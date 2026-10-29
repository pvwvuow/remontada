// ------------------------------------------------------------------
// Remontada — /api/team-difficulty/[id]
// Fixture difficulty («سختی بازی‌های پیش‌رو», cycle-112) from FotMob's
// data/teams endpoint (overview.fixtureDifficulty: the difficulty widget
// payload — an overall verdict enum + the next fixtures each with a small
// int difficulty rating) — the SAME cached raw payload the squad/transfers/
// trophies/venue/stats/history/coaches/top-players reads use, so this adds
// zero upstream hits. Fetched lazily by the team page; difficulty: null
// with ok: true when the source has no widget so the UI can hide the
// section (same contract as team-top-players, cycle-95).
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamFixtureDifficulty } from "@/lib/fotmob";

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
    const difficulty = await getTeamFixtureDifficulty(teamId);
    return NextResponse.json({ ok: true, difficulty });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت سختی بازی‌های پیش‌رو ناموفق بود." },
      { status: 502 }
    );
  }
}
