#!/usr/bin/env python3
# cycle-195 update live probe — bytes BEFORE the fold (D5 discipline).
# The gap: the TEAM search index = the 24 portal tables + 7 hand-pinned
# fallbacks (cycle-79) — every OTHER team on FotMob (MLS, Brasileirão,
# national teams, all sub-covered competitions) answers ZERO to /api/search
# while the ALREADY-CACHED daily matches feed (94 groups, ~170 matches
# today) carries those teams with id/name/fa/logo + a Persian competition
# name. This probe pins (P1) the defect on real feed teams, (P2) the exact
# feed bytes a fold row must carry, (P3) the /team/{id} page health for
# out-of-portal ids (a fold row that 404s would be a dead link — the 167
# dead-id lesson), (P4) the standings anchors that must stay byte-identical.
import json, urllib.request, urllib.parse, urllib.error

BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}

def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))

def code(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        return urllib.request.urlopen(req, timeout=30).getcode()
    except urllib.error.HTTPError as e:
        return e.code

def j(x):
    return json.dumps(x, ensure_ascii=False)[:300]

print("== P0: today's feed scan (the ALREADY-cached source) ==")
d = get(f"{BASE}/api/matches")
groups = d.get("groups") or []
total = sum(len(g.get("matches") or []) for g in groups)
print(f"groups={len(groups)} matches={total} date={d.get('date')} source={d.get('source')}")
# collect candidate teams from the LAST (smallest/priority) groups — the
# out-of-portal competitions the 24 tables never contain
seen_team = set()
cands = []
for g in reversed(groups):
    for m in g.get("matches") or []:
        for side in ("home", "away"):
            t = m.get(side) or {}
            tid = t.get("id")
            if tid and tid not in seen_team:
                seen_team.add(tid)
                cands.append({"id": tid, "name": t.get("name"), "fa": t.get("fa"),
                              "leagueFa": g.get("leagueFa"), "leagueName": g.get("leagueName"),
                              "logo": t.get("logo"), "matchId": m.get("id")})
print(f"unique teams in feed: {len(cands)}")
small = [c for c in cands if c["leagueName"] not in
         ("LaLiga", "Premier League", "Serie A", "Bundesliga", "Ligue 1", "UEFA Champions League")]

print("== P1: the defect — feed teams unsearchable TODAY ==")
tested = 0
defects = []
for c in small[:40]:
    q = c["fa"] or c["name"]
    if not q or len(q) < 2:
        continue
    d2 = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    teams = d2.get("results") or []
    hit = any(r.get("teamId") == c["id"] for r in teams)
    tested += 1
    if not hit:
        defects.append(c)
print(f"tested={tested} unsearchable={len(defects)}")
for c in defects[:6]:
    print("  DEFECT:", j(c))

print("== P2: pin the fold bytes for three defect teams ==")
pinned = defects[:3]
for c in pinned:
    print("  pin:", j(c))

print("== P3: /team/{id} health for the pinned ids (dead-link guard) ==")
for c in pinned:
    c1 = code(f"{BASE}/team/{c['id']}")
    a1 = code(f"{BASE}/api/team/{c['id']}")
    print(f"  team {c['id']} {c['name']}: /team/ HTTP={c1} /api/team/ HTTP={a1}")

print("== P4: anchors that must stay byte-identical ==")
for q, tid in (("رئال مادرید", 8633), ("پرسپولیس", 101610), ("Celtic", 9925)):
    d2 = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    r = next((x for x in (d2.get("results") or []) if x.get("teamId") == tid), None)
    print(f"  q={q!r} -> {'OK '+str((r or {}).get('leagueFa')) if r else 'MISSING(!!)'}")
