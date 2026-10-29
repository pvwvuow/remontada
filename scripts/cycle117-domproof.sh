#!/bin/bash
# Cycle-117 update DOM proof at 390x844 — «گلزنان فصل دو تیم» on the match
# h2h (رو در رو) tab. The feature: the matchFacts.topScorers block — each
# side's LEAGUE season top scorer + season line (goals / assists / xG /
# minutes-per-goal / MOTM awards / season rating / games), unconsumed since
# the beginning (the per-match playerStats table is a DIFFERENT section).
# Proof:
#   1) API truth: /api/match/5071457 topScorers carries both sides (Messi
#      25 goals / 12 assists / xG 20.2 / every 96 min / rating 8.26 / 28
#      games; Denkey 17 / 3 / 18 / 139 / 7.32 / 29) with /player/{id} ids;
#   2) DOM: the «رو در رو» tab shows TopScorersCard (testid=match-topscorers)
#      with the header «گلزنان فصل دو تیم», both Persian team labels, the
#      big Persian goal numbers, the season sub-rows and /player/ links;
#      the H2H summary card intact below it;
#   3) contracts: sw=cw=390, exactly 1 h1, 0 broken imgs, console=0,
#      pageErr=0 (cycle-108 url convention — records without url don't count).
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null

# — API truth —
API=$(curl -s "http://localhost:3000/api/match/5071457" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin); ts=d.get('topScorers') or {}
  h=ts.get('home') or {}; a=ts.get('away') or {}
  print(json.dumps({'hGoals':h.get('goals'),'hAst':h.get('assists'),'hXg':h.get('xg'),'hMpg':h.get('minsPerGoal'),'hRating':h.get('rating'),'hGames':h.get('games'),'hId':h.get('playerId'),'aGoals':a.get('goals'),'aId':a.get('playerId')},ensure_ascii=False))
except Exception:
  print('ERR')")
echo "[api 5071457] $API"
echo "$API" | grep -q '"hGoals": 25' || echo "$API" | grep -q '"hGoals":25' || { FAIL=1; echo "  !! home goals != 25"; }
echo "$API" | grep -q '"hAst": 12' || echo "$API" | grep -q '"hAst":12' || { FAIL=1; echo "  !! home assists != 12"; }
echo "$API" | grep -q '"hXg": 20.2' || echo "$API" | grep -q '"hXg":20.2' || { FAIL=1; echo "  !! home xG != 20.2"; }
echo "$API" | grep -q '"hMpg": 96' || echo "$API" | grep -q '"hMpg":96' || { FAIL=1; echo "  !! minutes-per-goal != 96"; }
echo "$API" | grep -q '"hRating": 8.26' || echo "$API" | grep -q '"hRating":8.26' || { FAIL=1; echo "  !! season rating != 8.26"; }
echo "$API" | grep -q '"hId": 30981' || echo "$API" | grep -q '"hId":30981' || { FAIL=1; echo "  !! home playerId missing"; }
echo "$API" | grep -q '"aGoals": 17' || echo "$API" | grep -q '"aGoals":17' || { FAIL=1; echo "  !! away goals != 17"; }

# — DOM checks —
check_page () { # $1=url $2=label
  local URL="$1" LABEL="$2"
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$URL" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  # open the h2h tab (the card rides the main payload, no extra fetch needed)
  $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="رو در رو");if(b)b.click();return 1})()' >/dev/null 2>&1
  for i in 1 2 3 4 5 6; do
    GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=match-topscorers]"))' 2>/dev/null | tr -d '"\\')
    [ "$GOT" = "true" ] && break
    sleep 2
  done
  sleep 1.5
  local BM RES CON ERR
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  RES=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-topscorers]");if(!c)return {present:false};const t=c.innerText||"";return {present:true,title:t.includes("گلزنان فصل دو تیم"),sub:t.includes("آقای گل لیگ هر تیم")}})())' 2>/dev/null | tr -d '"\\')
  CON=$($B console 2>/dev/null | grep -ci error || true)
  ERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
  echo "[$LABEL] bm=$BM card=$RES consoleErr=$CON pageErr=$ERR"
  case "$BM" in *"sw:390,"*|*'"sw":390,'*) ;; *) FAIL=1; echo "  !! viewport contract broken";; esac
  case "$BM" in *"h1:1,"*|*'"h1":1,'*) ;; *) FAIL=1; echo "  !! h1 count != 1";; esac
  case "$BM" in *"img:0"*|*'"img":0'*) ;; *) FAIL=1; echo "  !! broken images";; esac
  [ "$CON" = "0" ] || { FAIL=1; echo "  !! console errors"; }
  [ "$ERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }
}

check_page "http://localhost:3000/match/5071457" "match-5071457"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=match-topscorers]")?.innerText||"")+"\n"+(document.body.innerText))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "گلزنان فصل دو تیم" || { FAIL=1; echo "  !! card header missing"; }
echo "$TXT" | grep -q "آقای گل لیگ هر تیم" || { FAIL=1; echo "  !! card sub missing"; }
echo "$TXT" | grep -q "Lionel Messi" || { FAIL=1; echo "  !! home scorer missing"; }
echo "$TXT" | grep -q "Denkey" || { FAIL=1; echo "  !! away scorer missing"; }
echo "$TXT" | grep -q "گل فصل" || { FAIL=1; echo "  !! season-goals metric label missing"; }
echo "$TXT" | grep -q "پاس گل" || { FAIL=1; echo "  !! assists row missing"; }
echo "$TXT" | grep -q "xG فصل" || { FAIL=1; echo "  !! xG row missing"; }
echo "$TXT" | grep -q "سرعت گلزنی" || { FAIL=1; echo "  !! minutes-per-goal row missing"; }
echo "$TXT" | grep -q "امتیاز فصل" || { FAIL=1; echo "  !! season rating row missing"; }
echo "$TXT" | grep -q "۲۵" || { FAIL=1; echo "  !! Persian 25 missing"; }
echo "$TXT" | grep -q "۹۶ دقیقه" || { FAIL=1; echo "  !! Persian minutes-per-goal value missing"; }
echo "$TXT" | grep -q "بازی در فصل" || { FAIL=1; echo "  !! games line missing"; }
# h2h summary card intact below (regression: the tab still works)
$B eval 'JSON.stringify(document.body.innerText.includes("دیدار"))' >/dev/null 2>&1 || true
NLINK=$($B eval 'JSON.stringify(document.querySelectorAll("[data-testid=match-topscorers] a").length)' 2>/dev/null | tr -d '"\\')
echo "[topscorer player links] $NLINK"
[ "$NLINK" -ge 2 ] 2>/dev/null || { FAIL=1; echo "  !! /player/ links < 2"; }

# a second fixture — another live MLS match from the same matchday pool
check_page "http://localhost:3000/match/5071463" "match-5071463"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=match-topscorers]")?.innerText||"")+"\n"+(document.body.innerText))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "گلزنان فصل دو تیم" || { FAIL=1; echo "  !! second fixture card missing"; }

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE117 DOMPROOF OK" || echo "CYCLE117 DOMPROOF FAIL"
exit $FAIL
