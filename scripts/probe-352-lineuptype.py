#!/usr/bin/env python3
# probe-352: lineupType honesty (predicted vs standard) — upstream contract + API surface
# update cycle-352: pre-match fixtures carry lineupType "predicted" (the predicted XI);
# the route now surfaces lineups.predicted=true only for those. 0 refs before this cycle.
import json, urllib.request, gzip, sys

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
BASE = "http://localhost:3000"
fails = []

def check(name, cond, detail=""):
    print(("PASS" if cond else "FAIL"), name, detail if not cond else "")
    if not cond:
        fails.append(name)

def get(url, raw=False):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=15) as r:
        b = r.read()
    if not raw and b[:2] == b"\x1f\x8b":
        b = gzip.decompress(b)
    return b if raw else json.loads(b)

# ---------- upstream contract ----------
def upstream(match_id, tag):
    m = get(f"https://www.fotmob.com/api/data/matchDetails?matchId={match_id}")
    lu = (m.get("content") or {}).get("lineup")
    lt = lu.get("lineupType") if isinstance(lu, dict) else None
    started = bool((m.get("general") or {}).get("started"))
    return lt, started, lu

print("== upstream contract ==")
# pre-match anchor: Liverpool vs Arsenal (16:30 UTC today, probed pre-match)
lt, started, lu = upstream(5795501, "pre")
check("pre-match 5795501 lineupType=predicted", lt == "predicted", f"got {lt!r} started={started}")
check("pre-match 5795501 not started", not started)
if isinstance(lu, dict):
    ht = lu.get("homeTeam") or {}
    check("pre-match predicted XI has 11 starters", len(ht.get("starters") or []) == 11, f"n={len(ht.get('starters') or [])}")

# live/finished anchor: Como vs Venezia (was live at probe time)
lt2, started2, _ = upstream(5749733, "live")
check("live 5749733 lineupType=standard", lt2 == "standard", f"got {lt2!r}")
check("live 5749733 started", started2)

# ---------- API surface ----------
print("== API surface ==")
try:
    d = get(f"{BASE}/api/match/5795501")
    check("api pre-match ok", d.get("ok") is True)
    ln = (d.get("match") or {}).get("lineups") or (d.get("lineups") if isinstance(d.get("lineups"), dict) else None)
    if ln is None:
        # normalized shape: {ok, match:{...}} vs flat — locate lineups key defensively
        def find(o):
            if isinstance(o, dict):
                if "home" in o and "away" in o and ("predicted" in o or "rows" in json.dumps(o)[:2000]):
                    return o
                for v in o.values():
                    r = find(v)
                    if r is not None:
                        return r
            return None
        ln = find(d)
    check("pre-match lineups present", ln is not None)
    check("pre-match predicted=true", ln is not None and ln.get("predicted") is True, f"predicted={ln.get('predicted') if ln else None}")
    check("pre-match home rows exist", ln is not None and bool((ln.get("home") or {}).get("rows")))
except Exception as e:
    check("pre-match API reachable", False, repr(e))

try:
    d2 = get(f"{BASE}/api/match/5749733")
    check("api live ok", d2.get("ok") is True)
    s = json.dumps(d2)
    check("live payload has NO predicted flag", '"predicted":true' not in s and "'predicted'" not in s)
    def find2(o):
        if isinstance(o, dict):
            if "home" in o and "away" in o:
                return o
            for v in o.values():
                r = find2(v)
                if r is not None:
                    return r
        return None
    ln2 = find2(d2)
    check("live lineups present", ln2 is not None)
except Exception as e:
    check("live API reachable", False, repr(e))

print()
print("RESULT:", "ALL GREEN" if not fails else f"{len(fails)} FAIL: {fails}")
sys.exit(0 if not fails else 1)
