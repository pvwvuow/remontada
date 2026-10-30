#!/usr/bin/env python3
# ------------------------------------------------------------------
# cycle-181 Belgium fact pack (probe #3) — dump-first shapes for the
# pieces probe #2 misread: goals.json row0 KEYS, seasons[0] keys (the
# real titles container), archived-2023/2024 table shape, transfers,
# ESPN bel.1, and the day-feed name+ccode for «First Division A».
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

# 1. goals.json shape
g = get("https://data.fotmob.com/stats/40/season/37803/goals.json")
tl = g.get("TopLists") or []
print("TopLists[0] keys:", sorted(tl[0].keys()) if tl else None)
sl = tl[0].get("StatList") or [] if tl else []
print("StatList rows:", len(sl))
if sl:
    print("ROW0 FULL:", json.dumps(sl[0], ensure_ascii=False)[:500])
    print("ROW1 FULL:", json.dumps(sl[1], ensure_ascii=False)[:300])
    # find Eckert
    for i, e in enumerate(sl):
        s = json.dumps(e, ensure_ascii=False)
        if "892709" in s or "Eckert" in s:
            print(f"ECKERT rank={i+1}:", s[:300])
            break
    else:
        print("ECKERT not in goals file")

# 2. seasons[0] — real titles container
p = get("https://www.fotmob.com/api/data/leagues?id=40&ccode3=BEL")
seas = p.get("seasons") or []
print("\nseasons len:", len(seas))
if seas:
    print("seasons[0] keys:", sorted(seas[0].keys()))
    # maybe titles inside each season object
    s0 = seas[0]
    for k in sorted(s0.keys()):
        v = s0[k]
        print(f"  seasons[0].{k}: {type(v).__name__} = {json.dumps(v, ensure_ascii=False)[:160]}")

# 3. archived 2023/2024 table shape
arch = get("https://www.fotmob.com/api/data/leagues?id=40&ccode3=BEL&season=2023/2024")
at0 = (arch.get("table") or [{}])[0]
adata = at0.get("data", {})
print("\nARCHIVED table[0].data keys:", sorted(adata.keys()) if isinstance(adata, dict) else type(adata))
print("ARCHIVED isCurrentSeason:", adata.get("isCurrentSeason"), "| selectedSeason:", adata.get("selectedSeason"))
tb = adata.get("table")
if isinstance(tb, dict):
    print("ARCHIVED table.all rows:", len(tb.get("all") or []), "top:", (tb.get('all') or [{}])[0].get('name'))
elif isinstance(tb, list):
    print("ARCHIVED table is LIST len:", len(tb), "elem0 keys:", sorted(tb[0].keys()) if tb else None)

# 4. transfers
tr = (p.get("transfers") or {}).get("data") or []
names = set()
for t in tr:
    for k in ("fromTeam", "toTeam", "from", "to"):
        v = t.get(k)
        if isinstance(v, dict) and v.get("name"): names.add(v.get("name"))
        elif isinstance(v, str): names.add(v)
print(f"\nTRANSFERS data={len(tr)} distinct sides={len(names)}")
print("TRANSFER CLUBS:", json.dumps(sorted(names), ensure_ascii=False))
if tr:
    print("T0 FULL:", json.dumps(tr[0], ensure_ascii=False)[:300])

# 5. ESPN bel.1
print("\nESPN probe (bel.1):")
try:
    req = urllib.request.Request("https://site.api.espn.com/apis/site/v2/sports/soccer/bel.1/scoreboard",
                                 headers={"User-Agent": UA})
    e = json.loads(urllib.request.urlopen(req, timeout=15).read().decode("utf-8"))
    print("  ESPN bel.1 OK — leagues:", json.dumps([l.get("name") for l in (e.get("leagues") or [])], ensure_ascii=False)[:140])
except Exception as ex:
    print("  ESPN bel.1 FAIL:", ex)

# 6. day-feed name for Belgium (today's matches)
print("\nDay feed scan for BEL ccode:")
try:
    df = get("https://www.fotmob.com/api/matches?date=20261030")
    found = 0
    for lg in (df.get("leagues") or []):
        if (lg.get("ccode") or "").upper() == "BEL":
            print("  day-feed entry:", json.dumps({k: lg.get(k) for k in ("name", "ccode", "primaryId", "dayTournamentId")}, ensure_ascii=False))
            found += 1
    if not found: print("  no BEL entry today (no matches)")
except Exception as ex:
    print("  day feed FAIL:", ex)
