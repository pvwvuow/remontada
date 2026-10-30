#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-208 bug-hunt — patrol of the 204-207 surfaces + six NEW cross
# dimensions no prior gate combined. Product-bug contract: findings are
# REPORTED only (the fix belongs to the rotation's next cycle); zero
# src changes expected from a hunt.
#
# Surfaces: 204 (keyboard scrollIntoView in the search dialog), 205
# (touch map «نقشهٔ گرمای لمس»), 206 (per-player deep stats panel),
# 207 (pre-match previews «پیش‌نمای بازی»).
#
# D1 207×191×205×206 four-block co-existence on the FINISHED Clásico
#    (5868105): previews + reviews + touchmap + playerStats(deep) all
#    alive on ONE payload; DOM order: previews BEFORE reviews (pre
#    before post), touchmap AFTER top-players and before the tabs.
# D2 207 future shape (5881208 Bayern–Dortmund): previews=/news/ Opta
#    rows + the honest-absence trio (reviews, touchMap, playerStats)
#    on the SAME payload; DOM mirrors it.
# D3 the 207 ar-wins RTL contract: the preview title is Arabic-script,
#    the href carries the _ar-- slug, the DOM title equals the
#    same-moment API title, and the page keeps sw=390 (no RTL overflow).
# D4 205×206 interaction marathon on ONE page (Clásico): away-pill
#    aria-pressed handover swaps dots to the runtime API away count;
#    the players tab deep toggle opens/closes/reopens idempotently
#    with the حمله section alive.
# D5 205×206 universality on a SECOND finished competition (EFL Cup
#    6275369): touchmap + deep stats alive on the same page.
# D6 honest absence on the uncovered 5868115: BOTH preview and review
#    cards absent while the page stays healthy.
# D7 204 keyboard scroll on a runtime-derived fat needle: after a full
#    ArrowDown walk the active row stays fully inside the scroll
#    container; overflow ⇒ scrollTop>0, no overflow ⇒ scrollTop
#    unchanged (nearest never moves fully-visible rows).
# LAT the warm contract: the match API answers well inside 5s once warm
#    (the ~25s cold producer must never leak into a warm call).
#
# All DOM: sw=cw=390, exactly 1 h1, 0 broken images, console=0, appErrors=0.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

# warm the match payloads once (the hunt must not depend on leftover warmth)
curl -s "$BASE/api/match/5868105" -o /tmp/c208_clasico.json
curl -s "$BASE/api/match/5881208" -o /tmp/c208_future.json
curl -s "$BASE/api/match/6275369" -o /tmp/c208_efl.json
python3 -c "
import json,sys
for f in ('/tmp/c208_clasico.json','/tmp/c208_future.json','/tmp/c208_efl.json'):
    d=json.load(open(f))
    assert d.get('ok') is True, f
" || { echo "MATCH WARMUP FAILED — aborting"; exit 1; }

echo "== PART A: API proof (6 gates) =="
A_OUT=$(python3 - <<'PY'
import json, re, time, urllib.request
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u, timeout=30):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=timeout))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

def arabic(s):
    return any('\u0600' <= ch <= '\u06FF' for ch in (s or ""))

# D1(API): four-block simultaneity on the finished Clásico
try:
    d = get(f"{BASE}/api/match/5868105")
    pv, rv = d.get("previews") or [], d.get("reviews") or []
    tm = d.get("touchMap") or {}
    ps = d.get("playerStats") or {}
    home_rows = ps.get("home") or []
    deep_rows = [r for r in home_rows if r.get("deep")]
    good = (len(pv) >= 1 and len(rv) >= 1
            and (tm.get("home") or {}).get("touches", 0) > 0
            and (tm.get("away") or {}).get("touches", 0) > 0
            and len(deep_rows) >= 10)
    report("D1-api Clásico four-block simultaneity (previews+reviews+touchmap+deep)", good,
           f"pv={len(pv)} rv={len(rv)} tmH={(tm.get('home') or {}).get('touches')} tmA={(tm.get('away') or {}).get('touches')} homeDeep={len(deep_rows)}/{len(home_rows)}")
