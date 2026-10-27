// ------------------------------------------------------------------
// Remontada — server-side football data layer
// Primary:  FotMob (unofficial, keyless)
// Fallback: ESPN public APIs
// ------------------------------------------------------------------
import { LEAGUES, teamFa, fotmobTeamLogo, competitionFa } from "./leagues";
import { cached } from "./cache";
import { faDigits } from "./format";

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
    if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
    return (await res.json()) as T;
  } finally {
    clearTimeout(t);
  }
}

// ---------------- Normalized types ----------------
export interface NormMatch {
  id: string;
  leagueId: number;
  leagueName: string;
  leagueFa: string;
  leagueCcode: string;
  utcTime: string;         // ISO
  started: boolean;
  finished: boolean;
  cancelled: boolean;
  live: boolean;
  minute?: string;         // "27'" | "HT" | "FT"
  statusText?: string;
  home: { id: number; name: string; fa: string; short: string; score: number | null; logo: string };
  away: { id: number; name: string; fa: string; short: string; score: number | null; logo: string };
}

export interface LeagueGroup {
  leagueId: number;
  leagueName: string;
  leagueFa: string;
  ccode: string;
  matches: NormMatch[];
}

export interface StandingsRow {
  idx: number;
  teamId: number;
  name: string;
  fa: string;
  logo: string;
  played: number; wins: number; draws: number; losses: number;
  goalsFor: number; goalsAgainst: number; gd: number; pts: number;
  qualColor?: string;
  form?: ("W" | "D" | "L")[];   // last 5 league results, oldest → newest (from season fixtures)
}

export interface ScorerEntry {
  rank: number;
  name: string;
  team: string;
  teamId: number;
  goals: number;
  ccode?: string;
  assists?: number;   // from the league "Assists" category (matched by player id)
  gPlusA?: number;    // "Goals + Assists"
  xg?: number;        // "Expected goals (xG)"
  rating?: number;    // "FotMob rating"
  minutes?: number;   // "Minutes played" (enables minutes-per-goal)
}

export interface AssistEntry {
  rank: number;
  name: string;
  team: string;
  teamId: number;
  assists: number;
}

export interface StandingsData {
  leagueKey: string;
  leagueFa: string;
  season: string;
  rows: StandingsRow[];
  scorers: ScorerEntry[];
  assists: AssistEntry[];
  updatedAt: string;
}

// ---------------- FotMob: daily matches ----------------
interface FotMobMatches {
  leagues: {
    ccode: string; id: number; name: string;
    matches: FotMobMatch[];
  }[];
}

interface FotMobMatch {
  id: number;
  leagueId: number;
  home: { id: number; score?: number; name: string; shortName?: string; longName?: string };
  away: { id: number; score?: number; name: string; shortName?: string; longName?: string };
  statusId: number;
  status: {
    utcTime: string; started: boolean; finished: boolean; cancelled: boolean;
    liveTime?: { short?: string; long?: string; ongoing?: boolean };
    reason?: { short?: string; long?: string };
  };
}

function normalizeFotMobMatches(raw: FotMobMatches): LeagueGroup[] {
  const groups: LeagueGroup[] = [];
  for (const lg of raw.leagues || []) {
    const matches: NormMatch[] = (lg.matches || []).map((m) => {
      const live = m.statusId === 2 || (!!m.status?.liveTime?.ongoing && !m.status?.finished);
      const halfTime = m.statusId === 10;
      const minute = live
        ? (m.status?.liveTime?.short || "در جریان")
        : halfTime ? "بین دو نیمه" : undefined;
      const scoreH = typeof m.home?.score === "number" ? m.home.score : null;
      const scoreA = typeof m.away?.score === "number" ? m.away.score : null;
      return {
        id: String(m.id),
        leagueId: lg.id,
        leagueName: lg.name,
        leagueFa: competitionFa(lg.name, lg.ccode),
        leagueCcode: lg.ccode,
        utcTime: m.status?.utcTime || "",
        started: !!m.status?.started,
        finished: !!m.status?.finished,
        cancelled: !!m.status?.cancelled,
        live,
        minute,
        statusText: m.status?.reason?.long,
        home: {
          id: m.home?.id ?? 0,
          name: m.home?.name || "",
          fa: teamFa(m.home?.name, m.home?.longName, m.home?.shortName),
          short: m.home?.shortName || m.home?.name || "",
          score: scoreH,
          logo: fotmobTeamLogo(m.home?.id ?? 0),
        },
        away: {
          id: m.away?.id ?? 0,
          name: m.away?.name || "",
          fa: teamFa(m.away?.name, m.away?.longName, m.away?.shortName),
          short: m.away?.shortName || m.away?.name || "",
          score: scoreA,
          logo: fotmobTeamLogo(m.away?.id ?? 0),
        },
      };
    });
    if (matches.length === 0) continue;
    groups.push({
      leagueId: lg.id,
      leagueName: lg.name,
      leagueFa: competitionFa(lg.name, lg.ccode),
      ccode: lg.ccode,
      matches,
    });
  }
  return groups;
}

const IMPORTANT_LEAGUE_PATTERNS: { re: RegExp; cc?: string }[] = [
  { re: /efl cup|carabao/i }, { re: /fa cup/i, cc: "ENG" }, { re: /copa del rey/i, cc: "ESP" },
  { re: /coppa italia/i, cc: "ITA" }, { re: /dfb pokal/i, cc: "GER" }, { re: /supercopa/i },
  { re: /community shield/i },
  { re: /afc champions|copa libertadores|caf champions/i },
  { re: /saudi/i }, { re: /eredivisie/i }, { re: /liga portugal|primeira/i },
  { re: /super lig/i, cc: "TUR" }, { re: /mls/i }, { re: /brasileir/i }, { re: /liga mx/i },
];

