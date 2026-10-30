#!/bin/bash
# cycle223-probe.sh — live probes for the cycle-223 bug-hunt
# (Bug-hunt (cycle 223): patrol focused on the cycle-222 surface «سیو در هر ۹۰»
#  + new cross-dimensions. UA Chrome/124 like every probe since 205.)
set -u
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
BASE="${BASE:-http://localhost:3000}"

echo "== P1: API sweep — all 7 leagues, the 8-field additive contract + sp90 shape =="
for K in ucl pl laliga seriea bundesliga ligue1 persiangulf; do
  curl -s "$BASE/api/topscorers/$K" | python3 -c "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
sp=d.get('savesPer90') or []
r1=(sp[0]['name'],sp[0]['savesPer90']) if sp else ('-','-')
fa=sum(1 for e in sp if (e.get('nameFa') or '')!=e['name'])
print('$K', 'scorers=%d cs=%d rat=%d gpa=%d gp=%d min=%d svpct=%d sp90=%d'%(f('scorers'),f('cleanSheets'),f('ratings'),f('gPlusA'),f('goalsPrevented'),f('minutes'),f('savePercentage'),f('savesPer90')), 'rank1=',r1, 'fa=%d/%d'%(fa,len(sp)))
"
done

echo "== P2: ucl raw saves.json — upstream Rank sequence (expect competition tie-rank class) =="
RAWU=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=42&ccode3=UEFA&lang=en" | python3 -c "
import sys,json
d=json.load(sys.stdin)
cat=next((c for c in (d.get('stats') or {}).get('players') or [] if (c.get('header') or '').lower()=='saves per 90'), None)
print(cat.get('fetchAllUrl') if cat else 'NONE')
")
if [ "$RAWU" != "NONE" ] && [ -n "$RAWU" ]; then
  curl -s --compressed -A "$UA" "$RAWU" | python3 -c "
import sys,json
d=json.load(sys.stdin)
rows=d['TopLists'][0]['StatList'][:10]
print('ucl raw ranks :', [r.get('Rank') for r in rows])
print('ucl raw vals  :', [r.get('StatValue') for r in rows])
print('ucl raw names :', [r.get('ParticipantName') for r in rows[:3]])
"
else echo "ucl fetchAllUrl NONE"; fi

echo "== P3: served ucl sp90 — positional re-rank (the 216 lesson on the NEWEST surface) =="
curl -s "$BASE/api/topscorers/ucl" | python3 -c "
import sys,json
d=json.load(sys.stdin)
sp=d.get('savesPer90') or []
print('served ranks:', [e['rank'] for e in sp])
print('served vals :', [e['savesPer90'] for e in sp])
print('served names:', [e['name'] for e in sp[:3]])
"

echo "== P4: pl raw saves.json rank-1 (second live-anchor league for D2) =="
RAWP=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=47&ccode3=ENG&lang=en" | python3 -c "
import sys,json
d=json.load(sys.stdin)
cat=next((c for c in (d.get('stats') or {}).get('players') or [] if (c.get('header') or '').lower()=='saves per 90'), None)
print(cat.get('fetchAllUrl') if cat else 'NONE')
")
if [ "$RAWP" != "NONE" ] && [ -n "$RAWP" ]; then
  curl -s --compressed -A "$UA" "$RAWP" | python3 -c "
import sys,json
d=json.load(sys.stdin)
r=d['TopLists'][0]['StatList'][0]
print('pl raw rank-1:', r.get('Rank'), r.get('ParticipantName'), r.get('StatValue'))
"
else echo "pl fetchAllUrl NONE"; fi

echo "== P5: ligue1 served sp90 — the deliberate honest-English tail (the 219 Kocik verdict) =="
curl -s "$BASE/api/topscorers/ligue1" | python3 -c "
import sys,json
d=json.load(sys.stdin)
sp=d.get('savesPer90') or []
for e in sp: print(' ', e['rank'], e['name'], e['savesPer90'], 'FA' if (e.get('nameFa') or '')!=e['name'] else 'LATIN')
"

echo "== P6: laliga 2022/23 historical sp90 — second historical season sweep (222 proved 2020/21) =="
curl -s "$BASE/api/topscorers/laliga?season=2022%2F2023" | python3 -c "
import sys,json
d=json.load(sys.stdin)
sp=d.get('savesPer90') or []
fa=sum(1 for e in sp if (e.get('nameFa') or '')!=e['name'])
print('rows=%d fa=%d/%d'%(len(sp),fa,len(sp)), 'top3:', [(e['name'],e['savesPer90']) for e in sp[:3]])
"
