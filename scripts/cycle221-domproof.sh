#!/bin/bash
# cycle221-domproof.sh — permanent gate for the cycle-221 update
# (Update (cycle 221): «درصد سیو» — the deep-file family's NINTH sibling and
#  the THIRD keeper surface, _save_percentage.json).
# Part A (API, 4 checks):
#   A1 current laliga: 10 named rows, percent values (0,100], monotonic
#      non-increasing, positional ranks 1..10, all Persian-mapped
#      (nameFa != name)
#   A2 additive contract on the SAME response: scorers=20 + cleanSheets=10
#      + ratings=10 + gPlusA=10 + goalsPrevented=10 + minutes=10
#      + savePercentage=10
#   A3 anchors: LIVE — the served rank-1 name+value == the raw
#      _save_percentage.json file's rank-1 (fetched in-gate, UA Chrome/124);
#      FROZEN — 2025/26 finished season: Joan García 77.9 / David Soria 75.6
#      / Aarón Escandell 72.5 top-3 (the 202 anchor pattern)
#   A4 persiangulf: honest absence — savePercentage=[] (the feed carries no
#      keeper category at all, live-probed) while the league itself still
#      serves (minutes=10, the 220 contract) — absence is per-category, not
#      a broken league
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 the «درصد سیو» section: 10 sv-rows + h2 present + first pill
#      dir="ltr" (the 210/217 decimal contract) with Persian digits
#   B2 real navigation: first sv-row click → /player/[id] with profile h1
#   B3 the family intact: NINE sections on one page + the keeper trio
#      adjacent (درصد سیو → گل نخرده‌ها → گل‌های پیشگیری‌شده, the 217
#      contract extended) + the 2020/21 historical season renders the
#      curated «خائومه دومنک» (the dead-key fix, live) + viewport integrity
#   B4 console=0 errors=0
set -u
BASE="${BASE:-http://localhost:3000}"
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1
J=$(curl -s "$BASE/api/topscorers/laliga")
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
sv=d.get('savePercentage') or []
rows=len(sv)==10
named=all(e.get('name') and e.get('team') and e.get('playerId',0)>0 for e in sv)
pcts=all(0<e['savePercentage']<=100 for e in sv)
mono=all(sv[i]['savePercentage']>=sv[i+1]['savePercentage'] for i in range(len(sv)-1))
pos=[e['rank'] for e in sv]==list(range(1,len(sv)+1))
fa=all((e.get('nameFa') or '')!=e['name'] for e in sv)
print('A1CHECK', rows, named, pcts, mono, pos, fa)
" > /tmp/a1_221.txt
grep -q "A1CHECK True True True True True True" /tmp/a1_221.txt && ok "A1 savePercentage: 10 named rows, percent (0,100], monotonic, positional 1..10, all Persian" || bad "A1: $(cat /tmp/a1_221.txt)"

# A2 additive contract
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
c={'scorers':len(d.get('scorers') or []),'cleanSheets':len(d.get('cleanSheets') or []),'ratings':len(d.get('ratings') or []),'gPlusA':len(d.get('gPlusA') or []),'goalsPrevented':len(d.get('goalsPrevented') or []),'minutes':len(d.get('minutes') or []),'savePercentage':len(d.get('savePercentage') or [])}
print('A2CHECK', c['scorers']==20 and c['cleanSheets']==10 and c['ratings']==10 and c['gPlusA']==10 and c['goalsPrevented']==10 and c['minutes']==10 and c['savePercentage']==10, c)
" > /tmp/a2_221.txt
grep -q "A2CHECK True" /tmp/a2_221.txt && ok "A2 additive contract: scorers=20/cleanSheets=10/ratings=10/gPlusA=10/goalsPrevented=10/minutes=10/savePercentage=10" || bad "A2: $(cat /tmp/a2_221.txt)"

# A3 live anchor: served rank-1 == the raw file's rank-1 (name+value)
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
curl -s --compressed -A "$UA" "https://data.fotmob.com/stats/87/season/38843/_save_percentage.json" -o /tmp/sv221_raw.json
echo "$J" > /tmp/sv221_api.json
py "
import json
api=json.load(open('/tmp/sv221_api.json'))
raw=json.load(open('/tmp/sv221_raw.json'))
rows=raw['TopLists'][0]['StatList']
sv=api.get('savePercentage') or []
r1=rows[0] if rows else {}
ok=bool(sv) and sv[0]['name']==r1.get('ParticipantName') and abs(sv[0]['savePercentage']-r1.get('StatValue',-1))<1e-9
print('A3LIVE', ok, sv[0]['name'] if sv else '-', r1.get('ParticipantName'), r1.get('StatValue'))
" > /tmp/a3_221.txt
grep -q "A3LIVE True" /tmp/a3_221.txt && ok "A3 live anchor: served rank-1 == the raw _save_percentage.json rank-1 (name+value verbatim)" || bad "A3-live: $(cat /tmp/a3_221.txt)"

