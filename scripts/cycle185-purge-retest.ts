// cycle-185 diagnostic: purge the standings:v9 + cards:v2 L2 rows for pl,
// rebuild through getStandings in THIS process (same path as the server)
// and report what the cards block produces for CURRENT and one HISTORICAL
// season — distinguishes a build-time transient bake from a code defect.
import { PrismaClient } from "@prisma/client";
const db = new PrismaClient();
const gone = await db.$executeRawUnsafe(
  `DELETE FROM Cache WHERE key LIKE 'standings:v9:pl:%' OR key LIKE 'cards:v2:pl:%' OR key LIKE 'leagueRaw:pl:%'`
);
console.log("purged rows:", gone);
await db.$disconnect();

const { getStandings } = await import("/home/z/my-project/remontada/src/lib/fotmob");
const cur = await getStandings("pl");
const c = cur.cards;
console.log(
  "CURRENT cards:",
  c ? `y${(c.yellow || []).length} r${(c.red || []).length} y0=${(c.yellow || [])[0]?.name}/${(c.yellow || [])[0]?.value}/pid${(c.yellow || [])[0]?.playerId}` : "ABSENT"
);
const hist = await getStandings("pl", "2023/2024");
const hc = hist.cards;
console.log(
  "HIST 23/24 cards:",
  hc ? `y${(hc.yellow || []).length} r${(hc.red || []).length} y0=${(hc.yellow || [])[0]?.name}/${(hc.yellow || [])[0]?.value}/pid${(hc.yellow || [])[0]?.playerId}` : "ABSENT"
);
process.exit(0);
