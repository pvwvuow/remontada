#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-209 fix gate — the per-row source chip on the pre-match preview
# rows («پیش‌نمای بازی»). The 208-hunt found no product bugs → per the
# rotation contract a fix without findings is ONE small real polish:
# the header attribution («منبع: Opta · FotMob · در تب جدید باز می‌شود»)
# stays byte-identical and generic, while each row now renders its own
# r.source verbatim (the honest raw-label family — injuries 96 / deep
# labels 206). Additive-only: no pinned text moves, absent source → no
# chip, reviews rows (191) untouched.
#
# A1 Clásico previews[0]: source=FotMob + /topnews/ + the frozen byte
#    title (the 207 A1 pin) + the 191 reviews block intact beside it
# A2 future Bayern–Dortmund previews[0]: source=Opta + the _ar-- slug
# A3 the preview entry key-set contract unchanged (the 207 A1 shape)
# A4 honest absence intact: the uncovered match carries no previews
# B1 @390×844 Clásico: the chip renders «FotMob» inside the row, the
#    header attribution byte-exact, external href intact
# B2 @390×844 future: the chip renders «Opta», /news/ href, reviews
#    card honestly absent
# B3 @390×844 uncovered: no previews card, page healthy
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

# warm the payloads once (the gate must not depend on leftover warmth)
curl -s "$BASE/api/match/5868105" -o /tmp/c209_clasico.json
curl -s "$BASE/api/match/5881208" -o /tmp/c209_future.json
curl -s "$BASE/api/match/5868115" -o /tmp/c209_uncovered.json
python3 -c "
import json,sys
for f in ('/tmp/c209_clasico.json','/tmp/c209_future.json','/tmp/c209_uncovered.json'):
    d=json.load(open(f))
    assert d.get('ok') is True, f
" || { echo "MATCH WARMUP FAILED — aborting"; exit 1; }

echo "== PART A: API proof (4 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: the Clásico editorial row — source, url family, frozen byte title,
# and the 191 reviews block alive beside it
try:
    d = json.load(open('/tmp/c209_clasico.json'))
    pv = d.get("previews") or []
    rv = d.get("reviews") or []
    r0 = pv[0] if pv else {}
    good = (r0.get("source") == "FotMob"
            and "/topnews/" in (r0.get("url") or "")
            and r0.get("title") == "تقديم الكلاسيكو: برشلونة يواجه ريال مدريد"
            and len(rv) >= 1)
    report("A1 Clásico: source=FotMob + /topnews/ + frozen title + reviews intact", good,
           f"src={r0.get('source')!r} title_len={len(r0.get('title') or '')} rv={len(rv)}")
except Exception as e:
    report("A1 Clásico: source=FotMob + /topnews/ + frozen title + reviews intact", False, repr(e))

# A2: the future Opta row — source + the _ar-- slug (the 207 D3 contract)
try:
    d = json.load(open('/tmp/c209_future.json'))
    pv = d.get("previews") or []
    r0 = pv[0] if pv else {}
    good = (r0.get("source") == "Opta"
            and "_ar--" in (r0.get("url") or "")
            and "/news/" in (r0.get("url") or ""))
    report("A2 future: source=Opta + _ar-- /news/ slug", good,
           f"src={r0.get('source')!r} url0={(r0.get('url') or '')[:52]}")
except Exception as e:
    report("A2 future: source=Opta + _ar-- /news/ slug", False, repr(e))

# A3: the preview entry key-set contract unchanged (the 207 A1 shape —
# the fix is pure-render; no payload key added or dropped)
try:
    good = True; det = []
    for f in ('/tmp/c209_clasico.json', '/tmp/c209_future.json'):
        d = json.load(open(f))
        for r in d.get("previews") or []:
            keys = set(r.keys())
            if not keys <= {"title", "description", "image", "source", "url", "date"}:
                good = False
            det.append(f"{len(keys)}keys")
    report("A3 preview key-set contract unchanged on both payloads", good, " ".join(det))
except Exception as e:
    report("A3 preview key-set contract unchanged on both payloads", False, repr(e))

# A4: honest absence intact — the uncovered match carries no previews
try:
    d = json.load(open('/tmp/c209_uncovered.json'))
    good = not d.get("previews")
    report("A4 uncovered match: no previews block (honest absence)", good,
           f"pv={len(d.get('previews') or [])}")
except Exception as e:
    report("A4 uncovered match: no previews block (honest absence)", False, repr(e))

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

# B1: the Clásico page — the chip renders «FotMob» inside the first
# preview row, the header attribution byte-exact, the external href and
# the 191 reviews card intact beside it
open_page "/match/5868105"
clean_ls
B1=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),chip:(document.querySelector('[data-testid=match-previews] a span[dir=ltr]')||{textContent:''}).textContent,hdr:[...document.querySelectorAll('[data-testid=match-previews] header span')].map(x=>x.textContent).join('|'),rows:document.querySelectorAll('[data-testid=match-previews] a').length,ext:[...document.querySelectorAll('[data-testid=match-previews] a')].every(a=>a.target==='_blank'&&a.rel.includes('noopener')),rv:!!document.querySelector('[data-testid=match-reviews]')")
B1R=0
echo "$B1" | rg -q "pv:true" || B1R=1
echo "$B1" | rg -q "chip:FotMob" || B1R=1
echo "$B1" | rg -q "منبع: Opta · FotMob · در تب جدید باز می‌شود" || B1R=1
echo "$B1" | rg -q "rows:[1-9][0-9]*" || B1R=1
echo "$B1" | rg -q "ext:true" || B1R=1
echo "$B1" | rg -q "rv:true" || B1R=1
[ "$B1R" -eq 0 ] || BAD=$((BAD+1))
gate "B1 Clásico: chip=FotMob + byte header + external href + reviews intact" "$B1"

# B2: the future covered match — the chip renders «Opta», /news/ href,
# the reviews card honestly absent
open_page "/match/5881208"
clean_ls
B2=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),chip:(document.querySelector('[data-testid=match-previews] a span[dir=ltr]')||{textContent:''}).textContent,href0:(document.querySelector('[data-testid=match-previews] a')||{href:''}).href.slice(0,44),rv:!!document.querySelector('[data-testid=match-reviews]')")
B2R=0
echo "$B2" | rg -q "pv:true" || B2R=1
echo "$B2" | rg -q "chip:Opta" || B2R=1
echo "$B2" | rg -q "href0:https://www.fotmob.com/news/" || B2R=1
echo "$B2" | rg -q "rv:false" || B2R=1
[ "$B2R" -eq 0 ] || BAD=$((BAD+1))
gate "B2 future: chip=Opta + /news/ href + reviews absent" "$B2"

# B3: the uncovered match — no previews card at all, page healthy
open_page "/match/5868115"
clean_ls
B3=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),tabs:!!document.querySelector('nav[aria-label=\"بخش‌های مسابقه\"]')")
B3R=0
echo "$B3" | rg -q "pv:false" || B3R=1
echo "$B3" | rg -q "tabs:true" || B3R=1
[ "$B3R" -eq 0 ] || BAD=$((BAD+1))
gate "B3 uncovered: no previews card, tabs alive" "$B3"

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "CYCLE209 DOMPROOF ALL GREEN (the per-row source chip — Clásico «FotMob» + future «Opta», the header attribution byte-exact, the 207 payload contract and the 191 reviews block untouched, honest absence intact — API 4/4 + DOM 3/3 @390x844)"
else
  echo "CYCLE209 DOMPROOF FAILURES: $BAD"
  exit 1
fi