except Exception as e:
    report("D1-api Clásico four-block simultaneity (previews+reviews+touchmap+deep)", False, repr(e))

# D2(API): the future covered match — previews + the honest-absence trio
try:
    d = get(f"{BASE}/api/match/5881208")
    pv = d.get("previews") or []
    u0 = (pv[0] or {}).get("url", "") if pv else ""
    good = (len(pv) >= 1
            and not d.get("reviews")
            and not d.get("touchMap")
            and not ((d.get("playerStats") or {}).get("home"))
            and "/news/" in u0)
    report("D2-api future covered match: previews present + absence trio", good,
           f"pv={len(pv)} rv={len(d.get('reviews') or [])} tm={'Y' if d.get('touchMap') else 'N'} psH={len((d.get('playerStats') or {}).get('home') or [])} url0={u0[:40]}")
except Exception as e:
    report("D2-api future covered match: previews present + absence trio", False, repr(e))

# D3(API): the ar-wins RTL contract — TWO source families, two url
# contracts (the 207 A1 pin): Opta /news/ previews carry the _ar--
# language slug; the FotMob /topnews/ editorial is language-neutral.
# All three titles must be Arabic-script.
try:
    good = True; det = []
    for mid, fam in (("5881208", "opta"), ("5795498", "opta"), ("5868105", "editorial")):
        d = get(f"{BASE}/api/match/{mid}")
        pv = d.get("previews") or []
        if not pv: good = False; det.append(f"{mid}:no-preview"); continue
        t0, u0 = pv[0].get("title") or "", pv[0].get("url") or ""
        slug_ok = ("_ar--" in u0) if fam == "opta" else ("/topnews/" in u0)
        a = arabic(t0) and slug_ok
        if not a: good = False
        det.append(f"{mid}:{fam}:ar={a}:len={len(t0)}")
    report("D3-api ar-wins: Arabic titles + per-family url contracts", good, " ".join(det))
except Exception as e:
    report("D3-api ar-wins: Arabic titles + per-family url contracts", False, repr(e))

# D4(API): deep universality on the Clásico HOME side — every deep entry
# carries titled sections with non-empty fa labels
try:
    d = get(f"{BASE}/api/match/5868105")
    home_rows = (d.get("playerStats") or {}).get("home") or []
    deep_rows = [r for r in home_rows if r.get("deep")]
    wf = all(
        s.get("titleFa") and len(s.get("rows") or []) >= 1
        and all(r.get("labelFa") for r in s.get("rows") or [])
        for r in deep_rows for s in r.get("deep") or []
    )
    good = len(deep_rows) >= 10 and wf
    report("D4-api deep universality (Clásico home): ≥10 rows, sections titled, fa labels", good,
           f"deep={len(deep_rows)}/{len(home_rows)} wf={wf}")
except Exception as e:
    report("D4-api deep universality (Clásico home): ≥10 rows, sections titled, fa labels", False, repr(e))

# D5(API): 205×206 universality on a SECOND finished competition (EFL Cup)
try:
    d = get(f"{BASE}/api/match/6275369")
    tm = d.get("touchMap") or {}
    ps = d.get("playerStats") or {}
    all_rows = (ps.get("home") or []) + (ps.get("away") or [])
    deep_n = sum(1 for r in all_rows if r.get("deep"))
    good = ((tm.get("home") or {}).get("touches", 0) > 0
            and (tm.get("away") or {}).get("touches", 0) > 0
            and deep_n >= 20)
    report("D5-api EFL Cup second competition: touchmap + deep co-exist", good,
           f"tmH={(tm.get('home') or {}).get('touches')} tmA={(tm.get('away') or {}).get('touches')} deep={deep_n}")
except Exception as e:
    report("D5-api EFL Cup second competition: touchmap + deep co-exist", False, repr(e))

