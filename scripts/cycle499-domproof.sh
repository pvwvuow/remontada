#!/usr/bin/env bash
# cycle499-domproof.sh — born cycle 499 (the fix cycle): the 494 recorded
# observation FIXED (composite clubIds from data.tables[].table.all) + the
# fresh c469-league-sweep census + the day-id trap filter verdicts.
# Sections: A in-repo static integrity · B the live API proof (mls/argentina
# now serve 100-row transfer feeds; pl flat byte-stable; ucl honest-hide) ·
# C the visible DOM at 390×844 (the «انتقال‌ها» tab PRESENT on the composite
# league pages — it was honestly-hidden before the fix) · D fresh home clean.
BASE=http://localhost:3000
AB="agent-browser"
OUT=/tmp/c499-domproof.log
: > "$OUT"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "PASS $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 :: ${2:-}"; }
# agent-browser eval prints the result as a JSON-QUOTED string (inner quotes
# escaped) — decode twice: the outer quote, then the inner JSON dict.
abjson() { python3 -c "
import json,sys
s=sys.stdin.read().strip()
try:
    d=json.loads(s)
    if isinstance(d,str): d=json.loads(d)
    print(json.dumps(d, ensure_ascii=False))
except Exception: print('{}')" 2>/dev/null; }
abfield() { python3 -c "
import json,sys
s=sys.stdin.read().strip()
try:
    d=json.loads(s)
    if isinstance(d,str): d=json.loads(d)
    print(d.get('$1',''))
except Exception: print('')" 2>/dev/null; }

echo "== A. in-repo static integrity =="
grep -q "tableData?.composite === true && Array.isArray(tableData?.tables)" src/lib/fotmob.ts \
  && ok "A1 the composite clubIds guard present in getLeagueTransfers (the 494 observation's fix shape)" \
  || bad "A1" "composite guard missing"
grep -q "tableData.tables.flatMap((sub) => sub?.table?.all || \[\])" src/lib/fotmob.ts \
  && ok "A2 the composite sub-table flatMap present (data.tables[].table.all)" \
  || bad "A2" "flatMap missing"
[ -f scripts/c499-league-sweep.py ] && ok "A3 the fresh sweep census artifact in-repo (the c469 discipline re-born)" || bad "A3" "missing"
[ -f scripts/c499-dayid-probe2.py ] && ok "A4 the day-id trap filter artifact in-repo (the 469/474/494 lesson)" || bad "A4" "missing"

echo "== B. the live API proof =="
MLS=$(curl -s "$BASE/api/league-transfers?league=mls")
echo "$MLS" | python3 -c "
import json,sys
d=json.load(sys.stdin); t=d.get('transfers')
assert d.get('ok') is True, 'ok!=true'
assert t is not None, 'transfers null — the fix did not land'
items=t.get('items',[])
assert len(items)==100, f'items={len(items)}'
kinds={i['kind'] for i in items}
assert kinds <= {'in','out','internal'}, kinds
fa_empty=sum(1 for i in items if not i['from'].get('fa') or not i['to'].get('fa'))
kfa_ok=all(i['kindFa'] in ('ورودی','خروجی','داخلی') for i in items)
print(f\"MLS first={items[0]['name']!r} | {items[0]['from']['fa']} -> {items[0]['to']['fa']} | fa_empty={fa_empty} kindFa_ok={kfa_ok}\")
" > /tmp/c499-mls.txt 2>&1
if [ $? -eq 0 ]; then ok "B1 MLS composite transfers NOW SERVED: 100 items (null before the fix), kinds ⊆ {in,out,internal} — $(cat /tmp/c499-mls.txt)"; else bad "B1" "$(cat /tmp/c499-mls.txt)"; fi
FIRST=$(cat /tmp/c499-mls.txt)
echo "$FIRST" | grep -q "Hernán López" && ok "B2 the 494 card's own first-row witness live: Hernán López (هِرنان لوپس)" || bad "B2" "$FIRST"
echo "$FIRST" | grep -q "fa_empty=0" && ok "B3 zero EMPTY fa club cells in the MLS feed (the fallback always fills — the 446-pick raw class is report-only)" || bad "B3" "$FIRST"
echo "$FIRST" | grep -q "kindFa_ok=True" && ok "B4 the direction chips Persian (ورودی/خروجی/داخلی)" || bad "B4" "$FIRST"
ARG=$(curl -s "$BASE/api/league-transfers?league=argentina")
AC=$(echo "$ARG" | python3 -c "
import json,sys
d=json.load(sys.stdin); t=d.get('transfers')
print(len(t['items']) if t else 'null')" 2>/dev/null)
[ "$AC" = "100" ] && ok "B5 ARG composite transfers NOW SERVED: 100 items (null since the 474 registration)" || bad "B5" "arg items=$AC"
PL=$(curl -s "$BASE/api/league-transfers?league=pl")
PC=$(echo "$PL" | python3 -c "
import json,sys
d=json.load(sys.stdin); t=d.get('transfers')
print(f\"{len(t['items'])}|{t.get('season')}\" if t else 'null')" 2>/dev/null)
[ "$PC" = "100|2026/2027" ] && ok "B6 the FLAT branch byte-stable: pl items=100 season=2026/2027 (no regression)" || bad "B6" "pl=$PC"
UC=$(curl -s "$BASE/api/league-transfers?league=ucl" | python3 -c "
import json,sys
d=json.load(sys.stdin); print('null' if d.get('transfers') is None else 'SERVED')" 2>/dev/null)
[ "$UC" = "null" ] && ok "B7 the honest-hide contract intact: ucl transfers null" || bad "B7" "ucl=$UC"

echo "== C. the visible DOM (agent-browser 390×844) — the tab the fix BORN =="
$AB set viewport 390 844 >> "$OUT" 2>&1
for LEAGUE in mls argentina; do
  $AB console --clear >/dev/null 2>&1
  $AB open "$BASE/league/$LEAGUE" >> "$OUT" 2>&1
  sleep 4
  CLICK=$($AB eval "(()=>{const b=Array.from(document.querySelectorAll('button')).find(x=>x.textContent.trim()==='انتقال‌ها');if(!b)return JSON.stringify({tab:false});b.click();return JSON.stringify({tab:true})})()" 2>/dev/null | abjson)
  echo "$CLICK" | grep -q '"tab": true' && ok "C-$LEAGUE-tab the «انتقال‌ها» tab PRESENT on /league/$LEAGUE (honestly-hidden before the fix — the fix's own DOM evidence)" || { bad "C-$LEAGUE-tab" "$CLICK"; continue; }
  sleep 2
  DOM=$($AB eval "(()=>{const s=document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]');if(!s)return JSON.stringify({panel:false});const head=s.querySelector('p');const lis=s.querySelectorAll('ul > li').length;const chips=['ورودی','خروجی','داخلی'].filter(x=>s.innerText.includes(x));const de=document.documentElement;return JSON.stringify({panel:true,head:head?head.innerText.slice(0,60):'',rows:lis,chips:chips.length,sw:de.scrollWidth,vw:window.innerWidth})})()" 2>/dev/null | abjson)
  PANEL=$(echo "$DOM" | grep -c '"panel": true')
  ROWSN=$(echo "$DOM" | abfield rows); CHIPS=$(echo "$DOM" | abfield chips); SW=$(echo "$DOM" | abfield sw); VW=$(echo "$DOM" | abfield vw); HEADTXT=$(echo "$DOM" | abfield head)
  [ "$PANEL" = "1" ] && [ "$ROWSN" -ge 90 ] && ok "C-$LEAGUE-rows the transfers panel live: rows=$ROWSN head=$HEADTXT" || bad "C-$LEAGUE-rows" "rows=$ROWSN panel=$PANEL"
  [ "$CHIPS" = "3" ] && ok "C-$LEAGUE-chips all three direction counters visible (ورودی/خروجی/داخلی)" || bad "C-$LEAGUE-chips" "$CHIPS"
  [ "$SW" = "390" ] && [ "$VW" = "390" ] && ok "C-$LEAGUE-viewport scrollW=390 innerW=390 (no horizontal overflow)" || bad "C-$LEAGUE-viewport" "sw=$SW vw=$VW"
  CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
  PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
  [ "$CE" = "0" ] && [ "$PE" = "0" ] && ok "C-$LEAGUE-console console 0 + page errors 0 on the live transfers tab" || bad "C-$LEAGUE-console" "console=$CE page=$PE"
done

echo "== D. fresh home still clean (the 434 mount-gate) =="
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >> "$OUT" 2>&1
sleep 2
CE2=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE2" = "0" ] && ok "D1 console errors 0 on fresh home" || bad "D1 console" "$CE2"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
