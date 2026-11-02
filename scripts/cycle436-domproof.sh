#!/bin/bash
# cycle436-domproof.sh — harvest batch 5 (Update cycle 436)
#
# The work: 40 more single-country team names into TEAM_FA (the Spain Copa
# del Rey / Federaciones tranche — Primera/Segunda Federacion groups +
# LaLiga2), every key byte-verified against the live ±7 feed
# (scripts/cycle436-batch5-verify.py: 40/40 verified=0 bad, all ESP), the
# census arithmetic EXACT (2053 − 40 = 2013, zero distinct drift), the direct
# re-check decisive (0 batch raw literals leaking; 122 Persian renders =
# the 120 expected + 2 rows of live upstream window drift — the 431 lesson:
# rows drift, the distinct count is the decisive index and it is EXACT),
# matches cache v6 → v7 per the 426/430/431/432/435 rule (18 v6 L2 rows
# purged + official restart = fresh cold window), patrol B4 re-anchored
# 2053 → 2013 with the history line (loud-pool rule) + B8 batch-5 witnesses.
#
# This domproof: the map block integrity + the API + the visible DOM on the
# richest witness day (offset -2 = 2026-11-01, 34 batch-5 renders), 390×844,
# console clean.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/home/z/my-project/remontada/scripts/cycle436-results.txt
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
m = re.search(r'cycle-436: harvest batch 5(.*?)};', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c436-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c436-pairs.json'))))")
[ "$NB" = "40" ] && ok "A1 the batch-5 map block parses to exactly 40 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c436-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "1" ] && ok "A2 exactly one intentional value-dup (Logroñés + SD Logroñés → لاگرونیس, two feed spellings of one club)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 -c "
import json
s=open('src/lib/leagues.ts',encoding='utf-8').read()
v=json.load(open('/tmp/c436-verified.json'))
p=json.load(open('/tmp/c436-pairs.json'))
bad=[x['key'] for x in v if x['key'] not in p]
print(len(bad))")
[ "$SRC" = "0" ] && ok "A3 every verified key (40/40 from the live ±7 gate) is present in the block" || bad "A3 key coverage" "$SRC"

echo "== B. the API feed on the witness day (offset -2 = 2026-11-01) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
out=subprocess.run(["curl","-s","--max-time","40","-A",UA,f"{BASE}/api/matches?offset=-2"],capture_output=True,text=True,timeout=60).stdout
d=json.loads(out)
pairs=json.load(open('/tmp/c436-pairs.json'))
vals=set(pairs.values()); raws=set(pairs.keys())
hits=[]; rawleak=0
for g in d.get("groups",[]):
    for m in g.get("matches",[]):
        for side in ("home","away"):
            t=m.get(side) or {}
            n=t.get("fa") or t.get("name") or ""
            if n in vals: hits.append(n)
            elif n in raws: rawleak+=1
print(json.dumps({"hits":len(hits),"rawleak":rawleak,"date":d.get("date")}, ensure_ascii=False))
PY
)
HITS=$(abf "$FEED" hits); RLEAK=$(abf "$FEED" rawleak); FDATE=$(abf "$FEED" date)
[ "$FDATE" = "20261101" ] && ok "B1 witness day feed date = 20261101 (offset -2)" || bad "B1 feed date" "$FDATE"
[ "$RLEAK" = "0" ] && ok "B2 zero batch-5 raw literals in the witness-day feed" || bad "B2 raw leak" "$RLEAK"
[ "$HITS" = "34" ] && ok "B3 34 batch-5 Persian renders present in the witness-day feed (the census count)" || bad "B3 hits" "$HITS"

echo "== C. the visible DOM (agent-browser 390×844, /?date=2026-11-01) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=2026-11-01" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval '(()=>{const b=document.body.innerText;const w=["رایو کانتابریا","اورنسه","پورتوالته","کوروشو","آموربیتا","خیمناستیکا","رکراتیوو اوئلوا","نومانسیا"];const vis=w.filter(x=>b.includes(x));const raws=["Rayo Cantabria","Ourense","Portugalete","Coruxo","Amorebieta","Gimnástica","Huelva","Numancia"];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector("h1")})})()' 2>/dev/null)
VIS=$(abf "$DOM" vis); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "8" ] && ok "C1 all 8 probe witnesses visible in the DOM at 390×844" || bad "C1 visible" "$VIS/8"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-5 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
[ "$FAIL" = "0" ] && echo "DOMPROOF 436 OK" || echo "DOMPROOF 436 BROKEN"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
