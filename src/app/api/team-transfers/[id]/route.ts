// ------------------------------------------------------------------
// Remontada — /api/team-transfers/[id]
// Team transfer feed («بازار انتقال‌ها») from FotMob's live-returned
// data/teams endpoint (cycle-71). Fetched lazily by the team page so
// the first paint stays fast; transfers: null with ok: true when the
// source has no feed so the UI can hide the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamTransfers } from "@/lib/fotmob";

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
    const transfers = await getTeamTransfers(teamId);
    return NextResponse.json({ ok: true, transfers });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت بازار انتقال‌های تیم ناموفق بود." },
      { status: 502 }
    );
  }
}
