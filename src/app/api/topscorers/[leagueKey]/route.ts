// ------------------------------------------------------------------
// Remontada — /api/topscorers/[leagueKey]
// Full top-scorers list of ONE league (from the league payload stats,
// enriched with assists / G+A / xG / rating / minutes by player id).
// Uses the same 60-min cached getStandings payload — no extra FotMob hit.
// cycle-174 additive: the response now also carries the freshened assists
// block (same payload, same zero extra upstream cost) so the per-league
// topscorers page can render «بهترین پاس‌دهندگان» like its sister page.
// cycle-179 additive: same sister-page consistency one surface over — the
// SAME cached payload has carried the cycle-176 cards block since the v8
// bump; the route dropped it exactly like it dropped assists before 174.
// cycle-180 additive: optional historical season — the exact cycle-55
// contract the standings route has honored since day one (strict
// SEASON_PARAM_RE shape → getStandings(key, season)); the per-league
// topscorers page was the only league-scoped surface still stuck on the
// current season. The response also carries selectedSeason + allSeasons
// (the cycle-55 payload fields) so the selector's options come from the
// payload itself and the UI can honestly snap a bogus-but-well-formed
// season back to what is actually shown (the cycle-99 marker contract).
// cycle-210 additive: the ratings block («آقای امتیاز») rides the SAME
// cached payload — the deep-file family's next sibling (goals/assists/
// cards), decimal values verbatim; old consumers never read this field
// (the 108 rule).
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getStandings, LeagueUnavailableError } from "@/lib/fotmob";
import { SEASON_PARAM_RE } from "@/lib/season";
import { LEAGUES } from "@/lib/leagues";

export const dynamic = "force-dynamic";

const VALID_KEYS = LEAGUES.map((l) => l.key);

