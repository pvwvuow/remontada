#!/usr/bin/env python3
# ------------------------------------------------------------------
# cycle-181 Belgium fact pack (probe #4) — leftovers: oldest title,
# archived 2023/2024 composite tables rows (the cycle-141 parser path),
# transfer club sweep with the REAL keys (fromClub/toClub — D5 caught
# probe #3 guessing fromTeam), day-feed name+ccode via /api/data/matches.
# ------------------------------------------------------------------
import json, gzip, urllib.request

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8"))

p = get("https://www.fotmob.com/api/data/leagues?id=40&ccode3=BEL")
seas = p.get("seasons") or []
print(f"TITLES: {len(seas)} seasons; newest={seas[0].get('seasonName')} winner={(seas[0].get('winner') or {}).get('name')} loser={(seas[0].get('loser') or {}).get('name')}")
print(f"  oldest={seas[-1].get('seasonName')} winner={(seas[-1].get('winner') or {}).get('name')} loser={(seas[-1].get('loser') or {}).get('name')}")

# archived composite tables (2023/2024)
arch = get("https://www.fotmob.com/api/data/leagues?id=40&ccode3=BEL&season=2023/2024")
adata = (arch.get("table") or [{}])[0].get("data", {})
print("\nARCHIVED 2023/2024 composite:", adata.get("composite"), "| tables:", len(adata.get("tables") or []))
for t in (adata.get("tables") or [])[:4]:
    rows = ((t or {}).get("table", {}) or {}).get("all") or []
    print(f"  table group: leagueName={t.get('leagueName')} groupName={t.get('groupName')} rows={len(rows)} top={(rows[0].get('name') if rows else None)}")

# transfers: real keys fromClub/toClub
tr = (p.get("transfers") or {}).get("data") or []
names = {}
for t in tr:
    for k in ("fromClub", "toClub"):
        v = t.get(k)
        if isinstance(v, str) and v:
            names[v] = names.get(v, 0) + 1
        elif isinstance(v, dict) and v.get("name"):
            names[v["name"]] = names.get(v["name"], 0) + 1
print(f"\nTRANSFERS data={len(tr)} distinct sides={len(names)}")
print("TRANSFER CLUBS:", json.dumps(sorted(names), ensure_ascii=False))

# day feed: find the Belgian entry (today 2026-10-30)
df = get("https://www.fotmob.com/api/data/matches?date=20261030")
found = 0
for lg in (df.get("leagues") or []):
    if (lg.get("ccode") or "").upper() == "BEL":
        print("\nDAY-FEED BEL entry:", json.dumps({k: lg.get(k) for k in ("name", "ccode", "primaryId", "dayTournamentId")}, ensure_ascii=False))
        found += 1
print("day-feed BEL groups:", found)

# live Eckert via our own player API (the app must serve him 200 with Iran hook)
req = urllib.request.Request("http://localhost:3000/api/player/892709", headers={"User-Agent": UA})
pj = json.loads(urllib.request.urlopen(req, timeout=30).read().decode("utf-8"))
info = pj.get("player") or {}
print("\nOUR /api/player/892709:", pj.get("ok"), "| name:", info.get("name"),
      "| country:", json.dumps(info.get("country"), ensure_ascii=False)[:120],
      "| team:", (info.get("team") or {}).get("name"))
