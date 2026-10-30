#!/bin/bash
# cycle234-fixproof.sh — permanent gate for the cycle-234 fix
# (Fix (cycle 234): the 233 hunt's ONE registered finding — the standing
#  name-curation chain (215→217→221→222→229, 'the fallbacks on the SERVED
#  top-10s', the 167 lesson) did NOT ride the 230/231/232 trio, so the THREE
#  newest surfaces' (xGOT 232 / xA 230 / BCC 231) served top-10s rendered
#  raw English on the six domestics: 44 rows as-found (laliga 7 / ucl 7 /
#  pl 10 / seriea 4 / bundesliga 7 / ligue1 9 — re-probed fresh by
#  scripts/cycle234-probe.sh, ZERO drift vs the 233 A1 evidence). The fix
#  continues the chain in the 222/229 pattern: 25 confident transliterations
#  appended to PLAYER_NAME_FA (759→934→959 keys, zero duplicates) covering
#  33 of the 44 rows, under the in-file conventions (روژه مارتی → Roger,
#  آنخل کوره‌آ → Ángel, یولیان برانت → Julian, جاناتان دیوید → Jonathan,
#  امانوئله لولی → Emanuele, ویسنته گوایتا → Vicente); media-verified via
#  fa.wikipedia (امین السباعی — the explicit Angers article) and fa-wiki
#  search (شارل دی کتلاره). The 104 rule holds and the 219 verdict is
#  INTACT: the genuinely doubtful stay honest-English, DELIBERATELY ABSENT
#  (10 names → the remaining 11 rows): Alysson Edward, Danijel Šturm, Yvan
#  Dibango, Ilias Akhomach, Adam Daghim, Derry Scherhant, Joris Chotard,
#  Gessime Yassine, Ilan Kebbal, Lucas Calodat. The read-time freshener
#  (the 170 contract) puts every new entry live without cache invalidation.
#  Supersedes cycle233-hunt.sh A1 (which asserted the gap AS FOUND — the
#  233 card's own supersession note).)
# Part A (API, live-observed 2026-10-30):
#   A1 THE FIX: all 25 curated Persian strings serve somewhere on the three
#      newest surfaces' top-10s across the six domestics; pl+seriea English
#      count == 0 (fully curated today); the 10 registered doubtful names
#      NEVER render Persian (honest-English if present — the 219 class)
#   A2 the trio contract sweep (the 233 A2 contract unchanged): six
#      domestics xgot/xa/bcc = 10 rows, monotonic DESC, positional rank
#      1..10, one-decimal xgot/xa, INTEGER bcc; persiangulf honestly absent
#      from all three; mas cards-only (the 176 rule)
#   A3 the frozen 2020/2021 laliga anchor (zero regression): xGOT rank-1
#      «لیونل مسی» 32.8 one-decimal + xA 13.4 + BCC 22
#   A4 the negative probe: bad season shape 2020/21 → ok:false (the
#      SEASON_PARAM_RE contract, the 233 A5 face)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 /topscorers/laliga: the xgot block renders «روژه بروگه» and the xa
#      block renders «اینیگو ویسنته» + «آنخل پرز» + «خورخه سالیناس» — with
#      the single honest-English row «Ilias Akhomach» still honest
#   B2 /topscorers/pl: ZERO Latin rows on all five testid blocks (pl was
#      10/10 English as-found — fully curated); «مارتین اودگارد» +
#      «مورگان گیبس-وایت» + «گرانیت ژاکا» + «اندرو رابرتسون» in DOM
#   B3 /topscorers/ligue1: «امین السباعی» + «جاناتان کلاوس» in DOM
#   B4 real navigation /player/604785 (Iwobi) → h1 «الکس ایووبی» (the
#      170/176 link contract end-to-end with a newly curated name)
#   B5 console=0 errors=0 across the whole session
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle234-fixproof-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 THE FIX — the 25 curated strings serve; pl+seriea fully Persian; the
# doubtful stay honest-English
: > "$TMP.jsonl"
for K in laliga ucl pl seriea bundesliga ligue1; do
  curl -s "$BASE/api/topscorers/$K" >> "$TMP.jsonl"
  echo "" >> "$TMP.jsonl"
