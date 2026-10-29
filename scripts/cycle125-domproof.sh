#!/bin/bash
# cycle-125 DOM proof at 390x844 — «ویدیوی خلاصهٔ بازی» (official YouTube highlights)
# The update: matchFacts.highlights (zero-consumption since the beginning — the
# last unconsumed CONTENT block after the 124 sweep; the rest are navigation
# metadata or the declined English-prose/poll class) is now normalized with
# strict protocol guards (ONLY https youtube.com/watch links; ytimg thumbnails
# guarded separately with text-row degradation) and rendered as a compact
# header-level card under the scoreboard: external link (new tab, noopener),
# onError-hide thumbnail (site-wide pattern — vbroken=0 invariant preserved),
# honest source label. Probed at cycle-125 time: featured finished matches only
# (5071457 + 5795486 have it, 5071463 did not) → honest-hide contract (legend-111).
# DRIFT NOTE (cycle-129, 2026-10-29): upstream FotMob has since ATTACHED a
# highlight to 5071463 (verified via the local signed API — the direct fotmob
# fetch is unsigned/blocked); the product correctly surfaces it. B2 was frozen
# to "absence" and rotted — it is now DRIFT-AWARE: the API is queried first and
# the DOM must be CONSISTENT with it (card present with the full contract iff
# the API has highlights, honestly absent iff not). The invalid-id 400 case
# keeps the honest-error contract covered.
# Proof: (A) API truth — both branches + the invalid-id contract;
# (B) DOM — the card renders on a match that has the block (with the youtube
# href + target=_blank + thumbnail) and matches the API on the drift-aware one;
# 390x844: sw=cw, exactly 1 h1, 0 broken images, console=0, appErr=0 (bitmask
# 1=overflow 2=h1!=1 4=broken imgs; cycle-108 url convention).
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    return json.load(urllib.request.urlopen(r, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
try:
    d = get('http://localhost:3000/api/match/5071457')
    h = d.get('highlights') or {}
    report('5071457 highlights', d.get('ok') is True
           and str(h.get('url','')).startswith('https://www.youtube.com/watch')
           and str(h.get('image','')).startswith('https://i.ytimg.com/')
           and h.get('source') == 'www.youtube.com',
           f"url={str(h.get('url'))[:52]}... img={str(h.get('image'))[:40]}...")
except Exception as e:
    report('5071457 highlights', False, str(e)[:90])
try:
    d = get('http://localhost:3000/api/match/5071463')
    hl = d.get('highlights') or {}
    has_hl = isinstance(hl, dict) and str(hl.get('url', '')).startswith('https://www.youtube.com/watch')
    # drift-aware: ok is the contract; presence is DATA (upstream may attach/detach)
    report('5071463 API truth (drift-aware, highlights=%s)' % has_hl, d.get('ok') is True,
           f"ok={d.get('ok')} highlights={d.get('highlights')}")
    open('/home/z/my-project/.c125-b2-state', 'w').write('has' if has_hl else 'absent')
except Exception as e:
    report('5071463 API truth (drift-aware)', False, str(e)[:90])
    open('/home/z/my-project/.c125-b2-state', 'w').write('absent')
try:
    urllib.request.urlopen('http://localhost:3000/api/match/badid', timeout=20)
    report('invalid-id 400', False, 'expected 400, got 200')
except urllib.error.HTTPError as e:
    report('invalid-id 400', e.code == 400, f"{e.code}")
except Exception as e:
    report('invalid-id 400', False, str(e)[:90])
print("API_TRUTH " + ("OK" if ok else "BAD"))
PY

echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local OUT BAD C E RC=0
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
  echo "$2 → $OUT | console=$C appErrors=$E"
  [ "$BAD" != "0" ] && RC=1
  [ "$E" != "0" ] && RC=1
  return $RC
}
TOTAL_BAD=0

# B1: match WITH the block — card renders with the guarded link + thumbnail
probe "http://localhost:3000/match/5071457" "B1 /match/5071457 (has highlights)" \
  || { echo "   ⚠ B1 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
B1B=$($B eval 'JSON.stringify((()=>{const a=document.querySelector("a[aria-label=\"ویدیوی خلاصهٔ بازی (یوتیوب)\"]");if(!a)return {card:false};const txt=a.innerText||"";const img=a.querySelector("img");return {card:true,href:(a.getAttribute("href")||"").startsWith("https://www.youtube.com/watch"),targetBlank:a.getAttribute("target")==="_blank",relSafe:(a.getAttribute("rel")||"").includes("noopener"),label:txt.includes("ویدیوی خلاصهٔ بازی"),source:txt.includes("یوتیوب"),hasImg:!!img,imgVisible:img?getComputedStyle(img).visibility!=="hidden":false}})())' 2>/dev/null | tr -d '"\\')
echo "B1b highlights card → $B1B"
echo "$B1B" | grep -q 'card:true' && echo "$B1B" | grep -q 'href:true' && echo "$B1B" | grep -q 'targetBlank:true' \
  && echo "$B1B" | grep -q 'relSafe:true' && echo "$B1B" | grep -q 'label:true' && echo "$B1B" | grep -q 'source:true' \
  || { echo "   ⚠ B1b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B2: API↔DOM CONSISTENCY (drift-aware since cycle-129 — upstream FotMob may
# attach highlights to a previously highlight-less match (it did for 5071463);
# the page must MATCH the API: card with the full contract iff API has it)
B2_STATE=$(cat /home/z/my-project/.c125-b2-state 2>/dev/null || echo absent)
if [ "$B2_STATE" = "has" ]; then
  probe "http://localhost:3000/match/5071463" "B2 /match/5071463 (API has highlights → card expected)" \
    || { echo "   ⚠ B2 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
  B2B=$($B eval 'JSON.stringify((()=>{const a=document.querySelector("a[aria-label=\"ویدیوی خلاصهٔ بازی (یوتیوب)\"]");if(!a)return {card:false};const txt=a.innerText||"";const img=a.querySelector("img");return {card:true,href:(a.getAttribute("href")||"").startsWith("https://www.youtube.com/watch"),targetBlank:a.getAttribute("target")==="_blank",relSafe:(a.getAttribute("rel")||"").includes("noopener"),label:txt.includes("ویدیوی خلاصهٔ بازی"),source:txt.includes("یوتیوب"),hasImg:!!img,imgVisible:img?getComputedStyle(img).visibility!=="hidden":false}})())' 2>/dev/null | tr -d '"\\')
  echo "B2b consistency (API=has) → $B2B"
  echo "$B2B" | grep -q 'card:true' && echo "$B2B" | grep -q 'href:true' && echo "$B2B" | grep -q 'targetBlank:true' \
    && echo "$B2B" | grep -q 'relSafe:true' && echo "$B2B" | grep -q 'label:true' && echo "$B2B" | grep -q 'source:true' \
    || { echo "   ⚠ B2b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
else
  probe "http://localhost:3000/match/5071463" "B2 /match/5071463 (API has no highlights → honest absence)" \
    || { echo "   ⚠ B2 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
  B2B=$($B eval 'JSON.stringify((()=>{return {cardAbsent:!document.querySelector("a[aria-label=\"ویدیوی خلاصهٔ بازی (یوتیوب)\"]")}})())' 2>/dev/null | tr -d '"\\')
  echo "B2b absence (API=absent) → $B2B"
  echo "$B2B" | grep -q 'cardAbsent:true' \
    || { echo "   ⚠ B2b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
fi

# B3: second WITH match (5795486 — ars-vs-avl, the lineup-card fixture)
probe "http://localhost:3000/match/5795486" "B3 /match/5795486 (has highlights)" \
  || { echo "   ⚠ B3 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
B3B=$($B eval 'JSON.stringify((()=>{const a=document.querySelector("a[aria-label=\"ویدیوی خلاصهٔ بازی (یوتیوب)\"]");return {card:!!a}})())' 2>/dev/null | tr -d '"\\')
echo "B3b presence → $B3B"
echo "$B3B" | grep -q 'card:true' \
  || { echo "   ⚠ B3b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

echo "==="
echo "FLAGGED_PAGES=$TOTAL_BAD of 3 (B1b/B2b/B3b counted separately)"
if [ "$TOTAL_BAD" = "0" ]; then
  echo "CYCLE125 UPDATE PROOF OK"
else
  echo "CYCLE125 UPDATE PROOF BAD"
fi
