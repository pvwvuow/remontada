// ------------------------------------------------------------------
// Remontada — /api/league-transfers?league={key}
// Current-season transfer feed of a configured league's clubs (cycle-57).
// No season parameter on purpose: probed live — the transfers key is only
// populated for the current-season payload (historical season → null data);
// leagues without a feed (UCL, Persian Gulf) return transfers: null with
// ok: true so the UI can hide the tab.
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueTransfers, LeagueUnavailableError, LEAGUES } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const valid = LEAGUES.some((l) => l.key === key);
  if (!valid) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  try {
    const transfers = await getLeagueTransfers(key);
    return NextResponse.json({ ok: true, transfers });
  } catch (err) {
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "دریافت انتقال‌ها ناموفق بود." },
      { status: 502 }
    );
  }
}
