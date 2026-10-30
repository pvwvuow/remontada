#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-207 update — «پیش‌نمای بازی» (the pre-match preview feed) on
# the match page.
#
# D5 probe first (live, 2026-10-30, UA Chrome/124): matchFacts.
# preReview — the editorial preview article, the chronological
# sibling of the 191 postReview, NEVER mapped before (grep-verified
# zero usage in src/). ONE article repeated in 8 languages (ids
# carry a "_lang" suffix; en/es/it/pt-BR/fr/de/ar/pt) on
# editorially-covered matches BOTH upcoming (5795498 Chelsea-ManUtd,
# 5881208 Bayern-Dortmund — shareUrl under /news/) and finished
# (5868105 Clásico — shareUrl under /topnews/); uncovered matches
# (5868115 Barca-Alavés, 5749730 Milan-Inter) carry nothing → honest
# absence. source varies (Opta / FotMob), image hosts vary
# (images.performgroup.com / latest.fotmob.com — both https).
#
# Update additive-only, ZERO fresh upstream calls (rides the one
# already-cached matchDetails fetch): /api/match/[id] gains an
# OPTIONAL `previews` array — same _lang id-suffix dedupe as 191
# with ONE probed widening (the shareUrl guard accepts /news/ AND
# /topnews/) and a FRESH language contract: the "ar" entry wins its
# group (RTL, script-adjacent to the Persian UI), en fallback, else
# first-seen; all entries scanned so the ar pick survives several
# articles; groups keep upstream order, capped at 3. The 191 reviews
# keep their frozen en-wins contract. UI: PreviewsCard — a
# header-level glass card BEFORE the reviews card (pre before post),
# same external-row mechanics (new-tab link, onError-hide image,
# text-only degradation). Hidden when absent (honest absence).
#
# Negative probe (same cycle, documented in the worklog card): the
# player matches pagination endpoint (matchesUrl → pub.fotmob.com/
# prod/db/api/player/{id}/matches) answers HTTP 400 for every
# parameter variant tried (empty, leagueId only, teamId only, both
# filled) — the same inaccessible class as the cycle-201
# season-params pin; the initialMatchesPage "load more" gap stays
# honestly unreachable.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API previews contract =="
curl -s "$BASE/api/match/5868105" -o /tmp/c207_a1.json
A_OUT=""

A1=$(python3 - << 'PY'
import json
try:
    d = json.load(open('/tmp/c207_a1.json'))
    pv = d.get('previews')
    if not pv or not isinstance(pv, list) or len(pv) < 1:
        print('A1_FAIL no-previews'); raise SystemExit
    r = pv[0]
    keys = set(r.keys())
    if not keys <= {'title','description','image','source','url','date'}:
        print(f'A1_FAIL keys={keys}'); raise SystemExit
    # the ar-wins contract: the Clásico editorial is frozen (finished match)
    if r['title'] != 'تقديم الكلاسيكو: برشلونة يواجه ريال مدريد':
        print(f"A1_FAIL title={r['title'][:60]!r}"); raise SystemExit
    if not r['url'].startswith('https://www.fotmob.com/topnews/'):
        print(f"A1_FAIL url={r['url'][:60]}"); raise SystemExit
    if not r['image'].startswith('https://'):
        print(f"A1_FAIL image={r['image'][:60]}"); raise SystemExit
    if not r.get('source'):
        print('A1_FAIL no-source'); raise SystemExit
    # 191 sibling untouched on the same payload (additive coexistence)
    rv = d.get('reviews')
    if not rv or not isinstance(rv, list) or len(rv) < 1:
        print('A1_FAIL reviews-gone'); raise SystemExit
    print(f"A1_OK n={len(pv)} ar-title src={r['source']} topnews=Y reviews={len(rv)}")
except Exception as e:
    print('A1_FAIL', e)
PY
)
A_OUT="$A_OUT$A1
"
echo "$A1" | rg -q "A1_OK" || BAD=$((BAD+1))

# A2: an UPCOMING covered match — /news/ shareUrl + Opta source, and
# the honest pre/post independence (upcoming never carries postReview)
curl -s "$BASE/api/match/5795498" -o /tmp/c207_a2.json
A2=$(python3 - << 'PY'
import json
try:
    d = json.load(open('/tmp/c207_a2.json'))
    pv = d.get('previews')
    if not pv or not isinstance(pv, list) or len(pv) < 1:
        print('A2_FAIL no-previews'); raise SystemExit
    r = pv[0]
    if not r['url'].startswith('https://www.fotmob.com/news/'):
        print(f"A2_FAIL url={r['url'][:60]}"); raise SystemExit
    if r.get('source') != 'Opta':
        print(f"A2_FAIL src={r.get('source')!r}"); raise SystemExit
    # structure only (upcoming editorial can rotate — the 202 lesson)
    if not r['title'] or not r['title'].strip():
        print('A2_FAIL empty-title'); raise SystemExit
    rv = d.get('reviews')
    if rv:
        print(f'A2_FAIL upcoming-reviews={len(rv)}'); raise SystemExit
    m = d.get('match') or {}
    if m.get('finished'):
        print('A2_FAIL expected-upcoming'); raise SystemExit
    print(f"A2_OK n={len(pv)} news=Y src=Opta finished=False reviews=null")
except Exception as e:
    print('A2_FAIL', e)
PY
)
A_OUT="$A_OUT$A2
"
echo "$A2" | rg -q "A2_OK" || BAD=$((BAD+1))

