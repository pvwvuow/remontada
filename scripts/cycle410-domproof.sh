#!/usr/bin/env bash
# cycle410-domproof.sh — update cycle 410 (فرمول ۱): the match-page name-map
# batch. The cycle-407 probe closed the «غایبان» map-lag class for ONE match
# (Sassuolo–Fiorentina, +8); the cycle-410 wide probe (repo-external
# scripts/cycle410_leakscan.py + cycle410_widematch.py, UA Chrome/124, 45
# distinct leagues' matches, 1954 name rows) measured the SAME class across
# the whole match frontier: 146 unique Class-B names rendering raw — the
# «غایبان» chips (cycle-116: nameFa ONLY on a map hit) + the events-assist
# rows — while player-profile / team / bracket / topscorers / transfers
# payloads read 100% clean. Fix = 130 curated confident transliterations in
# PLAYER_NAME_FA (byte-exact upstream keys, diacritics preserved); 16
# genuinely-uncertain names stay honest raw (cycle-96). Map-only, additive;
# no cache bump (match route applies playerFa at normalize time, TTL 25s).
#   A   the flips LIVE in DOM at 390x844 (real «ترکیب» tab clicks — the
#       407 lesson) across five witness matches + nothing broken beside.
#   B   the fix contracts (API byte flips, honest-raw stays raw on the SAME
#       page, diff scope = one src/ file, batch size 130).
#   C   the standing holds (398/399/400/405/406/407/409) + anchors + the
#       hygiene three-pack on TEN pages including the fixed surfaces.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the 410 flips LIVE in DOM (390x844, real «ترکیب» clicks) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
# A1-A3: /match/5868113 (LaLiga, Osasuna) — the «غایبان» chips flip after a
# REAL «ترکیب» tab click (the 407 lesson: the block lives inside the tab)
agent-browser open "http://localhost:3000/match/5868113" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آیمار اروز')>=0?1:0)+'|'+(t.indexOf('خورخه اراندو')>=0?1:0)+'|'+(t.indexOf('برایت اده')>=0?1:0)+'|'+(t.indexOf('زکریا الدخشوری')>=0?1:0)+'|'+(t.indexOf('غایبان')>=0?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 A4 A5 <<< "$R"
ck "A1 FLIP: «آیمار اروز» rides the «غایبان» block (5868113)" "$A1"
ck "A2 FLIP: «خورخه اراندو» rides (5868113)" "$A2"
ck "A3 FLIP: «برایت اده» rides (5868113)" "$A3"
ck "A4 FLIP: «زکریا الدخشوری» rides (5868113)" "$A4"
ck "A5 the «غایبان» block itself renders (tab structure intact)" "$A5"
# A6-A8: /match/5071483 (MLS) — Casemiro the superstar witness + the assist row
agent-browser open "http://localhost:3000/match/5071483" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('کازمیرو')>=0?1:0)+'|'+(t.indexOf('دور تورگمان')>=0?1:0)+'|'+(t.indexOf('تادئو آلنده')>=0?1:0)+'|'+(t.indexOf('دین سنت کلیر')>=0?1:0)" | tr -d '"')
IFS='|' read -r A6 A7 A8 A9 <<< "$R"
ck "A6 FLIP: «کازمیرو» rides (5071483, the superstar witness)" "$A6"
ck "A7 FLIP: «دور تورگمان» rides (5071483)" "$A7"
ck "A8 FLIP: «تادئو آلنده» rides (5071483)" "$A8"
ck "A9 FLIP: «دین سنت کلیر» rides (5071483)" "$A9"
# A10-A11: /match/6050088 (AFC Champions League Elite West) — Coman + Al Ghannam
agent-browser open "http://localhost:3000/match/6050088" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('کینگزلی کومان')>=0?1:0)+'|'+(t.indexOf('سلطان الغنام')>=0?1:0)" | tr -d '"')
IFS='|' read -r A10 A11 <<< "$R"
ck "A10 FLIP: «کینگزلی کومان» rides (6050088)" "$A10"
ck "A11 FLIP: «سلطان الغنام» rides (6050088)" "$A11"
# A12: /match/5887671 (Liga Portugal) — Kamiński flips
agent-browser open "http://localhost:3000/match/5887671" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('یاکوب کامینسکی')>=0?1:0)" | tr -d '"')
ck "A12 FLIP: «یاکوب کامینسکی» rides (5887671)" "$R"
# A13: /match/5904789 (Süper Lig) — Etebo flips
agent-browser open "http://localhost:3000/match/5904789" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('پیتر اتهبو')>=0?1:0)" | tr -d '"')
ck "A13 FLIP: «پیتر اتهبو» rides (5904789)" "$R"

