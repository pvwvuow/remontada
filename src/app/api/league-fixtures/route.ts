// ------------------------------------------------------------------
// Remontada — /api/league-fixtures?league={key}
// Full-season fixtures (upcoming + recent) for a configured league
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueFixtures, LeagueUnavailableError, LEAGUES } from "@/lib/fotmob";
import { seasonParamOk } from "@/lib/season";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const lg = LEAGUES.find((l) => l.key === key);
  if (!lg) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  // cycle-55: optional historical season ("2024/2025") — strict shape, then
  // passed straight to the FotMob fetch; anything else → 400. cycle-382:
  // plain-year shapes ("2022") ride the per-league plainYearSeasons flag.
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !seasonParamOk(season, lg.plainYearSeasons === true)) {
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
