#!/usr/bin/env bash
# cycle373-domproof.sh — bug-hunt patrol (cycle 373): 9 pages at 390x844.
# Per page: page errors 0, console errors 0, scrollW==cw==390.
# Targeted contract assertions (369-372): ٫ decimals, zero ASCII dots,
# KPI/meter podium, bracket tab, referee averages, poll card, honest absence.
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

# ---- P1 home ----
fresh "$BASE/"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()?.slice(0,60)" 2>/dev/null | tr -d '"')
hygiene "P1 home"
ck "P1 home h1 rendered («$H1»)" "$([ -n "$H1" ] && echo 1 || echo 0)"

# ---- P2 /topscorers/pl (cycle-371 contract) ----
fresh "$BASE/topscorers/pl"
D=$(dots); S=$(seps)
ck "P2 pl zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
ck "P2 pl ٫ decimals present (got $S)" "$([ "${S:-0}" -ge 1 ] && echo 1 || echo 0)"
hygiene "P2 topscorers/pl"

# ---- P3 /league/pl آمار فصل (367/369 contract: meter podium ٫ + live KPI) ----
fresh "$BASE/league/pl"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='آمار فصل'); if(t) t.click(); return t?'ok':'no-tab'; })()" >/dev/null 2>&1
sleep 2
CH=$(agent-browser eval "document.querySelectorAll('[data-testid=league-boards] [role=tab]').length" 2>/dev/null | tr -d '"')
ck "P3 pl boards role=tab chips=33 (got $CH)" "$([ "$CH" = "33" ] && echo 1 || echo 0)"
# live KPI: expected value computed from the standings payload (no hardcoded anchor)
KPI_EXP=$(python3 -c "
import json,urllib.request
UA={'User-Agent':'Mozilla/5.0'}
d=json.load(urllib.request.urlopen('http://localhost:3000/api/standings?league=pl',timeout=25))
rows=d['rows']; g=sum(r['goalsFor'] for r in rows); m=sum(r['played'] for r in rows)/2
fa=lambda s: s.translate(str.maketrans('0123456789.','۰۱۲۳۴۵۶۷۸۹٫'))
print(fa(f'{g/m:.2f}'))")
KPI=$(agent-browser eval "(() => { const p=[...document.querySelectorAll('p')].find(x=>x.textContent?.includes('میانگین گل هر بازی')); return p ? p.parentElement.querySelector('p').textContent : 'no-kpi'; })()" 2>/dev/null | tr -d '"')
ck "P3 pl KPI live = computed ($KPI vs $KPI_EXP)" "$([ "$KPI" = "$KPI_EXP" ] && echo 1 || echo 0)"
D=$(dots)
ck "P3 pl zero dots in boards (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P3 league/pl-stats"

# ---- P4 /league/ucl bracket (372 contract) ----
fresh "$BASE/league/ucl"
BT=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='براکت') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P4 ucl bracket tab present" "$([ "$BT" = "yes" ] && echo 1 || echo 0)"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
BR=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('فینال')||t.includes('نیمه‌نهایی')||t.includes('پلی‌آف') ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P4 ucl bracket renders rounds (got $BR)" "$([ "$BR" = "yes" ] && echo 1 || echo 0)"
hygiene "P4 league/ucl-bracket"

# ---- P5 /team/9825 (370 contract: میانگین ۱٫۶ + zero dots) ----
fresh "$BASE/team/9825"
AV=$(agent-browser eval "(() => { const t=document.body.innerText; const m=t.match(/میانگین [۰-۹]+٫[۰-۹]+/); return m?m[0]:'none'; })()" 2>/dev/null | tr -d '"')
ck "P5 team میانگین with ٫ (got $AV)" "$([ "$AV" != "none" ] && echo 1 || echo 0)"
D=$(dots)
ck "P5 team zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P5 team/9825"

# ---- P6 /match/5868114 info tab (372 contract: referee averages ٫ + zero dots) ----
fresh "$BASE/match/5868114"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='اطلاعات'); if(t) t.click(); return t?'ok':'no-tab'; })()" >/dev/null 2>&1
sleep 1
RF=$(agent-browser eval "(() => { const t=document.body.innerText; return (t.includes('۵٫۳۵')||/میانگین کارت زرد\s*[۰-۹]+٫/.test(t)) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P6 match referee averages with ٫ (got $RF)" "$([ "$RF" = "yes" ] && echo 1 || echo 0)"
D=$(dots)
ck "P6 match zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P6 match/5868114-info"

# ---- P7 /player/737066 (370 contract) ----
fresh "$BASE/player/737066"
D=$(dots); S=$(seps)
ck "P7 player zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
ck "P7 player ٫ decimals present (got $S)" "$([ "${S:-0}" -ge 1 ] && echo 1 || echo 0)"
hygiene "P7 player/737066"

# ---- P8 /league/iraq (92 honest absence + 12-option selector) ----
fresh "$BASE/league/iraq"
SEL=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.options.length : 0; })()" 2>/dev/null | tr -d '"')
ck "P8 iraq season selector 12 options (got $SEL)" "$([ "$SEL" = "12" ] && echo 1 || echo 0)"
hygiene "P8 league/iraq"

# ---- P9 /match/5749720 (369/370 contract: rating pill ۸٫۷) ----
fresh "$BASE/match/5749720"
RP=$(agent-browser eval "(() => { const t=document.body.innerText; const m=t.match(/۸٫[۰-۹]/); return m?m[0]:'none'; })()" 2>/dev/null | tr -d '"')
ck "P9 match rating pill with ٫ (got $RP)" "$([ "$RP" != "none" ] && echo 1 || echo 0)"
D=$(dots)
ck "P9 match zero dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P9 match/5749720"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
