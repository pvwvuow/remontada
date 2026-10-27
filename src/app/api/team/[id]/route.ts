// ------------------------------------------------------------------
// Remontada — /api/team/[id]
// Team profile assembled from FotMob daily feed (recent + upcoming)
// and league standings lookup (rank / points). Team endpoint is gone
// from FotMob, so we aggregate reliable sources instead.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import {
  getMatchesByDate,
  findTeamInStandings,
  dateKeyToYYYYMMDD,
  type NormMatch,
} from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  const teamId = Number(id);
  if (!Number.isFinite(teamId) || teamId <= 0 || !/^\d{1,10}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسه تیم نامعتبر است" }, { status: 400 });
  }

  // past 3 days .. next 10 days (all cached per date upstream)
  const OFFSETS = [-3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  const now = Date.now();

  try {
    const results = await Promise.allSettled(OFFSETS.map((o) => getMatchesByDate(dateKeyToYYYYMMDD(o))));
    const teamMatches: NormMatch[] = [];
    let hintLeagueId: number | undefined;

    for (const r of results) {
      if (r.status !== "fulfilled") continue;
      for (const g of r.value.groups) {
        for (const m of g.matches) {
          if (m.home.id === teamId || m.away.id === teamId) {
            teamMatches.push(m);
            if (!hintLeagueId && (m.live || m.finished)) hintLeagueId = g.leagueId;
            if (!hintLeagueId) hintLeagueId = g.leagueId;
          }
        }
      }
    }

    if (teamMatches.length === 0) {
      return NextResponse.json({ ok: false, error: "بازی‌ای برای این تیم در بازه‌ی نزدیک یافت نشد" }, { status: 404 });
    }

    // de-dup by match id, sort by time
    const seen = new Set<string>();
    const unique = teamMatches.filter((m) => (seen.has(m.id) ? false : (seen.add(m.id), true)));
    unique.sort((a, b) => (a.utcTime || "").localeCompare(b.utcTime || ""));

    const recent = unique
      .filter((m) => m.finished && !m.cancelled)
      .slice(-6)
      .reverse();
    const upcoming = unique
      .filter((m) => !m.started && !m.cancelled)
      .slice(0, 8);
    const live = unique.filter((m) => m.live);

    const first = unique[0];
    const teamName = first.home.id === teamId ? first.home : first.away;
    const logo = teamName.logo;

    // standings lookup (best-effort; never fails the request)
    const row = await findTeamInStandings(teamId, hintLeagueId).catch(() => null);

    return NextResponse.json({
      ok: true,
      team: { id: teamId, name: teamName.name, fa: teamName.fa, logo },
      standings: row,
      live,
      recent,
      upcoming,
      fetchedAt: new Date().toISOString(),
    });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "خطا در دریافت اطلاعات تیم" },
      { status: 502 }
    );
  }
}
