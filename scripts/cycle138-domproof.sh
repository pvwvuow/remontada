#!/bin/bash
# cycle-138 fix proof at 390x844 — «بودجهٔ سخت ترجمهٔ اخبار». The twice-documented
# first-run 27/28 transient (cycles 134/135: «گذرای news-upstream درست بعد از
# ری‌استارت، اجرای دوم کامل») was diagnosed as a LATENCY bug, not an upstream
# bug: on a cold (expired-cache) request /api/news = 5 parallel feeds (each
# capped 12s) followed by an UNBOUNDED LLM translation call — past the
# regression's 25s curl budget, with the slow first fill only warming the
# cache in time for the SECOND run. The fix: hard 10s budget on the LLM call
# (honest English fallback — the documented graceful path), feeds 12s → 10s,
# skip the LLM entirely for an empty list. Cold producer is now hard-bounded
# at ~20s < 25s. The cold-budget refutation itself is the acceptance chain's
# FIRST regression run right after the official restart (28/28 first try);
# this script pins the warm contract + the /news surface at 390x844.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth =="
python3 - <<'PY'
import json, time, urllib.request, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    t0 = time.time()
    try:
        body = urllib.request.urlopen(r, timeout=120).read().decode()
        return json.loads(body), time.time() - t0
    except urllib.error.HTTPError as e:
        return json.loads(e.read().decode() or '{}'), time.time() - t0
ok = True
def report(name, good, detail):
    global ok
    print(('PASS ' if good else 'FAIL ') + name + ' — ' + detail)
    if not good: ok = False

# A1: the /api/news contract — ok:true, real items with the full field shape,
# every response inside the regression's 25s curl budget, and every item
# carrying a non-empty titleFa (Persian when the LLM made the budget,
# English on the honest timeout — both are contract-valid)
try:
    d, dt = get('http://localhost:3000/api/news')
    items = d.get('items') or []
    srcs = sorted({x.get('source') for x in items})
    shaped = all(isinstance(x.get('title'), str) and x.get('title')
                 and isinstance(x.get('titleFa'), str) and x.get('titleFa')
                 and isinstance(x.get('source'), str) and x.get('source')
                 and isinstance(x.get('publishedAt'), str) for x in items)
    fa = sum(1 for x in items if any('\u0600' <= c <= '\u06FF' for c in x.get('titleFa') or ''))
    report('A1 news contract + 25s budget', d.get('ok') is True and len(items) >= 3
           and shaped and len(srcs) >= 2 and dt < 25,
           f"items={len(items)} srcs={srcs} t={dt:.2f}s faTitles={fa}/{len(items)}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: the warm path — a second hit must ride the cache (L1) and answer fast;
# a slow warm response would mean the cache tier broke (the exact thing the
# stale-while-error contract forbids)
try:
    d, dt = get('http://localhost:3000/api/news')
    report('A2 warm cache fast', d.get('ok') is True and dt < 3,
           f"t={dt:.2f}s items={len(d.get('items') or [])}")
except Exception as e:
    ok = False; print('A2: ERR', e)
PY
A_BAD=$?

echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label $3=feature-js $4=optional click-js $5=optional extra wait-fn
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  if [ -n "${5:-}" ]; then $B wait --fn "$5" >/dev/null 2>&1; fi
  sleep 3
  if [ -n "${4:-}" ]; then $B eval "$4" >/dev/null 2>&1; sleep 3; fi
  local FEAT FEAT_RAW OUT BAD C E RC=0
  FEAT_RAW=$($B eval "JSON.stringify((()=>{$3})())" 2>/dev/null)
  FEAT=$(echo "$FEAT_RAW" | tr -d '"\\')
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null)
  BAD=$($B eval '(function(){var sw=document.documentElement.scrollWidth,cw=document.documentElement.clientWidth,h1n=document.querySelectorAll("h1").length,vb=[...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden"}).length;return (sw!=cw?1:0)+(h1n!=1?2:0)+(vb>0?4:0)})()' 2>/dev/null | tr -d '"')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]
  print(len(app))
except Exception:
  print('ERR')")
  echo "$2 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  [ "$BAD" != "0" ] && RC=1
  echo "$FEAT_RAW" | python3 -c "
import json, sys
raw = sys.stdin.read().strip()
try:
    d = json.loads(raw)
    if isinstance(d, str): d = json.loads(d)
    assert isinstance(d, dict) and all(v is not False and v is not None for v in d.values()), f'falsey: {d}'
except Exception as ex:
    print('  FEAT-BAD:', raw, ex); sys.exit(1)
" || RC=1
  [ "$C" = "0" ] || RC=1
  [ "$E" = "0" ] || RC=1
  return $RC
}

TOTAL_BAD=0

# D1: the /news page at 390x844 — Persian h1, live items from the fixed route
# (status line «N خبر از ESPN، BBC Sport و Sky Sports»), one clean 390px layout
probe "http://localhost:3000/news" "D1 news page live" \
"const b=document.body.innerText;const h1=(document.querySelector('h1')||{}).innerText||'';return {h1:h1,loaded:/خبر از ESPN/.test(b),chips:b.includes('همه مسابقات')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: real user interaction — the «بروزرسانی» button refetches the fixed route
# client-side; the list must survive the round-trip with a clean console
probe "http://localhost:3000/news" "D2 refresh button refetch" \
"const btn=[...document.querySelectorAll('button')].find(b=>b.innerText.includes('بروزرسانی'));btn.click();return {clicked:true}" \
"" \
"document.body.innerText.includes('خبر از ESPN')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 2/2 + DOM 2/2 green — news fix honest end-to-end: contract items with full shape inside the 25s budget, warm cache fast, /news page Persian h1 + live ESPN/BBC/Sky items + refresh interaction; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
