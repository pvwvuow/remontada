#!/usr/bin/env python3
# ------------------------------------------------------------------
# cycle-181 Belgium fact pack (probe #2) — everything the leagues.ts
# integration + the domproof gate need, live (UA Chrome/124):
#   league name (details/leagueName), flat table top-5 with points,
#   goals.json fetchAllUrl (leader + Eckert 892709 rank), archived
#   season goals file (2023/2024 → season id), title seasons newest/
#   oldest, transfers.data count + distinct club sweep, ESPN slug
#   (bel.1) live probe, day-feed name+ccode for COMPETITION_FA.
# ------------------------------------------------------------------
import json, gzip, urllib.request, time

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8"))

BEL = 40
p = get(f"https://www.fotmob.com/api/data/leagues?id={BEL}&ccode3=BEL")

# 1. official league name
det = p.get("details") or {}
print("details.leagueName:", det.get("leagueName"))
print("details keys:", sorted(det.keys())[:14])
data0 = (p.get("table") or [{}])[0].get("data", {})
print("table.data.leagueName:", data0.get("leagueName"), "| ccode:", data0.get("ccode"), "| selectedSeason:", data0.get("selectedSeason"))

# 2. table top-5
rows = data0.get("table", {}).get("all") or []
print("\nTABLE top-5:")
for r in rows[:5]:
    print(f"  {r.get('idx')}. {r.get('name')} id={r.get('id')} pts={r.get('pts')} {r.get('scoresStr')} played={r.get('played')}")
print("TABLE bottom-3:")
for r in rows[-3:]:
    print(f"  {r.get('idx')}. {r.get('name')} id={r.get('id')} pts={r.get('pts')}")
clubs = [r.get("name") for r in rows]
print("ALL CLUBS:", json.dumps(clubs, ensure_ascii=False))

# 3. goals.json
st = p.get("stats") or {}
pl = st.get("players")
cats = (pl.get("categories") if isinstance(pl, dict) else pl) or []
print("\nSTAT CATEGORIES:", json.dumps([{c.get('name'): (c.get('fetchAllUrl') or '')[:80]} for c in cats], ensure_ascii=False)[:400])
goals_cat = next((c for c in cats if c.get("name") == "goals" or c.get("leagueCatType") == "goals"), None)
url = (goals_cat or {}).get("fetchAllUrl") or ""
if url:
    if url.startswith("//"): url = "https:" + url
    g = get(url)
    tl = g.get("TopLists") or []
    rl = (tl[0].get("StatList") if tl else []) or []
    print(f"GOALS FILE rows={len(rl)} seasonId={g.get('seasonId')}")
    for i, e in enumerate(rl[:6]):
        pt = e.get("participation") or {}
        team = (pt.get("team") or {}).get("name") if isinstance(pt, dict) else e.get("teamName")
        print(f"  {i+1}. {e.get('name')} pid={((pt or {}).get('player') or {}).get('id')} team={team} stat={e.get('statValue')} cc={e.get('ccode')}")
    # Eckert's rank
    for i, e in enumerate(rl):
        pt = e.get("participation") or {}
        pid = ((pt or {}).get("player") or {}).get("id") if isinstance(pt, dict) else None
        if pid == 892709:
            print(f"  ECKERT rank={i+1} stat={e.get('statValue')} name={e.get('name')} team={team if False else (pt.get('team') or {}).get('name')}")

# 4. archived season goals (2023/2024 → find season id)
seasons_avail = p.get("allAvailableSeasons") or []
print("\nSEASONS:", seasons_avail[:3], "...", seasons_avail[-2:])
try:
    arch = get(f"https://www.fotmob.com/api/data/leagues?id={BEL}&ccode3=BEL&season=2023/2024")
    adata0 = (arch.get("table") or [{}])[0].get("data", {})
    arows = adata0.get("table", {}).get("all") or []
    print(f"ARCHIVED 2023/2024: rows={len(arows)} champion={arows[0].get('name') if arows else None} selectedSeason={adata0.get('selectedSeason')}")
    ast = arch.get("stats") or {}
    apl = ast.get("players")
    acats = (apl.get("categories") if isinstance(apl, dict) else apl) or []
    agoals = next((c for c in acats if c.get("name") == "goals" or c.get("leagueCatType") == "goals"), None)
    aurl = (agoals or {}).get("fetchAllUrl") or ""
    print("  archived fetchAllUrl:", aurl[:100])
    if aurl:
        if aurl.startswith("//"): aurl = "https:" + aurl
        ag = get(aurl)
        atl = ag.get("TopLists") or []
        arl = (atl[0].get("StatList") if atl else []) or []
        print(f"  archived goals rows={len(arl)} top={arl[0].get('name') if arl else None}")
except Exception as e:
    print("ARCHIVED probe error:", e)

# 5. titles
seas = p.get("seasons") or []
if seas:
    titles = seas[0].get("titles") or []
    print(f"\nTITLE seasons: {len(titles)}")
    for t in titles[:2]:
        print("  newest:", json.dumps(t, ensure_ascii=False)[:200])
    print("  oldest:", json.dumps(titles[-1], ensure_ascii=False)[:200])

# 6. transfers + club sweep
tr = (p.get("transfers") or {}).get("data") or []
names = set()
for t in tr:
    for k in ("fromTeam", "toTeam", "from", "to"):
        v = t.get(k)
        if isinstance(v, dict) and v.get("name"): names.add(v.get("name"))
        elif isinstance(v, str): names.add(v)
print(f"\nTRANSFERS data={len(tr)} distinct sides={len(names)}")
print("TRANSFER CLUBS:", json.dumps(sorted(names), ensure_ascii=False))

# 7. ESPN slug probe
print("\nESPN probe (bel.1):")
try:
    req = urllib.request.Request("https://site.api.espn.com/apis/site/v2/sports/soccer/bel.1/scoreboard",
                                 headers={"User-Agent": UA})
    e = json.loads(urllib.request.urlopen(req, timeout=15).read().decode("utf-8"))
    print("  ESPN bel.1 OK — leagues:", json.dumps([l.get("name") for l in (e.get("leagues") or [])], ensure_ascii=False)[:120])
except Exception as ex:
    print("  ESPN bel.1 FAIL:", ex)
