// ------------------------------------------------------------------
// Remontada — /api/team-last-lineup/[id]
// «آخرین ترکیب» (cycle-120): the XI that actually started the team's
// most recent played match, from FotMob's data/teams endpoint
// (overview.lastLineupStats — probed live, uniform across probed clubs).
// The SAME cached raw payload the squad/transfers/trophies/venue/stats/
// history/coaches/top-players and fixture-difficulty reads use, so this
// adds zero upstream hits. lastLineup: null with ok: true when the source
// has no block so the UI can hide the section (same contract as
// team-difficulty, cycle-112).
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamLastLineup } from "@/lib/fotmob";

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
    const lastLineup = await getTeamLastLineup(teamId);
    return NextResponse.json({ ok: true, lastLineup });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت آخرین ترکیب ناموفق بود." },
      { status: 502 }
    );
  }
}
