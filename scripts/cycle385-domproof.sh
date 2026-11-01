#!/usr/bin/env bash
# cycle385-domproof.sh — آپدیت cycle 385: the AFC Asian Cup joins the portal
# (the SECOND national-team competition, priority 32, plainYearSeasons).
# Probed live first (UA Chrome/124, 2026-11-02): catalog id 290 from the
# matchDetails parentLeagueId via the matchDetails?matchId= variant (the
# /api/data/match/{id} path 404s for the 2024 final — new artifact subclass);
# the 890103 day-tournament id answers NULL as a league page (cycle-141 gap).
# Hard checks: composite tables (default 2027 = 6 groups; 2023 = 6 groups +
# best-3rd, Iran tops C), the 144-slash bracket (2023 8/4/2/1 + Persian
# stages; 2027 slot codes ride the Persian position guard «دوم گروه A»),
# 18 title seasons (Iran 3×: 1968/1972/1976), fixtures 51/51 with Persian
# roundNames, negative season guards, honest-empty topscorers, zero Latin
# leaks in every fa field, siblings untouched, DOM at 390x844 + clean console.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

# ============ A: standings — the 382 composite class ============
D=$(api '/api/standings?league=asiancup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
raw=[r.get('name') for r in rows if (r.get('fa') or '')==(r.get('name') or '') and r.get('name')]
print(1 if (d.get('ok') and len(rows)==24 and len(d.get('allSeasons') or [])==5
      and (d.get('allSeasons') or [])[0]=='2027' and d.get('color')=='#0c272e'
      and len(d.get('groups') or [])==6 and not raw) else 0
); print(' | rows:',len(rows),'raw:',len(raw),file=sys.stderr)")
ck "A1 asiancup default 2027: rows24/6groups/5 plain seasons/color #0c272e/zero raw fa" "$D"
D=$(api '/api/standings?league=asiancup&season=2023' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
iran=[r for r in rows if (r.get('name') or '')=='Iran']
ok=(d.get('ok') and len(rows)==30 and len(d.get('groups') or [])==7 and iran
    and iran[0].get('fa')=='ایران' and iran[0].get('wins')==3 and iran[0].get('idx')==1)
raw=[r.get('name') for r in rows if (r.get('fa') or '')==(r.get('name') or '') and r.get('name')]
print(1 if (ok and not raw) else 0); print(' | iran fa:',(iran[0] or {}).get('fa') if iran else '-',file=sys.stderr)")
ck "A2 asiancup 2023 deep-link: rows30/7 groups/Iran tops C fa=ایران 3wins/zero raw fa" "$D"
D=$(api '/api/standings?league=asiancup&season=2019' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if (d.get('ok') and len(d.get('rows') or [])==30) else 0)")
ck "A3 asiancup 2019 historical: rows30" "$D"

# ============ B: the 144-slash bracket ============
D=$(api '/api/league-bracket?league=asiancup&season=2023' | python3 -c "
import json,sys,re; d=json.load(sys.stdin)
rounds=(d.get('bracket') or {}).get('rounds') or []
stages=[r.get('stageFa') for r in rounds]
ms=[len(r.get('matchups') or []) for r in rounds]
raw=json.dumps(d,ensure_ascii=False)
latin=[s for s in re.findall(r'\"(?:name|fa)\":\"([^\"]+)\"',raw) if re.search(r'[A-Za-z]',s) and 'http' not in s]
print(1 if (d.get('ok') and len(rounds)==4 and ms==[8,4,2,1]
      and stages==['یک‌هشتم نهایی','یک‌چهارم نهایی','نیمه‌نهایی','فینال'] and not latin) else 0
); print(' | stages:',stages,'ms:',ms,'latin:',len(latin),file=sys.stderr)")
ck "B1 asiancup 2023 bracket: 4 Persian stages 8/4/2/1 + zero Latin names" "$D"
# the 2027 draw serves BOTH position-slot classes (1X winners + 2X runners
# + 3XYZ best-thirds + composed winner strings) — the check asserts the
# MECHANISM (zero Latin + every slot class riding the Persian guard),
# robust to upstream redraws (probe lesson: assert the contract, not one
# frozen draw).
D=$(api '/api/league-bracket?league=asiancup' | python3 -c "
import json,sys,re; d=json.load(sys.stdin)
rounds=(d.get('bracket') or {}).get('rounds') or []
names=set()
for r in rounds:
    for m in (r.get('matchups') or []):
        for k in ('home','away'):
            v=m.get(k) or {}
            names.add(v.get('name') or '')
first=sum(1 for n in names if re.match(r'^اول گروه [A-F]$',n))
second=sum(1 for n in names if re.match(r'^دوم گروه [A-F]$',n))
third=sum(1 for n in names if re.match(r'^سوم گروه‌های',n))
winn=sum(1 for n in names if n.startswith('برنده '))
raw=json.dumps(d,ensure_ascii=False)
latin=[s for s in re.findall(r'\"name\":\"([^\"]+)\"',raw) if re.search(r'[A-Za-z]',s)]
print(1 if (d.get('ok') and len(rounds)==4 and first>=4 and second>=1 and third>=1 and winn>=1 and not latin) else 0
); print(' | first:',first,'second:',second,'third:',third,'winner:',winn,'latin:',len(latin),file=sys.stderr)")
ck "B2 asiancup 2027 bracket: Persian position slots (دوم گروه A / سوم گروه‌های C، D، E / برنده …) + zero Latin" "$D"

# ============ C: titles + fixtures ============
D=$(api '/api/league-titles?league=asiancup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
iran=[it.get('season') for it in items if it.get('championFa')=='ایران']
bad=[1 for it in items if any(any(ch.isalpha() and ord(ch)<0x0600 for ch in (it.get(f) or '')) for f in ('championFa','runnerUpFa'))]
print(1 if (d.get('ok') and len(items)==18 and len(iran)==3 and not bad
      and items[0].get('championFa')=='قطر' and items[0].get('runnerUpFa')=='اردن') else 0
); print(' | items:',len(items),'iran:',iran,file=sys.stderr)")
ck "C1 asiancup titles: 18 seasons, Iran 3× (1968/1972/1976), Qatar over Jordan 2023, zero Latin" "$D"
# probe lesson: the fixtures rows carry the mapped round in `round` (not
# roundFa — that was the 382 bracket-side field name).
D=$(api '/api/league-fixtures?league=asiancup&season=2023' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rec=d.get('recent') or []
rns=set(str(r.get('round') or '') for r in rec)
print(1 if (d.get('ok') and d.get('total')==51 and len(rec)>0 and 'فینال' in rns) else 0
); print(' | total:',d.get('total'),'recent:',len(rec),'round:',sorted(rns),file=sys.stderr)")
ck "C2 asiancup 2023 fixtures: total 51 + recent carries «فینال» round" "$D"
D=$(api '/api/league-fixtures?league=asiancup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
up=d.get('upcoming') or []
print(1 if (d.get('ok') and (d.get('total') or 0)>=51 and len(up)>0) else 0
); print(' | total:',d.get('total'),'upcoming:',len(up),file=sys.stderr)")
ck "C3 asiancup default 2027 fixtures: upcoming scheduled (the drawn edition)" "$D"

# ============ D: negative guards (the 382 class) ============
C1=$(api -w '%{http_code}' -o /dev/null '/api/standings?league=asiancup&season=mas' 2>/dev/null; )
C1=$(curl -s -A "$UA" -o /dev/null -w '%{http_code}' "$BASE/api/standings?league=asiancup&season=mas")
C2=$(curl -s -A "$UA" -o /dev/null -w '%{http_code}' "$BASE/api/standings?league=asiancup&season=2020%2F21")
ck "D1 negative guards: season=mas → 400 (got $C1), season=2020/21 → 400 (got $C2)" "$([ "$C1" = "400" ] && [ "$C2" = "400" ] && echo 1 || echo 0)"

# ============ E: honest-empty topscorers (the cup class) ============
D=$(api '/api/topscorers/asiancup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if (d.get('ok') and d.get('boards') is None) else 0)")
ck "E1 /api/topscorers/asiancup: 200 + boards null (honest empty, the facup class)" "$D"

# ============ Guards: 380/381/382 contracts untouched ============
D=$(api '/api/standings?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if d.get('ok') and len(d.get('rows',[]))==60 and d.get('color')=='#06062D' else 0)")
ck "G1 worldcup 382 contract untouched (rows60/#06062D)" "$D"
D=$(api '/api/standings?league=facup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#02264C' else 0)")
ck "G2 facup 381 noTable contract untouched" "$D"
D=$(api '/api/standings?league=coppaitalia' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if d.get('ok') and d.get('noTable') and d.get('color')=='#2EA736' else 0)")
ck "G3 coppaitalia 380 noTable contract untouched" "$D"
D=$(api '/api/standings?league=pl' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if d.get('ok') and len(d.get('rows',[]))==20 and d['rows'][0]['name']=='Arsenal' else 0)")
ck "G4 pl table path untouched (rows20/Arsenal)" "$D"
D=$(api '/api/matches' | python3 -c "
import json,sys; d=json.load(sys.stdin)
gs=d.get('groups') or []
CATIDS={42,47,87,55,54,53,523,73,10216,525,71,64,536,48,61,538,535,57,9469,69,252,8985,196,40,519,524,138,209,141,132,77}
leak=set()
for g in gs:
    if g.get('leagueId') in CATIDS:
        for m in (g.get('matches') or []):
            for k in ('home','away'):
                v=m.get(k) or {}
                if (v.get('fa') or '')==(v.get('name') or '') and v.get('name'): leak.add(v.get('name'))
print(1 if (d.get('ok') and len(gs)>=60 and not leak) else 0
); print(' | groups:',len(gs),'catLeak:',len(leak),file=sys.stderr)")
ck "G5 day-feed catalog 0-leak invariant holds (31 competitions)" "$D"

fresh() { agent-browser close --all >/dev/null 2>&1; agent-browser open "$1" >/dev/null 2>&1; agent-browser set viewport 390 844 >/dev/null 2>&1; agent-browser errors --clear >/dev/null 2>&1; agent-browser console --clear >/dev/null 2>&1; sleep 3; }
hygiene() { local ERR CON SW CW
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "$1 page-errors=0" "$([ -z "$ERR" ] && echo 1 || echo 0)"
  ck "$1 console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "$1 scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "390" ] && [ "$CW" = "390" ] && echo 1 || echo 0)"
}
dots() { agent-browser eval "(document.body.innerText.match(/[\u06F0-\u06F9]\.[\u06F0-\u06F9]/g)||[]).length" 2>/dev/null | tr -d '"'; }

# P1: /league/asiancup — h1 + Persian teams + zero Latin + selector
fresh "$BASE/league/asiancup"
DT=$(agent-browser eval "(() => { const h=document.querySelector('h1')?.textContent?.trim()||''; const t=document.body.innerText; const lat=['Qatar','Jordan','Iran','Japan','Kuwait'].filter(x=>t.includes(x)); return [h, lat.length, t.includes('ایران')||t.includes('کویت'), t.includes('۲۰۲۷')||t.includes('۲۰۲۳')].join('|'); })()" 2>/dev/null | tr -d '"')
H1=$(echo "$DT" | cut -d'|' -f1); LAT=$(echo "$DT" | cut -d'|' -f2); P3=$(echo "$DT" | cut -d'|' -f3); P4=$(echo "$DT" | cut -d'|' -f4)
ck "P1 /league/asiancup DOM: h1 «$H1» + zero Latin team leaks ($LAT) + Persian names + year" "$([ "$H1" = "جام ملت‌های آسیا" ] && [ "$LAT" = "0" ] && [ "$P3" = "true" ] && [ "$P4" = "true" ] && echo 1 || echo 0)"
hygiene "P1 league/asiancup"

# P2: ?season=2023 deep-link — selector 2023 + Iran group visible
fresh "$BASE/league/asiancup?season=2023"
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('۲۰۲۳'), t.includes('ایران'), (t.match(/Qatar|Jordan|Japan|Kuwait|Bahrain/g)||[]).length].join('|'); })()" 2>/dev/null | tr -d '"')
A=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)$(echo "$DT" | cut -d'|' -f3)
ck "P2 /league/asiancup?season=2023 DOM: year + ایران visible + zero Latin teams (got $A)" "$([ "$A" = "truetrue0" ] && echo 1 || echo 0)"
hygiene "P2 league/asiancup-2023"

# P3: «قهرمانان» tab — 18 title seasons + Iran 3× + zero Latin
fresh "$BASE/league/asiancup"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent?.trim()==='قهرمانان'); if(b) b.click(); })()" >/dev/null 2>&1
sleep 2
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('ایران'), t.includes('قطر'), (t.match(/Qatar|Jordan|Japan|Israel|Kuwait/g)||[]).length].join('|'); })()" 2>/dev/null | tr -d '"')
A=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)$(echo "$DT" | cut -d'|' -f3)
ck "P3 asiancup «قهرمانان» DOM: ایران/قطر visible + zero Latin titles (got $A)" "$([ "$A" = "truetrue0" ] && echo 1 || echo 0)"
hygiene "P3 league/asiancup-titles"

# P4: topscorers honest-empty page + home sanity + worldcup h1 + zero dots
fresh "$BASE/topscorers/asiancup"
D=$(dots); H=$(agent-browser eval "document.body.innerText.includes('آقای گل')||document.body.innerText.includes('گل')" 2>/dev/null | tr -d '"')
ck "P4 /topscorers/asiancup: 200 honest-empty + zero ASCII dots (dots=$D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P4 topscorers/asiancup"
fresh "$BASE/league/worldcup"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P5 worldcup h1 «جام جهانی» (got «$H1»)" "$([ "$H1" = "جام جهانی" ] && echo 1 || echo 0)"
hygiene "P5 league/worldcup"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
