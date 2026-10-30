#!/usr/bin/env bash
# cycle-242 probe: feasibility sweep for the NEXT team-side sibling —
# «کارت‌های زرد تیم‌ها» (total_yel_card_team.json), the candidate the 241
# card registered ("probed wide 16-20 rows, the integer class like 236/240").
# As-found, UA Chrome/124, zero app changes:
#   P1 every league feed's TEAMS stat block: list ALL categories + which
#      one carries the yellow-card TEAM fetchAllUrl
#   P2 the file itself: rows / rank-1 / values / StatFormat (int vs dec)
#   P3 the honest absences: persiangulf + mas — serve or not?
#   P4 SEASON-AWARE: the 2020/21 laliga raw serves its own file?
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/c242-probe
rm -rf "$OUT"; mkdir -p "$OUT"

probe_league() { # key id cc season_out
  curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=$2&ccode3=$3&lang=en" -o "$OUT/$1.json" &
}
probe_league laliga 87 ESP
probe_league pl 47 ENG
probe_league seriea 55 ITA
probe_league bundesliga 54 GER
probe_league ligue1 53 FRA
probe_league ucl 42 UEFA
probe_league portugal 61 POR
probe_league persiangulf 523 IRN
probe_league mas 8985 MAS
curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en&season=15585" -o "$OUT/laliga-2020.json" &
wait

python3 - "$OUT" <<'PY'
import json, os, re, subprocess, sys
out = sys.argv[1]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def load(name):
    p = os.path.join(out, name)
    if not os.path.exists(p) or os.path.getsize(p) < 50:
        return None
    try:
        return json.load(open(p))
    except Exception:
        return None

def file_rows(url):
    p = os.path.join(out, "file_" + re.sub(r"[^a-z0-9]", "_", url[-70:]))
    subprocess.run(["curl", "-s", "--compressed", "-A", UA, url, "-o", p], check=False)
    try:
        d = json.load(open(p))
    except Exception:
        return None
    rows = (d.get("TopLists") or [{}])[0].get("StatList") or []
    return rows

LEAGUES = ["laliga", "pl", "seriea", "bundesliga", "ligue1", "ucl", "portugal", "persiangulf", "mas", "laliga-2020"]

print("== P1 TEAMS categories per league ==")
targets = []  # (league, header, url) — ALL card categories, no overwrite
for k in LEAGUES:
    raw = load(k + ".json")
    if raw is None:
        print(f"{k}: FEED MISSING")
        continue
    teams = (raw.get("stats") or {}).get("teams") or []
    heads = [(t.get("header") or "?", bool(t.get("fetchAllUrl"))) for t in teams]
    print(f"{k}: {len(teams)} team cats: " + "; ".join(f"{h}{'*' if u else ''}" for h, u in heads))
    # yellow-card team category candidates
    for t in teams:
        h = (t.get("header") or "").lower()
        u = t.get("fetchAllUrl") or ""
        if "card" in h and u:
            targets.append((k, t.get("header"), u))

print()
print("== P2/P3 the card TEAM files (yellow AND red) ==")
for k, h, u in targets:
    rows = file_rows(u)
    if rows is None:
        print(f"{k}: [{h}] FETCH FAILED {u}")
        continue
    n = len(rows)
    r1 = rows[0] if rows else {}
    vals = [r.get("StatValue") for r in rows]
    ints = all(float(v) == int(float(v)) for v in vals if v is not None)
    fmt = ((rows[0].get("StatFormat") or {}) if rows else {})
    print(f"{k}: [{h}] {u.split('/')[-1]} rows={n} rank1={r1.get('ParticipantName')!r} teamId={r1.get('TeamId')} val={r1.get('StatValue')} maxdec={fmt.get('maxdec')} kind={fmt.get('kind','?') if isinstance(fmt,dict) else '?'} all-int={ints}")
    if k == "laliga":
        print("   laliga top6:", [(r.get("Rank"), r.get("ParticipantName"), r.get("TeamId"), r.get("StatValue")) for r in rows[:6]])
        ties = {}
        for r in rows:
            ties.setdefault(r.get("StatValue"), []).append(r.get("Rank"))
        print("   laliga tie-ranks:", {v: rs for v, rs in ties.items() if len(rs) > 1})
    if k == "portugal" and rows:
        print("   portugal top3:", [(r.get("Rank"), r.get("ParticipantName"), r.get("StatValue")) for r in rows[:3]])
    if k == "laliga" and "yel" in u:
        print("   laliga top6:", [(r.get("Rank"), r.get("ParticipantName"), r.get("TeamId"), r.get("StatValue")) for r in rows[:6]])
        ties = {}
        for r in rows:
            ties.setdefault(r.get("StatValue"), []).append(r.get("Rank"))
        print("   laliga tie-ranks:", {v: rs for v, rs in ties.items() if len(rs) > 1})

served = {k for k, h, u in targets}
print()
print("== P4 honest absences ==")
for k in LEAGUES:
    if k not in served:
        print(f"{k}: NO card-bearing team category → honest []")

print()
print("== P5 season-aware check ==")
raw = load("laliga-2020.json")
if raw is None:
    print("laliga 2020/21 feed MISSING")
else:
    teams = (raw.get("stats") or {}).get("teams") or []
    for t in teams:
        h = (t.get("header") or "").lower()
        u = t.get("fetchAllUrl") or ""
        if "yel" in u:
            rows = file_rows(u)
            if rows:
                r1 = rows[0]
                ties = {}
                for r in rows:
                    ties.setdefault(r.get("StatValue"), []).append(r.get("Rank"))
                print(f"laliga-2020: [{t.get('header')}] {u.split('/')[-1]} rows={len(rows)} rank1={r1.get('ParticipantName')!r} teamId={r1.get('TeamId')} val={r1.get('StatValue')} tie-ranks={ {v: rs for v, rs in ties.items() if len(rs) > 1} }")
            else:
                print(f"laliga-2020: [{t.get('header')}] fetch failed")
PY
echo "== probe done =="
