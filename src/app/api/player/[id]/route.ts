// ------------------------------------------------------------------
// Remontada — /api/player/[id]
// Player profile + season stats + recent appearances from FotMob
// playerData. Guards (cycle-17 finding): FotMob answers HTTP 200 for
// unknown ids with a `null` body or {error:true} → real 404 here;
// upstream/network failures → 502.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getPlayerData, PlayerNotFoundError } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  if (!/^\d{3,12}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسه بازیکن نامعتبر است" }, { status: 400 });
  }
  try {
    const player = await getPlayerData(id);
    return NextResponse.json({ ok: true, player });
  } catch (err) {
    if (err instanceof PlayerNotFoundError) {
      return NextResponse.json({ ok: false, error: "بازیکن یافت نشد." }, { status: 404 });
    }
    console.error("[api/player]", err);
    return NextResponse.json(
      { ok: false, error: "خطا در دریافت اطلاعات بازیکن" },
      { status: 502 }
    );
  }
}
