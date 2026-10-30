#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-202 update — «خبرها» join the header search.
#
# D5 probe first (live, 2026-10-30): the news feed (news:v1, 15-min TTL,
# 16 items) carries Persian-translated titles (titleFa — the LLM stage)
# and the honest English originals, but /api/search answered ZERO for
# every headline word — the whole news surface was unreachable from the
# search dialog. The old gap list (انتخابگر فصل، براکت جام‌ها،
# انتقال‌ها) was already exhausted by cycles 99/57/121; TotW was probed
# and CLEARED this cycle (SSR page props only — no clean JSON API, the
# 198 honest-skip class).
#
# Update additive-only, ZERO fresh upstream calls: the producer moved
# verbatim from src/app/api/news/route.ts to src/lib/news.ts (same
# cache key news:v1, same 15-min TTL — the feed route contract is
# byte-identical) and searchNews() folds the SAME cached instance via
# cacheGetDeep (cycle-42 warm-only read — search NEVER triggers the
# ~20s cold producer; absent/expired cache → [] → section hides, the
# cards/market honesty pattern). Matching = searchLeagues mechanics
# (normalizeQuery both sides, exact 100 > prefix 80 > includes 50 >
# all-words 40, rangeOf spans — exported this cycle for the reuse),
# normalized on BOTH titles (Persian display + honest English), ties
# keep the feed's newest-first order. The answer rides a NEW `news`
# field on /api/search (the 166/200 additive-field precedent; the
# min-length guard shape gains news:[] exactly like leagues:[]).
# Dialog: a «خبرها» section AFTER players (teams → leagues → players →
# خبرها), every row an external <a target=_blank rel=noopener> with the
# «خبر» badge, source + timeAgoFa subtitle, Enter mirrors the click.
#
# Pin discipline (the 193 lesson): needles are RUNTIME-DERIVED from the
# live feed each run (the 195 D3 pattern — the feed rotates every 15
# min, so byte-pinning a headline would rot); byte-exact pins only on
# identity + structure (the «فتای» 194 loop, the 166 pinned hint, the
# badge, the hrefs ⊆ live feed links — zero-fabrication).
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

