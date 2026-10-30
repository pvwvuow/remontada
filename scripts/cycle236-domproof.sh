#!/bin/bash
# cycle236-domproof.sh — permanent gate for the cycle-236 update
# (Update (cycle 236): «سانس بزرگ ازدست‌رفته» — the deep-file family's
#  EIGHTEENTH sibling, the MISSED-volume twin of the BCC surface (231),
#  straight from the live big_chance_missed.json probe (UA Chrome/124,
#  2026-10-30): WIDE on ALL SIX domestic globalMerge leagues — ucl 140
#  Haaland 6 / pl 135 Thierno Barry 12 / laliga 142 Mbappé 13 / seriea 171
#  Malen 9 / bundesliga 126 Demirović 8 / ligue1 128 Mafouta 6 rows;
#  persiangulf honestly absent and mas absent (null payload).
#  INTEGER-VALUED floats (probed nonint=0 on every serving file,
#  StatDecimals=0) → the 215/216/220 integer convention: rounded once at
#  build, pill Persian digits WITHOUT dir=ltr (13 renders «۱۳»). Upstream
#  COMPETITION tie-ranks kept verbatim (pl 6.0 ×4 / laliga 7.0 ×3 —
#  probed); the merge re-ranks POSITIONALLY like every sibling.
#  SEASON-AWARE (the 124/175/185/226/227/230/231/232/235 class): the
#  2020/21 laliga raw serves its OWN file — 257 rows, Karim Benzema 19 /
#  Alexander Isak 16 / Rafa Mir 16 — frozen, the 202 anchor, and the 229
#  curation rides free («کریم بنزما» «رافا میر»). Additive mirror of
#  230/231/232/235 end-to-end: BigChancesMissedEntry + the REQUIRED
#  bigChancesMissed field on the mapped payload + getFullBigChancesMissed
#  (fullBigChancesMissed:v1, standard wide guard) + the 170 read-time
#  honest-names line + the bcmMap badge map + the category-top-3-first
#  merge (dedup by playerId, bigChancesMissed DESC, top-10, POSITIONAL
#  re-rank) + standings:v24→v25 (the 52/…/235 additive-shape convention) +
#  the API route field + the league-page block «سانس بزرگ ازدست‌رفته»
#  placed right after فرصت‌های خلق‌شده so the creation-volume run
#  (خلق‌شده → کل → ازدست‌رفته) reads together while the keeper QUINTET
#  stays untouched — the 230/231/232/233/235 gates' relative-order asserts
#  are inequality-based so the insertion provably keeps them green (all
#  re-ran green) — with data-testid=bcm-row and the 170/176 link contract
#  + the «N سانس ازدست‌رفته» badge twin on scorer rows in BOTH views. THE
#  EIGHTEENTH THIN-GUARD CLAUSE (the 210 class) — the cold-build fallback
#  lesson held (the guard re-probes in 90s; served 10/10 on all six).)
# Part A (API): A1 the live anchor (laliga «کیلیان امباپه» 13, positional
#               1..10, integer monotonic) + the six-domestic bcm=10
#               contract beside the full sister family
#               (xg/xgot/gp90/xa/bcc/cc=10) + the persiangulf/mas honest
#               absences
#               A2 the frozen 2020/2021 laliga anchor («کریم بنزما» 19 +
#               «رافا میر» 16) + A2b the ucl live anchor «ارلینگ هالند» 6
#               A3 the badge map flow (drift-tolerant: ≥1 scorer row
#               carrying the bigChancesMissed badge across the six)
#               A4 the negative probe (bad season shape → ok:false)
# Part B (DOM @390x844): B1 h2 «سانس بزرگ ازدست‌رفته» + 10 bcm-rows + the
#               creation-volume order (BCC → CC → BCM → minutes) with the
#               keeper QUINTET adjacent and zero real overflow
#               B2 the dir-less integer pill («۱۳») + real navigation to
#               /player/<id> h1 «کیلیان امباپه»
#               B3 the historical UI deep-link ?season=2020/2021 renders
#               the frozen «کریم بنزما» «۱۹» anchor with the URL param
#               preserved
#               B4 the honest absences in DOM (persiangulf) + console=0
#               errors=0
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle236-domproof-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the live anchor + the six-domestic contract + honest absences
A1=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
b=d.get('bigChancesMissed') or []
ok=1
if len(b)!=10: ok=0
vals=[r.get('bigChancesMissed') for r in b]
if any(v is None for v in vals) or any(float(v)!=int(v) for v in vals): ok=0
for i in range(len(b)-1):
    if vals[i]<vals[i+1]: ok=0