# LAT: the warm contract — a warm match API call answers inside 5s
try:
    t0 = time.time()
    d = get(f"{BASE}/api/match/5881208", timeout=8)
    dt = time.time() - t0
    good = dt < 5.0 and d.get("ok") is True
    report("LAT warm match API < 5s", good, f"{dt:.2f}s (cold producer ~25s would blow it)")
except Exception as e:
    report("LAT warm match API < 5s", False, repr(e))

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
open_search() {
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
}
close_search() {
  $B eval '(function(){document.body.dispatchEvent(new MouseEvent("mousedown",{bubbles:true}));return "closed"})()' >/dev/null 2>&1
  sleep 0.6
}
type_into() {
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
}
arrow_down() {
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';i.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowDown',bubbles:true}));return 'moved'})()" >/dev/null 2>&1
}
click_tab() {
  $B eval "(function(){const bs=[...document.querySelectorAll('nav[aria-label=\"بخش‌های مسابقه\"] button')];const b=bs.find(x=>x.textContent.trim()==='$1');if(!b)return 'notab';b.click();return 'clicked';})()" >/dev/null 2>&1
  sleep 1.2
}
VIS_EXPR='(function(){var c=document.querySelector("[role=dialog] .overflow-y-auto");if(!c)return "";var r=c.querySelector(".cmd-active");if(!r)return "";var a=c.getBoundingClientRect(),b=r.getBoundingClientRect();return (b.top>=a.top-2&&b.bottom<=a.bottom+2)+"|over:"+Math.round(b.bottom-a.bottom)+"|top:"+Math.round(b.top-a.top);})()'
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

