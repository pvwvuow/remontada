// ------------------------------------------------------------------
// Remontada — /api/topscorers/[leagueKey]
// Full top-scorers list of ONE league (from the league payload stats,
// enriched with assists / G+A / xG / rating / minutes by player id).
// Uses the same 60-min cached getStandings payload — no extra FotMob hit.
// cycle-174 additive: the response now also carries the freshened assists
// block (same payload, same zero extra upstream cost) so the per-league
// topscorers page can render «بهترین پاس‌دهندگان» like its sister page.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getStandings, LeagueUnavailableError } from "@/lib/fotmob";
import { LEAGUES } from "@/lib/leagues";

export const dynamic = "force-dynamic";

const VALID_KEYS = LEAGUES.map((l) => l.key);

export async function GET(_req: Request, { params }: { params: Promise<{ leagueKey: string }> }) {
  const { leagueKey } = await params;

  if (!VALID_KEYS.includes(leagueKey)) {
    return NextResponse.json({ ok: false, error: "لیگ ناشناخته است." }, { status: 404 });
  }

  try {
    const st = await getStandings(leagueKey);
    return NextResponse.json({
      ok: true,
      leagueKey: st.leagueKey,
      leagueFa: st.leagueFa,
      season: st.season,
      scorers: st.scorers,
      // cycle-174 additive: assists ride the SAME cached payload — consumers
      // written before this field never read it (the 108 additive contract).
      assists: st.assists,
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
