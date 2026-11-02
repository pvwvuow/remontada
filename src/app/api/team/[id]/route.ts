// ------------------------------------------------------------------
// Remontada — /api/team/[id]
// Team profile assembled from FotMob daily feed (recent + upcoming),
// league standings lookup (rank / points) and — since cycle 10 — full
// season stats computed from the team's league fixtures (home/away
// splits, averages, clean sheets, biggest win/loss). Team endpoint is
// gone from FotMob, so we aggregate reliable sources instead.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import {
  getMatchesByDate,
  findTeamInStandings,
  getTeamSeasonFromLeague,
  getTeamOfficialColor,
  getTeamFixturesAll,
  dateKeyToYYYYMMDD,
  type NormMatch,
  type NormFixture,
  type TeamRowInfo,
  type TeamSeasonStats,
  type TeamSeasonFixture,
} from "@/lib/fotmob";
import { LEAGUES, fotmobTeamLogo } from "@/lib/leagues";

/** Pre-match context for the team page panel (cycle 18): opponent form + season stats */
export interface PreMatchInfo {
  matchId: string;
  kickoff: string;
  venue: "home" | "away";
  opponent: { id: number; name: string; fa: string; logo: string };
  oppRow: TeamRowInfo | null;       // opponent standings row (null for leagues w/o standings)
  oppSeason: TeamSeasonStats | null; // opponent season stats (null for e.g. Persian Gulf league)
}

export const dynamic = "force-dynamic";

type MatchRow = NormMatch & { round?: string };

/** Convert a season fixture into the NormMatch shape the UI renders. */
function fixtureToRow(f: NormFixture, lg: (typeof LEAGUES)[number]): MatchRow {
  return {
    id: f.id,
    leagueId: lg.fotmobId,
    leagueName: lg.enName,
    leagueFa: lg.faName,
    leagueCcode: lg.ccode3,
    utcTime: f.utcTime,
    started: f.started,
    finished: f.finished,
    cancelled: f.cancelled,
    live: false,
    home: f.home,
    away: f.away,
    round: f.round,
  };
}

