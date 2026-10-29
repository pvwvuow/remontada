// cycle-129 — Pre-fix reproduction probe for the registered L2-write-drop class
// (standalone fix candidate noted on the cycle-127 card): concurrent cacheSet()
// calls contend for SQLite's single-writer lock; dbSet swallowed the resulting
// SQLITE_BUSY errors silently, so rows simply VANISHED from L2 (observed live
// during the cycle-127 behavioral proof: leagueRaw/snapshot written, v6/fullGoals not).
//
// This probe runs the REAL product cache module (src/lib/cache.ts → src/lib/db.ts,
// anchored to the repo's own prisma/dev.db) the same way cycle102/cycle114 probes do:
//   - N=40 concurrent cacheSet() calls (~30KB payloads; real leagueRaw rows are 850KB+,
//     the drop class is about lock contention, not payload size)
//   - bounded concurrent cacheGetDeep() readers during the write storm
//   - then it polls the DB until the storm settles and counts how many rows LANDED.
// Pre-fix expectation: present < N (silent drops). Post-fix expectation: N/N within budget.
// Probe rows are deleted again at the end (prisma/dev.db is git-ignored, unaffected).
// Logging is UNBUFFERED (fs.writeSync) + a hard watchdog guarantees self-termination.
//
// Run: bun scripts/cycle129-probe.ts [runid]

import { writeSync } from "node:fs";

const N = 40;
const ROWS = 140;
const RUN = process.argv[2] ?? `r${Date.now().toString(36)}`;
const PREFIX = `c129probe:${RUN}:`;
const SETTLE_BUDGET_MS = 25_000;
const T0 = Date.now();

function log(msg: string) {
  try {
    writeSync(1, `[probe +${Date.now() - T0}ms] ${msg}\n`);
  } catch {
    /* stdout gone */
  }
}

const watchdog = setTimeout(() => {
  log(`WATCHDOG: aborting after 70s — stuck state dump`);
  process.exit(3);
}, 70_000);
watchdog.unref?.();

log(`importing product cache module... run=${RUN}`);
const { cacheSet, cacheGetDeep } = await import("../src/lib/cache");
const { db } = await import("../src/lib/db");
log("imports done");

function makeValue(i: number) {
  return {
    probe: true,
    run: RUN,
    rows: Array.from({ length: ROWS }, (_, r) => ({
      id: r,
      name: `player-row-${r}-${"p".repeat(72)}`,
      note: `probe-payload-${i}-${"x".repeat(48)}`,
    })),
  };
}

// bounded readers: each read races a 2s cap, max 25 reads per reader
let readerAlive = 0;
const readers: Promise<void>[] = [];
for (let r = 0; r < 6; r++) {
  readers.push(
    (async () => {
      readerAlive++;
      for (let k = 0; k < 25; k++) {
        if (Date.now() - T0 > 6000) break;
        const i = Math.floor(Math.random() * N);
        await Promise.race([
          cacheGetDeep(`${PREFIX}${i}`).catch(() => null),
          new Promise((res) => setTimeout(res, 2000)),
        ]);
      }
      readerAlive--;
    })()
  );
}
log("6 bounded readers started");

const fireT = Date.now();
for (let i = 0; i < N; i++) {
  cacheSet(`${PREFIX}${i}`, makeValue(i), 120_000);
}
log(`fired ${N} concurrent cacheSet in ${Date.now() - fireT}ms`);

await new Promise((res) => setTimeout(res, 1500));
log(`readers alive=${readerAlive} (storm churn window done)`);

// poll until present stops growing for 4 consecutive polls or budget ends
let present = -1;
let stable = 0;
const pollStart = Date.now();
let polls = 0;
while (Date.now() - pollStart < SETTLE_BUDGET_MS) {
  await new Promise((res) => setTimeout(res, 500));
  polls++;
  const p = await Promise.race([
    db.cache.findMany({ where: { key: { startsWith: PREFIX } }, select: { key: true } }),
    new Promise<{ key: string }[]>((res) => setTimeout(() => res([]), 3000)),
  ]).then((rows) => rows.length);
  if (p === present) stable++;
  else stable = 0;
  if (p !== present) log(`poll ${polls}: present=${p}/${N}`);
  present = p;
  if (present >= N || stable >= 4) break;
}

const dropped = N - present;
log(`present=${present}/${N} dropped=${dropped} (polls=${polls})`);
log(dropped === 0 ? "PROBE RESULT: NO DROPS" : `PROBE RESULT: ${dropped} SILENT L2 DROPS — class reproduced`);

const del = await Promise.race([
  db.cache.deleteMany({ where: { key: { startsWith: PREFIX } } }),
  new Promise<{ count: number }>((res) => setTimeout(() => res({ count: -1 }), 5000)),
]);
log(`cleanup: deleted ${del.count} probe rows (-1 = cleanup raced timeout, rows are TTL garbage only)`);
log("DONE");
process.exit(0);
