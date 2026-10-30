#!/usr/bin/env python3
# cycle-188 bug-hunt live probe — establish current truth BEFORE pinning
# (D5: look at bytes first, then pin). UA Chrome/124. Read-only.
import json, urllib.request, urllib.parse, urllib.error

BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}

def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))

def code(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        return urllib.request.urlopen(req, timeout=30).getcode(), None
    except urllib.error.HTTPError as e:
        try:
            body = json.load(e)
        except Exception:
            body = None
        return e.code, body

def j(x):
    return json.dumps(x, ensure_ascii=False)[:400]

print("== P1: the 184 guard (current behavior) ==")
c, b = code(BASE + "/api/topscorers?league=belgium")
print("P1a ?league=belgium ->", c, j(b))
c, b = code(BASE + "/api/topscorers?league=belgium&season=2023%2F2024")
print("P1b league+season   ->", c, j(b))

print("== P2: global hist 2024/2025 (the 186 merge, second season) ==")
q = urllib.parse.quote("2024/2025", safe="")
d = get(f"{BASE}/api/topscorers?season={q}")
s0 = (d.get("scorers") or [{}])[0]
cards = d.get("cards") or {}
y0 = (cards.get("yellow") or [{}])[0]
r0 = (cards.get("red") or [{}])[0]
print("sel=", d.get("selectedSeason"), "scorers=", len(d.get("scorers") or []),
      "assists=", len(d.get("assists") or []))
print("s0=", j(s0))
print("y0=", j(y0))
print("r0=", j(r0))

print("== P3: hnl per-league hist 2024/2025 (merge source consistency) ==")
d = get(f"{BASE}/api/topscorers/hnl?season={q}")
cards = d.get("cards") or {}
y0 = (cards.get("yellow") or [{}])[0]
r0 = (cards.get("red") or [{}])[0]
s0 = (d.get("scorers") or [{}])[0]
print("lg=", d.get("leagueKey"), d.get("leagueFa"), "sel=", d.get("selectedSeason"),
      "rows=", len(d.get("scorers") or []))
print("s0=", j(s0))
print("y0=", j(y0))
print("r0=", j(r0))

print("== P4: belgium per-league hist 2023/2024 (185 surface, non-pl league) ==")
q2 = urllib.parse.quote("2023/2024", safe="")
d = get(f"{BASE}/api/topscorers/belgium?season={q2}")
cards = d.get("cards") or {}
y0 = (cards.get("yellow") or [{}])[0]
r0 = (cards.get("red") or [{}])[0]
s0 = (d.get("scorers") or [{}])[0]
print("lg=", d.get("leagueKey"), d.get("leagueFa"), "sel=", d.get("selectedSeason"),
      "rows=", len(d.get("scorers") or []))
print("s0=", j(s0))
print("y0=", j(y0))
print("r0=", j(r0))

print("== P5: match zones — second match 5749721 (key order + halves) ==")
d = get(BASE + "/api/match/5749721")
z = d.get("zones") or {}
h, a = z.get("home") or {}, z.get("away") or {}
print("home keys=", list(h.keys()))
print("away keys=", list(a.keys()))
print("home=", j(h))
print("away=", j(a))
hs = lambda t: (t.get("left") or 0) + (t.get("center") or 0) + (t.get("right") or 0)
for side, t in (("home", h), ("away", a)):
    for half in ("firstHalf", "secondHalf"):
        hv = t.get(half)
        if hv is not None:
            print(f"{side}.{half} sum={hs(hv)} vs total={hs(t)} keys={list(hv.keys())}")

print("== P6: honest absence matches ==")
for mid in (5868120, 5765944):
    d = get(f"{BASE}/api/match/{mid}")
    print(mid, "zones=", d.get("zones"), "status=", d.get("status") or d.get("match", {}).get("status") if isinstance(d.get("match"), dict) else d.get("status"))

print("== P7: search pool — new hist kings (observation, not a gate) ==")
for term, pid in (("Feta", 1516458), ("فتای", 1516458), ("Alejo", 640089), ("آلخو", 640089), ("Bruggen", 232299), ("Downes", 844943)):
    try:
        rs = get(f"{BASE}/api/search?q={urllib.parse.quote(term)}").get("players") or []
        ids = [r.get("playerId") for r in rs][:5]
        print(f"q={term!r} -> hit={pid in ids} ids={ids}")
    except Exception as e:
        print(f"q={term!r} -> ERR {e!r}")

print("== P8: 2013/2014 honest empty (stays) ==")
q3 = urllib.parse.quote("2013/2014", safe="")
d = get(f"{BASE}/api/topscorers?season={q3}")
print("sel=", d.get("selectedSeason"), "scorers=", len(d.get("scorers") or []), "cards present=", "cards" in d)

print("== P9: current race parity quick check ==")
d = get(BASE + "/api/topscorers")
s0 = (d.get("scorers") or [{}])[0]
print("s0=", s0.get("playerId"), s0.get("name"), "sc=", len(d.get("scorers") or []),
      "pl=", len(d.get("perLeague") or []), "sel=", d.get("selectedSeason"))
