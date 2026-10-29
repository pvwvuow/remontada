import { NextRequest, NextResponse } from "next/server";
import { searchTeams, searchPlayers } from "@/lib/fotmob";

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
      message: "برای جستجو حداقل ۲ کاراکتر وارد کنید",
    });
  }
  try {
    // cycle-166: players join the search — the «آقای گل» pool per league
    // (the scorer blocks getTeamIndex always had in hand) rides a NEW
    // `players` field so existing clients reading `results` stay untouched
    const [results, players] = await Promise.all([searchTeams(q), searchPlayers(q)]);
    return NextResponse.json({ ok: true, results, players });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "search failed" },
      { status: 502 }
    );
  }
}