# A3: honest absence — uncovered finished (Milan-Inter) AND uncovered
# upcoming (Barca-Alavés): previews null, the route still healthy
curl -s "$BASE/api/match/5749730" -o /tmp/c207_a3.json
curl -s "$BASE/api/match/5868115" -o /tmp/c207_a3b.json
A3=$(python3 - << 'PY'
import json
ok = True
for f, lbl in (('/tmp/c207_a3.json','milan-inter'), ('/tmp/c207_a3b.json','barca-alaves')):
    try:
        d = json.load(open(f))
    except Exception as e:
        print(f'A3_FAIL {lbl} parse {e}'); ok = False; continue
    if not d.get('ok'):
        print(f'A3_FAIL {lbl} ok=false err={d.get("error","")[:40]}'); ok = False; continue
    if d.get('previews'):
        print(f'A3_FAIL {lbl} previews-present={len(d["previews"])}'); ok = False
if ok:
    print('A3_OK absence honest on both uncovered matches')
PY
)
A_OUT="$A_OUT$A3
"
echo "$A3" | rg -q "A3_OK" || BAD=$((BAD+1))

# A4: the additive contract on the same Clásico payload — every legacy
# block byte-present (scoreboard/lineups/topPlayers/touchMap/timeline)
A4=$(python3 - << 'PY'
import json
try:
    d = json.load(open('/tmp/c207_a1.json'))
    m = d.get('match') or {}
    need_match = {'id','leagueFa','home','away','finished'}
    if not need_match <= set(m.keys()):
        print(f'A4_FAIL match-keys={sorted(m.keys())}'); raise SystemExit
    for k in ('scorers','events','lineups','topPlayers','playerStats','touchMap'):
        if k not in d:
            print(f'A4_FAIL missing-{k}'); raise SystemExit
    ls = d.get('lineups') or {}
    if not (ls.get('home') and ls.get('away')):
        print('A4_FAIL lineups-empty'); raise SystemExit
    print('A4_OK legacy intact (scorers/events/lineups/topPlayers/playerStats/touchMap)')
except Exception as e:
    print('A4_FAIL', e)
PY
)
A_OUT="$A_OUT$A4
"
echo "$A4" | rg -q "A4_OK" || BAD=$((BAD+1))

echo "$A_OUT"
echo "$A_OUT" | rg -q "A1_OK" && echo "$A_OUT" | rg -q "A2_OK" && echo "$A_OUT" | rg -q "A3_OK" && echo "$A_OUT" | rg -q "A4_OK" || BAD=$((BAD+1))

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

# B1: the Clásico page renders the previews card — header label, ≥1
# external row (target=_blank), topnews href, and the DOM order
# pre-before-post (previews precedes reviews)
open_page "/match/5868105"
clean_ls
B1=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),hdr:[...document.querySelectorAll('[data-testid=match-previews] header span')].map(x=>x.textContent).join('|'),rows:document.querySelectorAll('[data-testid=match-previews] a').length,ext:[...document.querySelectorAll('[data-testid=match-previews] a')].every(a=>a.target==='_blank'&&a.rel.includes('noopener')),href0:(document.querySelector('[data-testid=match-previews] a')||{href:''}).href.slice(0,40),rv:!!document.querySelector('[data-testid=match-reviews]')")
ORDER=$($B eval '(function(){const p=document.querySelector("[data-testid=match-previews]"),r=document.querySelector("[data-testid=match-reviews]");if(!p||!r)return "missing";return (p.compareDocumentPosition(r)&Node.DOCUMENT_POSITION_FOLLOWING)?"pre-before-post":"wrong-order"})()' 2>/dev/null | tr -d '"\')
echo "B1 $B1 order=$ORDER"
echo "$B1" | rg -q "pv:true" && echo "$B1" | rg -q "پیش‌نمای بازی" && echo "$B1" | rg -q "rows:[1-9][0-9]*" && echo "$B1" | rg -q "ext:true" && echo "$B1" | rg -q "topnews" && echo "$B1" | rg -q "rv:true" && [ "$ORDER" = "pre-before-post" ] || { echo "B1 FAIL"; BAD=$((BAD+1)); }
gate "B1-gate" "previews card renders pre-before-post with external topnews rows"

# B2: an UPCOMING covered match — the card renders from /news/ rows and
# the reviews card is honestly absent (pre≠post independence in DOM)
open_page "/match/5795498"
clean_ls
B2=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),rows:document.querySelectorAll('[data-testid=match-previews] a').length,href0:(document.querySelector('[data-testid=match-previews] a')||{href:''}).href.slice(0,40),rv:!!document.querySelector('[data-testid=match-reviews]'),tm:!!document.querySelector('[data-testid=touchmap-side-home]')")
echo "B2 $B2"
H=$(echo "$B2" | rg -o "href0:https://www.fotmob.com/news/" || true)
echo "$B2" | rg -q "pv:true" && echo "$B2" | rg -q "rows:[1-9][0-9]*" && [ -n "$H" ] && echo "$B2" | rg -q "rv:false" || { echo "B2 FAIL"; BAD=$((BAD+1)); }
gate "B2-gate" "upcoming covered match — /news/ rows, reviews honestly absent"

# B3: honest absence in DOM — an uncovered match renders NO previews
# card while the page itself stays healthy
open_page "/match/5749730"
clean_ls
B3=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),rv:!!document.querySelector('[data-testid=match-reviews]')")
echo "B3 $B3"
echo "$B3" | rg -q "pv:false" || { echo "B3 FAIL"; BAD=$((BAD+1)); }
gate "B3-gate" "uncovered match — no previews card, page healthy"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "CYCLE207 DOMPROOF ALL GREEN"
else
  echo "CYCLE207 DOMPROOF FAILURES: $BAD"
  exit 1
fi