export async function GET(req: Request, { params }: { params: Promise<{ leagueKey: string }> }) {
  const { leagueKey } = await params;

  if (!VALID_KEYS.includes(leagueKey)) {
    return NextResponse.json({ ok: false, error: "لیگ ناشناخته است." }, { status: 404 });
  }

  // cycle-180 additive: the cycle-55 season contract, byte-for-byte the
  // standings route's guard — strict "YYYY/YYYY" shape, anything else → 400.
  const season = new URL(req.url).searchParams.get("season") || undefined;
  if (season && !SEASON_PARAM_RE.test(season)) {
    return NextResponse.json({ ok: false, error: `Invalid season: ${season}` }, { status: 400 });
  }

  try {
    const st = await getStandings(leagueKey, season);
    return NextResponse.json({
      ok: true,
      leagueKey: st.leagueKey,
      leagueFa: st.leagueFa,
      season: st.season,
      // cycle-180 additive: the payload's own season marker + offer list —
      // old consumers never read these fields (the 108 rule); the UI uses
      // selectedSeason for the honest label and allSeasons for the selector.
      selectedSeason: st.selectedSeason,
      allSeasons: st.allSeasons,
      scorers: st.scorers,
      // cycle-174 additive: assists ride the SAME cached payload — consumers
      // written before this field never read it (the 108 additive contract).
      assists: st.assists,
      // cycle-210 additive: «آقای امتیاز» rides the SAME cached payload —
      // the deep-file family's next sibling, decimal ratings verbatim; old
      // consumers never read this field (the 108 rule).
      ratings: st.ratings,
      // cycle-215 additive: «گل نخرده‌ها» rides the SAME cached payload —
      // the deep-file family's next sibling and the portal's first
      // goalkeeper surface, integer values; old consumers never read this
      // field (the 108 rule).
      cleanSheets: st.cleanSheets,
      // cycle-216 additive: «گل+پاس» rides the SAME cached payload — the
      // deep-file family's sixth sibling, the upstream's OWN combined
      // participation ranking (integer values); old consumers never read
      // this field (the 108 rule).
      gPlusA: st.gPlusA,
      // cycle-217 additive: «گل‌های پیشگیری‌شده» rides the SAME cached
      // payload — the deep-file family's SEVENTH sibling and the FIRST
      // SIGNED one (SIGNED DECIMAL values verbatim — the rating
      // convention); old consumers never read this field (the 108 rule).
      goalsPrevented: st.goalsPrevented,
      // cycle-220 additive: «بیشترین دقایق» rides the SAME cached payload —
      // the deep-file family's EIGHTH sibling and the first PRESENCE
      // surface (integer minutes — the 215/216 convention); old consumers
      // never read this field (the 108 rule).
      minutes: st.minutes,
      // cycle-221 additive: «درصد سیو» rides the SAME cached payload — the
      // deep-file family's NINTH sibling and the THIRD keeper surface
      // (percent values with one decimal, verbatim — the 210/217
      // convention; honest [] on persiangulf, probed); old consumers never
      // read this field (the 108 rule).
      savePercentage: st.savePercentage,
      // cycle-222 additive: «سیو در هر ۹۰» rides the SAME cached payload —
      // the deep-file family's TENTH sibling and the FOURTH keeper surface
      // (per-90 decimal values with one decimal, verbatim — the 210/217/221
      // convention; honest [] on persiangulf, probed); old consumers never
      // read this field (the 108 rule).
      savesPer90: st.savesPer90,
      // cycle-225 additive: «پنالتی‌های مهارشده» rides the SAME cached
      // payload — the deep-file family's ELEVENTH sibling and the FIFTH
      // keeper surface (naturally thin 2-5-row files, integer values —
      // the 215 convention; honest [] on persiangulf AND on every
      // historical season, probed); old consumers never read this field
      // (the 108 rule).
      penaltySaves: st.penaltySaves,
      // cycle-226 additive: «گل مورد انتظار» rides the SAME cached payload —
      // the deep-file family's TWELFTH sibling and the first pure-ANALYTICS
      // surface (decimal xG values verbatim — the 210/217 convention;
      // season-aware like goals/assists; honest [] on persiangulf, probed);
      // old consumers never read this field (the 108 rule).
      xg: st.xg,
      // cycle-227 additive: «گل در هر ۹۰» rides the SAME cached payload —
      // the deep-file family's THIRTEENTH sibling and the production-RATE
      // surface (decimal values verbatim, up to two decimals — the
      // 210/217/226 convention; season-aware like goals/assists/xG; honest
      // [] on mas, probed; PERSIANGULF SERVES — 93 rows, the first deep
      // sibling besides minutes to reach the home league); old consumers
      // never read this field (the 108 rule).
      goalsPer90: st.goalsPer90,
      // cycle-230 additive: «پاس مورد انتظار» rides the SAME cached payload —
      // the deep-file family's FOURTEENTH sibling and the assist-side
      // ANALYTICS twin of the xG surface (decimal xA values verbatim,
      // exactly one decimal — the 210/217/226 convention; season-aware
      // like goals/assists/xG/gp90; honest [] on persiangulf AND mas,
      // probed); old consumers never read this field (the 108 rule).
      xa: st.xa,
      // cycle-231 additive: «سانس بزرگ خلق‌شده» rides the SAME cached payload —
      // the deep-file family's FIFTEENTH sibling and the production-CREATION
      // volume surface beside the analytics twins (integer values rounded
      // once at build — the 215/220 convention; season-aware like the
      // decimal sisters; honest [] on persiangulf AND mas, probed); old
      // consumers never read this field (the 108 rule).
      bigChancesCreated: st.bigChancesCreated,
      // cycle-232 additive: «گل مورد انتظار روی دروازه» rides the SAME
      // cached payload — the deep-file family's SIXTEENTH sibling and the
      // third ANALYTICS level, the on-target accuracy twin of the xG
      // surface (decimal xGOT values verbatim, exactly one decimal — the
      // 210/217/226/230 convention; season-aware like the sisters; honest
      // [] on persiangulf AND mas, probed); old consumers never read this
      // field (the 108 rule).
      xgot: st.xgot,
      // cycle-235 additive: «فرصت‌های خلق‌شده» rides the SAME cached
      // payload — the deep-file family's SEVENTEENTH sibling and the
      // TOTAL-creation VOLUME twin of the BCC surface (integer values
      // rounded once at build — the 215/220 convention; season-aware like
      // the sisters; honest [] on persiangulf AND mas, probed); old
      // consumers never read this field (the 108 rule).
      chancesCreated: st.chancesCreated,
      // cycle-236 additive: «سانس بزرگ ازدست‌رفته» rides the SAME cached
      // payload — the deep-file family's EIGHTEENTH sibling and the
      // MISSED-volume twin of the BCC surface (integer values rounded once
      // at build — the 215/220 convention; season-aware like the sisters;
      // honest [] on persiangulf AND mas, probed); old consumers never
      // read this field (the 108 rule).
      bigChancesMissed: st.bigChancesMissed,
      // cycle-237 additive: «گل مورد انتظار تیم‌ها» rides the SAME cached
      // payload — the deep-file family's NINETEENTH sibling and its FIRST
      // TEAM-PARTICIPANT member: the team-side LEVEL of the xG surface
      // (decimal values verbatim, exactly one decimal — the
      // 210/217/226/230/232 convention; season-aware like the sisters;
      // honest [] on persiangulf AND mas, probed); old consumers never
      // read this field (the 108 rule).
      teamXg: st.teamXg,
      // cycle-240 additive: «گل نخرده‌های تیم‌ها» rides the SAME cached
      // payload — the deep-file family's TWENTIETH sibling and its SECOND
      // TEAM-PARTICIPANT member: the team-side LEVEL of the keeper clean
      // sheets surface (the team twin relationship 237 established;
      // INTEGER values verbatim — the 215/220/231/235/236 convention;
      // season-aware like the sisters; honest [] on persiangulf, probed;
      // mas serves a naturally-thin 8-row file, probed); old consumers
      // never read this field (the 108 rule).
      teamCleanSheets: st.teamCleanSheets,
      // cycle-241 additive: «مالکیت توپ تیم‌ها» rides the SAME cached
      // payload — the deep-file family's TWENTY-FIRST sibling and its
      // THIRD TEAM-PARTICIPANT member: the team-side possession surface
      // (percent one-decimal values verbatim — the 221 percent convention,
      // toFixed(1) dir=ltr with no appended sign; season-aware like the
      // sisters; honest [] on persiangulf AND mas — the 237 absence pair,
      // probed); old consumers never read this field (the 108 rule).
      teamPossession: st.teamPossession,
      // cycle-242 additive: «کارت‌های زرد تیم‌ها» rides the SAME cached
      // payload — the deep-file family's TWENTY-SECOND sibling and its
      // FOURTH TEAM-PARTICIPANT member: the team-side yellow-card surface
      // (INTEGER values verbatim — the 215/220/231/235/236 convention,
      // String() pill; season-aware like the sisters; honest [] on
      // persiangulf AND mas — the 237/241 absence pair, probed); old
      // consumers never read this field (the 108 rule).
      teamYellowCards: st.teamYellowCards,
      // cycle-245 additive: «کارت‌های قرمز تیم‌ها» rides the SAME cached
      // payload — the deep-file family's TWENTY-THIRD sibling and its
      // FIFTH TEAM-PARTICIPANT member: the team-side red-card surface
      // (INTEGER values verbatim — the 215/…/242 convention, String()
      // pill; season-aware like the sisters; honest [] on persiangulf
      // only — feed-driven, probed; mas SERVES — the SECOND mas
      // team-surface after 240); old consumers never read this field
      // (the 108 rule).
      teamRedCards: st.teamRedCards,
      // cycle-246 additive: «گل به از مسابقهٔ تیم‌ها» rides the SAME cached
      // payload — the deep-file family's TWENTY-FOURTH sibling and its
      // SIXTH TEAM-PARTICIPANT member: the team-side scoring-rate level
      // (1-decimal values verbatim — the 241 toFixed(1) convention;
      // season-aware like the sisters; NINE of NINE leagues serve — pg's
      // FIRST-EVER team surface + mas's third); old consumers never read
      // this field (the 108 rule).
      teamGoalsPerMatch: st.teamGoalsPerMatch,
      // cycle-247 additive: «کرنرهای تیم‌ها» rides the SAME cached payload —
      // the deep-file family's TWENTY-FIFTH sibling and its SEVENTH
      // TEAM-PARTICIPANT member: the team-side corner volume (INTEGER
      // values verbatim — the 215/…/245 convention, String() pill;
      // season-aware like the sisters; honest [] on persiangulf AND mas —
      // not in feed AND bare direct files absent, the 241 honesty; EIGHT
      // leagues serve incl. uel — the STANDARD guard class); old consumers
      // never read this field (the 108 rule).
      teamCorners: st.teamCorners,
      // cycle-179 additive: cards ride the SAME cached payload (yellow/red,
      // per-kind honest absence — mas has no yellow category). Zero extra
      // upstream calls; old consumers never read this field (the 108 rule).
      cards: st.cards,
      updatedAt: st.updatedAt,
    });
  } catch (err) {
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "دریافت گلزنان این لیگ ناموفق بود." },
      { status: 502 }
    );
  }
}
