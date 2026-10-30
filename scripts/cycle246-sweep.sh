#!/usr/bin/env bash
# cycle-246 sweep probe: ALL remaining team-side categories across the nine
# leagues — reuse the 245-probe feed snapshots for URL discovery, probe
# every not-yet-landed team file live (UA Chrome/124), group by file name.
# Landed so far: expected_goals_team (237) / clean_sheet_team (240) /
# possession_percentage_team (241) / total_yel_card_team (242) /
# total_red_card_team (245).
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/c246-probe
rm -rf "$OUT"; mkdir -p "$OUT"
cp /tmp/c245-probe/laliga.json /tmp/c245-probe/pl.json /tmp/c245-probe/seriea.json /tmp/c245-probe/bundesliga.json /tmp/c245-probe/ligue1.json /tmp/c245-probe/ucl.json /tmp/c245-probe/portugal.json /tmp/c245-probe/persiangulf.json /tmp/c245-probe/mas.json "$OUT"/ 2>/dev/null
# refresh the feeds to be fresh-safe
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
LANDED = {"expected_goals_team.json","clean_sheet_team.json","possession_percentage_team.json","total_yel_card_team.json","total_red_card_team.json"}

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
# file → league → (rows, rank1, val)
table = {}
for k in LEAGUES:
    raw = load(k + ".json")
    if raw is None: continue
    teams = (raw.get("stats") or {}).get("teams") or []
    for t in teams:
        u = t.get("fetchAllUrl") or ""
        fn = u.split("/")[-1] if u else "?"
        if not u or fn in LANDED or not fn.endswith(".json"): continue
        d = file_rows(u)
        rows = (d.get("TopLists") or [{}])[0].get("StatList") or [] if d else None
        if rows is None:
            table.setdefault(fn, {})[k] = ("ABSENT", None, None)
        else:
            r1 = rows[0] if rows else {}
            table.setdefault(fn, {})[k] = (len(rows), r1.get("ParticipantName"), r1.get("StatValue"))

print("== SWEEP: not-yet-landed team files (9 leagues: laliga pl seriea bund ligue1 ucl portugal pg mas) ==")
for fn in sorted(table, key=lambda f: -sum(1 for v in table[f].values() if v[0] not in ("ABSENT",None) and isinstance(v[0],int) and v[0]>0)):
    per = table[fn]
    serving = sum(1 for v in per.values() if isinstance(v[0],int) and v[0]>0)
    widths = [v[0] for v in per.values() if isinstance(v[0],int)]
    print(f"\n{fn}  [{serving}/9 serve, widths {sorted(widths) if widths else '-'}]")
    for k in LEAGUES:
        v = per.get(k)
        if v is None: continue
        n,name,val = v
        print(f"   {k:12s} rows={n}  rank1={name!r} val={val}")
PY
echo "== sweep done =="
