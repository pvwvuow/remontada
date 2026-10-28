// ------------------------------------------------------------------
// Remontada — /api/team-fixtures/[id]
// Full season fixture archive («همهٔ بازی‌های فصل») from FotMob's
// live-returned data/teams endpoint (cycle-81). Fetched lazily by the
// team page so the first paint stays fast; fixtures: null with ok: true
// when the source has no list so the UI can hide the section.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamFixturesAll } from "@/lib/fotmob";

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
    const fixtures = await getTeamFixturesAll(teamId);
    return NextResponse.json({ ok: true, fixtures });
  } catch {
    return NextResponse.json(
      { ok: false, error: "دریافت بازی‌های فصل ناموفق بود." },
      { status: 502 }
    );
  }
}
