import { NextResponse, type NextRequest } from "next/server";
import { getAllTopScorers, SEASON_PARAM_RE, type GlobalScorersData } from "@/lib/fotmob";
import { cacheGetDeep, cacheSet } from "@/lib/cache";

export const dynamic = "force-dynamic";

// ------------------------------------------------------------------
// Cycle 42 — topscorers cold-start fix (long-standing cycle-36/40 finding).
// The merged table is built from 7 league feeds; on a cold start or during
// a FotMob hiccup some feeds fail and `getAllTopScorers` silently drops
// them, so the first visitor could see a thin or empty table. A full
// snapshot of the last successful merge is kept in the two-tier cache
// (L2 = SQLite, survives restarts). When the live merge comes back
// thinner than the snapshot — or fails outright — the snapshot is served
// with `stale: true` so the UI can label it honestly.
// TOPSCORERS_MIN_SCORERS exists for operational testing of the partial
// path (a healthy 7-league merge is well past 30 entries).
//
// cycle-132 — historical race («مسابقهٔ تاریخی آقای گل»): an optional
// `?season=YYYY/YYYY` (same strict shape guard as the standings family —
// 400 on anything else) threads the season into every per-league read.
// Historical requests BYPASS the snapshot logic entirely in both
// directions: they never READ the snapshot (a current-season table must
// never masquerade as 2023/2024) and never WRITE one (a historical merge
// must never evict the current-season last-known-good). Feeds that don't
// serve the season (probed: UCL historical → upstream failure,
// persiangulf → designed 503) just drop out of the merge — the UI shows
// exactly which leagues contributed. No param = the cycle-42 path,
// byte-identical.
// ------------------------------------------------------------------
const SNAPSHOT_KEY = "topscorers:snapshot";
const MIN_FULL = Number(process.env.TOPSCORERS_MIN_SCORERS || 30);
const SNAPSHOT_TTL = 24 * 60 * 60_000; // last-known-good kept up to 24h

export async function GET(req: NextRequest) {
  // cycle-132: optional historical season — same one-regex contract as the
  // standings/league-fixtures/league-bracket family
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !SEASON_PARAM_RE.test(season)) {
    return NextResponse.json({ ok: false, error: `Invalid season: ${season}` }, { status: 400 });
  }
  if (season) {
    // historical: live merge only — no snapshot read, no snapshot write
    try {
      const data = await getAllTopScorers(season);
      return NextResponse.json({ ok: true, ...data });
    } catch (err) {
      return NextResponse.json(
        { ok: false, error: err instanceof Error ? err.message : "fetch failed" },
        { status: 502 }
      );
    }
  }
  const prev = await cacheGetDeep<GlobalScorersData>(SNAPSHOT_KEY);
  const prevUsable =
    prev && !prev.stale && Array.isArray(prev.value?.scorers) && prev.value.scorers.length > 0
      ? prev
      : null;
  try {
    const data = await getAllTopScorers();
    if (data.scorers.length >= MIN_FULL) {
      cacheSet(SNAPSHOT_KEY, data, SNAPSHOT_TTL);
      return NextResponse.json({ ok: true, ...data });
    }
    // partial merge (some league feeds failed this round) — prefer a richer snapshot
    if (prevUsable && prevUsable.value.scorers.length > data.scorers.length) {
      return NextResponse.json({ ok: true, ...prevUsable.value, stale: true });
    }
    return NextResponse.json({ ok: true, ...data });
  } catch (err) {
    // total failure — a last-known-good snapshot beats an empty error page
    if (prevUsable) {
      return NextResponse.json({ ok: true, ...prevUsable.value, stale: true });
    }
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "fetch failed" },
      { status: 502 }
    );
  }
}
