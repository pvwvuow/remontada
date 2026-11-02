// ------------------------------------------------------------------
// Remontada — server-side football data layer
// Primary:  FotMob (unofficial, keyless)
// Fallback: ESPN public APIs
// ------------------------------------------------------------------
import { LEAGUES, teamFa, fotmobTeamLogo, competitionFa } from "./leagues";
import { cached } from "./cache";

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
}

export interface StandingsData {
  leagueKey: string;
  leagueFa: string;
  season: string;
  rows: StandingsRow[];
  scorers: { rank: number; name: string; team: string; teamId: number; goals: number; ccode?: string }[];
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
interface FotMobLeague {
  details?: { name?: string; seasons?: { year?: string; active?: boolean }[] };
  table?: { data?: { table?: { all?: FotMobRow[] } } };
  stats?: {
    players?: {
      header?: string;
      participant?: { id: number; name: string; teamId?: number; teamName?: string; ccode?: string; value?: number; rank?: number };
      topThree?: { id: number; name: string; teamId?: number; teamName?: string; ccode?: string; value?: number; rank?: number }[];
    }[];
  };
}
interface FotMobRow {
  id: number; name: string; shortName?: string;
  played: number; wins: number; draws: number; losses: number;
  scoresStr?: string; goalConDiff?: number; pts: number; idx: number;
  qualColor?: string | null;
}

export async function getStandings(leagueKey: string): Promise<StandingsData> {
  const lg = LEAGUES.find((l) => l.key === leagueKey);
  if (!lg) throw new Error(`Unknown league: ${leagueKey}`);
  return cached(`standings:${leagueKey}`, 60 * 60_000, async () => {
    const raw = await fetchJson<FotMobLeague>(
      `https://www.fotmob.com/api/data/leagues?id=${lg.fotmobId}&ccode3=${lg.ccode3}&lang=en`
    );
    const rows: StandingsRow[] = (raw.table?.[0]?.data?.table?.all || []).map((r) => {
      const [gf, ga] = (r.scoresStr || "0-0").split("-").map((x) => parseInt(x, 10) || 0);
      return {
        idx: r.idx, teamId: r.id, name: r.name, fa: teamFa(r.name, r.shortName),
        logo: fotmobTeamLogo(r.id),
        played: r.played, wins: r.wins, draws: r.draws, losses: r.losses,
        goalsFor: gf, goalsAgainst: ga, gd: r.goalConDiff ?? gf - ga, pts: r.pts,
        qualColor: r.qualColor || undefined,
      };
    });
    if (rows.length === 0) throw new Error("No standings data");

    // Top scorers from stats.players (header "Top scorer" + topThree)
    const scorers: StandingsData["scorers"] = [];
    const gs = raw.stats?.players?.find?.((p) => /top scorer/i.test(p.header || ""));
    const pushScorer = (s: { id: number; name: string; teamId?: number; teamName?: string; ccode?: string; value?: number; rank?: number }, i: number) => {
      if (!s?.name) return;
      scorers.push({
        rank: s.rank ?? i + 1, name: s.name, team: teamFa(s.teamName, ) || s.teamName || "",
        teamId: s.teamId ?? 0, goals: s.value ?? 0, ccode: s.ccode,
      });
    };
    if (gs?.participant) pushScorer(gs.participant, 0);
    (gs?.topThree || []).forEach((s, i) => pushScorer(s, i));
    // de-dup by name
    const seen = new Set<string>();
    const uniqueScorers = scorers.filter((s) => (seen.has(s.name) ? false : (seen.add(s.name), true)));

    const season = raw.details?.seasons?.find?.((s) => s.active)?.year || "";
    return {
      leagueKey, leagueFa: lg.faName, season, rows,
      scorers: uniqueScorers.slice(0, 5),
      updatedAt: new Date().toISOString(),
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
