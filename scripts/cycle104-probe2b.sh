#!/bin/bash
# Cycle-104 probe 2b (fixed): standings rows[].teamId -> top-8 teams per
# league -> their team-top-players names.
set -u
OUT=/home/z/my-project/remontada/scripts/cycle104-names.txt

for L in ucl pl laliga seriea bundesliga ligue1; do
  IDS=$(curl -s "http://localhost:3000/api/standings?league=$L" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  sys.exit()
rows=d.get('rows') or []
print(' '.join(str(r['teamId']) for r in rows[:8] if r.get('teamId')))")
  echo "league=$L ids=$IDS" >&2
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
    sleep 0.3
  done
done
[ -f "$OUT.tmp" ] && cat "$OUT.tmp" >> "$OUT" && rm -f "$OUT.tmp"
sort -u "$OUT" -o "$OUT"
echo "unique names total: $(wc -l < "$OUT")"