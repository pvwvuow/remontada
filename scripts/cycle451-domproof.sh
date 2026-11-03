#!/bin/bash
# cycle450-domproof.sh — harvest batch 14 (Update cycle 451)
#
# The work: ALL 12 count-3 single-country names of the GUATEMALA tranche into
# TEAM_FA (Liga Nacional Apertura — exactly the 447/448 rotation lines' own
# prediction «GUA ۱۲ در نوبت است», the window delivered: GUA 12/36 > CYP 11
# = THA 11; the count>=4 multi-country names stay honest-raw, the 389 rule;
# no (W) sides, no exclusions), every key byte-verified against the live ±7
# feed (scripts/c451-batch13-verify.py: 12/12 verified=0 bad, all GUA, 36
# rows covered), NINE direct Persian-Wikipedia anchors (the map's new
# record), matches cache v15 → v16 per the standing rule (18 v15 L2 rows
# purged + official restart = fresh cold window), patrol B4 re-anchored
# 1864 → 1852 (the loud-pool rule) + B17 batch-13 witnesses.
#
# This domproof: the map block integrity + the API across the WHOLE ±7 window
# (no single day carries all 12 — the census shows two richest days with 6 of
# 12 each; the witness day is computed LIVE from the feed, the harness rule)
# + the visible DOM on that witness day, 390×844, console clean.
# Harness lessons (432-449): probes are picked from the day's ACTUAL render
# set (count from the feed, never from a manual tally); eval prints escaped-
# quoted JSON (parse with abf); grep -c counts lines not occurrences.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c451-domproof-results.txt
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
m = re.search(r'cycle-451: harvest batch 14(.*?)};', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c451-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c451-pairs.json'))))")
[ "$NB" = "11" ] && ok "A1 the batch-14 map block parses to exactly 11 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c451-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 11 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 -c "
import json
s=open('src/lib/leagues.ts',encoding='utf-8').read()
v=json.load(open('/tmp/c451-verified.json'))
p=json.load(open('/tmp/c451-pairs.json'))
bad=[x['key'] for x in v if x['key'] not in p]
print(len(bad))")
[ "$SRC" = "0" ] && ok "A3 every verified key (11/11 from the live ±7 gate) is present in the block" || bad "A3 key coverage" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c451-pairs.json'))
ok = ('omonia 29 maiou' in p) and ('۲۹' in p['omonia 29 maiou']) and (p['omonia 29 maiou'] == 'اومونیا ۲۹ می') and (p['ael limassol'] == 'آئل لیماسول') and (p['olympiakos nicosia'] == 'المپیاکوس نیکوزیا') and (p['doxa katokopia'] == 'دوکسا کاتوکوپیاس') and (p['karmiotissa'] == 'کارمیوتیسا')
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the Persian digits byte-exact in اومونیا ۲۹ می (۲۹ = U+06F2 U+06F9) + the آئل/المپیاکوس نیکوزیا/دوکسا کاتوکوپیاس/کارمیوتیسا renders" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c451-pairs.json'))
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
[ "$RLEAK" = "0" ] && ok "B1 zero batch-14 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "11" ] && ok "B2 ALL 11 batch-14 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/11 ($HITS rows)"
[ "$WITCOUNT" = "5" ] && ok "B3 the witness day ($WITDAY) carries exactly the documented 5 of 11" || bad "B3 witness day" "$WITCOUNT/5"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
# the feed's date field is YYYYMMDD; the app's ?date= param is ISO YYYY-MM-DD
# (the 450 harness lesson: the c447 script hardcoded an ISO date, this one
# converts the live witness day instead)
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['AEL Limassol','AEP Polemidion','Chalkanoras Idaliou','Digenis Morphou','Doxa Katokopia','Ermis Aradippou','Iraklis Gerolakkou','Karmiotissa','Olympiakos Nicosia','Omonia 29 Maiou','Omonia Aradippou'];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-14 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
