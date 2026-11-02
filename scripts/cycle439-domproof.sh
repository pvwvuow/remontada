#!/usr/bin/env bash
# cycle439-domproof.sh — the fix proof for the a11y skip link (cycle 439).
# The fix: src/app/layout.tsx now opens every page with a keyboard skip link
# («پرش به محتوا» → #main-content) — the 438 bug-hunt probe found the site had
# NO skip mechanism at all. Every route shell (13 pages + not-found + error)
# carries <main id="main-content"> (scripts/cycle439-main-ids.py, 15/15).
# Sections:
#   A. the SSR surface — the link is served in the static shell AND the 434
#      mount-gate hold is re-proven (layout.tsx is the body-level file: if the
#      skip link had introduced any time-derived text, the strip would break)
#   B. the live behavior at 390×844 — first-focusable / parked-at-rest /
#      revealed-on-focus / jumps past the header / present on 4 routes + 404 /
#      fresh-load console still zero
# Harness lessons carried from 432/434: eval JSON comes back as an outer-
# quoted string with \" escapes → abf() (quoted heredoc + argv, zero bash
# escaping); grep -c counts LINES → cnt() counts occurrences.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
OUT=/tmp/c439-domproof.txt
: > "$OUT"
ok() { PASS=$((PASS+1)); echo "PASS $1" | tee -a "$OUT"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 :: $2" | tee -a "$OUT"; }
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1" | tee -a "$OUT"; else FAIL=$((FAIL+1)); echo "FAIL $1 :: ${3:-}" | tee -a "$OUT"; fi; }
AB="agent-browser"
cnt() { printf '%s' "$1" | python3 -c "import sys;print(sys.stdin.read().count(sys.argv[1]))" "$2"; }
abf() { # $1 = raw eval output, $2 = JSON key
  python3 - "$1" "$2" <<'PYEOF'
import json, sys
s = sys.argv[1].strip()
if s.startswith('"') and s.endswith('"'):
    s = s[1:-1]
s = s.replace('\\"', '"')
print(json.loads(s)[sys.argv[2]])
PYEOF
}

echo "== A. the SSR surface (served static shell) =="
curl -s --max-time 25 "$BASE/" > /tmp/c439-served.html
[ -s /tmp/c439-served.html ] && ok "A0 served / HTML fetched ($(stat -c%s /tmp/c439-served.html) bytes)" || bad "A0 fetch" "empty"
H=$(cat /tmp/c439-served.html)
# A1 the link is the first anchor in the served body and targets #main-content
FIRSTA=$(python3 - <<'PY'
h = open('/tmp/c439-served.html', encoding='utf-8').read()
b = h.find('<body')
i = h.find('<a', b)
j = h.find('</a>', i)
seg = h[i:j] if i >= 0 and j > i else ''
import re
href = re.search(r'href="([^"]*)"', seg)
print((href.group(1) if href else '') + '|' + ('yes' if 'پرش به محتوا' in seg else 'no'))
PY
)
ck "A1 first anchor of body = skip link → #main-content «پرش به محتوا»" \
  "$(printf '%s' "$FIRSTA" | grep -q '^#main-content|yes$' && echo 1 || echo 0)" "$FIRSTA"
ck "A2 the park/reveal transform classes served (fixed -translate-y-16 → focus:translate-y-0)" \
  "$(printf '%s' "$H" | grep -q '\-translate-y-16' && printf '%s' "$H" | grep -q 'focus:translate-y-0' && echo 1 || echo 0)"
MC=$(cnt "$H" '<main id="main-content"')
ck "A3 home serves <main id=\"main-content\"> (exactly 1)" "$([ "$MC" = "1" ] && echo 1 || echo 0)" "count=$MC"
# A4 the 434 mount-gate hold re-proven on the changed layout
STRIP=$(python3 - <<'PY'
h = open('/tmp/c439-served.html', encoding='utf-8').read()
i = h.find('flex gap-2 overflow-x-auto pb-1.5')
k = h.find('role="group"', i)
print(h[i:k] if i >= 0 and k > i else "")
PY
)
NB=$(cnt "$STRIP" "<button"); AM=$(cnt "$STRIP" "امروز")
DIG=$(cnt "$STRIP" "۰"); for d in ۱۲۳۴۵۶۷۸۹; do DIG=$((DIG + $(cnt "$STRIP" "$d"))); done
WDHIT=$(printf '%s' "$STRIP" | python3 -c "
import sys, re
s = sys.stdin.read()
print('|'.join(sorted(set(re.findall(r'(یکشنبه|دوشنبه|سه‌شنبه|چهارشنبه|پنجشنبه|جمعه|شنبه)', s)))) or '')" 2>/dev/null)
ck "A4 the 434 hold on the NEW layout: strip time-invariant (15 chips / 1 امروز / 0 digits / 0 weekdays)" \
  "$([ "$NB" = "15" ] && [ "$AM" = "1" ] && [ "$DIG" = "0" ] && [ -z "$WDHIT" ] && echo 1 || echo 0)" \
  "chips=$NB today=$AM digits=$DIG weekdays='$WDHIT'"

echo "== B. the live behavior (agent-browser, 390x844) =="
$AB set viewport 390 844 >/dev/null 2>&1
$AB errors --clear >/dev/null 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >/dev/null 2>&1
sleep 3
JS_FIRST='(()=>{const all=[...document.querySelectorAll("a[href],button,input,select,textarea,[tabindex]:not([tabindex=\"-1\"])")].filter(el=>!(el instanceof HTMLOptionElement));const f=all[0];return JSON.stringify({n:all.length,first:(f&&(f.getAttribute("href")==="#main-content")&&f.textContent.trim()==="پرش به محتوا")?"skip-link":(f?f.tagName:"none")})})()'
R=$($AB eval "$JS_FIRST" 2>/dev/null)
V=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" first 2>/dev/null || echo parse-err)
ck "B1 skip link is the FIRST focusable element of the page" "$([ "$V" = "skip-link" ] && echo 1 || echo 0)" "raw=${R:0:140}"
JS_REST='(()=>{const el=document.querySelector("a[href=\"#main-content\"]");if(!el)return JSON.stringify({err:"absent"});const r=el.getBoundingClientRect();return JSON.stringify({bottom:Math.round(r.bottom),w:Math.round(r.width),pos:getComputedStyle(el).position})})()'
R=$($AB eval "$JS_REST" 2>/dev/null)
BOT=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" bottom 2>/dev/null || echo NA)
POS=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" pos 2>/dev/null || echo NA)
ck "B2 at rest parked ABOVE the viewport (fixed, bottom<=0)" \
  "$([ "$POS" = "fixed" ] && [ "$BOT" != "NA" ] && [ "$BOT" -le 0 ] 2>/dev/null && echo 1 || echo 0)" "bottom=$BOT pos=$POS raw=${R:0:120}"
$AB eval "(()=>{const el=document.querySelector('a[href=\"#main-content\"]');if(el)el.focus();return !!el})()" >/dev/null 2>&1
sleep 1
JS_FOCUS='(()=>{const el=document.querySelector("a[href=\"#main-content\"]");if(!el)return JSON.stringify({err:"absent"});const r=el.getBoundingClientRect();return JSON.stringify({bottom:Math.round(r.bottom),top:Math.round(r.top),w:Math.round(r.width),txt:el.textContent.trim()})})()'
R=$($AB eval "$JS_FOCUS" 2>/dev/null)
FB=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" bottom 2>/dev/null || echo NA)
FW=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" w 2>/dev/null || echo NA)
FT=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" txt 2>/dev/null || echo NA)
ck "B3 on keyboard focus revealed as a visible chip («پرش به محتوا»)" \
  "$([ "$FB" != "NA" ] && [ "$FB" -gt 0 ] 2>/dev/null && [ "$FW" -ge 60 ] 2>/dev/null && [ "$FT" = "پرش به محتوا" ] && echo 1 || echo 0)" "bottom=$FB w=$FW txt=$FT"
$AB eval "window.scrollTo(0, document.body.scrollHeight)" >/dev/null 2>&1
sleep 1
PRETOP=$($AB eval "Math.round(document.getElementById('main-content').getBoundingClientRect().top)" 2>/dev/null | tr -d '"')
$AB eval "(()=>{const el=document.querySelector('a[href=\"#main-content\"]');if(el)el.click();return !!el})()" >/dev/null 2>&1
sleep 1
HASH=$($AB eval "location.hash" 2>/dev/null | tr -d '"')
POSTTOP=$($AB eval "Math.round(document.getElementById('main-content').getBoundingClientRect().top)" 2>/dev/null | tr -d '"')
ck "B4 activation jumps back to the content (scroll $PRETOP → $POSTTOP, hash=$HASH)" \
  "$([ "$HASH" = "#main-content" ] && [ -n "$POSTTOP" ] && [ "$POSTTOP" -lt 300 ] 2>/dev/null && echo 1 || echo 0)" "pre=$PRETOP post=$POSTTOP hash=$HASH"
ROUTES=("/league/pl" "/team/8456" "/news" "/no-such-page-439")
BADR=0
for P in "${ROUTES[@]}"; do
  $AB open "$BASE$P" >/dev/null 2>&1
  sleep 2
  R=$($AB eval "JSON.stringify({link:!!document.querySelector('a[href=\"#main-content\"]'),main:!!document.getElementById('main-content')})" 2>/dev/null)
  L=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" link 2>/dev/null || echo NA)
  M=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" main 2>/dev/null || echo NA)
  if [ "$L" != "True" ] || [ "$M" != "True" ]; then BADR=$((BADR+1)); echo "  !! $P link=$L main=$M"; fi
done
ck "B5 skip link + #main-content present on league/team/news/404 (bad=$BADR)" "$([ "$BADR" = "0" ] && echo 1 || echo 0)"
$AB errors --clear >/dev/null 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >/dev/null 2>&1
sleep 3
PE=$($AB errors --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    e=(d.get('data') or {}).get('errors', [])
    print(len(e) if isinstance(e,list) else 0)
except Exception: print('NA')")
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    msgs=(d.get('data') or {}).get('messages', [])
    print(sum(1 for m in msgs if isinstance(m,dict) and m.get('type') in ('error','assert')))
except Exception: print('NA')")
SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
H1=$($AB eval "document.querySelector('h1')?1:0" 2>/dev/null | tr -d '"')
ck "B6 fresh home: console 0 / page errors 0 / scrollW=390 / h1 (the 434 C12 hold)" \
  "$([ "$PE" = "0" ] && [ "$CE" = "0" ] && [ "$SW" = "390" ] && [ "$H1" = "1" ] && echo 1 || echo 0)" \
  "console=$CE pageErrors=$PE sw=$SW h1=$H1"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
