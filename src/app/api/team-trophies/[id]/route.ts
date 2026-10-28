// ------------------------------------------------------------------
// Remontada — /api/team-trophies/[id]
// Team trophy cabinet («گنجهٔ افتخارات») from FotMob's live-returned
// data/teams endpoint (cycle-72). Fetched lazily by the team page so
// the first paint stays fast; trophies: null with ok: true when the
// source has no list so the UI can hide the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamTrophies } from "@/lib/fotmob";

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
    const trophies = await getTeamTrophies(teamId);
    return NextResponse.json({ ok: true, trophies });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت گنجهٔ افتخارات ناموفق بود." },
      { status: 502 }
    );
  }
}
