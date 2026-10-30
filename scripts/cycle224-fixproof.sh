#!/bin/bash
# cycle224-fixproof.sh — permanent gate for the cycle-224 fix
# (Fix (cycle 224): the 223 hunt's ONE registered finding — the search player
#  pool (166 scorers / 171 assists / 177 cards / 194 historical folds) never
#  folded the deep-file family blocks (ratings 210 / cleanSheets 215 / gPlusA
#  216 / goalsPrevented 217 / minutes 220 / savePercentage 221 / savesPer90
#  222) that ride the VERY SAME cached getStandings payload. The fix folds all
#  seven blocks after the cards with the same seen-set mechanics — ZERO extra
#  upstream fetches. Supersedes cycle223-hunt.sh A1/B5c (which asserted the
#  gap AS FOUND — their bad-branches say "if 224 landed, the fixproof rules").
# Part A (API, live-observed 2026-10-30):
#   A1 THE FIX: the 223 trio «والس»/«رادو»/«موریچ» each return ≥1 player;
#      Vallés row == (999171, «آلوارو والس») — the 223-pinned live profile id
#   A2 the fold class BREADTH: cleanSheets-only king «خوان گارسیا» (1167220)
#      + persiangulf minutes king «میثم تیموری» (863678) both hit
#   A3 zero-regression controls: صیادمنش ≥1 + امباپه ≥2 (Ethan + Kylian)
#   A4 honesty: a deep fold row carries NO goals key (ratings/counts/minutes
#      are not goals — the 194 convention, JSON omits undefined)
#   A5 seen-set single-listing: «رافینیا» (in scorers AND ratings AND gPlusA
#      of laliga) appears EXACTLY once (playerId 696679)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 search dialog «والس» renders the بازیکنان row «آلوارو والس» — the
#      not-found hint («با این نام پیدا نشد») ABSENT (223 B5c flipped)
#   B2 Enter on the row navigates to /player/999171 with profile h1
#   B3 console=0 errors=0 across the whole session
set -u
BASE="${BASE:-http://localhost:3000}"
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 THE FIX — the 223 trio now searchable (was players=0 before the fold)
A1=1
declare -A VALL
QN=$(curl -s "$BASE/api/search?q=$(enc "والس")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
v=[p for p in ps if p['playerId']==999171]
print(len(ps), bool(v) and v[0]['fa']=='آلوارو والس', v[0].get('leagueFa','') if v else '-')
" )
echo "$QN" | py "
import sys
tok=sys.stdin.read().split()
n=int(tok[0]); hit=tok[1]=='True'
sys.exit(0 if n>=1 and hit else 1)
" && ok "A1a «والس» → $(echo "$QN" | awk '{print $1}') player(s) incl. (999171, آلوارو والس) — the 223-pinned profile" || bad "A1a: $QN"
for Q in "رادو" "موریچ"; do
  N=$(curl -s "$BASE/api/search?q=$(enc "$Q")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
  [ "$N" -ge 1 ] || A1=0
done
[ "$A1" = "1" ] && ok "A1b «رادو»/«موریچ» each ≥1 player — the whole 223 trio flipped from players=0" || bad "A1b: trio incomplete"

# A2 the fold class BREADTH beyond the trio (cleanSheets-only + minutes-only kings)
G=$(curl -s "$BASE/api/search?q=$(enc "خوان گارسیا")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
h=[p for p in ps if p['playerId']==1167220]
print('GC', bool(h) and h[0]['fa']=='خوان گارسیا')
")
echo "$G" | grep -q "GC True" && ok "A2a cleanSheets-only king «خوان گارسیا» (1167220) searchable" || bad "A2a: $G"
T=$(curl -s "$BASE/api/search?q=$(enc "میثم تیموری")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
h=[p for p in ps if p['playerId']==863678]
print('MT', bool(h) and h[0]['fa']=='میثم تیموری')
")
echo "$T" | grep -q "MT True" && ok "A2b persiangulf minutes king «میثم تیموری» (863678) searchable" || bad "A2b: $T"

# A3 zero-regression controls
C1=$(curl -s "$BASE/api/search?q=$(enc "صیادمنش")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
C2=$(curl -s "$BASE/api/search?q=$(enc "امباپه")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
[ "$C1" -ge 1 ] && [ "$C2" -ge 2 ] && ok "A3 controls intact: صیادمنش=$C1 / امباپه=$C2 (Ethan+Kylian)" || bad "A3: $C1/$C2"

# A4 honesty: a deep fold row carries NO goals key (the 194 convention)
H=$(curl -s "$BASE/api/search?q=$(enc "والس")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
v=[p for p in ps if p['playerId']==999171]
print('GOALSLIE', bool(v) and ('goals' in v[0]))
")
echo "$H" | grep -q "GOALSLIE False" && ok "A4 honesty: the deep fold row carries NO goals key (ratings/counts are not goals)" || bad "A4: $H"

# A5 seen-set single-listing: Raphinha rides scorers+ratings+gPlusA of laliga
R=$(curl -s "$BASE/api/search?q=$(enc "رافینیا")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
n=sum(1 for p in ps if p['playerId']==696679)
print('RAP', n)
")
echo "$R" | grep -q "RAP 1" && ok "A5 seen-set: «رافینیا» (scorers AND ratings AND gPlusA) listed EXACTLY once" || bad "A5: $R"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
agent-browser eval "document.querySelector('button[aria-label*=جست], button[class*=search], [class*=search] button')?.click(); 'OPEN'" >/dev/null
sleep 1
agent-browser eval "(() => { const inp=document.querySelector('dialog input, [role=dialog] input, input[type=search], input[type=text]'); const setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set; setter.call(inp,'والس'); inp.dispatchEvent(new Event('input',{bubbles:true})); return 'TYPED'; })()" >/dev/null
sleep 2
B1=$(agent-browser eval "(() => { const dlg=document.querySelector('dialog,[role=dialog]'); return JSON.stringify({row:(dlg?.textContent||'').includes('آلوارو والس'), notFound:(dlg?.textContent||'').includes('با این نام پیدا نشد'), groupHdr:(dlg?.textContent||'').includes('بازیکنان')}); })()")
echo "$B1" | tr -d '\\' | grep -q '"row":true' && echo "$B1" | tr -d '\\' | grep -q '"notFound":false' && echo "$B1" | tr -d '\\' | grep -q '"groupHdr":true' && ok "B1 DOM: «والس» renders the بازیکنان row «آلوارو والس» — the 223 B5c not-found hint FLIPPED absent" || bad "B1: $B1"
agent-browser eval "document.querySelector('dialog input,[role=dialog] input')?.focus(); 'F'" >/dev/null
agent-browser press Enter >/dev/null 2>&1
sleep 2.5
B2=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
echo "$B2" | tr -d '\\' | grep -q '"/player/999171"' && ok "B2 DOM: Enter navigates to the REAL profile /player/999171 ($B2)" || bad "B2: $B2"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B3 console=0 errors=0 across the whole session" || bad "B3: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE224 FIXPROOF ALL GREEN (the deep-file family folded into the search pool — the 223 trio + class-breadth kings searchable, controls/honesty/single-listing intact, DOM flipped @390x844)" && exit 0
exit 1
