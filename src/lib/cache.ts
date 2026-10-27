// ------------------------------------------------------------------
// Remontada — two-tier TTL cache with stale-while-error behavior
//   L1: in-memory Map (per process, fastest)
//   L2: SQLite `Cache` table via Prisma (survives restarts/redeploys)
// If the database is unavailable (missing engine, locked file, …) the
// cache silently degrades to memory-only — the site never breaks
// because of the cache. DB access is lazy (dynamic import) so a broken
// Prisma setup cannot crash module initialization.
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
let dbDisabled = false;

function getDb(): Promise<PrismaCacheClient | null> {
  if (dbDisabled) return Promise.resolve(null);
  if (!dbPromise) {
    dbPromise = (async () => {
      try {
        const mod = await import("./db");
        // tiny smoke query — proves the engine + file are usable
        await mod.db.$queryRaw`SELECT 1`;
        return mod.db as unknown as PrismaCacheClient;
      } catch (err) {
        console.warn("[cache] Prisma unavailable — memory-only cache:", err instanceof Error ? err.message : err);
        dbDisabled = true;
        return null;
      }
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

async function dbSet<T>(key: string, value: T, ttlMs: number): Promise<void> {
  const db = await getDb();
  if (!db) return;
  try {
    const expiresAt = new Date(Date.now() + Math.max(ttlMs, 60_000));
    await db.cache.upsert({
      where: { key },
      create: { key, value: JSON.stringify(value), expiresAt },
      update: { value: JSON.stringify(value), expiresAt, storedAt: new Date() },
    });
    // occasional sweep of long-expired rows (cheap, indexed)
    if (Math.random() < 0.02) {
      await db.cache.deleteMany({ where: { expiresAt: { lt: new Date(Date.now() - 7 * 86400_000) } } });
    }
  } catch {
    // ignore write failures
  }
}

// ---------- public API (same signature as before) ----------
export function cacheGet<T>(key: string): { value: T; stale: boolean } | null {
  const e = memGet<T>(key);
  if (!e) return null;
  return { value: e.value, stale: Date.now() > e.expiresAt };
}

export function cacheSet<T>(key: string, value: T, ttlMs: number): void {
  memSet(key, value, ttlMs);
  void dbSet(key, value, ttlMs);
}

export async function cached<T>(key: string, ttlMs: number, producer: () => Promise<T>): Promise<T> {
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
    cacheSet(key, fresh, ttlMs);
    return fresh;
  } catch (err) {
    // stale-while-error: memory first, then disk
    if (mem) return mem.value;
    if (disk) return disk.value as T;
    throw err;
  }
}
