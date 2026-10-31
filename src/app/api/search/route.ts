import { NextRequest, NextResponse } from "next/server";
import { searchTeams, searchPlayers, searchLeagues, searchCoaches } from "@/lib/fotmob";
import { searchNews } from "@/lib/news";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const q = (req.nextUrl.searchParams.get("q") || "").trim();
  if (q.length < 2) {
    // fix cycle-37: say the minimum length explicitly instead of silently
    // answering an empty result set — ok:true and results:[] stay for
    // backwards compatibility with existing clients
    return NextResponse.json({
      ok: true,
      results: [],
      players: [],
      // cycle-200 additive: the shape always carries the field (empty here)
      leagues: [],
      // cycle-202 additive: the news index joins the same way — warm-only
      // (never triggers the producer), empty here
      news: [],
      // cycle-256 additive: the coach seed joins the same way, empty here
      coaches: [],
      message: "برای جستجو حداقل ۲ کاراکتر وارد کنید",
    });
  }
  try {
    // cycle-166: players join the search — the «آقای گل» pool per league
    // (the scorer blocks getTeamIndex always had in hand) rides a NEW
    // `players` field so existing clients reading `results` stay untouched
    // cycle-200: competitions join the same way — a NEW `leagues` field
    // folded from the in-memory catalog (zero upstream fetches)
    // cycle-202: news joins the same way — a NEW `news` field folded from
    // the cached news:v1 feed (warm-only read, zero fresh upstream calls)
    // cycle-256: coaches join the same way — a NEW `coaches` field folded
    // from the live-probed static seed (zero upstream fetches)
    const [results, players, news] = await Promise.all([searchTeams(q), searchPlayers(q), searchNews(q)]);
    const leagues = searchLeagues(q);
    const coaches = searchCoaches(q);
    return NextResponse.json({ ok: true, results, players, leagues, news, coaches });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "search failed" },
      { status: 502 }
    );
  }
}
