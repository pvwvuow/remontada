#!/usr/bin/env bash
# cycle-480 domproof (the 452..477 harness family) — the batch-30 PAR
# tranche: A the in-repo block integrity (7 pairs, zero dup values,
# byte-exact vs the EMBEDDED expected pairs — the 454 standalone lesson —
# plus the byte specials: the ñ/í keys, the two direct-anchor FC-rule
# renders, the city-grounded toponym, the ۲ digit), B the LIVE API across
# the whole ±7 window (zero raw literals, 7/7 distinct Persian renders
# over the 21 mapped rows, the witness SPREAD computed live) + the
# visible DOM on the best witness day 390×844, console clean, D the fresh
# home (the 434 mount-gate).
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c480-domproof-results.txt
: > "$OUT"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1" >> "$OUT"; echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 :: $2" >> "$OUT"; echo "FAIL $1 :: $2"; }
AB="agent-browser"

abf() {
  python3 - "$1" "$2" <<'PYEOF'
import json, sys
s = sys.argv[1].strip()
if s.startswith('"') and s.endswith('"'):
    s = s[1:-1]
s = s.replace('\\"', '"')
print(json.loads(s)[sys.argv[2]])
PYEOF
}

echo "== A. the map block integrity =="
python3 - <<'PY'
import re, json
s = open('src/lib/leagues.ts', encoding='utf-8').read()
m = re.search(r'cycle-480: batch 30(.*?)(?=// cycle-|};)', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c480-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c480-pairs.json'))))")
[ "$NB" = "7" ] && ok "A1 the batch-30 map block parses to exactly 7 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c480-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 7 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import json
EXPECTED = {
  "2 de mayo": "۲ د مایو",
  "cerro porteño": "سرو پورتنیو",
  "guaraní": "گوارانی",
  "rubio ñú": "روبیو نیو",
  "sportivo ameliano": "اسپورتیوو آملیانو",
  "sportivo san lorenzo": "اسپورتیوو سن لورنزو",
  "sportivo trinidense": "اسپورتیوو ترینیدنس",
}
p = json.load(open("/tmp/c480-pairs.json"))  # written by THIS domproof from the committed block (A1)
miss = sorted(k for k in EXPECTED if k not in p or p[k] != EXPECTED[k])
extra = sorted(k for k in p if k not in EXPECTED)
n = len(miss) + len(extra)
print(str(n) if n == 0 else "%d missing=%s extra=%s" % (n, miss, extra))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 lesson, standalone) the block is byte-exact against the 7 embedded expected pairs (no /tmp dependency)" || bad "A3 byte-exact" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c480-pairs.json'))
ok = (p['cerro porteño'] == 'سرو پورتنیو') and (p['guaraní'] == 'گوارانی') and (p['sportivo san lorenzo'] == 'اسپورتیوو سن لورنزو') and (p['2 de mayo'] == '۲ د مایو') and (p['rubio ñú'] == 'روبیو نیو') and (p['sportivo ameliano'] == 'اسپورتیوو آملیانو') and (p['sportivo trinidense'] == 'اسپورتیوو ترینیدنس') and ('ñ' in list(p)[3]) and ('í' in list(p)[2]) and ('۲' in p['2 de mayo'])
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the byte-exactness: the TWO direct-anchor FC-rule renders (سرو پورتنیو — the 477-documented pageid 41367502 RENAMED upstream to the باشگاه-prefixed title, the anchor's OWN title wins, the 475 lesson / گوارانی — 6305735, minus the prefix AND the (پاراگوئه) disambiguator) / the city-grounded toponym (اسپورتیوو سن لورنزو — سن لورنزو (پاراگوئه) 1071973, the 461 rule) / the zero-anchor honest reads (۲ د مایو Q1926287 / روبیو نیو Q603085 / اسپورتیوو آملیانو Q15294976 / اسپورتیوو ترینیدنس Q2980011 — pure phonetic, the 466 UPNFM rule) / the byte specials: the ñ key (rubio ñú, U+00F1), the í key (cerro porteño/guaraní, U+00ED), the ۲ digit (2 de mayo)" || bad "A4 byte-exact" "$SPECIAL"
echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c480-pairs.json'))
vals=set(pairs.values()); raws=set(pairs.keys())
hits=0; distinct=set(); rawleak=0; witday=None; witset=set(); best=0; pername={}
for o in range(-7,8):
    out=subprocess.run(["curl","-s","--max-time","40","-A",UA,f"{BASE}/api/matches?offset={o}"],capture_output=True,text=True,timeout=60).stdout
    d=json.loads(out)
    day=d.get("date") or str(o)
    dayset=set()
    for g in d.get("groups",[]):
        for m in g.get("matches",[]):
            for side in ("home","away"):
                t=m.get(side) or {}
                n=t.get("fa") or t.get("name") or ""
                if n in vals:
                    hits+=1; distinct.add(n); dayset.add(n)
                    pername[n]=pername.get(n,0)+1
                elif n in raws: rawleak+=1
    if len(dayset) > best:
        best=len(dayset); witday=day; witset=sorted(dayset)
print(json.dumps({"hits":hits,"distinct":len(distinct),"rawleak":rawleak,"witday":witday,"witcount":best,"witset":witset,"pername":pername,"minname":min(pername.values()) if pername else 0}, ensure_ascii=False))
PY
)
HITS=$(abf "$FEED" hits); DISTINCT=$(abf "$FEED" distinct); RLEAK=$(abf "$FEED" rawleak)
WITDAY=$(abf "$FEED" witday); WITCOUNT=$(abf "$FEED" witcount)
WITSET=$(abf "$FEED" witset); MINNAME=$(abf "$FEED" minname)
echo "   witness day: $WITDAY count=$WITCOUNT set=$WITSET"
echo "   witness spread: hits=$HITS min-per-club=$MINNAME"
[ "$RLEAK" = "0" ] && ok "B1 zero batch-30 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "7" ] && ok "B2 ALL 7 batch-30 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/7 ($HITS rows)"
[ "$HITS" = "21" ] && [ "$MINNAME" = "3" ] && ok "B3 the live witness spread: 21 mapped rows, every club 3/3 fixtures inside the window (computed live from the feed)" || bad "B3 witness spread" "hits=$HITS min=$MINNAME"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['2 de Mayo','Cerro Porteño','Guaraní','Rubio Ñú','Sportivo Ameliano','Sportivo San Lorenzo','Sportivo Trinidense'];const cells=Array.from(document.querySelectorAll('*')).filter(e=>e.children.length===0).map(e=>e.textContent.trim());const rleak=raws.filter(x=>cells.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-30 raw literals as rendered team-name cells in the DOM (exact-cell match — the 462 lesson)" || bad "C2 raw leak" "$RLEAKD"
[ "$SW" = "390" ] && [ "$VW" = "390" ] && ok "C3 scrollW=390 innerW=390 (no horizontal overflow)" || bad "C3 scroll" "sw=$SW vw=$VW"
[ "$H1" = "True" ] && ok "C4 h1 present" || bad "C4 h1" "$H1"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE" = "0" ] && ok "C5 console errors 0" || bad "C5 console" "$CE"
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "C6 page errors 0" || bad "C6 page errors" "$PE"

echo "== D. default home fresh load (the 434 mount-gate still clean) =="
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >> "$OUT" 2>&1
sleep 2
CE2=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE2" = "0" ] && ok "D1 console errors 0 on fresh home" || bad "D1 console" "$CE2"
PE2=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE2" = "0" ] && ok "D2 page errors 0 on fresh home" || bad "D2 page errors" "$PE2"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
