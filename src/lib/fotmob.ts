// ------------------------------------------------------------------
// Remontada — server-side football data layer
// Primary:  FotMob (unofficial, keyless)
// Fallback: ESPN public APIs
// ------------------------------------------------------------------
import { LEAGUES, teamFa, fotmobTeamLogo, competitionFa, countryFa } from "./leagues";
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
  xa?: number;        // cycle-230 additive: "Expected assist (xA)" — the badge twin of the xG badge
  bigChances?: number; // cycle-231 additive: "Big chances created" — the creation-volume badge (integer, the 215 convention)
  xgot?: number;      // cycle-232 additive: "Expected goals on target (xGOT)" — the on-target accuracy badge (one decimal, the 226/230 convention)
  chancesCreated?: number; // cycle-235 additive: "Chances created" — the TOTAL-creation volume badge (integer, the 215 convention)
  bigChancesMissed?: number; // cycle-236 additive: "Big chances missed" — the missed-volume badge (integer, the 215 convention)
  rating?: number;    // "FotMob rating"
  minutes?: number;   // "Minutes played" (enables minutes-per-goal)
}

export interface AssistEntry {
  rank: number;
  name: string;
  /** cycle-170 additive: honest Persian name (playerFa) — raw English fallback, same rule as scorers. */
  nameFa?: string;
  team: string;
  teamId: number;
  assists: number;
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-210 additive: one «آقای امتیاز» row — the rating twin of
 *  AssistEntry (the 170 honest-name contract included), except the value is
 *  a DECIMAL that must never be rounded or re-scaled. */
export interface RatingEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as scorers/assists. */
  nameFa?: string;
  team: string;
  teamId: number;
  rating: number;  // FotMob rating kept verbatim (8.6, 8.51…) — display formats, storage never rounds
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-215 additive: one «گل نخرده» row — the goalkeeper twin of
 *  AssistEntry (the 170 honest-name contract included); the value is a
 *  plain INTEGER (upstream StatValue arrives as 6.0 → stored rounded once,
 *  the family's integer convention — goals/assists/cards — not the rating
 *  one). */
export interface CleanSheetEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as scorers/assists/ratings. */
  nameFa?: string;
  team: string;
  teamId: number;
  cleanSheets: number;  // clean sheets kept as an integer (StatValue 6.0 → 6)
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-216 additive: one «گل+پاس» row — the participation twin of
 *  CleanSheetEntry/AssistEntry (the 170 honest-name contract included);
 *  the value is a plain INTEGER (StatValue 16.0 → 16, the goals/assists
 *  convention). NOT computed as goals+assists of the scorers list — it is
 *  the upstream's OWN combined ranking, a genuinely different order (an
 *  8G+8A player outranks a 13G+0A one). */
export interface GPlusAEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  gPlusA: number;  // combined goals+assists kept as an integer (StatValue 16.0 → 16)
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-217 additive: one «گل‌های پیشگیری‌شده» row — the goalkeeper QUALITY
 *  twin (the 215 clean-sheet block is the keeper's COUNT, this is the
 *  keeper's WORTH: xG-on-target faced minus goals actually conceded). The
 *  170 honest-name contract included. The value is a DECIMAL kept verbatim
 *  (the rating convention, NOT the integer one) — and the family's FIRST
 *  SIGNED leaderboard: live-probed laliga season/38843 carries negatives
 *  at the tail (David Soria −2.4 at rank 21), a keeper who conceded more
 *  than expected renders a negative pill. Sorting is the plain desc order
 *  (most-prevented first) — negatives sink to the tail naturally. */
export interface GoalsPreventedEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  goalsPrevented: number;  // xGOT faced − goals conceded, kept VERBATIM (8.2, −2.4) — storage never rounds
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-220 additive: one «بیشترین دقایق» row — the deep-file family's
 *  EIGHTH sibling and the first NON-scoring, NON-keeper surface: pure
 *  presence (minutes on the pitch). Live-probed 2026-10-30 UA Chrome/124:
 *  the "Minutes played" category carries its own fetchAllUrl →
 *  data.fotmob.com stats/{id}/season/{sid}/mins_played.json (no underscore
 *  prefix — the family's first member whose file name lacks it), laliga
 *  current season/38843 = 482 ranked rows, the 2025/26 raw serves its OWN
 *  file (season/27233, 600 rows, Antonio Sivera / David Soria / Ionuț Radu
 *  3420 = 38×90 — every second of the finished season, frozen — the 202
 *  anchor pattern). Two upstream quirks this sibling must respect:
 *  (1) the file carries COMPETITION tie-ranks (1,1,1,4,4,4,4,8,9,10 at
 *  25/26) unlike clean_sheet.json's sequential ones — the merge re-ranks
 *  POSITIONALLY like every sibling (rank = position in the served top-10),
 *  the upstream's own tie ORDER (alphabetical within equal minutes) is
 *  kept as the sort-stable base order;
 *  (2) values are DECIMAL floats (900.0) rounded ONCE at build — the
 *  integer convention (clean sheets 215 / G+A 216), never the verbatim
 *  float one. */
export interface MinutesEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  minutes: number;  // Math.round(StatValue) ONCE — the integer convention (215/216), not the float one
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-221 additive: one «درصد سیو» row — the deep-file family's NINTH
 *  sibling and the THIRD keeper surface. Live-probed 2026-10-30 UA
 *  Chrome/124: the "Save percentage" category carries its own fetchAllUrl →
 *  data.fotmob.com stats/{id}/season/{sid}/_save_percentage.json, serving
 *  on SIX of the seven leagues (ucl 45 / pl 21 / laliga 21 / seriea 21 /
 *  bundesliga 20 / ligue1 18 rows) — persiangulf honestly absent (no
 *  keeper category at all, the 215/217 pattern). The file's row shape is
 *  the FMStatFullRow family but the participant rides FLAT:
 *  ParticipantName + ParticiantId (upstream's own typo the type already
 *  handles). StatValue is a PERCENT with one decimal (82.5 = 82.5% saved —
 *  StatFormat "percent", StatDecimals 1) kept VERBATIM — the third
 *  non-integer member after ratings 210 and goals prevented 217. The
 *  SubStatValue (goals conceded), MinutesPlayed and MatchesPlayed columns
 *  ride along in the file but the surface serves the percentage only (one
 *  stat per row, the family contract). Upstream Rank: SEQUENTIAL on the
 *  domestics (1..21, like clean_sheet.json) but COMPETITION tie-ranked on
 *  ucl (1,2,3,3,5,6 live-probed) — the merge re-ranks POSITIONALLY like
 *  every sibling either way. */
export interface SavePercentageEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  savePercentage: number;  // StatValue VERBATIM — percent, one decimal (82.5), the 210/217 convention, never rounded
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-222: «سیو در هر ۹۰» — the deep-file family's TENTH sibling and the
 *  FOURTH keeper surface (clean sheets 215 / goals prevented 217 / save
 *  percentage 221 → saves per 90 222). Shape = the 221 sibling verbatim:
 *  the FMStatFullRow family with the participant carried FLAT
 *  (ParticipantName + ParticiantId) and StatValue a PER-90 DECIMAL with one
 *  decimal (4.3) kept VERBATIM — the 210/217/221 convention, never rounded.
 *  The file's SubStatValue is the TOTAL saves (43.0) and rides along, but
 *  the surface serves the per-90 rate only (one stat per row, the family
 *  contract — the file's own Title is "Saves per 90"). Upstream Rank:
 *  SEQUENTIAL on the domestics but COMPETITION tie-ranked on ucl (1,1,3,4,
 *  5,5,7,8,8,10 live-probed — the _save_percentage.json class); the merge
 *  re-ranks POSITIONALLY like every sibling either way. */
export interface SavesPer90Entry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  savesPer90: number;  // StatValue VERBATIM — per-90 decimal (4.3), the 210/217/221 convention, never rounded
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-225 additive: one «پنالتی‌های مهارشده» row — the deep-file family's
 *  ELEVENTH sibling and the FIFTH keeper surface (clean sheets 215 / goals
 *  prevented 217 / save percentage 221 / saves per 90 222 → penalty saves
 *  225). Live-probed 2026-10-30 UA Chrome/124: the "Penalty saves" category
 *  serves on SIX of the seven leagues and its penalty_save.json files are
 *  NATURALLY THIN — ucl 2 / pl 2 / laliga 5 / seriea 5 / bundesliga 4 /
 *  ligue1 3 rows (a penalty save is a rare event; the whole league's worth
 *  fits in a handful of rows) — persiangulf honestly absent (no keeper
 *  category at all, the 215/217/221/222 pattern). StatValue is a small
 *  INTEGER rounded ONCE (1.0 → 1, the 215/216 convention — never the
 *  verbatim-float one). CURRENT-SEASON ONLY (the cycle-132 class, probed:
 *  the 2020/21, 2023/24 and 2025/26 finished raws carry NO "Penalty saves"
 *  category — historical views honestly hide the section). Upstream Rank:
 *  COMPETITION tie-ranked on the serving files (laliga 1,2,2,4,5 / ucl 1,1
 *  — probed) — the merge re-ranks POSITIONALLY like every sibling. */
export interface PenaltySavesEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  penaltySaves: number;  // StatValue rounded ONCE (1.0 → 1) — the 215/216 integer convention
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-226 additive: one «گل مورد انتظار» row — the deep-file family's
 *  TWELFTH sibling and the first pure-ANALYTICS surface (goals 23 / assists
 *  175 / cards 50+185 / rating 210 / clean sheets 215 / G+A 216 / goals
 *  prevented 217 / minutes 220 / save percentage 221 / saves per 90 222 /
 *  penalty saves 225 → expected goals 226). The "Expected goals (xG)"
 *  category carries its own fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/expected_goals.json (live-probed 2026-10-30, UA
 *  Chrome/124: serving on SIX of the seven leagues — laliga 389 rows
 *  Mbappé 12.2 / Raphinha 9.2 / Yamal 7.0, ucl 479 rows Guirassy 4.2;
 *  persiangulf honestly absent — no xG category at all, the 215/210
 *  pattern). Decimal values kept VERBATIM — the family's FIFTH
 *  non-integer member (ratings 210 / goals prevented 217 / save percentage
 *  221 / saves per 90 222 → xG 226); upstream precision is EXACTLY one
 *  decimal (live-probed: all 389 laliga rows one-decimal) so the pill
 *  renders toFixed(1) — the 217 display rule, storage never rounds.
 *  SEASON-AWARE (the 124/175/185 class, NOT the 132 one): historical raws
 *  carry their OWN file (the 2020/21 raw serves season/15585, 471 rows,
 *  Lionel Messi 23.9 / Gerard Moreno 19.0 / Karim Benzema 18.8 — frozen,
 *  the 202 anchor pattern). Upstream Rank sequential on the probing
 *  files — the merge re-ranks POSITIONALLY like every sibling. */
export interface XgEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  xg: number;  // StatValue VERBATIM — expected goals decimal (12.2), the 210/217 convention, never rounded
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-230 additive: one «پاس مورد انتظار» row — the deep-file family's
 *  FOURTEENTH sibling and the assist-side ANALYTICS twin of XgEntry (goals
 *  23 / assists 175 / cards 50+185 / rating 210 / clean sheets 215 / G+A
 *  216 / goals prevented 217 / minutes 220 / save percentage 221 / saves
 *  per 90 222 / penalty saves 225 / expected goals 226 / goals per 90 227
 *  → expected assist 230). The "Expected assist (xA)" category carries its
 *  own fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/expected_assists.json (live-probed 2026-10-30,
 *  UA Chrome/124: serving on SIX of the seven globalMerge leagues — ucl
 *  721 Kimmich 1.9 / pl 448 Iwobi 2.6 / laliga 480 Yamal 4.0 / seriea 487
 *  Dybala 3.4 / bundesliga 399 Olise 4.1 / ligue1 422 Thauvin 3.8 rows;
 *  persiangulf honestly absent — no xA category (5 player cats); mas
 *  absent (2 cats); 12 of the other 16 leagues.ts entries serve it too).
 *  Decimal values kept VERBATIM (the SEVENTH non-integer member — the
 *  210/217/221/222/226/227 convention; upstream precision EXACTLY one
 *  decimal, probed maxdec=1 on every serving file). SEASON-AWARE (the
 *  124/175/185/226/227 class): historical raws serve their OWN files
 *  (2020/21 laliga = 565 rows, Messi 13.4 — frozen, the 202 anchor
 *  pattern; 2023/24 pl = Ødegaard 11.2; 2022/23 laliga = Griezmann 9.8).
 *  Wide healthy files → the STANDARD thin guard (the 210 class) applies;
 *  always present (possibly []) like the siblings; feeds without the
 *  category degrade honestly to []. */
export interface XaEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  xa: number;  // StatValue VERBATIM — expected assists decimal (13.4), the 210/217/226 convention, never rounded
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-231 additive: one «سانس بزرگ خلق‌شده» row — the deep-file family's
 *  FIFTEENTH sibling and the production-CREATION volume surface beside the
 *  analytics twins (goals 23 / assists 175 / cards 50+185 / rating 210 /
 *  clean sheets 215 / G+A 216 / goals prevented 217 / minutes 220 / save
 *  percentage 221 / saves per 90 222 / penalty saves 225 / expected goals
 *  226 / goals per 90 227 / expected assist 230 → big chances created
 *  231). The "Big chances created" category carries its own fetchAllUrl →
 *  data.fotmob.com stats/{id}/season/{sid}/big_chances_created.json
 *  (live-probed 2026-10-30, UA Chrome/124: serving on 22 of the 24
 *  leagues.ts entries — every league but persiangulf (5 player cats) and
 *  mas (2 cats), the gp90 footprint — six domestics with WIDE files: ucl
 *  190 Yamal 5 / pl 152 Groß 7 / laliga 185 Yamal 14 / seriea 202 Dybala
 *  8 / bundesliga 160 Nusa+Kane 6 / ligue1 157 Thauvin 9 rows).
 *  INTEGER-VALUED floats (live-probed nonint=0 on every serving file —
 *  StatValue 5.0/14.0) → the 215/216/220 integer convention: rounded once
 *  at build, the pill renders Persian digits WITHOUT dir=ltr. SEASON-AWARE
 *  (the 124/175/185/226/227/230 class): historical raws serve their OWN
 *  files (2020/21 laliga = 309 rows, Messi 22.0 — frozen, the 202 anchor
 *  pattern; 2023/24 pl = Salah 22.0; 2022/23 laliga = Griezmann 24.0).
 *  Wide healthy files → the STANDARD thin guard (the 210 class) applies;
 *  always present (possibly []) like the siblings; feeds without the
 *  category degrade honestly to []. */
export interface BigChancesCreatedEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  bigChances: number;  // StatValue rounded ONCE at build (the 215/220 integer convention — upstream is integer-valued, probed nonint=0)
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-232 additive: one «گل مورد انتظار روی دروازه» row — the deep-file
 *  family's SIXTEENTH sibling and the third ANALYTICS level, the on-target
 *  accuracy twin of the xG surface (goals 23 / assists 175 / cards 50+185 /
 *  rating 210 / clean sheets 215 / G+A 216 / goals prevented 217 / minutes
 *  220 / save percentage 221 / saves per 90 222 / penalty saves 225 /
 *  expected goals 226 / goals per 90 227 / expected assist 230 / big
 *  chances created 231 → expected goals on target 232). The "Expected
 *  goals on target (xGOT)" category carries its own fetchAllUrl →
 *  data.fotmob.com stats/{id}/season/{sid}/expected_goalsontarget.json
 *  (live-probed 2026-10-30, UA Chrome/124: serving on SIX of the seven
 *  globalMerge leagues with WIDE files — ucl 305 Tresoldi 4.5 / pl 241
 *  Haaland 8.2 / laliga 277 Mbappé 12.8 / seriea 286 Malen 6.6 /
 *  bundesliga 227 Füllkrug 6.2 / ligue1 227 Lepaul 6.0 rows; persiangulf
 *  honestly absent — 5 player cats, no xGOT; mas absent, null payload; 12
 *  of the other 16 leagues.ts entries serve it too). Decimal values kept
 *  VERBATIM — the family's EIGHTH non-integer member (the
 *  210/217/221/222/226/227/230 convention, never rounded); upstream
 *  precision is EXACTLY one decimal (probed decimal-counts=[1] on every
 *  serving file AND the historical raw) so the pill renders toFixed(1).
 *  Upstream Rank is COMPETITION tie-ranked on several files (ucl 5,5 / pl
 *  4,4 / seriea 4,4 / ligue1 3,3 — probed); loaders keep the file's own
 *  order and rank verbatim — the merge re-ranks POSITIONALLY like every
 *  sibling. SEASON-AWARE (the 124/175/185/226/227/230/231 class):
 *  historical raws serve their OWN files (2020/21 laliga = 385 rows,
 *  Messi 32.8 / Gerard Moreno 24.8 — frozen, the 202 anchor pattern;
 *  2023/24 pl = 402 rows, Haaland 27.1 / Isak 22.8 / Palmer 20.0). Wide
 *  healthy files → the STANDARD thin guard (the 210 class) applies; always
 *  present (possibly []) like the siblings; feeds without the category
 *  degrade honestly to []. */
export interface XgotEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  xgot: number;  // StatValue VERBATIM — expected goals on target decimal (12.8), the 210/217/226/230 convention, never rounded
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-235 additive: one «فرصت‌های خلق‌شده» row — the deep-file family's
 *  SEVENTEENTH sibling and the TOTAL-creation VOLUME twin of the BCC
 *  surface (goals 23 / assists 175 / cards 50+185 / rating 210 / clean
 *  sheets 215 / G+A 216 / goals prevented 217 / minutes 220 / save
 *  percentage 221 / saves per 90 222 / penalty saves 225 / expected goals
 *  226 / goals per 90 227 / expected assist 230 / big chances created 231
 *  / expected goals on target 232 → chances created 235). The "Chances
 *  created" category carries its own fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/total_att_assist.json (live-probed 2026-10-30,
 *  UA Chrome/124: serving on ALL SIX domestic globalMerge leagues with
 *  WIDE files — ucl 466 Thauvin 15 / pl 323 Groß 23 / laliga 363 Arda
 *  Güler 33 / seriea 382 Giacomo Calò 34 / bundesliga 308 Olise 25 /
 *  ligue1 304 Thauvin 27 rows; persiangulf honestly absent — 5 player
 *  cats; mas absent, empty payload). INTEGER-VALUED floats (live-probed
 *  nonint=0 on every serving file, StatDecimals=0) → the 215/216/220
 *  integer convention: rounded ONCE at build, the pill renders Persian
 *  digits WITHOUT dir=ltr (the minutes/BCC contract — 33 renders «۳۳»). Upstream
 *  Rank is COMPETITION tie-ranked on every file (ucl 10.0 → 4,5,6 / pl
 *  18.0 → 4,4,6 / laliga 21.0 → 6,7,8 — probed); this loader keeps the
 *  file's own order and rank verbatim — the merge re-ranks POSITIONALLY
 *  like every sibling. SEASON-AWARE (the 124/175/185/226/227/230/231/232
 *  class): historical raws serve their OWN files (2020/21 laliga = 466
 *  rows, Lionel Messi 77 / David Ferreiro 73 / Toni Kroos 67 — frozen,
 *  the 202 anchor pattern; the 229 curation rides free — «لیونل مسی»
 *  «تونی کروس»). Wide healthy files → the STANDARD thin guard (the 210
 *  class) applies; always present (possibly []) like the siblings; feeds
 *  without the category degrade honestly to []. */
export interface ChancesCreatedEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  chancesCreated: number;  // StatValue rounded ONCE at build (the 215/220 integer convention — upstream is integer-valued, probed nonint=0)
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-236 additive: one «سانس بزرگ ازدست‌رفته» row — the deep-file
 *  family's EIGHTEENTH sibling and the MISSED-volume twin of the BCC
 *  surface (goals 23 / assists 175 / cards 50+185 / rating 210 / clean
 *  sheets 215 / G+A 216 / goals prevented 217 / minutes 220 / save
 *  percentage 221 / saves per 90 222 / penalty saves 225 / expected goals
 *  226 / goals per 90 227 / expected assist 230 / big chances created 231
 *  / expected goals on target 232 / chances created 235 → big chances
 *  missed 236). The "Big chances missed" category carries its own
 *  fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/big_chance_missed.json (live-probed
 *  2026-10-30, UA Chrome/124: serving on ALL SIX domestic globalMerge
 *  leagues with WIDE files — ucl 140 Haaland 6 / pl 135 Thierno Barry 12
 *  / laliga 142 Mbappé 13 / seriea 171 Malen 9 / bundesliga 126
 *  Demirović 8 / ligue1 128 Mafouta 6 rows; persiangulf honestly absent;
 *  mas absent, null payload). INTEGER-VALUED floats (live-probed
 *  nonint=0 on every serving file, StatDecimals=0) → the 215/216/220
 *  integer convention: rounded ONCE at build, the pill renders Persian
 *  digits WITHOUT dir=ltr (12 renders «۱۲»). Upstream Rank is
 *  COMPETITION tie-ranked on every file (pl 6.0 ×4 / laliga 7.0 ×3 —
 *  probed); this loader keeps the file's own order and rank verbatim —
 *  the merge re-ranks POSITIONALLY like every sibling. SEASON-AWARE (the
 *  124/175/185/226/227/230/231/232/235 class): historical raws serve
 *  their OWN files (2020/21 laliga = 257 rows, Karim Benzema 19 /
 *  Alexander Isak 16 / Rafa Mir 16 — frozen, the 202 anchor pattern; the
 *  229 curation rides free — «کریم بنزما» «رافا میر»). Wide healthy
 *  files → the STANDARD thin guard (the 210 class) applies; always
 *  present (possibly []) like the siblings; feeds without the category
 *  degrade honestly to []. */
export interface BigChancesMissedEntry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  bigChancesMissed: number;  // StatValue rounded ONCE at build (the 215/220 integer convention — upstream is integer-valued, probed nonint=0)
  playerId?: number;  // FotMob player id → links to /player/[id]
}

/** cycle-237 additive: one «گل مورد انتظار تیم‌ها» row — the deep-file
 *  family's NINETEENTH sibling and its FIRST TEAM-PARTICIPANT member:
 *  the team-side LEVEL of the xG surface (goals 23 / assists 175 / cards
 *  50+185 / rating 210 / clean sheets 215 / G+A 216 / goals prevented
 *  217 / minutes 220 / save percentage 221 / saves per 90 222 / penalty
 *  saves 225 / expected goals 226 / goals per 90 227 / expected assist
 *  230 / big chances created 231 / expected goals on target 232 /
 *  chances created 235 / big chances missed 236 → team expected goals
 *  237). The "Expected goals" TEAM category carries its own fetchAllUrl →
 *  data.fotmob.com stats/{id}/season/{sid}/expected_goals_team.json
 *  (live-probed 2026-10-30, UA Chrome/124: serving on ALL SIX domestic
 *  globalMerge leagues with NATURALLY-THIN team files — laliga 20
 *  Barcelona 34.8 / pl 20 Manchester City 16.7 / seriea 20 Inter 25.5 /
 *  bundesliga 18 Bayern 23.8 / ligue1 18 PSG 20.0 / ucl 36 PSG 10.1
 *  rows; uel 36 Leverkusen 11.0 + portugal 18 Benfica 20.8 probed for
 *  breadth; persiangulf honestly absent — 1 team category; mas absent —
 *  4 team cats, no xG). DECIMAL 1-fraction (probed nonint 15-32 rows
 *  per file, maxdec=1 on every serving file) → the 210/217/226/230/232
 *  VERBATIM-decimal convention: storage never rounds, the pill renders
 *  toFixed(1) dir=ltr (34.8 renders «۳۴.۸»). Upstream Rank is positional
 *  (one competition tie probed: portugal 5,5) — kept verbatim; the merge
 *  re-ranks POSITIONALLY like every sibling. The rows' ParticiantId is
 *  ALWAYS 0 (teams carry TeamId) → dedup by TeamId, the id /team/[id]
 *  keys on. The honest-name contract rides the EXISTING teamFa map —
 *  zero new PLAYER_NAME_FA entries (the standings already curate these
 *  clubs). SEASON-AWARE (the 124/…/236 class): historical raws serve
 *  their OWN files (2020/21 laliga = 20 rows, Barcelona 74.3 / Real
 *  Madrid 62.3 / Real Sociedad 61.9 — frozen, the 202 anchor pattern).
 *  Wide-enough files (18-36 rows, comfortably above the family's
 *  FULL_LIST_HEALTHY_MIN floor) → the STANDARD guard (the 210 class)
 *  applies with NO natural-thinness exemption (the 225 class does not
 *  arise); always present (possibly []); feeds without the team
 *  category degrade honestly to []. */
export interface TeamXgEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamXg: number;  // StatValue VERBATIM — xG decimal (34.8), the 210/217/226/230/232 convention, never rounded
}

/** cycle-240 additive: one «گل نخرده‌های تیم‌ها» row — the deep-file
 *  family's TWENTIETH sibling, its SECOND TEAM-PARTICIPANT member and the
 *  team-side LEVEL of the keeper clean-sheets surface (215), the team twin
 *  relationship 237 established for xG. The "Clean sheets" TEAM category
 *  carries its own fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/clean_sheet_team.json (live-probed 2026-10-30,
 *  UA Chrome/124: WIDE files on all six domestic globalMerge leagues —
 *  laliga 18 Athletic Club 6.0 / pl 18 Arsenal 5.0 / seriea 18 Roma 5.0 /
 *  bundesliga 16 Borussia Dortmund 5.0 / ligue1 14 Lorient 5.0 / ucl 17
 *  Arsenal 2.0 rows; portugal 17 with the THREE-WAY tie Arouca/Porto/
 *  Santa Clara 5,5,5 probed for breadth; persiangulf honestly absent (its
 *  feed carries ONE team category, goals_team_match — probed) while MAS
 *  SERVES a naturally-thin 8-row file (Johor Darul Ta'zim 6.0 — the FIRST
 *  below-the-floor serve in the family, the 225 health-rule class on the
 *  mas panel). INTEGER-VALUED floats (StatFormat number — probed int on
 *  every serving file) → the 215/220/231/235/236 integer convention: the
 *  pill renders the integer via String() (6.0 → «۶»), dir=ltr. Upstream
 *  Rank keeps competition ties verbatim (laliga rank 2,2 Atlético+Celta
 *  probed) — the merge re-ranks POSITIONALLY like every sibling. The
 *  rows' ParticiantId is ALWAYS 0 (teams carry TeamId) → dedup by TeamId,
 *  the id /team/[id] keys on. The honest-name contract rides the EXISTING
 *  teamFa map — zero new PLAYER_NAME_FA entries. NO badge twin and NO
 *  global-merge participation BY DESIGN (the 237 team-surface rule).
 *  SEASON-AWARE (the 124/…/236 class): the 2020/21 laliga raw serves its
 *  OWN file — 20 rows, Atletico Madrid 18.0 / Real Madrid 17.0 / Sevilla
 *  17.0 — frozen, the 202 anchor pattern. Wide-enough files on the
 *  domestics (14-20 rows, above the FULL_LIST_HEALTHY_MIN floor) → the
 *  STANDARD guard with ONE documented mas exemption (its 8-row file is
 *  the file's real size, not a dropped fetch — the 176 red-cards lesson);
 *  always present (possibly []); feeds without the team category degrade
 *  honestly to []. */
export interface TeamCleanSheetEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamCleanSheets: number;  // StatValue VERBATIM — integer-valued float (6.0), the 215/220/231/235/236 convention, never rounded
}

/** cycle-241 additive: one «مالکیت توپ تیم‌ها» row — the deep-file
 *  family's TWENTY-FIRST sibling, its THIRD TEAM-PARTICIPANT member and
 *  the team-side possession surface (the 92 boards showed this category
 *  as a ≤3-row podium — the full top-10 file level is new). The "Average
 *  possession" TEAM category carries its own fetchAllUrl →
 *  data.fotmob.com stats/{id}/season/{sid}/possession_percentage_team.json
 *  (live-probed 2026-10-30, UA Chrome/124: WIDE files on all six domestic
 *  globalMerge leagues — laliga 20 Barcelona 69.4 / pl 20 Manchester City
 *  64.2 / seriea 20 Inter 63.0 / bundesliga 18 Bayern München 66.9 /
 *  ligue1 18 Paris Saint-Germain 68.0 / ucl 36 Barcelona 65.2 rows;
 *  portugal 18 Benfica 63.1 probed for breadth; persiangulf AND mas
 *  honestly absent — the 237 absence pair exactly: mas's feed carries
 *  only FOUR team categories and possession is not one of them, probed).
 *  PERCENT 1-fraction (probed maxdec=1 on every serving file, StatFormat
 *  percent) → the 221 percent convention VERBATIM: storage never rounds,
 *  the pill renders toFixed(1) dir=ltr (69.4 renders «۶۹.۴») with NO
 *  appended percent sign (the 221 rendering rule). Upstream Rank kept
 *  verbatim; the merge re-ranks POSITIONALLY like every sibling.
 *  ParticiantId is ALWAYS 0 (teams carry TeamId) → dedup by TeamId, the
 *  id /team/[id] keys on. The honest-name contract rides the EXISTING
 *  teamFa map — zero new PLAYER_NAME_FA entries. NO badge twin and NO
 *  global-merge participation BY DESIGN (the 237 team-surface rule);
 *  the block rides the league page only, rows link /team/[id].
 *  SEASON-AWARE (the 124/…/236 class): the 2020/21 laliga raw serves its
 *  OWN file — 20 rows, Barcelona 65.8 / Sevilla 61.2 / Real Madrid 59.6
 *  — frozen, the 202 anchor pattern. Wide files (18-36 rows, above the
 *  FULL_LIST_HEALTHY_MIN floor) → the STANDARD guard, NO exemption (the
 *  honest-empty pair pg+mas degrades to [] upstream of the guard, the
 *  237 pattern — mas needed NO league-aware floor here, unlike the 240
 *  clean-sheet sibling it does not serve this category at all); always
 *  present (possibly []); feeds without the team category degrade
 *  honestly to []. */
export interface TeamPossessionEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamPossession: number;  // StatValue VERBATIM — percent one decimal (69.4), the 221 percent convention, never rounded
}

/** cycle-242 additive: one «کارت‌های زرد تیم‌ها» row — the deep-file
 *  family's TWENTY-SECOND sibling and its FOURTH TEAM-PARTICIPANT member:
 *  the team-side yellow-card surface (the player-level 50/176 cards
 *  family, the team twin). The "Yellow cards" TEAM category carries its
 *  own fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/total_yel_card_team.json (live-probed
 *  2026-10-30, UA Chrome/124, scripts/cycle242-probe.sh: WIDE files on
 *  all six domestic globalMerge leagues — laliga 20 Getafe 33.0 / pl 20
 *  AFC Bournemouth 22.0 / seriea 20 Fiorentina 20.0 / bundesliga 18
 *  Borussia Mönchengladbach 21.0 / ligue1 18 Nice 19.0 / ucl 36 Club
 *  Brugge 9.0 rows; portugal 18 Académico Viseu 27.0 with the top-3
 *  25,25 tie probed for breadth); persiangulf AND mas honestly absent —
 *  the 237/241 absence pair EXACTLY (pg's feed carries ONE team
 *  category, Goals per match; mas's feed carries FOUR — Goals per
 *  match / Goals conceded per match / Clean sheets / Red cards — and
 *  yellow is not one, probed), so NO league-aware floor is needed — the
 *  honest-empty pair degrades to [] upstream of the guard, the 237/241
 *  pattern (unlike the 240 clean-sheet sibling, mas does not serve this
 *  category at all). INTEGER-VALUED floats (probed int on every serving
 *  file) → the 215/220/231/235/236 integer convention: storage never
 *  rounds, the pill renders String(value) dir=ltr (33.0 renders «۳۳»).
 *  Upstream Rank keeps COMPETITION ties verbatim (laliga rank 5,6 on
 *  25.0 / 15,16,16 on 17.0 probed) — the merge re-ranks POSITIONALLY
 *  like every sibling. ParticiantId is ALWAYS 0 (teams carry TeamId) →
 *  dedup by TeamId. NO badge twin and NO global-merge participation BY
 *  DESIGN (the 237 team-surface rule); the block rides the league page
 *  only, rows link /team/{teamId}. SEASON-AWARE (the 124/…/236 class):
 *  the 2020/21 laliga raw serves its OWN file — season/15585, 20 rows,
 *  Getafe 114.0 / Celta Vigo 104.0 / Atletico Madrid 100.0 — frozen,
 *  the 202 anchor pattern, DISTINCT from the current 33.0 (Getafe tops
 *  BOTH eras — the dirtiest team in the file's history, probed). Wide
 *  files (18-36 rows, above the FULL_LIST_HEALTHY_MIN floor) → the
 *  STANDARD guard, NO exemption; always present (possibly []); feeds
 *  without the team category degrade honestly to []. */
export interface TeamYellowCardEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamYellowCards: number;  // StatValue VERBATIM — integer-valued float (33.0), the 215/220/231/235/236 convention, never rounded
}

