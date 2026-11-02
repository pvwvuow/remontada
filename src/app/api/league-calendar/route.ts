// ------------------------------------------------------------------
// Remontada — /api/league-calendar?league={key}&season={yyyy/yyyy}
// cycle-312: the whole league season as an RFC 5545 ICS calendar file.
// Upstream feasibility probed live (UA Chrome/124): the league details
// payload exposes canSyncCalendar=true (Premier League / LaLiga / Serie A
// at probe time) but serves no REST calendar surface — so this route
// builds one from the same cached getLeagueRaw payload the fixtures tab
// already uses (zero new upstream requests). Additive: nothing existing
// changes; a season without usable rows degrades to a valid empty
// VCALENDAR, an unavailable league to the shared JSON error shapes.
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { getLeagueCalendar, LeagueUnavailableError, LEAGUES } from "@/lib/fotmob";
import { seasonParamOk } from "@/lib/season";
import { SITE_URL } from "@/lib/site";
// cycle-420: the RFC 5545 primitives moved verbatim to the shared src/lib/ics
// (the team-calendar sibling route reads the same vocabulary — one ICS
// implementation, the season.ts convention). Zero behavior change.
import { foldLine, icsText, icsUtc } from "@/lib/ics";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  const lg = LEAGUES.find((l) => l.key === key);
  if (!lg) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  // cycle-382: plain-year seasons ride the per-league plainYearSeasons flag.
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !seasonParamOk(season, lg.plainYearSeasons === true)) {
    return NextResponse.json({ ok: false, error: `Invalid season: ${season}` }, { status: 400 });
  }
  try {
    const cal = await getLeagueCalendar(key, season);
    const nowZ = icsUtc(new Date().toISOString());
    const shownSeason = cal.selectedSeason || cal.season;
    const lines: string[] = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Remontada//League Fixtures//FA",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      `X-WR-CALNAME:${icsText(`${cal.leagueFa} — فیکسچرها${shownSeason ? ` ${shownSeason}` : ""}`)}`,
      "X-WR-TIMEZONE:UTC",
    ];
    for (const ev of cal.events) {
      const startZ = icsUtc(ev.utcTime);
      if (!startZ) continue;
      // upstream gives no end time — a 2h block is the honest default
      const endDate = new Date(new Date(ev.utcTime).getTime() + 2 * 3600_000);
      lines.push(
        "BEGIN:VEVENT",
        `UID:remontada-fixture-${ev.id}@remontada`,
        `DTSTAMP:${nowZ}`,
        `DTSTART:${startZ}`,
        `DTEND:${icsUtc(endDate.toISOString())}`,
        `SUMMARY:${icsText(`${ev.homeFa} در برابر ${ev.awayFa}${ev.round ? ` (${ev.round})` : ""}`)}`,
        `DESCRIPTION:${icsText(`${cal.leagueFa}${shownSeason ? ` — فصل ${shownSeason}` : ""}`)}`,
        `URL:${SITE_URL}/match/${ev.id}`,
        "END:VEVENT"
      );
    }
    lines.push("END:VCALENDAR");
    const body = lines.map(foldLine).join("\r\n") + "\r\n";
    const fname = shownSeason ? `${key}-${shownSeason.replace(/\//g, "-")}.ics` : `${key}.ics`;
    return new NextResponse(body, {
      status: 200,
      headers: {
        "Content-Type": "text/calendar; charset=utf-8",
        "Content-Disposition": `attachment; filename="${fname}"`,
        "Cache-Control": "public, max-age=60",
      },
    });
  } catch (err) {
    if (err instanceof LeagueUnavailableError) {
      return NextResponse.json(
        { ok: false, error: "داده این لیگ موقتاً در دسترس نیست." },
        { status: 503 }
      );
    }
    return NextResponse.json(
      { ok: false, error: "تولید تقویم لیگ ناموفق بود." },
      { status: 502 }
    );
  }
}
