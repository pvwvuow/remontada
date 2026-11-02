// ------------------------------------------------------------------
// Remontada — /api/league-totw?league={key}[&season=YYYY/YYYY][&round=]
// «تیم هفته» (TOTW) for a configured league; leagues without the surface
// (null-body upstream) → ok:false so the section hides itself — the honest
// absence. The hyphenated upstream endpoints were found in cycle-360 via
// the real client XHRs after three cycles of singular-pattern 404s.
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueTotw, LEAGUES } from "@/lib/fotmob";
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
  const round = req.nextUrl.searchParams.get("round") || undefined;
  try {
    const totw = await getLeagueTotw(key, season, round);
    if (!totw) {
      return NextResponse.json({ ok: false, error: "این لیگ تیم هفته ندارد." });
    }
    return NextResponse.json({ ok: true, totw });
  } catch {
    return NextResponse.json({ ok: false, error: "دریافت تیم هفته ناموفق بود." }, { status: 502 });
  }
}