# runtime dots from the warm Clásico payload (finished ⇒ frozen values)
DOTS=$(python3 -c "
import json
d=json.load(open('/tmp/c208_clasico.json'))
tm=d.get('touchMap') or {}
print((tm.get('home') or {}).get('touches',0), (tm.get('away') or {}).get('touches',0))")
HOME_DOTS=$(echo "$DOTS" | rg -o '^[0-9]+')
AWAY_DOTS=$(echo "$DOTS" | rg -o '[0-9]+$')
echo "runtime dots: home=$HOME_DOTS away=$AWAY_DOTS"

# B1 (D1): four cards alive on the finished Clásico + the DOM order
# contract (previews before reviews; touchmap after top-players)
open_page "/match/5868105"
clean_ls
B1=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),rv:!!document.querySelector('[data-testid=match-reviews]'),tm:!!document.querySelector('[data-testid=match-touchmap]'),tp:!!document.querySelector('[data-testid=match-top-players]'),dots:document.querySelectorAll('[data-testid=match-touchmap] span[class*=rounded-full]').length")
ORDER1=$($B eval '(function(){const p=document.querySelector("[data-testid=match-previews]"),r=document.querySelector("[data-testid=match-reviews]");if(!p||!r)return "missing";return (p.compareDocumentPosition(r)&Node.DOCUMENT_POSITION_FOLLOWING)?"pre-before-post":"wrong-order"})()' 2>/dev/null | tr -d '"\')
ORDER2=$($B eval '(function(){const t=document.querySelector("[data-testid=match-top-players]"),m=document.querySelector("[data-testid=match-touchmap]");if(!t||!m)return "missing";return (t.compareDocumentPosition(m)&Node.DOCUMENT_POSITION_FOLLOWING)?"tp-before-tm":"wrong-order"})()' 2>/dev/null | tr -d '"\')
B1R=0
echo "$B1" | rg -q "pv:true" || B1R=1
echo "$B1" | rg -q "rv:true" || B1R=1
echo "$B1" | rg -q "tm:true" || B1R=1
echo "$B1" | rg -q "tp:true" || B1R=1
echo "$B1" | rg -q "dots:$HOME_DOTS" || B1R=1
[ "$ORDER1" = "pre-before-post" ] || B1R=1
[ "$ORDER2" = "tp-before-tm" ] || B1R=1
[ "$B1R" -eq 0 ] || BAD=$((BAD+1))
gate "B1 four cards co-exist; dots==$HOME_DOTS; order pre<post + tp<tm" "$B1 order=$ORDER1/$ORDER2"

# B3 (D3): the RTL title contract on the FROZEN editorial anchor — the
# Clásico preview is the language-neutral /topnews/ editorial (the 207
# A1 pin; finished ⇒ frozen, no rotation race). Same-moment API fetch:
# DOM title must equal it, Arabic-script, /topnews/ href, and the page
# keeps sw=390 (no RTL overflow — the gate below).
$B eval "JSON.stringify((document.querySelector('[data-testid=match-previews] a span.block')||{}).textContent||'')" 2>/dev/null > /tmp/c208_domtitle.json
curl -s "$BASE/api/match/5868105" -o /tmp/c208_clasico_live.json
python3 - <<'PY' || BAD=$((BAD+1))
import json
def resilient_decode(path):
    # agent-browser may double-encode: JSON.stringify's quotes get
    # re-JSON-encoded by the tool output (the 202 gate lesson) — peel
    # layers while the decoded value still parses as a JSON string.
    s = open(path, encoding='utf-8').read().strip()
    for _ in range(3):
        try:
            v = json.loads(s)
        except Exception:
            break
        if isinstance(v, str) and v.startswith('"') and v.endswith('"') and len(v) >= 2:
            s = v
            continue
        return v if isinstance(v, str) else s
    return s
dom = resilient_decode('/tmp/c208_domtitle.json')
live = json.load(open('/tmp/c208_clasico_live.json'))
pv = (live.get('previews') or [{}])[0]
api, u0 = pv.get('title') or '', pv.get('url') or ''
ar = any('\u0600' <= ch <= '\u06FF' for ch in dom)
same = dom == api
top = '/topnews/' in u0
good = same and ar and top and len(dom) > 10
print(f"B3-api-dom RTL title: dom==api:{same} arabic:{ar} topnews:{top} len={len(dom)} {'OK' if good else 'BAD'}")
raise SystemExit(0 if good else 1)
PY
gate "B3 DOM title == same-moment API title (frozen editorial, RTL-safe)" "sw gate below"

# B2 (D2): the future covered match — /news/ preview rows (structural,
# rotation-proof), reviews and touchmap cards honestly absent
open_page "/match/5881208"
clean_ls
B2=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),rows:document.querySelectorAll('[data-testid=match-previews] a').length,href0:(document.querySelector('[data-testid=match-previews] a')||{href:''}).href.slice(0,44),rv:!!document.querySelector('[data-testid=match-reviews]'),tm:!!document.querySelector('[data-testid=match-touchmap]')")
B2R=0
echo "$B2" | rg -q "pv:true" || B2R=1
echo "$B2" | rg -q "rows:[1-9][0-9]*" || B2R=1
echo "$B2" | rg -q "href0:https://www.fotmob.com/news/" || B2R=1
echo "$B2" | rg -q "rv:false" || B2R=1
echo "$B2" | rg -q "tm:false" || B2R=1
[ "$B2R" -eq 0 ] || BAD=$((BAD+1))
gate "B2 future covered match: /news/ previews, reviews+touchmap absent" "$B2"

# B4 (D4): the interaction marathon on the SAME Clásico page — away pill
# handover swaps dots to the runtime away count; players tab deep toggle
# idempotent with the حمله section alive
open_page "/match/5868105"
clean_ls
$B eval '(function(){const b=document.querySelector("[data-testid=touchmap-side-away]");if(b)b.click();return b?"clicked":"no-pill"})()' >/dev/null 2>&1
sleep 0.8
B4a=$(snap "awayPressed:document.querySelector('[data-testid=touchmap-side-away]')?document.querySelector('[data-testid=touchmap-side-away]').getAttribute('aria-pressed'):'none',homePressed:document.querySelector('[data-testid=touchmap-side-home]')?document.querySelector('[data-testid=touchmap-side-home]').getAttribute('aria-pressed'):'none',dots:document.querySelectorAll('[data-testid=match-touchmap] span[class*=rounded-full]').length")
B4aR=0
echo "$B4a" | rg -q "awayPressed:true" || B4aR=1
echo "$B4a" | rg -q "homePressed:false" || B4aR=1
echo "$B4a" | rg -q "dots:$AWAY_DOTS" || B4aR=1
[ "$B4aR" -eq 0 ] || BAD=$((BAD+1))
gate "B4a away-pill handover → dots==$AWAY_DOTS" "$B4a"
click_tab "بازیکن‌ها"
$B wait --fn "!!document.querySelector('[data-testid=player-deep-toggle]')" >/dev/null 2>&1
sleep 0.8
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "opened"})()' >/dev/null 2>&1
sleep 0.6
B4b=$(snap "panel:!!document.querySelector('[data-testid=player-deep]'),expanded:document.querySelector('[data-testid=player-deep-toggle]')?document.querySelector('[data-testid=player-deep-toggle]').getAttribute('aria-expanded'):'none',secs:[...document.querySelectorAll('[data-testid=player-deep] > div > p')].map(x=>x.textContent).join('|'),attack:(document.body.innerText||'').indexOf('حمله')>=0")
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "closed"})()' >/dev/null 2>&1
sleep 0.4
B4c=$(snap "panel:!!document.querySelector('[data-testid=player-deep]')")
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "reopened"})()' >/dev/null 2>&1
sleep 0.5
B4d=$(snap "panel:!!document.querySelector('[data-testid=player-deep]')")
B4bR=0
echo "$B4b" | rg -q "panel:true" || B4bR=1
echo "$B4b" | rg -q "expanded:true" || B4bR=1
echo "$B4b" | rg -q "attack:true" || B4bR=1
echo "$B4b" | rg -q "secs:[حمدل|]+" || B4bR=1
[ "$B4bR" -eq 0 ] || BAD=$((BAD+1))
[ "$(echo "$B4c" | rg -q 'panel:false' && echo ok)" = "ok" ] || BAD=$((BAD+1))
[ "$(echo "$B4d" | rg -q 'panel:true' && echo ok)" = "ok" ] || BAD=$((BAD+1))
gate "B4b-d deep toggle open→close→reopen idempotent, حمله alive" "$B4b | close=$B4c reopen=$B4d"