export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  const teamId = Number(id);
  if (!Number.isFinite(teamId) || teamId <= 0 || !/^\d{1,10}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسه تیم نامعتبر است" }, { status: 400 });
  }

  // past 3 days .. next 10 days (all cached per date upstream)
  const OFFSETS = [-3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

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
            if (!hintLeagueId) hintLeagueId = g.leagueId;
          }
        }
      }
    }

    if (teamMatches.length === 0) {
      // cycle-390: the NT-aware fallback (the 386 F2 update-scale decision).
      // The -3..+10 day-feed window is club-shaped; a national team between
      // tournaments (probed: Iran 6711 — nothing in the window while the
      // upstream fixture list carries 9 results + 4 upcoming incl. the 2027
      // Asian Cup) used to hit the honest 404 and lose the whole team
      // surface. The upstream team fixture archive (the SAME cached
      // data/teams payload team-fixtures reads — zero extra upstream hit)
      // now fills the window-shaped gap: nearest finished results + next
      // upcoming rows ride the exact same pipeline below (name/logo, recent
      // merge, prematch). Teams with NOTHING upstream keep the honest 404 —
      // the contract only widens, never fakes.
      const all = await getTeamFixturesAll(teamId).catch(() => null);
      if (!all || all.total === 0) {
        return NextResponse.json({ ok: false, error: "بازی‌ای برای این تیم در بازه‌ی نزدیک یافت نشد" }, { status: 404 });
      }
      const fromSeason = (f: TeamSeasonFixture): MatchRow => ({
        id: String(f.id),
        leagueId: 0, // no league context upstream — standings/prematch degrade honestly
        leagueName: "",
        leagueFa: f.tournamentFa,
        leagueCcode: "",
        utcTime: f.utcTime,
        started: f.started,
        finished: f.finished,
        cancelled: false,
        live: false,
        home: { id: f.home.id, name: f.home.name, fa: f.home.fa, short: f.home.name, score: f.home.score, logo: fotmobTeamLogo(f.home.id) },
        away: { id: f.away.id, name: f.away.name, fa: f.away.fa, short: f.away.name, score: f.away.score, logo: fotmobTeamLogo(f.away.id) },
      });
      teamMatches.push(
        ...all.results.slice(0, 6).map(fromSeason), // finished, newest first — same shape feedRecent wants
        ...all.upcoming.slice(0, 8).map(fromSeason),
      );
    }

    // de-dup by match id, sort by time
    const seen = new Set<string>();
    const unique = teamMatches.filter((m) => (seen.has(m.id) ? false : (seen.add(m.id), true)));
    unique.sort((a, b) => (a.utcTime || "").localeCompare(b.utcTime || ""));

    const feedRecent = unique
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

    // ---- cycle-54 fix: league-context selection ----
    // Bug (cycle-53 finding): hintLeagueId is the league of the FIRST feed match
    // in the -3..+10d window — often a cup not present in LEAGUES (e.g. League
    // Cup), so findTeamInStandings' hint boost was a no-op and its candidate
    // order (LEAGUES array, UCL first) handed back the UCL row for any team
    // that also plays in Europe. Arsenal then showed UCL rank/season/recent
    // while their PL context (rank 2, next fixture PL) was missing entirely.
    // Fix: prefer the NEXT fixture's league (the competition the user is
    // heading into), then the first feed match's league. Accept a standings
    // row only if it actually came from one of the hinted leagues; otherwise
    // fall back to the array-order row (old behavior) and finally to the raw
    // hint → LEAGUES mapping (leagues without standings rows).
    const resolveLeagueContext = async (): Promise<{ row: TeamRowInfo | null; leagueKey?: string }> => {
      const hints = [...new Set([upcoming[0]?.leagueId, hintLeagueId].filter(
        (x): x is number => typeof x === "number",
      ))];
      let firstRow: TeamRowInfo | null = null;
      for (const h of hints) {
        const r = await findTeamInStandings(teamId, h).catch(() => null);
        if (!r) continue;
        if (!firstRow) firstRow = r;
        const hintedKey = LEAGUES.find((l) => l.fotmobId === h)?.key;
        if (hintedKey && r.leagueKey === hintedKey) return { row: r, leagueKey: hintedKey };
      }
      if (firstRow) return { row: firstRow, leagueKey: firstRow.leagueKey };
      return { row: null, leagueKey: undefined };
    };
    const ctx = await resolveLeagueContext();
    const row = ctx.row;

    // season stats from the team's league fixtures (best-effort too).
    // leagueKey: prefer standings row, fall back to the daily-feed league id.
    let leagueKey = ctx.leagueKey ?? row?.leagueKey;
    if (!leagueKey && hintLeagueId) {
      leagueKey = LEAGUES.find((l) => l.fotmobId === hintLeagueId)?.key;
    }
    const season = leagueKey
      ? await getTeamSeasonFromLeague(leagueKey, teamId).catch(() => null)
      : null;

    // merge season fixtures into the recent list (season rows carry round labels)
    const byId = new Map<string, MatchRow>();
    if (season) {
      const lgCfg = LEAGUES.find((l) => l.key === season.leagueKey);
      if (lgCfg) for (const f of season.fixtures) byId.set(f.id, fixtureToRow(f, lgCfg));
    }
    for (const m of feedRecent) {
      const prev = byId.get(m.id);
      if (!prev) byId.set(m.id, { ...m });
    }
    const recent = [...byId.values()]
      .sort((a, b) => (b.utcTime || "").localeCompare(a.utcTime || ""))
      .slice(0, 10);

    // ---- pre-match context (cycle 18): opponent of the next fixture ----
    // best-effort only — a failure here must never fail the whole request
    let prematch: PreMatchInfo | null = null;
    const nextMatch = upcoming[0];
    if (nextMatch) {
      try {
        const isHome = nextMatch.home.id === teamId;
        const opp = isHome ? nextMatch.away : nextMatch.home;
        const oppRow = await findTeamInStandings(opp.id, nextMatch.leagueId).catch(() => null);
        // league of the fixture itself first, then opponent's standings league
        const nextLeagueKey =
          LEAGUES.find((l) => l.fotmobId === nextMatch.leagueId)?.key || oppRow?.leagueKey;
        const oppSeason = nextLeagueKey
          ? await getTeamSeasonFromLeague(nextLeagueKey, opp.id).catch(() => null)
          : null;
        prematch = {
          matchId: nextMatch.id,
          kickoff: nextMatch.utcTime,
          venue: isHome ? "home" : "away",
          opponent: { id: opp.id, name: opp.name, fa: opp.fa, logo: opp.logo },
          oppRow,
          oppSeason,
        };
      } catch {
        prematch = null;
      }
    }

    return NextResponse.json({
      ok: true,
      team: { id: teamId, name: teamName.name, fa: teamName.fa, logo },
      // cycle-350: the club's OFFICIAL color (overview.teamColors /
      // details.teamColor, strict-hex guarded in lib, honest-absence) —
      // rendered as the accent dot beside the team name, the team-page
      // sibling of the league-page dot from cycle-346.
      teamColor: await getTeamOfficialColor(teamId).catch(() => null),
      standings: row,
      season,
      live,
      recent,
      upcoming,
      prematch,
      fetchedAt: new Date().toISOString(),
    });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "خطا در دریافت اطلاعات تیم" },
      { status: 502 }
    );
  }
}