function groupPriority(g: LeagueGroup): number {
  // our configured leagues come first, in config order (UCL, PL, LaLiga, ...)
  const byId = LEAGUES.findIndex((l) => l.fotmobId === g.leagueId);
  if (byId >= 0) return byId;
  const n = g.leagueName.toLowerCase();
  const c = g.ccode.toUpperCase();
  // English Premier League exact-name match (avoid Tanzania "Premier League")
  if (n === "premier league" && c === "ENG") return 7;
  // UEFA competitions
  if (n.includes("uefa champions league")) return 8;
  if (n.includes("uefa europa league")) return 9;
  if (n.includes("uefa europa conference")) return 10;
  if (/persian gulf|azadegan/i.test(n)) return 11;
  for (let i = 0; i < IMPORTANT_LEAGUE_PATTERNS.length; i++) {
    const p = IMPORTANT_LEAGUE_PATTERNS[i];
    if (p.cc && p.cc !== c) continue;
    if (p.re.test(n)) return 20 + i;
  }
  return 100;
}

export async function getMatchesByDate(dateYYYYMMDD: string): Promise<{ groups: LeagueGroup[]; fetchedAt: string; source: string }> {
  // Live days need short TTL; far days can cache longer
  const isTodayOrLiveDay = dateYYYYMMDD === todayInTehran();
  const ttl = isTodayOrLiveDay ? 45_000 : 10 * 60_000;
  return cached(`matches:${dateYYYYMMDD}`, ttl, async () => {
    try {
      const raw = await fetchJson<FotMobMatches>(
        `https://www.fotmob.com/api/data/matches?date=${dateYYYYMMDD}`
      );
      const groups = normalizeFotMobMatches(raw);
      // sort groups: important leagues first, then by number of matches
      groups.sort((a, b) => {
        const pa = groupPriority(a), pb = groupPriority(b);
        if (pa !== pb) return pa - pb;
        return b.matches.length - a.matches.length;
      });
      return { groups, fetchedAt: new Date().toISOString(), source: "fotmob" };
    } catch (err) {
      // -------- ESPN fallback --------
      const groups: LeagueGroup[] = [];
      for (const lg of LEAGUES) {
        if (!lg.espnSlug) continue;
        try {
          const raw = await fetchJson<{
            leagues?: { name?: string }[];
            events?: {
              id: string; date: string;
              competitions?: {
                competitors?: {
                  homeAway: string; score?: string;
                  team?: { id: string; displayName: string; shortDisplayName?: string; logo?: string };
                }[];
              }[];
              status?: { type?: { state?: string; shortDetail?: string } };
            }[];
          }>(
            `https://site.api.espn.com/apis/site/v2/sports/soccer/${lg.espnSlug}/scoreboard?dates=${dateYYYYMMDD}`
          );
          const matches: NormMatch[] = (raw.events || []).map((ev) => {
            const comps = ev.competitions?.[0]?.competitors || [];
            const home = comps.find((c) => c.homeAway === "home");
            const away = comps.find((c) => c.homeAway === "away");
            const state = ev.status?.type?.state || "pre";
            const live = state === "in";
            const finished = state === "post";
            const h = home?.team;
            const a = away?.team;
            return {
              id: ev.id,
              leagueId: lg.fotmobId,
              leagueName: lg.enName,
              leagueFa: lg.faName,
              leagueCcode: lg.ccode3,
              utcTime: ev.date,
              started: state !== "pre",
              finished,
              cancelled: false,
              live,
              minute: live ? ev.status?.type?.shortDetail : undefined,
              statusText: ev.status?.type?.shortDetail,
              home: {
                id: Number(h?.id || 0), name: h?.displayName || "", fa: teamFa(h?.displayName, h?.shortDisplayName),
                short: h?.shortDisplayName || h?.displayName || "",
                score: home?.score != null && home.score !== "" ? Number(home.score) : null,
                logo: h?.logo || fotmobTeamLogo(h?.id || 0),
              },
              away: {
                id: Number(a?.id || 0), name: a?.displayName || "", fa: teamFa(a?.displayName, a?.shortDisplayName),
                short: a?.shortDisplayName || a?.displayName || "",
                score: away?.score != null && away.score !== "" ? Number(away.score) : null,
                logo: a?.logo || fotmobTeamLogo(a?.id || 0),
              },
            };
          });
          if (matches.length) {
            groups.push({ leagueId: lg.fotmobId, leagueName: lg.enName, leagueFa: lg.faName, ccode: lg.ccode3, matches });
          }
        } catch {
          // ignore single-league failures
        }
      }
      if (groups.length === 0) throw err;
      return { groups, fetchedAt: new Date().toISOString(), source: "espn-fallback" };
    }
  });
}

// ---------------- FotMob: standings + top scorers ----------------
interface FMStatPlayer { id: number; name: string; teamId?: number; teamName?: string; ccode?: string; value?: number; rank?: number }
interface FotMobLeague {
  details?: { name?: string; seasons?: { year?: string; active?: boolean }[] };
  table?: { data?: { table?: { all?: FotMobRow[] } } };
  fixtures?: { allMatches?: unknown[] };
  stats?: {
    players?: { header?: string; participant?: FMStatPlayer; topThree?: FMStatPlayer[] }[];
  };
}
interface FotMobRow {
  id: number; name: string; shortName?: string;
  played: number; wins: number; draws: number; losses: number;
  scoresStr?: string; goalConDiff?: number; pts: number; idx: number;
  qualColor?: string | null;
}