done
A1=$(python3 - "$TMP.jsonl" <<'PY'
import sys,json
FA=lambda s: any('\u0600'<=c<='\u06FF' for c in s)
curated=["مارتین اودگارد","الکس ایووبی","مورگان گیبس-وایت","براهیم دیاز","ایسکو","یوری تیله‌مانس","گرانیت ژاکا","جرمی دوکو","اندرو رابرتسون","ساموئل چوکوووزه","یولیان رایرسون","نادیم امیری","ولادیمیر کوفال","ماریوس وولف","جاناتان کلاوس","امین السباعی","شارل دی کتلاره","خولیو انسیسو","انزو لو فه","آرمان لوریانته","امانوئله والری","اینیگو ویسنته","آنخل پرز","خورخه سالیناس","روژه بروگه"]
doubtful=["Alysson Edward","Danijel Šturm","Yvan Dibango","Ilias Akhomach","Adam Daghim","Derry Scherhant","Joris Chotard","Gessime Yassine","Ilan Kebbal","Lucas Calodat"]
hits={k:0 for k in curated}; doubt_bad=0; per={}
leagues=['laliga','ucl','pl','seriea','bundesliga','ligue1']
docs=[]
with open(sys.argv[1],encoding='utf-8') as f:
    dec=json.JSONDecoder()
    buf=f.read().strip()
    i=0
    while i<len(buf):
        try:
            obj,j=dec.raw_decode(buf,i)
            docs.append(obj); i=j
            while i<len(buf) and buf[i] in ' \n\r\t': i+=1
        except Exception:
            i+=1
for d,k in zip(docs,leagues):
    en=0
    for sec in ('xgot','xa','bigChancesCreated'):
        for r in (d.get(sec) or [])[:10]:
            nf=r.get('nameFa') or ''; nm=r.get('name') or ''
            if not FA(nf): en+=1
            for c in curated:
                if nf==c: hits[c]+=1
            for dn in doubtful:
                if dn in nm and FA(nf): doubt_bad+=1
    per[k]=en
missing=[c for c in curated if hits[c]==0]
print('MISSING',len(missing),'|',';'.join(missing[:3]) if missing else '-')
print('DOUBT_BAD',doubt_bad,'|'.join(f'{k}:{v}' for k,v in per.items()))
PY
)
M=$(echo "$A1" | sed -n 's/^MISSING \([0-9]*\).*/\1/p')
P=$(echo "$A1" | awk 'NR==2')
PL=$(echo "$P" | grep -o 'pl:[0-9]*'); SA=$(echo "$P" | grep -o 'seriea:[0-9]*')
DB=$(echo "$A1" | sed -n 's/^DOUBT_BAD \([0-9]*\).*/\1/p')
[ "$M" = "0" ] && [ "$PL" = "pl:0" ] && [ "$SA" = "seriea:0" ] && [ "$DB" = "0" ] \
  && ok "A1 THE FIX: all 25 curated Persian strings serve on the three newest surfaces' top-10s (each ≥1), pl+seriea English count == 0 (fully curated — were 10+4), and the 10 doubtful names never render Persian (the 219 class intact) [$P]" \
  || bad "A1: missing=$M pl=$PL seriea=$SA doubt_bad=$DB detail=$A1"

# A2 the trio contract sweep (the 233 A2 contract unchanged)
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
  && ok "A2 trio contract: six domestics each serve xgot=xa=bcc=10 rows (one-decimal xgot/xa, INTEGER bcc, monotonic DESC, positional rank 1..10); persiangulf honestly absent from all three; mas cards-only (the 176 rule)" \
  || bad "A2: sw=$SW pg=$PG mas=$MAS"

# A3 the frozen 2020/2021 laliga anchor — zero regression
A3=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
x=(d.get('xgot') or []); xa=(d.get('xa') or []); b=(d.get('bigChancesCreated') or [])
def f(rows): return (rows[0].get('nameFa'),rows[0].get('xgot') or rows[0].get('xa') or rows[0].get('bigChances') or rows[0].get('value')) if rows else ('NONE','NONE')
print('X',f(x),'A',f(xa),'B',f(b))
")
echo "$A3" | grep -q "X ('لیونل مسی', 32.8)" && echo "$A3" | grep -q "A ('لیونل مسی', 13.4)" && echo "$A3" | grep -q "B ('لیونل مسی', 22)" \
  && ok "A3 frozen 2020/2021 laliga anchor intact: xGOT «لیونل مسی» 32.8 + xA 13.4 + BCC 22 (the 232/230/231 frozen class, the 229 curation riding free)" || bad "A3: $A3"

