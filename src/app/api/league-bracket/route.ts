// ------------------------------------------------------------------
// Remontada — /api/league-bracket?league={key}[&season=YYYY/YYYY]
// Cup knockout bracket (playoff rounds) for a configured league;
// bracket is null for leagues without knockout stages (cycle-56).
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueBracket, LeagueUnavailableError, LEAGUES } from "@/lib/fotmob";
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
    const bracket = await getLeagueBracket(key, season);
    return NextResponse.json({ ok: true, bracket });
  } catch (err) {
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "دریافت براکت جام ناموفق بود." },
      { status: 502 }
    );
  }
}
