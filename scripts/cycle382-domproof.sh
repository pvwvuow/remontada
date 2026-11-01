#!/usr/bin/env bash
# cycle382-domproof.sh — update cycle 382: the FIFA World Cup joins the
# portal (31st competition, FIRST national-team tournament). DOM proof at
# 390x844 that the new /league/worldcup surface renders the CLASSIC table
# path (60 rows: 12 groups «گروه A..L» + «بهترین تیم‌های سوم» — the
# composite branch grown by 5 keys), the plain-year season contract
# (?season=2022 deep link end-to-end — the headline gap), the 6-round
# bracket with the NEW «بازی رده‌بندی» bronze round (France 4-6 England),
# ZERO Latin team names (the 8 COUNTRY_FA entries + چکسلواکی), the 23-edition
# title history (1930 → 2026 اسپانیا), transfers honestly ABSENT, and the
# negative season guards byte-identical (2020/21 → 400 everywhere; plain
# years rejected for unflagged leagues). Sibling sanity: facup/coppaitalia/
# dfbpokal/pl untouched.
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
dots() { agent-browser eval "(document.body.innerText.match(/[\u06F0-\u06F9]\.[\u06F0-\u06F9]/g)||[]).length" 2>/dev/null | tr -d '"'; }
scoreCensus() { agent-browser eval "(() => { const spans=[...document.querySelectorAll('span')].map(s=>s.textContent.trim()).filter(t=>/^[0-9\u06F0-\u06F9]+ : [0-9\u06F0-\u06F9]+$|^\u2014 : \u2014$/.test(t)); return [spans.length, spans.filter(t=>/[0-9]/.test(t)).length, spans.filter(t=>/[\u06F0-\u06F9]/.test(t)).length].join('|'); })()" 2>/dev/null | tr -d '"'; }
censusCk() { # $1=label $2=n|ascii|persian  $3=min n
  local N ASC PE
  N=$(echo "$2" | cut -d'|' -f1); ASC=$(echo "$2" | cut -d'|' -f2); PE=$(echo "$2" | cut -d'|' -f3)
  ck "$1 (n=$N ascii=$ASC persian=$PE, need n≥$3 ascii=0 persian=n)" "$([ "${N:-0}" -ge "$3" ] && [ "${ASC:-1}" = "0" ] && [ "${PE:-0}" = "${N:-1}" ] && echo 1 || echo 0)"
}

