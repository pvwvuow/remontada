#!/usr/bin/env bash
# cycle409-domproof.sh — fix cycle 409 (فرمول ۵): closing the cycle-408
# documented finding — the search page's raw-name subtitle contract was
# one-sided: only the «رقابت» (league) rows carried the honest upstream
# spelling under a Persian title (subtitle={l.en !== (l.fa || l.en) ? l.en :
# undefined}) while team/coach/player rows let the raw name vanish the
# moment title={fa || name} rendered («یورگن کلوپ» with NO "Jürgen Klopp"
# anywhere, «بوکایو ساکا» with NO "Bukayo Saka", «آرسنال» with NO
# "Arsenal"). Fix = one rawSub() helper in search-page-client.tsx shared by
# ALL four entity sections (the league-row contract from cycle-296, now
# uniform): raw rides the subtitle IFF it differs from the rendered title —
# equal strings (the honest fallback) render nothing, so unmapped rows
# never duplicate. UI-only, additive; the /api/search byte contract and
# the header dropdown stay untouched.
#   A   the 408 finding FLIPPED in DOM at 390x844 (coach/player/team rows
#       now carry the raw name; the league contract unchanged) + nothing
#       broken beside (leagueFa/rank/pts/teamName/teamFa still ride).
#   B   the fix contracts (no-duplication on the honest fallback via the
#       live "Jack Rudoni" witness, the /api/search byte contract intact,
#       the source-diff scope = search-page-client.tsx ONLY).
#   C   the standing holds re-asserted (398/399/400/405/406/407) + anchors
#       + the hygiene three-pack on TEN pages including the fixed surface.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the 408 finding FLIPPED in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
# A1-A3: the coach row — «یورگن کلوپ» title, "Jürgen Klopp" NOW rides the
# subtitle (the exact 408 witness: raw absent before this fix)
agent-browser open "http://localhost:3000/search?q=%DA%A9%D9%84%D9%88%D9%BE" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=search-sec-coaches]')||{innerText:''}).innerText; (s.indexOf('یورگن کلوپ')>=0?1:0)+'|'+(s.indexOf('Jürgen Klopp')>=0?1:0)+'|'+(s.indexOf('سرمربی')>=0?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 <<< "$R"
ck "A1 coach row title «یورگن کلوپ» rides" "$A1"
ck "A2 FLIP: raw «Jürgen Klopp» rides the coach subtitle (the 408 witness)" "$A2"
ck "A3 nothing broken: «سرمربی» club chip still rides" "$A3"
# A4-A6: the player row — «بوکایو ساکا» + "Bukayo Saka" + «آرسنال»
agent-browser open "http://localhost:3000/search?q=%D8%B3%D8%A7%DA%A9%D8%A7" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=search-sec-players]')||{innerText:''}).innerText; (s.indexOf('بوکایو ساکا')>=0?1:0)+'|'+(s.indexOf('Bukayo Saka')>=0?1:0)+'|'+(s.indexOf('آرسنال')>=0?1:0)" | tr -d '"')
IFS='|' read -r A4 A5 A6 <<< "$R"
ck "A4 player row title «بوکایو ساکا» rides" "$A4"
ck "A5 FLIP: raw «Bukayo Saka» rides the player subtitle" "$A5"
ck "A6 nothing broken: teamFa «آرسنال» still rides" "$A6"
# A7-A9: the team row — «آرسنال» + "Arsenal" + leagueFa/rank/pts intact
agent-browser open "http://localhost:3000/search?q=%D8%A2%D8%B1%D8%B3%D9%86%D8%A7%D9%84" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=search-sec-teams]')||{innerText:''}).innerText; (s.indexOf('آرسنال')>=0?1:0)+'|'+(s.indexOf('Arsenal')>=0?1:0)+'|'+(s.indexOf('پریمیرلیگ انگلیس')>=0?1:0)+'|'+(s.indexOf('رتبه')>=0?1:0)+'|'+(s.indexOf('امتیاز')>=0?1:0)" | tr -d '"')
IFS='|' read -r A7 A8 A9 A10 A11 <<< "$R"
ck "A7 team row title «آرسنال» rides" "$A7"
ck "A8 FLIP: raw «Arsenal» rides the team subtitle" "$A8"
ck "A9 nothing broken: leagueFa «پریمیرلیگ انگلیس» still rides" "$A9"
ck "A10 nothing broken: «رتبه» chip still rides" "$A10"
ck "A11 nothing broken: «امتیاز» chip still rides" "$A11"
# A12-A13: the league row — the REFERENCE contract, unchanged semantics via rawSub
agent-browser open "http://localhost:3000/search?q=%D8%A7%D9%86%DA%AF%D9%84%DB%8C%D8%B3" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=search-sec-leagues]')||{innerText:''}).innerText; (s.indexOf('پریمیرلیگ انگلیس')>=0?1:0)+'|'+(s.indexOf('Premier League')>=0?1:0)" | tr -d '"')
IFS='|' read -r A12 A13 <<< "$R"
ck "A12 league title «پریمیرلیگ انگلیس» rides (unchanged)" "$A12"
ck "A13 league raw «Premier League» subtitle rides (the reference contract)" "$A13"