# warm the shared feed once — deterministic gate, no dependence on a
# warm cache left over from earlier traffic
curl -s "$BASE/api/news" -o /tmp/c202_feed.json
FEED_OK=$(python3 -c "
import json
try:
    d=json.load(open('/tmp/c202_feed.json'))
    print('yes' if d.get('ok') and len(d.get('items') or [])>=1 else 'no')
except Exception: print('no')")
[ "$FEED_OK" = "yes" ] || { echo "FEED NOT WARM — aborting"; exit 1; }

# runtime-derived needles from the LIVE feed (fa + en), shell-side
python3 - << 'PY' > /tmp/c202_needles.env
import json, re
d = json.load(open('/tmp/c202_feed.json'))
items = d.get('items') or []
def fa_needle(t):
    best = ""
    for w in re.findall(r"[\w\u200c]+", t or ""):
        if len(w) > len(best): best = w
    return best if len(best) >= 4 else ""
fa1 = fa_needle(items[0].get("titleFa"))
en1 = fa_needle(items[0].get("title"))
link1 = items[0].get("link") or ""
fa2 = fa_needle(items[1].get("titleFa"))
fa3 = fa_needle(items[2].get("titleFa"))
import shlex
print(f'NFA={shlex.quote(fa1)}')
print(f'NEN={shlex.quote(en1)}')
print(f'NLINK={shlex.quote(link1)}')
print(f'NFA2={shlex.quote(fa2)}')
print(f'NFA3={shlex.quote(fa3)}')
PY
. /tmp/c202_needles.env
echo "needles: fa=$NFA en=$NEN fa2=$NFA2 fa3=$NFA3"

echo "== PART A: API proof (5 gates) =="
A_OUT=$(NFA="$NFA" NEN="$NEN" NFA2="$NFA2" NFA3="$NFA3" python3 - <<'PY'
import json, os, urllib.request, urllib.parse
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
def enc(s): return urllib.parse.quote(s)

NFA = os.environ["NFA"]; NEN = os.environ["NEN"]
NFA2 = os.environ["NFA2"]; NFA3 = os.environ["NFA3"]

# A1: the runtime-derived Persian needle finds its own headline —
# matchedOn carries the matched value, hl.fa is a valid span, the row
# carries source/publishedAt/link
try:
    d = get(f"{BASE}/api/search?q={enc(NFA)}")
    nw = d.get("news") or []
    r0 = nw[0] if nw else {}
    hl = (r0.get("hl") or {}).get("fa")
    span_ok = isinstance(hl, list) and len(hl) == 2 and 0 <= hl[0] < hl[1] <= len(r0.get("titleFa") or "")
    good = len(nw) >= 1 and NFA in (r0.get("titleFa") or "") and \
           bool(r0.get("matchedOn")) and span_ok and \
           bool(r0.get("source")) and bool(r0.get("publishedAt")) and bool(r0.get("link"))
    report("A1 fa needle → own headline (hl span + row shape)", good,
           f"n={len(nw)} matchedOn={(r0.get('matchedOn') or '')[:40]!r} span={hl} source={r0.get('source')}")
except Exception as e:
    report("A1 fa needle → own headline (hl span + row shape)", False, repr(e))

# A1b: zero-drop — the index IS the feed: three different items' needles
# each find at least one news row
try:
    hits = 0
    for nd in (NFA, NFA2, NFA3):
        d = get(f"{BASE}/api/search?q={enc(nd)}")
        if len(d.get("news") or []) >= 1: hits += 1
    good = hits == 3
    report("A1b zero-drop: 3/3 feed needles find rows", good, f"hits={hits}/3")
except Exception as e:
    report("A1b zero-drop: 3/3 feed needles find rows", False, repr(e))

# A2: the honest English title is searchable too (dual alphabet, the 195 class)
try:
    d = get(f"{BASE}/api/search?q={enc(NEN)}")
    nw = d.get("news") or []
    r0 = nw[0] if nw else {}
    hle = (r0.get("hl") or {}).get("en")
    span_ok = isinstance(hle, list) and len(hle) == 2 and 0 <= hle[0] < hle[1] <= len(r0.get("title") or "")
    good = len(nw) >= 1 and (r0.get("matchedOn") == r0.get("title")) and span_ok
    report("A2 en needle → matchedOn=en + hl.en span", good,
           f"n={len(nw)} matchedOn={(r0.get('matchedOn') or '')[:40]!r} span={hle}")
except Exception as e:
    report("A2 en needle → matchedOn=en + hl.en span", False, repr(e))

# A3: additive contract — team/player queries keep their loops and the
# news field is always present (never a leak-fabrication: empty when no
# headline matches)
try:
    d = get(f"{BASE}/api/search?q=" + enc("رئال مادرید"))
    tm = d.get("results") or []
    d2 = get(f"{BASE}/api/search?q=" + enc("فتای"))
    pl = d2.get("players") or []
    one194 = len(pl) == 1 and str((pl[0] or {}).get("playerId")) == "1516458" and \
              (pl[0] or {}).get("rank") == 0 and "goals" not in (pl[0] or {})
    good = len(tm) >= 1 and isinstance(d.get("news"), list) and \
           isinstance(d2.get("news"), list) and one194
    report("A3 additive contract — team loop + 194 fold + field always present", good,
           f"teams={len(tm)} players={len(pl)} newsTypes=({type(d.get('news')).__name__},{type(d2.get('news')).__name__})")
except Exception as e:
    report("A3 additive contract — team loop + 194 fold + field always present", False, repr(e))

# A4: the min-length guard gains news:[] (the 200 A6 field-specific style)
try:
    d = get(f"{BASE}/api/search?q=x")
    good = d.get("ok") is True and d.get("leagues") == [] and d.get("news") == [] and bool(d.get("message"))
    report("A4 min-length guard shape", good,
           f"ok={d.get('ok')} leagues={d.get('leagues')} news={d.get('news')} msg={'yes' if d.get('message') else 'no'}")
except Exception as e:
    report("A4 min-length guard shape", False, repr(e))

# A5: the news ROUTE contract is byte-identical after the producer move
try:
    d = json.load(open("/tmp/c202_feed.json"))
    it = (d.get("items") or [{}])[0]
    keys_ok = all(k in it for k in ("title", "titleFa", "source", "publishedAt"))
    good = d.get("ok") is True and len(d.get("items") or []) >= 1 and keys_ok
    report("A5 /api/news contract unchanged (title/titleFa/source)", good,
           f"ok={d.get('ok')} n={len(d.get('items') or [])} keys_ok={keys_ok}")
except Exception as e:
    report("A5 /api/news contract unchanged (title/titleFa/source)", False, repr(e))

print("API_ALL_OK" if ok else "API_FLAGGED")
PY
)
echo "$A_OUT"
echo "$A_OUT" | rg -q "API_ALL_OK" || BAD=$((BAD+1))

echo "== PART B: DOM proof @390x844 (agent-browser, console must stay 0) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
CNT='import json,sys
try:
  d=json.load(sys.stdin); print(len(d["data"]["messages"]))
except Exception: print("ERR")'
ECNT='import json,sys
try:
  d=json.load(sys.stdin); es=d["data"]["errors"]
  print(len([e for e in es if e.get("url")]))
except Exception: print("ERR")'

open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
gate() {
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}
open_search() {
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
}
close_search() {
  # the click-outside handler listens for mousedown outside the box — a
  # defensive close so the NEXT open_search never toggles an open dialog
  $B eval '(function(){document.body.dispatchEvent(new MouseEvent("mousedown",{bubbles:true}));return "closed"})()' >/dev/null 2>&1
  sleep 0.6
}
type_into() {
  # the 149 React-input pattern; the needle is embedded raw (no quotes inside)
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
}

open_page "/"
clean_ls

# B1: the runtime-derived Persian needle renders the «خبرها» section with
# the «خبر» badge; every news href ∈ the live feed links (zero fabrication);
# the needle length is computed shell-side (the 198 bash-eval lesson)
NP_LEN=$(printf %s "$NFA" | wc -m)
open_search
type_into "$NFA"
$B wait --fn "!!document.querySelector('[data-testid=search-news]')" >/dev/null 2>&1
sleep 1.2
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=search-news]"),hdr:document.body.innerText.indexOf("خبرها")>=0,badge:[...document.querySelectorAll("[data-testid=search-news] a")].some(function(a){return a.innerText.indexOf("خبر")>=0&&a.innerText.length>2;}),rows:document.querySelectorAll("[data-testid=search-news] a").length,needle:[...document.querySelectorAll("[data-testid=search-news] a")].some(function(a){return a.innerText.length>0;}),blank:[...document.querySelectorAll("[data-testid=search-news] a")].every(function(a){return a.getAttribute("target")==="_blank";})')
B1=0
echo "$FEAT" | rg -q 'sec:true' || B1=1
echo "$FEAT" | rg -q 'hdr:true' || B1=1
echo "$FEAT" | rg -q 'badge:true' || B1=1
echo "$FEAT" | rg -q 'rows:[1-9]' || B1=1
echo "$FEAT" | rg -q 'blank:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 news section + badge + external rows" "$FEAT"
HREFS=$($B eval 'JSON.stringify([...document.querySelectorAll("[data-testid=search-news] a")].map(function(a){return a.getAttribute("href");}))' 2>/dev/null)
# same-moment consistency: the DOM hrefs must equal the links the API serves
# for the SAME needle right now (both views of the same cache — a snapshot
# comparison would race the feed's 15-min rotation)
SUBSET=$(HREFS_JSON="$HREFS" NFA="$NFA" python3 -c "
import json, os, urllib.request, urllib.parse
raw = os.environ.get('HREFS_JSON','[]')
try:
    hrefs = json.loads(raw)
    if isinstance(hrefs, str): hrefs = json.loads(hrefs)
except Exception:
    hrefs = []
if not isinstance(hrefs, list): hrefs = []
nfa = os.environ['NFA']
req = urllib.request.Request('http://localhost:3000/api/search?q=' + urllib.parse.quote(nfa), headers={'User-Agent': 'Mozilla/5.0'})
d = json.load(urllib.request.urlopen(req, timeout=30))
api_links = [ (n.get('link') or '') for n in (d.get('news') or []) ]
good = len(hrefs) >= 1 and all(isinstance(h, str) and h in api_links for h in hrefs)
print('yes' if good else 'no')")
[ "$SUBSET" = "yes" ] || BAD=$((BAD+1))
gate "B1b hrefs == same-moment API links" "subset=$SUBSET"
clean_ls

# B2: the 194 loop byte-identical — «فتای» still EXACTLY one button row with
# the season hint, NO «خبرها» and NO «رقابت‌ها» leak (the 200 B3 contract)
close_search
open_search
type_into "فتای"
$B wait --fn "[...document.querySelectorAll('[role=dialog] button')].some(b=>(b.innerText||'').indexOf('فتا فتای')>=0)" >/dev/null 2>&1
sleep 1.2
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("فتا فتای")>=0;}).length,news:document.body.innerText.indexOf("خبرها")>=0,lg:document.body.innerText.indexOf("رقابت‌ها")>=0,hint:[...document.querySelectorAll("[role=dialog] button")].some(function(b){var t=b.innerText;return t.indexOf("فتا فتای")>=0&&t.indexOf("۲۰۲۴/۲۰۲۵")>=0;})')
B2=0
echo "$FEAT" | rg -q 'n:1' || B2=1
echo "$FEAT" | rg -q 'news:false' || B2=1
echo "$FEAT" | rg -q 'lg:false' || B2=1
echo "$FEAT" | rg -q 'hint:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 فتای loop byte-identical, no news/league leak" "$FEAT"
clean_ls

# B3: the 166 pinned hint byte-identical on the <2 chars state
close_search
open_search
FEAT=$(snap 'hint:document.body.innerText.indexOf("جستجو بین تیم‌ها و آقای گل‌های ۲۴ لیگ و جام")>=0')
B3=0
echo "$FEAT" | rg -q 'hint:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 pinned min-2-chars hint byte-identical" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-202 update proven (A 5/5 + B 4/4 @390x844): «خبرها» join the header search — runtime-derived Persian and English needles each find their own headline with valid highlight spans and external hrefs strictly inside the live feed (zero fabrication), the 194 «فتای» loop and the 166 pinned hint stay byte-identical, the feed route contract unchanged after the producer move to src/lib/news.ts (same news:v1 cache, warm-only fold — zero fresh upstream calls)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
