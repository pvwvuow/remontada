// cycle417-unit.ts — the 417 FA-map contract at unit level (the 414 pattern:
// import the REAL functions, assert the REAL upstream strings).
//   U1  competitionFa: the day-feed group header «Hazfi Cup» renders Persian
//       (bare key — the coppa-italia pattern; no AMBIGUOUS_NAMES entry).
//   U2  competitionFa: byte-identical passthrough of a name the map must NOT
//       touch (the negative half of the same contract).
//   U3  teamFa: the FULL live census — all 32 distinct league-9487 names
//       (fixtures + playoff + seasons winner/loser, scripts/cycle417-probe.sh)
//       map to Persian. Zero raw passthrough — the F2-378 guard for the new
//       cup's every display field.
//   U4  teamFa: the 7 NEW keys byte-exact (the second-tier entrants).
import { competitionFa, teamFa } from "../src/lib/leagues";

let pass = 0, fail = 0;
function ck(name: string, ok: boolean) {
  if (ok) { pass++; console.log("PASS", name); }
  else { fail++; console.log("FAIL", name); }
}

// U1 — the day-feed header name (upstream details.name, probed)
ck("U1-competitionFa-hazfi-cup", competitionFa("Hazfi Cup", "IRN") === "جام حذفی ایران");
ck("U1b-bare-no-cc", competitionFa("Hazfi Cup") === "جام حذفی ایران");
// U2 — untouched name stays byte-identical (honest passthrough)
ck("U2-untouched-passthrough", competitionFa("Hazfi Cup Qualification", "IRN") === "Hazfi Cup Qualification");

// U3 — the full census (32 distinct names from the live probe)
const CENSUS = [
  "Aluminium Arak", "Bargh Shiraz", "Beasat Kermanshah", "Chadormalu Ardakan SC",
  "Chooka Talesh", "Damash", "Esteghlal", "Esteghlal Khuzestan", "Fajr Sepasi",
  "Foolad Hormozgan", "Foolad Khuzestan", "Gol Gohar", "Havadar SC", "KIA FC",
  "Kheybar Khorramabad", "Malavan", "Mes Kerman", "Mes Rafsanjan", "Mes Shahr Babak",
  "Naft Gachsaran", "Nassaji Mazandaran FC", "Niroye Zamini", "Padyab Khalkhal",
  "Paykan", "Persepolis", "Qeshm Island", "Saipa", "Sepahan", "Shahrdari Nowshahr",
  "Shams Azar Qazvin", "Tractor", "Zob Ahan",
];
const LATIN = /[A-Za-z]{2,}/;
const raw = CENSUS.filter((n) => LATIN.test(teamFa(n)));
ck("U3-census-32-persian (" + raw.length + " raw)", raw.length === 0);
if (raw.length) console.log("   raw passthroughs:", raw.join(", "));

// U4 — the 7 new second-tier keys, byte-exact (the F2-378 guard)
ck("U4-bargh-shiraz", teamFa("Bargh Shiraz") === "برق شیراز");
ck("U4-chooka-talesh", teamFa("Chooka Talesh") === "چوکا تالش");
ck("U4-damash", teamFa("Damash") === "داماش");
ck("U4-foolad-hormozgan", teamFa("Foolad Hormozgan") === "فولاد هرمزگان");
ck("U4-kia-fc", teamFa("KIA FC") === "کیا");
ck("U4-padyab-khalkhal", teamFa("Padyab Khalkhal") === "پادیاب خلخال");
ck("U4-shahrdari-nowshahr", teamFa("Shahrdari Nowshahr") === "شهرداری نوشهر");

console.log(`=== result ===\nPASS=${pass} FAIL=${fail}`);
process.exit(fail === 0 ? 0 : 1);
