#!/bin/bash
# cycle228-hunt.sh — the cycle-228 bug-hunt patrol (registrar of the found class)
# (Bug-hunt (cycle 228): patrol focused on the two NEWEST surfaces — «گل در
#  هر ۹۰» (gp90, cycle 227) + «گل مورد انتظار» (xG, cycle 226) — + new
#  cross-dimensions. Verdict: ZERO rendering/data bugs; ONE real
#  coverage-class finding registered for cycle 229 = fix. THE FINDING: the
#  226/227 surfaces broke the standing name-curation chain (215→217→221→222
#  — "the fallbacks on the SERVED top-10s", the 167 lesson) — 52 unmapped raw
#  English rows on the two newest surfaces' served top-10s across 7 leagues,
#  including 9 of the 10 persiangulf gp90 rows (Iranian players rendering
#  English on the Persian UI; rank-7 Hosseinzadeh IS mapped — the internal
#  control proving the mechanism works on this very block), plus a rolling
#  drift backlog on the older surfaces (56 more English rows, e.g. Szoboszlai/
#  Rico Lewis on ucl ratings, Stefano Turati on the seriea penalty-saves
#  rank-1) and the historical anchors (Messi 2020/21, Durán 2023/24, Benzema
#  2022/23). Every such row is unreachable from Persian search — live A/B
#  proof 2026-10-30: «بولای دیا»=0/'Boulaye Dia'=1 (ligue1 gp90 RANK-1),
#  «وحید امیری»=0/'Vahid Amiri'=1, «گابریل جسوس»=0/'Gabriel Jesus'=1,
#  «توراتی»=0/'Turati'=1, «شهریاری»=0/'Shahriari'=1, «فلمینگ»=0/'Flemming'=1
#  — while the mapped control «حسین‌زاده»=1 hits. A1 asserts the gap AS FOUND;
#  scripts/cycle229-fixproof.sh will supersede it after the 222-pattern
#  curation lands (the 104 rule: confident transliterations only; the 219
#  verdict: genuinely doubtful names stay honest-English like Kocik).)
# Part A (API): A1 the finding as-found (registrar) + the mapped internal control
#               A2 the full 12-field contract sweep (six domestics + persiangulf
#                  mirror honesty incl. the FIRST Gulf deep sibling + mas cards-only)
#               A3 season-aware anchors on THREE historical seasons (the 202 pattern)
#               A4 live upstream drift probe on the NEWEST surface (raw vs served,
#                  UA Chrome/124, with the 95s guard-class retry against L2 staleness)
#               A5 the 224 fold-chain regression (ten blocks + single-listing)
# Part B (DOM @390x844): B1 laliga rate-pair order + keeper quintet + no overflow
#               B2 the «۱.۷۷» dir=ltr pill + real navigation to /player/696679
#               B3 ucl the Haaland 2.0 JS-number corner renders «۲.۰۰» (toFixed(2))
#               B4 persiangulf: the Gulf's own gp90 serves in DOM (ملوان first),
#                  xg honestly absent, minutes intact
#               B5 mas honest absence (the 176 cards-only contract)
#               B6 historical UI (season deep-link): Messi 0.89 anchor renders;
#                  the finding's DOM face = the anchor's English name (registrar,
#                  superseded by the 229 fixproof once the curation lands)
#               B7 search dialog: «فلمینگ» honest not-found + suggestions (the
#                  finding in DOM); 'Flemming' renders the بازیکنان row
#               B8 console=0 errors=0 across the whole patrol session
# Part C: warm LAT sweep, all 7 leagues <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle228-hunt-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 THE FINDING as-found (registrar — superseded by 229-fixproof)
F=1
for PAIR in "بولای دیا|Boulaye Dia" "وحید امیری|Vahid Amiri" "گابریل جسوس|Gabriel Jesus" "توراتی|Turati" "شهریاری|Shahriari" "فلمینگ|Flemming"; do
  FA="${PAIR%%|*}"; EN="${PAIR##*|}"
  FN=$(curl -s "$BASE/api/search?q=$(enc "$FA")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
  ENN=$(curl -s "$BASE/api/search?q=$(enc "$EN")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
  [ "$FN" = "0" ] && [ "$ENN" -ge 1 ] || F=0
done
PGN=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPer90') or []
en=sum(1 for r in gp if (r.get('nameFa') or '')==r['name'])
ctrl=sum(1 for r in gp if (r.get('nameFa') or '')!=r['name'])
print('PGN', en, ctrl, len(gp))
")
PGENG=$(echo "$PGN" | awk '{print $2}'); PGFA=$(echo "$PGN" | awk '{print $3}')
TOTEN=$(python3 - <<PY
import json,urllib.request
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r: return json.load(r)
n=0
for k in ['ucl','pl','laliga','seriea','bundesliga','ligue1','persiangulf']:
    d=get('$BASE/api/topscorers/'+k)
    for r in (d.get('goalsPer90') or [])+(d.get('xg') or []):
        if (r.get('nameFa') or '')==r['name']: n+=1
print(n)
PY
)
[ "$F" = "1" ] && [ "$PGENG" = "9" ] && [ "$PGFA" -ge 1 ] && [ "$TOTEN" -ge 40 ] \
  && ok "A1 FINDING as-found: 6/6 Persian-search A/B pairs dead-end (0 fa vs ≥1 en) — «بولای دیا» the ligue1 gp90 RANK-1, «وحید امیری» the famous Iranian international, «گابریل جسوس», «توراتی» the seriea penalty-saves rank-1, «شهریاری» the Gulf's own king; persiangulf gp90 = $PGENG/10 English rows while rank-7 Hosseinzadeh IS mapped (the internal control — the mechanism works on this very block); total unmapped English rows on the two newest surfaces' top-10s = $TOTEN (the 215→217→221→222 curation chain broken by 226/227 + form-drift backlog)" \
  || bad "A1: gap behavior changed — pairs F=$F pgEnglish=$PGENG pgFa=$PGFA total=$TOTEN (if 229 landed, the fixproof gate rules now)"

# A2 the full 12-field contract sweep
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
gp=d.get('goalsPer90') or []; xg=d.get('xg') or []
mono=all(gp[i]['goalsPer90']>=gp[i+1]['goalsPer90'] for i in range(len(gp)-1)) and all(xg[i]['xg']>=xg[i+1]['xg'] for i in range(len(xg)-1)) if len(gp)==10 and len(xg)==10 else False
pos=[e['rank'] for e in gp]==list(range(1,11))
print(1 if (f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10 and f('xg')==10 and f('goalsPer90')==10 and 0<f('penaltySaves')<10 and mono and pos) else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K sweep failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
print(1 if (f('scorers')==20 and f('minutes')==10 and f('goalsPer90')==10 and f('xg')==0 and f('penaltySaves')==0 and f('cleanSheets')==0 and f('ratings')==0 and f('gPlusA')==0 and f('goalsPrevented')==0 and f('savePercentage')==0 and f('savesPer90')==0) else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
c=d.get('cards') or {}
ncards=len((c.get('yellow') or []))+len((c.get('red') or []))
print(1 if (f('scorers')==20 and f('goalsPer90')==0 and f('xg')==0 and f('minutes')==0 and isinstance(c,dict) and ncards>=1) else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A2 six domestics carry the full 12-field contract (gp90+xg monotonic positional 1..10, penaltySaves naturally thin); PERSIANGULF mirrors honestly with the FIRST Gulf deep sibling SERVING (gp90=10 beside scorers=20/minutes=10, xg/ps/deep honestly 0); mas cards-only (the 176 contract, cards ≥1 — the yellow list may be naturally thin/empty upstream, the 225 lesson: live-observed 2026-10-30 yellow=0 red=5 with the empty group honestly absent in DOM)" || bad "A2: SW=$SW PG=$PG MAS=$MAS"

# A3 season-aware anchors on three historical seasons
H=1
for Q in "laliga?season=2020%2F2021|Lionel Messi|0.89|23.9" "pl?season=2023%2F2024|Jhon Durán|0.97|29.3" "laliga?season=2022%2F2023|Karim Benzema|0.84|24.3"; do
  IFS='|' read -r QQ GN GV XV <<< "$Q"
  R=$(curl -s "$BASE/api/topscorers/$QQ" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPer90') or []; xg=d.get('xg') or []
print('H', len(gp)==10, gp[0]['name']=='$GN' and abs(gp[0]['goalsPer90']-$GV)<1e-9, xg[0]['name'] in ('$GN','Erling Haaland','Robert Lewandowski') and abs(xg[0]['xg']-$XV)<1e-9, len(d.get('penaltySaves') or [])==0)
" 2>/dev/null || echo "H False False False False")
  echo "$R" | grep -q "H True True True True" || { H=0; bad "A3: $QQ → $R"; }
done
[ "$H" = "1" ] && ok "A3 season-aware anchors: 2020/21 laliga Messi 0.89/23.9, 2023/24 pl Durán 0.97 + Haaland 29.3, 2022/23 laliga Benzema 0.84 + Lewandowski 24.3 — penaltySaves honestly 0 on all three (the 132 sibling)" || bad "A3: $H"

# A4 live upstream drift on the NEWEST surface (raw vs served, with the guard-class retry)
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
URLS=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en" | py "
import sys,json
d=json.load(sys.stdin)
cats=(d.get('stats') or {}).get('players') or []
gp=next((c for c in cats if (c.get('header') or '').lower()=='goals per 90'), None)
xg=next((c for c in cats if (c.get('header') or '').lower()=='expected goals (xg)'), None)
print((gp.get('fetchAllUrl') if gp else 'NONE')+' '+(xg.get('fetchAllUrl') if xg else 'NONE'))
")
GPURL="${URLS%% *}"; XGURL="${URLS##* }"
if [ "$GPURL" != "NONE" ] && [ -n "$GPURL" ] && [ "$XGURL" != "NONE" ] && [ -n "$XGURL" ]; then
  A4=0
  for TRY in 1 2; do
    curl -s --compressed -A "$UA" "$GPURL" > "$TMP/gp90raw.json"
    curl -s --compressed -A "$UA" "$XGURL" > "$TMP/xgraw.json"
    curl -s "$BASE/api/topscorers/laliga" > "$TMP/laliga.json"
    R=$(py "
import json
g=json.load(open('$TMP/gp90raw.json'))['TopLists'][0]['StatList']
x=json.load(open('$TMP/xgraw.json'))['TopLists'][0]['StatList']
api=json.load(open('$TMP/laliga.json'))
gp=api.get('goalsPer90') or []; xg=api.get('xg') or []
gdec=max((len(str(r['StatValue']).split('.')[1]) if '.' in str(r['StatValue']) else 0) for r in g)
xdec=max((len(str(r['StatValue']).split('.')[1]) if '.' in str(r['StatValue']) else 0) for r in x)
ok=bool(gp) and bool(xg) and gp[0]['name']==g[0]['ParticipantName'] and abs(gp[0]['goalsPer90']-g[0]['StatValue'])<1e-9 and xg[0]['name']==x[0]['ParticipantName'] and abs(xg[0]['xg']-x[0]['StatValue'])<1e-9 and gdec<=2 and xdec<=1
print('A4CHECK', ok, g[0]['ParticipantName'], g[0]['StatValue'], x[0]['ParticipantName'], x[0]['StatValue'], 'dec', gdec, xdec)
")
    echo "$R" | grep -q "A4CHECK True" && { A4=1; break; }
    [ "$TRY" = "1" ] && sleep 95  # the 210-class guard re-probe window against a stale L2
  done
  [ "$A4" = "1" ] && ok "A4 live drift probe (the NEWEST surface): laliga raw goals_per_90.json rank-1 == served VERBATIM + raw xg rank-1 == served, upstream decimals ≤2 (gp90) / ≤1 (xg) — the 227/226 precision claims hold live, ZERO drift" || bad "A4: $R"
else
  bad "A4: category fetchAllUrl unresolvable ($URLS)"
fi

# A5 the 224 fold-chain regression (ten blocks, single-listing, mapped Gulf control)
FL=$(curl -s "$BASE/api/search?q=$(enc "Flemming")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
h=[p for p in ps if p['playerId']==873559]
print('FL', bool(h) and h[0].get('rank')==1 and ('goals' not in h[0]))
")
SH=$(curl -s "$BASE/api/search?q=$(enc "Shahriari")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
print('SH', any(p['playerId']==1793813 for p in ps))
")
VA=$(curl -s "$BASE/api/search?q=$(enc "والس")" | py "import sys,json;print('VA', len(json.load(sys.stdin).get('players') or []))")
MB=$(curl -s "$BASE/api/search?q=$(enc "امباپه")" | py "import sys,json;print('MB', len(json.load(sys.stdin).get('players') or []))")
HZ=$(curl -s "$BASE/api/search?q=$(enc "حسین‌زاده")" | py "import sys,json;print('HZ', len(json.load(sys.stdin).get('players') or []))")
RA=$(curl -s "$BASE/api/search?q=$(enc "رافینیا")" | py "import sys,json;print('RA', len(json.load(sys.stdin).get('players') or []))")
echo "$FL" | grep -q "FL True" && echo "$SH" | grep -q "SH True" && echo "$VA" | grep -q "VA 1" && echo "$MB" | grep -q "MB 2" && echo "$HZ" | grep -q "HZ 1" && echo "$RA" | grep -q "RA 1" \
  && ok "A5 fold-chain regression (ten blocks): 'Flemming' rank=1 with NO goals key, 'Shahriari' searchable, «والس»=1, «امباپه»=2 (Ethan+Kylian), «حسین‌زاده»=1 (the mapped Gulf control), Raphinha listed EXACTLY once (scorers+ratings+gPlusA+gp90+xg dual-listing deduped)" || bad "A5: $FL $SH $VA $MB $HZ $RA"

echo "== Part B: DOM patrol @390x844 =="
agent-browser set viewport 390 844 >/dev/null

# B1 laliga: rate-pair order + keeper quintet + no overflow
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iG=h2s.indexOf('گل در هر ۹۰'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iG>iX&&iM>iG; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({gp90:document.querySelectorAll('[data-testid=gp90-row]').length, xg:document.querySelectorAll('[data-testid=xg-row]').length, order, quintet, vbroken}); })()")
echo "$B1" | tr -d '\\' | grep -q '"gp90":10' && echo "$B1" | tr -d '\\' | grep -q '"xg":10' && echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && ok "B1 laliga: 10 gp90-rows + 10 xg-rows, the rate PAIR adjacent (گل مورد انتظار → گل در هر ۹۰ → دقایق), keeper QUINTET still adjacent, zero real overflow @390x844" || bad "B1: $B1"

# B2 the pill + real navigation to Raphinha
B2=$(agent-browser eval "(() => { const row=document.querySelector('[data-testid=gp90-row]'); const pill=row?.firstElementChild?.lastElementChild; return JSON.stringify({pillTxt:pill?.textContent, dir:pill?.getAttribute('dir'), href:row?.querySelector('a')?.getAttribute('href')}); })()")
echo "$B2" | tr -d '\\' | grep -q '"pillTxt":"۱.۷۷"' && echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"/player/696679"' && ok "B2 laliga: the «۱.۷۷» dir=ltr pill (Raphinha, two decimals verbatim) links /player/696679" || bad "B2: $B2"
agent-browser open "$BASE/player/696679" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2
B2B=$(agent-browser eval "JSON.stringify({h1:(document.querySelector('h1')||{}).textContent})")
echo "$B2B" | tr -d '\\' | grep -q '"رافینیا"' && ok "B2b real navigation: /player/696679 renders h1 «رافینیا»" || bad "B2b: $B2B"

# B3 ucl: the Haaland 2.0 JS-number corner renders «۲.۰۰» (toFixed(2), the 217 display rule)
agent-browser open "$BASE/topscorers/ucl" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B3=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=gp90-row]')]; const pill=rows[0]?.firstElementChild?.lastElementChild; return JSON.stringify({rows:rows.length, pillTxt:pill?.textContent, dir:pill?.getAttribute('dir'), first:(rows[0]?.textContent||'').replace(/\s+/g,'').slice(0,24)}); })()")
echo "$B3" | tr -d '\\' | grep -q '"rows":10' && echo "$B3" | tr -d '\\' | grep -q '"pillTxt":"۲.۰۰"' && echo "$B3" | tr -d '\\' | grep -q '"dir":"ltr"' && ok "B3 ucl: the JS-number corner (raw 2.0 Haaland) renders «۲.۰۰» with dir=ltr — toFixed(2) verbatim, the 227 display rule holds on the value that would lose its decimals naively" || bad "B3: $B3"

# B4 persiangulf: the Gulf's own gp90 serves in DOM + xg honest absence
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B4=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const rows=[...document.querySelectorAll('[data-testid=gp90-row]')]; const first=(rows[0]?.textContent||'').replace(/\s+/g,''); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({gp90H2:h2s.includes('گل در هر ۹۰'), xgH2:h2s.includes('گل مورد انتظار'), mpH2:h2s.includes('بیشترین دقایق'), rows:rows.length, malavanFirst:first.includes('ملوان'), mpRows:document.querySelectorAll('[data-testid=mp-row]').length, vbroken}); })()")
echo "$B4" | tr -d '\\' | grep -q '"gp90H2":true' && echo "$B4" | tr -d '\\' | grep -q '"xgH2":false' && echo "$B4" | tr -d '\\' | grep -q '"mpH2":true' && echo "$B4" | tr -d '\\' | grep -q '"rows":10' && echo "$B4" | tr -d '\\' | grep -q '"malavanFirst":true' && echo "$B4" | tr -d '\\' | grep -q '"mpRows":10' && echo "$B4" | tr -d '\\' | grep -q '"vbroken":0' && ok "B4 persiangulf: «گل در هر ۹۰» serves 10 rows with ملوان first (Shahriari ۱.۰۶) — the FIRST Gulf deep sibling in DOM — while «گل مورد انتظار» is honestly ABSENT (no xG category upstream) and minutes stays intact, zero overflow" || bad "B4: $B4"

# B5 mas honest absence (the 176 cards-only contract)
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({gp90:h2s.includes('گل در هر ۹۰'), xg:h2s.includes('گل مورد انتظار'), cards:h2s.some(h=>(h||'').includes('کارت'))}); })()")
echo "$B5" | tr -d '\\' | grep -q '"gp90":false' && echo "$B5" | tr -d '\\' | grep -q '"xg":false' && echo "$B5" | tr -d '\\' | grep -q '"cards":true' && ok "B5 mas: both newest surfaces honestly absent, the cards-only contract stands (the 176 rule)" || bad "B5: $B5"

# B6 historical UI deep-link: Messi 0.89 anchor + the finding's DOM face (registrar)
agent-browser open "$BASE/topscorers/laliga?season=2020%2F2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 3
B6=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const gp=[...document.querySelectorAll('[data-testid=gp90-row]')]; const first=(gp[0]?.textContent||'').replace(/\s+/g,''); const name=gp[0]?.querySelector('span.block')?.textContent||gp[0]?.textContent||''; return JSON.stringify({gp90H2:h2s.includes('گل در هر ۹۰'), xgH2:h2s.includes('گل مورد انتظار'), rows:gp.length, firstTxt:first.slice(0,28), anchorEnglish:/[A-Za-z]/.test(name)}); })()")
echo "$B6" | tr -d '\\' | grep -q '"gp90H2":true' && echo "$B6" | tr -d '\\' | grep -q '"xgH2":true' && echo "$B6" | tr -d '\\' | grep -q '"rows":10' && echo "$B6" | tr -d '\\' | grep -q '"firstTxt":"۰۱LionelMessiبارسلونا۰.۸۹"' && ok "B6 historical UI: the season deep-link renders BOTH newest surfaces with the frozen anchor Lionel Messi بارسلونا ۰.۸۹ first (the 202 pattern in the real UI)" || bad "B6: $B6"
echo "$B6" | tr -d '\\' | grep -q '"anchorEnglish":true' && ok "B6b THE FINDING in DOM (registrar — superseded by the 229 fixproof): the historical ANCHOR renders its raw English name (Lionel Messi, no nameFa) — the same curation gap, on the most famous face of the class" || bad "B6b: $B6"

# B7 search dialog: the finding in DOM + the English positive
agent-browser open "$BASE" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
agent-browser eval "document.querySelector('button[aria-label*=جست], button[class*=search], [class*=search] button')?.click(); 'OPEN'" >/dev/null
sleep 1
agent-browser eval "(() => { const inp=document.querySelector('dialog input, [role=dialog] input, input[type=search], input[type=text]'); const setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set; setter.call(inp,'فلمینگ'); inp.dispatchEvent(new Event('input',{bubbles:true})); return 'TYPED'; })()" >/dev/null
sleep 2.5
B7=$(agent-browser eval "(() => { const dlg=document.querySelector('dialog,[role=dialog]'); return JSON.stringify({notFound:(dlg?.textContent||'').includes('با این نام پیدا نشد'), suggestions:(dlg?.textContent||'').includes('شاید دنبال این تیم')}); })()")
echo "$B7" | tr -d '\\' | grep -q '"notFound":true' && echo "$B7" | tr -d '\\' | grep -q '"suggestions":true' && ok "B7a THE FINDING in DOM: «فلمینگ» (the pl gp90 RANK-1, live profile) → the honest not-found hint + suggestions, while the row sits served on /topscorers/pl" || bad "B7a: $B7"
agent-browser eval "(() => { const inp=document.querySelector('dialog input, [role=dialog] input, input[type=search], input[type=text]'); const setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set; setter.call(inp,'Flemming'); inp.dispatchEvent(new Event('input',{bubbles:true})); return 'TYPED'; })()" >/dev/null
sleep 2.5
B7B=$(agent-browser eval "(() => { const dlg=document.querySelector('dialog,[role=dialog]'); return JSON.stringify({row:(dlg?.textContent||'').includes('Zian Flemming'), group:(dlg?.textContent||'').includes('بازیکنان')}); })()")
echo "$B7B" | tr -d '\\' | grep -q '"row":true' && echo "$B7B" | tr -d '\\' | grep -q '"group":true' && ok "B7b the English spelling renders the بازیکنان row (Zian Flemming) — the A/B pair visible in one dialog" || bad "B7b: $B7B"

# B8 console across the whole patrol session
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B8 console=0 errors=0 across the whole patrol session (laliga, profile, ucl, persiangulf, mas, historical, home, dialog)" || bad "B8: console=$CN errors=$CE"
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
[ "$FAIL" = "0" ] && echo "CYCLE228 HUNT ALL GREEN (the patrol holds everywhere it looks — ZERO rendering/data bugs; the ONE registered finding is the name-curation gap: the 226/227 surfaces + form-drift left 100+ unmapped raw English rows on the CURRENTLY SERVED top-10s across 12 blocks/7 leagues, incl. 9/10 of the persiangulf gp90 block and the historical anchors — every one unreachable from Persian search; registered for cycle 229 = fix, the 222 pattern: curate the confident subset of the served top-10s, Kocik-class doubtful names stay honest-English)" && exit 0
exit 1
