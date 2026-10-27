// ------------------------------------------------------------------
// Remontada — /api/league-fixtures?league={key}
// Full-season fixtures (upcoming + recent) for a configured league
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueFixtures, LEAGUES } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const valid = LEAGUES.some((l) => l.key === key);
  if (!valid) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  try {
    const data = await getLeagueFixtures(key);
    return NextResponse.json({ ok: true, ...data });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "fetch failed" },
      { status: 502 }
    );
  }
}
