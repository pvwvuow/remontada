// ------------------------------------------------------------------
// Remontada — /api/team-squad/[id]
// Team squad («ترکیب تیم») from FotMob's live-returned data/teams
// endpoint (cycle-70). The squad is fetched lazily by the team page so
// the first paint stays fast; squad: null with ok: true when the source
// has no squad (national squads / missing payload) so the UI can hide
// the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamSquad } from "@/lib/fotmob";

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
    const squad = await getTeamSquad(teamId);
    return NextResponse.json({ ok: true, squad });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت ترکیب تیم ناموفق بود." },
      { status: 502 }
    );
  }
}
