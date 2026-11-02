// ------------------------------------------------------------------
// Remontada — /api/day-calendar?date=YYYY-MM-DD  (update cycle-422)
// The DAY-level calendar — the fourth rung of the ICS ladder (312 league
// season → 420 team season → 421 single fixture → 422 whole matchday):
// every match of one day as an RFC 5545 file. Source = getMatchesByDate —
// the SAME cached payload /api/matches (the home day feed) already reads,
// so the file always reflects exactly what the home day view shows (zero
// new upstream requests). Date contract = the home page's own deep-link
// language ?date=YYYY-MM-DD (the cycle-297 URL contract), validated with
// the same regex PLUS the cycle-299 calendar re-serialization (impossible
// dates are rejected, never rolled over), then mapped onto the feed's ±7
// day window — outside → honest 400 BEFORE any upstream touch. An empty
// matchday degrades to a valid empty VCALENDAR (the 312 empty-season
// precedent); an outage → 502 (the getter throws when both the fotmob
// wire and its ESPN fallback fail). UID namespace
// remontada-day-{yyyymmdd}-fixture-{matchId}@remontada so a matchday
// subscription coexists with the league/team/match ones. Cancelled
// matches ride STATUS:CANCELLED (the 421 convention). SUMMARY carries the
// competition in parentheses — leagueFa Persian, honest raw fallback.
// ------------------------------------------------------------------
import { NextRequest, NextResponse } from "next/server";
import { dateKeyToYYYYMMDD, getMatchesByDate } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";
import { jalaliShort } from "@/lib/format";
import { foldLine, icsText, icsUtc } from "@/lib/ics";

export const dynamic = "force-dynamic";

// the home deep-link regex (cycle-297) — shape first, calendar honesty second
const DATE_RE = /^(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;

export async function GET(req: NextRequest) {
  const date = req.nextUrl.searchParams.get("date") || "";
  if (!DATE_RE.test(date)) {
    return NextResponse.json(
      { ok: false, error: "تاریخ نامعتبر است؛ قالب درست YYYY-MM-DD است." },
      { status: 400 }
    );
  }
  // cycle-299: V8 silently rolls impossible dates (2026-02-30 → 03-02) —
  // reject by re-serializing the parsed date and comparing
  const t = Date.parse(`${date}T12:00:00Z`);
  const re = new Date(t).toISOString().slice(0, 10);
  if (!Number.isFinite(t) || re !== date) {
    return NextResponse.json(
      { ok: false, error: "تاریخ نامعتبر است؛ چنین روزی در تقویم نیست." },
      { status: 400 }
    );
  }
  // the day feed's own window (the /api/matches clamp): ±7 days
  const offset = Math.round(
    (t - Date.parse(`${new Date().toISOString().slice(0, 10)}T12:00:00Z`)) / 86400000
  );
  if (offset < -7 || offset > 7) {
    return NextResponse.json(
      { ok: false, error: "تقویم بازی‌ها فقط برای ۷ روز پیش تا ۷ روز بعد در دسترس است." },
      { status: 400 }
    );
  }
  const yyyymmdd = dateKeyToYYYYMMDD(offset);
  let data;
  try {
    data = await getMatchesByDate(yyyymmdd);
  } catch {
    return NextResponse.json({ ok: false, error: "تولید تقویم روز ناموفق بود." }, { status: 502 });
  }
  const j = jalaliShort(date);
  const calName = `بازی‌های ${j.day} ${j.month} ${j.year}`;
  const nowZ = icsUtc(new Date().toISOString());
  type Row = { utcTime: string; id: string; line: string[] };
  const rows: Row[] = [];
  for (const g of data.groups) {
    for (const m of g.matches) {
      const startZ = icsUtc(m.utcTime);
      if (!startZ) continue;
      // upstream gives no end time — a 2h block is the honest default (312/420/421)
      const endIso = new Date(new Date(m.utcTime).getTime() + 2 * 3600_000).toISOString();
      const homeFa = m.home.fa || m.home.name;
      const awayFa = m.away.fa || m.away.name;
      const comp = g.leagueFa || g.leagueName;
      const lines = [
        "BEGIN:VEVENT",
        `UID:remontada-day-${yyyymmdd}-fixture-${m.id}@remontada`,
        `DTSTAMP:${nowZ}`,
        `DTSTART:${startZ}`,
        `DTEND:${icsUtc(endIso)}`,
        `SUMMARY:${icsText(comp ? `${homeFa} در برابر ${awayFa} (${comp})` : `${homeFa} در برابر ${awayFa}`)}`,
        `DESCRIPTION:${icsText(`${calName} — جزئیات، آمار و گزارش زنده در رمانتادا`)}`,
        `URL:${SITE_URL}/match/${m.id}`,
      ];
      if (m.cancelled) lines.push("STATUS:CANCELLED");
      lines.push("END:VEVENT");
      rows.push({ utcTime: m.utcTime, id: String(m.id), line: lines });
    }
  }
  rows.sort((a, b) => a.utcTime.localeCompare(b.utcTime) || a.id.localeCompare(b.id));
  const out: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Remontada//Day Fixtures//FA",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${icsText(calName)}`,
    "X-WR-TIMEZONE:UTC",
  ];
  for (const r of rows) out.push(...r.line);
  out.push("END:VCALENDAR");
  const body = out.map(foldLine).join("\r\n") + "\r\n";
  return new NextResponse(body, {
    status: 200,
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": `attachment; filename="day-${yyyymmdd}.ics"`,
      "Cache-Control": "public, max-age=60",
    },
  });
}
