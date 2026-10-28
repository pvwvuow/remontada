#!/bin/bash
# Cycle-104 probe 2: sweep the top-8 teams of each league's standings and
# pull their team-top-players rows — the union of names that ACTUALLY appear
# in the «بازیکنان کلیدی فصل» sections across the covered leagues.
set -u
OUT=/home/z/my-project/remontada/scripts/cycle104-names.txt

for L in ucl pl laliga seriea bundesliga ligue1; do
  IDS=$(curl -s "http://localhost:3000/api/standings?league=$L" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  sys.exit()
tables=d.get('tables') or d.get('standings') or []
def rows_of(x):
  if isinstance(x,dict):
    for k in ('rows','table','teams','list'):
      if isinstance(x.get(k),list): return x[k]
  if isinstance(x,list): return x
  return []
seen=[]
for t in tables:
  for r in rows_of(t):
    team=r.get('team') or r
    i=team.get('id')
    if i and i not in seen: seen.append(i)
print(' '.join(str(i) for i in seen[:8]))")
  for T in $IDS; do
    curl -s "http://localhost:3000/api/team-top-players/$T" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  sys.exit()
tp=d.get('topPlayers') or {}
if isinstance(tp,dict):
  for rows in tp.values():
    if isinstance(rows,list):
      for r in rows:
        if isinstance(r,dict) and r.get('name'): print(r['name'])" >> "$OUT.tmp"
  sleep 0.4
done
done
# persiangulf: standings may be null (503 design) — use squad sweep of known ids instead
for T in 24502 6603 13886; do
  curl -s "http://localhost:3000/api/team-top-players/$T" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  sys.exit()
tp=d.get('topPlayers') or {}
if isinstance(tp,dict):
  for rows in tp.values():
    if isinstance(rows,list):
      for r in rows:
        if isinstance(r,dict) and r.get('name'): print(r['name'])" >> "$OUT.tmp" 2>/dev/null
  sleep 0.4
done
[ -f "$OUT.tmp" ] && cat "$OUT.tmp" >> "$OUT" && rm -f "$OUT.tmp"
sort -u "$OUT" -o "$OUT"
echo "unique names total: $(wc -l < "$OUT")"