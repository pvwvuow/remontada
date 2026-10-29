#!/usr/bin/env python3
# cycle-158 live-truth probe (D5: establish facts BEFORE writing gates).
# Targets: acl2 surfaces through our own app + search attribution + players
# hub chips + historical race window + the older-surface spot checks.
import json, re, urllib.request, urllib.parse

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = "http://localhost:3000"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))

# 1) search attribution: Gol Gohar → acl2? (the newest league must be in the
#    search index with its Persian name)
d = get(f"{BASE}/api/search?q={urllib.parse.quote('Gol Gohar')}")
res = d.get("results") or d.get("teams") or []
print("search 'Gol Gohar':", json.dumps(res[:3], ensure_ascii=False)[:300])

# 2) search attribution regression probes (the recorded truths)
for q in ("Al-Hilal", "Feyenoord", "Malcom"):
    d = get(f"{BASE}/api/search?q={q}")
    res = d.get("results") or d.get("teams") or []
    top = res[0] if res else {}
    print(f"search {q!r}:", top.get("name"), top.get("fa"), top.get("leagueKey") or top.get("league"), top.get("teamId") or top.get("id"))

# 3) players hub chips: does the teams-mode league list include acl2?
#    (the hub page source drives the two-step click — probe the API the UI uses)
d = get(f"{BASE}/api/standings?league=acl2")
rows = d.get("rows") or []
print("acl2 rows:", len(rows), "top:", rows[0].get("fa"), "groups:", [g.get("fa") for g in (d.get("groups") or [])][:3], "...")

# 4) historical 2023/2024 race: acl2 must stay OUT (merge-exempt) → 15
d = get(f"{BASE}/api/topscorers?league=all&season=2023/2024")
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
ts = d.get("scorers") or []
print("race 2023/2024: n=", len(ts), "participants=", len(pl), "acl2-out:", "acl2" not in pl)

# 5) current race untouched
d = get(f"{BASE}/api/topscorers?league=all")
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
ts = d.get("scorers") or []
print("race cur: n=", len(ts), "participants=", len(pl), "leader:", (ts[0] or {}).get("nameFa"), (ts[0] or {}).get("goals"))

# 6) acl2 fixtures feed shape (the league page fixtures tab)
d = get(f"{BASE}/api/league-fixtures?league=acl2")
fx = d.get("fixtures") or []
print("acl2 fixtures:", len(fx) if isinstance(fx, list) else type(fx).__name__)

# 7) h2h/match spot: an ACL Two group match (from the Nov 3 feed, 6054514)
try:
    d = get(f"{BASE}/api/match/6054514")
    m = d.get("match") or {}
    print("match 6054514:", m.get("home", {}).get("fa"), "vs", m.get("away", {}).get("fa"), m.get("score"))
except Exception as e:
    print("match 6054514: ERR", e)

# 8) titles shape all-Persian window (top-8 champions)
d = get(f"{BASE}/api/league-titles?league=acl2")
items = (d.get("titles") or {}).get("items") or []
print("acl2 titles top-8:", [(t.get("season"), t.get("championFa")) for t in items[:8]])
ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))
leaks = [t.get("championFa") for t in items[:8] if ascii_leak(t.get("championFa"))]
print("title champion ASCII leaks in top-8:", leaks)
