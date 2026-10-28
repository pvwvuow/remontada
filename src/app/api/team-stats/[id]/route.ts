// ------------------------------------------------------------------
// Remontada — /api/team-stats/[id]
// Season stat leaders («آمار برتر فصل») from FotMob's live-returned
// data/teams endpoint (cycle-76). Fetched lazily by the team page so
// the first paint stays fast; stats: null with ok: true when the
// source has no stats so the UI can hide the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamStats } from "@/lib/fotmob";

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
    const stats = await getTeamStats(teamId);
    return NextResponse.json({ ok: true, stats });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت آمار تیم ناموفق بود." },
      { status: 502 }
    );
  }
}