echo "================ B: the fix contracts ================"
# B1-B2: the honest-fallback no-duplication contract — "Jack Rudoni" is
# unmapped (fa==name, probed live 2026-11-02): the title IS the raw name,
# so rawSub must render NOTHING extra — exactly ONE occurrence, teamFa
# «کاونتری» rides alone
agent-browser open "http://localhost:3000/search?q=Rudoni" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=search-sec-players]')||{innerText:''}).innerText; (s.split('Jack Rudoni').length-1)+'|'+(s.indexOf('کاونتری')>=0?1:0)" | tr -d '"')
IFS='|' read -r B1 B2 <<< "$R"
ck "B1 no-duplication: raw-fallback row shows «Jack Rudoni» exactly once (rawSub silent on equal)" "$([ "$B1" = "1" ] && echo 1 || echo 0)"
ck "B2 fallback row subtitle «کاونتری» rides alone" "$B2"
# B3: the /api/search byte contract intact (the 399 dual-purpose hold)
R=$(api "/api/search?q=%DA%A9%D9%84%D9%88%D9%BE" | python3 -c "import json,sys; d=json.load(sys.stdin); c=(d.get('coaches') or [{}])[0]; print((c.get('name')=='Jürgen Klopp')and(c.get('fa')=='یورگن کلوپ')and(c.get('teamName')=='Germany'))" 2>/dev/null)
ck "B3 /api/search byte contract: name=«Jürgen Klopp» + fa=«یورگن کلوپ» + teamName (untouched)" "$([ "$R" = "True" ] && echo 1 || echo 0)"
# B4: the player payload still carries rawSub's inputs
R=$(api "/api/search?q=%D8%B3%D8%A7%DA%A9%D8%A7" | python3 -c "import json,sys; d=json.load(sys.stdin); p=(d.get('players') or [{}])[0]; print((p.get('name')=='Bukayo Saka')and(p.get('fa')=='بوکایو ساکا')and(p.get('teamFa')=='آرسنال'))" 2>/dev/null)
ck "B4 player payload: name+fa+teamFa side by side (the rawSub inputs)" "$([ "$R" = "True" ] && echo 1 || echo 0)"
# B5: the league payload unchanged
R=$(api "/api/search?q=%D8%A7%D9%86%DA%AF%D9%84%DB%8C%D8%B3" | python3 -c "import json,sys; d=json.load(sys.stdin); l=(d.get('leagues') or [{}])[0]; print((l.get('en')=='Premier League')and(l.get('fa')=='پریمیرلیگ انگلیس'))" 2>/dev/null)
ck "B5 league payload: en+fa intact" "$([ "$R" = "True" ] && echo 1 || echo 0)"
# B6: source-diff scope — ONLY search-page-client.tsx changed in src/
N=$(git diff --name-only HEAD -- src/ 2>/dev/null | grep -c .)
OK=$(git diff --name-only HEAD -- src/ 2>/dev/null | grep -c "search-page-client.tsx")
ck "B6 source scope: exactly one src/ file and it is search-page-client.tsx (dropdown+API untouched)" "$([ "$N" = "1" ] && [ "$OK" = "1" ] && echo 1 || echo 0)"

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
agent-browser open http://localhost:3000/leagues >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)" | tr -d '"')
ck "C10 /leagues anchor «لیگ‌ها»" "$R"

for PG in "" "search?q=%D8%A2%D8%B1%D8%B3%D9%86%D8%A7%D9%84" "search?q=%DA%A9%D9%84%D9%88%D9%BE" "search?q=Rudoni" "team/8650" "player/319784" "coach/26630" "league/pl" "topscorers/pl" "news"; do
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
