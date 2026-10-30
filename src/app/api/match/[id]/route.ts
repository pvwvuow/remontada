// ------------------------------------------------------------------
// Remontada — /api/match/[id]
// Match details from FotMob (events, stats, lineups, info, form)
// Normalized for Persian display
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { LEAGUES, teamFa, fotmobTeamLogo, competitionFa } from "@/lib/leagues";
import { cached } from "@/lib/cache";
import { buildShootout } from "@/lib/shootout";
import { roundFa, unavailableReturnFa, marketValueFa } from "@/lib/fotmob";
import { playerFa } from "@/lib/player-names-fa";
import { faDigits } from "@/lib/format";

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

// ---------------- FotMob raw shapes ----------------
interface FMPlayerRef { id?: number | null; name?: string | null }
interface FMEvent {
  type: string;
  time?: number;
  addedTime?: number | null;
  isHome?: boolean | null;
  player?: FMPlayerRef | null;
  homeScore?: number;
  awayScore?: number;
  card?: string | null;           // "yellow" | "red" | ...
  ownGoal?: boolean | null;
  isPenalty?: boolean | null;
  isPenaltyShootoutEvent?: boolean;
  swap?: { name: string; id?: string }[] | null;  // [in, out]
  injuryTimeInMin?: number;
  assistInput?: string | null;
  assistPlayerId?: number | null;
  assistStr?: string | null;
}
interface FMStatRow {
  title: string;
  key: string;
  stats?: (string | number | null)[];
  rawStats?: ({ value?: number | null; total?: number } | null)[];
  type?: string; // "graph" | "text" | "title"
  highlighted?: string;
}
interface FMStatGroup {
  title: string;
  key?: string;
  stats?: FMStatRow[];
}
// update cycle-47: one raw entry of content.playerStats (dict keyed by player
// id); `stats` is an array of sections whose labels are English titles. Players
// who never stepped on the pitch carry an empty stats array.
interface FMPlayerEntry {
  name?: string;
  id?: number;
  teamId?: number;
  teamName?: string;
  isGoalkeeper?: boolean;
  shirtNumber?: string;
  usualPosition?: number;
  stats?: FMPlayerStatSection[];
  shotmap?: unknown[];
}
interface FMPlayerStatSection {
  title?: string;
  key?: string;
  stats?: Record<string, { key?: string | null; stat?: { value?: number | null; total?: number | null; type?: string } } | undefined>;
}
// update cycle-46: one raw shot from content.shotmap.shots
interface FMShot {
  eventType?: string;
  teamId?: number;
  playerName?: string;
  x?: number;
  y?: number;
  min?: number;
  minAdded?: number | null;
  isBlocked?: boolean;
  isOnTarget?: boolean;
  expectedGoals?: number;
}

interface FMStarter {
  id: number; name: string; shirtNumber?: string;
  positionId?: number; usualPlayingPositionId?: number;
  verticalLayout?: { x?: number; y?: number };
  performance?: { rating?: number };
  age?: number;
}
interface FMLineupTeam {
  id: number; name: string; formation?: string | null;
  starters?: FMStarter[];
  subs?: FMStarter[];
  coach?: { name?: string; firstName?: string; lastName?: string } | null;
  // cycle-116: lineup-tab «غایبان و آمار ترکیب» — the unavailable (injured /
  // suspended / international duty) block + starter facts, unconsumed since
  // the beginning (probed shapes over 4 matches, UA Chrome/124).
  averageStarterAge?: number;
  totalStarterMarketValue?: number;
  unavailable?: {
    id?: number; name?: string; firstName?: string; lastName?: string;
    marketValue?: number;
    unavailability?: { type?: string; expectedReturn?: string } | null;
  }[] | null;
}
interface FMPotmStatValue { value?: number | null; total?: number | null; type?: string }
interface FMPotmStatGroup {
  title?: string;
  key?: string;
  stats?: Record<string, { key?: string | null; stat?: FMPotmStatValue } | undefined>;
}
interface FMPotm {
  id?: number;
  name?: string | { firstName?: string; lastName?: string; fullName?: string } | null;
  rating?: { num?: string } | null;
  teamName?: string;
  teamId?: number;
  minutesPlayed?: number;
  role?: string;
  isHomeTeam?: boolean;
  stats?: FMPotmStatGroup[];
}
// update cycle-110 probed (UA Chrome/124, 2026-10-29, 5 live matches):
// matchFacts.insights carries pre-match story lines as localized templates
// (localizedTextId + statValues[{value,name,type}] + team color). Curated
// Persian templates live in MATCH_INSIGHT_FA; unknown ids are dropped.
interface FMInsightStatValue { value?: number | string | null; name?: string | null; type?: string }
interface FMInsight {
  type?: string; // "team" | "player"
  teamId?: number;
  playerId?: number;
  priority?: number;
  localizedTextId?: string;
  statValues?: FMInsightStatValue[];
  color?: string;
}

// update cycle-110: curated Persian renderings of the upstream insight
// templates (probed live across 5 matches, UA Chrome/124, 2026-10-29 —
// 11 distinct localizedTextIds). {N} placeholders fill from statValues in
// order: entries with a `name` are entity refs (team → teamFa, otherwise
// playerFa; honest fallback = raw upstream name), bare values → Persian
// digits. Unknown localizedTextIds never render (honest drop).
const MATCH_INSIGHT_FA: Record<string, string> = {
  "h2h_winstreak": "{0} در {2} دیدار قبلی مقابل {1} پیروز شده است.",
  "insights_goals_team": "در {1} بازی اخیر {0} گل به ثمر رسانده است.",
  "insights_not_clean_sheet": "در {0} بازی متوالی دروازهٔ بسته نداشته است.",
  "insights_not_won_team": "در {0} بازی اخیر به پیروزی نرسیده است.",
  "insights_bad_form_team": "{0} بازی اخیر خود را با شکست پشت سر گذاشته است.",
  "insights_goalless_team": "در {0} بازی متوالی گلی نزده است.",
  "insights_clean_sheets": "بیشترین کلین‌شیت رقابت را در اختیار دارد ({0}).",
  "insights_player_most_chances_for_team": "{0} بیشترین موقعیت طلایی را برای {1} ساخته است ({2}).",
  "insights_player_most_shots_on_target_for_team": "{0} بیشترین شوت در چارچوب را به‌ازای هر بازی برای {1} دارد ({2}).",
  "insights_player_chances_created_rank_in_competition": "{0} در ساختن موقعیت طلایی رتبهٔ {1} رقابت را دارد ({2}).",
  "insights_player_goals_scored": "{0} آقای گل رقابت است ({1}).",
};
// update cycle-117 probed (UA Chrome/124, live sweep across MLS/Brazil/
// Libertadores, 2026-10-29): matchFacts.topScorers — each side's LEAGUE
// season top scorer + their season line. Shape uniform across the probe
// pool {playerId, fullName, lastName, stats{...}} but the whole block is
// ABSENT on some feeds (e.g. Brazilian Série A) → honest-hide upstream.
interface FMTopScorerStats {
  goals?: number;
  goalAssist?: number;
  expectedGoals?: number;
  gamesPlayed?: number;
  minsPlayedGoal?: number; // minutes per goal
  ontargetScoringAtt?: number; // shots on target per match
  motm?: number; // man-of-the-match awards this season
  playerRating?: number; // season average FotMob rating
  minsPlayed?: number;
}
interface FMTopScorerPlayer {
  playerId?: number;
  fullName?: string;
  lastName?: string;
  stats?: FMTopScorerStats;
}

