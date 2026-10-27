import { NextRequest, NextResponse } from "next/server";
import { searchTeams } from "@/lib/fotmob";

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
      message: "برای جستجو حداقل ۲ کاراکتر وارد کنید",
    });
  }
  try {
    const results = await searchTeams(q);
    return NextResponse.json({ ok: true, results });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "search failed" },
      { status: 502 }
    );
  }
}