// Thrown when FotMob has no usable payload for a league (e.g. Persian Gulf
// Pro League returns a literal `null` body). Routes translate this into a
// friendly 503 Persian message instead of a raw engine TypeError.
export class LeagueUnavailableError extends Error {
  constructor(leagueKey: string) {
    super(`league payload unavailable: ${leagueKey}`);
    this.name = "LeagueUnavailableError";
  }
}

// Fetch + cache the (heavy) league payload once; standings & fixtures share it
async function getLeagueRaw(leagueKey: string): Promise<{ lg: (typeof LEAGUES)[number]; raw: FotMobLeague }> {
  const lg = LEAGUES.find((l) => l.key === leagueKey);
  if (!lg) throw new Error(`Unknown league: ${leagueKey}`);
  // NOTE: the null/invalid guard lives INSIDE the cached producer so an
  // unusable payload is never cached — each request retries upstream.
  const raw = await cached(`leagueRaw:${leagueKey}`, 60 * 60_000, async () => {
    const data = await fetchJson<FotMobLeague>(
      `https://www.fotmob.com/api/data/leagues?id=${lg.fotmobId}&ccode3=${lg.ccode3}&lang=en`
    );
    if (data == null || typeof data !== "object") {
      throw new LeagueUnavailableError(leagueKey);
    }
    return data;
  });
  // belt & braces: payloads cached as `null` by OLDER builds (L1/L2) must
  // also fail fast here instead of leaking a TypeError downstream
  if (raw == null || typeof raw !== "object") {
    throw new LeagueUnavailableError(leagueKey);
  }
  return { lg, raw };
}

/** Pull one stats category (participant + topThree, deduped by player id). */
function statCategory(raw: FotMobLeague, re: RegExp): FMStatPlayer[] {
  const cat = raw.stats?.players?.find?.((p) => re.test(p.header || ""));
  if (!cat) return [];
  const out: FMStatPlayer[] = [];
  if (cat.participant?.name) out.push(cat.participant);
  for (const t of cat.topThree || []) if (t?.name) out.push(t);
  const seen = new Set<number>();
  return out.filter((p) => (seen.has(p.id) ? false : (seen.add(p.id), true)));
}

export async function getStandings(leagueKey: string): Promise<StandingsData> {
  const { lg, raw } = await getLeagueRaw(leagueKey);
  const build = () => {
    // ---- team form (last 5 league results per team, one pass over season fixtures) ----
    const formMap = new Map<number, ("W" | "D" | "L")[]>();
    for (const f of (raw.fixtures?.allMatches || []) as FotMobFixture[]) {
      const st = f?.status;
      if (!st?.finished || st.cancelled) continue;
      const sm = /^\s*(\d+)\s*-\s*(\d+)\s*$/.exec(st.scoreStr || "");
      if (!sm) continue;
      const h = Number(sm[1]);
      const a = Number(sm[2]);
      const hid = Number(f.home?.id || 0);
      const aid = Number(f.away?.id || 0);
      const push = (id: number, res: "W" | "D" | "L") => {
        const arr = formMap.get(id);
        if (arr) arr.push(res);
        else formMap.set(id, [res]);
      };
      push(hid, h > a ? "W" : h < a ? "L" : "D");
      push(aid, a > h ? "W" : a < h ? "L" : "D");
    }

    const rows: StandingsRow[] = (raw.table?.[0]?.data?.table?.all || []).map((r) => {
      const [gf, ga] = (r.scoresStr || "0-0").split("-").map((x) => parseInt(x, 10) || 0);
      const form = formMap.get(r.id);
      return {
        idx: r.idx, teamId: r.id, name: r.name, fa: teamFa(r.name, r.shortName),
        logo: fotmobTeamLogo(r.id),
        played: r.played, wins: r.wins, draws: r.draws, losses: r.losses,
        goalsFor: gf, goalsAgainst: ga, gd: r.goalConDiff ?? gf - ga, pts: r.pts,
        qualColor: r.qualColor || undefined,
        ...(form && form.length > 0 ? { form: form.slice(-5) } : {}),
      };
    });
    if (rows.length === 0) throw new Error("No standings data");

    // Top scorers from stats.players (header "Top scorer" + topThree),
    // enriched with assists / G+A / xG / rating matched by player id
    const assistsMap = new Map(statCategory(raw, /^assists$/i).map((p) => [p.id, p.value ?? 0]));
    const gpaMap = new Map(statCategory(raw, /goals \+ assists/i).map((p) => [p.id, p.value ?? 0]));
    const xgMap = new Map(statCategory(raw, /^expected goals \(xg\)$/i).map((p) => [p.id, p.value ?? 0]));
    const ratingMap = new Map(statCategory(raw, /fotmob rating/i).map((p) => [p.id, p.value ?? 0]));
    const minutesMap = new Map(statCategory(raw, /^minutes played$/i).map((p) => [p.id, p.value ?? 0]));

    const scorers: StandingsData["scorers"] = [];
    const gs = raw.stats?.players?.find?.((p) => /top scorer/i.test(p.header || ""));
    const pushScorer = (s: FMStatPlayer, i: number) => {
      if (!s?.name) return;
      scorers.push({
        rank: s.rank ?? i + 1, name: s.name, team: teamFa(s.teamName, ) || s.teamName || "",
        teamId: s.teamId ?? 0, goals: s.value ?? 0, ccode: s.ccode,
        ...(assistsMap.has(s.id) ? { assists: assistsMap.get(s.id) } : {}),
        ...(gpaMap.has(s.id) ? { gPlusA: gpaMap.get(s.id) } : {}),
        ...(xgMap.has(s.id) ? { xg: xgMap.get(s.id) } : {}),
        ...(ratingMap.has(s.id) ? { rating: ratingMap.get(s.id) } : {}),
        ...(minutesMap.has(s.id) ? { minutes: minutesMap.get(s.id) } : {}),
      });
    };
    if (gs?.participant) pushScorer(gs.participant, 0);
    (gs?.topThree || []).forEach((s, i) => pushScorer(s, i));
    // de-dup by name
    const seen = new Set<string>();
    const uniqueScorers = scorers.filter((s) => (seen.has(s.name) ? false : (seen.add(s.name), true)));

    // assist leaders (participant + topThree of the "Assists" category)
    const assistEntries: AssistEntry[] = statCategory(raw, /^assists$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName, ) || p.teamName || "",
        teamId: p.teamId ?? 0, assists: p.value ?? 0,
      }))
      .sort((a, b) => b.assists - a.assists || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }))
      .slice(0, 6);

    const season = raw.details?.seasons?.find?.((s) => s.active)?.year || "";
    return {
      leagueKey, leagueFa: lg.faName, season, rows,
      scorers: uniqueScorers.slice(0, 10),
      assists: assistEntries,
      updatedAt: new Date().toISOString(),
    };
  };
  return cached(`standings:${leagueKey}`, 60 * 60_000, build);
}

