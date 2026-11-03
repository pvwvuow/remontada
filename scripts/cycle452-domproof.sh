#!/bin/bash
# cycle452-domproof.sh — harvest batch 15 (Update cycle 452)
#
# The work: ALL 11 count-3 single-country names of the THAILAND tranche into
# TEAM_FA (League Cup Play-offs — the honest 451 runner-up: the CYP/THA tie
# broke on anchor quality and CYP went first; with CYP gone THA stands alone
# as the largest pool at 11 names/33 rows, the 446-pick rule; the count>=4
# multi-country names stay honest-raw, the 389 rule; no (W) sides, no
# exclusions), every key byte-verified against the live ±7 feed
# (scripts/c452-batch15-verify.py: 11/11 verified=0 bad, all THA, 33 rows
# covered + the collision gate: dupKeys=[] and each batch value exactly once
# in the 1750-pair file), zero direct fa.wiki club articles in the pool —
# exactly the 451 read — so the batch rides the fa.wiki CITY-TITLE toponym
# rule (چای نات/ناکون پاتوم/سونگکلا/ساتون/پاتایا/کانتچانابوری) + the
# footba11 press forms (خون کائن یونایتد/نونگ بوا پیچایا) + the
# BBC-syndicated مهاساراخام + the fa.wiki «دانشگاه کاستسارت» eponym,
# matches cache v17 → v18 per the standing rule (18 v17 L2 rows purged +
# official restart = fresh cold window), patrol B4 re-anchored 1841 → 1830
# (the loud-pool rule) + B19 batch-15 witnesses.
#
# This domproof: the map block integrity + the API across the WHOLE ±7 window
# (no single day carries all 11 — the live scan shows the richest days carry
# 5-7 of 11; the witness day is computed LIVE from the feed, the harness
# rule) + the visible DOM on that witness day, 390×844, console clean.
# Harness lessons (432-451): probes are picked from the day's ACTUAL render
# set (count from the feed, never from a manual tally); eval prints escaped-
# quoted JSON (parse with abf); grep -c counts lines not occurrences.
# cycle-454 re-anchor (the Fix cycle for finding #453): A3 no longer reads
# /tmp/c452-verified.json — that PRE byte-proof was ONE-SHOT by design (once
# the batch ships, the raw literals leave the live feed and PRE reports
# ABSENT) and /tmp does not survive a container recycle (453 caught A3 red
# with FileNotFoundError on a HEALTHY product; B/C/D all green in the same
# run). A3 is now anchored to the in-repo git truth: the 11 pairs commit
# 886f6ff added to src/lib/leagues.ts, byte-compared (key AND value) against
# the current block. The domproof is standalone-runnable on any fresh clone;
# run c452-batch15-verify.py PRE only BEFORE a batch ships, POST (--post)
# after. The same hold now lives permanently in the patrol as B20.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c452-domproof-results.txt
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
m = re.search(r'cycle-452: harvest batch 15(.*?)};', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c452-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c452-pairs.json'))))")
[ "$NB" = "11" ] && ok "A1 the batch-15 map block parses to exactly 11 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c452-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 11 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import re, json, subprocess
d = subprocess.run(["git", "show", "886f6ff", "--", "src/lib/leagues.ts"],
                   capture_output=True, text=True).stdout
batch = dict(re.findall(r'^\+\s*"([^"]+)"\s*:\s*"([^"]*)"', d, re.M))
if len(batch) != 11:
    print("BADCOUNT:%d (expected the 11 batch-15 pairs added by 886f6ff)" % len(batch))
else:
    p = json.load(open("/tmp/c452-pairs.json"))  # written by THIS domproof from the committed block (A1)
    missing = sorted(k for k in batch if k not in p)
    drifted = sorted(k for k in batch if k in p and p[k] != batch[k])
    n = len(missing) + len(drifted)
    print(str(n) if n == 0 else "%d missing=%s drifted=%s" % (n, missing, drifted))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 re-anchor) every batch-15 key shipped in commit 886f6ff is present in the current block byte-exact (11/11, git truth — the one-shot /tmp/c452-verified.json dependency is gone)" || bad "A3 key coverage" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c452-pairs.json'))
ok = (p['nakhon pathom'] == 'ناکون پاتوم') and (p['songkhla united fc'] == 'سونگکلا یونایتد') and (p['pt satun fc'] == 'پی‌تی ساتون') and (p['kasetsart'] == 'کاستسارت') and (p['chainat fc'] == 'چای نات') and (p['muang loei united'] == 'موانگ لویی یونایتد')
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the city-title byte-exactness: ناکون پاتوم (city, not the ناخون province) / سونگکلا (the ک city spelling) / پی‌تی ساتون / کاستسارت / چای نات / موانگ لویی یونایتد" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c452-pairs.json'))
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
[ "$RLEAK" = "0" ] && ok "B1 zero batch-15 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "11" ] && ok "B2 ALL 11 batch-15 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/11 ($HITS rows)"
[ "$WITCOUNT" = "7" ] && ok "B3 the witness day ($WITDAY) carries exactly the documented 7 of 11" || bad "B3 witness day" "$WITCOUNT/7"

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
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['Chainat FC','Kanchanaburi Power','Kasetsart','Khonkaen United FC','Mahasarakham Sam Bai Tao','Muang Loei United','Nakhon Pathom','Nong Bua Pitchaya FC','PT Satun FC','Pattaya Dolphins United','Songkhla United FC'];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-15 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
