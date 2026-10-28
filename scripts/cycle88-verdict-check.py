#!/usr/bin/env python3
# cycle-88 bug-hunt: cross-check app team-fixtures verdicts/scores vs live FotMob
import json, subprocess, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
BASE = "http://localhost:3000"

def live_fixtures(team_id):
    d = json.load(open(f"/tmp/fm-team-{team_id}.json"))
    af = (d.get("fixtures", {}) or {}).get("allFixtures", {}) or {}
    out = {}
    for m in af.get("fixtures", []) or []:
        out[str(m.get("id"))] = m
    return out

def app_fixtures(team_id):
    url = f"{BASE}/api/team-fixtures/{team_id}"
    with urllib.request.urlopen(url, timeout=30) as r:
        return json.load(r)

def verdict_from(hs, as_, side):
    if hs is None or as_ is None:
        return None
    if side == "home":
        return "W" if hs > as_ else ("D" if hs == as_ else "L")
    else:
        return "W" if as_ > hs else ("D" if as_ == hs else "L")

issues = []
for T, NAME in ((9925, "Celtic"), (9826, "Crystal Palace"), (8456, "Man City")):
    live = live_fixtures(T)
    app = app_fixtures(T)
    rows = (app.get("fixtures") or {}).get("results", [])
    total = (app.get("fixtures") or {}).get("total")
    print(f"== {NAME} ({T}): app total={total} rows={len(rows)} live={len(live)}")
    n_checked = 0
    for row in rows:
        mid = str(row.get("id"))
        lm = live.get(mid)
        if not lm:
            continue
        n_checked += 1
        hs = (lm.get("home") or {}).get("score")
        as_ = (lm.get("away") or {}).get("score")
        fin = bool(lm.get("status", {}).get("finished"))
        side = "home" if (lm.get("home") or {}).get("id") == T else "away"
        exp_v = verdict_from(hs, as_, side) if fin else None
        app_v = row.get("verdict")
        app_h = (row.get("home") or {}).get("score")
        app_a = (row.get("away") or {}).get("score")
        if fin and (app_h != hs or app_a != as_):
            issues.append(f"{NAME} match {mid}: scores app {app_h}-{app_a} vs live {hs}-{as_}")
        if fin and exp_v and app_v != exp_v:
            issues.append(f"{NAME} match {mid}: verdict app {app_v} vs expected {exp_v} ({hs}-{as_})")
    print(f"   checked {n_checked} matches against live")
    # verdict distribution
    dist = {}
    for row in rows:
        v = row.get("verdict")
        if v in ("W", "D", "L"):
            dist[v] = dist.get(v, 0) + 1
    print(f"   W/D/L: {dist.get('W',0)}/{dist.get('D',0)}/{dist.get('L',0)}")

print()
if issues:
    print(f"ISSUES ({len(issues)}):")
    for i in issues[:20]:
        print(" -", i)
else:
    print("ALL CHECKS PASS — app matches live truth")
