#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-177 update proof — «مضربان کارت به استخر جستجو می‌پیوندند»
#
# The cycle-176 surface (the «کارت‌ها» yellow/red block) rides the SAME
# cached getStandings payload, but getPlayerIndex (the cycle-166 search
# pool, extended by the 171 assists fold) ignored it: card kings who are
# neither top-20 scorers nor assist leaders were unsearchable.
#
# Live probe BEFORE code (2026-10-30, the D5 rule — observed bytes only):
#   q=Janelt  → {"ok":true,"results":[],"players":[]}  (ZERO rows)
#   q=یانلت   → ZERO rows   q=Alizadeh → ZERO rows
#   while /api/standings?league=pl cards.yellow[0] = Vitaly Janelt
#   688273 «ویتالی یانلت» برنتفورد — and 688273 is in NO other pl
#   player-id surface (scorers False / assists False / cards True) →
#   a search hit for him can ONLY come from the new fold (strong gate).
#   mas cards.red[0] = Fazly Mazlan 694010 «Fazly Mazlan» پنانگ (honest
#   EN nameFa fallback, the mas way).
#
# Update (additive-only, the 108/171 contract): getPlayerIndex folds
# cards.yellow then cards.red AFTER the assists loop — zero extra
# upstream fetches (same cached payload), seen-set keeps a dual-listed
# player once (as the scorer/assist row), playerId null/<=0 guard is
# MANDATORY here because GlobalCard.playerId is optional (the 167
# dead-id lesson), rank 0 (card rows carry no rank), no goals field.
# /api/search contract byte-untouched — only ENTRIES added; the
# searchbox renders the new rows with the same contract automatically.
#
# Pinned values (probed on the NEW build, same bytes as the gate):
#   q=Janelt   → players[0] = 688273 «ویتالی یانلت» برنتفورد (rank 0)
#   q=یانلت    → same hit (the FA alias path)
#   q=Mazlan   → 694010 fa="Fazly Mazlan" پنانگ (mas red, EN fallback)
#   q=Alizadeh → 900771 "Alireza Alizadeh" (persiangulf yellow; fa is
#                the honest EN fallback so the FA query يانلت-style does
#                NOT hit — pinned as 0 rows, NOT a gate)
#   /player/688273 h1 = «ویتالی یانلت» (pinned 200 + h1 before the gate)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
A_OUT=$(python3 - <<'PY'
import json, urllib.parse, urllib.request
BASE = "http://localhost:3000"
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

def search(q):
    d = get(BASE + "/api/search?q=" + urllib.parse.quote(q))
    return d.get("players") or []

# A1: the pl yellow leader is searchable — Janelt pin (byte-exact probe)
try:
    ps = search("Janelt")
    r = next((x for x in ps if x.get("playerId") == 688273), None)
    good = bool(r) and r.get("fa") == "ویتالی یانلت" and r.get("teamFa") == "برنتفورد" and r.get("leagueKey") == "pl"
    report("A1 q=Janelt hits 688273", good, f"n={len(ps)} fa={r and r.get('fa')}/{r and r.get('teamFa')}")
except Exception as e:
    report("A1 q=Janelt hits 688273", False, repr(e))

# A2: the FA alias path — «یانلت» hits the SAME pid (accent/alias lesson)
try:
    ps = search("یانلت")
    good = any(x.get("playerId") == 688273 for x in ps)
    report("A2 FA یانلت same hit", good, f"n={len(ps)}")
except Exception as e:
    report("A2 FA یانلت same hit", False, repr(e))

# A3: the red kind folded too + honest EN fallback — mas red leader
try:
    ps = search("Mazlan")
    r = next((x for x in ps if x.get("playerId") == 694010), None)
    good = bool(r) and r.get("fa") == "Fazly Mazlan" and r.get("leagueKey") == "mas"
    report("A3 q=Mazlan red kind EN fallback", good, f"n={len(ps)} fa={r and r.get('fa')}")
except Exception as e:
    report("A3 q=Mazlan red kind EN fallback", False, repr(e))

# A4: strong gate — 688273 is in NO pl surface except cards (the 174 pattern)
try:
    d = get(BASE + "/api/standings?league=pl")
    sids = {x.get("playerId") for x in (d.get("scorers") or [])}
    aids = {x.get("playerId") for x in (d.get("assists") or [])}
    c = d.get("cards") or {}
    cids = {x.get("playerId") for x in (c.get("yellow") or [])} | {x.get("playerId") for x in (c.get("red") or [])}
    good = (688273 not in sids) and (688273 not in aids) and (688273 in cids)
    report("A4 Janelt only-in-cards", good, f"scorers={688273 in sids} assists={688273 in aids} cards={688273 in cids}")
except Exception as e:
    report("A4 Janelt only-in-cards", False, repr(e))

# A5: second strong gate — persiangulf yellow leader only-in-cards too
try:
    ps = search("Alizadeh")
    hit = any(x.get("playerId") == 900771 for x in ps)
    d = get(BASE + "/api/standings?league=persiangulf")
    sids = {x.get("playerId") for x in (d.get("scorers") or [])}
    aids = {x.get("playerId") for x in (d.get("assists") or [])}
    c = d.get("cards") or {}
    cids = {x.get("playerId") for x in (c.get("yellow") or [])} | {x.get("playerId") for x in (c.get("red") or [])}
    good = hit and (900771 not in sids) and (900771 not in aids) and (900771 in cids)
    report("A5 Alizadeh only-in-cards", good, f"hit={hit} scorers={900771 in sids} assists={900771 in aids} cards={900771 in cids}")
except Exception as e:
    report("A5 Alizadeh only-in-cards", False, repr(e))

# A6: legacy pool byte-parity — the 166/171 surfaces survive the fold
try:
    ps1 = search("صیادمنش")
    ps2 = search("Dybala")
    g1 = any(x.get("playerId") == 887680 for x in ps1)
    g2 = any(x.get("playerId") == 325916 for x in ps2)
    good = g1 and g2
    report("A6 legacy rows survive", good, f"saiedmanesh={g1} dybala={g2}")
except Exception as e:
    report("A6 legacy rows survive", False, repr(e))

# A7: dead-id sweep — zero folded rows with playerId<=0 across queries
try:
    bad = 0
    for q in ("Janelt", "Mazlan", "Alizadeh", "Rice", "دیبالا", "صیادمنش", "card"):
        for x in search(q):
            pid = x.get("playerId")
            if pid is None or pid <= 0:
                bad += 1
    good = bad == 0
    report("A7 dead-id sweep", good, f"badRows={bad}")
except Exception as e:
    report("A7 dead-id sweep", False, repr(e))

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
dom_search "Janelt" "ویتالی یانلت" "B1 UI Janelt → yellow-leader row"
dom_search "Mazlan" "Fazly Mazlan" "B2 UI Mazlan → red-leader row (EN fallback)"
dom_search "صیادمنش" "اللهیار صیادمنش" "B3 UI صیادمنش legacy guard"

# B4: REAL click-through — Janelt row → /player/688273 with Persian h1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Janelt');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('ویتالی یانلت'))" >/dev/null 2>&1
sleep 1
CLICKED=$($B eval '(function(){const btns=[...document.querySelectorAll("div[role=\"dialog\"] ul li button")];const hit=btns.find(b=>(b.innerText||"").includes("ویتالی یانلت"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/688273')" >/dev/null 2>&1
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
case "$URL" in /player/688273*) : ;; *) B4_RC=1 ;; esac
echo "$H1" | grep -q "یانلت" || B4_RC=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B4_RC=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B4_RC=1
echo "B4 click-through Janelt → URL=$URL h1=$H1 | $OUT | console=$C appErrors=$E rc=$B4_RC"
[ "$B4_RC" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-177: the «کارت‌ها» block joins the player-search pool — Janelt 688273/Mazlan 694010/Alizadeh 900771 class searchable, both kinds folded, honest EN nameFa fallback, dead-id guard, legacy 166/171 rows byte-identical, zero extra upstream fetches)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
