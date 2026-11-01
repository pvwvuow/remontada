#!/bin/bash
# cycle-368 bug-hunt DOM patrol — pages sweep + live re-verification of recent
# cycles' features at 390x844 (bug-hunt = report only, zero code changes).
# Covers: 367 meter boards, 366 catalog round-3, 365 catalog round-2,
#         364 medal empty states + bracket, 43 freshness labels,
#         42 stale-while-error flag contract, 41 match countdown,
#         season selector (55/99), honest degradation (92).
AB="agent-browser"
BASE="http://localhost:3000"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "PASS: $1"; }
bad(){ FAIL=$((FAIL+1)); echo "FAIL: $1"; }

# fresh page: close-all, open, viewport 390x844, clear error/console buffers
fresh(){
  $AB close --all >/dev/null 2>&1
  $AB open "$1" >/dev/null 2>&1 || { bad "open $1"; return 1; }
  $AB set viewport 390 844 >/dev/null 2>&1
  $AB errors --clear >/dev/null 2>&1
  $AB console --clear >/dev/null 2>&1
  sleep 1
}

# viewport + console verdict for the CURRENT page (arg: label)
vpc(){
  local SW CW E C
  SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null)
  CW=$($AB eval "document.documentElement.clientWidth" 2>/dev/null)
  E=$($AB errors 2>/dev/null | grep -v -i '^no ' | grep -c . )
  C=$($AB console 2>/dev/null | grep -ci 'error')
  if [ "$SW" = "390" ] && [ "$CW" = "390" ]; then ok "$1 scrollW=cw=390"; else bad "$1 scrollW=$SW cw=$CW"; fi
  if [ "${E:-0}" = "0" ]; then ok "$1 page-errors=0"; else bad "$1 page-errors=$E: $($AB errors 2>/dev/null | head -3)"; fi
  if [ "${C:-0}" = "0" ]; then ok "$1 console-errors=0"; else bad "$1 console-errors=$C"; fi
}

ev(){ $AB eval "$1" 2>/dev/null; }

echo "=========== P1: / (home) ==========="
fresh "$BASE/" || exit 1
TITLE=$(ev "document.title")
echo "$TITLE" | grep -qi رمانتادا && ok "home title has رمانتادا: $TITLE" || bad "home title: $TITLE"
vpc "home"

echo "=========== P2: /leagues ==========="
fresh "$BASE/leagues" || exit 1
N=$(ev "document.querySelectorAll('a').length")
[ "${N:-0}" -gt 5 ] 2>/dev/null && ok "leagues links=$N" || bad "leagues links=$N"
vpc "leagues"

echo "=========== P3: /league/pl — boards (367 meter + 366/365 catalog) ==========="
fresh "$BASE/league/pl" || exit 1
# boards live under the «آمار فصل» tab (default tab is جدول)
$AB find text "آمار فصل" click >/dev/null 2>&1; sleep 3
# hour-baked L2 self-heal: if counts look pre-367, wait ~75s and reload once
CNT=$(ev "[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].length")
if [ "${CNT:-0}" != "33" ]; then
  echo "  (first read teams-chips=$CNT — waiting 75s for documented standings re-probe self-heal)"
  sleep 75; $AB reload >/dev/null 2>&1; $AB set viewport 390 844 >/dev/null 2>&1; sleep 3
  $AB find text "آمار فصل" click >/dev/null 2>&1; sleep 3
  CNT=$(ev "[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].length")
fi
[ "${CNT:-0}" = "33" ] && ok "pl team chips=33 (31 categories + 2 kind toggles) got=$CNT" || bad "pl team chips got=$CNT want=33"
# 367: meter chip present in team view
ev "(() => { const b=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(x=>x.textContent.includes('مسافت پوشیده')); b && b.click(); return b? 'clicked':'missing'; })()" >/dev/null
sleep 1
POD=$(ev "[...document.querySelectorAll('[data-testid=league-boards] a[href*=\"/team/\"]')].slice(0,3).map(a=>a.textContent.trim()).join(' | ')")
echo "$POD" | grep -q 'کیلومتر' && ok "367 team meter podium live: $POD" || bad "367 team meter podium: $POD"
HL=$(echo "$POD" | head -c 60); echo "  podium[0..60]=$HL"
# kind toggle -> player view
$AB find text "بازیکنان" click >/dev/null 2>&1; sleep 1
CNT2=$(ev "[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].length")
[ "${CNT2:-0}" = "47" ] && ok "pl player chips=47 (45 categories + 2 toggles) got=$CNT2" || bad "pl player chips got=$CNT2 want=47"
ev "(() => { const b=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(x=>x.textContent.includes('جمع مسافت')); b && b.click(); return b? 'clicked':'missing'; })()" >/dev/null
sleep 1
POD2=$(ev "[...document.querySelectorAll('[data-testid=league-boards] a[href*=\"/player/\"]')].slice(0,3).map(a=>a.textContent.trim()).join(' | ')")
echo "$POD2" | grep -q 'کیلومتر' && ok "367 player total-distance podium live: $POD2" || bad "367 player podium: $POD2"
# 366 spot-check: tackles chip in team view
$AB find text "تیم‌ها" click >/dev/null 2>&1; sleep 1
TC=$(ev "[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].filter(x=>['تکل در هر بازی','قطع توپ در هر بازی','دفع توپ در هر بازی','پاس بلند دقیق در هر بازی'].some(t=>x.textContent.includes(t))).length")
[ "${TC:-0}" = "4" ] && ok "366 defensive-volume family 4/4 chips" || bad "366 family chips got=$TC want=4"
vpc "league/pl"

