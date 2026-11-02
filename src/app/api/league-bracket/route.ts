// ------------------------------------------------------------------
// Remontada — /api/league-bracket?league={key}[&season=YYYY/YYYY]
// Cup knockout bracket (playoff rounds) for a configured league;
// bracket is null for leagues without knockout stages (cycle-56).
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueBracket, LeagueUnavailableError, LEAGUES, SEASON_PARAM_RE } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const valid = LEAGUES.some((l) => l.key === key);
  if (!valid) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !SEASON_PARAM_RE.test(season)) {
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
