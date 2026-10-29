import { NextRequest, NextResponse } from "next/server";
import { getStandings, LeagueUnavailableError, LEAGUES, SEASON_PARAM_RE, type StandingsData } from "@/lib/fotmob";
import { cacheGetDeep, cacheSet } from "@/lib/cache";

export const dynamic = "force-dynamic";

// ------------------------------------------------------------------
// cycle-114 — standings last-known-good snapshot fallback (the cycle-42
// topscorers design, mirrored for the standings surface).
// Why: `cached()` already degrades to a stale L1/L2 payload when the
// producer fails, but a key with NO stored row at all (cold process +
// a league/season never successfully fetched, e.g. the transient 503s
// registered by the cycle-113 patrol right after its restart) has no
// safety net — the honest 503 was the only answer. A full snapshot of
// the last successful per-league payload is now kept in the two-tier
// cache (L2 = SQLite, survives restarts) and served with `stale: true`
// when the live fetch throws, so the UI can label it honestly
// («آخرین داده‌های ذخیره‌شده») instead of dropping the table.
// persiangulf keeps its designed empty-state: the upstream payload is
// always unusable, no snapshot is ever written, and the fallback never
// fires there.
// ------------------------------------------------------------------
const SNAPSHOT_TTL = 24 * 60 * 60_000; // last-known-good kept up to 24h (cycle-42 mirror)

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const valid = LEAGUES.some((l) => l.key === key);
  if (!valid) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  // cycle-55: optional historical season ("2024/2025") — strict shape, then
  // passed straight to the FotMob fetch; anything else → 400
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !SEASON_PARAM_RE.test(season)) {
    return NextResponse.json({ ok: false, error: `Invalid season: ${season}` }, { status: 400 });
  }
  // cycle-114: snapshot probe BEFORE the fetch (cheap L1/L2 read, never
  // triggers a producer) so a failing producer still has a net to catch it
  const snapKey = `standings:snapshot:${key}:${season || "cur"}`;
  const prev = await cacheGetDeep<StandingsData>(snapKey);
  const prevUsable =
    prev && !prev.stale && Array.isArray(prev.value?.rows) && prev.value.rows.length > 0
      ? prev
      : null;
  try {
    const data = await getStandings(key, season);
    // snapshot only meaningful payloads (a table with rows) — thin/empty
    // feeds never overwrite a good snapshot (MIN_FULL philosophy of cycle-42)
    if (Array.isArray(data.rows) && data.rows.length > 0) {
      cacheSet(snapKey, data, SNAPSHOT_TTL);
    }
    return NextResponse.json({ ok: true, ...data });
  } catch (err) {
    // upstream outage — a last-known-good snapshot beats the honest 503
    if (prevUsable) {
      return NextResponse.json({ ok: true, ...prevUsable.value, stale: true });
    }
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "دریافت جدول رده‌بندی ناموفق بود." },
      { status: 502 }
    );
  }
}
