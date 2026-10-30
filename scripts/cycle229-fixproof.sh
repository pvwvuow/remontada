#!/bin/bash
# cycle229-fixproof.sh — permanent gate for the cycle-229 fix
# (Fix (cycle 229): the 228 hunt's ONE registered finding — the standing
#  name-curation chain (215→217→221→222, 'the fallbacks on the SERVED
#  top-10s', the 167 lesson) was NOT continued by 226/227 + a rolling
#  form-drift backlog + the historical anchors. The fix continues the chain
#  in the 222 pattern: 173 confident transliterations appended to
#  PLAYER_NAME_FA, priority: (1) the persiangulf gp90 top-10 (the 228
#  sharpest corner — Iranian players in Latin script on their OWN league's
#  Persian UI), (2) the two newest surfaces (xG 226 + gp90 227), (3) the
#  other currently-served top-10s, (4) the three frozen historical anchors;
#  PLUS the 220 home-league precedent on the persiangulf scorers top-20.
#  The 104 rule: media-verified confident spellings only (fa.wikipedia/
#  varzesh3: اشترکالی/ابن‌طالب/جان دوران/بیفوما/بولای دیا/میکاوتادزه/
#  قلی‌زاده/سورگی/خوسلو). The 219 verdict INTACT: the doubtful
#  (Kocik/Diaoune/Nyland/Valle/Monfray/Simpson-Pusey/Bourabaa/Athekame/
#  Balliu) stay honest-English. Supersedes cycle228-hunt.sh A1/B6b/B7a
#  (which asserted the gap AS FOUND — the 228 card's own supersession note).
#  Persian-leg correction: the 228 pair «گابریل جسوس» is the colloquial
#  variant; Persian media (barcanews/varzesh3-class) spell him «گابریل
#  ژسوس» — the pair flips on the media-correct leg, documented here.)
# Part A (API, live-observed 2026-10-30):
#   A1 THE FIX: the 228 registered A/B pairs flip — Persian query returns
#      ≥1 player for بولای دیا / وحید امیری / توراتی / شهریاری / فلمینگ /
#      گابریل ژسوس (the corrected media leg)
#   A2 the sharpest corner: persiangulf gp90 top-10 ALL TEN rows render
#      Persian (nameFa != name) — rank-1 = (1793813, عرفان شهریاری)
#   A3 the two newest surfaces: xg+gp90 English count == 0 on every league
#      that serves them (6 domestics + ucl + persiangulf); mas honest-absent
#   A4 the historical anchors render Persian: 2020/21 laliga gp90 rank-1
#      «لیونل مسی»، 2023/24 pl «جان دوران»، 2022/23 laliga «کریم بنزما»
#   A5 the 219 verdict intact: Nicolas Kocik rows REMAIN honest-English on
#      all three ligue1 keeper surfaces (deliberately absent from the map)
#   A6 zero-regression: «حسین‌زاده»≥1 + «صیادمنش»≥1 + «امباپه»≥2 controls
#      + the gulf scorers serve Persian (اسانی/حاج‌صفی) + Raphinha single
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 /topscorers/persiangulf renders the «گل در هر ۹۰» block with
#      «عرفان شهریاری» in DOM — zero Latin-script Iranian names in the block
#   B2 search dialog «بولای دیا» renders the بازیکنان row — the not-found
#      hint («با این نام پیدا نشد») ABSENT (228 B7a flipped)
#   B3 the historical UI deep-link (?season=2020/2021) renders «لیونل مسی»
#      (228 B6b registrar face flipped)
#   B4 console=0 errors=0 across the whole session
set -u
BASE="${BASE:-http://localhost:3000}"
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 THE FIX — the six registered pairs (the Persian legs) now hit
A1=1
for Q in "بولای دیا" "وحید امیری" "توراتی" "شهریاری" "فلمینگ" "گابریل ژسوس"; do
  N=$(curl -s "$BASE/api/search?q=$(enc "$Q")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
  [ "$N" -ge 1 ] || { A1=0; echo "     ($Q -> $N)"; }
done
[ "$A1" = "1" ] && ok "A1 THE FIX: all six registered pairs flipped — «بولای دیا»/«وحید امیری»/«توراتی»/«شهریاری»/«فلمینگ»/«گابریل ژسوس» each ≥1 player (were 0 in the 228 A/B sweep)" || bad "A1: a pair still dead"

# A2 the sharpest corner — persiangulf gp90 fully Persian, rank-1 anchor
P=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
gp=d.get('goalsPer90') or []
en=sum(1 for r in gp if (r.get('nameFa') or '')==r['name'])
r1=(gp[0]['playerId'], gp[0].get('nameFa')) if gp else (0,'')
print('PG', len(gp), en, r1[0], r1[1])
")
echo "$P" | grep -q "PG 10 0 1793813 عرفان شهریاری" && ok "A2 sharpest corner: persiangulf gp90 top-10 ALL Persian (0 English rows), rank-1 = (1793813, عرفان شهریاری) — the 228 9/10 corner flipped" || bad "A2: $P"

# A3 the two newest surfaces — zero English rows everywhere they serve
T=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
tot=0
for K in ['ucl','pl','laliga','seriea','bundesliga','ligue1','persiangulf']:
    pass
print('SKIP')
")
T=$(for K in ucl pl laliga seriea bundesliga ligue1 persiangulf; do
  curl -s "$BASE/api/topscorers/$K"
done | py "
import sys,json
tot=0; detail=[]
buf=''
for line in sys.stdin:
    buf+=line
    try:
        d=json.loads(buf); buf=''
    except Exception: continue
    gp=d.get('goalsPer90') or []; xg=d.get('xg') or []
    en=sum(1 for r in gp+xg if (r.get('nameFa') or '')==r['name'])
    tot+=en; detail.append(en)
print('EN', tot, detail)
")
echo "$T" | grep -q "EN 0" && ok "A3 the two newest surfaces: xg+gp90 English rows == 0 across all 7 serving leagues (was 52 in the 228 as-found sweep)" || bad "A3: $T"

# A4 the historical anchors render Persian
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
gp=json.load(sys.stdin).get('goalsPer90') or []
print('M', (gp[0].get('nameFa') or '') if gp else 'NONE')
")
echo "$H" | grep -q "M لیونل مسی" && ok "A4a 2020/21 laliga gp90 rank-1 renders «لیونل مسی» (the 228 A3 anchor)" || bad "A4a: $H"
H2=$(curl -s "$BASE/api/topscorers/pl?season=2023%2F2024" | py "
import sys,json
gp=json.load(sys.stdin).get('goalsPer90') or []
print('D', (gp[0].get('nameFa') or '') if gp else 'NONE')
")
echo "$H2" | grep -q "D جان دوران" && ok "A4b 2023/24 pl gp90 rank-1 renders «جان دوران» (media-verified spelling)" || bad "A4b: $H2"
H3=$(curl -s "$BASE/api/topscorers/laliga?season=2022%2F2023" | py "
import sys,json
gp=json.load(sys.stdin).get('goalsPer90') or []
print('B', (gp[0].get('nameFa') or '') if gp else 'NONE')
")
echo "$H3" | grep -q "B کریم بنزما" && ok "A4c 2022/23 laliga gp90 rank-1 renders «کریم بنزما»" || bad "A4c: $H3"

# A5 the 219 verdict intact — Kocik stays honest-English (deliberate absence)
K=$(curl -s "$BASE/api/topscorers/ligue1" | py "
import sys,json
d=json.load(sys.stdin)
sp=d.get('savesPer90') or []; ps=d.get('penaltySaves') or []
en=sum(1 for r in sp+ps if (r.get('nameFa') or '')==r['name'])
kocik=sum(1 for r in sp+ps if r['name']=='Nicolas Kocik')
print('K', en, kocik)
")
echo "$K" | grep -q "K 2 2" && ok "A5 honesty: Nicolas Kocik renders honest-English on ligue1 sp90+ps (the 219 verdict intact — 1+1 rows, both his)" || bad "A5: $K"

# A6 zero-regression controls
C1=$(curl -s "$BASE/api/search?q=$(enc "حسین‌زاده")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
C2=$(curl -s "$BASE/api/search?q=$(enc "صیادمنش")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
C3=$(curl -s "$BASE/api/search?q=$(enc "امباپه")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
G=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
sc=json.load(sys.stdin).get('scorers') or []
fa=sum(1 for r in sc if (r.get('nameFa') or '')!='')
asani=[r for r in sc if r.get('nameFa')=='جاسیر اسانی']
print('GS', len(sc), fa, bool(asani))
")
R=$(curl -s "$BASE/api/search?q=$(enc "رافینیا")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
print('RAP', sum(1 for p in ps if p['playerId']==696679))
")
[ "$C1" -ge 1 ] && [ "$C2" -ge 1 ] && [ "$C3" -ge 2 ] && echo "$G" | grep -q "GS 20 20 True" && echo "$R" | grep -q "RAP 1" && ok "A6 zero-regression: حسین‌زاده=$C1 صیادمنش=$C2 امباپه=$C3 + gulf scorers 20/20 Persian incl. «جاسیر اسانی» + رافینیا single-listing" || bad "A6: $C1/$C2/$C3 | $G | $R"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const txt=document.body.innerText||''; const g=Array.from(document.querySelectorAll('[data-testid=gp90-row]')); const lat=[...document.querySelectorAll('[data-testid=gp90-row]')].filter(r=>/[A-Za-z]/.test(r.textContent)).length; return JSON.stringify({rows:g.length, shahriari:txt.includes('عرفان شهریاری'), latinRows:lat, h2:txt.includes('گل در هر ۹۰')}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"shahriari":true' && echo "$B1" | tr -d '\\' | grep -q '"latinRows":0' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' && ok "B1 DOM: «گل در هر ۹۰» h2 + 10 gp90-rows on /topscorers/persiangulf, «عرفان شهریاری» in DOM, ZERO Latin-script rows in the block — the 228 B4 face flipped Persian" || bad "B1: $B1"

agent-browser open "$BASE" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1
agent-browser eval "document.querySelector('button[aria-label*=جست], button[class*=search], [class*=search] button')?.click(); 'OPEN'" >/dev/null
sleep 1
agent-browser eval "(() => { const inp=document.querySelector('dialog input, [role=dialog] input, input[type=search], input[type=text]'); const setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set; setter.call(inp,'بولای دیا'); inp.dispatchEvent(new Event('input',{bubbles:true})); return 'TYPED'; })()" >/dev/null
sleep 2
B2=$(agent-browser eval "(() => { const dlg=document.querySelector('dialog,[role=dialog]'); return JSON.stringify({row:(dlg?.textContent||'').includes('بولای دیا'), notFound:(dlg?.textContent||'').includes('با این نام پیدا نشد'), groupHdr:(dlg?.textContent||'').includes('بازیکنان')}); })()")
echo "$B2" | tr -d '\\' | grep -q '"row":true' && echo "$B2" | tr -d '\\' | grep -q '"notFound":false' && echo "$B2" | tr -d '\\' | grep -q '"groupHdr":true' && ok "B2 DOM: «بولای دیا» renders the بازیکنان row — the 228 B7a not-found hint FLIPPED absent" || bad "B2: $B2"

agent-browser open "$BASE/topscorers/laliga?season=2020/2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B3=$(agent-browser eval "(() => { const txt=document.body.innerText||''; return JSON.stringify({messi:txt.includes('لیونل مسی'), xgH2:txt.includes('گل مورد انتظار')||txt.includes('گل در هر ۹۰'), noEnglishMessi:!/(Lionel\s*Messi)/.test(txt)}); })()")
echo "$B3" | tr -d '\\' | grep -q '"messi":true' && echo "$B3" | tr -d '\\' | grep -q '"noEnglishMessi":true' && ok "B3 DOM: the historical UI (2020/2021) renders «لیونل مسی» with zero English 'Lionel Messi' rows — the 228 B6b registrar face flipped" || bad "B3: $B3"

CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B4 console=0 errors=0 across the whole session" || bad "B4: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE229 FIXPROOF ALL GREEN (the curation chain continued — the gulf gp90 corner + the two newest surfaces + the form-drift backlog + the historical anchors Persian, the 219 honesty class intact, DOM flipped @390x844)" && exit 0
exit 1
