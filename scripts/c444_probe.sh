#!/usr/bin/env bash
# cycle444 probe — is the skip-link LANDING covered by the sticky header?
# 439/443 proved: first focusable / parked / revealed / jump happens.
# Never asserted: after the anchor jump, is the first row of #main-content
# VISIBLE, or painted over by the sticky top-0 z-40 header (site-chrome:99)?
# Method per page: measure header rect.bottom (HB), jump via the real link
# click from the page bottom, then measure main rect.top (MT). Covered = MT < HB.
set -u
BASE=http://localhost:3000
AB="agent-browser"
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
$AB set viewport 390 844 >/dev/null 2>&1

JS_HDR='(()=>{const h=document.querySelector("header");if(!h)return JSON.stringify({err:"no-header"});const r=h.getBoundingClientRect();const m=document.getElementById("main-content");const mr=m?m.getBoundingClientRect():null;return JSON.stringify({hb:Math.round(r.bottom),ht:Math.round(r.top),sticky:getComputedStyle(h).position,mt:mr?Math.round(mr.top):-1})})()'

for P in "/" "/league/pl" "/team/8456" "/news"; do
  $AB open "$BASE$P" >/dev/null 2>&1
  sleep 3
  R=$($AB eval "$JS_HDR" 2>/dev/null)
  HB=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" hb 2>/dev/null || echo NA)
  ST=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" sticky 2>/dev/null || echo NA)
  MT0=$(printf '%s' "$R" | abf "$(printf '%s' "$R")" mt 2>/dev/null || echo NA)
  $AB eval "window.scrollTo(0, document.body.scrollHeight)" >/dev/null 2>&1
  sleep 1
  $AB eval "(()=>{const el=document.querySelector('a[href=\"#main-content\"]');if(el)el.click();return !!el})()" >/dev/null 2>&1
  sleep 1.5
  R2=$($AB eval "JSON.stringify({mt:Math.round(document.getElementById('main-content').getBoundingClientRect().top),y:Math.round(window.scrollY)})" 2>/dev/null)
  MT=$(printf '%s' "$R2" | abf "$(printf '%s' "$R2")" mt 2>/dev/null || echo NA)
  YY=$(printf '%s' "$R2" | abf "$(printf '%s' "$R2")" y 2>/dev/null || echo NA)
  if [ "$MT" != "NA" ] && [ "$HB" != "NA" ] && [ "$MT" -lt "$HB" ] 2>/dev/null; then
    VERDICT="COVERED"
  else
    VERDICT="clear"
  fi
  echo "$P | header-bottom=$HB sticky=$ST | main-top at-rest=$MT0 | after-jump main-top=$MT scrollY=$YY | verdict=$VERDICT"
done
