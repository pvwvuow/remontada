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
