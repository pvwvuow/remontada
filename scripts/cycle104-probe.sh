#!/bin/bash
# Cycle-104 probe: collect the REAL player-name strings currently in
# circulation across the app's top-players surfaces:
#   (a) /api/team-top-players for the standing patrol teams
#   (b) /api/topscorers for all 7 leagues (the league-leader pool that
#       feeds the league-wide rank chips)
# Output: scripts/cycle104-names.txt (unique names) for the curated map.
set -u
OUT=/home/z/my-project/remontada/scripts/cycle104-names.txt
: > "$OUT"

echo "== team-top-players for known teams =="
for T in 8456 9925 9826 737066; do
  curl -s "http://localhost:3000/api/team-top-players/$T" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  sys.exit()
tp=d.get('topPlayers') or {}
for cat,rows in (tp.items() if isinstance(tp,dict) else []):
  if not isinstance(rows,list): continue
  for r in rows:
    if r.get('name'): print(r['name'])" >> "$OUT"
done

echo "== topscorers per league =="
for L in ucl pl laliga seriea bundesliga ligue1 persiangulf; do
  curl -s "http://localhost:3000/api/topscorers?league=$L" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  sys.exit()
def walk(o):
  if isinstance(o,dict):
    if 'name' in o and isinstance(o.get('name'),str) and o.get('name') and 'goal' not in o:
      pass
  return o
# topscorers shape: try common keys
for key in ('topscorers','scorers','list','items','data'):
  v=d.get(key)
  if isinstance(v,list):
    for r in v[:20]:
      if isinstance(r,dict) and r.get('name'): print(r['name'])
    break
else:
  # fallback: scan one level deep
  for v in d.values():
    if isinstance(v,list):
      for r in v[:20]:
        if isinstance(r,dict) and r.get('name') and isinstance(r['name'],str): print(r['name'])
    " >> "$OUT"
done

sort -u "$OUT" -o "$OUT"
echo "unique names: $(wc -l < "$OUT")"
head -40 "$OUT"