// ---------------- FotMob: league fixtures (full season) ----------------
interface FotMobFixture {
  id: string;
  round?: string;
  roundName?: number | string;
  home: { id: string | number; name: string; shortName?: string };
  away: { id: string | number; name: string; shortName?: string };
  status: { utcTime: string; started: boolean; finished: boolean; cancelled: boolean; scoreStr?: string };
}

export interface NormFixture {
  id: string;
  round?: string;
  utcTime: string;
  started: boolean;
  finished: boolean;
  cancelled: boolean;
  home: { id: number; name: string; fa: string; short: string; logo: string; score: number | null };
  away: { id: number; name: string; fa: string; short: string; logo: string; score: number | null };
}

function normalizeFixture(f: FotMobFixture): NormFixture {
  // finished fixtures carry "2 - 1" in status.scoreStr
  let hs: number | null = null;
  let as: number | null = null;
  const sm = /^\s*(\d+)\s*-\s*(\d+)\s*$/.exec(f.status?.scoreStr || "");
  if (sm) {
    hs = Number(sm[1]);
    as = Number(sm[2]);
  }
  return {
    id: String(f.id),
    round: f.roundName ? (/^\d+$/.test(String(f.roundName)) ? `هفته ${f.roundName}` : String(f.roundName)) : undefined,
    utcTime: f.status?.utcTime || "",
    started: !!f.status?.started,
    finished: !!f.status?.finished,
    cancelled: !!f.status?.cancelled,
    home: {
      id: Number(f.home?.id || 0),
      name: f.home?.name || "",
      fa: teamFa(f.home?.name, f.home?.shortName),
      short: f.home?.shortName || f.home?.name || "",
      logo: fotmobTeamLogo(Number(f.home?.id || 0)),
      score: hs,
    },
    away: {
      id: Number(f.away?.id || 0),
      name: f.away?.name || "",
      fa: teamFa(f.away?.name, f.away?.shortName),
      short: f.away?.shortName || f.away?.name || "",
      logo: fotmobTeamLogo(Number(f.away?.id || 0)),
      score: as,
    },
  };
}

export interface LeagueFixturesData {
  leagueKey: string;
  leagueFa: string;
  season: string;
  upcoming: NormFixture[];
  recent: NormFixture[];
  total: number;
  stats?: LeagueStats;
}

// ---------------- league advanced stats (from full-season fixtures) ----------------
export interface LeagueTeamWinStat { teamId: number; fa: string; short: string; logo: string; wins: number }
export interface LeagueRoundStat { round: string; games: number; goals: number; avg: number }
export interface LeagueStats {
  finished: number;
  totalGoals: number;
  avgGoals: number;
  homeWins: number;
  awayWins: number;
  draws: number;
  bttsPct: number;
  topHomeWins: LeagueTeamWinStat[];
  topAwayWins: LeagueTeamWinStat[];
  topRounds: LeagueRoundStat[];
  biggestWin: { id: string; round?: string; utcTime: string; diff: number; home: NormFixture["home"]; away: NormFixture["away"] } | null;
}

/** Round label → Persian. "Regular season - 8" / "8" → «هفته ۸». */
function roundFa(round: string | undefined): string | undefined {
  if (!round) return undefined;
  const raw = String(round);
  if (/^\d+$/.test(raw)) return `هفته ${faDigits(raw)}`;
  const m = /(\d+)\s*$/.exec(raw);
  if (m) return `هفته ${faDigits(m[1])}`;
  return raw;
}