# ================= API prelude (UA Chrome/124) =================
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
# A1: the classic-table contract for worldcup (60 rows, composite groups)
D=$(api '/api/standings?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
gs=d.get('groups') or []
ok = (d.get('ok') and 'noTable' not in d and len(d.get('rows',[]))==60
      and d.get('color')=='#06062D' and d.get('selectedSeason')=='2026'
      and len(gs)==13 and gs[0]['fa']=='گروه A' and gs[0]['count']==4
      and gs[11]['fa']=='گروه L' and gs[12]['fa']=='بهترین تیم‌های سوم' and gs[12]['count']==12
      and len(d.get('allSeasons',[]))==12 and d['allSeasons'][0]=='2026' and d['allSeasons'][1]=='2022'
      and len(d.get('legend',[]))==2 and d['legend'][0]['fa']=='صعود به مرحلهٔ بعد' and d['legend'][1]['fa']=='صعودِ احتمالی به مرحلهٔ بعد')
print(1 if ok else 0)")
ck "A1 worldcup table contract (rows60/#06062D/sel2026/12 plain seasons/13 groups/legend2)" "$D"
# A2: the Iran row + zero Latin fa across all 60 rows
D=$(api '/api/standings?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows',[])
iran=[r for r in rows if r.get('teamId')==6711]
latin=[r.get('fa') for r in rows if any('a'<=ch.lower()<='z' for ch in (r.get('fa') or ''))]
ok = d.get('ok') and iran and iran[0]['fa']=='ایران' and iran[0]['draws']==3 and iran[0]['pts']==3 and iran[0]['played']==3 and not latin
print(1 if ok else 0)
print('IRAN:', json.dumps(iran[0], ensure_ascii=False)[:120] if iran else 'MISSING', ' LATIN:', latin[:6], file=sys.stderr)")
ck "A2 iran row (۳مساوی/۳امتیاز) + zero Latin fa in 60 rows" "$D"
# A3: bracket 2026 — 6 Persian rounds incl. the NEW «بازی رده‌بندی» + zero Latin
D=$(api '/api/league-bracket?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rs=(d.get('bracket') or {}).get('rounds') or []
names=[]
for r in rs:
    for m in r.get('matchups',[]):
        for side in ['home','away']: names.append((m.get(side) or {}).get('name') or '')
        for leg in (m.get('legs') or []):
            for side in ['home','away']: names.append((leg.get(side) or {}).get('name') or '')
latin=[n for n in names if any(ch.isalpha() and ord(ch)<0x0600 for ch in n)]
shape = [ (r.get('stageFa'), len(r.get('matchups',[]))) for r in rs ]
ok = (d.get('ok') and shape==[('یک‌شانزدهم نهایی',16),('یک‌هشتم نهایی',8),('یک‌چهارم نهایی',4),('نیمه‌نهایی',2),('فینال',1),('بازی رده‌بندی',1)] and not latin)
s=json.dumps(d, ensure_ascii=False)
ok = ok and all(w in s for w in ['اسپانیا','آرژانتین','فرانسه','انگلیس','مراکش','آلمان'])
fin = rs[-2]['matchups'][0]; brz = rs[-1]['matchups'][0]
ok = ok and fin.get('winnerId')==6720 and brz.get('winnerId')==8491 and brz['home']['name']=='فرانسه' and brz['away']['name']=='انگلیس'
print(1 if ok else 0)
print('SHAPE:', shape, ' LATIN:', latin[:8], file=sys.stderr)")
ck "A3 bracket 2026: 6 Persian rounds + bronze فرانسه–انگلیس + zero Latin names" "$D"
# A4: bracket 2022 (plain-year season param at the API level)
D=$(api '/api/league-bracket?league=worldcup&season=2022' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rs=(d.get('bracket') or {}).get('rounds') or []
shape=[(r.get('stageFa'), len(r.get('matchups',[]))) for r in rs]
ok = d.get('ok') and (d.get('bracket') or {}).get('selectedSeason')=='2022' and shape==[('یک‌هشتم نهایی',8),('یک‌چهارم نهایی',4),('نیمه‌نهایی',2),('فینال',1),('بازی رده‌بندی',1)]
if ok:
    fin=rs[-2]['matchups'][0]; brz=rs[-1]['matchups'][0]
    ok = fin['home']['name']=='آرژانتین' and fin['away']['name']=='فرانسه' and fin.get('winnerId')==6706 and brz['home']['name']=='کرواسی' and brz['away']['name']=='مراکش'
print(1 if ok else 0)")
ck "A4 bracket 2022 (plain-year): فینال آرژانتین–فرانسه + برنز کرواسی–مراکش" "$D"
# A5: the negative season guards byte-identical
# (NOTE the 382 probe lesson: the api() helper fetches the BODY — status
# probes must go through a raw curl -w, same artifact class as 373/378/379)
D=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/standings?league=worldcup&season=2020/21")
ck "A5 worldcup 2020/21 → 400 (slash contract still rejects two-stage)" "$([ "$D" = "400" ] && echo 1 || echo 0)"
D=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/standings?league=mas&season=2023")
ck "A5 mas 2023 → 400 (the 162 plain-year contract for unflagged leagues)" "$([ "$D" = "400" ] && echo 1 || echo 0)"
D=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/standings?league=pl&season=2022")
ck "A5 pl 2022 → 400 (plain year rejected without the flag)" "$([ "$D" = "400" ] && echo 1 || echo 0)"
D=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/standings?league=worldcup&season=abcd")
ck "A5 worldcup junk season → 400" "$([ "$D" = "400" ] && echo 1 || echo 0)"
# A6: fixtures-all — 104 rows, Persian round census
D=$(api '/api/league-fixtures-all?league=worldcup' | python3 -c "
import json,sys,collections; d=json.load(sys.stdin)
rows=d.get('rows') or []
c=collections.Counter((f.get('round') or '—') for f in rows)
ok = (d.get('ok') and len(rows)==104
      and c.get('هفته ۱')==24 and c.get('هفته ۲')==24 and c.get('هفته ۳')==24
      and c.get('یک‌شانزدهم نهایی')==16 and c.get('یک‌هشتم نهایی')==8
      and c.get('یک‌چهارم نهایی')==4 and c.get('نیمه‌نهایی')==2
      and c.get('بازی رده‌بندی')==1 and c.get('فینال')==1)
bad=[f.get('round') for f in rows if f.get('round') and any('a'<=ch.lower()<='z' for ch in f['round'])]
print(1 if ok and not bad else 0)")
ck "A6 fixtures 104 rows + full Persian round census (هفته ۱..۳ + حذفی + رده‌بندی)" "$D"
# A7: titles — the 23-edition history incl. the چکسلواکی fix
D=$(api '/api/league-titles?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
t=d.get('titles') or {}; items=t.get('items') or []
latin=[(it.get('season'),it.get('championFa'),it.get('runnerUpFa')) for it in items if any('a'<=ch.lower()<='z' for ch in (it.get('championFa') or '')+(it.get('runnerUpFa') or ''))]
ok = (d.get('ok') and t.get('total')==23 and len(items)==23
      and items[0].get('championFa')=='اسپانیا' and items[0].get('runnerUpFa')=='آرژانتین'
      and items[1].get('championFa')=='آرژانتین'
      and items[-1].get('season')=='1930 Uruguay' and items[-1].get('championFa')=='اروگوئه'
      and 'چکسلواکی' in json.dumps(items, ensure_ascii=False) and not latin)
print(1 if ok else 0)
print('LATIN:', latin[:4], file=sys.stderr)")
ck "A7 titles 23 editions (اسپانیا 2026 … اروگوئه 1930) + چکسلواکی healed + zero Latin" "$D"
# A8/A9/A10: sibling sanity — cups + PL untouched
D=$(api '/api/standings?league=facup' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#02264C' and len(d.get('allSeasons',[]))==12 and '/' in d['allSeasons'][0] else 0)")
ck "A8 facup noTable contract untouched (slash seasons intact)" "$D"
D=$(api '/api/standings?league=coppaitalia' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#2EA736' else 0)")
ck "A9 coppaitalia noTable contract untouched" "$D"
D=$(api '/api/standings?league=pl' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and len(d.get('rows',[]))==20 and 'noTable' not in d and d['rows'][0]['name']=='Arsenal' else 0)")
ck "A10 pl table path untouched (rows20/Arsenal/no-noTable)" "$D"

# ================= P1 /league/worldcup (the new surface) =================
fresh "$BASE/league/worldcup"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P1 worldcup h1 «جام جهانی» (got «$H1»)" "$([ "$H1" = "جام جهانی" ] && echo 1 || echo 0)"
DOT=$(agent-browser eval "(() => { const s=document.querySelector('h1 span[aria-hidden]'); return s ? getComputedStyle(s).backgroundColor : 'none'; })()" 2>/dev/null | tr -d '"')
ck "P1 worldcup accent dot #06062D (got $DOT)" "$([ "$DOT" = "rgb(6, 6, 45)" ] && echo 1 || echo 0)"
CHIP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('INT') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 worldcup INT chip present" "$([ "$CHIP" = "yes" ] && echo 1 || echo 0)"
GRP=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('گروه A'), t.includes('گروه G'), t.includes('گروه L'), t.includes('بهترین تیم‌های سوم'), t.includes('ایران'), t.includes('اسپانیا')].every(x=>x) ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 standings DOM: گروه A/G/L + بهترین تیم‌های سوم + ایران + اسپانیا (got $GRP)" "$([ "$GRP" = "yes" ] && echo 1 || echo 0)"
LAT=$(agent-browser eval "(() => { const t=document.body.innerText; const bad=['Mexico','Spain','Argentina','England','France','Germany','Morocco','Netherlands','Iran','New Zealand','Turkiye','Czechoslovakia']; return bad.filter(w=>t.includes(w)).join(','); })()" 2>/dev/null | tr -d '"')
ck "P1 standings ZERO Latin leaks (got «$LAT»)" "$([ -z "$LAT" ] && echo 1 || echo 0)"
SEL=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.options.length : 0; })()" 2>/dev/null | tr -d '"')
ck "P1 season selector 12 options (got $SEL)" "$([ "$SEL" = "12" ] && echo 1 || echo 0)"
SELV=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.options[0].textContent.trim() : ''; })()" 2>/dev/null | tr -d '"')
ck "P1 first season option «۲۰۲۶ (فعلی)» (got «$SELV»)" "$([ "$SELV" = "۲۰۲۶ (فعلی)" ] && echo 1 || echo 0)"
TR=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='انتقال‌ها') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 transfers tab honestly ABSENT (got $TR)" "$([ "$TR" = "no" ] && echo 1 || echo 0)"
BT=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='براکت') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 bracket tab present" "$([ "$BT" = "yes" ] && echo 1 || echo 0)"
# switch to the bracket tab: the 6 Persian rounds incl. «بازی رده‌بندی»
# (the bracket payload lands client-side — poll up to ~12s; the 378 P8 lesson)
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
BR='no'
for i in 1 2 3 4 5 6; do
  sleep 2
  BR=$(agent-browser eval "(() => { const t=document.body.innerText; const need=['یک‌شانزدهم نهایی','یک‌هشتم نهایی','نیمه‌نهایی','فینال','بازی رده‌بندی','اسپانیا','آرژانتین','فرانسه','انگلیس']; return need.every(w=>t.includes(w)) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
  [ "$BR" = "yes" ] && break
done
ck "P1 bracket renders 5 Persian stages + بازی رده‌بندی + اسپانیا/آرژانتین/فرانسه/انگلیس (got $BR)" "$([ "$BR" = "yes" ] && echo 1 || echo 0)"
LAT2=$(agent-browser eval "(() => { const t=document.body.innerText; const bad=['Mexico','Spain','Argentina','England','France','Germany','Morocco','Netherlands','Portugal','Brazil','Uruguay','Croatia','Japan']; return bad.filter(w=>t.includes(w)).join(','); })()" 2>/dev/null | tr -d '"')
ck "P1 bracket ZERO Latin leaks (got «$LAT2»)" "$([ -z "$LAT2" ] && echo 1 || echo 0)"
C=$(scoreCensus)
censusCk "P1 bracket score spans all Persian (379 F1 contract holds)" "$C" 10
hygiene "P1 league/worldcup-bracket"

# ================= P2 plain-year deep link /league/worldcup?season=2022 =================
fresh "$BASE/league/worldcup?season=2022"
sleep 3
DV=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.value : ''; })()" 2>/dev/null | tr -d '"')
ck "P2 deep link selector value «2022» survives (got «$DV»)" "$([ "$DV" = "2022" ] && echo 1 || echo 0)"
SEL2=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? [...s.options].find(o=>o.selected)?.textContent.trim() : ''; })()" 2>/dev/null | tr -d '"')
ck "P2 selected option label «۲۰۲۲» (got «$SEL2»)" "$([ "$SEL2" = "۲۰۲۲" ] && echo 1 || echo 0)"
P22='no'
for i in 1 2 3 4 5 6; do
  agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
  sleep 2
  P22=$(agent-browser eval "(() => { const t=document.body.innerText; const need=['بازی رده‌بندی','آرژانتین','فرانسه','کرواسی','مراکش']; return need.every(w=>t.includes(w)) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
  [ "$P22" = "yes" ] && break
done
ck "P2 2022 bracket end-to-end: آرژانتین/فرانسه final + کرواسی/مراکش bronze (got $P22)" "$([ "$P22" = "yes" ] && echo 1 || echo 0)"
hygiene "P2 worldcup-2022-deeplink"

# ================= P3 /topscorers/worldcup (honest empty, new SSG path) =================
fresh "$BASE/topscorers/worldcup"
CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/topscorers/worldcup")
ck "P3 topscorers/worldcup HTTP 200 (got $CODE)" "$([ "$CODE" = "200" ] && echo 1 || echo 0)"
D=$(dots)
ck "P3 topscorers/worldcup zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P3 topscorers/worldcup"

# ================= P4 /match/4653858 (the final — match pages carry WC ids) =================
fresh "$BASE/match/4653858"
D=$(dots)
ck "P4 match/4653858 zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P4 match/4653858"

# ================= P5 sibling sanity — dfbpokal bracket (379 دارمشتات) =================
fresh "$BASE/league/dfbpokal"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 3
DB=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('دارمشتات') && !t.includes('Darmstadt') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P5 dfbpokal bracket دارمشتات intact (379 F2; got $DB)" "$([ "$DB" = "yes" ] && echo 1 || echo 0)"
hygiene "P5 league/dfbpokal-bracket"

# ================= P6 /league/pl table path sanity =================
fresh "$BASE/league/pl"
ROWS=$(agent-browser eval "document.querySelectorAll('table tbody tr').length" 2>/dev/null | tr -d '"')
ck "P6 pl table renders (got $ROWS rows)" "$([ "${ROWS:-0}" -ge 20 ] && echo 1 || echo 0)"
hygiene "P6 league/pl"

# ================= P7 home sanity =================
fresh "$BASE/"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()?.slice(0,60)" 2>/dev/null | tr -d '"')
hygiene "P7 home"
ck "P7 home h1 rendered («$H1»)" "$([ -n "$H1" ] && echo 1 || echo 0)"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