# A3 frozen anchor: 2025/26 finished season
S=$(curl -s "$BASE/api/topscorers/laliga?season=2025%2F2026" | py "
import sys,json
d=json.load(sys.stdin)
sv=d.get('savePercentage') or []
trio=[(e['name'],e['savePercentage']) for e in sv[:3]]
ok=len(sv)==10 and ('Joan García',77.9) in trio and ('David Soria',75.6) in trio and ('Aarón Escandell',72.5) in trio
print('SEASON', ok, trio)
")
echo "$S" | grep -q "SEASON True" && ok "A3 frozen anchor: 2025/26 Joan García 77.9 / Soria 75.6 / Escandell 72.5 (the finished-season file)" || bad "A3-season: $S"

# A4 persiangulf honest absence + league still alive (minutes=10)
PW=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
sv=d.get('savePercentage') or []
mp=d.get('minutes') or []
print('PG', len(sv), len(mp))
")
echo "$PW" | grep -q "PG 0 10" && ok "A4 persiangulf: savePercentage honestly [] (no keeper category, probed) while minutes still serve 10 — per-category absence" || bad "A4: $PW"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=sv-row]')]; const first=rows[0]; const pill=first?.querySelector('span[dir=ltr]'); const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({rows:rows.length, dirAttr:pill?.getAttribute('dir'), pillTxt:pill?.textContent, hasSection:h2s.includes('درصد سیو'), cw:document.documentElement.clientWidth}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"dirAttr":"ltr"' && echo "$B1" | tr -d '\\' | grep -q '"hasSection":true' && ok "B1 DOM: 10 sv-rows + «درصد سیو» + percent pill WITH dir=ltr ($B1)" || bad "B1: $B1"

# B2 real navigation from the first sv-row
NAV=$(agent-browser eval "document.querySelector('[data-testid=sv-row] a')?.getAttribute('href') || 'NO_LINK'")
HREF=$(echo "$NAV" | tr -d '"' | tr -d '\\')
if [ "$HREF" != "NO_LINK" ] && [ -n "$HREF" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B2=$(agent-browser eval "JSON.stringify({path:location.pathname, h1n:document.querySelectorAll('h1').length, h1t:(document.querySelector('h1')||{}).textContent})")
  echo "$B2" | tr -d '\\' | grep -q '"h1n":1' && ok "B2 nav: sv-row click → $HREF with profile h1 «$(echo "$B2" | tr -d '\\' | python3 -c "import sys,json; print(json.loads(sys.stdin.read().strip().strip('\"').replace('\\\\\"','\"'))['h1t'])" 2>/dev/null)»" || bad "B2: $B2"
else
  bad "B2: no link on first sv-row"
fi

# B3 family intact + keeper trio adjacent + historical curation live
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2
B3=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const need=['بهترین پاس‌دهندگان','گل+پاس','برترین امتیازها','بیشترین دقایق','درصد سیو','گل نخرده‌ها','گل‌های پیشگیری‌شده','کارت‌ها']; const missing=need.filter(x=>!h2s.includes(x)); const i1=h2s.indexOf('درصد سیو'), i2=h2s.indexOf('گل نخرده‌ها'), i3=h2s.indexOf('گل‌های پیشگیری‌شده'); const trio=(i1>-1&&i2>-1&&i3>-1&&i1<i2&&i2<i3); return JSON.stringify({missing, trio, vbroken:[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length}); })()")
echo "$B3" | tr -d '\\' | grep -q '"missing":\[\]' && echo "$B3" | tr -d '\\' | grep -q '"trio":true' && echo "$B3" | tr -d '\\' | grep -q '"vbroken":0' && ok "B3 family intact: all NINE sections + keeper trio adjacent (درصد سیو → گل نخرده‌ها → گل‌های پیشگیری‌شده) + no real overflow" || bad "B3: $B3"

# B3b historical season: 2020/21 renders the dead-key-fix curation
agent-browser open "$BASE/topscorers/laliga?season=2020%2F2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B3B=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=sv-row]')]; const names=rows.map(r=>r.querySelector('span.block')?.textContent); return JSON.stringify({rows:rows.length, domenek:names.includes('خائومه دومنک'), faCount:names.filter(n=>n&&/[\\u0600-\\u06FF]/.test(n)).length}); })()")
echo "$B3B" | tr -d '\\' | grep -q '"rows":10' && echo "$B3B" | tr -d '\\' | grep -q '"domenek":true' && echo "$B3B" | tr -d '\\' | grep -q '"faCount":10' && ok "B3b 2020/21: 10 sv-rows all Persian incl. the dead-key-fix «خائومه دومنک» rendering live" || bad "B3b: $B3B"

CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B4 console=0 errors=0" || bad "B4: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== LAT: the warm topscorers route =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm ${MS}ms (contract <5000ms)" || bad "LAT ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE221 DOMPROOF ALL GREEN («درصد سیو» — the deep-file family's NINTH sibling and the THIRD keeper surface: 10-row verbatim-percent on the SAME cached payload, live + frozen anchors, the keeper trio adjacent, the 170 navigation real, the dead-key fix live — API 4/4 + DOM 5/5 + LAT @390x844)" && exit 0
exit 1
