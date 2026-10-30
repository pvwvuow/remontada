#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-203 bug-hunt — patrol of the 199-202 surfaces + five NEW cross
# dimensions no prior gate combined. Product-bug contract: findings are
# REPORTED only (the fix belongs to the rotation's next cycle); zero
# src changes expected from a hunt.
#
# Surfaces: 199 (the honest boards season chip), 200 (leagues in the
# search dialog), 201 (statSeasons «رقابت‌های هر فصل» on the profile),
# 202 («خبرها» in the search dialog — warm-only fold of news:v1).
#
# D1 202 multi-section co-existence + the FULL four-section keyboard
#    span: a runtime-derived needle that hits whatever sections the
#    live data serves; ArrowDown must walk teams → رقابت‌ها → بازیکنان
#    → خبرها and land the cmd-active highlight on a news row.
# D2 202 zero-fabrication: a garbage query answers [] in ALL fields
#    (API) and the dialog keeps the 149-pinned no-match state (DOM).
# D3 201×197 profile co-existence: statSeasons + teammates + career +
#    افتخارات all alive on ONE profile (Yamal).
# D4 199×92 on a SECOND league (bundesliga): the season chip form-pin +
#    the boards family alive with /team links.
# D5 201 universality on RUNTIME-DERIVED players: the current topscorer
#    of pl and bundesliga (whatever ids the feed serves NOW) must each
#    carry a well-formed statSeasons block.
# LAT the warm-only contract: a needle search answers well inside 5s —
#    a regression into the ~20s cold producer path would blow it.
#
# All DOM: sw=cw=390, exactly 1 h1, 0 broken images, console=0, appErrors=0.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

# warm the shared feed once (the hunt must not depend on leftover warmth)
curl -s "$BASE/api/news" -o /tmp/c203_feed.json
python3 -c "
import json,sys
d=json.load(open('/tmp/c203_feed.json'))
sys.exit(0 if d.get('ok') and len(d.get('items') or [])>=1 else 1)" || { echo "FEED NOT WARM — aborting"; exit 1; }

# runtime-derived combined needle: the first popular-team fa name that
# appears in a live headline (drift-tolerant — the feed rotates)
python3 - << 'PY' > /tmp/c203_needle.env
import json, re, shlex
items = (json.load(open('/tmp/c203_feed.json')).get('items') or [])
POPULAR = ["منچستریونایتد", "رئال مادرید", "بارسلونا", "لیورپول", "آرسنال", "چلسی", "پرسپولیس", "استقلال"]
needle = ""
for it in items:
    for p in POPULAR:
        if p in (it.get("titleFa") or ""):
            needle = p
            break
    if needle: break
