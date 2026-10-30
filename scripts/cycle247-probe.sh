#!/usr/bin/env bash
# cycle-247 first live probe (UA Chrome/124): the 246 card's registered team
# candidates — corner_taken_team + touches_in_opp_box_team (both 7/9 integer,
# class 215) — plus a pg-historical width check for both, per the honest-
# absence scoping lesson (243/245: current absence is current-season-scoped).
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/c247-probe
rm -rf "$OUT"; mkdir -p "$OUT"

probe_league() { curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=$2&ccode3=$3&lang=en" -o "$OUT/$1.json" & }
probe_league laliga 87 ESP
probe_league pl 47 ENG
probe_league seriea 55 ITA
probe_league bundesliga 54 GER
probe_league ligue1 53 FRA
probe_league ucl 42 UEFA
probe_league portugal 61 POR
probe_league persiangulf 523 IRN
probe_league mas 8985 MAS
wait

python3 - "$OUT" <<'PY'
import json, os, re, subprocess, sys
out = sys.argv[1]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
TARGETS = ["corner_taken_team.json", "touches_in_opp_box_team.json"]

def load(name):
    p = os.path.join(out, name)
    if not os.path.exists(p) or os.path.getsize(p) < 50: return None
    try: return json.load(open(p))
    except Exception: return None

def file_rows(url):
    p = os.path.join(out, "f_" + re.sub(r"[^a-z0-9]", "_", url.split("/stats/")[1]))
    if os.path.exists(p) and os.path.getsize(p) > 2:
        try: return json.load(open(p))
        except Exception: pass
    subprocess.run(["curl","-s","--compressed","-A",UA,url,"-o",p], check=False)
    try: return json.load(open(p))
    except Exception: return None

LEAGUES = ["laliga","pl","seriea","bundesliga","ligue1","ucl","portugal","persiangulf","mas"]
# collect every fetchAllUrl per league (team stats section), incl. non-target
# for context; keep target files + remember URLs per league for historical probing
urls = {}
for k in LEAGUES:
    raw = load(k + ".json")
    if raw is None:
        print(f"!! feed {k} load failed"); continue
    teams = (raw.get("stats") or {}).get("teams") or []
    for t in teams:
        u = t.get("fetchAllUrl") or ""
        fn = u.split("/")[-1] if u else "?"
        if fn in TARGETS and u:
            urls.setdefault(fn, {})[k] = u

# the historical probing pattern (245/246 class): season/15585 = 2020/21 for laliga
SEASON_URL = {}
for fn, per in urls.items():
    for k, u in per.items():
        if k == "laliga":
            SEASON_URL[fn] = u.replace("/leagues/", "/leagues/season/15585/", 1) if "/season/" not in u else u

print("== TARGET FILES (current season, 9 leagues) ==")
for fn in TARGETS:
    per = urls.get(fn, {})
    serving = []
    for k in LEAGUES:
        u = per.get(k)
        if not u:
            print(f"  {fn} {k:12s} NOT-IN-FEED")
            continue
        d = file_rows(u)
        rows = (d.get("TopLists") or [{}])[0].get("StatList") or [] if d else None
        if rows is None:
            print(f"  {fn} {k:12s} ABSENT(file)")
        else:
            r1 = rows[0] if rows else {}
            vals = [r.get("StatValue") for r in rows]
            ints = all(float(v).is_integer() for v in vals if v is not None) if vals else False
            ties = [(i, r.get("Rank")) for i, r in enumerate(rows) if i and r.get("Rank") == rows[i-1].get("Rank")]
            pids = sorted(set(r.get("ParticipantId") for r in rows))
            serving.append((k, len(rows)))
            print(f"  {fn} {k:12s} rows={len(rows):2d} rank1={r1.get('ParticipantName')!r} val={r1.get('StatValue')} allint={ints} ties={ties} pids={pids}")
    print(f"  -> {fn}: {len(serving)}/9 serve\n")

print("== HISTORICAL 2020/21 (laliga season/15585) ==")
for fn, u in SEASON_URL.items():
    d = file_rows(u)
    rows = (d.get("TopLists") or [{}])[0].get("StatList") or [] if d else None
    if rows is None:
        print(f"  {fn} laliga-2020/21 ABSENT")
    else:
        r1 = rows[0] if rows else {}
        print(f"  {fn} laliga-2020/21 rows={len(rows)} rank1={r1.get('ParticipantName')!r} val={r1.get('StatValue')}")
PY
echo "== probe done =="
