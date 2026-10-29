#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-171 update proof — «بهترین پاس‌دهندگان» به جستجو می‌پیوندند
#
# Live-probed gap (2026-10-30, old build, UA Chrome/124): the player-search
# pool (cycle-166) was built from the 20-SCORER block only, while the SAME
# /api/standings payload also carries the assists block (the cycle-170
# surface). 16 of 27 assist entries across 9 probed leagues were NOT in the
# scorer pool → UNSEARCHABLE world stars, proven live on the old build:
#   q=Dybala → players: 0 ; q=Zaccagni → 0 ; q=Rice → 2 WRONG fuzzy rows
#   (Isaac Price / Maurice Krattenmacher) — Rice himself absent.
#
# Additive fix (one fold in getPlayerIndex): the assists rows ride the SAME
# cached payload — ZERO extra upstream fetches. seen-set dedupes against the
# scorer rows; playerId<=0 guard mirrors the 167 transfer dead-id lesson.
# The /api/search contract is untouched (additive ENTRIES only, no shape
# change) — the search-box player section renders the new rows as-is.
#
# Live-truth baseline (pinned from the NEW build BEFORE the gates — D5 rule):
#   q=Dybala          → Paulo Dybala / پائولو دیبالا / 325916 / رم / سری‌آ
#   q=دیبالا (fa)     → same hit (Persian alias path)
#   q=Rice            → Declan Rice FIRST / دکلن رایس / 654096 / آرسنال
#   q=Zaccagni        → Mattia Zaccagni / ماتیا زاکانی / 541555 / لاتزیو
#   q=Javi Hernandez  → Javi Hernández / خاوی هرناندس / 1427828 / اسپانیول
#                       (the 169 accent fold reaches the NEW entries)
#   q=Evanilson       → Evanilson honest-raw / 1098096 / بورنموث
# Legacy byte-parity: Sayyadmanesh → 887680 لخ پوزنان؛ Sanchez hl.name=[6,13]؛
# Rijeka → رییکا|hnl (the 166 teams+players compat shape).
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
# Warmup: the FIRST index sweep after a fresh start can come back partial
# (23 upstream fetches in one burst — cycle-169 hardening bounds it to ≤30s).
# Warm on the FOLD control itself with a 60s budget; the gates below judge
# the settled truth.
python3 - <<'PY'
import json, time, urllib.request, urllib.parse
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
ctrl = urllib.parse.quote("Dybala")
for i in range(12):
    try:
        d = get(f"http://localhost:3000/api/search?q={ctrl}")
        if any((p or {}).get("playerId") == 325916 for p in (d.get("players") or [])):
            print("WARMUP OK"); break
    except Exception:
        pass
    time.sleep(5)
PY

A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
def search(q):
    return get("http://localhost:3000/api/search?q=" + urllib.parse.quote(q))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: q=Dybala — the fold control; full row contract pinned from live truth
try:
    pl = search("Dybala").get("players") or []
    hit = next((p for p in pl if p.get("playerId") == 325916), None)
    good = bool(hit) and hit.get("name") == "Paulo Dybala" \
        and hit.get("fa") == "پائولو دیبالا" and hit.get("teamFa") == "رم" \
        and hit.get("leagueFa") == "سری\u200cآ ایتالیا"
    report("A1 Dybala searchable", good, f"rows={len(pl)} hit={hit and (hit.get('fa'), hit.get('teamFa'))}")
except Exception as e:
    report("A1 Dybala", False, str(e))

# A2: Persian query «دیبالا» — the PLAYER_NAME_FA alias path (166 contract)
try:
    pl = search("دیبالا").get("players") or []
    good = any(p.get("playerId") == 325916 and p.get("fa") == "پائولو دیبالا" for p in pl)
    report("A2 Persian دیبالا", good, f"rows={len(pl)}")
except Exception as e:
    report("A2 Persian", False, str(e))

# A3: q=Rice — BEFORE the fold: 2 wrong fuzzy rows, Rice absent. NOW: first row.
try:
    pl = search("Rice").get("players") or []
    good = bool(pl) and pl[0].get("playerId") == 654096 \
        and pl[0].get("name") == "Declan Rice" and pl[0].get("fa") == "دکلن رایس" \
        and pl[0].get("teamFa") == "آرسنال"
    report("A3 Rice first row", good, f"rows={len(pl)} first={pl[0].get('fa') if pl else None}")
except Exception as e:
    report("A3 Rice", False, str(e))

# A4: q=Zaccagni — seriea assist king (live-probed 0 before the fold)
try:
    pl = search("Zaccagni").get("players") or []
    good = any(p.get("playerId") == 541555 and p.get("fa") == "ماتیا زاکانی"
               and p.get("teamFa") == "لاتزیو" for p in pl)
    report("A4 Zaccagni searchable", good, f"rows={len(pl)}")
