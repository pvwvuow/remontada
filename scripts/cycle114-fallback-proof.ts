// cycle-114 — Part B proof: the REAL /api/standings route handler serves the
// last-known-good snapshot (stale:true, HTTP 200) when the upstream is down
// AND no leagueRaw/standings row exists — the exact registered failure mode
// of the cycle-113 observation (no L1/L2 row + producer throw = honest
// error with no net). fetch is monkey-patched to reject fotmob.com
// (simulated outage); the DB is the repo's own prisma/dev.db (src/lib/db.ts
// anchors file: URLs there).
// TWO invocations are required: `seed` performs a healthy fetch that writes
// the snapshot; `outage` runs in a FRESH process (empty L1 — the cache's
// memory tier is module-internal, so a same-process re-test would be served
// from L1 and never reach the producer). Steps:
//   seed:   GET ?league=laliga&season=2024/2025 (fetch OK) → 200 fresh,
//           snapshot row written to L2.
//   outage: delete ONLY the leagueRaw/standings L2 rows for that key
//           (simulating "no stored row", cycle-113 mode; snapshot kept) →
//           fetch FAILS → same GET → expect 200 ok:true stale:true rows>0
//           → persiangulf under a network failure (no snapshot ever) → 502
//           honest error (generic branch; the LeagueUnavailable 503 branch
//           is proven separately with the REAL fetch) → fetch restored →
//           persiangulf REAL null-body outage → 503 «موقتاً در دسترس نیست»
//           unchanged (designed empty-state) → seriea current → fresh 200
//           with NO stale flag (healthy path renders no notice).
import { PrismaClient } from "@prisma/client";

const db = new PrismaClient({
  datasources: { db: { url: "file:/home/z/my-project/remontada/prisma/dev.db" } },
});

async function main() {
  const mode = process.argv[2] || "seed";
  const realFetch = globalThis.fetch.bind(globalThis);
  let outage = false;
  globalThis.fetch = async (input: unknown, init?: unknown) => {
    const url = typeof input === "string" ? input : (input as { url?: string })?.url ?? String(input);
    if (outage && url.includes("fotmob.com")) {
      throw new Error("SIMULATED-OUTAGE (cycle-114 proof): upstream unreachable");
    }
    return realFetch(input as RequestInfo, init as RequestInit | undefined);
  };

  const { GET } = await import("../src/app/api/standings/route");
  const { NextRequest } = await import("next/server");

  const call = async (qs: string) => {
    const res = await GET(new NextRequest(`http://localhost:3000/api/standings?${qs}`));
    return { status: res.status, body: await res.json() };
  };

  let bad = 0;
  const check = (name: string, cond: boolean, detail: string) => {
    console.log(`${cond ? "PASS" : "FAIL"} ${name} ${detail}`);
    if (!cond) bad++;
  };

  if (mode === "seed") {
    const s1 = await call("league=laliga&season=2024/2025");
    check("seed.fresh-historical", s1.status === 200 && s1.body.ok === true && !s1.body.stale && s1.body.rows?.length > 0,
      `status=${s1.status} rows=${s1.body.rows?.length} stale=${s1.body.stale}`);
    const snap1 = await db.cache.findUnique({ where: { key: "standings:snapshot:laliga:2024/2025" } });
    check("seed.snapshot-written", !!snap1 && JSON.parse(snap1.value).rows?.length > 0,
      `present=${!!snap1} rows=${snap1 ? JSON.parse(snap1.value).rows?.length : 0}`);
  } else {
    // ---- simulate "no stored row for the live keys" (cycle-113 mode) ----
    await db.cache.deleteMany({
      where: { key: { in: ["leagueRaw:laliga:2024/2025", "standings:v5:laliga:2024/2025"] } },
    });
    const snap = await db.cache.findUnique({ where: { key: "standings:snapshot:laliga:2024/2025" } });
    check("outage.snapshot-present", !!snap && JSON.parse(snap.value).rows?.length > 0,
      `present=${!!snap} rows=${snap ? JSON.parse(snap.value).rows?.length : 0}`);

    // ---- outage → snapshot fallback (stale:true, 200) ----
    outage = true;
    const s2 = await call("league=laliga&season=2024/2025");
    check("outage.fallback-stale", s2.status === 200 && s2.body.ok === true && s2.body.stale === true && s2.body.rows?.length > 0,
      `status=${s2.status} ok=${s2.body.ok} stale=${s2.body.stale} rows=${s2.body.rows?.length} leagueFa=${s2.body.leagueFa}`);
    const top = s2.body.rows?.[0];
    check("outage.snapshot-content", !!top && typeof top.name === "string" && typeof top.pts === "number",
      `top=${top?.name} pts=${top?.pts}`);

    // ---- persiangulf under a NETWORK failure (no snapshot ever) → honest 502 ----
    const s3 = await call("league=persiangulf");
    check("outage.persiangulf-no-net", s3.status === 502 && s3.body.ok === false,
      `status=${s3.status} error=${s3.body.error}`);
    outage = false;

    // ---- persiangulf REAL null-body outage → designed 503 unchanged ----
    const s3b = await call("league=persiangulf");
    check("real.persiangulf-503", s3b.status === 503 && s3b.body.ok === false && s3b.body.error === "داده این لیگ موقتاً در دسترس نیست.",
      `status=${s3b.status} error=${s3b.body.error}`);

    // ---- healthy path again → fresh 200, NO stale flag ----
    const s4 = await call("league=seriea");
    check("real.fresh-no-stale", s4.status === 200 && s4.body.ok === true && s4.body.stale === undefined,
      `status=${s4.status} stale=${s4.body.stale}`);
  }

  await db.$disconnect();
  console.log(bad === 0 ? `CYCLE114-PROOF[${mode}] ALL-GREEN` : `CYCLE114-PROOF[${mode}] FAILED=${bad}`);
  process.exit(bad === 0 ? 0 : 1);
}
main().catch((e) => { console.error(e); process.exit(1); });
