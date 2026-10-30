#!/bin/bash
# cycle228-probe.sh — live probes for the cycle-228 bug-hunt
# (Bug-hunt (cycle 228): patrol focused on the two NEWEST surfaces
#  «گل در هر ۹۰» (gp90, cycle 227) + «گل مورد انتظار» (xG, cycle 226)
#  + new cross-dimensions. UA Chrome/124 like every probe since 205.)
set -u
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
BASE="${BASE:-http://localhost:3000}"

echo "== P1: full 12-field contract sweep, all 8 leagues =="
for K in ucl pl laliga seriea bundesliga ligue1 persiangulf mas; do
  curl -s "$BASE/api/topscorers/$K" | python3 -c "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
gp=d.get('goalsPer90') or []; xg=d.get('xg') or []
mono_gp=all(gp[i]['goalsPer90']>=gp[i+1]['goalsPer90'] for i in range(len(gp)-1)) if len(gp)==10 else None
pos_gp=[e['rank'] for e in gp]==list(range(1,11)) if gp else None
mono_xg=all(xg[i]['xg']>=xg[i+1]['xg'] for i in range(len(xg)-1)) if len(xg)==10 else None
en=sum(1 for r in gp+xg if (r.get('nameFa') or '')==r['name'])
print('$K', 'scorers=%d cs=%d rat=%d gpa=%d gprev=%d min=%d svpct=%d sp90=%d ps=%d xg=%d gp90=%d'%(f('scorers'),f('cleanSheets'),f('ratings'),f('gPlusA'),f('goalsPrevented'),f('minutes'),f('savePercentage'),f('savesPer90'),f('penaltySaves'),f('xg'),f('goalsPer90')), 'gp90:mono=%s pos=%s'%(mono_gp,pos_gp), 'xg:mono=%s'%mono_xg, 'english=%d/%d'%(en,len(gp)+len(xg)), 'gp1=%r'%(gp[0]['name'] if gp else None))
"
done

echo "== P2: historical anchors (season=YYYY/YYYY) =="
for Q in "laliga?season=2020%2F2021" "pl?season=2023%2F2024" "laliga?season=2022%2F2023"; do
  curl -s "$BASE/api/topscorers/$Q" | python3 -c "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPer90') or []; xg=d.get('xg') or []; ps=d.get('penaltySaves') or []
print('$Q', 'gp90=%d xg=%d ps=%d'%(len(gp),len(xg),len(ps)),
      'gp1=',(gp[0]['name'],gp[0]['goalsPer90'],gp[0].get('nameFa')) if gp else None,
      'xg1=',(xg[0]['name'],xg[0]['xg'],xg[0].get('nameFa')) if xg else None)
"
done

echo "== P3: Persian-search dead-end A/B pairs (THE FINDING) =="
python3 - <<'PY'
import json,urllib.request,urllib.parse
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r: return json.load(r)
B='http://localhost:3000'
for fa,en in [('بولای دیا','Boulaye Dia'),('وحید امیری','Vahid Amiri'),('گابریل جسوس','Gabriel Jesus'),('توراتی','Turati'),('شهریاری','Shahriari'),('فلمینگ','Flemming')]:
    fa_n=len(get(f'{B}/api/search?q={urllib.parse.quote(fa)}').get('players') or [])
    en_n=len(get(f'{B}/api/search?q={urllib.parse.quote(en)}').get('players') or [])
    print(f'  q={fa!r} -> {fa_n} | q={en!r} -> {en_n}')
PY

echo "== P4: live upstream drift on the NEWEST surface (laliga raw vs served) =="
GPURL=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en" | python3 -c "
import sys,json
d=json.load(sys.stdin)
cat=next((c for c in (d.get('stats') or {}).get('players') or [] if (c.get('header') or '').lower()=='goals per 90'), None)
print(cat.get('fetchAllUrl') if cat else 'NONE')
")
XGURL=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en" | python3 -c "
import sys,json
d=json.load(sys.stdin)
cat=next((c for c in (d.get('stats') or {}).get('players') or [] if (c.get('header') or '').lower()=='expected goals (xg)'), None)
print(cat.get('fetchAllUrl') if cat else 'NONE')
")
if [ "$GPURL" != "NONE" ] && [ -n "$GPURL" ] && [ "$XGURL" != "NONE" ] && [ -n "$XGURL" ]; then
  curl -s --compressed -A "$UA" "$GPURL" > /tmp/c228-gp90.json
  curl -s --compressed -A "$UA" "$XGURL" > /tmp/c228-xg.json
  curl -s "$BASE/api/topscorers/laliga" > /tmp/c228-laliga.json
  python3 - <<'PY'
import json
raw=json.load(open('/tmp/c228-gp90.json'))['TopLists'][0]['StatList']
api=json.load(open('/tmp/c228-laliga.json')).get('goalsPer90') or []
print('  raw gp90 rows:', len(raw), 'top3:', [(r['ParticipantName'],r['StatValue']) for r in raw[:3]])
print('  served gp90 top3:', [(e['name'],e['goalsPer90']) for e in api[:3]])
gdec=set(len(str(r['StatValue']).split('.')[1]) if '.' in str(r['StatValue']) else 0 for r in raw)
print('  raw gp90 decimals:', sorted(gdec))
xraw=json.load(open('/tmp/c228-xg.json'))['TopLists'][0]['StatList']
xapi=json.load(open('/tmp/c228-laliga.json')).get('xg') or []
print('  raw xg rows:', len(xraw), 'top1:', (xraw[0]['ParticipantName'],xraw[0]['StatValue']), '| served xg top1:', (xapi[0]['name'],xapi[0]['xg']) if xapi else None)
xdec=set(len(str(r['StatValue']).split('.')[1]) if '.' in str(r['StatValue']) else 0 for r in xraw)
print('  raw xg decimals:', sorted(xdec))
print('  substat (total goals, rides unused):', [r.get('SubStatValue') for r in raw[:3]])
PY
else
  echo "  P4: category fetchAllUrl unresolvable"
fi
echo "cycle228-probe done."
