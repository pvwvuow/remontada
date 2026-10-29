// ------------------------------------------------------------------
// Remontada — server-side football data layer
// Primary:  FotMob (unofficial, keyless)
// Fallback: ESPN public APIs
// ------------------------------------------------------------------
import { LEAGUES, teamFa, fotmobTeamLogo, competitionFa } from "./leagues";
import { cached } from "./cache";
import { faDigits, jalaliShort } from "./format";
// cycle-99: canonical definition lives in @/lib/season (client-safe,
// dependency-free) so the league page's deep-link seeding guards the SAME
// regex without pulling this server graph into the client bundle.
import { SEASON_PARAM_RE } from "./season";
import { playerFa } from "./player-names-fa";
export { SEASON_PARAM_RE };

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

// cycle-127: transient-guard for the data.fotmob.com static per-season files
// (goals.json / *_card.json). These are one-shot gzip fetches on the cold
// path: when one gets dropped by a cold start the graceful producers below
// bake a THIN result (empty or topThree-only) into the 60-minute cache —
// the live incident logged in cycle-124, whose only self-heal was a full
// restart (an L2 purge alone was not enough because L1 held the payload).
// Two tries with a short pause close the transient class; the thin-TTL
// guard below still heals anything that slips through (a 90s re-probe
// instead of an hour-baked row, in BOTH L1 and L2 since they share the TTL).
async function fetchDataFile<T>(url: string): Promise<T> {
  try {
    return await fetchJson<T>(url);
  } catch {
    await new Promise((r) => setTimeout(r, 400));
    return await fetchJson<T>(url);
  }
}

// Full-season S3 files are ALWAYS wide (live-probed 2026-10-29: goals.json
// 298/130 rows for PL 2023/24 + 2000/01, yellow_card.json 438/204) while the
// degraded fallback lists carry only the category topThree (~3-4). Anything
// below these thresholds therefore means "the file fetch was dropped", not
// "the season had no scorers/cards".
const FULL_LIST_HEALTHY_MIN = 10;
const CARD_LIST_HEALTHY_MIN = 8;

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
  // cycle-90 additive: FotMob's xG table variant (same league payload, joined
  // by team id) — optional because only the big leagues + UCL carry it
  // (probed live 2026-10-28: PL/LaLiga/SerieA 20 rows, Bundesliga/Ligue1 18,
  // UCL 36, Persian Gulf none) and historical seasons may omit it too
  xg?: number;      // expected goals for (season total)
  xga?: number;     // expected goals against (xgConceded upstream)
  xPts?: number;    // expected points (xPoints upstream)
}

