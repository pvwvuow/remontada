// ------------------------------------------------------------------
// Remontada — /api/team-top-players/[id]
// Team key players («بازیکنان کلیدی فصل», cycle-95) from FotMob's
// data/teams endpoint (overview.topPlayers: three league-scoped rankings —
// rating / goals / assists, ≤3 rows each) — the SAME cached raw payload the
// squad/transfers/trophies/venue/stats/history/coaches reads use, so this
// adds zero upstream hits. Fetched lazily by the team page; topPlayers:
// null with ok: true when the source has no ranking so the UI can hide
// the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamTopPlayers } from "@/lib/fotmob";

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
    const topPlayers = await getTeamTopPlayers(teamId);
    return NextResponse.json({ ok: true, topPlayers });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت بازیکنان کلیدی ناموفق بود." },
      { status: 502 }
    );
  }
}
