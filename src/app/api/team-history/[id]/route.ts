// ------------------------------------------------------------------
// Remontada — /api/team-history/[id]
// Per-season league finishes («سوابق لیگ») from FotMob's live-returned
// data/teams endpoint (cycle-80). Fetched lazily by the team page so
// the first paint stays fast; history: null with ok: true when the
// source has no ranks so the UI can hide the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamSeasonHistory } from "@/lib/fotmob";

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
    const history = await getTeamSeasonHistory(teamId);
    return NextResponse.json({ ok: true, history });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت سوابق لیگ ناموفق بود." },
      { status: 502 }
    );
  }
}
