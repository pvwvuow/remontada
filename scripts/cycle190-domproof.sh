#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-190 update — the match stats go half-by-half («آمار
# نیمه‌به‌نیمه») — the whole stat table joins the 187 zones family
#
# The cycle-97/187 arc surfaced the attacking zones per period; the
# SAME upstream payload carries Periods.All/FirstHalf/SecondHalf for the
# ENTIRE stat table (probed UA Chrome/124 2026-10-30: 5749721 +
# 5749727 each carry all 7 group titles per period) and the site
# normalized only All. This cycle closes it: the stat-table mapping is
# extracted into one helper; statGroups (All) stays byte-identical and
# a NEW optional statPeriods key carries firstHalf/secondHalf groups —
# a half key exists only when its upstream block yields ≥1 non-empty
# group (honest per-period omission, the 187 zones contract family).
# The stats tab grows a pill switcher (کل بازی / نیمهٔ اول / نیمهٔ دوم)
# rendered ONLY when a half exists — «کل بازی» default keeps the
# pre-190 view byte-identical.
#
# Pinned live truth (probed 2026-10-30 ~11:3x +08, UA Chrome/124,
# official start after the cycle-190 build):
#   /api/match/5749727 (Sassuolo–Lazio)
#     statPeriods both halves 7 groups each; fh possession 52/48 +
#     xG 0.72/1.18؛ sh possession 34/66 + xG 0.04/2.39؛
#     statGroups (All) r0 possession 42/58 — 7 titles unchanged
#   /api/match/5749721 (Roma–Cagliari)
#     fh 62/38 + xG 1.28/1.43؛ sh 59/41 + xG 1.60/1.19؛ All 61/39
#   /api/match/5868120 (upcoming)  statPeriods = null (honest)
#   row shape parity: {away,awayVal,graph,home,homeVal,key,title}
# DOM @390x844 (the 187 gate lesson: click the tab, wait AFTER click):
#   /match/5749727 stats tab → 3 pills → REAL click «نیمهٔ دوم» →
#     the pill goes aria-pressed AND the possession header shows «۳۴»
#     (second-half 34/66 — All shows «۴۲») → back to «کل بازی» → «۴۲»
#   /match/5868120 stats tab → NO pills (honest absence)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (6 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

TITLES = ["آمار کلیدی", "شوت\u200cها", "گل\u200Cهای مورد انتظار", "پاس\u200Cها", "دفاع", "دوئل\u200Cها", "انضباطی"]
ROWKEYS = ["away", "awayVal", "graph", "home", "homeVal", "key", "title"]
def row(r, t, h, a):
    return r.get("title") == t and r.get("home") == h and r.get("away") == a

# A1: 5749727 — both halves, byte-pinned possession+xG per half
try:
    d = get(BASE + "/api/match/5749727")
    sp = d.get("statPeriods")
    fh, sh = (sp or {}).get("firstHalf") or [], (sp or {}).get("secondHalf") or []
    good = sp is not None and sorted(sp.keys()) == ["firstHalf", "secondHalf"] \
        and len(fh) == 7 and [g["title"] for g in fh] == TITLES \
        and len(sh) == 7 and [g["title"] for g in sh] == TITLES \
        and row(fh[0]["rows"][0], "مالکیت توپ", "52", "48") \
        and row(fh[0]["rows"][1], "گل\u200cهای مورد انتظار (xG)", "0.72", "1.18") \
        and row(sh[0]["rows"][0], "مالکیت توپ", "34", "66") \
        and row(sh[0]["rows"][1], "گل\u200cهای مورد انتظار (xG)", "0.04", "2.39")
    report("A1 5749727 halves pinned", good,
           f"fh={len(fh)} sh={len(sh)} fh0={fh[0]['rows'][0]['home']}/{fh[0]['rows'][0]['away']} "
           f"sh0={sh[0]['rows'][0]['home']}/{sh[0]['rows'][0]['away']}")
except Exception as e:
    report("A1 5749727 halves pinned", False, repr(e))

# A2: 5749721 — the second live sample, same shape
try:
    d = get(BASE + "/api/match/5749721")
    sp = d.get("statPeriods")
    fh, sh = (sp or {}).get("firstHalf") or [], (sp or {}).get("secondHalf") or []
    good = sp is not None \
        and row(fh[0]["rows"][0], "مالکیت توپ", "62", "38") \
        and row(fh[0]["rows"][1], "گل\u200cهای مورد انتظار (xG)", "1.28", "1.43") \
        and row(sh[0]["rows"][0], "مالکیت توپ", "59", "41") \
        and row(sh[0]["rows"][1], "گل\u200cهای مورد انتظار (xG)", "1.60", "1.19")
    report("A2 5749721 halves pinned", good,
           f"fh0={fh[0]['rows'][0]['home']}/{fh[0]['rows'][0]['away']} "
           f"sh0={sh[0]['rows'][0]['home']}/{sh[0]['rows'][0]['away']}")
except Exception as e:
    report("A2 5749721 halves pinned", False, repr(e))

# A3: upcoming — honest absence (no fake half panels)
try:
    d = get(BASE + "/api/match/5868120")
    good = d.get("statPeriods") is None
    report("A3 upcoming honest absence", good, f"sp={d.get('statPeriods')}")
except Exception as e:
    report("A3 upcoming honest absence", False, repr(e))

