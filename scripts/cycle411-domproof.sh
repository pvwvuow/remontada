#!/usr/bin/env bash
# cycle411-domproof.sh — update cycle 411 (فرمول ۲): the residual map-lag
# batch. The cycle-410 wide probe swept the match frontier (146 Class-B
# names → 130 fixed) but never read two surfaces the cycle-411 live probe
# (repo-external scripts/cycle411_leakscan.py, UA Chrome/124, ~2200 rows)
# measured: /api/team-last-lineup («آخرین ترکیب», the XI that actually
# started) and the /api/team-squad coach chip — plus the match-frontier
# residue. 44 unique fa-less names measured; fix = 34 curated PLAYER_NAME_FA
# entries + 3 COACH_SEED benches (Moyes/Allegri/Blessin, ids probed live off
# /api/team-squad — the 397 method); 7 genuinely-uncertain names stay honest
# raw (cycle-96). Map-only, additive, zero UI/API-shape change, no cache
# bump (last-lineup/squad transform per request from teamDataRaw:v2 — the
# 404 precedent; match route applies playerFa at normalize time — the 410).
#   A   the flips LIVE in DOM at 390x844 (the lazy team sections need only a
#       wait; the match «غایبان» block needs a REAL «ترکیب» tab click — the
#       407 lesson) + the honest-raw stays Latin on the SAME pages.
#   B   the fix contracts (API byte flips both directions, batch sizes, diff
#       scope = two src/ files, no cache bump, the 410/407 holds ride).
#   C   the standing holds (398/399/400/405/406/407/409) + anchors + the
#       hygiene three-pack on TEN pages including the fixed surfaces.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the 411 flips LIVE in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
# A1-A4: /team/8668 (Everton) — the lazy «آخرین ترکیب» section + the squad
# coach chip («دیوید مویس», the 259 fa-first path)
agent-browser open "$BASE/team/8668" >/dev/null 2>&1
sleep 7
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-last-lineup]')||{innerText:''}).innerText; var t=document.body.innerText; (s.indexOf('آخرین ترکیب')>=0||s.length>0?1:0)+'|'+(s.indexOf('کیرنان دیوزبری-هال')>=0?1:0)+'|'+(s.indexOf('ویتالی میکولنکو')>=0?1:0)+'|'+(t.indexOf('دیوید مویس')>=0?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 A4 <<< "$R"
ck "A1 the «آخرین ترکیب» section renders on /team/8668" "$A1"
ck "A2 FLIP: «کیرنان دیوزبری-هال» rides the last-lineup section" "$A2"
ck "A3 FLIP: «ویتالی میکولنکو» rides the last-lineup section" "$A3"
ck "A4 FLIP: squad coach chip «دیوید مویس» rides (the 259 fa-first path)" "$A4"
# A5-A7: /team/9875 (Napoli) — Allegri chip + the two Napoli witnesses
agent-browser open "$BASE/team/9875" >/dev/null 2>&1
sleep 7
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ماسیمیلیانو آلگری')>=0?1:0)+'|'+(t.indexOf('لوکا ماریانوچی')>=0?1:0)+'|'+(t.indexOf('رافا مارین')>=0?1:0)" | tr -d '"')
IFS='|' read -r A5 A6 A7 <<< "$R"
ck "A5 FLIP: coach chip «ماسیمیلیانو آلگری» rides (9875)" "$A5"
ck "A6 FLIP: «لوکا ماریانوچی» rides the last-lineup section (9875)" "$A6"
ck "A7 FLIP: «رافا مارین» rides the last-lineup section (9875)" "$A7"
# A8-A10: /team/9788 (Gladbach) — Blessin chip + Neuhaus + the honest-raw hold
agent-browser open "$BASE/team/9788" >/dev/null 2>&1
sleep 7
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-last-lineup]')||{innerText:''}).innerText; var t=document.body.innerText; (t.indexOf('الکساندر بلسین')>=0?1:0)+'|'+(s.indexOf('فلوریان نوهاوس')>=0?1:0)+'|'+(s.indexOf('Zento Uno')>=0?1:0)+'|'+(s.indexOf('روبین هاک')>=0?1:0)" | tr -d '"')
IFS='|' read -r A8 A9 A10 A11 <<< "$R"
ck "A8 FLIP: coach chip «الکساندر بلسین» rides (9788)" "$A8"
ck "A9 FLIP: «فلوریان نوهاوس» rides the last-lineup section (9788)" "$A9"
ck "A10 HONEST: «Zento Uno» stays byte-raw on the SAME section (no invention)" "$A10"
ck "A11 FLIP: «روبین هاک» rides the last-lineup section (9788)" "$A11"
# A12-A15: /match/5749731 — the «غایبان» chips flip after a REAL «ترکیب»
# tab click (the 407 lesson); the Raspadori witness is asserted via its
# pure-Persian surname substring (script-safety)
agent-browser open "$BASE/match/5749731" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('غایبان')>=0?1:0)+'|'+(t.indexOf('فرانک کسیه')>=0?1:0)+'|'+(t.indexOf('راسپادوری')>=0?1:0)+'|'+(t.indexOf('کولاشیناتس')>=0?1:0)+'|'+(t.indexOf('اسکامااکا')>=0?1:0)" | tr -d '"')
IFS='|' read -r A12 A13 A14 A15 A16 <<< "$R"
ck "A12 the «غایبان» block renders after the real «ترکیب» click (5749731)" "$A12"
ck "A13 FLIP: «فرانک کسیه» rides the «غایبان»/events rows (5749731)" "$A13"
ck "A14 FLIP: «راسپادوری» rides (5749731)" "$A14"
ck "A15 FLIP: «کولاشیناتس» rides (5749731)" "$A15"
ck "A16 FLIP: «اسکامااکا» rides (5749731)" "$A16"

