import { NextResponse } from "next/server";
import { getNewsFeed } from "@/lib/news";

export const dynamic = "force-dynamic";

// cycle-202: the producer (RSS/ESPN fetchers + the batched Persian
// translation stage) moved to src/lib/news.ts so /api/search can fold
// the SAME cached instance («خبرها» search index) — this route keeps
// the exact contract: same cache key news:v1, same 15-min TTL, same
// response shape { ok, items, fetchedAt }.
export async function GET() {
  try {
    const items = await getNewsFeed();
    return NextResponse.json({ ok: true, items, fetchedAt: new Date().toISOString() });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "news fetch failed", items: [] },
      { status: 502 }
    );
  }
}