function computeLeagueStats(mapped: NormFixture[]): LeagueStats | undefined {
  const done = mapped.filter((f) => f.finished && !f.cancelled && f.home.score !== null && f.away.score !== null);
  if (done.length === 0) return undefined;

  let totalGoals = 0;
  let homeWins = 0;
  let awayWins = 0;
  let draws = 0;
  let btts = 0;
  const homeWinCnt = new Map<number, LeagueTeamWinStat>();
  const awayWinCnt = new Map<number, LeagueTeamWinStat>();
  const rounds = new Map<string, { games: number; goals: number; raw: string | undefined }>();
  let biggest: LeagueStats["biggestWin"] = null;

  for (const f of done) {
    const h = f.home.score as number;
    const a = f.away.score as number;
    const goals = h + a;
    totalGoals += goals;
    if (h > 0 && a > 0) btts += 1;

    const track = (map: Map<number, LeagueTeamWinStat>, t: NormFixture["home" | "away"]) => {
      const prev = map.get(t.id);
      if (prev) prev.wins += 1;
      else map.set(t.id, { teamId: t.id, fa: t.fa, short: t.short, logo: t.logo, wins: 1 });
    };

    if (h > a) {
      homeWins += 1;
      track(homeWinCnt, f.home);
    } else if (a > h) {
      awayWins += 1;
      track(awayWinCnt, f.away);
    } else {
      draws += 1;
    }

    // weeks/rounds
    const label = roundFa(f.round) || "—";
    const r = rounds.get(label) || { games: 0, goals: 0, raw: f.round };
    r.games += 1;
    r.goals += goals;
    rounds.set(label, r);

    // biggest win margin
    const diff = Math.abs(h - a);
    if (!biggest || diff > biggest.diff) {
      biggest = { id: f.id, round: f.round, utcTime: f.utcTime, diff, home: f.home, away: f.away };
    }
  }

  const n = done.length;
  const top = (map: Map<number, LeagueTeamWinStat>) =>
    [...map.values()].sort((x, y) => y.wins - x.wins || x.short.localeCompare(y.short)).slice(0, 5);
  const topRounds: LeagueRoundStat[] = [...rounds.entries()]
    .map(([round, r]) => ({ round, games: r.games, goals: r.goals, avg: r.games ? r.goals / r.games : 0 }))
    .sort((a, b) => b.goals - a.goals || b.avg - a.avg)
    .slice(0, 5);

  return {
    finished: n,
    totalGoals,
    avgGoals: totalGoals / n,
    homeWins,
    awayWins,
    draws,
    bttsPct: (btts / n) * 100,
    topHomeWins: top(homeWinCnt),
    topAwayWins: top(awayWinCnt),
    topRounds,
    biggestWin: biggest && biggest.diff > 0 ? biggest : null,
  };
}

export async function getLeagueFixtures(leagueKey: string): Promise<LeagueFixturesData> {
  const { lg, raw } = await getLeagueRaw(leagueKey);
  const all = (raw.fixtures?.allMatches || []) as FotMobFixture[];
  const season = raw.details?.seasons?.find?.((s) => s.active)?.year || "";
  const now = Date.now();
  const mapped = all.filter((f) => f?.id && f?.home && f?.away).map(normalizeFixture);
  const upcoming = mapped
    .filter((f) => !f.started && !f.finished && !f.cancelled && new Date(f.utcTime).getTime() >= now - 3 * 3600_000)
    .sort((a, b) => a.utcTime.localeCompare(b.utcTime))
    .slice(0, 20);
  const recent = mapped
    .filter((f) => f.finished && !f.cancelled)
    .sort((a, b) => b.utcTime.localeCompare(a.utcTime))
    .slice(0, 10);
  return {
    leagueKey,
    leagueFa: lg.faName,
    season,
    upcoming,
    recent,
    total: mapped.length,
    stats: computeLeagueStats(mapped),
  };
}

// ---------------- FotMob: team page (via league payload + daily feed) ----------------
export interface TeamRowInfo {
  rank: number;
  pts: number;
  played: number;
  gd: number;
  wins: number;
  draws: number;
  losses: number;
  leagueKey: string;
  leagueFa: string;
}

/** Find a team's standings row across our configured leagues (best-effort). */
export async function findTeamInStandings(teamId: number, hintLeagueId?: number): Promise<TeamRowInfo | null> {
  const candidates = [...LEAGUES].sort((a, b) => {
    const ah = hintLeagueId && a.fotmobId === hintLeagueId ? -1 : 0;
    const bh = hintLeagueId && b.fotmobId === hintLeagueId ? -1 : 0;
    return ah - bh;
  });
  for (const lg of candidates) {
    try {
      const st = await getStandings(lg.key);
      const row = st.rows.find((r) => r.teamId === teamId);
      if (row) {
        return {
          rank: row.idx, pts: row.pts, played: row.played, gd: row.gd,
          wins: row.wins, draws: row.draws, losses: row.losses,
          leagueKey: lg.key, leagueFa: lg.faName,
        };
      }
    } catch {
      // try next league
    }
  }
  return null;
}

// ---------------- Team season stats (from league season fixtures) ----------------
export interface TeamSeasonOpponent { id: number; name: string; fa: string; short: string; logo: string }
export interface TeamFormMatch {
  id: string;
  utcTime: string;
  round?: string;
  res: "W" | "D" | "L";
  gf: number;          // goals scored by the team
  ga: number;          // goals conceded
  venue: "home" | "away";
  opponent: TeamSeasonOpponent;
}
export interface TeamSeasonSplit { wins: number; draws: number; losses: number; gf: number; ga: number }
export interface TeamSeasonStats {
  leagueKey: string;
  leagueFa: string;
  season: string;
  played: number;
  wins: number; draws: number; losses: number;
  goalsFor: number; goalsAgainst: number;
  avgFor: number; avgAgainst: number;
  home: TeamSeasonSplit;
  away: TeamSeasonSplit;
  cleanSheets: number;
  failedToScore: number;
  form: TeamFormMatch[];                       // last 5 finished, newest first
  biggestWin: (TeamFormMatch & { diff: number }) | null;
  biggestLoss: (TeamFormMatch & { diff: number }) | null;
  fixtures: NormFixture[];                     // all finished team fixtures, newest first (cap 12)
}