interface FMMatchDetails {
  general?: {
    matchId?: number; matchName?: string; leagueId?: number; parentLeagueId?: number;
    leagueName?: string; leagueRoundName?: string; countryCode?: string;
    homeTeam?: { id?: number; name?: string };
    awayTeam?: { id?: number; name?: string };
    matchTimeUTC?: string; started?: boolean; finished?: boolean;
    teamColors?: { darkMode?: { home?: string; away?: string } };
  };
  header?: {
    teams?: { id?: number; name?: string; score?: number }[];
    status?: {
      utcTime?: string; started?: boolean; finished?: boolean; cancelled?: boolean;
      reason?: { short?: string; long?: string } | null;
      scoreStr?: string;
    };
  };
  content?: {
    matchFacts?: {
      events?: { events?: FMEvent[] };
      infoBox?: Record<string, unknown>;
      teamForm?: [
        { result?: number; resultString?: string }[],
        { result?: number; resultString?: string }[]
      ];
      playerOfTheMatch?: FMPotm | null;
      insights?: FMInsight[];
      // update cycle-125: the official YouTube highlight video link +
      // thumbnail (live-probed UA Chrome/124, 2026-10-29: present for FEATURED
      // finished matches only — 2 of 3 sampled; absent/None otherwise → the
      // surface honest-hides). Flat dict: {image, url, source}.
      highlights?: {
        image?: string;
        url?: string;
        source?: string;
      } | null;
      // update cycle-191: the post-match review feed («گزارش‌های بازی") —
      // live-probed UA Chrome/124, 2026-10-30: Opta articles on SOME finished
      // matches (5749721 → 1 entry, 5749727 → 8 entries = ONE article in 8
      // languages via "_lang"-suffixed ids); absent on other finished matches
      // (5765944) and on upcoming ones (5868120) → honest absence.
      postReview?: {
        id?: string;
        title?: string;
        description?: string;
        image?: string;
        source?: string;
        shareUrl?: string;
        lang?: string;
        dateUpdated?: string;
      }[] | null;
      // update cycle-192: the top-5 rated players per side («برترین‌های بازی»)
      // — live-probed UA Chrome/124, 2026-10-30: 5749721 → 5+5 entries
      // (playerId, name{fullName}, playerRatingRounded, playerRating, color,
      // manOfTheMatch, teamId, positionLabel{label,key}); the upcoming
      // 5868120 carries EMPTY arrays; content.table sits beside this block
      // but is only a pointer to a data.fotmob.com XML blob (set aside).
      topPlayers?: {
        homeTopPlayers?: {
          playerId?: number;
          name?: { fullName?: string };
          playerRatingRounded?: string;
          manOfTheMatch?: boolean;
          positionLabel?: { label?: string };
        }[] | null;
        awayTopPlayers?: {
          playerId?: number;
          name?: { fullName?: string };
          playerRatingRounded?: string;
          manOfTheMatch?: boolean;
          positionLabel?: { label?: string };
        }[] | null;
      } | null;
      // update cycle-117: the two sides' season top scorers («گلزنان فصل
      // دو تیم») — unconsumed since the beginning (the per-match playerStats
      // block consumed by cycle-47 is a DIFFERENT payload section)
      topScorers?: {
        homePlayer?: FMTopScorerPlayer | null;
        awayPlayer?: FMTopScorerPlayer | null;
      } | null;
    };
    stats?: { Periods?: Record<string, { stats?: FMStatGroup[] }> };
    lineup?: { homeTeam?: FMLineupTeam; awayTeam?: FMLineupTeam } | null;
    momentum?: { main?: { data?: { minute?: number; value?: number }[] } } | null;
    // update cycle-46: shotmap (per-shot locations, outcome, xG)
    shotmap?: { shots?: FMShot[] };
    // update cycle-47: per-player match stats (dict keyed by player id)
    playerStats?: Record<string, FMPlayerEntry>;
    // update cycle-97 probed (UA Chrome/124, 2026-10-29): present for
    // started/finished matches, null for upcoming ones; per side it carries
    // total/firstHalf/secondHalf × left/center/right integer shares
    // cycle-187 probed (UA Chrome/124, 2026-10-30, live samples: 5749727
    // Sassuolo–Lazio, 5749721 Roma–Cagliari): the halves are NOT always
    // present even when total is — every period block is read independently
    // and only surfaced when its sum > 0 (honest per-period omission).
    attackingZones?: {
      home?: {
        total?: { left?: number; center?: number; right?: number };
        firstHalf?: { left?: number; center?: number; right?: number };
        secondHalf?: { left?: number; center?: number; right?: number };
      } | null;
      away?: {
        total?: { left?: number; center?: number; right?: number };
        firstHalf?: { left?: number; center?: number; right?: number };
        secondHalf?: { left?: number; center?: number; right?: number };
      } | null;
    } | null;
    // update cycle-100 probed (UA Chrome/124, 2026-10-29, 28-sample live
    // sweep): content.weather is ALWAYS present — 0 nulls — for started,
    // finished AND upcoming matches (upcoming carries apiUsed:"forecast",
    // started/finished "current"). Flat object, never an array:
    // {temperature, windSpeed, windDirectionCardinal, iconCode,
    // relativeHumidity, precipChance?, precipitation, snow, cloudCover,
    // description, apiUsed, lastUpdated, localizedKey, defaultTitle}.
    // update cycle-101 probed: the COMPLETE localizedKey vocabulary (12 keys)
    // was read from FotMob's own i18n bundle in their match-page HTML —
    // weather_condition_{clear, sunny, partly_cloudy, cloudy, foggy,
    // light_rain, heavy_rain, rain, thunderstorms, stormy, snowy, windy}.
    // windUnit verdict (cycle-101): FotMob's own surfaces NEVER display wind
    // — their match widget renders temperature + icon only ("11°C"), 0 "km/h"
    // occurrences in the rendered page, all 21 "m/s" hits are URL false
    // positives (hreflang/links) → the windSpeed unit is permanently
    // unassertable from FotMob itself; temperature IS Celsius (their widget).
    // precipitation/snow verdict (cycle-102): their i18n bundle carries ONLY
    // the 12 condition keys — no unit strings at all, and the widget shows
    // neither value → same permanent honest omission as wind.
    weather?: {
      temperature?: number;
      windSpeed?: number;
      windDirectionCardinal?: string;
      iconCode?: number;
      relativeHumidity?: number;
      precipChance?: number;
      precipitation?: number;
      snow?: number;
      cloudCover?: number;
      description?: string;
      apiUsed?: string;
      lastUpdated?: string;
      localizedKey?: string;
      defaultTitle?: string;
    } | null;
  };
}

// ---------------- Persian mappings ----------------
const EVENT_FA: Record<string, string> = {
  Goal: "گل",
  Card: "کارت",
  Substitution: "تعویض",
  Half: "پایان نیمه",
  AddedTime: "وقت تلف‌شده",
  MissedPenalty: "پنالتی از دست رفته",
  Penalty: "پنالتی",
  VAR: "ویدیو داوری",
  Injury: "مصدمیت",
};

// update cycle-100: Persian weather condition labels keyed by the upstream
// localizedKey. update cycle-101: the map was completed 5 → 12 — the FULL
// vocabulary read from FotMob's own i18n bundle in their match-page HTML
// (live-fetched, UA Chrome/124), so every key FotMob can emit now renders in
// Persian; the defaultTitle (English) fallback remains as the honest guard
// for any future key FotMob adds (same convention as the cycle-96 names).
const WEATHER_FA: Record<string, string> = {
  weather_condition_clear: "صاف",
  weather_condition_sunny: "آفتابی",
  weather_condition_partly_cloudy: "تا حدی ابری",
  weather_condition_cloudy: "ابری",
  weather_condition_foggy: "مه‌آلود",
  weather_condition_light_rain: "باران سبک",
  weather_condition_heavy_rain: "باران سنگین",
  weather_condition_rain: "بارانی",
  weather_condition_thunderstorms: "رعدوبرق",
  weather_condition_stormy: "طوفانی",
  weather_condition_snowy: "برفی",
  weather_condition_windy: "پرباد",
};

const STAT_FA: Record<string, string> = {
  ballpossession: "مالکیت توپ",
  ballpossesion: "مالکیت توپ",
  shotsontarget: "شوت در چارچوب",
  shots_on_target: "شوت در چارچوب",
  shotsonunsave: "شوت‌های روی دروازه",
  shotstarget: "شوت در چارچوب",
  expected_goals: "گل‌های مورد انتظار (xG)",
  expected_goals_open_play: "xG بازی باز",
  expected_goals_set_play: "xG ضربات ایستگاهی",
  expected_goals_non_penalty: "xG بدون پنالتی",
  expected_goals_on_target: "xG روی در چارچوب",
  expected_goals_on_target_variant: "xGOT (روی در چارچوب)",
  total_shots: "شوت‌های کل",
  shotsofftarget: "شوت خارج از چارچوب",
  blocked_shots: "شوت بلاک‌شده",
  shots_woodwork: "برخورد با تیرک",
  shots_inside_box: "شوت داخل محوطه",
  shots_outside_box: "شوت بیرون محوطه",
  big_chance: "موقعیت طلایی",
  big_chance_missed_title: "موقعیت طلایی از دست رفته",
  accurate_passes: "پاس صحیح",
  passes: "کل پاس‌ها",
  own_half_passes: "پاس در نیمه خودی",
  opposition_half_passes: "پاس در نیمه حریف",
  long_balls_accurate: "پاس بلند صحیح",
  accurate_crosses: "پاس عرضی صحیح",
  player_throws: "اوت",
  touches_opp_box: "لمس در محوطه حریف",
  offsides: "آفساید",
  "matchstats.headers.tackles": "تکل",
  interceptions: "قطع توپ",
  rating_title: "امتیاز فوت‌ماب",
  minutes_played: "دقیقه بازی",
  goals: "گل",
  assists: "پاس گل",
  expected_assists: "پاس گل مورد انتظار (xA)",
  xg_and_xa: "xG + xA",
  chances_created: "موقعیت خلق‌شده",
  shot_accuracy: "دقت شوت",
  defensive_actions: "اکشن دفاعی",
  touches: "لمس توپ",
  recoveries: "برگرداندن توپ",
  dribbled_past: "دریبل‌شده",
  was_fouled: "خطا گرفته",
  duel_lost: "دوئل باخته",
  shot_blocks: "بلاک (دفاع)",
  clearances: "دفع توپ",
  keeper_saves: "مهار دروازه‌بان",
  duel_won: "دوئل برده",
  ground_duels_won: "دوئل زمینی برده",
  aerials_won: "دوئل هوایی برده",
  dribbles_succeeded: "دریبل موفق",
  yellow_cards: "کارت زرد",
  red_cards: "کارت قرمز",
  fouls: "خطا",
  corners: "کرنر",
  dispossessed: "از دست دادن توپ",
};

