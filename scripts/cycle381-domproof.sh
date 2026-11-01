#!/usr/bin/env bash
# cycle381-domproof.sh — update cycle 381: FA Cup joins the portal (30th
# competition, fourth live cup bracket). DOM proof at 390x844 that the new
# /league/facup surface renders exactly like its 376/377/380 siblings:
# honest cup empty state, 12-season selector, bracket tab with the Persian
# «دور اول» header (the numeric-stage fix), ZERO Latin team names in the
# whole bracket DOM (the 67-entry TEAM_FA section), transfers honestly
# ABSENT, scorers tab honest empty (upstream serves 0 player categories),
# and faDigits everywhere. Sibling sanity: coppaitalia/dfbpokal/pl intact.
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
# A1: the no-table cup contract for facup
D=$(api '/api/standings?league=facup' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and len(d.get('rows',[]))==0 and d.get('color')=='#02264C' and len(d.get('allSeasons',[]))==12 and d.get('selectedSeason')=='2026/2027' else 0)")
ck "A1 facup noTable contract (rows0/color#02264C/12 seasons/sel 2026/2027)" "$D"
# A2: honest scorers-0 (upstream serves 0 player categories; boards=null)
D=$(api '/api/standings?league=facup' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('scorers')==[] and d.get('boards') in (None, []) else 0)")
ck "A2 facup scorers honestly empty (upstream 0 player categories; boards null/[])" "$D"
# A3: bracket — «دور اول» Persian stage + ZERO Latin team names
D=$(api '/api/league-bracket?league=facup' | python3 -c "
import json,sys; d=json.load(sys.stdin); rs=(d.get('bracket') or {}).get('rounds') or []
names=[]
for r in rs:
    for m in r.get('matchups',[]):
        for side in ['home','away']: names.append((m.get(side) or {}).get('name') or '')
        for leg in (m.get('legs') or []):
            for side in ['home','away']: names.append((leg.get(side) or {}).get('name') or '')
latin=[n for n in names if any(ch.isalpha() and ord(ch)<0x0600 for ch in n) and not any('\u0627'<=ch<='\u06cc' for ch in n)]
ok = d.get('ok') and len(rs)==1 and rs[0].get('stageFa')=='دور اول' and len(rs[0].get('matchups',[]))==64 and not latin
s=json.dumps(d, ensure_ascii=False)
ok = ok and all(w in s for w in ['آکسفوردسیتی','لسترسیتی','استافورد رنجرز','وایکام','شفیلد ونزدی'])
print(1 if ok else 0)
print('LATIN:', latin[:8], file=sys.stderr)")
ck "A3 facup bracket: stage «دور اول» + 64 matchups + zero Latin names (آکسفوردسیتی/لسترسیتی/استافورد رنجرز)" "$D"
# A4: titles
D=$(api '/api/league-titles?league=facup' | python3 -c "import json,sys; d=json.load(sys.stdin); t=d.get('titles') or {}; it=t.get('items') or []; print(1 if d.get('ok') and t.get('total')==145 and it and it[0].get('championFa')=='منچسترسیتی' and it[0].get('runnerUpFa')=='چلسی' else 0)")
ck "A4 facup titles 145 / newest منچسترسیتی over چلسی" "$D"
# A5: fixtures
D=$(api '/api/league-fixtures?league=facup' | python3 -c "import json,sys; d=json.load(sys.stdin); u=d.get('upcoming') or []; print(1 if d.get('ok') and len(u)>=10 and u[0]['home']['fa']=='بریستول راورز' and u[0]['away']['fa']=='کمبریج یونایتد' else 0)")
ck "A5 facup fixtures upcoming (بریستول راورز–کمبریج یونایتد first)" "$D"
# A6/A7/A8: sibling sanity — the three older cups + PL table path untouched
D=$(api '/api/standings?league=coppaitalia' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#2EA736' else 0)")
ck "A6 coppaitalia noTable contract untouched" "$D"
D=$(api '/api/standings?league=dfbpokal' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#004941' else 0)")
ck "A7 dfbpokal noTable contract untouched" "$D"
D=$(api '/api/standings?league=pl' | python3 -c "import json,sys; d=json.load(sys.stdin); print(1 if d.get('ok') and len(d.get('rows',[]))==20 and 'noTable' not in d and d['rows'][0]['name']=='Arsenal' else 0)")
ck "A8 pl table path untouched (rows20/Arsenal/no-noTable)" "$D"

# ================= P1 /league/facup (the new surface) =================
fresh "$BASE/league/facup"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P1 facup h1 «جام حذفی انگلیس» (got «$H1»)" "$([ "$H1" = "جام حذفی انگلیس" ] && echo 1 || echo 0)"
DOT=$(agent-browser eval "(() => { const s=document.querySelector('h1 span[aria-hidden]'); return s ? getComputedStyle(s).backgroundColor : 'none'; })()" 2>/dev/null | tr -d '"')
ck "P1 facup accent dot #02264C (got $DOT)" "$([ "$DOT" = "rgb(2, 38, 76)" ] && echo 1 || echo 0)"
CHIP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('ENG') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 facup ENG chip present" "$([ "$CHIP" = "yes" ] && echo 1 || echo 0)"
CUP=$(agent-browser eval "(() => { const t=document.body.innerText; return t.includes('مسابقات حذفی جدول رده‌بندی ندارند') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 facup honest cup empty copy" "$([ "$CUP" = "yes" ] && echo 1 || echo 0)"
SEL=$(agent-browser eval "(() => { const s=document.querySelector('#season-select'); return s ? s.options.length : 0; })()" 2>/dev/null | tr -d '"')
ck "P1 facup season selector 12 options (got $SEL)" "$([ "$SEL" = "12" ] && echo 1 || echo 0)"
TR=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='انتقال‌ها') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 facup transfers tab honestly ABSENT (got $TR)" "$([ "$TR" = "no" ] && echo 1 || echo 0)"
BT=$(agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; return b.some(x=>x.textContent?.trim()==='براکت') ? 'yes' : 'no'; })()" 2>/dev/null | tr -d '"')
ck "P1 facup bracket tab present" "$([ "$BT" = "yes" ] && echo 1 || echo 0)"
# switch to the bracket tab: Persian «دور اول» header + zero Latin
# (the bracket payload lands client-side — poll up to ~12s instead of a
# fixed sleep; the 378 P8 flake lesson)
# NOTE (378 F3 class, documented): the Leicester tie carries TWO honest
# Persian spellings — matchup level «لسترسیتی» (from "Leicester City") and
# leg level «لستر» (from the bare upstream "Leicester"); «لستر» is a
# substring of both, so the probe anchors on it.
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
BR='no'
for i in 1 2 3 4 5 6; do
  sleep 2
  BR=$(agent-browser eval "(() => { const t=document.body.innerText; const need=['دور اول','آکسفوردسیتی','لستر','وایکام','استافورد رنجرز']; return need.every(w=>t.includes(w)) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
  [ "$BR" = "yes" ] && break
done
ck "P1 facup bracket renders «دور اول» + آکسفوردسیتی/لستر(سیتی)/وایکام/استافورد رنجرز (got $BR)" "$([ "$BR" = "yes" ] && echo 1 || echo 0)"
LAT=$(agent-browser eval "(() => { const t=document.body.innerText; const bad=['Wycombe','Oxford City','Leicester','Stafford','Barnsley','Aldershot','Tranmere','Grimsby','Wigan','Oldham']; return bad.filter(w=>t.includes(w)).join(','); })()" 2>/dev/null | tr -d '"')
ck "P1 facup bracket ZERO Latin leaks (got «$LAT»)" "$([ -z "$LAT" ] && echo 1 || echo 0)"
C=$(scoreCensus)
censusCk "P1 facup bracket score spans all Persian (379 F1 contract holds)" "$C" 10
hygiene "P1 league/facup-bracket"

# ================= P2 /topscorers/facup (honest empty, new SSG path) =================
fresh "$BASE/topscorers/facup"
CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/topscorers/facup")
ck "P2 topscorers/facup HTTP 200 (got $CODE)" "$([ "$CODE" = "200" ] && echo 1 || echo 0)"
D=$(dots)
ck "P2 topscorers/facup zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P2 topscorers/facup"

# ================= P3 sibling sanity — coppaitalia bracket still fully Persian =================
fresh "$BASE/league/coppaitalia"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')]; const t=b.find(x=>x.textContent?.trim()==='براکت'); if(t) t.click(); })()" >/dev/null 2>&1
sleep 3
CI=$(agent-browser eval "(() => { const t=document.body.innerText; const need=['یک\u200cسی\u200cودوم نهایی','فینال','برنده یک\u200cچهارم نهایی']; return need.every(w=>t.includes(w)) ? 'yes':'no'; })()" 2>/dev/null | tr -d '"')
ck "P3 coppaitalia bracket intact (380 contract; got $CI)" "$([ "$CI" = "yes" ] && echo 1 || echo 0)"
hygiene "P3 league/coppaitalia-bracket"

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
