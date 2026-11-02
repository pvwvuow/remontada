import { NextResponse } from "next/server";
import { getNewsFeedMeta } from "@/lib/news";

export const dynamic = "force-dynamic";

// cycle-202: the producer (RSS/ESPN fetchers + the batched Persian
// translation stage) moved to src/lib/news.ts so /api/search can fold
// the SAME cached instance («خبرها» search index) — this route keeps
// the exact contract: same cache key (news:v3 since update cycle-305),
// same 15-min TTL, same response shape { ok, items, fetchedAt }.
// update cycle-305: fetchedAt now comes from the cached payload itself
// (the producer's real fetch time) instead of the route-call instant —
// same field, same type, honest value: clients can show the feed's true
// cache age, including during stale-while-error windows.
export async function GET() {
  try {
    const feed = await getNewsFeedMeta();
    return NextResponse.json({ ok: true, items: feed.items, fetchedAt: feed.fetchedAt });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "news fetch failed", items: [] },
      { status: 502 }
    );
  }
}
