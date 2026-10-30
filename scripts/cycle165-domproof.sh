#!/usr/bin/env bash
# cycle-165 domproof — Ekstraklasa (اکستراکلاسا لهستان), the 23rd competition
# and the 19th race participant, TWO live Iranian hooks in ONE club (لخ پوزنان:
# صیادمنش 887680 race rank 8 / 5 goals / ccode IRN + غلی‌زاده 746018).
# One-pass API truth + DOM proof @390x844, house pattern (console=0/appErrors=0,
# sw=cw=390, 1 h1, 0 broken images, empty feat FAILS — the 163 hardening).
set -u
B=agent-browser
BASE="http://localhost:3000"
$B set viewport 390 844 >/dev/null
BAD=0

collect() {
  local FEAT="$1" LABEL="$2" OUT C E RC=0
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  echo "$LABEL → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ -z "$FEAT" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

api() { # $1=url $2=label $3=py-assert (reads d)
  local OUT
  OUT=$(python3 - "$1" "$3" << 'PYEOF'
import json, sys, urllib.request
url, code = sys.argv[1], sys.argv[2]
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"}
try:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        import gzip; raw = gzip.decompress(raw)
    d = json.loads(raw.decode("utf-8", "replace"))
    ns = {"json": json}
    exec("import json\nimport urllib.request\nd = json.loads(" + json.dumps(json.dumps(d)) + ")\n" + code, ns)
    print("OK" if ns.get("ok") else "BAD")
except Exception as e:
    print("BAD", type(e).__name__, e)
PYEOF
) 2>/dev/null
  echo "$2 → $OUT"
  [ "$OUT" = "OK" ] || BAD=$((BAD+1))
  return 0
}

echo "== PART A: API truth =="
api "$BASE/api/standings?league=poland" "A1 poland 18 rows لخ پوزنان 28 + scorer block 20 سانچز 9 + صیادمنش IRN" "
rows=d.get('rows') or []; sc=d.get('scorers') or []
say=[s for s in sc if (s.get('nameFa') or '')=='اللهیار صیادمنش']
lead=sc[0] if sc else {}
ok=(d.get('ok') and len(rows)==18 and rows[0].get('fa')=='لخ پوزنان' and rows[0].get('pts')==28
    and len(sc)==20 and lead.get('nameFa')=='خوردی سانچز' and lead.get('goals')==9
    and lead.get('team')=='پوگون شچچین'
    and say and say[0].get('goals')==5 and say[0].get('ccode')=='IRN' and say[0].get('team')=='لخ پوزنان'
    and not any(any('a'<=c.lower()<='z' for c in (r.get('fa') or '')) for r in rows[:5]))"
api "$BASE/api/topscorers" "A2 race 400/20 poland-in mas-out رافینیا 13" "
ts=d.get('scorers') or []; pl=[p.get('leagueKey') for p in (d.get('perLeague') or [])]
lead=ts[0] if ts else {}
ok=(len(ts)==400 and len(pl)==20 and 'poland' in pl and 'mas' not in pl
    and lead.get('nameFa')=='رافینیا' and lead.get('goals')==13)"
api "$BASE/api/topscorers?season=2023/2024" "A3 historical 380/19 poland-in" "
ts=d.get('scorers') or []; pl=[p.get('leagueKey') for p in (d.get('perLeague') or [])]
ok=(len(ts)==380 and len(pl)==19 and 'poland' in pl and 'mas' not in pl)"
api "$BASE/api/league-titles?league=poland" "A4 titles 99 — newest لخ پوزنان/گورنیک زابژه, oldest 1912/1913" "
t=d.get('titles') or {}; items=t.get('items') or []
newest=items[0] if items else {}; oldest=items[-1] if items else {}
ok=(d.get('ok') and t.get('total')==99 and len(items)==99
    and newest.get('season')=='2025/2026' and newest.get('championFa')=='لخ پوزنان' and newest.get('runnerUpFa')=='گورنیک زابژه'
    and oldest.get('season')=='1912/1913' and not any(any('a'<=c.lower()<='z' for c in str(i.get('championFa') or '')) for i in items[:10]))"
api "$BASE/api/league-transfers?league=poland" "A5 transfers 100 items zero-ASCII sides" "
pay=d.get('transfers') or {}; items=pay.get('items') or []
def ascii_in(v): return any('a'<=c.lower()<='z' for c in str(v or ''))
ok=(d.get('ok') and pay.get('leagueFa')=='اکستراکلاسا لهستان' and len(items)==100
    and not any(ascii_in(i['from'].get('fa')) or ascii_in(i['to'].get('fa')) for i in items))"
api "$BASE/api/league-bracket?league=poland" "A6 bracket honestly null (playoff=null, cycle-56)" "
ok=(d.get('ok') is True and d.get('bracket') is None)"
api "$BASE/api/team-squad/2182" "A7 hook-club squad carries BOTH Iranians" "
sq=(d.get('squad') or {}); gs=sq.get('groups') or []
blob=json.dumps(gs,ensure_ascii=False)
ok=(d.get('ok') and len(gs)>=3 and '746018' in blob and '887680' in blob)"
api "$BASE/api/player/887680" "A8 player 887680 Persian name" "
p=d.get('player') or {}
ok=(d.get('ok') and p.get('nameFa')=='اللهیار صیادمنش')"
api "$BASE/api/player/746018" "A8b player 746018 Persian name" "
p=d.get('player') or {}
ok=(d.get('ok') and p.get('nameFa')=='علی غلی‌زاده')"
api "$BASE/api/search?q=Lech" "A9 search Lech→لخ پوزنان (fa, live attribution)" "
rs=d.get('results') or d.get('teams') or []
hit=[r for r in rs if (r.get('fa') or '')=='لخ پوزنان']
ok=bool(hit)"
api "$BASE/api/matches?offset=1" "A11 day-feed (offset scan) اکستراکلاسا لهستان Persian" "
def scan():
    for off in range(0,4):
        req=urllib.request.Request(f'$BASE/api/matches?offset={off}',headers={'User-Agent':'Mozilla/5.0'})
        with urllib.request.urlopen(req,timeout=30) as r:
            raw=r.read()
        if raw[:2]==b'\x1f\x8b':
            import gzip; raw=gzip.decompress(raw)
        dd=json.loads(raw.decode('utf-8','replace'))
        for g in dd.get('groups') or []:
            if (g.get('leagueFa') or '')=='اکستراکلاسا لهستان':
                return True
    return False
ok=scan()"
python3 scripts/cycle162-mapcheck.py >/dev/null 2>&1 && echo "A10 mapcheck 1077/533 zero-dups → OK" || { echo "A10 mapcheck → BAD"; BAD=$((BAD+1)); }

echo "== PART B: DOM proof @390x844 =="
open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
}

