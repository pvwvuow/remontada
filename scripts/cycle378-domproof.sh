#!/usr/bin/env bash
# cycle378-domproof.sh — bug-hunt patrol (cycle 378): full page patrol +
# verification of the two newest cycles (376 Copa del Rey, 377 DFB Pokal)
# at 390x844. Per page: page errors 0, console errors 0, scrollW==cw==390.
# API prelude: noTable contracts (376/377), table path untouched (PL,
# bundesliga), bracket shapes, hasPendingVAR pass-through (375).
# bug-hunt = report only; no product code changed.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

fresh() { agent-browser close --all >/dev/null 2>&1; agent-browser open "$1" >/dev/null 2>&1; agent-browser set viewport 390 844 >/dev/null 2>&1; agent-browser errors --clear >/dev/null 2>&1; agent-browser console --clear >/dev/null 2>&1; sleep 3; }
hygiene() { # $1=label
  local ERR CON SW CW
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "$1 page-errors=0" "$([ -z "$ERR" ] && echo 1 || echo 0)"
  ck "$1 console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "$1 scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "390" ] && [ "$CW" = "390" ] && echo 1 || echo 0)"
}
dots() { agent-browser eval "(document.body.innerText.match(/[\u06F0-\u06F9]\.[\u06F0-\u06F9]/g)||[]).length" 2>/dev/null | tr -d '"'; }
seps() { agent-browser eval "(document.body.innerText.match(/[\u06F0-\u06F9]\u066B[\u06F0-\u06F9]/g)||[]).length" 2>/dev/null | tr -d '"'; }

# ================= API prelude (live probes, UA Chrome/124) =================
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

# A1/A2: the 376/377 no-table cup contracts
D=$(api '/api/standings?league=dfbpokal' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and len(d.get('rows',[]))==0 and d.get('color')=='#004941' and len(d.get('allSeasons',[]))==12 and d.get('selectedSeason')=='2026/2027' else 0)")
ck "A1 dfbpokal noTable contract (rows0/color/allSeasons12/sel)" "$D"
D=$(api '/api/standings?league=copadelrey' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and len(d.get('rows',[]))==0 and d.get('color')=='#D2202B' else 0)")
ck "A2 copadelrey noTable contract" "$D"
# A3/A4: table path byte-identical (no noTable key leaked into league tables)
D=$(api '/api/standings?league=pl' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and len(d.get('rows',[]))==20 and 'noTable' not in d and d['rows'][0]['name']=='Arsenal' else 0)")
ck "A3 pl table path untouched (rows20/no-noTable/Arsenal)" "$D"
D=$(api '/api/standings?league=bundesliga' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and len(d.get('rows',[]))==18 and 'noTable' not in d else 0)")
ck "A4 bundesliga sibling unchanged (rows18/no-noTable)" "$D"
# A5/A6: bracket shapes — dfbpokal served (377), copadelrey honestly null
D=$(api '/api/league-bracket?league=dfbpokal' | python3 -c "
import json,sys; d=json.load(sys.stdin); b=d.get('bracket') or {}
rs=b.get('rounds') or []
ok = d.get('ok') and len(rs)==1 and rs[0].get('stage')=='1/8' and len(rs[0].get('matchups',[]))==8
names=json.dumps(rs, ensure_ascii=False)
ok = ok and 'اینتراخت\u200cفرانکفورت' in names and 'بروسیادورتموند' in names
print(1 if ok else 0)")
ck "A5 dfbpokal bracket served (1 round 1/8, 8 matchups, Frankfurt/BVB)" "$D"
D=$(api '/api/league-bracket?league=copadelrey' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('bracket') is None else 0)")
ck "A6 copadelrey bracket honestly null (draw pending)" "$D"
# A7: 375 pass-through — hasPendingVAR boolean in the match payload
D=$(api '/api/match/5868114' | python3 -c "import json,sys; d=json.load(sys.stdin); v=d.get('match',{}).get('hasPendingVAR','MISSING'); print(1 if v is False else 0)")
ck "A7 match 5868114 hasPendingVAR boolean false (375 pass-through)" "$D"
# A8: dfbpokal scorers through the standings payload
D=$(api '/api/standings?league=dfbpokal' | python3 -c "import json,sys; d=json.load(sys.stdin); sc=d.get('scorsers') if False else d.get('scorers',[]); print(1 if len(sc)==20 and sc[0].get('name')=='Jonathan Burkardt' else 0)")
ck "A8 dfbpokal scorers 20 / top Burkardt" "$D"

# ================= P1 home =================
fresh "$BASE/"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()?.slice(0,60)" 2>/dev/null | tr -d '"')
hygiene "P1 home"
ck "P1 home h1 rendered («$H1»)" "$([ -n "$H1" ] && echo 1 || echo 0)"

# ================= P2 /league/dfbpokal (377 contract) =================
fresh "$BASE/league/dfbpokal"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal h1 «جام حذفی آلمان» (got «$H1»)" "$([ "$H1" = "جام حذفی آلمان" ] && echo 1 || echo 0)"
DOT=$(agent-browser eval "(() => { const s=document.querySelector('h1 span[aria-hidden]'); return s ? getComputedStyle(s).backgroundColor : 'none'; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal accent dot #004941 (got $DOT)" "$([ "$DOT" = "rgb(0, 73, 65)" ] && echo 1 || echo 0)"
CHIP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('GER') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal GER chip present" "$([ "$CHIP" = "yes" ] && echo 1 || echo 0)"
CUP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('مسابقات حذفی جدول رده‌بندی ندارند') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal honest cup empty copy" "$([ "$CUP" = "yes" ] && echo 1 || echo 0)"
SEL=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.options.length : 0; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal season selector 12 options (got $SEL)" "$([ "$SEL" = "12" ] && echo 1 || echo 0)"
BT=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='براکت') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal bracket tab present" "$([ "$BT" = "yes" ] && echo 1 || echo 0)"
TR=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='انتقال‌ها') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal transfers tab honestly ABSENT (got $TR)" "$([ "$TR" = "no" ] && echo 1 || echo 0)"
# cycle-373 lesson applied: leg rows render the LEG-level names («فرانکفورت»
# from upstream "Frankfurt"), not the matchup-level «اینتراخت‌فرانکفورت» —
# the 377 card transcribed the leg names correctly; probe anchor corrected.
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
BR=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('یک‌هشتم نهایی') && t.includes('فرانکفورت') && t.includes('دورتموند') ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal bracket renders R16 + Frankfurt/BVB leg names (got $BR)" "$([ "$BR" = "yes" ] && echo 1 || echo 0)"
D=$(dots)
ck "P2 dfbpokal zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P2 league/dfbpokal-bracket"

