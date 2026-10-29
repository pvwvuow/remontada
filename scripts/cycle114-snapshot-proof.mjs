// cycle-114 — Part A proof: the /api/standings route WROTE the last-known-good
// snapshot row(s) into the L2 SQLite Cache table on the healthy live path.
import { PrismaClient } from "@prisma/client";

const db = new PrismaClient({
  datasources: { db: { url: "file:/home/z/my-project/remontada/prisma/dev.db" } },
});
const keys = [
  "standings:snapshot:seriea:cur",
  "standings:snapshot:pl:cur",
];

const rows = await db.cache.findMany({
  where: { key: { in: keys } },
  select: { key: true, value: true, expiresAt: true, storedAt: true },
});

if (rows.length === 0) {
  console.error("SNAPSHOT_MISSING");
  process.exit(1);
}
for (const r of rows) {
  const v = JSON.parse(r.value);
  const ttlMin = Math.round((r.expiresAt.getTime() - r.storedAt.getTime()) / 60000);
  console.log(
    `SNAPSHOT_OK ${r.key} rows=${v.rows?.length} scorers=${v.scorers?.length} ttl=${ttlMin}min storedAt=${r.storedAt.toISOString()} staleFlagInPayload=${v.stale === undefined ? "absent" : v.stale}`
  );
}
await db.$disconnect();
