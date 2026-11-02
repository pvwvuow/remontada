#!/bin/bash
# cycle434-domproof.sh — the day-nav mount-gate (Fix cycle 434)
#
# The bug (432 finding, 433-verified): the statically prerendered home shell
# froze the BUILD-time Tehran date into the day-nav chips — weekday words and
# Jalali day digits inside 15 SSR'd buttons — so any fresh load after the next
# Tehran midnight re-forked the HTML against the fresh client render: the
# deterministic React #418 hydration text mismatch. The pinned re-break was
# 2026-11-04 00:00 Tehran.
#
# The fix: mount-gate the chips per the 424 freshness-label pattern — the
# date-derived slots (weekday/day) stay EMPTY until mount, so the server
# render and the first client render are byte-identical at ANY build/load
# pair; the deferred mounted pass populates the live values. «امروز» is the
# stable isToday label and stays SSR'd.
#
# Witness design:
#   A. the served shell is TIME-INVARIANT: the strip has 15 buttons and the
#      stable «امروز» label but ZERO Persian digits and ZERO weekday words —
#      nothing date-derived is frozen anymore, at any build clock.
#   B. the hydration gate-flip: the served HTML's day slots are EMPTY spans
#      while the hydrated DOM is fully populated, and the populated values
#      byte-match an INDEPENDENT python gregorian→jalali replica of the live
#      Tehran date (not the repo's TS code, not Intl, not the build clock).
#   C. interaction intact: chip click moves aria-pressed + the day heading
#      updates post-hydration (no mismatch) and returns clean.
#   D. the 432/433 witness day /?date=2026-10-27 loads with zero errors —
#      the load that used to fire #418 at a midnight-crossing build.
#   E. hygiene: console 0 / page errors 0 / scrollW=390 / h1 present on both
#      loads (per-page buffer clears — the 432 cumulative-buffer lesson).
#
# agent-browser eval output convention (this harness): the CLI prints JSON
# with the inner quotes backslash-escaped ({"n":15,"today":"امروز"}); every
# read goes through ab_json() which un-escapes and extracts a field — never
# tr -d '"' (the 434 first-run lesson: it shreds the JSON into \-rubble).
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/home/z/my-project/remontada/scripts/cycle434-results.txt
: > "$OUT"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1" >> "$OUT"; echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 :: $2" >> "$OUT"; echo "FAIL $1 :: $2"; }
AB="agent-browser"

# occurrence count of $2 in the string $1 (grep -c counts LINES — the strip
# is one minified line; the 434 first-run lesson)
cnt() { printf '%s' "$1" | python3 -c "import sys;print(sys.stdin.read().count(sys.argv[1]))" "$2"; }

# $1 = raw agent-browser eval output, $2 = JSON key → prints the field value
# (quoted heredoc + argv: inside a bash double-quoted -c string the escape
# levels shift — the 434 second-run lesson: '\\"' in the file became '"'
# by the time python saw it, silently no-oping the unescape)
abf() {
  python3 - "$1" "$2" <<'PYEOF'
import json, sys
s = sys.argv[1].strip()
if s.startswith('"') and s.endswith('"'):
    s = s[1:-1]
s = s.replace('\\"', '"')
print(json.loads(s)[sys.argv[2]])
PYEOF
}

STRIP_MARK='flex gap-2 overflow-x-auto pb-1.5'
extract_strip() { # $1 = html file path
python3 - "$1" <<'PY'
import sys
h = open(sys.argv[1], encoding='utf-8').read()
i = h.find('flex gap-2 overflow-x-auto pb-1.5')
k = h.find('role="group"', i)
print(h[i:k] if i >= 0 and k > i else "")
PY
}

