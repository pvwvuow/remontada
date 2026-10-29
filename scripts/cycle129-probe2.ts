// cycle-129 — DIAGNOSTIC probe: map the REAL failure surface of concurrent L2
// writes. Unlike cycle129-probe.ts (which uses the product cacheSet that swallows
// errors), this calls db.cache.upsert DIRECTLY and collects every rejection, so we
// see the raw mechanism (P2024 pool timeout vs SQLITE_BUSY vs none) under three
// burst shapes. Run: bun scripts/cycle129-probe2.ts
import { writeSync } from "node:fs";

const T0 = Date.now();
function log(msg: string) {
  try {
    writeSync(1, `[diag +${Date.now() - T0}ms] ${msg}\n`);
  } catch {}
}
const watchdog = setTimeout(() => {
  log("WATCHDOG abort");
  process.exit(3);
}, 100_000);
watchdog.unref?.();

const { db } = await import("../src/lib/db");
log("db imported");

function blob(rows: number, tag: string) {
  return {
    rows: Array.from({ length: rows }, (_, r) => ({
      id: r,
      name: `${tag}-row-${r}-${"p".repeat(72)}`,
      note: `${tag}-${"x".repeat(48)}`,
    })),
  };
}

const PREFIX = "c129diag";
async function phase(tag: string, n: number, rows: number) {
  const key = (i: number) => `${PREFIX}:${tag}:${i}`;
  const value = JSON.stringify(blob(rows, tag));
  const t = Date.now();
  const results = await Promise.allSettled(
    Array.from({ length: n }, (_, i) =>
      db.cache.upsert({
        where: { key: key(i) },
        create: { key: key(i), value, expiresAt: new Date(Date.now() + 120_000) },
        update: { value, expiresAt: new Date(Date.now() + 120_000), storedAt: new Date() },
      })
    )
  );
  const rejected = results.filter((r) => r.status === "rejected");
  const msgs = new Map<string, number>();
  for (const r of rejected) {
    const m = String((r as PromiseRejectedResult).reason?.message ?? r.reason).slice(0, 90);
    msgs.set(m, (msgs.get(m) ?? 0) + 1);
  }
  log(`PHASE ${tag}: n=${n} valueSize=${(value.length / 1024).toFixed(0)}KB elapsed=${Date.now() - t}ms rejected=${rejected.length}`);
  for (const [m, c] of msgs) log(`  └ ${c}× ${m}`);
  const del = await db.cache.deleteMany({ where: { key: { startsWith: `${PREFIX}:${tag}:` } } });
  log(`  └ cleanup ${del.count} rows in ${Date.now() - t}ms total`);
}

await phase("a-small-400", 400, 140);   // ~30KB × 400
await phase("b-real-80", 80, 4500);     // ~850KB × 80 (real leagueRaw size)
await phase("c-huge-40", 40, 22000);    // ~4MB × 40
log("DONE");
process.exit(0);