# A4 the negative probe — bad season shape
N=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A4 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A4: $N"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const txt=document.body.innerText||''; const blocks={}; for (const t of ['xgot','xa']) { const els=Array.from(document.querySelectorAll('[data-testid='+t+'-row]')); blocks[t]={rows:els.length, latin:els.filter(r=>/[A-Za-z]{3,}/.test(r.textContent)).length}; } return JSON.stringify({bruge:txt.includes('روژه بروگه'), vicente:txt.includes('اینیگو ویسنته'), perez:txt.includes('آنخل پرز'), salinas:txt.includes('خورخه سالیناس'), akhomach_honest:txt.includes('Ilias Akhomach'), xgot:blocks.xgot, xa:blocks.xa}); })()")
echo "$B1" | tr -d '\\' | grep -q '"bruge":true' && echo "$B1" | tr -d '\\' | grep -q '"vicente":true' && echo "$B1" | tr -d '\\' | grep -q '"perez":true' && echo "$B1" | tr -d '\\' | grep -q '"salinas":true' && echo "$B1" | tr -d '\\' | grep -q '"akhomach_honest":true' && echo "$B1" | tr -d '\\' | grep -q '"rows":10' \
  && ok "B1 DOM laliga: «روژه بروگه» (xgot) + «اینیگو ویسنته»/«آنخل پرز»/«خورخه سالیناس» (xa) in DOM, 10 rows per testid, the single honest-English «Ilias Akhomach» still honest" || bad "B1: $B1"

agent-browser open "$BASE/topscorers/pl" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B2=$(agent-browser eval "(() => { const txt=document.body.innerText||''; let latin=0; for (const t of ['xg','xgot','gp90','xa','bigChancesCreated']) latin+=Array.from(document.querySelectorAll('[data-testid='+t+'-row]')).filter(r=>/[A-Za-z]{3,}/.test(r.textContent)).length; return JSON.stringify({odegaard:txt.includes('مارتین اودگارد'), gibbs:txt.includes('مورگان گیبس-وایت'), xhaka:txt.includes('گرانیت ژاکا'), robertson:txt.includes('اندرو رابرتسون'), latinAll:latin}); })()")
echo "$B2" | tr -d '\\' | grep -q '"odegaard":true' && echo "$B2" | tr -d '\\' | grep -q '"gibbs":true' && echo "$B2" | tr -d '\\' | grep -q '"xhaka":true' && echo "$B2" | tr -d '\\' | grep -q '"robertson":true' && echo "$B2" | tr -d '\\' | grep -q '"latinAll":0' \
  && ok "B2 DOM pl: ZERO Latin rows across all five testid blocks (pl was 10/10 English as-found — fully curated), «مارتین اودگارد»/«مورگان گیبس-وایت»/«گرانیت ژاکا»/«اندرو رابرتسون» in DOM" || bad "B2: $B2"

agent-browser open "$BASE/topscorers/ligue1" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B3=$(agent-browser eval "(() => { const txt=document.body.innerText||''; return JSON.stringify({sbai:txt.includes('امین السباعی'), clauss:txt.includes('جاناتان کلاوس'), yassine_honest:txt.includes('Gessime Yassine')}); })()")
echo "$B3" | tr -d '\\' | grep -q '"sbai":true' && echo "$B3" | tr -d '\\' | grep -q '"clauss":true' && echo "$B3" | tr -d '\\' | grep -q '"yassine_honest":true' \
  && ok "B3 DOM ligue1: «امین السباعی» + «جاناتان کلاوس» in DOM while «Gessime Yassine» stays honest-English (the 219 class side by side)" || bad "B3: $B3"

agent-browser open "$BASE/player/604785" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4=$(agent-browser eval "(() => { const h=document.querySelector('h1'); return JSON.stringify({h1:(h&&h.textContent.trim())||''}); })()")
echo "$B4" | tr -d '\\' | grep -q '"h1":"الکس ایووبی"' \
  && ok "B4 real navigation: /player/604785 (Iwobi) → h1 «الکس ایووبی» — the 170/176 link contract end-to-end on a newly curated name" || bad "B4: $B4"

CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B5 console=0 errors=0 across the whole session" || bad "B5: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LAT=1
for P_ in / /topscorers/laliga /topscorers/pl; do
  T=$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$BASE$P_")
  echo "     LAT $P_ = ${T}s"
  python3 -c "import sys; sys.exit(0 if float('$T')<5.0 else 1)" || LAT=0
done
[ "$LAT" = "1" ] && ok "Part C warm LAT: 3 routes <5000ms" || bad "Part C: a route exceeded 5000ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE234 FIXPROOF ALL GREEN (the curation chain continued in the 222/229 pattern — the three newest surfaces' top-10s: 25 confident transliterations → 33 of the 44 rows Persian, pl+seriea fully Persian, the 10 doubtful names honest-English by the 219 verdict, the trio contract + frozen anchors + link contract intact, DOM flipped @390x844, console clean)" && exit 0
exit 1
