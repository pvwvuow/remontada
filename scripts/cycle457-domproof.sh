#!/bin/bash
# cycle457-domproof.sh — harvest batch 18 (Update cycle 457)
#
# The work: ALL 10 count-3 single-country names of the UKRAINE tranche into
# TEAM_FA (the Ukrainian Cup field — the 447 tie-break winner RE-READ live
# and DEEPENED this cycle: the two-way tie POL/UKR each 10 names / 30 rows
# was DEAD-EVEN on direct club articles (POL 1 زنیچ پروشکوف vs UKR 1
# دینامو کی‌یف), so the read extended one documented level — CITY-TOPONYM
# anchor quality (the 452 rule): UKR 6 city hits (خارکوف Q42308،
# ژیتومیر Q156713، ریونه Q156739، چرکاسی Q157055، کامیانتس-پودیلسکی
# Q193965، برهوفه Q146497 — the last a WRONG-CITY probe artifact for Liviy
# Bereh, excluded from value anchoring) vs POL 4 — scripts/
# c457-wiki-tiebreak.py, documented as read; no exclusions), every key
# byte-verified against the live ±7 feed (scripts/c457-batch18-verify.py:
# 10/10 verified=0 bad, all UKR, 30 rows covered + the collision gate:
# dupKeys=[] and zero value collisions against the whole 1770-pair file),
# one direct fa.wiki club article anchors the batch (دینامو کی‌یف pageid
# 43974850) + the city-title rule for خارکوف 44675128 / لویو 44886178 /
# چرکاسی 35486135 / ژیتومیر 44202029 / ریونه 41341728 / لوگانسک 12375949 /
# کامیانتس-پودیلسکی 43825852 + the encyclopedia's OWN spellings (اپیسنتر
# from the epicenter word؛ پولیسیا from the «پولیسیان‌ها» derivation؛
# کریفیی ریه the Kryvyi Rih sitelink — documented, not used) + the
# NON-club bare-form exclusions (کارپات = an SS Ramsey Town SHIP؛ ورس = a
# Category:Eva Perón؛ زوریا = an unresolvable redirect — the 456 بوکلی
# lesson) + the honest-read fallbacks (کارپات/کریوباس/لیوی بره)، matches
# cache v20 → v21 per the standing rule (fresh cold window), patrol B4
# re-anchored 1809 → 1798 (the loud-pool rule: the −10 batch EXACTLY −10
# in the count-3 segment 203→193 — the isolated proof — + 1 long-tail
# window drift, the 445/455 precedent) + B23 batch-18 witnesses.
#
# This domproof: the map block integrity + the API across the WHOLE ±7
# window (the witness day is computed LIVE from the feed, the harness
# rule — this window's richest day carries 5 of 10, the Cup matchday) +
# the visible DOM on that witness day, 390×844, console
# clean. Harness lessons (432-456): probes are picked from the day's
# ACTUAL render set; the witness day converts through the ISO converter;
# the domproof is STANDALONE-runnable on any fresh clone — the expected
# pairs are EMBEDDED here (the 454 finding: no /tmp one-shot dependency).
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c457-domproof-results.txt
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
m = re.search(r'cycle-457: harvest batch 18(.*?)(?=// cycle-|};)', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c457-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c457-pairs.json'))))")
[ "$NB" = "10" ] && ok "A1 the batch-18 map block parses to exactly 10 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c457-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 10 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import json
EXPECTED = {
  "dynamo kyiv": "دینامو کی‌یف",
  "epitsentr kamianets-podilskyi": "اپیسنتر کامیانتس-پودیلسکی",
  "fc kharkiv": "خارکوف",
  "karpaty": "کارپات لویو",
  "kryvbas": "کریوباس",
  "lnz cherkasy": "ال\u200cان\u200cزد چرکاسی",
  "liviy bereh": "لیوی بره",
  "polissya zhytomyr": "پولیسیا ژیتومیر",
  "veres rivne": "ورس ریونه",
  "zorya": "زوریا لوگانسک",
}
p = json.load(open("/tmp/c457-pairs.json"))  # written by THIS domproof from the committed block (A1)
miss = sorted(k for k in EXPECTED if k not in p or p[k] != EXPECTED[k])
extra = sorted(k for k in p if k not in EXPECTED)
n = len(miss) + len(extra)
print(str(n) if n == 0 else "%d missing=%s extra=%s" % (n, miss, extra))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 lesson, standalone) the block is byte-exact against the 10 embedded expected pairs (no /tmp dependency)" || bad "A3 byte-exact" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c457-pairs.json'))
ok = (p['dynamo kyiv'] == 'دینامو کی‌یف') and (p['fc kharkiv'] == 'خارکوف') and (p['karpaty'] == 'کارپات لویو') and (p['lnz cherkasy'] == 'ال\u200cان\u200cزد چرکاسی') and (p['epitsentr kamianets-podilskyi'] == 'اپیسنتر کامیانتس-پودیلسکی')
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the byte-exactness: دینامو کی‌یف (the club article, descriptor dropped) / خارکوف (the bare club=town, the رید precedent) / کارپات لویو (the file's OWN پوگون لویو letter-reading) / ال‌ان‌زد چرکاسی (the ZWNJ letter-reading, the ال‌ان‌جی family) / اپیسنتر کامیانتس-پودیلسکی (the encyclopedia's OWN epicenter spelling)" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c457-pairs.json'))
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
[ "$RLEAK" = "0" ] && ok "B1 zero batch-18 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "10" ] && ok "B2 ALL 10 batch-18 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/10 ($HITS rows)"
[ "$WITCOUNT" = "5" ] && ok "B3 the witness day ($WITDAY) carries exactly the documented 5 of 10 (the Cup matchday)" || bad "B3 witness day" "$WITCOUNT/5"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
# the feed's date field is YYYYMMDD; the app's ?date= param is ISO YYYY-MM-DD
# (the 450 harness lesson: convert the live witness day, never hardcode)
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['Dynamo Kyiv','Epitsentr Kamianets-Podilskyi','FC Kharkiv','Karpaty','Kryvbas','LNZ Cherkasy','Liviy Bereh','Polissya Zhytomyr','Veres Rivne','Zorya'];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-18 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
