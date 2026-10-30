#!/bin/bash
# cycle234-probe.sh — the fresh as-found probe for the cycle-234 fix
# (Fix (cycle 234): the 222/229-pattern name curation of the THREE newest
#  surfaces' (xgot/xa/bigChancesCreated) served top-10s — the 233 finding.
#  Dumps the EXACT unmapped raw English names per league per surface so the
#  confident subset can be curated under the 104 rule / 219 verdict.)
set -u
BASE="${BASE:-http://localhost:3000}"
python3 - <<PY
import json,urllib.request,re
fa=re.compile(r'[\u0600-\u06FF]')
tot=0
per={}
names={}
for k in ['laliga','ucl','pl','seriea','bundesliga','ligue1']:
    with urllib.request.urlopen('$BASE/api/topscorers/'+k, timeout=30) as r: d=json.load(r)
    n=0; rows=[]
    for sec in ('xgot','xa','bigChancesCreated'):
        for row in (d.get(sec) or [])[:10]:
            nm=row.get('nameFa') or row.get('name') or ''
            if not fa.search(nm):
                n+=1; tot+=1
                raw=row.get('name') or ''
                rows.append(f'{sec}|{raw}|{row.get("playerId")}|{row.get("team")}')
    per[k]=n; names[k]=rows
print('TOTAL',tot,'|'.join(f'{k}:{v}' for k,v in per.items()))
print('----DUMP----')
for k in ['laliga','ucl','pl','seriea','bundesliga','ligue1']:
    print(f'== {k} ({per[k]}) ==')
    for r in names[k]: print(' ',r)
PY
