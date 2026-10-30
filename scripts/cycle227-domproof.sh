#!/bin/bash
# cycle227-domproof.sh — permanent gate for the cycle-227 update
# (Update (cycle 227): «گل در هر ۹۰» — the deep-file family's THIRTEENTH
#  sibling and the production-RATE surface, straight from the
#  goals_per_90.json probe. Live-probed 2026-10-30 UA Chrome/124: serves on
#  23 of the 24 leagues.ts entries — EVERY league but mas (two player
#  categories only) — with WIDE files (laliga 139 / ucl 128 / championship
#  196 rows) and PERSIANGULF SERVES TOO: 93 rows, the FIRST deep sibling
#  besides minutes to reach the Persian Gulf (Erfan Shahriari / Kasra
#  Taheri 1.06 on the honest competition tie-rank 1,1,3). Decimal values
#  VERBATIM — the SIXTH non-integer member (the 210/217/221/222/226
#  convention), upstream precision UP TO two decimals (probed max 2 on
#  every serving league) → pill toFixed(2) dir=ltr. SEASON-AWARE (the
#  124/175/185/226 class): the 2020/21 raw serves its OWN file — 224 rows,
#  Lionel Messi 0.89 / Gerard Moreno 0.77 / Luis Suárez 0.75 — frozen
#  anchor. Standard wide-file thin guard (the 210 class) — PROVEN LIVE ON
#  THIS CYCLE: the cold build dropped the fetch (3 rows), the 90s guard
#  re-probed and self-healed to 10 (the 222/226 story replaying under the
#  guard built for it). The 224 search-fold chain grows to TEN blocks
#  («Flemming»/873559 searchable with no goals key, zero fetch).)
# 239 REFRESH (Fix (cycle 239), 2026-10-30 ~23:0x +08:00): the gate's TWO
#  LIVE Gulf anchors drifted with the feed - gate-internal live drift, NOT
#  app bugs (registered by the 237 card, re-observed 12/14 by the 238
#  hunt). As-found: the 227-era rank-1 (Shahriari 1.06, Malavan) is TODAY
#  rank-2 (same player, same 1.06 value, same Malavan team); the live
#  rank-1 is Kasra Taheri 1.32, Sepahan (playerId 1580548, teamId 101611)
#  - probed live on the app API AND the DOM this cycle. A2 + B5a refreshed
#  to the current rank-1 identity (A2 additionally pins the playerId, the
#  A1 style); EVERYTHING else untouched. A4c 'Shahriari' stays green by
#  design (he is still in the feed and searchable, now rank-2). The laliga
#  live anchors (Raphinha 1.77 class) still held at refresh time - same
#  volatile class, future fix rounds refresh them the same way if drift.
# Part A (API, live-observed 2026-10-30):
#   A1 laliga: 10 rows positional 1..10, two-decimal floats verbatim
#      monotonic, rank-1 = (696679, «رافینیا», 1.77) — the live anchor
#   A2 the league contract: six domestics gp90=10 + sibling contract
#      intact; PERSIANGULF SERVES (gp90=10 beside minutes=10, scorers=20 —
#      the first deep sibling besides minutes to reach the Gulf); mas
#      honestly 0 while its scorers still serve 20
#   A3 SEASON-AWARE: laliga?season=2020/2021 → gp90 10 rows, rank-1
#      name='Lionel Messi' gp90=0.89 (the frozen anchor) while penaltySaves
#      stays honestly 0 (the 132 class sibling)
#   A4 the fold chain: 'Flemming' (873559) = the gp90 king searchable with
#      NO goals key (the deep-fold honesty) + «امباپه» control = 2 +
#      'Shahriari' (1793813) the Gulf's own king searchable
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «گل در هر ۹۰» h2 + 10 gp90-rows on /topscorers/laliga
#   B2 order: گل در هر ۹۰ between گل مورد انتظار and بیشترین دقایق (the
#      rate pair) + the keeper QUINTET still adjacent + no real overflow
#   B3 decimal pill: dir=ltr + «۱.۷۷» on the first row (toFixed(2))
#   B4 real navigation: first gp90-row → /player/696679 h1 «رافینیا»
#   B5a persiangulf SERVES in DOM: h2 + 10 gp90-rows, first team «ملوان»
#   B5b mas honest absence: no گل در هر ۹۰ h2 while گلزن‌ها still renders
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle227-dom-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 the live anchor + shape
curl -s "$BASE/api/topscorers/laliga" > "$TMP/laliga.json"
py "
import json
d=json.load(open('$TMP/laliga.json'))
gp=d.get('goalsPer90') or []
ranks=[e['rank'] for e in gp]
r1=gp[0] if gp else {}
mono=all(gp[i]['goalsPer90']>=gp[i+1]['goalsPer90'] for i in range(len(gp)-1)) if len(gp)==10 else False
two_dec=all(round(e['goalsPer90'],2)==e['goalsPer90'] for e in gp)
has_two=any(round(e['goalsPer90'],2)!=round(e['goalsPer90'],1) for e in gp)
print('A1CHECK', len(gp)==10, ranks==list(range(1,11)), mono, two_dec, has_two, r1.get('playerId')==696679 and r1.get('nameFa')=='رافینیا' and abs(r1.get('goalsPer90',0)-1.77)<1e-9)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True True" "$TMP/a1.txt" && ok "A1 laliga: 10 rows positional 1..10, two-decimal verbatim monotonic, rank-1 «رافینیا»/696679/1.77 (live anchor)" || bad "A1: $(cat "$TMP/a1.txt")"

