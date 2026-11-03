#!/bin/bash
# cycle446-domproof.sh — harvest batch 11 (Update cycle 446)
#
# The work: ALL 13 single-country names with count>=3 of the COLOMBIA tranche
# into TEAM_FA (11 count-3 + Envigado/Unión Magdalena at count-4 — Primera A +
# Primera B; the 445 rotation line predicted the KSA/AUT/ISR segment to lead
# but the window re-ranked again: RUS/GUA tied 12 while COL's count≥3 singles
# reached 13 names / 41 live leak rows — the 435 lesson: the window decides;
# the count>=4 multi-country names stay honest-raw, the 389 identity-first
# rule; no (W) sides, no exclusions), every key byte-verified against the
# live ±7 feed (scripts/c446-batch11-verify.py: 13/13 verified=0 bad, all
# COL, 41 rows covered), the post-fix direct re-check decisive (41 Persian
# renders = the exact 13×rows, ZERO batch raw literals, pool distinct
# 1890 → 1877 EXACTLY −13 with zero long-tail drift), matches cache v12 → v13
# per the standing rule (18 v12 L2 rows purged + official restart = fresh
# cold window), patrol B4 re-anchored 1890 → 1877 (the loud-pool rule) +
# B14 batch-11 witnesses.
#
# This domproof: the map block integrity + the API across the WHOLE ±7 window
# (no single day carries all 13 — the richest witness day is offset −5 =
# 2026-10-29 with 10 of 13) + the visible DOM on that witness day, 390×844,
# console clean.
# Harness lessons (432-445): probes are picked from the day's ACTUAL render
# set (count from the feed, never from a manual tally); eval prints escaped-
# quoted JSON (parse with abf); grep -c counts lines not occurrences.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c446-domproof-results.txt
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
m = re.search(r'cycle-446: harvest batch 11(.*?)};', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c446-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c446-pairs.json'))))")
[ "$NB" = "13" ] && ok "A1 the batch-11 map block parses to exactly 13 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c446-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 13 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 -c "
import json
s=open('src/lib/leagues.ts',encoding='utf-8').read()
v=json.load(open('/tmp/c446-verified.json'))
p=json.load(open('/tmp/c446-pairs.json'))
bad=[x['key'] for x in v if x['key'] not in p]
print(len(bad))")
[ "$SRC" = "0" ] && ok "A3 every verified key (13/13 from the live ±7 gate) is present in the block" || bad "A3 key coverage" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c446-pairs.json'))
ok = ('unión magdalena' in p) and ('américa de cali' in p) and ('chicó fc' in p) and ('deportes quindío' in p) and ('águilas doradas' in p)
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the ó/á/í keys byte-exact (ó=U+00F3, á=U+00E1, í=U+00ED — the lowercased live-feed literals)" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c446-pairs.json'))
vals=set(pairs.values()); raws=set(pairs.keys())
hits=0; distinct=set(); rawleak=0; wit=set()
for o in range(-7,8):
    out=subprocess.run(["curl","-s","--max-time","40","-A",UA,f"{BASE}/api/matches?offset={o}"],capture_output=True,text=True,timeout=60).stdout
    d=json.loads(out)
    for g in d.get("groups",[]):
        for m in g.get("matches",[]):
            for side in ("home","away"):
                t=m.get(side) or {}
                n=t.get("fa") or t.get("name") or ""
                if n in vals:
                    hits+=1; distinct.add(n)
                    if o == -5: wit.add(n)
                elif n in raws: rawleak+=1
print(json.dumps({"hits":hits,"distinct":len(distinct),"rawleak":rawleak,"wit":len(wit)}, ensure_ascii=False))
PY
)
HITS=$(abf "$FEED" hits); DISTINCT=$(abf "$FEED" distinct); RLEAK=$(abf "$FEED" rawleak); WIT=$(abf "$FEED" wit)
[ "$RLEAK" = "0" ] && ok "B1 zero batch-11 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "13" ] && ok "B2 ALL 13 batch-11 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/13 ($HITS rows)"
[ "$WIT" = "10" ] && ok "B3 the witness day (offset −5) carries exactly the documented 10 of 13" || bad "B3 witness day" "$WIT/10"

echo "== C. the visible DOM (agent-browser 390×844, /?date=2026-10-29) =="
WITNESS=$(python3 - <<'PY'
import json, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c446-pairs.json'))
vals=set(pairs.values())
wit=set()
out=subprocess.run(["curl","-s","--max-time","40","-A",UA,f"{BASE}/api/matches?offset=-5"],capture_output=True,text=True,timeout=60).stdout
d=json.loads(out)
for g in d.get("groups",[]):
    for m in g.get("matches",[]):
        for side in ("home","away"):
            t=m.get(side) or {}
            n=t.get("fa") or t.get("name") or ""
            if n in vals: wit.add(n)
print(json.dumps(sorted(wit), ensure_ascii=False))
PY
)
echo "   witness set: $WITNESS"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=2026-10-29" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITNESS;const vis=w.filter(x=>b.includes(x));const raws=['Envigado','Unión Magdalena','América de Cali','Boca Juniors de Cali','Chicó FC','Deportes Quindío','Deportivo Pereira','Fortaleza FC','Independiente Valle del Cauca','Real Cartagena','Real Cundinamarca','Tigres FC','Águilas Doradas'];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-11 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