echo "================ B: the fix contracts ================"
# B1-B3: the squad coach dual contract — the raw name stays byte-exact AND
# the fa twin rides beside it (the 259 shape: {name, fa})
for pair in "8668|David Moyes|دیوید مویس" "9875|Massimiliano Allegri|ماسیمیلیانو آلگری" "9788|Alexander Blessin|الکساندر بلسین"; do
  TID=$(echo "$pair" | cut -d'|' -f1); EN=$(echo "$pair" | cut -d'|' -f2); FA=$(echo "$pair" | cut -d'|' -f3)
  R=$(api "/api/team-squad/$TID" | python3 -c "
import json,sys
c=(json.load(sys.stdin).get('squad') or {}).get('coach') or {}
en, fa = '''$EN''', '''$FA'''
print('1' if c.get('name')==en and c.get('fa')==fa else '0')")
  ck "B(T$TID) squad coach: raw «$EN» byte-exact + fa «$FA» rides" "$R"
done
# B4: the last-lineup fa-first contract — name IS the fa attempt (the 120
# wire), so the mapped witness name == the Persian value and the raw English
# spelling no longer appears as the name
R=$(api "/api/team-last-lineup/8668" | python3 -c "
import json,sys
st=(json.load(sys.stdin).get('lastLineup') or {}).get('starters') or []
names=[s.get('name') for s in st]
want=['کیرنان دیوزبری-هال','ویتالی میکولنکو','جیمز گارنر','جیک اوبراین','هریسون آرمسترانگ','مرلین رول','تایریک جورج']
print('1' if all(w in names for w in want) and 'Kiernan Dewsbury-Hall' not in names else '0')")
ck "B4 last-lineup/8668: all 7 witnesses fa-first, raw English gone" "$R"
# B5: the honest-raw contract at payload level
R=$(api "/api/team-last-lineup/9788" | grep -c "Zento Uno")
ck "B5a honest-raw: «Zento Uno» byte-raw in the last-lineup payload" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
R=$(api "/api/match/5904789" | grep -c "Fatih Aksoy")
ck "B5b honest-raw: «Fatih Aksoy» byte-raw in the match payload" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
# B6: batch sizes — 34 new player entries + 3 new coach rows
R=$(sed -n '/— the match-frontier residue —/,/^};/p' src/lib/player-names-fa.ts | grep -c '": "')
ck "B6a PLAYER_NAME_FA batch = 34 entries" "$([ "$R" = "34" ] && echo 1 || echo 0)"
R=$(sed -n '/— cycle-411: the squad-coach rows/,/^];/p' src/lib/fotmob.ts | grep -c '{ id:')
ck "B6b COACH_SEED batch = 3 benches" "$([ "$R" = "3" ] && echo 1 || echo 0)"
# B7: diff scope — exactly two src/ files in the working tree
R=$(git diff --name-only | grep -c "^src/" 2>/dev/null || echo 0)
N=$(git diff --name-only 2>/dev/null | grep "^src/" | tr '\n' ' ')
ck "B7 diff scope = two src/ files (fotmob.ts + player-names-fa.ts): $N" "$([ "$R" = "2" ] && echo 1 || echo 0)"
# B8: the no-cache-bump proof — the derivation caches keep their versions
# (teamDataRaw:v2 feeds last-lineup/squad per request — the 404 precedent;
# standings stays v41 — the 406 bump; fullGoals v4 — the 405 bump)
R=$(grep -c "teamDataRaw:v2" src/lib/fotmob.ts)
ck "B8a teamDataRaw stays :v2 (no bump — per-request transform)" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
R=$(grep -cE "STANDINGS_VERSION[^=]*= ?\"?v41|standings:v41" src/lib/fotmob.ts)
ck "B8b standings cache stays v41 (the 406 bump, untouched)" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
# B9: the 410 holds ride at payload level (the superstar witnesses)
R=$(api "/api/match/5071483" | grep -c "کازمیرو")
ck "B9a the 410 hold: «کازمیرو» still rides (5071483)" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
R=$(api "/api/match/6050088" | grep -c "کینگزلی کومان")
ck "B9b the 410 hold: «کینگزلی کومان» still rides (6050088)" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"
# B10: the 407 hold rides (per-90 freshener names still present)
R=$(api "/api/topscorers/pl" | grep -c "گرانیت ژاکا")
ck "B10 the 407 hold: «گرانیت ژاکا» still rides /api/topscorers/pl" "$([ "$R" -ge 1 ] && echo 1 || echo 0)"

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
ck "C5 the 405 hold in DOM: transfers «ابراهیما کوناته» still rides" "$C5"
agent-browser open "$BASE/topscorers/pl" >/dev/null 2>&1; sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('گرانیت ژاکا')>=0?1:0)+'|'+(t.indexOf('ساندرلند')>=0?1:0)" | tr -d '"')
IFS='|' read -r C6 C7 <<< "$R"
ck "C6 /topscorers/pl per-90 flip «گرانیت ژاکا» (the 407 hold)" "$C6"
ck "C7 per-90 team subtitle «ساندرلند» rides (the 407 hold)" "$C7"
agent-browser open "$BASE/league/ucl" >/dev/null 2>&1; sleep 4
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آمار فصل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('پاری سن‌ژرمن')>=0?1:0)+'|'+(t.indexOf('استون‌ویلا')>=0?1:0)" | tr -d '"')
IFS='|' read -r C8 C9 <<< "$R"
ck "C8 /league/ucl boards flip «پاری سن‌ژرمن» after real «آمار فصل» click (the 406 hold)" "$C8"
ck "C9 boards flip «استون‌ویلا» rides (the 406 hold)" "$C9"
agent-browser open "$BASE/search?q=%DA%A9%D9%84%D9%88%D9%BE" >/dev/null 2>&1; sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('یورگن کلوپ')>=0?1:0)+'|'+(t.indexOf('Jürgen Klopp')>=0?1:0)" | tr -d '"')
IFS='|' read -r C10 C11 <<< "$R"
ck "C10 the 409 hold: search «یورگن کلوپ» title rides" "$C10"
ck "C11 the 409 hold: raw «Jürgen Klopp» subtitle rides" "$C11"
agent-browser open "$BASE/leagues" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)" | tr -d '"')
ck "C12 /leagues anchor «لیگ‌ها»" "$R"

for PG in "" "team/8668" "team/9875" "team/9788" "match/5749731" "topscorers/pl" "league/pl" "player/319784" "coach/24011" "news"; do
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
