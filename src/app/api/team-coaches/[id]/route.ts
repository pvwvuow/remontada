// ------------------------------------------------------------------
// Remontada — /api/team-coaches/[id]
// Team coach history («تاریخچهٔ نیمکت», cycle-91) from FotMob's
// data/teams endpoint (history.coachHistory) — the SAME cached raw
// payload the squad/transfers/trophies/venue/stats/history reads use,
// so this adds zero upstream hits. Fetched lazily by the team page so
// the first paint stays fast; coaches: null with ok: true when the
// source has no list so the UI can hide the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamCoachHistory } from "@/lib/fotmob";

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
    const coaches = await getTeamCoachHistory(teamId);
    return NextResponse.json({ ok: true, coaches });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت تاریخچهٔ نیمکت ناموفق بود." },
      { status: 502 }
    );
  }
}