/**
 * Build one team's season stats from the league's full-season fixtures.
 * Reuses the 60-min cached league payload — no extra FotMob load.
 * Works even when standings are missing (e.g. Persian Gulf Pro League).
 */
export async function getTeamSeasonFromLeague(leagueKey: string, teamId: number): Promise<TeamSeasonStats | null> {
  const { lg, raw } = await getLeagueRaw(leagueKey);
  const all = ((raw.fixtures?.allMatches || []) as FotMobFixture[])
    .filter((f) => f?.id && f?.home && f?.away)
    .map(normalizeFixture);
  const mine = all.filter((f) => (f.home.id === teamId || f.away.id === teamId) && !f.cancelled);
  if (mine.length === 0) return null;

  const done = mine
    .filter((f) => f.finished && f.home.score !== null && f.away.score !== null)
    .sort((a, b) => b.utcTime.localeCompare(a.utcTime));
  const season = raw.details?.seasons?.find?.((s) => s.active)?.year || "";

  const home: TeamSeasonSplit = { wins: 0, draws: 0, losses: 0, gf: 0, ga: 0 };
  const away: TeamSeasonSplit = { wins: 0, draws: 0, losses: 0, gf: 0, ga: 0 };
  let goalsFor = 0;
  let goalsAgainst = 0;
  let cleanSheets = 0;
  let failedToScore = 0;
  const form: TeamFormMatch[] = [];
  let biggestWin: TeamSeasonStats["biggestWin"] = null;
  let biggestLoss: TeamSeasonStats["biggestLoss"] = null;

  for (const f of done) {
    const isHome = f.home.id === teamId;
    const my = (isHome ? f.home.score : f.away.score) as number;
    const op = (isHome ? f.away.score : f.home.score) as number;
    const res: "W" | "D" | "L" = my > op ? "W" : my < op ? "L" : "D";
    const opponent = isHome ? f.away : f.home;
    const entry: TeamFormMatch = {
      id: f.id,
      utcTime: f.utcTime,
      round: f.round,
      res,
      gf: my,
      ga: op,
      venue: isHome ? "home" : "away",
      opponent: { id: opponent.id, name: opponent.name, fa: opponent.fa, short: opponent.short, logo: opponent.logo },
    };
    const bucket = isHome ? home : away;
    bucket.gf += my;
    bucket.ga += op;
    if (res === "W") bucket.wins += 1;
    else if (res === "D") bucket.draws += 1;
    else bucket.losses += 1;
    goalsFor += my;
    goalsAgainst += op;
    if (op === 0) cleanSheets += 1;
    if (my === 0) failedToScore += 1;
    if (form.length < 5) form.push(entry);
    const diff = Math.abs(my - op);
    if (res === "W" && (!biggestWin || diff > biggestWin.diff)) biggestWin = { ...entry, diff };
    if (res === "L" && (!biggestLoss || diff > biggestLoss.diff)) biggestLoss = { ...entry, diff };
  }

  const played = done.length;
  return {
    leagueKey,
    leagueFa: lg.faName,
    season,
    played,
    wins: home.wins + away.wins,
    draws: home.draws + away.draws,
    losses: home.losses + away.losses,
    goalsFor,
    goalsAgainst,
    avgFor: played ? goalsFor / played : 0,
    avgAgainst: played ? goalsAgainst / played : 0,
    home,
    away,
    cleanSheets,
    failedToScore,
    form,
    biggestWin,
    biggestLoss,
    fixtures: done.slice(0, 12),
  };
}

// ---------------- Minimal match data for SSR JSON-LD (cycle 18) ----------------
export interface MatchLdData {
  id: string;
  homeName: string;
  homeFa: string;
  awayName: string;
  awayFa: string;
  utcTime: string;
  cancelled: boolean;
  finished: boolean;
  leagueName?: string;
  stadium?: string;
  city?: string;
}

interface FMLdDetails {
  general?: {
    homeTeam?: { id?: number; name?: string };
    awayTeam?: { id?: number; name?: string };
    leagueName?: string;
    parentLeagueName?: string;
  };
  header?: {
    status?: { utcTime?: string; finished?: boolean; cancelled?: boolean };
  };
  content?: {
    matchFacts?: { infoBox?: Record<string, unknown> };
  };
}

/** sentinel cached for unknown/dead match ids so 404 spam does not hit FotMob */
const LD_NOT_FOUND = { __remontadaLdNotFound: true } as const;

/**
 * Minimal match payload for the server-rendered SportsEvent JSON-LD on
 * /match/[id]. Lightweight: one short-timeout FotMob call, cached 60s.
 * Never throws — returns null when data is unavailable/unknown
 * (FotMob answers HTTP 200 with {error:true} for dead ids, cycle-17 finding).
 */
