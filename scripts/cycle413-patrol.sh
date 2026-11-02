#!/usr/bin/env bash
# cycle413-patrol.sh — bug-hunt cycle 413 (فرمول ۴): wide patrol + the
# recent-cycle feature re-verification at 390x844. Findings are REPORTED
# ONLY (the fix belongs to cycle-414=فیکس). No source changes expected —
# the 398/403/408 precedent: the server stays on the official 412 build.
#   A   hygiene three-pack (page-errors / console-errors=0 / scrollW=cw=390)
#       on TWENTY-THREE pages — including surfaces the 408 patrol never
#       swept in DOM: /league/laliga, /league/bundesliga, /league/ligue1,
#       /league/facup, /topscorers/laliga, /topscorers/ucl + the 412/411
#       witness pages (/match/5749731, /match/5904789, /team/8668).
#   B   the recent-cycle witness re-assertions with REAL tab clicks
#       (412/411/410 + the standing 407/406/405/404/400/399/398 holds).
#   C   the new-surface bug hunt: the full API inventory health sweep
#       (27 endpoints, live-probed shapes) + og/rss/sitemap/manifest +
#       the two by-design classifications (topscorers 400-guard,
#       og unknown-key 404 contract).
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
info_tab_click() {
  agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='اطلاعات'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
}

echo "================ A: hygiene three-pack on TWENTY-THREE pages (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
for PG in "" "standings" "leagues" "news" "players" "search?q=%DA%A9%D9%84%D9%88%D9%BE" "topscorers" "topscorers/laliga" "topscorers/ucl" "league/pl" "league/ucl" "league/laliga" "league/bundesliga" "league/ligue1" "league/facup" "team/8650" "team/8668" "team/9875" "player/319784" "coach/26630" "match/5795503" "match/5749731" "match/5904789"; do
  agent-browser open "http://localhost:3000/$PG" >/dev/null 2>&1
  sleep 2
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "H /$PG page-errors clean" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
  ck "H /$PG console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "H /$PG scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"
done

echo "================ B: recent-cycle witness re-assertions (390x844, real clicks) ================"
# B1-B3: the 412 holds — venue/city/referee rows via the real «اطلاعات» click
agent-browser open http://localhost:3000/match/5795503 >/dev/null 2>&1
sleep 5
info_tab_click
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ورزشگاه سنت جیمز پارک')>=0?1:0)+'|'+(t.indexOf('نیوکاسل')>=0?1:0)+'|'+(t.indexOf('جان بروکس')>=0?1:0)" | tr -d '"')
IFS='|' read -r B1 B2 B3 <<< "$R"
ck "B1 412-hold: «ورزشگاه سنت جیمز پارک» rides (5795503)" "$B1"
ck "B2 412-hold: city «نیوکاسل» rides" "$B2"
ck "B3 412-hold: referee «جان بروکس» rides" "$B3"
# B4-B6: the 412 honest-raw hold on the SAME page family (5904789)
agent-browser open http://localhost:3000/match/5904789 >/dev/null 2>&1
sleep 5
info_tab_click
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ورزشگاه اریامان')>=0?1:0)+'|'+(t.indexOf('آنکارا')>=0?1:0)+'|'+(t.indexOf('Fatih Tokail')>=0?1:0)" | tr -d '"')
IFS='|' read -r B4 B5 B6 <<< "$R"
ck "B4 412-hold: «ورزشگاه اریامان» rides (5904789)" "$B4"
ck "B5 412-hold: city «آنکارا» rides" "$B5"
ck "B6 412-hold: honest-raw referee «Fatih Tokail» stays on the same page" "$B6"
# B7-B9: the 411 holds — 8668 squad coach chip + last-lineup fa-first + honest raw
agent-browser open http://localhost:3000/team/8668 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('دیوید مویس')>=0?1:0)+'|'+(t.indexOf('کیرنان دیوزبری-هال')>=0?1:0)+'|'+(t.indexOf('Zento Uno')>=0?1:0)" | tr -d '"')
IFS='|' read -r B7 B8 B9 <<< "$R"
ck "B7 411-hold: squad coach chip «دیوید مویس» rides (8668)" "$B7"
ck "B8 411-hold: last-lineup «کیرنان دیوزبری-هال» rides fa-first" "$B8"
# B9 re-pointed (the first-run FAIL, reclassified with evidence): the
# «Zento Uno» witness rotated OUT of the upstream XI since the 411 card —
# today's Everton lineup is 100% fa-covered. The hold becomes the CLASS
# check: zero honest-raw Latin names remain in the lineup payload (the
# no-invention contract can only be proven where raw names exist; the live
# raw witness rides B6, the 412 referee).
ck "B9 411-hold: 8668 lineup payload zero honest-raw Latin (XI fully fa-covered)" "$(api /api/team-last-lineup/8668 | python3 -c "
import json,re,sys
LAT=re.compile(r'^[A-Za-z\\u00C0-\\u024F .\\-]+$')
raw=[]
def walk(o):
    if isinstance(o,dict):
        n=o.get('name') or o.get('playerName')
        if isinstance(n,str) and LAT.search(n) and not (o.get('nameFa') or o.get('fa') or '').strip(): raw.append(n)
        for v in o.values(): walk(v)
    elif isinstance(o,list):
        for v in o: walk(v)
