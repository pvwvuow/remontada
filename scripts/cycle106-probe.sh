#!/usr/bin/env bash
# ------------------------------------------------------------------
# Remontada — cycle-106 feasibility probe (update cycle)
# Registered candidate (cycle-104/105 cards): extend the honest Persian
# name map to match lineups (POTM / scorers / rows) and the player-profile h1.
# This probe answers, live with UA Chrome/124:
#   A) RAW matchDetails lineup/POTM/scorer name field paths still hold
#   B) the real lineup name pool of recent covered-league matches
#   C) coverage of the current PLAYER_NAME_FA map over that pool
#   D) playerData name field for the profile h1
# Output: scripts/cycle106-names.txt (unique pool) + coverage report on stdout.
# ------------------------------------------------------------------
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT="/home/z/my-project/scripts/cycle106-names.txt"
TMP="/home/z/my-project/scripts/cycle106-tmp"
mkdir -p "$TMP"
: > "$OUT"

# covered league fotmob ids (src/lib/leagues.ts)
LEAGUE_IDS="42 47 87 55 54 53 1000001715"

fetch() { curl -s --max-time 20 -A "$UA" "$1"; }

echo "== A/B) collect finished covered-league matches for the last 3 days =="
MATCH_IDS=""
for D in 20261026 20261027 20261028; do
  fetch "https://www.fotmob.com/api/data/matches?date=$D" > "$TMP/matches-$D.json" 2>/dev/null
  IDS=$(python3 - "$TMP/matches-$D.json" $D <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    print("", end=""); raise SystemExit
covered = {42, 47, 87, 55, 54, 53, 1000001715}
out = []
for lg in data.get("leagues", []):
    if lg.get("id") not in covered:
        continue
    for m in lg.get("matches", []):
        st = m.get("status", {}) or {}
        if st.get("finished") and st.get("scoreStr"):
            out.append(str(m.get("id")))
print(" ".join(out[:6]))
PY
)
  echo "  $D -> [$IDS]"
  MATCH_IDS="$MATCH_IDS $IDS"
done
MATCH_IDS=$(echo $MATCH_IDS | tr ' ' '\n' | awk 'NF' | sort -u | head -10)

echo "== probe up to 10 matchDetails: lineups + POTM + events =="
i=0
for ID in $MATCH_IDS; do
  i=$((i+1))
  fetch "https://www.fotmob.com/api/data/matchDetails?matchId=$ID" > "$TMP/md-$ID.json" 2>/dev/null
  python3 - "$TMP/md-$ID.json" "$OUT" "$ID" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    raise SystemExit
if d.get("error"):
    raise SystemExit
def team_names(t):
    names = []
    for st in (t or {}).get("starters", []) or []:
        if st.get("name"): names.append(st["name"])
    for s in (t or {}).get("subs", []) or []:
        if s.get("name"): names.append(s["name"])
    c = (t or {}).get("coach") or {}
    full = " ".join(x for x in (c.get("firstName"), c.get("lastName")) if x) or c.get("name")
    if full: names.append(full)
    return names
lu = (d.get("content") or {}).get("lineup") or {}
pool = team_names(lu.get("homeTeam")) + team_names(lu.get("awayTeam"))
potm = ((d.get("content") or {}).get("matchFacts") or {}).get("playerOfTheMatch") or {}
pn = potm.get("name")
if isinstance(pn, dict):
    pn = pn.get("fullName") or " ".join(x for x in (pn.get("firstName"), pn.get("lastName")) if x)
if pn: pool.append(pn)
for ev in (((d.get("content") or {}).get("matchFacts") or {}).get("events") or {}).get("events", []) or []:
    p = (ev.get("player") or {}).get("name")
    if p: pool.append(p)
    for sw in ev.get("swap") or []:
        if sw.get("name"): pool.append(sw["name"])
with open(sys.argv[2], "a", encoding="utf-8") as f:
    for n in pool:
        f.write(n + "\n")
print(f"  match {sys.argv[3]}: {len(pool)} names (POTM={pn!r})")
PY
done

echo "== C) coverage of the current map over the pool =="
python3 - "$OUT" "/home/z/my-project/remontada/src/lib/player-names-fa.ts" <<'PY'
import re, sys
pool = [l.strip() for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
uniq = sorted(set(pool))
ts = open(sys.argv[2], encoding="utf-8").read()
keys = set(k.strip().lower() for k in re.findall(r'"([^"]+)":', ts))
mapped = [n for n in uniq if n.strip().lower() in keys]
unmapped = [n for n in uniq if n.strip().lower() not in keys]
print(f"unique pool: {len(uniq)} | already mapped: {len(mapped)} ({100*len(mapped)//max(1,len(uniq))}%) | unmapped: {len(unmapped)}")
print("--- sample mapped:", ", ".join(mapped[:8]))
print("--- UNMAPPED (candidate names for curation):")
for n in unmapped:
    print("   ", n)
PY

echo "== D) playerData profile name (737066 = Håland) =="
fetch "https://www.fotmob.com/api/data/playerData?id=737066" > "$TMP/player-737066.json" 2>/dev/null
python3 -c "
import json
d = json.load(open('$TMP/player-737066.json'))
print('playerData name:', repr(d.get('name')), '| id:', d.get('id'))
"
echo "PROBE-DONE"
