// ------------------------------------------------------------------
// Remontada — /api/team-rumours/[id]
// Team transfer RUMOUR feed («شایعات انتقال», cycle-260) from FotMob's
// data/teams endpoint. Rides the SAME cached upstream fetch as the
// cycle-71 transfers feed (transfers.allRumours[] on the shared
// `teamDataRaw:{id}` payload — zero extra upstream). rumours: null with
// ok: true when the source has no feed so the UI can hide the section
// (same contract as /api/team-transfers).
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamRumours } from "@/lib/fotmob";

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
    const rumours = await getTeamRumours(teamId);
    return NextResponse.json({ ok: true, rumours });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت شایعات انتقال تیم ناموفق بود." },
      { status: 502 }
    );
  }
}
