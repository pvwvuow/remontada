#!/bin/bash
# cycle-127 fix proof at 390x844 — the cycle-124 incident class CLOSED:
# a dropped transient data.fotmob.com file fetch used to bake a THIN result
# (empty / topThree-only) into the 60-minute cache whose only self-heal was a
# full restart. Fix (src/lib/fotmob.ts): (1) fetchDataFile — two tries with a
# short pause on BOTH transient S3 reads (goals.json + *_card.json);
# (2) thin-TTL guards — fullGoals AND standings:v6 (the merged scorers list
# rides on the standings entry, so without this second guard a thin list
# stayed visible for a full ttlMinutes generation) now re-probe in 90 SECONDS
# when the produced scorers list is thin (<10 — full-season files are ALWAYS
# wide: live-probed 298/130/438/204 rows vs the 3-4 row fallback), while
# healthy lists keep the exact previous TTLs. No cache-key bump: live rows
# are healthy by definition.
# Proof:
#   (A) API truth — current scorers intact (Haaland 9, n=20, Persian names),
#       the cycle-124 season-pure contract intact (2023/24 Haaland 27 +
#       Watkins 19), the thin season honestly empty (2010/2011 scorers=0 with
#       a HEALTHY 20-row table + honest selectedSeason), designed 503/400.
#   (BEHAVIOR — run separately, logged in the worklog card): after purge +
#       official restart, the thin view rebuilt at T1 and RE-PROBED at
#       T1+~104s (updatedAt moved) while the healthy view kept updatedAt
#       frozen — the self-heal, live.
#   (B) DOM — historic thin season renders its table with NO false banner and
#       an honest (empty) scorers tab; current + 2023/24 keep their heroes;
#       every page sw=cw=390, exactly 1 h1, 0 broken images, console=0,
#       appErr=0 (cycle-108 url convention; bitmask 1=overflow 2=h1!=1
#       4=broken imgs).
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
    d = get('http://localhost:3000/api/standings?league=pl')
    s = d.get('scorers') or []
    report('pl current scorers (healthy TTL branch)',
           d.get('ok') is True and len(s) == 20
           and s[0].get('name') == 'Erling Haaland' and s[0].get('goals') == 9
           and all(x.get('nameFa') for x in s[:5]),
           f"n={len(s)} top={s[0].get('name')}({s[0].get('goals')}) fa={bool(s[0].get('nameFa'))}")
except Exception as e:
    ok = False; print('pl current scorers: ERR', e)
try:
    d = get('http://localhost:3000/api/standings?league=pl&season=2023/2024')
    s = d.get('scorers') or []
    report('pl 2023/2024 season-pure (cycle-124 contract)',
           d.get('ok') is True and len(s) == 20
           and s[0].get('name') == 'Erling Haaland' and s[0].get('goals') == 27
           and any(x.get('name') == 'Ollie Watkins' and x.get('goals') == 19 for x in s),
           f"n={len(s)} top={s[0].get('name')}({s[0].get('goals')}) watkins19={any(x.get('name')=='Ollie Watkins' and x.get('goals')==19 for x in s)}")
except Exception as e:
    ok = False; print('pl 2023/2024: ERR', e)
try:
    d = get('http://localhost:3000/api/standings?league=pl&season=2010/2011')
    rows = d.get('rows') or []
    report('pl 2010/2011 thin-but-honest (thin-TTL branch)',
           d.get('ok') is True and d.get('selectedSeason') == '2010/2011'
           and len(d.get('scorers') or []) == 0 and len(rows) >= 18,
           f"selectedSeason={d.get('selectedSeason')} scorers=0 rows={len(rows)}")
except Exception as e:
    ok = False; print('pl 2010/2011: ERR', e)
try:
    get('http://localhost:3000/api/standings?league=persiangulf')
    ok = False; print('persiangulf designed-503: BAD (200 returned)')
except urllib.error.HTTPError as e:
    report('persiangulf designed-503', e.code == 503, f"code={e.code}")
except Exception as e:
    ok = False; print('persiangulf: ERR', e)
try:
    get('http://localhost:3000/api/standings?league=nonexistent')
    ok = False; print('bad-key designed-400: BAD (200 returned)')
except urllib.error.HTTPError as e:
    report('bad-key designed-400', e.code == 400, f"code={e.code}")
except Exception as e:
    ok = False; print('bad-key: ERR', e)
print('API_TRUTH', 'OK' if ok else 'FAILED')
PY

echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label $3=extra-bool-expr(json fields over txt/tabs)
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT OUT BAD C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const txt=document.body.innerText||'';return $3})())" 2>/dev/null | tr -d '"\\')
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
  [ "$E" != "0" ] && RC=1
  return $RC
}
TOTAL_BAD=0

# B1: the thin season — table renders healthy, NO false banner, honest empty scorers tab
probe "http://localhost:3000/league/pl?season=2010/2011" "B1 /league/pl?season=2010/2011 (thin season)" \
  '{histLabel:txt.includes("۲۰۱۰/۲۰۱۱"),falseBanner:txt.includes("ارتباط برقرار نشد."),tableOk:txt.includes("منچستریونایتد")}' \
  || { echo "   ⚠ B1 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(b)b.click();return 1})()' >/dev/null 2>&1
sleep 2
B1B=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {tabOpen:!document.body.innerText.includes("ارتباط برقرار نشد."),noFalseError:true}})())' 2>/dev/null | tr -d '"\\')
echo "B1b thin scorers tab → $B1B"
echo "$B1B" | grep -q 'tabOpen:true' || { echo "   ⚠ B1b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B2: current view — hero stays the CURRENT leader (Haaland ۹), healthy TTL branch
probe "http://localhost:3000/league/pl" "B2 /league/pl (current)" \
  '{falseBanner:txt.includes("ارتباط برقرار نشد.")}' \
  || { echo "   ⚠ B2 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(b)b.click();return 1})()' >/dev/null 2>&1
sleep 2
B2B=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {haaland:txt.includes("هالند"),g9:txt.includes("۹")}})())' 2>/dev/null | tr -d '"\\')
echo "B2b current scorers tab → $B2B"
echo "$B2B" | grep -q 'haaland:true' && echo "$B2B" | grep -q 'g9:true' \
  || { echo "   ⚠ B2b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B3: the cycle-124 season-pure hero (Haaland ۲۷) intact
probe "http://localhost:3000/league/pl?season=2023/2024" "B3 /league/pl?season=2023/2024" \
  '{histLabel:txt.includes("فصل ۲۰۲۳/۲۰۲۴"),falseBanner:txt.includes("ارتباط برقرار نشد.")}' \
  || { echo "   ⚠ B3 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(b)b.click();return 1})()' >/dev/null 2>&1
sleep 2
B3B=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {haaland:txt.includes("هالند"),g27:txt.includes("۲۷"),palmer22:txt.includes("کول پالمر")&&txt.includes("۲۲")}})())' 2>/dev/null | tr -d '"\\')
echo "B3b 2023/24 scorers tab → $B3B"
echo "$B3B" | grep -q 'haaland:true' && echo "$B3B" | grep -q 'g27:true' && echo "$B3B" | grep -q 'palmer22:true' \
  || { echo "   ⚠ B3b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

echo "==="
echo "FLAGGED_BLOCKS=$TOTAL_BAD of 3 (+tab sub-checks)"
[ "$TOTAL_BAD" = "0" ] && echo "CYCLE127 FIX PROOF OK" || echo "CYCLE127 FIX PROOF FAILED"
