# -*- coding: utf-8 -*-
# cycle-474: FULL league-page probe for Liga Profesional ARG (page id 112,
# cracked via the 141 matchDetails parentLeagueId crack) — the app's own
# fetch shape (api/data/leagues?id=&ccode3=&lang=en, UA Chrome/124)
import json, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

d = get("https://www.fotmob.com/api/data/leagues?id=112&ccode3=ARG&lang=en")
print("name:", d.get("name"), "| ccdata:", (d.get("ccdata") or {}).get("ccode3"),
      "| selectedSeason:", d.get("selectedSeason"), "| color:", d.get("leagueColor"))
print("tabs:", d.get("tabs"))

t = d.get("table")
if isinstance(t, list):
    t = t[0]
if t:
    print("composite:", t.get("composite"), "| tableType:", t.get("tableType"))
    tables = t.get("tables", [])
    print("table blocks:", len(tables))
    for tb in tables[:2]:
        rows = tb.get("allMatches", [])
        print(" block:", repr(tb.get("groupName")), "rows:", len(rows))
        for r in rows[:4]:
            print("   ", r.get("team", {}).get("name"), "| rank:", r.get("rank"), "| pts:", r.get("pts"))

sals = d.get("allAvailableSeasons") or []
plain = [s for s in sals if "-" not in str(s)]
slash = [s for s in sals if "-" in str(s)]
print("seasons:", len(sals), "| plain-year:", len(plain), "| slash:", len(slash), "| sample:", sals[:6])

print("playoff:", "PRESENT" if d.get("playoff") else "absent")
if d.get("playoff"):
    print("  playoff sample:", json.dumps(d["playoff"], ensure_ascii=False)[:180])
print("titleHistory:", "PRESENT" if d.get("titleHistory") else "absent")
tr = d.get("transfers") or {}
print("transfers.data:", "REAL" if tr.get("data") else "absent", "| first:", (tr.get("data") or [{}])[0])
st = d.get("stats") or {}
print("stats:", "present" if st else "absent", "| keys:", list(st.keys())[:5])
print("fixtures.allMatches:", len(((d.get("fixtures") or {}).get("allMatches")) or []))
print("titleHolder:", d.get("titleHolder"))