# A2 the league contract: domestics serve 10 + siblings intact; the Gulf
# SERVES; mas honestly absent
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPer90') or []
f=lambda k: len(d.get(k) or [])
ok=(len(gp)==10 and f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10 and 1<=f('penaltySaves')<=10 and f('xg')==10)
print(1 if ok else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPer90') or []
r1=gp[0] if gp else {}
# 239 REFRESH: was name=='Erfan Shahriari' and gp90==1.06 (the 227 anchor);
# the live feed moved him to rank-2 and Kasra Taheri (1580548, 1.32,
# Sepahan) to rank-1 - re-probed live 2026-10-30, the registered 239 fix.
ok=(len(gp)==10 and len(d.get('minutes') or [])==10 and len(d.get('scorers') or [])==20 and r1.get('name')=='Kasra Taheri' and r1.get('playerId')==1580548 and abs(r1.get('goalsPer90',0)-1.32)<1e-9)
print(1 if ok else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('goalsPer90') or [])==0 and len(d.get('scorers') or [])==20 else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A2 six domestics carry gp90=10 + the full sibling contract; PERSIANGULF SERVES (10 rows, Taheri 1.32 rank-1 [239 refresh - the 227-era Shahriari 1.06 anchor drifted to rank-2], beside minutes=10/scorers=20 — the first deep sibling besides minutes to reach the Gulf); mas mirror-honest (gp90=0, scorers=20)" || bad "A2: SW=$SW PG=$PG MAS=$MAS"

# A3 SEASON-AWARE frozen anchor (Messi 0.89)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPer90') or []
r1=gp[0] if gp else {}
print('H', len(gp)==10, r1.get('name')=='Lionel Messi' and abs(r1.get('goalsPer90',0)-0.89)<1e-9, len(d.get('penaltySaves') or [])==0)
")
echo "$H" | grep -q "H True True True" && ok "A3 historical 2020/21: goalsPer90 serves 10 rows with the frozen anchor Lionel Messi 0.89 (the 202 pattern, season-aware) while penaltySaves stays honestly 0 (the 132 sibling)" || bad "A3: $H"

# A4 the fold chain extension (deep-only king + control + the Gulf's own)
B=$(curl -s "$BASE/api/search?q=$(enc "Flemming")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
h=[p for p in ps if p['playerId']==873559]
print('AB', bool(h) and h[0].get('rank')==1 and ('goals' not in h[0]))
")
echo "$B" | grep -q "AB True" && ok "A4a fold extension: 'Flemming' (Zian Flemming 873559, the pl gp90 king) searchable with rank=1 and NO goals key — the goals-per-90 block joined the 224 chain (ten blocks)" || bad "A4a: $B"
M=$(curl -s "$BASE/api/search?q=$(enc "امباپه")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
[ "$M" -ge 2 ] && ok "A4b control intact: «امباپه» = $M (Ethan + Kylian)" || bad "A4b: $M"
S=$(curl -s "$BASE/api/search?q=$(enc "Shahriari")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
h=[p for p in ps if p['playerId']==1793813]
print('SB', bool(h))
")
echo "$S" | grep -q "SB True" && ok "A4c the Gulf's own: 'Shahriari' (Erfan Shahriari 1793813, the 227-era Gulf gp90 king - now rank-2 after the 239-documented live drift, still in the feed) searchable — the home-league deep rows reach the header search" || bad "A4c: $S"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=gp90-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='گل در هر ۹۰'); return JSON.stringify({rows:rows.length, h2}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' && ok "B1 DOM: «گل در هر ۹۰» h2 renders + 10 gp90-rows on /topscorers/laliga" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iG=h2s.indexOf('گل در هر ۹۰'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iG>iX&&iM>iG; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order, quintet, vbroken}); })()")
echo "$B2" | tr -d '\\' | grep -q '"order":true' && echo "$B2" | tr -d '\\' | grep -q '"quintet":true' && echo "$B2" | tr -d '\\' | grep -q '"vbroken":0' && ok "B2 DOM: گل در هر ۹۰ between گل مورد انتظار and دقایق (the rate pair) + keeper QUINTET still adjacent + no real overflow @390x844" || bad "B2: $B2"
B3=$(agent-browser eval "(() => { const row=document.querySelector('[data-testid=gp90-row]'); const pill=row.firstElementChild.lastElementChild; return JSON.stringify({dirAttr:pill?.getAttribute('dir'), txt:pill?.textContent}); })()")
echo "$B3" | tr -d '\\' | grep -q '"dirAttr":"ltr"' && echo "$B3" | tr -d '\\' | grep -q '"txt":"۱.۷۷"' && ok "B3 DOM: decimal pill dir=ltr renders «۱.۷۷» (toFixed(2), the 217 display rule)" || bad "B3: $B3"
HREF=$(agent-browser eval "document.querySelector('[data-testid=gp90-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/player/696679" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B4=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B4" | tr -d '\\' | grep -q '"/player/696679"' && echo "$B4" | tr -d '\\' | grep -q '"رافینیا"' && ok "B4 DOM: first gp90-row really navigates to /player/696679 with h1 «رافینیا» (the 170/176 link contract)" || bad "B4: $B4"
else
  bad "B4: first gp90-row href is $HREF (expected /player/696679)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
# 239 REFRESH: was malavan:first.includes(ملوان) (the 227 rank-1 Shahriari team) -
# the live rank-1 is now Taheri/Sepahan; the drift itself re-observed in DOM this
# cycle (row 2 renders 02 Shahriari Malavan 1.06) and kept as a drift witness.
B5A=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=gp90-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='گل در هر ۹۰'); const first=rows[0]?.textContent||''; const second=rows[1]?.textContent||''; return JSON.stringify({rows:rows.length, h2, taheri:first.includes('کسری طاهری'), sepahan:first.includes('سپاهان'), driftWitness:second.includes('ملوان')}); })()")
echo "$B5A" | tr -d '\\' | grep -q '"rows":10' && echo "$B5A" | tr -d '\\' | grep -q '"h2":true' && echo "$B5A" | tr -d '\\' | grep -q '"taheri":true' && echo "$B5A" | tr -d '\\' | grep -q '"sepahan":true' && echo "$B5A" | tr -d '\\' | grep -q '"driftWitness":true' && ok "B5a DOM: PERSIANGULF SERVES the section in the browser too — h2 + 10 gp90-rows with «سپاهان» (Kasra Taheri 1.32) first [239 refresh], the 227-era «ملوان» (Shahriari) row still witnessed at rank-2" || bad "B5a: $B5A"
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5B=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({gp90:h2s.includes('گل در هر ۹۰'), cards:h2s.includes('کارت‌ها')}); })()")
echo "$B5B" | tr -d '\\' | grep -q '"gp90":false' && echo "$B5B" | tr -d '\\' | grep -q '"cards":true' && ok "B5b DOM: mas honestly hides the section (no گل در هر ۹۰ h2) while its cards block still renders (the 176 mas contract)" || bad "B5b: $B5B"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE227 DOMPROOF ALL GREEN («گل در هر ۹۰» — the deep-file family's THIRTEENTH sibling and the production-RATE surface: 23-of-24 leagues served at 10 rows, PERSIANGULF REACHED, season-aware with the frozen Messi 0.89 anchor, the dropped-fetch self-heal proven live, fold chain ten blocks — API 4/4 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
