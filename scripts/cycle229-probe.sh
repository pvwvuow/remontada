#!/bin/bash
# cycle229-probe.sh — dump EVERY unmapped (English-rendering) row on every
# SERVED surface, current + historical, for the cycle-229 fix curation
# (Fix (cycle 229): the 228 registered finding — the name-curation chain
#  215→217→221→222 was not continued by 226/227. Priority: the persiangulf
#  gp90 block → the two newest surfaces → the form-drift backlog → the
#  historical anchors. UA Chrome/124 like every probe since 205.)
set -u
BASE="${BASE:-http://localhost:3000}"

echo "== P1: unmapped rows per surface, current season, all 8 leagues =="
for K in ucl pl laliga seriea bundesliga ligue1 persiangulf mas; do
  curl -s "$BASE/api/topscorers/$K" | python3 -c "
import sys,json
d=json.load(sys.stdin)
surfaces=[('scorers','scorers'),('cleanSheets','cs'),('ratings','rat'),('gPlusA','gpa'),('goalsPrevented','gprev'),('minutes','min'),('savePercentage','svpct'),('savesPer90','sp90'),('penaltySaves','ps'),('xg','xg'),('goalsPer90','gp90')]
for key,tag in surfaces:
    rows=d.get(key) or []
    en=[r['name'] for r in rows if (r.get('nameFa') or '')==r['name']]
    if en:
        print('$K',tag,len(rows),';'.join(en))
"
done

echo "== P2: historical anchors + their surfaces (the three frozen seasons) =="
for Q in "laliga?season=2020%2F2021" "pl?season=2023%2F2024" "laliga?season=2022%2F2023"; do
  curl -s "$BASE/api/topscorers/$Q" | python3 -c "
import sys,json
d=json.load(sys.stdin)
surfaces=[('scorers','scorers'),('cleanSheets','cs'),('ratings','rat'),('gPlusA','gpa'),('goalsPrevented','gprev'),('minutes','min'),('savePercentage','svpct'),('savesPer90','sp90'),('penaltySaves','ps'),('xg','xg'),('goalsPer90','gp90')]
for key,tag in surfaces:
    rows=d.get(key) or []
    en=[r['name'] for r in rows if (r.get('nameFa') or '')==r['name']]
    if en:
        print('$Q',tag,len(rows),';'.join(en))
"
done
echo "cycle229-probe done."
