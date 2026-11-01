#!/usr/bin/env bash
# cycle371-domproof.sh — DOM proof for the faDecimal adoption in league-scorers-view (cycle 371).
# Pages: /topscorers/pl (the dir=ltr mirror file's route), /topscorers/ucl, /topscorers (global).
# Assertions per page: page errors 0, console errors 0, scrollW==cw==390,
# zero ASCII-dot numerals (fa digit + '.' + fa digit) in the rendered text,
# and on /topscorers/pl: a real ٫ decimal visible + sample pill transcription.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

fresh() { agent-browser close --all >/dev/null 2>&1; agent-browser open "$1" >/dev/null 2>&1; agent-browser set viewport 390 844 >/dev/null 2>&1; agent-browser errors --clear >/dev/null 2>&1; agent-browser console --clear >/dev/null 2>&1; sleep 2; }

# ---- P1 /topscorers/pl ----
fresh "$BASE/topscorers/pl"
ERR=$(agent-browser errors 2>/dev/null | tr -d '"')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
ck "P1 pl page-errors=0" "$([ -z "$ERR" ] || [ "$ERR" = "[]" ] && echo 1 || echo 0)"
ck "P1 pl console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
DOTS=$(agent-browser eval "document.body.innerText.match(/[\u06F0-\u06F9]\.[\u06F0-\u06F9]/g)?.length ?? 0" 2>/dev/null | tr -d '"')
ck "P1 pl zero ASCII-dot numerals (got $DOTS)" "$([ "$DOTS" = "0" ] && echo 1 || echo 0)"
SEPS=$(agent-browser eval "document.body.innerText.match(/[\u06F0-\u06F9]\u066B[\u06F0-\u06F9]/g)?.length ?? 0" 2>/dev/null | tr -d '"')
ck "P1 pl Persian-separator decimals present (got $SEPS)" "$([ "${SEPS:-0}" -ge 1 ] && echo 1 || echo 0)"
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
ck "P1 pl scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "$CW" ] && [ "$SW" = "390" ] && echo 1 || echo 0)"

# ---- P2 /topscorers/ucl ----
fresh "$BASE/topscorers/ucl"
ERR=$(agent-browser errors 2>/dev/null | tr -d '"')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
DOTS=$(agent-browser eval "document.body.innerText.match(/[\u06F0-\u06F9]\.[\u06F0-\u06F9]/g)?.length ?? 0" 2>/dev/null | tr -d '"')
ck "P2 ucl page-errors=0 + console=0 + zero dots (dots=$DOTS)" "$([ -z "$ERR" ] && [ "$CON" = "0" ] && [ "$DOTS" = "0" ] && echo 1 || echo 0)"
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
ck "P2 ucl scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "$CW" ] && [ "$SW" = "390" ] && echo 1 || echo 0)"

# ---- P3 /topscorers global ----
fresh "$BASE/topscorers"
ERR=$(agent-browser errors 2>/dev/null | tr -d '"')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
DOTS=$(agent-browser eval "document.body.innerText.match(/[\u06F0-\u06F9]\.[\u06F0-\u06F9]/g)?.length ?? 0" 2>/dev/null | tr -d '"')
ck "P3 global page-errors=0 + console=0 + zero dots (dots=$DOTS)" "$([ -z "$ERR" ] && [ "$CON" = "0" ] && [ "$DOTS" = "0" ] && echo 1 || echo 0)"

# ---- P4 pl: transcription evidence (pill + hero badge) ----
fresh "$BASE/topscorers/pl"
TXT=$(agent-browser eval "document.body.innerText.slice(0, 1200)" 2>/dev/null | tr -d '"' | head -c 700)
echo "---- pl first-1200-chars sample ----"
echo "$TXT"
echo "------------------------------------"
agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
