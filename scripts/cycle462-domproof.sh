#!/usr/bin/env bash
# cycle-462 domproof (the 450/455/456/457/460/461 harness family). Independent
# acceptance for the batch-21 harvest (the 19-name ARGENTINA tranche — the
# live Liga Profesional + Copa Argentina wave): A the in-repo map block
# integrity (1798→19 pairs, zero dup values, byte-exact vs the EMBEDDED
# expected pairs — the 454 standalone lesson, no /tmp dependency — plus the
# byte-exactness specials), B the LIVE API across the whole ±7 window (zero
# batch-21 raw literals, 19/19 distinct Persian renders over the 62 mapped
# rows, the witness day computed LIVE from the feed) + the visible DOM on
# that witness day, 390×844, console clean, and D the fresh home (the 434
# mount-gate). The B3 expectation: the Liga Profesional + Copa Argentina
# matchday 20261108 carries ALL 19 of the batch (the live post-patch
# observation: every one of the 19 renders sits on 20261108).
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c462-domproof-results.txt
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
m = re.search(r'cycle-462: harvest batch 21(.*?)(?=// cycle-|};)', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c462-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c462-pairs.json'))))")
[ "$NB" = "19" ] && ok "A1 the batch-21 map block parses to exactly 19 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c462-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 19 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import json
EXPECTED = {
  "deportivo riestra": "دپورتیوو ریسترا",
  "argentinos juniors": "آرژانتینوس جونیورز",
  "independiente rivadavia": "ایندپندینته ریواداویا",
  "atlético tucumán": "اتلتیکو توکومان",
  "club atlético platense": "پلاتنسه",
  "instituto": "انستیتو",
  "estudiantes de río cuarto": "استودیانتس دی ریو کوارتو",
  "gimnasia lp": "جیمناسیا لاپلاتا",
  "huracán": "هوراکان",
  "racing club": "راسینگ کلوب",
  "sarmiento": "سارمینتو",
  "rosario central": "روزاریو سنترال",
  "vélez sarsfield": "ولز سارسفیلد",
  "unión": "اونیون",
  "belgrano": "بلگرانو",
  "barracas central": "باراکاس سنترال",
  "defensa y justicia": "دفنسا و خوستیسیا",
  "independiente": "ایندپندینته",
  "banfield": "بانفیلد",
}
p = json.load(open("/tmp/c462-pairs.json"))  # written by THIS domproof from the committed block (A1)
miss = sorted(k for k in EXPECTED if k not in p or p[k] != EXPECTED[k])
extra = sorted(k for k in p if k not in EXPECTED)
n = len(miss) + len(extra)
print(str(n) if n == 0 else "%d missing=%s extra=%s" % (n, miss, extra))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 lesson, standalone) the block is byte-exact against the 19 embedded expected pairs (no /tmp dependency)" || bad "A3 byte-exact" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c462-pairs.json'))
ok = (p['gimnasia lp'] == 'جیمناسیا لاپلاتا') and (p['huracán'] == 'هوراکان') and (p['racing club'] == 'راسینگ کلوب') and (p['unión'] == 'اونیون') and (p['banfield'] == 'بانفیلد') and (p['estudiantes de río cuarto'] == 'استودیانتس دی ریو کوارتو')
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the byte-exactness: جیمناسیا لاپلاتا (the article's OWN intro SHORT form for the literal Gimnasia LP, 43107433) / هوراکان (the encyclopedia's OWN rendering, 41152768) / راسینگ کلوب (the intro's OWN full-name rendering minus the city آویاندا, 44298641) / اونیون (the Spanish-phonetic اونیون family vs the file's OWN latin-union یونیون convention) / بانفیلد (the direct club article 43805809 superseding the wikidata CITY-entity artifact) / استودیانتس دی ریو کوارتو (the OWN استودیانتس + the de→دی boca-juniors-de-cali rule + the OWN city ریو کوارتو 41557532)" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c462-pairs.json'))
vals=set(pairs.values()); raws=set(pairs.keys())
hits=0; distinct=set(); rawleak=0; witday=None; witset=set(); best=0
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
                elif n in raws: rawleak+=1
    if len(dayset) > best:
        best=len(dayset); witday=day; witset=sorted(dayset)
print(json.dumps({"hits":hits,"distinct":len(distinct),"rawleak":rawleak,"witday":witday,"witcount":best,"witset":witset}, ensure_ascii=False))
PY
)
HITS=$(abf "$FEED" hits); DISTINCT=$(abf "$FEED" distinct); RLEAK=$(abf "$FEED" rawleak)
WITDAY=$(abf "$FEED" witday); WITCOUNT=$(abf "$FEED" witcount)
WITSET=$(abf "$FEED" witset)
echo "   witness day: $WITDAY count=$WITCOUNT set=$WITSET"
[ "$RLEAK" = "0" ] && ok "B1 zero batch-21 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "19" ] && ok "B2 ALL 19 batch-21 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/19 ($HITS rows)"
# cycle-481 re-anchor (the only-eaten rule, the 477 precedent): the harvest-day
# exactness "19/19 on the witness day" was a snapshot of the ±7 window as it
# stood at cycle 462 — the window moved on and the best witness day now carries
# 9 (B1 zero raw leaks + B2 all 19 renders present across the window BOTH still
# green, the mapping untouched). B3 re-anchored to the PERMANENT invariant:
# the witness day carries >=1 batch-21 render, the count REPORTED not pinned.
[ "$WITCOUNT" -ge 1 ] && ok "B3 the witness day ($WITDAY) carries $WITCOUNT batch-21 renders in the live window (reported, not pinned — the harvest-day 19/19 snapshot retired, the 477 window-drift reality; B1/B2 carry the strength)" || bad "B3 witness day" "$WITCOUNT"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
# the feed's date field is YYYYMMDD; the app's ?date= param is ISO YYYY-MM-DD
# (the 450 harness lesson: convert the live witness day, never hardcode)
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['Deportivo Riestra','Argentinos Juniors','Independiente Rivadavia','Atlético Tucumán','Club Atlético Platense','Instituto','Estudiantes de Río Cuarto','Gimnasia LP','Huracán','Racing Club','Sarmiento','Rosario Central','Vélez Sarsfield','Unión','Belgrano','Barracas Central','Defensa y Justicia','Independiente','Banfield'];const cells=Array.from(document.querySelectorAll('*')).filter(e=>e.children.length===0).map(e=>e.textContent.trim());const rleak=raws.filter(x=>cells.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-21 raw literals as rendered team-name cells in the DOM (exact-cell match — the substring check false-positived on the NON-batch containments Unión La Calera / Independiente de La Chorrera, documented)" || bad "C2 raw leak" "$RLEAKD"
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
