#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-199 fix — the honest season marker reaches the boards header
# («برترین‌های رسمی فصل · فصل ۲۰۲۴/۲۰۲۵»).
#
# No findings came out of the 198 hunt (product bugs = 0), so per the fix
# contract this cycle ships ONE real small additive polish: SeasonBoards
# was the only major season-bearing league surface whose header did not
# reveal WHICH season the podiums describe — on a deep-linked historical
# season (/league/pl?season=2024/2025, exactly what the 196 gate B2
# exercises) the podiums switch while the title stayed ambiguous. The
# payload has carried the honest selectedSeason marker since cycle-55 and
# the sibling GlassLeagueHeader sections (آقای گل, league-view 443/752)
# already render it as a chip — the boards section now does the same,
# zero fetch, additive-only.
#
# Pin discipline (the 193 lesson): the CURRENT season's marker is pinned
# by FORM only (Persian-digit season shape — it rolls over every summer);
# the FINISHED 2024/2025 marker is pinned byte-exact (immutable). The 196
# surface must stay green underneath (xG-diff podium = Liverpool).
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (2 gates) =="
A_OUT=$(python3 - <<'PY'
import json, re, urllib.request, urllib.parse
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: the finished-season payload carries the byte-exact marker the chip renders
try:
    d = get(f"{BASE}/api/standings?league=laliga&season=" + urllib.parse.quote("2024/2025"))
    sel = d.get("selectedSeason") or ""
    good = sel == "2024/2025" and len(d.get("boards") or []) >= 25
    report("A1 finished-season marker byte-exact", good,
           f"selectedSeason={sel!r} boards={len(d.get('boards') or [])}")
except Exception as e:
    report("A1 finished-season marker byte-exact", False, repr(e))

# A2: the current payload carries a well-formed marker (FORM pin — drifts in 2027)
try:
    d = get(f"{BASE}/api/standings?league=laliga")
    sel = d.get("selectedSeason") or d.get("season") or ""
    good = bool(re.fullmatch(r"\d{4}/\d{4}", sel)) and len(d.get("boards") or []) >= 20
    report("A2 current marker form-wellformed", good, f"selectedSeason={sel!r}")
except Exception as e:
    report("A2 current marker form-wellformed", False, repr(e))

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
BOARD_CHIP='(function(){var s=document.querySelector("[data-testid=league-boards] h3");if(!s)return "no-title";var sec=s.closest("[data-testid=league-boards]");var chip=[...sec.querySelectorAll("span")].find(function(x){return /فصل [۰-۹]{4}\/[۰-۹]{4}/.test(x.innerText);});return chip?chip.innerText:"no-chip"})()'

open_page "/"
clean_ls

# B1: the CURRENT laliga page — the boards header carries a well-formed
# season chip (FORM pin) and the tabs stay alive beside it
open_page "/league/laliga"
click_tab "آمار فصل"
$B wait --fn '!!document.querySelector("[data-testid=league-boards]")' >/dev/null 2>&1
sleep 0.6
FEAT=$(snap 'chip:(function(){var s=document.querySelector("[data-testid=league-boards] h3");if(!s)return "";var sec=s.closest("[data-testid=league-boards]");var c=[...sec.querySelectorAll("span")].find(function(x){return /فصل [۰-۹]{4}\/[۰-۹]{4}/.test(x.innerText);});return c?c.innerText:"none"})(),tabs:!!document.querySelector("[data-testid=league-boards] [role=tablist]")')
B1=0
echo "$FEAT" | rg -q 'chip:فصل [۰-۹]{4}/[۰-۹]{4}' || B1=1
echo "$FEAT" | rg -q 'tabs:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 current boards header chip (form pin)" "$FEAT"
clean_ls

# B2: the FINISHED deep-linked season — byte-exact «فصل ۲۰۲۴/۲۰۲۵» AND the
# 196 surface stays green underneath (xG-diff podium head = Liverpool)
open_page "/league/pl?season=2024%2F2025"
click_tab "آمار فصل"
$B wait --fn '!!document.querySelector("[data-testid=league-boards]")' >/dev/null 2>&1
sleep 0.6
CHIPVAL=$($B eval "$BOARD_CHIP" 2>/dev/null | tr -d '"\\')
FEAT="$CHIPVAL"
B2=0
[ "$CHIPVAL" = "فصل ۲۰۲۴/۲۰۲۵" ] || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 deep-linked finished season chip byte-exact" "$FEAT"
$B eval '(function(){var b=[...document.querySelectorAll("[data-testid=league-boards] button")].find(function(x){return x.innerText.indexOf("تفاضل گل انتظاری")>=0;});if(b)b.click();return b?"clicked":"nochip"})()' >/dev/null 2>&1
sleep 0.8
FEAT=$(snap 'lead:[...document.querySelectorAll("[data-testid=league-boards] a[href^=\"/team/\"]")].map(function(a){return a.innerText;}).join("|"),chipStay:(function(){var s=document.querySelector("[data-testid=league-boards] h3");if(!s)return "";var sec=s.closest("[data-testid=league-boards]");var c=[...sec.querySelectorAll("span")].find(function(x){return x.innerText.indexOf("۲۰۲۴/۲۰۲۵")>=0;});return !!c})()')
B2=0
echo "$FEAT" | grep -q "Liverpool" || B2=1
echo "$FEAT" | rg -q 'chipStay:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2b 196 xG-diff podium co-exists, chip stays" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-199 fix proven (A 2/2 + B 3/3 @390x844): the boards header now carries the honest season marker — form-pinned on the current season, byte-exact «فصل ۲۰۲۴/۲۰۲۵» on the finished deep-link, the 196 xG-diff podium co-existing underneath"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
