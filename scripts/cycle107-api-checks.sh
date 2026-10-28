#!/usr/bin/env bash
# ------------------------------------------------------------------
# Remontada — cycle-107 API verification («تکمیل قوس نام صادق»)
#   A) standings v5: ScorerEntry rows carry nameFa (mapped + honest fallback)
#   B) boards: player-kind LeagueBoardRow rows carry nameFa
#   C) player metadata <title> follows the honest display name
#   D) probe-only: does upstream matchDetails expose fan votes? (future
#      candidate registration — NOT implemented this cycle)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
FAIL=0

echo "== A) standings v5 scorers nameFa (pl) =="
curl -s "$BASE/api/standings?league=pl" > /tmp/c107-st.json
python3 -c "
import json
d = json.load(open('/tmp/c107-st.json'))
assert d.get('ok'), 'standings not ok'
sc = d.get('scorers') or []
assert sc, 'no scorers rows'
missing = [s['name'] for s in sc if not s.get('nameFa')]
mapped = [(s['name'], s['nameFa']) for s in sc if s.get('nameFa') and s['nameFa'] != s['name']]
raw = [s['name'] for s in sc if s.get('nameFa') == s['name']]
print('rows:', len(sc), '| nameFa-missing:', len(missing), '| mapped:', len(mapped), '| honest-english:', len(raw))
print('sample mapped:', mapped[:4])
print('sample fallback:', raw[:3])
assert not missing, 'scorer nameFa missing'
assert mapped, 'no mapped scorer at all'
print('A-DONE OK')
" || FAIL=1

echo "== B) boards player rows nameFa (pl) =="
python3 -c "
import json
d = json.load(open('/tmp/c107-st.json'))
boards = d.get('boards') or []
prows = [r for b in boards if b.get('kind') == 'player' for r in b.get('rows', [])]
missing = [r['name'] for r in prows if not r.get('nameFa')]
mapped = [(r['name'], r['nameFa']) for r in prows if r.get('nameFa') and r['nameFa'] != r['name']]
print('player board rows:', len(prows), '| nameFa-missing:', len(missing), '| mapped:', len(mapped))
print('sample mapped:', mapped[:4])
assert prows, 'no player board rows in payload (boards may be absent — check league)'
assert not missing, 'board row nameFa missing'
print('B-DONE OK')
" || FAIL=1

echo "== C) player profile metadata title (737066) =="
curl -s "$BASE/player/737066" > /tmp/c107-p.html
python3 -c "
import re
html = open('/tmp/c107-p.html', encoding='utf-8').read()
m = re.search(r'<title>([^<]+)</title>', html)
title = m.group(1) if m else ''
print('title:', title)
assert 'ارلینگ هالند' in title, 'metadata title not Persian'
assert 'پروفایل بازیکن' in title, 'metadata title suffix missing'
print('C-DONE OK')
" || FAIL=1

echo "== D) probe-only: fan votes on matchDetails (future candidate) =="
curl -s -A "$UA" "https://www.fotmob.com/api/data/matchDetails?matchId=5749720" > /tmp/c107-raw.json 2>/dev/null
python3 -c "
import json
d = json.load(open('/tmp/c107-raw.json'))
content = d.get('content') or {}
mc = content.get('matchContent') or {}
keys = sorted(mc.keys()) if isinstance(mc, dict) else []
print('content.matchContent keys:', keys)
votes = mc.get('votes') if isinstance(mc, dict) else None
print('votes block:', json.dumps(votes, ensure_ascii=False)[:220] if votes else 'ABSENT')
print('D-DONE (probe-only, no implementation this cycle)')
" || FAIL=1

if [ "$FAIL" = "0" ]; then echo "CYCLE107-API-CHECKS ALL-OK"; else echo "CYCLE107-API-CHECKS FAILED"; exit 1; fi
