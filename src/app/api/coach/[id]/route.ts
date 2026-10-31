// ------------------------------------------------------------------
// Remontada — /api/coach/[id]
// Coach profile (current bench record + stints + honours) from FotMob
// playerData (the coach id-space rides the player endpoint — cycle-255
// probe: Xabi Alonso 30889). Guards mirror /api/player/[id]: unknown or
// non-coach ids → real 404; upstream/network failures → 502.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getCoachData, CoachNotFoundError } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  if (!/^\d{3,12}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسه مربی نامعتبر است" }, { status: 400 });
  }
  try {
    const coach = await getCoachData(id);
    return NextResponse.json({ ok: true, coach });
  } catch (err) {
    if (err instanceof CoachNotFoundError) {
      return NextResponse.json({ ok: false, error: "مربی یافت نشد." }, { status: 404 });
    }
    console.error("[api/coach]", err);
    return NextResponse.json(
      { ok: false, error: "خطا در دریافت اطلاعات مربی" },
      { status: 502 }
    );
  }
}