const STAT_GROUP_FA: Record<string, string> = {
  "top stats": "آمار کلیدی",
  shots: "شوت‌ها",
  "expected goals (xg)": "گل‌های مورد انتظار",
  passes: "پاس‌ها",
  defence: "دفاع",
  duels: "دوئل‌ها",
  discipline: "انضباطی",
};

function statFa(title: string, key: string): string {
  return STAT_FA[(key || "").toLowerCase()] || STAT_FA[title?.toLowerCase()] || title;
}

function fmtMinute(e: FMEvent): string {
  const base = e.time ?? 0;
  if (e.addedTime && e.addedTime > 0) return `${base}+${e.addedTime}′`;
  return `${base}′`;
}

// cycle-172: safe player-id coercion for the timeline family — upstream sends
// numbers on event player refs but STRING ids on substitution swap refs
// (live-probed 2026-10-30: swap: [{name, id: "1311977"}, …]). Anything that
// is not a positive integer (missing, 0, junk) → undefined, so the UI falls
// back to the plain honest name (the 167 dead-id rule).
function posId(v: unknown): number | undefined {
  const n = typeof v === "number" ? v : typeof v === "string" ? Number(v) : NaN;
  return Number.isInteger(n) && n > 0 ? n : undefined;
}

// ---------------- lineup row clustering ----------------
// cycle-106: chips/subs/coach carry nameFa — the honest Persian display name
// (curated PLAYER_NAME_FA hit, else the raw upstream English name), same
// contract as the cycle-104/105 name-map extensions; `name` stays upstream.
interface Chip { id: number; name: string; nameFa: string; shirt?: string; rating?: number; _y?: number }

function toChip(p: FMStarter): Chip {
  return {
    id: p.id,
    name: p.name,
    nameFa: playerFa(p.name),
    shirt: p.shirtNumber || undefined,
    rating: p.performance?.rating ?? undefined,
    _y: p.verticalLayout?.y ?? 0,
  };
}

function clusterRows(starters: FMStarter[]): { players: Chip[] }[] {
  const sorted = [...starters].sort((a, b) => (a.verticalLayout?.y ?? 0) - (b.verticalLayout?.y ?? 0));
  const rows: Chip[][] = [];
  for (const p of sorted) {
    const chip = toChip(p);
    const last = rows[rows.length - 1];
    if (!last) {
      rows.push([chip]);
      continue;
    }
    if (Math.abs(chip._y! - last[0]._y!) <= 0.14) {
      last.push(chip);
    } else {
      rows.push([chip]);
    }
  }
  return rows.map((players) => ({ players: players.map(({ _y, ...rest }) => rest) }));
}

interface LineupSide {
  teamId: number;
  name: string;
  fa: string;
  formation?: string;
  coach?: string;
  coachFa?: string; // cycle-106 honest map (present only when a coach name exists)
  starterAge?: number;       // cycle-116 raw — the UI formats (میانگین سن)
  totalMarketValue?: number; // cycle-116 raw EUR
  totalMarketValueFa?: string; // cycle-116 display-ready «۲۵۶.۷ میلیون یورو» (marketValueFa server-side — the client bundle must NOT pull fotmob/db)
  unavailable?: {            // cycle-116 «غایبان» — honest names (playerFa)
    id?: number; name: string; nameFa?: string;
    type?: string; typeFa?: string;
    returnRaw?: string; returnFa?: string | null;
  }[];
  rows: { players: Omit<Chip, "_y">[] }[];
  subs: { id: number; name: string; nameFa: string; shirt?: string }[];
}

// ---------------- normalizer ----------------
export interface MatchDetailNormalized {
  match: {
    id: string;
    leagueName: string;
    leagueFa: string;
    ccode: string;
    leagueId: number;
    round?: string;
    utcTime: string;
    started: boolean;
    finished: boolean;
    cancelled: boolean;
    live: boolean;
    minute?: string;
    statusText?: string;
    home: { id: number; name: string; fa: string; logo: string; score: number | null };
    away: { id: number; name: string; fa: string; logo: string; score: number | null };
  };
  // cycle-172 additive: upstream player ids join the timeline family —
  // player/assist/sub names become live /player links in the UI. Optional
  // fields only; every legacy field byte-untouched. ids are omitted when
  // upstream lacks them or the value is a dead id (≤0 — the 167 guard).
  scorers: { side: "home" | "away"; player: string; playerFa: string; minute: string; ownGoal: boolean; penalty: boolean; assist?: string; assistFa?: string; playerId?: number; assistId?: number }[];
  events: {
    type: string;
    typeFa: string;
    minute: string;
    side: "home" | "away" | "neutral";
    player?: string;
    playerFa?: string;
    playerId?: number;
    card?: string;
    assistId?: number;
    swapInId?: number;
    swapOutId?: number;
    ownGoal: boolean;
    penalty: boolean;
    swapIn?: string;
    swapInFa?: string;
    swapOut?: string;
    swapOutFa?: string;
    homeScore: number | null;
    awayScore: number | null;
    assist?: string;
    assistFa?: string;
  }[];
  statGroups: { title: string; rows: { key: string; title: string; home: string; away: string; graph: boolean; homeVal: number | null; awayVal: number | null }[] }[];
  // update cycle-190: per-period stats («آمار نیمه‌به‌نیمه») — the SAME
  // stat-table normalization applied to the upstream Periods.FirstHalf /
  // Periods.SecondHalf blocks (probed UA Chrome/124 2026-10-30 on
  // 5749721/5749727: Periods = All/FirstHalf/SecondHalf, each carrying the
  // same 7 group titles). statGroups stays the All period byte-identical
  // (pre-190 consumers untouched); a period key is emitted ONLY when that
  // period's upstream block yields ≥1 non-empty group (honest per-period
  // omission — the 187 zones contract family). null when neither half has
  // data (e.g. matches whose feed only fills All).
  statPeriods?: {
    firstHalf: { title: string; rows: { key: string; title: string; home: string; away: string; graph: boolean; homeVal: number | null; awayVal: number | null }[] }[];
    secondHalf: { title: string; rows: { key: string; title: string; home: string; away: string; graph: boolean; homeVal: number | null; awayVal: number | null }[] }[];
  } | null;
  lineups: { home: LineupSide | null; away: LineupSide | null } | null;
  info: {
    stadium?: string; city?: string; referee?: string; attendance?: string; date?: string; tournament?: string; round?: string;
    // cycle-115 additive: referee & stadium facts («داور و ورزشگاه») — the
    // infoBox Referee.stats block + Stadium capacity/surface, unconsumed since
    // the beginning. Optional → pre-115 cached payloads self-heal at the next
    // 25s cache generation (UI hides the card). Unknown stat types drop.
    refereeStats?: {
      matches?: number;
      yellowPerMatch?: number; yellowAvg?: number; yellowVs?: "above" | "below" | "average";
      red?: number; penalties?: number;
      foulsPerMatch?: number; foulsAvg?: number; foulsVs?: "above" | "below" | "average";
    } | null;
    stadiumExtra?: { capacity?: number; surface?: string } | null;
  };
  form: { home: string[]; away: string[] } | null;
  momentum: { minute: number; value: number }[] | null;
  // update cycle-97: attacking zones («جهت حملات») — TOTAL split of each
  // team's attacking output across the three pitch lanes; null when upstream
  // lacks the block (upcoming matches) or both sides are all-zero.
  // cycle-187 closes the v1 boundary cycle-97 declared («TOTAL split only in
  // v1 — firstHalf/secondHalf stay unrendered»): the per-half splits join as
  // OPTIONAL keys appended AFTER the legacy triple — the legacy shape
  // {left,center,right} stays byte-identical and every pre-187 consumer that
  // reads only left/center/right is untouched. A half key is emitted only
  // when that half's shares sum > 0 upstream (honest per-period omission —
  // probed: live matches mid-first-half carry no secondHalf data yet).
  zones?: {
    home: {
      left: number; center: number; right: number;
      firstHalf?: { left: number; center: number; right: number };
      secondHalf?: { left: number; center: number; right: number };
    };
    away: {
      left: number; center: number; right: number;
      firstHalf?: { left: number; center: number; right: number };
      secondHalf?: { left: number; center: number; right: number };
    };
  } | null;
  // update cycle-100: match weather («وضعیت هوا») — ONLY the honestly
  // displayable subset: condition (localizedKey→Persian, unknown→upstream
  // defaultTitle), temperature (°C — verified from FotMob's own widget),
  // relativeHumidity/cloudCover (inherent percentages) and precipChance
  // (inherent percentage, forecast-only). windSpeed / precipitation / snow /
  // iconCode are deliberately NOT normalized for display: windSpeed carries
  // no displayable unit — cycle-101 probe verdict: FotMob never displays
  // wind on any surface (widget = temperature + icon only; 0 km/h, all m/s
  // hits URL false positives) → PERMANENT honest omission (closed, not
  // deferred); precipitation/snow units unverified, iconCode never mapped.
  // null when the block is missing or carries no displayable value
  // (defensive — probe showed 0 nulls).
  weather?: {
    condition: string;
    conditionSource: "localized" | "upstream";
    temperature?: number;
    humidity?: number;
    cloudCover?: number;
    precipChance?: number;
    forecast: boolean;
  } | null;
  // update cycle-110: match insights («بینش‌ها») — upstream localized story
  // templates rendered through the curated Persian map; entries with an
  // unknown localizedTextId are dropped (honest convention, like the weather
  // keys); empty when the payload has none (or all unmapped)
  insights?: { text: string; color: string; kind: "team" | "player" | "h2h" }[] | null;
  // update cycle-117: the two sides' season top scorers («گلزنان فصل دو
  // تیم») — one entry per side, only finite stats carried (honest absence
  // per field); null when the payload lacks the block (some feeds do) or
  // neither side carries a displayable season line
  topScorers?: {
    home: TopScorerSide | null;
    away: TopScorerSide | null;
  } | null;
  // fix cycle-45: shootout attempts were dropped entirely before — the
  // decisive phase of knockout matches was invisible to the user
  shootout?: {
    home: number;
    away: number;
    attempts: { side: "home" | "away" | "neutral"; player?: string; playerFa?: string; playerId?: number; scored: boolean; noteFa: string }[];
  } | null;
  // update cycle-46: normalized shotmap (null when the match has no shot data)
  shots?: {
    side: "home" | "away";
    minute: string;
    player?: string;
    playerFa?: string;
    x: number;
    y: number;
    isGoal: boolean;
    onTarget: boolean;
    blocked: boolean;
    post: boolean;
    xg?: number;
  }[] | null;
  // update cycle-51: complete team xG («اسکوآپ تیم») — official FotMob xG stat
  // row (key=expected_goals) with the per-shot sum as fallback; shot breakdown
  // counts come from the shotmap. null when neither source has any xG data.
  xg?: {
    home: number | null;
    away: number | null;
    source: "stats" | "shotmap";
    homeBreakdown: {
      total: number; onTarget: number; blocked: number; post: number; goals: number;
    } | null;
    awayBreakdown: {
      total: number; onTarget: number; blocked: number; post: number; goals: number;
    } | null;
  } | null;
  // update cycle-47: per-player match stats, starters first then subs, each
  // sorted by FotMob rating desc (players with no data are filtered out)
  playerStats?: {
    home: PlayerStatRow[];
    away: PlayerStatRow[];
  } | null;
  playerOfTheMatch?: {
    id?: number;
    name: string;
    nameFa: string; // cycle-106 honest map (falls back to the raw name)
    rating?: string | null;
    teamId?: number;
    teamName?: string;
    teamLogo?: string;
    minutes?: number;
    role?: string;
    stats: { title: string; display: string }[];
  } | null;
  // update cycle-125: the official YouTube highlight video («ویدیوی خلاصهٔ
  // بازی») — only https youtube.com/watch links normalize; the thumbnail is
  // optional (card degrades to a text row when absent/foreign); null when
  // upstream lacks the block (legend-111 honest absence)
  highlights?: {
    url: string;
    image: string;
    source: string;
  } | null;
  // update cycle-191: the post-match review feed («گزارش‌های بازی") —
  // matchFacts.postReview deduped: the upstream array repeats ONE article in
  // several languages (ids get a "_lang" suffix); entries group by the base
  // id and the "en" entry wins each group, capped at 3 articles. The image
  // is optional (row degrades to text); url is the fotmob news shareUrl.
  reviews?: MatchReview[] | null;
  // update cycle-192: the top-5 rated players per side («برترین‌های بازی») —
  // matchFacts.topPlayers normalized; null when both sides end up empty
  // (honest absence — upcoming matches carry empty arrays upstream).
  topPlayers?: MatchTopPlayerSides | null;
  fetchedAt: string;
}

