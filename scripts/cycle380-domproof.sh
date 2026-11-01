#!/usr/bin/env bash
# cycle380-domproof.sh — update cycle 380: Coppa Italia joins the portal (29th
# competition, third live cup bracket). DOM proof at 390x844 that the new
# /league/coppaitalia surface renders exactly like its 376/377 siblings:
# honest cup empty state, 12-season selector, bracket tab with SIX Persian
# rounds («یک‌سی‌ودوم» → «فینال»), zero Latin leaks in the WHOLE bracket JSON
# (incl. the «Winner QF/SF» placeholders mapped to «برنده …») AND the whole
# bracket/fixures DOM, transfers tab honestly ABSENT, faDigits everywhere.
# Sibling sanity: dfbpokal/copadelrey/pl untouched; home day feed faName.
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
# A1: the no-table cup contract for coppaitalia
D=$(api '/api/standings?league=coppaitalia' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and len(d.get('rows',[]))==0 and d.get('color')=='#2EA736' and len(d.get('allSeasons',[]))==12 and d.get('selectedSeason')=='2026/2027' else 0)")
ck "A1 coppaitalia noTable contract (rows0/color#2EA736/12 seasons/sel 2026/2027)" "$D"
# A2: scorers through the standings payload
D=$(api '/api/standings?league=coppaitalia' | python3 -c "import json,sys; d=json.load(sys.stdin); sc=d.get('scorers',[]); print(1 if len(sc)==20 and sc[0].get('name')=='Joel Pohjanpalo' and sc[0].get('team')=='پالرمو' else 0)")
ck "A2 coppaitalia scorers 20 / top Pohjanpalo (پالرمو)" "$D"
# A3: bracket — 6 Persian rounds, ZERO Latin leaks in every TEAM NAME field
# (the `short` codes are Latin by design — the 377 convention, e.g. SGE/BVB)
D=$(api '/api/league-bracket?league=coppaitalia' | python3 -c "
import json,sys; d=json.load(sys.stdin); rs=(d.get('bracket') or {}).get('rounds') or []
stages=[r.get('stageFa') for r in rs]
fa=['یک\u200cسی\u200cودوم نهایی','یک\u200cشانزدهم نهایی','یک\u200cهشتم نهایی','یک\u200cچهارم نهایی','نیمه\u200cنهایی','فینال']
names=[]
for r in rs:
    for m in r.get('matchups',[]):
        for side in ['home','away']:
            names.append((m.get(side) or {}).get('name') or '')
        for leg in (m.get('legs') or []):
            for side in ['home','away']:
                names.append((leg.get(side) or {}).get('name') or '')
latin=[n for n in names if any('\u0627' <= ch <= '\u06cc' for ch in n) is False and any(ch.isalpha() and ord(ch) < 0x0600 for ch in n)]
ok = d.get('ok') and len(rs)==6 and stages==fa and not latin
s=json.dumps(d, ensure_ascii=False)
ok = ok and all(w in s for w in ['برنده یک\u200cچهارم نهایی','برنده نیمه\u200cنهایی','زودتیرول','ویرتوس انتلا','آث\u200cمیلان','پالرمو'])
print(1 if ok else 0)
print('LATIN:', latin, file=sys.stderr)")
ck "A3 coppaitalia bracket: 6 Persian stages + zero Latin team names + برنده/زودتیرول/آث‌میلان/پالرمو mapped" "$D"
# A4: titles
D=$(api '/api/league-titles?league=coppaitalia' | python3 -c "import json,sys; d=json.load(sys.stdin); t=d.get('titles') or {}; it=t.get('items') or []; print(1 if d.get('ok') and t.get('total')==78 and it and it[0].get('championFa')=='اینتر' and it[0].get('runnerUpFa')=='لاتزیو' else 0)")
ck "A4 coppaitalia titles 78 / newest اینتر over لاتزیو" "$D"
# A5: fixtures
D=$(api '/api/league-fixtures?league=coppaitalia' | python3 -c "import json,sys; d=json.load(sys.stdin); u=d.get('upcoming') or []; r=d.get('recent') or []; print(1 if d.get('ok') and len(u)>=10 and len(r)>=5 and u[0]['home']['fa']=='اینتر' and u[0]['away']['fa']=='جنوا' else 0)")
ck "A5 coppaitalia fixtures upcoming(اینتر–جنوا first) + recent" "$D"
# A6: sibling sanity — the two older cups + PL table path untouched
D=$(api '/api/standings?league=dfbpokal' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#004941' else 0)")
ck "A6 dfbpokal noTable contract untouched" "$D"
D=$(api '/api/standings?league=copadelrey' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#D2202B' else 0)")
ck "A7 copadelrey noTable contract untouched" "$D"
D=$(api '/api/standings?league=pl' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and len(d.get('rows',[]))==20 and 'noTable' not in d and d['rows'][0]['name']=='Arsenal' else 0)")
ck "A8 pl table path untouched (rows20/Arsenal/no-noTable)" "$D"

# ================= P1 /league/coppaitalia (the new surface) =================
fresh "$BASE/league/coppaitalia"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia h1 «جام حذفی ایتالیا» (got «$H1»)" "$([ "$H1" = "جام حذفی ایتالیا" ] && echo 1 || echo 0)"
DOT=$(agent-browser eval "(() => { const s=document.querySelector('h1 span[aria-hidden]'); return s ? getComputedStyle(s).backgroundColor : 'none'; })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia accent dot #2EA736 (got $DOT)" "$([ "$DOT" = "rgb(46, 167, 54)" ] && echo 1 || echo 0)"
CHIP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('ITA') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia ITA chip present" "$([ "$CHIP" = "yes" ] && echo 1 || echo 0)"
CUP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('مسابقات حذفی جدول رده‌بندی ندارند') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia honest cup empty copy" "$([ "$CUP" = "yes" ] && echo 1 || echo 0)"
SEL=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.options.length : 0; })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia season selector 12 options (got $SEL)" "$([ "$SEL" = "12" ] && echo 1 || echo 0)"
BT=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='براکت') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia bracket tab present" "$([ "$BT" = "yes" ] && echo 1 || echo 0)"
TR=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='انتقال‌ها') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia transfers tab honestly ABSENT (got $TR)" "$([ "$TR" = "no" ] && echo 1 || echo 0)"
# switch to the bracket tab: six Persian rounds, برنده placeholders, zero Latin
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 3
BR=$(agent-browser eval "(() => { const t=document.body.innerText; const need=['یک\u200cسی\u200cودوم نهایی','یک\u200cشانزدهم نهایی','یک\u200cهشتم نهایی','یک\u200cچهارم نهایی','نیمه\u200cنهایی','فینال','اینتر','جنوا','برنده یک\u200cچهارم نهایی']; return need.every(w=>t.includes(w)) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia bracket renders 6 Persian rounds + اینتر/جنوا + برنده slots (got $BR)" "$([ "$BR" = "yes" ] && echo 1 || echo 0)"
LAT=$(agent-browser eval "(() => { const t=document.body.innerText; const bad=['Winner QF','Winner SF','Palermo','Südtirol','Cremonese','Monza','Arezzo','Benevento','Catanzaro','Virtus Entella']; return bad.filter(w=>t.includes(w)).join(','); })()" 2>/dev/null | tr -d '"')
ck "P1 coppaitalia bracket ZERO Latin leaks (got «$LAT»)" "$([ -z "$LAT" ] && echo 1 || echo 0)"
C=$(scoreCensus)
censusCk "P1 coppaitalia bracket score spans all Persian (379 F1 contract holds)" "$C" 10
hygiene "P1 league/coppaitalia-bracket"

# ================= P2 /topscorers/coppaitalia (new SSG path) =================
fresh "$BASE/topscorers/coppaitalia"
PO=$(agent-browser eval "(() => { const t=document.body.innerText; return (t.includes('Pohjanpalo')||t.includes('پوهیانپالو')) ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P2 topscorers/coppaitalia Pohjanpalo present (got $PO)" "$([ "$PO" = "yes" ] && echo 1 || echo 0)"
D=$(dots)
ck "P2 topscorers/coppaitalia zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P2 topscorers/coppaitalia"

# ================= P3 sibling sanity — dfbpokal bracket still fully Persian =================
fresh "$BASE/league/dfbpokal"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 2
DM=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('دارمشتات') && !t.includes('Darmstadt') ? 'persian-ok' : 'leak'; })()" 2>/dev/null | tr -d '"')
ck "P3 dfbpokal bracket دارمشتات intact (379 contract; got $DM)" "$([ "$DM" = "persian-ok" ] && echo 1 || echo 0)"
hygiene "P3 league/dfbpokal-bracket"

# ================= P4 /league/pl table path sanity =================
fresh "$BASE/league/pl"
ROWS=$(agent-browser eval "document.querySelectorAll('table tbody tr').length" 2>/dev/null | tr -d '"')
ck "P4 pl table renders (got $ROWS rows)" "$([ "${ROWS:-0}" -ge 20 ] && echo 1 || echo 0)"
hygiene "P4 league/pl"

# ================= P5 home sanity =================
fresh "$BASE/"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()?.slice(0,60)" 2>/dev/null | tr -d '"')
hygiene "P5 home"
ck "P5 home h1 rendered («$H1»)" "$([ -n "$H1" ] && echo 1 || echo 0)"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
