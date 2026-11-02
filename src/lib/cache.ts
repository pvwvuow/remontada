// ------------------------------------------------------------------
// Remontada — two-tier TTL cache with stale-while-error behavior
//   L1: in-memory Map (per process, fastest)
//   L2: SQLite `Cache` table via Prisma (survives restarts/redeploys)
// If the database is unavailable (missing engine, locked file, …) the
// cache silently degrades to memory-only — the site never breaks
// because of the cache. DB access is lazy (dynamic import) so a broken
// Prisma setup cannot crash module initialization.
//
// Cycle 129 — L2 write reliability (registered candidate from card 127):
// the old getDb() permanently disabled L2 after a SINGLE failed smoke
// query, so one transient lock (e.g. a copy/restart window on dev.db)
// silently killed every L2 write for the rest of the process (reproduced
// pre-fix by scripts/cycle129-poison-probe.ts). Now: init is retried,
// and after exhaustion L2 re-tries after a cooldown instead of dying.
// All L2 writes also flow through one FIFO queue with bounded retries,
// so a transient write error retries instead of vanishing, and the
// final drop is logged instead of being fully silent.
// ------------------------------------------------------------------

interface CacheEntry<T> {
  value: T;
  expiresAt: number;
  storedAt: number;
}

const store = new Map<string, CacheEntry<unknown>>();

// ---------- L1 helpers ----------
function memGet<T>(key: string): CacheEntry<T> | null {
  return (store.get(key) as CacheEntry<T> | undefined) ?? null;
}

function memSet<T>(key: string, value: T, ttlMs: number): void {
  store.set(key, { value, expiresAt: Date.now() + ttlMs, storedAt: Date.now() });
  // opportunistic cleanup
  if (store.size > 200) {
    const now = Date.now();
    for (const [k, v] of store) {
      if (now > v.expiresAt + 10 * 60 * 1000) store.delete(k);
    }
  }
}

// ---------- L2 (Prisma / SQLite) ----------
interface PrismaCacheClient {
  cache: {
    findUnique(args: { where: { key: string } }): Promise<{ value: string; expiresAt: Date; storedAt: Date } | null>;
    upsert(args: {
      where: { key: string };
      create: { key: string; value: string; expiresAt: Date };
      update: { value: string; expiresAt: Date; storedAt: Date };
    }): Promise<unknown>;
    deleteMany(args: { where: { expiresAt: { lt: Date } } }): Promise<unknown>;
  };
}

let dbPromise: Promise<PrismaCacheClient | null> | null = null;
// cycle-129: cooldown timestamp instead of a permanent kill switch — L2
// degrades to memory-only for RETRY_COOLDOWN_MS after exhausted init
// attempts, then one fresh init cycle is allowed (self-healing L2).
let dbRetryNotBefore = 0;

const INIT_ATTEMPTS = 3;
const INIT_RETRY_PAUSE_MS = 400;
const RETRY_COOLDOWN_MS = 30_000;

function getDb(): Promise<PrismaCacheClient | null> {
  if (Date.now() < dbRetryNotBefore) return Promise.resolve(null);
  if (!dbPromise) {
    dbPromise = (async () => {
      for (let attempt = 1; attempt <= INIT_ATTEMPTS; attempt++) {
        try {
          const mod = await import("./db");
          // tiny smoke query — proves the engine + file are usable
          await mod.db.$queryRaw`SELECT 1`;
          return mod.db as unknown as PrismaCacheClient;
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          if (attempt < INIT_ATTEMPTS) {
            console.warn(
              `[cache] Prisma init attempt ${attempt}/${INIT_ATTEMPTS} failed — retrying in ${INIT_RETRY_PAUSE_MS}ms:`,
              msg
            );
            await new Promise((resolve) => setTimeout(resolve, INIT_RETRY_PAUSE_MS));
          } else {
            // exhausted: cooldown, then let a future call start a fresh init
            dbRetryNotBefore = Date.now() + RETRY_COOLDOWN_MS;
            dbPromise = null;
            console.warn(
              `[cache] Prisma unavailable — memory-only cache for ${RETRY_COOLDOWN_MS / 1000}s:`,
              msg
            );
            return null;
          }
        }
      }
      return null;
    })();
  }
  return dbPromise;
}

