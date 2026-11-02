#!/usr/bin/env bash
# cycle412-domproof.sh — update cycle 412 (فرمول ۳): the match-page venue/
# city/referee wiring + map batch. The cycle-412 probe first measured the
# whole never-swept API inventory (h2h, fixtures, titles, totw, team-news,
# team-difficulty — 1310 rows, ZERO new name leaks beyond the 7 deliberate
# honest-raw holds) and then a supplementary field-shape scan found the REAL
# class the name-row scanners could not see: the match-page «ورزشگاه» and
# «داور» info rows render the infoBox Stadium.name / city / Referee.text RAW
# since cycle-115 — while the 391 maps (VENUE_FA/VENUE_CITY_FA) existed for
# the team-venue direction only. Fix = (1) the wiring: info gains additive
# stadiumFa/cityFa/refereeFa (the 391 heal shape, match-page direction; a
# new REFEREE_FA map + refereeFa() — the 115 "honest English" comment was
# pre-wave); (2) the batch: VENUE_FA +18, VENUE_CITY_FA +18, REFEREE_FA +15
# (byte-exact upstream keys, exact-case — venueFa does NOT lowercase);
# 2 stadiums + 1 city + 2 referees stay honest raw (uncertain).
#   A   the flips LIVE in DOM at 390x844 after REAL «اطلاعات» tab clicks
#       (the 407 lesson) + the honest-raw referee stays Latin on the SAME page.
#   B   the fix contracts (raw byte-exact beside the fa twins, batch sizes,
#       diff scope = three src/ files, no cache bump — the 25s self-heal,
#       the 391 team-venue consumer untouched, the 411 holds ride).
#   C   the standing holds (398/399/400/405/406/407/409/410/411) + anchors +
#       the hygiene three-pack on TEN pages.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
info_tab_click() {
  agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='اطلاعات'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
}

echo "================ A: the 412 flips LIVE in DOM (390x844, real «اطلاعات» clicks) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
# A1-A3: /match/5795503 (Newcastle) — stadium/city/referee all flip
agent-browser open "$BASE/match/5795503" >/dev/null 2>&1
sleep 5
info_tab_click
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ورزشگاه سنت جیمز پارک')>=0?1:0)+'|'+(t.indexOf('نیوکاسل')>=0?1:0)+'|'+(t.indexOf('جان بروکس')>=0?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 <<< "$R"
ck "A1 FLIP: «ورزشگاه سنت جیمز پارک» rides the «ورزشگاه» row (5795503)" "$A1"
ck "A2 FLIP: city «نیوکاسل» rides (5795503)" "$A2"
ck "A3 FLIP: referee «جان بروکس» rides the «داور» row (5795503)" "$A3"
# A4-A5: /match/5749731 (Atalanta) — the city the supplementary scan found
agent-browser open "$BASE/match/5749731" >/dev/null 2>&1
sleep 5
info_tab_click
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('برگامو')>=0?1:0)+'|'+(t.indexOf('والریو چرزینی')>=0?1:0)" | tr -d '"')
IFS='|' read -r A4 A5 <<< "$R"
ck "A4 FLIP: city «برگامو» rides (5749731, the scan witness)" "$A4"
ck "A5 FLIP: referee «والریو چرزینی» rides (5749731)" "$A5"
# A6-A8: /match/5904789 — the mapped pair rides AND the honest-raw referee
# (Fatih Tokail) stays Latin on the SAME page (no invention)
agent-browser open "$BASE/match/5904789" >/dev/null 2>&1
sleep 5
info_tab_click
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ورزشگاه اریامان')>=0?1:0)+'|'+(t.indexOf('آنکارا')>=0?1:0)+'|'+(t.indexOf('Fatih Tokail')>=0?1:0)" | tr -d '"')
IFS='|' read -r A6 A7 A8 <<< "$R"
ck "A6 FLIP: «ورزشگاه اریامان» rides (5904789)" "$A6"
ck "A7 FLIP: city «آنکارا» rides (5904789)" "$A7"
ck "A8 HONEST: referee «Fatih Tokail» stays byte-raw on the SAME page" "$A8"

