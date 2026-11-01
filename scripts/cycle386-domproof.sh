#!/usr/bin/env bash
# cycle386-domproof.sh — bug-hunt cycle 386: the patrol through the corners
# the 385 happy-path domproof never looked at (the 383 method: UNCURATED
# Latin scans on DISPLAY fields + the DOM corners at 390x844).
#
# FINDINGS (evidence asserted at the CURRENT state; cycle-387 فیکس flips):
#   F1 the date-dependent day-feed tail ROTATES daily — today's feed is
#      fully clean (the exact 384 key set), but offset=-1 serves 4 MORE
#      raw IRANIAN Azadegan names (Havadar SC — the bare «havadar» key
#      exists, the «SC» suffix spelling doesn't — Kara Gostar, Naft
#      Masjed Soleyman FC, Niroye Zamini) + raw league headers 17 (−1) /
#      21 (+1) / 11 (+2): every new day mints new leaks. otherRaw
#      124–666 unbounded (documented, NOT scheduled).
#   F2 national-team pages have no designed surface: /team/6711 (Iran)
#      renders the DESIGNED honest error «بازی‌ای برای این تیم در بازه‌ی
#      نزدیک یافت نشد» (the team route builds around nearby matches — a
#      NT between tournaments has none). Honest Persian state, no crash/
#      leak; an NT-aware team page is an آپدیت-scale decision.
#   K1 the bracket/fixture TBD slots carry the DELIBERATE Latin-letter
#      convention («اول گروه A» — the COMPOSITE_REGION_FA class), so the
#      naive Latin scan flags them; not leaks. K2 the calendar endpoint
#      serves ICS text (not JSON) — a probe-artifact for JSON parsers.
# CLEAN verifications: today's day-feed zero raw; AC fixtures/brackets
# across ALL 5 seasons zero raw .fa; AC titles zero Latin (seasonFa
# labels included); catalog standings zero leaks across 25 leagues; the
# AC final h1 fully Persian; tabs/selector/2011 view/topscorers empty/
# home hygiene all clean; search surfaces the new entry (fa + en).
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

