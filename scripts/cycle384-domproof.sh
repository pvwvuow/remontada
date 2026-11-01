#!/usr/bin/env bash
# cycle384-domproof.sh — فیکس cycle 384: the 383 findings flipped to hard
# zero-leak checks (same two-cycle rhythm as 378→379).
#   F1 titles — facup 145 / coppaitalia 78 / dfbpokal 83 items, ZERO raw
#               Latin in championFa/runnerUpFa + the previously-leaking
#               names now ride Persian anchors.
#   F2 fixtures — dfbpokal 56 rows, ZERO raw .fa + «پروسن مونستر» anchor;
#               facup/coppaitalia stay clean.
#   F3 match pages — /match/5750685 h1 fully Persian (JSON fa + DOM h1).
#   F4 home day-feed — zero raw headers among the 18 probed names, zero
#               IRN raw teams + «مس کرمان» anchor; catalog 0-leak invariant
#               holds; the ~191 world-feed raw teams stay DOCUMENTED (not
#               scheduled for mapping — asserted as recorded, not zero).
# Guards: the 380/381/382 contracts untouched + hygiene at 390x844.
# Probe-lesson compliance (373/378/379/382/383): DOM probes ride plain
# pipe-separated eval output + tr, never JSON parsing; match pages are
# client-hydrated so h1 probes ride the DOM; status probes ride curl -w.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

