// ------------------------------------------------------------------
// Remontada — /api/team-calendar/[id]  (update cycle-420)
// The TEAM-level subscription calendar — the sibling of the league-level
// /api/league-calendar (cycle-312): one club's whole season (league + cups
// + friendlies) as an RFC 5545 ICS file. Source = getTeamFixturesAll, the
// shared cached data/teams payload the team page's «همهٔ بازی‌های فصل»
// section already reads — zero new upstream requests. The team's own
// Persian name comes from the rows themselves (every row carries the team
// on one side, fa already mapped by the portal's teamFa vocabulary — the
// same mapping the UI shows).
// Contract: invalid id shape → 400 before upstream; a payload without a
// usable fixtures list → honest 404; upstream failure → 502. Events share
// the league route's honest conventions (Z-form UTC, 2h end block, TEXT
// escaping, §3.1 folding) but carry their own UID namespace
// remontada-team-{id}-fixture-{matchId}@remontada so a club calendar and a
// competition calendar can be subscribed side by side without clashing.
// SUMMARY carries the tournament in parentheses — the dimension a TEAM
// feed needs (league vs cup vs friendly), already Persian in the payload.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamFixturesAll } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";
import { foldLine, icsText, icsUtc } from "@/lib/ics";

export const dynamic = "force-dynamic";

export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  // pre-upstream shape guard (the person-OG convention): ids are numeric
  if (!/^\d{3,12}$/.test(id)) {
    return NextResponse.json({ ok: false, error: "شناسهٔ تیم نامعتبر است." }, { status: 400 });
  }
  let fixtures;
  try {
    fixtures = await getTeamFixturesAll(Number(id));
  } catch {
    return NextResponse.json({ ok: false, error: "تولید تقویم تیم ناموفق بود." }, { status: 502 });
  }
  if (!fixtures) {
    return NextResponse.json(
      { ok: false, error: "فیکسچری برای این تیم یافت نشد." },
      { status: 404 }
    );
  }
  const all = [...fixtures.results, ...fixtures.upcoming].sort((a, b) =>
    a.utcTime.localeCompare(b.utcTime)
  );
  // the team's Persian name off its own rows (every row has the team on one
  // side); honest fallbacks keep the raw name, then the bare id
  const own =
    all.find((f) => f.home.id === Number(id)) ||
    all.find((f) => f.away.id === Number(id));
  const teamFa = own
    ? own.home.id === Number(id)
      ? own.home.fa || own.home.name
      : own.away.fa || own.away.name
    : "";
  const calName = `${teamFa || `تیم ${id}`} — فیکسچرها`;
  const nowZ = icsUtc(new Date().toISOString());
  const lines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Remontada//Team Fixtures//FA",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${icsText(calName)}`,
    "X-WR-TIMEZONE:UTC",
  ];
  for (const f of all) {
    const startZ = icsUtc(f.utcTime);
    if (!startZ) continue;
    // upstream gives no end time — a 2h block is the honest default (the 312 convention)
    const endDate = new Date(new Date(f.utcTime).getTime() + 2 * 3600_000);
    lines.push(
      "BEGIN:VEVENT",
      `UID:remontada-team-${id}-fixture-${f.id}@remontada`,
      `DTSTAMP:${nowZ}`,
      `DTSTART:${startZ}`,
      `DTEND:${icsUtc(endDate.toISOString())}`,
      `SUMMARY:${icsText(`${f.home.fa || f.home.name} در برابر ${f.away.fa || f.away.name} (${f.tournamentFa})`)}`,
      `DESCRIPTION:${icsText(`${calName} — همهٔ بازی‌های فصل`)}`,
      `URL:${SITE_URL}/match/${f.id}`,
      "END:VEVENT"
    );
  }
  lines.push("END:VCALENDAR");
  const body = lines.map(foldLine).join("\r\n") + "\r\n";
  return new NextResponse(body, {
    status: 200,
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": `attachment; filename="team-${id}.ics"`,
      "Cache-Control": "public, max-age=60",
    },
  });
}
