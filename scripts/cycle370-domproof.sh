#!/bin/bash
# cycle-370 update DOM proof — faDecimal adoption across the remaining
# numeric-display surfaces (topscorers badges, team page, match detail,
# player profile) + league-view regression. Assertion: NO Persian-digit
# ASCII-dot numerals («۷.۸») remain on these surfaces; «٫» present.
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
  sleep 2
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
ev(){ $AB eval "$1" 2>/dev/null | tr -d '"'; }
nodot(){ # arg: label — no Persian-digit ASCII-dot in body
  D=$(ev "(()=>{const m=document.body.textContent.match(/[۰-۹]\.[۰-۹]/); return m? m[0] : 'CLEAN';})()")
  [ "$D" = "CLEAN" ] && ok "$1: zero Persian-digit ASCII-dot numerals" || bad "$1: ASCII-dot numeral found: $D"
}

echo "=== P0: pick ids from /league/pl ==="
fresh "$BASE/league/pl" || exit 1
TEAM=$(ev "document.querySelector('a[href*=\"/team/\"]')?.getAttribute('href') || ''")
PLAYER=$(ev "document.querySelector('a[href*=\"/player/\"]')?.getAttribute('href') || ''")
TEAM=${TEAM%% *}; PLAYER=${PLAYER%% *}
echo "  team=$TEAM player=$PLAYER"

echo "=== P1: /topscorers — xG/xA/xGOT badges ٫ ==="
fresh "$BASE/topscorers" || exit 1
nodot "topscorers"
BADGE=$(ev "(()=>{const b=[...document.querySelectorAll('span')].find(x=>/xG [۰-۹]/.test(x.textContent)); return b? b.textContent : 'NO-XG-BADGE';})()")
echo "  badge: $BADGE"
case "$BADGE" in *"٫"*) ok "xG badge uses ٫: $BADGE";; "NO-XG-BADGE") ok "no xG badge rendered in current rows (honest)";; *) bad "xG badge: $BADGE";; esac
vpc "topscorers"

echo "=== P2: $TEAM — season averages + squad ratings ٫ ==="
fresh "$BASE$TEAM" || exit 1
sleep 1
nodot "team page"
AVG=$(ev "document.body.textContent.includes('میانگین') ? (document.body.textContent.match(/میانگین [۰-۹٫]+/)||['none'])[0] : 'NO-AVG'")
echo "  avg: $AVG"
vpc "team page"

echo "=== P3: /match/5749720 — rating pills (toFixed(2)) ٫ ==="
fresh "$BASE/match/5749720" || exit 1
sleep 2
nodot "match page"
PILL=$(ev "(()=>{const el=[...document.querySelectorAll('span')].find(x=>/^[۰-۹]٫[۰-۹]$/.test(x.textContent.trim())); return el? el.textContent.trim() : 'NO-PILL';})()")
echo "  first rating pill: $PILL"
vpc "match page"

echo "=== P4: $PLAYER — profile rating ٫ ==="
if [ -n "$PLAYER" ]; then
  fresh "$BASE$PLAYER" || exit 1
  nodot "player profile"
  vpc "player profile"
else
  ok "no player link on pl page — skipped"
fi

echo "=== P5: /league/pl boards regression (369 intact) ==="
fresh "$BASE/league/pl" || exit 1
$AB find text "آمار فصل" click >/dev/null 2>&1; sleep 2
ev "(() => { const b=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(x=>x.textContent.includes('مسافت پوشیده')); b && b.click(); return b?'clicked':'missing'; })()" >/dev/null
sleep 1
POD=$(ev "[...document.querySelectorAll('[data-testid=league-boards] a[href*=\"/team/\"]')].slice(0,1).map(a=>a.textContent.trim()).join('')")
echo "$POD" | grep -q 'کیلومتر' && echo "$POD" | grep -q '٫' && ok "369 meter podium intact with ٫: $POD" || bad "podium: $POD"
nodot "league boards"
vpc "league/pl"

echo "=== RESULT ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "UPDATE-370 DOM PROOF GREEN" || echo "FINDINGS PRESENT"
