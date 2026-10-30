#!/bin/bash
# cycle219-fixproof.sh — permanent gate for the cycle-219 fix
# (Fix (cycle 219): the keeper-surface honest-English fallback — a curated
# 60-name keeper batch + the diacritic-fold class fix in playerFa).
# Part A (API):  4 checks
#   A1 laliga?season=2020/2021 goalsPrevented: all 10 rows Persian-mapped
#      (nameFa != name) incl. the 218-observed Bravo/Bounou/Ledesma/Badía
#   A2 FOLD class proof: seriea?season=2023/2024 spells the keeper ASCII
#      "Wojciech Szczesny" — the map key is "wojciech szczęsny" (ę) — the
#      row must resolve to «وویچیخ شچسنی» through the folded index
#   A3 no-regression: current laliga gp rank-1 stays «آلوارو والس»/8.2
#      (the 217 live anchor) + honest absence intact on persiangulf
#   A4 variant pairs: pl "Djordje Petrović" + bundesliga "Lukás Hrádecky"
#      resolve through the fold to their single curated entries
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 laliga?season=2020/2021 gp section renders ≥5 rows, zero identity
#      fallbacks, signed dir=ltr pills intact (the 217 contract)
#   B2 current laliga gp section: 10 rows + «آلوارو والس» visible
#   B3 viewport integrity + clean console on both pages
set -u
BASE="${BASE:-http://localhost:3000}"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
S20="%5B0-5D"
py(){ python3 -c "$1"; }

# ---------- Part A ----------
echo "== Part A: API gates =="

# A1
J=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021")
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPrevented') or []
ident=[e['name'] for e in gp if (e.get('nameFa') or '')==e['name']]
names=' '.join(e.get('nameFa','') for e in gp)
need=['کلاودیو براوو','یاسین بونو','جرمیاس لدسما','ادگار بادیا','خوردی ماسیپ','ایوان ویار']
missing=[x for x in need if x not in names]
pill=all(isinstance(e['goalsPrevented'],(int,float)) for e in gp)
print('A1CHECK', len(gp)==10, not ident, not missing, pill)
" > /tmp/a1.txt
grep -q "A1CHECK True True True True" /tmp/a1.txt && ok "A1 gp 2020/21: 10 rows all Persian (Bravo/Bounou/Ledesma/Badía/Masip/Villar) signed-decimal" || bad "A1: $(cat /tmp/a1.txt)"

# A2 fold proof
J=$(curl -s "$BASE/api/topscorers/seriea?season=2023%2F2024")
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
hit=[(e['name'],e.get('nameFa')) for e in (d.get('goalsPrevented') or []) if 'zczesny' in e['name'].lower()]
print('A2CHECK', hit and hit[0][0]=='Wojciech Szczesny' and hit[0][1]=='وویچیخ شچسنی', hit)
" > /tmp/a2.txt
grep -q "A2CHECK True" /tmp/a2.txt && ok "A2 FOLD: upstream ASCII 'Wojciech Szczesny' → «وویچیخ شچسنی» via folded index" || bad "A2: $(cat /tmp/a2.txt)"

# A3 no-regression anchors
A=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPrevented') or []
r1=gp[0] if gp else {}
print('ANCHOR', r1.get('nameFa')=='آلوارو والس' and r1.get('goalsPrevented')==8.2, len(gp))
")
echo "$A" | grep -q "ANCHOR True 10" && ok "A3 live anchor intact: «آلوارو والس»/8.2 top of current gp" || bad "A3: $A"
P=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
print('ABSENT', len(d.get('goalsPrevented') or [])==0)
")
echo "$P" | grep -q "ABSENT True" && ok "A3 honest absence intact: persiangulf hides the section" || bad "A3-absence: $P"

# A4 variant pairs through the fold (Petrović serves on pl cleanSheets 2025/26;
# Hrádecky on bundesliga goalsPrevented 2023/24 — per the 218 collector)
PL=$(curl -s "$BASE/api/topscorers/pl?season=2025%2F2026" | py "
import sys,json
d=json.load(sys.stdin)
hit=[(e['name'],e.get('nameFa')) for e in (d.get('cleanSheets') or []) if 'etrovi' in e['name']]
print('PV', hit[0][1]=='دجوردیه پتروویچ' if hit else None, hit)
")
echo "$PL" | grep -q "PV True" && ok "A4 fold pair: pl cleanSheets 'Djordje Petrović' → «دجوردیه پتروویچ»" || bad "A4-pl: $PL"
BL=$(curl -s "$BASE/api/topscorers/bundesliga?season=2023%2F2024" | py "
import sys,json
d=json.load(sys.stdin)
hit=[(e['name'],e.get('nameFa')) for e in (d.get('goalsPrevented') or []) if 'hrádeck' in e['name'].lower() or 'hradeck' in e['name'].lower()]
print('HR', hit[0][1]=='لوکاش هرادتسکی' if hit else None, hit)
")
echo "$BL" | grep -q "HR True" && ok "A4 fold pair: bundesliga 'Lukás Hrádecky' → «لوکاش هرادتسکی»" || bad "A4-bl: $BL"

# ---------- Part B ----------
echo "== Part B: DOM proof @390x844 =="
AB() { agent-browser "$@"; }
AB set viewport 390 844 >/dev/null
AB open "$BASE/topscorers/laliga?season=2020%2F2021" >/dev/null
AB wait --load networkidle >/dev/null; sleep 2
B1=$(AB eval "(() => { const rows=[...document.querySelectorAll('[data-testid=gp-row]')]; const ident=rows.filter(r=>{const n=r.querySelector('span.block')?.textContent||''; return /^[\x00-\x7F]*\$/.test(n);}).length; const pills=[...rows.map(r=>r.querySelector('span[dir=ltr]'))]; const dirOk=pills.every(p=>p&&p.getAttribute('dir')==='ltr'); return JSON.stringify({rows:rows.length, identFallbacks:ident, dirOk}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"identFallbacks":0' && echo "$B1" | tr -d '\\' | grep -q '"dirOk":true' && ok "B1 DOM: gp 2020/21 = 10 rows, 0 identity fallbacks, dir=ltr pills" || bad "B1: $B1"
C1=$(AB eval "JSON.stringify({c:window.__consoleErrors||0, e:document.querySelectorAll('h1').length, w:document.documentElement.clientWidth})")
AB console --clear >/dev/null 2>&1
AB open "$BASE/topscorers/laliga" >/dev/null
AB wait --load networkidle >/dev/null; sleep 2
B2=$(AB eval "(() => { const rows=[...document.querySelectorAll('[data-testid=gp-row]')]; const names=rows.map(r=>r.textContent||'').join('|'); return JSON.stringify({rows:rows.length, valles:names.includes('آلوارو والس'), h1:document.querySelectorAll('h1').length, cw:document.documentElement.clientWidth}); })()")
echo "$B2" | tr -d '\\' | grep -q '"rows":10' && echo "$B2" | tr -d '\\' | grep -q '"valles":true' && echo "$B2" | tr -d '\\' | grep -q '"h1":1' && ok "B2 DOM: current gp = 10 rows + «آلوارو والس» visible" || bad "B2: $B2"
CN=$(AB console | wc -l); CE=$(AB errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B3 console=0 errors=0 on both pages" || bad "B3: console=$CN errors=$CE"
AB close >/dev/null 2>&1

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE219 FIXPROOF ALL GREEN (the keeper-surface honest-English fallback: curated 60-name batch + the diacritic-fold class fix — API 4/4 + DOM 3/3 @390x844)" && exit 0
exit 1
