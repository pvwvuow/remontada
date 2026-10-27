// ------------------------------------------------------------------
// Remontada — /api/league-fixtures?league={key}
// Full-season fixtures (upcoming + recent) for a configured league
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueFixtures, LeagueUnavailableError, LEAGUES } from "@/lib/fotmob";

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
