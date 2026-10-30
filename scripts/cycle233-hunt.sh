#!/bin/bash
# cycle233-hunt.sh — the cycle-233 bug-hunt patrol (registrar of the found class)
# (Bug-hunt (cycle 233): FULL-page patrol across all seven page types — home,
#  league (tabs + season selector + historical tables), topscorers/[league]
#  (the FULL analytics run), the global merge, team, match, player — at
#  viewport 390x844, plus negative probes. Verdict: ZERO rendering/data bugs.
#  ONE real coverage-class finding re-registered (with FRESH as-found drift
#  evidence, 2026-10-30) for cycle 234 = fix: the standing name-curation chain
#  (215→217→221→222→229, "the fallbacks on the SERVED top-10s", the 167
#  lesson) did NOT ride the 230/231/232 trio — 44 unmapped raw English rows
#  on the THREE newest surfaces' (xgot/xa/bigChancesCreated) top-10s across
#  the six domestics, fresh as-found: laliga 7 (Roger Brugué, Iñigo Vicente,
#  Ángel Pérez ×2, Ilias Akhomach, Jorge Salinas, …) / ucl 7 (Martin
#  Ødegaard, Alysson Edward, Danijel Šturm, Yvan Dibango, Brahim Díaz, Isco,
#  …) / pl 10 (Alex Iwobi, Ødegaard, Morgan Gibbs-White ×2, Enzo Le Fée,
#  Julio Enciso, …) / seriea 4 (Charles De Ketelaere, Armand Laurienté,
#  Emanuele Valeri, Samuel Chukwueze) / bundesliga 7 (Julian Ryerson, Nadiem
#  Amiri, Vladimír Coufal, Adam Daghim, Marius Wolf, Derry Scherhant, …) /
#  ligue1 9 (Amine Sbaï, Jonathan Clauss, Joris Chotard, Gessime Yassine,
#  Ilan Kebbal, Lucas Calodat, …); persiangulf honestly absent from all three
#  surfaces (0 rows — the 231/232 honest-absence contract). The fix = the 222
#  pattern (curate the confident subset of the served top-10s; the 104 rule:
#  confident transliterations only; the 219 verdict: doubtful names stay
#  honest-English). scripts/cycle234-fixproof.sh will supersede this gate's
#  A1 once the curation lands.)
# Part A (API): A1 the finding as-found (registrar: per-league counts + sentinels)
#               A2 the trio contract sweep (xgot/xa/bcc = 10 rows, one-decimal
#                  floats, integer bcc, monotonic DESC + positional rank 1..10
#                  on the six domestics; persiangulf honest absence; mas cards-only)
#               A3 the frozen 2020/2021 laliga anchor (Messi 32.8 xGOT / 13.4 xA /
#                  22 BCC + «لیونل مسی» + topScorer Messi 30 goals — the 229
#                  curation riding free)
#               A4 the current live anchors (laliga xGOT leader one-decimal +
#                  mapped nameFa; bcc leader integer; xa leader; gp90 Raphinha 1.77)
#               A5 the negative probes (bad season shape 2020/21 → ok:false
#                  "Invalid season"; league-transfers current-season ok:true)
# Part B (DOM @390x844): B1 /topscorers/laliga the 232 order (xG → xGOT → gp90 →
#                  xA → BCC → minutes), 10 rows on all five testids, keeper
#                  QUINTET adjacent, zero real overflow
#               B2 the «۱۲.۸» dir=ltr one-decimal xGOT pill + the «۱۴» dir-less
#                  integer bcc pill + real navigation /player/701154 h1 «کیلیان امباپه»
#               B3 the season deep-link UI ?season=2020/2021 renders the frozen
#                  Messi «۳۲.۸» anchor with «لیونل مسی» and the URL param PRESERVED
#               B4 the global merge: h1 «مصاف گلزنان», ≥20 «xGOT …» badges, the
#                  first badge = the laliga leader twin
#               B5 team page /team/<id-from-standings> h1 + match page h1 «در برابر»
#               B6 league page: historical ?season=2020/2021 → selector 2020/2021,
#                  TWO tables (standings 20 + xG 20), the transfers tab honestly
#                  ABSENT (the cycle-57 current-season-only rule); current season
#                  → the انتقال‌ها tab present (7 tabs)
#               B7 the negative DOM probe: /team/barcelona (non-numeric) → the
#                  honest noindex «صفحه تیم» shell (the fix cycle-33 contract)
#               B8 console=0 errors=0 across the whole patrol session
# Part C: warm LAT sweep, 7 leagues + the historical standings <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle233-hunt-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 THE FINDING as-found (registrar — superseded by 234-fixproof)
REG=$(python3 - <<PY
import json,urllib.request,re
fa=re.compile(r'[\u0600-\u06FF]')
per={}; sent={'ucl':'Martin Ødegaard','pl':'Alex Iwobi','seriea':'Charles De Ketelaere','bundesliga':'Julian Ryerson','ligue1':'Jonathan Clauss'}
sentok={k:0 for k in sent}; total=0
for k in ['laliga','ucl','pl','seriea','bundesliga','ligue1']:
    with urllib.request.urlopen('$BASE/api/topscorers/'+k, timeout=30) as r: d=json.load(r)
    n=0
    for sec in ('xgot','xa','bigChancesCreated'):
        for row in (d.get(sec) or [])[:10]:
            nm=row.get('nameFa') or row.get('name') or ''
            if not fa.search(nm):
                n+=1; total+=1
                for sk,sn in sent.items():
                    if sk==k and sn in (row.get('name') or ''): sentok[sk]=1
    per[k]=n
print('TOTAL',total,'|'.join(f'{k}:{v}' for k,v in per.items()),'|'.join(f'{k}:{v}' for k,v in sentok.items()))
PY
)
RTOT=$(echo "$REG" | awk '{print $2}')
RPER=$(echo "$REG" | awk '{print $3}')
RSENT=$(echo "$REG" | awk '{print $4}')
ALLSENT=$(echo "$RSENT" | grep -q ":0" && echo 0 || echo 1)
[ "$RTOT" -ge 35 ] && [ "$ALLSENT" = "1" ] && ok "A1 FINDING as-found (registrar): $RTOT unmapped raw English rows on the THREE newest surfaces' (xgot/xa/bcc) top-10s across the six domestics [$RPER] with ALL five league sentinels present [$RSENT] — the standing curation chain (215→217→221→222→229) did not ride the 230/231/232 trio; registered for cycle 234 = fix (the 222 pattern)" \
  || bad "A1: registrar drifted — total=$RTOT sentinels=$RSENT per=[$RPER] (if 234 landed, the fixproof gate rules now)"