/** cycle-245 additive: one «کارت‌های قرمز تیم‌ها» row — the deep-file
 *  family's TWENTY-THIRD sibling and its FIFTH TEAM-PARTICIPANT member
 *  (the team-side red-card surface, the yellow 242 sibling's red brother).
 *  stats/{id}/season/{sid}/total_red_card_team.json (live-probed
 *  2026-10-31, UA Chrome/124 — "Red cards" TEAM category, INTEGER-valued
 *  floats, naturally SHORT files: red cards are rare — laliga 16 / pl 12 /
 *  portugal 13 / mas 11 rows vs seriea 6 / bundesliga 7 / ucl 7 / ligue1 9
 *  / ucl-breadth uel EXACTLY 4 — four of the nine serving files sit under
 *  10 as-found and early-season reds legitimately sit low). NINE serving
 *  leagues — the family's FIRST NINE-league team surface: the six
 *  domestics + uel + portugal AND MAS (its feed carries the "Red cards"
 *  TEAM category — the SECOND mas team-surface after the 240 clean-sheets,
 *  probed: season/47747 file = 11 rows, Kuching City 3.0); persiangulf
 *  honestly absent (its feed carries ONE team category, Goals per match,
 *  probed — the bare direct file serves 15 rows but the app is
 *  feed-driven: no category → honest [] upstream of any fetch). Same
 *  cache as the siblings; the guard is the 240 floor-4 class GENERALIZED
 *  league-wide (the podium can never exceed 3 rows, so ≥4 PROVES the full
 *  file arrived while ≤3 always re-probes — the standard <10 guard would
 *  re-probe forever on the naturally-short files, the exact trap the
 *  cycle-176 PLAYER-red comment documented). Season-aware like every
 *  sibling (the 2020/21 laliga raw serves season/15585 — 19 rows,
 *  Deportivo Alaves 8.0 rank-1 with the 8,8 Betis tie, frozen, DISTINCT
 *  from the current Getafe 5.0). Feeds without the team category degrade
 *  honestly to []. */
export interface TeamRedCardEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamRedCards: number;  // StatValue VERBATIM — integer-valued float (5.0), the 215/220/231/235/236/242 convention, never rounded
}

/** cycle-246 additive: one «گل به از مسابقهٔ تیم‌ها» row — the deep-file
 *  family's TWENTY-FOURTH sibling and its SIXTH TEAM-PARTICIPANT member
 *  (the team-side scoring-rate LEVEL). stats/{id}/season/{sid}/
 *  goals_team_match.json (live-probed 2026-10-31, UA Chrome/124,
 *  scripts/cycle246-sweep.sh): NINE of NINE leagues serve it — the
 *  family's FIRST NINE-league team surface at the STANDARD guard (the
 *  245 red surface reached nine too but needed the floor-4; these files
 *  are WIDE everywhere: 12-36 rows) — AND THE PERSIAN GULF IS REACHED:
 *  pg's ONE team category IS "Goals per match" (the 237/240/241/242
 *  cards documented it as the reason pg had no team surface) → pg renders
 *  its FIRST-EVER team block (18 rows, Persepolis 1.8 / Sepahan 1.7 /
 *  Tractor 1.3, teamId 101610/101611/176352); mas's first feed category
 *  serves too (12 rows, Johor Darul Ta'zim 4.7 — mas's THIRD
 *  team-surface after 240/245). Decimal 1-fraction values (4.0 / 2.9 /
 *  1.8 probed) → the 241 toFixed(1) dir=ltr convention verbatim (no
 *  appended sign; 4.0 renders «۴.۰») — storage never rounds. Upstream
 *  Rank keeps COMPETITION ties verbatim (the 2020/21 2,2 Atletico+Real
 *  Madrid tie probed); the merge re-ranks POSITIONALLY. ParticiantId is
 *  ALWAYS 0 (teams carry TeamId) → dedup by TeamId. NO badge twin and NO
 *  global-merge participation BY DESIGN (the 237 team-surface rule); the
 *  block rides the league page only, rows link /team/{teamId} (the
 *  standings-view contract), data-testid=tgm-row, the scoring-rate glyph,
 *  sublabel «قدرت حمله — سطح تیم». SEASON-AWARE (the 124/…/245 class):
 *  the 2020/21 laliga raw serves its OWN file — season/15585, 20 rows,
 *  Barcelona 2.2 rank-1 with the 1.8 Atletico+Real Madrid tie — frozen,
 *  the 202 anchor pattern, DISTINCT from the current 4.0. The honest-name
 *  contract rides the EXISTING teamFa map (probed: Persepolis/Sepahan/
 *  Tractor/Johor all covered). Feeds without the team category degrade
 *  honestly to []. */
export interface TeamGoalsPerMatchEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamGoalsPerMatch: number;  // StatValue VERBATIM — 1-decimal float (4.0), the 241 toFixed(1) convention, never rounded
}

/** cycle-247 additive: one «کرنرهای تیم‌ها» row — the deep-file family's
 *  TWENTY-FIFTH sibling and its SEVENTH TEAM-PARTICIPANT member: the
 *  team-side corner volume (the raw set-piece attack surface). Straight
 *  from the live corner_taken_team.json probe (UA Chrome/124,
 *  2026-10-31, scripts/cycle247-probe.sh + probe2.sh): EIGHT leagues
 *  serve it (the seven feed leagues + uel 73 — files WIDE 18-36 rows
 *  everywhere: laliga 20 Villarreal 73 / pl 20 Tottenham 52 / seriea 20
 *  Juventus 69 / bundesliga 18 Bayern 64 / ligue1 18 Lens 52 / ucl 36
 *  Dortmund 27 / uel 36 Olympiacos 28 / portugal 18 Benfica 65), so the
 *  STANDARD <10 guard needs no league-aware floor; persiangulf AND mas
 *  honestly absent TWICE OVER (not in feed AND the bare direct files
 *  data.fotmob.com/stats/{523,8985}/corner_taken_team.json both
 *  ABSENT — the 241 honesty, stronger than the 245 bare-serves class).
 *  Integer-valued floats → the 215/220/231/235/236/242/245 integer
 *  convention: storage never rounds, the pill renders String(value)
 *  dir=ltr (73 renders «۷۳»; the frozen 2020/21 file's 224 renders
 *  «۲۲۴»). Upstream Rank keeps COMPETITION ties verbatim (laliga
 *  (8,8)/(13,13)/(17,17), ucl's dense (7,6)+(8,6)+(20,19)+(21,19)
 *  ladder probed); the merge re-ranks POSITIONALLY with the name
 *  tiebreak. ParticiantId is ALWAYS 0 (teams carry TeamId, probed
 *  Villarreal 10205 / Olympiacos 8638) → dedup by TeamId. NO badge
 *  twin and NO global-merge participation BY DESIGN (the 237
 *  team-surface rule); the block rides the league page only, rows link
 *  /team/{teamId} (the standings-view contract), data-testid=tcor-row,
 *  the corner-flag glyph, sublabel «حجم حملات — سطح تیم».
 *  SEASON-AWARE (the 124/…/246 class): the 2020/21 laliga raw serves
 *  its OWN file — season/15585, 20 rows, Real Madrid 224 rank-1 with
 *  the 196 Atletico+Real Sociedad tie — frozen, DISTINCT from the
 *  current 73 (probed via the NAME-form season feed, the exact call
 *  getLeagueRaw makes; the numeric-form season=15585 feed provably
 *  leaks the CURRENT fetchAllUrls — documented in the probe). The
 *  honest-name contract rides the EXISTING teamFa map for every
 *  CURRENT top-10 (70/70 probed, zero new entries) — ONE new entry
 *  for the frozen file's rank-3 «Eibar» → «ایبار» (the first
 *  uncovered name in the family's frozen rows; the current-season
 *  surfaces stay zero-new-entry). Feeds without the "Corners" team
 *  category degrade honestly to []. */
export interface TeamCornerEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamCorners: number;  // StatValue VERBATIM — integer-valued float, the 215/…/245 convention, never rounded
}


/** cycle-227 additive: one «گل در هر ۹۰» row — the deep-file family's
 *  THIRTEENTH sibling and the production-RATE surface (goals 23 / assists
 *  175 / cards 50+185 / rating 210 / clean sheets 215 / G+A 216 / goals
 *  prevented 217 / minutes 220 / save percentage 221 / saves per 90 222 /
 *  penalty saves 225 / expected goals 226 → goals per 90 227). The "Goals
 *  per 90" category carries its own fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/goals_per_90.json (live-probed 2026-10-30, UA
 *  Chrome/124: serving on 23 of the 24 leagues.ts entries — EVERY league
 *  but mas, whose feed carries only two player categories — with WIDE
 *  files: laliga 139 rows Raphinha 1.77 / Gabriel Jesus 1.36, ucl 128
 *  Haaland 2.0, championship 196; PERSIANGULF SERVES — 93 rows, the first
 *  deep sibling besides minutes to reach the Persian Gulf). Decimal values
 *  kept VERBATIM — the family's SIXTH non-integer member (the
 *  210/217/221/222/226 convention); upstream precision is UP TO two
 *  decimals (probed max 2 on every serving league; the 2.6/2.0 JS-number
 *  corners exist beside 1.77) so the pill renders toFixed(2) — the 217
 *  display rule, storage never rounds. The file's SubStatValue is the
 *  TOTAL goals (Raphinha 13.0; Messi 30.0 in the 2020/21 file) and rides
 *  along unused — one stat per row, the family contract. SEASON-AWARE
 *  (the 124/175/185/226 class, NOT the 132 one): historical raws carry
 *  their OWN file (the 2020/21 laliga raw serves season/15585, 224 rows,
 *  Lionel Messi 0.89 / Gerard Moreno 0.77 — frozen, the 202 anchor
 *  pattern). Upstream Rank COMPETITION tie-ranked on some files
 *  (persiangulf 1,1,3 / pl 1,2,3,4,4 — probed) — the merge re-ranks
 *  POSITIONALLY like every sibling. */