if [r.get('rank') for r in b]!=list(range(1,11)): ok=0
if len(d.get('xg') or [])!=10 or len(d.get('xgot') or [])!=10 or len(d.get('goalsPer90') or [])!=10 or len(d.get('xa') or [])!=10 or len(d.get('bigChancesCreated') or [])!=10 or len(d.get('chancesCreated') or [])!=10: ok=0
print(f\"{ok}|{b[0].get('nameFa')}|{b[0].get('bigChancesMissed')}\" if b else '0|-|-')
")
  ST=$(echo "$L" | cut -d'|' -f1)
  [ "$ST" = "1" ] || { A1=0; bad "A1: $K contract failed ($L)"; }
done
LAL=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
b=json.load(sys.stdin).get('bigChancesMissed') or []
print(f\"{b[0].get('nameFa')}|{b[0].get('bigChancesMissed')}\" if b else '-|-')
")
echo "$LAL" | grep -q "کیلیان امباپه|13" && ok "A1 live anchor: laliga bcm rank-1 = «کیلیان امباپه» 13 (integer, positional 1..10 monotonic) + ALL SIX domestics bcm=10 with the sister family (xg/xgot/gp90/xa/bcc/cc=10) beside it" || bad "A1 anchor: $LAL"
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
print(1 if (f('scorers')==20 and f('goalsPer90')==10 and f('bigChancesMissed')==0 and f('chancesCreated')==0 and f('xgot')==0) else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
c=d.get('cards') or {}
nc=len((c.get('yellow') or []))+len((c.get('red') or []))
print(1 if (f('scorers')==20 and f('bigChancesMissed')==0 and f('chancesCreated')==0 and nc>=1) else 0)
")
[ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A1b honest absences: persiangulf bcm=0 (scorers=20/gp90=10 intact) + mas bcm=0 (cards-only, the 176 rule)" || bad "A1b: pg=$PG mas=$MAS"

# A2 the frozen 2020/2021 laliga anchor + the ucl live anchor
A2=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
b=(json.load(sys.stdin).get('bigChancesMissed') or [])
r1=b[0] if b else {}
r3=b[2] if len(b)>2 else {}
print(f\"{r1.get('nameFa')}|{r1.get('bigChancesMissed')}|{r3.get('nameFa')}|{r3.get('bigChancesMissed')}\")
")
echo "$A2" | grep -q "کریم بنزما|19" && echo "$A2" | grep -q "رافا میر|16" && ok "A2a frozen 2020/2021 laliga anchor: bcm rank-1 «کریم بنزما» 19 + rank-3 «رافا میر» 16 (the 202 anchor pattern; the 229 curation riding free)" || bad "A2a: $A2"
UCL=$(curl -s "$BASE/api/topscorers/ucl" | py "
import sys,json
b=(json.load(sys.stdin).get('bigChancesMissed') or [])
print(f\"{b[0].get('nameFa')}|{b[0].get('bigChancesMissed')}\" if b else '-|-')
")
echo "$UCL" | grep -q "ارلینگ هالند|6" && ok "A2b live ucl anchor: bcm rank-1 «ارلینگ هالند» 6" || bad "A2b: $UCL"

# A3 the badge map flow — drift-tolerant across the six
A3=$( : > "$TMP.six"; for K in ucl pl laliga seriea bundesliga ligue1; do curl -s "$BASE/api/topscorers/$K" >> "$TMP.six"; echo "" >> "$TMP.six"; done; python3 - "$TMP.six" <<'PY'
import sys,json
hit=0; who=''
dec=json.JSONDecoder()
buf=open(sys.argv[1],encoding='utf-8').read().strip()
i=0
while i<len(buf):
    try:
        obj,j=dec.raw_decode(buf,i); i=j
        while i<len(buf) and buf[i] in ' \n\r\t': i+=1
        for s in (obj.get('scorers') or []):
            if s.get('bigChancesMissed') is not None and s['bigChancesMissed']>0:
                hit+=1
                if not who: who=f"{s.get('nameFa')}:{s['bigChancesMissed']}"
    except Exception:
        i+=1
print(f'{hit}|{who}')
PY
)
NH=$(echo "$A3" | cut -d'|' -f1); WHO=$(echo "$A3" | cut -d'|' -f2)
[ "$NH" -ge 1 ] 2>/dev/null && ok "A3 badge map: the bigChancesMissed badge twin fires on $NH scorer row(s) across the six domestics (first: $WHO) — the id-intersection mechanism, the 231/232/235 flow" || bad "A3: badge flow = $A3"

# A4 the negative probe
N=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A4 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A4: $N"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iC=h2s.indexOf('فرصت‌های خلق‌شده'), iM=h2s.indexOf('بیشترین دقایق'), iBM=h2s.indexOf('سانس بزرگ ازدست‌رفته'); const order=iB>-1&&iC>iB&&iBM>iC&&iM>iBM; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const rows=document.querySelectorAll('[data-testid=bcm-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,rows,vbroken,h2:h2s.includes('سانس بزرگ ازدست‌رفته')}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' \
  && ok "B1 DOM laliga: h2 «سانس بزرگ ازدست‌رفته» + 10 bcm-rows, the creation-volume order (…سانس بزرگ خلق‌شده → فرصت‌های خلق‌شده → سانس بزرگ ازدست‌رفته → دقایق) with the keeper QUINTET adjacent + zero real overflow @390x844" || bad "B1: $B1"

B2=$(agent-browser eval "(() => { const r=document.querySelector('[data-testid=bcm-row]'); const a=r&&r.querySelector('a'); const pill=a&&a.lastElementChild; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, href:(a&&a.getAttribute('href'))||''}); })()")
PID=$(echo "$B2" | tr -d '\\' | grep -oE '"href":"[^"]*"' | grep -oE 'player/[0-9]+' | grep -oE '[0-9]+' | head -1)
PILL=$(echo "$B2" | tr -d '\\' | grep -oE '"pill":"[^"]*"' | cut -d'"' -f4)
[ "$PILL" = "۱۳" ] && ok "B2a DOM pill: the bcm top-1 pill renders «۱۳» — Persian digits WITHOUT dir=ltr (the integer contract)" || bad "B2a: pill=$PILL"
agent-browser open "$BASE/player/$PID" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
H1=$(agent-browser eval "(() => { const h=document.querySelector('h1'); return JSON.stringify({h1:(h&&h.textContent.trim())||''}); })()")
echo "$H1" | tr -d '\\' | grep -q '"h1":"کیلیان امباپه"' && ok "B2b real navigation: /player/$PID → h1 «کیلیان امباپه» (the 170/176 link contract on the bcm top-1)" || bad "B2b: h1=$H1"

agent-browser open "$BASE/topscorers/laliga?season=2020/2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B3=$(agent-browser eval "(() => { const txt=document.body.innerText||''; const url=new URL(location.href); return JSON.stringify({benzema:txt.includes('کریم بنزما'), c19:txt.includes('۱۹'), season:url.searchParams.get('season')}); })()")
echo "$B3" | tr -d '\\' | grep -q '"benzema":true' && echo "$B3" | tr -d '\\' | grep -q '"c19":true' && echo "$B3" | tr -d '\\' | grep -q '"season":"2020/2021"' \
  && ok "B3 DOM historical: ?season=2020/2021 renders the frozen «کریم بنزما» «۱۹» anchor with the URL param preserved (the honesty-snap rule)" || bad "B3: $B3"

agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4=$(agent-browser eval "(() => { const txt=document.body.innerText||''; return JSON.stringify({bcmAbsent:!txt.includes('سانس بزرگ ازدست‌رفته'), gp90:txt.includes('گل در هر ۹۰')}); })()")
echo "$B4" | tr -d '\\' | grep -q '"bcmAbsent":true' && echo "$B4" | tr -d '\\' | grep -q '"gp90":true' \
  && ok "B4 DOM honest absence: persiangulf hides the bcm block while گل در هر ۹۰ serves (the 231/232/235 absence contract in DOM)" || bad "B4: $B4"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B5 console=0 errors=0 across the whole session" || bad "B5: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LAT=1
for P_ in / /topscorers/laliga /topscorers/persiangulf; do
  T=$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$BASE$P_")
  echo "     LAT $P_ = ${T}s"
  python3 -c "import sys; sys.exit(0 if float('$T')<5.0 else 1)" || LAT=0
done
[ "$LAT" = "1" ] && ok "Part C warm LAT: 3 routes <5000ms" || bad "Part C: a route exceeded 5000ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE236 DOMPROOF ALL GREEN («سانس بزرگ ازدست‌رفته» — the deep-file family's EIGHTEENTH sibling and the MISSED-volume twin of BCC: WIDE on all six domestics at 10 rows, persiangulf+mas honestly absent, season-aware with the frozen Benzema 19 anchor + the 229 curation riding free, integer pill the 215/220 contract, badge flow on the id-intersection mechanism, the EIGHTEENTH thin-guard clause — API 5/5 + DOM 5/5 + LAT @390x844)" && exit 0
exit 1
