// ------------------------------------------------------------------
// Remontada — /api/favorites-calendar  (update cycle-425)
// The PERSONAL rung of the subscription-calendar ladder (312 league ->
// 420 team -> 421 fixture -> 422 matchday -> 425 favorites): every
// fixture of the user's favorited teams, merged into ONE RFC 5545 file.
// Source = getTeamFixturesAll per id — the SAME cached data/teams payload
// the team route (420) reads — zero new upstream request shapes; the ids
// come from the client's own favorites store (the same list the UI shows).
// Contract: ids= comma-separated numeric tokens (3-12 digits each, ≤ 30 —
// the favorites store's own MAX); empty tokens / non-numerics / over-cap
// → honest 400 BEFORE any upstream touch; a team whose payload has no
// fixtures is skipped (honest absence — off-season/cups), but an upstream
// FAILURE aborts the whole file with 502 — a partial calendar that LOOKS
// complete would be a lie (the cycle-42 honesty ethos). Fixtures are
// deduped globally by id (a head-to-head fixture sits in BOTH teams'
// feeds — live-probed: 8456∩10204 = 5795502/5795626/6275368); the first
// requested team owns the UID — deterministic. UID namespace
// remontada-fav-{ownerTeamId}-fixture-{matchId}@remontada so the personal
// calendar coexists with the league/team/match subscriptions of the same
// fixture. SUMMARY carries the tournament in parentheses (the 420
// convention — already Persian in the payload). Cancelled fixtures never
// reach this payload (getTeamFixturesAll filters them upstream of the
// route — the 420 semantics), so no STATUS:CANCELLED is emitted here.
// ------------------------------------------------------------------
import { NextResponse } from "next/server";
import { getTeamFixturesAll } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";
import { foldLine, icsText, icsUtc } from "@/lib/ics";

export const dynamic = "force-dynamic";

// the favorites store's own cap (src/lib/favorites.ts MAX = 30)
const MAX_FAVS = 30;

export async function GET(req: Request) {
  const raw = new URL(req.url).searchParams.get("ids") || "";
  if (raw.trim() === "") {
    return NextResponse.json({ ok: false, error: "هیچ تیمی انتخاب نشده است." }, { status: 400 });
  }
  // the strict list contract: NO empty segments (a «8456,,8668» or a trailing
  // comma is a malformed list — honest 400, never a silent repair)
  const tokens = raw.split(",").map((t) => t.trim());
  if (tokens.some((t) => t.length === 0)) {
    return NextResponse.json({ ok: false, error: "شناسهٔ تیم نامعتبر است." }, { status: 400 });
  }
  if (!tokens.every((t) => /^\d{3,12}$/.test(t))) {
    return NextResponse.json({ ok: false, error: "شناسهٔ تیم نامعتبر است." }, { status: 400 });
  }
  if (tokens.length > MAX_FAVS) {
    return NextResponse.json(
      { ok: false, error: `بیش از ${MAX_FAVS} تیم مجاز نیست.` },
      { status: 400 }
    );
  }
  // a repeated id is one team (the store itself dedupes — belt and braces)
  const ids: number[] = [];
  const seen = new Set<number>();
  for (const t of tokens) {
    const n = Number(t);
    if (!seen.has(n)) {
      seen.add(n);
      ids.push(n);
    }
  }

  type MergedRow = {
    owner: number;
    id: number;
    utcTime: string;
    home: { id: number; name: string; fa: string };
    away: { id: number; name: string; fa: string };
    tournamentFa: string;
  };
  const merged = new Map<number, MergedRow>();
  try {
    for (const id of ids) {
      const fixtures = await getTeamFixturesAll(id);
      // honest absence: this team simply has no fixtures (off-season/cup) — skip
      if (!fixtures) continue;
      for (const f of [...fixtures.results, ...fixtures.upcoming]) {
        // global dedupe by fixture id — the first requested team owns the event
        if (!merged.has(f.id)) {
          merged.set(f.id, {
            owner: id,
            id: f.id,
            utcTime: f.utcTime,
            home: { id: f.home.id, name: f.home.name, fa: f.home.fa },
            away: { id: f.away.id, name: f.away.name, fa: f.away.fa },
            tournamentFa: f.tournamentFa,
          });
        }
      }
    }
  } catch {
    return NextResponse.json(
      { ok: false, error: "تولید تقویم منتخب‌ها ناموفق بود." },
      { status: 502 }
    );
  }
  if (merged.size === 0) {
    return NextResponse.json(
      { ok: false, error: "فیکسچری برای تیم‌های منتخب یافت نشد." },
      { status: 404 }
    );
  }
  const all = [...merged.values()].sort((a, b) => a.utcTime.localeCompare(b.utcTime));
  const calName = "بازی‌های تیم‌های منتخب من";
  const nowZ = icsUtc(new Date().toISOString());
  const lines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Remontada//Favorites Fixtures//FA",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${icsText(calName)}`,
    "X-WR-TIMEZONE:UTC",
  ];
  for (const f of all) {
    const startZ = icsUtc(f.utcTime);
    if (!startZ) continue;
    // upstream gives no end time — a 2h block is the honest default (the 312/420 convention)
    const endDate = new Date(new Date(f.utcTime).getTime() + 2 * 3600_000);
    lines.push(
      "BEGIN:VEVENT",
      `UID:remontada-fav-${f.owner}-fixture-${f.id}@remontada`,
      `DTSTAMP:${nowZ}`,
      `DTSTART:${startZ}`,
      `DTEND:${icsUtc(endDate.toISOString())}`,
      `SUMMARY:${icsText(`${f.home.fa || f.home.name} در برابر ${f.away.fa || f.away.name} (${f.tournamentFa})`)}`,
      `DESCRIPTION:${icsText(`${calName} — همهٔ بازی‌های فصل تیم‌های منتخب`)}`,
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
      "Content-Disposition": 'attachment; filename="favorites.ics"',
      "Cache-Control": "public, max-age=60",
    },
  });
}
