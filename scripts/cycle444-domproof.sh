#!/usr/bin/env bash
# cycle444-domproof.sh — the fix proof for the skip-link LANDING (cycle 444).
# The fix: globals.css now gives #main-content a scroll-margin-top of 176px.
# The 439 skip link rides the native anchor jump, but the sticky top-0 header
# painted OVER the first row after the jump (probe: 4/4 routes COVERED,
# main-top=0 vs header-bottom=68/145). Because #main-content is preceded in
# the flow by ONLY the header, its offsetTop always equals the header height,
# so an oversized scroll-margin is CLAMPED and lands main exactly at the
# header's bottom edge — visible on every route, any header height.
# Sections:
#   A. the SSR/CSS surface — the rule is in the served CSS bundle AND the
#      439/443 skip-link holds are re-proven on the touched stylesheet
#   B. the live behavior at 390×844 — first-focusable / parked / revealed /
#      the FIX ITSELF: jump lands main BELOW the header bottom on 4 routes /
#      fresh-load console still zero (the 434 C12 hold)
# Harness lessons carried from 439/443: eval JSON comes back as an outer-
# quoted string with \" escapes → abf() (quoted heredoc + argv, zero bash
# escaping); grep -c counts LINES → cnt() counts occurrences.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
OUT=/tmp/c444-domproof.txt
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

