#!/bin/bash
# Cycle-103 bug-hunt: API-level truth checks.
# 1) cycle-102 matchday TTL metadata across ALL 7 leagues (contract:
#    matchday league -> ttlMinutes 15, quiet -> 60, null-fixtures persiangulf -> nulls).
# 2) Exact weather/zones mirrors for the two standing fixtures (5749720 finished,
#    5071464 forecast) — plus a RAW FotMob cross-check of the drifted forecast
#    values (18->19, 51->78 since cycle-101) to prove the app faithfully mirrors
#    the CURRENT upstream forecast (forecast drift = expected, not a bug).
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

echo "== A) standings TTL metadata (7 leagues) =="
for L in ucl pl laliga seriea bundesliga ligue1 persiangulf; do
  curl -s "http://localhost:3000/api/standings?league=$L" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print('$L'.ljust(12), 'matchday=', d.get('matchday'), ' ttlMinutes=', d.get('ttlMinutes'))"
done

echo "== B) weather/zones mirrors (standing fixtures) =="
curl -s "http://localhost:3000/api/match/5749720" | python3 -c "
import json,sys
d=json.load(sys.stdin); w=d.get('weather') or {}
ok = (w.get('condition')=='صاف' and w.get('temperature')==11 and w.get('humidity')==91
      and w.get('cloudCover')==5 and w.get('forecast')==False)
z=d.get('zones') or {}
zok = z=={'home':{'left':49,'center':21,'right':30},'away':{'left':35,'center':23,'right':42}}
print('5749720 weather', 'OK' if ok else f'MISMATCH {w}')
print('5749720 zones  ', 'OK' if zok else f'MISMATCH {z}')"

curl -s "http://localhost:3000/api/match/5071464" | python3 -c "
import json,sys
d=json.load(sys.stdin); w=d.get('weather') or {}
ok = (w.get('condition')=='رعدوبرق' and w.get('forecast')==True
      and all(w.get(k) is not None for k in ('temperature','humidity','cloudCover','precipChance')))
print('5071464 weather', 'OK(struct)' if ok else f'MISMATCH {w}', json.dumps(w, ensure_ascii=False))"

echo "== C) RAW cross-check of drifted forecast (5071464) =="
curl -s -A "$UA" "https://www.fotmob.com/api/data/matchDetails?matchId=5071464" > /home/z/my-project/scripts/cycle103-raw-5071464.json 2>/dev/null
python3 - <<'EOF'
import json
raw = json.load(open('/home/z/my-project/scripts/cycle103-raw-5071464.json'))
w = (raw.get('content') or {}).get('weather') or {}
app = json.load(open('/dev/stdin')) if False else None
print('RAW 5071464 weather:', json.dumps({k: w.get(k) for k in ('temperature','relativeHumidity','cloudCover','precipChance','localizedKey','apiUsed')}, ensure_ascii=False))
# live app value for comparison
import urllib.request
a = json.load(urllib.request.urlopen('http://localhost:3000/api/match/5071464')).get('weather') or {}
pairs = [('temperature', w.get('temperature'), a.get('temperature')),
         ('humidity', w.get('relativeHumidity'), a.get('humidity')),
         ('cloudCover', w.get('cloudCover'), a.get('cloudCover')),
         ('precipChance', w.get('precipChance'), a.get('precipChance'))]
allok = True
for name, r, ap in pairs:
    m = (r == ap); allok = allok and m
    print(f'  {name}: raw={r} app={ap} {"OK" if m else "MISMATCH"}')
print('FORECAST-MIRROR', 'ALL-OK' if allok else 'MISMATCH')
EOF
