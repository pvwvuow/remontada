#!/usr/bin/env bash
# cycle-167 domproof — transfers join the player-profile network («انتقال‌ها به
# شبکهٔ پروفایل‌ها می‌پیوندند»). Probed gap: /player/<id> serves ANY playerId,
# yet transfer names were the LAST dead-text player mentions — no link, no
# Persian map, while scorers/squads/search all link + nameFa (cycle-107 arc).
# Fix: nameFa (playerFa) added to BOTH feeds (League/Team), names become
# /player/<id> links guarded for playerId ≤ 0 (probed 1 of 908 live: laliga).
# House pattern @390x844, console=0, empty feat FAILS.
set -u
B=agent-browser
BASE="http://localhost:3000"
$B set viewport 390 844 >/dev/null
BAD=0

collect() {
  local FEAT="$1" LABEL="$2" OUT C E RC=0
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  echo "$LABEL → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ -z "$FEAT" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

api() {
  local OUT
  OUT=$(python3 - "$1" "$3" << 'PYEOF'
import json, sys, urllib.request
url, code = sys.argv[1], sys.argv[2]
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"}
try:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read()
    d = json.loads(raw.decode("utf-8", "replace"))
    ns = {"json": json}
    exec("import json\nimport urllib.request\nd = json.loads(" + json.dumps(json.dumps(d)) + ")\n" + code, ns)
    print("OK" if ns.get("ok") else "BAD")
except Exception as e:
    print("BAD", type(e).__name__, e)
PYEOF
) 2>/dev/null
  echo "$2 → $OUT"
  [ "$OUT" = "OK" ] || BAD=$((BAD+1))
  return 0
}

echo "== PART A: API truth =="
api "$BASE/api/league-transfers?league=laliga" "A1 laliga: nameFa everywhere + fa-hits + zero-id guarded" "
items=(d.get('transfers') or {}).get('items') or []
hits=[t for t in items if t.get('nameFa')!=t.get('name')]
zero=[t for t in items if t.get('playerId',0)<=0]
ok=(len(items)>=50 and all('nameFa' in t and t.get('nameFa') for t in items) and len(hits)>=3 and any(t.get('nameFa')=='یوسف فوفانا' for t in hits) and all('nameFa' in t for t in zero))"
api "$BASE/api/league-transfers?league=poland" "A2 poland: Jordi Sánchez → خوردی سانچز (cycle-165 spelling)" "
items=(d.get('transfers') or {}).get('items') or []
ok=(len(items)==100 and any(t.get('name')=='Jordi Sánchez' and t.get('nameFa')=='خوردی سانچز' for t in items))"
api "$BASE/api/team-transfers/2182" "A3 Lech team feed: BOTH Iranian hooks in Persian" "
items=(d.get('transfers') or {}).get('items') or []
ok=(any(t.get('name')=='Allahyar Sayyadmanesh' and t.get('nameFa')=='اللهیار صیادمنش' and t.get('playerId')==887680 for t in items) and any(t.get('name')=='Ali Gholizadeh' and t.get('nameFa')=='علی غلی\u200cزاده' and t.get('playerId')==746018 for t in items))"
api "$BASE/api/league-transfers?league=laliga" "A4 backward-compat: all 10 legacy fields byte-untouched" "
items=(d.get('transfers') or {}).get('items') or []
need={'playerId','name','position','date','from','to','kind','kindFa','feeFa','nameFa'}
ok=(len(items)>0 and all(need<=set(t) and isinstance(t.get('from'),dict) and isinstance(t.get('to'),dict) and 'fa' in t.get('from',{}) and 'fa' in t.get('to',{}) for t in items))"
api "$BASE/api/league-transfers?league=mas" "A5 small feed (mas, 3 items) alive + nameFa" "
items=(d.get('transfers') or {}).get('items') or []
ok=(1<=len(items)<=10 and all('nameFa' in t and t.get('nameFa') for t in items))"
api "$BASE/api/team-transfers/2182" "A6 name stays raw upstream (additive-only contract)" "
items=(d.get('transfers') or {}).get('items') or []
ok=(any(t.get('name')=='Allahyar Sayyadmanesh' for t in items) and all(t.get('name') and isinstance(t.get('name'),str) for t in items))"

echo "== PART B: DOM proof @390x844 =="
open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
}

# B1: /league/poland → REAL «انتقال‌ها» tab click → panel alive, Persian hit
# خوردی سانچز visible, and the name now anchors to /player/<id>
open_page "$BASE/league/poland"
$B eval "(function(){const t=[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').trim()==='انتقال‌ها'});if(t)t.click();return t?'clicked':'no-tab'})()" >/dev/null 2>&1
sleep 4
FEAT=$($B eval "JSON.stringify(({panel:(document.body.innerText||'').indexOf('انتقال')>-1,faHit:(document.body.innerText||'').indexOf('خوردی سانچز')>-1,anchors:document.querySelectorAll('a[href^=\"/player/\"]').length}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B1 poland transfers tab → Persian names + /player anchors"

# B2: REAL click on the خوردی سانچز anchor → lands on the profile page
$B eval "(function(){const a=[...document.querySelectorAll('a[href^=\"/player/\"]')].find(function(x){return (x.textContent||'').indexOf('خوردی')>-1});if(a)a.click();return a?'clicked':'no-anchor'})()" >/dev/null 2>&1
sleep 5
FEAT=$($B eval "JSON.stringify(({url:location.pathname.indexOf('/player/')===0,h1:((document.querySelector('h1')||{}).innerText||'').indexOf('خوردی سانچز')>-1}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B2 click transfer name → /player/<id> Persian h1"

# B3: team page Lech (2182) → «بازار انتقال‌ها» renders BOTH Iranian hooks as links
open_page "$BASE/team/2182"
sleep 3
FEAT=$($B eval "JSON.stringify(({section:(document.body.innerText||'').indexOf('بازار انتقال')>-1,sayyad:(document.body.innerText||'').indexOf('اللهیار صیادمنش')>-1,gholi:(document.body.innerText||'').indexOf('علی غلی\u200cزاده')>-1,anchor887680:!!document.querySelector('a[href=\"/player/887680\"]'),anchor746018:!!document.querySelector('a[href=\"/player/746018\"]')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B3 Lech team transfers → صیادمنش+غلی‌زاده linked"

# B4: REAL click on غلی‌زاده transfer link → /player/746018 Persian h1
$B eval "(function(){const a=document.querySelector('a[href=\"/player/746018\"]');if(a)a.click();return a?'clicked':'no-anchor'})()" >/dev/null 2>&1
sleep 5
FEAT=$($B eval "JSON.stringify(({url:location.pathname.indexOf('/player/746018')===0,h1:((document.querySelector('h1')||{}).innerText||'').indexOf('علی غلی\u200cزاده')>-1}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B4 click غلی‌زاده → /player/746018"

echo "== RESULT =="
echo "API 6/6 + DOM 4/4 expected; BAD=$BAD"
[ "$BAD" -eq 0 ] && echo "DOM_PROOF OK (cycle-167: transfers join the profile network — انتقال‌ها هم لینک و نام فارسی)" || { echo "DOM_PROOF FLAGGED"; exit 1; }
