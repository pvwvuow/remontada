#!/bin/bash
# cycle-369 fix DOM proof — the Persian decimal separator ٫ (U+066B) now
# renders inside Persian numerals in league-view numeric displays
# (boardValue podiums, KPI averages, xG table), ASCII '.' gone.
AB="agent-browser"
BASE="http://localhost:3000"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "PASS: $1"; }
bad(){ FAIL=$((FAIL+1)); echo "FAIL: $1"; }
fresh(){
  $AB close --all >/dev/null 2>&1
  $AB open "$1" >/dev/null 2>&1 || { bad "open $1"; return 1; }
  $AB set viewport 390 844 >/dev/null 2>&1
  $AB errors --clear >/dev/null 2>&1
  $AB console --clear >/dev/null 2>&1
  sleep 1
}
vpc(){
  local SW CW E C
  SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null)
  CW=$($AB eval "document.documentElement.clientWidth" 2>/dev/null)
  E=$($AB errors 2>/dev/null | grep -v -i '^no ' | grep -c .)
  C=$($AB console 2>/dev/null | grep -ci 'error')
  if [ "$SW" = "390" ] && [ "$CW" = "390" ]; then ok "$1 scrollW=cw=390"; else bad "$1 scrollW=$SW cw=$CW"; fi
  if [ "${E:-0}" = "0" ]; then ok "$1 page-errors=0"; else bad "$1 page-errors=$E"; fi
  if [ "${C:-0}" = "0" ]; then ok "$1 console-errors=0"; else bad "$1 console-errors=$C"; fi
}
ev(){ $AB eval "$1" 2>/dev/null; }

echo "=== P1: /league/pl boards — meter podium now ٫ ==="
fresh "$BASE/league/pl" || exit 1
$AB find text "آمار فصل" click >/dev/null 2>&1; sleep 3
CNT=$(ev "[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].length")
[ "${CNT:-0}" = "33" ] && ok "team chips=33 got=$CNT" || bad "team chips got=$CNT want=33"
ev "(() => { const b=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(x=>x.textContent.includes('مسافت پوشیده')); b && b.click(); return b?'clicked':'missing'; })()" >/dev/null
sleep 1
POD=$(ev "[...document.querySelectorAll('[data-testid=league-boards] a[href*=\"/team/\"]')].slice(0,3).map(a=>a.textContent.trim()).join(' | ')")
echo "  podium: $POD"
echo "$POD" | grep -q 'کیلومتر' && echo "$POD" | grep -q '٫' && ok "369 meter podium uses ٫ (Persian decimal)" || bad "meter podium: $POD"
echo "$POD" | grep -q '۱۱۹٫۴' && ok "Fulham ۱۱۹٫۴ کیلومتر exact" || bad "Fulham value: $POD"
DOT=$(ev "[...document.querySelectorAll('[data-testid=league-boards] a')].some(a=>/[۰-۹]\.[۰-۹]/.test(a.textContent))")
[ "$DOT" = "false" ] && ok "no ASCII-dot numerals inside boards links" || bad "ASCII dot still in boards: $DOT"

echo "=== P2: player view — total distance ٫ ==="
$AB find text "بازیکنان" click >/dev/null 2>&1; sleep 1
ev "(() => { const b=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(x=>x.textContent.includes('جمع مسافت')); b && b.click(); return b?'clicked':'missing'; })()" >/dev/null
sleep 1
POD2=$(ev "[...document.querySelectorAll('[data-testid=league-boards] a[href*=\"/player/\"]')].slice(0,3).map(a=>a.textContent.trim()).join(' | ')")
echo "  podium: $POD2"
echo "$POD2" | grep -q '۱۰۷٫۴' && ok "Gross ۱۰۷٫۴ کیلومتر exact (player)" || bad "player podium: $POD2"

echo "=== P3: KPI میانگین گل هر بازی — ٫ (value <p> renders BEFORE label) ==="
KPI=$(ev "(()=>{const p=[...document.querySelectorAll('p')].find(x=>x.textContent.trim()==='میانگین گل هر بازی'); return p? p.parentElement.querySelector('p').textContent : 'ABSENT';})()")
echo "  kpi value: $KPI"
echo "$KPI" | grep -q '٫' && ok "KPI avg uses ٫: $KPI" || bad "KPI avg value: $KPI"

echo "=== P4: xG table (fmt1) — ٫ on the default جدول view (fresh state, no tab clicks) ==="
fresh "$BASE/league/pl" >/dev/null || exit 1; sleep 2
XG=$(ev "(()=>{const el=document.querySelector('[data-testid=league-xg]'); return el? (/[۰-۹]\.[۰-۹]/.test(el.textContent)?'ASCIIDOT':(el.textContent.includes('٫')?'PERSIAN':'NODECIMAL')) : 'ABSENT';})()")
echo "  xg table state: $XG"
XG=$(echo "$XG" | tr -d '"')
[ "$XG" = "PERSIAN" ] && ok "xG table decimals use ٫" || bad "xG table: $XG"
vpc "league/pl"

echo "=== P5: /league/iraq honest absence intact ==="
fresh "$BASE/league/iraq" || exit 1
HAS=$(ev "!!document.querySelector('[data-testid=league-boards]')")
[ "$HAS" = "false" ] && ok "iraq boards still honest-absent" || bad "iraq boards present=$HAS"
vpc "league/iraq"

echo "=== RESULT ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "FIX-369 DOM PROOF GREEN" || echo "FINDINGS PRESENT"
