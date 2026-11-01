#!/usr/bin/env bash
# cycle383-domproof.sh — bug-hunt cycle 383: the patrol that found the
# Persian-mapping gaps the update cycles' happy-path domproofs never
# looked at (378 was page/viewport level; 383 goes through the API
# payload's DISPLAY fields with UNCURATED Latin scans + the DOM corners).
#
# FINDINGS (evidence asserted at the CURRENT buggy state; cycle-384 فیکس
# flips these to zero, same two-cycle rhythm as 378→379):
#   F1 titles  — «قهرمانان» tab of the three cups leaks raw Latin names:
#                facup 9 distinct/15 items, coppaitalia 7/7, dfbpokal
#                16+/26 (VfB Leipzig beyond the API list cap); worldcup 0/23
#                (the 382 titles sweep worked — the cups predate it).
#   F2 dfbpokal fixtures — 29 distinct German teams ride the .fa DISPLAY
#                field raw (32/56 rows of the 2026/2027 season; R1 minnows
#                Bahlinger SC / HEBC Hamburg / 1. FC Phönix Lübeck …).
#   F3 match pages — /match/5750685 h1 = «Preussen Münster در برابر
#                Karlsruher SC — جام حذفی آلمان»: the matchDetails path
#                falls through the same TEAM_FA gap; mapped matches render
#                fully Persian («الچه در برابر والنسیا»). facup match clean
#                (the 381 sweep holds).
#   F4 home day-feed — (a) 17/79 group headers render the RAW competition
#                name (date-dependent list; Saudi First Division / Allsvenskan /
#                Leumit League / Baller League …); (b) 7 IRANIAN Azadegan
#                League teams raw (Mes Kerman, Naft Bandar Abbas …) —
#                audience-critical on a Persian portal; (c) ~191 other
#                world-feed teams raw (unbounded scope — documented, NOT
#                scheduled for full mapping). The CATALOGED contract is
#                100% clean (0 raw-pass in the 31 competitions' groups).
#   K1 player names are Latin portal-wide BY DESIGN (lineups, topscorers).
#   K2 studio micro-labels («TOP MATCH», «LEAGUE LEADER» — 8px tracking
#      kickers) are intentional design, not leaks.
# Guards: the 381/382 contracts untouched, hygiene clean at 390x844.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
latinBad() { python3 -c "
import json,sys
d=json.load(sys.stdin)
items=((d.get('titles') or {}).get('items')) if 'titles' in d else (d.get('rows') or [])
def bad(v): return any(ch.isalpha() and ord(ch)<0x0600 for ch in (v or ''))
print(json.dumps({'n':len(items),'bad':bad}))" ; }

# ============ F1: titles history raw-Latin evidence (3 cups) ============
D=$(api '/api/league-titles?league=facup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
names=set()
for it in items:
    for f in ('championFa','runnerUpFa'):
        v=it.get(f) or ''
        if any(ch.isalpha() and ord(ch)<0x0600 for ch in v): names.add(v)
need={'Wimbledon FC',\"Queen's Park\",'Blackburn Olympic FC','Old Etonians FC','Old Carthusians FC','Clapham Rovers FC','Wanderers Football Club','Royal Engineers AFC','Oxford University AFC'}
print(1 if len(items)==145 and len(names)==9 and need<=names else 0
); print(' | leaks:',json.dumps(sorted(names),ensure_ascii=False),file=sys.stderr)")
ck "F1 facup titles: 15/145 items leak, EXACTLY the 9 amateur-era names" "$D"
D=$(api '/api/league-titles?league=coppaitalia' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
names=set()
for it in items:
    for f in ('championFa','runnerUpFa'):
        v=it.get(f) or ''
        if any(ch.isalpha() and ord(ch)<0x0600 for ch in v): names.add(v)
need={'AC Ancona','Alessandria','Football Padova Spa','Novara','SPAL','Vado','Vicenza'}
print(1 if len(items)==78 and len(names)==7 and need<=names else 0)")
ck "F1 coppaitalia titles: 7/78 items leak, EXACTLY the 7 historic names" "$D"
D=$(api '/api/league-titles?league=dfbpokal' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
names=set()
for it in items:
    for f in ('championFa','runnerUpFa'):
        v=it.get(f) or ''
        if any(ch.isalpha() and ord(ch)<0x0600 for ch in v): names.add(v)
print(1 if len(items)==83 and len(names)>=16 and 'VfB Leipzig' in names and '1860 München' in names else 0
); print(' | distinct:',len(names),file=sys.stderr)")
ck "F1 dfbpokal titles: 26/83 items leak, ≥16 distinct names (VfB Leipzig in DOM)" "$D"
D=$(api '/api/league-titles?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
bad=[it for it in items if any(any(ch.isalpha() and ord(ch)<0x0600 for ch in (it.get(f) or '')) for f in ('championFa','runnerUpFa'))]
print(1 if len(items)==23 and not bad else 0)")
ck "F1 contrast: worldcup titles 23/23 CLEAN (the 382 sweep worked)" "$D"

# ============ F2: dfbpokal fixtures .fa raw evidence ============
D=$(api '/api/league-fixtures-all?league=dfbpokal' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
names=set(); aff=0
for f in rows:
    hit=False
    for k in ('home','away'):
        v=(f.get(k) or {}).get('fa') or ''
        if any(ch.isalpha() and ord(ch)<0x0600 for ch in v): names.add(v); hit=True
    if hit: aff+=1
print(1 if len(rows)==56 and aff>=32 and len(names)>=29 and 'Bahlinger SC' in names and '1. FC Phönix Lübeck' in names and 'Preussen Münster' in names else 0
); print(' | distinct:',len(names),'rows:',aff,file=sys.stderr)")
ck "F2 dfbpokal fixtures: ≥29 distinct German teams ride .fa raw (≥32/56 rows)" "$D"
D=$(api '/api/league-fixtures-all?league=facup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
bad=[(f.get(k) or {}).get('fa') for f in rows for k in ('home','away') if any(ch.isalpha() and ord(ch)<0x0600 for ch in ((f.get(k) or {}).get('fa') or ''))]
print(1 if len(rows)==40 and not bad else 0)")
ck "F2 contrast: facup fixtures .fa CLEAN 40/40 (the 381 sweep holds)" "$D"
D=$(api '/api/league-fixtures-all?league=coppaitalia' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
bad=[(f.get(k) or {}).get('fa') for f in rows for k in ('home','away') if any(ch.isalpha() and ord(ch)<0x0600 for ch in ((f.get(k) or {}).get('fa') or ''))]
print(1 if not bad else 0)")
ck "F2 contrast: coppaitalia fixtures .fa CLEAN" "$D"

# ============ F3: match-page h1 falls through the same gap ============
# (the match page hydrates client-side — probe the DOM, not the raw HTML;
#  the 378/379 artifact class: eval output is a DOUBLE-quoted JSON string,
#  so DOM probes ride plain text + tr, never JSON parsing)
agent-browser close --all >/dev/null 2>&1; agent-browser open "$BASE/match/5750685" >/dev/null 2>&1; agent-browser set viewport 390 844 >/dev/null 2>&1; sleep 4
D=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim() || ''" 2>/dev/null | tr -d '"')
ck "F3 /match/5750685 h1 carries RAW team names + Persian competition (got «$D»)" "$(echo "$D" | grep -q 'Preussen' && echo "$D" | grep -q 'Karlsruher' && echo "$D" | grep -q 'جام حذفی آلمان' && echo 1 || echo 0)"
agent-browser open "$BASE/match/6469281" >/dev/null 2>&1; sleep 4
D=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim() || ''" 2>/dev/null | tr -d '"')
ck "F3 contrast: /match/6469281 (facup) h1 fully Persian (got «$D»)" "$(echo "$D" | grep -q 'بریستول راورز' && echo "$D" | grep -q 'کمبریج یونایتد' && ! echo "$D" | grep -q 'Bristol' && echo 1 || echo 0)"

# ============ F4: home day-feed evidence (catalog-clean invariant HARD) ============
D=$(api '/api/matches' | python3 -c "
import json,sys; d=json.load(sys.stdin)
gs=d.get('groups') or []
CATIDS={42,47,87,55,54,53,523,73,10216,525,71,64,536,48,61,538,535,57,9469,69,252,8985,196,40,519,524,138,209,141,132,77}
rawL=[g for g in gs if (g.get('leagueFa') or '')==(g.get('leagueName') or '')]
catLeak=set(); irn=set(); other=set()
for g in gs:
    for m in (g.get('matches') or []):
        for k in ('home','away'):
            v=m.get(k) or {}
            n=v.get('name') or ''
            if (v.get('fa') or '')==n and n:
                if g.get('leagueId') in CATIDS: catLeak.add(n)
                elif g.get('ccode')=='IRN': irn.add(n)
                else: other.add(n)
print(1 if (d.get('ok') and len(gs)>=60 and not catLeak and len(irn)==7
      and {'Mes Kerman','Naft Bandar Abbas','Qeshm Island','Beasat Kermanshah','Ario Islamshahr','FC Fard','Shahin Bandar Ameri'}<=irn
      and len(rawL)>=15 and len(other)>=150) else 0
); print(' | rawLeagues:',len(rawL),'irnRaw:',len(irn),'otherRaw:',len(other),file=sys.stderr)")
ck "F4 day-feed: catalog 0-leak invariant + 7 IRANIAN raw teams + ≥15 raw league headers (date-dependent scale)" "$D"

# ============ Guards: 381/382 contracts untouched + hygiene ============
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

# P1: dfbpokal — the «قهرمانان» tab renders the F1 leaks (DOM evidence)
fresh "$BASE/league/dfbpokal"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent?.trim()==='قهرمانان'); if(b) b.click(); })()" >/dev/null 2>&1
sleep 2
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('MSV Duisburg')&&t.includes('Kickers Offenbach'), t.includes('بایرن مونیخ')||t.includes('وردربرمن')].join('|'); })()" 2>/dev/null | tr -d '"')
DT=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)
ck "P1 dfbpokal «قهرمانان» DOM: F1 leaks visible alongside Persian names (got $DT)" "$([ "$DT" = "truetrue" ] && echo 1 || echo 0)"
hygiene "P1 league/dfbpokal-titles"

# P2: dfbpokal — the full-season expander renders the F2 leaks (DOM evidence)
fresh "$BASE/league/dfbpokal"
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent?.trim()==='بازی‌های پیش‌رو'); if(b) b.click(); })()" >/dev/null 2>&1
sleep 3
agent-browser eval "(() => { const b=[...document.querySelectorAll('button')].find(x=>x.textContent?.includes('نمایش همهٔ مسابقه‌های فصل')); if(b) b.click(); })()" >/dev/null 2>&1
sleep 5
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('Preussen'), t.includes('Bahlinger')].join('|'); })()" 2>/dev/null | tr -d '"')
DT=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)
ck "P2 dfbpokal full-season expander DOM: F2 leaks visible (Preussen/Bahlinger, got $DT)" "$([ "$DT" = "truetrue" ] && echo 1 || echo 0)"
hygiene "P2 league/dfbpokal-fixtures"

