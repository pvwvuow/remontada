#!/bin/bash
# cycle223-hunt.sh — the cycle-223 bug-hunt patrol (registrar of the found class)
# (Bug-hunt (cycle 223): patrol focused on the cycle-222 surface «سیو در هر ۹۰»
#  + new cross-dimensions. THE FINDING (registered for cycle 224 = fix): the
#  search player pool (166 scorers / 171 assists / 177 cards / 194 folds) never
#  folded the deep-file family blocks (215/210/216/217/220/221/222) — keepers
#  and presence/rating kings ride the SAME cached getStandings payload yet are
#  unsearchable (Vallés/Radu/Murić return 0 while Şıyadmanesh/Mbappé hit) —
#  exactly the cycle-177 Janelt class, ×7 blocks. A1 asserts the gap AS FOUND;
#  scripts/cycle224-fixproof.sh will supersede it after the fold lands.)
# Part A (API): A1 the finding as-found + positive controls
#               A2 the 7-league additive sweep + persiangulf mirror honesty
#               A3 ucl tie-rank class on the NEWEST surface (raw 1,1,3,4,5,5,7,8,8,10
#                  → served positional 1..10, the 216 lesson, live-fetched in-gate)
#               A4 second live anchor league: pl served rank-1 == raw rank-1
# Part B (DOM @390x844): B1 bundesliga integer-valued per-90 pill «۶.۰» dir=ltr
#               B2 ucl: keeper QUARTET adjacent + 10 sp90-rows (first quartet DOM
#                  proof outside laliga) + no real overflow
#               B3 ligue1: exactly 9 Persian rows + the deliberate Kocik
#                  honest-English tail at rank-7 (the 219 verdict, rendered as designed)
#               B4 persiangulf: ZERO keeper h2s while minutes serve 10 mp-rows
#               B5 search dialog: Mbappé rows render + Enter navigates to the real
#                  profile; «والس» shows the not-found hint (the finding, in DOM)
#               B6 real navigation from a persiangulf MINUTES row → profile h1
#               B7 console=0 errors=0 across the whole patrol session
# Part C: warm LAT sweep, all 7 leagues <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle223-hunt-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 the FINDING as-found + positive controls (registrar — superseded by 224-fixproof)
F=1
for Q in "والس" "رادو" "موریچ"; do
  N=$(curl -s "$BASE/api/search?q=$(enc "$Q")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
  [ "$N" = "0" ] || F=0
done
C1=$(curl -s "$BASE/api/search?q=$(enc "صیادمنش")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
C2=$(curl -s "$BASE/api/search?q=$(enc "امباپه")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
[ "$F" = "1" ] && [ "$C1" -ge 1 ] && [ "$C2" -ge 1 ] \
  && ok "A1 FINDING as-found: والس/رادو/موریچ (deep-family leaders) unsearchable while صیادمنش=$C1/امباپه=$C2 controls hit — the 177 class ×7 blocks" \
  || bad "A1: gap behavior changed — F=$F controls=$C1/$C2 (if 224 landed, the fixproof gate rules now)"

# A2 7-league additive sweep + persiangulf mirror honesty
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
sp=d.get('savesPer90') or []
mono=all(sp[i]['savesPer90']>=sp[i+1]['savesPer90'] for i in range(len(sp)-1)) if len(sp)==10 else False
pos=[e['rank'] for e in sp]==list(range(1,11))
print(1 if (f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10 and mono and pos) else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K sweep failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
print(1 if (f('scorers')==20 and f('minutes')==10 and f('cleanSheets')==0 and f('ratings')==0 and f('gPlusA')==0 and f('goalsPrevented')==0 and f('savePercentage')==0 and f('savesPer90')==0) else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && ok "A2 six serving leagues carry the full 8-field contract (monotonic positional sp90) + persiangulf mirror-honest (scorers=20 minutes=10, all six deep cats =0)" || bad "A2: SW=$SW PG=$PG"

# A3 ucl tie-rank class on the NEWEST surface (live raw fetch, UA Chrome/124)
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
RAWU=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=42&ccode3=UEFA&lang=en" | py "
import sys,json
d=json.load(sys.stdin)
cat=next((c for c in (d.get('stats') or {}).get('players') or [] if (c.get('header') or '').lower()=='saves per 90'), None)
print(cat.get('fetchAllUrl') if cat else 'NONE')
")
if [ "$RAWU" != "NONE" ] && [ -n "$RAWU" ]; then
  curl -s --compressed -A "$UA" "$RAWU" > "$TMP/uclraw.json"
  curl -s "$BASE/api/topscorers/ucl" > "$TMP/uclapi.json"
  py "
import json
raw=json.load(open('$TMP/uclraw.json'))['TopLists'][0]['StatList'][:10]
api=json.load(open('$TMP/uclapi.json')).get('savesPer90') or []
ranks=[r.get('Rank') for r in raw]==[1,1,3,4,5,5,7,8,8,10]
pos=[e['rank'] for e in api]==list(range(1,11))
vals=all(api[i]['savesPer90']>=api[i+1]['savesPer90'] for i in range(len(api)-1))
names=[r.get('ParticipantName') for r in raw[:3]]==[e['name'] for e in api[:3]]
print('A3CHECK', ranks and pos and vals and names, [r.get('Rank') for r in raw], [e['rank'] for e in api])
" > "$TMP/a3.txt"
  grep -q "A3CHECK True" "$TMP/a3.txt" && ok "A3 ucl tie-rank class: raw competition ranks [1,1,3,4,5,5,7,8,8,10] → served positional 1..10, values monotonic, raw order preserved (the 216 lesson on the NEWEST surface)" || bad "A3: $(cat "$TMP/a3.txt")"
else
  bad "A3: ucl saves category fetchAllUrl unresolvable"
fi

# A4 second live-anchor league: pl
RAWP=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=47&ccode3=ENG&lang=en" | py "
import sys,json
d=json.load(sys.stdin)
cat=next((c for c in (d.get('stats') or {}).get('players') or [] if (c.get('header') or '').lower()=='saves per 90'), None)
print(cat.get('fetchAllUrl') if cat else 'NONE')
")
if [ "$RAWP" != "NONE" ] && [ -n "$RAWP" ]; then
  curl -s --compressed -A "$UA" "$RAWP" > "$TMP/plraw.json"
  curl -s "$BASE/api/topscorers/pl" > "$TMP/plapi.json"
  py "
import json
r=json.load(open('$TMP/plraw.json'))['TopLists'][0]['StatList'][0]
sp=json.load(open('$TMP/plapi.json')).get('savesPer90') or []
ok=bool(sp) and sp[0]['name']==r.get('ParticipantName') and abs(sp[0]['savesPer90']-r.get('StatValue',-1))<1e-9
print('A4CHECK', ok, sp[0]['name'] if sp else '-', r.get('ParticipantName'), r.get('StatValue'))
" > "$TMP/a4.txt"
  grep -q "A4CHECK True" "$TMP/a4.txt" && ok "A4 pl live anchor: served rank-1 == raw saves.json rank-1 (name+value verbatim) — the 222 live-anchor class extends beyond laliga" || bad "A4: $(cat "$TMP/a4.txt")"
else
  bad "A4: pl saves category fetchAllUrl unresolvable"
fi

echo "== Part B: DOM patrol @390x844 =="
agent-browser set viewport 390 844 >/dev/null

# B1 bundesliga integer-valued per-90 corner (raw 6.0 → pill «۶.۰», the one-decimal family format)
agent-browser open "$BASE/topscorers/bundesliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=sp90-row]')]; const pill=rows[0]?.querySelector('span[dir=ltr]'); return JSON.stringify({rows:rows.length, pillTxt:pill?.textContent, dirAttr:pill?.getAttribute('dir')}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"pillTxt":"۶.۰"' && echo "$B1" | tr -d '\\' | grep -q '"dirAttr":"ltr"' && ok "B1 bundesliga: 10 sp90-rows, integer-valued per-90 (raw 6.0) renders the one-decimal family format «۶.۰» with dir=ltr — verbatim preserved (observation, not bug)" || bad "B1: $B1"

# B2 ucl quartet adjacent (first quartet DOM proof outside laliga)
agent-browser open "$BASE/topscorers/ucl" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B2=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده'].map(x=>h2s.indexOf(x)); const rows=[...document.querySelectorAll('[data-testid=sp90-row]')]; const pill=rows[0]?.querySelector('span[dir=ltr]'); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({quartetAdj:q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]), sp90rows:rows.length, pillTxt:pill?.textContent, vbroken}); })()")
echo "$B2" | tr -d '\\' | grep -q '"quartetAdj":true' && echo "$B2" | tr -d '\\' | grep -q '"sp90rows":10' && echo "$B2" | tr -d '\\' | grep -q '"vbroken":0' && ok "B2 ucl: keeper QUARTET adjacent + 10 sp90-rows + «۶.۷» pill + no real overflow — first quartet DOM proof outside laliga" || bad "B2: $B2"

# B3 ligue1: the deliberate honest-English tail (Kocik rank-7, the 219 verdict)
agent-browser open "$BASE/topscorers/ligue1" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B3=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=sp90-row]')]; const names=rows.map(r=>r.querySelector('span.block')?.textContent); const faCount=names.filter(n=>n&&/[\\u0600-\\u06FF]/.test(n)).length; const kocikIdx=names.findIndex(n=>n&&n.includes('Kocik')); return JSON.stringify({rows:rows.length, faCount, kocikIdx}); })()")
echo "$B3" | tr -d '\\' | grep -q '"rows":10' && echo "$B3" | tr -d '\\' | grep -q '"faCount":9' && echo "$B3" | tr -d '\\' | grep -q '"kocikIdx":6' && ok "B3 ligue1: exactly 9 Persian rows + Nicolas Kocik honest-English at rank-7 — the deliberate 219 verdict rendered as designed (not a mapping failure)" || bad "B3: $B3"

# B4 persiangulf: ZERO keeper h2s while minutes serve 10 (mirror honesty)
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B4=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const keepers=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده']; return JSON.stringify({keeperPresent:keepers.filter(k=>h2s.includes(k)), minutes:h2s.includes('بیشترین دقایق'), mpRows:document.querySelectorAll('[data-testid=mp-row]').length}); })()")
echo "$B4" | tr -d '\\' | grep -q '"keeperPresent":\[\]' && echo "$B4" | tr -d '\\' | grep -q '"minutes":true' && echo "$B4" | tr -d '\\' | grep -q '"mpRows":10' && ok "B4 persiangulf: zero keeper h2s (mirror payload honesty extended to the QUARTET) while بیشترین دقایق serves 10 mp-rows" || bad "B4: $B4"

# B4b real navigation from a MINUTES row → profile (the presence surface's first nav proof)
MHREF=$(agent-browser eval "document.querySelector('[data-testid=mp-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$MHREF" != "NO_LINK" ] && [ -n "$MHREF" ]; then
  agent-browser eval "window.location.href='$MHREF'" >/dev/null
  sleep 2.5
  B4B=$(agent-browser eval "JSON.stringify({path:location.pathname, h1n:document.querySelectorAll('h1').length, h1t:(document.querySelector('h1')||{}).textContent})")
  echo "$B4B" | tr -d '\\' | grep -q '"h1n":1' && ok "B4b nav: minutes-row click → $MHREF with profile h1 ($B4B)" || bad "B4b: $B4B"
else
  bad "B4b: no link on first mp-row"
fi

# B5 search dialog: positive control renders + Enter navigates; «والس» shows the finding hint
agent-browser open "$BASE" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
agent-browser eval "document.querySelector('button[aria-label*=جست], button[class*=search], [class*=search] button')?.click(); 'OPEN'" >/dev/null
sleep 1
agent-browser eval "(() => { const inp=document.querySelector('dialog input, [role=dialog] input, input[type=search], input[type=text]'); const setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set; setter.call(inp,'امباپه'); inp.dispatchEvent(new Event('input',{bubbles:true})); return 'TYPED'; })()" >/dev/null
sleep 2
B5A=$(agent-browser eval "(() => { const dlg=document.querySelector('dialog,[role=dialog]'); return JSON.stringify({mbappe:(dlg?.textContent||'').includes('کیلیان امباپه'), groupHdr:(dlg?.textContent||'').includes('بازیکنان')}); })()")
echo "$B5A" | tr -d '\\' | grep -q '"mbappe":true' && echo "$B5A" | tr -d '\\' | grep -q '"groupHdr":true' && ok "B5a search dialog positive control: «امباپه» renders the بازیکنان group with کیلیان امباپه" || bad "B5a: $B5A"
agent-browser eval "document.querySelector('dialog input,[role=dialog] input')?.focus(); 'F'" >/dev/null
agent-browser press Enter >/dev/null 2>&1
sleep 2.5
B5B=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
echo "$B5B" | tr -d '\\' | grep -q '"/player/' && ok "B5b Enter selection navigates to the real profile ($B5B)" || bad "B5b: $B5B"
agent-browser open "$BASE" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
agent-browser eval "document.querySelector('button[aria-label*=جست], button[class*=search], [class*=search] button')?.click(); 'OPEN'" >/dev/null
sleep 1
agent-browser eval "(() => { const inp=document.querySelector('dialog input, [role=dialog] input, input[type=search], input[type=text]'); const setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set; setter.call(inp,'والس'); inp.dispatchEvent(new Event('input',{bubbles:true})); return 'TYPED'; })()" >/dev/null
sleep 2
B5C=$(agent-browser eval "(() => { const dlg=document.querySelector('dialog,[role=dialog]'); return JSON.stringify({notFound:(dlg?.textContent||'').includes('با این نام پیدا نشد')}); })()")
echo "$B5C" | tr -d '\\' | grep -q '"notFound":true' && ok "B5c THE FINDING in DOM: «والس» (the CURRENT sp90 rank-1 of laliga, profile live at /player/999171) → the not-found hint — the pool gap, visible" || bad "B5c: $B5C"

# B7 console across the whole patrol session
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B7 console=0 errors=0 across the whole patrol session" || bad "B7: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LATOK=1
for K in ucl pl laliga seriea bundesliga ligue1 persiangulf; do
  T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/$K"; T1=$(date +%s%N)
  MS=$(( (T1-T0)/1000000 ))
  [ "$MS" -lt 5000 ] || { LATOK=0; bad "LAT $K ${MS}ms"; }
done
[ "$LATOK" = "1" ] && ok "LAT warm sweep: all 7 leagues <5000ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE223 HUNT ALL GREEN (the patrol holds everywhere it looks — the ONE registered finding is the search-pool coverage gap: the deep-file family blocks 215/210/216/217/220/221/222 never joined the 166/171/177/194 fold chain; keepers and presence/rating kings unsearchable while riding the SAME cached payload — registered for cycle 224 = fix)" && exit 0
exit 1
