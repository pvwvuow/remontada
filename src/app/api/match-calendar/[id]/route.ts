// ------------------------------------------------------------------
// Remontada — /api/match-calendar/[id]  (update cycle-421)
// The MATCH-level calendar — the third rung of the ICS ladder
// (cycle-312 league season → cycle-420 team season → this: one fixture
// as a single-VEVENT RFC 5545 file for «add to calendar» deep links).
// Source = getMatchLdData — the SAME 60s-cached matchDetails payload the
// match page's SportsEvent JSON-LD already reads (zero new upstream
// requests, the 420 pattern). Honest asymmetry, documented: that getter
// never throws and deliberately conflates an outage with an unknown id
// (the cycle-18 design the page itself rides) — so BOTH answer the honest
// 404 here rather than the 502 the throwing getters (team/league) use.
// DTEND: the seo-harvested endDate when it parses and lands after kickoff,
// else the family's 2h block (upstream serves no end time on the base
// path). UID namespace remontada-match-{id}@remontada so a single-match
// event coexists with league/team subscriptions of the same fixture.
// A cancelled match still serves the event with STATUS:CANCELLED — the
// RFC-correct state — while the page CTA hides for it (the visible-CTA ⇔
// schedulable-event contract). SUMMARY carries the competition in
// parentheses, the same dimension the team feed events carry: the
// cataloged Persian leagueFa first, the honest raw leagueName fallback.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getMatchLdData } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";
import { foldLine, icsText, icsUtc } from "@/lib/ics";

export const dynamic = "force-dynamic";

export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  // pre-upstream shape guard (the team-calendar convention): ids are numeric
  if (!/^\d{3,12}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسهٔ مسابقه نامعتبر است." }, { status: 400 });
  }
  // the LD getter never throws: null = unknown id OR outage (both → honest 404)
  const m = await getMatchLdData(id).catch(() => null);
  if (!m) {
    return NextResponse.json(
      { ok: false, error: "مسابقه‌ای برای این شناسه یافت نشد." },
      { status: 404 }
    );
  }
  const startZ = icsUtc(m.utcTime);
  if (!startZ) {
    return NextResponse.json(
      { ok: false, error: "زمان شروع این مسابقه در دسترس نیست." },
      { status: 404 }
    );
  }
  const homeFa = m.homeFa || m.homeName;
  const awayFa = m.awayFa || m.awayName;
  const calName = `${homeFa} در برابر ${awayFa}`;
  const comp = m.leagueFa || m.leagueName;
  const nowZ = icsUtc(new Date().toISOString());
  // the real end time when the seo harvest carries one that lands after the
  // kickoff, else the family's honest 2h block (the 312/420 convention)
  const startMs = new Date(m.utcTime).getTime();
  const endMs = m.endDate ? new Date(m.endDate).getTime() : NaN;
  const endIso = Number.isFinite(endMs) && endMs > startMs && m.endDate ? m.endDate : new Date(startMs + 2 * 3600_000).toISOString();
  const lines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Remontada//Match Event//FA",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${icsText(calName)}`,
    "X-WR-TIMEZONE:UTC",
    "BEGIN:VEVENT",
    `UID:remontada-match-${id}@remontada`,
    `DTSTAMP:${nowZ}`,
    `DTSTART:${startZ}`,
    `DTEND:${icsUtc(endIso)}`,
    `SUMMARY:${icsText(comp ? `${calName} (${comp})` : calName)}`,
    `DESCRIPTION:${icsText(`${calName} — جزئیات، آمار و گزارش زنده در رمانتادا`)}`,
    `URL:${SITE_URL}/match/${id}`,
  ];
  if (m.stadium || m.city) {
    // the raw venue names — the same honest raw the SportsEvent LD ships
    const venue = [m.stadium, m.city].filter((v): v is string => Boolean(v)).join(" — ");
    lines.push(`LOCATION:${icsText(venue)}`);
  }
  if (m.cancelled) lines.push("STATUS:CANCELLED");
  lines.push("END:VEVENT", "END:VCALENDAR");
  const body = lines.map(foldLine).join("\r\n") + "\r\n";
  return new NextResponse(body, {
    status: 200,
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": `attachment; filename="match-${id}.ics"`,
      "Cache-Control": "public, max-age=60",
    },
  });
}