# ================= P3 /league/dfbpokal?season=2024/2025 (377 historical) =================
fresh "$BASE/league/dfbpokal?season=2024%2F2025"
sleep 1
SC=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.value : 'none'; })()" 2>/dev/null | tr -d '"')
ck "P3 dfbpokal historical season chip selected (got $SC)" "$([ "$SC" = "2024/2025" ] && echo 1 || echo 0)"
# cycle-373 lesson applied: the honest-empty copy lives in the جدول tab —
# assert it BEFORE switching to براکت (probe-order artifact fixed).
CUP2=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('مسابقات حذفی جدول رده‌بندی ندارند') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P3 dfbpokal historical keeps honest empty state (جدول tab, pre-switch)" "$([ "$CUP2" = "yes" ] && echo 1 || echo 0)"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
HB=$(agent-browser eval "(() => { const t=document.body.innerText; return (t.includes('فینال') && t.includes('اشتوتگارت')) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P3 dfbpokal historical finished bracket (فینال + اشتوتگارت champion) (got $HB)" "$([ "$HB" = "yes" ] && echo 1 || echo 0)"
hygiene "P3 league/dfbpokal-historical"

# ================= P4 /league/copadelrey (376 contract) =================
fresh "$BASE/league/copadelrey"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P4 copadelrey h1 «جام حذفی اسپانیا» (got «$H1»)" "$([ "$H1" = "جام حذفی اسپانیا" ] && echo 1 || echo 0)"
DOT=$(agent-browser eval "(() => { const s=document.querySelector('h1 span[aria-hidden]'); return s ? getComputedStyle(s).backgroundColor : 'none'; })()" 2>/dev/null | tr -d '"')
ck "P4 copadelrey accent dot #D2202B (got $DOT)" "$([ "$DOT" = "rgb(210, 32, 43)" ] && echo 1 || echo 0)"
CUP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('مسابقات حذفی جدول رده‌بندی ندارند') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P4 copadelrey honest cup empty copy" "$([ "$CUP" = "yes" ] && echo 1 || echo 0)"
SEL=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.options.length : 0; })()" 2>/dev/null | tr -d '"')
ck "P4 copadelrey season selector 12 options (got $SEL)" "$([ "$SEL" = "12" ] && echo 1 || echo 0)"
TR=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='انتقال‌ها') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P4 copadelrey transfers tab honestly ABSENT (got $TR)" "$([ "$TR" = "no" ] && echo 1 || echo 0)"
BT=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='براکت') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P4 copadelrey bracket tab honestly ABSENT until draw (got $BT)" "$([ "$BT" = "no" ] && echo 1 || echo 0)"
# 376 fixture tab: date-grouped real first-round ties render
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='بازی‌های پیش‌رو'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
FX=$(agent-browser eval "(() => { const t=document.body.innerText; return (t.includes('Anaitasuna')||t.includes('آلاوس')||t.includes('ایبار')) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P4 copadelrey fixtures render real R1 ties (got $FX)" "$([ "$FX" = "yes" ] && echo 1 || echo 0)"
D=$(dots)
ck "P4 copadelrey zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P4 league/copadelrey"

# ================= P5 /league/pl (376 rows-guard sanity: table path intact) =================
fresh "$BASE/league/pl"
ROWS=$(agent-browser eval "document.querySelectorAll('table tbody tr').length" 2>/dev/null | tr -d '"')
ck "P5 pl table renders (got $ROWS rows)" "$([ "${ROWS:-0}" -ge 20 ] && echo 1 || echo 0)"
TOP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('آرسنال') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P5 pl آرسنال present in table" "$([ "$TOP" = "yes" ] && echo 1 || echo 0)"
D=$(dots)
ck "P5 pl zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P5 league/pl"

# ================= P6 /topscorers/dfbpokal (377 SSG page) =================
fresh "$BASE/topscorers/dfbpokal"
BU=$(agent-browser eval "(() => { const t=document.body.innerText; return (t.includes('Burkardt')||t.includes('بورکاردت')) ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P6 topscorers/dfbpokal Burkardt present (got $BU)" "$([ "$BU" = "yes" ] && echo 1 || echo 0)"
D=$(dots); S=$(seps)
ck "P6 topscorers/dfbpokal zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
ck "P6 topscorers/dfbpokal ٫ decimals present (got $S)" "$([ "${S:-0}" -ge 1 ] && echo 1 || echo 0)"
hygiene "P6 topscorers/dfbpokal"

# ================= P7 /topscorers/pl (371 contract regression) =================
fresh "$BASE/topscorers/pl"
D=$(dots); S=$(seps)
ck "P7 topscorers/pl zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
ck "P7 topscorers/pl ٫ decimals present (got $S)" "$([ "${S:-0}" -ge 1 ] && echo 1 || echo 0)"
hygiene "P7 topscorers/pl"

# ================= P8 /league/ucl (372 bracket contract regression) =================
fresh "$BASE/league/ucl"
sleep 2   # the bracket tab appears after the client-side league payload lands; 3s alone flaked once (slow upstream)
BT=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='براکت') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P8 ucl bracket tab present" "$([ "$BT" = "yes" ] && echo 1 || echo 0)"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
BR=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('فینال')||t.includes('نیمه‌نهایی')||t.includes('پلی‌آف') ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P8 ucl bracket renders rounds (got $BR)" "$([ "$BR" = "yes" ] && echo 1 || echo 0)"
hygiene "P8 league/ucl-bracket"

# ================= P9 /match/5868114 (375 honest absence + 372 referee decimals) =================
fresh "$BASE/match/5868114"
VP=$(agent-browser eval "(() => { return document.querySelector('[data-testid=var-pending]') ? 'present' : 'absent'; })()" 2>/dev/null | tr -d '"')
ck "P9 match var-pending honestly ABSENT on finished match (got $VP)" "$([ "$VP" = "absent" ] && echo 1 || echo 0)"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='اطلاعات'); if(t) t.click(); return t?'ok':'no-tab'; })()" >/dev/null 2>&1
sleep 1
RF=$(agent-browser eval "(() => { const t=document.body.innerText; return /میانگین کارت زرد\s*[۰-۹]+٫/.test(t) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P9 match referee averages with ٫ (got $RF)" "$([ "$RF" = "yes" ] && echo 1 || echo 0)"
D=$(dots)
ck "P9 match zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P9 match/5868114"

# ================= P10 /player/737066 (370 contract regression) =================
fresh "$BASE/player/737066"
D=$(dots); S=$(seps)
ck "P10 player zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
ck "P10 player ٫ decimals present (got $S)" "$([ "${S:-0}" -ge 1 ] && echo 1 || echo 0)"
hygiene "P10 player/737066"

# ================= K1/K2: KNOWN FINDINGS of this bug-hunt (informational) =================
# cycle-379 (fix) must turn these into hard checks with the expectations below.
# K1 (F1): leg/fixture scores render ASCII digits — the two uncovered rows:
#   league-view.tsx FixtureRow (:89) + league-bracket.tsx LegRow (:24),
#   while the portal convention is faDigits everywhere else (matches-view,
#   team-view, match-detail, goal-notifier, the same card's مجموع row).
#   After the 379 fix: ascii MUST be 0 and persian MUST equal the span count.
agent-browser close --all >/dev/null 2>&1; agent-browser open "$BASE/league/pl" >/dev/null 2>&1; agent-browser set viewport 390 844 >/dev/null 2>&1; sleep 3
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='نتایج اخیر'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
K1=$(agent-browser eval "(() => { const spans=[...document.querySelectorAll('span')].filter(s=>/^[0-9\u06F0-\u06F9]+ : [0-9\u06F0-\u06F9]+$/.test(s.textContent.trim())); return JSON.stringify({n:spans.length, ascii:spans.filter(s=>/[0-9]/.test(s.textContent)).length}); })()" 2>/dev/null | tr -d '"')
echo "KNOWN-FIND K1 pl-recent score spans $K1 (currently ASCII; 379 flips to hard check ascii=0)"
agent-browser close --all >/dev/null 2>&1; agent-browser open "$BASE/league/dfbpokal" >/dev/null 2>&1; agent-browser set viewport 390 844 >/dev/null 2>&1; sleep 3
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
K2=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('Darmstadt') ? 'latin-leak' : 'persian-ok'; })()" 2>/dev/null | tr -d '"')
echo "KNOWN-FIND K2 dfbpokal bracket Darmstadt=$K2 (TEAM_FA entry missing; 379 flips to hard check persian-ok)"
hygiene "K3 dfbpokal-bracket"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
