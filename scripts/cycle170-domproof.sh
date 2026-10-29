#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-170 update proof — «بهترین پاس‌دهندگان» به صفحهٔ لیگ می‌پیوندد
#
# Live-probed gap (2026-10-30, UA Chrome/124): EVERY /api/standings payload
# carries an `assists` block (3 items for most leagues, [] for mas) but the
# league page dropped it — league-view.tsx had ZERO assists usage while the
# GLOBAL race page has its own «مسابقه پاس گل» card. Worse, freshenHonestNames
# freshened ONLY the team on assist items — no nameFa — so even a surfaced
# block would have shown raw English names (the 167 dead-end lesson).
#
# Additive contract: AssistEntry gains nameFa (playerFa, honest raw fallback —
# same rule as scorers since 107); freshenHonestNames maps it; ScorersList
# renders «بهترین پاس‌دهندگان» (compact 3-row list under the scorers table,
# playerId → /player Link prefetch=false + title tooltip = English original
# when Persian shown — the 107/167 contract; honest absence when the feed has
# no assists). Everything else byte-untouched.
#
# Live-truth baseline (probed before the gates were written — the D5 rule):
#   pl       = دکلن رایس 4 آرسنال (pid 654096) / Evanilson (honest raw fallback)
#              / پاسکال گروس 4 برایتون;
#   poland   = بارتوش نواک 8 گکس کاتوویتسه + پیوتر سامیتس-تالار (mapped via the
#              165 map) + Wiktor Długosz (honest raw);
#   mas      = assists [] → the section must be HONESTLY ABSENT;
#   laliga   = Javi Hernández 6 → no mapping in PLAYER_NAME_FA → raw fallback.
# ------------------------------------------------------------------
set -u
B=agent-browser
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
# A1: pl — nameFa flows (mapped + honest raw) + full item shape
try:
    d = get("http://localhost:3000/api/standings?league=pl")
    a = d.get("assists") or []
    a0, a1, a2 = (a + [{}, {}, {}])[:3]
    keys = set(a[0].keys()) if a else set()
    good = (len(a) == 3
            and a0.get("nameFa") == "دکلن رایس" and a0.get("name") == "Declan Rice"
            and a0.get("team") == "آرسنال" and a0.get("assists") == 4 and a0.get("playerId") == 654096
            and a1.get("nameFa") == "Evanilson" and a1.get("name") == "Evanilson"  # honest raw fallback
            and a2.get("nameFa") == "پاسکال گروس"
            and keys == {"rank", "name", "nameFa", "team", "teamId", "assists", "playerId"})
    report("pl assists nameFa + shape", good, f"n={len(a)} a0={a0.get('nameFa')}({a0.get('assists')}) keys={len(keys)}")
except Exception as e:
    report("pl assists", False, str(e))
# A2: poland — the 165 map reaches assists (2 mapped + 1 honest raw)
try:
    d = get("http://localhost:3000/api/standings?league=poland")
    a = d.get("assists") or []
    good = (len(a) == 3 and a[0].get("nameFa") == "بارتوش نواک"
            and a[1].get("nameFa") == "پیوتر سامیتس-تالار"
            and a[2].get("nameFa") == "Wiktor Długosz")
    report("poland assists mapped+raw", good, f"n={len(a)} {a[0].get('nameFa') if a else None}")
except Exception as e:
    report("poland assists", False, str(e))
# A3: mas — honest absence ([] → the UI section hidden)
try:
    d = get("http://localhost:3000/api/standings?league=mas")
    report("mas assists honest []", d.get("assists") == [], f"assists={d.get('assists')}")
except Exception as e:
    report("mas assists", False, str(e))
# A4: legacy byte-parity — rows/scorers untouched by the assists change
try:
    d = get("http://localhost:3000/api/standings?league=pl")
    rows = d.get("rows") or []
    sc = d.get("scorers") or []
    good = (len(rows) == 20 and len(sc) == 20 and sc[0].get("nameFa") is not None
            and rows[0].get("fa") is not None)
    report("pl legacy rows/scorers intact", good, f"rows={len(rows)} scorers={len(sc)}")
