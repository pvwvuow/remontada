#!/usr/bin/env python3
# cycle-159 D5 scope probe v2 — sweep career (senior+national+youth) of live
# player feeds + every standings team name of every league, for fa Latin
# passthrough (unmapped names). Reads under the {ok, player} envelope.
import json, re, subprocess

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = "http://localhost:3000"
LEAGUES = ["acl2", "qatar", "eredivisie", "uae", "portugal", "championship",
           "superlig", "persiangulf", "laliga", "seriea", "bundesliga",
           "ligue1", "europa", "acl", "uel", "saudi", "scottish", "pl"]

def get(url):
    p = subprocess.run(["curl", "-s", "-A", UA, "--max-time", "60", url],
                       capture_output=True, text=True)
    return json.loads(p.stdout)

latin = re.compile(r"[A-Za-z]")
unmapped = {}

def note(team, fa, where):
    if team and latin.search(fa or ""):
        key = f"{team}"
        if key not in unmapped:
            unmapped[key] = {"fa": fa, "where": where}

# 1) standings teams of every league
for lk in LEAGUES:
    try:
        d = get(f"{BASE}/api/standings?league={lk}")
    except Exception:
        continue
    rows = d.get("rows") or []
    for r in rows:
        note(r.get("name") or r.get("team"), r.get("fa") or "", f"standings/{lk}")
    for g in d.get("groups") or []:
        for r in g.get("rows") or []:
            note(r.get("name") or r.get("team"), r.get("fa") or "", f"standings/{lk}/groups")

# 2) player careers: topscorers ids + gol gohar squad ids + rahmati
pids = {196041}
for lk in ["all"] + LEAGUES:
    try:
        d = get(f"{BASE}/api/topscorers?league={lk}")
        for p in (d.get("scorers") or [])[:30]:
            pid = p.get("playerId") or p.get("id")
            if pid:
                pids.add(pid)
    except Exception:
        pass
try:
    d = get(f"{BASE}/api/team-squad/389880")
    for p in (d.get("squad") or d.get("players") or []):
        pid = p.get("playerId") or p.get("id")
        if pid:
            pids.add(pid)
except Exception:
    pass

print(f"player ids to probe: {len(pids)}")
probed = 0
for pid in sorted(pids)[:80]:
    try:
        d = get(f"{BASE}/api/player/{pid}")
        p = d.get("player") or {}
    except Exception:
        continue
    probed += 1
    for c in (p.get("career") or []):
        note(c.get("team"), c.get("fa") or "", f"career/{pid}")
    for c in (p.get("careerYouth") or []):
        note(c.get("team"), c.get("fa") or "", f"careerYouth/{pid}")
    for c in (p.get("recentTeams") or []):
        note(c.get("team") or c.get("name"), c.get("fa") or c.get("name") or "", f"recentTeams/{pid}")

print(f"probed {probed} players")
print(f"\nUNMAPPED ({len(unmapped)}):")
for k, v in sorted(unmapped.items()):
    print(f"  {k!r} → fa={v['fa']!r}  @ {v['where']}")