print(f'NEEDLE={shlex.quote(needle)}')
PY
. /tmp/c203_needle.env
echo "combined needle: ${NEEDLE:-<none — news-only fallback>}"
[ -n "$NEEDLE" ] || NEEDLE=$(python3 -c "
import json, re
t=(json.load(open('/tmp/c203_feed.json')).get('items') or [{}])[0].get('titleFa') or ''
best=''
for w in re.findall(r'[\w\u200c]+', t):
    if len(w)>len(best): best=w
print(best)")
NP_LEN=$(printf %s "$NEEDLE" | wc -m)

echo "== PART A: API proof (5 gates) =="
A_OUT=$(NEEDLE="$NEEDLE" python3 - <<'PY'
import json, os, re, time, urllib.request, urllib.parse
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
def enc(s): return urllib.parse.quote(s)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

NEEDLE = os.environ["NEEDLE"]

# LAT: the warm-only contract — a needle search answers well inside 5s
try:
    t0 = time.time()
    d = get(f"{BASE}/api/search?q={enc(NEEDLE)}")
    dt = time.time() - t0
    good = dt < 5.0 and d.get("ok") is True
    report("LAT warm-only search latency < 5s", good, f"{dt:.2f}s (cold-producer path ~20s would blow it)")
except Exception as e:
    report("LAT warm-only search latency < 5s", False, repr(e))

# D1(API): the combined needle — derive the sections the live data serves
try:
    d = get(f"{BASE}/api/search?q={enc(NEEDLE)}")
    res = d.get("results") or []
    lg = d.get("leagues") or []
    pl = d.get("players") or []
    nw = d.get("news") or []
    good = d.get("ok") is True and isinstance(d.get("news"), list) and len(nw) >= 1
    report("D1-api combined needle → news present + all four fields", good,
           f"teams={len(res)} leagues={len(lg)} players={len(pl)} news={len(nw)}")
except Exception as e:
    report("D1-api combined needle → news present + all four fields", False, repr(e))

# D2(API): zero fabrication on a garbage query — every field [] (the ≥2-char
# path carries no message by contract; the min-length message is the q<2
# path — the 200 A6 gate pins THAT one)
try:
    d = get(f"{BASE}/api/search?q=" + enc("zzqqnn"))
    good = d.get("ok") is True and d.get("results") == [] and d.get("players") == [] \
           and d.get("leagues") == [] and d.get("news") == []
    report("D2-api garbage query → all fields empty", good,
           f"r={len(d.get('results') or [])} p={len(d.get('players') or [])} l={len(d.get('leagues') or [])} n={len(d.get('news') or [])}")
except Exception as e:
    report("D2-api garbage query → all fields empty", False, repr(e))

# D5(API): 201 universality on runtime-derived players — the CURRENT
# topscorer of two OTHER catalog leagues
try:
    good_all = True
    det = []
    for key in ("pl", "bundesliga"):
        t = get(f"{BASE}/api/topscorers/{key}")
        sc = t.get("scorers") or []
        pid = sc[0].get("playerId") if sc and sc[0].get("playerId") else None
        if not pid:
            good_all = False; det.append(f"{key}:no-scorer"); continue
        p = get(f"{BASE}/api/player/{pid}")
        pl = p.get("player") or {}
        ss = pl.get("statSeasons") or []
        wf = all(re.fullmatch(r"\d{4}/\d{4}", s.get("season", "")) for s in ss) \
             and all(x.get("name") and x.get("nameFa") for s in ss for x in s.get("tournaments", []))
        chip = any(x.get("leagueKey") for s in ss for x in s.get("tournaments", []))
        if not (len(ss) >= 1 and wf and chip): good_all = False
        det.append(f"{key}:{pid}:n={len(ss)}:wf={wf}:chip={chip}")
    report("D5-api statSeasons universality on live topscorers (pl+bundesliga)", good_all, " ".join(det))
except Exception as e:
    report("D5-api statSeasons universality on live topscorers (pl+bundesliga)", False, repr(e))

# D4(API): the 199 marker on a SECOND league (bundesliga) — form pin
try:
    d = get(f"{BASE}/api/standings?league=bundesliga")
    sel = d.get("selectedSeason") or d.get("season") or ""
    good = bool(re.fullmatch(r"\d{4}/\d{4}", sel)) and len(d.get("boards") or []) >= 20
    report("D4-api bundesliga marker form + boards ≥ 20", good,
           f"selectedSeason={sel!r} boards={len(d.get('boards') or [])}")
except Exception as e:
    report("D4-api bundesliga marker form + boards ≥ 20", False, repr(e))

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
  $B eval "(function(){var b=[...document.querySelectorAll('button')].find(function(x){return x.innerText.trim().indexOf('$1')===0;});if(!b)return 'notab';b.click();return 'clicked';})()" >/dev/null 2>&1
  sleep 1.2
}
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

open_page "/"
clean_ls

# B1 (D1): the combined needle — sections per the same-moment API, then the
# keyboard walk: ArrowDown × (teams+leagues+players) must land cmd-active on
# the FIRST news row (the four-section span, the 202 order contract)
open_search
type_into "$NEEDLE"
$B wait --fn "!!document.querySelector('[data-testid=search-news]')" >/dev/null 2>&1
sleep 1.2
COUNTS=$(NEEDLE="$NEEDLE" python3 -c "
import json, os, urllib.request, urllib.parse
req = urllib.request.Request('http://localhost:3000/api/search?q=' + urllib.parse.quote(os.environ['NEEDLE']), headers={'User-Agent': 'Mozilla/5.0'})
d = json.load(urllib.request.urlopen(req, timeout=30))
print((len(d.get('results') or [])) + (len(d.get('leagues') or [])) + (len(d.get('players') or [])))")
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=search-news]"),rows:document.querySelectorAll("[data-testid=search-news] a").length,btns:[...document.querySelectorAll("[role=dialog] ul li button")].filter(function(b){return (b.innerText||"").trim().length>2;}).length')
B1=0
echo "$FEAT" | rg -q 'sec:true' || B1=1
echo "$FEAT" | rg -q 'rows:[1-9]' || B1=1
echo "$FEAT" | rg -q "btns:$COUNTS" || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 news co-exists; button rows == API teams+leagues+players ($COUNTS)" "$FEAT"
i=0
while [ "$i" -lt "$COUNTS" ]; do arrow_down; i=$((i+1)); done
sleep 0.8
FEAT=$(snap 'activeNews:!!document.querySelector("[data-testid=search-news] a.cmd-active"),activeOther:!!document.querySelector("[role=dialog] ul li button.cmd-active")')
B1=0
echo "$FEAT" | rg -q 'activeNews:true' || B1=1
echo "$FEAT" | rg -q 'activeOther:false' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1b keyboard span crosses all sections → news row active" "$FEAT"
close_search
clean_ls

# B2 (D2 DOM): garbage query keeps the 149-pinned no-match state, zero sections
open_search
type_into "zzqqnn"
$B wait --fn "(document.body.innerText||'').indexOf('پیدا نشد')>=0" >/dev/null 2>&1
sleep 1
FEAT=$(snap 'empty:(document.body.innerText||"").indexOf("پیدا نشد")>=0,sugg:(document.body.innerText||"").indexOf("شاید دنبال این تیم‌ها بودید")>=0,news:!!document.querySelector("[data-testid=search-news]"),suggbtns:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return (b.innerText||"").trim().length>1;}).length')
B2=0
echo "$FEAT" | rg -q 'empty:true' || B2=1
echo "$FEAT" | rg -q 'sugg:true' || B2=1
echo "$FEAT" | rg -q 'news:false' || B2=1
echo "$FEAT" | rg -q 'suggbtns:6' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 garbage → 149 no-match state + 6 suggestions, no sections" "$FEAT"
close_search
clean_ls

# B3 (D3): 201×197 profile co-existence — four sections alive on ONE profile
open_page "/player/1467236"
$B wait --fn '!!document.querySelector("[data-testid=player-statseasons]")' >/dev/null 2>&1
sleep 0.8
FEAT=$(snap 'ss:!!document.querySelector("[data-testid=player-statseasons]"),tm:!!document.querySelector("[data-testid=player-teammates]"),career:(document.body.innerText||"").indexOf("مسیر حرفه‌ای")>=0,hon:(document.body.innerText||"").indexOf("افتخارات")>=0,ssrows:document.querySelectorAll("[data-testid=player-statseasons] li").length')
B3=0
echo "$FEAT" | rg -q 'ss:true' || B3=1
echo "$FEAT" | rg -q 'tm:true' || B3=1
echo "$FEAT" | rg -q 'career:true' || B3=1
echo "$FEAT" | rg -q 'hon:true' || B3=1
echo "$FEAT" | rg -q 'ssrows:[2-9]' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 statSeasons+teammates+career+honours co-exist" "$FEAT"
clean_ls

# B4 (D4): the 199×92 family on a SECOND league — bundesliga boards chip
# (form pin) + a board click still yields the podium with /team links
open_page "/league/bundesliga"
click_tab "آمار فصل"
$B wait --fn '!!document.querySelector("[data-testid=league-boards]")' >/dev/null 2>&1
sleep 0.6
FEAT=$(snap 'chip:(function(){var s=document.querySelector("[data-testid=league-boards] h3");if(!s)return "";var sec=s.closest("[data-testid=league-boards]");var c=[...sec.querySelectorAll("span")].find(function(x){return /فصل [۰-۹]{4}\/[۰-۹]{4}/.test(x.innerText);});return c?c.innerText:"none"})(),pods:document.querySelectorAll("[data-testid=league-boards] a[href^=\"/team/\"]").length')
B4=0
echo "$FEAT" | rg -q 'chip:فصل [۰-۹]{4}/[۰-۹]{4}' || B4=1
echo "$FEAT" | rg -q 'pods:[2-9]' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 bundesliga boards chip form + podium links" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-203: patrol of the 199-202 surfaces — the 202 news/teams/leagues/players four-section dialog co-existence with the FULL keyboard span landing on a news row, the 202 zero-fabrication garbage path keeping the 149-pinned no-match state, the 201×197 four-section profile co-existence, the 199×92 boards family on a SECOND league (bundesliga), the 201 statSeasons universality on RUNTIME-DERIVED live topscorers of two other catalog leagues, the warm-only latency bound — API 5/5 + DOM 4/4 @390x844; product bugs = 0)"
else
  echo "HUNT BAD=$BAD"
  exit 1
fi
