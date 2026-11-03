#!/bin/bash
# cycle455-domproof.sh — harvest batch 16 (Update cycle 455)
#
# The work: ALL 10 count-3 single-country names of the AUSTRIA tranche into
# TEAM_FA (Bundesliga + 2. Liga — the 447 tie-break winner: the four-way
# tie AUT/POL/UKR/MNE each 10 names / 30 rows broke on fa.wiki DIRECT
# club-article anchor quality, scripts/c455-wiki-tiebreak.py: AUT 3 vs
# POL 0 / UKR 1 / MNE 2, documented as read; no exclusions), every key
# byte-verified against the live ±7 feed (scripts/c455-batch16-verify.py:
# 10/10 verified=0 bad, all AUT, 30 rows covered + the collision gate:
# dupKeys=[] and zero value collisions against the whole 1750-pair file),
# five direct fa.wiki club articles anchor the batch (آستریا وین pageid
# 535778 / فرست ویینا 5211062 / گراتس 4904665 / تیرول 5973388 / ولفسبرگر
# 4940416) + the city-title rule for ولس 638927 / اینسبروک 222006 /
# برگنتس 643035 / رید ایم اینکرایس + the file's OWN letter-reading
# conventions (fsv→اف‌اس‌وی for SW؛ austria→آستریا؛ wien→وین) + the
# honest-read fallback for آلتاخ (no fa.wiki article under any spelling —
# the 452 لویی precedent), matches cache v18 → v19 per the standing rule
# (18 v18 L2 rows purged + official restart = fresh cold window), patrol
# B4 re-anchored 1830 → 1819 (the loud-pool rule: −10 batch EXACTLY −10 in
# the count-3 segment 223→213 + 1 long-tail window drift, the 445
# precedent) + B21 batch-16 witnesses.
#
# This domproof: the map block integrity + the API across the WHOLE ±7
# window (no single day carries all 10 — the live scan shows the richest
# days carry 6 of 10; the witness day is computed LIVE from the feed, the
# harness rule) + the visible DOM on that witness day, 390×844, console
# clean. Harness lessons (432-454): probes are picked from the day's
# ACTUAL render set; the witness day converts through the ISO converter;
# the domproof is STANDALONE-runnable on any fresh clone — the expected
# pairs are EMBEDDED here (the 454 finding: no /tmp one-shot dependency).
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c455-domproof-results.txt
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
m = re.search(r'cycle-455: harvest batch 16(.*?)(?=// cycle-|};)', s, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
json.dump(dict(pairs), open('/tmp/c455-pairs.json', 'w'), ensure_ascii=False)
print(len(pairs))
PY
NB=$(python3 -c "import json;print(len(json.load(open('/tmp/c455-pairs.json'))))")
[ "$NB" = "10" ] && ok "A1 the batch-16 map block parses to exactly 10 key→value pairs" || bad "A1 map block" "$NB"
DUPL=$(python3 -c "
import json
p=json.load(open('/tmp/c455-pairs.json'))
vs=list(p.values())
print(len(vs)-len(set(vs)))")
[ "$DUPL" = "0" ] && ok "A2 zero within-block value-dups (each of the 10 clubs one render in the block)" || bad "A2 dup values" "$DUPL"
SRC=$(python3 - <<'PY'
import json
EXPECTED = {
  "altach": "آلتاخ",
  "austria wien": "آستریا وین",
  "fc hertha wels": "هرتا ولس",
  "fc wacker innsbruck": "واکر اینسبروک",
  "first vienna fc": "فرست ویینا",
  "grazer ak": "گراتس",
  "ried": "رید",
  "sw bregenz": "اس\u200cدبلیو برگنتس",
  "wsg tirol": "تیرول",
  "wolfsberger ac": "ولفسبرگر",
}
p = json.load(open("/tmp/c455-pairs.json"))  # written by THIS domproof from the committed block (A1)
miss = sorted(k for k in EXPECTED if k not in p or p[k] != EXPECTED[k])
extra = sorted(k for k in p if k not in EXPECTED)
n = len(miss) + len(extra)
print(str(n) if n == 0 else "%d missing=%s extra=%s" % (n, miss, extra))
PY
)
[ "$SRC" = "0" ] && ok "A3 (454 lesson, standalone) the block is byte-exact against the 10 embedded expected pairs (no /tmp dependency)" || bad "A3 byte-exact" "$SRC"
SPECIAL=$(python3 -c "
import json
p=json.load(open('/tmp/c455-pairs.json'))
zw = '\u200c'
ok = (p['austria wien'] == 'آستریا وین') and (p['first vienna fc'] == 'فرست ویینا') and (p['fc hertha wels'] == 'هرتا ولس') and (p['sw bregenz'] == 'اس' + zw + 'دبلیو برگنتس') and (p['wsg tirol'] == 'تیرول')
print('yes' if ok else 'no')")
[ "$SPECIAL" = "yes" ] && ok "A4 the byte-exactness: آستریا وین (the file's own austria/wien readings) / فرست ویینا (the encyclopedia's ویینا spelling) / هرتا ولس (the city ولس, NOT the invented ولز=Wales) / اس‌دبلیو برگنتس (the ZWNJ letters, the fsv convention) / تیرول" || bad "A4 byte-exact" "$SPECIAL"

echo "== B. the API across the WHOLE ±7 window (batch coverage) =="
FEED=$(python3 - <<'PY'
import json, re, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
pairs=json.load(open('/tmp/c455-pairs.json'))
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
[ "$RLEAK" = "0" ] && ok "B1 zero batch-16 raw literals anywhere in the ±7 window" || bad "B1 raw leak" "$RLEAK"
[ "$DISTINCT" = "10" ] && ok "B2 ALL 10 batch-16 Persian renders present across the window ($HITS rows)" || bad "B2 distinct" "$DISTINCT/10 ($HITS rows)"
[ "$WITCOUNT" = "6" ] && ok "B3 the witness day ($WITDAY) carries exactly the documented 6 of 10" || bad "B3 witness day" "$WITCOUNT/6"

echo "== C. the visible DOM (agent-browser 390×844, witness day) =="
# the feed's date field is YYYYMMDD; the app's ?date= param is ISO YYYY-MM-DD
# (the 450 harness lesson: convert the live witness day, never hardcode)
WITDATE=$(python3 -c "d='$WITDAY'; print(f'{d[0:4]}-{d[4:6]}-{d[6:8]}')")
echo "   witness URL date: $WITDATE"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=$WITDATE" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const w=$WITSET;const vis=w.filter(x=>b.includes(x));const raws=['Altach','Austria Wien','FC Hertha Wels','FC Wacker Innsbruck','First Vienna FC','Grazer AK','Ried','SW Bregenz','WSG Tirol','Wolfsberger AC'];const rleak=raws.filter(x=>b.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:w.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); TOT=$(abf "$DOM" tot); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: visible=$VIS/$TOT rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "$TOT" ] && ok "C1 ALL $TOT witness-day probe renders visible in the DOM at 390×844 (counted from the feed, the harness rule)" || bad "C1 visible" "$VIS/$TOT"
[ "$RLEAKD" = "0" ] && ok "C2 zero batch-16 raw literals anywhere in the body text" || bad "C2 raw leak" "$RLEAKD"
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