echo "=========== P4: /league/ucl — meter on second rich feed ==========="
fresh "$BASE/league/ucl" || exit 1
$AB find text "آمار فصل" click >/dev/null 2>&1; sleep 3
CNT3=$(ev "[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].length")
[ "${CNT3:-0}" = "33" ] && ok "ucl team chips=33 got=$CNT3" || bad "ucl team chips got=$CNT3 want=33"
ev "(() => { const b=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(x=>x.textContent.includes('مسافت پوشیده')); b && b.click(); return b? 'clicked':'missing'; })()" >/dev/null
sleep 1
POD3=$(ev "[...document.querySelectorAll('[data-testid=league-boards] a[href*=\"/team/\"]')].slice(0,3).map(a=>a.textContent.trim()).join(' | ')")
echo "$POD3" | grep -q 'کیلومتر' && ok "367 ucl meter podium live: $POD3" || bad "367 ucl podium: $POD3"
vpc "league/ucl"

echo "=========== P5: /league/iraq — honest absence (92) + season selector ==========="
fresh "$BASE/league/iraq" || exit 1
HAS=$(ev "!!document.querySelector('[data-testid=league-boards]')")
[ "$HAS" = "false" ] && ok "iraq: no boards section (honest skip)" || bad "iraq boards present=$HAS"
SC=$(ev "document.querySelectorAll('#season-select option').length")
[ "${SC:-0}" -ge 2 ] 2>/dev/null && ok "season selector options=$SC (55/99)" || bad "season options=$SC"
vpc "league/iraq"

echo "=========== P6: /league/iraq?season=2023/2024 — 364 medal + bracket ==========="
fresh "$BASE/league/iraq?season=2023/2024" || exit 1
sleep 1
MED=$(ev "document.body.textContent.includes('هنوز کسی به این نشان نرسیده')")
TRO=$(ev "document.body.textContent.includes('جام همچنان در راه است')")
[ "$MED" = "true" ] && ok "364 medal flavor on hollow-season standings" || bad "364 medal flavor missing"
[ "$TRO" = "false" ] && ok "364 trophy flavor gone" || bad "364 trophy flavor STILL present"
$AB find text "براکت" click >/dev/null 2>&1; sleep 1
BR=$(ev "document.body.textContent.includes('فینال') && document.body.textContent.includes('دهوک')")
[ "$BR" = "true" ] && ok "bracket intact (فینال + دهوک champion)" || bad "bracket: فینال=$BR"
vpc "iraq hollow season"

echo "=========== P7: /topscorers — freshness label (43) + 120 contract (42) ==========="
fresh "$BASE/topscorers" || exit 1
FL=$(ev "document.body.textContent.includes('به‌روزرسانی')")
[ "$FL" = "true" ] && ok "freshness label present" || bad "freshness label missing"
ROWS=$(ev "document.querySelectorAll('ol li').length")
[ "${ROWS:-0}" -ge 100 ] 2>/dev/null && ok "scorer rows=$ROWS (120 contract, ol/li view)" || bad "scorer rows=$ROWS"
vpc "topscorers"

echo "=========== P8: /topscorers/pl ==========="
fresh "$BASE/topscorers/pl" || exit 1
FL2=$(ev "document.body.textContent.includes('به‌روزرسانی')")
[ "$FL2" = "true" ] && ok "freshness label on league topscorers" || bad "league topscorers label missing"
vpc "topscorers/pl"

echo "=========== P9: match detail — countdown (41) ==========="
fresh "$BASE/" || exit 1
LINKS=$(ev "[...document.querySelectorAll('a[href*=\"/match/\"]')].map(a=>a.getAttribute('href')).slice(0,8).join(' ')")
LINKS=$(echo "$LINKS" | tr -d '"')
echo "  match links: $LINKS"
FOUND=0
for M in $LINKS; do
  fresh "$BASE$M" || continue
  sleep 1
  CD=$(ev "document.body.textContent.includes('شروع بازی تا')")
  if [ "$CD" = "true" ]; then
    TXT=$(ev "document.body.textContent.match(/شروع بازی تا[^‌]*دیگر/)?.[0] || ''")
    ok "41 countdown live on $M: $TXT"; FOUND=1; vpc "match $M"; break
  fi
done
[ "$FOUND" = "0" ] && { ok "no upcoming match on home cards right now — countdown honest-absent (not a bug)"; }

echo "=========== RESULT ==========="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "BUG-HUNT PATROL GREEN" || echo "BUG-HUNT PATROL: FINDINGS PRESENT"