# P3: home — hygiene + the F4 evidence visible + catalog headers Persian
fresh "$BASE/"
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('پریمیرلیگ انگلیس'), t.includes('Mes Kerman')||t.includes('Naft Bandar Abbas'), t.includes('TOP MATCH')].join('|'); })()" 2>/dev/null | tr -d '"')
DT=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)$(echo "$DT" | cut -d'|' -f3)
ck "P3 home DOM: catalog header Persian + F4 IRN leak visible + TOP MATCH (design, got $DT)" "$([ "$DT" = "truetruetrue" ] && echo 1 || echo 0)"
hygiene "P3 home"

# P4: facup match page — fully Persian h1 + no ASCII dots
fresh "$BASE/match/6469281"
D=$(dots)
ck "P4 /match/6469281 zero ASCII dots (got $D)" "$([ "$D" = "0" ] && echo 1 || echo 0)"
hygiene "P4 match/6469281"

# P5: worldcup page sanity (382 untouched)
fresh "$BASE/league/worldcup"
H1=$(agent-browser eval "document.querySelector('h1')?.textContent?.trim()" 2>/dev/null | tr -d '"')
ck "P5 worldcup h1 «جام جهانی» (got «$H1»)" "$([ "$H1" = "جام جهانی" ] && echo 1 || echo 0)"
hygiene "P5 league/worldcup"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
