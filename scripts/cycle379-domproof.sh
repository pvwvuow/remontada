#!/usr/bin/env bash
# cycle379-domproof.sh — fix cycle 379: verifies the two bug-hunt-378 findings
# are FIXED, at 390x844, with HARD checks (the 378 K1/K2 informational probes
# flipped per their own contract):
#   F1 — ASCII digits in the two uncovered score rows (league-view.tsx:89
#        FixtureRow showResult / league-bracket.tsx:24 LegRow) now render
#        faDigits like the rest of the portal (matches-view convention).
#        HARD: on PL «نتایج اخیر», dfbpokal bracket, dfbpokal historical
#        bracket and UCL historical bracket — every score span Persian
#        (ascii=0, persian==n, n>0).
#   F2 — Latin leak «Darmstadt» in the dfbpokal bracket (matchup+leg level)
#        now maps via TEAM_FA («دارمشتات»). HARD: API JSON + DOM both
#        Darmstadt-free with the Persian name present.
# Sanity: the touched contracts (376/377 cups, PL table path) unchanged.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

fresh() { agent-browser close --all >/dev/null 2>&1; agent-browser open "$1" >/dev/null 2>&1; agent-browser set viewport 390 844 >/dev/null 2>&1; agent-browser errors --clear >/dev/null 2>&1; agent-browser console --clear >/dev/null 2>&1; sleep 3; }
hygiene() { # $1=label
  local ERR CON SW CW
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "$1 page-errors=0" "$([ -z "$ERR" ] && echo 1 || echo 0)"
  ck "$1 console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "$1 scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "390" ] && [ "$CW" = "390" ] && echo 1 || echo 0)"
}
# score-span census: spans shaped «X : Y» (X/Y digits ASCII or Persian, or «—»)
# returns pipe-separated n|ascii|persian (no JSON — tr-safe, 378 K1 lesson)
scoreCensus() { agent-browser eval "(() => { const spans=[...document.querySelectorAll('span')].map(s=>s.textContent.trim()).filter(t=>/^[0-9\u06F0-\u06F9]+ : [0-9\u06F0-\u06F9]+$|^\u2014 : \u2014$/.test(t)); return [spans.length, spans.filter(t=>/[0-9]/.test(t)).length, spans.filter(t=>/[\u06F0-\u06F9]/.test(t)).length].join('|'); })()" 2>/dev/null | tr -d '"'; }
censusCk() { # $1=label $2=n|ascii|persian  $3=min n
  local N ASC PE
  N=$(echo "$2" | cut -d'|' -f1); ASC=$(echo "$2" | cut -d'|' -f2); PE=$(echo "$2" | cut -d'|' -f3)
  ck "$1 (n=$N ascii=$ASC persian=$PE, need n≥$3 ascii=0 persian=n)" "$([ "${N:-0}" -ge "$3" ] && [ "${ASC:-1}" = "0" ] && [ "${PE:-0}" = "${N:-1}" ] && echo 1 || echo 0)"
}
dots() { agent-browser eval "(document.body.innerText.match(/[\u06F0-\u06F9]\.[\u06F0-\u06F9]/g)||[]).length" 2>/dev/null | tr -d '"'; }

# ================= API prelude =================
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
# A1 (F2 server-side): dfbpokal bracket JSON carries «دارمشتات» and zero 'Darmstadt'
D=$(api '/api/league-bracket?league=dfbpokal' | python3 -c "
import json,sys; d=json.load(sys.stdin); s=json.dumps(d, ensure_ascii=False)
ok = d.get('ok') and 'دارمشتات' in s and 'Darmstadt' not in s
b=d.get('bracket') or {}; rs=b.get('rounds') or []
ok = ok and len(rs)==1 and rs[0].get('stage')=='1/8' and len(rs[0].get('matchups',[]))==8
print(1 if ok else 0)")
ck "A1 dfbpokal bracket JSON: دارمشتات mapped, no Latin Darmstadt, R16 shape intact" "$D"
# A2 (F2 sibling sanity): 377 noTable contract untouched by the leagues.ts edit
D=$(api '/api/standings?league=dfbpokal' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and len(d.get('rows',[]))==0 and d.get('color')=='#004941' else 0)")
ck "A2 dfbpokal noTable contract intact (377)" "$D"
# A3 (F1 sibling sanity): PL table path untouched
D=$(api '/api/standings?league=pl' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and len(d.get('rows',[]))==20 and 'noTable' not in d and d['rows'][0]['name']=='Arsenal' else 0)")
ck "A3 pl table path untouched (rows20/Arsenal/no-noTable)" "$D"

# ================= P1 /league/pl — F1-a hard check (FixtureRow showResult) =================
fresh "$BASE/league/pl"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='نتایج اخیر'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
C=$(scoreCensus)
censusCk "P1 pl recent-tab score spans all Persian (F1-a FIX)" "$C" 10
D=$(dots)
ck "P1 pl zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P1 league/pl-recent"

# ================= P2 /league/dfbpokal — F1-b + F2 hard checks (LegRow + TEAM_FA) =================
fresh "$BASE/league/dfbpokal"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
DM=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('دارمشتات') && !t.includes('Darmstadt') ? 'persian-ok' : (t.includes('Darmstadt') ? 'latin-leak' : 'missing'); })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal bracket Darmstadt=دارمشتات (F2 FIX; got $DM)" "$([ "$DM" = "persian-ok" ] && echo 1 || echo 0)"
C=$(scoreCensus)
censusCk "P2 dfbpokal bracket leg scores all Persian (F1-b FIX)" "$C" 8
AG=$(agent-browser eval "(() => { const t=document.body.innerText; return (t.match(/مجموع: [۰-۹]+–[۰-۹]+/g)||[]).length; })()" 2>/dev/null | tr -d '"')
ck "P2 dfbpokal مجموع rows still Persian (got $AG)" "$([ "${AG:-0}" -ge 1 ] && echo 1 || echo 0)"
hygiene "P2 league/dfbpokal-bracket"

# ================= P3 /league/dfbpokal?season=2024/2025 — historical bracket Persian =================
fresh "$BASE/league/dfbpokal?season=2024%2F2025"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
C=$(scoreCensus)
censusCk "P3 dfbpokal historical bracket leg scores all Persian" "$C" 15
hygiene "P3 league/dfbpokal-historical"

# ================= P4 /league/ucl?season=2025/2026 — the 378 F1 proof site (90/90 ASCII) now Persian =================
fresh "$BASE/league/ucl?season=2025%2F2026"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
C=$(scoreCensus)
censusCk "P4 ucl 2025/2026 bracket leg scores all Persian (378 K1 proof site)" "$C" 30
hygiene "P4 league/ucl-historical-bracket"

# ================= P5 home sanity =================
fresh "$BASE/"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()?.slice(0,60)" 2>/dev/null | tr -d '"')
hygiene "P5 home"
ck "P5 home h1 rendered («$H1»)" "$([ -n "$H1" ] && echo 1 || echo 0)"

# ================= P6 /match/5868114 sanity (FixtureRow-independent score path untouched) =================
fresh "$BASE/match/5868114"
D=$(dots)
ck "P6 match zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P6 match/5868114"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