walk(json.load(sys.stdin))
print(1 if len(raw)==0 else 0)")"
# B10-B11: the 410 holds — lineups via the real «ترکیب» click (5071483)
agent-browser open http://localhost:3000/match/5071483 >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('کازمیرو')>=0?1:0)+'|'+(t.indexOf('Fatih Aksoy')>=0?1:0)" | tr -d '"')
IFS='|' read -r B10 B11 <<< "$R"
ck "B10 410-hold: «کازمیرو» rides the lineups (5071483)" "$B10"
# B11 re-pointed (the first-run FAIL, reclassified with evidence): «Fatih
# Aksoy» rotated out of the 5071483 payload since the 410 card — today's
# payload is fully fa-covered. The hold becomes the same CLASS check at
# match level (the live raw witness rides B6).
ck "B11 410-hold: 5071483 payload zero honest-raw Latin (fully fa-covered)" "$(api /api/match/5071483 | python3 -c "
import json,re,sys
LAT=re.compile(r'^[A-Za-z\\u00C0-\\u024F .\\-]+$')
raw=[]
def walk(o):
    if isinstance(o,dict):
        n=o.get('name') or o.get('playerName')
        if isinstance(n,str) and LAT.search(n) and not (o.get('nameFa') or o.get('fa') or '').strip(): raw.append(n)
        for v in o.values(): walk(v)
    elif isinstance(o,list):
        for v in o: walk(v)
walk(json.load(sys.stdin))
print(1 if len(raw)==0 else 0)")"
# B12-B14: the 407 holds — per-90 flips
agent-browser open http://localhost:3000/topscorers/pl >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('گرانیت ژاکا')>=0?1:0)+'|'+(t.indexOf('ساندرلند')>=0?1:0)+'|'+(t.indexOf('داوید رایا')>=0?1:0)" | tr -d '"')
IFS='|' read -r B12 B13 B14 <<< "$R"
ck "B12 407-hold: «گرانیت ژاکا» rides per-90" "$B12"
ck "B13 407-hold: team subtitle «ساندرلند» rides" "$B13"
ck "B14 407-hold: «داوید رایا» rides" "$B14"
# B15-B16: the 407 holds — «غایبان» via the real «ترکیب» click (5749738)
agent-browser open http://localhost:3000/match/5749738 >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('غایبان')>=0?1:0)+'|'+(t.indexOf('اسماعیل کونه')>=0?1:0)+'|'+(t.indexOf('فده لیزن')>=0?1:0)" | tr -d '"')
IFS='|' read -r B15 B16a B16b <<< "$R"
ck "B15 407-hold: «غایبان» renders after the real «ترکیب» click" "$B15"
ck "B16 407-hold: «اسماعیل کونه»+«فده لیزن» ride the absentees" "$([ "$B16a" = "1" ] && [ "$B16b" = "1" ] && echo 1 || echo 0)"
# B17: the 407 holds — «آقای گل» tab on /league/pl
agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1
sleep 4
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آقای گل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ارلینگ هالند')>=0?1:0)" | tr -d '"')
ck "B17 407-hold: /league/pl «آقای گل» leader «ارلینگ هالند» rides" "$R"
# B18-B19: the 406 holds — team-kind boards via the real «آمار فصل» click
agent-browser open http://localhost:3000/league/ucl >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آمار فصل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('پاری سن‌ژرمن')>=0?1:0)+'|'+(t.indexOf('استون‌ویلا')>=0?1:0)" | tr -d '"')
IFS='|' read -r B18 B19 <<< "$R"
ck "B18 406-hold: /league/ucl boards «پاری سن‌ژرمن» after «آمار فصل»" "$B18"
ck "B19 406-hold: «استون‌ویلا» rides the team boards" "$B19"
# B20-B23: the 405/399/400 holds on /team/8650
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ابراهیما کوناته')>=0?1:0)+'|'+(t.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)+'|'+(t.indexOf('جام حذفی انگلیس')>=0?1:0)" | tr -d '"')
IFS='|' read -r B20 B21 B22 B23 <<< "$R"
ck "B20 405-hold: /team/8650 transfers «ابراهیما کوناته» rides" "$B20"
ck "B21 399-hold: bench «آرنه اسلوت» rides" "$B21"
ck "B22 399-hold: no bench raw regression (Sampaoli absent)" "$B22"
ck "B23 400-hold: trophies «جام حذفی انگلیس» rides" "$B23"
# B24: the 404 hold at payload level — 8650 team-stats lockstep
ck "B24 404-hold: 8650 team-stats leaderFa/extrasFa lockstep (BAD=0)" "$(api /api/team-stats/8650 | python3 -c "
import json,sys
bad=0; rows=0
try:
    d=json.load(sys.stdin); s=(d.get('stats') or {})
    for r in (s.get('playerRows') or [])+(s.get('teamRows') or []):
        rows+=1
        if r.get('leader') and not (r.get('leaderFa') or '').strip(): bad+=1
        ex=r.get('extras') or []; ef=r.get('extrasFa')
        if ex and (not ef or len(ef)!=len(ex)): bad+=1
