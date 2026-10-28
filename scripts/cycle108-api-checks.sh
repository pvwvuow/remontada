#!/bin/bash
# Cycle-108 bug-hunt: API-level truth checks.
# A) cycle-102 matchday TTL metadata across ALL 7 leagues (contract:
#    matchday league -> ttlMinutes 15, quiet -> 60, null-fixtures persiangulf -> nulls).
# B) Weather/zones mirrors for the two standing fixtures: 5749720 (finished,
#    apiUsed=current, exact since cycle-97/100) and 5071464 (forecast, structural
#    assertions — values may drift with upstream model refresh).
# C) RAW FotMob cross-check (UA Chrome/124): field-by-field raw=app mirror for
#    BOTH fixtures — forecast drift is expected; the honest contract is that the
#    app mirrors the CURRENT upstream exactly.
# D) nameFa contract spot checks (cycles 104-107): team top-players rows,
#    player profile, global topscorers merge, standings player-boards.
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
RAW=/home/z/my-project/scripts/cycle108-raw
mkdir -p "$RAW"

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
ok = (w.get('forecast')==True
      and all(w.get(k) is not None for k in ('temperature','humidity','cloudCover','precipChance')))
print('5071464 weather', 'OK(struct)' if ok else f'MISMATCH {w}', json.dumps(w, ensure_ascii=False))"

echo "== C) RAW mirror cross-check (both fixtures) =="
curl -s -A "$UA" "https://www.fotmob.com/api/data/matchDetails?matchId=5749720" > "$RAW/5749720.json" 2>/dev/null
curl -s -A "$UA" "https://www.fotmob.com/api/data/matchDetails?matchId=5071464" > "$RAW/5071464.json" 2>/dev/null
python3 - "$RAW" <<'EOF'
import json, sys, urllib.request
raw_dir = sys.argv[1]
def mirror(mid, fields):
    raw = json.load(open(f'{raw_dir}/{mid}.json'))
    w = (raw.get('content') or {}).get('weather') or {}
    a = json.load(urllib.request.urlopen(f'http://localhost:3000/api/match/{mid}')).get('weather') or {}
    pairs = [('temperature', w.get('temperature'), a.get('temperature')),
             ('humidity', w.get('relativeHumidity'), a.get('humidity')),
             ('cloudCover', w.get('cloudCover'), a.get('cloudCover')),
             ('precipChance', w.get('precipChance'), a.get('precipChance'))]
    allok = True
    for name, r, ap in pairs:
        m = (r == ap); allok = allok and m
        print(f'  {mid} {name}: raw={r} app={ap} {"OK" if m else "MISMATCH"}')
    print(f'  {mid} localizedKey raw={w.get("localizedKey")} app_cond={a.get("condition")} apiUsed raw={w.get("apiUsed")} app={a.get("forecast")}')
    print(f'MIRROR {mid}', 'ALL-OK' if allok else 'MISMATCH')
mirror('5749720', None)
mirror('5071464', None)
EOF

echo "== D) nameFa contract spot checks =="
python3 - <<'EOF'
import json, urllib.request
def get(u):
    return json.load(urllib.request.urlopen(u))

# D1) team top-players: every City row must carry a non-empty nameFa (cycle-104: 9/9)
d = get('http://localhost:3000/api/team-top-players/8456')['topPlayers']
total = mapped = 0
for cat, rows in d.items():
    for r in rows:
        total += 1
        if r.get('nameFa') and r['nameFa'] != r['name']:
            mapped += 1
print(f'D1 team/8456 rows={total} nameFa-mapped={mapped}', 'OK' if total > 0 and mapped == total else 'CHECK')

# D2) player profile (cycle-106): h1 source = nameFa || name
p = get('http://localhost:3000/api/player/737066')['player']
ok = p.get('name') == 'Erling Haaland' and p.get('nameFa') == 'ارلینگ هالند'
print('D2 player/737066', 'OK' if ok else f'MISMATCH name={p.get("name")} nameFa={p.get("nameFa")}')

# D3) global topscorers merge (cycle-105): hero + mapped coverage
t = get('http://localhost:3000/api/topscorers')
sc = t.get('scorers') or []
mapped = [r for r in sc if r.get('nameFa') and r['nameFa'] != r['name']]
hero = sc[0] if sc else {}
print(f'D3 topscorers rows={len(sc)} mapped={len(mapped)} hero={hero.get("name")}→{hero.get("nameFa")}',
      'OK' if sc and hero.get('nameFa') else 'CHECK')

# D4) standings player-boards (cycle-107): board rows carry nameFa fields
s = get('http://localhost:3000/api/standings?league=pl')
boards = s.get('boards') or []
prows = unmp = 0
for b in boards:
    if b.get('kind') != 'player':
        continue
    for r in b.get('rows', []):
        prows += 1
        if not r.get('nameFa'):
            unmp += 1
print(f'D4 standings/pl player-rows={prows} missing-nameFa={unmp}', 'OK' if prows > 0 and unmp == 0 else 'CHECK')
EOF
