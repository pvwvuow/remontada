// ------------------------------------------------------------------
// Remontada — /api/match-h2h/[id]
// Head-to-head history for a match (from FotMob matchDetails.content.h2h)
// Normalized: totals oriented to the CURRENT match home/away
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { cached } from "@/lib/cache";
import { teamFa, competitionFa, fotmobTeamLogo, LEAGUES } from "@/lib/leagues";
import { findTeamInStandings, getTeamSeasonFromLeague, type TeamSeasonStats } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

async function fetchJson<T>(url: string, timeoutMs = 12000): Promise<T> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": UA, Accept: "application/json" },
      signal: ctrl.signal,
      cache: "no-store",
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return (await res.json()) as T;
  } finally {
    clearTimeout(t);
  }
}

// ---------------- raw FotMob shapes (only what we need) ----------------
interface FMTeamRef { id: number; name: string }
interface FMH2HMatch {
  matchUrl?: string;
  league?: { name?: string };
  home?: FMTeamRef;
  away?: FMTeamRef;
  status?: {
    utcTime?: string;
    started?: boolean;
    finished?: boolean;
    cancelled?: boolean;
    scoreStr?: string;
    reason?: { short?: string };
  };
  time?: { utcTime?: string };
}
interface FMH2HPayload {
  header?: { teams?: FMTeamRef[] };
  content?: { h2h?: { summary?: number[]; matches?: FMH2HMatch[] } };
}

// ---------------- normalized shapes ----------------
export interface H2HTeam { id: number; name: string; fa: string; logo: string }
export interface H2HMeeting {
  id: string;
  utcTime: string;
  leagueFa: string;
  home: H2HTeam;
  away: H2HTeam;
  scoreStr?: string;
  winner: "home" | "away" | "draw" | null; // relative to that meeting's home/away
  reason?: string;
  finished: boolean;
}

function matchIdFromUrl(u?: string): string | null {
  if (!u) return null;
  const m = /#(\d+)/.exec(u);
  return m ? m[1] : null;
}

function normTeam(t: FMTeamRef | undefined): H2HTeam | null {
  if (!t || !t.id || !t.name) return null;
  return { id: t.id, name: t.name, fa: teamFa(t.name), logo: fotmobTeamLogo(t.id) };
}

function parseScore(s?: string): [number, number] | null {
  if (!s) return null;
  const m = /^\s*(\d+)\s*-\s*(\d+)\s*$/.exec(s);
  return m ? [Number(m[1]), Number(m[2])] : null;
}

// h2h league entries are ambiguous by name alone (e.g. "Serie A" BRA vs ITA)
// → disambiguate via FotMob league id when it matches one of our known leagues
function leagueFaName(name: string | undefined, leagueId?: string | number): string {
  if (leagueId != null) {
    const lg = LEAGUES.find((l) => String(l.fotmobId) === String(leagueId));
    if (lg) return lg.faName;
  }
  return competitionFa(name || "");
}

export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!/^\d+$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسه مسابقه نامعتبر است." }, { status: 400 });
  }

  try {
    const raw = await cached<FMH2HPayload>(`fotmob:matchdetails:${id}`, 3 * 60_000, () =>
      fetchJson<FMH2HPayload>(`https://www.fotmob.com/api/data/matchDetails?matchId=${id}`)
    );

    const teams = raw.header?.teams || [];
    const home = normTeam(teams[0]);
    const away = normTeam(teams[1]);
    if (!home || !away) {
      return NextResponse.json({ ok: false, error: "تیم‌های مسابقه یافت نشد." }, { status: 404 });
    }

    const h2h = raw.content?.h2h;
    const allMatches = h2h?.matches || [];

    const meetings: H2HMeeting[] = [];
    const seen = new Set<string>();
    for (const fm of allMatches) {
      const st = fm.status || {};
      const mid = matchIdFromUrl(fm.matchUrl);
      if (!mid || seen.has(mid) || mid === id) continue; // skip dupes + the current match itself
      const mh = normTeam(fm.home);
      const ma = normTeam(fm.away);
      if (!mh || !ma) continue;
      seen.add(mid);
      const score = parseScore(st.scoreStr);
      let winner: H2HMeeting["winner"] = null;
      if (score && st.finished) {
        winner = score[0] > score[1] ? "home" : score[0] < score[1] ? "away" : "draw";
      }
      meetings.push({
        id: mid,
        utcTime: st.utcTime || fm.time?.utcTime || "",
        leagueFa: leagueFaName(fm.league?.name, fm.league?.id),
        home: mh,
        away: ma,
        scoreStr: st.scoreStr,
        winner,
        reason: st.reason?.short,
        finished: Boolean(st.finished),
      });
    }

    // newest first (input is roughly sorted, but be safe)
    meetings.sort((a, b) => (b.utcTime || "").localeCompare(a.utcTime || ""));

    const results = meetings.filter((m) => m.finished && m.winner);
    const upcoming = meetings.filter((m) => !m.finished).slice(0, 4);

    // totals oriented to the CURRENT match: homeWins = wins of the current home team
    let homeWins = 0, draws = 0, awayWins = 0;
    for (const m of results) {
      if (m.winner === "draw") {
        draws++;
        continue;
      }
      const winnerTeamId = m.winner === "home" ? m.home.id : m.away.id;
      if (winnerTeamId === home.id) homeWins++;
      else awayWins++;
    }

    // ---- season stats comparison of the two teams (best-effort) ----
    // leagueKey: standings lookup per team (works even when the two teams
    // play in different leagues, e.g. cup or European fixtures)
    const seasonFor = async (teamId: number): Promise<TeamSeasonStats | null> => {
      const row = await findTeamInStandings(teamId).catch(() => null);
      if (!row?.leagueKey) return null;
      return getTeamSeasonFromLeague(row.leagueKey, teamId).catch(() => null);
    };
    const [homeSeason, awaySeason] = await Promise.all([seasonFor(home.id), seasonFor(away.id)]);
    const comparison = homeSeason || awaySeason
      ? { home: { ...home, season: homeSeason }, away: { ...away, season: awaySeason } }
      : null;

    return NextResponse.json({
      ok: true,
      matchId: id,
      home,
      away,
      totals: { homeWins, draws, awayWins, played: results.length },
      comparison,
      results: results.slice(0, 8),
      upcoming,
      hasData: meetings.length > 0,
      fetchedAt: new Date().toISOString(),
    });
  } catch {
    return NextResponse.json({ ok: false, error: "دریافت سابقه رو در رو ناموفق بود." }, { status: 502 });
  }
}