export interface MatchTopPlayer {
  id: number; // upstream playerId, guarded > 0 (the 167 convention)
  name: string; // upstream fullName (honest Latin identity — the 189 contract)
  nameFa: string; // playerFa at normalize time (match TTL is 25s — always fresh)
  rating: string; // upstream playerRatingRounded ("8.7") — display string
  motm: boolean; // upstream manOfTheMatch badge
  pos: string; // upstream positionLabel.label ("RM") — "" when absent
}

export interface MatchTopPlayerSides {
  home: MatchTopPlayer[];
  away: MatchTopPlayer[];
}

export interface MatchReview {
  title: string;
  description: string;
  image: string; // "" → the row renders text-only (onError-hide pattern)
  source: string;
  url: string; // https://www.fotmob.com/news/... (opens in a new tab)
  date?: string; // upstream dateUpdated ISO
}

// update cycle-117: one side's season top scorer for the h2h tab card.
// Name rides playerFa with the honest-English fallback (Loftus-Cheek
// contract); stats are the raw upstream numbers, each present only when
// finite.
export interface TopScorerSide {
  playerId?: number; // >0 → /player/{id} link
  name: string;
  nameFa: string;
  side: "home" | "away";
  goals?: number;
  assists?: number;      // goalAssist
  xg?: number;           // season expectedGoals, 1 decimal
  minsPerGoal?: number;  // minsPlayedGoal — «هر X دقیقه یک گل»
  motm?: number;         // man-of-the-match awards this season
  rating?: number;       // season average FotMob rating
  games?: number;        // gamesPlayed
}

// update cycle-47: one normalized player row for the «بازیکن‌ها» tab
export interface PlayerStatRow {
  id: number;
  name: string;
  nameFa: string; // cycle-106 honest map (falls back to the raw name)
  shirt?: string;
  side: "home" | "away";
  isGk: boolean;
  starter: boolean;
  rating?: number;
  minutes?: number;
  goals?: number;
  assists?: number;
  passesAcc?: number;
  passesTotal?: number;
  chances?: number;
  defActions?: number;
  // goalkeeper-specific (undefined for field players)
  saves?: number;
  conceded?: number;
  goalsPrevented?: number;
}