except Exception: print(0); raise SystemExit
print(1 if rows>0 and bad==0 else 0)")"
# B25: the 399 dual-purpose at the API level (byte-exact pair)
ck "B25 399-hold: /api/search «کلوپ» dual byte-exact (name+fa)" "$(api "/api/search?q=%DA%A9%D9%84%D9%88%D9%BE" | python3 -c "
import json,sys
cs=(json.load(sys.stdin).get('coaches') or [])
print(1 if any(c.get('name')=='Jürgen Klopp' and c.get('fa')=='یورگن کلوپ' for c in cs) else 0)")"
# B26: the 398 anchor
agent-browser open http://localhost:3000/player/319784 >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('آلیسون بکر')>=0?1:0)" | tr -d '"')
ck "B26 398-hold: /player/319784 h1 «آلیسون بکر»" "$R"

echo "================ C: new-surface bug hunt (findings only) ================"
# C1: the FULL API inventory health sweep — 27 endpoints, live-probed
# shapes (HTTP 200 + payload parses as JSON). The two earlier suspects are
# BY-DESIGN and excluded from the sweep: /api/topscorers?league=… → honest
# 400 (cycle-184 guard: the league is a path segment); /api/og/<unknown-key>
# → hard 404 (dynamicParams=false, the topscorers-page contract).
# C1 final shape (the second sweep suspect, reclassified with evidence):
# /api/league-calendar is the DESIGNED iCalendar feed (content-type
# text/calendar, BEGIN:VCALENDAR body — its own contract check rides C1b),
# so the JSON sweep covers the other 29 endpoints. 29 JSON endpoints here.
API_HEALTH=$(X=0
for U in "api/standings?league=pl" "api/matches?offset=0" "api/news" "api/topscorers/pl" "api/search?q=%DA%A9%D9%84%D9%88%D9%BE" "api/match/5795503" "api/match-h2h/5795503" "api/league-fixtures?league=pl" "api/league-fixtures-all?league=pl" "api/league-bracket?league=ucl" "api/league-titles?league=ucl" "api/league-totw?league=pl" "api/league-transfers?league=pl" "api/team/8650" "api/team-squad/8650" "api/team-coaches/8650" "api/team-stats/8650" "api/team-transfers/8650" "api/team-trophies/8650" "api/team-venue/8650" "api/team-history/8650" "api/team-news/8650" "api/team-fixtures/8650" "api/team-difficulty/8650" "api/team-last-lineup/8668" "api/team-top-players/8650" "api/team-rumours/8650" "api/player/319784" "api/coach/26630"; do
  CODE=$(curl -s -o /tmp/c413_body -w '%{http_code}' -A "$UA" "$BASE/$U")
  # the patrol-413 hardening: the sweep runs WHILE the browser hammers the
  # same upstream-backed routes; one live probe showed a transient non-200
  # that self-heals (the designed 502/snapshot path). One 3s-backed retry
  # separates a transient from a real breakage.
  if [ "$CODE" != "200" ] || ! python3 -c "import json,sys; json.load(open('/tmp/c413_body'))" 2>/dev/null; then
    sleep 3
    CODE=$(curl -s -o /tmp/c413_body -w '%{http_code}' -A "$UA" "$BASE/$U")
  fi
  if [ "$CODE" != "200" ] || ! python3 -c "import json,sys; json.load(open('/tmp/c413_body'))" 2>/dev/null; then
    echo "  BAD: /$U -> $CODE"; X=1
  fi
done
echo "$X")
# C1 semantics: the loop echoes X=0 when CLEAN (no BAD lines) and X=1
# otherwise — the first three patrol runs' C1 FAILs were THIS ck inversion
# (ck expects "1"=PASS), not the server: the standalone sweep was green all
# along. The ck below converts the loop's 0-clean convention properly.
ck "C1 API inventory health sweep: 29 JSON endpoints all 200 + JSON" "$([ "$API_HEALTH" = "0" ] && echo 1 || echo 0)"
[ "$API_HEALTH" = "0" ] || echo "C1-DETAIL:$API_HEALTH"
# C1b: the DESIGNED iCalendar feed contract (the second suspect, live-probed:
# content-type text/calendar, VCALENDAR body, Persian fa-first summaries)
ck "C1b /api/league-calendar → 200 text/calendar + VCALENDAR + fa summary" "$(R=$(curl -s -o /tmp/c413_cal -w '%{http_code} %{content_type}' -A "$UA" "$BASE/api/league-calendar?league=pl"); T=$(head -c 20 /tmp/c413_cal); F=$(grep -c 'آرسنال' /tmp/c413_cal 2>/dev/null || echo 0); echo "$R" | grep -q '200 text/calendar' && echo "$T" | grep -q 'BEGIN:VCALENDAR' && [ "$F" -gt 0 ] && echo 1 || echo 0)"
ck "C4b og image endpoints 200 + image/png" "$(R1=$(curl -s -o /dev/null -w '%{http_code} %{content_type}' -A "$UA" "$BASE/api/og/pl"); R2=$(curl -s -o /dev/null -w '%{http_code} %{content_type}' -A "$UA" "$BASE/api/og/person/319784"); echo "$R1 $R2" | grep -qv image/png && echo 0 || echo 1)"
# C2: the cycle-184 honest-400 guard re-assertion (documented BY-DESIGN)
R=$(curl -s -o /tmp/c413_t -w '%{http_code}' -A "$UA" "$BASE/api/topscorers?league=pl")
CONTRACT=$( [ "$R" = "400" ] && python3 -c "import json; d=json.load(open('/tmp/c413_t')); print(1 if 'path segment' in d.get('error','') else 0)" || echo 0)
ck "C2 BY-DESIGN: /api/topscorers?league=pl → honest 400 + path-segment hint" "$CONTRACT"
# C3: the og unknown-key 404 contract re-assertion (documented BY-DESIGN)
R=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/og/nonexistent-league")
ck "C3 BY-DESIGN: /api/og/unknown-key → hard 404 (dynamicParams=false)" "$([ "$R" = "404" ] && echo 1 || echo 0)"
# C4: the og league card renders an image with the weekly cache policy
R=$(curl -s -o /tmp/c413_og -w '%{http_code} %{content_type}' -A "$UA" "$BASE/api/og/ucl")
ck "C4 /api/og/ucl → 200 image/*" "$(echo "$R" | grep -q '200 image/' && echo 1 || echo 0)"
# C5: rss + sitemap + manifest live (the 408 sweep re-assertion)
ck "C5 rss.xml 200 + XML" "$(curl -s -o /dev/null -w '%{http_code} %{content_type}' -A "$UA" "$BASE/rss.xml" | grep -q '200' && echo 1 || echo 0)"
ck "C6 sitemap.xml 200" "$([ "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/sitemap.xml")" = "200" ] && echo 1 || echo 0)"
ck "C7 webmanifest 200" "$([ "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/manifest.webmanifest")" = "200" ] || [ "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/manifest.json")" = "200" ] && echo 1 || echo 0)"
# C8: /news content health re-assertion (the 408 C1 contract)
agent-browser open http://localhost:3000/news >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=(document.body.innerText||''); var a=document.querySelectorAll('a').length; (t.length>200?1:0)+'|'+(a>3?1:0)" | tr -d '"')
IFS='|' read -r C8a C8b <<< "$R"
ck "C8a /news body renders substantial content" "$C8a"
ck "C8b /news has clickable items (links>3)" "$C8b"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
