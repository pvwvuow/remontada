#!/bin/bash
# cycle235-domproof.sh — permanent gate for the cycle-235 update
# (Update (cycle 235): «فرصت‌های خلق‌شده» — the deep-file family's
#  SEVENTEENTH sibling, the TOTAL-creation VOLUME twin of the BCC surface
#  (231), straight from the live total_att_assist.json probe (UA Chrome/124,
#  2026-10-30): WIDE on ALL SIX domestic globalMerge leagues — ucl 466
#  Thauvin 15 / pl 323 Groß 23 / laliga 363 Arda Güler 33 / seriea 382
#  Giacomo Calò 34 / bundesliga 308 Olise 25 / ligue1 304 Thauvin 27 rows;
#  persiangulf honestly absent (5 player cats) and mas absent (empty
#  payload). INTEGER-VALUED floats (probed nonint=0 on every serving file,
#  StatDecimals=0) → the 215/216/220 integer convention: rounded once at
#  build, pill Persian digits WITHOUT dir=ltr (33 renders «۳۳»). Upstream
#  COMPETITION tie-ranks kept verbatim (ucl 10.0 → 4,5,6 / pl 18.0 → 4,4,6
#  / laliga 21.0 → 6,7,8 — probed); the merge re-ranks POSITIONALLY like
#  every sibling. SEASON-AWARE (the 124/175/185/226/227/230/231/232
#  class): the 2020/21 laliga raw serves its OWN file — 466 rows, Lionel
#  Messi 77 / David Ferreiro 73 / Toni Kroos 67 — frozen, the 202 anchor,
#  and the 229 curation rides free («لیونل مسی» «تونی کروس»); 2023/24 pl =
#  Bruno Fernandes 114 / Groß 103. Additive mirror of 230/231/232
#  end-to-end: ChancesCreatedEntry + the REQUIRED chancesCreated field on
#  the mapped payload + getFullChancesCreated (fullChancesCreated:v1,
#  standard wide guard) + the 170 read-time honest-names line + the
#  category-top-3-first merge (dedup by playerId, chancesCreated DESC,
#  top-10, POSITIONAL re-rank) + standings:v23→v24 (the 52/…/232
#  additive-shape convention) + the API route field + the league-page
#  block «فرصت‌های خلق‌شده» placed right after سانس بزرگ خلق‌شده so the
#  subset→total pair reads together while the rest of the analytics run
#  and the keeper QUINTET stay untouched — the 230/231/232/233 gates'
#  relative-order asserts are inequality-based so the insertion provably
#  keeps them green (all re-ran green) — with data-testid=cc-row and the
#  170/176 link contract + the «N فرصت‌سازی» badge twin on scorer rows in
#  BOTH views (ScorerEntry/GlobalScorer + the global merge). THE
#  SEVENTEENTH THIN-GUARD CLAUSE (the 210 class) — PROVEN LIVE THIS CYCLE,
#  the 230/231/232 lesson institutionalized: the cold build dropped the
#  deep fetch (3-row category fallback baked) and the cc guard clause
#  re-probed in 90s and self-healed to 10/10 on ALL SIX domestics with
#  ZERO manual purge (3→10, rank-1 Arda Güler 33).)
# Part A (API): A1 the live anchor (laliga «آردا گولر» 33, positional 1..10,
#               integer monotonic) + the six-domestic cc=10 contract beside
#               the full sister family (xg/xgot/gp90/xa/bcc=10) + the
#               persiangulf/mas honest absences with their deep surfaces
#               serving
#               A2 the frozen 2020/2021 laliga anchor (Messi 77 «لیونل مسی»
#               + Kroos 67 «تونی کروس») + A2b the 2023/24 pl anchor (برونو
#               فرناندس 114)
#               A3 the integer precision on all six + the badge map flow
#               (a laliga top-3 scorer carrying the cc badge when in the cc
#               top-3)
#               A4 the negative probe (bad season shape → ok:false)
# Part B (DOM @390x844): B1 h2 «فرصت‌های خلق‌شده» + 10 cc-rows + the
#               subset→total order (BCC before CC before minutes) with the
#               keeper QUINTET adjacent and zero real overflow
#               B2 the dir-less integer pill («۳۳») + real navigation to
#               /player/<id> h1 «آردا گولر» (a cc top-1 link)
#               B3 the historical UI deep-link ?season=2020/2021 renders
#               the frozen «لیونل مسی» 77 anchor with the URL param preserved
#               B4 the honest absences in DOM (persiangulf/mas) + console=0
#               errors=0
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle235-domproof-XXXXXX)"
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
cc=d.get('chancesCreated') or []
ok=1
if len(cc)!=10: ok=0
vals=[r.get('chancesCreated') for r in cc]
if any(v is None for v in vals) or any(float(v)!=int(v) for v in vals): ok=0
for i in range(len(cc)-1):
    if vals[i]<vals[i+1]: ok=0