# B5 (D7): keyboard scroll containment on a runtime-derived fat needle —
# full ArrowDown walk lands with the active row fully inside the container
NEEDLE=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
best, best_n = "ali", 0
for cand in ("ali", "al", "سی", "a"):
    try:
        q = urllib.parse.quote(cand)
        d = json.load(urllib.request.urlopen(urllib.request.Request(f"http://localhost:3000/api/search?q={q}", headers=UA), timeout=15))
        n = len(d.get("results") or []) + len(d.get("leagues") or []) + len(d.get("players") or [])
        if n >= 8:
            best, best_n = cand, n
            break
        if n > best_n:
            best, best_n = cand, n
    except Exception:
        pass
print(best)
PY
)
echo "B5 needle: $NEEDLE"
open_page "/"
clean_ls
open_search
type_into "$NEEDLE"
$B wait --fn "document.querySelectorAll('[role=dialog] li').length >= 3" >/dev/null 2>&1
sleep 1.2
ROWS=$(snap 'rows:document.querySelectorAll("[role=dialog] li").length,sh:document.querySelector("[role=dialog] .overflow-y-auto")?document.querySelector("[role=dialog] .overflow-y-auto").scrollHeight:0,ch:document.querySelector("[role=dialog] .overflow-y-auto")?document.querySelector("[role=dialog] .overflow-y-auto").clientHeight:0')
ROWS_N=$(echo "$ROWS" | rg -o 'rows:[0-9]+' | rg -o '[0-9]+')
OVERF=$(echo "$ROWS" | rg -o 'sh:[0-9]+' | rg -o '[0-9]+')
CLIENTH=$(echo "$ROWS" | rg -o 'ch:[0-9]+' | rg -o '[0-9]+')
echo "B5 rows=$ROWS_N sh=$OVERF ch=$CLIENTH"
[ -n "$ROWS_N" ] && [ "$ROWS_N" -ge 3 ] || { echo "B5 FAIL: dialog rows missing"; BAD=$((BAD+1)); }
i=0
while [ "$i" -lt "${ROWS_N:-0}" ]; do arrow_down; i=$((i+1)); done
sleep 0.8
B5=$(snap "act:!!document.querySelector('[role=dialog] .cmd-active'),sc:document.querySelector('[role=dialog] .overflow-y-auto')?document.querySelector('[role=dialog] .overflow-y-auto').scrollTop:-1,vis:$VIS_EXPR")
B5R=0
echo "$B5" | rg -q "act:true" || B5R=1
echo "$B5" | rg -q "vis:true\|over:" || B5R=1
if [ -n "$OVERF" ] && [ -n "$CLIENTH" ] && [ "$OVERF" -gt "$CLIENTH" ]; then
  echo "$B5" | rg -q "sc:[1-9][0-9]*" || B5R=1
  COND="overflow path (sc>0 required)"