export interface GoalsPer90Entry {
  rank: number;
  name: string;
  /** honest Persian name (playerFa) — raw English fallback, same rule as the siblings. */
  nameFa?: string;
  team: string;
  teamId: number;
  goalsPer90: number;  // StatValue VERBATIM — per-90 decimal (1.77), the 210/217/226 convention, never rounded
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
  /** cycle-210 additive: «آقای امتیاز» — the league's own FotMob-rating
   *  kings, the deep-file family's next sibling (goals 23 / assists 175 /
   *  cards 50+185 → rating 210). The "FotMob rating" category carries its
   *  own fetchAllUrl → data.fotmob.com stats/{id}/season/{sid}/rating.json
   *  (live-probed 2026-10-30, UA Chrome/124: laliga = 331 ranked rows vs
   *  the 3-row category fallback; 2023/2024 raw serves its OWN file,
   *  season/21053, 311 rows, Bellingham 8.12 rank-1 — finished-season
   *  frozen, the 202 anchor pattern). Decimal values kept VERBATIM — the
   *  only non-integer family member (the value pill renders the decimal
   *  dot, dir=ltr). Always present (possibly []) like assists; feeds
   *  without the category degrade honestly to []. */
  ratings: RatingEntry[];
  /** cycle-215 additive: «گل نخرده‌ها» — the league's own clean-sheet kings,
   *  the deep-file family's next sibling (goals 23 / assists 175 / cards
   *  50+185 / rating 210 → clean sheets 215). The "Clean sheets" category
   *  carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/clean_sheet.json (live-probed 2026-10-30,
   *  UA Chrome/124: laliga season/38843 = 19 ranked rows, Unai Simón 6 —
   *  the FULL file: goalkeepers are a short population by nature; the
   *  2025/26 raw serves its OWN file, season/27233, 28 rows, Joan García
   *  15 — finished-season frozen, the 202 anchor pattern). Integer values
   *  (StatValue 6.0 → 6, the goals/assists convention). Always present
   *  (possibly []) like ratings; feeds without the category degrade
   *  honestly to []. The FIRST goalkeeper surface of the portal — keepers
   *  were invisible on every leaderboard before this field. */
  cleanSheets: CleanSheetEntry[];
  /** cycle-216 additive: «گل+پاس» — the league's own combined-participation
   *  kings, the deep-file family's sixth sibling (goals 23 / assists 175 /
   *  cards 50+185 / rating 210 / clean sheets 215 → G+A 216). The "Goals +
   *  Assists" category carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/_goals_and_goal_assist.json (live-probed
   *  2026-10-30, UA Chrome/124: laliga season/38843 = 213 ranked rows,
   *  Raphinha 16, Yamal 14, Mbappé 13; pl season/36781 = 186 rows, Haaland
   *  9; the 2025/26 raw serves its OWN file, season/27233, 371 rows,
   *  Mbappé 30 — finished-season frozen, the 202 anchor pattern). The
   *  upstream's OWN combined order — a genuinely different leaderboard
   *  than the goals one (the ScorerBadges gPlusA badge on the scorer hero
   *  is a per-scorer decoration, not this ranking). Integer values. Always
   *  present (possibly []) like the siblings; feeds without the category
   *  degrade honestly to []. */
  gPlusA: GPlusAEntry[];
  /** cycle-217 additive: «گل‌های پیشگیری‌شده» — the league's own
   *  goals-prevented kings, the deep-file family's SEVENTH sibling (goals
   *  23 / assists 175 / cards 50+185 / rating 210 / clean sheets 215 / G+A
   *  216 → goals prevented 217) and the FIRST SIGNED one. The "Goals
   *  prevented" category carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/_goals_prevented.json (live-probed
   *  2026-10-30, UA Chrome/124: laliga season/38843 = 21 ranked rows,
   *  Álvaro Vallés 8.2, Unai Simón 2.8, Ionuț Radu 2.7 — and NEGATIVES at
   *  the tail, David Soria −2.4; pl season/36781 = 21 rows, Bart
   *  Verbruggen 3.3; the 2025/26 raw serves its OWN file, season/27233,
   *  20 rows, Joan García 10.3 — finished-season frozen, the 202 anchor
   *  pattern). Decimal values kept VERBATIM — the second non-integer
   *  family member after ratings (the value pill renders the decimal dot
   *  AND the minus sign, dir=ltr). Always present (possibly []) like the
   *  siblings; feeds without the category degrade honestly to []
   *  (live-probed: persiangulf has no "Goals prevented" category — the
   *  section simply hides there). */
  goalsPrevented: GoalsPreventedEntry[];
  /** cycle-220 additive: «بیشترین دقایق» — the league's own minutes-played
   *  kings, the deep-file family's EIGHTH sibling (goals 23 / assists 175 /
   *  cards 50+185 / rating 210 / clean sheets 215 / G+A 216 / goals
   *  prevented 217 → minutes played 220) and the first surface about pure
   *  PRESENCE rather than production or keeping. The "Minutes played"
   *  category carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/mins_played.json (live-probed 2026-10-30, UA
   *  Chrome/124: laliga current season/38843 = 482 rows — the family's
   *  widest file; the 2025/26 raw serves its OWN file, season/27233, 600
   *  rows, Antonio Sivera / David Soria / Ionuț Radu 3420 = 38×90 — the
   *  frozen full-season anchor, the 202 pattern). Integer values (rounded
   *  once at build — the 215/216 convention); rank POSITIONAL (the merge's
   *  own i+1, the family contract — the file's competition tie-ranks 1,1,1,
   *  4,4,4… are honest upstream data but the served top-10 re-ranks like
   *  every sibling). Always present (possibly []) like the siblings; feeds
   *  without the category degrade honestly to []. */
  minutes: MinutesEntry[];
  /** cycle-221 additive: «درصد سیو» — the league's own save-percentage
   *  kings, the deep-file family's NINTH sibling (goals 23 / assists 175 /
   *  cards 50+185 / rating 210 / clean sheets 215 / G+A 216 / goals
   *  prevented 217 / minutes played 220 → save percentage 221) and the
   *  THIRD keeper surface after clean sheets and goals prevented. The
   *  "Save percentage" category carries its own fetchAllUrl →
   *  data.fotmob.com stats/{id}/season/{sid}/_save_percentage.json
   *  (live-probed 2026-10-30, UA Chrome/124: serving on SIX of the seven
   *  leagues — laliga season/38843 = 21 rows, Ionuț Radu 82.5 / Thibaut
   *  Courtois 76.3 / Jan Oblak 75.8; the 2025/26 raw serves its OWN file,
   *  20 rows, Joan García 77.9 / David Soria 75.6 / Aarón Escandell 72.5 —
   *  finished-season frozen, the 202 anchor pattern). Percent values with
   *  one decimal kept VERBATIM (StatFormat "percent" — the third
   *  non-integer member after ratings 210 and goals prevented 217); rank
   *  POSITIONAL (the merge's own i+1 — ucl's file carries competition
   *  tie-ranks 1,2,3,3,5,6, the domestics sequential; the served top-10
   *  re-ranks like every sibling). Always present (possibly []) like the
   *  siblings; feeds without the category degrade honestly to []
   *  (live-probed: persiangulf carries no keeper category at all — the
   *  section simply hides there). */
  savePercentage: SavePercentageEntry[];
  /** cycle-222 additive: «سیو در هر ۹۰» — the league's own saves-per-90
   *  kings, the deep-file family's TENTH sibling (goals 23 / assists 175 /
   *  cards 50+185 / rating 210 / clean sheets 215 / G+A 216 / goals
   *  prevented 217 / minutes 220 / save percentage 221 → saves per 90 222)
   *  and the FOURTH keeper surface. The "Saves per 90" category carries its
   *  own fetchAllUrl → data.fotmob.com stats/{id}/season/{sid}/saves.json
   *  (live-probed 2026-10-30, UA Chrome/124: serving on SIX of the seven
   *  leagues — ucl 43 / pl 21 / laliga 21 / seriea 21 / bundesliga 20 /
   *  ligue1 18 rows; persiangulf honestly absent — no keeper category at
   *  all; the 2025/26 finished raw serves its OWN file, 20 rows, Aarón
   *  Escandell 4.1 / Marko Dmitrović 3.6 / Mathew Ryan 3.5 — the frozen
   *  202 anchor pattern). Per-90 decimal values with one decimal kept
   *  VERBATIM (the fourth non-integer member after ratings 210, goals
   *  prevented 217 and save percentage 221; the file's SubStatValue carries
   *  the TOTAL saves but one stat per row serves — the family contract);
   *  rank POSITIONAL (the merge's own i+1 — ucl's file carries competition
   *  tie-ranks 1,1,3,4,5,5,7,8,8,10, the domestics sequential; the served
   *  top-10 re-ranks like every sibling). Always present (possibly []) like
   *  the siblings; feeds without the category degrade honestly to [] (the
   *  section simply hides there). NOTE: the family's other live candidate
   *  penalty_save.json came alive the same day but its files are THIN
   *  (2-5 rows — a new class below the healthy threshold) — logged as the
   *  next update's candidate, needs its own guard decision. */
  savesPer90: SavesPer90Entry[];
  /** cycle-225 additive: «پنالتی‌های مهارشده» — the deep-file family's
   *  ELEVENTH sibling and the FIFTH keeper surface (clean sheets 215 / goals
   *  prevented 217 / save percentage 221 / saves per 90 222 → penalty saves
   *  225). The "Penalty saves" category carries its own fetchAllUrl →
   *  data.fotmob.com stats/{id}/season/{sid}/penalty_save.json (live-probed
   *  2026-10-30, UA Chrome/124: serving on SIX of the seven leagues — ucl 2
   *  / pl 2 / laliga 5 / seriea 5 / bundesliga 4 / ligue1 3 rows;
   *  persiangulf honestly absent — no keeper category at all). The files
   *  are NATURALLY THIN (a penalty save is rare — the whole league's worth
   *  fits in a handful of rows), so this sibling carries NO thin-TTL
   *  re-probe guard anywhere (the cycle-176 red-cards precedent — a <10
   *  guard would re-probe forever); the loader's own rule is ≥1 row =
   *  healthy. CURRENT-SEASON ONLY (the 132 class — the 2020/21, 2023/24
   *  and 2025/26 finished raws lack the category, probed): historical
   *  views honestly hide the section. Integer values (StatValue 1.0 → 1,
   *  the 215/216 convention). Always present (possibly []) like the
   *  siblings; feeds without the category degrade honestly to [] (the
   *  section simply hides there). */
  penaltySaves: PenaltySavesEntry[];
  /** cycle-225 internal: the dropped-fetch marker for the penalty-saves block
   *  — true ONLY when the raw carries the "Penalty saves" category (the data
   *  genuinely exists upstream) but the penalty_save.json fetch failed after
   *  the loader's retries (the cold-build race class, the 210/222
   *  incidents). The standings TTL reader re-probes the payload in 90s when
   *  set, so a dropped fetch cannot bake the short category fallback for a
   *  full generation. NATURAL thinness (2-5 rows, probed) never sets it —
   *  no UI/API consumer ever reads it (the 108 rule). */
  penaltySavesDropped?: boolean;
  /** cycle-226 additive: «گل مورد انتظار» — the deep-file family's TWELFTH
   *  sibling and the first pure-ANALYTICS surface (→ expected goals 226).
   *  The "Expected goals (xG)" category carries its own fetchAllUrl →
   *  data.fotmob.com stats/{id}/season/{sid}/expected_goals.json
   *  (live-probed 2026-10-30, UA Chrome/124: serving on SIX of the seven
   *  leagues — laliga 389 rows Mbappé 12.2 / Raphinha 9.2 / Yamal 7.0, ucl
   *  479 rows Guirassy 4.2; persiangulf honestly absent — no xG category).
   *  Decimal values kept VERBATIM (the fifth non-integer member — the
   *  210/217/221/222 convention; upstream precision EXACTLY one decimal,
   *  probed). SEASON-AWARE (the 124/175/185 class): historical raws serve
   *  their OWN files (2020/21 laliga = 471 rows, Messi 23.9 — frozen, the
   *  202 anchor pattern). Wide healthy files → the STANDARD thin guard
   *  (the 210 class) applies; always present (possibly []) like the
   *  siblings; feeds without the category degrade honestly to []. */
  xg: XgEntry[];
  /** cycle-227 additive: «گل در هر ۹۰» — the deep-file family's THIRTEENTH
   *  sibling and the production-RATE surface (→ goals per 90 227). The
   *  "Goals per 90" category carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/goals_per_90.json (live-probed 2026-10-30, UA
   *  Chrome/124: serving on 23 of the 24 leagues.ts entries — every league
   *  but mas — with WIDE files; PERSIANGULF SERVES, 93 rows — the first
   *  deep sibling besides minutes to reach the Persian Gulf). Decimal
   *  values kept VERBATIM (the sixth non-integer member — the
   *  210/217/221/222/226 convention; upstream precision UP TO two decimals,
   *  probed). SEASON-AWARE (the 124/175/185/226 class): historical raws
   *  serve their OWN files (2020/21 laliga = 224 rows, Messi 0.89 —
   *  frozen, the 202 anchor pattern). Wide healthy files → the STANDARD
   *  thin guard (the 210 class) applies; always present (possibly []) like
   *  the siblings; feeds without the category degrade honestly to []. */
  goalsPer90: GoalsPer90Entry[];
  /** cycle-230 additive: «پاس مورد انتظار» — the deep-file family's
   *  FOURTEENTH sibling and the assist-side ANALYTICS twin of the xg
   *  surface (→ expected assist 230). The "Expected assist (xA)" category
   *  carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/expected_assists.json (live-probed 2026-10-30,
   *  UA Chrome/124: serving on SIX of the seven globalMerge leagues — ucl
   *  721 Kimmich 1.9 / pl 448 Iwobi 2.6 / laliga 480 Yamal 4.0 / seriea 487
   *  Dybala 3.4 / bundesliga 399 Olise 4.1 / ligue1 422 Thauvin 3.8 rows;
   *  persiangulf honestly absent — no xA category; mas absent).
   *  Decimal values kept VERBATIM (the SEVENTH non-integer member — the
   *  210/217/221/222/226/227 convention; upstream precision EXACTLY one
   *  decimal, probed) so the pill renders toFixed(1). SEASON-AWARE (the
   *  124/175/185/226/227 class): historical raws serve their OWN files
   *  (2020/21 laliga = 565 rows, Messi 13.4 — frozen, the 202 anchor
   *  pattern). Wide healthy files → the STANDARD thin guard (the 210
   *  class) applies; always present (possibly []) like the siblings; feeds
   *  without the category degrade honestly to []. */
  xa: XaEntry[];
  /** cycle-231 additive: «سانس بزرگ خلق‌شده» — the deep-file family's
   *  FIFTEENTH sibling and the production-CREATION volume surface beside
   *  the analytics twins (→ big chances created 231). The "Big chances
   *  created" category carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/big_chances_created.json (live-probed
   *  2026-10-30, UA Chrome/124: serving on 22 of the 24 leagues.ts
   *  entries — every league but persiangulf AND mas, the gp90 footprint —
   *  six domestics with WIDE files: ucl 190 / pl 152 / laliga 185 /
   *  seriea 202 / bundesliga 160 / ligue1 157 rows). INTEGER-VALUED
   *  floats (probed nonint=0) → the 215/216/220 integer convention:
   *  rounded once at build, the pill renders Persian digits WITHOUT
   *  dir=ltr. SEASON-AWARE (the 124/175/185/226/227/230 class):
   *  historical raws serve their OWN files (2020/21 laliga = 309 rows,
   *  Messi 22.0 — frozen, the 202 anchor pattern). Wide healthy files →
   *  the STANDARD thin guard (the 210 class) applies; always present
   *  (possibly []) like the siblings; feeds without the category degrade
   *  honestly to []. */
  bigChancesCreated: BigChancesCreatedEntry[];
  /** cycle-232 additive: «گل مورد انتظار روی دروازه» — the deep-file
   *  family's SIXTEENTH sibling and the third ANALYTICS level, the
   *  on-target accuracy twin of the xg surface (→ expected goals on target
   *  232). The "Expected goals on target (xGOT)" category carries its own
   *  fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/expected_goalsontarget.json (live-probed
   *  2026-10-30, UA Chrome/124: serving on SIX of the seven globalMerge
   *  leagues with WIDE files — ucl 305 Tresoldi 4.5 / pl 241 Haaland 8.2 /
   *  laliga 277 Mbappé 12.8 / seriea 286 Malen 6.6 / bundesliga 227
   *  Füllkrug 6.2 / ligue1 227 Lepaul 6.0 rows; persiangulf honestly
   *  absent — 5 player cats, no xGOT; mas absent, null payload). Decimal
   *  values kept VERBATIM (the EIGHTH non-integer member — the
   *  210/217/221/222/226/227/230 convention; upstream precision EXACTLY
   *  one decimal, probed) so the pill renders toFixed(1). SEASON-AWARE
   *  (the 124/175/185/226/227/230/231 class): historical raws serve their
   *  OWN files (2020/21 laliga = 385 rows, Messi 32.8 — frozen, the 202
   *  anchor pattern; 2023/24 pl = 402 rows, Haaland 27.1). Wide healthy
   *  files → the STANDARD thin guard (the 210 class) applies; always
   *  present (possibly []) like the siblings; feeds without the category
   *  degrade honestly to []. */
  xgot: XgotEntry[];
  /** cycle-235 additive: «فرصت‌های خلق‌شده» — the deep-file family's
   *  SEVENTEENTH sibling and the TOTAL-creation VOLUME twin of the BCC
   *  surface (→ chances created 235). The "Chances created" category
   *  carries its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/total_att_assist.json (live-probed
   *  2026-10-30, UA Chrome/124: WIDE on ALL SIX domestic globalMerge
   *  leagues — ucl 466 / pl 323 / laliga 363 / seriea 382 / bundesliga
   *  308 / ligue1 304 rows; persiangulf honestly absent — 5 player cats;
   *  mas absent, empty payload). INTEGER-VALUED floats (probed nonint=0)
   *  → the 215/216/220 integer convention: rounded once at build, pill
   *  Persian digits WITHOUT dir=ltr. SEASON-AWARE (the
   *  124/175/185/226/227/230/231/232 class): historical raws serve their
   *  OWN files (2020/21 laliga = 466 rows, Lionel Messi 77 — frozen, the
   *  202 anchor pattern). Wide healthy files → the STANDARD thin guard
   *  (the 210 class) applies; always present (possibly []) like the
   *  siblings; feeds without the category degrade honestly to []. */
  chancesCreated: ChancesCreatedEntry[];
  /** cycle-236 additive: «سانس بزرگ ازدست‌رفته» — the deep-file family's
   *  EIGHTEENTH sibling and the MISSED-volume twin of the BCC surface (→
   *  big chances missed 236). The "Big chances missed" category carries
   *  its own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/big_chance_missed.json (live-probed
   *  2026-10-30, UA Chrome/124: WIDE on ALL SIX domestic globalMerge
   *  leagues — ucl 140 / pl 135 / laliga 142 / seriea 171 / bundesliga
   *  126 / ligue1 128 rows; persiangulf honestly absent; mas absent,
   *  null payload). INTEGER-VALUED floats (probed nonint=0) → the
   *  215/216/220 integer convention: rounded once at build, pill Persian
   *  digits WITHOUT dir=ltr. SEASON-AWARE (the
   *  124/175/185/226/227/230/231/232/235 class): historical raws serve
   *  their OWN files (2020/21 laliga = 257 rows, Karim Benzema 19 —
   *  frozen, the 202 anchor pattern). Wide healthy files → the STANDARD
   *  thin guard (the 210 class) applies; always present (possibly [])
 *  like the siblings; feeds without the category degrade honestly to []. */
  bigChancesMissed: BigChancesMissedEntry[];
  /** cycle-237 additive: «گل مورد انتظار تیم‌ها» — the deep-file family's
   *  NINETEENTH sibling and its FIRST TEAM-PARTICIPANT member (→ team
   *  expected goals 237). The "Expected goals" TEAM category carries its
   *  own fetchAllUrl → data.fotmob.com
   *  stats/{id}/season/{sid}/expected_goals_team.json (live-probed
   *  2026-10-30, UA Chrome/124: NATURALLY-THIN team files on ALL SIX
   *  domestic globalMerge leagues — laliga 20 / pl 20 / seriea 20 /
   *  bundesliga 18 / ligue1 18 / ucl 36 rows; persiangulf honestly
   *  absent; mas absent). DECIMAL 1-fraction (probed maxdec=1) → the
   *  210/217/226/230/232 VERBATIM-decimal convention: storage never
   *  rounds, pill toFixed(1) dir=ltr. NO badge twin and NO global-merge
   *  participation BY DESIGN (the badge/merge mechanisms key on PLAYER
   *  ids — a team surface has none); the block rides the league page
   *  only, rows link /team/[id]. SEASON-AWARE (the 124/…/236 class):
   *  historical raws serve their OWN files (2020/21 laliga = 20 rows,
   *  Barcelona 74.3 — frozen, the 202 anchor pattern). Team files serve
   *  18-36 rows — above the FULL_LIST_HEALTHY_MIN floor → the STANDARD
   *  thin guard applies; always present (possibly []); feeds without
   *  the team category degrade honestly to []. */
  teamXg: TeamXgEntry[];
  /** cycle-240 additive: «گل نخرده‌های تیم‌ها» rides the mapped payload —
   *  the deep-file family's TWENTIETH sibling and its SECOND
   *  TEAM-PARTICIPANT member (the team-side LEVEL of the keeper clean
   *  sheets 215 — the team twin relationship 237 established). Integer-
   *  valued floats verbatim (the 215/220/231/235/236 convention); the
   *  block rides the league page only, rows link /team/[id]; mas serves
   *  a naturally-thin 8-row file (probed) while persiangulf honestly
   *  degrades to []; always present (possibly []). REQUIRED since the
   *  v27 bump — old v26 rows lack it and would keep the section hidden
   *  for a full TTL generation. */
  teamCleanSheets: TeamCleanSheetEntry[];
  /** cycle-241 additive: «مالکیت توپ تیم‌ها» rides the mapped payload —
   *  the deep-file family's TWENTY-FIRST sibling and its THIRD
   *  TEAM-PARTICIPANT member (the team-side possession surface). Percent
   *  one-decimal values verbatim (the 221 percent convention — toFixed(1)
   *  dir=ltr, no appended sign); the block rides the league page only,
   *  rows link /team/[id]; persiangulf AND mas honestly degrade to []
   *  (the 237 absence pair, probed); always present (possibly []).
   *  REQUIRED since the v28 bump — old v27 rows lack it and would keep
   *  the section hidden for a full TTL generation. */
  teamPossession: TeamPossessionEntry[];
  /** cycle-242 additive: «کارت‌های زرد تیم‌ها» rides the mapped payload —
   *  the deep-file family's TWENTY-SECOND sibling and its FOURTH
   *  TEAM-PARTICIPANT member (the team-side yellow-card surface).
   *  Integer-valued floats verbatim (the 215/220/231/235/236 convention
   *  — String() pill); the block rides the league page only, rows link
   *  /team/[id]; persiangulf AND mas honestly degrade to [] (the
   *  237/241 absence pair, probed); always present (possibly []).
   *  REQUIRED since the v29 bump — old v28 rows lack it and would keep
   *  the section hidden for a full TTL generation. */
  teamYellowCards: TeamYellowCardEntry[];
  /** cycle-245 additive: «کارت‌های قرمز تیم‌ها» rides the mapped payload —
   *  the deep-file family's TWENTY-THIRD sibling and its FIFTH
   *  TEAM-PARTICIPANT member (the team-side red-card surface, the yellow
   *  sibling's red brother). Integer-valued floats verbatim (the
   *  215/…/242 convention — String() pill); the block rides the league
   *  page only, rows link /team/[id]; persiangulf honestly degrades to []
   *  (feed-driven: ONE team category, probed) while MAS SERVES (its feed
   *  carries the "Red cards" TEAM category — the SECOND mas team-surface
   *  after 240, probed); always present (possibly []).
   *  REQUIRED since the v30 bump — old v29 rows lack it and would keep
   *  the section hidden for a full TTL generation. */
  teamRedCards: TeamRedCardEntry[];
  /** cycle-246 additive: «گل به از مسابقهٔ تیم‌ها» rides the mapped
   *  payload — the deep-file family's TWENTY-FOURTH sibling and its
   *  SIXTH TEAM-PARTICIPANT member (the team-side scoring-rate level).
   *  1-decimal values verbatim (the 241 toFixed(1) convention); the
   *  block rides the league page only, rows link /team/[id]; NINE of
   *  NINE leagues serve — pg's FIRST-EVER team surface + mas's third;
   *  always present (possibly []).
   *  REQUIRED since the v31 bump — old v30 rows lack it and would keep
   *  the section hidden for a full TTL generation. */
  teamGoalsPerMatch: TeamGoalsPerMatchEntry[];
  /** cycle-247 additive: «کرنرهای تیم‌ها» — the SEVENTH team-side block.
   *  REQUIRED on the mapped payload (honest [] when the feed lacks the
   *  category), the 242/245/246 additive-shape convention. */
  teamCorners: TeamCornerEntry[];
  /** cycle-176 additive: the league's own yellow/red card leaders — the
   *  cycle-50 pipeline (getLeagueCardLeaders: fetchAllUrl deep files +
   *  cycle-127 thin-TTL + freshCardNames) had exactly ONE consumer (the
   *  global /topscorers merge); the league page never surfaced its own
   *  league's cards. Plucked into the mapped payload current-season only
   *  (cycle-132 rule — the deep files are current-season), absent when the
   *  feed has no card categories or both lists come back empty (the UI
   *  hides the section, the table is untouched). Per-kind honest absence:
   *  mas has no "Yellow cards" category → yellow: [] with red: [8 rows]. */
  cards?: { yellow: LeagueCardEntry[]; red: LeagueCardEntry[] };
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
      // reverted cycle-251: the cycle-250 "halfs.firstHalfStarted = hard
      // evidence of kick-off" clause was WRONG — live re-probe showed every
      // fixture on the day feed carries the stamp (even the 23:30 Tehran
      // late kick-off), so it is the SCHEDULED half-one time, pre-filled,
      // not proof the ball rolled. ORing it in marked 542 not-yet-kicked-off
      // matches as started (fake 0:0 scores on the homepage). The plain
      // upstream flag is restored; statusId/ongoing remain the only live
      // sources (they DID track reality: 2/3/10/6 while we watched).
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

/** cycle-237: pull one TEAM stats category (participant + topThree,
 *  deduped by team id) — the team-side mirror of statCategory. The
 *  declared FotMobLeague stats type carries only `players`, so the
 *  `teams` block rides the same extractLeagueBoards cast (the 92
 *  convention); the nodes carry header + fetchAllUrl + podium rows. */
function statTeamCategory(raw: FotMobLeague, re: RegExp): FMStatTeamRow[] {
  const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
  const cat = teams?.find?.((t) => re.test(t.header || ""));
  if (!cat) return [];
  const out: FMStatTeamRow[] = [];
  if (cat.participant?.name) out.push(cat.participant);
  for (const t of cat.topThree || []) if (t?.name) out.push(t);
  const seen = new Set<number>();
  return out.filter((p) =>
    p.teamId != null && seen.has(p.teamId)
      ? false
      : (p.teamId != null && seen.add(p.teamId), true)
  );
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
    // cycle-196: the 92 catalog covered 6 of the 31 team leaderboards the
    // SAME payload carries — the defensive/expected-goals/set-piece/card
    // families never surfaced (probe 2026-10-30: 8/8 absent from the served
    // boards while the upstream bytes sat in the cached leagueRaw). Same
    // extraction, same chips, zero new fetches; categories a league's feed
    // lacks (or a season's) simply stay hidden (the 92 honest-skip rule).
    "Goals conceded per match": { fa: "گل خورده در هر بازی", sub: "استحکام خط دفاع فصل" },
    "Shots on target per match": { fa: "شوت در چارچوب در هر بازی", sub: "خطرآفرینی پیوسته" },
    "Expected goals": { fa: "گل انتظاری (xG)", sub: "کیفیت موقعیت‌های ساخته‌شده" },
    "xG difference": { fa: "تفاضل گل انتظاری", sub: "عملکرد واقعی در برابر انتظار" },
    Corners: { fa: "کرنر", sub: "بیشترین کرنر فصل" },
    "Set piece goals": { fa: "گل از ضربات ایستگاهی", sub: "کرنر، پنالتی و ضربهٔ آزاد" },
    "Penalties awarded": { fa: "پنالتی گرفته‌شده", sub: "دریافت پنالتی در بازی‌های فصل" },
    "Yellow cards": { fa: "کارت زرد", sub: "بی‌نظمی فصل — سطح تیم" },
  },
  player: {
    "FotMob rating": { fa: "امتیاز فوت‌ماب", sub: "میانگین نمره بازی‌ها" },
    "Top speed": { fa: "بیشترین سرعت", sub: "بر حسب کیلومتر بر ساعت" },
    "Big chances created": { fa: "موقعیت طلایی ساخته", sub: "پاس‌های منجر به موقعیت پنهان" },
    "Successful dribbles per 90": { fa: "دریبل موفق در هر ۹۰ دقیقه", sub: "میانگین دریبل‌های برنده" },
    "Goals prevented": { fa: "گل مهارشده", sub: "دروازه‌بان‌ها؛ منفی = بیش از انتظار گل خورده" },
    "Accurate passes per 90": { fa: "پاس دقیق در هر ۹۰ دقیقه", sub: "میانگین پاس‌های درست" },
    // cycle-196: 6 more of the 46 player leaderboards — the defensive and
    // goalkeeper families (tackles/interceptions، creator volume، xA، GK
    // clean sheets/save percentage) join the curated set; rows keep the
    // /player/{id} link + honest Persian club (probe: id+teamName+teamId
    // on every new block).
    "Tackles per 90": { fa: "تکل در هر ۹۰ دقیقه", sub: "برندگی در تن‌به‌تن" },
    "Interceptions per 90": { fa: "قطع توپ در هر ۹۰ دقیقه", sub: "خواندن مسیر پاس" },
    "Chances created": { fa: "موقعیت ساخته", sub: "پاس‌های منجر به شوت" },
    "Expected assist (xA)": { fa: "پاس منجر انتظاری (xA)", sub: "کیفیت پاس‌های آخر" },
    "Clean sheets": { fa: "کلین‌شیت", sub: "دروازه‌بان‌ها؛ بازی بدون گل خورده" },
    "Save percentage": { fa: "درصد مهار", sub: "دروازه‌بان‌ها؛ سهم شوت‌های مهارشده" },
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
  fetchAllUrl?: string;  // cycle-237: the full-season TEAM stats file (data.fotmob.com, gzip) — probed present on every team category node
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
 * cycle-175: full-season ASSISTS list for one league — the cycle-23 move for
 * playmakers. The "Assists" category rides the SAME league payload as the
 * goals list and carries its own fetchAllUrl → data.fotmob.com
 * stats/{leagueId}/season/{sid}/goal_assist.json (live-probed 2026-10-30, UA
 * Chrome/124: PL = 106 ranked rows vs the 3-4 category entries; gzip-served,
 * fetch decompresses transparently — the exact mechanism goals.json has used
 * since cycle-23). Same cache + cycle-127 thin-TTL guard as the goals file;
 * feeds without fetchAllUrl (mas) degrade to [] and the honest category list
 * stays. Rows map with the honest-name contract: playerFa + teamFa fallbacks.
 */
export async function getFullAssists(leagueKey: string, season?: string): Promise<AssistEntry[]> {
  try {
    return await cached(
      `fullAssists:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^assists$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: AssistEntry[] = [];
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
            assists: Math.round(r.StatValue ?? 0),
            playerId: id,
          });
          if (out.length >= 20) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * cycle-210: full-season FOTMOB-RATING list for one league («آقای امتیاز»)
 * — the deep-file family's next sibling. The "FotMob rating" category rides
 * the SAME league payload as goals/assists/cards and carries its own
 * fetchAllUrl → data.fotmob.com stats/{leagueId}/season/{sid}/rating.json
 * (live-probed 2026-10-30, UA Chrome/124: laliga season/38843 = 331 ranked
 * rows vs the 3-row category fallback, Raphinha 8.6 rank-1; gzip-served,
 * fetch decompresses transparently — the exact mechanism every sibling file
 * has used). The ONLY non-integer family member: StatValue arrives as a
 * decimal (8.6, 8.51…) and is kept VERBATIM — no Math.round, the value pill
 * renders the decimal dot (dir=ltr). Same cache + cycle-127 thin-TTL guard
 * as the sibling files (healthy = wide file; the fallback is ~3 rows);
 * season-aware like every sibling since 124/175/185 (a historical raw
 * carries its own rating file — probed: 2023/2024 → season/21053, 311
 * rows, Bellingham 8.12 rank-1, finished = frozen). Top-10 cap matches the
 * render contract; feeds without fetchAllUrl (mas) degrade to [] and the
 * honest category fallback still feeds the merge.
 */
export async function getFullRatings(leagueKey: string, season?: string): Promise<RatingEntry[]> {
  try {
    return await cached(
      `fullRatings:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^fotmob rating$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: RatingEntry[] = [];
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
            rating: r.StatValue ?? 0,  // decimal kept verbatim — the family's only non-integer
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * cycle-215: full-season CLEAN-SHEET list for one league («گل نخرده‌ها»)
 * — the deep-file family's next sibling and the FIRST goalkeeper surface
 * of the portal (keepers were invisible on every leaderboard before).
 * The "Clean sheets" category rides the SAME league payload as the
 * siblings and carries its own fetchAllUrl → data.fotmob.com
 * stats/{leagueId}/season/{sid}/clean_sheet.json (live-probed 2026-10-30,
 * UA Chrome/124: laliga season/38843 = 19 ranked rows, Unai Simón 6, Ionuț
 * Radu 5, Jan Oblak 5; gzip-served — the exact mechanism every sibling
 * file has used). StatValue arrives as a float (6.0) and is stored ONCE
 * rounded (Math.round → 6): the integer convention of goals/assists/cards,
 * NOT the rating one. Same cache + cycle-127 thin-TTL guard as the
 * siblings (healthy = ≥10 rows — a finished 20-team season is 19-30 rows;
 * the category fallback is ~3); season-aware like every sibling since
 * 124/175/185/210 (a historical raw carries its OWN file — probed:
 * 2025/26 → season/27233, 28 rows, Joan García 15, Courtois 13,
 * David Soria 12 — finished = frozen, the 202 anchor pattern). Top-10 cap matches the
 * render contract; feeds without the category (if any) degrade to [] and
 * the honest category fallback still feeds the merge.
 */
export async function getFullCleanSheets(leagueKey: string, season?: string): Promise<CleanSheetEntry[]> {
  try {
    return await cached(
      `fullCleanSheets:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^clean sheets$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: CleanSheetEntry[] = [];
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
            cleanSheets: Math.round(r.StatValue ?? 0),  // 6.0 → 6 — the integer convention
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * cycle-216: full-season GOALS+ASSISTS list for one league («گل+پاس»)
 * — the deep-file family's sixth sibling, the combined-participation
 * ranking. The "Goals + Assists" category rides the SAME league payload
 * and carries its own fetchAllUrl → data.fotmob.com
 * stats/{leagueId}/season/{sid}/_goals_and_goal_assist.json (live-probed
 * 2026-10-30, UA Chrome/124: laliga season/38843 = 213 ranked rows,
 * Raphinha 16, Yamal 14, Mbappé 13; pl season/36781 = 186 rows, Haaland
 * 9; gzip-served — the exact mechanism every sibling file has used).
 * StatValue arrives as a float (16.0) and is stored ONCE rounded
 * (Math.round → 16): the integer convention. The upstream's OWN combined
 * order — a genuinely different leaderboard than the goals one. Same
 * cache + cycle-127 thin-TTL guard as the siblings (healthy = ≥10 rows —
 * even matchday-9 pl already carries 186; the category fallback is ~3);
 * season-aware like every sibling (a historical raw carries its OWN file
 * — probed: 2025/26 → season/27233, 371 rows, Mbappé 30 — finished =
 * frozen, the 202 anchor pattern). Top-10 cap matches the render
 * contract; feeds without the category degrade to [] and the honest
 * category fallback still feeds the merge.
 */
export async function getFullGPlusA(leagueKey: string, season?: string): Promise<GPlusAEntry[]> {
  try {
    return await cached(
      `fullGPlusA:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^goals \+ assists$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: GPlusAEntry[] = [];
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
            gPlusA: Math.round(r.StatValue ?? 0),  // 16.0 → 16 — the integer convention
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * cycle-217: full-season GOALS PREVENTED list for one league («گل‌های
 * پیشگیری‌شده») — the deep-file family's SEVENTH sibling and the keeper
 * QUALITY surface (the 215 clean-sheet block is the keeper's COUNT). The
 * "Goals prevented" category rides the SAME league payload and carries its
 * own fetchAllUrl → data.fotmob.com
 * stats/{leagueId}/season/{sid}/_goals_prevented.json (live-probed
 * 2026-10-30, UA Chrome/124: laliga season/38843 = 21 ranked rows, Álvaro
 * Vallés 8.2, Unai Simón 2.8, Ionuț Radu 2.7; pl season/36781 = 21 rows,
 * Bart Verbruggen 3.3; gzip-served — the exact mechanism every sibling
 * file has used). StatValue is a SIGNED DECIMAL (8.2 … −2.4 — the family's
 * first negative-capable leaderboard) and is stored VERBATIM: the rating
 * convention, never Math.round. Same cache + cycle-127 thin-TTL guard as
 * the siblings (healthy = ≥10 rows — both probed leagues carry 21; the
 * category fallback is ~3); season-aware like every sibling (a historical
 * raw carries its OWN file — probed: 2025/26 → season/27233, 20 rows,
 * Joan García 10.3 — finished = frozen, the 202 anchor pattern). Top-10
 * cap matches the render contract; feeds without the category degrade to
 * [] (probed: persiangulf has no such category) and the honest category
 * fallback still feeds the merge.
 */
export async function getFullGoalsPrevented(leagueKey: string, season?: string): Promise<GoalsPreventedEntry[]> {
  try {
    return await cached(
      `fullGoalsPrevented:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^goals prevented$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: GoalsPreventedEntry[] = [];
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
            goalsPrevented: r.StatValue ?? 0,  // SIGNED DECIMAL kept verbatim — 8.2 / −2.4, the rating convention (storage never rounds)
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * Full «بیشترین دقایق» leaderboard for one league (cycle-220) — the deep-file
 * family's EIGHTH sibling, first PRESENCE surface. The "Minutes played"
 * category carries its own fetchAllUrl →
 * stats/{id}/season/{sid}/mins_played.json (live-probed 2026-10-30, UA
 * Chrome/124: laliga season/38843 = 482 ranked rows — the family's widest
 * file, every registered player; the finished 2025/26 raw serves its OWN
 * file, season/27233 = 600 rows, Antonio Sivera / David Soria / Ionuț Radu
 * 3420 = 38×90 — frozen, the 202 anchor pattern; note the file name has NO
 * underscore prefix unlike _goals_prevented.json). StatValue is a DECIMAL
 * float (900.0) rounded ONCE — the integer convention (215/216), never the
 * verbatim float one. Upstream Rank is COMPETITION tie-rank here (1,1,1,
 * 4,4,4… — unlike clean_sheet.json's sequential ranks); the merge re-ranks
 * POSITIONALLY like every sibling, so this loader keeps the file's own
 * order and rank verbatim. Same cache + cycle-127 thin-TTL guard as the
 * siblings (healthy = ≥10 rows — the category fallback is ~3); season-aware
 * like every sibling (a historical raw carries its OWN fetchAllUrl).
 * Feeds without the category degrade to [] and the honest category
 * fallback still feeds the merge.
 */
export async function getFullMinutes(leagueKey: string, season?: string): Promise<MinutesEntry[]> {
  try {
    return await cached(
      `fullMinutes:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^minutes played$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: MinutesEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream competition tie-rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            minutes: Math.round(r.StatValue ?? 0),  // integer convention (215/216): 900.0 → 900, rounded once at build
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * Full «درصد سیو» leaderboard for one league (cycle-221) — the deep-file
 * family's NINTH sibling, the THIRD keeper surface. The "Save percentage"
 * category carries its own fetchAllUrl →
 * stats/{id}/season/{sid}/_save_percentage.json (live-probed 2026-10-30,
 * UA Chrome/124: serving on SIX of the seven leagues — ucl 45 / pl 21 /
 * laliga 21 / seriea 21 / bundesliga 20 / ligue1 18 rows; persiangulf has
 * no keeper category at all → honest []; the finished 2025/26 laliga raw
 * serves its OWN file, 20 rows, Joan García 77.9 / David Soria 75.6 /
 * Aarón Escandell 72.5 — frozen, the 202 anchor pattern). The row shape is
 * the FMStatFullRow family with the participant carried FLAT
 * (ParticipantName + ParticiantId — upstream's own typo the type already
 * handles) and StatValue a PERCENT with one decimal (82.5) kept VERBATIM —
 * the rating/gp convention (210/217), never the rounding one. Upstream
 * Rank is sequential on the domestics but COMPETITION tie-ranked on ucl
 * (1,2,3,3,5,6 live-probed); this loader keeps the file's own order and
 * rank verbatim — the merge re-ranks POSITIONALLY like every sibling.
 * Same cache + cycle-127 thin-TTL guard as the siblings (healthy = ≥10
 * rows); season-aware like every sibling (a historical raw carries its OWN
 * fetchAllUrl — the 2020/21 raw serves Oblak 80.5 / Courtois 76.3 / Bounou
 * 74.1). Feeds without the category degrade to [] and the honest category
 * fallback still feeds the merge.
 */
export async function getFullSavePercentage(leagueKey: string, season?: string): Promise<SavePercentageEntry[]> {
  try {
    return await cached(
      `fullSavePercentage:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^save percentage$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: SavePercentageEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            savePercentage: r.StatValue ?? 0,  // percent VERBATIM — the 210/217 convention, never rounded
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * Full «سیو در هر ۹۰» leaderboard for one league (cycle-222) — the deep-file
 * family's TENTH sibling, the FOURTH keeper surface. The "Saves per 90"
 * category carries its own fetchAllUrl →
 * stats/{id}/season/{sid}/saves.json (live-probed 2026-10-30, UA Chrome/124:
 * serving on SIX of the seven leagues — ucl 43 / pl 21 / laliga 21 / seriea
 * 21 / bundesliga 20 / ligue1 18 rows; persiangulf has no keeper category
 * at all → honest []; the finished 2025/26 laliga raw serves its OWN file,
 * 20 rows, Aarón Escandell 4.1 / Marko Dmitrović 3.6 / Mathew Ryan 3.5 —
 * frozen, the 202 anchor pattern). The row shape is the FMStatFullRow
 * family with the participant carried FLAT (ParticipantName + ParticiantId
 * — upstream's own typo the type already handles) and StatValue a PER-90
 * DECIMAL with one decimal (4.3) kept VERBATIM — the 210/217/221
 * convention, never rounded; the file's SubStatValue is the TOTAL saves
 * (43.0) and rides along but the surface serves the per-90 rate only (one
 * stat per row, the family contract). Upstream Rank is sequential on the
 * domestics but COMPETITION tie-ranked on ucl (1,1,3,4,5,5,7,8,8,10
 * live-probed); this loader keeps the file's own order and rank verbatim —
 * the merge re-ranks POSITIONALLY like every sibling. Same cache +
 * cycle-127 thin-TTL guard as the siblings (healthy = ≥10 rows); season-
 * aware like every sibling (a historical raw carries its OWN fetchAllUrl —
 * the 2020/21 raw serves Edgar Badía 3.2 / Jaume Domènech 3.2 / Jordi
 * Masip 3.0). Feeds without the category degrade to [] and the honest
 * category fallback still feeds the merge.
 */
export async function getFullXg(leagueKey: string, season?: string): Promise<XgEntry[]> {
  try {
    return await cached(
      `fullXg:v1:${leagueKey}:${season || "cur"}`,
      // Standard wide-file guard (the 210/222 class): expected_goals.json is
      // a WIDE file (live-probed 2026-10-30: laliga 389 / ucl 479 rows —
      // every outfield player with minutes), so thin means "the fetch was
      // dropped" and re-probes in 90s. Season-aware like every
      // production sibling — a historical raw carries its OWN fetchAllUrl
      // (the 2020/21 laliga raw serves season/15585, 471 rows).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^expected goals \(xg\)$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: XgEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            xg: r.StatValue ?? 0,  // decimal VERBATIM — the 210/217 convention, never rounded
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/** cycle-227 additive: «گل در هر ۹۰» loader — the THIRTEENTH sibling, the
 *  production-rate twin of getFullXg. goals_per_90.json (live-probed
 *  2026-10-30 UA Chrome/124: serving on 23 of the 24 leagues.ts entries —
 *  EVERY league but mas — with WIDE files, laliga 139 rows Raphinha 1.77 /
 *  Gabriel Jesus 1.36, ucl 128 Haaland 2.0, championship 196;
 *  PERSIANGULF SERVES — 93 rows, the first deep sibling besides minutes to
 *  reach the Persian Gulf, with the honest competition tie-rank 1,1,3 at
 *  the top, Erfan Shahriari / Kasra Taheri 1.06). StatValue is a PER-90
 *  DECIMAL kept VERBATIM — the family's SIXTH non-integer member (the
 *  210/217/221/222/226 convention, never rounded); upstream precision is
 *  UP TO two decimals (probed max 2 on every serving league) so the pill
 *  renders toFixed(2). The file's SubStatValue is the TOTAL goals and
 *  rides along but the surface serves the per-90 rate only (one stat per
 *  row, the family contract). Upstream Rank is COMPETITION tie-ranked on
 *  some files (persiangulf 1,1,3 / pl 1,2,3,4,4 — probed); this loader
 *  keeps the file's own order and rank verbatim — the merge re-ranks
 *  POSITIONALLY like every sibling. Same cache + cycle-127 thin-TTL guard
 *  as the siblings (healthy = ≥10 rows — every serving league probed ≥59,
 *  the natural-thinness conflict the 225 penalty-saves class has does not
 *  exist here); season-aware like every sibling (a historical raw carries
 *  its OWN fetchAllUrl — the 2020/21 laliga raw serves season/15585, 224
 *  rows, Messi 0.89 / Moreno 0.77 / Suárez 0.75). Feeds without the
 *  category degrade to [] and the honest category fallback still feeds
 *  the merge.
 */
export async function getFullGoalsPer90(leagueKey: string, season?: string): Promise<GoalsPer90Entry[]> {
  try {
    return await cached(
      `fullGoalsPer90:v1:${leagueKey}:${season || "cur"}`,
      // Standard wide-file guard (the 210/222/226 class): goals_per_90.json
      // is a WIDE file (live-probed 2026-10-30: 59-240 rows across the 23
      // serving leagues — every outfield player with minutes), so thin
      // means "the fetch was dropped" and re-probes in 90s. Season-aware
      // like every production sibling — a historical raw carries its OWN
      // fetchAllUrl (the 2020/21 laliga raw serves season/15585, 224 rows).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^goals per 90$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: GoalsPer90Entry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            goalsPer90: r.StatValue ?? 0,  // decimal VERBATIM — the 210/217/226 convention, never rounded
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/** cycle-230 additive: «پاس مورد انتظار» loader — the FOURTEENTH sibling,
 *  the assist-side analytics twin of getFullXg. expected_assists.json
 *  (live-probed 2026-10-30 UA Chrome/124: serving on SIX of the seven
 *  globalMerge leagues with WIDE files — ucl 721 Kimmich 1.9 / Yamal 1.8 /
 *  Ødegaard 1.8, pl 448 Iwobi 2.6 / Gibbs-White 2.0, laliga 480 Yamal 4.0,
 *  seriea 487 Dybala 3.4, bundesliga 399 Olise 4.1, ligue1 422 Thauvin
 *  3.8; persiangulf honestly absent — no xA category, 5 player cats; mas
 *  absent, 2 cats; 12 of the other 16 leagues.ts entries serve it too).
 *  StatValue is a DECIMAL kept VERBATIM — the family's SEVENTH non-integer
 *  member (the 210/217/221/222/226/227 convention, never rounded); upstream
 *  precision is EXACTLY one decimal (probed maxdec=1 on every serving
 *  file) so the pill renders toFixed(1). Upstream Rank is COMPETITION
 *  tie-ranked on several files (ucl 1..10,10,10 / pl 1..6,6,8 / seriea
 *  1..5,5,7 — probed); this loader keeps the file's own order and rank
 *  verbatim — the merge re-ranks POSITIONALLY like every sibling. Same
 *  cache + cycle-127 thin-TTL guard as the siblings (healthy = ≥10 rows —
 *  every serving league probed ≥152, no natural-thinness class); season-
 *  aware like every sibling (a historical raw carries its OWN fetchAllUrl
 *  — the 2020/21 laliga raw serves 565 rows, Messi 13.4 / Jordi Alba 9.9 /
 *  Jesús Navas 8.0, frozen; 2023/24 pl = Ødegaard 11.2; 2022/23 laliga =
 *  Griezmann 9.8). Feeds without the category degrade to [] and the
 *  honest category fallback still feeds the merge.
 */
export async function getFullXa(leagueKey: string, season?: string): Promise<XaEntry[]> {
  try {
    return await cached(
      `fullXa:v1:${leagueKey}:${season || "cur"}`,
      // Standard wide-file guard (the 210/222/226/227 class):
      // expected_assists.json is a WIDE file (live-probed 2026-10-30:
      // 152-721 rows across the six serving globalMerge leagues — every
      // outfield player with minutes), so thin means "the fetch was
      // dropped" and re-probes in 90s. Season-aware like every production
      // sibling — a historical raw carries its OWN fetchAllUrl (the 2020/21
      // laliga raw serves 565 rows, Messi 13.4).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        // the header is SINGULAR upstream — "Expected assist (xA)" (probed
        // verbatim off the laliga category list; the plural probe
        // 0-matched every league before the fix)
        const cat = raw.stats?.players?.find?.((p) => /^expected assist \(xa\)$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: XaEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            xa: r.StatValue ?? 0,  // decimal VERBATIM — the 210/217/226 convention, never rounded
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/** cycle-231 additive: «سانس بزرگ خلق‌شده» loader — the FIFTEENTH sibling,
 *  the production-CREATION volume surface beside the analytics twins
 *  (getFullXg 226 / getFullXa 230). big_chances_created.json (live-probed
 *  2026-10-30 UA Chrome/124: serving on 22 of the 24 leagues.ts entries —
 *  every league but persiangulf (5 player cats) and mas (2 cats), the
 *  gp90 footprint — six domestics with WIDE files: ucl 190 Yamal 5 / pl
 *  152 Groß 7 / laliga 185 Yamal 14 / seriea 202 Dybala 8 / bundesliga
 *  160 Nusa+Kane 6 / ligue1 157 Thauvin 9; historical raws serve their
 *  OWN files — 2020/21 laliga 309 rows Messi 22.0, 2023/24 pl 325 Salah
 *  22.0, 2022/23 laliga 339 Griezmann 24.0). StatValue is an
 *  INTEGER-VALUED float (probed nonint=0 on every serving file) → the
 *  215/216/220 integer convention: rounded ONCE at build, never re-rounded
 *  downstream; the pill renders Persian digits WITHOUT dir=ltr (the
 *  minutes contract). Upstream Rank is COMPETITION tie-ranked on several
 *  files (bundesliga 1,1,3 / ucl 1,2,3,4,4,4,7,7,7,7 — probed); this
 *  loader keeps the file's own order and rank verbatim — the merge
 *  re-ranks POSITIONALLY like every sibling. Same cache + cycle-127
 *  thin-TTL guard as the siblings (healthy = ≥10 rows — every serving
 *  league probed ≥89, no natural-thinness class); season-aware like every
 *  sibling. Feeds without the category degrade to [] and the honest
 *  category fallback still feeds the merge.
 */
export async function getFullBigChances(leagueKey: string, season?: string): Promise<BigChancesCreatedEntry[]> {
  try {
    return await cached(
      `fullBigChances:v1:${leagueKey}:${season || "cur"}`,
      // Standard wide-file guard (the 210/222/226/227/230 class):
      // big_chances_created.json is a WIDE file (live-probed 2026-10-30:
      // 89-339 rows across the 22 serving leagues), so thin means "the
      // fetch was dropped" and re-probes in 90s. Season-aware like every
      // production sibling — a historical raw carries its OWN fetchAllUrl
      // (the 2020/21 laliga raw serves 309 rows, Messi 22.0).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^big chances created$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: BigChancesCreatedEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            bigChances: Math.round(r.StatValue ?? 0),  // integer convention (the 215/220 class) — upstream is integer-valued, probed nonint=0
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/** cycle-232 additive: «گل مورد انتظار روی دروازه» loader — the SIXTEENTH
 *  sibling, the third ANALYTICS level and the on-target accuracy twin of
 *  getFullXg. expected_goalsontarget.json (live-probed 2026-10-30 UA
 *  Chrome/124: serving on SIX of the seven globalMerge leagues with WIDE
 *  files — ucl 305 Tresoldi 4.5 / pl 241 Haaland 8.2 / laliga 277 Mbappé
 *  12.8 / seriea 286 Malen 6.6 / bundesliga 227 Füllkrug 6.2 / ligue1 227
 *  Lepaul 6.0 rows; persiangulf honestly absent — 5 player cats, no xGOT;
 *  mas absent, null payload; 12 of the other 16 leagues.ts entries serve
 *  it too). StatValue is a DECIMAL kept VERBATIM — the family's EIGHTH
 *  non-integer member (the 210/217/221/222/226/227/230 convention, never
 *  rounded); upstream precision is EXACTLY one decimal (probed
 *  decimal-counts=[1] on every serving file AND the historical raw) so the
 *  pill renders toFixed(1). Upstream Rank is COMPETITION tie-ranked on
 *  several files (ucl 5,5 / pl 4,4 / seriea 4,4 / ligue1 3,3 — probed);
 *  this loader keeps the file's own order and rank verbatim — the merge
 *  re-ranks POSITIONALLY like every sibling. Same cache + cycle-127
 *  thin-TTL guard as the siblings (healthy = ≥10 rows — every serving
 *  league probed ≥227, no natural-thinness class); season-aware like every
 *  sibling (a historical raw carries its OWN fetchAllUrl — the 2020/21
 *  laliga raw serves 385 rows, Messi 32.8 / Gerard Moreno 24.8 / Luis
 *  Suárez 20.2, frozen; 2023/24 pl = 402 rows, Haaland 27.1 / Isak 22.8 /
 *  Palmer 20.0). Feeds without the category degrade to [] and the honest
 *  category fallback still feeds the merge.
 */
export async function getFullXgot(leagueKey: string, season?: string): Promise<XgotEntry[]> {
  try {
    return await cached(
      `fullXgot:v1:${leagueKey}:${season || "cur"}`,
      // Standard wide-file guard (the 210/222/226/227/230/231 class):
      // expected_goalsontarget.json is a WIDE file (live-probed 2026-10-30:
      // 227-305 rows across the six serving globalMerge leagues — every
      // outfield player with a shot on target), so thin means "the fetch
      // was dropped" and re-probes in 90s. Season-aware like every
      // production sibling — a historical raw carries its OWN fetchAllUrl
      // (the 2020/21 laliga raw serves 385 rows, Messi 32.8).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^expected goals on target \(xgot\)$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: XgotEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            xgot: r.StatValue ?? 0,  // decimal VERBATIM — the 210/217/226/230 convention, never rounded
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/** cycle-235: the deep-file family's SEVENTEENTH sibling — the TOTAL-creation
 *  VOLUME twin of getFullBigChances. total_att_assist.json (live-probed
 *  2026-10-30 UA Chrome/124: serving on ALL SIX domestic globalMerge
 *  leagues with WIDE files — ucl 466 Thauvin 15 / pl 323 Groß 23 / laliga
 *  363 Arda Güler 33 / seriea 382 Giacomo Calò 34 / bundesliga 308 Olise
 *  25 / ligue1 304 Thauvin 27 rows; persiangulf honestly absent — 5
 *  player cats; mas absent, empty payload). INTEGER-VALUED floats
 *  (live-probed nonint=0 on every serving file, StatDecimals=0) → the
 *  215/216/220 integer convention: rounded ONCE at build, pill Persian
 *  digits WITHOUT dir=ltr. Upstream Rank is COMPETITION tie-ranked on
 *  every file (ucl 10.0 → 4,5,6 / pl 18.0 → 4,4,6 / laliga 21.0 → 6,7,8
 *  — probed); this loader keeps the file's own order and rank verbatim —
 *  the merge re-ranks POSITIONALLY like every sibling. Same cache +
 *  cycle-127 thin-TTL guard as the siblings (healthy = ≥10 rows — every
 *  serving league probed ≥304, no natural-thinness class); season-aware
 *  like every sibling (a historical raw carries its OWN fetchAllUrl —
 *  the 2020/21 laliga raw serves 466 rows, Lionel Messi 77 / David
 *  Ferreiro 73 / Toni Kroos 67, frozen; the 229 curation rides free —
 *  «لیونل مسی» «تونی کروس»). Feeds without the category degrade to []
 *  and the honest category fallback still feeds the merge.
 */
export async function getFullChancesCreated(leagueKey: string, season?: string): Promise<ChancesCreatedEntry[]> {
  try {
    return await cached(
      `fullChancesCreated:v1:${leagueKey}:${season || "cur"}`,
      // Standard wide-file guard (the 210/222/226/227/230/231/232 class):
      // total_att_assist.json is a WIDE file (live-probed 2026-10-30:
      // 304-466 rows across the six serving domestic leagues — every
      // outfield creator), so thin means "the fetch was dropped" and
      // re-probes in 90s. Season-aware like every production sibling — a
      // historical raw carries its OWN fetchAllUrl (the 2020/21 laliga raw
      // serves 466 rows, Messi 77).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^chances created$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: ChancesCreatedEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            chancesCreated: Math.round(r.StatValue ?? 0),  // integer convention (the 215/220 class) — upstream is integer-valued, probed nonint=0
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/** cycle-236: the deep-file family's EIGHTEENTH sibling — the MISSED-volume
 *  twin of getFullBigChances. big_chance_missed.json (live-probed
 *  2026-10-30 UA Chrome/124: serving on ALL SIX domestic globalMerge
 *  leagues with WIDE files — ucl 140 Haaland 6 / pl 135 Thierno Barry 12
 *  / laliga 142 Mbappé 13 / seriea 171 Malen 9 / bundesliga 126
 *  Demirović 8 / ligue1 128 Mafouta 6 rows; persiangulf honestly absent;
 *  mas absent, null payload). INTEGER-VALUED floats (live-probed nonint=0
 *  on every serving file, StatDecimals=0) → the 215/216/220 integer
 *  convention: rounded ONCE at build, pill Persian digits WITHOUT
 *  dir=ltr. Upstream Rank is COMPETITION tie-ranked on every file (pl
 *  6.0 ×4 / laliga 7.0 ×3 — probed); this loader keeps the file's own
 *  order and rank verbatim — the merge re-ranks POSITIONALLY like every
 *  sibling. Same cache + cycle-127 thin-TTL guard as the siblings
 *  (healthy = ≥10 rows — every serving league probed ≥126, no
 *  natural-thinness class); season-aware like every sibling (a historical
 *  raw carries its OWN fetchAllUrl — the 2020/21 laliga raw serves 257
 *  rows, Karim Benzema 19 / Alexander Isak 16 / Rafa Mir 16, frozen; the
 *  229 curation rides free — «کریم بنزما» «رافا میر»). Feeds without the
 *  category degrade to [] and the honest category fallback still feeds
 *  the merge.
 */
export async function getFullBigChancesMissed(leagueKey: string, season?: string): Promise<BigChancesMissedEntry[]> {
  try {
    return await cached(
      `fullBigChancesMissed:v1:${leagueKey}:${season || "cur"}`,
      // Standard wide-file guard (the 210/222/226/227/230/231/232/235
      // class): big_chance_missed.json is a WIDE file (live-probed
      // 2026-10-30: 126-171 rows across the six serving domestic leagues —
      // every outfield finisher), so thin means "the fetch was dropped"
      // and re-probes in 90s. Season-aware like every production sibling —
      // a historical raw carries its OWN fetchAllUrl (the 2020/21 laliga
      // raw serves 257 rows, Benzema 19).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^big chances missed$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: BigChancesMissedEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            bigChancesMissed: Math.round(r.StatValue ?? 0),  // integer convention (the 215/220 class) — upstream is integer-valued, probed nonint=0
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/** cycle-237: the deep-file family's NINETEENTH sibling — the FIRST
 *  TEAM-participant member, the team-side LEVEL of getFullExpectedGoals.
 *  expected_goals_team.json (live-probed 2026-10-30 UA Chrome/124:
 *  serving on ALL SIX domestic globalMerge leagues with NATURALLY-THIN
 *  team files — laliga 20 Barcelona 34.8 / pl 20 Manchester City 16.7 /
 *  seriea 20 Inter 25.5 / bundesliga 18 Bayern 23.8 / ligue1 18 PSG
 *  20.0 / ucl 36 PSG 10.1 rows; uel 36 + portugal 18 probed for
 *  breadth; persiangulf honestly absent — 1 team category; mas absent
 *  — 4 team cats, no xG). DECIMAL 1-fraction (probed nonint 15-32 per
 *  file, maxdec=1 on every serving file) → the 210/217/226/230/232
 *  VERBATIM-decimal convention: storage never rounds, the pill renders
 *  toFixed(1) dir=ltr. The rows' ParticiantId is ALWAYS 0 (teams carry
 *  TeamId) → dedup by TeamId. The honest-name contract rides the
 *  EXISTING teamFa map — zero new PLAYER_NAME_FA entries. Same cache +
 *  guard as the siblings: team files are naturally thin BUT never under
 *  the family floor (probed 18-36 rows), so <10 means "the fetch was
 *  dropped" — the STANDARD guard applies with NO natural-thinness
 *  exemption (the 225 penalty-save class does NOT arise); season-aware
 *  like every sibling (a historical raw carries its OWN fetchAllUrl —
 *  the 2020/21 laliga raw serves 20 rows, Barcelona 74.3 / Real Madrid
 *  62.3 / Real Sociedad 61.9, frozen). Feeds without the team category
 *  degrade to [].
 */
export async function getFullTeamXg(leagueKey: string, season?: string): Promise<TeamXgEntry[]> {
  try {
    return await cached(
      `fullTeamXg:v1:${leagueKey}:${season || "cur"}`,
      // Standard guard (the 210/…/236 class): team files are naturally
      // thin but never under the family floor — live-probed 18-36 rows
      // on every serving league, so thin means "the fetch was dropped"
      // and re-probes in 90s. Honest-empty feeds (no "Expected goals"
      // team category — persiangulf AND mas, probed) degrade to []
      // upstream of the guard. Season-aware like every production
      // sibling — a historical raw carries its OWN fetchAllUrl (the
      // 2020/21 laliga raw serves 20 rows, Barcelona 74.3).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^expected goals$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamXgEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamXg: r.StatValue ?? 0,  // VERBATIM — the 210/217/226/230/232 decimal convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

/** cycle-240: the full-file fetch for the team clean-sheets block — the
 *  exact 237 getFullTeamXg mirror one category over: stats/{id}/season/
 *  {sid}/clean_sheet_team.json (live-probed 2026-10-30, UA Chrome/124 —
 *  "Clean sheets" TEAM category, INTEGER-valued floats, wide files on the
 *  six domestics 14-20 rows, ucl 17, portugal 17 with the three-way
 *  5,5,5 tie; persiangulf honestly absent — its feed carries one team
 *  category, goals_team_match, probed; MAS SERVES a naturally-thin 8-row
 *  file, Johor Darul Ta'zim 6.0 — the first below-the-floor serve in the
 *  family). Same cache + standard guard as the siblings on the domestics;
 *  the mas 8-row file is the file's REAL size, not a dropped fetch — the
 *  guard exemption for mas lives at the standings TTL clause (the 225
 *  health-rule class, the 176 red-cards lesson). Season-aware like every
 *  sibling (the 2020/21 laliga raw serves 20 rows, Atletico Madrid 18.0,
 *  frozen). Feeds without the team category degrade to []. */
export async function getFullTeamCleanSheets(leagueKey: string, season?: string): Promise<TeamCleanSheetEntry[]> {
  try {
    return await cached(
      `fullTeamCleanSheets:v1:${leagueKey}:${season || "cur"}`,
      // Standard guard (the 210/…/237 class) for the WIDE domestics:
      // clean_sheet_team files serve 14-20 rows there — above the family
      // floor, so thin means "the fetch was dropped" and re-probes in 90s.
      // mas's 8-row file is naturally thin (probed) — its exemption is
      // the standings TTL clause, NOT here (a fetch that DROPS mas's file
      // returns [] which caches 90s and re-probes, the honest path).
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^clean sheets$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamCleanSheetEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamCleanSheets: r.StatValue ?? 0,  // VERBATIM — the 215/220/231/235/236 integer convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

/** cycle-241: the full-file fetch for the team possession block — the
 *  exact 240 getFullTeamCleanSheets mirror one category over:
 *  stats/{id}/season/{sid}/possession_percentage_team.json (live-probed
 *  2026-10-30, UA Chrome/124 — "Average possession" TEAM category,
 *  PERCENT 1-fraction values, wide files on the six domestics 18-36
 *  rows, portugal 18; persiangulf AND mas honestly absent — the 237
 *  absence pair, probed: mas's feed carries FOUR team categories and
 *  possession is not one). Same cache + standard guard as the siblings;
 *  the honest-empty pair degrades to [] upstream of the guard — NO
 *  league-aware floor needed this time (unlike the 240 clean-sheet
 *  sibling, mas does not serve this category at all). Season-aware like
 *  every sibling (the 2020/21 laliga raw serves 20 rows, Barcelona 65.8,
 *  frozen). Feeds without the team category degrade to []. */
export async function getFullTeamPossession(leagueKey: string, season?: string): Promise<TeamPossessionEntry[]> {
  try {
    return await cached(
      `fullTeamPossession:v1:${leagueKey}:${season || "cur"}`,
      // Standard guard (the 210/…/240 class): possession files are WIDE
      // (18-36 rows probed) — above the family floor, so thin means "the
      // fetch was dropped" and re-probes in 90s. Honest-empty feeds (no
      // "Average possession" TEAM category — persiangulf AND mas, probed)
      // degrade to [] upstream of the guard and keep the normal TTL.
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^average possession$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamPossessionEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamPossession: r.StatValue ?? 0,  // VERBATIM — the 221 percent convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

/** cycle-242: the full-file fetch for the team yellow-cards block — the
 *  exact 241 getFullTeamPossession mirror one category over:
 *  stats/{id}/season/{sid}/total_yel_card_team.json (live-probed
 *  2026-10-30, UA Chrome/124 — "Yellow cards" TEAM category,
 *  INTEGER-valued floats, wide files on the six domestics 18-36 rows,
 *  portugal 18; persiangulf AND mas honestly absent — the 237/241
 *  absence pair, probed: mas's feed carries FOUR team categories and
 *  yellow is not one). Same cache + standard guard as the siblings; the
 *  honest-empty pair degrades to [] upstream of the guard — NO
 *  league-aware floor needed. Season-aware like every sibling (the
 *  2020/21 laliga raw serves season/15585, 20 rows, Getafe 114.0,
 *  frozen). Feeds without the team category degrade to []. */
export async function getFullTeamYellowCards(leagueKey: string, season?: string): Promise<TeamYellowCardEntry[]> {
  try {
    return await cached(
      `fullTeamYellowCards:v1:${leagueKey}:${season || "cur"}`,
      // Standard guard (the 210/…/241 class): yellow-card TEAM files are
      // WIDE (18-36 rows probed) — above the family floor, so thin means
      // "the fetch was dropped" and re-probes in 90s. Honest-empty feeds
      // (no "Yellow cards" TEAM category — persiangulf AND mas, probed)
      // degrade to [] upstream of the guard and keep the normal TTL.
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^yellow cards$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamYellowCardEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamYellowCards: r.StatValue ?? 0,  // VERBATIM — the 215/220/231/235/236 integer convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

/** cycle-245: the full-file fetch for the team red-cards block — the exact
 *  242 getFullTeamYellowCards mirror one category over, with ONE
 *  deliberate guard difference: red TEAM files are NATURALLY SHORT (probed
 *  2026-10-31, UA Chrome/124: laliga 16 / pl 12 / portugal 13 / mas 11 /
 *  ligue1 9 / bundesliga 7 / ucl 7 / seriea 6 / uel EXACTLY 4 rows) — red
 *  cards are rare and early-season reds legitimately sit under 10, so the
 *  standard <10 guard would re-probe FOREVER on four of the nine serving
 *  files (the exact trap the cycle-176 PLAYER-red comment documented).
 *  Guard = the 240 mas floor-4 class GENERALIZED league-wide: STRUCTURAL,
 *  not a file-size pin — the podium (participant + topThree) can never
 *  exceed 3 rows, so ≥4 PROVES the full file arrived while ≤3 always
 *  re-probes. Honest-empty feed (no "Red cards" TEAM category —
 *  persiangulf only, probed: its feed carries ONE team category; the bare
 *  direct file serves 15 rows but the app is feed-driven — no category →
 *  honest [] upstream of any fetch) degrades to [] and keeps the normal
 *  TTL. MAS SERVES (its feed carries the "Red cards" TEAM category — the
 *  SECOND mas team-surface after the 240 clean-sheets). Season-aware like
 *  every sibling (the 2020/21 laliga raw serves season/15585 — 19 rows,
 *  Deportivo Alaves 8.0, frozen). Feeds without the team category degrade
 *  honestly to []. */
export async function getFullTeamRedCards(leagueKey: string, season?: string): Promise<TeamRedCardEntry[]> {
  try {
    return await cached(
      `fullTeamRedCards:v1:${leagueKey}:${season || "cur"}`,
      // The 240 floor-4 class, league-wide for red: files are naturally
      // short (4-16 rows probed), thin-below-4 means "the fetch was
      // dropped" (or the season literally has ≤3 reds) and re-probes in
      // 90s; healthy files keep the normal TTL.
      (rows) => (rows.length >= 4 ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^red cards$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamRedCardEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamRedCards: r.StatValue ?? 0,  // VERBATIM — the 215/…/242 integer convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

/** cycle-246: the full-file fetch for the team goals-per-match block —
 *  the exact 245 mirror one category over, back to the STANDARD guard:
 *  goals_team_match.json is WIDE on every serving league (probed
 *  2026-10-31, UA Chrome/124: 12-36 rows on all nine — including pg's
 *  18 and mas's 12), so thin means "the fetch was dropped" and re-probes
 *  in 90s. NO league-aware floor needed — the family's first nine-league
 *  surface at the standard <10 guard. Honest-empty feeds (no "Goals per
 *  match" TEAM category) degrade to [] upstream of the guard and keep
 *  the normal TTL. Season-aware like every sibling (the 2020/21 laliga
 *  raw serves season/15585 — 20 rows, Barcelona 2.2, frozen). */
export async function getFullTeamGoalsPerMatch(leagueKey: string, season?: string): Promise<TeamGoalsPerMatchEntry[]> {
  try {
    return await cached(
      `fullTeamGoalsPerMatch:v1:${leagueKey}:${season || "cur"}`,
      // Standard guard (the 210/…/242 class): goals_team_match files are
      // WIDE (12-36 rows probed on all nine serving leagues) — thin
      // means "the fetch was dropped" and re-probes in 90s.
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^goals per match$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamGoalsPerMatchEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamGoalsPerMatch: r.StatValue ?? 0,  // VERBATIM — the 241 1-decimal convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

/** cycle-247: the full-file fetch for the team corners block — the exact
 *  246 mirror one category over, back on the STANDARD guard:
 *  corner_taken_team.json is WIDE on every serving league (probed
 *  2026-10-31, UA Chrome/124: 18-36 rows on all EIGHT — the seven feed
 *  leagues plus uel 73), so thin means "the fetch was dropped" and
 *  re-probes in 90s. NO league-aware floor needed. Honest-empty feeds
 *  (no "Corners" TEAM category — persiangulf AND mas, probed; their
 *  bare direct files are absent too) degrade to [] upstream of the
 *  guard and keep the normal TTL. Integer values → the 215/…/245
 *  convention: StatValue stored VERBATIM (never rounded), the pill
 *  renders String(value). Season-aware like every sibling (the 2020/21
 *  laliga raw serves season/15585 — 20 rows, Real Madrid 224, frozen,
 *  DISTINCT from the current 73). */
export async function getFullTeamCorners(leagueKey: string, season?: string): Promise<TeamCornerEntry[]> {
  try {
    return await cached(
      `fullTeamCorners:v1:${leagueKey}:${season || "cur"}`,
      // Standard guard (the 210/…/246 class): corner files are WIDE
      // (18-36 rows probed on all eight serving leagues) — thin means
      // "the fetch was dropped" and re-probes in 90s.
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^corners$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamCornerEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamCorners: r.StatValue ?? 0,  // VERBATIM — the 215/…/245 integer convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

export async function getFullPenaltySaves(leagueKey: string, season?: string): Promise<PenaltySavesEntry[]> {
  // cycle-225 shape: real absence (the raw has no "Penalty saves" category —
  // persiangulf, probed, AND every historical raw, probed) returns [] — the
  // honest feed-without-the-category degradation, same as the siblings. A
  // FAILED fetch when the category EXISTS is a different class entirely: it
  // re-THROWS after the loader-level cache, so the standings build can mark
  // the payload penaltySavesDropped and the TTL reader re-probes in 90s
  // instead of baking the category-only fallback for a full generation (the
  // live-proven 210/222 cold-build race class — this block's first cold
  // build DID drop it once, serving 3 fallback rows while the file holds 5).
  const { raw } = await getLeagueRaw(leagueKey, season);
  const cat = raw.stats?.players?.find?.((p) => /^penalty saves$/i.test(p.header || ""));
  const url = cat?.fetchAllUrl;
  if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];  // real absence — honest []
  try {
    return await cached(
      `fullPenaltySaves:v1:${leagueKey}:${season || "cur"}`,
      // THE cycle-225 GUARD DECISION (the thread the 222/224 cards left
      // open): penalty_save.json files are NATURALLY thin — live-probed
      // 2026-10-30 across all six serving leagues: ucl 2 / pl 2 / laliga 5
      // / seriea 5 / bundesliga 4 / ligue1 3 rows. A penalty save is a rare
      // event, so the FULL file will never reach FULL_LIST_HEALTHY_MIN —
      // the cycle-127 thin guard (rows < 10 → re-probe in 90s) would
      // re-probe FOREVER here (the cycle-176 red-cards lesson verbatim:
      // "red files are naturally short — a red guard would re-probe
      // forever"). Health rule for this sibling: ≥1 row = healthy (the
      // normal 60-min TTL); 0 rows (an empty upstream file — never yet
      // observed on a serving league) re-probe in 90s.
      (rows) => (rows.length >= 1 ? 60 * 60_000 : 90_000),
      async () => {
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: PenaltySavesEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            penaltySaves: Math.round(r.StatValue ?? 0),  // integer ONCE — the 215/216 convention (1.0 → 1)
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch (err) {
    // cycle-225: NOT honest absence — the category exists upstream. Re-throw
    // (the standings build marks the payload and the 90s re-probe heals; the
    // throw itself never breaks the merge — the build catches it and serves
    // the honest category fallback meanwhile).
    throw err instanceof Error ? err : new Error("penalty_save.json fetch failed");
  }
}

export async function getFullSavesPer90(leagueKey: string, season?: string): Promise<SavesPer90Entry[]> {
  try {
    return await cached(
      `fullSavesPer90:v1:${leagueKey}:${season || "cur"}`,
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const cat = raw.stats?.players?.find?.((p) => /^saves per 90$/i.test(p.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\/\/data\.fotmob\.com\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: SavesPer90Entry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const id = r.ParticiantId ?? r.ParticipantId;
          if (!r.ParticipantName || id == null || seen.has(id)) continue;
          seen.add(id);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: playerFa(r.ParticipantName),
            team: teamFa(r.TeamName || undefined) || r.TeamName || "",
            teamId: r.TeamId ?? 0,
            savesPer90: r.StatValue ?? 0,  // per-90 decimal VERBATIM — the 210/217/221 convention, never rounded
            playerId: id,
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the merge
  }
}

/**
 * Card leaders for one league («آقای کارت», cycle-50). The league payload
 * carries "Yellow cards" / "Red cards" categories with the same fetchAllUrl
 * S3 static-file mechanism as the goals list — full ranking when the file
 * is reachable, participant + topThree fallback otherwise. Fully graceful:
 * any failure (e.g. the persiangulf null feed) returns [] and the merged
 * section simply omits that league.
 *
 * cycle-185: season-aware — the last season-blind deep fetch. The scorers
 * file followed the requested season since cycle-124 (the raw carries each
 * season's OWN fetchAllUrl) and the assists file since cycle-175, but the
 * card files kept serving the CURRENT season for every request, so the
 * standings build had to gate the whole block off for historical views
 * (the cycle-132 rule). Live-probed 2026-10-30 (UA Chrome/124) that the
 * gate was hiding reachable data: the 2023/2024 pl raw carries
 * stats/47/season/20720/yellow_card.json (438 rows, Palhinha 13) and
 * red_card.json (55 rows, Bissouma 2). Optional `season` now threads into
 * getLeagueRaw exactly like getFullGoalScorers/getFullAssists; cache key
 * gains the season segment (v2 namespace — the old key baked season-blind
 * rows, a historical request must never read it); current-season behavior
 * byte-identical (`cur` key, same files).
 */
export async function getLeagueCardLeaders(
  leagueKey: string,
  kind: CardKind,
  limit = 15,
  season?: string,
): Promise<Omit<GlobalCard, "rank" | "leagueKey" | "leagueFa">[]> {
  try {
    return freshCardNames(
      await cached(
        `cards:v2:${leagueKey}:${kind}:${season || "cur"}`,
        // cycle-127 thin-TTL guard (same class as getFullGoalScorers):
        // full card files are always wide (live-probed 438/204 yellow rows),
        // the topThree fallback is ~3-4 — thin rows re-probe after 90s
        // instead of baking for an hour.
        (rows) => (rows.length >= CARD_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
        async () => {
      const { raw } = await getLeagueRaw(leagueKey, season);
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
    // cycle-170 additive: assists gain the honest Persian name like scorers —
    // the league page surfaces the block (بهترین پاس‌دهندگان) and the raw
    // English name alone would dead-end the profile network (the 167 lesson)
    assists: st.assists.map((a) => ({ ...a, team: teamFa(a.team) || a.team, nameFa: playerFa(a.name) })),
    // cycle-210 additive: ratings gain the honest Persian names like
    // assists — «برترین امتیازها» renders on the per-league topscorers page
    // and the raw English name alone would dead-end the profile network
    // (the 167 lesson). Decimal value untouched (storage never rounds).
    ratings: (st.ratings || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-215 additive: clean sheets gain the honest Persian names like
    // ratings — «گل نخرده‌ها» renders on the per-league topscorers page and
    // the raw English name alone would dead-end the profile network (the
    // 167 lesson). Integer value untouched (rounded once at build).
    cleanSheets: (st.cleanSheets || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-216 additive: G+A rows gain the honest Persian names like the
    // siblings — «گل+پاس» renders on the per-league topscorers page and the
    // raw English name alone would dead-end the profile network (the 167
    // lesson). Integer value untouched (rounded once at build).
    gPlusA: (st.gPlusA || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-217 additive: goals-prevented rows gain the honest Persian
    // names like the siblings — «گل‌های پیشگیری‌شده» renders on the
    // per-league topscorers page and the raw English name alone would
    // dead-end the profile network (the 167 lesson). SIGNED DECIMAL value
    // untouched (storage never rounds).
    goalsPrevented: (st.goalsPrevented || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-220 additive: minutes-played rows gain the honest Persian names
    // like the siblings — «بیشترین دقایق» renders on the per-league
    // topscorers page and the raw English name alone would dead-end the
    // profile network (the 167 lesson). Integer value untouched (rounded
    // once at build).
    minutes: (st.minutes || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-221 additive: save-percentage rows gain the honest Persian names
    // like the siblings — «درصد سیو» renders on the per-league topscorers
    // page and the raw English name alone would dead-end the profile
    // network (the 167 lesson). Percent value untouched (verbatim).
    savePercentage: (st.savePercentage || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-222 additive: the saves-per-90 rows get the same read-time
    // honest names — the category top-3 rows enter the merge WITHOUT a
    // nameFa (statCategory carries raw names only), so this mapped-payload
    // re-application is what makes them Persian (the live-proven 2020/21
    // case: the first gate run rendered Badía/Domènech/Masip honest-English
    // until this line rejoined the 219/221 curation). Per-90 value
    // untouched (verbatim).
    savesPer90: (st.savesPer90 || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-225 additive: penalty-saves rows gain the same read-time honest
    // names (the 222 lesson — the category top-3 rows enter the merge
    // WITHOUT a nameFa; statCategory carries raw names only). Integer value
    // untouched (rounded once at build).
    penaltySaves: (st.penaltySaves || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-226 additive: xG rows gain the same read-time honest names (the
    // 222 lesson — the category top-3 rows enter the merge WITHOUT a
    // nameFa). Decimal value untouched (verbatim, storage never rounds).
    xg: (st.xg || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-227 additive: goals-per-90 rows gain the same read-time honest
    // names (the 222 lesson — the category top-3 rows enter the merge
    // WITHOUT a nameFa; statCategory carries raw names only). Decimal
    // value untouched (verbatim, storage never rounds).
    goalsPer90: (st.goalsPer90 || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-230 additive: xA rows gain the same read-time honest names (the
    // 222 lesson — the category top-3 rows enter the merge WITHOUT a
    // nameFa; statCategory carries raw names only). Decimal value
    // untouched (verbatim, storage never rounds).
    xa: (st.xa || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-231 additive: big-chances rows gain the same read-time honest
    // names (the 222 lesson — the category top-3 rows enter the merge
    // WITHOUT a nameFa; statCategory carries raw names only). Integer
    // value untouched (rounded once at build, the 215/220 convention).
    bigChancesCreated: (st.bigChancesCreated || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-232 additive: xGOT rows gain the same read-time honest names
    // (the 222 lesson — the category top-3 rows enter the merge WITHOUT a
    // nameFa; statCategory carries raw names only). Decimal value
    // untouched (verbatim, storage never rounds).
    xgot: (st.xgot || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-235 additive: chances-created rows gain the same read-time
    // honest names (the 222 lesson — the category top-3 rows enter the
    // merge WITHOUT a nameFa; statCategory carries raw names only).
    // Integer value untouched (rounded once at build, the 215/220
    // convention).
    chancesCreated: (st.chancesCreated || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-236 additive: big-chances-missed rows gain the same read-time
    // honest names (the 222 lesson — the category top-3 rows enter the
    // merge WITHOUT a nameFa; statCategory carries raw names only).
    // Integer value untouched (rounded once at build, the 215/220
    // convention).
    bigChancesMissed: (st.bigChancesMissed || []).map((r) => ({ ...r, team: teamFa(r.team) || r.team, nameFa: playerFa(r.name) })),
    // cycle-237 additive: the team-xg rows ARE teams — the honest Persian
    // team name re-applies at read time exactly like the standings table
    // rows (rowFa, the teamFa edition of the 170 contract): a teamFa map
    // addition never waits a full generation to reach «گل مورد انتظار
    // تیم‌ها». Decimal value untouched (verbatim, storage never rounds).
    teamXg: (st.teamXg || []).map((r) => ({ ...r, nameFa: teamFa(r.name) || undefined })),
    // cycle-176 additive: card rows get the same read-time honest names —
    // freshCardNames (the cycle-109 idempotent read-freshener for the cards
    // family) reused verbatim, so a player-name map addition never waits a
    // full generation to reach the league page's کارت‌ها section
    ...(st.cards
      ? {
          cards: {
            yellow: freshCardNames(st.cards.yellow || []),
            red: freshCardNames(st.cards.red || []),
          },
        }
      : {}),
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
      // cycle-160: archived Swiss seasons split into Championship/Relegation
      // groups (live-probed 2025/2026: 6+6 rows + the 12-row overall table
      // — leagueName values "Championship Group"/"Relegation Group"/
      // "Super League"; the overall rides the «جدول کلی» label below)
      "championship group": "دور قهرمانی", "relegation group": "دور سقوط",
      // the archived Swiss third sub-table IS the combined table (its
      // leagueName is just the league's English name) — the standard
      // Persian-sports label for the merged standings
      "super league": "جدول کلی",
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
    // cycle-230 additive: the xA badge map — the assist-side twin of xgMap
    // (header SINGULAR upstream, probed: "Expected assist (xA)")
    const xaMap = new Map(statCategory(raw, /^expected assist \(xa\)$/i).map((p) => [p.id, p.value ?? 0]));
    // cycle-231 additive: the big-chances badge map — the creation-volume
    // twin (header "Big chances created", probed)
    const bccMap = new Map(statCategory(raw, /^big chances created$/i).map((p) => [p.id, Math.round(p.value ?? 0)]));
    // cycle-232 additive: the xGOT badge map — the on-target accuracy twin
    // (header "Expected goals on target (xGOT)", probed verbatim off the
    // laliga category list)
    const xgotMap = new Map(statCategory(raw, /^expected goals on target \(xgot\)$/i).map((p) => [p.id, p.value ?? 0]));
    // cycle-235 additive: the chances-created badge map — the TOTAL-creation
    // volume twin (header "Chances created", probed verbatim off the
    // laliga category list; integer values, nonint=0)
    const ccMap = new Map(statCategory(raw, /^chances created$/i).map((p) => [p.id, Math.round(p.value ?? 0)]));
    // cycle-236 additive: the big-chances-missed badge map — the
    // missed-volume twin (header "Big chances missed", probed; integer
    // values, nonint=0)
    const bcmMap = new Map(statCategory(raw, /^big chances missed$/i).map((p) => [p.id, Math.round(p.value ?? 0)]));
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
        ...(xaMap.has(s.id) ? { xa: xaMap.get(s.id) } : {}),
        ...(bccMap.has(s.id) ? { bigChances: bccMap.get(s.id) } : {}),
        ...(xgotMap.has(s.id) ? { xgot: xgotMap.get(s.id) } : {}),
        ...(ccMap.has(s.id) ? { chancesCreated: ccMap.get(s.id) } : {}),
        ...(bcmMap.has(s.id) ? { bigChancesMissed: bcmMap.get(s.id) } : {}),
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
      .map((e, i) => ({ ...e, rank: i + 1 }));
    // cycle-175: the cycle-23 move for playmakers — merge the full-season
    // assists file on top of the 3-4 category names, then rank deep.
    // Enriched category entries stay first when tied (same merge order as
    // the scorers); feeds without fetchAllUrl degrade honestly.
    const fullAssists = await getFullAssists(leagueKey, requestedSeason);
    const enrichedAIds = new Set(
      assistEntries.map((a) => a.playerId).filter((id): id is number => id != null),
    );
    const mergedAssists = [...assistEntries, ...fullAssists.filter((a) => a.playerId == null || !enrichedAIds.has(a.playerId))]
      .sort((a, b) => b.assists - a.assists || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-210: «آقای امتیاز» — the deep-file family's next sibling rides
    // the SAME cached payload (zero extra upstream cost beyond the one gzip
    // file on cold build, exactly like the siblings). Category top-3 first
    // (enriched entries stay first when tied — the 175 merge order), then
    // the full rating file merged on top, deduped by player id, ranked by
    // the DECIMAL value (never rounded — sorting on the verbatim float),
    // top-10. Feeds without the category degrade honestly to [].
    const ratingEntries: RatingEntry[] = statCategory(raw, /^fotmob rating$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, rating: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.rating - a.rating || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullRatings = await getFullRatings(leagueKey, requestedSeason);
    const enrichedRIds = new Set(
      ratingEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedRatings = [...ratingEntries, ...fullRatings.filter((r) => r.playerId == null || !enrichedRIds.has(r.playerId))]
      .sort((a, b) => b.rating - a.rating || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-215: «گل نخرده‌ها» — the deep-file family's next sibling rides
    // the SAME cached payload (zero extra upstream cost beyond the one gzip
    // file on cold build, exactly like the siblings). Category top-3 first
    // (enriched entries stay first when tied — the 175 merge order), then
    // the full clean-sheet file merged on top, deduped by player id, ranked
    // by the INTEGER value, top-10. Feeds without the category degrade
    // honestly to []. SEQUENTIAL after the ratings merge (the 176
    // discipline: one L2 write at a time — the mas cold-build race lesson).
    const cleanSheetEntries: CleanSheetEntry[] = statCategory(raw, /^clean sheets$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, cleanSheets: Math.round(p.value ?? 0),
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.cleanSheets - a.cleanSheets || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullCleanSheets = await getFullCleanSheets(leagueKey, requestedSeason);
    const enrichedCSIds = new Set(
      cleanSheetEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedCleanSheets = [...cleanSheetEntries, ...fullCleanSheets.filter((r) => r.playerId == null || !enrichedCSIds.has(r.playerId))]
      .sort((a, b) => b.cleanSheets - a.cleanSheets || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-216: «گل+پاس» — the deep-file family's sixth sibling rides the
    // SAME cached payload (zero extra upstream cost beyond the one gzip
    // file on cold build, exactly like the siblings). Category top-3 first
    // (enriched entries stay first when tied — the 175 merge order), then
    // the full G+A file merged on top, deduped by player id, ranked by the
    // INTEGER value, top-10. The upstream's OWN combined order — never
    // recomputed from the scorers list. Feeds without the category degrade
    // honestly to []. SEQUENTIAL after the clean-sheets merge (the 176
    // discipline: one L2 write at a time — the mas cold-build race lesson).
    const gPlusAEntries: GPlusAEntry[] = statCategory(raw, /^goals \+ assists$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, gPlusA: Math.round(p.value ?? 0),
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.gPlusA - a.gPlusA || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullGPlusA = await getFullGPlusA(leagueKey, requestedSeason);
    const enrichedGAIds = new Set(
      gPlusAEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedGPlusA = [...gPlusAEntries, ...fullGPlusA.filter((r) => r.playerId == null || !enrichedGAIds.has(r.playerId))]
      .sort((a, b) => b.gPlusA - a.gPlusA || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-217: «گل‌های پیشگیری‌شده» — the deep-file family's SEVENTH
    // sibling rides the SAME cached payload (zero extra upstream cost
    // beyond the one gzip file on cold build, exactly like the siblings).
    // Category top-3 first (enriched entries stay first when tied — the
    // 175 merge order), then the full goals-prevented file merged on top,
    // deduped by player id, ranked by the SIGNED DECIMAL value (verbatim
    // float — the rating convention; negatives sink to the tail by the
    // plain desc sort), top-10. Feeds without the category (persiangulf,
    // probed) degrade honestly to []. SEQUENTIAL after the G+A merge (the
    // 176 discipline: one L2 write at a time — the mas cold-build race
    // lesson).
    const goalsPreventedEntries: GoalsPreventedEntry[] = statCategory(raw, /^goals prevented$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, goalsPrevented: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.goalsPrevented - a.goalsPrevented || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullGoalsPrevented = await getFullGoalsPrevented(leagueKey, requestedSeason);
    const enrichedGPIds = new Set(
      goalsPreventedEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedGoalsPrevented = [...goalsPreventedEntries, ...fullGoalsPrevented.filter((r) => r.playerId == null || !enrichedGPIds.has(r.playerId))]
      .sort((a, b) => b.goalsPrevented - a.goalsPrevented || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-220: «بیشترین دقایق» — the deep-file family's EIGHTH sibling
    // rides the SAME cached payload (zero extra upstream cost beyond the
    // one gzip file on cold build, exactly like the siblings). The first
    // PRESENCE surface (minutes on the pitch — not production, not
    // keeping): stats/{id}/season/{sid}/mins_played.json (live-probed
    // 2026-10-30 UA Chrome/124: laliga 38843 = 482 rows, the family's
    // widest file; 2025/26 = season/27233, 600 rows, Sivera/Soria/Radu
    // 3420 = 38×90 frozen). Category top-3 first (the 175 merge order),
    // then the full file merged on top, deduped by player id, sorted by
    // minutes DESC (stable — the file's own alphabetical tie order inside
    // equal minutes is kept as the base order, the 216 lesson), top-10,
    // POSITIONAL rank re-assignment (the family contract — the file's
    // competition tie-ranks 1,1,1,4,4,4… are honest upstream data but the
    // served top-10 re-ranks like every sibling). SEQUENTIAL after the
    // goals-prevented merge (the 176 discipline: one L2 write at a time).
    const minutesEntries: MinutesEntry[] = statCategory(raw, /^minutes played$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, minutes: Math.round(p.value ?? 0),
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.minutes - a.minutes || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullMinutes = await getFullMinutes(leagueKey, requestedSeason);
    const enrichedMinutesIds = new Set(
      minutesEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedMinutes = [...minutesEntries, ...fullMinutes.filter((r) => r.playerId == null || !enrichedMinutesIds.has(r.playerId))]
      .sort((a, b) => b.minutes - a.minutes || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-221: «درصد سیو» — the deep-file family's NINTH sibling and the
    // THIRD keeper surface rides the SAME cached payload (zero extra
    // upstream cost beyond the one gzip file on cold build, exactly like
    // the siblings): stats/{id}/season/{sid}/_save_percentage.json
    // (live-probed 2026-10-30 UA Chrome/124: SIX of the seven leagues —
    // ucl 45 / pl 21 / laliga 21 / seriea 21 / bundesliga 20 / ligue1 18
    // rows; persiangulf honestly absent — no keeper category at all; the
    // 2025/26 frozen anchor Joan García 77.9 / Soria 75.6 / Escandell
    // 72.5). Category top-3 first (the 175 merge order), then the full
    // file merged on top, deduped by player id, sorted by percentage DESC
    // (stable), top-10, POSITIONAL rank re-assignment (the family
    // contract — ucl's competition tie-ranks 1,2,3,3,5,6 are honest
    // upstream data but the served top-10 re-ranks like every sibling).
    // SEQUENTIAL after the minutes merge (the 176 discipline: one L2
    // write at a time).
    const savePercentageEntries: SavePercentageEntry[] = statCategory(raw, /^save percentage$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, savePercentage: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.savePercentage - a.savePercentage || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullSavePercentage = await getFullSavePercentage(leagueKey, requestedSeason);
    const enrichedSVIds = new Set(
      savePercentageEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedSavePercentage = [...savePercentageEntries, ...fullSavePercentage.filter((r) => r.playerId == null || !enrichedSVIds.has(r.playerId))]
      .sort((a, b) => b.savePercentage - a.savePercentage || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-222: «سیو در هر ۹۰» — the TENTH sibling joins the SAME cached
    // payload (the 175→221 merge pattern one surface over):
    // stats/{id}/season/{sid}/saves.json (live-probed 2026-10-30 UA
    // Chrome/124: SIX of the seven leagues — ucl 43 / pl 21 / laliga 21 /
    // seriea 21 / bundesliga 20 / ligue1 18 rows; persiangulf honestly
    // absent — no keeper category at all; the 2025/26 frozen anchor Aarón
    // Escandell 4.1 / Dmitrović 3.6 / Ryan 3.5). Category top-3 first (the
    // 175 merge order), then the full file merged on top, deduped by player
    // id, sorted by per-90 DESC (stable), top-10, POSITIONAL rank
    // re-assignment (the family contract — ucl's competition tie-ranks
    // 1,1,3,4,5,5,7,8,8,10 are honest upstream data but the served top-10
    // re-ranks like every sibling). SEQUENTIAL after the save-percentage
    // merge (the 176 discipline: one L2 write at a time).
    const savesPer90Entries: SavesPer90Entry[] = statCategory(raw, /^saves per 90$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, savesPer90: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.savesPer90 - a.savesPer90 || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullSavesPer90 = await getFullSavesPer90(leagueKey, requestedSeason);
    const enrichedSP90Ids = new Set(
      savesPer90Entries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedSavesPer90 = [...savesPer90Entries, ...fullSavesPer90.filter((r) => r.playerId == null || !enrichedSP90Ids.has(r.playerId))]
      .sort((a, b) => b.savesPer90 - a.savesPer90 || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-225: «پنالتی‌های مهارشده» — the ELEVENTH sibling joins the SAME
    // cached payload (the 175→222 merge pattern one surface over):
    // stats/{id}/season/{sid}/penalty_save.json (live-probed 2026-10-30 UA
    // Chrome/124: SIX of the seven leagues — ucl 2 / pl 2 / laliga 5 /
    // seriea 5 / bundesliga 4 / ligue1 3 rows, all INTEGER StatValue 1-2
    // with competition tie-ranks (laliga 1,2,2,4,5); persiangulf honestly
    // absent — no keeper category; CURRENT-SEASON ONLY: the 2020/21,
    // 2023/24 and 2025/26 finished raws carry NO "Penalty saves" category —
    // probed — so historical views honestly hide the section, the
    // cycle-132 class). Category top-3 first (the 175 merge order), then
    // the full file merged on top, deduped by player id, sorted by penalty
    // saves DESC then name, top-10 (the thin files cap well below),
    // POSITIONAL rank re-assignment (the family contract — the upstream's
    // tie-ranks are honest data but the served list re-ranks like every
    // sibling). NO length-based thin guard for this block (the TTL reader
    // below): the files are naturally short FOREVER — a <10 re-probe guard
    // would spin eternally (the 176 red-cards lesson); the DROPPED-FETCH
    // class is instead guarded precisely via the penaltySavesDropped marker
    // (the catch below + the TTL reader).
    // SEQUENTIAL after the saves-per-90 merge (the 176 discipline: one L2
    // write at a time).
    let penaltySavesDropped = false;
    const penaltySavesEntries: PenaltySavesEntry[] = statCategory(raw, /^penalty saves$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, penaltySaves: Math.round(p.value ?? 0),
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.penaltySaves - a.penaltySaves || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullPenaltySaves = await getFullPenaltySaves(leagueKey, requestedSeason).catch(() => {
      // cycle-225: the dropped-fetch class — the category exists upstream but
      // the file fetch failed after the retries (the 210/222 cold-build race;
      // this block's FIRST cold build dropped exactly this way: 3 fallback
      // rows baked while the file holds 5). The merge still serves the honest
      // category fallback meanwhile, and the payload carries the
      // penaltySavesDropped marker so the TTL reader re-probes in 90s
      // instead of baking the short list for a full generation.
      penaltySavesDropped = true;
      return [] as PenaltySavesEntry[];
    });
    const enrichedPSIds = new Set(
      penaltySavesEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedPenaltySaves = [...penaltySavesEntries, ...fullPenaltySaves.filter((r) => r.playerId == null || !enrichedPSIds.has(r.playerId))]
      .sort((a, b) => b.penaltySaves - a.penaltySaves || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-226: «گل مورد انتظار» — the TWELFTH sibling joins the SAME
    // cached payload (the 175→225 merge pattern one surface over):
    // stats/{id}/season/{sid}/expected_goals.json (live-probed 2026-10-30
    // UA Chrome/124: SIX of the seven leagues — laliga 389 rows Mbappé
    // 12.2 / Raphinha 9.2 / Yamal 7.0, ucl 479 Guirassy 4.2; persiangulf
    // honestly absent — no xG category; SEASON-AWARE (the 124/175/185
    // class): the 2020/21 raw serves its OWN file, 471 rows, Messi 23.9 /
    // Moreno 19.0 / Benzema 18.8 — frozen, the 202 anchor pattern). Decimal
    // values kept VERBATIM — the fifth non-integer member (the 210/217/221/
    // 222 convention); upstream precision EXACTLY one decimal (probed) so
    // the pill renders toFixed(1), the 217 display rule. Category top-3
    // first (the 175 merge order), then the full file merged on top,
    // deduped by player id, sorted xg DESC then name, top-10, POSITIONAL
    // rank re-assignment. Standard thin guard applies (wide files — the
    // 210 class). SEQUENTIAL after the penalty-saves merge (the 176
    // discipline: one L2 write at a time).
    const xgEntries: XgEntry[] = statCategory(raw, /^expected goals \(xg\)$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, xg: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.xg - a.xg || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullXg = await getFullXg(leagueKey, requestedSeason);
    const enrichedXgIds = new Set(
      xgEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedXg = [...xgEntries, ...fullXg.filter((r) => r.playerId == null || !enrichedXgIds.has(r.playerId))]
      .sort((a, b) => b.xg - a.xg || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-227: «گل در هر ۹۰» — the THIRTEENTH sibling joins the SAME
    // merge on the SAME cached payload. goals_per_90.json (live-probed
    // 2026-10-30 UA Chrome/124: 23 of the 24 leagues — everything but mas —
    // with WIDE files, laliga 139 rows Raphinha 1.77 / Gabriel Jesus 1.36,
    // championship 196; PERSIANGULF SERVES — 93 rows, the first deep
    // sibling besides minutes to reach the Persian Gulf; competition
    // tie-ranks 1,1,3 re-ranked POSITIONALLY like every sibling). Decimal
    // values kept VERBATIM — the sixth non-integer member (the
    // 210/217/221/222/226 convention); upstream precision UP TO two
    // decimals (probed) so the pill renders toFixed(2), the 217 display
    // rule. SEASON-AWARE (the 124/175/185/226 class): historical raws
    // serve their OWN files — the 2020/21 laliga raw = season/15585, 224
    // rows, Messi 0.89 / Moreno 0.77 / Suárez 0.75 — frozen, the 202
    // anchor pattern. Category top-3 first (the 175 merge order), then the
    // full file merged on top, deduped by player id, sorted value-DESC
    // then name, top-10, POSITIONAL rank re-assignment. Standard thin
    // guard applies (wide files — the 210 class). SEQUENTIAL after the xG
    // merge (the 176 discipline: one L2 write at a time).
    const gp90Entries: GoalsPer90Entry[] = statCategory(raw, /^goals per 90$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, goalsPer90: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.goalsPer90 - a.goalsPer90 || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullGp90 = await getFullGoalsPer90(leagueKey, requestedSeason);
    const enrichedGp90Ids = new Set(
      gp90Entries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedGoalsPer90 = [...gp90Entries, ...fullGp90.filter((r) => r.playerId == null || !enrichedGp90Ids.has(r.playerId))]
      .sort((a, b) => b.goalsPer90 - a.goalsPer90 || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-230: «پاس مورد انتظار» — the FOURTEENTH sibling joins the SAME
    // merge on the SAME cached payload, the assist-side ANALYTICS twin of
    // the xG merge one block over. expected_assists.json (live-probed
    // 2026-10-30 UA Chrome/124: SIX of the seven globalMerge leagues —
    // ucl 721 Kimmich 1.9 / pl 448 Iwobi 2.6 / laliga 480 Yamal 4.0 /
    // seriea 487 Dybala 3.4 / bundesliga 399 Olise 4.1 / ligue1 422
    // Thauvin 3.8 rows; persiangulf honestly absent — no xA category; mas
    // absent; SEASON-AWARE (the 124/175/185/226/227 class): the 2020/21
    // raw serves its OWN file, 565 rows, Messi 13.4 / Jordi Alba 9.9 —
    // frozen, the 202 anchor pattern). Decimal values kept VERBATIM — the
    // SEVENTH non-integer member (the 210/217/221/222/226/227 convention);
    // upstream precision EXACTLY one decimal (probed) so the pill renders
    // toFixed(1), the 217 display rule. Category top-3 first (the 175
    // merge order), then the full file merged on top, deduped by player
    // id, sorted xa DESC then name, top-10, POSITIONAL rank re-assignment.
    // Standard thin guard applies (wide files — the 210 class).
    // SEQUENTIAL after the goals-per-90 merge (the 176 discipline: one L2
    // write at a time).
    const xaEntries: XaEntry[] = statCategory(raw, /^expected assist \(xa\)$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, xa: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.xa - a.xa || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullXa = await getFullXa(leagueKey, requestedSeason);
    const enrichedXaIds = new Set(
      xaEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedXa = [...xaEntries, ...fullXa.filter((r) => r.playerId == null || !enrichedXaIds.has(r.playerId))]
      .sort((a, b) => b.xa - a.xa || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-231: «سانس بزرگ خلق‌شده» — the FIFTEENTH sibling joins the SAME
    // merge on the SAME cached payload, the production-CREATION volume
    // surface beside the analytics twins. big_chances_created.json
    // (live-probed 2026-10-30 UA Chrome/124: 22 of the 24 leagues.ts
    // entries — every league but persiangulf AND mas, the gp90 footprint —
    // six domestics: ucl 190 Yamal 5 / pl 152 Groß 7 / laliga 185 Yamal
    // 14 / seriea 202 Dybala 8 / bundesliga 160 Nusa+Kane 6 / ligue1 157
    // Thauvin 9; SEASON-AWARE (the 124/175/185/226/227/230 class): the
    // 2020/21 raw serves its OWN file, 309 rows, Messi 22.0 / Iago Aspas
    // 16.0 — frozen, the 202 anchor pattern). INTEGER-VALUED floats
    // (probed nonint=0) → the 215/216/220 integer convention: rounded once
    // at build, pill Persian digits WITHOUT dir=ltr. Category top-3 first
    // (the 175 merge order), then the full file merged on top, deduped by
    // player id, sorted value-DESC then name, top-10, POSITIONAL rank
    // re-assignment. Standard thin guard applies (wide files — the 210
    // class). SEQUENTIAL after the expected-assist merge (the 176
    // discipline: one L2 write at a time).
    const bccEntries: BigChancesCreatedEntry[] = statCategory(raw, /^big chances created$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, bigChances: Math.round(p.value ?? 0),
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.bigChances - a.bigChances || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullBcc = await getFullBigChances(leagueKey, requestedSeason);
    const enrichedBccIds = new Set(
      bccEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedBigChances = [...bccEntries, ...fullBcc.filter((r) => r.playerId == null || !enrichedBccIds.has(r.playerId))]
      .sort((a, b) => b.bigChances - a.bigChances || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-232: «گل مورد انتظار روی دروازه» — the SIXTEENTH sibling joins
    // the SAME merge on the SAME cached payload, the third ANALYTICS level
    // and the on-target accuracy twin of the xG merge one block over.
    // expected_goalsontarget.json (live-probed 2026-10-30 UA Chrome/124:
    // SIX of the seven globalMerge leagues — ucl 305 Tresoldi 4.5 / pl 241
    // Haaland 8.2 / laliga 277 Mbappé 12.8 / seriea 286 Malen 6.6 /
    // bundesliga 227 Füllkrug 6.2 / ligue1 227 Lepaul 6.0 rows;
    // persiangulf honestly absent — 5 player cats, no xGOT; mas absent,
    // null payload; SEASON-AWARE (the 124/175/185/226/227/230/231 class):
    // the 2020/21 raw serves its OWN file, 385 rows, Messi 32.8 / Gerard
    // Moreno 24.8 — frozen, the 202 anchor pattern). Decimal values kept
    // VERBATIM — the EIGHTH non-integer member (the
    // 210/217/221/222/226/227/230 convention); upstream precision EXACTLY
    // one decimal (probed) so the pill renders toFixed(1), the 217 display
    // rule. Category top-3 first (the 175 merge order), then the full file
    // merged on top, deduped by player id, sorted xgot DESC then name,
    // top-10, POSITIONAL rank re-assignment. Standard thin guard applies
    // (wide files — the 210 class). SEQUENTIAL after the big-chances merge
    // (the 176 discipline: one L2 write at a time).
    const xgotEntries: XgotEntry[] = statCategory(raw, /^expected goals on target \(xgot\)$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, xgot: p.value ?? 0,
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.xgot - a.xgot || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullXgot = await getFullXgot(leagueKey, requestedSeason);
    const enrichedXgotIds = new Set(
      xgotEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedXgot = [...xgotEntries, ...fullXgot.filter((r) => r.playerId == null || !enrichedXgotIds.has(r.playerId))]
      .sort((a, b) => b.xgot - a.xgot || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-235: «فرصت‌های خلق‌شده» — the SEVENTEENTH sibling joins the
    // SAME merge on the SAME cached payload, the TOTAL-creation VOLUME
    // twin of the BCC merge one block over. total_att_assist.json
    // (live-probed 2026-10-30 UA Chrome/124: ALL SIX domestic globalMerge
    // leagues — ucl 466 Thauvin 15 / pl 323 Groß 23 / laliga 363 Arda
    // Güler 33 / seriea 382 Giacomo Calò 34 / bundesliga 308 Olise 25 /
    // ligue1 304 Thauvin 27 rows; persiangulf honestly absent — 5 player
    // cats; mas absent, empty payload; SEASON-AWARE (the
    // 124/175/185/226/227/230/231/232 class): the 2020/21 raw serves its
    // OWN file, 466 rows, Lionel Messi 77 / David Ferreiro 73 / Toni
    // Kroos 67 — frozen, the 202 anchor pattern). INTEGER-VALUED floats
    // (probed nonint=0) → the 215/216/220 integer convention: rounded once
    // at build, pill Persian digits WITHOUT dir=ltr. Category top-3 first
    // (the 175 merge order), then the full file merged on top, deduped by
    // player id, sorted chancesCreated DESC then name, top-10, POSITIONAL
    // rank re-assignment. Standard thin guard applies (wide files — the
    // 210 class). SEQUENTIAL after the xGOT merge (the 176 discipline:
    // one L2 write at a time).
    const ccEntries: ChancesCreatedEntry[] = statCategory(raw, /^chances created$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, chancesCreated: Math.round(p.value ?? 0),
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.chancesCreated - a.chancesCreated || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullChancesCreated = await getFullChancesCreated(leagueKey, requestedSeason);
    const enrichedCcIds = new Set(
      ccEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedChancesCreated = [...ccEntries, ...fullChancesCreated.filter((r) => r.playerId == null || !enrichedCcIds.has(r.playerId))]
      .sort((a, b) => b.chancesCreated - a.chancesCreated || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-236: «سانس بزرگ ازدست‌رفته» — the EIGHTEENTH sibling joins the
    // SAME merge on the SAME cached payload, the MISSED-volume twin of the
    // BCC merge two blocks over. big_chance_missed.json (live-probed
    // 2026-10-30 UA Chrome/124: ALL SIX domestic globalMerge leagues — ucl
    // 140 Haaland 6 / pl 135 Thierno Barry 12 / laliga 142 Mbappé 13 /
    // seriea 171 Malen 9 / bundesliga 126 Demirović 8 / ligue1 128 Mafouta
    // 6 rows; persiangulf honestly absent; mas absent, null payload;
    // SEASON-AWARE (the 124/175/185/226/227/230/231/232/235 class): the
    // 2020/21 raw serves its OWN file, 257 rows, Karim Benzema 19 /
    // Alexander Isak 16 / Rafa Mir 16 — frozen, the 202 anchor pattern).
    // INTEGER-VALUED floats (probed nonint=0) → the 215/216/220 integer
    // convention: rounded once at build, pill Persian digits WITHOUT
    // dir=ltr. Category top-3 first (the 175 merge order), then the full
    // file merged on top, deduped by player id, sorted bigChancesMissed
    // DESC then name, top-10, POSITIONAL rank re-assignment. Standard thin
    // guard applies (wide files — the 210 class). SEQUENTIAL after the
    // chances-created merge (the 176 discipline: one L2 write at a time).
    const bcmEntries: BigChancesMissedEntry[] = statCategory(raw, /^big chances missed$/i)
      .map((p, i) => ({
        rank: p.rank ?? i + 1, name: p.name, team: teamFa(p.teamName) || p.teamName || "",
        teamId: p.teamId ?? 0, bigChancesMissed: Math.round(p.value ?? 0),
        ...(p.id ? { playerId: p.id } : {}),
      }))
      .sort((a, b) => b.bigChancesMissed - a.bigChancesMissed || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullBigChancesMissed = await getFullBigChancesMissed(leagueKey, requestedSeason);
    const enrichedBcmIds = new Set(
      bcmEntries.map((r) => r.playerId).filter((id): id is number => id != null),
    );
    const mergedBigChancesMissed = [...bcmEntries, ...fullBigChancesMissed.filter((r) => r.playerId == null || !enrichedBcmIds.has(r.playerId))]
      .sort((a, b) => b.bigChancesMissed - a.bigChancesMissed || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-237: «گل مورد انتظار تیم‌ها» — the NINETEENTH sibling joins the
    // SAME cached payload, the FIRST TEAM-PARTICIPANT member of the family
    // (the team-side LEVEL the 196 boards only ever showed as a ≤3-row
    // podium). expected_goals_team.json (live-probed 2026-10-30 UA
    // Chrome/124: ALL SIX domestic globalMerge leagues — laliga 20
    // Barcelona 34.8 / pl 20 Manchester City 16.7 / seriea 20 Inter 25.5 /
    // bundesliga 18 Bayern 23.8 / ligue1 18 PSG 20.0 / ucl 36 PSG 10.1
    // rows; persiangulf honestly absent; mas absent; SEASON-AWARE: the
    // 2020/21 raw serves its OWN file, 20 rows, Barcelona 74.3 / Real
    // Madrid 62.3 / Real Sociedad 61.9 — frozen, the 202 anchor pattern).
    // DECIMAL 1-fraction (probed maxdec=1 on every serving file) → the
    // 210/217/226/230/232 VERBATIM-decimal convention: storage never
    // rounds, the pill renders toFixed(1) dir=ltr. Team top-3 first (the
    // 175 merge order, statTeamCategory), then the full file merged on
    // top, deduped by TEAM id (ParticiantId is ALWAYS 0 on team files),
    // sorted teamXg DESC then name, top-10, POSITIONAL rank
    // re-assignment. NO badge twin and NO global-merge participation BY
    // DESIGN: the family's badge/merge mechanisms key on PLAYER ids (the
    // id-intersection with the scorer rows) — a team surface has none;
    // the honest-team block rides the league page only, rows link
    // /team/[id] (the standings-view contract). Standard thin guard
    // applies (team files serve 18-36 rows — above the 10-row floor, no
    // natural-thinness exemption). SEQUENTIAL after the
    // big-chances-missed merge (the 176 discipline: one L2 write at a
    // time).
    const txgEntries: TeamXgEntry[] = statTeamCategory(raw, /^expected goals$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamXg: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamXg - a.teamXg || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamXg = await getFullTeamXg(leagueKey, requestedSeason);
    const enrichedTxgIds = new Set(txgEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamXg = [...txgEntries, ...fullTeamXg.filter((r) => r.teamId <= 0 || !enrichedTxgIds.has(r.teamId))]
      .sort((a, b) => b.teamXg - a.teamXg || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-240: the team clean-sheets block («گل نخرده‌های تیم‌ها») — the
    // deep-file family's TWENTIETH sibling and its SECOND TEAM-PARTICIPANT
    // member: the team-side LEVEL of the keeper clean-sheets surface (215),
    // the team-twin relationship 237 established for xG — straight from the
    // live clean_sheet_team.json probe (UA Chrome/124, 2026-10-30,
    // scripts/cycle240-probe.sh): WIDE files on all six domestic globalMerge
    // leagues (laliga 18 Athletic Club 6.0 / pl 18 Arsenal 5.0 / seriea 18
    // Roma 5.0 / bundesliga 16 Borussia Dortmund 5.0 / ligue1 14 Lorient
    // 5.0 / ucl 17 Arsenal 2.0 rows; portugal 17 with the THREE-WAY tie
    // Arouca/Porto/Santa Clara 5,5,5 probed for breadth); persiangulf
    // honestly absent (its feed carries ONE team category,
    // goals_team_match — probed) while MAS SERVES a naturally-thin 8-row
    // file (Johor Darul Ta'zim 6.0 — the FIRST below-the-floor serve in
    // the family, the 225 health-rule class on the mas panel).
    // INTEGER-VALUED floats (StatFormat number, probed int on every
    // serving file) → the 215/220/231/235/236 integer convention: storage
    // never rounds, the pill renders the integer via String() dir=ltr (6.0
    // renders «۶»; the JS-number corner mirrors the 238 «۲۰.۰» proof —
    // String() on an integer-valued float prints without the .0).
    // Upstream Rank keeps competition ties verbatim (laliga rank 2,2
    // Atlético+Celta probed); the merge re-ranks POSITIONALLY like every
    // sibling. ParticiantId is ALWAYS 0 (teams carry TeamId) → dedup by
    // TeamId. NO badge twin and NO global-merge participation BY DESIGN
    // (the 237 team-surface rule); the block rides the league page only,
    // rows link /team/{teamId} (the standings-view contract).
    // SEASON-AWARE (the 124/…/236 class): the 2020/21 laliga raw serves
    // its OWN file — 20 rows, Atletico Madrid 18.0 / Real Madrid 17.0 /
    // Sevilla 17.0 — frozen, the 202 anchor pattern. The honest-name
    // contract rides the EXISTING teamFa map (zero new PLAYER_NAME_FA
    // entries) + the teamFa edition of the 170 read-time freshener line.
    // Additive mirror of 237 end-to-end: TeamCleanSheetEntry + the
    // REQUIRED teamCleanSheets field on the mapped payload + the team
    // top-3-first merge (dedup by TEAM id, teamCleanSheets DESC, top-10,
    // POSITIONAL re-rank) + standings:v26→v27 (the 52/…/236 additive-
    // shape convention) + the /api/topscorers/[leagueKey] route field +
    // the league-page block «گل نخرده‌های تیم‌ها» placed right after گل
    // مورد انتظار تیم‌ها so the two team-side blocks read together while
    // the player→team pair and the keeper QUINTET stay untouched — the
    // older gates' relative-order asserts are index-inequality-based so
    // the insertion provably keeps them green (all re-ran green) — with
    // data-testid=tcs-row. The mas exemption: the standings TTL guard
    // does NOT demand ≥10 rows on mas (its 8-row file is the file's REAL
    // size — the 176 red-cards lesson; the 225 health-rule class), the
    // domestics keep the standard thin-kept clause.
    const csTeamEntries: TeamCleanSheetEntry[] = statTeamCategory(raw, /^clean sheets$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamCleanSheets: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamCleanSheets - a.teamCleanSheets || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamCleanSheets = await getFullTeamCleanSheets(leagueKey, requestedSeason);
    const enrichedCsIds = new Set(csTeamEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamCleanSheets = [...csTeamEntries, ...fullTeamCleanSheets.filter((r) => r.teamId <= 0 || !enrichedCsIds.has(r.teamId))]
      .sort((a, b) => b.teamCleanSheets - a.teamCleanSheets || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-241: the team possession block («مالکیت توپ تیم‌ها») — the
    // deep-file family's TWENTY-FIRST sibling and its THIRD
    // TEAM-PARTICIPANT member: the team-side possession surface — straight
    // from the live possession_percentage_team.json probe (UA Chrome/124,
    // 2026-10-30, scripts/cycle240-probe.sh family): WIDE files on all six
    // domestic globalMerge leagues (laliga 20 Barcelona 69.4 / pl 20
    // Manchester City 64.2 / seriea 20 Inter 63.0 / bundesliga 18 Bayern
    // München 66.9 / ligue1 18 Paris Saint-Germain 68.0 / ucl 36 Barcelona
    // 65.2 rows; portugal 18 Benfica 63.1 probed for breadth);
    // persiangulf AND mas honestly absent (the 237 absence pair exactly —
    // mas's feed carries FOUR team categories and possession is not one,
    // probed). PERCENT 1-fraction (probed maxdec=1, StatFormat percent) →
    // the 221 percent convention VERBATIM: storage never rounds, the pill
    // renders toFixed(1) dir=ltr (69.4 renders «۶۹.۴») with NO appended
    // percent sign (the 221 rendering rule). Upstream Rank kept verbatim;
    // the merge re-ranks POSITIONALLY like every sibling. ParticiantId is
    // ALWAYS 0 (teams carry TeamId) → dedup by TeamId. NO badge twin and
    // NO global-merge participation BY DESIGN (the 237 team-surface rule);
    // the block rides the league page only, rows link /team/{teamId} (the
    // standings-view contract). SEASON-AWARE (the 124/…/236 class): the
    // 2020/21 laliga raw serves its OWN file — 20 rows, Barcelona 65.8 /
    // Sevilla 61.2 / Real Madrid 59.6 — frozen, the 202 anchor pattern.
    // The honest-name contract rides the EXISTING teamFa map (zero new
    // PLAYER_NAME_FA entries) + the teamFa edition of the 170 read-time
    // freshener line. Additive mirror of 240 end-to-end:
    // TeamPossessionEntry + the REQUIRED teamPossession field on the
    // mapped payload + getFullTeamPossession (fullTeamPossession:v1, the
    // STANDARD guard — NO league-aware floor needed: the honest-empty pair
    // pg+mas degrades to [] upstream of the guard, the 237 pattern) + the
    // team top-3-first merge (dedup by TEAM id, teamPossession DESC,
    // top-10, POSITIONAL re-rank) + standings:v27→v28 (the 52/…/237
    // additive-shape convention) + the /api/topscorers/[leagueKey] route
    // field + the league-page block «مالکیت توپ تیم‌ها» placed right after
    // گل نخرده‌های تیم‌ها so the three team-side blocks read together
    // while the player→team pair and the keeper QUINTET stay untouched —
    // the older gates' relative-order asserts are index-inequality-based
    // so the insertion provably keeps them green (all re-ran green) —
    // with data-testid=tposs-row.
    const posTeamEntries: TeamPossessionEntry[] = statTeamCategory(raw, /^average possession$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamPossession: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamPossession - a.teamPossession || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamPossession = await getFullTeamPossession(leagueKey, requestedSeason);
    const enrichedPosIds = new Set(posTeamEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamPossession = [...posTeamEntries, ...fullTeamPossession.filter((r) => r.teamId <= 0 || !enrichedPosIds.has(r.teamId))]
      .sort((a, b) => b.teamPossession - a.teamPossession || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-242: the team yellow-cards block («کارت‌های زرد تیم‌ها») — the
    // deep-file family's TWENTY-SECOND sibling and its FOURTH
    // TEAM-PARTICIPANT member: the team-side yellow-card surface — straight
    // from the live total_yel_card_team.json probe (UA Chrome/124,
    // 2026-10-30, scripts/cycle242-probe.sh): WIDE files on all six
    // domestic globalMerge leagues (laliga 20 Getafe 33.0 / pl 20 AFC
    // Bournemouth 22.0 / seriea 20 Fiorentina 20.0 / bundesliga 18
    // Borussia Mönchengladbach 21.0 / ligue1 18 Nice 19.0 / ucl 36 Club
    // Brugge 9.0 rows; portugal 18 Académico Viseu 27.0 with the top-3
    // 25,25 tie probed for breadth); persiangulf AND mas honestly absent
    // (the 237/241 absence pair exactly — pg's feed carries ONE team
    // category, Goals per match; mas's feed carries FOUR — Goals per
    // match / Goals conceded per match / Clean sheets / Red cards — and
    // yellow is not one, probed). INTEGER-VALUED floats (probed int on
    // every serving file) → the 215/220/231/235/236 integer convention:
    // storage never rounds, the pill renders String(value) dir=ltr
    // (33.0 renders «۳۳»). Upstream Rank keeps COMPETITION ties verbatim
    // (laliga rank 5,6 on 25.0 / 15,16,16 on 17.0 probed); the merge
    // re-ranks POSITIONALLY like every sibling. ParticiantId is ALWAYS 0
    // (teams carry TeamId) → dedup by TeamId. NO badge twin and NO
    // global-merge participation BY DESIGN (the 237 team-surface rule);
    // the block rides the league page only, rows link /team/{teamId} (the
    // standings-view contract). SEASON-AWARE (the 124/…/236 class): the
    // 2020/21 laliga raw serves its OWN file — season/15585, 20 rows,
    // Getafe 114.0 / Celta Vigo 104.0 / Atletico Madrid 100.0 — frozen,
    // the 202 anchor pattern, DISTINCT from the current 33.0 (Getafe
    // tops BOTH eras, probed). The honest-name contract rides the
    // EXISTING teamFa map (zero new PLAYER_NAME_FA entries) + the teamFa
    // edition of the 170 read-time freshener line. Additive mirror of
    // 241 end-to-end: TeamYellowCardEntry + the REQUIRED teamYellowCards
    // field on the mapped payload + getFullTeamYellowCards
    // (fullTeamYellowCards:v1, the STANDARD guard — NO league-aware
    // floor needed: the honest-empty pair pg+mas degrades to [] upstream
    // of the guard, the 237/241 pattern) + the team top-3-first merge
    // (dedup by TEAM id, teamYellowCards DESC, top-10, POSITIONAL
    // re-rank) + standings:v28→v29 (the 52/…/241 additive-shape
    // convention) + the /api/topscorers/[leagueKey] route field + the
    // league-page block «کارت‌های زرد تیم‌ها» placed right after مالکیت
    // توپ تیم‌ها so the FOUR team-side blocks read together while the
    // player→team pair and the keeper QUINTET stay untouched — the older
    // gates' relative-order asserts are index-inequality-based so the
    // insertion provably keeps them green (all re-ran green) — with
    // data-testid=tyc-row.
    const ycardTeamEntries: TeamYellowCardEntry[] = statTeamCategory(raw, /^yellow cards$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamYellowCards: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamYellowCards - a.teamYellowCards || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamYellowCards = await getFullTeamYellowCards(leagueKey, requestedSeason);
    const enrichedYcIds = new Set(ycardTeamEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamYellowCards = [...ycardTeamEntries, ...fullTeamYellowCards.filter((r) => r.teamId <= 0 || !enrichedYcIds.has(r.teamId))]
      .sort((a, b) => b.teamYellowCards - a.teamYellowCards || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-245: «کارت‌های قرمز تیم‌ها» — the deep-file family's
    // TWENTY-THIRD sibling and its FIFTH TEAM-PARTICIPANT member (the
    // team-side red-card surface, the yellow 242 sibling's red brother),
    // straight from the live total_red_card_team.json probe (UA
    // Chrome/124, 2026-10-31, scripts/cycle245-probe.sh): NATURALLY SHORT
    // files on the NINE serving leagues (laliga 16 Getafe 5.0 / pl 12
    // Brentford 2.0 / seriea 6 Atalanta 2.0 / bundesliga 7 Hoffenheim 2.0
    // / ligue1 9 Le Havre 2.0 / ucl 7 Inter 1.0 / uel 4 Milan 2.0 /
    // portugal 13 Alverca 3.0 with the top-3 2,2 tie probed for breadth /
    // mas 11 Kuching City 3.0 — the SECOND mas team-surface after the 240
    // clean-sheets); persiangulf honestly absent (its feed carries ONE
    // team category, Goals per match, probed — the bare direct file
    // serves 15 rows but the app is feed-driven: no category → honest []
    // upstream of any fetch). INTEGER-VALUED floats (probed int on every
    // serving file) → the 215/220/231/235/236/242 integer convention:
    // storage never rounds, the pill renders String(value) dir=ltr (5.0
    // renders «۵»). Upstream Rank keeps COMPETITION ties verbatim (laliga
    // rank 2,3,4 on 3.0 / 5,6,7 on 2.0 / the duplicated 14,14,16 probed);
    // the merge re-ranks POSITIONALLY like every sibling. ParticiantId is
    // ALWAYS 0 (teams carry TeamId) → dedup by TeamId. NO badge twin and
    // NO global-merge participation BY DESIGN (the 237 team-surface
    // rule); the block rides the league page only, rows link
    // /team/{teamId} (the standings-view contract), data-testid=trc-row,
    // the red-card rect icon, sublabel «انضباط — سطح تیم». SEASON-AWARE
    // (the 124/…/242 class): the 2020/21 laliga raw serves its OWN file —
    // season/15585, 19 rows, Deportivo Alaves 8.0 rank-1 with the 8,8
    // Betis tie — frozen, the 202 anchor pattern, DISTINCT from the
    // current 5.0 (Getafe tops the CURRENT file, Alaves the 2020/21
    // one — probed). The honest-name contract rides the EXISTING teamFa
    // map (zero new PLAYER_NAME_FA entries, probed: all nine rank-1
    // sides covered). Additive mirror of 242 end-to-end:
    // TeamRedCardEntry + the REQUIRED teamRedCards field on the mapped
    // payload + getFullTeamRedCards (fullTeamRedCards:v1, the 240
    // floor-4 class GENERALIZED league-wide — red files are naturally
    // short, the standard <10 guard would re-probe forever) + the team
    // top-3-first merge (dedup by TEAM id, teamRedCards DESC, top-10,
    // POSITIONAL re-rank) + standings:v29→v30 (the 52/…/242
    // additive-shape convention) + the /api/topscorers/[leagueKey]
    // route field + the LeagueScorersData view field (tsc catches the
    // second interface — the view carries its own type) + the
    // league-page block «کارت‌های قرمز تیم‌ها» placed right after
    // کارت‌های زرد تیم‌ها so the FIVE team-side blocks read together
    // while the player→team pair and the keeper QUINTET stay untouched
    // (the older gates' relative-order asserts are index-inequality-based
    // — all re-ran green) — with data-testid=trc-row.
    const rcardTeamEntries: TeamRedCardEntry[] = statTeamCategory(raw, /^red cards$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamRedCards: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamRedCards - a.teamRedCards || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamRedCards = await getFullTeamRedCards(leagueKey, requestedSeason);
    const enrichedRcIds = new Set(rcardTeamEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamRedCards = [...rcardTeamEntries, ...fullTeamRedCards.filter((r) => r.teamId <= 0 || !enrichedRcIds.has(r.teamId))]
      .sort((a, b) => b.teamRedCards - a.teamRedCards || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-246: «گل به از مسابقهٔ تیم‌ها» — the deep-file family's
    // TWENTY-FOURTH sibling and its SIXTH TEAM-PARTICIPANT member (the
    // team-side scoring-rate level), straight from the live
    // goals_team_match.json probe (UA Chrome/124, 2026-10-31,
    // scripts/cycle246-sweep.sh): NINE of NINE leagues serve — the
    // family's FIRST NINE-league surface at the STANDARD guard (files
    // WIDE everywhere: laliga 20 Barcelona 4.0 / pl 20 Brighton 2.9 /
    // seriea 20 Inter 2.8 / bundesliga 18 Bayern 3.6 / ligue1 18
    // Marseille 2.3 / ucl 36 PSG 4.7 / portugal 18 Benfica 2.9 /
    // persiangulf 18 Persepolis 1.8 / mas 12 Johor 4.7) — AND THE
    // PERSIAN GULF IS REACHED: pg's ONE team category IS "Goals per
    // match" (the 237/240/241/242/245 cards documented pg as
    // honestly-absent BECAUSE of that) → pg renders its FIRST-EVER team
    // block; mas's first feed category serves too (its THIRD
    // team-surface after 240/245). Decimal 1-fraction values → the 241
    // toFixed(1) dir=ltr convention verbatim (4.0 renders «۴.۰», no
    // appended sign) — storage never rounds. Upstream Rank keeps
    // COMPETITION ties verbatim (the 2020/21 2,2 Atletico+Real Madrid
    // tie probed); the merge re-ranks POSITIONALLY. ParticiantId is
    // ALWAYS 0 (teams carry TeamId) → dedup by TeamId. NO badge twin
    // and NO global-merge participation BY DESIGN (the 237
    // team-surface rule); the block rides the league page only, rows
    // link /team/{teamId} (the standings-view contract),
    // data-testid=tgm-row, the scoring-rate glyph, sublabel «قدرت حمله
    // — سطح تیم». SEASON-AWARE (the 124/…/245 class): the 2020/21
    // laliga raw serves its OWN file — season/15585, 20 rows,
    // Barcelona 2.2 rank-1 with the 1.8 Atletico+Real Madrid tie —
    // frozen, the 202 anchor pattern, DISTINCT from the current 4.0.
    // The honest-name contract rides the EXISTING teamFa map (probed:
    // Persepolis/Sepahan/Tractor/Johor all covered — zero new
    // entries). Additive mirror of 245 end-to-end:
    // TeamGoalsPerMatchEntry + the REQUIRED teamGoalsPerMatch field on
    // the mapped payload + getFullTeamGoalsPerMatch
    // (fullTeamGoalsPerMatch:v1, the STANDARD guard — all nine files
    // wide 12-36 rows, NO floor needed) + the team top-3-first merge
    // (dedup by TEAM id, teamGoalsPerMatch DESC, top-10, POSITIONAL
    // re-rank) + standings:v30→v31 (the 52/…/245 additive-shape
    // convention) + the /api/topscorers/[leagueKey] route field + the
    // LeagueScorersData view field + the league-page block «گل به از
    // مسابقهٔ تیم‌ها» placed at the HEAD of the team group (right
    // before گل مورد انتظار تیم‌ها — the raw scoring rate leads, the
    // analytics follow) so the SIX team-side blocks read together while
    // the player→team pair and the keeper QUINTET stay untouched (the
    // older gates' relative-order asserts are index-inequality-based —
    // all re-ran green) — with data-testid=tgm-row.
    const gpmTeamEntries: TeamGoalsPerMatchEntry[] = statTeamCategory(raw, /^goals per match$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamGoalsPerMatch: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamGoalsPerMatch - a.teamGoalsPerMatch || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamGoalsPerMatch = await getFullTeamGoalsPerMatch(leagueKey, requestedSeason);
    const enrichedGpmIds = new Set(gpmTeamEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamGoalsPerMatch = [...gpmTeamEntries, ...fullTeamGoalsPerMatch.filter((r) => r.teamId <= 0 || !enrichedGpmIds.has(r.teamId))]
      .sort((a, b) => b.teamGoalsPerMatch - a.teamGoalsPerMatch || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-247: «کرنرهای تیم‌ها» — the deep-file family's TWENTY-FIFTH
    // sibling and its SEVENTH TEAM-PARTICIPANT member, the team-side corner
    // volume (the raw set-piece attack surface). Straight from the live
    // corner_taken_team.json probe (UA Chrome/124, 2026-10-31,
    // scripts/cycle247-probe.sh + probe2.sh): EIGHT leagues serve — the
    // seven feed leagues plus uel 73 — files WIDE 18-36 rows on all of
    // them (laliga 20 Villarreal 73 / pl 20 Tottenham 52 / seriea 20
    // Juventus 69 / bundesliga 18 Bayern 64 / ligue1 18 Lens 52 / ucl 36
    // Dortmund 27 / uel 36 Olympiacos 28 / portugal 18 Benfica 65), so
    // back on the STANDARD guard (no league-aware floor — the 246 class).
    // persiangulf AND mas honestly absent TWICE OVER (no "Corners" team
    // category in their feeds AND the bare direct files absent — the 241
    // honesty, stronger than the 245 bare-serves class). Integer-valued
    // floats → the 215/220/231/235/236/242/245 integer convention:
    // storage never rounds, the pill renders String(value) dir=ltr (73
    // renders «۷۳»; the frozen 2020/21 file's 224 renders «۲۲۴"). Upstream
    // Rank keeps COMPETITION ties verbatim (laliga (8,8)/(13,13)/(17,17),
    // ucl's dense (7,6)+(8,6)+(20,19)+(21,19) ladder probed); the merge
    // re-ranks POSITIONALLY with the name tiebreak. ParticiantId is
    // ALWAYS 0 (teams carry TeamId, probed Villarreal 10205 / Olympiacos
    // 8638) → dedup by TEAM id. NO badge twin and NO global-merge
    // participation BY DESIGN (the 237 team-surface rule); the block
    // rides the league page only, rows link /team/{teamId} (the
    // standings-view contract), data-testid=tcor-row, the corner-flag
    // glyph, sublabel «حجم حملات — سطح تیم». SEASON-AWARE (the
    // 124/…/246 class): the 2020/21 laliga raw serves its OWN file —
    // season/15585, 20 rows, Real Madrid 224 rank-1 with the 196
    // Atletico+Real Sociedad tie — frozen, DISTINCT from the current 73
    // (probed via the NAME-form season feed, the exact call getLeagueRaw
    // makes; the numeric-form season=15585 feed provably leaks the
    // CURRENT fetchAllUrls — documented in the probe). The honest-name
    // contract rides the EXISTING teamFa map for every CURRENT top-10
    // (70/70 probed, zero new entries) — ONE new entry for the frozen
    // file's rank-3 «Eibar» → «ایبار». Feeds without the team category
    // degrade honestly to []. Additive mirror of 246 end-to-end:
    // TeamCornerEntry + the REQUIRED teamCorners field on the mapped
    // payload + getFullTeamCorners (fullTeamCorners:v1, the STANDARD
    // guard — all eight files wide, NO floor needed) + the team
    // top-3-first merge (dedup by TEAM id, teamCorners DESC, top-10,
    // POSITIONAL re-rank) + standings:v31→v32 (the 52/…/246
    // additive-shape convention) + the /api/topscorers/[leagueKey] route
    // field + the LeagueScorersData view field + the league-page block
    // «کرنرهای تیم‌ها» placed right after گل به از مسابقهٔ تیم‌ها (the raw
    // attack-volume pair reads together: scoring rate, then corners) so
    // the SEVEN team-side blocks read as a family while the player→team
    // pair and the keeper QUINTET stay untouched — the older gates'
    // relative-order asserts are index-inequality-based (all pairwise,
    // zero adjacency) so the insertion provably keeps them green — with
    // data-testid=tcor-row.
    const cornerTeamEntries: TeamCornerEntry[] = statTeamCategory(raw, /^corners$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamCorners: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamCorners - a.teamCorners || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamCorners = await getFullTeamCorners(leagueKey, requestedSeason);
    const enrichedCornerIds = new Set(cornerTeamEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamCorners = [...cornerTeamEntries, ...fullTeamCorners.filter((r) => r.teamId <= 0 || !enrichedCornerIds.has(r.teamId))]
      .sort((a, b) => b.teamCorners - a.teamCorners || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

    // cycle-176: the league's own card leaders ride the mapped payload —
    // getLeagueCardLeaders has been fully built (deep fetchAllUrl files,
    // cycle-127 thin-TTL, freshCardNames) since cycle-50, but its only
    // consumer was the global /topscorers merge; the league page never
    // surfaced them. Live-probed 2026-10-30 UA Chrome/124: pl yellow_card.json
    // = 204 rows / red_card.json = 14 rows; persiangulf = 178/19 with the
    // Persian hook (Alireza Alizadeh, Gol Gohar, 5 yellows); mas carries ONLY
    // the "Red cards" category (yellow legitimately absent). Rows keep the
    // FILE's rank order (no re-sort — same contract the global page renders);
    // limit 15 matches the global merge (the UI slices 5 per kind, the API
    // keeps the depth). Both-empty → block omitted (not {yellow:[],red:[]}).
    // cycle-185: the block follows the requested season — the cycle-132
    // current-season gate is GONE: live-probing the historical raws proved
    // the card files are season-scoped on upstream exactly like the goals
    // (cycle-124) and assists (cycle-175) files (2023/2024 pl raw carries
    // season/20720/yellow_card.json = 438 rows, Palhinha 13 — reachable
    // data the old gate dropped). getLeagueCardLeaders now takes the
    // optional season and getLeagueRaw serves each season's own fetchAllUrl.
    // SEQUENTIAL on purpose (cycle-176 live incident): the first draft
    // Promise.all'd the two kinds and the mas cold build raced the two L2
    // writes — yellow's [] row landed, red's write lost and its rows were
    // silently dropped by the catch-all (cards:mas:red had NO row while
    // the payload shipped without the block). Same discipline as the 175
    // merge: one write at a time. Per-kind catch keeps the documented
    // honesty: one transient failure degrades THAT kind to [] instead of
    // killing the whole block (a season file that upstream truly lacks —
    // if one ever appears — degrades to the both-empty omission).
    const yellow = await getLeagueCardLeaders(leagueKey, "yellow", 15, requestedSeason).catch(() => [] as LeagueCardEntry[]);
    const red = await getLeagueCardLeaders(leagueKey, "red", 15, requestedSeason).catch(() => [] as LeagueCardEntry[]);
    let cards: StandingsData["cards"];
    if (yellow.length > 0 || red.length > 0) cards = { yellow, red };

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
      assists: mergedAssists,
      ratings: mergedRatings,
      cleanSheets: mergedCleanSheets,
      gPlusA: mergedGPlusA,
      goalsPrevented: mergedGoalsPrevented,
      minutes: mergedMinutes,
      savePercentage: mergedSavePercentage,
      savesPer90: mergedSavesPer90,
      penaltySaves: mergedPenaltySaves,
      xg: mergedXg,
      goalsPer90: mergedGoalsPer90,
      xa: mergedXa,
      bigChancesCreated: mergedBigChances,
      xgot: mergedXgot,
      chancesCreated: mergedChancesCreated,
      bigChancesMissed: mergedBigChancesMissed,
      teamXg: mergedTeamXg,
      teamCleanSheets: mergedTeamCleanSheets,
      teamPossession: mergedTeamPossession,
      teamYellowCards: mergedTeamYellowCards,
      teamRedCards: mergedTeamRedCards,
      teamGoalsPerMatch: mergedTeamGoalsPerMatch,
      teamCorners: mergedTeamCorners,
      ...(penaltySavesDropped && mergedPenaltySaves.length > 0 ? { penaltySavesDropped: true } : {}),
      ...(cards ? { cards } : {}),
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
    // cycle-175: v7 — the deep merged assists list (fullAssists merge) forces
    // an immediate clean rebuild instead of serving 3-row assists for up to a
    // full TTL generation (the same reasoning that produced v6 for scorers).
    // cycle-176: v8 — the additive cards block forces the same immediate
    // clean rebuild (old v7 rows lack the block and would keep the section
    // hidden for up to a full TTL generation; the 52/55/90/92/107/175
    // additive-shape convention).
    // cycle-185: v9 — the cards block is now season-aware (the cycle-132
    // historical omission lifted); old v8 HISTORICAL rows lack the block and
    // would keep it hidden for up to a full TTL generation (the current-
    // season rows are byte-identical but share the namespace, so the whole
    // key bumps; the 176 convention repeated verbatim).
    // cycle-196: v10 — the boards catalog grew 6→12 team + 6→12 player
    // kinds (the 92 extraction unchanged); v9 rows carry only the old 12
    // boards and would keep the new 12 hidden for up to a full TTL
    // generation (the L2 survives restarts — probed: boards=12 right after
    // a fresh build). Same shared-namespace rule: the whole key bumps
    // (the 176/185 convention repeated verbatim).
    // cycle-210: v11 — the ratings block («آقای امتیاز») joins the mapped
    // payload as a REQUIRED field; old v10 rows lack it and would keep the
    // new section hidden for up to a full TTL generation. Whole key bumps
    // (the 52/55/90/92/107/175/176/185/196 additive-shape convention).
    // cycle-215: v12 — the clean-sheets block («گل نخرده‌ها») joins the
    // mapped payload as a REQUIRED field; old v11 rows lack it and would
    // keep the new section hidden for up to a full TTL generation. Whole
    // key bumps (the 52/55/90/92/107/175/176/185/196/210 convention).
    // cycle-216: v13 — the G+A block («گل+پاس») joins the mapped payload as
    // a REQUIRED field; old v12 rows lack it and would keep the new section
    // hidden for up to a full TTL generation. Whole key bumps (the
    // 52/55/90/92/107/175/176/185/196/210/215 convention).
    // cycle-217: v14 — the goals-prevented block («گل‌های پیشگیری‌شده»)
    // joins the mapped payload as a REQUIRED field; old v13 rows lack it
    // and would keep the new section hidden for up to a full TTL
    // generation. Whole key bumps (the
    // 52/55/90/92/107/175/176/185/196/210/215/216 convention).
    // cycle-220: v15 — the minutes-played block («بیشترین دقایق») joins the
    // mapped payload as a REQUIRED field; old v14 rows lack it and would
    // keep the new section hidden for up to a full TTL generation. Whole
    // key bumps (the
    // 52/55/90/92/107/175/176/185/196/210/215/216/217 convention).
    // cycle-221: v16 — the save-percentage block («درصد سیو») joins the
    // mapped payload as a REQUIRED field; old v15 rows lack it and would
    // keep the new section hidden for up to a full TTL generation. Whole
    // key bumps (the
    // 52/55/90/92/107/175/176/185/196/210/215/216/217/220 convention).
    // cycle-222: v17 — the saves-per-90 block («سیو در هر ۹۰») joins the
    // mapped payload as a REQUIRED field; old v16 rows lack it and would
    // keep the new section hidden for up to a full TTL generation. Whole
    // key bumps (the
    // 52/55/90/92/107/175/176/185/196/210/215/216/217/220/221 convention).
    // cycle-225: v18 — the penalty-saves block («پنالتی‌های مهارشده») joins
    // the mapped payload as a REQUIRED field; old v17 rows lack it and
    // would keep the new section hidden for up to a full TTL generation.
    // Whole key bumps (the
    // 52/55/90/92/107/175/176/185/196/210/215/216/217/220/221/222
    // convention).
    // cycle-226: v19 — the xG block («گل مورد انتظار») joins the mapped
    // payload as a REQUIRED field; old v18 rows lack it and would keep the
    // new section hidden for up to a full TTL generation. Whole key bumps
    // (the 52/…/225 additive-shape convention).
    // cycle-227: v20 — the goals-per-90 block («گل در هر ۹۰») joins the
    // mapped payload as a REQUIRED field; old v19 rows lack it and would
    // keep the new section hidden for up to a full TTL generation. Whole
    // key bumps (the 52/…/226 additive-shape convention).
    // cycle-230: v21 — the expected-assist block («پاس مورد انتظار»)
    // joins the mapped payload as a REQUIRED field; old v20 rows lack it
    // and would keep the new section hidden for up to a full TTL
    // generation. Whole key bumps (the 52/…/227 additive-shape
    // convention).
    // cycle-231: v22 — the big-chances-created block («سانس بزرگ
    // خلق‌شده») joins the mapped payload as a REQUIRED field; old v21
    // rows lack it and would keep the new section hidden for up to a full
    // TTL generation. Whole key bumps (the 52/…/230 additive-shape
    // convention).
    // cycle-232: v23 — the xGOT block («گل مورد انتظار روی دروازه») joins
    // the mapped payload as a REQUIRED field; old v22 rows lack it and
    // would keep the new section hidden for up to a full TTL generation.
    // Whole key bumps (the 52/…/231 additive-shape convention).
    // cycle-235: v24 — the chances-created block («فرصت‌های خلق‌شده») joins
    // the mapped payload as a REQUIRED field; old v23 rows lack it and
    // would keep the new section hidden for up to a full TTL generation.
    // Whole key bumps (the 52/…/232 additive-shape convention).
    // cycle-236: v25 — the big-chances-missed block («سانس بزرگ
    // ازدست‌رفته») joins the mapped payload as a REQUIRED field; old v24
    // rows lack it and would keep the new section hidden for up to a full
    // TTL generation. Whole key bumps (the 52/…/235 additive-shape
    // convention).
    // cycle-237: v26 — the team-xg block («گل مورد انتظار تیم‌ها») joins
    // the mapped payload as a REQUIRED field; old v25 rows lack it and
    // would keep the new section hidden for up to a full TTL generation.
    // Whole key bumps (the 52/…/236 additive-shape convention).
    // cycle-240: v27 — the team clean-sheets block («گل نخرده‌های
    // تیم‌ها») joins the mapped payload as a REQUIRED field; old v26 rows
    // lack it and would keep the new section hidden for up to a full TTL
    // generation. Whole key bumps (the 52/…/237 additive-shape
    // convention).
    // cycle-241: v28 — the team possession block («مالکیت توپ تیم‌ها»)
    // joins the mapped payload as a REQUIRED field; old v27 rows lack it
    // and would keep the new section hidden for up to a full TTL
    // generation. Whole key bumps (the 52/…/240 additive-shape
    // convention).
    // cycle-242: v29 — the team yellow-cards block («کارت‌های زرد تیم‌ها»)
    // joins the mapped payload as a REQUIRED field; old v28 rows lack it
    // and would keep the new section hidden for up to a full TTL
    // generation. Whole key bumps (the 52/…/241 additive-shape
    // convention).
    // cycle-245: v30 — the team red-cards block («کارت‌های قرمز تیم‌ها»)
    // joins the mapped payload as a REQUIRED field; old v29 rows lack it
    // and would keep the new section hidden for up to a full TTL
    // generation. Whole key bumps (the 52/…/242 additive-shape
    // convention).
    // cycle-246: v31 — the team goals-per-match block («گل به از مسابقهٔ
    // تیم‌ها») joins the mapped payload as a REQUIRED field; old v30
    // rows lack it and would keep the new section hidden for up to a
    // full TTL generation. Whole key bumps (the 52/…/245 additive-shape
    // convention).
    await cached(`standings:v32:${leagueKey}:${season || "cur"}`, (mapped) =>
      // cycle-127 thin-scorers guard (closes the cycle-124 incident class
      // END-TO-END): the merged scorers list rides on this cached entry, so
      // even with the thin-TTL on fullGoals itself a thin merged list would
      // stay visible for a full ttlMinutes generation (the thin fullGoals row
      // expires but nothing re-runs build()). A thin scorers list — dropped
      // goals.json fetch, or a payload without the stats block — now re-probes
      // in 90s (upstream-free: reads the cached leagueRaw); healthy tables
      // keep the exact matchday-aware TTL.
      // cycle-175: the same end-to-end guard now covers thin merged ASSISTS —
      // a league whose assists category exists but whose goal_assist.json
      // fetch was dropped would bake 3-4 rows for a full ttlMinutes
      // generation; re-probe in 90s (upstream-free: leagueRaw is cached and
      // the thin fullAssists row re-probes its own file). Honest-empty feeds
      // (assists == []) keep the normal TTL. Healthy tables keep the exact
      // matchday-aware TTL.
      (Array.isArray(mapped.scorers) && mapped.scorers.length >= FULL_LIST_HEALTHY_MIN) &&
      !(Array.isArray(mapped.assists) && mapped.assists.length > 0 && mapped.assists.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-176: the same end-to-end guard for a thin-but-nonempty YELLOW
      // list — the wide yellow_card.json fetch dropped at build time would
      // bake the 3-4-row category fallback for a full ttlMinutes generation;
      // re-probe in 90s (upstream-free: leagueRaw + the card rows are both
      // cached with their own cycle-127 guards). RED is deliberately
      // unguarded: red files are naturally short (live-probed pl=14,
      // persiangulf=19, mas=8 rows) and early-season reds legitimately sit
      // under 10 — a red guard would re-probe forever. Honest-empty yellow
      // (mas: no category) keeps the normal TTL.
      //
      // cycle-185: the guard now also covers a MISSING cards block — the
      // cycle-185 build-time incident: the SSG cold build raced the card
      // files and baked a card-less CURRENT payload for a full ttlMinutes
      // generation (the v9 purge-retest proved the same build healthy once
      // warm: y15/r14 Janelt). A missing block re-probes in 90s
      // (upstream-free: leagueRaw + card rows are cached with their own
      // guards; a feed with genuinely no card categories just re-scans the
      // cached raw). mas red-only payloads carry the block and keep the
      // normal TTL.
      //
      // cycle-210: the same end-to-end guard for a thin-but-nonempty RATINGS
      // list — the rating.json fetch dropped at build time would bake the
      // 3-row category fallback for a full ttlMinutes generation (probed
      // live: the SSG cold build DID drop it once — direct fetch 331 rows
      // 248ms while the first payload baked 3); re-probe in 90s
      // (upstream-free: leagueRaw + the thin fullRatings row are cached with
      // their own cycle-127 guards). Honest-empty ratings (mas: no category)
      // keep the normal TTL — the same convention as the assists guard.
      (Array.isArray(mapped.scorers) && mapped.scorers.length >= FULL_LIST_HEALTHY_MIN) &&
      !(Array.isArray(mapped.assists) && mapped.assists.length > 0 && mapped.assists.length < FULL_LIST_HEALTHY_MIN) &&
      !(Array.isArray(mapped.ratings) && mapped.ratings.length > 0 && mapped.ratings.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-215: the same end-to-end guard for a thin-but-nonempty
      // CLEAN-SHEET list — the clean_sheet.json fetch dropped at build time
      // would bake the 3-row category fallback for a full ttlMinutes
      // generation (the 210 ratings incident class). The assists-guard
      // precedent applies verbatim: a count-stat that grows through the
      // season is legitimately thin EARLY (matchday 1-4 in a 20-team league
      // sits under 10 rows) and self-heals — the thin row re-probes its own
      // static gzip file after 90s (upstream-free: leagueRaw is cached and
      // the thin fullCleanSheets row re-probes with its own cycle-127
      // guard). Honest-empty feeds (no "Clean sheets" category at all) keep
      // the normal TTL — the same convention as the assists/ratings guards.
      !(Array.isArray(mapped.cleanSheets) && mapped.cleanSheets.length > 0 && mapped.cleanSheets.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-216: the same end-to-end guard for a thin-but-nonempty G+A
      // list — the _goals_and_goal_assist.json fetch dropped at build time
      // would bake the 3-row category fallback for a full ttlMinutes
      // generation (the 210/215 incident class). The assists-guard
      // precedent applies verbatim: a count-stat that grows through the
      // season is legitimately thin EARLY and self-heals — the thin row
      // re-probes its own static gzip file after 90s (upstream-free:
      // leagueRaw is cached and the thin fullGPlusA row re-probes with its
      // own cycle-127 guard). Honest-empty feeds (no "Goals + Assists"
      // category at all) keep the normal TTL — the same convention as the
      // assists/ratings/clean-sheets guards.
      !(Array.isArray(mapped.gPlusA) && mapped.gPlusA.length > 0 && mapped.gPlusA.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-217: the same end-to-end guard for a thin-but-nonempty
      // goals-prevented list — the _goals_prevented.json fetch dropped at
      // build time would bake the 3-row category fallback for a full
      // ttlMinutes generation (the 210/215/216 incident class). The
      // assists-guard precedent applies verbatim: a stat that grows
      // through the season is legitimately thin EARLY and self-heals — the
      // thin row re-probes its own static gzip file after 90s
      // (upstream-free: leagueRaw is cached and the thin fullGoalsPrevented
      // row re-probes with its own cycle-127 guard). Honest-empty feeds
      // (persiangulf: no "Goals prevented" category, probed) keep the
      // normal TTL — the same convention as the assists/ratings/
      // clean-sheets/G+A guards.
      !(Array.isArray(mapped.goalsPrevented) && mapped.goalsPrevented.length > 0 && mapped.goalsPrevented.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-220: the same thin-kept-for-a-generation class closes for the
      // minutes block (the 175/210/215/216/217 guard family grows by one) —
      // a thin merged minutes list re-probes in 90s; honest-empty feeds
      // (no "Minutes played" category) keep the normal TTL.
      !(Array.isArray(mapped.minutes) && mapped.minutes.length > 0 && mapped.minutes.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-221: the same thin-kept-for-a-generation class closes for the
      // save-percentage block (the 175/210/215/216/217/220 guard family
      // grows by one) — a thin merged save-percentage list re-probes in 90s;
      // honest-empty feeds (no "Save percentage" category — persiangulf,
      // probed) keep the normal TTL.
      !(Array.isArray(mapped.savePercentage) && mapped.savePercentage.length > 0 && mapped.savePercentage.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-222: the same thin-kept-for-a-generation class closes for the
      // saves-per-90 block (the 175/210/215/216/217/220/221 guard family
      // grows by one) — a thin merged saves-per-90 list re-probes in 90s;
      // honest-empty feeds (no "Saves per 90" category — persiangulf,
      // probed) keep the normal TTL.
      !(Array.isArray(mapped.savesPer90) && mapped.savesPer90.length > 0 && mapped.savesPer90.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-225: penaltySaves deliberately UNGUARDED by length here (the
      // cycle-176 red-cards precedent — the files are NATURALLY thin
      // FOREVER: 2-5 rows live-probed across all six serving leagues; a <10
      // re-probe guard would re-probe eternally). The dropped-fetch class is
      // instead covered PRECISELY by the penaltySavesDropped marker the
      // build sets when the category exists but the file fetch failed: the
      // payload re-probes in 90s in exactly that case, never on natural
      // thinness. The v18 key bump already forces one clean rebuild.
      !mapped.penaltySavesDropped &&
      // cycle-226: the standard thin-kept-for-a-generation guard closes for
      // the xG block (the 175/210/215/216/217/220/221/222 guard family grows
      // by one) — expected_goals.json is a WIDE file (probed 389/479 rows),
      // so a thin merged xG list means the fetch was dropped; re-probes in
      // 90s. Honest-empty feeds (no "Expected goals (xG)" category —
      // persiangulf, probed) keep the normal TTL.
      !(Array.isArray(mapped.xg) && mapped.xg.length > 0 && mapped.xg.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-227: the standard thin-kept-for-a-generation guard closes for
      // the goals-per-90 block (the 175/210/215/216/217/220/221/222/226
      // guard family grows by one) — goals_per_90.json is a WIDE file
      // (probed 59-240 rows on the 23 serving leagues), so a thin merged
      // list means the fetch was dropped; re-probes in 90s. Honest-empty
      // feeds (no "Goals per 90" category — mas, probed) keep the normal
      // TTL.
      !(Array.isArray(mapped.goalsPer90) && mapped.goalsPer90.length > 0 && mapped.goalsPer90.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-230: the standard thin-kept-for-a-generation guard closes for
      // the expected-assist block (the 175/210/215/216/217/220/221/222/226/
      // 227 guard family grows by one) — expected_assists.json is a WIDE
      // file (probed 152-721 rows on the six serving globalMerge leagues),
      // so a thin merged list means the fetch was dropped (live-proven THIS
      // cycle: the first cold build baked the 3-row category fallback while
      // the direct file held 480 laliga rows); re-probes in 90s.
      // Honest-empty feeds (no "Expected assist (xA)" category —
      // persiangulf AND mas, probed) keep the normal TTL.
      !(Array.isArray(mapped.xa) && mapped.xa.length > 0 && mapped.xa.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-231: the standard thin-kept-for-a-generation guard closes for
      // the big-chances-created block (the 175/210/215/216/217/220/221/222/
      // 226/227/230 guard family grows by one) — big_chances_created.json
      // is a WIDE file (probed 89-339 rows on the 22 serving leagues), so
      // a thin merged list means the fetch was dropped; re-probes in 90s.
      // Honest-empty feeds (no "Big chances created" category —
      // persiangulf AND mas, probed) keep the normal TTL.
      !(Array.isArray(mapped.bigChancesCreated) && mapped.bigChancesCreated.length > 0 && mapped.bigChancesCreated.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-232: the standard thin-kept-for-a-generation guard closes for
      // the xGOT block (the 175/210/215/216/217/220/221/222/226/227/230/231
      // guard family grows by one) — expected_goalsontarget.json is a WIDE
      // file (probed 227-305 rows on the six serving globalMerge leagues),
      // so a thin merged list means the fetch was dropped; re-probes in
      // 90s. Honest-empty feeds (no "Expected goals on target (xGOT)"
      // category — persiangulf AND mas, probed) keep the normal TTL.
      !(Array.isArray(mapped.xgot) && mapped.xgot.length > 0 && mapped.xgot.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-235: the standard thin-kept-for-a-generation guard closes for
      // the chances-created block (the 175/210/215/216/217/220/221/222/
      // 226/227/230/231/232 guard family grows by one) —
      // total_att_assist.json is a WIDE file (probed 304-466 rows on the
      // six serving domestic leagues), so a thin merged list means the
      // fetch was dropped; re-probes in 90s. Honest-empty feeds (no
      // "Chances created" category — persiangulf AND mas, probed) keep
      // the normal TTL.
      !(Array.isArray(mapped.chancesCreated) && mapped.chancesCreated.length > 0 && mapped.chancesCreated.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-236: the standard thin-kept-for-a-generation guard closes for
      // the big-chances-missed block (the 175/210/215/216/217/220/221/222/
      // 226/227/230/231/232/235 guard family grows by one) —
      // big_chance_missed.json is a WIDE file (probed 126-171 rows on the
      // six serving domestic leagues), so a thin merged list means the
      // fetch was dropped; re-probes in 90s. Honest-empty feeds (no "Big
      // chances missed" category — persiangulf AND mas, probed) keep
      // the normal TTL.
      !(Array.isArray(mapped.bigChancesMissed) && mapped.bigChancesMissed.length > 0 && mapped.bigChancesMissed.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-237: the standard thin-kept-for-a-generation guard closes for
      // the team-xg block (the 175/210/215/216/217/220/221/222/226/227/
      // 230/231/232/235/236 guard family grows by one) —
      // expected_goals_team.json is a NATURALLY-THIN-BUT-NEVER-UNDER-THE-
      // FLOOR file (probed 18-36 rows on the six serving domestic
      // leagues), so a thin merged list means the fetch was dropped;
      // re-probes in 90s. Honest-empty feeds (no "Expected goals" TEAM
      // category — persiangulf AND mas, probed) keep the normal TTL.
      !(Array.isArray(mapped.teamXg) && mapped.teamXg.length > 0 && mapped.teamXg.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-240: the team clean-sheets block joins the guard family —
      // clean_sheet_team.json is WIDE on the six domestics (14-20 rows,
      // above the floor) so a thin merged list there means the fetch was
      // dropped → re-probes in 90s. THE MAS FLOOR (league-aware, the 225
      // health-rule class, the 176 red-cards lesson): mas's clean-sheet
      // file is NATURALLY thin — live-probed 2026-10-30 at EIGHT rows
      // (Johor Darul Ta'zim 6.0 rank-1), the file's real size — so the
      // 10-row floor would re-probe mas FOREVER. But mas still needs the
      // dropped-fetch protection: the PROBED first cold build served the
      // podium-only 3 rows for a full generation before the floor was
      // fixed. The mas floor is 4 — STRUCTURAL, not a file-size pin: the
      // podium (participant + topThree) can never exceed 3 rows, so ≥4
      // PROVES the full file arrived while ≤3 always re-probes. mas is
      // globalMerge:false with its own panel; the exemption is
      // league-scoped and documented here.
      !(Array.isArray(mapped.teamCleanSheets) && mapped.teamCleanSheets.length > 0 && mapped.teamCleanSheets.length < (leagueKey === "mas" ? 4 : FULL_LIST_HEALTHY_MIN)) &&
      // cycle-241: the team possession block joins the guard family —
      // possession_percentage_team.json is WIDE (probed 18-36 rows on the
      // six serving domestic leagues), so a thin merged list means the
      // fetch was dropped; re-probes in 90s. Honest-empty feeds (no
      // "Average possession" TEAM category — persiangulf AND mas, the 237
      // absence pair, probed) degrade to [] upstream of the guard and
      // keep the normal TTL — NO league-aware floor needed (unlike the
      // 240 clean-sheet sibling, mas does not serve this category).
      !(Array.isArray(mapped.teamPossession) && mapped.teamPossession.length > 0 && mapped.teamPossession.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-242: the team yellow-cards block joins the guard family —
      // total_yel_card_team.json is WIDE (probed 18-36 rows on the six
      // serving domestic leagues), so a thin merged list means the fetch
      // was dropped; re-probes in 90s. Honest-empty feeds (no "Yellow
      // cards" TEAM category — persiangulf AND mas, the 237/241 absence
      // pair, probed: mas's feed carries FOUR team categories and yellow
      // is not one) degrade to [] upstream of the guard and keep the
      // normal TTL — NO league-aware floor needed (unlike the 240
      // clean-sheet sibling, mas does not serve this category at all).
      !(Array.isArray(mapped.teamYellowCards) && mapped.teamYellowCards.length > 0 && mapped.teamYellowCards.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-245: the team red-cards block joins the guard family — with
      // ONE deliberate difference: total_red_card_team.json is NATURALLY
      // SHORT (probed 4-16 rows on the nine serving leagues — red cards
      // are rare; uel's file is EXACTLY 4 as-found), so the standard <10
      // guard would re-probe forever on four of the nine files (the exact
      // trap the cycle-176 PLAYER-red comment documented). Guard = the
      // 240 mas floor-4 class GENERALIZED league-wide: STRUCTURAL, not a
      // file-size pin — the podium can never exceed 3 rows, so ≥4 PROVES
      // the full file arrived while ≤3 always re-probes. Honest-empty
      // feed (no "Red cards" TEAM category — persiangulf only, probed)
      // degrades to [] upstream of the guard and keeps the normal TTL.
      !(Array.isArray(mapped.teamRedCards) && mapped.teamRedCards.length > 0 && mapped.teamRedCards.length < 4) &&
      // cycle-246: the team goals-per-match block joins the guard family
      // back at the STANDARD <10 threshold — goals_team_match.json is
      // WIDE on every serving league (probed 12-36 rows on all nine,
      // including pg 18 and mas 12), so a thin merged list means the
      // fetch was dropped; re-probes in 90s. Honest-empty feeds (no
      // "Goals per match" TEAM category) degrade to [] upstream of the
      // guard and keep the normal TTL — NO league-aware floor needed
      // (the family's first nine-league surface at the standard guard).
      !(Array.isArray(mapped.teamGoalsPerMatch) && mapped.teamGoalsPerMatch.length > 0 && mapped.teamGoalsPerMatch.length < FULL_LIST_HEALTHY_MIN) &&
      // cycle-247: the team corners block joins the guard family back at
      // the STANDARD <10 threshold — corner_taken_team.json is WIDE on
      // every serving league (probed 18-36 rows on all eight, including
      // uel 36), so a thin merged list means the fetch was dropped;
      // re-probes in 90s. Honest-empty feeds (no "Corners" TEAM category
      // — persiangulf AND mas, both bare-direct-file absent too) degrade
      // to [] upstream of the guard and keep the normal TTL — NO
      // league-aware floor needed.
      !(Array.isArray(mapped.teamCorners) && mapped.teamCorners.length > 0 && mapped.teamCorners.length < FULL_LIST_HEALTHY_MIN) &&
      !(Array.isArray(mapped.cards?.yellow) && mapped.cards.yellow.length > 0 && mapped.cards.yellow.length < FULL_LIST_HEALTHY_MIN) &&
      !!mapped.cards
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
  // cycle-167: honest Persian display name (playerFa hit, else the raw
  // upstream name) — transfers join the same naming contract every other
  // player surface already honors (scorers/squads/search since cycle-107).
  nameFa: string;
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
      nameFa: playerFa(t.name),
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

// cycle-255: identity check alone is NOT enough — cached() persists values to
// the L2 SQLite, and a JSON round-trip re-creates the sentinel as a NEW object
// (proven live: post-restart /api/player/<unknown> answered 502 instead of 404).
// The structural check survives the round-trip for BOTH the player and coach
// read paths.
function isPlayerSentinel(v: unknown): boolean {
  return typeof v === "object" && v !== null && "__remontadaPlayerNotFound" in v;
}

interface FMPlayerInfoEntry {
  title?: string;
  // cycle-255: stable upstream key ("age_sentencecase"/"country_sentencecase")
  // — coach profile reads it for age/country; titles stay unmapped (english)
  translationKey?: string;
  value?: { numberValue?: number; fallback?: unknown; key?: string | null; dateValue?: string } | null;
  icon?: { id?: string } | null;
}
interface FMPlayerDetails {
  id?: number;
  name?: string;
  isCoach?: boolean;
  // cycle-255 probed (UA Chrome/124, 2026-10-31, Xabi Alonso id 30889): the
  // current-bench record block — teamId/teamName/teamColors + matches/wins/
  // draws/losses. Optional: player payloads answer null.
  coachStats?: {
    activeCareerEntry?: {
      teamId?: number; teamName?: string;
      teamColors?: Record<string, string>;
      startDate?: string | null; endDate?: string | null;
      matches?: number; wins?: number; draws?: number; losses?: number;
    } | null;
  } | null;
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
    // cycle-255: "coach" joined the union — playerData serves coaches too and
    // the coach page reads careerItems.coach.teamEntries[] (stints); the
    // player-side senior/youth/national-team reads are untouched.
    careerItems?: Partial<Record<"senior" | "youth" | "national team" | "coach", { teamEntries?: FMCareerEntry[] | null } | null>> | null;
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
  // cycle-201 probed (UA Chrome/124, 2026-10-30): EVERY playerData payload
  // carries `statSeasons` — the player's stat-tracked seasons, newest first,
  // each with the tournaments the player was registered in that season
  // (Yamal n=5, Balde n=6, Fetai n=4, Ćurković n=2). Each tournament row is
  // registration metadata only: name + tournamentId (catalog-mappable) +
  // entryId/hasDeepStats (per-season stat-table pointers — deliberately
  // unmapped: display is registration-only). The portal drops the whole
  // block today; the mapping rides the ONE already-cached raw fetch.
  statSeasons?: {
    seasonName?: string;
    tournaments?: { name?: string; tournamentId?: number; entryId?: string; hasDeepStats?: boolean }[] | null;
  }[] | null;
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
  // cycle-197 probed (UA Chrome/124, 4 anchors: star Raphinha / non-star Lulli
  // / fold-king Fetai / pool-star Gyokeres): EVERY playerData payload carries
  // `relatedLinksData` — the current club squad (`teammates`) and the
  // national-team squads (`mensNationalTeam` + empty-on-all-probes
  // `womensNationalTeam`) as flat {id, name} rows. 23-30 club / 27-35 NT rows
  // per player, ZERO malformed rows, the player himself never in his own
  // lists, zero duplicate ids, zero upstream-Persian names. The block had
  // ZERO usage in src/ before this cycle (grep-verified) — the profile had no
  // squad-navigation surface at all.
  relatedLinksData?: {
    teammates?: { id?: number; name?: string }[] | null;
    mensNationalTeam?: { id?: number; name?: string }[] | null;
    womensNationalTeam?: { id?: number; name?: string }[] | null;
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
  // cycle-197: squad-navigation rows off the SAME cached playerData payload
  // (zero extra upstream fetch). ALWAYS present after the v8 bump — empty
  // arrays when upstream lacks the block (the section hides, honest absence).
  // nameFa derives via playerFa (the 104 map); unmapped rows stay honest
  // Latin (the 92/107 contract). Row guards: id>0 (the 167 lesson), non-empty
  // name, per-list seen-set dedupe; nationalTeammates = mens + womens merged
  // (a player belongs to one NT context; mens first).
  teammates: PlayerLinkRow[];
  nationalTeammates: PlayerLinkRow[];
  // cycle-201: per-season competition registrations off the SAME cached
  // playerData payload (zero extra upstream fetch — the statSeasons block
  // rides the one raw fetch). OPTIONAL by contract — v8-cached snapshots
  // legitimately lack it → the section hides (the cards/market honesty
  // pattern). Always present after the v9 bump — empty array when upstream
  // lacks the block (honest absence, the section hides).
  statSeasons: PlayerStatSeason[];
  fetchedAt: string;
}

export interface PlayerLinkRow {
  id: number;      // FotMob player id → /player/[id] (the 172 family)
  name: string;    // raw upstream name (Latin)
  nameFa: string;  // curated Persian when the 104 map hits, else the raw name
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

// cycle-201: one stat-tracked season of the player («رقابت‌های هر فصل» on the
// profile). tournaments = the competitions the player was REGISTERED in that
// season — the honest statSeasons block, zero extra upstream fetch.
export interface PlayerStatSeasonTournament {
  name: string;       // raw upstream tournament name (Latin, honest fallback)
  nameFa: string;     // leagueFaById resolution — catalog faName → competitionFa map → raw name
  leagueKey?: string; // catalog league key → real /league/{key} link; absent = honest text chip
}
export interface PlayerStatSeason {
  season: string; // raw upstream season name ("2024/2025")
  tournaments: PlayerStatSeasonTournament[];
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

  // cycle-201: per-season competition registrations («رقابت‌های هر فصل») from
  // the SAME raw payload — newest first, season label + tournament chips.
  // nameFa/leagueKey resolve through leagueFaById / the LEAGUES catalog
  // (fotmobId hit → real /league/{key} link, else competitionFa, else the
  // honest raw name). Guards: non-empty seasonName, non-empty tournament
  // name, per-season seen-set dedupe (the 197 lesson), caps 8 seasons × 10
  // tournaments (upstream serves ≤6/≤5 on all live probes — defensive only).
  const statSeasons: PlayerStatSeason[] = [];
  for (const ss of (raw.statSeasons || []).slice(0, 8)) {
    const seasonName = (ss?.seasonName || "").trim();
    if (!seasonName) continue;
    const seenT = new Set<string>();
    const tournaments: PlayerStatSeasonTournament[] = [];
    for (const t of (ss.tournaments || []).slice(0, 10)) {
      const name = (t?.name || "").trim();
      if (!name) continue;
      const tid = typeof t.tournamentId === "number" ? t.tournamentId : undefined;
      const dk = `${name.toLowerCase()}|${tid ?? ""}`;
      if (seenT.has(dk)) continue;
      seenT.add(dk);
      const cat = tid ? LEAGUES.find((l) => l.fotmobId === tid) : undefined;
      tournaments.push({
        name,
        nameFa: leagueFaById(tid, name),
        ...(cat ? { leagueKey: cat.key } : {}),
      });
    }
    if (tournaments.length > 0) statSeasons.push({ season: seasonName, tournaments });
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
    statSeasons,
    ...buildRelatedLinks(raw, id),
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

// ---------------- cycle-197: squad navigation (teammates + NT squad-mates) ----------------
// Flat {id, name} rows → guarded PlayerLinkRow[]: id>0 (the 167 lesson —
// every rendered id must serve a real profile), non-empty trimmed name,
// per-list seen-set dedupe. The player himself never appears (probed), but
// the guard is cheap so it rides here too. nameFa resolves through playerFa
// at normalize time (the 104/189 map — the same normalize-time convention
// as career/recentTeams rows; a curated-map addition reaches these rows on
// the row's own 10-min TTL, the root-h1 read-time freshening stays 189-only).
function buildLinkRows(rows: { id?: number; name?: string }[] | null | undefined, selfId: string): PlayerLinkRow[] {
  const seen = new Set<number>();
  const out: PlayerLinkRow[] = [];
  for (const r of Array.isArray(rows) ? rows : []) {
    const id = typeof r?.id === "number" ? r.id : 0;
    const name = (r?.name || "").trim();
    if (id <= 0 || !name || String(id) === selfId || seen.has(id)) continue;
    seen.add(id);
    out.push({ id, name, nameFa: playerFa(name) });
  }
  return out;
}

function buildRelatedLinks(raw: FMPlayerDetails, selfId: string): { teammates: PlayerLinkRow[]; nationalTeammates: PlayerLinkRow[] } {
  const rl = raw.relatedLinksData || {};
  const mens = buildLinkRows(rl.mensNationalTeam, selfId);
  const womens = buildLinkRows(rl.womensNationalTeam, selfId);
  return {
    teammates: buildLinkRows(rl.teammates, selfId),
    nationalTeammates: [...mens, ...womens],
  };
}

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
  // cycle-197: key bumped to v8 — normalized output gained the required
  // teammates/nationalTeammates navigation rows; a v7-cached shape would
  // serve profiles WITHOUT the block from the persistent SQLite L2 across
  // restarts (the 196 standings:v10 lesson re-proven) for up to the TTL
  // (same convention as cycle-52/86/87/96/135/159)
  // cycle-201: key bumped to v9 — normalized output gained the required
  // statSeasons rows («رقابت‌های هر فصل»); a v8-cached shape would serve
  // profiles WITHOUT the block from the persistent SQLite L2 across restarts
  // for up to the TTL (same convention as cycle-52/86/87/96/135/159/197)
  const payload = await cached(`player:v9:${id}`, 10 * 60_000, async (): Promise<PlayerData | typeof PLAYER_NOT_FOUND> => {
    const raw = await fetchJson<FMPlayerDetails>(`https://www.fotmob.com/api/data/playerData?id=${id}`, 9000);
    if (!raw || typeof raw !== "object" || (raw as { error?: unknown }).error === true) return PLAYER_NOT_FOUND;
    if (!raw.name || !raw.id) return PLAYER_NOT_FOUND;
    return normalizePlayer(raw, id);
  });
  if (payload === PLAYER_NOT_FOUND || isPlayerSentinel(payload) || !payload || typeof payload !== "object") {
    throw new PlayerNotFoundError(`player ${id} not found`);
  }
  // cycle-189: the root nameFa is a single playerFa(raw.name) call — re-apply
  // it on every read (the cycle-109 read-time freshening convention,
  // idempotent: an already-Persian string never matches the English-keyed
  // map and falls back to itself). A curated-map addition reaches the
  // profile h1/metadata immediately instead of waiting out the 10-min
  // player:v7 L2 TTL (seen live this cycle: the fix's own gate caught the
  // pre-fix probes' Latin nameFa still baked in the persistent L2 while a
  // row whose TTL had expired already rendered Persian). The deeper fa
  // fields (positions/career/injury labels) keep the 135/159 namespace-bump
  // convention — those need whole-shape changes, this one does not.
  const p = payload as PlayerData;
  return { ...p, nameFa: playerFa(p.name) };
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
  xa?: number;
  bigChances?: number;
  xgot?: number;   // cycle-232 additive: the xGOT badge twin (one decimal, the 226/230 convention)
  chancesCreated?: number; // cycle-235 additive: the total-creation volume badge twin (integer, the 215 convention)
  bigChancesMissed?: number; // cycle-236 additive: the missed-volume badge twin (integer, the 215 convention)
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

/** cycle-176: the per-league card row exactly as getLeagueCardLeaders maps
 *  it (rank/leagueKey/leagueFa are the GLOBAL merge's dense decorations and
 *  are meaningless inside one league's payload). Same shape the league page
 *  renders — name/nameFa/team for the honest display, playerId for the
 *  170/174 link contract, value = card count. */
export type LeagueCardEntry = Omit<GlobalCard, "rank" | "leagueKey" | "leagueFa">;

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
          ...(s.xa != null ? { xa: s.xa } : {}),
          ...(s.bigChances != null ? { bigChances: s.bigChances } : {}),
          ...(s.xgot != null ? { xgot: s.xgot } : {}),
          ...(s.chancesCreated != null ? { chancesCreated: s.chancesCreated } : {}),
          ...(s.bigChancesMissed != null ? { bigChancesMissed: s.bigChancesMissed } : {}),
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
  // cycle-186: the cycle-132 current-season gate is GONE — the rule is
  // retired END-TO-END. Cycle-185 made the per-league card files
  // season-aware (the third season-blind fetch joined its 124/175 sisters)
  // and documented the global-merge boundary as the declared remainder;
  // this lift closes it. Historical merges now aggregate each season's
  // own card kings exactly like the scorers/assists merges above; a
  // failure still degrades honestly (cards stay undefined, the UI hides
  // the section, the table itself is untouched — and a season with no
  // card files at all, like 2013/2014, stays an honest omission).
  let cards: GlobalCardsData | undefined;
  try {
    const merged_cards = await getAllCardLeaders(season);
    // the 176 contract verbatim: both-empty → block omitted, never
    // {yellow:[],red:[]} — an offered-but-dataless season (2013/2014) keeps
    // its byte-honest "no cards key" shape instead of a fake empty block
    if ((merged_cards.yellow || []).length > 0 || (merged_cards.red || []).length > 0) {
      cards = merged_cards;
    }
  } catch {
    // cards stay undefined — the UI hides the section, the table itself is untouched
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
 *
 * cycle-186: season-aware — the merge side of the 185 move. The optional
 * season threads into every per-league getLeagueCardLeaders call (whose
 * cache keys already carry the season segment — no new namespace needed);
 * the current-season call is byte-identical (`cur` segment). Same
 * merge-exemption (globalMerge: false) and domestic-first attribution as
 * the cycle-50 current-season merge.
 */
export async function getAllCardLeaders(season?: string): Promise<GlobalCardsData> {
  // cycle-140: same merge-exemption as the scorers race (globalMerge: false)
  // — one flag, one semantic: the /topscorers page shows one participant set,
  // never a 9th competition in the cards section while the race says 8.
  const ordered = [...LEAGUES].filter((lg) => lg.globalMerge !== false).sort((a, b) => (a.key === "ucl" ? 1 : 0) - (b.key === "ucl" ? 1 : 0));
  const jobs = ordered.flatMap((lg) =>
    (["yellow", "red"] as const).map(async (kind) => ({
      lg,
      kind,
      rows: await getLeagueCardLeaders(lg.key, kind, 15, season),
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

/** Normalize a search query / team name: lowercase, strip ZWNJ/diacritics, unify Arabic→Persian chars.
 *  fix cycle-169: Latin diacritics now fold to base letters (ń→n, á→a, ç→c) so a plain-Latin
 *  keyboard query («Poznan», «Sanchez») matches the accented feed names («Lech Poznań»,
 *  «Jordi Sánchez») — probed live 2026-10-30: BOTH returned 0 hits before this fold while the
 *  accented spellings hit. The query AND every haystack (aliases/name/fa) pass through here,
 *  so one fold repairs both sides at once (the cycle-149 separator lesson). Persian/Arabic
 *  characters have no canonical decomposition — NFD is a no-op for them, so the existing
 *  matches (case/ZWNJ/ي→ی/ك→ک) behave byte-identically. */
export function normalizeQuery(q: string): string {
  return (q || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
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

let teamIndexCache: { at: number; data: TeamIndexEntry[]; full: boolean } | null = null;
let teamIndexLastGood: TeamIndexEntry[] | null = null;

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

/** Flat index of every team in our 8 league/cup standings (getStandings is cached, so this is cheap).
 *  cycle-169 hardening (live-observed 2026-10-30): a cold sweep can drop some upstream feeds
 *  (Promise.allSettled swallows) — a PARTIAL index (e.g. poland/bundesliga teams missing) was
 *  cached for the full 10-min TTL and /api/search answered 0 for «Poznań» for minutes while
 *  the teams existed upstream. Now: a FULL sweep caches 10 min as before; a PARTIAL sweep
 *  serves the last good index when one exists (stale-but-complete beats fresh-but-partial)
 *  and is itself cached only 30s so a retry comes soon instead of 10 minutes later. */
export async function getTeamIndex(): Promise<TeamIndexEntry[]> {
  if (teamIndexCache) {
    const ttl = teamIndexCache.full ? 10 * 60_000 : 30_000;
    if (Date.now() - teamIndexCache.at < ttl) return teamIndexCache.data;
  }
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
  // cycle-195: the daily feed's teams join the index — the portal tables plus
  // the 79 fallbacks cover ~500 sides while the ALREADY-cached matches feed
  // (probe 2026-10-30: 94 competitions, 340 unique teams today) carries every
  // OTHER team on FotMob — MLS, Brasileirão Série B, Thai League 2, women's
  // cups, national sides — with id/name/fa(TEAM_FA-mapped)/logo and a Persian
  // competition label from its group. That day's probe: 37 of 40 sampled
  // out-of-portal teams answered ZERO to /api/search while /team/{id} and
  // /api/team/{id} fully serve them (HTTP 200 — no dead links, the 167
  // lesson). The seen-set keeps portal rows first (they carry rank/pts);
  // feed teams backfill with rank 0 (the no-hint convention) and their
  // group's leagueFa. ZERO extra upstream fetches — the today feed rides its
  // own 45s cache and every index rebuild re-uses it. Feed teams are a
  // DAILY BONUS by design: they stay searchable while they play (the
  // standings index remains the stable core) — a feed failure must never
  // take the core index down, hence the try/catch.
  try {
    const feed = await getMatchesByDate(todayInTehran());
    for (const g of feed.groups || []) {
      for (const m of g.matches || []) {
        for (const side of [m.home, m.away]) {
          if (!side || side.id == null || side.id <= 0 || seen.has(side.id)) continue;
          seen.add(side.id);
          out.push({
            teamId: side.id,
            name: side.name,
            fa: side.fa || side.name,
            logo: side.logo || fotmobTeamLogo(side.id),
            leagueKey: `feed-${g.leagueId}`,
            leagueFa: g.leagueFa || g.leagueName || "",
            rank: 0,
            pts: 0,
            aliases: `${side.name} ${side.fa || ""}`,
          });
        }
      }
    }
  } catch {
    // feed fold is a bonus: a feed failure leaves the standings index intact
  }
  const failed = settled.filter((r) => r.status !== "fulfilled").length;
  const full = failed === 0;
  if (full) teamIndexLastGood = out;
  teamIndexCache = { at: Date.now(), data: out, full };
  if (!full && teamIndexLastGood && teamIndexLastGood.length > out.length) {
    return teamIndexLastGood; // fresh-but-partial: the stale complete index wins
  }
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
 *  in the ORIGINAL string so the client can highlight without index drift.
 *  cycle-202: exported — searchNews (src/lib/news.ts) reuses the exact
 *  highlight mechanics so both alphabets highlight identically. */
export function rangeOf(display: string, nq: string): [number, number] | null {
  if (!display || !nq) return null;
  const chars: string[] = [];
  const map: number[] = [];
  for (let i = 0; i < display.length; i++) {
    const cp = display.charCodeAt(i);
    if (cp === 0x200c || cp === 0x200e || cp === 0x200f || cp === 0x0640 || (cp >= 0x064b && cp <= 0x0652)) continue;
    // fix cycle-169: an already-decomposed (NFD) display keeps the combining
    // mark in its OWN code unit — skip it so the folded haystack stays aligned
    // (the base char was pushed at its own index one iteration earlier)
    if (cp >= 0x0300 && cp <= 0x036f) continue;
    let c = display[i].toLowerCase();
    if (c === "ي") c = "ی";
    else if (c === "ك") c = "ک";
    // fix cycle-149: fold separators here too so the highlight range stays
    // consistent with the folded matcher (map indices stay display-correct)
    else if (c === "-" || c === "_") c = " ";
    else {
      // fix cycle-169: precomposed (NFC) Latin diacritics fold to their base
      // letter (ń→n, á→a) — one base char maps to ONE original index, so the
      // highlight range lands on the ACCENTED original text (e.g. «Sánchez»
      // highlights [6,13) exactly), never drifting into the mark
      const d = c.normalize("NFD");
      if (d.length > 1) c = d[0];
    }
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
  // update cycle-252: same cross-league tie-break fix as the player search
  // below — the U18 squad's table rank 1 outranked the senior side's PL
  // rank 1; feed-depot entries (leagueKey «feed-…») demote below catalogued
  // leagues so the senior team answers first.
  const feedDep = (e: TeamIndexEntry) => (e.leagueKey?.startsWith("feed-") ? 1 : 0);
  scored.sort((a, b) => b.score - a.score || feedDep(a.e) - feedDep(b.e) || a.e.rank - b.e.rank);
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

// ---------------- FotMob: player search index (cycle-166, +assists cycle-171, +family cycle-224) ----------------
// The header search covered TEAMS only (the team index from standings rows)
// while every league's standings payload ALSO carries a 20-scorer block that
// getTeamIndex discarded — so the searchable player pool (460 «آقای گل» rows
// incl. the Iranian hooks صیادمنش/زاهدی) rides the SAME getStandings calls,
// ZERO extra upstream fetches. cycle-171 folds the SAME payload's assists
// block («بهترین پاس‌دهندگان», the cycle-170 surface) into the pool — the
// Dybala/Rice/Zaccagni class of creators is searchable now. cycle-177 folds
// the cards, cycle-194 the historical kings, and cycle-224 folds the WHOLE
// deep-file family (ratings/cleanSheets/gPlusA/goalsPrevented/minutes/
// savePercentage/savesPer90) — keepers and presence kings searchable too.
// Keys/aliases ride PLAYER_NAME_FA through the standings mapper, so Persian
// queries («صیادمنش») match by design.
export interface PlayerIndexEntry {
  playerId: number;
  name: string; // honest upstream English name
  fa: string; // Persian display (PLAYER_NAME_FA hit or honest fallback)
  teamFa?: string;
  teamId?: number;
  leagueKey: string;
  leagueFa: string;
  goals?: number;
  rank: number; // scorer rank inside the league block (ordering hint)
  season?: string; // cycle-194 additive: historical fold rows carry their
  // finished season (the UI renders «۲۰۲۴/۲۰۲۵» after the league name);
  // current-season rows omit it — the field only exists on the folds
}

export interface PlayerSearchResult extends PlayerIndexEntry {
  matchedOn: string;
  hl?: { fa?: [number, number] | null; name?: [number, number] | null };
}

// cycle-194: the five historical-only card kings join the search pool as
// ZERO-fetch static fold rows — the open half of the cycle-188 honest
// observation (cycle-189 closed the nameFa half; the searchability half
// lands here). Their rows never ride a CURRENT standings payload (probe
// 2026-10-30: all five absent from every current sweep, P4), and finished
// seasons are immutable, so the bytes below are pinned from the live
// historical payloads (scripts/cycle194-probe.py, per-league کارت‌ها
// blocks): Alejo laliga 2023/2024 yellow 17 «کادیز»؛ Downes pl 2024/2025
// yellow 12 «ساوتهمپتون»؛ Fetai hnl 2024/2025 yellow 14 «لوکوموتیوا»؛
// Van der Bruggen belgium 2023/2024 yellow 12 «سرکل بروژ»؛ Radakovic
// superlig 2024/2025 red 4 «سیواس‌اسپور» (the standings row spells him
// ASCII — the profile's diacritic spelling has its own map key, the 189
// lesson). fa rides playerFa (the 104 map contract — the 189 keys), so a
// future map edit reaches the folds too; rank 0 = the no-hint convention;
// goals stays UNDEFINED — these are CARD counts, carrying them as goals
// would be a lie. The UI season hint (search-box) is the honest tell that
// a fold row is a finished-season king, not a current-race row.
const HISTORICAL_KING_FOLDS: PlayerIndexEntry[] = (
  [
    [640089, "Iván Alejo", "کادیز", 8385, "laliga", "2023/2024"],
    [844943, "Flynn Downes", "ساوتهمپتون", 8466, "pl", "2024/2025"],
    [1516458, "Feta Fetai", "لوکوموتیوا", 175388, "hnl", "2024/2025"],
    [232299, "Hannes van der Bruggen", "سرکل بروژ", 9984, "belgium", "2023/2024"],
    [364855, "Uros Radakovic", "سیواس‌اسپور", 6265, "superlig", "2024/2025"],
  ] as const
).map(([playerId, name, teamFa, teamId, leagueKey, season]) => ({
  playerId,
  name,
  fa: playerFa(name),
  teamFa,
  teamId,
  leagueKey,
  leagueFa: LEAGUES.find((l) => l.key === leagueKey)?.faName || leagueKey,
  rank: 0,
  season,
}));

let playerIndexCache: { at: number; data: PlayerIndexEntry[]; full: boolean } | null = null;
let playerIndexLastGood: PlayerIndexEntry[] | null = null;

export async function getPlayerIndex(): Promise<PlayerIndexEntry[]> {
  // cycle-169 hardening: same partial-sweep rule as getTeamIndex — a full sweep
  // caches 10 min, a partial one serves the last good index and caches only 30s
  if (playerIndexCache) {
    const ttl = playerIndexCache.full ? 10 * 60_000 : 30_000;
    if (Date.now() - playerIndexCache.at < ttl) return playerIndexCache.data;
  }
  const ordered = [...LEAGUES].sort((a, b) => {
    const rank = (k: string) => (k === "ucl" ? 1 : 0);
    return rank(a.key) - rank(b.key);
  });
  const settled = await Promise.allSettled(ordered.map((lg) => getStandings(lg.key)));
  const out: PlayerIndexEntry[] = [];
  const seen = new Set<number>();
  settled.forEach((r, i) => {
    const lg = ordered[i];
    if (r.status !== "fulfilled") return;
    for (const s of r.value.scorers || []) {
      if (s.playerId == null || seen.has(s.playerId)) continue;
      seen.add(s.playerId);
      out.push({
        playerId: s.playerId,
        name: s.name,
        fa: s.nameFa || s.name,
        teamFa: s.team || undefined,
        teamId: s.teamId ?? undefined,
        leagueKey: lg.key,
        leagueFa: lg.faName,
        goals: s.goals ?? undefined,
        rank: s.rank ?? 0,
      });
    }
    // cycle-171: the «بهترین پاس‌دهندگان» block rides the SAME payload (the
    // cycle-170 surface) — assist kings who are not top-20 scorers (live probe
    // 2026-10-30: 16 of 27 across 9 leagues — Dybala/Rice/Zaccagni…) were
    // unsearchable while their rows sit in the very same cached standings
    // answer. ZERO extra upstream fetches: fold them after the scorers; the
    // seen-set keeps a dual-listed player once (as the scorer row). The
    // playerId<=0 guard mirrors the 167 transfer lesson (a dead id would
    // dead-end the /player link network).
    for (const a of r.value.assists || []) {
      if (a.playerId == null || a.playerId <= 0 || seen.has(a.playerId)) continue;
      seen.add(a.playerId);
      out.push({
        playerId: a.playerId,
        name: a.name,
        fa: a.nameFa || a.name,
        teamFa: a.team || undefined,
        teamId: a.teamId ?? undefined,
        leagueKey: lg.key,
        leagueFa: lg.faName,
        rank: a.rank ?? 0,
      });
    }
    // cycle-177: the «کارت‌ها» block (the cycle-176 surface) rides the SAME
    // payload — card kings who are neither top-20 scorers nor assist leaders
    // (live probe 2026-10-30: Janelt 688273 = the pl yellow leader returned
    // ZERO rows for q=Janelt/q=یانلت while his row sat in the very same
    // cached standings answer; Alizadeh 900771 persiangulf yellow; mas red =
    // Fazly Mazlan 694010) were unsearchable. ZERO extra upstream fetches:
    // fold yellow then red after the assists; the seen-set keeps a
    // dual-listed player once (as the scorer/assist row). playerId is
    // OPTIONAL on card rows (GlobalCard.playerId?) → the null/<=0 guard is
    // mandatory here, not just hygiene (the 167 dead-id lesson). Card rows
    // carry no rank (LeagueCardEntry = Omit<GlobalCard, "rank"|"leagueKey"|
    // "leagueFa">) and no goals → rank 0 (the no-hint convention) and no
    // goals field, same as the 171 assists fold.
    for (const kind of [r.value.cards?.yellow, r.value.cards?.red]) {
      for (const c of kind || []) {
        if (c.playerId == null || c.playerId <= 0 || seen.has(c.playerId)) continue;
        seen.add(c.playerId);
        out.push({
          playerId: c.playerId,
          name: c.name,
          fa: c.nameFa || c.name,
          teamFa: c.team || undefined,
          teamId: c.teamId ?? undefined,
          leagueKey: lg.key,
          leagueFa: lg.faName,
          rank: 0,
        });
      }
    }
    // cycle-224: the deep-file family joins the pool — the 223 hunt's ONE
    // registered finding. SEVEN more blocks (ratings 210 / cleanSheets 215 /
    // gPlusA 216 / goalsPrevented 217 / minutes 220 / savePercentage 221 /
    // savesPer90 222) ride the VERY SAME cached getStandings payload the
    // scorers/assists/cards folds read — yet the pool never folded them, so
    // keeper and rating/presence kings who appear on no goals/assists/card
    // list were unsearchable while their profile pages were live (probe
    // 2026-10-30: «والس» = the laliga saves-per-90 rank-1 with the profile at
    // /player/999171, «رادو» = the save-percentage rank-1 and «موریچ» = the
    // seriea sp90 rank-1 all returned players=0 from /api/search while the
    // controls صیادمنش/امباپه hit — exactly the cycle-177 Janelt class, ×7
    // blocks ≈ hundreds of unsearchable rows). ZERO extra upstream fetches:
    // fold all seven blocks after the cards (the 171/177 pattern); the
    // seen-set keeps a dual-listed player once, as the highest-priority row
    // above (a scorer row with its goals hint wins over the same player's
    // rating row). The playerId null/<=0 guard is MANDATORY — playerId is
    // OPTIONAL on every family entry (the 167 dead-id lesson). Goals stay
    // UNDEFINED: these are ratings/counts/minutes/percentages — carrying
    // them as goals would be a lie (the 194 convention). rank rides the
    // block's positional top-10 rank (the ordering hint).
    const deepFamilyBlocks: {
      rank: number;
      name: string;
      nameFa?: string;
      team: string;
      teamId: number;
      playerId?: number;
    }[][] = [
      r.value.ratings || [],
      r.value.cleanSheets || [],
      r.value.gPlusA || [],
      r.value.goalsPrevented || [],
      r.value.minutes || [],
      r.value.savePercentage || [],
      r.value.savesPer90 || [],
      // cycle-225: the family's ELEVENTH sibling joins the 224 fold chain —
      // penalty-saves kings (Turati/Vallés/Hein…) searchable too, zero fetch.
      r.value.penaltySaves || [],
      // cycle-226: the TWELFTH sibling joins the fold chain — the xG kings
      // (the analytics surface) searchable too, zero fetch.
      r.value.xg || [],
      // cycle-227: the THIRTEENTH sibling joins the fold chain — the
      // goals-per-90 rate kings searchable too, zero fetch (the Persian
      // Gulf's own Shahriari/Taheri included — the first deep sibling
      // besides minutes whose block feeds the home-league search).
      r.value.goalsPer90 || [],
    ];
    for (const block of deepFamilyBlocks) {
      for (const row of block) {
        if (row.playerId == null || row.playerId <= 0 || seen.has(row.playerId)) continue;
        seen.add(row.playerId);
        out.push({
          playerId: row.playerId,
          name: row.name,
          fa: row.nameFa || row.name,
          teamFa: row.team || undefined,
          teamId: row.teamId,
          leagueKey: lg.key,
          leagueFa: lg.faName,
          rank: row.rank ?? 0,
        });
      }
    }
  });
  // cycle-194: fold the historical-only kings AFTER the sweep — the seen-set
  // (live rows first) means a king who ever re-enters a current payload
  // stays single-listed as that live row; the static folds only backfill the
  // gaps. ZERO extra upstream fetches — pinned immutable bytes of finished
  // seasons (see HISTORICAL_KING_FOLDS above).
  for (const k of HISTORICAL_KING_FOLDS) {
    if (seen.has(k.playerId)) continue;
    seen.add(k.playerId);
    out.push(k);
  }
  const failed = settled.filter((r) => r.status !== "fulfilled").length;
  const full = failed === 0;
  if (full) playerIndexLastGood = out;
  playerIndexCache = { at: Date.now(), data: out, full };
  if (!full && playerIndexLastGood && playerIndexLastGood.length > out.length) {
    return playerIndexLastGood; // fresh-but-partial: the stale complete index wins
  }
  return out;
}

export async function searchPlayers(q: string, limit = 6): Promise<PlayerSearchResult[]> {
  const nq = normalizeQuery(q);
  if (nq.length < 2) return [];
  const index = await getPlayerIndex();
  const scored: { e: PlayerIndexEntry; score: number; matchedOn: string }[] = [];
  for (const e of index) {
    const hay = normalizeQuery(`${e.name} ${e.fa}`);
    let score = -1;
    let matchedOn = e.fa || e.name;
    if (hay === nq) { score = 100; }
    else if (hay.startsWith(nq)) { score = 80; matchedOn = e.fa || e.name; }
    else if (hay.includes(nq)) { score = 50; }
    else {
      const words = nq.split(" ");
      if (words.length > 1 && words.every((w) => hay.includes(w))) { score = 40; }
    }
    if (score > 0) scored.push({ e, score, matchedOn });
  }
  // update cycle-252: the rank tie-break was cross-league and lost sight of
  // seniority — «Chelsea» returned Chelsea U18 first because both entries
  // scored 80 (aliases start with the query) and the youth side's rank 0 in
  // its U18 table beat the senior side's rank 1 in the PL table. League
  // ranks are only comparable inside one league, so non-catalogued feeds
  // (leagueKey «feed-…»: U18/development/qualifying squads) now sort after
  // every catalogued league before rank is consulted. Zero upstream cost.
  const feedDep = (e: PlayerIndexEntry) => (e.leagueKey?.startsWith("feed-") ? 1 : 0);
  scored.sort((a, b) => b.score - a.score || feedDep(a.e) - feedDep(b.e) || a.e.rank - b.e.rank);
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

// ---------------- FotMob: competition search (cycle-200) ----------------
/** cycle-200 additive: the 24-league catalog joins the header search —
 *  probed live (2026-10-30, UA Chrome/124): «لالیگا»/«پریمیرلیگ»/LaLiga/
 *  Bundesliga all answered ZERO rows while every catalog league has a live
 *  /league/{key} page and the bilingual catalog (faName/enName) already
 *  sits in src/lib/leagues.ts. ZERO upstream fetches — the index IS the
 *  catalog. Same matching mechanics as searchPlayers (normalizeQuery on
 *  both sides, exact > prefix > includes > all-words, rangeOf highlight
 *  spans), ties broken by the catalog's own priority. The answer rides a
 *  NEW `leagues` field on /api/search (the cycle-166 additive-field
 *  precedent — existing clients reading results/players stay untouched). */
export interface LeagueSearchResult {
  key: string;
  fa: string;
  en: string;
  leagueId: number;
  matchedOn: string;
  hl?: { fa: [number, number] | null; en: [number, number] | null };
}

export function searchLeagues(q: string, limit = 3): LeagueSearchResult[] {
  const nq = normalizeQuery(q);
  if (nq.length < 2) return [];
  const scored: { lg: (typeof LEAGUES)[number]; score: number }[] = [];
  for (const lg of LEAGUES) {
    const hay = normalizeQuery(`${lg.faName} ${lg.enName}`);
    let score = -1;
    if (hay === nq) score = 100;
    else if (hay.startsWith(nq)) score = 80;
    else if (hay.includes(nq)) score = 50;
    else {
      const words = nq.split(" ");
      if (words.length > 1 && words.every((w) => hay.includes(w))) score = 40;
    }
    if (score > 0) scored.push({ lg, score });
  }
  scored.sort((a, b) => b.score - a.score || a.lg.priority - b.lg.priority);
  return scored.slice(0, limit).map(({ lg }) => {
    const faRange = rangeOf(lg.faName, nq);
    const enRange = rangeOf(lg.enName, nq);
    return {
      key: lg.key,
      fa: lg.faName,
      en: lg.enName,
      leagueId: lg.fotmobId,
      matchedOn: faRange ? lg.faName : lg.enName,
      hl: faRange || enRange ? { fa: faRange, en: enRange } : undefined,
    };
  });
}

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
  coach: { id: number; name: string; fa?: string | null; age?: number; nationality?: string } | null;
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

// cycle-260 probed (2026-10-31, Node fetch — the TLS-fingerprint reality of
// cycle-257): the SAME api/data/teams payload carries transfers.allRumours[]
// — press rumours with a probability enum. Row shape ≈ FMTeamTransferRaw but
// fee carries a real `value` (EUR), plus probability ("Low"/"Medium"/"High"
// — the full probed set over 104 rows on 10 clubs), marketValue, rumourId and
// sourceName/sourceUrl (probed: sourceUrl always a full https URL). The feed
// rides the ONE cached teams fetch — zero extra upstream.
interface FMRumourRaw {
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
  fee?: { feeText?: string; value?: number | null } | null;
  transferType?: { text?: string };
  contractExtension?: boolean;
  onLoan?: boolean;
  probability?: string;
  sourceName?: string | null;
  sourceUrl?: string | null;
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
  transfers?: { allTransfers?: FMTeamTransferRaw[]; allRumours?: FMRumourRaw[] };
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
    // cycle-261 probed (2026-10-31, Node fetch — the TLS-fingerprint reality
    // of cycle-257): overview.newsSummary = the club press digest. Shape
    // {items[]} with each item {summary, source{sourceName, uri, articleId,
    // title}}; uri is ALWAYS a full https fotmob.com/news URL (probed) and
    // sourceName is a publisher tag ("Opta"). Present on major clubs (City:
    // 3 rows); null on smaller ones (probed 9865 LaLiga2) → section hidden
    // (honest absence, the cycle-260 rumours convention).
    newsSummary?: FMNewsSummaryRaw;
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

// cycle-261: raw club news digest (see FMTeamDataRaw.overview comment)
interface FMNewsSummaryRaw {
  items?: FMNewsItemRaw[];
}

interface FMNewsItemRaw {
  summary?: string;
  source?: {
    sourceName?: string;
    uri?: string;
    articleId?: string;
    title?: string;
  };
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

// cycle-264: key bumped v1→v2 — builds before this fix could cache the
// transient upstream `null` body (JSON-valid!) for the full 60 min in L1+L2
// (L2 persists across restarts), so a single glitched fetch hid every lazy
// team section for an hour after the upstream healed. The v2 key makes any
// poisoned row unreachable instantly (same convention as the 196
// standings:v10 / player:v9 lessons).
const getTeamDataRaw = (teamId: number): Promise<FMTeamDataRaw> =>
  cached(`teamDataRaw:v2:${teamId}`, 60 * 60_000, async () => {
    const data = await fetchJson<FMTeamDataRaw>(
      `https://www.fotmob.com/api/data/teams?id=${teamId}`,
      15000
    );
    // cycle-264: live-probed transient upstream shape (2026-10-31 ~22:30
    // Tehran): teams?id=17 answered 200 with a literal `null` body (4 bytes)
    // while every other team/league/match id returned full payloads — and it
    // heals on its own moments later. JSON null parses fine so fetchJson
    // resolves instead of throwing; the guard lives INSIDE the producer (the
    // documented getLeagueRaw convention) so nothing unusable is ever cached
    // — each request retries upstream instead. The five families below are
    // exactly the keys every consumer reads (diff-ключ sweep, cycle-262): a
    // payload without any of them would only ever normalize to nulls.
    if (
      data == null ||
      typeof data !== "object" ||
      !("squad" in data || "transfers" in data || "fixtures" in data || "history" in data || "overview" in data)
    ) {
      throw new Error(`teams payload unusable for id ${teamId}`);
    }
    return data;
  });

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
        coach = {
          id: c.id,
          name: c.name,
          // cycle-259 (bug-hunt 258 finding): the chip renders Persian first
          fa: coachFa(c.id),
          ...(c.age != null ? { age: c.age } : {}),
          ...(c.cname ? { nationality: c.cname } : {}),
        };
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
  // cycle-167: honest Persian display name — same contract as the league feed.
  nameFa: string;
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
      nameFa: playerFa(t.name),
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

// ---------------- FotMob: team transfer RUMOURS (data/teams, cycle-260) ----------------
/** One press rumour of the team («شایعات انتقال», cycle-260). Direction and
 *  naming follow the cycle-71 transfer contract; the rumour-specific bits are
 *  the probability pill (honest Persian, "" → UI omits the pill) and the
 *  source attribution (only surfaced when BOTH name and an https URL exist —
 *  the honest-link rule). */
export interface TeamRumourItem {
  playerId: number;
  name: string;
  nameFa: string;
  position: string;
  date: string; // ISO
  kind: "in" | "out" | "internal";
  kindFa: string;
  from: { id: number; fa: string };
  to: { id: number; fa: string };
  feeFa: string;
  probability: "" | "low" | "medium" | "high";
  probabilityFa: string;
  sourceName: string | null;
  sourceUrl: string | null;
}

export interface TeamRumoursData {
  total: number;
  nIn: number;
  nOut: number;
  items: TeamRumourItem[];
}

/** Persian fee/type label for the RUMOUR feed — like teamTransferFeeFa but
 *  rumour rows carry a REAL fee.value (probed: 35,000,000 on a 2026/27 City
 *  rumour) while amountEuroEstimated is absent on the shape. */
const rumourFeeFa = (t: FMRumourRaw): string => {
  if (t.contractExtension) return "تمدید قرارداد";
  if (typeof t.fee?.value === "number" && t.fee.value > 0) return `کارمزد ${euroFa(t.fee.value)}`;
  const feeText = (t.fee?.feeText || "").toLowerCase();
  const typeText = (t.transferType?.text || "").toLowerCase();
  if (feeText === "on loan" || typeText === "on loan" || t.onLoan) return "انتقال امانی";
  if (feeText === "free transfer" || typeText === "free transfer") return "انتقال آزاد";
  if (feeText === "undisclosed" || typeText === "undisclosed") return "کارمزد نامشخص";
  if (feeText === "fee") return "کارمزد";
  if (typeText === "contract") return "قرارداد";
  return t.transferType?.text || t.fee?.feeText || "انتقال";
};

/** Probed probability enum (104 rows / 10 clubs): "Low" | "Medium" | "High".
 *  Unknown values degrade to "" both sides — the UI omits the pill (the
 *  honest-drop convention of MATCH_POLL_FA / MATCH_INSIGHT_FA). */
const RUMOUR_PROBABILITY_FA: Record<string, string> = {
  low: "احتمال کم",
  medium: "احتمال متوسط",
  high: "احتمال زیاد",
};

/**
 * Team-level transfer RUMOUR feed («شایعات انتقال», cycle-260) from the SAME
 * data/teams payload as the cycle-71 feed — allRumours rides the one cached
 * `teamDataRaw:{id}` fetch, so this costs ZERO extra upstream. Direction is
 * classified against the team id exactly like the transfers feed (in = toId,
 * out = fromId, internal = both). Source order is already date-desc — kept
 * as-is. Returns null when the payload has no rumour feed so the UI hides
 * the section (same contract as getTeamTransfers).
 */
export async function getTeamRumours(teamId: number): Promise<TeamRumoursData | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const list = raw?.transfers?.allRumours;
  if (!Array.isArray(list) || list.length === 0) return null;
  const items: TeamRumourItem[] = [];
  for (const t of list) {
    if (!t?.name || !t?.fromClub || !t?.toClub) continue;
    const fromId = Number(t.fromClubId || 0);
    const toId = Number(t.toClubId || 0);
    if (fromId !== teamId && toId !== teamId) continue;
    const kind: TeamRumourItem["kind"] =
      fromId === teamId && toId === teamId ? "internal" : toId === teamId ? "in" : "out";
    const probKey = (t.probability || "").toLowerCase();
    const probability = probKey === "low" || probKey === "medium" || probKey === "high" ? probKey : "";
    const srcName = t.sourceName || null;
    const srcUrl = t.sourceUrl && /^https:\/\//.test(t.sourceUrl) ? t.sourceUrl : null;
    items.push({
      playerId: Number(t.playerId || 0),
      name: t.name,
      nameFa: playerFa(t.name),
      position: t.position?.label || "",
      date: t.transferDate || "",
      kind,
      kindFa: kind === "in" ? "ورودی" : kind === "out" ? "خروجی" : "تمدید",
      from: { id: fromId, fa: teamFa(t.fromClubFullName, t.fromClub) || t.fromClubFullName || t.fromClub },
      to: { id: toId, fa: teamFa(t.toClubFullName, t.toClub) || t.toClubFullName || t.toClub },
      feeFa: rumourFeeFa(t),
      probability,
      probabilityFa: probability ? RUMOUR_PROBABILITY_FA[probability] : "",
      sourceName: srcName,
      sourceUrl: srcName && srcUrl ? srcUrl : null,
    });
  }
  if (items.length === 0) return null;
  return {
    total: items.length,
    nIn: items.filter((x) => x.kind === "in").length,
    nOut: items.filter((x) => x.kind === "out").length,
    items,
  };
}

// ---------------- FotMob: team news digest (data/teams, cycle-261) ----------------
/** One club news digest row («اخبار باشگاه», cycle-261) from the SAME
 *  data/teams payload as the transfers/rumours feeds — zero extra upstream.
 *  titleFa rides the exact /api/news LLM translate stage (translateBatch,
 *  English fallback — the news-page convention); the summary line stays
 *  English as on the news cards. Parser drops any row whose title, summary,
 *  source name or https link did not survive (honest-drop convention). */
export interface TeamNewsItem {
  title: string; // original (English)
  titleFa: string; // Persian via the translate stage (falls back to English)
  summary: string;
  sourceName: string;
  url: string; // https-only article link
}

export interface TeamNewsData {
  total: number;
  items: TeamNewsItem[];
}

/**
 * Team-level club news digest («اخبار باشگاه», cycle-261) from the SAME
 * data/teams payload — overview.newsSummary rides the one cached
 * `teamDataRaw:{id}` fetch, so this costs ZERO extra upstream. Source order
 * is the feed's own (newest-first) — kept as-is. Returns null when the
 * payload has no digest so the UI hides the section (same contract as
 * getTeamRumours). titleFa is filled with the English title here; the
 * /api/team-news route upgrades it via the shared translate stage.
 */
export async function getTeamNews(teamId: number): Promise<TeamNewsData | null> {
  if (!Number.isFinite(teamId) || teamId <= 0) return null;
  const raw = await getTeamDataRaw(teamId);
  const list = raw?.overview?.newsSummary?.items;
  if (!Array.isArray(list) || list.length === 0) return null;
  const items: TeamNewsItem[] = [];
  for (const n of list) {
    const title = (n?.source?.title || "").trim();
    const summary = (n?.summary || "").trim();
    const sourceName = (n?.source?.sourceName || "").trim();
    const uri = n?.source?.uri || "";
    if (!title || !summary || !sourceName || !/^https:\/\//.test(uri)) continue;
    items.push({ title, titleFa: title, summary, sourceName, url: uri });
    if (items.length >= 6) break; // probed feed depth: 3 rows on City
  }
  if (items.length === 0) return null;
  return { total: items.length, items };
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

// ---------------- FotMob: coach profile (cycle-255 «صفحهٔ مربی») ----------------
// playerData serves COACHES too (probed live 2026-10-31, UA Chrome/124,
// Xabi Alonso id 30889 — Chelsea's bench): isCoach=true + coachStats.
// activeCareerEntry (current bench W/D/L: 11/6/1/4) + careerHistory.careerItems.
// coach.teamEntries[] (stints with startDate/endDate/active) + the shared
// playerTrophies block. Non-coach ids (plain players) → the sentinel →
// CoachNotFoundError → honest 404, same contract as getPlayerData.

export class CoachNotFoundError extends Error {}

export interface CoachStint {
  teamId: number;
  team: string;   // english name
  fa: string;     // teamFa map hit else english fallback
  logo: string;
  from: string;   // gregorian year (faDigits applied in the UI)
  to: string;     // gregorian year or "" while active
  active: boolean;
}

export interface CoachData {
  id: string;
  name: string;
  // cycle-259: the COACH_FA seed hit (bug-hunt 258 finding — coach h1 rendered
  // raw english while players ride playerFa). null → the UI falls back to name
  fa: string | null;
  age: number | null;
  countryFa: string | null; // countryFa() hit; null → the UI falls back to english
  countryEn: string | null;
  team: {
    id: number; name: string; fa: string; logo: string;
    matches: number; wins: number; draws: number; losses: number;
  } | null;
  career: CoachStint[];
  trophies: { teamName: string; leagueName: string; seasonsWon: string[]; runnerUp: number }[];
}

function coachInfoRow(raw: FMPlayerDetails, translationKey: string): { text: string | null; num: number | null } {
  const rows = Array.isArray(raw.playerInformation)
    ? raw.playerInformation
    : Object.values(raw.playerInformation || {});
  for (const r of rows) {
    if (r?.translationKey !== translationKey) continue;
    const v = r.value || {};
    const num = typeof v.numberValue === "number" ? v.numberValue : null;
    const text = typeof v.fallback === "string" && v.fallback ? v.fallback : num != null ? String(num) : null;
    return { text, num };
  }
  return { text: null, num: null };
}

/**
 * Full coach payload for the SSR /coach/[id] page + /api/coach/[id].
 * Same error contract as getPlayerData: unknown/non-coach id → cached
 * sentinel → CoachNotFoundError (real 404); upstream/network failure →
 * the error propagates (nothing cached → the next request retries).
 */
export async function getCoachData(id: string): Promise<CoachData> {
  if (!/^\d{3,12}$/.test(id)) throw new CoachNotFoundError(`bad coach id: ${id}`);
  const payload = await cached(`coach:v2:${id}`, 10 * 60_000, async (): Promise<CoachData | typeof PLAYER_NOT_FOUND> => {
    const raw = await fetchJson<FMPlayerDetails>(`https://www.fotmob.com/api/data/playerData?id=${id}`, 9000);
    if (!raw || typeof raw !== "object" || (raw as { error?: unknown }).error === true) return PLAYER_NOT_FOUND;
    if (!raw.name || !raw.id || raw.isCoach !== true) return PLAYER_NOT_FOUND;

    // current bench record (optional — some coach payloads answer without it)
    const ace = raw.coachStats?.activeCareerEntry || null;
    const team = ace && ace.teamId && ace.teamName
      ? {
          id: ace.teamId,
          name: ace.teamName,
          fa: teamFa(ace.teamName) || ace.teamName,
          logo: fotmobTeamLogo(ace.teamId),
          matches: Number(ace.matches || 0),
          wins: Number(ace.wins || 0),
          draws: Number(ace.draws || 0),
          losses: Number(ace.losses || 0),
        }
      : null;

    // stints — upstream order kept (newest first on the probe); the active
    // flag renders the «اکنون» badge and clears the end year
    const entries = raw.careerHistory?.careerItems?.coach?.teamEntries || [];
    const career: CoachStint[] = entries
      .filter((e) => e && e.team && e.teamId)
      .map((e) => ({
        teamId: Number(e.teamId),
        team: String(e.team),
        fa: teamFa(String(e.team)) || String(e.team),
        logo: fotmobTeamLogo(Number(e.teamId)),
        from: e.startDate ? String(e.startDate).slice(0, 4) : "",
        to: e.active ? "" : e.endDate ? String(e.endDate).slice(0, 4) : "",
        active: !!e.active,
      }));

    // shared trophies block — the player-honours normalization, reused
    const trophies: CoachData["trophies"] = [];
    for (const pt of raw.trophies?.playerTrophies || []) {
      for (const t of pt.tournaments || []) {
        const won = t.seasonsWon || [];
        const runnerUp = (t.seasonsRunnerUp || []).length;
        if (won.length === 0 && runnerUp === 0) continue;
        trophies.push({ teamName: pt.teamName || "", leagueName: t.leagueName || "", seasonsWon: won, runnerUp });
      }
    }
    trophies.sort((a, b) => b.seasonsWon.length - a.seasonsWon.length);

    const country = coachInfoRow(raw, "country_sentencecase");
    const age = coachInfoRow(raw, "age_sentencecase");

    return {
      id: String(raw.id),
      name: String(raw.name),
      fa: coachFa(Number(raw.id)),
      age: age.num,
      countryFa: country.text ? countryFa(country.text) || null : null,
      countryEn: country.text,
      team,
      career,
      trophies: trophies.slice(0, 12),
    };
  });
  if (payload === PLAYER_NOT_FOUND || isPlayerSentinel(payload) || !payload || typeof payload !== "object") {
    throw new CoachNotFoundError(`coach ${id} not found`);
  }
  // same explicit cast as getPlayerData — the cached<T> union doesn't narrow
  // by the sentinel identity check alone
  return payload as CoachData;
}

// ---------------- coach search (cycle-256) ----------------
// cycle-255 built the /coach/[id] surface (playerData serves coaches); this
// cycle makes coaches FINDABLE from the header search. The index is a
// live-probed SEED — same curated-seed convention as SEARCH_FALLBACK_TEAMS:
// every entry read from the real data/teams?id=X .coach block (UA Chrome/124,
// 2026-10-31, 30 clubs of the catalogued leagues; Iranian clubs' payloads
// honestly lack the coach object → absent until a richer source exists).
// Search-time cost: ZERO upstream fetches (static array); team fa names ride
// teamFa at match time; rows link the club badge (no coach headshots exist).

export interface CoachSearchResult {
  id: number;       // coach id (the playerData id-space → /coach/[id])
  name: string;     // upstream english name
  // cycle-259 (bug-hunt 258 finding): Persian rendering joins the seed — the
  // search haystack must answer PERSIAN queries («مورینیو»، «آلونسو»،
  // «پلگرینی») on a Persian-first site, and the UI row + coach h1 render it.
  fa: string | null;
  teamId: number;   // current club (badge + fa chip in the UI)
  teamName: string; // english club name
}

const COACH_SEED: CoachSearchResult[] = [
  { id: 24011, name: "Mikel Arteta", fa: "میکل آرتتا", teamId: 9825, teamName: "Arsenal" },
  { id: 2642, name: "Diego Simeone", fa: "دیگو سیمئونه", teamId: 9906, teamName: "Atlético Madrid" },
  { id: 131509, name: "Hans-Dieter Flick", fa: "هانسی فلیک", teamId: 8634, teamName: "Barcelona" },
  { id: 1515447, name: "Carles Martínez", fa: "کارلس مارتینس", teamId: 8178, teamName: "Bayer Leverkusen" },
  { id: 1415967, name: "Aaron Danks", fa: "آرون دنکس", teamId: 9823, teamName: "Bayern München" },
  { id: 33072, name: "Niko Kovač", fa: "نیکو کواچ", teamId: 9789, teamName: "Borussia Dortmund" },
  { id: 38711, name: "Keith Andrews", fa: "کیت اندروز", teamId: 9937, teamName: "Brentford" },
  { id: 208516, name: "Fabian Hürzeler", fa: "فابیان هورزلر", teamId: 10204, teamName: "Brighton & Hove Albion" },
  { id: 30889, name: "Xabi Alonso", fa: "شابی آلونسو", teamId: 8455, teamName: "Chelsea" },
  { id: 30613, name: "Cesc Fàbregas", fa: "سسک فابرگاس", teamId: 10171, teamName: "Como" },
  { id: 94647, name: "Vincent Wagner", fa: "وینسنت واگنر", teamId: 8232, teamName: "Elversberg" },
  { id: 36771, name: "Julian Schuster", fa: "یولیان شوستر", teamId: 8358, teamName: "Freiburg" },
  { id: 1188285, name: "Massimiliano Alvini", fa: "ماسیمیلیانو آلوینی", teamId: 9891, teamName: "Frosinone" },
  { id: 27692, name: "Cristian Chivu", fa: "کریستیان کیوو", teamId: 8636, teamName: "Inter" },
  { id: 30721, name: "Gennaro Gattuso", fa: "جنارو گاتوزو", teamId: 8543, teamName: "Lazio" },
  { id: 1108529, name: "Davide Ancelotti", fa: "داویده آنچلوتی", teamId: 8639, teamName: "Lille" },
  { id: 33025, name: "Andoni Iraola", fa: "آندونی ایرولا", teamId: 8650, teamName: "Liverpool" },
  { id: 361759, name: "Paulo Fonseca", fa: "پائولو فونسکا", teamId: 9748, teamName: "Lyon" },
  { id: 34000, name: "Enzo Maresca", fa: "انزو مارسکا", teamId: 8456, teamName: "Manchester City" },
  { id: 11754, name: "Ruben Amorim", fa: "روبن آموریم", teamId: 8564, teamName: "Milan" },
  { id: 41167, name: "Filipe Luís", fa: "فیلیپه لوئیس", teamId: 9829, teamName: "Monaco" },
  { id: 24105, name: "Liam Rosenior", fa: "لیام روزنیور", teamId: 6379, teamName: "Paris FC" },
  { id: 11532, name: "Luis Enrique", fa: "لوییس انریکه", teamId: 9847, teamName: "Paris Saint-Germain" },
  { id: 30459, name: "Martín Demichelis", fa: "مارتین دمیکیلیس", teamId: 178475, teamName: "RB Leipzig" },
  { id: 78591, name: "Manuel Pellegrini", fa: "مانوئل پلگرینی", teamId: 8603, teamName: "Real Betis" },
  { id: 78719, name: "José Mourinho", fa: "ژوزه مورینیو", teamId: 8633, teamName: "Real Madrid" },
  { id: 27204, name: "Pellegrino Matarazzo", fa: "پلگرینو ماتارازو", teamId: 8560, teamName: "Real Sociedad" },
  { id: 804046, name: "Franck Haise", fa: "فرانک هایز", teamId: 9851, teamName: "Rennes" },
  { id: 96945, name: "Gian Piero Gasperini", fa: "جان‌پی‌یرو گاسپرینی", teamId: 8686, teamName: "Roma" },
  { id: 242474, name: "Luis García", fa: "لوییس گارسیا", teamId: 8302, teamName: "Sevilla" },
];

// cycle-259: Persian name of a coach by id — the seed is the single source
// (30 catalogued-club benches). Coaches outside the seed → null (the UI and
// the API fall back to the upstream english name — honest, no guessing).
export function coachFa(id: number): string | null {
  if (!Number.isFinite(id)) return null;
  return COACH_SEED.find((e) => e.id === id)?.fa ?? null;
}

/** Header-search coach bucket — same fold/scoring family as searchLeagues.
 *  Haystack = coach en/fa name + club en/fa (cycle-259: the PERSIAN coach name
 *  joins so «مورینیو»/«آلونسو» hit); the static seed answers instantly. */
export function searchCoaches(q: string, limit = 4): CoachSearchResult[] {
  const nq = normalizeQuery(q);
  if (nq.length < 2) return [];
  const scored: { e: CoachSearchResult; score: number }[] = [];
  for (const e of COACH_SEED) {
    const hay = normalizeQuery(`${e.name} ${e.fa || ""} ${e.teamName} ${teamFa(e.teamName) || e.teamName}`);
    let score = -1;
    if (hay === nq) score = 100;
    else if (hay.startsWith(nq)) score = 80;
    else if (hay.includes(nq)) score = 50;
    else {
      const words = nq.split(" ");
      if (words.length > 1 && words.every((w) => hay.includes(w))) score = 40;
    }
    if (score > 0) scored.push({ e, score });
  }
  scored.sort((a, b) => b.score - a.score || a.e.name.localeCompare(b.e.name));
  return scored.slice(0, limit).map(({ e }) => e);
}
