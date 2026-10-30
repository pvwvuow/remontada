#!/usr/bin/env python3
# cycle-192 probe round 2 — deep-dive the candidate orphans for 5749721 (finished)
import json, urllib.request

BASE = "http://localhost:3000"
UP = "https://www.fotmob.com/api/data/matchDetails?matchId="
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0", "Accept": "application/json"}

def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))

d = get(UP + "5749721")
content = d["content"]

print("== Q1: content.table RAW (5749721) ==")
tbl = content.get("table")
print(json.dumps(tbl, ensure_ascii=False, indent=1)[:3500])

print("\n== Q2: site match API 'form' + table-related keys ==")
site = get(BASE + "/api/match/5749721")
print("form:", json.dumps(site.get("form"), ensure_ascii=False)[:600])
print("match.league:", json.dumps((site.get("match") or {}).get("league"), ensure_ascii=False)[:300])

print("\n== Q3: content.shotmap vs site 'shots' — already normalized? ==")
sm = content.get("shotmap")
print("upstream shotmap keys:", sorted(sm.keys()) if isinstance(sm, dict) else type(sm).__name__)
sh = site.get("shots")
print("site shots:", "len=" + str(len(sh)) if isinstance(sh, list) else sh)

print("\n== Q4: matchFacts.infoBox vs site 'info' ==")
ib = content["matchFacts"].get("infoBox")
print("infoBox keys:", sorted(ib.keys()) if isinstance(ib, dict) else type(ib).__name__)
print("site info keys:", sorted((site.get("info") or {}).keys()))

print("\n== Q5: matchFacts.topPlayers — normalized anywhere? ==")
tp = content["matchFacts"].get("topPlayers")
print("topPlayers type:", type(tp).__name__)
if isinstance(tp, dict):
    print("topPlayers keys:", sorted(tp.keys()))
    for k, v in tp.items():
        print(f"  {k}: {type(v).__name__}", f"len={len(v)}" if isinstance(v, (list, dict)) else v)
print("site playerStats:", "len=" + str(len(site["playerStats"])) if site.get("playerStats") else site.get("playerStats"))

print("\n== Q6: content.superlive (191 set-aside) — confirm off-brand ==")
print(json.dumps(content.get("superlive"), ensure_ascii=False)[:300])