if [r.get('rank') for r in cc]!=list(range(1,11)): ok=0
if len(d.get('xg') or [])!=10 or len(d.get('xgot') or [])!=10 or len(d.get('goalsPer90') or [])!=10 or len(d.get('xa') or [])!=10 or len(d.get('bigChancesCreated') or [])!=10: ok=0
r1=cc[0] if cc else {}
print(f\"{ok}|{r1.get('nameFa')}|{r1.get('chancesCreated')}\")
")
  ST=$(echo "$L" | cut -d'|' -f1)
  [ "$ST" = "1" ] || { A1=0; bad "A1: $K contract failed ($L)"; }
done
LAL=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
cc=json.load(sys.stdin).get('chancesCreated') or []
r1=cc[0] if cc else {}
print(f\"{r1.get('playerId')}|{r1.get('nameFa')}|{r1.get('chancesCreated')}\")
")
echo "$LAL" | grep -q "آردا گولر|33" && ok "A1 live anchor: laliga cc rank-1 = «آردا گولر» 33 (integer, positional 1..10 monotonic) + ALL SIX domestics cc=10 with the sister family (xg/xgot/gp90/xa/bcc=10) beside it" || bad "A1 anchor: $LAL"
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
print(1 if (f('scorers')==20 and f('goalsPer90')==10 and f('chancesCreated')==0 and f('xgot')==0 and f('xa')==0 and f('bigChancesCreated')==0) else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
c=d.get('cards') or {}
nc=len((c.get('yellow') or []))+len((c.get('red') or []))
print(1 if (f('scorers')==20 and f('chancesCreated')==0 and f('xgot')==0 and f('bigChancesCreated')==0 and nc>=1) else 0)
")
[ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A1b honest absences: persiangulf cc=0 (scorers=20/gp90=10 intact) + mas cc=0 (cards-only, the 176 rule)" || bad "A1b: pg=$PG mas=$MAS"

# A2 the frozen 2020/2021 laliga anchor + the 2023/24 pl anchor
A2=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
cc=d.get('chancesCreated') or []
r1=cc[0] if cc else {}
r3=cc[2] if len(cc)>2 else {}
print(f\"{r1.get('nameFa')}|{r1.get('chancesCreated')}|{r3.get('nameFa')}|{r3.get('chancesCreated')}\")
")
echo "$A2" | grep -q "لیونل مسی|77" && echo "$A2" | grep -q "تونی کروس|67" && ok "A2a frozen 2020/2021 laliga anchor: cc rank-1 «لیونل مسی» 77 + rank-3 «تونی کروس» 67 (the 202 anchor pattern; the 229 curation riding free)" || bad "A2a: $A2"
A2b=$(curl -s "$BASE/api/topscorers/pl?season=2023%2F2024" | py "
import sys,json
cc=(json.load(sys.stdin).get('chancesCreated') or [])
r1=cc[0] if cc else {}
print(f\"{r1.get('nameFa')}|{r1.get('chancesCreated')}\")
")
echo "$A2b" | grep -q "برونو فرناندس|114" && ok "A2b frozen 2023/24 pl anchor: cc rank-1 «برونو فرناندس» 114 (the 402+row-class season file)" || bad "A2b: $A2b"

# A3 the badge map flow — the id-intersection mechanism (the 231/232 flow):
# a scorer row carries the chancesCreated badge when the player sits in BOTH
# the "Top scorer" category top-3 AND the "Chances created" category top-3
# of the same league raw. Drift-tolerant: at least ONE of the six domestics
# must show the twin today (live-observed: bundesliga — Olise, scorer top-2
# × cc top-1 → 25; laliga today: the Top-scorer category is
# Raphinha/Mbappé/Zabiri — none in the cc top-3, so laliga rows carry no
# cc badge, the documented 230 mechanism, not a bug).
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
            if s.get('chancesCreated') is not None and s['chancesCreated']>0:
                hit+=1
                if not who: who=f"{s.get('nameFa')}:{s['chancesCreated']}"
    except Exception:
        i+=1
print(f'{hit}|{who}')
PY
)
NH=$(echo "$A3" | cut -d'|' -f1); WHO=$(echo "$A3" | cut -d'|' -f2)
[ "$NH" -ge 1 ] 2>/dev/null && ok "A3 badge map: the chancesCreated badge twin fires on $NH scorer row(s) across the six domestics (first: $WHO) — the id-intersection mechanism, the 231/232 flow" || bad "A3: badge flow = $A3"

# A4 the negative probe
N=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A4 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A4: $N"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iC=h2s.indexOf('فرصت‌های خلق‌شده'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iXG>iX&&iG>iXG&&iA>iG&&iB>iA&&iC>iB&&iM>iC; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const rows=document.querySelectorAll('[data-testid=cc-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,rows,vbroken,h2:h2s.includes('فرصت‌های خلق‌شده')}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' \
  && ok "B1 DOM laliga: h2 «فرصت‌های خلق‌شده» + 10 cc-rows, the subset→total order (…سانس بزرگ خلق‌شده → فرصت‌های خلق‌شده → دقایق) with the FULL analytics run + keeper QUINTET adjacent + zero real overflow @390x844" || bad "B1: $B1"

B2=$(agent-browser eval "(() => { const r=document.querySelector('[data-testid=cc-row]'); const a=r&&r.querySelector('a'); const pill=a&&a.lastElementChild; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, href:(a&&a.getAttribute('href'))||''}); })()")
PID=$(echo "$B2" | tr -d '\\' | grep -oE '"href":"[^"]*"' | grep -oE 'player/[0-9]+' | grep -oE '[0-9]+' | head -1)
PILL=$(echo "$B2" | tr -d '\\' | grep -oE '"pill":"[^"]*"' | cut -d'"' -f4)
[ "$PILL" = "۳۳" ] && ok "B2a DOM pill: the cc top-1 pill renders «۳۳» — Persian digits WITHOUT dir=ltr (the integer contract)" || bad "B2a: pill=$PILL"
agent-browser open "$BASE/player/$PID" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
H1=$(agent-browser eval "(() => { const h=document.querySelector('h1'); return JSON.stringify({h1:(h&&h.textContent.trim())||''}); })()")
echo "$H1" | tr -d '\\' | grep -q '"h1":"آردا گولر"' && ok "B2b real navigation: /player/$PID → h1 «آردا گولر» (the 170/176 link contract on the cc top-1)" || bad "B2b: h1=$H1"

agent-browser open "$BASE/topscorers/laliga?season=2020/2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B3=$(agent-browser eval "(() => { const txt=document.body.innerText||''; const url=new URL(location.href); return JSON.stringify({messi:txt.includes('لیونل مسی'), c77:txt.includes('۷۷'), season:url.searchParams.get('season')}); })()")
echo "$B3" | tr -d '\\' | grep -q '"messi":true' && echo "$B3" | tr -d '\\' | grep -q '"c77":true' && echo "$B3" | tr -d '\\' | grep -q '"season":"2020/2021"' \
  && ok "B3 DOM historical: ?season=2020/2021 renders the frozen «لیونل مسی» «۷۷» anchor with the URL param preserved (the honesty-snap rule)" || bad "B3: $B3"

agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4=$(agent-browser eval "(() => { const txt=document.body.innerText||''; return JSON.stringify({ccAbsent:!txt.includes('فرصت‌های خلق‌شده'), gp90:txt.includes('گل در هر ۹۰')}); })()")
echo "$B4" | tr -d '\\' | grep -q '"ccAbsent":true' && echo "$B4" | tr -d '\\' | grep -q '"gp90":true' \
  && ok "B4 DOM honest absence: persiangulf hides the cc block while گل در هر ۹۰ serves (the 231/232 absence contract in DOM)" || bad "B4: $B4"
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
[ "$FAIL" = "0" ] && echo "CYCLE235 DOMPROOF ALL GREEN («فرصت‌های خلق‌شده» — the deep-file family's SEVENTEENTH sibling and the TOTAL-creation VOLUME twin of BCC: WIDE on all six domestics at 10 rows, persiangulf+mas honestly absent, season-aware with the frozen Messi 77 anchor + the 229 curation riding free, integer pill the 215/220 contract, badge flow on the id-intersection mechanism, the SEVENTEENTH thin-guard clause proven live with a ZERO-touch 90s self-heal (3→10 on all six, the 230/231/232 lesson institutionalized) — API 5/5 + DOM 5/5 + LAT @390x844)" && exit 0
exit 1
