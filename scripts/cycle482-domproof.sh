#!/usr/bin/env bash
# cycle-482 domproof (the 452..480 harness family) — the batch-31 RUS
# tranche: A the in-repo block integrity (6 pairs, zero dup values,
# byte-exact vs the EMBEDDED expected pairs — the 454 standalone lesson —
# plus the byte specials: the ZWNJ inside ینی‌سئی, the anchor's-own-title
# زسکا, the honest phonetic لنینگرادتس, the city-grounded نیژنی نووگورود),
# B the LIVE API across the whole ±7 window (zero raw literals, 6/6
# distinct Persian renders over the 18 mapped rows, the witness SPREAD
# computed live in the PERMANENT form — the 477 re-anchor lesson applied
# from birth), C the visible DOM on the best witness day 390×844, console
# clean, D the fresh home (the 434 mount-gate).
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c482-domproof-results.txt
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
m = re.search(r'cycle-482: batch 31(.*?)(?=\n};)', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c482-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c482-pairs.json'))))")
[ "$NB" = "6" ] && ok "A1 the batch-31 map block parses to exactly 6 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c482-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 6 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import json
EXPECTED = {
  "fc yenisey krasnoyarsk": "ینی\u200cسئی کراسنویارسک",
  "leningradets": "لنینگرادتس",
  "nizhny novgorod": "نیژنی نووگورود",
  "ska-khabarovsk": "زسکا خاباروفسک",
  "spartak kostroma": "اسپارتاک کوستروما",
  "volga ulyanovsk": "ولگا اولیانوفسک",
}
p = json.load(open("/tmp/c482-pairs.json"))  # written by THIS domproof from the committed block (A1)
miss = sorted(k for k in EXPECTED if k not in p or p[k] != EXPECTED[k])
extra = sorted(k for k in p if k not in EXPECTED)
n = len(miss) + len(extra)
print(str(n) if n == 0 else "%d missing=%s extra=%s" % (n, miss, extra))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 lesson, standalone) the block is byte-exact against the 6 embedded expected pairs (no /tmp dependency)" || bad "A3 byte-exact" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c482-pairs.json'))
ks=list(p)
ok = (p['fc yenisey krasnoyarsk'] == 'ینی\u200cسئی کراسنویارسک') and ('\u200c' in p['fc yenisey krasnoyarsk']) and (p['ska-khabarovsk'] == 'زسکا خاباروفسک') and (p['nizhny novgorod'] == 'نیژنی نووگورود') and (p['spartak kostroma'] == 'اسپارتاک کوستروما') and (p['volga ulyanovsk'] == 'ولگا اولیانوفسک') and (p['leningradets'] == 'لنینگرادتس') and ('-' in ks[3])
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the byte-exactness: the FIVE direct-anchor FC-rule renders byte-derived from the anchor's OWN title (ینی‌سئی کراسنویارسک 4982538 with the U+200C ZWNJ byte-carried / زسکا خاباروفسک 4982452 — the anchor spells СКА «زسکا», the 475 own-title-wins lesson / نیژنی نووگورود 5972164 + Q20740338, also the 461 city-grounded toponym / اسپارتاک کوستروما 6980851 / ولگا اولیانوفسک 4983513 — surfaced by the fa SEARCH fallback, verified on the redirects=1 re-probe) + the ONE zero-anchor honest phonetic read (لنینگرادتس — Q54871945 proves the Russian football identity AND the fa-sitelink absence, the 466 UPNFM rule; the A-stage Q139743117 an ICE HOCKEY club, never consulted) + the byte specials: the ZWNJ (U+200C) inside ینی‌سئی, the hyphen key (ska-khabarovsk)" || bad "A4 byte-exact" "$SPECIAL"
echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c482-pairs.json'))
vals=set(pairs.values()); raws=set(pairs.keys())
hits=0; distinct=set(); rawleak=0; witday=None; witset=set(); best=0; pername={}
for o in range(-7,8):
    out=subprocess.run(["curl","-s","--max-time","40","-A",UA,f"{BASE}/api/matches?offset={o}"],capture_output=True,text=True,timeout=60).stdout
    try: d=json.loads(out)
    except Exception: continue
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
[ "$RLEAK" = "0" ] && ok "B1 zero batch-31 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "6" ] && ok "B2 ALL 6 batch-31 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/6 ($HITS rows)"
[ "$MINNAME" != "0" ] && [ "$HITS" -ge 6 ] && ok "B3 the PERMANENT spread (the 477 re-anchor form from birth): min-per-club=$MINNAME, hits=$HITS (reported, not pinned — the harvest-day snapshot class retired the hard way at c462 today)" || bad "B3 witness spread" "hits=$HITS min=$MINNAME"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['FC Yenisey Krasnoyarsk','Leningradets','Nizhny Novgorod','SKA-Khabarovsk','Spartak Kostroma','Volga Ulyanovsk'];const cells=Array.from(document.querySelectorAll('*')).filter(e=>e.children.length===0).map(e=>e.textContent.trim());const rleak=raws.filter(x=>cells.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-31 raw literals as rendered team-name cells in the DOM (exact-cell match — the 462 lesson)" || bad "C2 raw leak" "$RLEAKD"
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
