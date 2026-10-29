// ------------------------------------------------------------------
// Remontada — /api/league-titles?league={key}
// «قهرمانان» (cycle-121): the league's full per-season title history
// (champion + runner-up) from FotMob's data/leagues endpoint
// (top-level seasons[] — probed uniform across the configured leagues).
// The SAME cached raw payload the standings/fixtures/bracket/transfers
// reads use, so this adds zero upstream hits. Season-independent by
// design. titles: null with ok: true when the source has no list so the
// UI can hide the tab (same contract as league-bracket, cycle-56); the
// persiangulf null payload keeps its designed 503 contract.
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueTitleHistory, LeagueUnavailableError, LEAGUES } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const valid = LEAGUES.some((l) => l.key === key);
  if (!valid) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  try {
    const titles = await getLeagueTitleHistory(key);
    return NextResponse.json({ ok: true, titles });
  } catch (err) {
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "دریافت تاریخچهٔ قهرمانی ناموفق بود." },
      { status: 502 }
    );
  }
}
