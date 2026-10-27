import fs from "fs";
import { PrismaClient } from '@prisma/client'

// ------------------------------------------------------------------
// SQLite URL resolution:
// Relative `file:./x.db` URLs are ambiguous once the app runs from the
// standalone output (cwd != repo root), so we anchor them to the repo's
// prisma directory. Absolute file:/postgres URLs pass through untouched,
// so external deployments (e.g. Vercel + Postgres) keep working.
// ------------------------------------------------------------------
const REPO_PRISMA = "/home/z/my-project/remontada/prisma";
const REPO_DB = `file:${REPO_PRISMA}/dev.db`;

function resolveDatabaseUrl(): string | undefined {
  const envUrl = process.env.DATABASE_URL;
  // All SQLite (`file:`) URLs are anchored to the repo's own prisma/dev.db —
  // relative paths are ambiguous in the standalone output, and an inherited
  // shell DATABASE_URL (e.g. the parent workspace's custom.db) must not win,
  // otherwise the cache location flips between restarts. Non-file URLs
  // (postgres/mysql for external deployments) pass through untouched.
  if (!envUrl || /^file:/i.test(envUrl)) {
    if (fs.existsSync(`${REPO_PRISMA}/schema.prisma`)) return REPO_DB;
  }
  return envUrl;
}

const url = resolveDatabaseUrl();

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const db =
  globalForPrisma.prisma ??
  new PrismaClient(
    url && url !== process.env.DATABASE_URL
      ? { datasources: { db: { url } } }
      : undefined
  )

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
