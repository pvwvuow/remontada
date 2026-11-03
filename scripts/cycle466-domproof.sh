#!/usr/bin/env bash
# cycle-466 domproof (the 450/455/456/457/460/461/462/465 harness family).
# Independent acceptance for the batch-23 harvest (the 9-name HONDURAS
# tranche — the live Liga Nacional Apertura wave, the UNBROKEN half of the
# PAN/HON 9/27 tie after the 465 tie-break; the FIRST ZERO-ANCHOR batch —
# the live c466 probe found no direct fa.wiki club article under any
# spelling, all 9 honest phonetic reads): A the in-repo map block integrity
# (9 pairs, zero dup values, byte-exact vs the EMBEDDED expected pairs —
# the 454 standalone lesson, no /tmp dependency — plus the byte-exactness
# specials), B the LIVE API across the whole ±7 window (zero batch-23 raw
# literals, 9/9 distinct Persian renders over the 27 mapped rows, the
# witness SPREAD computed LIVE from the feed — this window is the compressed
# Liga Nacional Apertura schedule: NO single day carries all 9 (the 465
# single-witness-day shape does not apply; each club plays 3 fixtures inside
# the window) so B3 asserts the full spread: 27 rows, every club 3/3) + the
# visible DOM on the best witness day, 390×844, console clean, and D the
# fresh home (the 434 mount-gate).
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c466-domproof-results.txt
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
m = re.search(r'cycle-466: batch 23(.*?)(?=// cycle-|};)', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c466-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c466-pairs.json'))))")
[ "$NB" = "9" ] && ok "A1 the batch-23 map block parses to exactly 9 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c466-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 9 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import json
EXPECTED = {
  "estrella roja": "استریا روخا",
  "atletico independiente": "اتلتیکو ایندپندینته",
  "lobos upnfm": "لوبوس یو‌پی‌ان‌اف‌ام",
  "genesis fc": "جنسیس",
  "real españa": "رئال اسپانیا",
  "juticalpa": "خوتیکالپا",
  "cd choloma": "چولوما",
  "olancho fc": "اولانچو",
  "platense fc": "دپورتیوو پلاتنسه",
}
p = json.load(open("/tmp/c466-pairs.json"))  # written by THIS domproof from the committed block (A1)
miss = sorted(k for k in EXPECTED if k not in p or p[k] != EXPECTED[k])
extra = sorted(k for k in p if k not in EXPECTED)
n = len(miss) + len(extra)
print(str(n) if n == 0 else "%d missing=%s extra=%s" % (n, miss, extra))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 lesson, standalone) the block is byte-exact against the 9 embedded expected pairs (no /tmp dependency)" || bad "A3 byte-exact" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c466-pairs.json'))
ok = (p['estrella roja'] == 'استریا روخا') and (p['real españa'] == 'رئال اسپانیا') and (p['juticalpa'] == 'خوتیکالپا') and (p['olancho fc'] == 'اولانچو') and (p['platense fc'] == 'دپورتیوو پلاتنسه') and (p['atletico independiente'] == 'اتلتیکو ایندپندینته') and (p['lobos upnfm'] == 'لوبوس یو\u200cپی\u200cان\u200cاف\u200cام') and (p['genesis fc'] == 'جنسیس') and (p['cd choloma'] == 'چولوما')
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the byte-exactness: استریا روخا (estrella→استریا per the villa→ویا ll-rule + roja→روخا) / رئال اسپانیا (the OWN رئال form; the CURRENCY page under this title NOT used) / خوتیکالپا (the city-grounded spelling, the 461 مریدا pattern) / اولانچو (rides the city page's OWN intro «استان اولانچو») / دپورتیوو پلاتنسه (the club's OWN full-name prefix, deliberately DISTINCT from 462's Argentine پلاتنسه) / اتلتیکو ایندپندینته (the OWN forms, DISTINCT from 462's bare ایندپندینته; the REDIRECT-to-Argentine page NOT used) / لوبوس یو‌پی‌ان‌اف‌ام + جنسیس + چولوما (the honest reads)" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c466-pairs.json'))
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
[ "$RLEAK" = "0" ] && ok "B1 zero batch-23 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "9" ] && ok "B2 ALL 9 batch-23 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/9 ($HITS rows)"
[ "$HITS" = "27" ] && [ "$MINNAME" = "3" ] && ok "B3 the live witness spread: 27 mapped rows, every club 3/3 fixtures inside the window (the compressed Apertura schedule — computed live from the feed)" || bad "B3 witness spread" "hits=$HITS min=$MINNAME"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['Estrella Roja','Atletico Independiente','Lobos UPNFM','Genesis FC','Real España','Juticalpa','CD Choloma','Olancho FC','Platense FC'];const cells=Array.from(document.querySelectorAll('*')).filter(e=>e.children.length===0).map(e=>e.textContent.trim());const rleak=raws.filter(x=>cells.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-23 raw literals as rendered team-name cells in the DOM (exact-cell match — the 462 lesson)" || bad "C2 raw leak" "$RLEAKD"
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
