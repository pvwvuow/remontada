// cycle-144 fix probe — Persian-name leak sweep across ALL live surfaces.
// Contract: every team name the product serves in a Persian field on a PORTAL
// surface (standings / fixtures / cup brackets / merged topscorers / squads)
// must be Persian — zero ASCII leaks. The daily matches slate also serves
// non-portal minor leagues (Tanzanian PL, Copa del Rey early rounds, MLS…);
// those ride the honest English-fallback convention (cycle-104, players) and
// churn daily by design — counted separately, never a portal leak.
// Run: BASE=http://localhost:3000 bun scripts/cycle144-drift.ts
export {}; // module marker — top-level await requires a module under tsc
const BASE = process.env.BASE || "http://localhost:3000";
const KEYS = ["ucl", "pl", "laliga", "seriea", "bundesliga", "ligue1", "persiangulf", "uel", "uecl", "acl", "superlig", "scottish", "saudi", "championship", "portugal"];
const CUPS = ["ucl", "uel", "uecl", "acl"];

type Leak = { surface: string; path: string; field: string; val: string; name?: string };
const portalLeaks: Leak[] = [];
const dailyLeaks: Leak[] = [];
const seen = new Set<string>();
function leak(list: Leak[], surface: string, path: string, field: string, val: string, name?: string) {
  const k = `${surface}|${field}|${name ?? val}`;
  if (seen.has(k)) return;
  seen.add(k);
  list.push({ surface, path, field, val, name });
}
type Json = any;
const isAsciiLeak = (s: string) => /[A-Za-z]/.test(s);

function walk(node: Json, path: string, surface: string, opts: { persianName?: boolean } = {}) {
  if (Array.isArray(node)) {
    node.forEach((n, i) => walk(n, `${path}[${i}]`, surface, opts));
    return;
  }
  if (node && typeof node === "object") {
    if (typeof node.fa === "string" && node.fa) {
      if (isAsciiLeak(node.fa) || (typeof node.name === "string" && node.fa === node.name)) {
        leak(portalLeaks, surface, path, "fa", node.fa, node.name);
      }
    }
    if (opts.persianName && typeof node.name === "string" && node.name && isAsciiLeak(node.name)) {
      leak(portalLeaks, surface, path, "name", node.name);
    }
    for (const [k, v] of Object.entries(node)) {
      if (k === "fa") continue;
      walk(v, `${path}.${k}`, surface, opts);
    }
  }
}

async function get(path: string): Promise<Json | null> {
  try {
    const r = await fetch(`${BASE}${path}`);
    if (!r.ok) return null;
    return await r.json();
  } catch {
    return null;
  }
}

for (const key of KEYS) {
  const d = await get(`/api/standings?league=${key}`);
  if (d?.rows) walk(d.rows, `standings/${key}`, `standings:${key}`);
}
for (const key of CUPS) {
  const d = await get(`/api/league-bracket?league=${key}`);
  if (d?.bracket?.rounds) {
    for (const round of d.bracket.rounds) {
      walk(round.matchups ?? [], `bracket/${key}`, `bracket:${key}`, { persianName: true });
    }
  }
}
for (const key of KEYS) {
  const d = await get(`/api/league-fixtures?league=${key}`);
  if (d) walk(d, `fixtures/${key}`, `fixtures:${key}`);
}
for (const key of KEYS) {
  const d = await get(`/api/league-titles?league=${key}`);
  if (d) walk(d, `titles/${key}`, `titles:${key}`);
}
{
  const d = await get(`/api/topscorers`);
  if (Array.isArray(d?.scorers)) {
    for (const s of d.scorers) {
      if (typeof s.team === "string" && isAsciiLeak(s.team)) leak(portalLeaks, "topscorers", "merged", "team", s.team, s.name);
    }
    const mapped = d.scorers.filter((s: Json) => s.nameFa && s.nameFa !== s.name).length;
    console.log(`topscorers playerFa coverage: ${mapped}/${d.scorers.length} (fallback=by-design)`);
  }
  if (Array.isArray(d?.cards)) {
    for (const s of d.cards) {
      if (typeof s.team === "string" && isAsciiLeak(s.team)) leak(portalLeaks, "topscorers", "cards", "team", s.team, s.name);
    }
  }
}
let squadTeams = 0;
for (const key of KEYS) {
  const d = await get(`/api/standings?league=${key}`);
  for (const row of d?.rows ?? []) {
    const sq = await get(`/api/team-squad/${row.teamId}`);
    squadTeams++;
    if (sq) walk(sq, `squad/${row.teamId}`, `squad:${row.name}`);
  }
}
{
  // daily slate: informational only — non-portal minor leagues ride the
  // honest fallback convention and churn every day
  const d = await get(`/api/matches`);
  if (d?.groups) walk(d.groups, "matches", "matches");
  const moved = portalLeaks.filter((l) => l.surface === "matches");
  for (const m of moved) {
    portalLeaks.splice(portalLeaks.indexOf(m), 1);
    dailyLeaks.push(m);
  }
}

console.log(`squad sweep teams checked: ${squadTeams}`);
console.log(`PORTAL_LEAKS=${portalLeaks.length} (standings+fixtures+brackets+titles+topscorers+squads — must be 0)`);
console.log(`DAILY_FALLBACK=${dailyLeaks.length} (non-portal daily slate — honest fallback by design)`);
if (portalLeaks.length === 0) {
  console.log("DRIFT SWEEP CLEAN — every portal Persian field is Persian");
} else {
  console.log("PORTAL LEAKS:");
  for (const l of portalLeaks) {
    console.log(`  [${l.surface}] ${l.path} field=${l.field} val="${l.val}"${l.name ? ` (name="${l.name}")` : ""}`);
  }
  process.exit(1);
}
