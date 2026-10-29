// cycle-129 — Poisoning reproduction probe for the L2-write-drop class.
//
// Mechanism under test (src/lib/cache.ts, PRE-FIX): getDb() runs a ONE-TIME
// smoke query (`SELECT 1`); if that single call fails — even transiently, e.g.
// while another process briefly holds dev.db during a copy/restart window —
// the module sets dbDisabled=true FOREVER. From that moment every L2 write in
// the process is silently discarded (dbSet returns early) while the site keeps
// serving from L1 — exactly the "some rows written, some not" split observed
// live during the cycle-127 behavioral proof.
//
// Faithful simulation: db.$queryRaw is monkey-patched to REJECT while the mock
// window is open (the same rejection the real smoke query would produce under
// a transient lock) — the repo precedent is cycle-114's fetch monkey-patch for
// outage simulation. DB itself stays healthy the whole time.
//
// Modes:
//   transient : mock rejects until t+150ms  → post-fix init retry (#2, +400ms) succeeds
//   extended  : mock rejects until t+1500ms → post-fix init attempts exhaust,
//               30s cooldown passes, re-init self-heals (~t+31s)
//
// Usage: bun scripts/cycle129-poison-probe.ts <transient|extended> <prefix|postfix>
// Exit 0 = expectation met, 1 = expectation FAILED.
// NOTE: the `prefix` stage is only meaningful against the PRE-fix cache.ts —
// to re-run the reproduction, stash the src/lib/cache.ts change first. Pre-fix
// results (captured 2026-10-29 before the fix): transient → dropped at +10.0s,
// extended → dropped at +42.2s, both PERMANENTLY SILENTLY DROPPED, exit 0.
import { writeSync } from "node:fs";

const T0 = Date.now();
function log(msg: string) {
  try {
    writeSync(1, `[poison +${Date.now() - T0}ms] ${msg}\n`);
  } catch {}
}
const watchdog = setTimeout(() => {
  log("WATCHDOG abort");
  process.exit(1);
}, 75_000);
watchdog.unref?.();

const MODE = process.argv[2] ?? "transient";
const STAGE = process.argv[3] ?? "prefix";
const MOCK_UNTIL = MODE === "extended" ? 1500 : 150;
const PROVE_BY = MODE === "extended" ? 40_000 : 8_000; // poll deadline for the row to land
const KEY = `c129poison:${MODE}:${STAGE}`;

log(`mode=${MODE} stage=${STAGE} (mock rejects until +${MOCK_UNTIL}ms, prove-by +${PROVE_BY}ms)`);

const { cacheSet } = await import("../src/lib/cache");
const { db } = await import("../src/lib/db");

// ---- monkey-patch the smoke query while the window is open ----
const anyDb = db as unknown as { $queryRaw: (...a: unknown[]) => Promise<unknown> };
const realQueryRaw = anyDb.$queryRaw;
anyDb.$queryRaw = (...args: unknown[]) => {
  if (Date.now() - T0 < MOCK_UNTIL) {
    return Promise.reject(new Error("SIMULATED transient lock (cycle-129 mock)") as never);
  }
  return (realQueryRaw as (...a: unknown[]) => Promise<unknown>).apply(db, args);
};
log("mock armed");

cacheSet(KEY, { poisoned: STAGE, at: new Date().toISOString() }, 120_000);
log("cacheSet fired (write must survive the transient smoke failure)");

// restore the real query (DB healthy again — mirroring a lock window that passed)
setTimeout(() => {
  anyDb.$queryRaw = realQueryRaw;
  log("mock disarmed — DB fully healthy from here on");
}, MOCK_UNTIL + 50);

// extended mode: after the cooldown expires (~+31s), a SECOND write must land
// (L2 self-heal for subsequent writes — writes fired INSIDE the outage window
// are not retro-queued by design; the heal proves the cooldown path works)
const KEY2 = `${KEY}:after-cooldown`;
if (MODE === "extended") {
  setTimeout(() => {
    cacheSet(KEY2, { poisoned: STAGE, afterCooldown: true }, 120_000);
    log("second cacheSet fired post-cooldown");
  }, 31_500);
}

// poll for the rows
let landed = false;
let landed2 = false;
const pollStart = Date.now();
while (Date.now() - pollStart < PROVE_BY) {
  await new Promise((r) => setTimeout(r, 500));
  if (!landed) {
    const row = await db.cache.findUnique({ where: { key: KEY } });
    if (row) {
      landed = true;
      log(`row LANDED at +${Date.now() - T0}ms`);
    }
  }
  if (MODE === "extended" && Date.now() - T0 > 31_500 && !landed2) {
    const row2 = await db.cache.findUnique({ where: { key: KEY2 } });
    if (row2) {
      landed2 = true;
      log(`post-cooldown row LANDED at +${Date.now() - T0}ms`);
    }
  }
  if (landed && (MODE !== "extended" || landed2)) break;
}

// extra pre-fix certainty for `transient`: check AGAIN after the prove window
// so "poisoned" is not a race misread (row must still be absent with healthy DB)
if (!landed) {
  await new Promise((r) => setTimeout(r, 2000));
  const row = await db.cache.findUnique({ where: { key: KEY } });
  if (row) {
    landed = true;
    log(`row LANDED (late recheck) at +${Date.now() - T0}ms`);
  }
}

const ok =
  STAGE === "postfix"
    ? MODE === "extended"
      ? landed2 // heal = a post-cooldown write lands
      : landed // heal = the write survives the transient window via init retry
    : MODE === "extended"
      ? !landed && !landed2 // poisoned = even post-cooldown writes never land
      : !landed;
log(
  STAGE === "postfix"
    ? `RESULT: L2 write SURVIVED / self-healed (${MODE}/${STAGE}, row1=${landed} row2=${landed2}) — ${ok ? "as expected" : "UNEXPECTED"}`
    : `RESULT: L2 write PERMANENTLY SILENTLY DROPPED (${MODE}/${STAGE}, row1=${landed} row2=${landed2}) — ${ok ? "class reproduced" : "UNEXPECTED"}`
);

await db.cache.deleteMany({ where: { key: { startsWith: "c129poison:" } } });
log("cleanup done");
process.exit(ok ? 0 : 1);
