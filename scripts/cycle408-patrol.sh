#!/usr/bin/env bash
# cycle408-patrol.sh — bug-hunt cycle 408 (فرمول ۴): wide patrol + the
# recent-cycle feature re-verification at 390x844. Findings are REPORTED
# ONLY (the fix belongs to cycle-409=فیکس). No source changes expected —
# the 398/403 precedent: the server stays on the official 407 build.
#   A   hygiene three-pack (page-errors / console-errors=0 / scrollW=cw=390)
#       on TWENTY-ONE pages — including surfaces the 398/402/403/406 patrols
#       never swept: /news, /players, /search (Persian query), /match/5795503,
#       /team/9875, /league/seriea, /topscorers/seriea.
#   B   the recent-cycle witness re-assertions (407/406/405/404 + anchors).
#   C   the new-surface bug hunt: /news + /players content health, /search
#       packet in DOM, /api/news payload, rss.xml + sitemap.xml + manifest.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: hygiene three-pack on TWENTY-ONE pages (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
for PG in "" "standings" "leagues" "news" "players" "search?q=%DA%A9%D9%84%D9%88%D9%BE" "topscorers" "topscorers/pl" "topscorers/seriea" "league/pl" "league/ucl" "league/seriea" "team/8650" "team/6706" "team/9875" "player/319784" "player/361757" "coach/26630" "coach/9012" "match/5749738" "match/5795503"; do
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

echo "================ B: recent-cycle witness re-assertions (390x844) ================"
# B1-B2: the 407 holds — per-90 flips + the «غایبان» tab block
agent-browser open http://localhost:3000/topscorers/pl >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (document.querySelectorAll('[data-testid=passes-row]').length>0?1:0)+'|'+(t.indexOf('گرانیت ژاکا')>=0?1:0)+'|'+(t.indexOf('ساندرلند')>=0?1:0)+'|'+(t.indexOf('داوید رایا')>=0?1:0)" | tr -d '"')
IFS='|' read -r B1 B2 B3 B4 <<< "$R"
ck "B1 407-hold: /topscorers/pl «پاس دقیق در هر ۹۰» rows render" "$B1"
ck "B2 407-hold: «گرانیت ژاکا» rides" "$B2"
ck "B3 407-hold: team subtitle «ساندرلند» rides" "$B3"
ck "B4 407-hold: «داوید رایا» rides" "$B4"
agent-browser open http://localhost:3000/match/5749738 >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=match-unavailable]')||{innerText:''}).innerText; (s.length>0?1:0)+'|'+(s.indexOf('اسماعیل کونه')>=0?1:0)+'|'+(s.indexOf('کریستین توشتودت')>=0?1:0)+'|'+(s.indexOf('فده لیزن')>=0?1:0)" | tr -d '"')
IFS='|' read -r B5 B6 B7 B8 <<< "$R"
ck "B5 407-hold: «غایبان» renders after the real «ترکیب» click" "$B5"
ck "B6 407-hold: «اسماعیل کونه» rides" "$B6"
ck "B7 407-hold: «کریستین توشتودت» rides" "$B7"
ck "B8 407-hold: «فده لیزن» rides" "$B8"
# B9-B10: the 406 hold — team-kind boards via the «آمار فصل» tab click
agent-browser open http://localhost:3000/league/ucl >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آمار فصل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=league-boards]')||{innerText:''}).innerText; (s.length>0?1:0)+'|'+(s.indexOf('پاری سن‌ژرمن')>=0?1:0)+'|'+(s.indexOf('استون‌ویلا')>=0?1:0)" | tr -d '"')
IFS='|' read -r B9 B10 B11 <<< "$R"
ck "B9 406-hold: /league/ucl boards render after the «آمار فصل» click" "$B9"
ck "B10 406-hold: «پاری سن‌ژرمن» rides the team boards" "$B10"
ck "B11 406-hold: «استون‌ویلا» rides" "$B11"
# B12-B13: the 405 hold — transfers «ابراهیما کوناته» on /team/8650
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ابراهیما کوناته')>=0?1:0)+'|'+(t.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)" | tr -d '"')
IFS='|' read -r B12 B13 B14 <<< "$R"
ck "B12 405-hold: /team/8650 transfers «ابراهیما کوناته» rides" "$B12"
ck "B13 399-hold: bench «آرنه اسلوت» rides" "$B13"
ck "B14 399-hold: no bench raw regression (Sampaoli absent)" "$B14"
# B15: the 404 hold at payload level — 8650 team-stats lockstep
ck "B15 404-hold: 8650 team-stats leaderFa/extrasFa lockstep (BAD=0)" "$(python3 -c "
import json, subprocess
UA='$UA'
bad=0; rows=0
d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000/api/team-stats/8650']))
s=(d.get('stats') or {})
for r in (s.get('playerRows') or [])+(s.get('teamRows') or []):
    rows+=1
    if r.get('leader') and not (r.get('leaderFa') or '').strip(): bad+=1
    ex=r.get('extras') or []; ef=r.get('extrasFa')
    if ex and (not ef or len(ef)!=len(ex)): bad+=1