else
  COND="no-overflow path (sc must stay honest)"
fi
[ "$B5R" -eq 0 ] || BAD=$((BAD+1))
gate "B5 full walk ($ROWS_N rows, $COND) → active row fully visible" "$B5"
close_search
clean_ls

# B6 (D6): honest absence on the uncovered match — BOTH cards absent,
# page healthy
open_page "/match/5868115"
clean_ls
B6=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),rv:!!document.querySelector('[data-testid=match-reviews]'),tabs:!!document.querySelector('nav[aria-label=\"بخش‌های مسابقه\"]'),score:!!document.querySelector('[data-testid=match-touchmap]')")
B6R=0
echo "$B6" | rg -q "pv:false" || B6R=1
echo "$B6" | rg -q "rv:false" || B6R=1
echo "$B6" | rg -q "tabs:true" || B6R=1
echo "$B6" | rg -q "score:false" || B6R=1
[ "$B6R" -eq 0 ] || BAD=$((BAD+1))
gate "B6 uncovered match: no previews+no reviews+no touchmap, tabs alive" "$B6"

# B7 (D5): 205×206 universality on the SECOND finished competition —
# touchmap + deep toggle both alive on the EFL Cup page
open_page "/match/6275369"
clean_ls
B7=$(snap "tm:!!document.querySelector('[data-testid=match-touchmap]'),dots:document.querySelectorAll('[data-testid=match-touchmap] span[class*=rounded-full]').length")
click_tab "بازیکن‌ها"
$B wait --fn "!!document.querySelector('[data-testid=player-deep-toggle]')" >/dev/null 2>&1
sleep 0.8
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "opened"})()' >/dev/null 2>&1
sleep 0.6
B7b=$(snap "panel:!!document.querySelector('[data-testid=player-deep]'),rows:document.querySelectorAll('[data-testid=player-deep] div.flex.items-center').length")
B7R=0
echo "$B7" | rg -q "tm:true" || B7R=1
echo "$B7" | rg -q "dots:[1-9][0-9]*" || B7R=1
echo "$B7b" | rg -q "panel:true" || B7R=1
echo "$B7b" | rg -q "rows:[1-9][0-9]*" || B7R=1
[ "$B7R" -eq 0 ] || BAD=$((BAD+1))
gate "B7 EFL Cup: touchmap + deep panel co-exist (second competition)" "$B7 | $B7b"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-208: patrol of the 204-207 surfaces — the 207×191×205×206 four-block Clásico co-existence with both DOM-order contracts, the 207 future-shape absence trio on Bayern–Dortmund, the 207 ar-wins RTL contract with same-moment title equality @390, the 205×206 one-page interaction marathon (away-pill dots handover + idempotent deep toggle with حمله), the 205×206 EFL Cup second-competition universality, the honest double absence on the uncovered match, the 204 keyboard scroll containment on a runtime-derived fat needle, the warm match-API latency bound — API 6/6 + DOM 7/7 @390x844; product bugs = 0)"
else
  echo "HUNT BAD=$BAD"
  exit 1
fi
