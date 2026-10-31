// probe267a.mjs — standing-rule quick key-diff (committed at cycle-276 so container
// recycles stop eating it; template per cards 266/267: Node fetch + UA Chrome/124 —
// curl is TLS-fingerprinted). Dumps top-level keys of the four documented families;
// compare against the documented inventories of cards 262+265+266+267.
const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";
const H = { "User-Agent": UA, "Accept": "application/json" };

async function get(url) {
  const r = await fetch(url, { headers: H });
  const text = await r.text();
  try { return { code: r.status, body: JSON.parse(text) }; }
  catch { return { code: r.status, body: text.slice(0, 80) }; }
}
const keys = (o) => (o && typeof o === "object" && !Array.isArray(o) ? Object.keys(o).sort() : [typeof o]);

// documented samples: team 101610 (Persepolis), league 47 PL (ENG), match 5795498 (Chelsea 2-0 United), player 1190867 (Lavia POTM)
const out = {};

const t = await get("https://www.fotmob.com/api/data/teams?id=101610");
out.teams_code = t.code;
out.teams_top = keys(t.body);
out.teams_overview = keys(t.body?.overview);
out.teams_fixturesFixtures = keys(t.body?.fixtures?.fixtures ?? t.body?.fixtures);

const l = await get("https://www.fotmob.com/api/data/leagues?id=47&ccode3=ENG&lang=en");
out.leagues_code = l.code;
out.leagues_top = keys(l.body);

const m = await get("https://www.fotmob.com/api/data/matchDetails?matchId=5795498");
out.match_code = m.code;
out.match_top = keys(m.body);
out.match_content = keys(m.body?.content);
out.match_matchFacts = keys(m.body?.content?.matchFacts);

const p = await get("https://www.fotmob.com/api/data/playerData?id=1190867");
out.player_code = p.code;
out.player_top = keys(p.body);
out.player_meta = keys(p.body?.meta);

console.log(JSON.stringify(out, null, 1));