except Exception as e:
    report("A4 Zaccagni", False, str(e))

# A5: q=Javi Hernandez — accent-LESS Latin query (the 169 fold) must reach
# the accented NEW entry (Javi Hernández, laliga assists)
try:
    pl = search("Javi Hernandez").get("players") or []
    good = any(p.get("playerId") == 1427828 and p.get("fa") == "خاوی هرناندس" for p in pl)
    report("A5 accent-less Javi Hernandez", good, f"rows={len(pl)}")
except Exception as e:
    report("A5 accent-less", False, str(e))

# A6: q=Evanilson — honest raw fallback entry (fa == name, no mapping), pid>0
try:
    pl = search("Evanilson").get("players") or []
    hit = next((p for p in pl if p.get("playerId") == 1098096), None)
    good = bool(hit) and hit.get("fa") == "Evanilson" and hit.get("name") == "Evanilson"
    report("A6 Evanilson honest raw", good, f"hit={hit and (hit.get('fa'), hit.get('teamFa'))}")
except Exception as e:
    report("A6 Evanilson", False, str(e))

# A7: legacy byte-parity — the 166/169 paths untouched
try:
    pl = search("Sayyadmanesh").get("players") or []
    g1 = any(p.get("playerId") == 887680 and p.get("fa") == "اللهیار صیادمنش"
             and p.get("teamFa") == "لخ پوزنان" for p in pl)
    hl = (search("Sanchez").get("players") or [])
    hs = next((p for p in hl if p.get("name") == "Jordi Sánchez"), None)
    g2 = bool(hs) and (hs.get("hl") or {}).get("name") == [6, 13]
    tr = search("Rijeka").get("results") or []
    g3 = any(t.get("fa") == "رییکا" and t.get("leagueKey") == "hnl" for t in tr)
    report("A7 legacy parity (166/169)", g1 and g2 and g3,
           f"sayyad={g1} sanchez_hl={g2} rijeka={g3}")
except Exception as e:
    report("A7 legacy", False, str(e))

# A8: zero-id guard sweep — every player row of every probed query has pid>0
try:
    qs = ["Dybala", "دیبالا", "Rice", "Zaccagni", "Javi Hernandez", "Evanilson",
          "Sayyadmanesh", "Sanchez", "Gross", "Moleiro", "Diouf"]
    bad = []
    n = 0
    for q in qs:
        for p in (search(q).get("players") or []):
            n += 1
            if not isinstance(p.get("playerId"), int) or p.get("playerId") <= 0:
                bad.append((q, p.get("name")))
    report("A8 zero-id guard sweep", not bad, f"rows={n} bad={len(bad)}")
except Exception as e:
    report("A8 zero-id sweep", False, str(e))

print("API_PROOF OK" if ok else "API_PROOF FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_PROOF OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM proof @390x844 (real search UI + click-through) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
dom_search() { # $1=query $2=expect-fa $3=label
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE/" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
  $B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('$2'))" >/dev/null 2>&1
  sleep 1.5
  local FEAT OUT C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const btns=[...document.querySelectorAll('div[role=\"dialog\"] ul li button')];const hit=btns.find(b=>(b.innerText||'').includes('$2'));return {dialog:!!document.querySelector('div[role=\"dialog\"]'),hits:btns.length,found:!!hit,faHit:hit?(hit.innerText||'').includes('$2'):false}})())" 2>/dev/null | tr -d '"\\')
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
  echo "$3 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ -z "$FEAT" ] && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}
dom_search "Dybala" "پائولو دیبالا" "B1 UI Dybala → player row"
dom_search "Rice" "دکلن رایس" "B2 UI Rice → player row"
dom_search "صیادمنش" "اللهیار صیادمنش" "B3 UI صیادمنش legacy guard"

# B4: REAL click-through — دیبالا row → /player/325916 with Persian h1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Dybala');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('پائولو دیبالا'))" >/dev/null 2>&1
sleep 1
CLICKED=$($B eval '(function(){const btns=[...document.querySelectorAll("div[role=\"dialog\"] ul li button")];const hit=btns.find(b=>(b.innerText||"").includes("پائولو دیبالا"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/325916')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
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
B4_RC=0
[ "$CLICKED" = "clicked" ] || B4_RC=1
case "$URL" in /player/325916*) : ;; *) B4_RC=1 ;; esac
echo "$H1" | grep -q "دیبالا" || B4_RC=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B4_RC=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B4_RC=1
echo "B4 click-through دیبالا → URL=$URL h1=$H1 | $OUT | console=$C appErrors=$E rc=$B4_RC"
[ "$B4_RC" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-171: the assists block joins the player-search pool — Dybala/Rice/Zaccagni class searchable fa+en, accent-less Latin reaches the new entries, honest raw fallback rows carry live pids, legacy 166/169 paths byte-identical)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