export interface ScorerEntry {
  rank: number;
  name: string;
  nameFa: string; // cycle-107: honest Persian display name (curated map hit, else the raw upstream name) — completes the 104-106 arc on league/standings scorer surfaces
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
  /** cycle-141 additive: composite league-phase feeds only (AFC CL Elite —
   *  West/East). `rows` stays the FLAT concatenation (West rows first, each
   *  region's own idx preserved — both regional leaders are rank 1, honest),
   *  and `groups` records the segment boundaries so the UI can draw the
   *  region section rows. Absent on every flat (domestic/UCL) feed. */
  groups?: { fa: string; count: number }[];
  home?: StandingsRow[];   // cycle-52 additive: FotMob per-side split (optional — hidden when absent)
  away?: StandingsRow[];
  scorers: ScorerEntry[];
  assists: AssistEntry[];
  /** cycle-92 additive: curated upstream season leaderboards (team + player
   *  podiums from raw.stats blocks) — hidden when the feed lacks them. */
  boards?: LeagueBoard[];
  /** cycle-102 additive metadata: the league sits inside the matchday window
   *  (live / recently finished / same-day upcoming kickoff) — the payload is
   *  stored with the short TTL. Absent on quiet days (and on pre-102 cached
   *  entries, which the TTL reader treats as quiet — old behavior). */
  matchday?: boolean;
  /** cycle-102 additive metadata: effective cache TTL in minutes (15 matchday
   *  / 60 quiet) so callers (and checks) can verify the freshness contract. */
  ttlMinutes?: number;
  /** cycle-111 additive: standings zone legend («راهنمای سهمیه‌ها») — the
   *  upstream table legend (qualification/relegation zones) rendered through
   *  the curated Persian tKey map; explains the per-row qualColor strips.
   *  Absent on feeds without a legend (persiangulf) and on pre-111 cached
   *  entries (self-heals at the next TTL — UI hides the section). */
  legend?: { fa: string; color: string }[];
  /** cycle-114 additive: true when the payload comes from the last-known-good
   *  snapshot (upstream outage — the /api/standings route serves the 24h
   *  snapshot instead of the honest 503) — the UI shows an honest
   *  «آخرین داده‌های ذخیره‌شده» notice. Never set on the live path. */
  stale?: boolean;
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
// cycle-92 probed: every stats row also carries a nested `stat` hint
// {value, format: fraction|percent|number|currency|kph, fractions} alongside
// the legacy flat `value` field.
interface FMStatPlayer { id: number; name: string; teamId?: number; teamName?: string; ccode?: string; value?: number; rank?: number; stat?: { name?: string; value?: number; format?: string; fractions?: number } }

// cycle-111: standings zone legend row (see STANDINGS_LEGEND_FA)
interface FMTableLegendRow {
  title?: string;
  tKey?: string;
  color?: string;
  indices?: number[];
  targetLeague?: { id?: number; name?: string; tKey?: string };
}
// cycle-111: standings zone legend — upstream tKey → curated Persian title
// (probed live, UA Chrome/124, 2026-10-29: 8 distinct tKeys across the
// European table-carrying leagues; cycle-136 added the two AFC tKeys of the
// now-live persiangulf table — tr_afcchampionsleague[0-1] + tr_afcccup[2],
// relegation rides the existing "relegation" key). Unknown tKeys never
// render (honest convention).
const STANDINGS_LEGEND_FA: Record<string, string> = {
  "championsleague": "لیگ قهرمانان اروپا",
  "europaleague": "لیگ اروپا",
  "europa_conference_league": "سهمیهٔ کنفرانس‌لیگ",
  "clqual": "سهمیهٔ لیگ قهرمانان",
  "q1of8finals": "صعود به یک‌هشتم نهایی",
  "q1of16finals": "صعود به یک‌شانزدهم نهایی",
  "relegationqual": "سهمیهٔ سقوط",
  "relegation": "سقوط",
  // cycle-136: Persian Gulf Pro League (league 523) — probed tKeys
  "tr_afcchampionsleague": "لیگ قهرمانان آسیا",
  "tr_afcccup": "لیگ قهرمانان آسیا ۲",
};

interface FotMobLeague {
  details?: { name?: string; seasons?: { year?: string; active?: boolean }[] };
  allAvailableSeasons?: string[];
  table?: { data?: {
    table?: { all?: FotMobRow[]; home?: FotMobRow[]; away?: FotMobRow[] };
    selectedSeason?: string;
    // cycle-141 probed (UA Chrome/124, 2026-10-29, league 525 AFC CL Elite):
    // COMPOSITE league-phase feeds — `composite: true` with the real tables
    // in `tables[]` (West/East regional sub-tables; `table` itself is an
    // EMPTY object there). Each sub-table carries the SAME row shape as a
    // domestic `all` block (probed keys identical) plus its own legend.
    composite?: boolean;
    tables?: {
      leagueId?: number;
      leagueName?: string;   // "West" / "East" on league 525
      table?: { all?: FotMobRow[] };
    }[];
    // cycle-111 probed (UA Chrome/124, 2026-10-29, 6 leagues): zone legend of
    // the standings — {title, tKey, color, indices} (+ targetLeague on
    // relegation rows). PL: championsleague[0-3]/europaleague[4]/relegation[17-19];
    // UCL league phase: q1of8finals/q1of16finals; Bundesliga/Ligue1 add
    // relegationqual; laliga/seriea add europa_conference_league.
    legend?: FMTableLegendRow[];
  } };
  // cycle-102: hasOngoingMatch typed (probed: boolean; null on payloads whose
  // fixtures block is absent — rare, since cycle-136 every configured league
  // serves a real fixtures block) — the matchday detector reads it for free
  fixtures?: { allMatches?: unknown[]; hasOngoingMatch?: boolean | null };
  // cycle-141 probed (UA Chrome/124, 2026-10-29, league 525): overview.
  // selectedSeason = the season the payload ACTUALLY serves (the composite
  // table block never echoes it) — the honesty marker for echo-less feeds.
  overview?: { selectedSeason?: string; season?: string };
  playoff?: { rounds?: FMBracketRoundRaw[] };
  // cycle-121 probed (UA Chrome/124, 2026-10-29): top-level seasons = the
  // league's FULL title history — one entry per completed season, newest
  // first: {seasonName, winner {id, name, seasonName, winner:true},
  // loser {…}} where winner = champion and loser = runner-up. Uniform:
  // pl=127 (oldest 1888), seriea=121 (1898), laliga=95 (1929), ucl=71
  // (1955/1956) — every entry carries both names; since cycle-136
  // persiangulf (league 523) serves it too (24 entries, 2001/2002 →
  // 2024/2025). Leagues without the list keep the honest absence path.
  seasons?: FMTitleSeasonRaw[];
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

// Thrown when FotMob has no usable payload for a league (a literal `null`
// body — historically the placeholder persiangulf id, today only transient
// upstream gaps). Routes translate this into a
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
// cycle-99: the SEASON_PARAM_RE definition moved to @/lib/season and is
// re-exported from the top of this file — API route consumers unchanged.

// ---------------- cycle-102: matchday-aware league payload TTL ----------------
// Registered cycle-93/98 candidate closed: on matchdays FotMob applies
// post-hoc corrections (goals, points, tie-break order — root-caused in 98
// on Serie A) minutes-to-hours AFTER kickoff, and the fixed 60-min
// leagueRaw/standings TTL served a stale snapshot for up to an hour.
// The data/leagues payload itself carries the full-season fixture list
// (fixtures.allMatches with ISO status.utcTime + the upstream
// hasOngoingMatch flag) → matchday detection is FREE: zero extra upstream.
// Matchday = any non-cancelled fixture kicking off inside the live window
// [now-5h, now+10h] (recently finished: the corrections window; live; same-
// day upcoming) or the upstream hasOngoingMatch flag. Matchday payloads are
// stored 15 min, quiet days keep the 60-min behavior. Null fixtures block
// (persiangulf design) → quiet.
const LEAGUE_TTL_QUIET = 60 * 60_000;
const LEAGUE_TTL_MATCHDAY = 15 * 60_000;

export function isLeagueMatchday(raw: FotMobLeague, now = Date.now()): boolean {
  if (raw?.fixtures?.hasOngoingMatch === true) return true;
  const WINDOW_START = 5 * 3600_000;
  const WINDOW_END = 10 * 3600_000;
  const all = raw?.fixtures?.allMatches;
  if (!Array.isArray(all)) return false;
  for (const m of all as FotMobFixture[]) {
    if (m?.status?.cancelled) continue;
    const t = m?.status?.utcTime ? Date.parse(m.status.utcTime) : NaN;
    if (Number.isNaN(t)) continue;
    if (t <= now + WINDOW_END && t >= now - WINDOW_START) return true;
  }
  return false;
}

function leagueTtl(raw: FotMobLeague): number {
  return isLeagueMatchday(raw) ? LEAGUE_TTL_MATCHDAY : LEAGUE_TTL_QUIET;
}

// Fetch + cache the (heavy) league payload once; standings & fixtures share it
async function getLeagueRaw(leagueKey: string, season?: string): Promise<{ lg: (typeof LEAGUES)[number]; raw: FotMobLeague }> {
  const lg = LEAGUES.find((l) => l.key === leagueKey);
  if (!lg) throw new Error(`Unknown league: ${leagueKey}`);
  // NOTE: the null/invalid guard lives INSIDE the cached producer so an
  // unusable payload is never cached — each request retries upstream.
  // update cycle-102: the TTL is payload-derived (matchday-aware) — the same
  // raw payload the producer just fetched decides whether it is stored for
  // 15 min (matchday) or 60 min (quiet day).
  const raw = await cached(`leagueRaw:${leagueKey}:${season || "cur"}`, (data) => leagueTtl(data as FotMobLeague), async () => {
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

// ---------------- FotMob: league season boards («برترین‌های رسمی فصل», cycle-92) ----------------
// Probed live (2026-10-29, UA Chrome/124): raw.stats carries 40+ PLAYER and
// 30 TEAM leaderboard blocks {header, participant, topThree:[{name/teamId/
// id, stat:{value, format, fractions}}]} — the app only ever read the scorer/
// assist/rating/minutes categories as scorer-table enrichment. The curated
// boards below surface the rest (possession, clean sheets, attendance, squad
// value, top speed, dribbles, GK goals-prevented…) on the league stats tab.
// Categories are hidden when a league's feed lacks them (e.g. Top speed is
// PL-only) and the whole section hides when the payload has none.

export type LeagueBoardFmt = "fraction" | "percent" | "number" | "currency" | "kph";

export interface LeagueBoardRow {
  rank: number;
  name: string;
  nameFa?: string; // cycle-107: player rows only — honest Persian display name
  teamFa?: string; // player rows: their club (fa when known)
  teamId?: number;
  value: number;
  playerId?: number; // player rows → /player/{id}
}

export interface LeagueBoard {
  kind: "team" | "player";
  header: string; // upstream header (stable React key)
  headerFa: string;
  subFa?: string;
  fmt: LeagueBoardFmt; // from the payload's stat.format hint
  fractions: number; // from the payload's stat.fractions hint
  rows: LeagueBoardRow[]; // podium (≤3), payload order = ranking order
}

/** Curated board catalog: upstream header → Persian title (+subtitle). */
const LEAGUE_BOARD_FA: Partial<Record<"team" | "player", Record<string, { fa: string; sub?: string }>>> = {
  team: {
    "Average possession": { fa: "میانگین مالکیت توپ", sub: "درصد مالکیت در بازی‌های فصل" },
    "Clean sheets": { fa: "کلین‌شیت", sub: "بازی‌های بدون گل خورده" },
    Attendance: { fa: "میانگین تماشاگر خانه", sub: "میانگین حضور در ورزشگاه" },
    "Squad value": { fa: "ارزش بازار ترکیب", sub: "جمع ارزش نقل‌وانتقالی بازیکنان" },
    "FotMob rating": { fa: "امتیاز فوت‌ماب تیم", sub: "میانگین نمره بازی‌ها" },
    "Goals per match": { fa: "گل زده در هر بازی", sub: "قدرت آفنسیو فصل" },
  },
  player: {
    "FotMob rating": { fa: "امتیاز فوت‌ماب", sub: "میانگین نمره بازی‌ها" },
    "Top speed": { fa: "بیشترین سرعت", sub: "بر حسب کیلومتر بر ساعت" },
    "Big chances created": { fa: "موقعیت طلایی ساخته", sub: "پاس‌های منجر به موقعیت پنهان" },
    "Successful dribbles per 90": { fa: "دریبل موفق در هر ۹۰ دقیقه", sub: "میانگین دریبل‌های برنده" },
    "Goals prevented": { fa: "گل مهارشده", sub: "دروازه‌بان‌ها؛ منفی = بیش از انتظار گل خورده" },
    "Accurate passes per 90": { fa: "پاس دقیق در هر ۹۰ دقیقه", sub: "میانگین پاس‌های درست" },
  },
};

/** Team-block row of the stats payload: name=team name, teamId, stat hint. */
interface FMStatTeamRow {
  name?: string;
  teamId?: number;
  stat?: { value?: number; format?: string; fractions?: number };
}

interface FMStatBlockTeam {
  header?: string;
  participant?: FMStatTeamRow;
  topThree?: FMStatTeamRow[];
}

/**
 * Extract the curated season boards («برترین‌های رسمی فصل», cycle-92) from
 * the SAME cached leagueRaw payload — zero extra upstream hit. Podium rows =
 * participant (the leader) + topThree deduped, capped at 3, payload order
 * preserved (it is the ranking order). Boards missing from the feed are
 * skipped; empty result → section hidden upstream of the UI.
 */
function extractLeagueBoards(raw: FotMobLeague): LeagueBoard[] {
  const src = raw.stats as
    | { players?: (FMStatBlock & { participant?: FMStatPlayer })[]; teams?: FMStatBlockTeam[] }
    | undefined;
  const boards: LeagueBoard[] = [];
  const pick = (
    kind: "team" | "player",
    blocks: (FMStatBlock | FMStatBlockTeam)[] | undefined,
    idOf: (r: FMStatPlayer | FMStatTeamRow) => number | undefined
  ) => {
    const catalog = LEAGUE_BOARD_FA[kind] || {};
    for (const block of blocks || []) {
      const header = String(block?.header || "");
      const label = catalog[header];
      if (!label) continue; // not curated → skip
      const rowsRaw = [block.participant, ...(block.topThree || [])].filter(
        (r): r is FMStatPlayer | FMStatTeamRow => !!r && !!r.name
      );
      const seen = new Set<number>();
      const rows: LeagueBoardRow[] = [];
      for (const r of rowsRaw) {
        const id = idOf(r);
        if (id != null && seen.has(id)) continue;
        if (id != null) seen.add(id);
        const stat = r.stat || {};
        const value = Number(stat.value);
        if (!Number.isFinite(value)) continue;
        const fmt = String(stat.format || "fraction");
        // player rows carry their club (teamId + fa name) separately from the
        // player id (which powers the /player/{id} link); team rows ARE clubs
        const row =
          kind === "player"
            ? {
                rank: rows.length + 1,
                name: String(r.name),
                nameFa: playerFa(String(r.name)),
                ...((r as FMStatPlayer).teamName
                  ? { teamFa: teamFa((r as FMStatPlayer).teamName) || (r as FMStatPlayer).teamName }
                  : {}),
                ...((r as FMStatPlayer).teamId != null && Number((r as FMStatPlayer).teamId) > 0
                  ? { teamId: Number((r as FMStatPlayer).teamId) }
                  : {}),
                ...(id != null && id > 0 ? { playerId: id } : {}),
                value,
              }
            : {
                rank: rows.length + 1,
                name: String(r.name),
                ...(id != null && id > 0 ? { teamId: id } : {}),
                value,
              };
        rows.push(row);
      }
      if (rows.length === 0) continue;
      const hint = rowsRaw[0]?.stat || {};
      boards.push({
        kind,
        header,
        headerFa: label.fa,
        ...(label.sub ? { subFa: label.sub } : {}),
        fmt: (["fraction", "percent", "number", "currency", "kph"].includes(hint.format || "")
          ? hint.format
          : "fraction") as LeagueBoardFmt,
        fractions: Number.isFinite(Number(hint.fractions)) ? Number(hint.fractions) : 1,
        rows,
      });
    }
  };
  pick("team", src?.teams, (r) => (r as FMStatTeamRow).teamId);
  pick("player", src?.players as unknown as (FMStatBlock | FMStatBlockTeam)[] | undefined, (r) => (r as FMStatPlayer).id);
  return boards;
}

/**
 * Full-season goals list (cycle-23): the league payload's "Top scorer"
 * category exposes only participant + topThree (~4 names), but it also
 * carries a `fetchAllUrl` pointing at a static S3 file with the complete
 * ranking (100+ rows). Returns up to `limit` entries, de-duplicated by
 * player id. Fully graceful — any failure returns [] and callers fall
 * back to the short category list.
 */
// cycle-124: season-aware — the caller (getStandings) serves BOTH current and
// historical season views, so this file fetch MUST follow the requested
// season or the merge below leaks the CURRENT season's goal counts into
// historical views (live-proven incident: /league/pl?season=2023/2024 ranked
// João Pedro 5-goals 4th — a 2026/27 count — right after the true 2023/24
// topThree, because the old season-blind fetch appended the current goals.json
// under it; Watkins 19 / Foden 19 / Solanke 19 were displaced). The seasonal
// raw carries the season's OWN fetchAllUrl (probed live: 2023/2024 PL →
// data.fotmob.com/stats/47/season/20720/goals.json = 298 rows, Haaland 27 ✓),
// so one parameter both fixes the leak AND gives historical views the full
// per-season depth (current behavior byte-identical: current fetchAllUrl is
// the same file). Cache key bumped v2→v3 so no mixed payload survives the
// deploy.
export async function getFullGoalScorers(leagueKey: string, limit = 20, season?: string): Promise<ScorerEntry[]> {
  try {
    return await cached(
      `fullGoals:v3:${leagueKey}:${season || "cur"}`,
      // cycle-127 thin-TTL guard: a healthy full-season list keeps the exact
      // 60-minute TTL; a thin one (dropped transient fetch, or a league
      // payload without the category) is baked for 90 SECONDS only, so the
      // next generation re-probes and self-heals without a restart. The
      // re-probe is upstream-free: it reads the already-cached league payload.
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
      // v2 (cycle-107): rows gained the required `nameFa` — old v1 entries
      // would violate the ScorerEntry shape (same convention as standings v5)
      const { raw } = await getLeagueRaw(leagueKey, season);
      const cat = raw.stats?.players?.find?.((p) => /top scorer/i.test(p.header || ""));
      const url = cat?.fetchAllUrl;
      if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
      const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
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
          nameFa: playerFa(r.ParticipantName),
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
      }
    );
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
    return freshCardNames(
      await cached(
        `cards:${leagueKey}:${kind}`,
        // cycle-127 thin-TTL guard (same class as getFullGoalScorers):
        // full card files are always wide (live-probed 438/204 yellow rows),
        // the topThree fallback is ~3-4 — thin rows re-probe after 90s
        // instead of baking for an hour.
        (rows) => (rows.length >= CARD_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
        async () => {
      const { raw } = await getLeagueRaw(leagueKey);
      const re = kind === "yellow" ? /^yellow cards$/i : /^red cards$/i;
      const cat = raw.stats?.players?.find?.((p) => re.test(p.header || ""));
      if (!cat) return [];
      const out: Omit<GlobalCard, "rank" | "leagueKey" | "leagueFa">[] = [];
      const seen = new Set<number>();
      if (cat.fetchAllUrl && /^https:\/\/data\.fotmob\.com\//.test(cat.fetchAllUrl)) {
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(cat.fetchAllUrl);
        const rows = data?.TopLists?.[0]?.StatList || [];
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
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
            nameFa: playerFa(p.name),
            team: teamFa(p.teamName || undefined) || p.teamName || "",
            teamId: p.teamId ?? 0,
            value: Math.round(p.value ?? 0),
            playerId: p.id,
          });
        }
      }
      return out;
        }
      )
    );
  } catch {
    return [];  // unavailable league / upstream hiccup — never break the merge
  }
}

// cycle-109: read-time honest-name freshening. The L2 (SQLite) cache stores
// payloads whose nameFa/team strings were computed with WHATEVER the curated
// maps said at BUILD time — a map addition used to stay invisible for up to a
// full TTL generation (seen live this cycle: the per-league scorers page kept
// raw English rows while the global page, which maps at read time, was
// already Persian). Re-applying the maps on EVERY read makes the curated
// maps always-current regardless of cache age. Idempotent by construction:
// an already-Persian string never matches the English-keyed maps and falls
// back to itself (teamFa returns the input on miss).
function freshenHonestNames(st: StandingsData): StandingsData {
  const rowFa = (r: StandingsRow): StandingsRow => ({ ...r, fa: teamFa(r.name) || r.fa });
  return {
    ...st,
    rows: st.rows.map(rowFa),
    ...(st.home ? { home: st.home.map(rowFa) } : {}),
    ...(st.away ? { away: st.away.map(rowFa) } : {}),
    scorers: st.scorers.map((s) => ({ ...s, nameFa: playerFa(s.name), team: teamFa(s.team) || s.team })),
    assists: st.assists.map((a) => ({ ...a, team: teamFa(a.team) || a.team })),
    ...(st.boards
      ? {
          boards: st.boards.map((b) =>
            b.kind === "player"
              ? {
                  ...b,
                  rows: b.rows.map((r) => ({
                    ...r,
                    nameFa: playerFa(r.name),
                    ...(r.teamFa ? { teamFa: teamFa(r.teamFa) || r.teamFa } : {}),
                  })),
                }
              : b,
          ),
        }
      : {}),
  };
}

/** cycle-109: same read-time freshening for the cards cache family (60-min TTL) —
 * a map addition must not stay invisible for a full generation on the
 * «آقای کارت» section either. Idempotent like freshenHonestNames. */
function freshCardNames<T extends { name: string; nameFa: string; team: string }>(rows: T[]): T[] {
  return rows.map((r) => ({ ...r, nameFa: playerFa(r.name), team: teamFa(r.team) || r.team }));
}

export async function getStandings(leagueKey: string, season?: string): Promise<StandingsData> {
  const { lg, raw } = await getLeagueRaw(leagueKey, season);
  // cycle-124: capture the REQUESTED season before build()'s own local `season`
  // (line below the merge — raw.details.seasons is always empty per the
  // cycle-94 probe) shadows the parameter inside this block; the full-goals
  // fetch must follow the same season the raw was fetched with
  const requestedSeason = season;
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
    // cycle-141: COMPOSITE league-phase feeds (AFC Champions League Elite —
    // probed live UA Chrome/124, 2026-10-29, league 525). Upstream splits the
    // league phase into regional sub-tables under data.tables[] (West/East,
    // same FotMobRow shape each) and leaves data.table EMPTY — a domestic
    // read of fmTable.all would throw "No standings data". Flatten West→East
    // with each region's own idx preserved (both regional leaders stay rank
    // 1 — re-indexing 1..32 would strip the East podium, a dishonest table),
    // and record the segments in `groups` (curated Persian labels, unknown
    // names fall back to the raw string) so the UI draws the region rows.
    // The 9 flat feeds never enter this branch — byte-identical output.
    const COMPOSITE_REGION_FA: Record<string, string> = {
      west: "منطقهٔ غرب", east: "منطقهٔ شرق",
      // cycle-157: ACL Two serves eight four-team group sub-tables
      // (leagueName "Group A".."Group H") — Persian labels with the
      // Latin group letter, the standard Persian sports convention
      "group a": "گروه A", "group b": "گروه B", "group c": "گروه C", "group d": "گروه D", "group e": "گروه E", "group f": "گروه F", "group g": "گروه G", "group h": "گروه H",
    };
    const compositeSubs = raw.table?.[0]?.data?.composite === true ? raw.table?.[0]?.data?.tables : undefined;
    const rows: StandingsRow[] = [];
    const groups: { fa: string; count: number }[] = [];
    if (Array.isArray(compositeSubs) && compositeSubs.length > 0) {
      for (const sub of compositeSubs) {
        const mapped = ((sub?.table?.all || []) as FotMobRow[]).map((r) => mapRow(r, true));
        rows.push(...mapped);
        if (mapped.length > 0) {
          groups.push({
            fa: COMPOSITE_REGION_FA[(sub?.leagueName || "").toLowerCase()] || sub?.leagueName || "",
            count: mapped.length,
          });
        }
      }
    } else {
      rows.push(...(fmTable?.all || []).map((r) => mapRow(r, true)));
    }
    if (rows.length === 0) throw new Error("No standings data");

    // update cycle-111: zone legend («راهنمای سهمیه‌ها») — the upstream table
    // legend explains the per-row qualColor strips the portal has rendered
    // since the beginning with no explanation. tKey → curated Persian title;
    // unknown tKeys drop (honest convention). Additive optional field
    // (cycle-102 precedent: no cache-key bump — pre-111 entries lack it, the
    // UI hides the section, and it self-heals at the next TTL).
    const legendRows = raw.table?.[0]?.data?.legend || [];
    const legend: NonNullable<StandingsData["legend"]> = legendRows
      .map((l) => {
        const fa = l.tKey ? STANDINGS_LEGEND_FA[l.tKey] : undefined;
        return fa && l.color ? { fa, color: l.color } : null;
      })
      .filter((x): x is { fa: string; color: string } => x !== null);

    // cycle-90: join the xG table variant by team id — the SAME cached league
    // payload mirrors the table with expected-goals metrics (xg / xgConceded /
    // xPoints; live-probed 2026-10-28). Optional: only the big leagues + UCL
    // ship it (Persian Gulf has no table at all) and historical seasons may
    // omit it, so rows simply stay without xg fields and the UI hides the section.
    const xgRows = ((fmTable as { xg?: { id?: number; teamId?: number; xg?: number; xgConceded?: number; xPoints?: number }[] } | undefined)?.xg) || [];
    if (xgRows.length > 0) {
      const xgById = new Map<number, { xg?: number; xgConceded?: number; xPoints?: number }>();
      for (const x of xgRows) {
        const xid = x.id ?? x.teamId;
        if (xid == null) continue;
        xgById.set(xid, x);
      }
      for (const row of rows) {
        const x = xgById.get(row.teamId);
        if (!x) continue;
        if (typeof x.xg === "number") row.xg = Math.round(x.xg * 100) / 100;
        if (typeof x.xgConceded === "number") row.xga = Math.round(x.xgConceded * 100) / 100;
        if (typeof x.xPoints === "number") row.xPts = Math.round(x.xPoints * 100) / 100;
      }
    }
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
        rank: s.rank ?? i + 1, name: s.name, nameFa: playerFa(s.name), team: teamFa(s.teamName, ) || s.teamName || "",
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
    // cycle-124: season flows through — historical views merge the season's
    // own goals file (see getFullGoalScorers comment for the live-proven leak)
    const fullScorers = await getFullGoalScorers(leagueKey, 24, requestedSeason);
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

    // ⚠️ cycle-94 probe (UA Chrome/124): `details.seasons` is EMPTY in every
    // data/leagues payload — current AND historical (e.g. ?season=2020/2021) —
    // so this local is always "" and the honest label lives in selectedSeason
    // (raw.table[0].data.selectedSeason = the REQUESTED season). Every
    // consumer of the mapped `season` field must treat it as optional.
    const season = raw.details?.seasons?.find?.((s) => s.active)?.year || "";
    // cycle-55: FotMob's own selected-season label + the seasons it offers —
    // additive fields so the v2 cache shape stays backward compatible.
    // cycle-141: composite cups never echo selectedSeason in the table block
    // (live-probed league 525: absent on every request) — but overview.
    // selectedSeason carries the ACTUALLY SERVED season (probed: 2024/2025
    // request → "2024/2025"; a bogus 2019/2020 request silently serves the
    // current table and the marker says "2026/2027" — the exact cycle-99
    // honest-snap contract, just carried by a different field). The marker
    // chain therefore ends at overview, never at the requested param: the
    // league-view snap (selectedSeason ≠ season → strip URL) keeps working
    // for echo-less feeds. The 9 echo-carrying feeds never reach it.
    const selectedSeason = raw.table?.[0]?.data?.selectedSeason
      || raw.overview?.selectedSeason
      || season
      || undefined;
    const allSeasons = Array.isArray(raw.allAvailableSeasons)
      ? raw.allAvailableSeasons.filter((s) => SEASON_PARAM_RE.test(s)).slice(0, 12)
      : undefined;
    // cycle-92: curated upstream season boards (same leagueRaw, zero extra hit)
    const boards = extractLeagueBoards(raw);
    // cycle-102: freshness metadata — the SAME raw payload decides whether
    // this mapped value (and its leagueRaw source) is stored 15 min
    // (matchday) or 60 min (quiet). ttlMinutes is always set for fresh
    // builds; the cached() TTL reader falls back to quiet for pre-102
    // entries (old behavior preserved for one TTL generation).
    const matchday = isLeagueMatchday(raw);
    return {
      leagueKey, leagueFa: lg.faName, season, rows,
      ...(groups.length > 0 ? { groups } : {}),
      ...(selectedSeason ? { selectedSeason } : {}),
      ...(allSeasons && allSeasons.length > 1 ? { allSeasons } : {}),
      ...(homeRows ? { home: homeRows } : {}),
      ...(awayRows ? { away: awayRows } : {}),
      ...(boards.length > 0 ? { boards } : {}),
      ...(matchday ? { matchday: true } : {}),
      ttlMinutes: matchday ? 15 : 60,
      scorers: mergedScorers,
      assists: assistEntries,
      ...(legend.length > 0 ? { legend } : {}),
      updatedAt: new Date().toISOString(),
    };
  };
  // cycle-52: payload shape gained additive `home`/`away` → key bumped to v2
  // so the L2 (SQLite) cache cannot serve the old shape for its 60-min TTL
  // cycle-55: per-season cache keys ("cur" keeps the old key string for the
  // current season, so existing cache entries stay valid)
  // v3 (cycle-90): mapped row shape gained the optional xg/xga/xPts fields —
  // old v2 entries (without them) would keep the xG section hidden for an hour
  // v4 (cycle-92): mapped shape gained the optional `boards` field (upstream
  // season leaderboards) — old v3 entries would keep the section hidden an hour
  // cycle-102: TTL is now payload-derived (15 min matchday / 60 min quiet) —
  // NO key bump: the added matchday/ttlMinutes fields are metadata-only (no
  // UI consumer), and the TTL reader falls back to the old 60-min behavior
  // for pre-102 entries still inside their TTL (one generation, self-heals).
  // v5 (cycle-107): mapped shape gained the REQUIRED `nameFa` on ScorerEntry
  // rows (and nameFa on player LeagueBoardRow rows) — the honest-name arc
  // completes on the league/standings scorer surfaces; old v4 entries would
  // violate the required field (same convention as cycle-52/86/87/96/106).
  // ⚠️ cycle-94: the key deliberately uses the REQUESTED `season` PARAMETER
  // (in function scope), NOT the payload-derived local inside build — that
  // local is always "" (details.seasons is empty upstream), so keying on it
  // would collide the current season and EVERY historical season of a league
  // into `:cur` for the whole 60-min TTL. Verified: 2020/2021 and current
  // responses stay distinct end-to-end (honest rows/boards/xG both ways).
  // v6 (cycle-124): correctness bump — v5 historical entries were built with
  // the season-blind full-goals merge (getFullGoalScorers without season) and
  // carry CURRENT-season goal counts inside historical scorers lists
  // (live-proven: 2023/2024 PL ranked João Pedro 5-goals 4th). The producer
  // is now season-pure; v6 forces an immediate clean rebuild instead of
  // serving the mixed payloads for up to a full TTL generation.
  return freshenHonestNames(
    await cached(`standings:v6:${leagueKey}:${season || "cur"}`, (mapped) =>
      // cycle-127 thin-scorers guard (closes the cycle-124 incident class
      // END-TO-END): the merged scorers list rides on this cached entry, so
      // even with the thin-TTL on fullGoals itself a thin merged list would
      // stay visible for a full ttlMinutes generation (the thin fullGoals row
      // expires but nothing re-runs build()). A thin scorers list — dropped
      // goals.json fetch, or a payload without the stats block — now re-probes
      // in 90s (upstream-free: reads the cached leagueRaw); healthy tables
      // keep the exact matchday-aware TTL.
      Array.isArray(mapped.scorers) && mapped.scorers.length >= FULL_LIST_HEALTHY_MIN
        ? typeof mapped.ttlMinutes === "number" ? mapped.ttlMinutes * 60_000 : LEAGUE_TTL_QUIET
        : 90_000,
      build),
  );
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
  // cycle-86 probed: explicit false for non-captains, absent on some payloads
  isCaptain?: boolean;
  status?: string;
  birthDate?: { utcTime?: string } | null;
  primaryTeam?: { teamId?: number; teamName?: string; onLoan?: boolean } | null;
  // cycle-135 probed (UA Chrome/124, 2026-10-29): beyond the one
  // `primaryPosition` label mapped since the beginning, the payload carries
  // the FULL multi-position map — `positions[]` (Raphinha: 6 entries, each
  // {strPos:{label,key}, occurences, isMainPosition, pitchPositionData}) and
  // `nonPrimaryPositions`. We map only the label + occurrence count + main
  // flag (pitchPositionData is a per-entry pitch blob not needed for the
  // «پست‌های بازی» chips; kept unmapped on purpose). Optional + additive:
  // absence (coach payloads, odd feeds) → the profile section simply hides.
  positionDescription?: {
    primaryPosition?: { label?: string };
    positions?: { strPos?: { label?: string; key?: string }; occurences?: number; isMainPosition?: boolean }[];
  } | null;
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
  // cycle-82: deep season performance, peer traits, market-value history (all optional)
  // cycle-87 probed: firstSeasonStats also carries the season pitch data —
  // shotmap (outfield, 30 items on Haaland: eventType Goal/AttemptSaved/Miss,
  // x/y 0-100, minute, isOnTarget/isBlocked, expectedGoals), keeperShotmap
  // (GK, 38 items on Sinisalo — shots FACED, playerName = the shooter) and
  // heatmap.coordinates ({x,y} touches, 248-523 items)
  firstSeasonStats?: {
    statsSection?: {
      title?: string;
      items?: {
        title?: string;
        items?: {
          localizedTitleId?: string;
          title?: string;
          statValue?: string | number | null;
          per90?: number | null;
          percentileRank?: number | null;
          statFormat?: string;
        }[] | null;
      }[] | null;
    } | null;
    shotmap?: FMShotRaw[] | null;
    keeperShotmap?: FMShotRaw[] | null;
    heatmap?: { coordinates?: { x?: number; y?: number }[] | null } | null;
  } | null;
  traits?: {
    key?: string; title?: string;
    items?: { key?: string; title?: string; value?: number }[] | null;
  } | null;
  marketValues?: {
    values?: {
      date?: string; value?: number; currency?: string;
      teamId?: number; teamName?: string;
    }[] | null;
  } | null;
  // cycle-96 probed (UA Chrome/124, 23 live samples over 6 squads, 2026-10-29):
  // present ONLY for currently-unavailable players — a single object (never an
  // array), null for every available player. Shape: {name ("Thigh injury",
  // "Knock", "Physical discomfort", "Cruciate ligament injury"…), key
  // (injury_NN), expectedReturn {expectedReturnKey enum: expected_return_date_
  // early|mid|late + expectedReturnDateParam as MONTH TEXT ("November 2026",
  // never ISO) | expected_return_date_doubtful | expected_return_date_back_
  // in_training, both without a dateParam), lastUpdated {utcTime}}.
  // Complements the bare «مصدوم» squad flag (data/teams members[].injury) with
  // the WHY/until-WHEN the portal nowhere showed.
  injuryInformation?: {
    name?: string;
    key?: string;
    expectedReturn?: {
      expectedReturnKey?: string;
      expectedReturnDateParam?: string | null;
      expectedReturnFallback?: string;
    } | null;
    lastUpdated?: { utcTime?: string } | null;
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
  // cycle-86: which of the player's sides this appearance was for (club vs
  // national team) — powers the recent-matches side filter
  sideId: number;
  sideName: string;
}
export interface PlayerRecentSide { id: number; fa: string }
// cycle-87: season pitch data (shot map + touch heatmap) from firstSeasonStats
export interface PlayerShot {
  min: number;
  x: number; // 0-100, toward the opponent goal
  y: number; // 0-100, pitch width
  goal: boolean;
  onTarget: boolean;
  blocked: boolean;
  xg: number | null;
  typeFa: string | null; // «پای راست»/«پای چپ»/«سر»
  by: string | null;     // keeper view only: the shooter's name
}
export interface PlayerPitch {
  keeper: boolean;       // true → shots are shots FACED (GK)
  shots: PlayerShot[];
  goals: number;         // scored (outfield) / conceded (GK)
  xgTotal: number | null;
  heat: { x: number; y: number }[];
}
// cycle-135: one entry of the player's multi-position map («پست‌های بازی»).
// `occurrences` = how many official lineups the player featured there per
// FotMob's own tally; `isMain` = the payload's isMainPosition flag. Sorted
// main-first, then by occurrences — the UI renders them as chips in that
// honest order (no re-ranking of our own).
export interface PlayerPositionSpot {
  fa: string; // precise Persian label (faPositionDetail), English kept for title/tooltip
  en: string; // raw upstream label, e.g. "Left Winger"
  occurrences: number;
  isMain: boolean;
}

export interface PlayerData {
  id: string;
  name: string;
  nameFa: string; // cycle-106: honest Persian display name for the profile h1 (curated map hit, else the raw upstream name)
  positionFa: string | null;
  positionEn: string | null;
  // cycle-135: full multi-position map from positionDescription.positions
  // («پست‌های بازی» chips on the profile). OPTIONAL by contract — coach/odd
  // payloads legitimately lack it → the section hides (same honesty pattern
  // as pitch/traits/market). Cache key still bumped to v6 because the
  // NORMALIZED output changed (map added + refined keeper fa label) and a
  // stale v5 shape would serve unrefined labels for the TTL window.
  positions?: PlayerPositionSpot[];
  status: string;
  team: { id: number; name: string; fa: string; logo: string } | null;
  info: {
    age?: number; height?: string; shirt?: number; foot?: string;
    country?: string; countryCcode?: string; marketValue?: string; contractEnd?: string;
  };
  season: { leagueFa: string; season: string; stats: PlayerSeasonStat[] } | null;
  recent: PlayerRecentMatch[];
  // cycle-86: sides appearing in `recent` (club + national), first-seen order;
  // single-element when the archive only covers the current club
  recentTeams: PlayerRecentSide[];
  // cycle-87: season shot map + touch heatmap (null → section hidden)
  pitch: PlayerPitch | null;
  // cycle-86: probed playerData.isCaptain (explicit false when not captain,
  // absent for some payloads → mapped to false)
  isCaptain: boolean;
  next: { id: string; utcTime: string; opponent: string; opponentId: number; opponentLogo: string; isHome: boolean; leagueFa: string } | null;
  career: PlayerCareerEntry[];       // senior + national-team stops, newest first
  careerYouth: PlayerCareerEntry[];  // youth/academy stops (hidden section when empty)
  trophies: PlayerTrophy[];          // honours (league/team + winning seasons)
  deepStats: PlayerDeepGroup[] | null; // cycle-82: «عملکرد فصل» grouped detailed season stats
  traits: PlayerTraits | null;         // cycle-82: percentile comparison vs positional peers
  market: PlayerMarket | null;         // cycle-82: market-value history sparkline
  // cycle-96: current availability status from injuryInformation (null → the
  // whole section is hidden; most players carry null)
  injury: PlayerInjury | null;
  fetchedAt: string;
}

export interface PlayerInjury {
  nameFa: string;       // Persian type of the injury (raw upstream text when unmapped)
  nameEn?: string;      // kept only when a Persian mapping exists (UI title attr)
  returnFa: string | null;   // expected return in Persian; null → row omitted (honest absence)
  updatedFa: string | null;  // Jalali last-updated date, null when upstream lacks it
}

export interface PlayerDeepStat { fa: string; value: string; per90: string | null; pct: number | null }
export interface PlayerDeepGroup { fa: string; stats: PlayerDeepStat[] }
export interface PlayerTraits { titleFa: string; items: { fa: string; pct: number }[] }
export interface PlayerMarket {
  current: string; currentTeamFa: string | null;
  sinceValue: string; sinceTeamFa: string | null; sinceYear: string;
  points: number[];  // chronological EUR values for the sparkline
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

// cycle-135: side-aware refinement used ONLY by the «پست‌های بازی» chips.
// faPosition deliberately stays untouched — it feeds the profile sub-line and
// other surfaces whose labels are part of the proven contract (regression 28/28
// asserts none of them, but the honest-additive rule says new mapper for new
// surface). Falls back to faPosition for anything it does not refine.
function faPositionDetail(label?: string): string | null {
  const l = (label || "").toLowerCase();
  if (!l) return null;
  if (l.includes("centre back") || l.includes("center back") || l.includes("centre-back") || l.includes("center-back")) return "مدافع میانی";
  // cycle-135 probed: some payloads label the GK spot just "Keeper" (Joan
  // García id=1167220) while others use the full "Goalkeeper" — both are
  // the same spot. Refined here only; faPosition ("Goalkeeper"-only) keeps
  // its proven behaviour on existing surfaces.
  if (l.includes("keeper")) return "دروازه‌بان";
  if (/^right back|right back$/.test(l) || l.includes("right-back") || l.includes("rightback")) return "دفاع راست";
  if (/^left back|left back$/.test(l) || l.includes("left-back") || l.includes("leftback")) return "دفاع چپ";
  if (l.includes("right midfield")) return "هافبک راست";
  if (l.includes("left midfield")) return "هافبک چپ";
  const base = faPosition(l);
  if (base) return base;
  if (l.includes("second striker")) return "مهاجم دوم";
  if (l.includes("midfield")) return "هافبک";
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

// ---------------- cycle-82: player deep season stats / traits / market history ----------------

const PLAYER_DEEP_GROUP_FA: Record<string, string> = {
  shooting: "شوت",
  physical: "فیزیک",
  passing: "پاس",
  possession: "مالکیت توپ",
  defending: "دفاع",
  discipline: "انضباط",
  goalkeeping: "دروازه‌بانی",
  distribution: "توزیع توپ",
};

const PLAYER_DEEP_STAT_FA: Record<string, string> = {
  goals: "گل",
  expected_goals: "xG",
  expected_goals_on_target: "xGOT",
  non_penalty_xg: "xG بدون پنالتی",
  shots: "شوت",
  ShotsOnTarget: "شوت در چارچوب",
  headed_shots: "شوت با سر",
  physical_metrics_topspeed: "بیشترین سرعت",
  physical_metrics_distance_covered: "مسافت پیموده‌شده",
  physical_metrics_running: "دویدن",
  physical_metrics_sprinting: "اسپرینت",
  physical_metrics_number_of_sprints: "تعداد اسپرینت",
  assists: "پاس گل",
  expected_assists: "xA",
  successful_passes: "پاس صحیح",
  successful_passes_accuracy: "دقت پاس",
  long_balls_accurate: "توپ بلند صحیح",
  long_ball_succeeeded_accuracy: "دقت توپ بلند",
  line_breaking_passes: "پاس خط‌شکن",
  chances_created: "سانس‌سازی",
  big_chance_created_team_title: "سانس بزرگ خلق‌شده",
  dribbles_succeeded: "دریبل موفق",
  won_contest_subtitle: "نرخ موفقیت دریبل",
  duel_won: "دوئل برده",
  duel_won_percent: "درصد دوئل برده",
  aerials_won: "دوئل هوایی برده",
  aerials_won_percent: "درصد دوئل هوایی",
  touches: "لمس توپ",
  touches_opp_box: "لمس در محوطهٔ حریف",
  dispossessed: "از دست دادن توپ",
  fouls_won: "خطای گرفته‌شده",
  defensive_actions: "عمل دفاعی",
  "matchstats.headers.tackles": "تکل",
  interceptions: "قطع توپ",
  blocked_shots: "شوت بلاک‌شده",
  fouls: "خطای انجام‌شده",
  recoveries: "بازپس‌گیری توپ",
  poss_won_att_3rd_team_title: "بردهٔ توپ در ثلث پایانی",
  dribbled_past: "دریبل خورده",
  clearances: "دفع توپ",
  clean_sheet_team_title: "دروازهٔ بسته",
  goals_conceded_while_on_pitch: "گل خورده در زمین",
  expected_goals_against_while_on_pitch: "xG خورده در زمین",
  yellow_cards: "کارت زرد",
  red_cards: "کارت قرمز",
  saves: "مهار",
  save_percentage: "درصد مهار",
  goals_conceded: "گل خورده",
  goals_prevented: "گل پیشگیری‌شده",
  penalty_saves: "مهار پنالتی",
  penalty_goals_conceded: "پنالتی خورده",
  penalty_save_percent: "درصد مهار پنالتی",
  error_led_to_goal: "خطا منجر به گل",
  keeper_sweeper: "خروج اسوئیپر",
  keeper_high_claim: "گرفتن توپ بلند",
};

const PLAYER_TRAIT_FA: Record<string, string> = {
  chances_created: "سانس‌سازی",
  aerials_won: "دوئل هوایی",
  defensive_actions: "عمل دفاعی",
  goals: "گل",
  shot_attempts: "شوت",
  goals_conceded: "گل خورده",
  save_percentage: "درصد مهار",
  clean_sheet: "دروازهٔ بسته",
  keeper_sweeper_actions: "خروج اسوئیپر",
  keeper_high_claim: "گرفتن توپ بلند",
  long_ball_succeeeded_accuracy: "دقت توپ بلند",
  touches: "لمس توپ",
  dribbles_succeeded: "دریبل موفق",
  successful_passes: "پاس صحیح",
  duels_won: "دوئل برده",
  duel_won: "دوئل برده",
  assists: "پاس گل",
  xg: "xG",
  xa: "xA",
  interceptions: "قطع توپ",
  tackles: "تکل",
  recoveries: "بازپس‌گیری توپ",
  fouls: "خطای انجام‌شده",
  yellow_cards: "کارت زرد",
};

const PLAYER_TRAITS_TITLE_FA: Record<string, string> = {
  stats_comparison_forwards: "مقایسهٔ آمار با سایر مهاجمان",
  stats_comparison_midfielders: "مقایسهٔ آمار با سایر هافبک‌ها",
  stats_comparison_defenders: "مقایسهٔ آمار با سایر مدافعان",
  stats_comparison_keepers: "مقایسهٔ آمار با سایر دروازه‌بان‌ها",
};

/** ≤2-decimal Persian number, trailing zeros trimmed */
function deepNumFa(n: number): string {
  return faDigits((Math.round(n * 100) / 100).toString());
}

function deepStatValueFa(v: string, format?: string): string {
  const n = Number(v);
  if (!Number.isFinite(n)) return "";
  if (format === "percent") return `${deepNumFa(n)}٪`;
  if (format === "kph") return `${deepNumFa(n)} کیلومتر بر ساعت`;
  if (format === "meter") {
    return n >= 1000 ? `${deepNumFa(Math.round(n / 100) / 10)} کیلومتر` : `${deepNumFa(n)} متر`;
  }
  return deepNumFa(n);
}

/** «۱۵۹.۳ میلیون یورو» / «۱۱۰ هزار یورو» — EUR market values */
function marketNumFa(n: number): string {
  if (n >= 1e9) return `${deepNumFa(Math.round(n / 1e8) / 10)} میلیارد یورو`;
  if (n >= 1e6) return `${deepNumFa(Math.round(n / 1e5) / 10)} میلیون یورو`;
  if (n >= 1e3) return `${deepNumFa(Math.round(n / 1e3))} هزار یورو`;
  return `${faDigits(n)} یورو`;
}

/** cycle-116 additive export: public wrapper for marketNumFa — the lineup-tab
 *  «غایبان و آمار ترکیب» feature formats totalStarterMarketValue with the
 *  exact same EUR wording as the player market-value history (no drift). */
export function marketValueFa(n: number): string {
  return marketNumFa(n);
}

function buildDeepStats(raw: FMPlayerDetails): PlayerDeepGroup[] | null {
  const groups = raw.firstSeasonStats?.statsSection?.items;
  if (!Array.isArray(groups)) return null;
  const out: PlayerDeepGroup[] = [];
  for (const g of groups) {
    const rows: PlayerDeepStat[] = [];
    for (const it of Array.isArray(g.items) ? g.items : []) {
      const v = it.statValue;
      if (v === null || v === undefined || v === "") continue;
      const value = deepStatValueFa(String(v), it.statFormat);
      if (!value) continue;
      const id = it.localizedTitleId || "";
      // per90 only makes sense for count/rate stats — skip percent/physical and zeros
      const per90 =
        it.per90 != null &&
        Number.isFinite(it.per90) &&
        it.per90 > 0 &&
        (it.statFormat === "number" || it.statFormat === "fraction")
          ? deepNumFa(it.per90)
          : null;
      rows.push({
        fa: PLAYER_DEEP_STAT_FA[id] || it.title || id || "؟",
        value,
        per90,
        pct:
          it.percentileRank != null && Number.isFinite(it.percentileRank)
            ? Math.max(0, Math.min(100, Math.round(it.percentileRank)))
            : null,
      });
    }
    if (rows.length > 0) {
      out.push({ fa: PLAYER_DEEP_GROUP_FA[(g.title || "").toLowerCase()] || g.title || "؟", stats: rows });
    }
  }
  return out.length > 0 ? out : null;
}

function buildTraits(raw: FMPlayerDetails): PlayerTraits | null {
  const items = raw.traits?.items;
  if (!Array.isArray(items) || items.length === 0) return null;
  const rows = items
    .filter((t) => typeof t.value === "number" && Number.isFinite(t.value as number))
    .map((t) => ({
      fa: PLAYER_TRAIT_FA[t.key || ""] || t.title || "؟",
      pct: Math.max(0, Math.min(100, Math.round((t.value as number) * 100))),
    }));
  if (rows.length === 0) return null;
  return {
    titleFa: PLAYER_TRAITS_TITLE_FA[raw.traits?.key || ""] || "مقایسهٔ آمار با هم‌پست‌ها",
    items: rows,
  };
}

function buildMarket(raw: FMPlayerDetails): PlayerMarket | null {
  const vals = raw.marketValues?.values;
  if (!Array.isArray(vals)) return null;
  const pts = vals.filter((v) => typeof v.value === "number" && Number.isFinite(v.value as number));
  if (pts.length < 2) return null;
  const first = pts[0];
  const last = pts[pts.length - 1];
  const yearOf = (iso?: string): string => {
    if (!iso) return "";
    const d = new Date(iso);
    return Number.isNaN(d.getTime()) ? "" : String(d.getUTCFullYear());
  };
  const tFa = (name?: string): string | null => (name ? teamFa(name) || name : null);
  return {
    current: marketNumFa(last.value as number),
    currentTeamFa: tFa(last.teamName),
    sinceValue: marketNumFa(first.value as number),
    sinceTeamFa: tFa(first.teamName),
    sinceYear: yearOf(first.date),
    points: pts.map((v) => v.value as number),
  };
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

  // recent appearances (already newest-first) — cycle-86: full archive instead
  // of the old 10-row window (probed: 68 entries on Haaland, 70 on Sinisalo;
  // bounded upstream, 120 safety cap) with the side (club vs national team)
  // kept per row so the UI can filter
  const recent: PlayerRecentMatch[] = [];
  const recentTeams: PlayerRecentSide[] = [];
  for (const m of (raw.recentMatches || []).slice(0, 120)) {
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
      sideId: m.teamId ?? 0,
      sideName: teamFa(m.teamName || undefined) || m.teamName || "",
    });
    if (m.teamId && !recentTeams.some((t) => t.id === m.teamId)) {
      recentTeams.push({ id: m.teamId, fa: teamFa(m.teamName || undefined) || m.teamName || "" });
    }
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
  // cycle-135: full multi-position map («پست‌های بازی») — dedupe by English
  // label, sort main-first then by the payload's own occurrence tally, cap 8.
  // Section hides when the payload carries none (coach/odd feeds) — honest
  // absence, same pattern as pitch/traits/market.
  const rawSpots = raw.positionDescription?.positions ?? [];
  const seenPos = new Set<string>();
  const positions: PlayerPositionSpot[] = [];
  for (const s of rawSpots) {
    const en = s.strPos?.label?.trim();
    if (!en) continue;
    const key = en.toLowerCase();
    if (seenPos.has(key)) continue;
    seenPos.add(key);
    positions.push({
      fa: faPositionDetail(en) ?? faPosition(en) ?? en,
      en,
      occurrences: typeof s.occurences === "number" && s.occurences >= 0 ? s.occurences : 0,
      isMain: s.isMainPosition === true,
    });
  }
  positions.sort((a, b) => Number(b.isMain) - Number(a.isMain) || b.occurrences - a.occurrences);
  const careerItems = raw.careerHistory?.careerItems || {};
  const career = [
    ...normalizeCareerEntries(careerItems.senior?.teamEntries, "senior"),
    ...normalizeCareerEntries(careerItems["national team"]?.teamEntries, "national"),
  ];
  return {
    id,
    name: raw.name || "",
    nameFa: playerFa(raw.name || ""),
    positionFa: faPosition(posEn || undefined),
    positionEn: posEn,
    ...(positions.length > 0 ? { positions: positions.slice(0, 8) } : {}),
    status: raw.status || "",
    injury: buildInjury(raw),
    team: pt
      ? { id: pt.teamId as number, name: pt.teamName || "", fa: teamFa(pt.teamName || undefined) || pt.teamName || "", logo: fotmobTeamLogo(pt.teamId ?? 0) }
      : null,
    info,
    season,
    recent,
    recentTeams,
    pitch: buildPitch(raw.firstSeasonStats),
    isCaptain: !!raw.isCaptain,
    next,
    career,
    careerYouth: normalizeCareerEntries(careerItems.youth?.teamEntries, "youth"),
    trophies: normalizeTrophies(raw.trophies),
    deepStats: buildDeepStats(raw),
    traits: buildTraits(raw),
    market: buildMarket(raw),
    fetchedAt: new Date().toISOString(),
  };
}

// ---- cycle-96: player injury status («وضعیت مصدومیت») ----
// Persian names for the probed injury vocabulary (23 live samples). Unknown
// names fall back to the raw upstream text (honest), with nameEn kept for the
// UI title attr so the original wording is never lost.
const PLAYER_INJURY_FA: Record<string, string> = {
  "injured": "آسیب‌دیدگی",
  "knock": "ضربه",
  "illness": "بیماری",
  "physical discomfort": "ناراحتی جسمی",
  "suspension": "محرومیت",
  "red card suspension": "محرومیت با کارت قرمز",
  "ankle injury": "آسیب‌دیدگی مچ پا",
  "knee injury": "آسیب‌دیدگی زانو",
  "thigh injury": "آسیب‌دیدگی ران",
  "calf injury": "آسیب‌دیدگی ساق پا",
  "groin injury": "آسیب‌دیدگی کشالهٔ ران",
  "hamstring injury": "آسیب‌دیدگی همسترینگ",
  "foot injury": "آسیب‌دیدگی پا",
  "leg injury": "آسیب‌دیدگی پا",
  "back injury": "آسیب‌دیدگی کمر",
  "hip injury": "آسیب‌دیدگی لگن",
  "shoulder injury": "آسیب‌دیدگی شانه",
  "wrist injury": "آسیب‌دیدگی مچ دست",
  "toe injury": "آسیب‌دیدگی انگشت پا",
  "muscle injury": "آسیب‌دیدگی عضلانی",
  "tendon injury": "آسیب‌دیدگی تاندون",
  "ligament injury": "آسیب‌دیدگی رباط",
  "cruciate ligament injury": "پارگی رباط صلیبی",
  "achilles tendon injury": "آسیب‌دیدگی تاندون آشیل",
  "meniscus injury": "آسیب‌دیدگی منیسک",
  "concussion": "آسیب‌دیدگی سر",
  "coronavirus": "کرونا",
};
// expectedReturnKey enum observed live: early/mid/late ride with a month-text
// param, doubtful / back_in_training stand alone. Unknown keys WITH a param
// still render the date; unknown keys without one stay null (honest omission).
const RETURN_PREFIX_FA: Record<string, string> = {
  expected_return_date_early: "اوایل",
  expected_return_date_mid: "اواسط",
  expected_return_date_late: "اواخر",
};

// cycle-116: the MATCH lineup unavailable blocks (content.lineup.*Team.
// unavailable[].unavailability.expectedReturn) carry the return as a RAW
// STRING ("Doubtful" | "Out for season" | "Early November 2026" | "Mid …" |
// "Late …" — probed enum over 4 matches) unlike the player payload's keyed
// enum. Parse it with the SAME cycle-96 month/prefix maps; unmapped patterns
// return null and the UI falls back to the honest English raw.
export function unavailableReturnFa(raw?: string): string | null {
  const s = (raw || "").trim();
  if (!s) return null;
  const low = s.toLowerCase();
  if (low === "doubtful") return "مشارکت مشکوک";
  if (low === "out for season") return "خارج برای کل فصل";
  const mp = low.match(/^(early|mid|late)\s+([a-z]+)\s+(\d{4})$/);
  if (mp) {
    const prefix = RETURN_PREFIX_FA[`expected_return_date_${mp[1]}`];
    const month = MONTH_FA[mp[2]];
    if (prefix && month) return `${prefix} ${month} ${faDigits(mp[3])}`;
  }
  const mb = low.match(/^([a-z]+)\s+(\d{4})$/);
  if (mb && MONTH_FA[mb[1]]) return `${MONTH_FA[mb[1]]} ${faDigits(mb[2])}`;
  return null;
}
const PLAYER_RETURN_KEY_FA: Record<string, string> = {
  expected_return_date_doubtful: "مشارکت مشکوک",
  expected_return_date_back_in_training: "بازگشت به تمرین",
};
// expectedReturnDateParam is month TEXT ("November 2026", "Early November
// 2026"-style prefixes already extracted by the key) — transliterated, digits
// Persianized. Unknown month words pass through untouched.
const MONTH_FA: Record<string, string> = {
  january: "ژانویه", february: "فوریه", march: "مارس", april: "آوریل",
  may: "مه", june: "ژوئن", july: "ژوئیه", august: "اوت",
  september: "سپتامبر", october: "اکتبر", november: "نوامبر", december: "دسامبر",
};

function buildInjury(raw: FMPlayerDetails): PlayerInjury | null {
  const inj = raw.injuryInformation;
  if (!inj || !inj.name) return null;
  const nameEn = inj.name;
  const nameFa = PLAYER_INJURY_FA[nameEn.toLowerCase()] || nameEn;
  let returnFa: string | null = null;
  const er = inj.expectedReturn || {};
  const key = er.expectedReturnKey || "";
  const param = typeof er.expectedReturnDateParam === "string" ? er.expectedReturnDateParam.trim() : "";
  const paramFa = param
    ? param.split(/\s+/).map((w) => MONTH_FA[w.toLowerCase()] || faDigits(w)).join(" ")
    : "";
  if (PLAYER_RETURN_KEY_FA[key]) {
    returnFa = PLAYER_RETURN_KEY_FA[key];
  } else if (RETURN_PREFIX_FA[key] && paramFa) {
    returnFa = `${RETURN_PREFIX_FA[key]} ${paramFa}`;
  } else if (paramFa) {
    returnFa = `بازگشت: ${paramFa}`;
  }
  let updatedFa: string | null = null;
  const lu = inj.lastUpdated?.utcTime;
  if (lu && !Number.isNaN(new Date(lu).getTime())) {
    const j = jalaliShort(lu);
    if (j.day && j.month) updatedFa = `${j.day} ${j.month} ${j.year}`;
  }
  return {
    nameFa,
    ...(nameFa !== nameEn ? { nameEn } : {}),
    returnFa,
    updatedFa,
  };
}

function jalaliContract(iso: string): string {
  const j = jalaliShort(iso);
  // cycle-86: the year is the essential part for long contracts («۹ تیر ۱۴۱۳»
  // for 2034-06-30 — day+month alone was ambiguous)
  return j.day && j.month ? `${j.day} ${j.month} ${j.year}` : "";
}

// ---- cycle-87: season shot map + touch heatmap (all probed, best-effort) ----
interface FMShotRaw {
  eventType?: string;          // Goal / AttemptSaved / Miss (probed)
  shotType?: string;           // RightFoot / LeftFoot / Header (probed)
  situation?: string;          // RegularPlay / FromCorner (probed)
  x?: number; y?: number;      // 0-100 pitch coords, x toward opponent goal
  min?: number;
  isOwnGoal?: boolean;
  isOnTarget?: boolean;
  isBlocked?: boolean;
  expectedGoals?: number;
  playerName?: string;         // keeperShotmap: the shooter
}

const SHOT_TYPE_FA: Record<string, string> = {
  RightFoot: "پای راست",
  LeftFoot: "پای چپ",
  Header: "سر",
  Other: "دیگر",
};

function buildPitch(fss: FMPlayerDetails["firstSeasonStats"]): PlayerPitch | null {
  const own = Array.isArray(fss?.shotmap) ? fss.shotmap : [];
  const faced = Array.isArray(fss?.keeperShotmap) ? fss.keeperShotmap : [];
  // keeper view: no own shots on the season but shots faced recorded
  const keeper = own.length === 0 && faced.length > 0;
  const src = keeper ? faced : own;
  const shots: PlayerShot[] = [];
  for (const s of src || []) {
    if (!s || s.isOwnGoal) continue; // own goals are not the player's shots
    const x = typeof s.x === "number" ? s.x : null;
    const y = typeof s.y === "number" ? s.y : null;
    if (x === null || y === null) continue;
    shots.push({
      min: typeof s.min === "number" ? s.min : 0,
      x,
      y,
      goal: s.eventType === "Goal",
      onTarget: !!s.isOnTarget,
      blocked: !!s.isBlocked,
      xg: typeof s.expectedGoals === "number" ? s.expectedGoals : null,
      typeFa: SHOT_TYPE_FA[String(s.shotType || "")] || null,
      by: keeper ? s.playerName || null : null,
    });
  }
  const heat: { x: number; y: number }[] = [];
  const coords = fss?.heatmap?.coordinates;
  if (Array.isArray(coords)) {
    for (const c of coords.slice(0, 800)) {
      if (c && typeof c.x === "number" && typeof c.y === "number") heat.push({ x: c.x, y: c.y });
    }
  }
  if (shots.length === 0 && heat.length === 0) return null;
  const xgSum = shots.reduce((acc, s) => acc + (s.xg || 0), 0);
  return {
    keeper,
    shots,
    goals: shots.filter((s) => s.goal).length,
    xgTotal: shots.length > 0 ? Math.round(xgSum * 10) / 10 : null,
    heat,
  };
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
  // cycle-87: key bumped to v3 — output gained the pitch block (shot map +
  // heatmap) so the L2 SQLite cache cannot serve the older shapes
  // (same convention as cycle-52/86)
  // cycle-96: key bumped to v4 — output gained the injury block so the L2
  // SQLite cache cannot serve older injury-less shapes (same convention as
  // cycle-52/86/87)
  // cycle-106: key bumped to v5 — output gained the root nameFa (profile h1
  // display name); older shapes would violate the required field (same
  // convention as cycle-52/86/87/96)
  // cycle-135: key bumped to v6 — normalized output changed in place: gained
  // the optional positions[] map AND the detail-mapper refined fa labels
  // ("Keeper" → «دروازه‌بان»), so a v5-cached shape would serve the stale
  // unrefined labels for up to the TTL (same convention as cycle-52/86/87/96)
  // cycle-159: key bumped to v7 — normalized output changed in place: career
  // + recentTeams fa now resolve through the widened teamFa (qualifier
  // fallback rides COUNTRY_FA + the 159 mapping sweep), so a v6-cached shape
  // would serve Latin career rows («Iran U23», «Shahr Khodrou FC») from the
  // persistent L2 for up to the TTL (same convention as cycle-52/86/87/96/135)
  const payload = await cached(`player:v7:${id}`, 10 * 60_000, async (): Promise<PlayerData | typeof PLAYER_NOT_FOUND> => {
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
  nameFa: string; // display name — curated Persian (player-names-fa) when mapped, else the raw upstream name; cycle-105 extension of the cycle-104 map
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
  nameFa: string; // display name — cycle-105, same honest map as cycle-104
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
  nameFa: string; // display name — cycle-105, same honest map as cycle-104
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
  /** cycle-132: seasons the selector may offer — the INTERSECTION of
   *  allSeasons across the fulfilled league feeds of this very merge (a season
   *  only some feeds serve would make the «race» silently partial, so the
   *  common set is the honest offer). Optional: snapshots stored before this
   *  cycle lack it and the UI hides the selector (same convention as cards). */
  allSeasons?: string[];
  /** cycle-132: the season the payloads actually served — the mode (most
   *  common) of the fulfilled feeds' own selectedSeason markers. For the
   *  current view this is the current season; for a historical request the
   *  view compares it against the requested season and snaps back when
   *  upstream silently served the current one (same honesty snap as the
   *  league page, cycle-99). */
  selectedSeason?: string;
  updatedAt: string;
  /** cycle-42: true when the response comes from the last-known-good snapshot
   *  (cold start / upstream outage) instead of a fresh live merge — the UI
   *  shows an honest «آخرین داده‌های ذخیره‌شده» notice in that case. */
  stale?: boolean;
}

/**
 * cycle-132: optional `season` ("YYYY/YYYY", already shape-guarded by the
 * callers) — threads the historical season into every per-league
 * getStandings read so the merged race covers past seasons too. The
 * per-league reads are cache-backed per season, so a historical merge only
 * pays on the first request of that season. Card leaders stay a
 * current-season-only feed (probed) and are simply omitted from historical
 * merges — the UI already hides the section when `cards` is undefined.
 */
export async function getAllTopScorers(season?: string): Promise<GlobalScorersData> {
  // cycle-140: the race is LEAGUES minus merge-exempt cups (globalMerge:
  // false) — UECL's 6-season feed would shrink the cycle-132 allSeasons
  // intersection window from 12 to 6. Index alignment: the SAME filtered
  // array indexes the settled results below, never LEAGUES itself.
  const raceLeagues = LEAGUES.filter((lg) => lg.globalMerge !== false);
  const settled = await Promise.allSettled(raceLeagues.map((lg) => getStandings(lg.key, season)));
  const merged: GlobalScorer[] = [];
  const mergedAssists: GlobalAssist[] = [];
  const perLeague: GlobalScorersData["perLeague"] = [];
  // cycle-132: intersection of the feeds' allSeasons + mode of their
  // selectedSeason markers (see the GlobalScorersData field docs above)
  let seasonsCommon: string[] | undefined;
  const seasonVotes = new Map<string, number>();
  settled.forEach((r, i) => {
    const lg = raceLeagues[i];
    if (r.status !== "fulfilled") return;
    const st = r.value;
    // cycle-132: per-feed season contract bookkeeping (before the scorers
    // guard — a feed with an empty scorer list still votes its marker and
    // still narrows the intersection)
    if (st.selectedSeason) seasonVotes.set(st.selectedSeason, (seasonVotes.get(st.selectedSeason) || 0) + 1);
    if (Array.isArray(st.allSeasons) && st.allSeasons.length > 0) {
      if (!seasonsCommon) seasonsCommon = [...st.allSeasons];
      else {
        seasonsCommon = seasonsCommon.filter((s) => (st.allSeasons as string[]).includes(s));
        if (seasonsCommon.length === 0) seasonsCommon = undefined;
      }
    }
    if (st.scorers?.length) {
      perLeague.push({ leagueKey: lg.key, leagueFa: lg.faName, scorers: st.scorers });
      for (const s of st.scorers) {
        merged.push({
          rank: 0, // dense global rank assigned after the sort below
          name: s.name, nameFa: playerFa(s.name), team: s.team, teamId: s.teamId, goals: s.goals,
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
        name: a.name, nameFa: playerFa(a.name), team: a.team, teamId: a.teamId, value: a.assists,
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
  // cycle-132: current-season-only — historical merges omit cards entirely
  let cards: GlobalCardsData | undefined;
  if (!season) {
    try {
      cards = await getAllCardLeaders();
    } catch {
      // cards stay undefined — the UI hides the section, the table itself is untouched
    }
  }
  // cycle-132: mode of the served-season markers (tie → the value seen first)
  let selectedSeason: string | undefined;
  let best = 0;
  seasonVotes.forEach((n, s) => {
    if (n > best) { best = n; selectedSeason = s; }
  });
  return {
    scorers: merged, assists, perLeague, cards,
    ...(seasonsCommon && seasonsCommon.length > 1 ? { allSeasons: seasonsCommon } : {}),
    ...(selectedSeason ? { selectedSeason } : {}),
    updatedAt: new Date().toISOString(),
  };
}

/**
 * Global card leaders merged across all leagues (cycle-50). Domestic leagues
 * are attributed first and UCL last — a player listed in both competitions
 * keeps the domestic entry (same rule as the team index). Dense global rank
 * per kind, top 10 each.
 */
export async function getAllCardLeaders(): Promise<GlobalCardsData> {
  // cycle-140: same merge-exemption as the scorers race (globalMerge: false)
  // — one flag, one semantic: the /topscorers page shows one participant set,
  // never a 9th competition in the cards section while the race says 8.
  const ordered = [...LEAGUES].filter((lg) => lg.globalMerge !== false).sort((a, b) => (a.key === "ucl" ? 1 : 0) - (b.key === "ucl" ? 1 : 0));
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
        merged.push({ ...row, nameFa: playerFa(row.name), rank: 0, leagueKey: lg.key, leagueFa: lg.faName });
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
    // fix cycle-149 (FINDING-1 from the 148 bug-hunt): fold hyphen/underscore
    // separators to spaces so «Al-Hilal» / «man_united» match the space-formed
    // feed names — both the query and the alias haystack pass through here,
    // so one fold repairs both sides at once
    .replace(/[-_]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

let teamIndexCache: { at: number; data: TeamIndexEntry[] } | null = null;

// Teams whose league page is unavailable via FotMob keyless API (e.g. Persian Gulf Pro
// League returns `null`) or which sit outside the portal's 8 leagues/cups entirely, but
// which must still be searchable — the 404 page sends users to the header search, so
// any team with a working /team/ page has to be findable. Ids verified from match
// feed (persiangulf) and live data/teams probes (cycle-79: Ibrox / Tynecastle resolve).
const SEARCH_FALLBACK_TEAMS: { teamId: number; name: string; fa: string; leagueKey: string; leagueFa: string }[] = [
  { teamId: 101610, name: "Persepolis FC", fa: "پرسپولیس", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
  { teamId: 101614, name: "Esteghlal FC", fa: "استقلال", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
  { teamId: 176352, name: "Tractor SC", fa: "تراکتور", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
  { teamId: 101611, name: "Sepahan SC", fa: "سپاهان", leagueKey: "persiangulf", leagueFa: "لیگ خلیج فارس ایران" },
  // fix cycle-79: Glasgow clubs + Hearts have fully working team pages (the
  // stats/transfer/trophy/venue feeds all resolve) but the Scottish Premiership
  // is not a portal league, so the standings-built index never contained them
  // and the header search answered «تیمی با این نام پیدا نشد» for سلتیک/Celtic.
  { teamId: 9925, name: "Celtic FC", fa: "سلتیک", leagueKey: "scotland", leagueFa: "لیگ برتر اسکاتلند" },
  { teamId: 8548, name: "Rangers FC", fa: "رنجرز", leagueKey: "scotland", leagueFa: "لیگ برتر اسکاتلند" },
  { teamId: 9860, name: "Heart of Midlothian FC", fa: "هارت", leagueKey: "scotland", leagueFa: "لیگ برتر اسکاتلند" },
];

/** Flat index of every team in our 8 league/cup standings (getStandings is cached, so this is cheap). */
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
    // fix cycle-149: fold separators here too so the highlight range stays
    // consistent with the folded matcher (map indices stay display-correct)
    else if (c === "-" || c === "_") c = " ";
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
  // cycle-134 additive: the raw payload's details.name (honest English name)
  // so the /players squad panel can label the header on deep links (?team=)
  // without a second fetch; UI prefers the Persian name from the standings
  // rows when the team is in the loaded league list
  teamName?: string;
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

// ---------------- FotMob: team transfers (data/teams endpoint, cycle-71) ----------------
// Probed live (2026-10-29, UA Chrome/124): the SAME api/data/teams payload
// that feeds the squad also carries transfers.allTransfers[] — a date-desc
// feed of the team's moves. Row shape DIFFERS from the league feed: fee is
// {feeText, localizedFeeText} with NO value; the euro estimate sits on
// amountEuroEstimated (often null; feeText is then "fee"/"undisclosed").
// Probed directions on Celtic 9925: in=16, out=24, contract extensions
// (from == to == team) = 5.

interface FMTeamTransferRaw {
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
  fee?: { feeText?: string } | null;
  amountEuroEstimated?: number | null;
  transferType?: { text?: string };
  contractExtension?: boolean;
  onLoan?: boolean;
}

/** Raw api/data/teams payload — shared by the squad (cycle-70), transfers
 * (cycle-71), trophies (cycle-72) and venue (cycle-75) reads — ONE upstream
 * fetch per hour. */
interface FMStatParticipant {
  id?: number | string;
  name?: string;
  rank?: number;
  teamId?: number;
  value?: number;
  stat?: { name?: string; value?: number; format?: string; fractions?: number };
}

interface FMStatBlock {
  header?: string;
  participant?: FMStatParticipant;
  topThree?: FMStatParticipant[];
}

interface FMTeamDataRaw {
  squad?: { squad?: { title?: string; members?: FMSquadMember[] }[] };
  transfers?: { allTransfers?: FMTeamTransferRaw[] };
  fixtures?: {
    allFixtures?: { fixtures?: FMTeamFixtureRaw[] };
    primaryTournamentId?: number | string;
  };
  history?: {
    trophyList?: FMTeamTrophyRaw[];
    historicalTableData?: { ranks?: FMHistoryRankRaw[] };
    // cycle-91 probed (UA Chrome/124, 2026-10-29): one row per coach×season of
    // the club's PRIMARY league that year — { id (coach id-space, NOT player
    // ids), name, season "2012/2013", leagueId, leagueName, win, draw, loss,
    // pointsPerGame, winPercentage (0..1 fraction) }. Ascending by season.
    // Coverage: City 15 / Celtic 19 / Palace 24 / Liverpool 16 / even small
    // clubs (Whitby 6); mid-season handovers appear as consecutive rows of
    // different coaches (Strasbourg: 8 coaches over 14 seasons).
    coachHistory?: FMCoachHistoryRaw[];
  };
  overview?: {
    venue?: FMVenueRaw;
    // cycle-95 probed (UA Chrome/124, 2026-10-29): topPlayers = three league-
    // scoped rankings of the club's own players for the primary season —
    // byRating / byGoals / byAssists, each ≤3 rows {id (player id-space),
    // name, rank (league-wide rank in that stat), value, stat{format,
    // fractions}} + a seeAllUrl (unused — portal links /player/{id} instead).
    topPlayers?: FMTopPlayersRaw;
    // cycle-112 probed (UA Chrome/124, 2026-10-29): fixtureDifficulty = the
    // fixture-difficulty widget payload. Flat object: {leagueId, leagueName,
    // subheader ("Next 3", subheaderKey next_three_matches_short),
    // difficulty ("Moderate"/"Manageable"/"Hard" + difficultyKey enum),
    // matchesLeft (league games remaining), difficultyMatches, fixtures[≤5]}
    // where each fixture carries {matchId, opponentId, opponentName,
    // opponentShortName, isHome, difficulty (small int; 1..3 observed across
    // 9 clubs), matchDateUtc}. Present on all 9 probed clubs (domestic
    // leagues incl. Premiership); null/absent → section hidden (honest).
    fixtureDifficulty?: FMFixtureDifficultyRaw;
    // cycle-120 probed (UA Chrome/124, 2026-10-29): lastLineupStats = the XI
    // that actually started the team's most recent played match — flat object
    // {id, name, rating (team match rating), formation, coach, lastMatch
    // {matchId, home/awayTeamId+Name}, averageStarterAge,
    // totalStarterMarketValue, starters[11], subs[], unavailable[]} where each
    // starter carries {id, name, shirtNumber, marketValue, performance
    // {rating (this match), seasonRating, seasonGoals, seasonAssists,
    // totalDistanceCovered (m), topSpeed (km/h), playerOfTheMatch?, events[]}}.
    // Shape uniform across probed clubs (City/Arsenal/Brighton: 11 starters
    // each); absent/empty → section hidden (honest, legend-111 contract).
    lastLineupStats?: FMLastLineupStatsRaw;
  };
  stats?: {
    players?: FMStatBlock[];
    teams?: FMStatBlock[];
    primarySeasonId?: string | number;
  };
}

interface FMTopPlayersRaw {
  byRating?: FMTopPlayerBlockRaw;
  byGoals?: FMTopPlayerBlockRaw;
  byAssists?: FMTopPlayerBlockRaw;
}

// cycle-112: raw fixtureDifficulty (see FMTeamDataRaw.overview comment)
interface FMFixtureDifficultyRaw {
  leagueId?: number;
  leagueName?: string;
  subheader?: string;
  subheaderKey?: string;
  difficulty?: string;
  difficultyKey?: string;
  matchesLeft?: number;
  difficultyMatches?: number;
  fixtures?: {
    matchId?: number;
    opponentId?: number;
    opponentName?: string;
    opponentShortName?: string;
    isHome?: boolean;
    difficulty?: number;
    matchDateUtc?: string;
  }[];
}

interface FMTopPlayerBlockRaw {
  players?: FMTopPlayerRowRaw[];
}

interface FMTopPlayerRowRaw {
  id?: number;
  name?: string;
  rank?: number;
  value?: number;
  stat?: { name?: string; value?: number; format?: string; fractions?: number };
}

interface FMVenueRaw {
  widget?: { name?: string; city?: string };
  statPairs?: [string, string | number | null][];
}

interface FMTeamTrophyRaw {
  name?: string;
  leagueId?: string | number;
  won?: number;
  runnerup?: number;
  seasonsWon?: string;
  seasonsRunnerup?: string;
}

interface FMHistoryRankRaw {
  tournamentName?: string;
  seasonName?: string;
  shortSeasonName?: string;
  position?: number;
  numberOfTeams?: number;
  stats?: { points?: number; wins?: number; draws?: number; loss?: number };
}

interface FMTeamFixtureRaw {
  id?: number;
  // probed (cycle-85): on penalty shootouts home/away.score carry the SHOOTOUT
  // score while status.scoreStr keeps the regulation+ET score (City friendly
  // 5406269: entry 2-4 vs scoreStr «1 - 1», reason penalties_short)
  home?: { id?: number; name?: string; score?: number | null };
  away?: { id?: number; name?: string; score?: number | null };
  tournament?: { name?: string; leagueId?: number };
  // probed (cycle-85): result = verdict from the TEAM's perspective (1 win /
  // 0 draw / -1 loss) — present on every started fixture (53/53 across the
  // three reference clubs, zero semantics mismatches)
  result?: number;
  status?: {
    utcTime?: string;
    finished?: boolean;
    started?: boolean;
    cancelled?: boolean;
    scoreStr?: string;
    reason?: { short?: string; shortKey?: string; long?: string; longKey?: string };
  };
  notStarted?: boolean;
}

const getTeamDataRaw = (teamId: number): Promise<FMTeamDataRaw> =>
  cached(`teamDataRaw:${teamId}`, 60 * 60_000, async () =>
    fetchJson<FMTeamDataRaw>(`https://www.fotmob.com/api/data/teams?id=${teamId}`, 15000)
  );

export async function getTeamSquad(teamId: number): Promise<TeamSquad | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const list = raw?.squad?.squad;
  if (!Array.isArray(list) || list.length === 0) return null;

  // cycle-134: honest English name from the same cached payload (details.name,
  // live-probed 2026-10-29: "Barcelona" for id 8634) — additive, consumers
  // that never read it are unaffected
  const teamName =
    typeof (raw as { details?: { name?: string } })?.details?.name === "string" &&
    (raw as { details?: { name?: string } }).details!.name!.trim() !== ""
      ? (raw as { details?: { name?: string } }).details!.name!.trim()
      : undefined;

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
  return { ...(teamName ? { teamName } : {}), coach, groups };
}

export interface TeamTransferItem {
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

export interface TeamTransfersData {
  total: number;
  nIn: number;
  nOut: number;
  nInternal: number;
  items: TeamTransferItem[];
}

/** Persian fee/type label for the TEAM feed (fee has no value here — the euro
 * estimate lives on amountEuroEstimated; probed texts: fee, on loan, free
 * transfer, contract extension, undisclosed). */
const teamTransferFeeFa = (t: FMTeamTransferRaw): string => {
  if (t.contractExtension) return "تمدید قرارداد";
  if (typeof t.amountEuroEstimated === "number" && t.amountEuroEstimated > 0) {
    return `کارمزد ${euroFa(t.amountEuroEstimated)}`;
  }
  const feeText = (t.fee?.feeText || "").toLowerCase();
  const typeText = (t.transferType?.text || "").toLowerCase();
  if (feeText === "on loan" || typeText === "on loan" || t.onLoan) return "انتقال امانی";
  if (feeText === "free transfer" || typeText === "free transfer") return "انتقال آزاد";
  if (feeText === "undisclosed" || typeText === "undisclosed") return "کارمزد نامشخص";
  if (feeText === "fee") return "کارمزد";
  if (typeText === "contract") return "قرارداد";
  return t.transferType?.text || t.fee?.feeText || "انتقال";
};

/**
 * Team-level transfer feed («بازار انتقال‌ها», cycle-71) from the data/teams
 * payload — direction classified against the team id itself (in = toId, out =
 * fromId, internal = both, i.e. contract extensions). Source order is already
 * date-desc — kept as-is. Returns null when the payload has no feed so the UI
 * hides the section (same contract as getTeamSquad).
 */
export async function getTeamTransfers(teamId: number): Promise<TeamTransfersData | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const list = raw?.transfers?.allTransfers;
  if (!Array.isArray(list) || list.length === 0) return null;
  const items: TeamTransferItem[] = [];
  for (const t of list) {
    if (!t?.name || !t?.fromClub || !t?.toClub) continue;
    const fromId = Number(t.fromClubId || 0);
    const toId = Number(t.toClubId || 0);
    if (fromId !== teamId && toId !== teamId) continue;
    const kind: TeamTransferItem["kind"] =
      fromId === teamId && toId === teamId ? "internal" : toId === teamId ? "in" : "out";
    items.push({
      playerId: Number(t.playerId || 0),
      name: t.name,
      position: t.position?.label || "",
      date: t.transferDate || "",
      from: {
        id: fromId,
        name: t.fromClubFullName || t.fromClub,
        fa: teamFa(t.fromClubFullName, t.fromClub) || t.fromClubFullName || t.fromClub,
      },
      to: {
        id: toId,
        name: t.toClubFullName || t.toClub,
        fa: teamFa(t.toClubFullName, t.toClub) || t.toClubFullName || t.toClub,
      },
      kind,
      kindFa: kind === "in" ? "ورودی" : kind === "out" ? "خروجی" : "تمدید",
      feeFa: teamTransferFeeFa(t),
    });
  }
  if (items.length === 0) return null;
  return {
    total: items.length,
    nIn: items.filter((x) => x.kind === "in").length,
    nOut: items.filter((x) => x.kind === "out").length,
    nInternal: items.filter((x) => x.kind === "internal").length,
    items,
  };
}

// ---------------- FotMob: team trophies (data/teams endpoint, cycle-72) ----------------
// Probed live (2026-10-29, UA Chrome/124): history.trophyList[] —
// { name, leagueId, won, runnerup, seasonsWon ("2025/2026,2024/2025,…"
// desc-ordered), seasonsRunnerup }. Rows with won=0 but runnerup>0 exist
// (Celtic — Europa League runner-up). Probed: Celtic 9925 → 6 rows
// (Premiership 56, Scottish Cup 43, League Cup 22), Palace 9826 → 4.

const TROPHY_FA: Record<string, string> = {
  "Premier League": "لیگ برتر انگلیس",
  "Champions League": "لیگ قهرمانان اروپا",
  "Europa League": "لیگ اروپا",
  "Conference League": "کنفرانس‌لیگ",
  "FA Cup": "جام حذفی انگلیس",
  "League Cup": "جام اتحادیه",
  "Community Shield": "سوپرکاپ انگلیس",
  Championship: "چمپیونشیپ",
  "Scottish Premiership": "لیگ برتر اسکاتلند",
  Premiership: "لیگ برتر اسکاتلند",
  "Scottish Cup": "جام حذفی اسکاتلند",
  "Inter Continental Cup": "جام بین‌قاره‌ای",
  "Club World Cup": "جام باشگاه‌های جهان",
  "Serie A": "سری آ",
  LaLiga: "لالیگا",
  Bundesliga: "بوندس‌لیگا",
  "Ligue 1": "لیگ ۱ فرانسه",
  Eredivisie: "اردیویه",
  "Primeira Liga": "لیگ برتر پرتغال",
  "Süper Lig": "سوپرلیگ ترکیه",
};

export interface TeamTrophy {
  name: string;
  nameFa: string;
  won: number;
  runnerup: number;
  lastWon?: string; // season string, e.g. "2025/2026"
}

export interface TeamTrophiesData {
  totalWon: number;
  items: TeamTrophy[]; // sorted won desc
}

/**
 * Team trophy cabinet («گنجهٔ افتخارات», cycle-72) from the same data/teams
 * payload (shared cached raw fetch — no extra upstream hit). Rows with won=0
 * but runnerup>0 are kept (runner-up history is real info); fully empty rows
 * are dropped; null when the payload has no list so the UI hides the section.
 */
export async function getTeamTrophies(teamId: number): Promise<TeamTrophiesData | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const list = raw?.history?.trophyList;
  if (!Array.isArray(list)) return null;
  const items: TeamTrophy[] = [];
  for (const t of list) {
    if (!t?.name) continue;
    const won = Number(t.won || 0);
    const runnerup = Number(t.runnerup || 0);
    if (won <= 0 && runnerup <= 0) continue;
    const seasons = String(t.seasonsWon || "")
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
    items.push({
      name: t.name,
      nameFa: TROPHY_FA[t.name] || t.name,
      won,
      runnerup,
      ...(seasons.length > 0 ? { lastWon: seasons[0] } : {}),
    });
  }
  if (items.length === 0) return null;
  items.sort((a, b) => b.won - a.won || b.runnerup - a.runnerup || a.name.localeCompare(b.name));
  return { totalWon: items.reduce((a, t) => a + t.won, 0), items };
}

// ---------------- FotMob: team venue (data/teams endpoint, cycle-75) ----------------
// Probed live (2026-10-29, UA Chrome/124): overview.venue on the SAME
// data/teams payload — { widget: {name, city}, statPairs: [["Surface",
// "Grass"], ["Capacity", 60832], ["Opened", 1892]] }. Identical shape on
// Celtic 9925 (Celtic Park) and Palace 9826 (Selhurst Park).

export interface TeamVenue {
  name: string;
  city?: string;
  capacity?: number;
  surface?: string; // raw source text ("Grass")
  opened?: number;
}

const SURFACE_FA: Record<string, string> = {
  grass: "چمن طبیعی",
  artificial: "چمن مصنوعی",
};

/**
 * Home ground of a team («ورزشگاه خانه», cycle-75) from the shared cached
 * data/teams raw fetch — no extra upstream hit. Returns null when the payload
 * carries no venue so the UI hides the section (same contract as the other
 * lazy team reads).
 */
export async function getTeamVenue(teamId: number): Promise<TeamVenue | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const v = raw?.overview?.venue;
  const name = v?.widget?.name;
  if (!name) return null;
  const pairs = Array.isArray(v?.statPairs) ? v.statPairs : [];
  const pick = (label: string): string | number | null => {
    const hit = pairs.find((p) => String(p?.[0] || "").toLowerCase() === label);
    return hit ? hit[1] : null;
  };
  const capacity = pick("capacity");
  const opened = pick("opened");
  const surface = pick("surface");
  return {
    name,
    ...(v?.widget?.city ? { city: v.widget.city } : {}),
    ...(typeof capacity === "number" && capacity > 0 ? { capacity } : {}),
    ...(typeof surface === "string" && surface ? { surface } : {}),
    ...(typeof opened === "number" && opened > 0 ? { opened } : {}),
  };
}

// ---------------- FotMob: team season stats (data/teams endpoint, cycle-76) ----------------
// Probed live (2026-10-29, UA Chrome/124): stats.{players,teams} on the SAME
// data/teams payload — [{header: "Top scorer"|"FotMob rating", ..., participant:
// {name, value, stat:{value, fractions}, rank}, topThree: [...]}]. participant is
// the team's own leader (players) or the team itself (teams, rank = league spot);
// identical shape on Celtic 9925 (38/27 blocks) and Palace 9826 (43/28).

const STAT_FA: Record<string, string> = {
  // player categories
  "Top scorer": "آقای گل",
  "Assists": "پاس گل",
  "Goals + Assists": "گل + پاس گل",
  "FotMob rating": "امتیاز فوت‌ماب",
  "Expected goals (xG)": "گل مورد انتظار (xG)",
  "Expected assist (xA)": "پاس گل مورد انتظار (xA)",
  "Minutes played": "دقایق بازی",
  "Big chances created": "موقعیت بزرگ ساخته",
  "Big chances missed": "موقعیت بزرگ از دست رفته",
  "Clean sheets": "دروازه بسته",
  "Save percentage": "درصد مهار",
  "Goals prevented": "گل مهارشده",
  "Saves per 90": "مهار در هر ۹۰",
  "Shots per 90": "شوت در هر ۹۰",
  "Shots on target per 90": "شوت داخل چارچوب در هر ۹۰",
  "Accurate passes per 90": "پاس دقیق در هر ۹۰",
  "Chances created": "موقعیت ساخته",
  "Successful dribbles per 90": "دریبل موفق در هر ۹۰",
  "Tackles per 90": "تکل در هر ۹۰",
  "Interceptions per 90": "قطع توپ در هر ۹۰",
  "Clearances per 90": "دفع در هر ۹۰",
  "Recoveries per 90": "برداشت توپ در هر ۹۰",
  "Yellow cards": "کارت زرد",
  "Goals per 90": "گل در هر ۹۰",
  "Top speed": "بیشینه سرعت",
  // team categories
  "Goals per match": "گل در هر بازی",
  "Goals conceded per match": "گل خورده در هر بازی",
  "Average possession": "میانگین مالکیت",
  "Expected goals": "گل مورد انتظار (xG)",
  "xG difference": "اختلاف xG",
  "xG conceded": "گل مورد انتظار خورده",
  "Attendance": "میانگین تماشاگر",
  "Shots on target per match": "شوت داخل چارچوب در هر بازی",
  "Big chances": "موقعیت بزرگ",
  "Accurate passes per match": "پاس دقیق در هر بازی",
  "Touches in opposition box": "لمس توپ در محدودهٔ حریف",
  "Corners": "کرنر",
  "Saves per match": "مهار در هر بازی",
  "Fouls per match": "خطا در هر بازی",
  "Interceptions per match": "قطع توپ در هر بازی",
  "Tackles per match": "تکل در هر بازی",
  "Clearances per match": "دفع در هر بازی",
};

const STAT_UNIT: Record<string, string> = {
  "Average possession": "٪",
  "Save percentage": "٪",
};

// curated selection: the most meaningful categories first, shown in this order
const STAT_PLAYER_PREF = [
  "Top scorer",
  "Assists",
  "Goals + Assists",
  "FotMob rating",
  "Expected goals (xG)",
  "Expected assist (xA)",
  "Big chances created",
  "Clean sheets",
  "Save percentage",
  "Goals prevented",
  "Minutes played",
  "Yellow cards",
];

const STAT_TEAM_PREF = [
  "FotMob rating",
  "Goals per match",
  "Average possession",
  "Expected goals",
  "xG difference",
  "Clean sheets",
  "Attendance",
];

/** Persian stat value: fraction format keeps decimals («۷٫۳۴»), plain integers stay bare. */
const statValueFa = (value: number, fractions: number): string => {
  if (!Number.isFinite(value)) return "";
  const f =
    Number.isFinite(fractions) && fractions > 0
      ? Math.min(Math.round(fractions), 2)
      : Number.isInteger(value)
        ? 0
        : 2;
  return faDigits(value.toFixed(f)).replace(".", "٫");
};

export interface TeamStatRow {
  key: string; // source header (stable React key)
  nameFa: string;
  kind: "player" | "team";
  leader?: string; // players: the team's own leader of this stat
  value: string; // pre-formatted Persian value (unit appended)
  rank?: number; // league-wide rank (player) / league spot (team)
  extras?: string[]; // pre-formatted «name value» context strings (cycle-77)
}

export interface TeamStatsData {
  playerRows: TeamStatRow[];
  teamRows: TeamStatRow[];
}

/**
 * Season stat leaders («آمار برتر فصل», cycle-76) from the shared cached
 * data/teams raw fetch — no extra upstream hit. Curated subset of categories
 * (the payload carries ~40); null when the payload has no stats so the UI
 * hides the section (same contract as the other lazy team reads).
 */
export async function getTeamStats(teamId: number): Promise<TeamStatsData | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const st = raw?.stats;
  if (!st || (!Array.isArray(st.players) && !Array.isArray(st.teams))) return null;
  const pickRows = (
    list: FMStatBlock[] | undefined,
    pref: string[],
    kind: "player" | "team",
    limit: number
  ): TeamStatRow[] => {
    const out: TeamStatRow[] = [];
    if (!Array.isArray(list)) return out;
    for (const key of pref) {
      if (out.length >= limit) break;
      const block = list.find((b) => b?.header === key);
      const p = block?.participant;
      const v =
        typeof p?.value === "number"
          ? p.value
          : typeof p?.stat?.value === "number"
            ? p.stat.value
            : NaN;
      if (!block || !Number.isFinite(v)) continue;
      if (kind === "player" && !p?.name) continue;
      const fractions = typeof p?.stat?.fractions === "number" ? p.stat.fractions : 0;
      // cycle-77: topThree context — probed live (UA Chrome/124): player blocks
      // carry the team's own next-best (100% same teamId, participant is always
      // topThree[0]); team blocks carry the league top-3, where topThree[0] is
      // the league leader unless we are first.
      const extras: string[] = [];
      const top = Array.isArray(block.topThree) ? block.topThree : [];
      const fmtEntry = (t: FMStatParticipant, fb: number): string | null => {
        const tv =
          typeof t?.value === "number"
            ? t.value
            : typeof t?.stat?.value === "number"
              ? t.stat.value
              : NaN;
        if (!t?.name || !Number.isFinite(tv)) return null;
        const tf = typeof t.stat?.fractions === "number" ? t.stat.fractions : fb;
        return `${t.name} ${statValueFa(tv, tf)}${STAT_UNIT[key] || ""}`;
      };
      if (kind === "player") {
        for (const t of top) {
          if (extras.length >= 2) break;
          if (t?.name === p?.name) continue;
          const s = fmtEntry(t, fractions);
          if (s) extras.push(s);
        }
      } else {
        const l = top[0];
        const isUs =
          typeof l?.teamId === "number" ? l.teamId === teamId : l?.name === p?.name;
        if (l && !isUs) {
          const s = fmtEntry(l, fractions);
          if (s) extras.push(s);
        }
      }
      out.push({
        key,
        nameFa: STAT_FA[key] || key,
        kind,
        ...(kind === "player" && p?.name ? { leader: p.name } : {}),
        value: statValueFa(v, fractions) + (STAT_UNIT[key] || ""),
        ...(typeof p?.rank === "number" && p.rank > 0 ? { rank: p.rank } : {}),
        ...(extras.length > 0 ? { extras } : {}),
      });
    }
    return out;
  };
  const playerRows = pickRows(st.players, STAT_PLAYER_PREF, "player", 6);
  const teamRows = pickRows(st.teams, STAT_TEAM_PREF, "team", 4);
  if (playerRows.length === 0 && teamRows.length === 0) return null;
  return { playerRows, teamRows };
}

// ---------------- FotMob: team league history (data/teams endpoint, cycle-80) ----------------
// Probed live (2026-10-29, UA Chrome/124): history.historicalTableData.ranks on
// the SAME data/teams payload — per-season league finishes {tournamentName,
// seasonName, shortSeasonName, position, numberOfTeams, stats:{points, wins,
// draws, loss}}; 17 seasons on Celtic 9925 / Palace 9826 / City 8456. NOTE: a
// true season SWITCHER is not feasible — allAvailableSeasons is [] on all three
// reference teams, so this feed is the honest season-history read.

export interface TeamSeasonRank {
  season: string; // "2025/2026" (stable React key)
  shortFa: string; // pre-formatted «۲۵/۲۶»
  tournamentFa: string;
  position: number;
  ofTeams?: number;
  points: number;
  wins: number;
  draws: number;
  losses: number;
  live?: boolean; // seasonName === inferred current season → in progress
}

export interface TeamSeasonHistory {
  total: number; // full archive depth in the source
  items: TeamSeasonRank[]; // most recent first, capped for mobile
}

/** How many past seasons the mobile card shows (source carries ~17). */
const SEASON_HISTORY_SHOWN = 8;

/** European-style season key containing today (Tehran): Jul→Dec = Y/Y+1. */
const currentSeasonKey = (): string => {
  const t = todayInTehran(); // YYYYMMDD
  const y = Number(t.slice(0, 4));
  const m = Number(t.slice(4, 6));
  return m >= 7 ? `${y}/${y + 1}` : `${y - 1}/${y}`;
};

/**
 * Per-season league finishes («سوابق لیگ», cycle-80) from the shared cached
 * data/teams raw fetch — no extra upstream hit. Most recent first, capped at
 * SEASON_HISTORY_SHOWN rows; null when the payload has no ranks so the UI
 * hides the section (same contract as the other lazy team reads).
 */
interface FMCoachHistoryRaw {
  id?: number;
  name?: string;
  season?: string;
  leagueId?: number;
  leagueName?: string;
  win?: number;
  draw?: number;
  loss?: number;
  pointsPerGame?: number;
  winPercentage?: number;
}

export async function getTeamSeasonHistory(teamId: number): Promise<TeamSeasonHistory | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const ranks = raw?.history?.historicalTableData?.ranks;
  if (!Array.isArray(ranks) || ranks.length === 0) return null;
  const items: TeamSeasonRank[] = [];
  const cur = currentSeasonKey();
  for (const r of ranks) {
    const season = String(r?.seasonName || "");
    const position = Number(r?.position);
    if (!season || !Number.isFinite(position) || position <= 0) continue;
    const s = r?.stats || {};
    const num = (v: unknown): number => (Number.isFinite(Number(v)) ? Number(v) : 0);
    items.push({
      season,
      shortFa: faDigits(r?.shortSeasonName || season),
      tournamentFa: TROPHY_FA[String(r?.tournamentName || "")] || String(r?.tournamentName || ""),
      position,
      ...(Number.isFinite(Number(r?.numberOfTeams)) && Number(r?.numberOfTeams) > 0
        ? { ofTeams: Number(r?.numberOfTeams) }
        : {}),
      points: num(s.points),
      wins: num(s.wins),
      draws: num(s.draws),
      losses: num(s.loss),
      ...(season === cur ? { live: true } : {}),
    });
  }
  if (items.length === 0) return null;
  items.sort((a, b) => b.season.localeCompare(a.season));
  return { total: items.length, items: items.slice(0, SEASON_HISTORY_SHOWN) };
}

// ---------------- FotMob: team coach history (data/teams endpoint, cycle-91) ----------------
// «تاریخچهٔ نیمکت» — the bench timeline. Consecutive same-coach seasons are
// grouped into one tenure (Guardiola 2016/17→2025/26 on City); a mid-season
// handover or a return after a gap naturally starts a new tenure. Totals are
// plain sums; ppg/winPct are games-weighted averages of the source rows.
// Newest first. Same contract as every other lazy team read: null → UI hides.

export interface TeamCoachSeason {
  season: string; // "2025/2026" (stable React key within tenure)
  shortFa: string; // pre-formatted «۲۵/۲۶»
  leagueName: string;
  win: number;
  draw: number;
  loss: number;
  ppg: number;
}

export interface TeamCoachTenure {
  name: string;
  from: string; // "2016/2017"
  to: string; // "2025/2026"
  fromShortFa: string; // «۱۶/۱۷»
  toShortFa: string; // «۲۵/۲۶»
  leagueName: string; // primary league of the tenure's LATEST season (Palace tenures cross Championship→PL)
  seasons: number;
  games: number;
  win: number;
  draw: number;
  loss: number;
  ppg: number; // games-weighted avg, 2dp
  winPct: number; // 0..100, 0dp
  live?: boolean; // tenure contains the current season → «نیمکت فعلی»
  perSeason: TeamCoachSeason[]; // newest first
}

export interface TeamCoachHistory {
  total: number; // season rows in the source
  tenures: TeamCoachTenure[]; // newest first
}

/** "2016/2017" → «۱۶/۱۷» (same visual language as the season-history chips). */
const coachShortSeasonFa = (season: string): string => {
  const parts = season.split("/");
  if (parts.length !== 2) return faDigits(season);
  return faDigits(`${parts[0].slice(-2)}/${parts[1].slice(-2)}`);
};

export async function getTeamCoachHistory(teamId: number): Promise<TeamCoachHistory | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const list = raw?.history?.coachHistory;
  if (!Array.isArray(list) || list.length === 0) return null;
  const num = (v: unknown): number => (Number.isFinite(Number(v)) ? Number(v) : 0);
  const cur = currentSeasonKey();
  const rows = list
    .map((r) => {
      const name = String(r?.name || "");
      const season = String(r?.season || "");
      if (!name || !season) return null;
      return {
        name,
        season,
        leagueName: String(r?.leagueName || ""),
        win: num(r?.win),
        draw: num(r?.draw),
        loss: num(r?.loss),
        ppg: num(r?.pointsPerGame),
        winPct: num(r?.winPercentage),
      };
    })
    .filter((x): x is NonNullable<typeof x> => x !== null)
    // payload is ascending, but never trust order — group on a known order
    .sort((a, b) => a.season.localeCompare(b.season));
  if (rows.length === 0) return null;

  interface Acc {
    name: string;
    from: string;
    to: string;
    leagueName: string;
    games: number;
    win: number;
    draw: number;
    loss: number;
    ppgSum: number; // Σ ppg·games
    pctSum: number; // Σ winPct·games
    live: boolean;
    perSeason: TeamCoachSeason[]; // built newest-first via unshift
  }
  const accs: Acc[] = [];
  for (const r of rows) {
    const games = Math.max(r.win + r.draw + r.loss, 0);
    const last = accs[accs.length - 1];
    if (last && last.name === r.name) {
      last.to = r.season;
      last.leagueName = r.leagueName; // latest season's primary league wins
      last.games += games;
      last.win += r.win;
      last.draw += r.draw;
      last.loss += r.loss;
      last.ppgSum += r.ppg * games;
      last.pctSum += r.winPct * games;
      last.live = last.live || r.season === cur;
      last.perSeason.unshift({
        season: r.season,
        shortFa: coachShortSeasonFa(r.season),
        leagueName: r.leagueName,
        win: r.win,
        draw: r.draw,
        loss: r.loss,
        ppg: r.ppg,
      });
    } else {
      accs.push({
        name: r.name,
        from: r.season,
        to: r.season,
        leagueName: r.leagueName,
        games,
        win: r.win,
        draw: r.draw,
        loss: r.loss,
        ppgSum: r.ppg * games,
        pctSum: r.winPct * games,
        live: r.season === cur,
        perSeason: [
          {
            season: r.season,
            shortFa: coachShortSeasonFa(r.season),
            leagueName: r.leagueName,
            win: r.win,
            draw: r.draw,
            loss: r.loss,
            ppg: r.ppg,
          },
        ],
      });
    }
  }

  const tenures: TeamCoachTenure[] = accs.map((a) => ({
    name: a.name,
    from: a.from,
    to: a.to,
    fromShortFa: coachShortSeasonFa(a.from),
    toShortFa: coachShortSeasonFa(a.to),
    leagueName: a.leagueName,
    seasons: a.perSeason.length,
    games: a.games,
    win: a.win,
    draw: a.draw,
    loss: a.loss,
    ppg: a.games > 0 ? Math.round((a.ppgSum / a.games) * 100) / 100 : 0,
    winPct: a.games > 0 ? Math.round((a.pctSum / a.games) * 100) : 0,
    ...(a.live ? { live: true } : {}),
    perSeason: a.perSeason,
  }));
  if (tenures.length === 0) return null;
  tenures.reverse(); // newest bench first
  return { total: rows.length, tenures };
}

// ---------------- FotMob: team key players («بازیکنان کلیدی فصل», cycle-95) ----------------
// Three league-scoped rankings of the club's own players for the primary
// season, read from the SAME cached data/teams payload (overview.topPlayers,
// probed cycle-95) — zero extra upstream. Null → section hidden.
export interface TeamTopPlayerRow {
  playerId: number;
  name: string;
  nameFa: string; // display name — curated Persian (player-names-fa) when mapped, else the raw upstream name (honest fallback, cycle-96 convention); cycle-104
  rank: number | null; // league-wide rank in this stat (Haaland = 1 PL rating)
  value: number;
  fmt: "fraction" | "number";
  fractions: number; // decimals for fraction format
}

export interface TeamTopPlayers {
  rating: TeamTopPlayerRow[];
  goals: TeamTopPlayerRow[];
  assists: TeamTopPlayerRow[];
}

export async function getTeamTopPlayers(teamId: number): Promise<TeamTopPlayers | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const tp = raw?.overview?.topPlayers;
  if (!tp || typeof tp !== "object") return null;
  const mapBlock = (block: FMTopPlayerBlockRaw | undefined): TeamTopPlayerRow[] => {
    const list = Array.isArray(block?.players) ? block.players : [];
    const rows: TeamTopPlayerRow[] = [];
    const seen = new Set<number>();
    for (const p of list.slice(0, 3)) {
      // payload gives ≤3 per block; slice defensively anyway
      const id = Number(p?.id);
      const name = String(p?.name || "");
      if (!Number.isFinite(id) || id <= 0 || !name || seen.has(id)) continue;
      seen.add(id);
      const value = Number(p?.value);
      if (!Number.isFinite(value)) continue;
      const fmt = String(p?.stat?.format || "") === "fraction" ? "fraction" : "number";
      const fr = Number(p?.stat?.fractions);
      rows.push({
        playerId: id,
        name,
        nameFa: playerFa(name),
        rank: Number(p?.rank) > 0 && Number.isFinite(Number(p?.rank)) ? Number(p.rank) : null,
        value,
        fmt,
        fractions: Number.isFinite(fr) ? fr : fmt === "fraction" ? 2 : 0,
      });
    }
    return rows;
  };
  const out: TeamTopPlayers = {
    rating: mapBlock(tp.byRating),
    goals: mapBlock(tp.byGoals),
    assists: mapBlock(tp.byAssists),
  };
  if (out.rating.length === 0 && out.goals.length === 0 && out.assists.length === 0) return null;
  return out;
}

// ---------------- FotMob: team full-season fixtures (data/teams endpoint, cycle-81) ----------------
// Probed live (2026-10-29, UA Chrome/124): fixtures.allFixtures on the SAME
// data/teams payload — { fixtures: [ { id, home/away {id, name, score},
// tournament {name, leagueId}, status {utcTime, finished, started, cancelled,
// scoreStr}, notStarted } ], lastMatch, nextMatch }; 49 entries on Celtic 9925
// (league + cups + friendlies, whole season) — far beyond the 10-result /
// 8-upcoming windows the team page already shows.

export interface TeamSeasonFixture {
  id: number;
  utcTime: string; // ISO
  home: { id: number; name: string; fa: string; score: number | null };
  away: { id: number; name: string; fa: string; score: number | null };
  tournamentFa: string;
  finished: boolean;
  started: boolean;
  /** cycle-85: upstream verdict from the team's perspective (W/D/L) — scoreStr
   *  alone mislabels penalty shootouts as draws; null when undecidable. */
  verdict: "W" | "D" | "L" | null;
  /** cycle-85: shootout score when the tie went to penalties (home-away order,
   *  same direction as the main score). */
  pens?: { h: number; a: number };
}

export interface TeamFixturesAll {
  total: number; // everything in the source (results + upcoming)
  results: TeamSeasonFixture[]; // finished, newest first
  upcoming: TeamSeasonFixture[]; // not finished (incl. live), soonest first
}

/**
 * Full season fixture archive («همهٔ بازی‌های فصل», cycle-81) from the shared
 * cached data/teams raw fetch — no extra upstream hit. Cancelled rows are
 * dropped; results sorted newest-first, upcoming soonest-first; null when the
 * payload has no list so the UI hides the section (same contract as the other
 * lazy team reads).
 */
export async function getTeamFixturesAll(teamId: number): Promise<TeamFixturesAll | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const list = raw?.fixtures?.allFixtures?.fixtures;
  if (!Array.isArray(list) || list.length === 0) return null;
  const results: TeamSeasonFixture[] = [];
  const upcoming: TeamSeasonFixture[] = [];
  for (const f of list) {
    const id = Number(f?.id);
    const utcTime = String(f?.status?.utcTime || "");
    const home = f?.home;
    const away = f?.away;
    if (!id || !utcTime || !home?.name || !away?.name) continue;
    if (f?.status?.cancelled) continue;
    const finished = Boolean(f?.status?.finished);
    // cycle-85 score provenance: for finished matches status.scoreStr is the
    // canonical regulation+ET score, while the entry home/away scores carry
    // the SHOOTOUT score on penalty ties (probed: City friendly 5406269 entry
    // 2-4 vs scoreStr «1 - 1», reason penalties_short — 52 normal finished
    // rows have entry == scoreStr, zero mismatches). Unfinished rows keep the
    // entry scores (live/none).
    const sm = /^\s*(\d+)\s*-\s*(\d+)\s*$/.exec(String(f?.status?.scoreStr || ""));
    const reasonKey = String(f?.status?.reason?.shortKey || "");
    let hs = typeof home.score === "number" ? home.score : null;
    let as = typeof away.score === "number" ? away.score : null;
    let pens: { h: number; a: number } | undefined;
    if (finished && sm) {
      if (reasonKey === "penalties_short" && hs != null && as != null) {
        pens = { h: hs, a: as }; // entry scores = shootout outcome
      }
      hs = Number(sm[1]); // pill = regulation+ET score
      as = Number(sm[2]);
    }
    const row: TeamSeasonFixture = {
      id,
      utcTime,
      home: {
        id: Number(home.id || 0),
        name: home.name,
        fa: teamFa(home.name) || home.name,
        score: hs,
      },
      away: {
        id: Number(away.id || 0),
        name: away.name,
        fa: teamFa(away.name) || away.name,
        score: as,
      },
      // exact league names first (TROPHY_FA carries «Premiership»/«Premier
      // League»/… which competitionFa deliberately keeps English when the
      // country is unknown), then the general competition map, then the raw
      tournamentFa:
        TROPHY_FA[String(f?.tournament?.name || "")] ||
        competitionFa(String(f?.tournament?.name || "")) ||
        "بازی",
      finished,
      started: Boolean(f?.status?.started),
      verdict: null,
    };
    if (pens) row.pens = pens;
    // verdict: the upstream result field (1/0/-1, team perspective — probed
    // 53/53 started fixtures across the reference clubs) is authoritative;
    // scoreStr alone mislabels shootout ties as draws. Fallback: score compare.
    if (finished) {
      const rv = f?.result;
      if (rv === 1 || rv === 0 || rv === -1) {
        row.verdict = rv === 1 ? "W" : rv === 0 ? "D" : "L";
      } else if (row.home.score != null && row.away.score != null) {
        const isHome = Number(home.id || 0) === teamId;
        row.verdict =
          row.home.score === row.away.score
            ? "D"
            : (isHome ? row.home.score > row.away.score : row.away.score > row.home.score)
              ? "W"
              : "L";
      }
    }
    if (row.finished) results.push(row);
    else upcoming.push(row);
  }
  if (results.length === 0 && upcoming.length === 0) return null;
  results.sort((a, b) => b.utcTime.localeCompare(a.utcTime));
  upcoming.sort((a, b) => a.utcTime.localeCompare(b.utcTime));
  return { total: results.length + upcoming.length, results, upcoming };
}

// ---------------- FotMob: fixture difficulty («سختی بازی‌های پیش‌رو», cycle-112) ----------------
// The fixture-difficulty widget payload from the SAME cached data/teams raw
// fetch (overview.fixtureDifficulty, probed cycle-112) — zero extra upstream.
// FotMob's own rating of each of the next fixtures (small int, 1..3 observed
// across 9 clubs) plus an overall verdict enum. Unknown verdict keys drop the
// verdict (honest convention — same as weather keys / match insights); a
// payload without fixtures → null so the UI hides the section.

export interface TeamDifficultyFixture {
  matchId: number | null; // → links to /match/{id} when known
  opponentId: number;
  opponentFa: string; // curated Persian via teamFa when mapped, else raw upstream (honest contract)
  isHome: boolean;
  difficulty: number | null; // upstream small int; rendered as filled dots on a 1..5 scale
  utcTime: string; // ISO
}

export interface TeamFixtureDifficulty {
  leagueFa: string; // league context of the fixtures (LEAGUES/competitionFa map, honest fallback)
  verdictFa: string | null; // curated verdict («سخت»/«میانه»/«مدیریت‌پذیر»); unknown key → null (chip hidden)
  fixtures: TeamDifficultyFixture[];
}

// cycle-112 probed enum across 9 clubs: difficulty_moderate (City/Arsenal/
// Milan/Brighton), difficulty_manageable (Bologna/Celtic/Coventry),
// difficulty_hard (Fulham/Venezia). Unknown keys drop (honest convention).
const DIFFICULTY_VERDICT_FA: Record<string, string> = {
  difficulty_manageable: "مدیریت‌پذیر",
  difficulty_moderate: "میانه",
  difficulty_hard: "سخت",
};

// cycle-120: raw lastLineupStats (see FMTeamDataRaw.overview comment)
interface FMLastLineupStatsRaw {
  id?: number;
  name?: string;
  rating?: number;
  formation?: string;
  coach?: { id?: number; name?: string; countryName?: string } | null;
  averageStarterAge?: number;
  totalStarterMarketValue?: number;
  lastMatch?: {
    matchId?: number;
    homeTeamId?: number;
    homeTeamName?: string;
    awayTeamId?: number;
    awayTeamName?: string;
  } | null;
  starters?: Array<{
    id?: number;
    name?: string;
    shirtNumber?: string;
    marketValue?: number;
    performance?: {
      rating?: number;
      seasonRating?: number;
      seasonGoals?: number;
      seasonAssists?: number;
      totalDistanceCovered?: number;
      topSpeed?: number;
      playerOfTheMatch?: boolean;
      events?: Array<{ type?: string }> | null;
    } | null;
  }> | null;
}

export interface TeamLastLineupPlayer {
  id: number;                  // player id-space; >0 → /player/{id} link (cycle-117 contract)
  name: string;                // Persian via playerFa when mapped, honest English otherwise
  shirt: string | null;
  matchRating: number | null;  // performance.rating — the last match only
  seasonRating: number | null;
  seasonGoals: number | null;
  seasonAssists: number | null;
  distanceKm: number | null;   // totalDistanceCovered m → km, one decimal
  topSpeedKmh: number | null;
  marketValueFa: string | null; // cycle-116 formatter, same EUR wording (no drift)
  yellow: boolean;
  red: boolean;
  motm: boolean;               // performance.playerOfTheMatch
}

export interface TeamLastLineup {
  formation: string | null;
  coachName: string | null;    // honest English (coach names unmapped — Loftus-Cheek contract)
  teamMatchRating: number | null;
  averageAge: number | null;
  totalMarketValueFa: string | null;
  lastMatch: { matchId: number; opponentId: number; opponentFa: string } | null;
  starters: TeamLastLineupPlayer[];
}

/** cycle-120 additive export: «آخرین ترکیب» — the XI that actually started the
 *  team's most recent played match, from the SAME cached data/teams payload
 *  the squad/transfers/trophies/venue/stats/history/coaches/top-players and
 *  fixtureDifficulty reads use, so this adds zero upstream hits. Null when
 *  the source has no block (UI hides the section, legend-111 contract). */
export async function getTeamLastLineup(teamId: number): Promise<TeamLastLineup | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const lls = raw?.overview?.lastLineupStats;
  const startersRaw = lls?.starters;
  if (!lls || !Array.isArray(startersRaw) || startersRaw.length === 0) return null;
  const num = (v: unknown): number | null =>
    typeof v === "number" && Number.isFinite(v) ? v : null;
  const starters: TeamLastLineupPlayer[] = [];
  for (const s of startersRaw) {
    const id = Number(s?.id || 0);
    const name = String(s?.name || "");
    if (!id || !name) continue;
    const perf = s?.performance || null;
    const evs = Array.isArray(perf?.events) ? perf.events : [];
    const dist = num(perf?.totalDistanceCovered);
    const mv = num(s?.marketValue);
    starters.push({
      id,
      name: playerFa(name),
      shirt: typeof s?.shirtNumber === "string" && s.shirtNumber ? s.shirtNumber : null,
      matchRating: num(perf?.rating),
      seasonRating: num(perf?.seasonRating),
      seasonGoals: num(perf?.seasonGoals),
      seasonAssists: num(perf?.seasonAssists),
      distanceKm: dist != null ? Math.round(dist / 100) / 10 : null,
      topSpeedKmh: num(perf?.topSpeed),
      marketValueFa: mv != null && mv > 0 ? marketValueFa(mv) : null,
      yellow: evs.some((e) => e?.type === "yellowCard"),
      red: evs.some((e) => e?.type === "redCard" || e?.type === "yellowredCard"),
      motm: perf?.playerOfTheMatch === true,
    });
  }
  if (starters.length === 0) return null;
  const lm = lls.lastMatch || null;
  let lastMatch: TeamLastLineup["lastMatch"] = null;
  if (lm && typeof lm.matchId === "number" && lm.matchId > 0) {
    const isHome = Number(lm.homeTeamId) === teamId;
    const oppName = isHome ? String(lm.awayTeamName || "") : String(lm.homeTeamName || "");
    if (oppName) {
      lastMatch = {
        matchId: lm.matchId,
        opponentId: isHome ? Number(lm.awayTeamId || 0) : Number(lm.homeTeamId || 0),
        opponentFa: teamFa(oppName) || oppName,
      };
    }
  }
  const age = num(lls.averageStarterAge);
  const tmv = num(lls.totalStarterMarketValue);
  return {
    formation: typeof lls.formation === "string" && lls.formation ? lls.formation : null,
    coachName: typeof lls.coach?.name === "string" && lls.coach.name ? lls.coach.name : null,
    teamMatchRating: num(lls.rating),
    averageAge: age,
    totalMarketValueFa: tmv != null && tmv > 0 ? marketValueFa(tmv) : null,
    lastMatch,
    starters,
  };
}

export async function getTeamFixtureDifficulty(teamId: number): Promise<TeamFixtureDifficulty | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const fd = raw?.overview?.fixtureDifficulty;
  const list = fd?.fixtures;
  if (!fd || !Array.isArray(list) || list.length === 0) return null;
  const fixtures: TeamDifficultyFixture[] = [];
  for (const f of list) {
    const oppId = Number(f?.opponentId || 0);
    const utcTime = String(f?.matchDateUtc || "");
    if (!oppId || !utcTime) continue;
    const d = typeof f?.difficulty === "number" && Number.isFinite(f.difficulty) ? f.difficulty : null;
    fixtures.push({
      matchId: Number(f?.matchId) > 0 ? Number(f.matchId) : null,
      opponentId: oppId,
      opponentFa: teamFa(f?.opponentName || undefined) || f?.opponentName || "",
      isHome: Boolean(f?.isHome),
      difficulty: d && d >= 1 && d <= 5 ? d : null,
      utcTime,
    });
  }
  if (fixtures.length === 0) return null;
  return {
    leagueFa: leagueFaById(fd.leagueId, fd.leagueName),
    verdictFa: fd.difficultyKey ? DIFFICULTY_VERDICT_FA[fd.difficultyKey] ?? null : null,
    fixtures,
  };
}

// ---------------- FotMob: league title history (data/leagues endpoint, cycle-121) ----------------

// cycle-121 raw shape (see FotMobLeague.seasons comment)
interface FMTitleSeasonRaw {
  seasonName?: string;
  winner?: { id?: number; name?: string; seasonName?: string; winner?: boolean } | null;
  loser?: { id?: number; name?: string; seasonName?: string } | null;
}

export interface LeagueTitleSeason {
  season: string;          // raw upstream season name ("2025/2026", "1929")
  championId: number;      // >0 → /team/{id} link (cycle-117 contract)
  championFa: string;      // teamFa-mapped Persian, honest English fallback
  runnerUpId: number | null;
  runnerUpFa: string | null;
}

export interface LeagueTitleHistory {
  total: number;
  items: LeagueTitleSeason[]; // newest first
}

/** cycle-121 additive export: «قهرمانان» — the league's full title history
 *  from the SAME cached data/leagues payload the standings/fixtures/bracket/
 *  transfers reads use (top-level raw.seasons: winner = champion, loser =
 *  runner-up; probed uniform pl=127 / seriea=121 / laliga=95 / ucl=71 with
 *  both names on every entry; since cycle-136 persiangulf serves 24 too).
 *  Season-independent — fetched on the current
 *  raw, so zero upstream hits and no cache-key bump. Null when the source
 *  has no list (UI hides the tab, legend-111 contract); a null upstream
 *  payload still surfaces as LeagueUnavailableError → designed 503 like
 *  every other league surface. */
export async function getLeagueTitleHistory(leagueKey: string, season?: string): Promise<LeagueTitleHistory | null> {
  const { raw } = await getLeagueRaw(leagueKey, season);
  const list = raw?.seasons;
  if (!Array.isArray(list) || list.length === 0) return null;
  const items: LeagueTitleSeason[] = [];
  for (const s of list) {
    const seasonName = String(s?.seasonName || "");
    const wName = String(s?.winner?.name || "");
    if (!seasonName || !wName) continue;
    const wId = Number(s?.winner?.id || 0);
    const lName = String(s?.loser?.name || "");
    const lId = Number(s?.loser?.id || 0);
    items.push({
      season: seasonName,
      championId: wId > 0 ? wId : 0,
      championFa: teamFa(wName) || wName,
      runnerUpId: lName && lId > 0 ? lId : null,
      runnerUpFa: lName ? teamFa(lName) || lName : null,
    });
  }
  if (items.length === 0) return null;
  // upstream serves seasons[] NEWEST-first (probed: seasons[0] = 2025/2026) — serve as-is.
  return { total: items.length, items };
}
