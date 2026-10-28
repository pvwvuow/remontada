// ------------------------------------------------------------------
// Remontada — server-side football data layer
// Primary:  FotMob (unofficial, keyless)
// Fallback: ESPN public APIs
// ------------------------------------------------------------------
import { LEAGUES, teamFa, fotmobTeamLogo, competitionFa } from "./leagues";
import { cached } from "./cache";
import { faDigits, jalaliShort } from "./format";

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
  playerId?: number;  // FotMob player id → links to /player/[id]
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
  playerId?: number;  // FotMob player id → links to /player/[id]
}

export interface StandingsData {
  leagueKey: string;
  leagueFa: string;
  season: string;
  /** cycle-55 additive: the season this payload actually shows (FotMob's own label). */
  selectedSeason?: string;
  /** cycle-55 additive: seasons FotMob offers for this league (newest first, capped 12). */
  allSeasons?: string[];
  rows: StandingsRow[];
  home?: StandingsRow[];   // cycle-52 additive: FotMob per-side split (optional — hidden when absent)
  away?: StandingsRow[];
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
    ongoing?: boolean;
    liveTime?: { short?: string; long?: string; ongoing?: boolean };
    reason?: { short?: string; long?: string };
  };
}

function normalizeFotMobMatches(raw: FotMobMatches): LeagueGroup[] {
  const groups: LeagueGroup[] = [];
  for (const lg of raw.leagues || []) {
    const matches: NormMatch[] = (lg.matches || []).map((m) => {
      // cycle-22 bug fix: FotMob marks every in-progress match with
      // status.ongoing=true (statusId 2=1st half, 3=2nd half, 10=half-time,
      // 8=extra time, 20=penalties). The old second clause read
      // status.liveTime.ongoing which never exists in the api/data/matches
      // payload, so everything after the 1st half was classified as not-live.
      const finished = !!m.status?.finished;
      const live = (m.status?.ongoing === true || m.statusId === 2) && !finished;
      const halfTime = m.statusId === 10;
      const minute = !live
        ? undefined
        : halfTime
          ? "بین دو نیمه"
          : m.statusId === 20
            ? "پنالتی"
            : (m.status?.liveTime?.short || "در جریان");
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
  allAvailableSeasons?: string[];
  table?: { data?: { table?: { all?: FotMobRow[]; home?: FotMobRow[]; away?: FotMobRow[] }; selectedSeason?: string } };
  fixtures?: { allMatches?: unknown[] };
  playoff?: { rounds?: FMBracketRoundRaw[] };
  transfers?: FMTransfersRaw;
  stats?: {
    players?: {
      header?: string;
      participant?: FMStatPlayer;
      topThree?: FMStatPlayer[];
      fetchAllUrl?: string;  // full-season static stats file (data.fotmob.com, gzip)
    }[];
  };
}

// Row shape of the full-season goals file (TopLists[0].StatList).
// NOTE: "ParticiantId" is FotMob's own typo in the payload — both spellings accepted.
interface FMStatFullRow {
  ParticiantId?: number;
  ParticipantId?: number;
  ParticipantName?: string;
  TeamId?: number;
  TeamName?: string;
  ParticipantCountryCode?: string;
  StatValue?: number;
  Rank?: number;
  MatchesPlayed?: number;
  MinutesPlayed?: number;
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

// cycle-55: historical seasons are fetched with the same endpoint +
// `&season=YYYY/YYYY` (probed: selectedSeason label + full table/stats/matches
// come back for e.g. 2024/2025). Cache key separates per season.
export const SEASON_PARAM_RE = /^(19|20)\d{2}\/(19|20)\d{2}$/;

// Fetch + cache the (heavy) league payload once; standings & fixtures share it
async function getLeagueRaw(leagueKey: string, season?: string): Promise<{ lg: (typeof LEAGUES)[number]; raw: FotMobLeague }> {
  const lg = LEAGUES.find((l) => l.key === leagueKey);
  if (!lg) throw new Error(`Unknown league: ${leagueKey}`);
  // NOTE: the null/invalid guard lives INSIDE the cached producer so an
  // unusable payload is never cached — each request retries upstream.
  const raw = await cached(`leagueRaw:${leagueKey}:${season || "cur"}`, 60 * 60_000, async () => {
    const data = await fetchJson<FotMobLeague>(
      `https://www.fotmob.com/api/data/leagues?id=${lg.fotmobId}&ccode3=${lg.ccode3}&lang=en${season ? `&season=${encodeURIComponent(season)}` : ""}`
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

/**
 * Full-season goals list (cycle-23): the league payload's "Top scorer"
 * category exposes only participant + topThree (~4 names), but it also
 * carries a `fetchAllUrl` pointing at a static S3 file with the complete
 * ranking (100+ rows). Returns up to `limit` entries, de-duplicated by
 * player id. Fully graceful — any failure returns [] and callers fall
 * back to the short category list.
 */
export async function getFullGoalScorers(leagueKey: string, limit = 20): Promise<ScorerEntry[]> {
  try {
    return await cached(`fullGoals:${leagueKey}`, 60 * 60_000, async () => {
      const { raw } = await getLeagueRaw(leagueKey);
      const cat = raw.stats?.players?.find?.((p) => /top scorer/i.test(p.header || ""));
      const url = cat?.fetchAllUrl;
      if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
      const data = await fetchJson<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
      const rows = data?.TopLists?.[0]?.StatList || [];
      const out: ScorerEntry[] = [];
      const seen = new Set<number>();
      for (const r of rows) {
        const id = r.ParticiantId ?? r.ParticipantId;
        if (!r.ParticipantName || id == null || seen.has(id)) continue;
        seen.add(id);
        out.push({
          rank: r.Rank ?? out.length + 1,
          name: r.ParticipantName,
          team: teamFa(r.TeamName || undefined) || r.TeamName || "",
          teamId: r.TeamId ?? 0,
          goals: Math.round(r.StatValue ?? 0),
          playerId: id,
          ...(r.ParticipantCountryCode ? { ccode: r.ParticipantCountryCode } : {}),
          ...(r.MinutesPlayed ? { minutes: r.MinutesPlayed } : {}),
        });
        if (out.length >= limit) break;
      }
      return out;
    });
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the caller
  }
}

/**
 * Card leaders for one league («آقای کارت», cycle-50). The league payload
 * carries "Yellow cards" / "Red cards" categories with the same fetchAllUrl
 * S3 static-file mechanism as the goals list — full ranking when the file
 * is reachable, participant + topThree fallback otherwise. Fully graceful:
 * any failure (e.g. the persiangulf null feed) returns [] and the merged
 * section simply omits that league.
 */
export async function getLeagueCardLeaders(
  leagueKey: string,
  kind: CardKind,
  limit = 15,
): Promise<Omit<GlobalCard, "rank" | "leagueKey" | "leagueFa">[]> {
  try {
    return await cached(`cards:${leagueKey}:${kind}`, 60 * 60_000, async () => {
      const { raw } = await getLeagueRaw(leagueKey);
      const re = kind === "yellow" ? /^yellow cards$/i : /^red cards$/i;
      const cat = raw.stats?.players?.find?.((p) => re.test(p.header || ""));
      if (!cat) return [];
      const out: Omit<GlobalCard, "rank" | "leagueKey" | "leagueFa">[] = [];
      const seen = new Set<number>();
      if (cat.fetchAllUrl && /^https:\/\/data\.fotmob\.com\//.test(cat.fetchAllUrl)) {
        const data = await fetchJson<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(cat.fetchAllUrl);
        const rows = data?.TopLists?.[0]?.StatList || [];
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            name: r.ParticipantName,
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            value: Math.round(r.StatValue ?? 0),
            playerId: id,
          });
          if (out.length >= limit) break;
        }
      }
      if (out.length === 0) {
        // short category fallback (participant + topThree only)
        for (const p of statCategory(raw, re)) {
          if (seen.has(p.id)) continue;
          seen.add(p.id);
          out.push({
            name: p.name,
            team: teamFa(p.teamName || undefined) || p.teamName || "",
            teamId: p.teamId ?? 0,
            value: Math.round(p.value ?? 0),
            playerId: p.id,
          });
        }
      }
      return out;
    });
  } catch {
    return [];  // unavailable league / upstream hiccup — never break the merge
  }
}

export async function getStandings(leagueKey: string, season?: string): Promise<StandingsData> {
  const { lg, raw } = await getLeagueRaw(leagueKey, season);
  const build = async () => {
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

    // cycle-52 (Update #2): one mapper for all three variants — `all` carries
    // the computed last-5 form chips; FotMob home/away rows share the exact
    // row shape of `all` (probe: same keys + goalsScored) but attaching the
    // OVERALL form there would be misleading, so side rows carry no form
    const fmTable = raw.table?.[0]?.data?.table;
    const mapRow = (r: FotMobRow, withForm: boolean): StandingsRow => {
      const [gf, ga] = (r.scoresStr || "0-0").split("-").map((x) => parseInt(x, 10) || 0);
      const form = withForm ? formMap.get(r.id) : undefined;
      return {
        idx: r.idx, teamId: r.id, name: r.name, fa: teamFa(r.name, r.shortName),
        logo: fotmobTeamLogo(r.id),
        played: r.played, wins: r.wins, draws: r.draws, losses: r.losses,
        goalsFor: gf, goalsAgainst: ga, gd: r.goalConDiff ?? gf - ga, pts: r.pts,
        qualColor: r.qualColor || undefined,
        ...(form && form.length > 0 ? { form: form.slice(-5) } : {}),
      };
    };
    const rows: StandingsRow[] = (fmTable?.all || []).map((r) => mapRow(r, true));
    if (rows.length === 0) throw new Error("No standings data");
    const sideRows = (v?: FotMobRow[]) => {
      const arr = (v || []).map((r) => mapRow(r, false));
      return arr.length > 0 ? arr : undefined;
    };
    const homeRows = sideRows(fmTable?.home);
    const awayRows = sideRows(fmTable?.away);

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
        ...(s.id ? { playerId: s.id } : {}),
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

    // cycle-23: merge the full-season goals file on top of the ~4 category
    // names — enriched entries (assists/xG/rating) stay first, the rest of
    // the ranking is appended so /topscorers + the sitemap get real depth
    const fullScorers = await getFullGoalScorers(leagueKey, 24);
    const enrichedIds = new Set(
      uniqueScorers.map((s) => s.playerId).filter((id): id is number => id != null),
    );
    const mergedScorers = [...uniqueScorers, ...fullScorers.filter((s) => s.playerId == null || !enrichedIds.has(s.playerId))]
      .sort((a, b) => b.goals - a.goals || a.name.localeCompare(b.name))
      .slice(0, 20)
      .map((s, i) => ({ ...s, rank: i + 1 }));

    // assist leaders (participant + topThree of the "Assists" category)
    const assistEntries: AssistEntry[] = statCategory(raw, /^assists$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName, ) || p.teamName || "",
        teamId: p.teamId ?? 0, assists: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.assists - a.assists || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }))
      .slice(0, 6);

    const season = raw.details?.seasons?.find?.((s) => s.active)?.year || "";
    // cycle-55: FotMob's own selected-season label + the seasons it offers —
    // additive fields so the v2 cache shape stays backward compatible
    const selectedSeason = raw.table?.[0]?.data?.selectedSeason || season || undefined;
    const allSeasons = Array.isArray(raw.allAvailableSeasons)
      ? raw.allAvailableSeasons.filter((s) => SEASON_PARAM_RE.test(s)).slice(0, 12)
      : undefined;
    return {
      leagueKey, leagueFa: lg.faName, season, rows,
      ...(selectedSeason ? { selectedSeason } : {}),
      ...(allSeasons && allSeasons.length > 1 ? { allSeasons } : {}),
      ...(homeRows ? { home: homeRows } : {}),
      ...(awayRows ? { away: awayRows } : {}),
      scorers: mergedScorers,
      assists: assistEntries,
      updatedAt: new Date().toISOString(),
    };
  };
  // cycle-52: payload shape gained additive `home`/`away` → key bumped to v2
  // so the L2 (SQLite) cache cannot serve the old shape for its 60-min TTL
  // cycle-55: per-season cache keys ("cur" keeps the old key string for the
  // current season, so existing cache entries stay valid)
  return cached(`standings:v2:${leagueKey}:${season || "cur"}`, 60 * 60_000, build);
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
    round: roundFa(f.roundName == null ? undefined : String(f.roundName)),
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
  /** cycle-55 additive: season this payload actually shows. */
  selectedSeason?: string;
  upcoming: NormFixture[];
  recent: NormFixture[];
  total: number;
  stats?: LeagueStats;
  /** Current-week progress (numeric rounds only — cup phases hide it). */
  progress: { current: number; total: number } | null;
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

/** Round label → Persian. "Regular season - 8" / "8" → «هفته ۸».
    fix cycle-59: exported + also used by normalizeFixture and the match API
    route so week labels never leak Latin digits («هفته ۹» not «هفته 9»). */
export function roundFa(round: string | undefined): string | undefined {
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

export async function getLeagueFixtures(leagueKey: string, season?: string): Promise<LeagueFixturesData> {
  const { lg, raw } = await getLeagueRaw(leagueKey, season);
  const all = (raw.fixtures?.allMatches || []) as FotMobFixture[];
  const activeSeason = raw.details?.seasons?.find?.((s) => s.active)?.year || "";
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

  // ---- current-week progress (best-effort, numeric rounds only) ----
  // total = highest numeric round across the whole season payload;
  // current = round of the first upcoming fixture, fallback: highest finished
  const roundNumOf = (r?: string): number | null => {
    const m = /(\d+)\s*$/.exec(String(r || "").trim());
    return m ? Number(m[1]) : null;
  };
  let progress: LeagueFixturesData["progress"] = null;
  const allRoundNums = mapped.map((f) => roundNumOf(f.round)).filter((n): n is number => typeof n === "number");
  if (allRoundNums.length > 0) {
    const total = Math.max(...allRoundNums);
    const nextRound = [...mapped]
      .filter((f) => !f.started && !f.cancelled && f.utcTime)
      .sort((a, b) => a.utcTime.localeCompare(b.utcTime))
      .map((f) => roundNumOf(f.round))
      .find((n): n is number => typeof n === "number") ?? null;
    const finishedNums = mapped
      .filter((f) => f.finished)
      .map((f) => roundNumOf(f.round))
      .filter((n): n is number => typeof n === "number");
    const current = nextRound ?? (finishedNums.length > 0 ? Math.max(...finishedNums) : null);
    if (current !== null && total > 0 && current >= 1 && current <= total) {
      progress = { current, total };
    }
  }

  const selectedSeason = raw.table?.[0]?.data?.selectedSeason || season || undefined;
  return {
    leagueKey,
    leagueFa: lg.faName,
    season: activeSeason || season || "",
    ...(selectedSeason ? { selectedSeason } : {}),
    upcoming,
    recent,
    total: mapped.length,
    stats: computeLeagueStats(mapped),
    progress,
  };
}

// ---------------- FotMob: cup knockout bracket (playoff) ----------------
// cycle-56: raw shapes of the league payload's `playoff` key. Probed live:
// UCL carries rounds (playoff, 1/8, 1/4, 1/2, final); each matchup holds the
// tie-level teams + aggregate (aggregatedResult/aggregatedWinner) and the
// actual legs in `matches` (matchId, per-leg score/winner, status). Leagues
// without knockout stages simply have no/empty playoff → getLeagueBracket
// returns null and the UI hides the bracket tab.
interface FMBracketMatchRaw {
  matchId?: number | string;
  home?: { id?: number; name?: string; shortName?: string; score?: number; winner?: boolean };
  away?: { id?: number; name?: string; shortName?: string; score?: number; winner?: boolean };
  status?: { utcTime?: string; finished?: boolean; started?: boolean; cancelled?: boolean };
}
interface FMBracketMatchupRaw {
  homeTeam?: string; homeTeamId?: number; homeTeamShortName?: string;
  awayTeam?: string; awayTeamId?: number; awayTeamShortName?: string;
  aggregatedResult?: { homeScore?: number; awayScore?: number } | null;
  aggregatedWinner?: number | null;
  drawDate?: string;
  hasTwoPossibleMatchups?: boolean;
  matches?: FMBracketMatchRaw[];
}
interface FMBracketRoundRaw {
  stage?: string;
  participantCount?: number;
  matchups?: FMBracketMatchupRaw[];
}

export interface BracketLeg {
  matchId?: string;
  utcTime?: string;
  finished: boolean;
  home: { id: number; name: string; short: string; score: number | null; winner: boolean | null };
  away: { id: number; name: string; short: string; score: number | null; winner: boolean | null };
}
export interface BracketMatchup {
  home: { id: number; name: string; short: string };
  away: { id: number; name: string; short: string };
  aggHome: number | null;
  aggAway: number | null;
  winnerId: number | null;
  drawDate?: string;
  legs: BracketLeg[];
}
export interface BracketRound {
  stage: string;
  stageFa: string;
  matchups: BracketMatchup[];
}
export interface LeagueBracketData {
  leagueKey: string;
  leagueFa: string;
  selectedSeason?: string;
  rounds: BracketRound[];
}

const BRACKET_STAGE_FA: Record<string, string> = {
  "playoff": "پلی‌آف",
  "1/8": "یک‌هشتم نهایی",
  "1/4": "یک‌چهارم نهایی",
  "1/2": "نیمه‌نهایی",
  "final": "فینال",
};

const bracketTeam = (id?: number, name?: string, short?: string) => ({
  id: Number(id || 0),
  name: teamFa(name, short) || name || "",
  short: short || "",
});

/**
 * Cup knockout bracket for a league+season (cycle-56 «براکت جام‌ها»).
 * Returns null when the payload has no usable playoff rounds (domestic
 * leagues) — callers hide the tab instead of showing an empty shell.
 */
export async function getLeagueBracket(leagueKey: string, season?: string): Promise<LeagueBracketData | null> {
  const { lg, raw } = await getLeagueRaw(leagueKey, season);
  const roundsRaw = raw.playoff?.rounds || [];
  const rounds: BracketRound[] = [];
  for (const r of roundsRaw) {
    const stage = String(r?.stage || "");
    const matchups: BracketMatchup[] = [];
    for (const m of r?.matchups || []) {
      if (!m) continue;
      const legs: BracketLeg[] = (m.matches || [])
        .filter((x) => x?.home?.name && x?.away?.name)
        .map((x) => ({
          ...(x.matchId != null ? { matchId: String(x.matchId) } : {}),
          ...(x.status?.utcTime ? { utcTime: x.status.utcTime } : {}),
          finished: !!x.status?.finished,
          home: {
            id: Number(x.home?.id || 0),
            name: teamFa(x.home?.name, x.home?.shortName) || x.home?.name || "",
            short: x.home?.shortName || "",
            score: x.home?.score ?? null,
            winner: x.home?.winner ?? null,
          },
          away: {
            id: Number(x.away?.id || 0),
            name: teamFa(x.away?.name, x.away?.shortName) || x.away?.name || "",
            short: x.away?.shortName || "",
            score: x.away?.score ?? null,
            winner: x.away?.winner ?? null,
          },
        }));
      matchups.push({
        home: bracketTeam(m.homeTeamId, m.homeTeam, m.homeTeamShortName),
        away: bracketTeam(m.awayTeamId, m.awayTeam, m.awayTeamShortName),
        aggHome: m.aggregatedResult?.homeScore ?? null,
        aggAway: m.aggregatedResult?.awayScore ?? null,
        winnerId: m.aggregatedWinner ?? null,
        ...(m.drawDate ? { drawDate: m.drawDate } : {}),
        legs,
      });
    }
    if (matchups.length > 0) {
      rounds.push({ stage, stageFa: BRACKET_STAGE_FA[stage] || stage, matchups });
    }
  }
  if (rounds.length === 0) return null;
  const selectedSeason = raw.table?.[0]?.data?.selectedSeason || season || undefined;
  return {
    leagueKey,
    leagueFa: lg.faName,
    ...(selectedSeason ? { selectedSeason } : {}),
    rounds,
  };
}

// ---------------- FotMob: league transfers (current season) ----------------
// cycle-57: raw shape of the league payload's `transfers` key, probed live
// (UA Chrome/124, 2026-10-29): transfers.data is a date-desc list (~100 rows)
// covering the league's clubs — each row carries both clubs (id + short/full
// names), player, position, transferDate, fee (feeText/value) and transferType
// ("contract" | "on loan" | …). Probed limits: season=2024/2025 →
// transfers.data is null (feed exists for the CURRENT season only) and
// UCL/Persian Gulf carry an empty list → getLeagueTransfers returns null and
// the UI hides the tab. Direction is classified against the standings club
// ids of the SAME payload (feed ids match standings ids; Hull City 8667 is a
// genuine 2026/27 PL member).
interface FMTransfersRaw {
  data?: FMTransferRaw[];
}
interface FMTransferRaw {
  name?: string;
  playerId?: number;
  position?: { label?: string };
  transferDate?: string;
  fromClub?: string;
  fromClubFullName?: string;
  fromClubId?: number;
  toClub?: string;
  toClubFullName?: string;
  toClubId?: number;
  fee?: { feeText?: string; value?: number } | null;
  transferType?: { text?: string };
  contractExtension?: boolean;
  onLoan?: boolean;
}

export interface LeagueTransferItem {
  playerId: number;
  name: string;
  position: string;
  date: string; // ISO
  from: { id: number; name: string; fa: string };
  to: { id: number; name: string; fa: string };
  kind: "in" | "out" | "internal";
  kindFa: string;
  feeFa: string;
}

export interface LeagueTransfersData {
  leagueKey: string;
  leagueFa: string;
  season: string;
  items: LeagueTransferItem[];
}

/** Compact Persian euro amount: 689000 → «۶۸۹ هزار یورو»، 15e6 → «۱۵ میلیون یورو». */
const euroFa = (v: number): string => {
  if (v >= 1e6) {
    const m = v / 1e6;
    const s = (m >= 10 ? String(Math.round(m)) : m.toFixed(1).replace(/\.0$/, "")).replace(".", "٫");
    return `${faDigits(s)} میلیون یورو`;
  }
  if (v >= 1e3) return `${faDigits(Math.round(v / 1e3))} هزار یورو`;
  return `${faDigits(v)} یورو`;
};

/** Persian label for fee/type (source texts probed: fee, on loan, free transfer, contract). */
const transferFeeFa = (t: FMTransferRaw): string => {
  if (t.contractExtension) return "تمدید قرارداد";
  const feeText = (t.fee?.feeText || "").toLowerCase();
  const typeText = (t.transferType?.text || "").toLowerCase();
  if (feeText === "fee" && t.fee?.value) return `کارمزد ${euroFa(t.fee.value)}`;
  if (feeText === "on loan" || typeText === "on loan" || t.onLoan) return "انتقال امانی";
  if (feeText === "free transfer" || typeText === "free transfer") return "انتقال آزاد";
  if (typeText === "contract") return "قرارداد";
  return t.transferType?.text || t.fee?.feeText || "انتقال";
};

/**
 * Current-season transfers of a league's clubs (cycle-57 «انتقال‌ها»).
 * Returns null when the payload has no transfer feed (UCL, Persian Gulf) —
 * callers hide the tab instead of an empty shell. No season parameter on
 * purpose: probed live, the feed exists only for the current-season payload.
 * Source order is already date-desc — kept as-is.
 */
export async function getLeagueTransfers(leagueKey: string): Promise<LeagueTransfersData | null> {
  const { lg, raw } = await getLeagueRaw(leagueKey);
  const list = raw.transfers?.data || [];
  if (list.length === 0) return null;
  const clubIds = new Set<number>(
    (raw.table?.[0]?.data?.table?.all || []).map((r) => Number(r?.id || 0)).filter((x) => x > 0)
  );
  const items: LeagueTransferItem[] = [];
  for (const t of list) {
    if (!t?.name || !t?.fromClub || !t?.toClub) continue;
    const fromIn = clubIds.has(Number(t.fromClubId || 0));
    const toIn = clubIds.has(Number(t.toClubId || 0));
    if (!fromIn && !toIn) continue;
    const kind: LeagueTransferItem["kind"] = fromIn && toIn ? "internal" : toIn ? "in" : "out";
    items.push({
      playerId: Number(t.playerId || 0),
      name: t.name,
      position: t.position?.label || "",
      date: t.transferDate || "",
      from: {
        id: Number(t.fromClubId || 0),
        name: t.fromClubFullName || t.fromClub,
        fa: teamFa(t.fromClubFullName, t.fromClub) || t.fromClubFullName || t.fromClub,
      },
      to: {
        id: Number(t.toClubId || 0),
        name: t.toClubFullName || t.toClub,
        fa: teamFa(t.toClubFullName, t.toClub) || t.toClubFullName || t.toClub,
      },
      kind,
      kindFa: kind === "in" ? "ورودی" : kind === "out" ? "خروجی" : "داخلی",
      feeFa: transferFeeFa(t),
    });
  }
  if (items.length === 0) return null;
  const season = raw.table?.[0]?.data?.selectedSeason || "";
  return { leagueKey, leagueFa: lg.faName, season, items };
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

// ---------------- FotMob: player profile (/player/[id]) ----------------
// Thrown when FotMob has no player for an id. NOTE (cycle-17/19 finding):
// FotMob answers HTTP 200 for BOTH nonexistent ids and empty players —
// body is either `null` or {error:true, message:"Data not found"} — a
// real network failure must NOT be classified as "not found".
export class PlayerNotFoundError extends Error {}

const PLAYER_NOT_FOUND = { __remontadaPlayerNotFound: true } as const;

interface FMPlayerInfoEntry {
  title?: string;
  value?: { numberValue?: number; fallback?: unknown; key?: string | null; dateValue?: string } | null;
  icon?: { id?: string } | null;
}
interface FMPlayerDetails {
  id?: number;
  name?: string;
  isCoach?: boolean;
  status?: string;
  birthDate?: { utcTime?: string } | null;
  primaryTeam?: { teamId?: number; teamName?: string; onLoan?: boolean } | null;
  positionDescription?: { primaryPosition?: { label?: string } } | null;
  playerInformation?: Record<string, FMPlayerInfoEntry> | FMPlayerInfoEntry[];
  mainLeague?: { leagueId?: number; leagueName?: string; season?: string; stats?: { title?: string; localizedTitleId?: string; value?: number }[] } | null;
  nextMatch?: { matchId?: number; homeId?: number; awayId?: number; homeName?: string; awayName?: string; matchDate?: string; leagueId?: number; leagueName?: string } | null;
  recentMatches?: {
    teamId?: number; teamName?: string;
    opponentTeamId?: number; opponentTeamName?: string;
    isHomeTeam?: boolean;
    id?: number;
    matchDate?: { utcTime?: string } | null;
    leagueId?: number; leagueName?: string;
    homeScore?: number; awayScore?: number;
    minutesPlayed?: number; goals?: number; assists?: number;
    yellowCards?: number; redCards?: number;
    ratingProps?: { rating?: string } | null;
    playerOfTheMatch?: boolean; onBench?: boolean; playedInMatch?: boolean;
  }[] | null;
  // cycle-20: career path + trophies (both optional — many players lack them)
  careerHistory?: {
    careerItems?: Partial<Record<"senior" | "youth" | "national team", { teamEntries?: FMCareerEntry[] | null } | null>> | null;
  } | null;
  trophies?: {
    playerTrophies?: {
      teamName?: string; ccode?: string;
      tournaments?: { leagueName?: string; leagueId?: number; seasonsWon?: string[]; seasonsRunnerUp?: string[] }[] | null;
    }[] | null;
  } | null;
}

interface FMCareerEntry {
  teamId?: number; team?: string;
  startDate?: string; endDate?: string | null;
  active?: boolean;
  appearances?: string; goals?: string; assists?: string;
  transferType?: { text?: string; localizationKey?: string } | null;
}

export interface PlayerCareerEntry {
  teamId: number;
  team: string;      // english name
  fa: string;        // persian name (teamFa map) or english fallback
  logo: string;
  from: string;      // gregorian year "2022" (faDigits applied in UI)
  to: string;        // gregorian year or "" when active
  active: boolean;
  apps: number | null;
  goals: number | null;
  assists: number | null;
  transfer: string | null;   // persian transfer note or null
  kind: "senior" | "national" | "youth";  // cycle-22: declared (was pushed undeclared)
}

export interface PlayerTrophy {
  teamName: string;
  leagueName: string;
  seasonsWon: string[];
  runnerUp: number;
}

export interface PlayerSeasonStat { title: string; display: string; key: string }
export interface PlayerRecentMatch {
  id: string;
  utcTime: string;
  leagueFa: string;
  isHome: boolean;
  opponent: string;
  opponentId: number;
  opponentLogo: string;
  homeScore: number | null;
  awayScore: number | null;
  result: "W" | "D" | "L" | null;   // from the player's team perspective
  played: boolean;
  onBench: boolean;
  minutes: number | null;
  goals: number;
  assists: number;
  yellow: number;
  red: number;
  rating: string | null;
  potm: boolean;
}
export interface PlayerData {
  id: string;
  name: string;
  positionFa: string | null;
  positionEn: string | null;
  status: string;
  team: { id: number; name: string; fa: string; logo: string } | null;
  info: {
    age?: number; height?: string; shirt?: number; foot?: string;
    country?: string; countryCcode?: string; marketValue?: string; contractEnd?: string;
  };
  season: { leagueFa: string; season: string; stats: PlayerSeasonStat[] } | null;
  recent: PlayerRecentMatch[];
  next: { id: string; utcTime: string; opponent: string; opponentId: number; opponentLogo: string; isHome: boolean; leagueFa: string } | null;
  career: PlayerCareerEntry[];       // senior + national-team stops, newest first
  careerYouth: PlayerCareerEntry[];  // youth/academy stops (hidden section when empty)
  trophies: PlayerTrophy[];          // honours (league/team + winning seasons)
  fetchedAt: string;
}

function faPosition(label?: string): string | null {
  const l = (label || "").toLowerCase();
  if (!l) return null;
  if (l.includes("goalkeeper")) return "دروازه‌بان";
  if (l.includes("defensive midfield")) return "هافبک دفاعی";
  if (l.includes("attacking midfield")) return "هافبک هجومی";
  if (l.includes("midfield")) return "هافبک";
  if (l.includes("centre back") || l.includes("center back") || l.includes("centre-back") || l.includes("center-back")) return "مدافع میانی";
  if (l.includes("back")) return "دفاع کناری";
  if (l.includes("defend")) return "مدافع";
  if (l.includes("left winger")) return "وینگر چپ";
  if (l.includes("right winger")) return "وینگر راست";
  if (l.includes("winger")) return "وینگر";
  if (l.includes("striker") || l.includes("forward")) return "مهاجم";
  return null;
}

const PLAYER_STAT_FA: Record<string, string> = {
  goals: "گل",
  assists: "پاس گل",
  started: "ترکیب اصلی",
  matches_uppercase: "بازی",
  matches: "بازی",
  minutes_played: "دقیقه",
  rating: "امتیاز فوت‌ماب",
  yellow_cards: "کارت زرد",
  red_cards: "کارت قرمز",
};

const FOOT_FA: Record<string, string> = { left: "چپ", right: "راست", both: "دو پا" };

function leagueFaById(id?: number, name?: string): string {
  const lg = LEAGUES.find((l) => l.fotmobId === id);
  if (lg) return lg.faName;
  return competitionFa(name || "") || name || "";
}

function normalizePlayer(raw: FMPlayerDetails, id: string): PlayerData {
  const pt = raw.primaryTeam && raw.primaryTeam.teamId ? raw.primaryTeam : null;
  const info: PlayerData["info"] = {};
  const entries = Array.isArray(raw.playerInformation)
    ? raw.playerInformation
    : Object.values(raw.playerInformation || {});
  for (const e of entries) {
    const t = (e?.title || "").toLowerCase();
    const v = e?.value;
    const fb = v?.fallback;
    if (t === "age" && typeof v?.numberValue === "number") info.age = v.numberValue;
    else if (t === "height") info.height = typeof fb === "string" ? fb : undefined;
    else if (t === "shirt" && typeof v?.numberValue === "number") info.shirt = v.numberValue;
    else if (t === "preferred foot") {
      const key = (v?.key || "").toLowerCase();
      info.foot = FOOT_FA[key] || (typeof fb === "string" ? fb : undefined);
    } else if (t === "country") {
      info.country = typeof fb === "string" ? fb : undefined;
      info.countryCcode = e.icon?.id || undefined;
    } else if (t === "market value") info.marketValue = typeof fb === "string" ? fb : undefined;
    else if (t === "contract end") {
      const iso = typeof v?.dateValue === "string" ? v.dateValue : (fb as { utcTime?: string } | undefined)?.utcTime;
      if (iso && !Number.isNaN(new Date(iso).getTime())) info.contractEnd = jalaliContract(iso);
    }
  }

  // season stats from mainLeague (title → Persian via localizedTitleId)
  let season: PlayerData["season"] = null;
  const ml = raw.mainLeague;
  if (ml?.stats?.length) {
    const stats: PlayerSeasonStat[] = [];
    for (const s of ml.stats) {
      if (typeof s.value !== "number") continue;
      const key = (s.localizedTitleId || s.title || "").toLowerCase();
      const titleFa = PLAYER_STAT_FA[key] || s.title || key;
      const display = key === "rating" ? s.value.toFixed(1) : String(s.value);
      stats.push({ title: titleFa, display, key });
    }
    if (stats.length > 0) {
      season = {
        leagueFa: leagueFaById(ml.leagueId, ml.leagueName),
        season: ml.season || "",
        stats,
      };
    }
  }

  // recent appearances (already newest-first) — keep the last 10
  const recent: PlayerRecentMatch[] = [];
  for (const m of (raw.recentMatches || []).slice(0, 10)) {
    if (!m?.id) continue;
    const isHome = !!m.isHomeTeam;
    const hs = typeof m.homeScore === "number" ? m.homeScore : null;
    const as = typeof m.awayScore === "number" ? m.awayScore : null;
    let result: PlayerRecentMatch["result"] = null;
    if (hs !== null && as !== null) {
      const my = isHome ? hs : as;
      const op = isHome ? as : hs;
      result = my > op ? "W" : my < op ? "L" : "D";
    }
    recent.push({
      id: String(m.id),
      utcTime: m.matchDate?.utcTime || "",
      leagueFa: leagueFaById(m.leagueId, m.leagueName),
      isHome,
      opponent: teamFa(m.opponentTeamName) || m.opponentTeamName || "",
      opponentId: m.opponentTeamId ?? 0,
      opponentLogo: fotmobTeamLogo(m.opponentTeamId ?? 0),
      homeScore: hs,
      awayScore: as,
      result,
      played: !!m.playedInMatch,
      onBench: !!m.onBench,
      minutes: typeof m.minutesPlayed === "number" ? m.minutesPlayed : null,
      goals: m.goals ?? 0,
      assists: m.assists ?? 0,
      yellow: m.yellowCards ?? 0,
      red: m.redCards ?? 0,
      rating: m.ratingProps?.rating || null,
      potm: !!m.playerOfTheMatch,
    });
  }

  // next match (opponent relative to the player's current team)
  let next: PlayerData["next"] = null;
  const nm = raw.nextMatch;
  if (nm?.matchId && nm.matchDate && pt?.teamId) {
    const isHome = nm.homeId === pt.teamId;
    const oppName = isHome ? nm.awayName : nm.homeName;
    const oppId = isHome ? nm.awayId : nm.homeId;
    next = {
      id: String(nm.matchId),
      utcTime: nm.matchDate,
      opponent: teamFa(oppName) || oppName || "",
      opponentId: oppId ?? 0,
      opponentLogo: fotmobTeamLogo(oppId ?? 0),
      isHome,
      leagueFa: leagueFaById(nm.leagueId, nm.leagueName),
    };
  }

  const posEn = raw.positionDescription?.primaryPosition?.label || null;
  const careerItems = raw.careerHistory?.careerItems || {};
  const career = [
    ...normalizeCareerEntries(careerItems.senior?.teamEntries, "senior"),
    ...normalizeCareerEntries(careerItems["national team"]?.teamEntries, "national"),
  ];
  return {
    id,
    name: raw.name || "",
    positionFa: faPosition(posEn || undefined),
    positionEn: posEn,
    status: raw.status || "",
    team: pt
      ? { id: pt.teamId as number, name: pt.teamName || "", fa: teamFa(pt.teamName || undefined) || pt.teamName || "", logo: fotmobTeamLogo(pt.teamId ?? 0) }
      : null,
    info,
    season,
    recent,
    next,
    career,
    careerYouth: normalizeCareerEntries(careerItems.youth?.teamEntries, "youth"),
    trophies: normalizeTrophies(raw.trophies),
    fetchedAt: new Date().toISOString(),
  };
}

function jalaliContract(iso: string): string {
  const j = jalaliShort(iso);
  return j.day && j.month ? `${j.day} ${j.month}` : "";
}

// ---- cycle-20: career path + trophies parsing (all best-effort) ----
const TRANSFER_FA: Record<string, string> = {
  on_loan: "انتقال قرضی",
  free_transfer: "انتقال آزاد",
  back_from_loan: "بازگشت از قرضی",
  loan_end: "پایان قرضی",
};

function yearOf(iso?: string | null): string {
  if (!iso) return "";
  const y = /^(\d{4})/.exec(iso);
  return y ? y[1] : "";
}

function numOr(s?: string): number | null {
  if (!s) return null;
  const n = parseInt(s.replace(/[^0-9-]/g, ""), 10);
  return Number.isFinite(n) ? n : null;
}

function normalizeCareerEntries(
  entries: FMCareerEntry[] | null | undefined,
  kind: "senior" | "national" | "youth",
): PlayerCareerEntry[] {
  const out: PlayerCareerEntry[] = [];
  for (const e of entries || []) {
    if (!e?.teamId || !e.team) continue;
    out.push({
      teamId: e.teamId,
      team: e.team,
      fa: teamFa(e.team) || e.team,
      logo: fotmobTeamLogo(e.teamId),
      from: yearOf(e.startDate),
      to: e.active ? "" : yearOf(e.endDate),
      active: !!e.active,
      apps: numOr(e.appearances),
      goals: numOr(e.goals),
      assists: numOr(e.assists),
      transfer: e.transferType?.localizationKey
        ? TRANSFER_FA[e.transferType.localizationKey] || e.transferType.text || null
        : e.transferType?.text || null,
      kind,
    });
  }
  // newest first: active club first, then by start year desc
  out.sort((a, b) => {
    if (a.active !== b.active) return a.active ? -1 : 1;
    return (b.from || "").localeCompare(a.from || "");
  });
  return out;
}

function normalizeTrophies(raw?: FMPlayerDetails["trophies"]): PlayerTrophy[] {
  const out: PlayerTrophy[] = [];
  for (const pt of raw?.playerTrophies || []) {
    for (const t of pt.tournaments || []) {
      const won = t.seasonsWon || [];
      const runnerUp = (t.seasonsRunnerUp || []).length;
      if (won.length === 0 && runnerUp === 0) continue;
      out.push({ teamName: pt.teamName || "", leagueName: t.leagueName || "", seasonsWon: won, runnerUp });
    }
  }
  // most-winning first, cap at 12 to keep the page light
  out.sort((a, b) => b.seasonsWon.length - a.seasonsWon.length);
  return out.slice(0, 12);
}

/**
 * Full player payload for the SSR /player/[id] page + /api/player/[id].
 * • nonexistent player (FotMob 200 + null / {error:true}) → cached sentinel → PlayerNotFoundError
 * • network/timeout/HTTP failure → the error propagates (page shows its
 *   in-page error state; nothing is cached so the next request retries)
 */
export async function getPlayerData(id: string): Promise<PlayerData> {
  if (!/^\d{3,12}$/.test(id)) throw new PlayerNotFoundError(`bad player id: ${id}`);
  const payload = await cached(`player:${id}`, 10 * 60_000, async (): Promise<PlayerData | typeof PLAYER_NOT_FOUND> => {
    const raw = await fetchJson<FMPlayerDetails>(`https://www.fotmob.com/api/data/playerData?id=${id}`, 9000);
    if (!raw || typeof raw !== "object" || (raw as { error?: unknown }).error === true) return PLAYER_NOT_FOUND;
    if (!raw.name || !raw.id) return PLAYER_NOT_FOUND;
    return normalizePlayer(raw, id);
  });
  if (payload === PLAYER_NOT_FOUND || !payload || typeof payload !== "object") {
    throw new PlayerNotFoundError(`player ${id} not found`);
  }
  return payload as PlayerData;
}

// ---------------- Global top scorers (merged across all leagues) ----------------
export interface GlobalScorer {
  rank: number;        // global dense rank across all leagues
  leagueRank: number;  // rank within the scorer's own league (from FotMob)
  name: string;
  team: string;
  teamId: number;
  goals: number;
  playerId?: number;   // FotMob player id → links to /player/[id]
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
  playerId?: number;   // FotMob player id → links to /player/[id]
  leagueKey: string;
  leagueFa: string;
}

// cycle-50: card leaders («آقای کارت») — same S3 full-list mechanism as goals
export type CardKind = "yellow" | "red";

export interface GlobalCard {
  rank: number;        // global dense rank across leagues (per kind)
  name: string;
  team: string;
  teamId: number;
  value: number;       // card count
  playerId?: number;   // FotMob player id → links to /player/[id]
  leagueKey: string;
  leagueFa: string;
}

export interface GlobalCardsData {
  yellow: GlobalCard[];
  red: GlobalCard[];
}

export interface GlobalScorersData {
  scorers: GlobalScorer[];
  assists: GlobalAssist[];
  /** cycle-50: yellow/red card leaders across all leagues. Additive + optional:
   *  older snapshots served from L2 lack this field and the UI hides the
   *  section rather than showing a dishonest empty state. */
  cards?: GlobalCardsData;
  perLeague: { leagueKey: string; leagueFa: string; scorers: StandingsData["scorers"] }[];
  updatedAt: string;
  /** cycle-42: true when the response comes from the last-known-good snapshot
   *  (cold start / upstream outage) instead of a fresh live merge — the UI
   *  shows an honest «آخرین داده‌های ذخیره‌شده» notice in that case. */
  stale?: boolean;
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
          rank: 0, // dense global rank assigned after the sort below
          name: s.name, team: s.team, teamId: s.teamId, goals: s.goals,
          leagueRank: s.rank || 0,
          ...(s.playerId != null ? { playerId: s.playerId } : {}),
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
        rank: 0, // dense global rank assigned after the sort below
        name: a.name, team: a.team, teamId: a.teamId, value: a.assists,
        ...(a.playerId != null ? { playerId: a.playerId } : {}),
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
  // cycle-50: card leaders ride along in the same payload (all per-league
  // fetches are cache-backed, so the merge only pays on a cold start)
  let cards: GlobalCardsData | undefined;
  try {
    cards = await getAllCardLeaders();
  } catch {
    // cards stay undefined — the UI hides the section, the table itself is untouched
  }
  return { scorers: merged, assists, perLeague, cards, updatedAt: new Date().toISOString() };
}

/**
 * Global card leaders merged across all leagues (cycle-50). Domestic leagues
 * are attributed first and UCL last — a player listed in both competitions
 * keeps the domestic entry (same rule as the team index). Dense global rank
 * per kind, top 10 each.
 */
export async function getAllCardLeaders(): Promise<GlobalCardsData> {
  const ordered = [...LEAGUES].sort((a, b) => (a.key === "ucl" ? 1 : 0) - (b.key === "ucl" ? 1 : 0));
  const jobs = ordered.flatMap((lg) =>
    (["yellow", "red"] as const).map(async (kind) => ({
      lg,
      kind,
      rows: await getLeagueCardLeaders(lg.key, kind, 15),
    }))
  );
  const settled = await Promise.allSettled(jobs);
  const build = (kind: CardKind): GlobalCard[] => {
    const merged: GlobalCard[] = [];
    const seen = new Set<number>();
    for (const r of settled) {
      if (r.status !== "fulfilled" || r.value.kind !== kind) continue;
      const { lg } = r.value;
      for (const row of r.value.rows) {
        if (row.playerId == null || seen.has(row.playerId)) continue;
        seen.add(row.playerId);
        merged.push({ ...row, rank: 0, leagueKey: lg.key, leagueFa: lg.faName });
      }
    }
    merged.sort((a, b) => b.value - a.value || a.name.localeCompare(b.name));
    merged.forEach((c, i) => { c.rank = i + 1; });
    return merged.slice(0, 10);
  };
  return { yellow: build("yellow"), red: build("red") };
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

// ---------------- FotMob: team squad (data/teams endpoint, cycle-70) ----------------
// Probed live (2026-10-29, UA Chrome/124): https://www.fotmob.com/api/data/teams?id={teamId}
// is BACK — /api/team/[id] still carries the old comment "Team endpoint is gone"
// (true in cycle 10, no longer true). The payload carries squad.squad = groups:
// [{ title: "coach"|"keepers"|"defenders"|"midfielders"|"attackers", members: [...] }]
// with per-player season numbers (rating/goals/assists/cards), shirt, age,
// nationality (cname), injury flag and height. ccode3 is optional (works without).

export interface TeamSquadPlayer {
  id: number;
  name: string;
  shirt?: number;
  age?: number;
  nationality?: string;
  rating?: number;
  goals?: number;
  assists?: number;
  injured: boolean;
  height?: number;
}

export interface TeamSquad {
  coach: { id: number; name: string; age?: number; nationality?: string } | null;
  groups: {
    key: "keepers" | "defenders" | "midfielders" | "attackers";
    titleFa: string;
    players: TeamSquadPlayer[];
  }[];
}

const SQUAD_GROUP_FA: Record<string, string> = {
  keepers: "دروازه‌بان‌ها",
  defenders: "مدافعان",
  midfielders: "هافبک‌ها",
  attackers: "مهاجمان",
};

interface FMSquadMember {
  id?: number;
  name?: string;
  shirtNumber?: number | null;
  age?: number | null;
  cname?: string | null;
  rating?: number | null;
  goals?: number | null;
  assists?: number | null;
  injury?: unknown;
  height?: number | null;
  excludeFromRanking?: boolean;
}

export async function getTeamSquad(teamId: number): Promise<TeamSquad | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  return cached(`teamSquad:${teamId}`, 60 * 60_000, async () => {
    const raw = await fetchJson<{ squad?: { squad?: { title?: string; members?: FMSquadMember[] }[] } }>(
      `https://www.fotmob.com/api/data/teams?id=${teamId}`,
      15000
    );
    const list = raw?.squad?.squad;
    if (!Array.isArray(list) || list.length === 0) return null;

    let coach: TeamSquad["coach"] = null;
    const groups: TeamSquad["groups"] = [];
    for (const g of list) {
      const title = String(g?.title || "");
      const members = Array.isArray(g?.members) ? g.members : [];
      if (title === "coach") {
        const c = members[0];
        if (c?.id && c.name) {
          coach = { id: c.id, name: c.name, ...(c.age != null ? { age: c.age } : {}), ...(c.cname ? { nationality: c.cname } : {}) };
        }
        continue;
      }
      if (!SQUAD_GROUP_FA[title] || members.length === 0) continue;
      const players = members
        .filter((m) => m?.id && m.name)
        .map((m) => ({
          id: m.id as number,
          name: m.name as string,
          ...(m.shirtNumber != null ? { shirt: m.shirtNumber } : {}),
          ...(m.age != null ? { age: m.age } : {}),
          ...(m.cname ? { nationality: m.cname } : {}),
          ...(m.rating != null && m.rating > 0 ? { rating: m.rating } : {}),
          ...(m.goals ? { goals: m.goals } : {}),
          ...(m.assists ? { assists: m.assists } : {}),
          injured: Boolean(m.injury),
          ...(m.height ? { height: m.height } : {}),
        }));
      if (players.length === 0) continue;
      groups.push({ key: title as TeamSquad["groups"][number]["key"], titleFa: SQUAD_GROUP_FA[title], players });
    }
    if (groups.length === 0 && !coach) return null;
    return { coach, groups };
  });
}
