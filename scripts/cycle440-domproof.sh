#!/bin/bash
# cycle440-domproof.sh — harvest batch 7 (Update cycle 440)
#
# The work: ALL 30 count-3 single-country team names of the SCOTLAND tranche
# into TEAM_FA (Challenge Cup 13 + FA Cup 1 + Lowland League East/West 16 —
# the live ±7 window's biggest single-country pool; no (W) sides, no
# exclusions), every key byte-verified against the live ±7 feed
# (scripts/cycle440-batch7-verify.py: 30/30 verified=0 bad, all SCO), the
# census arithmetic EXACT (1973 − 30 = 1943, zero distinct drift), the direct
# re-check decisive (0 batch raw literals leaking; 90 Persian renders = the
# exact 30×3; witness day 2026-10-31 renders all 30 names), matches cache
# v8 → v9 per the 426/430/431/432/435/436/437 rule (18 v8 L2 rows purged +
# official restart = fresh cold window), patrol B4 re-anchored 1973 → 1943
# with the history line (loud-pool rule) + B10 batch-7 witnesses.
#
# This domproof: the map block integrity + the API + the visible DOM on the
# richest witness day (offset -3 = 2026-10-31, the full Scottish cup/lowland
# matchday — all 30 batch-7 names render there), 390×844, console clean.
# Harness lessons (432-437): probes are picked from the day's ACTUAL render
# set (a fixed probe list is day-blind); eval prints escaped-quoted JSON
# (parse with abf); grep -c counts lines not occurrences.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c440-domproof-results.txt
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
m = re.search(r'cycle-440: harvest batch 7(.*?)};', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c440-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c440-pairs.json'))))")
[ "$NB" = "30" ] && ok "A1 the batch-7 map block parses to exactly 30 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c440-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero value-dups (each of the 30 clubs one distinct render — no Logroñés case this batch)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 -c "
import json
s=open('src/lib/leagues.ts',encoding='utf-8').read()
v=json.load(open('/tmp/c440-verified.json'))
p=json.load(open('/tmp/c440-pairs.json'))
bad=[x['key'] for x in v if x['key'] not in p]
print(len(bad))")
[ "$SRC" = "0" ] && ok "A3 every verified key (30/30 from the live ±7 gate) is present in the block" || bad "A3 key coverage" "$SRC"

echo "== B. the API feed on the witness day (offset -3 = 2026-10-31) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
out=subprocess.run(["curl","-s","--max-time","40","-A",UA,f"{BASE}/api/matches?offset=-3"],capture_output=True,text=True,timeout=60).stdout
d=json.loads(out)
pairs=json.load(open('/tmp/c440-pairs.json'))
vals=set(pairs.values()); raws=set(pairs.keys())
hits=[]; rawleak=0
for g in d.get("groups",[]):
    for m in g.get("matches",[]):
        for side in ("home","away"):
            t=m.get(side) or {}
            n=t.get("fa") or t.get("name") or ""
            if n in vals: hits.append(n)
            elif n in raws: rawleak+=1
print(json.dumps({"hits":len(hits),"distinct":len(set(hits)),"rawleak":rawleak,"date":d.get("date")}, ensure_ascii=False))
PY
)
HITS=$(abf "$FEED" hits); DISTINCT=$(abf "$FEED" distinct); RLEAK=$(abf "$FEED" rawleak); FDATE=$(abf "$FEED" date)
[ "$FDATE" = "20261031" ] && ok "B1 witness day feed date = 20261031 (offset -3)" || bad "B1 feed date" "$FDATE"
[ "$RLEAK" = "0" ] && ok "B2 zero batch-7 raw literals in the witness-day feed" || bad "B2 raw leak" "$RLEAK"
[ "$DISTINCT" = "30" ] && ok "B3 all 30 distinct batch-7 Persian renders present on the witness day ($HITS rows — Formartine United legitimately plays twice: Highland League 1000012608 + FA Cup 6385239)" || bad "B3 distinct" "$DISTINCT/30 ($HITS rows)"

echo "== C. the visible DOM (agent-browser 390×844, /?date=2026-10-31) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=2026-10-31" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval '(()=>{const b=document.body.innerText;const w=["ایردریونینز","آلبیون روورز","کویین اوف ساوت","کلتی هارتس","اینورنس کالدونین تیسل","فورمارترین یونایتد","بونس یونایتد","لینلیتگو روز"];const vis=w.filter(x=>b.includes(x));const raws=["Airdrieonians","Albion Rovers","Queen of the South","Kelty Hearts","Inverness Caledonian Thistle","Formartine United","Linlithgow Rose","East Stirlingshire"];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector("h1")})})()' 2>/dev/null)
VIS=$(abf "$DOM" vis); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "8" ] && ok "C1 all 8 probe witnesses visible in the DOM at 390×844" || bad "C1 visible" "$VIS/8"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-7 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
[ "$FAIL" = "0" ] && echo "DOMPROOF 440 OK" || echo "DOMPROOF 440 BROKEN"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
