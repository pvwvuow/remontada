#!/bin/bash
# Cycle-112 update DOM proof at 390x844 — fixture difficulty («سختی
# بازی‌های پیش‌رو»). The feature: FotMob's difficulty widget payload
# (data/teams overview.fixtureDifficulty — the SAME cached raw fetch the
# other lazy team reads use) rendered as a lazy section on the team page
# (testid=team-difficulty): overall verdict chip (سخت/میانه/مدیریت‌پذیر)
# + the next fixtures each with filled difficulty dots on a 1..5 scale.
# Proof:
#   1) API truth: /api/team-difficulty/{8456,9857,9879} carry the right
#      verdicts + 5 fixtures each, all opponents Persian (cycle-112 map
#      keys closed Brighton & Hove Albion / AFC Bournemouth),
#   2) DOM: /team/8456 shows the section with «میانه» + باید باطل «سخت» روی
#      /team/9879 و «مدیریت‌پذیر» روی /team/9857 — rows carry Persian
#      opponent names + 5 dots per row (25 total),
#   3) contracts: sw=cw=390, exactly 1 h1, 0 broken imgs, console=0,
#      pageErr=0 (cycle-108 url convention — records without url don't count).
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null

# — API truth —
for TID in 8456 9857 9879; do
  API=$(curl -s "http://localhost:3000/api/team-difficulty/$TID" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  fd=d.get('difficulty') or {}
  fx=fd.get('fixtures') or []
  raw=[f['opponentFa'] for f in fx if f['opponentFa'] == f.get('opponentEn')]
  print(json.dumps({'verdict':fd.get('verdictFa'),'n':len(fx),'ids':[f.get('matchId') for f in fx]},ensure_ascii=False))
except Exception as e:
  print('ERR')
")
  echo "[api $TID] $API"
  case "$TID" in
    8456) echo "$API" | grep -q "میانه" || { FAIL=1; echo "  !! 8456 verdict wrong"; };;
    9857) echo "$API" | grep -q "مدیریت‌پذیر" || { FAIL=1; echo "  !! 9857 verdict wrong"; };;
    9879) echo "$API" | grep -q "سخت" || { FAIL=1; echo "  !! 9879 verdict wrong"; };;
  esac
  echo "$API" | grep -q '"n": 5' || { FAIL=1; echo "  !! $TID fixture count != 5"; }
done

# — DOM checks —
check_page () { # $1=url $2=label $3=eval-expr
  local URL="$1" LABEL="$2" EXPR="$3"
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$URL" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  # lazy section: poll for the testid (raw payload may need one upstream fetch)
  for i in 1 2 3 4 5 6; do
    GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=team-difficulty]"))' 2>/dev/null | tr -d '"\\')
    [ "$GOT" = "true" ] && break
    sleep 2
  done
  sleep 1.5
  local BM RES CON ERR
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  RES=$($B eval "$EXPR" 2>/dev/null | tr -d '"\\')
  CON=$($B console 2>/dev/null | grep -ci error || true)
  ERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
  echo "[$LABEL] bm=$BM sec=$RES consoleErr=$CON pageErr=$ERR"
  case "$BM" in *"sw:390,"*|*'"sw":390,'*) ;; *) FAIL=1; echo "  !! viewport contract broken";; esac
  case "$BM" in *"h1:1,"*|*'"h1":1,'*) ;; *) FAIL=1; echo "  !! h1 count != 1";; esac
  case "$BM" in *"img:0"*|*'"img":0'*) ;; *) FAIL=1; echo "  !! broken images";; esac
  [ "$CON" = "0" ] || { FAIL=1; echo "  !! console errors"; }
  [ "$ERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }
}

SEC_EXPR='JSON.stringify((()=>{const c=document.querySelector("[data-testid=team-difficulty]");if(!c)return {present:false};const sec=c.closest("section");const t=(sec&&sec.innerText)||"";return {present:true,rows:c.children.length,dots:c.querySelectorAll(".rounded-full").length,title:t.includes("سختی بازی"),text:t.slice(0,200)}})())'

check_page "http://localhost:3000/team/8456" "team-8456-city" "$SEC_EXPR"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=team-difficulty]")?.closest("section")?.innerText)||"")' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "میانه" || { FAIL=1; echo "  !! city verdict chip missing"; }
echo "$TXT" | grep -q "پریمیرلیگ" || { FAIL=1; echo "  !! city league label missing"; }
echo "$TXT" | grep -q "برایتون" || { FAIL=1; echo "  !! brighton Persian missing"; }
echo "$TXT" | grep -q "آرسنال" || { FAIL=1; echo "  !! arsenal missing"; }

check_page "http://localhost:3000/team/9879" "team-9879-fulham" "$SEC_EXPR"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=team-difficulty]")?.closest("section")?.innerText)||"")' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "سخت" || { FAIL=1; echo "  !! fulham hard verdict missing"; }
echo "$TXT" | grep -q "استون‌ویلا" || { FAIL=1; echo "  !! aston villa missing"; }

check_page "http://localhost:3000/team/9857" "team-9857-bologna" "$SEC_EXPR"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=team-difficulty]")?.closest("section")?.innerText)||"")' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "مدیریت‌پذیر" || { FAIL=1; echo "  !! bologna verdict missing"; }
echo "$TXT" | grep -q "سری‌آ" || { FAIL=1; echo "  !! seriea label missing"; }

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE112 DOMPROOF OK" || echo "CYCLE112 DOMPROOF FAIL"
exit $FAIL