# A4: All period byte-identical (pre-190 consumers untouched)
try:
    d = get(BASE + "/api/match/5749727")
    sg = d.get("statGroups") or []
    r0 = sg[0]["rows"][0]
    good = len(sg) == 7 and [g["title"] for g in sg] == TITLES \
        and r0.get("title") == "مالکیت توپ" and r0.get("home") == "42" and r0.get("away") == "58"
    report("A4 All period parity (42/58)", good,
           f"groups={len(sg)} r0={r0.get('home')}/{r0.get('away')}")
except Exception as e:
    report("A4 All period parity (42/58)", False, repr(e))

# A5: row shape parity — the periods reuse the EXACT stat row shape
try:
    d = get(BASE + "/api/match/5749727")
    a = (d.get("statGroups") or [{}])[0]
    b = ((d.get("statPeriods") or {}).get("secondHalf") or [{}])[0]
    ka = sorted((a.get("rows") or [{}])[0].keys())
    kb = sorted((b.get("rows") or [{}])[0].keys())
    good = ka == kb == ROWKEYS
    report("A5 row shape parity", good, f"all={ka} half={kb}")
except Exception as e:
    report("A5 row shape parity", False, repr(e))

# A6: the 187 zones sister surface intact on the same payload
try:
    d = get(BASE + "/api/match/5749727")
    z = d.get("zones") or {}
    h = z.get("home") or {}
    good = list(h.keys())[:3] == ["left", "center", "right"] \
        and "firstHalf" in h and "secondHalf" in h
    report("A6 zones sister surface intact", good, f"homeKeys={list(h.keys())}")
except Exception as e:
    report("A6 zones sister surface intact", False, repr(e))

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
  sleep 2.5
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
click_stats_tab() {
  $B eval "[...document.querySelectorAll('nav[aria-label=\"بخش\u200Cهای مسابقه\"] button')].find(b => b.textContent.trim() === 'آمار')?.click()" >/dev/null 2>&1
  sleep 1.5
}
# the first StatBars group header's home span (faDigits of rows[0].home)
first_stat_val='(function(){const hs=[...document.querySelectorAll("header")].filter(h=>h.textContent.includes("آمار کلیدی"));if(!hs.length)return "no-group";const sp=hs[0].querySelector("span");return sp?sp.textContent:"no-span"})()'

open_page "/"
clean_ls

# B1: the switcher — REAL click «نیمهٔ دوم» → the header value flips to the
# second-half possession («۳۴» = 34/66; All shows «۴۲» = 42/58); then a
# round-trip back to «کل بازی» restores «۴۲» (the 187 lesson: wait AFTER
# the tab click, not networkidle)
open_page "/match/5749727"
click_stats_tab
$B wait --fn '!!document.querySelector("[data-testid=\"stat-period-secondHalf\"]")' >/dev/null 2>&1
sleep 1
FEAT=$(snap 'allPill:!!document.querySelector("[data-testid=\"stat-period-all\"]"),fhPill:!!document.querySelector("[data-testid=\"stat-period-firstHalf\"]"),shPill:!!document.querySelector("[data-testid=\"stat-period-secondHalf\"]"),allVal:document.querySelector("[data-testid=\"stat-period-all\"]")?.getAttribute("aria-pressed")')
VAL_ALL=$($B eval "$first_stat_val" 2>/dev/null | tr -d '"\\')
B1=0
echo "$FEAT" | rg -q 'allPill:true' || B1=1
echo "$FEAT" | rg -q 'fhPill:true' || B1=1
echo "$FEAT" | rg -q 'shPill:true' || B1=1
echo "$FEAT" | rg -q 'allVal:true' || B1=1
[ "$VAL_ALL" = "۴۲" ] || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 switcher present + All=۴۲" "$FEAT | val=$VAL_ALL"

$B eval 'document.querySelector("[data-testid=\"stat-period-secondHalf\"]")?.click()' >/dev/null 2>&1
sleep 1
FEAT2=$(snap 'pressed:document.querySelector("[data-testid=\"stat-period-secondHalf\"]")?.getAttribute("aria-pressed")')
VAL_SH=$($B eval "$first_stat_val" 2>/dev/null | tr -d '"\\')
B2=0
echo "$FEAT2" | rg -q 'pressed:true' || B2=1
[ "$VAL_SH" = "۳۴" ] || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 click secondHalf → ۳۴" "$FEAT2 | val=$VAL_SH"

$B eval 'document.querySelector("[data-testid=\"stat-period-all\"]")?.click()' >/dev/null 2>&1
sleep 1
VAL_BACK=$($B eval "$first_stat_val" 2>/dev/null | tr -d '"\\')
B3=0
[ "$VAL_BACK" = "۴۲" ] || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 round-trip back to All" "val=$VAL_BACK"
clean_ls

# B4: honest absence — the upcoming match's stats tab has NO switcher and
# still renders the honest empty copy (pre-190 byte-identical view)
open_page "/match/5868120"
click_stats_tab
sleep 1
FEAT=$(snap 'noPills:!document.querySelector("[data-testid=\"stat-period-all\"]"),empty:document.body.innerText.includes("آمار پس از شروع بازی")')
B4=0
echo "$FEAT" | rg -q 'noPills:true' || B4=1
echo "$FEAT" | rg -q 'empty:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 upcoming no switcher (honest)" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-190 update proven (A 6/6 + B 4/4 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
