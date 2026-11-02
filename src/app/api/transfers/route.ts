// ------------------------------------------------------------------
// Remontada — /api/transfers (cycle-415)
// The portal-wide transfers wire («تازه‌ترین انتقال‌های فوتبال») — the
// third and last level of the «انتقال‌ها» backlog (league tab = cycle-57,
// team feed = the team page; the global wire upstream was never consumed
// before this cycle). One cached producer getGlobalTransfers()
// (`globalTransfers:v1`, 15-min TTL, the news cadence), honest latest-50
// window (upstream ignores page/date params — probed live, see the
// producer card). Shape mirrors /api/news: { ok, items, fetchedAt } with
// the honest 502 on outage (never an empty success).
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getGlobalTransfers } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const feed = await getGlobalTransfers();
    return NextResponse.json({ ok: true, items: feed.items, total: feed.total, fetchedAt: feed.fetchedAt });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت انتقال‌ها ناموفق بود." },
      { status: 502 }
    );
  }
}
