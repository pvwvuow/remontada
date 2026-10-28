// cycle-102 unit proof for isLeagueMatchday — runs the REAL exported detector
// against the LIVE-probed payloads (seriea = matchday right now, pl = quiet)
// plus synthetic edge cases. Run: bun scripts/cycle102-matchday-check.ts
import { isLeagueMatchday } from "../src/lib/fotmob";
import { readFileSync } from "node:fs";

type LM = Parameters<typeof isLeagueMatchday>[0];
const load = (k: string): LM => JSON.parse(readFileSync(`/home/z/my-project/scripts/cycle102-${k}.json`, "utf8"));

let fails = 0;
function check(name: string, got: unknown, want: unknown) {
  const ok = got === want;
  if (!ok) fails++;
  console.log(`${ok ? "PASS" : "FAIL"} ${name}: got=${got} want=${want}`);
}

// live payloads (probed 2026-10-29 ~06:2x +08:00)
check("seriea live payload → matchday (kickoff 2.5h ago, hasOngoing=true)", isLeagueMatchday(load("seriea")), true);
check("pl live payload → quiet (nearest kickoff 62h away)", isLeagueMatchday(load("pl")), false);
check("ucl live payload → quiet (nearest 139h)", isLeagueMatchday(load("ucl")), false);
check("laliga live payload → quiet (nearest 45h)", isLeagueMatchday(load("laliga")), false);

// synthetic edges
const H = 3600_000;
const mk = (offsets: number[], extra: Record<string, unknown> = {}): LM => ({
  fixtures: {
    ...extra,
    allMatches: offsets.map((o) => ({
      status: { utcTime: new Date(Date.now() + o * H).toISOString(), cancelled: false },
    })),
  },
});
check("kickoff +9h (today upcoming) → matchday", isLeagueMatchday(mk([9])), true);
check("kickoff -4h (just finished) → matchday", isLeagueMatchday(mk([-4])), true);
check("kickoff -6h (corrections window closed) → quiet", isLeagueMatchday(mk([-6])), false);
check("kickoff +11h (tomorrow) → quiet", isLeagueMatchday(mk([11])), false);
check("only cancelled fixture in window → quiet",
  isLeagueMatchday({ fixtures: { allMatches: [{ status: { utcTime: new Date().toISOString(), cancelled: true } }] } } as unknown as LM), false);
check("hasOngoingMatch=true overrides → matchday", isLeagueMatchday(mk([-8], { hasOngoingMatch: true })), true);
check("null fixtures block (persiangulf design) → quiet", isLeagueMatchday({ fixtures: null } as unknown as LM), false);
check("empty allMatches → quiet", isLeagueMatchday(mk([])), false);
check("garbage utcTime → quiet", isLeagueMatchday({ fixtures: { allMatches: [{ status: { utcTime: "not-a-date", cancelled: false } }] } } as unknown as LM), false);

console.log(fails === 0 ? "ALL-CHECKS-OK" : `FAILURES=${fails}`);
process.exit(fails === 0 ? 0 : 1);