except Exception as e:
    report("pl legacy", False, str(e))

print("API_PROOF " + ("OK" if ok else "FLAGGED"))
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_PROOF OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM proof @390x844 =="
$B set viewport 390 844 >/dev/null

collect() { # $1=feat $2=label
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
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

scorers_tab() { # $1=url $2=wait-fn $3=label $4=featjs $5=clickjs(optional)
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && ($2)" >/dev/null 2>&1
  sleep 3
  [ -n "${5:-}" ] && $B eval "$5" >/dev/null 2>&1 && sleep 3
  local FEAT
  FEAT=$($B eval "JSON.stringify(($4))" 2>/dev/null | tr -d '"\\')
  collect "$FEAT" "$3"
  return 0
}

CLICK_SCORERS='(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(t)t.click();return t?"clicked":"no-tab"})()'

# B1: pl — section visible + real click through to the player profile
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.includes('لیگ')" >/dev/null 2>&1
sleep 3
$B eval "$CLICK_SCORERS" >/dev/null 2>&1
sleep 3
FEAT1=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';return {section:b.includes('بهترین پاس‌دهندگان'),rice:b.includes('دکلن رایس'),team:b.includes('آرسنال'),link:!!document.querySelector('a[href=\"/player/654096\"]'),scorersAlive:b.includes('گل')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const l=document.querySelector("a[href=\"/player/654096\"]");if(l)l.click();return l?"clicked":"no-link"})()' >/dev/null 2>&1
sleep 3
FEAT1b=$($B eval "JSON.stringify((()=>{return {url:location.pathname==='/player/654096',h1:((document.querySelector('h1')||{}).innerText||'').includes('دکلن رایس')}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT1 $FEAT1b" "B1 pl پاس‌دهندگان section + real click → /player/654096"

# B2: poland — the 165 map reaches the new section
scorers_tab "$BASE/league/poland" "document.body.innerText.includes('لخ پوزنان')" \
"B2 poland پاس‌دهندگان mapped" \
"({section:(document.body.innerText||'').includes('بهترین پاس‌دهندگان'),nowak:(document.body.innerText||'').includes('بارتوش نواک'),team:(document.body.innerText||'').includes('گکس کاتوویتسه')})" \
"$CLICK_SCORERS"

# B3: mas — honest absence (no assists feed → no section) + scorers alive
scorers_tab "$BASE/league/mas" "document.body.innerText.includes('جوهور')" \
"B3 mas پاس‌دهندگان honest-absent" \
"({sectionAbsent:!((document.body.innerText||'').includes('بهترین پاس‌دهندگان')),scorersAlive:(document.body.innerText||'').includes('کریگور')})" \
"$CLICK_SCORERS"

echo "== PART C: cross-gates (the two freshest synced gates) =="
bash scripts/cycle169-domproof.sh >/tmp/c170-g169.log 2>&1 && G169=$? || G169=$?
grep -q "DOM_PROOF OK" /tmp/c170-g169.log && grep -q "API_PROOF OK" /tmp/c170-g169.log && G169PASS=1 || G169PASS=0
echo "cycle169-domproof re-run rc=$G169 green=$G169PASS"
[ "$G169PASS" = "1" ] || BAD=$((BAD+1))
bash scripts/cycle164-digitsweep.sh >/tmp/c170-g164.log 2>&1 && G164=$? || G164=$?
grep -q "nleaks:0" /tmp/c170-g164.log && G164PASS=1 || G164PASS=0
echo "cycle164-digitsweep re-run rc=$G164 nleaks:0 green=$G164PASS"
[ "$G164PASS" = "1" ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-170: بهترین پاس‌دهندگان joins the league page — the standings assists block finally renders with honest Persian names + profile links; mas honestly absent; legacy surfaces untouched)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