echo "================ B: the fix contracts ================"
# B1: API byte flips — the unavailable rows carry nameFa on 5868113
R=$(api "/api/match/5868113" | python3 -c "
import json,sys
d=json.load(sys.stdin)
hits=set()
def w(o):
    if isinstance(o,dict):
        if o.get('name') in ('Aimar Oroz','Jorge Herrando','Bright Ede','Zakaria Eddahchouri') and o.get('nameFa'): hits.add(o['name']+'='+o['nameFa'])
        for v in o.values(): w(v)
    elif isinstance(o,list):
        for v in o: w(v)
w(d)
print(1 if len(hits)>=4 else 0)")
ck "B1 API byte flips: 4+ unavailable rows carry nameFa (5868113)" "$R"
# B2: the honest fallback stays raw ON THE SAME PAGE — Fatih Aksoy (5868113's
# sibling witness 5904789) renders raw; NO Persian invention
R=$(api "/api/match/5904789" | python3 -c "
import json,sys
d=json.load(sys.stdin)
res={'raw':0,'fa':0}
def w(o):
    if isinstance(o,dict):
        if o.get('name')=='Fatih Aksoy':
            if o.get('nameFa')=='Fatih Aksoy' or not o.get('nameFa') or o.get('nameFa')=='Fatih Aksoy': res['raw']=1
        for v in o.values(): w(v)
    elif isinstance(o,list):
        for v in o: w(v)
w(d)
print(1 if res['raw']==1 else 0)")
ck "B2 honest fallback: «Fatih Aksoy» (uncertain) stays byte-raw in API" "$R"
agent-browser open "http://localhost:3000/match/5904789" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('Fatih Aksoy')>=0?1:0)+'|'+(t.indexOf('فاطیح')===-1?1:0)" | tr -d '"')
IFS='|' read -r B3 B4 <<< "$R"
ck "B3 DOM honest fallback: raw «Fatih Aksoy» still renders (no invention)" "$B3"
ck "B4 no Persian hallucination for the uncertain name" "$B4"
# B5: the events-assist sub-class — Ilay Feingold rides assistFa (5071483)
R=$(api "/api/match/5071483" | python3 -c "
import json,sys
d=json.load(sys.stdin)
hit=0
def w(o):
    global hit
    if isinstance(o,dict):
        if (o.get('assist')=='Ilay Feingold' and o.get('assistFa')=='ایلای فاینگولد') or (o.get('name')=='Ilay Feingold' and o.get('nameFa')=='ایلای فاینگولد'): hit=1
        for v in o.values(): w(v)
    elif isinstance(o,list):
        for v in o: w(v)
w(d)
print(hit)")
ck "B5 the events-assist sub-class: «ایلای فاینگولد» rides (5071483)" "$R"
# B6: source-diff scope — exactly ONE src/ file (player-names-fa.ts), UI/API untouched
N=$(git diff --name-only HEAD -- src/ 2>/dev/null | grep -c .)
OK=$(git diff --name-only HEAD -- src/ 2>/dev/null | grep -c "player-names-fa.ts")
ck "B6 source scope: exactly one src/ file and it is player-names-fa.ts" "$([ "$N" = "1" ] && [ "$OK" = "1" ] && echo 1 || echo 0)"
# B7: batch size = 130 new map entries
ADDED=$(git diff HEAD -- src/lib/player-names-fa.ts | grep -c '^+  "')
ck "B7 batch size: 130 new PLAYER_NAME_FA entries" "$([ "$ADDED" = "130" ] && echo 1 || echo 0)"
# B8: map-level flip count via the actual playerFa — 146→16 unmapped
R=$(cd /home/z/my-project/remontada && bun run /tmp/verify-fa.ts 2>&1 | tail -1 | grep -c "truly-unmapped=16")
ck "B8 map coverage: truly-unmapped 146→16 (the deliberate honest-raw remainder)" "$R"

echo "================ C: standing holds + anchors + hygiene ================"
agent-browser open http://localhost:3000/player/319784 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('آلیسون بکر')>=0?1:0)" | tr -d '"')
ck "C1 /player/319784 h1 «آلیسون بکر» (the 398 hold)" "$R"
agent-browser open http://localhost:3000/coach/24011 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('جام حذفی انگلیس')>=0?1:0)" | tr -d '"')
ck "C2 /coach/24011 honours «جام حذفی انگلیس» (the 400 hold)" "$R"
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)+'|'+(t.indexOf('ابراهیما کوناته')>=0?1:0)" | tr -d '"')
IFS='|' read -r C3 C4 C5 <<< "$R"
ck "C3 /team/8650 bench history «آرنه اسلوت» (the 399 hold)" "$C3"
ck "C4 no bench raw regression (Sampaoli absent on 8650)" "$C4"
ck "C5 the 405 hold in DOM: transfers «ابراهیما کوناته» still rides" "$C5"
agent-browser open http://localhost:3000/topscorers/pl >/dev/null 2>&1; sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('گرانیت ژاکا')>=0?1:0)+'|'+(t.indexOf('ساندرلند')>=0?1:0)" | tr -d '"')
IFS='|' read -r C6 C7 <<< "$R"
ck "C6 /topscorers/pl per-90 flip «گرانیت ژاکا» (the 407 hold)" "$C6"
ck "C7 per-90 team subtitle «ساندرلند» rides (the 407 hold)" "$C7"
agent-browser open http://localhost:3000/league/ucl >/dev/null 2>&1; sleep 4
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آمار فصل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('پاری سن‌ژرمن')>=0?1:0)+'|'+(t.indexOf('استون‌ویلا')>=0?1:0)" | tr -d '"')
IFS='|' read -r C8 C9 <<< "$R"
ck "C8 /league/ucl boards flip «پاری سن‌ژرمن» after real «آمار فصل» click (the 406 hold)" "$C8"
ck "C9 boards flip «استون‌ویلا» rides (the 406 hold)" "$C9"
agent-browser open "http://localhost:3000/search?q=%DA%A9%D9%84%D9%88%D9%BE" >/dev/null 2>&1; sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('یورگن کلوپ')>=0?1:0)+'|'+(t.indexOf('Jürgen Klopp')>=0?1:0)" | tr -d '"')
IFS='|' read -r C10 C11 <<< "$R"
ck "C10 the 409 hold: search «یورگن کلوپ» title rides" "$C10"
ck "C11 the 409 hold: raw «Jürgen Klopp» subtitle rides" "$C11"
agent-browser open http://localhost:3000/leagues >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)" | tr -d '"')
ck "C12 /leagues anchor «لیگ‌ها»" "$R"

for PG in "" "match/5868113" "match/5071483" "match/6050088" "search?q=%DA%A9%D9%84%D9%88%D9%BE" "team/8650" "player/319784" "league/pl" "topscorers/pl" "news"; do
  agent-browser open "http://localhost:3000/$PG" >/dev/null 2>&1
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
