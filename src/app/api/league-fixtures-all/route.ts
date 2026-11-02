// ------------------------------------------------------------------
// Remontada — /api/league-fixtures-all?league={key}&season={yyyy/yyyy}
// cycle-315: the FULL season fixture list for the league page's
// «فصل کامل» panel. The fixtures tab (/api/league-fixtures) serves a
// ±window; this route reads fixtures.allMatches off the SAME cached
// getLeagueRaw producer the tab and the ICS calendar (cycle-312) use —
// zero new upstream requests. Guards mirror the league-fixtures
// contract: unknown key / bad season → 400, unavailable league → 503,
// upstream failure → 502; a season without rows degrades to an honest
// empty rows[] (the panel shows its own empty state).
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueAllFixtures, LeagueUnavailableError, LEAGUES, SEASON_PARAM_RE } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  if (!LEAGUES.some((l) => l.key === key)) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !SEASON_PARAM_RE.test(season)) {
    return NextResponse.json({ ok: false, error: `Invalid season: ${season}` }, { status: 400 });
  }
  try {
    const data = await getLeagueAllFixtures(key, season);
    return NextResponse.json({ ok: true, ...data });
  } catch (err) {
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "دریافت برنامه کامل لیگ ناموفق بود." },
      { status: 502 }
    );
  }
}
