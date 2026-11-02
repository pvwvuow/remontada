// ------------------------------------------------------------------
// Remontada — /api/transfers (cycle-415, fee presets cycle-416)
// The portal-wide transfers wire («تازه‌ترین انتقال‌های فوتبال») — the
// third and last level of the «انتقال‌ها» backlog (league tab = cycle-57,
// team feed = the team page; the global wire upstream was never consumed
// before this cycle). One cached producer getGlobalTransfers()
// (`globalTransfers:v1`, 15-min TTL, the news cadence), honest latest-50
// window (upstream ignores page/date params — probed live, see the
// producer card). Shape mirrors /api/news: { ok, items, fetchedAt } with
// the honest 502 on outage (never an empty success).
//
// cycle-416: the fee-preset dimension — the 415 card's «چرخهٔ آینده» item.
// `?minFee=` accepts ONLY the strict preset allowlist (the season-param
// convention: one allowlist, one contract); every preset rides its OWN
// cache key (`globalTransfers:v1:f{N}`) so windows never mix, and the
// response echoes the applied threshold for the client state. Anything
// else → the honest 400 Persian error, upstream never sees it.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getGlobalTransfers, TRANSFER_FEE_PRESETS } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const rawFee = new URL(req.url).searchParams.get("minFee");
  let minFee: number | undefined;
  if (rawFee !== null) {
    if (!/^\d{1,9}$/.test(rawFee)) {
      return NextResponse.json({ ok: false, error: "آستانهٔ کارمزد نامعتبر است" }, { status: 400 });
    }
    const n = Number(rawFee);
    if (!(TRANSFER_FEE_PRESETS as readonly number[]).includes(n)) {
      return NextResponse.json({ ok: false, error: "آستانهٔ کارمزد نامعتبر است" }, { status: 400 });
    }
    minFee = n;
  }
  try {
    const feed = await getGlobalTransfers(minFee);
    return NextResponse.json({
      ok: true,
      items: feed.items,
      total: feed.total,
      fetchedAt: feed.fetchedAt,
      ...(feed.minFee ? { minFee: feed.minFee } : {}),
    });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت انتقال‌ها ناموفق بود." },
      { status: 502 }
    );
  }
}