# ============ F1 flipped: titles zero-Latin + Persian anchors ============
D=$(api '/api/league-titles?league=facup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
bad=[(it.get('championFa'),it.get('runnerUpFa')) for it in items if any(any(ch.isalpha() and ord(ch)<0x0600 for ch in (it.get(f) or '')) for f in ('championFa','runnerUpFa'))]
allv=' '.join(filter(None,(v for it in items for v in (it.get('championFa'),it.get('runnerUpFa')))))
anchor='واندررز' in allv and 'کوئینز پارک' in allv
print(1 if len(items)==145 and not bad and anchor else 0
); print(' | bad:',len(bad),file=sys.stderr)")
ck "F1-flip facup titles: 145 items ZERO Latin + Persian anchors (واندررز/کوئینز پارک)" "$D"
D=$(api '/api/league-titles?league=coppaitalia' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
bad=[(it.get('championFa'),it.get('runnerUpFa')) for it in items if any(any(ch.isalpha() and ord(ch)<0x0600 for ch in (it.get(f) or '')) for f in ('championFa','runnerUpFa'))]
allv=' '.join(filter(None,(v for it in items for v in (it.get('championFa'),it.get('runnerUpFa')))))
anchor='اسپال' in allv and 'پادوا' in allv
print(1 if len(items)==78 and not bad and anchor else 0)")
ck "F1-flip coppaitalia titles: 78 items ZERO Latin + Persian anchors (اسپال/پادوا)" "$D"
D=$(api '/api/league-titles?league=dfbpokal' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
bad=[(it.get('championFa'),it.get('runnerUpFa')) for it in items if any(any(ch.isalpha() and ord(ch)<0x0600 for ch in (it.get(f) or '')) for f in ('championFa','runnerUpFa'))]
allv=' '.join(filter(None,(v for it in items for v in (it.get('championFa'),it.get('runnerUpFa')))))
anchor='ام‌اس‌وی دویسبورگ' in allv and 'لایپزیش' in allv and 'مونیخ ۱۸۶۰' in allv
print(1 if len(items)==83 and not bad and anchor else 0
); print(' | bad:',len(bad),file=sys.stderr)")
ck "F1-flip dfbpokal titles: 83 items ZERO Latin + Persian anchors (دویسبورگ/لایپزیش/مونیخ ۱۸۶۰)" "$D"
D=$(api '/api/league-titles?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
bad=[it for it in items if any(any(ch.isalpha() and ord(ch)<0x0600 for ch in (it.get(f) or '')) for f in ('championFa','runnerUpFa'))]
print(1 if len(items)==23 and not bad else 0)")
ck "F1-keep worldcup titles 23/23 CLEAN (the 382 sweep still holds)" "$D"

# ============ F2 flipped: dfbpokal fixtures .fa zero-Latin ============
D=$(api '/api/league-fixtures-all?league=dfbpokal' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
bad=[(f.get(k) or {}).get('fa') for f in rows for k in ('home','away') if any(ch.isalpha() and ord(ch)<0x0600 for ch in ((f.get(k) or {}).get('fa') or ''))]
allv=' '.join(filter(None,((f.get(k) or {}).get('fa') for f in rows for k in ('home','away'))))
anchor='پروسن مونستر' in allv and 'کارلسروهه' in allv and 'باهلینگن' in allv
print(1 if len(rows)==56 and not bad and anchor else 0
); print(' | bad:',len(bad),file=sys.stderr)")
ck "F2-flip dfbpokal fixtures: 56 rows ZERO raw .fa + Persian anchors (پروسن مونستر/کارلسروهه/باهلینگن)" "$D"
D=$(api '/api/league-fixtures-all?league=facup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
bad=[(f.get(k) or {}).get('fa') for f in rows for k in ('home','away') if any(ch.isalpha() and ord(ch)<0x0600 for ch in ((f.get(k) or {}).get('fa') or ''))]
print(1 if len(rows)==40 and not bad else 0)")
ck "F2-keep facup fixtures .fa CLEAN 40/40" "$D"
D=$(api '/api/league-fixtures-all?league=coppaitalia' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
bad=[(f.get(k) or {}).get('fa') for f in rows for k in ('home','away') if any(ch.isalpha() and ord(ch)<0x0600 for ch in ((f.get(k) or {}).get('fa') or ''))]
print(1 if not bad else 0)")
ck "F2-keep coppaitalia fixtures .fa CLEAN" "$D"

# ============ F3 flipped: match page heals (JSON fa + DOM h1) ============
D=$(api '/api/match/5750685' | python3 -c "
import json,sys; d=json.load(sys.stdin)
m=d.get('match') or {}
h=(m.get('home') or {}).get('fa') or ''
a=(m.get('away') or {}).get('fa') or ''
lf=m.get('leagueFa') or ''
print(1 if h=='پروسن مونستر' and a=='کارلسروهه' and lf=='جام حذفی آلمان' else 0)")
ck "F3-flip /api/match/5750685 JSON: fa fields Persian (پروسن مونستر/کارلسروهه)" "$D"

# ============ F4 flipped: day-feed zero raw among probed + IRN heal ============
D=$(api '/api/matches' | python3 -c "
import json,sys; d=json.load(sys.stdin)
gs=d.get('groups') or []
CATIDS={42,47,87,55,54,53,523,73,10216,525,71,64,536,48,61,538,535,57,9469,69,252,8985,196,40,519,524,138,209,141,132,77}
PROBED={'saudi first division','baller league','leumit league','prva liga','1. cfl','kategoria superiore','veikkausliiga championship group','allsvenskan','primera b','usl league one - championship - quarter-finals','1. divisjon','cup','league cup grp. a','league cup grp. c','liga nacional apertura','superligaen',\"caf women's champions league\"}
rawL=[g for g in gs if (g.get('leagueFa') or '')==(g.get('leagueName') or '')]
stillRaw=[g.get('leagueName') for g in rawL if (g.get('leagueName') or '').lower() in PROBED]
catLeak=set(); irnRaw=set(); irnFa=set(); other=set()
for g in gs:
    for m in (g.get('matches') or []):
        for k in ('home','away'):
            v=m.get(k) or {}
            n=v.get('name') or ''
            if (v.get('fa') or '')==n and n:
                if g.get('leagueId') in CATIDS: catLeak.add(n)
                elif g.get('ccode')=='IRN': irnRaw.add(n)
                else: other.add(n)
    if g.get('ccode')=='IRN':
        for m in (g.get('matches') or []):
            for k in ('home','away'):
                v=m.get(k) or {}
                if (v.get('fa') or ''): irnFa.add(v.get('fa'))
posAnchor='مس کرمان' in irnFa or not irnFa
saudiOk=True
for g in gs:
    if (g.get('leagueName') or '').lower()=='saudi first division' and (g.get('leagueFa') or '')!='دسته اول عربستان': saudiOk=False
print(1 if (d.get('ok') and len(gs)>=60 and not stillRaw and not catLeak and not irnRaw and posAnchor and saudiOk) else 0
); print(' | stillRaw:',stillRaw,'irnRaw:',len(irnRaw),'otherRaw(documented,unscheduled):',len(other),file=sys.stderr)")
ck "F4-flip day-feed: probed 18 headers ZERO raw + catalog 0-leak + IRN 0-leak + مس کرمان anchor" "$D"

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

# P1: dfbpokal «قهرمانان» tab — the F1 leaks GONE (DOM flip)
fresh "$BASE/league/dfbpokal"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent?.trim()==='قهرمانان'); if(b) b.click(); })()" >/dev/null 2>&1
sleep 2
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('MSV Duisburg')||t.includes('Kickers Offenbach'), t.includes('ام‌اس‌وی دویسبورگ')||t.includes('کیکرز اوفنباخ')].join('|'); })()" 2>/dev/null | tr -d '"')
DT=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)
ck "P1 dfbpokal «قهرمانان» DOM: zero Latin leaks + Persian anchor visible (got $DT)" "$([ "$DT" = "falsetrue" ] && echo 1 || echo 0)"
hygiene "P1 league/dfbpokal-titles"

# P2: dfbpokal full-season expander — the F2 leaks GONE (DOM flip)
fresh "$BASE/league/dfbpokal"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent?.trim()==='بازی‌های پیش‌رو'); if(b) b.click(); })()" >/dev/null 2>&1
sleep 3
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent?.includes('نمایش همهٔ مسابقه‌های فصل')); if(b) b.click(); })()" >/dev/null 2>&1
sleep 5
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('Preussen')||t.includes('Bahlinger'), t.includes('پروسن مونستر')||t.includes('باهلینگن')].join('|'); })()" 2>/dev/null | tr -d '"')
DT=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)
ck "P2 dfbpokal full-season DOM: zero Latin leaks + Persian anchor visible (got $DT)" "$([ "$DT" = "falsetrue" ] && echo 1 || echo 0)"
hygiene "P2 league/dfbpokal-fixtures"