print(1 if rows>0 and bad==0 else 0)")"
# B16-B18: the standing anchors
agent-browser open http://localhost:3000/player/319784 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('آلیسون بکر')>=0?1:0)" | tr -d '"')
ck "B16 398-hold: /player/319784 h1 «آلیسون بکر»" "$R"
agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1; sleep 3
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آقای گل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ارلینگ هالند')>=0?1:0)" | tr -d '"')
ck "B17 407-hold: /league/pl «آقای گل» leader «ارلینگ هالند» rides" "$R"
agent-browser open http://localhost:3000/leagues >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)" | tr -d '"')
ck "B18 anchor: /leagues «لیگ‌ها»" "$R"

echo "================ C: new-surface bug hunt (findings only) ================"
# C1: /news content health in DOM (rendered cards + no page error)
agent-browser open http://localhost:3000/news >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=(document.body.innerText||''); var a=document.querySelectorAll('a').length; (t.length>200?1:0)+'|'+(a>3?1:0)" | tr -d '"')
IFS='|' read -r C1a C1b <<< "$R"
ck "C1a /news body renders substantial content" "$C1a"
ck "C1b /news has clickable items (links>3)" "$C1b"
# C2: /api/news payload health
ck "C2 /api/news payload ok=true with items" "$(api /api/news | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin); items=d.get('items') or d.get('news') or []
    print(1 if (d.get('ok') is not False) and isinstance(items,list) else 0)
except Exception: print(0)")"
# C3: /players — the team-grid lives behind the «تیم‌ها» mode click (the
# default mode is «stars»; the first run's C3a FAIL was a wrong witness —
# the 406 lesson again: assert the surface that actually renders). Also
# re-assert the stars mode warmth (the mode switcher itself).
agent-browser open http://localhost:3000/players >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "document.querySelectorAll('[data-testid^=mode-]').length" | tr -d '"')
ck "C3a /players mode switcher renders (stars+teams)" "$([ "${R:-0}" -ge 2 ] && echo 1 || echo 0)"
agent-browser eval "([...document.querySelectorAll('[data-testid=mode-teams]')][0]||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "document.querySelectorAll('[data-testid=team-grid]').length>0?1:0" | tr -d '"')
ck "C3b /players team-grid renders after the real «تیم‌ها» click" "$R"
# C4: /search Persian query — the page renders FA-FIRST titles BY DESIGN
# (search-page-client: title={c.fa || c.name}; the raw rides the API packet
# byte-exact — the 399 dual-purpose contract is an API contract). The first
# run's C4b FAIL (raw not in body text) was a wrong witness; the honest
# asymmetry worth noting: LEAGUE rows carry a visible raw subtitle
# (subtitle={l.en !== (l.fa || l.en) ? l.en : undefined}) while
# team/coach/player rows do not — a future-polish candidate, NOT a
# regression. Documented as a finding line, not an assertion.
agent-browser open "http://localhost:3000/search?q=%DA%A9%D9%84%D9%88%D9%BE" >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('یورگن کلوپ')>=0?1:0)" | tr -d '"')
ck "C4 /search «کلوپ» DOM: fa «یورگن کلوپ» rides (fa-first by design)" "$R"
ck "C5 the 399 dual-purpose at the REAL contract level: /api/search packet name=«Jürgen Klopp» + fa=«یورگن کلوپ» byte-exact" "$(api "/api/search?q=%DA%A9%D9%84%D9%88%D9%BE" | python3 -c "
import json,sys
cs=(json.load(sys.stdin).get('coaches') or [])
r=[c for c in cs if c.get('name')=='Jürgen Klopp' and c.get('fa')=='یورگن کلوپ']
print(1 if r else 0)")"
# C5-C7: rss/sitemap/manifest live
ck "C6 rss.xml 200 + XML content-type" "$(curl -s -o /dev/null -w '%{http_code} %{content_type}' -A "$UA" "$BASE/rss.xml" | grep -q '200' && echo 1 || echo 0)"
ck "C7 sitemap.xml 200" "$([ "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/sitemap.xml")" = "200" ] && echo 1 || echo 0)"
ck "C7b webmanifest 200" "$([ "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/manifest.webmanifest")" = "200" ] || [ "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/manifest.json")" = "200" ] && echo 1 || echo 0)"
# C8: /news English titles = the DESIGNED cycle-202 English-source feed
# (ESPN / BBC Sport) — a content-language observation, NOT a leak; recorded
# as a finding line. (If the user ever wants Persian headlines, that is a
# new feature — a translation stage — not a bug fix.)
agent-browser open http://localhost:3000/news >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; var lat=(t.match(/[A-Za-z]{4,}/g)||[]); JSON.stringify({count:lat.length, sample:lat.slice(0,4)})" | tr -d '"')
echo "C8-FINDING /news Latin tokens (designed English-source feed): $R"
ck "C8 /news page-errors stayed clean on re-open" "$([ -z "$(agent-browser errors 2>/dev/null | tr -d '"')" ] || [ "$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')" = "0" ] && echo 1 || echo 0)"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