# B1: /league/poland — h1 + live top + honest tab set (bracket absent, titles present)
open_page "$BASE/league/poland"
FEAT=$($B eval "JSON.stringify(({h1:((document.querySelector('h1')||{}).innerText||'').includes('اکستراکلاسا لهستان'),top:((document.querySelector('table tbody tr')||{}).innerText||'').includes('لخ پوزنان'),scorersTab:[...document.querySelectorAll('button')].some(function(b){return (b.textContent||'').trim()==='آقای گل'}),titlesTab:[...document.querySelectorAll('button')].some(function(b){return (b.textContent||'').trim()==='قهرمانان'}),transfersTab:[...document.querySelectorAll('button')].some(function(b){return (b.textContent||'').trim()==='انتقال‌ها'}),bracketAbsent:![...document.querySelectorAll('button')].some(function(b){return (b.textContent||'').trim()==='براکت'}),seasonSel:!!document.querySelector('select')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B1 league/poland tabs honest"

# B2: read top FIRST (the 148 lesson) then REAL «آقای گل» click → صیادمنش
TOP1=$($B eval "JSON.stringify((document.querySelector('table tbody tr')||{}).innerText||'')" 2>/dev/null | tr -d '"\\')
$B eval "(function(){const t=[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').trim()==='آقای گل'});if(t)t.click();return t?'clicked':'no-tab'})()" >/dev/null 2>&1
sleep 3
FEAT=$($B eval "JSON.stringify(({sayyad:(document.body.innerText||'').includes('اللهیار صیادمنش'),sanchez:(document.body.innerText||'').includes('خوردی سانچز'),lech:(document.body.innerText||'').includes('لخ پوزنان')}))" 2>/dev/null | tr -d '"\\')
collect "topWas:$TOP1 post:$FEAT" "B2 real scorers click → صیادمنش"

# B3: real «انتقال‌ها» click → panel alive, zero-ASCII sides visible
open_page "$BASE/league/poland"
$B eval "(function(){const t=[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').trim()==='انتقال‌ها'});if(t)t.click();return t?'clicked':'no-tab'})()" >/dev/null 2>&1
sleep 3
FEAT=$($B eval "JSON.stringify(({panel:(document.body.innerText||'').includes('ورود')||(document.body.innerText||'').includes('خروج')||(document.body.innerText||'').includes('انتقال'),fa:(document.body.innerText||'').includes('اکستراکلاسا لهستان')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B3 real transfers click"

# B4: race — copy ۱۹ + poland chip + real chip click reveals the dedicated link
open_page "$BASE/topscorers"
FEAT1=$($B eval "JSON.stringify(({copy20:(document.body.innerText||'').includes('۲۰ لیگ و جام برتر'),old19gone:!(document.body.innerText||'').includes('۱۹ لیگ و جام برتر'),chipPoland:[...document.querySelectorAll('button')].some(function(b){return (b.textContent||'').indexOf('اکستراکلاسا')>-1})}))" 2>/dev/null | tr -d '"\\')
$B eval "(function(){const t=[...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').indexOf('اکستراکلاسا')>-1});if(t)t.click();return t?'clicked':'no-chip'})()" >/dev/null 2>&1
sleep 3
FEAT2=$($B eval "JSON.stringify(({direct:!!document.querySelector(\"a[href='/topscorers/poland']\"),linkFa:(document.body.innerText||'').indexOf('صفحه اختصاصی گلزنان')>-1}))" 2>/dev/null | tr -d '"\\')
collect "pre:$FEAT1 post:$FEAT2" "B4 race copy + chip click"
# B4 cleanup (test hygiene, cycle-181): the chip click persists the league
# filter in localStorage (cycle-10 by-design) — clear it so later gates
# reading the DEFAULT race view are order-independent
$B eval "try{localStorage.removeItem('remontada:topscorers-filter')}catch(e){}" >/dev/null 2>&1

# B5: dedicated /topscorers/poland — سانچز + صیادمنش Persian
open_page "$BASE/topscorers/poland"
FEAT=$($B eval "JSON.stringify(({h1:((document.querySelector('h1')||{}).innerText||'').includes('اکستراکلاسا لهستان'),sanchez:(document.body.innerText||'').includes('خوردی سانچز'),sayyad:(document.body.innerText||'').includes('اللهیار صیادمنش'),lech:(document.body.innerText||'').includes('لخ پوزنان')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B5 /topscorers/poland"

# B6: hub — 23 cards + poland card
open_page "$BASE/leagues"
FEAT=$($B eval "JSON.stringify(({cards:document.querySelectorAll(\"a[href^='/league/']\").length>=23,polandCard:!!document.querySelector(\"a[href='/league/poland']\"),h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B6 hub 23 cards"

# B7: hook club /team/2182 — لخ پوزنان with the Iranian squad grid
open_page "$BASE/team/2182"
FEAT=$($B eval "JSON.stringify(({h1:((document.querySelector('h1')||{}).innerText||'').includes('لخ پوزنان'),squad:(document.body.innerText||'').includes('اللهیار صیادمنش')||(document.body.innerText||'').includes('علی غلی‌زاده'),next:(document.body.innerText||'').includes('اکستراکلاسا لهستان')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B7 /team/2182 hook club"

# B8: search guide ۲۳ via the real search UI
open_page "$BASE/"
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 2
FEAT=$($B eval "JSON.stringify(({guide24:(document.body.innerText||'').includes('۲۴ لیگ و جام'),old23gone:!(document.body.innerText||'').includes('۲۳ لیگ و جام')}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B8 search guide 23"

echo "== RESULT =="
echo "API 11/11 + DOM 8/8 expected; BAD=$BAD"
[ "$BAD" -eq 0 ] && echo "DOM_PROOF OK (cycle-165: اکستراکلاسا لهستان — the 23rd competition, 19th race participant, صیادمنش+غلی‌زاده both live at لخ پوزنان)" || { echo "DOM_PROOF FLAGGED"; exit 1; }