echo "== A. the SSR/CSS surface (served static shell + CSS bundle) =="
curl -s --max-time 25 "$BASE/" > /tmp/c444-served.html
[ -s /tmp/c444-served.html ] && ok "A0 served / HTML fetched ($(stat -c%s /tmp/c444-served.html) bytes)" || bad "A0 fetch" "empty"
H=$(cat /tmp/c444-served.html)
# A1 the fix rule is inside the CSS the page actually loads — the home shell
# ships SEVERAL stylesheet chunks (the first one is a 748B fragment), so
# fetch ALL of them and search the merged text
printf '%s' "$H" | python3 -c "
import sys, re
h = sys.stdin.read()
hrefs = re.findall(r'<link[^>]+rel=\"stylesheet\"[^>]+href=\"([^\"]+)\"', h)
hrefs += [x for x in re.findall(r'<link[^>]+href=\"([^\"]+\.css[^\"]*)\"', h) if x not in hrefs]
print('\n'.join(hrefs))" > /tmp/c444-css-hrefs.txt
: > /tmp/c444-css-all.css
while IFS= read -r CSSHREF; do
  [ -z "$CSSHREF" ] && continue
  CSSURL="$CSSHREF"; case "$CSSHREF" in http*) ;; /*) CSSURL="$BASE$CSSHREF" ;; *) CSSURL="$BASE/$CSSHREF" ;; esac
  curl -s --max-time 25 "$CSSURL" >> /tmp/c444-css-all.css
  printf '\n' >> /tmp/c444-css-all.css
done < /tmp/c444-css-hrefs.txt
NCH=$(grep -c . /tmp/c444-css-hrefs.txt || true)
SM=$(printf '%s' "$(cat /tmp/c444-css-all.css)" | python3 -c "
import sys, re
s = sys.stdin.read()
i = s.find('#main-content')
print('yes' if i >= 0 and 'scroll-margin-top:176px' in s[max(0,i-200):i+200] else 'no')")
ck "A1 served CSS bundles (n=$NCH) carry #main-content { scroll-margin-top: 176px }" \
  "$([ "$SM" = "yes" ] && echo 1 || echo 0)" "rule=$SM merged=$(stat -c%s /tmp/c444-css-all.css 2>/dev/null)B"
# A2 the 443 hold: the link is the first anchor in the served body
FIRSTA=$(python3 - <<'PY'
h = open('/tmp/c444-served.html', encoding='utf-8').read()
b = h.find('<body')
i = h.find('<a', b)
j = h.find('</a>', i)
seg = h[i:j] if i >= 0 and j > i else ''
import re
href = re.search(r'href="([^"]*)"', seg)
print((href.group(1) if href else '') + '|' + ('yes' if 'پرش به محتوا' in seg else 'no'))
PY
)
ck "A2 (443 hold) first anchor of body = skip link → #main-content «پرش به محتوا»" \
  "$(printf '%s' "$FIRSTA" | grep -q '^#main-content|yes$' && echo 1 || echo 0)" "$FIRSTA"
ck "A3 (443 hold) park/reveal transform classes served (fixed -translate-y-16 → focus:translate-y-0)" \
  "$(printf '%s' "$H" | grep -q '\-translate-y-16' && printf '%s' "$H" | grep -q 'focus:translate-y-0' && echo 1 || echo 0)"
MC=$(cnt "$H" '<main id="main-content"')
ck "A4 (439 hold) home serves <main id=\"main-content\"> (exactly 1)" "$([ "$MC" = "1" ] && echo 1 || echo 0)" "count=$MC"
# A5 the 434 mount-gate hold re-proven on the touched stylesheet
STRIP=$(python3 - <<'PY'
h = open('/tmp/c444-served.html', encoding='utf-8').read()
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
ck "A5 (434 hold) strip time-invariant (15 chips / 1 امروز / 0 digits / 0 weekdays)" \
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
ck "B1 (443 hold) skip link is the FIRST focusable element of the page" "$([ "$V" = "skip-link" ] && echo 1 || echo 0)" "raw=${R:0:140}"
JS_REST='(()=>{const el=document.querySelector("a[href=\"#main-content\"]");if(!el)return JSON.stringify({err:"absent"});const r=el.getBoundingClientRect();return JSON.stringify({bottom:Math.round(r.bottom),pos:getComputedStyle(el).position})})()'
R=$($AB eval "$JS_REST" 2>/dev/null)
BOT=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" bottom 2>/dev/null || echo NA)
POS=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" pos 2>/dev/null || echo NA)
ck "B2 (443 hold) at rest parked ABOVE the viewport (fixed, bottom<=0)" \
  "$([ "$POS" = "fixed" ] && [ "$BOT" != "NA" ] && [ "$BOT" -le 0 ] 2>/dev/null && echo 1 || echo 0)" "bottom=$BOT pos=$POS"
$AB eval "(()=>{const el=document.querySelector('a[href=\"#main-content\"]');if(el)el.focus();return !!el})()" >/dev/null 2>&1
sleep 1
JS_FOCUS='(()=>{const el=document.querySelector("a[href=\"#main-content\"]");if(!el)return JSON.stringify({err:"absent"});const r=el.getBoundingClientRect();return JSON.stringify({bottom:Math.round(r.bottom),txt:el.textContent.trim()})})()'
R=$($AB eval "$JS_FOCUS" 2>/dev/null)
FB=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" bottom 2>/dev/null || echo NA)
FT=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" txt 2>/dev/null || echo NA)
ck "B3 (443 hold, measured POST-transition) on focus revealed as a visible chip" \
  "$([ "$FB" != "NA" ] && [ "$FB" -gt 0 ] 2>/dev/null && [ "$FT" = "پرش به محتوا" ] && echo 1 || echo 0)" "bottom=$FB txt=$FT"
# B4 THE FIX: after the anchor jump, main lands BELOW the header bottom on
# every route (before the fix: main-top=0 < header-bottom → first row COVERED)
ROUTES=("/" "/league/pl" "/team/8456" "/news")
BADR=0; DETAIL=""
for P in "${ROUTES[@]}"; do
  $AB open "$BASE$P" >/dev/null 2>&1
  sleep 2
  R=$($AB eval 'JSON.stringify({hb:Math.round(document.querySelector("header").getBoundingClientRect().bottom)})' 2>/dev/null)
  HB=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" hb 2>/dev/null || echo NA)
  $AB eval "window.scrollTo(0, document.body.scrollHeight)" >/dev/null 2>&1
  sleep 1
  $AB eval "(()=>{const el=document.querySelector('a[href=\"#main-content\"]');if(el)el.click();return !!el})()" >/dev/null 2>&1
  sleep 1.5
  R=$($AB eval 'JSON.stringify({mt:Math.round(document.getElementById("main-content").getBoundingClientRect().top),h:location.hash})' 2>/dev/null)
  MT=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" mt 2>/dev/null || echo NA)
  HS=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" h 2>/dev/null || echo NA)
  VIS=$( [ "$MT" != "NA" ] && [ "$HB" != "NA" ] && [ "$HS" = "#main-content" ] && [ "$MT" -ge $((HB - 2)) ] 2>/dev/null && echo ok || echo COVERED )
  DETAIL="$DETAIL $P(hb=$HB,mt=$MT,$VIS)"
  [ "$VIS" = "ok" ] || BADR=$((BADR+1))
done
ck "B4 THE FIX: post-jump main-top >= header-bottom on 4 routes (landing visible, hash kept)$DETAIL" \
  "$([ "$BADR" = "0" ] && echo 1 || echo 0)" "bad=$BADR"
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
ck "B5 (434 C12 hold) fresh home: console 0 / page errors 0 / scrollW=390 / h1" \
  "$([ "$PE" = "0" ] && [ "$CE" = "0" ] && [ "$SW" = "390" ] && [ "$H1" = "1" ] && echo 1 || echo 0)" \
  "console=$CE pageErrors=$PE sw=$SW h1=$H1"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
