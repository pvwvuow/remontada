#!/usr/bin/env python3
# cycle-192 update live probe — establish current truth BEFORE pinning
# (D5: look at bytes first, then pin). UA Chrome/124. Read-only.
# Candidate gap (flagged by the 191 card): content.stats.statSeasons —
# "a season INDEX, not stats — a deeper rabbit hole for a later cycle".
# This probe opens that rabbit hole + rescans matchDetails for any block
# no cycle normalized yet.
import json, urllib.request, urllib.error

BASE = "http://localhost:3000"
UP = "https://www.fotmob.com/api/data/matchDetails?matchId="
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0", "Accept": "application/json"}

def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))

def tree(d, depth=0, maxdepth=2, path=""):
    """two-level key tree with type hints"""
    out = []
    if not isinstance(d, dict) or depth >= maxdepth:
        return out
    for k, v in d.items():
        t = type(v).__name__
        n = f"len={len(v)}" if isinstance(v, (list, dict, str)) else v
        out.append(f"{'  '*depth}{path}{k} ({t}, {n})")
        if isinstance(v, dict) and depth + 1 < maxdepth:
            out += tree(v, depth + 1, maxdepth)
    return out

MATCHES = [5749721, 5749727, 5868120]

print("== P1: upstream content.stats — full key tree (5749721 Roma-Cagliari) ==")
d = get(UP + "5749721")
stats = d.get("content", {}).get("stats", {})
for line in tree(stats, maxdepth=3):
    print(line)

print("\n== P2: statSeasons RAW bytes (all three matches) ==")
for m in MATCHES:
    try:
        d = get(UP + str(m))
        ss = d.get("content", {}).get("stats", {}).get("statSeasons")
        print(f"--- {m} statSeasons:", json.dumps(ss, ensure_ascii=False)[:1200] if ss else "ABSENT/null")
    except Exception as e:
        print(f"--- {m} ERROR: {e}")

print("\n== P3: site /api/match/[id] top-level keys (what IS normalized) ==")
site = get(BASE + "/api/match/5749721")
print(sorted(site.keys()))

print("\n== P4: upstream content.* level-1 blocks vs site keys (rescan for orphans) ==")
content = d.get("content", {})
for k, v in sorted(content.items()):
    t = type(v).__name__
    n = len(v) if isinstance(v, (list, dict)) else v
    print(f"content.{k} ({t}, {n})")
mf = content.get("matchFacts", {})
print("\nmatchFacts keys:", sorted(mf.keys()))
info = content.get("info", {})
print("info keys:", sorted(info.keys()) if isinstance(info, dict) else type(info).__name__)

print("\n== P5: IF statSeasons exists — what would it serve? inspect one entry deeply ==")
ss = stats.get("statSeasons")
if ss:
    print(json.dumps(ss[0] if isinstance(ss, list) else ss, ensure_ascii=False, indent=1)[:2000])
else:
    print("5749721 has no statSeasons — check P2 output for which match carries it")

print("\n== P6: stale-gap sanity (the three listed gaps still served) ==")
for path, needle in [
    ("/topscorers?season=2024%2F2025", "یوکرش"),      # season selector (55/99/180/182)
    ("/topscorers?season=2024%2F2025", "فتا فتای"),   # 189 fix surface
]:
    req = urllib.request.Request(BASE + path, headers=UA)
    try:
        html = urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "ignore")
        print(f"page {path[:40]}… needle «{needle[:20]}»:", "FOUND" if needle in html else "MISSING")
    except Exception as e:
        print(f"page {path} ERROR: {e}")
c, = get(BASE + "/api/league-fixtures?league=pl") and [True]
print("league-fixtures pl:", "OK" if c else "?")
d2 = get(BASE + "/api/league-bracket?league=ucl")
print("league-bracket ucl:", "null/empty" if not d2 else f"keys={sorted(d2.keys())[:6]}")
d3 = get(BASE + "/api/league-transfers?league=pl")
print("league-transfers pl:", "null" if not d3 else f"keys={sorted(d3.keys())[:6]}")
