// ------------------------------------------------------------------
// Remontada — src/lib/ics.ts (update cycle-420)
// The shared RFC 5545 primitives for the portal's two calendar routes
// (/api/league-calendar since cycle-312, /api/team-calendar since this
// cycle). Extracted VERBATIM from the league route so both subscriptions
// share one implementation — the season.ts «one regex, one contract»
// convention: one ICS vocabulary, one folding/escaping behavior. Zero
// behavior change for the league route (pure move).
// ------------------------------------------------------------------

const pad2 = (n: number) => String(n).padStart(2, "0");

/** RFC 5545 UTC date-time (the Z form) — an unusable time becomes "". */
export function icsUtc(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return (
    `${d.getUTCFullYear()}${pad2(d.getUTCMonth() + 1)}${pad2(d.getUTCDate())}` +
    `T${pad2(d.getUTCHours())}${pad2(d.getUTCMinutes())}${pad2(d.getUTCSeconds())}Z`
  );
}

/** RFC 5545 TEXT escaping — backslash, semicolon, comma, newlines. */
export function icsText(s: string): string {
  return s
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r?\n/g, "\\n");
}

/** RFC 5545 §3.1: content lines SHOULD be ≤ 75 octets — UTF-8-safe folding. */
export function foldLine(line: string): string {
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