function normalize(raw: FMMatchDetails, matchId: string): MatchDetailNormalized {
  const g = raw.general || {};
  const hs = raw.header?.status || {};
  const teams = raw.header?.teams || [];
  const homeT = teams.find((t) => t.id === g.homeTeam?.id) || teams[0];
  const awayT = teams.find((t) => t.id === g.awayTeam?.id) || teams[1];

  const started = !!hs.started || !!g.started;
  const finished = !!hs.finished || !!g.finished;
  const cancelled = !!hs.cancelled;
  const live = started && !finished && !cancelled;

  const utcTime = hs.utcTime || g.matchTimeUTC || "";
  const leagueName = g.leagueName || "";
  const ccode = (g.countryCode || "").toUpperCase();
  const lgCfg = LEAGUES.find((l) => l.fotmobId === (g.parentLeagueId || g.leagueId));

  const home = {
    id: g.homeTeam?.id ?? homeT?.id ?? 0,
    name: g.homeTeam?.name || homeT?.name || "",
    fa: teamFa(g.homeTeam?.name) || g.homeTeam?.name || "",
    logo: fotmobTeamLogo(g.homeTeam?.id ?? 0),
    score: typeof homeT?.score === "number" ? homeT.score : null,
  };
  const away = {
    id: g.awayTeam?.id ?? awayT?.id ?? 0,
    name: g.awayTeam?.name || awayT?.name || "",
    fa: teamFa(g.awayTeam?.name) || g.awayTeam?.name || "",
    logo: fotmobTeamLogo(g.awayTeam?.id ?? 0),
    score: typeof awayT?.score === "number" ? awayT.score : null,
  };

  // minute for live matches (computed Tehran-time from kickoff)
  let minute: string | undefined;
  if (live && utcTime) {
    const elapsedMin = Math.floor((Date.now() - new Date(utcTime).getTime()) / 60_000);
    if (elapsedMin >= 0 && elapsedMin <= 130) {
      minute = elapsedMin > 45 ? `${Math.min(elapsedMin, 90)}′` : `${elapsedMin}′`;
    }
  }
  if (live && !minute) minute = "در جریان";

  // ---------------- events + scorers ----------------
  const rawEvents = raw.content?.matchFacts?.events?.events || [];
  const events: MatchDetailNormalized["events"] = [];
  const scorers: MatchDetailNormalized["scorers"] = [];
  const shootoutRaw: FMEvent[] = [];
  for (const e of rawEvents) {
    // fix cycle-45: collect shootout events instead of dropping them —
    // buildShootout turns them into a dedicated normalized block
    if (e.isPenaltyShootoutEvent) {
      shootoutRaw.push(e);
      continue;
    }
    const side: "home" | "away" | "neutral" = e.isHome === true ? "home" : e.isHome === false ? "away" : "neutral";
    const isGoal = e.type === "Goal";
    events.push({
      type: e.type,
      typeFa: EVENT_FA[e.type] || e.type,
      minute: fmtMinute(e),
      side,
      player: e.player?.name || undefined,
      ...(e.player?.name ? { playerFa: playerFa(e.player.name) } : {}),
      playerId: posId(e.player?.id),
      card: e.card || undefined,
      ownGoal: !!e.ownGoal,
      penalty: e.type === "MissedPenalty" || (!!isGoal && !!e.isPenalty),
      swapIn: e.type === "Substitution" ? e.swap?.[0]?.name : undefined,
      swapInFa: e.type === "Substitution" && e.swap?.[0]?.name ? playerFa(e.swap[0].name) : undefined,
      swapInId: e.type === "Substitution" ? posId(e.swap?.[0]?.id) : undefined,
      swapOut: e.type === "Substitution" ? e.swap?.[1]?.name : undefined,
      swapOutFa: e.type === "Substitution" && e.swap?.[1]?.name ? playerFa(e.swap[1].name) : undefined,
      swapOutId: e.type === "Substitution" ? posId(e.swap?.[1]?.id) : undefined,
      homeScore: typeof e.homeScore === "number" ? e.homeScore : null,
      awayScore: typeof e.awayScore === "number" ? e.awayScore : null,
      assist: isGoal && !e.ownGoal ? e.assistInput || undefined : undefined,
      assistFa: isGoal && !e.ownGoal && e.assistInput ? playerFa(e.assistInput) : undefined,
      assistId: isGoal && !e.ownGoal ? posId(e.assistPlayerId) : undefined,
    });
    if (isGoal) {
      if (side !== "neutral") {
        scorers.push({
          side,
          player: e.player?.name || "",
          playerFa: playerFa(e.player?.name || ""),
          playerId: posId(e.player?.id),
          minute: fmtMinute(e),
          ownGoal: !!e.ownGoal,
          penalty: !!e.isPenalty,
          // own goals are credited to the attacking side but the defender scoring
          // is shown by FotMob as the player — keep assist only for real goals
          assist: (!e.ownGoal && e.assistInput) || undefined,
          assistFa: !e.ownGoal && e.assistInput ? playerFa(e.assistInput) : undefined,
          assistId: !e.ownGoal ? posId(e.assistPlayerId) : undefined,
        });
      }
    }
  }
  events.reverse(); // newest-first for timeline

  // fix cycle-45: penalty shootout block (score + attempts), null on quiet path
  const shootout = shootoutRaw.length > 0 ? buildShootout(shootoutRaw) : null;

  // ---------------- shots (shotmap, update cycle-46) ----------------
  // side comes from teamId vs the general home/away ids; x/y are 0..100 with
  // x ≈ 100 = the shooting team's target goal
  const rawShots = raw.content?.shotmap?.shots;
  let shots: MatchDetailNormalized["shots"] = null;
  if (Array.isArray(rawShots) && rawShots.length > 0) {
    const homeId = g.homeTeam?.id;
    const awayId = g.awayTeam?.id;
    shots = rawShots
      .filter((s) => typeof s?.x === "number" && typeof s?.y === "number")
      .map((s) => ({
        side: (awayId != null && s.teamId === awayId) ? ("away" as const) : ("home" as const),
        minute: fmtMinute({ type: "Shot", time: s.min, addedTime: s.minAdded } as FMEvent),
        player: s.playerName || undefined,
        playerFa: s.playerName ? playerFa(s.playerName) : undefined,
        x: s.x as number,
        y: s.y as number,
        isGoal: s.eventType === "Goal",
        onTarget: !!s.isOnTarget,
        blocked: !!s.isBlocked,
        post: s.eventType === "Post",
        xg: typeof s.expectedGoals === "number" ? Math.round(s.expectedGoals * 100) / 100 : undefined,
      }));
  }

  // ---------------- team xG (update cycle-51) ----------------
  // Official xG lives in a stats row (key=expected_goals, the dedicated
  // "Expected goals (xG)" group repeats it); when that row is absent the sum of
  // per-shot xG is used instead. Breakdown counts come from the shotmap.
  const r2dp = (v: number) => Math.round(v * 100) / 100;
  let xg: MatchDetailNormalized["xg"] = null;
  {
    const allGroups = raw.content?.stats?.Periods?.All?.stats;
    const statRows: FMStatRow[] = (Array.isArray(allGroups) ? allGroups : []).flatMap(
      (grp: FMStatGroup) => grp?.stats || []
    );
    const xgRow = statRows.find((s) => s?.key === "expected_goals" && s.type !== "title");
    const oh = parseFloat(String(xgRow?.stats?.[0] ?? ""));
    const oa = parseFloat(String(xgRow?.stats?.[1] ?? ""));
    const officialHome = Number.isNaN(oh) ? null : oh;
    const officialAway = Number.isNaN(oa) ? null : oa;
    const breakdown = (side: "home" | "away") => {
      const arr = (shots || []).filter((s) => s.side === side);
      if (arr.length === 0) return null;
      return {
        total: arr.length,
        onTarget: arr.filter((s) => s.onTarget).length,
        blocked: arr.filter((s) => s.blocked).length,
        post: arr.filter((s) => s.post).length,
        goals: arr.filter((s) => s.isGoal).length,
      };
    };
    const hasXgOn = (side: "home" | "away") => (shots || []).some((s) => s.side === side && s.xg != null);
    const sumXg = (side: "home" | "away") =>
      (shots || []).filter((s) => s.side === side).reduce((acc, s) => acc + (s.xg ?? 0), 0);
    const homeVal = officialHome ?? (hasXgOn("home") ? r2dp(sumXg("home")) : null);
    const awayVal = officialAway ?? (hasXgOn("away") ? r2dp(sumXg("away")) : null);
    if (homeVal != null || awayVal != null) {
      xg = {
        home: homeVal,
        away: awayVal,
        source: officialHome != null || officialAway != null ? "stats" : "shotmap",
        homeBreakdown: breakdown("home"),
        awayBreakdown: breakdown("away"),
      };
    }
  }

  // ---------------- player stats (update cycle-47) ----------------
  // content.playerStats is a dict keyed by player id; only players who actually
  // played carry stat sections (unused subs/bench GKs have empty arrays).
  // Starter/sub grouping is derived from content.lineup.*.starters ids; within
  // each group players are sorted by FotMob rating desc, missing rating last.
  const rawPS = raw.content?.playerStats;
  let playerStats: MatchDetailNormalized["playerStats"] = null;
  if (rawPS && typeof rawPS === "object") {
    const homeId = g.homeTeam?.id;
    const awayId = g.awayTeam?.id;
    const starterIds = new Set<string>();
    for (const lt of [raw.content?.lineup?.homeTeam, raw.content?.lineup?.awayTeam]) {
      for (const st of lt?.starters || []) {
        if (st?.id != null) starterIds.add(String(st.id));
      }
    }
    const rows: PlayerStatRow[] = Object.values(rawPS)
      .filter((p) => Array.isArray(p?.stats) && p.stats.length > 0 && typeof p.id === "number")
      .map((p) => {
        const top =
          p.stats!.find((s) => (s?.key || "").toLowerCase() === "top_stats")?.stats || {};
        const num = (label: string): number | undefined => {
          const v = top[label]?.stat?.value;
          return typeof v === "number" ? v : undefined;
        };
        const passes = top["Accurate passes"]?.stat;
        const gp = num("Goals prevented");
        return {
          id: p.id as number,
          name: p.name || "?",
          nameFa: playerFa(p.name || "?"),
          shirt: p.shirtNumber || undefined,
          side: (awayId != null && p.teamId === awayId) ? ("away" as const) : ("home" as const),
          isGk: !!p.isGoalkeeper,
          starter: starterIds.has(String(p.id)),
          rating: num("FotMob rating"),
          minutes: num("Minutes played"),
          goals: num("Goals"),
          assists: num("Assists"),
          passesAcc: typeof passes?.value === "number" ? passes.value : undefined,
          passesTotal: typeof passes?.total === "number" ? passes.total : undefined,
          chances: num("Chances created"),
          defActions: num("Defensive actions"),
          saves: num("Saves"),
          conceded: num("Goals conceded"),
          goalsPrevented: gp != null ? Math.round(gp * 10) / 10 : undefined,
        };
      });
    const order = (a: PlayerStatRow, b: PlayerStatRow) => {
      if (a.starter !== b.starter) return a.starter ? -1 : 1;
      const ra = a.rating ?? -1;
      const rb = b.rating ?? -1;
      if (rb !== ra) return rb - ra;
      return (b.minutes ?? 0) - (a.minutes ?? 0);
    };
    const homeRows = rows.filter((r) => r.side === "home").sort(order);
    const awayRows = rows.filter((r) => r.side === "away").sort(order);
    if (homeRows.length > 0 || awayRows.length > 0) {
      playerStats = { home: homeRows, away: awayRows };
    }
  }

  // ---------------- stats ----------------
  // Shape: Periods.All.stats = [ { title: groupName, stats: [ {row}, {titleRow}, ... ] }, ... ]
  // cycle-190: the SAME mapping extracted into a helper and reused for the
  // upstream Periods.FirstHalf / Periods.SecondHalf blocks (statPeriods) —
  // the All output stays byte-identical (same helper, same order).
  const mapStatGroups = (groups?: FMStatGroup[]): MatchDetailNormalized["statGroups"] => {
    const out: MatchDetailNormalized["statGroups"] = [];
    if (!groups) return out;
    for (const grp of groups) {
      const groupName = grp.title || "";
      const bucket: MatchDetailNormalized["statGroups"][number] = {
        title: STAT_GROUP_FA[groupName.toLowerCase()] || groupName,
        rows: [],
      };
      for (const s of grp.stats || []) {
        if (s.type === "title") continue; // section header row inside group
        const raw0 = s.rawStats?.[0]?.value;
        const raw1 = s.rawStats?.[1]?.value;
        const v0 = typeof raw0 === "number" ? raw0 : parseFloat(String(raw0 ?? "")) || 0;
        const v1 = typeof raw1 === "number" ? raw1 : parseFloat(String(raw1 ?? "")) || 0;
        const disp0 = s.stats?.[0] ?? (raw0 ?? "—");
        const disp1 = s.stats?.[1] ?? (raw1 ?? "—");
        bucket.rows.push({
          key: s.key || s.title,
          title: statFa(s.title, s.key || ""),
          home: String(disp0),
          away: String(disp1),
          graph: s.type === "graph",
          homeVal: v0,
          awayVal: v1,
        });
      }
      if (bucket.rows.length > 0) out.push(bucket);
    }
    return out;
  };
  const statGroups = mapStatGroups(raw.content?.stats?.Periods?.All?.stats);
  // cycle-190: per-period stats — honest per-period omission (the 187
  // zones family): a half key exists only when its upstream block yields
  // ≥1 non-empty group; neither half → statPeriods stays null.
  const fhGroups = mapStatGroups(raw.content?.stats?.Periods?.FirstHalf?.stats);
  const shGroups = mapStatGroups(raw.content?.stats?.Periods?.SecondHalf?.stats);
  const statPeriods: MatchDetailNormalized["statPeriods"] =
    fhGroups.length > 0 || shGroups.length > 0 ? { firstHalf: fhGroups, secondHalf: shGroups } : null;

  // ---------------- lineups ----------------
  let lineups: MatchDetailNormalized["lineups"] = null;
  const lu = raw.content?.lineup;
  if (lu?.homeTeam?.starters?.length && lu?.awayTeam?.starters?.length) {
    const build = (t?: FMLineupTeam): LineupSide | null => {
      if (!t?.starters?.length) return null;
      const coachName = t.coach?.name || [t.coach?.firstName, t.coach?.lastName].filter(Boolean).join(" ") || undefined;
      // cycle-116: «غایبان» — unavailable (injured / international duty / …)
      // players with the raw expectedReturn string parsed through the cycle-96
      // month/prefix maps (unavailableReturnFa). Names ride playerFa with the
      // honest-English fallback (Loftus-Cheek contract). Unmapped unavailability
      // TYPES drop their chip (honest convention, like weather keys/insights).
      const UNAVAILABLE_TYPE_FA: Record<string, string> = {
        injury: "مصدومیت",
        internationalduty: "اعزام به تیم ملی",
      };
      const isNum = (v: unknown): v is number => typeof v === "number" && Number.isFinite(v);
      const unavailable = Array.isArray(t.unavailable)
        ? t.unavailable
            .map((u) => {
              const nm = (u?.name || [u?.firstName, u?.lastName].filter(Boolean).join(" ") || "").trim();
              if (!nm) return null;
              const nfa = playerFa(nm);
              const typ = (u?.unavailability?.type || "").toLowerCase();
              const retRaw = u?.unavailability?.expectedReturn || undefined;
              return {
                ...(u?.id != null ? { id: u.id } : {}),
                name: nm,
                ...(nfa && nfa !== nm ? { nameFa: nfa } : {}),
                ...(typ ? { type: typ, ...(UNAVAILABLE_TYPE_FA[typ] ? { typeFa: UNAVAILABLE_TYPE_FA[typ] } : {}) } : {}),
                ...(retRaw ? { returnRaw: retRaw } : {}),
                returnFa: unavailableReturnFa(retRaw),
              };
            })
            .filter((u): u is NonNullable<typeof u> => u !== null)
        : undefined;
      return {
        teamId: t.id,
        name: t.name,
        fa: teamFa(t.name) || t.name,
        formation: t.formation || undefined,
        coach: coachName,
        coachFa: coachName ? playerFa(coachName) : undefined,
        ...(isNum(t.averageStarterAge) ? { starterAge: t.averageStarterAge } : {}),
        ...(isNum(t.totalStarterMarketValue)
          ? { totalMarketValue: t.totalStarterMarketValue, totalMarketValueFa: marketValueFa(t.totalStarterMarketValue) }
          : {}),
        ...(unavailable?.length ? { unavailable } : {}),
        rows: clusterRows(t.starters),
        subs: (t.subs || []).slice(0, 12).map((s) => ({ id: s.id, name: s.name, nameFa: playerFa(s.name), shirt: s.shirtNumber || undefined })),
      };
    };
    lineups = { home: build(lu.homeTeam), away: build(lu.awayTeam) };
  }

  // ---------------- info box ----------------
  const infoBox = raw.content?.matchFacts?.infoBox || {};
  const md = infoBox["Match Date"] as { utcTime?: string } | undefined;
  const st = infoBox["Stadium"] as { name?: string; city?: string; capacity?: number; surface?: string } | undefined;
  const rf = infoBox["Referee"] as { text?: string; stats?: { type?: string; value?: number; average?: number; averageType?: string }[] } | undefined;
  const at = infoBox["Attendance"] as unknown;
  const tn = infoBox["Tournament"] as { leagueName?: string; roundName?: string } | undefined;
  const roundRaw = g.leagueRoundName || tn?.roundName || "";
  // cycle-115: referee & stadium facts — the Referee.stats block (matches,
  // yellow/foul per-match averages with their league-average comparison,
  // red cards, penalties) + Stadium capacity/surface. Unknown stat types
  // drop (honest convention, like weather keys/insights/legend tKeys);
  // averageType outside the above/below enum falls back to "average" only
  // when a league average exists at all.
  const num = (v: unknown): number | undefined => (typeof v === "number" && Number.isFinite(v) ? v : undefined);
  const statOf = (t: string) => rf?.stats?.find((s) => s?.type === t);
  const vsOf = (s?: { average?: number; averageType?: string }): "above" | "below" | "average" | undefined =>
    s?.averageType === "above" || s?.averageType === "below" ? s.averageType : s?.average != null ? "average" : undefined;
  const yc = statOf("yellowCards");
  const fl = statOf("fouls");
  const refereeStats =
    rf?.stats?.length || rf?.text
      ? {
          ...(num(statOf("matches")?.value) != null ? { matches: num(statOf("matches")?.value) } : {}),
          ...(num(yc?.value) != null ? { yellowPerMatch: num(yc?.value) } : {}),
          ...(num(yc?.average) != null ? { yellowAvg: num(yc?.average) } : {}),
          ...(vsOf(yc) ? { yellowVs: vsOf(yc) } : {}),
          ...(num(statOf("redCards")?.value) != null ? { red: num(statOf("redCards")?.value) } : {}),
          ...(num(statOf("penalties")?.value) != null ? { penalties: num(statOf("penalties")?.value) } : {}),
          ...(num(fl?.value) != null ? { foulsPerMatch: num(fl?.value) } : {}),
          ...(num(fl?.average) != null ? { foulsAvg: num(fl?.average) } : {}),
          ...(vsOf(fl) ? { foulsVs: vsOf(fl) } : {}),
        }
      : undefined;
  const stadiumExtra =
    typeof st?.capacity === "number" || typeof st?.surface === "string"
      ? {
          ...(typeof st?.capacity === "number" ? { capacity: st.capacity } : {}),
          ...(typeof st?.surface === "string" ? { surface: st.surface } : {}),
        }
      : undefined;
  const info: MatchDetailNormalized["info"] = {
    stadium: st?.name,
    city: st?.city,
    referee: rf?.text,
    attendance: typeof at === "number" ? at.toLocaleString("en-US") : (typeof at === "string" ? at : undefined),
    date: md?.utcTime || utcTime,
    tournament: tn?.leagueName || leagueName,
    round: roundFa(roundRaw || undefined),
    refereeStats,
    stadiumExtra,
  };

  // ---------------- attacking zones (update cycle-97, halves cycle-187) ---
  // cycle-187 closes the boundary cycle-97 declared in v1: firstHalf/
  // secondHalf joins the normalization. Every value defensively coerced;
  // a period key is emitted only when its shares sum > 0 (honest per-period
  // omission); all-zero total → null → the stats tab hides the block
  // (unchanged).
  let zones: MatchDetailNormalized["zones"] = null;
  const az = raw.content?.attackingZones;
  type ZoneSides = NonNullable<MatchDetailNormalized["zones"]>;
  const periodOf = (p?: { left?: number; center?: number; right?: number } | null) => ({
    left: typeof p?.left === "number" ? p.left : 0,
    center: typeof p?.center === "number" ? p.center : 0,
    right: typeof p?.right === "number" ? p.right : 0,
  });
  const zoneOf = (s?: {
    total?: { left?: number; center?: number; right?: number };
    firstHalf?: { left?: number; center?: number; right?: number };
    secondHalf?: { left?: number; center?: number; right?: number };
  } | null): ZoneSides["home"] => {
    // legacy triple first, in the legacy order — pre-187 consumers see the
    // exact same key sequence; optional halves append after it
    const z: ZoneSides["home"] = {
      left: typeof s?.total?.left === "number" ? s.total.left : 0,
      center: typeof s?.total?.center === "number" ? s.total.center : 0,
      right: typeof s?.total?.right === "number" ? s.total.right : 0,
    };
    const h1 = periodOf(s?.firstHalf);
    const h2 = periodOf(s?.secondHalf);
    if (h1.left + h1.center + h1.right > 0) z.firstHalf = h1;
    if (h2.left + h2.center + h2.right > 0) z.secondHalf = h2;
    return z;
  };
  if (az?.home && az?.away) {
    const zh = zoneOf(az.home);
    const za = zoneOf(az.away);
    if (zh.left + zh.center + zh.right > 0 || za.left + za.center + za.right > 0) {
      zones = { home: zh, away: za };
    }
  }

  // ---------------- weather (update cycle-100) ----------------
  // Honest-subset normalization: every value defensively coerced; the card
  // renders only when at least one displayable value exists.
  let weather: MatchDetailNormalized["weather"] = null;
  const w = raw.content?.weather;
  if (w && typeof w === "object") {
    const key = typeof w.localizedKey === "string" ? w.localizedKey : "";
    const condFa = WEATHER_FA[key];
    const condition =
      condFa ||
      (typeof w.defaultTitle === "string" && w.defaultTitle.trim()) ||
      "";
    const hasAny =
      !!condition ||
      typeof w.temperature === "number" ||
      typeof w.relativeHumidity === "number" ||
      typeof w.cloudCover === "number" ||
      typeof w.precipChance === "number";
    if (hasAny) {
      weather = {
        condition,
        conditionSource: condFa ? "localized" : "upstream",
        temperature: typeof w.temperature === "number" ? w.temperature : undefined,
        humidity: typeof w.relativeHumidity === "number" ? w.relativeHumidity : undefined,
        cloudCover: typeof w.cloudCover === "number" ? w.cloudCover : undefined,
        precipChance: typeof w.precipChance === "number" ? w.precipChance : undefined,
        forecast: w.apiUsed === "forecast",
      };
    }
  }

  // ---------------- team form ----------------
  const tf = raw.content?.matchFacts?.teamForm;
  let form: MatchDetailNormalized["form"] = null;
  if (Array.isArray(tf) && tf.length === 2) {
    const mapForm = (arr: { resultString?: string }[]) =>
      (arr || []).slice(0, 5).map((f) => (f.resultString || "").charAt(0).toUpperCase()).filter((c) => "WDL".includes(c));
    form = { home: mapForm(tf[0]), away: mapForm(tf[1]) };
  }

  // ---------------- momentum ----------------
  const momData = raw.content?.momentum?.main?.data;
  const momentum =
    momData && momData.length > 4
      ? momData
          .filter((m) => typeof m.minute === "number")
          .map((m) => ({ minute: m.minute as number, value: m.value ?? 0 }))
      : null;

  const pom = raw.content?.matchFacts?.playerOfTheMatch;
  const pomNameRaw = pom?.name;
  const pomName = pom
    ? typeof pomNameRaw === "string"
      ? pomNameRaw
      : pomNameRaw?.fullName || [pomNameRaw?.firstName, pomNameRaw?.lastName].filter(Boolean).join(" ") || null
    : null;
  const pomRating = pom?.rating?.num || null;

  // rich best-player card: flatten the "Top stats" group into display rows
  let pomStats: { title: string; display: string }[] = [];
  if (pom?.stats?.length) {
    const grp =
      pom.stats.find((s) => (s.key || "").toLowerCase() === "top_stats") ||
      pom.stats.find((s) => (s.title || "").toLowerCase().includes("top")) ||
      pom.stats[0];
    for (const [humanTitle, entry] of Object.entries(grp?.stats || {})) {
      const v = entry?.stat;
      if (!v || typeof v.value !== "number" || v.type === "boolean") continue;
      let display: string;
      if (v.type === "fractionWithPercentage" && typeof v.total === "number") {
        display = `${Math.round(v.value)}/${Math.round(v.total)}`;
      } else if (v.type === "double") {
        display = v.value.toFixed(2);
      } else {
        display = String(Math.round(v.value));
      }
      const key = (entry?.key || humanTitle || "").toLowerCase();
      pomStats.push({ title: STAT_FA[key] || humanTitle, display });
    }
    pomStats = pomStats.slice(0, 8);
  }
  const playerOfTheMatch = pomName
    ? {
        id: typeof pom?.id === "number" ? pom.id : undefined,
        name: pomName,
        nameFa: playerFa(pomName),
        rating: pomRating,
        teamId: typeof pom?.teamId === "number" ? pom.teamId : undefined,
        teamName: pom?.teamName || undefined,
        teamLogo: fotmobTeamLogo(typeof pom?.teamId === "number" ? pom.teamId : 0),
        minutes: typeof pom?.minutesPlayed === "number" ? pom.minutesPlayed : undefined,
        role: pom?.role || undefined,
        stats: pomStats,
      }
    : null;

  // ---------------- video highlights (update cycle-125) ----------------
  // matchFacts.highlights = the official YouTube highlight link + thumbnail
  // (live-probed: featured finished matches only — 5071457/5795486 have it,
  // 5071463 does not). Strict protocol guards: ONLY https youtube.com/watch
  // links normalize (anything else → null, legend-111 honest absence); the
  // thumbnail is guarded separately and may be empty (the card degrades to a
  // text row — no broken-image risk on blocked-CDN clients thanks to the
  // site-wide onError-hide pattern).
  const hl = raw.content?.matchFacts?.highlights;
  const highlights =
    hl && typeof hl.url === "string" && /^https:\/\/(www\.)?youtube\.com\/watch/.test(hl.url)
      ? {
          url: hl.url,
          image:
            typeof hl.image === "string" && /^https:\/\/i\.ytimg\.com\//.test(hl.image)
              ? hl.image
              : "",
          source: typeof hl.source === "string" && hl.source ? hl.source : "www.youtube.com",
        }
      : null;

  // ---------------- post-match review feed (update cycle-191) ----------------
  // matchFacts.postReview = Opta's post-match articles («گزارش‌های بازی»).
  // Live-probed UA Chrome/124, 2026-10-30: the array repeats ONE article in
  // several languages — ids carry a "_lang" suffix (5749727: one article,
  // 8 entries en/es/pt-BR/fr/it/de/ar/pt). Dedupe: group by the base id
  // (suffix stripped), the "en" entry wins its group (else the first seen),
  // capped at 3 articles. Strict guards per the 125 protocol: BOTH a
  // non-empty title AND a https www.fotmob.com/news/ shareUrl are required;
  // the image is guarded separately (foreign/absent → "", the row degrades
  // to a text row — no broken-image risk, the onError-hide pattern). The
  // block is null when nothing survives (honest absence — 5765944 is
  // finished yet carries no postReview; upcoming matches never do).
  const prList = raw.content?.matchFacts?.postReview;
  let reviews: MatchDetailNormalized["reviews"] = null;
  if (Array.isArray(prList) && prList.length > 0) {
    const SUFFIX_RE = /_[a-z]{2}(?:-[A-Za-z]{2})?$/;
    const groups = new Map<string, (typeof prList)[number]>();
    for (const a of prList) {
      if (!a || typeof a !== "object") continue;
      if (typeof a.title !== "string" || !a.title.trim()) continue;
      if (typeof a.shareUrl !== "string" || !/^https:\/\/www\.fotmob\.com\/news\//.test(a.shareUrl)) continue;
      const base = typeof a.id === "string" && a.id ? a.id.replace(SUFFIX_RE, "") : a.title;
      const prev = groups.get(base);
      if (!prev || (a.lang === "en" && prev.lang !== "en")) groups.set(base, a);
      if (groups.size >= 3) break;
    }
    const rows: MatchReview[] = [];
    for (const a of groups.values()) {
      rows.push({
        title: a.title!,
        description: typeof a.description === "string" ? a.description : "",
        image: typeof a.image === "string" && /^https:\/\//.test(a.image) ? a.image : "",
        source: typeof a.source === "string" && a.source ? a.source : "FotMob",
        url: a.shareUrl!,
        date: typeof a.dateUpdated === "string" && a.dateUpdated ? a.dateUpdated : undefined,
      });
    }
    if (rows.length > 0) reviews = rows;
  }

  // matchFacts.topPlayers = the top-5 rated players per side («برترین‌های
  // بازی»). Live-probed UA Chrome/124, 2026-10-30: 5749721 → 5+5 entries;
  // the upcoming 5868120 carries EMPTY arrays. The block rides the payload
  // already fetched (zero extra upstream calls). Guards: a row needs
  // playerId > 0 (the 167 convention), a non-empty fullName and a non-empty
  // playerRatingRounded; cap 5 per side (upstream's own curation). The
  // block is null when both sides end up empty (honest absence — the 191
  // reviews family). nameFa rides playerFa at normalize time (match TTL
  // 25s — always fresh, no player:v7 L2 staleness surface here).
  const tpUp = raw.content?.matchFacts?.topPlayers;
  let topPlayers: MatchDetailNormalized["topPlayers"] = null;
  if (tpUp && typeof tpUp === "object") {
    const mapTpSide = (list: unknown): MatchTopPlayer[] => {
      if (!Array.isArray(list)) return [];
      const rows: MatchTopPlayer[] = [];
      for (const e of list) {
        if (!e || typeof e !== "object") continue;
        const t = e as {
          playerId?: unknown;
          name?: { fullName?: unknown };
          playerRatingRounded?: unknown;
          manOfTheMatch?: unknown;
          positionLabel?: { label?: unknown };
        };
        const id = typeof t.playerId === "number" ? t.playerId : 0;
        const nm = t.name?.fullName;
        const rt = t.playerRatingRounded;
        if (!(id > 0) || typeof nm !== "string" || !nm.trim()) continue;
        if (typeof rt !== "string" || !rt.trim()) continue;
        const posUp = t.positionLabel?.label;
        rows.push({
          id,
          name: nm,
          nameFa: playerFa(nm),
          rating: rt,
          motm: t.manOfTheMatch === true,
          pos: typeof posUp === "string" && posUp.trim() ? posUp : "",
        });
        if (rows.length >= 5) break;
      }
      return rows;
    };
    const tpHome = mapTpSide(tpUp.homeTopPlayers);
    const tpAway = mapTpSide(tpUp.awayTopPlayers);
    if (tpHome.length > 0 || tpAway.length > 0) topPlayers = { home: tpHome, away: tpAway };
  }

  // ---------------- match insights (update cycle-110) ----------------
  // Pre-match story lines (matchFacts.insights): only curated localizedTextId
  // templates render; numbers → Persian digits, team/player refs ride the
  // honest-name maps (unknown → raw upstream name). Single-team entries are
  // prefixed with the owner team's Persian name; h2h/player sentences carry
  // their subjects inline. Upstream order kept, capped at 6.
  let insights: MatchDetailNormalized["insights"] = null;
  {
    const rawIns = raw.content?.matchFacts?.insights;
    if (Array.isArray(rawIns) && rawIns.length > 0) {
      const homeName = g.homeTeam?.name || "";
      const awayName = g.awayTeam?.name || "";
      const sideNameOf = (tid?: number): string => {
        if (!tid) return "";
        if (tid === g.homeTeam?.id) return teamFa(homeName) || homeName;
        if (tid === g.awayTeam?.id) return teamFa(awayName) || awayName;
        return "";
      };
      const fill = (tpl: string, svs: FMInsightStatValue[]): string =>
        tpl.replace(/\{(\d+)\}/g, (_m, idx: string) => {
          const sv = svs[Number(idx)];
          if (!sv) return "…";
          if (typeof sv.name === "string" && sv.name) {
            const mapped = sv.type === "team" ? teamFa(sv.name) : playerFa(sv.name);
            return mapped || sv.name;
          }
          const n = sv.value;
          return n === null || n === undefined ? "…" : faDigits(n);
        });
      const out: NonNullable<MatchDetailNormalized["insights"]> = [];
      for (const it of rawIns) {
        const tpl = it.localizedTextId ? MATCH_INSIGHT_FA[it.localizedTextId] : undefined;
        if (!tpl) continue; // unknown template → honest drop
        const svs = Array.isArray(it.statValues) ? it.statValues : [];
        let text = fill(tpl, svs);
        if (text.includes("…")) continue; // incomplete placeholder set → skip
        const kind: "team" | "player" | "h2h" =
          it.localizedTextId === "h2h_winstreak" ? "h2h" : it.type === "player" ? "player" : "team";
        if (kind === "team") {
          const side = sideNameOf(it.teamId);
          if (side) text = `${side} — ${text}`;
        }
        const color =
          (typeof it.color === "string" && it.color) ||
          (it.teamId === g.homeTeam?.id ? g.teamColors?.darkMode?.home || "#5b8def" : g.teamColors?.darkMode?.away || "#f59e0b");
        out.push({ text, color, kind });
        if (out.length >= 6) break;
      }
      if (out.length > 0) insights = out;
    }
  }

  // ---------------- season top scorers of the two sides (update cycle-117) ----------------
  // matchFacts.topScorers: each side's LEAGUE season top scorer + their
  // season line (goals/assists/xG/minutes-per-goal/MOTM/rating/games).
  // Every number coerced through the finite guard; a side with no name or
  // no displayable season numbers drops; the whole block is null when the
  // payload lacks it (some feeds do — probed Brazilian Série A) → the h2h
  // tab hides the card (cycle-111 legend convention). No cache-key bump:
  // the 25s matchDetails cache self-heals.
  let topScorers: MatchDetailNormalized["topScorers"] = null;
  {
    const ts = raw.content?.matchFacts?.topScorers;
    const n = (v: unknown): number | undefined =>
      typeof v === "number" && Number.isFinite(v) ? v : undefined;
    const sideOf = (p?: FMTopScorerPlayer | null, side?: "home" | "away"): TopScorerSide | null => {
      if (!p || !side) return null;
      const nm = (p.fullName || p.lastName || "").trim();
      if (!nm) return null;
      const goals = n(p.stats?.goals);
      const assists = n(p.stats?.goalAssist);
      const xgRaw = n(p.stats?.expectedGoals);
      // need at least one displayable season number to justify the entry
      if (goals == null && assists == null && xgRaw == null) return null;
      return {
        ...(typeof p.playerId === "number" && p.playerId > 0 ? { playerId: p.playerId } : {}),
        name: nm,
        nameFa: playerFa(nm),
        side,
        ...(goals != null ? { goals } : {}),
        ...(assists != null ? { assists } : {}),
        ...(xgRaw != null ? { xg: Math.round(xgRaw * 10) / 10 } : {}),
        ...(n(p.stats?.minsPlayedGoal) != null ? { minsPerGoal: n(p.stats?.minsPlayedGoal) } : {}),
        ...(n(p.stats?.motm) != null ? { motm: n(p.stats?.motm) } : {}),
        ...(n(p.stats?.playerRating) != null ? { rating: n(p.stats?.playerRating) } : {}),
        ...(n(p.stats?.gamesPlayed) != null ? { games: n(p.stats?.gamesPlayed) } : {}),
      };
    };
    const h = sideOf(ts?.homePlayer, "home");
    const a = sideOf(ts?.awayPlayer, "away");
    if (h || a) topScorers = { home: h, away: a };
  }

  return {
    match: {
      id: matchId,
      leagueName,
      leagueFa: lgCfg?.faName || competitionFa(leagueName, ccode) || leagueName,
      ccode,
      leagueId: g.leagueId ?? 0,
      round: info.round,
      utcTime,
      started,
      finished,
      cancelled,
      live,
      minute,
      statusText: hs.reason?.long || undefined,
      home,
      away,
    },
    scorers,
    events,
    statGroups,
    statPeriods,
    lineups,
    info,
    form,
    momentum,
    zones,
    weather,
    insights,
    topScorers,
    shootout,
    shots,
    xg,
    playerStats,
    playerOfTheMatch,
    highlights,
    reviews,
    topPlayers,
    fetchedAt: new Date().toISOString(),
  };
}

// ---------------- route handler ----------------
// FotMob answers HTTP 200 with {error:true, message:"Data not found"} for
// unknown ids → distinguishable "not found", not a gateway failure
class MatchNotFoundError extends Error {}

export async function GET(_req: Request, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  if (!/^\d{3,12}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسه مسابقه نامعتبر است" }, { status: 400 });
  }

  try {
    const norm = await cached(`matchDetails:${id}`, 25_000, async () => {
      const raw = await fetchJson<FMMatchDetails>(
        `https://www.fotmob.com/api/data/matchDetails?matchId=${id}`
      );
      if (raw && typeof raw === "object" && (raw as { error?: unknown }).error === true) {
        throw new MatchNotFoundError("Data not found");
      }
      if (!raw?.general?.homeTeam) throw new Error("Empty match payload");
      return normalize(raw, id);
    });
    return NextResponse.json({ ok: true, ...norm });
  } catch (err) {
    console.error("[api/match]", err);
    const msg = err instanceof Error ? err.message : "";
    if (err instanceof MatchNotFoundError || /\bHTTP 404\b/.test(msg)) {
      return NextResponse.json({ ok: false, error: "مسابقه یافت نشد." }, { status: 404 });
    }
    return NextResponse.json(
      { ok: false, error: "خطا در دریافت جزئیات مسابقه" },
      { status: 502 }
    );
  }
}