# P3: /match/5750685 h1 — the F3 flip (client-hydrated → DOM probe)
fresh "$BASE/match/5750685"
DT=$(agent-browser eval "(() => { const h=document.querySelector('h1')?.textContent||''; return [h.includes('Preussen')||h.includes('Karlsruher'), h.includes('پروسن مونستر')&&h.includes('کارلسروهه')&&h.includes('جام حذفی آلمان')].join('|'); })()" 2>/dev/null | tr -d '"')
DT=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)
ck "P3 /match/5750685 h1 DOM: fully Persian, zero Latin (got $DT)" "$([ "$DT" = "falsetrue" ] && echo 1 || echo 0)"
hygiene "P3 match/5750685"

# P4: home — the F4 IRN leaks GONE (DOM flip) + catalog header Persian + TOP MATCH (design)
fresh "$BASE/"
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('Mes Kerman')||t.includes('Naft Bandar Abbas'), t.includes('مس کرمان')||t.includes('نفت بندرعباس'), t.includes('پریمیرلیگ انگلیس'), t.includes('TOP MATCH')].join('|'); })()" 2>/dev/null | tr -d '"')
A=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)$(echo "$DT" | cut -d'|' -f3)$(echo "$DT" | cut -d'|' -f4)
ck "P4 home DOM: zero IRN Latin + Persian anchor + catalog header + TOP MATCH (got $A)" "$([ "$A" = "falsetruetruetrue" ] && echo 1 || echo 0)"
hygiene "P4 home"

# P5: facup match page — the 381 contract + zero ASCII dots (383 P4 keep)
fresh "$BASE/match/6469281"
D=$(dots)
ck "P5 /match/6469281 zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P5 match/6469281"

# P6: worldcup page sanity (382 untouched)
fresh "$BASE/league/worldcup"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P6 worldcup h1 «جام جهانی» (got «$H1»)" "$([ "$H1" = "جام جهانی" ] && echo 1 || echo 0)"
hygiene "P6 league/worldcup"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
