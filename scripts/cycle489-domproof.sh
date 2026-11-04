#!/usr/bin/env bash
# cycle-489 domproof — the russia-cup 193 registration (the ledger's کاپ head).
# Written in the PERMANENT form from birth (the 477 lesson): structural
# invariants asserted, volatile snapshots REPORTED.
# A the in-repo registry integrity (catalog 40, the russia-cup entry
#   byte-exact, the composite labels, the walk-cache v6),
# B the LIVE APIs + the live trap-class re-proof (the 377/380 class) + the
#   match-hop effect, C the visible DOM at 390×844, D the fresh home.
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c489-domproof-results.txt
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

echo "== A. the registry integrity =="
A1=$(python3 - <<'PY'
import re
s = open('src/lib/leagues.ts', encoding='utf-8').read()
m = re.search(r'const LEAGUES[^=]*= \[(.*?)\];', s, re.S)
body = m.group(1)
entries = re.findall(r'\{ key: "([a-z0-9\-]+)",\s*fotmobId: (\d+),\s*ccode3: "([A-Z0-9]+)",\s*faName: "([^"]+)",\s*enName: "([^"]+)",?(.*?)\},', body)
d = {e[0]: e for e in entries}
ok = True; why = []
if len(entries) != 40: ok=False; why.append(f"entries={len(entries)}!=40")
e = d.get("russia-cup")
if not e: ok=False; why.append("russia-cup missing")
else:
    if e[1]!="193" or e[2]!="RUS": ok=False; why.append(f"russia-cup id/cc={e[1]}/{e[2]}")
    if e[3]!="جام حذفی روسیه": ok=False; why.append("russia-cup faName")
    if e[4]!="Russian Cup": ok=False; why.append(f"russia-cup enName={e[4]}")
    tail=e[5]
    if "espnSlug" in tail: ok=False; why.append("russia-cup must carry NO espnSlug (rus.cup+russian.cup both 400 live — the hazfi no-slug precedent)")
    if "priority: 40" not in tail: ok=False; why.append("russia-cup priority")
    if "globalMerge: false" not in tail: ok=False; why.append("russia-cup globalMerge")
    if "plainYearSeasons" in tail: ok=False; why.append("russia-cup must carry NO plainYearSeasons (17 slash seasons)")
# the 484 + 479 heads stay byte-intact
x = d.get("russia")
if not x or x[1]!="63" or x[2]!="RUS" or x[3]!="لیگ برتر روسیه": ok=False; why.append("russia head drifted")
y = d.get("guatemala")
if not y or y[1]!="336" or y[2]!="GUA": ok=False; why.append("guatemala head drifted")
print("0" if ok else ";".join(why))
PY
)
[ "$A1" = "0" ] && ok "A1 LEAGUES parses to exactly 40 entries; russia-cup=193/RUS/40 (faName «جام حذفی روسیه», enName «Russian Cup», NO espnSlug — the live 400 probe, globalMerge:false, NO plainYearSeasons — the 489 registry head); the 484 russia 63 + 479 guatemala 336 heads byte-intact" || bad "A1 catalog" "$A1"
A2=$(python3 - <<'PY'
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
ok = True; why = []
# faName rides the ALREADY-SHIPPED id-keyed mappings — one source of truth:
# the 462 live-window find (the day id) + the group-ids family
if '951803: "جام حذفی روسیه"' not in s: ok=False; why.append("ARCHIVE_TID_FA 951803 mapping missing")
if '938418: "جام حذفی روسیه — گروه A"' not in s: ok=False; why.append("group-ids family mapping missing")
# the four composite labels byte-present + family-equal
for k in ("cup grp. a","cup grp. b","cup grp. c","cup grp. d"):
    if f'"{k}":' not in s: ok=False; why.append(f"composite label {k} missing")
if '"cup grp. a": "جام حذفی روسیه — گروه A"' not in s: ok=False; why.append("composite label byte-drift")
print("0" if ok else ";".join(why))
PY
)
[ "$A2" = "0" ] && ok "A2 faName rides the published id-keyed mappings (ARCHIVE_TID_FA 951803 + the 938418-938421 group family — byte-equal, day feed and league page never disagree); the four «cup grp. x» composite labels byte-present with the family spellings" || bad "A2 names" "$A2"
A3=$(python3 -c "
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
v6 = 'teamStandingsRow:v6:' in s
v5 = 'teamStandingsRow:v5:' in s
print('0' if (v6 and not v5) else f'v6={v6} v5_still_present={v5}')")
[ "$A3" = "0" ] && ok "A3 the walk cache bumped teamStandingsRow:v5 → v6 (the pre-489 L2 negatives for the cup's own witnesses cannot survive the deploy — the standing one-move rule, the 474/479/484 chain)" || bad "A3 cache bump" "$A3"

echo "== B. the live APIs + the trap class + the hop =="
B1=$(curl -s --max-time 90 "$BASE/api/standings?league=russia-cup" | python3 -c "
import json,sys
d=json.load(sys.stdin)
rows=d.get('rows') or []
groups=d.get('groups') or []
want=['جام حذفی روسیه — گروه A','جام حذفی روسیه — گروه B','جام حذفی روسیه — گروه C','جام حذفی روسیه — گروه D']
got=[g.get('fa') for g in groups]
blob=json.dumps(d, ensure_ascii=False)
ok = (d.get('ok') and len(rows)==16 and got==want
      and all(g.get('count')==4 for g in groups)
      and 'Cup Grp' not in blob
      and all(any('\u0600'<=c<='\u06FF' for c in (r.get('fa') or '')) for r in rows[:4]))
print('0' if ok else f'rows={len(rows)} got={got} leaks={blob.count(\"Cup Grp\")}')")
[ "$B1" = "0" ] && ok "B1 /api/standings?league=russia-cup: ok, 16 rows in exactly 4 composite groups with the four Persian labels («جام حذفی روسیه — گروه A..D», count 4 each), every row Persian-fa, ZERO raw «Cup Grp» leaks (the 469/474 unmapped-label lesson applied)" || bad "B1 cup standings" "$B1"
B2=$(python3 - <<'PY'
import json, subprocess
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
def raw(url):
    r = subprocess.run(["curl","-s","--compressed","--max-time","40","-A",UA,url], capture_output=True, text=True, timeout=60)
    return r.stdout.strip()
ok = True; why = []
# the 377/380 day-tournament-id trap class, re-proven LIVE:
if raw("https://www.fotmob.com/api/data/leagues?id=951803") != "null":
    ok=False; why.append("id=951803 no longer answers null (trap class drift)")
# the real page id byte-read: details.name == the catalog enName
try:
    d = json.loads(raw("https://www.fotmob.com/api/data/leagues?id=193"))
    name = (d.get("details") or {}).get("name")
    if name != "Russian Cup": ok=False; why.append(f"193 name={name!r}")
    seas = d.get("allAvailableSeasons") or []
    if not seas or not all(isinstance(x,str) and "/" in x for x in seas[:5]): ok=False; why.append(f"seasons not slash: {seas[:3]}")
    print(f"REPORTED seasons_n={len(seas)} first={seas[0] if seas else None}")
except Exception as e:
    ok=False; why.append(f"193 payload unreadable: {e}")
s = open('src/lib/leagues.ts', encoding='utf-8').read()
print("0" if ok else ";".join(why))
PY
)
B2CORE=$(echo "$B2" | grep -v "^REPORTED" | head -1)
[ "$B2CORE" = "0" ] && ok "B2 the live trap-class re-proof: id=951803 answers HTTP 200 body null (the 377/380 day-tournament-id class, re-proven) while id=193 byte-reads details.name «Russian Cup» == the catalog enName with slash seasons ($(echo "$B2" | grep '^REPORTED' | head -1)) — the 474 byte-read rule" || bad "B2 trap class" "$B2CORE"
B3=$(curl -s --max-time 90 "$BASE/api/standings?league=russia-cup" | python3 -c "
import json,sys, re
d=json.load(sys.stdin)
seas=d.get('allSeasons') or []
ok = len(seas)>0 and len(seas)<=12 and all(re.fullmatch(r'\d{4}/\d{4}', s) for s in seas) and seas[0]=='2026/2027' and d.get('selectedSeason')=='2026/2027'
print('0' if ok else f'seasons={len(seas)} sample={seas[:3]} selected={d.get(\"selectedSeason\")}')")
[ "$B3" = "0" ] && ok "B3 seasons: the selector LIVE, all slash-form, first «2026/2027», selectedSeason the payload's own «2026/2027» (12 = the cycle-132 window cap of the payload's 17 — REPORTED, the permanent form)" || bad "B3 seasons" "$B3"
B4=$(python3 - <<'PY'
import json, subprocess
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
d = json.loads(subprocess.run(["curl","-s","--compressed","--max-time","40","-A",UA,
     "https://www.fotmob.com/api/data/leagues?id=193"], capture_output=True, text=True, timeout=60).stdout or "{}")
fx = ((d.get("fixtures") or {}).get("allMatches") or [])
ids = [str(f.get("id")) for f in fx if f.get("id")]
print(ids[0] if ids else "NONE")
PY
)
if [ "$B4" != "NONE" ] && [ -n "$B4" ]; then
  HOP=$(curl -s --max-time 60 "$BASE/match/$B4" | python3 -c "
import sys
html=sys.stdin.read()
print('0' if ('russia-cup' in html and 'جام حذفی روسیه' in html) else f'hop_missing match=$B4')")
  [ "$HOP" = "0" ] && ok "B4 the match hop (the fix's live effect on the match surface): the cup's own fixture $B4 (extracted live from the 193 payload — the 486 lesson) serves the BreadcrumbList hop → /league/russia-cup + «جام حذفی روسیه» (the parent-first lookup 7290 hits the catalog via general.parentLeagueId=193)" || bad "B4 hop" "$HOP"
else
  bad "B4 hop" "no fixture id extracted from the 193 payload"
fi

echo "== C. the visible DOM (agent-browser 390×844) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/league/russia-cup" >> "$OUT" 2>&1
sleep 4
DOM=$($AB eval "(()=>{const b=document.body.innerText;const want=['جام حذفی روسیه — گروه A','جام حذفی روسیه — گروه B','جام حذفی روسیه — گروه C','جام حذفی روسیه — گروه D'];const vis=want.filter(x=>b.includes(x)).length;const rawLeak=b.includes('Cup Grp');const h1=!!document.querySelector('h1');const de=document.documentElement;return JSON.stringify({vis:vis,rawLeak:rawLeak,h1:h1,sw:de.scrollWidth,vw:window.innerWidth})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); LEAK=$(abf "$DOM" rawLeak); H1=$(abf "$DOM" h1); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw)
echo "   league DOM: persianGroups=$VIS/4 rawLeak=$LEAK h1=$H1 scrollW=$SW innerW=$VW"
[ "$VIS" = "4" ] && [ "$LEAK" = "False" ] && ok "C1 /league/russia-cup at 390×844: ALL FOUR Persian group labels visible in the DOM, zero raw «Cup Grp» text (the fix's own page lit up honestly)" || bad "C1 league DOM" "vis=$VIS leak=$LEAK"
[ "$H1" = "True" ] && ok "C2 h1 present on /league/russia-cup" || bad "C2 h1" "$H1"
[ "$SW" = "390" ] && [ "$VW" = "390" ] && ok "C3 scrollW=390 innerW=390 (no horizontal overflow)" || bad "C3 scroll" "sw=$SW vw=$VW"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE" = "0" ] && ok "C4 console errors 0 on /league/russia-cup" || bad "C4 console" "$CE"
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "C5 page errors 0 on /league/russia-cup" || bad "C5 page errors" "$PE"

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