echo "================ B: the fix contracts ================"
# B1: the raw byte contract survives beside the fa twins (the dual contract)
R=$(api "/api/match/5795503" | python3 -c "
import json,sys
i=(json.load(sys.stdin).get('info') or {})
ok_raw = i.get('stadium')==\"St. James' Park\" and i.get('referee')=='John Brooks'
ok_fa = i.get('stadiumFa')=='ورزشگاه سنت جیمز پارک' and i.get('cityFa')=='نیوکاسل' and i.get('refereeFa')=='جان بروکس'
print('1' if ok_raw and ok_fa else '0')")
ck "B1 dual contract: raw byte-exact + fa twins beside (5795503)" "$R"
# B2: the honest-raw referee contract at payload level
R=$(api "/api/match/5904789" | python3 -c "
import json,sys
i=(json.load(sys.stdin).get('info') or {})
print('1' if i.get('referee')=='Fatih Tokail' and 'refereeFa' not in i and i.get('stadiumFa')=='ورزشگاه اریامان' else '0')")
ck "B2 honest-raw: refereeFa absent + raw rides; stadiumFa still flips" "$R"
# B3: batch sizes
R=$(sed -n '/— cycle-412: the match-page venue row was wired/,/^};/p' src/lib/fotmob.ts | grep -c '": "')
ck "B3a VENUE_FA batch = 18 entries" "$([ "$R" = "18" ] && echo 1 || echo 0)"
R=$(sed -n '/— cycle-412: the match-page city row wiring batch/,/^};/p' src/lib/fotmob.ts | grep -c '": "')
ck "B3b VENUE_CITY_FA batch = 18 entries" "$([ "$R" = "18" ] && echo 1 || echo 0)"
R=$(sed -n '/const REFEREE_FA/,/^};/p' src/lib/fotmob.ts | grep -c '": "')
ck "B3c REFEREE_FA = 15 entries" "$([ "$R" = "15" ] && echo 1 || echo 0)"
# B4: diff scope — exactly three src/ files
N=$(git diff --name-only 2>/dev/null | grep "^src/" | tr '\n' ' ')
C=$(git diff --name-only 2>/dev/null | grep -c "^src/")
ck "B4 diff scope = three src/ files (fotmob.ts + route + match-detail): $N" "$([ "$C" = "3" ] && echo 1 || echo 0)"
# B5: the no-bump proof — the matchDetails 25s self-heal rule untouched
R=$(grep -c "25_000\|25,000" src/app/api/match/\[id\]/route.ts src/lib/fotmob.ts | awk -F: '{s+=$2} END{print s}')
ck "B5 the 25s matchDetails self-heal constant present (no bump needed — the 117 rule)" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
# B6: the 391 consumer untouched — team-venue still heals
R=$(api "/api/team-venue/8650" | grep -c "nameFa\|cityFa")
ck "B6 the 391 hold: /api/team-venue/8650 still carries nameFa/cityFa" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
# B7: the 411 holds ride (payload level)
R=$(api "/api/team-squad/8668" | grep -c "دیوید مویس")
ck "B7a the 411 hold: squad coach «دیوید مویس» still rides (8668)" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
R=$(api "/api/team-last-lineup/8668" | grep -c "کیرنان دیوزبری-هال")
ck "B7b the 411 hold: last-lineup «کیرنان دیوزبری-هال» still rides" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"

echo "================ C: standing holds + anchors + hygiene ================"
agent-browser open "$BASE/player/319784" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('آلیسون بکر')>=0?1:0)" | tr -d '"')
ck "C1 /player/319784 h1 «آلیسون بکر» (the 398 hold)" "$R"
agent-browser open "$BASE/coach/24011" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('جام حذفی انگلیس')>=0?1:0)" | tr -d '"')
ck "C2 /coach/24011 honours «جام حذفی انگلیس» (the 400 hold)" "$R"
agent-browser open "$BASE/team/8650" >/dev/null 2>&1; sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)+'|'+(t.indexOf('ابراهیما کوناته')>=0?1:0)" | tr -d '"')
IFS='|' read -r C3 C4 C5 <<< "$R"
ck "C3 /team/8650 bench history «آرنه اسلوت» (the 399 hold)" "$C3"
ck "C4 no bench raw regression (Sampaoli absent on 8650)" "$C4"
ck "C5 the 405 hold: transfers «ابراهیما کوناته» still rides" "$C5"
agent-browser open "$BASE/topscorers/pl" >/dev/null 2>&1; sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('گرانیت ژاکا')>=0?1:0)+'|'+(t.indexOf('ساندرلند')>=0?1:0)" | tr -d '"')
IFS='|' read -r C6 C7 <<< "$R"
ck "C6 /topscorers/pl per-90 flip «گرانیت ژاکا» (the 407 hold)" "$C6"
ck "C7 per-90 team subtitle «ساندرلند» rides (the 407 hold)" "$C7"
agent-browser open "$BASE/league/ucl" >/dev/null 2>&1; sleep 4
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آمار فصل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('پاری سن‌ژرمن')>=0?1:0)" | tr -d '"')
ck "C8 /league/ucl boards flip «پاری سن‌ژرمن» after real click (the 406 hold)" "$R"
agent-browser open "$BASE/search?q=%DA%A9%D9%84%D9%88%D9%BE" >/dev/null 2>&1; sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('یورگن کلوپ')>=0?1:0)+'|'+(t.indexOf('Jürgen Klopp')>=0?1:0)" | tr -d '"')
IFS='|' read -r C9 C10 <<< "$R"
ck "C9 the 409 hold: search «یورگن کلوپ» title rides" "$C9"
ck "C10 the 409 hold: raw «Jürgen Klopp» subtitle rides" "$C10"
agent-browser open "$BASE/match/5071483" >/dev/null 2>&1; sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('کازمیرو')>=0?1:0)" | tr -d '"')
ck "C11 the 410 hold: «کازمیرو» rides after the real «ترکیب» click" "$R"
agent-browser open "$BASE/team/8668" >/dev/null 2>&1; sleep 7
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-last-lineup]')||{innerText:''}).innerText; (s.indexOf('کیرنان دیوزبری-هال')>=0?1:0)" | tr -d '"')
ck "C12 the 411 hold: «کیرنان دیوزبری-هال» rides the last-lineup section" "$R"
agent-browser open "$BASE/leagues" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)" | tr -d '"')
ck "C13 /leagues anchor «لیگ‌ها»" "$R"

for PG in "" "match/5795503" "match/5749731" "match/5904789" "team/8668" "team/8650" "topscorers/pl" "league/pl" "player/319784" "news"; do
  agent-browser open "$BASE/$PG" >/dev/null 2>&1
  sleep 3
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "H /$PG page-errors clean (empty or 0)" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
  ck "H /$PG console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "H /$PG scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"
done

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