export async function getMatchLdData(id: string): Promise<MatchLdData | null> {
  if (!/^\d{4,12}$/.test(id)) return null;
  const payload = await cached(`matchld:${id}`, 60_000, async (): Promise<MatchLdData | typeof LD_NOT_FOUND> => {
    const raw = await fetchJson<FMLdDetails>(`https://www.fotmob.com/api/data/matchDetails?matchId=${id}`, 6000).catch(() => null);
    if (!raw || typeof raw !== "object" || (raw as { error?: unknown }).error) return LD_NOT_FOUND;
    const g = raw.general;
    const home = g?.homeTeam;
    const away = g?.awayTeam;
    if (!home?.name || !away?.name) return LD_NOT_FOUND;
    const infoBox = raw.content?.matchFacts?.infoBox || {};
    const st = infoBox["Stadium"] as { name?: string; city?: string } | undefined;
    return {
      id,
      homeName: home.name,
      homeFa: teamFa(home.name),
      awayName: away.name,
      awayFa: teamFa(away.name),
      utcTime: raw.header?.status?.utcTime || "",
      cancelled: !!raw.header?.status?.cancelled,
      finished: !!raw.header?.status?.finished,
      leagueName: g?.leagueName || g?.parentLeagueName || undefined,
      stadium: st?.name || undefined,
      city: st?.city || undefined,
    };
  });
  if (!payload || typeof payload !== "object") return null;
  return (payload as typeof LD_NOT_FOUND).__remontadaLdNotFound ? null : (payload as MatchLdData);
}

// ---------------- Global top scorers (merged across all leagues) ----------------
export interface GlobalScorer {
  rank: number;        // global dense rank across all leagues
  leagueRank: number;  // rank within the scorer's own league (from FotMob)
  name: string;
  team: string;
  teamId: number;
  goals: number;
  assists?: number;
  gPlusA?: number;
  xg?: number;
  rating?: number;
  minutes?: number;
  leagueKey: string;
  leagueFa: string;
}

export interface GlobalAssist {
  rank: number;
  name: string;
  team: string;
  teamId: number;
  value: number;       // assists
  leagueKey: string;
  leagueFa: string;
}

export interface GlobalScorersData {
  scorers: GlobalScorer[];
  assists: GlobalAssist[];
  perLeague: { leagueKey: string; leagueFa: string; scorers: StandingsData["scorers"] }[];
  updatedAt: string;
}

export async function getAllTopScorers(): Promise<GlobalScorersData> {
  const settled = await Promise.allSettled(LEAGUES.map((lg) => getStandings(lg.key)));
  const merged: GlobalScorer[] = [];
  const mergedAssists: GlobalAssist[] = [];
  const perLeague: GlobalScorersData["perLeague"] = [];
  settled.forEach((r, i) => {
    const lg = LEAGUES[i];
    if (r.status !== "fulfilled") return;
    const st = r.value;
    if (st.scorers?.length) {
      perLeague.push({ leagueKey: lg.key, leagueFa: lg.faName, scorers: st.scorers });
      for (const s of st.scorers) {
        merged.push({
          name: s.name, team: s.team, teamId: s.teamId, goals: s.goals,
          leagueRank: s.rank || 0,
          ...(s.assists != null ? { assists: s.assists } : {}),
          ...(s.gPlusA != null ? { gPlusA: s.gPlusA } : {}),
          ...(s.xg != null ? { xg: s.xg } : {}),
          ...(s.rating != null ? { rating: s.rating } : {}),
          ...(s.minutes != null ? { minutes: s.minutes } : {}),
          leagueKey: lg.key, leagueFa: lg.faName,
        });
      }
    }
    for (const a of st.assists || []) {
      mergedAssists.push({
        name: a.name, team: a.team, teamId: a.teamId, value: a.assists,
        leagueKey: lg.key, leagueFa: lg.faName,
      });
    }
  });
  merged.sort((a, b) => b.goals - a.goals || a.name.localeCompare(b.name));
  // assign dense global ranks 1..n
  merged.forEach((s, i) => { s.rank = i + 1; });
  mergedAssists.sort((a, b) => b.value - a.value || a.name.localeCompare(b.name));
  mergedAssists.forEach((a, i) => { a.rank = i + 1; });
  // de-dup assist leaders by player name (same player can appear in league + cup lists)
  const seenA = new Set<string>();
  const assists = mergedAssists.filter((a) => (seenA.has(a.name) ? false : (seenA.add(a.name), true))).slice(0, 10);
  return { scorers: merged, assists, perLeague, updatedAt: new Date().toISOString() };
}

// ---------------- Team index (for search) ----------------
export interface TeamIndexEntry {
  teamId: number;
  name: string;
  fa: string;
  logo: string;
  leagueKey: string;
  leagueFa: string;
  rank: number;
  pts: number;
  aliases?: string;
}

/** Normalize a search query / team name: lowercase, strip ZWNJ/diacritics, unify Arabic→Persian chars. */
export function normalizeQuery(q: string): string {
  return (q || "")
    .toLowerCase()
    .replace(/[\u200c\u200e\u200f\u0640]/g, "")
    .replace(/[\u064b-\u0652]/g, "")
    .replace(/ي/g, "ی")
    .replace(/ك/g, "ک")
    .replace(/\s+/g, " ")
    .trim();
}

let teamIndexCache: { at: number; data: TeamIndexEntry[] } | null = null;

