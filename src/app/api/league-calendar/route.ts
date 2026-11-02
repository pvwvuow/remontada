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
import { getLeagueCalendar, LeagueUnavailableError, LEAGUES, SEASON_PARAM_RE } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";

export const dynamic = "force-dynamic";

const pad2 = (n: number) => String(n).padStart(2, "0");

/** RFC 5545 UTC date-time (the Z form) — an unusable time becomes "". */
function icsUtc(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return (
    `${d.getUTCFullYear()}${pad2(d.getUTCMonth() + 1)}${pad2(d.getUTCDate())}` +
    `T${pad2(d.getUTCHours())}${pad2(d.getUTCMinutes())}${pad2(d.getUTCSeconds())}Z`
  );
}

/** RFC 5545 TEXT escaping — backslash, semicolon, comma, newlines. */
function icsText(s: string): string {
  return s
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r?\n/g, "\\n");
}

/** RFC 5545 §3.1: content lines SHOULD be ≤ 75 octets — UTF-8-safe folding. */
function foldLine(line: string): string {
  const enc = new TextEncoder();
  if (enc.encode(line).length <= 75) return line;
  const parts: string[] = [];
  let cur = "";
  let curOctets = 0;
  const limit = 74; // continuation lines spend one octet on the leading space
  for (const ch of line) {
    const octets = enc.encode(ch).length;
    if (curOctets + octets > limit) {
      parts.push(cur);
      cur = ` ${ch}`;
      curOctets = 1 + octets;
    } else {
      cur += ch;
      curOctets += octets;
    }
  }
  if (cur) parts.push(cur);
  return parts.join("\r\n");
}

export async function GET(req: NextRequest) {
  const key = req.nextUrl.searchParams.get("league") || "pl";
  if (!LEAGUES.some((l) => l.key === key)) {
    return NextResponse.json({ ok: false, error: `Unknown league key: ${key}` }, { status: 400 });
  }
  const season = req.nextUrl.searchParams.get("season") || undefined;
  if (season && !SEASON_PARAM_RE.test(season)) {
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