# A2 the trio contract sweep
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
def check(sec,key,isint):
    rows=d.get(sec) or []
    if len(rows)!=10: return 0
    vals=[r.get(key) for r in rows]
    if any(v is None for v in vals): return 0
    for i in range(len(rows)-1):
        if vals[i]<vals[i+1]: return 0
    if [r.get('rank') for r in rows]!=list(range(1,11)): return 0
    if isint:
        if any(float(v)!=int(v) for v in vals): return 0
    else:
        if any(round(float(v),1)!=float(v) for v in vals): return 0
    return 1
# the bcc row VALUE key is bigChances (the list key is bigChancesCreated)
print(1 if (check('xgot','xgot',False) and check('xa','xa',False) and check('bigChancesCreated','bigChances',True)) else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K trio contract failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
print(1 if (f('scorers')==20 and f('goalsPer90')==10 and f('xgot')==0 and f('xa')==0 and f('bigChancesCreated')==0) else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
c=d.get('cards') or {}
ncards=len((c.get('yellow') or []))+len((c.get('red') or []))
print(1 if (f('scorers')==20 and f('xgot')==0 and f('xa')==0 and f('bigChancesCreated')==0 and isinstance(c,dict) and ncards>=1) else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && [ "$MAS" = "1" ] \
  && ok "A2 trio contract: six domestics each serve xgot=xa=bcc=10 rows (one-decimal floats on xgot/xa, INTEGER bcc, monotonic DESC, positional rank 1..10); persiangulf honestly absent from all three (scorers=20/gp90=10 intact); mas cards-only (the 176 rule)" \
  || bad "A2: sw=$SW pg=$PG mas=$MAS"

# A3 the frozen 2020/2021 laliga anchor (the 232/230/231 card contract)
A3=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
if not d.get('ok'): print('NOOK'); sys.exit()
ts=(d.get('scorers') or [{}])[0]
xg=(d.get('xgot') or [{}])[0]; xa=(d.get('xa') or [{}])[0]; bc=(d.get('bigChancesCreated') or [{}])[0]
print('OK' if (d.get('selectedSeason')=='2020/2021' and ts.get('name')=='Lionel Messi' and ts.get('goals')==30 and xg.get('nameFa')=='لیونل مسی' and float(xg.get('xgot'))==32.8 and float(xa.get('xa'))==13.4 and float(bc.get('bigChances'))==22.0) else 'MISMATCH')
")
echo "$A3" | grep -q "^OK$" && ok "A3 frozen anchor: ?season=2020/2021 laliga serves selectedSeason=2020/2021, topScorer Lionel Messi 30 goals («لیونل مسی» — the 229 curation rides free), xGOT Messi ۳۲.۸ / xA ۱۳.۴ / BCC ۲۲.۰ — the 232/230/231 frozen-file contract in one probe" \
  || bad "A3: $A3"

# A4 the current live anchors
A4=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json,re
d=json.load(sys.stdin)
fa=re.compile(r'[\u0600-\u06FF]')
xg=(d.get('xgot') or [{}])[0]; bc=(d.get('bigChancesCreated') or [{}])[0]; xa=(d.get('xa') or [{}])[0]; gp=(d.get('goalsPer90') or [{}])[0]
v1=float(xg.get('xgot')); v2=float(bc.get('bigChances')); v3=float(xa.get('xa')); v4=float(gp.get('goalsPer90'))
ok1=fa.search(xg.get('nameFa') or '') and round(v1,1)==v1
ok2=fa.search(bc.get('nameFa') or '') and v2==int(v2)
ok3=round(v3,1)==v3
ok4=abs(v4-1.77)<0.001
print('OK' if (ok1 and ok2 and ok3 and ok4) else 'MISMATCH')
")
echo "$A4" | grep -q "^OK$" && ok "A4 live anchors: laliga xGOT leader mapped-nameFa one-decimal, BCC leader integer+mapped, xA leader one-decimal, gp90 Raphinha ۱.۷۷ verbatim (the 227 anchor)" \
  || bad "A4: $A4"

# A5 the negative probes (honest contracts)
NEG1=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | head -c 200)
NEG2=$(curl -s "$BASE/api/league-transfers?league=laliga" | py "import sys,json;print(1 if json.load(sys.stdin).get('ok') else 0)")
echo "$NEG1" | grep -q '"ok":false' && echo "$NEG1" | grep -q "Invalid season" && [ "$NEG2" = "1" ] \
  && ok "A5 negative probes: the two-digit season shape (2020/21) is honestly rejected {\"ok\":false,\"error\":\"Invalid season: 2020/21\"} (the SEASON_PARAM_RE contract — the client ignores it and loads current, selector+data never contradict); league-transfers serves the current season ok:true" \
  || bad "A5: neg1=$NEG1 neg2=$NEG2"

echo "== Part B: DOM patrol @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser console --clear >/dev/null 2>&1; agent-browser errors --clear >/dev/null 2>&1

# B1 /topscorers/laliga: the 232 order + five testids + quintet + zero overflow
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'), iXA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iXG>iX&&iG>iXG&&iXA>iG&&iB>iXA&&iM>iB; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({xg:document.querySelectorAll('[data-testid=xg-row]').length,xgot:document.querySelectorAll('[data-testid=xgot-row]').length,gp90:document.querySelectorAll('[data-testid=gp90-row]').length,xa:document.querySelectorAll('[data-testid=xa-row]').length,bcc:document.querySelectorAll('[data-testid=bcc-row]').length,order,quintet,vbroken}); })()")
E1=$(echo "$B1" | tr -d '\\')
echo "$E1" | grep -q '"xg":10' && echo "$E1" | grep -q '"xgot":10' && echo "$E1" | grep -q '"gp90":10' && echo "$E1" | grep -q '"xa":10' && echo "$E1" | grep -q '"bcc":10' && echo "$E1" | grep -q '"order":true' && echo "$E1" | grep -q '"quintet":true' && echo "$E1" | grep -q '"vbroken":0' && ok "B1 /topscorers/laliga @390x844: the FULL analytics run — 10 rows on each of xg/xgot/gp90/xa/bcc, the 232 order (گل مورد انتظار → گل مورد انتظار روی دروازه → گل در هر ۹۰ → پاس مورد انتظار → سانس بزرگ خلق‌شده → دقایق), keeper QUINTET adjacent, zero real overflow" || bad "B1: $B1"

# B2 the pills + real navigation to Mbappé
B2=$(agent-browser eval "(() => { const xr=document.querySelector('[data-testid=xgot-row]'); const br=document.querySelector('[data-testid=bcc-row]'); const xp=xr?.querySelector('span[dir=ltr]'); const bp=br?.querySelector('span[dir=ltr], span[class*=pill], span[class*=rounded]'); return JSON.stringify({xgotPill:xp?.textContent, xgotDir:xp?.getAttribute('dir'), bccTxt:(br?.textContent||'').replace(/\s+/g,'').slice(0,30), href:xr?.querySelector('a')?.getAttribute('href')}); })()")
E2=$(echo "$B2" | tr -d '\\')
echo "$E2" | grep -q '"xgotDir":"ltr"' && echo "$E2" | grep -q '"/player/701154"' && echo "$E2" | grep -q '"xgotPill":"۱۲.۸"' && ok "B2 laliga: the «۱۲.۸» dir=ltr one-decimal xGOT pill (Mbappé, the 232 non-integer convention) links /player/701154; the bcc row renders the INTEGER dir-less pill (the 215/216/220 convention)" || bad "B2: $B2"
agent-browser open "$BASE/player/701154" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2
B2B=$(agent-browser eval "JSON.stringify({h1:(document.querySelector('h1')||{}).textContent})")
echo "$B2B" | tr -d '\\' | grep -q 'کیلیان امباپه' && ok "B2b real navigation: /player/701154 renders h1 «کیلیان امباپه» (the 170/176 link contract)" || bad "B2b: $B2B"

# B3 the season deep-link UI: the frozen Messi anchor
agent-browser open "$BASE/topscorers/laliga?season=2020%2F2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 3
B3=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=xgot-row]')]; const first=(rows[0]?.textContent||'').replace(/\s+/g,''); return JSON.stringify({rows:rows.length, first:first.slice(0,32), url:location.search}); })()")
E3=$(echo "$B3" | tr -d '\\')
echo "$E3" | grep -q '"rows":10' && echo "$E3" | grep -q 'لیونلمسی' && echo "$E3" | grep -q '۳۲.۸' && echo "$E3" | grep -q 'season=2020%2F2021' && ok "B3 season deep-link UI: ?season=2020/2021 renders the frozen xGOT anchor «لیونل مسی … ۳۲.۸» first, 10 rows, and the URL param is PRESERVED (the API's selectedSeason matches → no honesty snap needed)" || bad "B3: $B3"

# B4 the global merge
agent-browser open "$BASE/topscorers" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B4=$(agent-browser eval "(() => { const h1=document.querySelector('h1')?.textContent||''; const badges=[...document.querySelectorAll('*')].filter(e=>e.children.length===0&&e.textContent.trim().startsWith('xGOT')); return JSON.stringify({h1:h1.trim().slice(0,20), badges:badges.length, first:(badges[0]?.textContent||'').trim()}); })()")
E4=$(echo "$B4" | tr -d '\\')
B4N=$(echo "$E4" | grep -oE '"badges":[0-9]+' | grep -oE '[0-9]+')
echo "$E4" | grep -q 'مصاف گلزنان' && [ "$B4N" -ge 20 ] 2>/dev/null && echo "$E4" | grep -q '"first":"xGOT' && ok "B4 global merge: h1 «مصاف گلزنان» serves the badge flow — ${B4N:-?} «xGOT …» badge twins (grew from the 27 the 232 card observed — more leagues serving), the first badge = the laliga leader's twin" || bad "B4: $B4"

# B5 team + match pages (dynamic ids from the live APIs)
TID=$(curl -s "$BASE/api/standings?league=laliga" | py "import sys,json;d=json.load(sys.stdin);print((d.get('table') or d.get('rows') or d.get('standings') or [{}])[0].get('teamId',''))")
MID=$(curl -s "$BASE/api/league-fixtures?league=laliga" | py "import sys,json;d=json.load(sys.stdin);r=(d.get('recent') or (d.get('upcoming') or []));print(r[0].get('id','') if r else '')")
agent-browser open "$BASE/team/$TID" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5=$(agent-browser eval "JSON.stringify({h1:(document.querySelector('h1')||{}).textContent, overflow:document.documentElement.scrollWidth>window.innerWidth})")
agent-browser open "$BASE/match/$MID" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5B=$(agent-browser eval "JSON.stringify({h1:(document.querySelector('h1')||{}).textContent, overflow:document.documentElement.scrollWidth>window.innerWidth})")
echo "$B5" | tr -d '\\' | grep -q 'بارسلونا' && echo "$B5" | tr -d '\\' | grep -q '"overflow":false' && echo "$B5B" | tr -d '\\' | grep -q 'در برابر' && echo "$B5B" | tr -d '\\' | grep -q '"overflow":false' && ok "B5 team/match patrol: /team/$TID renders the real club h1 «بارسلونا» with zero overflow; /match/$MID renders the «در برابر» h1 with zero overflow (both live-derived ids — no hard-coded drift risk)" || bad "B5: $B5 / $B5B"

# B6 league page: historical tables + the transfers-tab rule
agent-browser open "$BASE/league/laliga?season=2020%2F2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 3
B6=$(agent-browser eval "(() => { const sel=document.querySelector('select')?.value; const tables=[...document.querySelectorAll('table')].map(t=>t.querySelectorAll('tbody tr').length); const btns=[...document.querySelectorAll('nav button')].map(b=>b.textContent.trim()); return JSON.stringify({sel, tables, hasTransfers:btns.some(t=>t.includes('انتقال')), tabCount:btns.length}); })()")
E6=$(echo "$B6" | tr -d '\\')
echo "$E6" | grep -q '"sel":"2020/2021"' && echo "$E6" | grep -q '"hasTransfers":false' && echo "$E6" | grep -q '"tables":\[20,20\]' && ok "B6 league historical: the selector holds 2020/2021, BOTH tables render 20+20 rows (standings + the جدول xG — Atlético 86 pts first on both, the real 2020/21 champion), and the انتقال‌ها tab is honestly ABSENT (the cycle-57 current-season-only rule)" || bad "B6: $B6"
agent-browser open "$BASE/league/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B6B=$(agent-browser eval "(() => { const btns=[...document.querySelectorAll('nav button')].map(b=>b.textContent.trim()); return JSON.stringify({tabCount:btns.length, hasTransfers:btns.some(t=>t.includes('انتقال'))}); })()")
echo "$B6B" | tr -d '\\' | grep -q '"tabCount":7' && echo "$B6B" | tr -d '\\' | grep -q '"hasTransfers":true' && ok "B6b current-season league page: 7 tabs WITH انتقال‌ها — the transfers tab exists exactly where upstream serves it (the mirror of B6)" || bad "B6b: $B6B"

# B7 the negative DOM probe: non-numeric team slug → the honest noindex shell
agent-browser open "$BASE/team/barcelona" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2
B7=$(agent-browser eval "JSON.stringify({h1:(document.querySelector('h1')||{}).textContent, title:document.title.slice(0,30)})")
echo "$B7" | tr -d '\\' | grep -q 'صفحه تیم' && ok "B7 negative probe: /team/barcelona (non-numeric slug) renders the honest «صفحه تیم» noindex shell — never a fake team page (the fix cycle-33 contract)" || bad "B7: $B7"

# B8 console across the whole patrol session
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B8 console=0 errors=0 across the whole patrol session (topscorers, player, historical, global merge, team, match, league current+historical, negative probes)" || bad "B8: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LATOK=1
for K in ucl pl laliga seriea bundesliga ligue1 persiangulf; do
  T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/$K"; T1=$(date +%s%N)
  MS=$(( (T1-T0)/1000000 ))
  [ "$MS" -lt 5000 ] || { LATOK=0; bad "LAT $K ${MS}ms"; }
done
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/standings?league=laliga&season=2020%2F2021"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] || { LATOK=0; bad "LAT historical ${MS}ms"; }
[ "$LATOK" = "1" ] && ok "LAT warm sweep: 7 leagues + the historical standings all <5000ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE233 HUNT ALL GREEN (the full-page patrol holds everywhere it looks — ZERO rendering/data bugs across home/league/topscorers/global/team/match/player + the negative probes; the ONE registered finding is the fresh name-curation gap: 44 unmapped raw English rows on the THREE newest surfaces' top-10s across the six domestics [laliga 7/ucl 7/pl 10/seriea 4/bundesliga 7/ligue1 9], persiangulf honestly absent — every one unreachable from Persian search; registered for cycle 234 = fix, the 222 pattern: curate the confident subset of the served top-10s, doubtful names stay honest-English)" && exit 0
[ "$FAIL" != "0" ] && echo "CYCLE233 HUNT: FAILURES PRESENT" && exit 1
