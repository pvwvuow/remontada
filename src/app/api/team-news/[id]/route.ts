// ------------------------------------------------------------------
// Remontada — /api/team-news/[id]
// Club news digest («اخبار باشگاه», cycle-261) from FotMob's data/teams
// endpoint — overview.newsSummary rides the SAME cached upstream fetch as
// the squad/transfers/rumours feeds (shared `teamDataRaw:{id}` payload —
// zero extra upstream). Titles upgrade to Persian via the EXACT /api/news
// translate stage (translateBatch — 10s budget, English fallback), cached
// per team for an hour (`teamNewsFa:{id}`) so the lazy card is instant on
// repeat visits. news: null with ok: true when the source has no digest so
// the UI can hide the section (same contract as /api/team-rumours).
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamNews } from "@/lib/fotmob";
import { translateBatch } from "@/lib/news";
import { cached } from "@/lib/cache";

export const dynamic = "force-dynamic";

export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  if (!/^\d{1,10}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسه تیم نامعتبر است" }, { status: 400 });
  }
  const teamId = Number(id);
  if (!Number.isFinite(teamId) || teamId <= 0) {
    return NextResponse.json({ ok: false, error: "شناسه تیم نامعتبر است" }, { status: 400 });
  }
  try {
    const news = await getTeamNews(teamId);
    if (!news) {
      return NextResponse.json({ ok: true, news: null });
    }
    const enriched = await cached(`teamNewsFa:${teamId}`, 60 * 60_000, async () => {
      const fa = await translateBatch(news.items.map((n) => n.title.replace(/"/g, "'")));
      return news.items.map((n, i) => ({ ...n, titleFa: fa[i] || n.title }));
    });
    return NextResponse.json({ ok: true, news: { total: enriched.length, items: enriched } });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت اخبار باشگاه ناموفق بود." },
      { status: 502 }
    );
  }
}
