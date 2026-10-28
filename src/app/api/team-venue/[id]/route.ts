// ------------------------------------------------------------------
// Remontada — /api/team-venue/[id]
// Team home ground («ورزشگاه خانه») from FotMob's live-returned
// data/teams endpoint (cycle-75). Fetched lazily by the team page so
// the first paint stays fast; venue: null with ok: true when the
// source has no venue so the UI can hide the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamVenue } from "@/lib/fotmob";

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
    const venue = await getTeamVenue(teamId);
    return NextResponse.json({ ok: true, venue });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت اطلاعات ورزشگاه ناموفق بود." },
      { status: 502 }
    );
  }
}
