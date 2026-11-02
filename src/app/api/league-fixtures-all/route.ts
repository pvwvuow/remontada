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
import { getLeagueAllFixtures, LeagueUnavailableError, LEAGUES } from "@/lib/fotmob";
import { seasonParamOk } from "@/lib/season";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const lg = LEAGUES.find((l) => l.key === key);
  if (!lg) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  // cycle-382: plain-year seasons ride the per-league plainYearSeasons flag.
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !seasonParamOk(season, lg.plainYearSeasons === true)) {
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
