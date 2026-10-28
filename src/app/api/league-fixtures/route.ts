// ------------------------------------------------------------------
// Remontada — /api/league-fixtures?league={key}
// Full-season fixtures (upcoming + recent) for a configured league
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueFixtures, LeagueUnavailableError, LEAGUES, SEASON_PARAM_RE } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

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
  try {
    const data = await getLeagueFixtures(key, season);
    return NextResponse.json({ ok: true, ...data });
  } catch (err) {
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "دریافت برنامه لیگ ناموفق بود." },
      { status: 502 }
    );
  }
}