# ============ F1: the date-dependent tail (evidence at current state) ============
D=$(api '/api/matches?offset=-1' | python3 -c "
import json,sys; d=json.load(sys.stdin)
gs=d.get('groups') or []
irn=set(); rawH=[]
for g in gs:
    if (g.get('leagueFa') or '')==(g.get('leagueName') or ''): rawH.append(g.get('leagueName'))
    if (g.get('ccode') or '')=='IRN':
        for m in (g.get('matches') or []):
            for k in ('home','away'):
                v=m.get(k) or {}
                if (v.get('fa') or '')==(v.get('name') or '') and v.get('name'): irn.add(v.get('name'))
need={'Havadar SC','Kara Gostar','Naft Masjed Soleyman FC','Niroye Zamini'}
print(1 if (len(irn)==4 and need<=irn and len(rawH)>=10) else 0
); print(' | irnRaw:',sorted(irn),'rawHeaders:',len(rawH),file=sys.stderr)")
ck "F1 offset=-1: 4 NEW raw IRANIAN names (Havadar SC/Kara Gostar/Naft Masjed Soleyman FC/Niroye Zamini) + ≥10 raw headers" "$D"
D=$(api '/api/matches' | python3 -c "
import json,sys; d=json.load(sys.stdin)
gs=d.get('groups') or []
CATIDS={42,47,87,55,54,53,523,73,10216,525,71,64,536,48,61,538,535,57,9469,69,252,8985,196,40,519,524,138,209,141,132,77}
rawH=[g for g in gs if (g.get('leagueFa') or '')==(g.get('leagueName') or '')]
irn=set(); other=set(); cat=set()
for g in gs:
    for m in (g.get('matches') or []):
        for k in ('home','away'):
            v=m.get(k) or {}
            n=v.get('name') or ''
            if (v.get('fa') or '')==n and n:
                if g.get('leagueId') in CATIDS: cat.add(n)
                elif g.get('ccode')=='IRN': irn.add(n)
                else: other.add(n)
print(1 if (d.get('ok') and len(gs)>=60 and not rawH and not cat and not irn) else 0
); print(' | today: rawHeaders:',len(rawH),'irnRaw:',len(irn),'otherRaw(documented):',len(other),file=sys.stderr)")
ck "F1-contrast TODAY's feed: ZERO raw headers + zero IRN raw (the exact 384 key set holds)" "$D"

# ============ F2: NT team pages — the designed honest error ============
# probe lesson: the api() helper takes only the URL — status probes ride
# raw curl -w (the 373/378/379/382 artifact class, again).
D=$(curl -s -A "$UA" -o /tmp/c386_team.json -w '%{http_code}' "$BASE/api/team/6711")
B2=$(cat /tmp/c386_team.json)
ck "F2 /api/team/6711 → 404 designed Persian error (got $D)" "$([ "$D" = "404" ] && echo "$B2" | grep -q 'بازی‌ای برای این تیم' && echo 1 || echo 0)"

# ============ CLEAN: AC all-season uncurated scans ============
# probe lesson (NEW subclass): parentheses inside an UNQUOTED heredoc body
# nested in $( ) are counted by the parser — heredoc python must live in a
# temp file, never inline in $().
cat > /tmp/c386_clean1.py << 'PYEOF'
import json,subprocess,re,sys
B='http://localhost:3000'
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
def api(p):
    r=subprocess.run(['curl','-s','-A',UA,f'{B}{p}','--max-time','30'],capture_output=True)
    try: return json.loads(r.stdout)
    except Exception: return {}
def latinword(s):
    # the deliberate «گروه A» letter convention: a LATIN WORD of >=3 chars is a
    # leak; a single trailing letter (the group letter) is the K1 convention
    return bool(re.search(r'[A-Za-z]{3,}', s or ''))
bad={}
for se in ['','2023','2019','2015','2011']:
    p='/api/league-fixtures-all?league=asiancup'+(f'&season={se}' if se else '')
    for f in (api(p).get('rows') or []):
        for k in ('home','away'):
            v=(f.get(k) or {}).get('fa') or ''
            if latinword(v): bad.setdefault(se or '2027',set()).add(v)
    p='/api/league-bracket?league=asiancup'+(f'&season={se}' if se else '')
    d=api(p)
    for r in ((d.get('bracket') or {}).get('rounds')) or []:
        for m in (r.get('matchups') or []):
            for k in ('home','away'):
                v=(m.get(k) or {}).get('name') or ''
                if latinword(v): bad.setdefault(se or '2027',set()).add(v)
            for lg in (m.get('legs') or []):
                for k in ('home','away'):
                    v=(lg.get(k) or {}).get('name') or ''
                    if latinword(v): bad.setdefault(se or '2027',set()).add(v)
print(1 if not bad else 0); print(' | leaks:',{k:sorted(v)[:4] for k,v in bad.items()},file=sys.stderr)
PYEOF
D=$(python3 /tmp/c386_clean1.py)
ck "CLEAN1 AC fixtures+brackets across ALL 5 seasons: zero Latin WORDS in fa fields (single group letters = the K1 convention)" "$D"
D=$(api '/api/league-titles?league=asiancup' | python3 -c "
import json,sys,re; d=json.load(sys.stdin)
items=(d.get('titles') or {}).get('items') or []
bad=[1 for it in items if re.search(r'[A-Za-z]{3,}', (it.get('season') or '')+(it.get('championFa') or '')+(it.get('runnerUpFa') or ''))]
print(1 if (len(items)==18 and not bad) else 0)")
ck "CLEAN2 AC titles: 18 items, zero Latin WORDS (seasonFa labels + names)" "$D"
cat > /tmp/c386_clean3.py << 'PYEOF'
import json,subprocess,re,sys
B='http://localhost:3000'
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
def api(p):
    r=subprocess.run(['curl','-s','-A',UA,f'{B}{p}','--max-time','30'],capture_output=True)
    try: return json.loads(r.stdout)
    except Exception: return {}
leak={}
for key in ['pl','laliga','seriea','bundesliga','ligue1','persiangulf','ucl','facup','coppaitalia','dfbpokal','copadelrey','worldcup','asiancup','acl','acltwo','roshn','egypt','iraqstars','qsl','eredivisie','ligaportugal','superlig','mls','brasileirao','ligamx']:
    for r in (api(f'/api/standings?league={key}').get('rows') or []):
        if re.search(r'[A-Za-z]{3,}', r.get('fa') or ''): leak.setdefault(key,set()).add(r.get('fa'))
print(1 if not leak else 0); print(' | leaks:',{k:sorted(v)[:3] for k,v in leak.items()},file=sys.stderr)
PYEOF
D=$(python3 /tmp/c386_clean3.py)
ck "CLEAN3 catalog standings 25 leagues: ZERO raw-pass (the 383 invariant holds)" "$D"

# ============ Guards: the 380/381/382/384/385 contracts ============
D=$(api '/api/standings?league=worldcup' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if d.get('ok') and len(d.get('rows',[]))==60 and d.get('color')=='#06062D' else 0)")
ck "G1 worldcup 382 (rows60/#06062D)" "$D"
D=$(api '/api/standings?league=asiancup&season=2023' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
iran=[r for r in rows if (r.get('name') or '')=='Iran']
print(1 if (d.get('ok') and len(rows)==30 and iran and iran[0].get('fa')=='ایران') else 0)")
ck "G2 asiancup 385 (rows30/Iran fa=ایران)" "$D"
D=$(api '/api/league-fixtures-all?league=dfbpokal' | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
bad=[1 for f in rows for k in ('home','away') if any(ch.isalpha() and ord(ch)<0x0600 for ch in ((f.get(k) or {}).get('fa') or ''))]
print(1 if (len(rows)==56 and not bad) else 0)")
ck "G3 dfbpokal 384 fixtures zero raw (56 rows)" "$D"
D=$(api '/api/standings?league=pl' | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(1 if d.get('ok') and len(d.get('rows',[]))==20 and d['rows'][0]['name']=='Arsenal' else 0)")
ck "G4 pl path (rows20/Arsenal)" "$D"

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

# P1: /team/6711 — the F2 designed honest error state (DOM)
fresh "$BASE/team/6711"
DT=$(agent-browser eval "(() => { const t=document.body.innerText.replace(/FotMob|ESPN/g,''); return [t.includes('بازی‌ای برای این تیم در بازه‌ی نزدیک یافت نشد'), t.includes('تلاش مجدد'), (t.match(/[A-Za-z]{4,}/g)||[]).length].join('|'); })()" 2>/dev/null | tr -d '"')
A=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)$(echo "$DT" | cut -d'|' -f3)
ck "P1 /team/6711 DOM: designed error + retry + zero Latin beyond the footer credit (got $A)" "$([ "$A" = "truetrue0" ] && echo 1 || echo 0)"
hygiene "P1 team/6711"

# P2: /match/4394647 — the AC final h1 fully Persian (the COUNTRY_FA heal through the match path)
fresh "$BASE/match/4394647"
DT=$(agent-browser eval "(() => { const h=document.querySelector('h1')?.textContent?.trim()||''; return [h, (h.match(/[A-Za-z]{3,}/g)||[]).length].join('|'); })()" 2>/dev/null | tr -d '"')
H=$(echo "$DT" | cut -d'|' -f1); L=$(echo "$DT" | cut -d'|' -f2)
ck "P2 /match/4394647 h1 «$H» zero Latin (got $L)" "$([ "$H" = "اردن در برابر قطر — جام ملت‌های آسیا" ] && [ "$L" = "0" ] && echo 1 || echo 0)"
hygiene "P2 match/4394647"

# P3: /league/asiancup — the 7-tab set + the 5-season plain selector (DOM corners)
fresh "$BASE/league/asiancup"
DT=$(agent-browser eval "(() => { const t=document.body.innerText; const sel=document.querySelector('select'); const opts=sel?[...sel.options].map(o=>o.textContent?.trim()):[]; return [t.includes('جدول'), t.includes('براکت'), t.includes('قهرمانان'), opts.length, (opts[0]||'').startsWith('۲۰۲۷')].join('|'); })()" 2>/dev/null | tr -d '"')
A=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)$(echo "$DT" | cut -d'|' -f3)$(echo "$DT" | cut -d'|' -f4)$(echo "$DT" | cut -d'|' -f5)
ck "P3 /league/asiancup DOM: tabs + 5-season selector («۲۰۲۷…» first, got opts=$(echo "$DT" | cut -d'|' -f4))" "$([ "$A" = "truetruetrue5true" ] && echo 1 || echo 0)"
hygiene "P3 league/asiancup"

# P4: season switch → 2011 historical view zero Latin (DOM)
fresh "$BASE/league/asiancup"
agent-browser eval "(() => { const sel=document.querySelector('select'); const set=Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype,'value').set; set.call(sel,'2011'); sel.dispatchEvent(new Event('change',{bubbles:true})); return 1; })()" >/dev/null 2>&1
sleep 4
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [t.includes('۲۰۱۱'), t.includes('ژاپن'), (t.match(/Japan|Australia|Kuwait|Qatar|Bahrain/g)||[]).length].join('|'); })()" 2>/dev/null | tr -d '"')
A=$(echo "$DT" | cut -d'|' -f1)$(echo "$DT" | cut -d'|' -f2)$(echo "$DT" | cut -d'|' -f3)
ck "P4 asiancup 2011 switch: year + ژاپن + zero Latin teams (got $A)" "$([ "$A" = "truetrue0" ] && echo 1 || echo 0)"
hygiene "P4 league/asiancup-2011"

# P5: home + topscorers empty + search surface
fresh "$BASE/topscorers/asiancup"
DT=$(agent-browser eval "(() => { const t=document.body.innerText; return [document.querySelector('h1')?.textContent?.trim()||'', (t.match(/[0-9]\.[0-9]/g)||[]).length].join('|'); })()" 2>/dev/null | tr -d '"')
H=$(echo "$DT" | cut -d'|' -f1); D2=$(echo "$DT" | cut -d'|' -f2)
ck "P5 /topscorers/asiancup h1 «$H» + zero ASCII dots (got $D2)" "$([ "$H" = "آقای گلان جام ملت‌های آسیا" ] && [ "$D2" = "0" ] && echo 1 || echo 0)"
hygiene "P5 topscorers/asiancup"
D=$(api '/api/search?q=%D8%A2%D8%B3%DB%8C%D8%A7' | python3 -c "
import json,sys; d=json.load(sys.stdin)
keys=[x.get('key') for x in (d.get('leagues') or [])]
print(1 if 'asiancup' in keys else 0)")
ck "P5b search «آسیا» surfaces the asiancup entry" "$D"
fresh "$BASE/"
hygiene "P5c home"

agent-browser close --all >/dev/null 2>&1
echo "=== RESULT: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" = "0" ]