async function dbGet(key: string): Promise<CacheEntry<unknown> | null> {
  const db = await getDb();
  if (!db) return null;
  try {
    const row = await db.cache.findUnique({ where: { key } });
    if (!row) return null;
    return { value: JSON.parse(row.value), expiresAt: row.expiresAt.getTime(), storedAt: row.storedAt.getTime() };
  } catch {
    return null;
  }
}

// cycle-129: SQLite tolerates one writer at a time — all L2 writes (and the
// occasional sweep) are chained through this FIFO so they never contend with
// each other, and each write retries transient failures instead of vanishing.
// Callers keep the exact fire-and-forget contract: cacheSet() still returns
// void immediately and never throws.
let writeChain: Promise<void> = Promise.resolve();
const WRITE_RETRIES = 2;
const WRITE_RETRY_BASE_MS = 250;

function enqueueWrite(task: () => Promise<void>): Promise<void> {
  const next = writeChain.then(task, task);
  writeChain = next.then(
    () => undefined,
    () => undefined
  );
  return next;
}

async function dbSet<T>(key: string, value: T, ttlMs: number): Promise<void> {
  const db = await getDb();
  if (!db) return;
  await enqueueWrite(async () => {
    const expiresAt = new Date(Date.now() + Math.max(ttlMs, 60_000));
    const payload = JSON.stringify(value);
    for (let attempt = 0; ; attempt++) {
      try {
        await db.cache.upsert({
          where: { key },
          create: { key, value: payload, expiresAt },
          update: { value: payload, expiresAt, storedAt: new Date() },
        });
        // occasional sweep of long-expired rows (cheap, indexed)
        if (Math.random() < 0.02) {
          await db.cache.deleteMany({ where: { expiresAt: { lt: new Date(Date.now() - 7 * 86400_000) } } });
        }
        return;
      } catch (err) {
        if (attempt >= WRITE_RETRIES) {
          // observability: a final drop is now visible in the logs instead of silent
          console.warn("[cache] L2 write dropped after retries:", key, err instanceof Error ? err.message : err);
          return;
        }
        await new Promise((resolve) => setTimeout(resolve, WRITE_RETRY_BASE_MS * (attempt + 1)));
      }
    }
  });
}

// ---------- public API (same signature as before) ----------
export function cacheGet<T>(key: string): { value: T; stale: boolean } | null {
  const e = memGet<T>(key);
  if (!e) return null;
  return { value: e.value, stale: Date.now() > e.expiresAt };
}

/**
 * Cycle 42: deep lookup for last-known-good fallbacks — checks L1 first,
 * then L2. Unlike `cached()` this never triggers the producer, so callers
 * can decide themselves whether a (possibly stale) snapshot is usable
 * after a cold start (fresh process, empty L1 but a surviving SQLite row).
 */
export async function cacheGetDeep<T>(key: string): Promise<{ value: T; stale: boolean } | null> {
  const mem = memGet<T>(key);
  if (mem) return { value: mem.value, stale: Date.now() > mem.expiresAt };
  const disk = await dbGet(key);
  if (disk) return { value: disk.value as T, stale: Date.now() > disk.expiresAt };
  return null;
}

export function cacheSet<T>(key: string, value: T, ttlMs: number): void {
  memSet(key, value, ttlMs);
  void dbSet(key, value, ttlMs);
}

export async function cached<T>(
  key: string,
  // update cycle-102: ttlMs may now be a function of the freshly produced
  // value (matchday-aware league payloads pick their own TTL from the
  // payload's fixture list). Plain numbers behave exactly as before — every
  // existing caller is unchanged.
  ttlMs: number | ((value: T) => number),
  producer: () => Promise<T>
): Promise<T> {
  // L1 fresh → done
  const mem = memGet<T>(key);
  if (mem && Date.now() <= mem.expiresAt) return mem.value;

  // L2 lookup (also rehydrates L1)
  const disk = await dbGet(key);
  if (disk && Date.now() <= disk.expiresAt) {
    memSet(key, disk.value as T, disk.expiresAt - Date.now());
    return disk.value as T;
  }

  // miss / stale → refresh from source
  try {
    const fresh = await producer();
    cacheSet(key, fresh, typeof ttlMs === "function" ? ttlMs(fresh) : ttlMs);
    return fresh;
  } catch (err) {
    // stale-while-error: memory first, then disk
    if (mem) return mem.value;
    if (disk) return disk.value as T;
    throw err;
  }
}
