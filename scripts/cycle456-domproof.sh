#!/bin/bash
# cycle456-domproof.sh — harvest batch 17 (Update cycle 456)
#
# The work: ALL 10 count-3 single-country names of the MONTENEGRO tranche
# into TEAM_FA (1. CFL — the 447 tie-break winner RE-READ live this cycle:
# the three-way tie POL/UKR/MNE each 10 names / 30 rows broke on fa.wiki
# DIRECT club-article anchor quality, scripts/c456-wiki-tiebreak.py: MNE 2
# — بودوچنوست پودگوریتسا / آرسنال تیوات — vs POL 1 / UKR 1, documented as
# read; the 455 read had MNE 2 / UKR 1 / POL 0 — the MNE lead held; no
# exclusions), every key byte-verified against the live ±7 feed (scripts/
# c456-batch17-verify.py: 10/10 verified=0 bad, all MNE, 30 rows covered +
# the collision gate: dupKeys=[] and zero value collisions against the
# whole 1760-pair file), two direct fa.wiki club articles anchor the batch
# (بودوچنوست پودگوریتسا pageid 42378368 / آرسنال تیوات 41367275) + the
# city-title rule for توزی 39148180 / کوتور 41551328 / پلاو 43888965 /
# بار 41746946 / نیکشیچ 41554198 + the encyclopedia's OWN toponym
# spellings (یزرو from the village cluster «یزرو (سینیتسا)/(دسپوتوواتس)/
# (سوکوبانگا)»؛ دونیا from «دونیا وربیتسا»؛ پتروواتس from «پتروواتس نا
# ملاوی») + the honest-read fallbacks (دچیچ/بوکلی/ملادوست/مورنار/اوترانت/
# سوتجسکا — opensearch gate dead, the 452 لویی precedent), matches cache
# v19 → v20 per the standing rule (fresh cold window), patrol B4
# re-anchored 1819 → 1809 (the loud-pool rule: the −10 batch EXACTLY −10
# in the count-3 segment 213→203 — the isolated proof, zero long-tail
# window drift this time) + B22 batch-17 witnesses.
#
# This domproof: the map block integrity + the API across the WHOLE ±7
# window (the witness day is computed LIVE from the feed, the harness
# rule — this window carries ALL 10 on 2026-11-07, the 1. CFL full
# matchday) + the visible DOM on that witness day, 390×844, console
# clean. Harness lessons (432-455): probes are picked from the day's
# ACTUAL render set; the witness day converts through the ISO converter;
# the domproof is STANDALONE-runnable on any fresh clone — the expected
# pairs are EMBEDDED here (the 454 finding: no /tmp one-shot dependency).
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c456-domproof-results.txt
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
m = re.search(r'cycle-456: harvest batch 17(.*?)(?=// cycle-|};)', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c456-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c456-pairs.json'))))")
[ "$NB" = "10" ] && ok "A1 the batch-17 map block parses to exactly 10 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c456-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 10 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import json
EXPECTED = {
  "budućnost podgorica": "بودوچنوست پودگوریتسا",
  "dečić tuzi": "دچیچ توزی",
  "fk arsenal tivat": "آرسنال تیوات",
  "fk bokelj": "بوکلی کوتور",
  "jezero": "یزرو پلاو",
  "mornar": "مورنار بار",
  "ofk mladost donja gorica": "ملادوست دونیا گوریتسا",
  "otrant": "اوترانت",
  "petrovac": "پتروواتس",
  "sutjeska": "سوتجسکا نیکشیچ",
}
p = json.load(open("/tmp/c456-pairs.json"))  # written by THIS domproof from the committed block (A1)
miss = sorted(k for k in EXPECTED if k not in p or p[k] != EXPECTED[k])
extra = sorted(k for k in p if k not in EXPECTED)
n = len(miss) + len(extra)
print(str(n) if n == 0 else "%d missing=%s extra=%s" % (n, miss, extra))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 lesson, standalone) the block is byte-exact against the 10 embedded expected pairs (no /tmp dependency)" || bad "A3 byte-exact" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c456-pairs.json'))
ok = (p['budućnost podgorica'] == 'بودوچنوست پودگوریتسا') and (p['dečić tuzi'] == 'دچیچ توزی') and (p['ofk mladost donja gorica'] == 'ملادوست دونیا گوریتسا') and (p['petrovac'] == 'پتروواتس') and (p['fk bokelj'] == 'بوکلی کوتور')
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the byte-exactness: بودوچنوست پودگوریتسا (the club article, descriptor dropped) / دچیچ توزی (the ć→چ convention) / ملادوست دونیا گوریتسا (the encyclopedia's OWN دونیا وربیتسا spelling) / پتروواتس (the encyclopedia's OWN پتروواتس نا ملاوی spelling) / بوکلی کوتور (the bare form disambiguated — the fa.wiki بوکلی page is a NON-club subject)" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c456-pairs.json'))
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
[ "$RLEAK" = "0" ] && ok "B1 zero batch-17 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "10" ] && ok "B2 ALL 10 batch-17 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/10 ($HITS rows)"
[ "$WITCOUNT" = "10" ] && ok "B3 the witness day ($WITDAY) carries exactly the documented 10 of 10 (the 1. CFL full matchday)" || bad "B3 witness day" "$WITCOUNT/10"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
# the feed's date field is YYYYMMDD; the app's ?date= param is ISO YYYY-MM-DD
# (the 450 harness lesson: convert the live witness day, never hardcode)
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['Budućnost Podgorica','Dečić Tuzi','FK Arsenal Tivat','FK Bokelj','Jezero','Mornar','OFK Mladost Donja Gorica','Otrant','Petrovac','Sutjeska'];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-17 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
