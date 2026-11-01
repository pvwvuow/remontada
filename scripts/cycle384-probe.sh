#!/usr/bin/env bash
# cycle384-probe.sh — pre-fix live probe for the 383 findings (فیکس 384).
# Extracts the EXACT distinct raw-Latin display names the fix must map:
#   P1 titles championFa/runnerUpFa leaks (facup/coppaitalia/dfbpokal)
#   P2 dfbpokal fixtures .fa leaks (full unique set, 2026/2027)
#   P3 day-feed raw league headers (leagueName==leagueFa, with ccode)
#      + IRN raw teams + the world-feed raw scale (documented, unmapped)
set -u
BASE=http://localhost:3000
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "=== P1 titles: distinct raw-Latin champion/runner-up names ==="
for L in facup coppaitalia dfbpokal; do
  api "/api/league-titles?league=$L" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
names=set()
for it in items:
    for f in ('championFa','runnerUpFa'):
        v=it.get(f) or ''
        if any(ch.isalpha() and ord(ch)<0x0600 for ch in v): names.add(v)
print('$L', 'items:', len(items), 'distinct:', len(names))
for n in sorted(names): print('  |', n)"
done

echo "=== P2 dfbpokal fixtures: distinct raw .fa team names ==="
api "/api/league-fixtures-all?league=dfbpokal" | python3 -c "
import json,sys
d=json.load(sys.stdin)
rows=d.get('rows') or []
names=set(); aff=0
for f in rows:
    hit=False
    for k in ('home','away'):
        v=(f.get(k) or {}).get('fa') or ''
        if any(ch.isalpha() and ord(ch)<0x0600 for ch in v): names.add(v); hit=True
    if hit: aff+=1
print('rows:', len(rows), 'affected:', aff, 'distinct:', len(names))
for n in sorted(names): print('  |', n)"

echo "=== P3 day feed: raw league headers (name==fa) with ccode ==="
api "/api/matches" | python3 -c "
import json,sys
d=json.load(sys.stdin)
gs=d.get('groups') or []
rawL=[(g.get('leagueName') or '', g.get('ccode') or '', len(g.get('matches') or [])) for g in gs if (g.get('leagueFa') or '')==(g.get('leagueName') or '')]
print('groups:', len(gs), 'rawHeaders:', len(rawL))
for n,c,k in rawL: print(f'  | {n} | cc={c} | matches={k}')"

echo "=== P3b day feed: IRN raw teams + world raw scale ==="
api "/api/matches" | python3 -c "
import json,sys
d=json.load(sys.stdin)
gs=d.get('groups') or []
CATIDS={42,47,87,55,54,53,523,73,10216,525,71,64,536,48,61,538,535,57,9469,69,252,8985,196,40,519,524,138,209,141,132,77}
irn=set(); other=set()
for g in gs:
    for m in (g.get('matches') or []):
        for k in ('home','away'):
            v=m.get(k) or {}
            n=v.get('name') or ''
            if (v.get('fa') or '')==n and n:
                if g.get('leagueId') in CATIDS: pass
                elif g.get('ccode')=='IRN': irn.add(n)
                else: other.add(n)
print('irnRaw:', len(irn), 'otherRaw:', len(other))
for n in sorted(irn): print('  IRN |', n)"

echo "=== P4 match h1 team names (matchDetails payload) ==="
api "/api/match/5750685" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except Exception as e:
    print('parse-fail', e); sys.exit(0)
def walk(o,path=''):
    if isinstance(o,dict):
        for k,v in o.items():
            if k in ('home','away') and isinstance(v,dict) and v.get('name'):
                yield path,v['name']
            yield from walk(v,f'{path}.{k}')
    elif isinstance(o,list):
        for i,v in enumerate(o[:6]): yield from walk(v,f'{path}[{i}]')
seen=set()
for p,n in walk(d):
    if n not in seen:
        seen.add(n); print('  |',n)
" 2>/dev/null | head -12
echo "=== done ==="
