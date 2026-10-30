#!/usr/bin/env bash
# cycle-166 domproof — player search (جستجوی بازیکن): the «آقای گل» pool joins
# the header search. Additive contract: /api/search keeps `results` (teams)
# untouched and adds `players` (PlayerSearchResult[] — fa/name/teamFa/leagueKey
# + /player/<id> links). The real-UI flow types a Persian query and lands on
# the player page. House pattern @390x844, console=0, empty feat FAILS.
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
api "$BASE/api/search?q=%D8%B5%DB%8C%D8%A7%D8%AF%D9%85%D9%86%D8%B4" "A1 fa-query صیادمنش → player hit لخ پوزنان|poland" "
ok=(d.get('ok') and not d.get('results') and [p for p in (d.get('players') or []) if p.get('playerId')==887680 and p.get('fa')=='اللهیار صیادمنش' and p.get('teamFa')=='لخ پوزنان' and p.get('leagueKey')=='poland'])"
api "$BASE/api/search?q=Sayyadmanesh" "A2 en-query Sayyadmanesh → same hit" "
hit=[p for p in (d.get('players') or []) if p.get('playerId')==887680 and p.get('fa')=='اللهیار صیادمنش']
ok=bool(hit)"
api "$BASE/api/search?q=%D8%B2%D8%A7%D9%87%D8%AF%DB%8C" "A3 fa-query زاهدی → شهاب زاهدی|جوهور|acl (the 153/162 first-seen attribution truth)" "
hit=[p for p in (d.get('players') or []) if p.get('fa')=='شهاب زاهدی' and p.get('teamFa')=='جوهور دارالتعظیم' and p.get('leagueKey') in ('mas','acl')]  # the pool first-seen is mas; the search overlay keeps the 153 ACL attribution truth — either is honest
ok=bool(hit)"
api "$BASE/api/search?q=%D8%B1%D8%A7%D9%81%DB%8C%D9%86%DB%8C%D8%A7" "A4 fa-query رافینیا → leader hit laliga" "
hit=[p for p in (d.get('players') or []) if p.get('fa')=='رافینیا' and p.get('leagueKey')=='laliga']
ok=bool(hit)"
api "$BASE/api/search?q=Lech" "A5 backward-compat: results untouched + players field present" "
ok=(d.get('ok') and isinstance(d.get('results'),list) and any((r.get('fa') or '')=='لخ پوزنان' for r in d.get('results') or []) and isinstance(d.get('players'),list))"
api "$BASE/api/search?q=S" "A6 short query → honest empty + message" "
ok=(d.get('ok') and d.get('results')==[] and d.get('players')==[] and bool(d.get('message')))"

echo "== PART B: DOM proof @390x844 =="
open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
}

# B1: guide copy mentions players, old team-only copy gone
open_page "$BASE/"
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 2
FEAT=$($B eval "JSON.stringify(({guide:(document.body.innerText||'').includes('تیم‌ها و آقای گل‌های ۲۴ لیگ و جام'),oldGone:!(document.body.innerText||'').includes('تیم‌های ۲۳ لیگ و جام')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B1 guide copy teams+players"

# B2: REAL Persian typing → the players section renders the صیادمنش row
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input, input');if(!i)return 'no-input';const set=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set;set.call(i,'صیادمنش');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
sleep 4
FEAT=$($B eval "JSON.stringify(({section:(document.body.innerText||'').includes('بازیکنان'),row:(document.body.innerText||'').includes('اللهیار صیادمنش'),team:(document.body.innerText||'').includes('لخ پوزنان'),league:(document.body.innerText||'').includes('اکستراکلاسا لهستان')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B2 real fa typing → player row"

# B3: click the player row → lands on /player/887680 with the Persian h1
$B eval "(function(){const b=[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').indexOf('اللهیار صیادمنش')>-1});if(b)b.click();return b?'clicked':'no-row'})()" >/dev/null 2>&1
sleep 4
FEAT=$($B eval "JSON.stringify(({url:location.pathname.indexOf('/player/887680')===0,h1:((document.querySelector('h1')||{}).innerText||'').includes('اللهیار صیادمنش')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B3 click → /player/887680"

# B4: English query rides the same UI → row + team chip
open_page "$BASE/"
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 2
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input, input');if(!i)return 'no-input';const set=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set;set.call(i,'Zahedi');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
sleep 4
FEAT=$($B eval "JSON.stringify(({row:(document.body.innerText||'').includes('شهاب زاهدی'),team:(document.body.innerText||'').includes('جوهور دارالتعظیم')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B4 en typing → زاهدی row"

echo "== RESULT =="
echo "API 6/6 + DOM 4/4 expected; BAD=$BAD"
[ "$BAD" -eq 0 ] && echo "DOM_PROOF OK (cycle-166: player search live — آقای گل‌های ۲۳ رقابت در جستجوی هدر، فارسی و انگلیسی)" || { echo "DOM_PROOF FLAGGED"; exit 1; }