# the independent jalali replica (python, standalone algorithm — NOT the repo's
# gregorianToJalali, NOT Intl): jd|month-name|weekday-name of a Tehran day
jalali_replica() { # $1 = optional YYYY-MM-DD, else now
python3 - "${1:-now}" <<'PY'
import sys, datetime, zoneinfo
def g2j(gy, gm, gd):
    g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    gy2 = gy + 1 if gm > 2 else gy
    days = 355666 + 365 * gy + (gy2 + 3) // 4 - (gy2 + 99) // 100 + (gy2 + 399) // 400 + gd + g_d_m[gm - 1]
    jy = -1595 + 33 * (days // 12053); days %= 12053
    jy += 4 * (days // 1461); days %= 1461
    if days > 365:
        jy += (days - 1) // 365; days = (days - 1) % 365
    if days < 186:
        jm, jd = 1 + days // 31, 1 + days % 31
    else:
        jm, jd = 7 + (days - 186) // 30, 1 + (days - 186) % 30
    return jy, jm, jd
FA_W = ["یکشنبه", "دوشنبه", "سه\u200cشنبه", "چهارشنبه", "پنجشنبه", "جمعه", "شنبه"]  # JS getDay: 0=Sun
FA_M = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"]
arg = sys.argv[1]
tz = zoneinfo.ZoneInfo("Asia/Tehran")
now = datetime.datetime.now(tz)
d = datetime.date.fromisoformat(arg) if arg != "now" else now.date()
n = (d - datetime.date(1970, 1, 1)).days  # 1970-01-01 = Thursday; JS day = (n+4)%7
js_day = (n + 4) % 7
jy, jm, jd = g2j(d.year, d.month, d.day)
dg = str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹")
print(f"{str(jd).translate(dg)}|{FA_M[jm-1]}|{FA_W[js_day]}")
PY
}

CHIPS_JS='(()=>{const b=[...document.querySelectorAll("button")].filter(x=>(x.className||"").includes("min-w-[62px]"));const t=b[7];if(!t)return JSON.stringify({err:"no chips"});return JSON.stringify({n:b.length,today:t.children[0].textContent.trim(),day:t.children[1].textContent.trim(),nonEmpty:b.filter(x=>x.children[1]&&x.children[1].textContent.trim()).length,p1w:b[8]?b[8].children[0].textContent.trim():"",p1d:b[8]?b[8].children[1].textContent.trim():"",act:b.findIndex(x=>x.getAttribute("aria-pressed")==="true")})})()'

echo "== A. the time-invariant shell (served prerendered HTML) =="
curl -s "$BASE/" > /tmp/c434-served.html
[ -s /tmp/c434-served.html ] && ok "A0 served / HTML fetched ($(stat -c%s /tmp/c434-served.html) bytes)" || bad "A0 fetch" "empty"
extract_strip /tmp/c434-served.html > /tmp/c434-served-strip.html
STRIP=$(cat /tmp/c434-served-strip.html)
NB=$(cnt "$STRIP" "<button")
[ "$NB" = "15" ] && ok "A1 strip has 15 chips in the served shell" || bad "A1 chip count" "$NB"
AM=$(cnt "$STRIP" "امروز")
[ "$AM" = "1" ] && ok "A2 the stable «امروز» label stays SSR'd (exactly 1)" || bad "A2 امروز count" "$AM"
DIG=$(cnt "$STRIP" "۰"); for d in ۱۲۳۴۵۶۷۸۹; do DIG=$((DIG + $(cnt "$STRIP" "$d"))); done
[ "$DIG" = "0" ] && ok "A3 strip freezes ZERO Persian digits (the 00:16 build froze 11)" || bad "A3 digits in strip" "$DIG"
WDHIT=$(printf '%s' "$STRIP" | python3 -c "
import sys
h=sys.stdin.read()
ws=['دوشنبه','سه\u200cشنب','چهارشن','پنجشنب','جمعه','شنبه','یکشن']
print(';'.join(w for w in ws if w in h))")
[ -z "$WDHIT" ] && ok "A4 strip freezes ZERO weekday words (the 00:16 build froze 7)" || bad "A4 weekdays in strip" "$WDHIT"
EMPTY=$(cnt "$STRIP" '<span class="text-sm font-black tabular-persian"></span>')
EMPTYT=$(cnt "$STRIP" '<span class="text-sm font-black tabular-persian text-primary"></span>')
[ $((EMPTY + EMPTYT)) = "15" ] && ok "A5 all 15 day slots are EMPTY spans in the shell (gate-closed bytes; 14 plain + 1 text-primary)" || bad "A5 empty slots" "$((EMPTY + EMPTYT))/15"
extract_strip .next/server/app/index.html > /tmp/c434-artifact-strip.html
if [ -s /tmp/c434-artifact-strip.html ] && cmp -s /tmp/c434-served-strip.html /tmp/c434-artifact-strip.html; then
  ok "A6 served strip byte-equals the build artifact strip (no runtime injection)"
else
  bad "A6 strip byte-equality" "served vs artifact differ"
fi

echo "== B. the hydration gate-flip (agent-browser 390×844) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >> "$OUT" 2>&1
CH=""
for i in $(seq 1 20); do
  RAW=$($AB eval "$CHIPS_JS" 2>/dev/null)
  [ -n "$RAW" ] && ! printf '%s' "$RAW" | grep -q 'no chips' && CH="$RAW" && break
  sleep 1
done
echo "   hydrated chips: $CH"
N=$(abf "$CH" n); TODAY=$(abf "$CH" today); DAY=$(abf "$CH" day)
NONEMPTY=$(abf "$CH" nonEmpty); P1W=$(abf "$CH" p1w); P1D=$(abf "$CH" p1d)
[ "$N" = "15" ] && ok "B1 15 chips in the hydrated DOM" || bad "B1 chip count" "$N"
REP=$(jalali_replica)
EXP_DAY=$(echo "$REP" | cut -d'|' -f1); EXP_MON=$(echo "$REP" | cut -d'|' -f2); EXP_WD=$(echo "$REP" | cut -d'|' -f3)
echo "   replica(Tehran now): day=$EXP_DAY month=$EXP_MON weekday=$EXP_WD"
[ "$TODAY" = "امروز" ] && ok "B2 today chip label «امروز» after the flip" || bad "B2 today label" "$TODAY"
[ "$DAY" = "$EXP_DAY" ] && ok "B3 today chip day byte-equals the independent replica ($DAY)" || bad "B3 today day" "DOM='$DAY' replica='$EXP_DAY'"
[ "$NONEMPTY" = "15" ] && ok "B4 all 15 day slots populated after mount (the gate opened)" || bad "B4 populated" "$NONEMPTY/15"
TOM_ISO=$(TZ=Asia/Tehran date -d '+1 day' +%F)
REP_TOM=$(jalali_replica "$TOM_ISO")
EXP_P1W=$(echo "$REP_TOM" | cut -d'|' -f3 | python3 -c "import sys;print(sys.stdin.read().strip()[:6])")
EXP_P1W_FULL=$(echo "$REP_TOM" | cut -d'|' -f3)
EXP_P1D=$(echo "$REP_TOM" | cut -d'|' -f1)
[ "$P1W" = "$EXP_P1W" ] && ok "B5 +1 chip weekday byte-equals tomorrow's replica slice ('$P1W')" || bad "B5 +1 weekday" "DOM='$P1W' replica='$EXP_P1W'"
[ "$P1D" = "$EXP_P1D" ] && ok "B6 +1 chip day byte-equals tomorrow's replica ($P1D)" || bad "B6 +1 day" "DOM='$P1D' replica='$EXP_P1D'"

echo "== C. interaction intact post-hydration =="
$AB eval '(()=>{const b=[...document.querySelectorAll("button")].filter(x=>(x.className||"").includes("min-w-[62px]"));b[8].click();return "clicked"})()' >/dev/null 2>&1
sleep 1
ACT=$($AB eval "$CHIPS_JS" 2>/dev/null)
ACTI=$(abf "$ACT" act)
HEAD=$($AB eval '(()=>{const p=[...document.querySelectorAll("p")].find(x=>x.textContent.trim().startsWith("بازی‌های"));const sp=p?p.querySelector("span"):null;return JSON.stringify({h:sp?sp.textContent.trim():""})})()' 2>/dev/null)
HEADV=$(abf "$HEAD" h)
[ "$ACTI" = "8" ] && ok "C1 chip click moves aria-pressed to +1" || bad "C1 pressed index" "$ACTI"
EXP_HEAD="$EXP_P1W_FULL $EXP_P1D $EXP_MON"  # the heading uses the FULL weekday (the slice is chips-only, jalaliShort.weekday)
[ "$HEADV" = "$EXP_HEAD" ] && ok "C2 day heading updates to «$EXP_HEAD» (post-hydration, zero mismatch)" || bad "C2 heading" "DOM='$HEADV' exp='$EXP_HEAD'"
$AB eval '(()=>{const b=[...document.querySelectorAll("button")].filter(x=>(x.className||"").includes("min-w-[62px]"));b[7].click();return "back"})()' >/dev/null 2>&1
sleep 1
ACT2=$($AB eval "$CHIPS_JS" 2>/dev/null)
BACK=$(abf "$ACT2" act)
[ "$BACK" = "7" ] && ok "C3 returns to the امروز chip cleanly" || bad "C3 back" "$BACK"

echo "== D. the 432/433 witness day (?date=2026-10-27) — the #418 load, now clean =="
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=2026-10-27" >> "$OUT" 2>&1
sleep 2
REP27=$(jalali_replica 2026-10-27)
EXP27_D=$(echo "$REP27" | cut -d'|' -f1); EXP27_M=$(echo "$REP27" | cut -d'|' -f2); EXP27_W=$(echo "$REP27" | cut -d'|' -f3)
H27=$($AB eval '(()=>{const p=[...document.querySelectorAll("p")].find(x=>x.textContent.trim().startsWith("بازی‌های"));const sp=p?p.querySelector("span"):null;const b=[...document.querySelectorAll("button")].filter(x=>(x.className||"").includes("min-w-[62px]"));const t=b[7]?b[7].children[0].textContent.trim():"";return JSON.stringify({h:sp?sp.textContent.trim():"",today:t})})()' 2>/dev/null)
H27H=$(abf "$H27" h); H27T=$(abf "$H27" today)
[ "$H27H" = "$EXP27_W $EXP27_D $EXP27_M" ] && ok "D1 witness-day heading byte-equals the replica («$EXP27_W $EXP27_D $EXP27_M»)" || bad "D1 heading" "DOM='$H27H' exp='$EXP27_W $EXP27_D $EXP27_M'"
[ "$H27T" = "امروز" ] && ok "D2 the strip still anchors «امروز» at offset 0 on a deep-link day" || bad "D2 today chip" "$H27T"

echo "== E. hygiene three-pack on both loads =="
conerrs() { $AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))"; }
pgerrs() { $AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)"; }
CE=$(conerrs)
[ "$CE" = "0" ] && ok "E1 console errors 0 (witness day buffer)" || bad "E1 console errors" "$CE"
PE=$(pgerrs)
[ "$PE" = "0" ] && ok "E2 page errors 0 (the #418 detector, witness day)" || bad "E2 page errors" "$PE"
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >> "$OUT" 2>&1
sleep 2
SW=$($AB eval '(()=>JSON.stringify({sw:document.documentElement.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector("h1")}))()' 2>/dev/null)
SWV=$(abf "$SW" sw); VWV=$(abf "$SW" vw); H1V=$(abf "$SW" h1)
[ "$SWV" = "390" ] && [ "$VWV" = "390" ] && ok "E3 home scrollW=390 innerW=390 (no horizontal overflow)" || bad "E3 scroll" "sw=$SWV vw=$VWV"
CE2=$(conerrs)
[ "$CE2" = "0" ] && ok "E4 console errors 0 on fresh home (hydration mismatch would fire here)" || bad "E4 console" "$CE2"
PE2=$(pgerrs)
[ "$PE2" = "0" ] && ok "E5 page errors 0 on fresh home" || bad "E5 page errors" "$PE2"
[ "$H1V" = "True" ] && ok "E6 h1 present" || bad "E6 h1" "$H1V"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ] && echo "DOMPROOF 434 OK" || echo "DOMPROOF 434 BROKEN"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