// Teams whose league page is unavailable via FotMob keyless API (e.g. Persian Gulf Pro
// League returns `null`), but which must still be searchable. Ids verified from match feed.
const SEARCH_FALLBACK_TEAMS: { teamId: number; name: string; fa: string; leagueKey: string; leagueFa: string }[] = [
  { teamId: 101610, name: "Persepolis FC", fa: "پرسپولیس", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
  { teamId: 101614, name: "Esteghlal FC", fa: "استقلال", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
  { teamId: 176352, name: "Tractor SC", fa: "تراکتور", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
  { teamId: 101611, name: "Sepahan SC", fa: "سپاهان", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
];

/** Flat index of every team in our 7 league standings (getStandings is cached, so this is cheap). */
export async function getTeamIndex(): Promise<TeamIndexEntry[]> {
  if (teamIndexCache && Date.now() - teamIndexCache.at < 10 * 60_000) return teamIndexCache.data;
  // domestic leagues first, UCL last — a team playing both (e.g. Real Madrid)
  // should be attributed to its domestic league
  const ordered = [...LEAGUES].sort((a, b) => {
    const rank = (k: string) => (k === "ucl" ? 1 : 0);
    return rank(a.key) - rank(b.key);
  });
  const settled = await Promise.allSettled(ordered.map((lg) => getStandings(lg.key)));
  const out: TeamIndexEntry[] = [];
  const seen = new Set<number>();
  settled.forEach((r, i) => {
    const lg = ordered[i];
    if (r.status !== "fulfilled") return;
    for (const row of r.value.rows) {
      if (seen.has(row.teamId)) continue;
      seen.add(row.teamId);
      out.push({
        teamId: row.teamId, name: row.name, fa: row.fa, logo: row.logo,
        leagueKey: lg.key, leagueFa: lg.faName, rank: row.idx, pts: row.pts,
        aliases: `${row.name} ${row.fa}`,
      });
    }
  });
  // fallback entries for leagues whose standings feed is unavailable
  for (const fb of SEARCH_FALLBACK_TEAMS) {
    if (seen.has(fb.teamId)) continue;
    seen.add(fb.teamId);
    out.push({
      teamId: fb.teamId, name: fb.name, fa: fb.fa, logo: fotmobTeamLogo(fb.teamId),
      leagueKey: fb.leagueKey, leagueFa: fb.leagueFa, rank: 0, pts: 0,
      aliases: `${fb.name} ${fb.fa}`,
    });
  }
  teamIndexCache = { at: Date.now(), data: out };
  return out;
}

export interface TeamSearchResult extends TeamIndexEntry {
  matchedOn: string;
  /** character ranges [start, end) in the original fa/name strings where the
   *  query matched — UI highlights them without re-normalizing (cycle 18) */
  hl?: { fa?: [number, number] | null; name?: [number, number] | null };
}

/** Find the query's match inside `display` tolerating normalization diffs
 *  (ZWNJ/diacritics stripped, Arabic→Persian chars, case). Returns [start, end)
 *  in the ORIGINAL string so the client can highlight without index drift. */
function rangeOf(display: string, nq: string): [number, number] | null {
  if (!display || !nq) return null;
  const chars: string[] = [];
  const map: number[] = [];
  for (let i = 0; i < display.length; i++) {
    const cp = display.charCodeAt(i);
    if (cp === 0x200c || cp === 0x200e || cp === 0x200f || cp === 0x0640 || (cp >= 0x064b && cp <= 0x0652)) continue;
    let c = display[i].toLowerCase();
    if (c === "ي") c = "ی";
    else if (c === "ك") c = "ک";
    chars.push(c);
    map.push(i);
  }
  const idx = chars.join("").indexOf(nq);
  if (idx < 0) return null;
  return [map[idx], map[idx + nq.length - 1] + 1];
}

export async function searchTeams(q: string, limit = 8): Promise<TeamSearchResult[]> {
  const nq = normalizeQuery(q);
  if (nq.length < 2) return [];
  const index = await getTeamIndex();
  const scored: { e: TeamIndexEntry; score: number; matchedOn: string }[] = [];
  for (const e of index) {
    const hay = normalizeQuery(e.aliases || `${e.name} ${e.fa}`);
    let score = -1;
    let matchedOn = e.fa || e.name;
    if (hay === nq) { score = 100; }
    else if (hay.startsWith(nq)) { score = 80; matchedOn = e.fa || e.name; }
    else if (hay.includes(nq)) { score = 50; }
    else {
      // word-level match (e.g. "real" matches "real madrid")
      const words = nq.split(" ");
      if (words.length > 1 && words.every((w) => hay.includes(w))) { score = 40; }
    }
    if (score > 0) scored.push({ e, score, matchedOn });
  }
  scored.sort((a, b) => b.score - a.score || a.e.rank - b.e.rank);
  return scored.slice(0, limit).map(({ e, matchedOn }) => {
    const faRange = rangeOf(e.fa || "", nq);
    const nameRange = rangeOf(e.name || "", nq);
    return {
      ...e,
      matchedOn,
      hl: faRange || nameRange ? { fa: faRange, name: nameRange } : undefined,
    };
  });
}

export { LEAGUES };

// ---------------- helpers ----------------
export function todayInTehran(): string {
  // Tehran = UTC+3:30 (no DST since 2022)
  const now = new Date(Date.now() + 3.5 * 3600_000);
  return now.toISOString().slice(0, 10).replace(/-/g, "");
}

export function dateKeyToYYYYMMDD(offsetFromToday: number): string {
  const now = new Date(Date.now() + 3.5 * 3600_000 + offsetFromToday * 86400_000);
  return now.toISOString().slice(0, 10).replace(/-/g, "");
}
