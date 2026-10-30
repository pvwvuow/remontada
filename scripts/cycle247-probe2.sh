#!/usr/bin/env bash
# cycle-247 probe #2: (a) the exact feed `header` for the corner category,
# (b) the FROZEN 2020/21 laliga raw (season/15585 — via the season FEED, the
#     245 P4 class, distinct cache names),
# (c) pg/mas DIRECT bare files (the 245 P3 class: bare file may serve but the
#     app never fetches it — not in feed),
# (d) top-10 team names per serving league → teamFa coverage check.
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/c247-probe
mkdir -p "$OUT"

curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en&season=15585" -o "$OUT/laliga-2020.json" &
wait

python3 - "$OUT" <<'PY'
import json, os, re, subprocess, sys
out = sys.argv[1]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def fetch(url, tag):
    p = os.path.join(out, "c_" + tag)
    if os.path.exists(p) and os.path.getsize(p) > 2:
        try: return json.load(open(p))
        except Exception: pass
    subprocess.run(["curl","-s","--compressed","-A",UA,url,"-o",p], check=False)
    try: return json.load(open(p))
    except Exception: return None

def rows(d):
    return (d.get("TopLists") or [{}])[0].get("StatList") or [] if d else None

print("== (a) feed headers for the corner category (current feeds) ==")
for lg in ["laliga","pl","seriea","bundesliga","ligue1","ucl","portugal","persiangulf","mas"]:
    p = os.path.join(out, lg + ".json")
    if not os.path.exists(p): continue
    raw = json.load(open(p))
    for t in (raw.get("stats") or {}).get("teams") or []:
        u = t.get("fetchAllUrl") or ""
        if "corner_taken_team" in u:
            print(f"  {lg}: header={t.get('header')!r} url={u}")

print("\n== (b) FROZEN 2020/21 laliga (season/15585, via season FEED) ==")
raw = json.load(open(os.path.join(out, "laliga-2020.json")))
for t in (raw.get("stats") or {}).get("teams") or []:
    u = t.get("fetchAllUrl") or ""
    if "corner_taken_team" in u:
        print(f"  header={t.get('header')!r} url={u}")
        d = fetch(u, "laliga2020_corner")
        r = rows(d)
        if r is None:
            print("  ABSENT/UNPARSEABLE")
        else:
            r1 = r[0] if r else {}
            print(f"  rows={len(r)} rank1={r1.get('ParticipantName')!r} val={r1.get('StatValue')} teamId={r1.get('TeamId')}")
            print("  top10:", [(x.get("ParticipantName"), x.get("StatValue")) for x in r[:10]])
    if "touches_in_opp_box_team" in u:
        d = fetch(u, "laliga2020_tob")
        r = rows(d)
        print(f"  (tob 2020/21: rows={len(r) if r is not None else 'ABSENT'})")

print("\n== (c) pg/mas DIRECT bare files (the 245 P3 class) ==")
for lgid, name in [(523, "persiangulf"), (8985, "mas")]:
    u = f"https://data.fotmob.com/stats/{lgid}/corner_taken_team.json"
    d = fetch(u, f"direct_{name}")
    r = rows(d)
    if r is None:
        print(f"  {name}: DIRECT → ABSENT/UNPARSEABLE")
    else:
        r1 = r[0] if r else {}
        print(f"  {name}: DIRECT SERVES rows={len(r)} rank1={r1.get('ParticipantName')!r} val={r1.get('StatValue')}")

print("\n== (d) top-10 names per serving league (teamFa coverage inputs) ==")
LEAGUES = ["laliga","pl","seriea","bundesliga","ligue1","ucl","portugal"]
for lg in LEAGUES:
    p = os.path.join(out, lg + ".json")
    raw = json.load(open(p))
    for t in (raw.get("stats") or {}).get("teams") or []:
        u = t.get("fetchAllUrl") or ""
        if "corner_taken_team" in u:
            d = fetch(u, f"cur_{lg}")
            r = rows(d) or []
            print(f"  {lg}: {[(x.get('ParticipantName'), x.get('StatValue')) for x in r[:10]]}")
PY
echo "== probe2 done =="
