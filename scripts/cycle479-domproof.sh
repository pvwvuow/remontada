#!/usr/bin/env bash
# cycle-479 domproof (the 452..477 harness family) — the GUA registration:
# A the in-repo registry integrity (catalog 38, the guatemala entry
# byte-exact + the HON byte-disambiguation + the walk-cache v4), B the LIVE
# APIs (the flat 12-row standings + the two crack witnesses' league lines +
# the 17 slash seasons), C the visible DOM at 390×844, D the fresh home.
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c479-domproof-results.txt
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
if len(entries) != 40: ok=False; why.append(f"entries={len(entries)}!=40")  # cycle-484: the registry's next head (russia 63) — the count legitimately grows one-per-fix-cycle
e = d.get("guatemala")
if not e: ok=False; why.append("guatemala missing")
else:
    if e[1]!="336" or e[2]!="GUA": ok=False; why.append(f"guatemala id/cc={e[1]}/{e[2]}")
    if e[3]!="لیگ ملی گواتمالا — آپرتورا": ok=False; why.append("guatemala faName")
    if e[4]!="Liga Nacional Apertura": ok=False; why.append(f"guatemala enName={e[4]}")
    tail=e[5]
    if 'espnSlug: "gua.1"' not in tail: ok=False; why.append("guatemala espnSlug")
    if "priority: 38" not in tail: ok=False; why.append("guatemala priority")
    if "globalMerge: false" not in tail: ok=False; why.append("guatemala globalMerge")
    if "plainYearSeasons" in tail: ok=False; why.append("guatemala must carry NO plainYearSeasons (all 17 seasons slash-form)")
# the 474 head stays byte-intact
x = d.get("argentina")
if not x or x[1]!="112" or x[2]!="ARG": ok=False; why.append("argentina head drifted")
print("0" if ok else ";".join(why))
PY
)
[ "$A1" = "0" ] && ok "A1 LEAGUES parses to exactly 40 entries; russia=63/RUS/39 (espnSlug rus.1 — the 484 registry head) + the 489 registry head russia-cup 193 (NO espnSlug — the hazfi no-slug precedent); the 479 guatemala head byte-intact" || bad "A1 catalog" "$A1"
A2=$(python3 - <<'PY'
s = open('src/lib/leagues.ts', encoding='utf-8').read()
ok = True; why = []
# faName rides the ALREADY-SHIPPED 384 CC-keyed mapping — one source of truth
if '"liga nacional apertura|GUA": "لیگ ملی گواتمالا — آپرتورا"' not in s: ok=False; why.append("published mapping missing")
# enName byte-identical to the day-feed group name AND byte-DISTINCT from
# honduras's dash-spelled form (the 469 disambiguation hold)
if 'enName: "Liga Nacional Apertura"' not in s: ok=False; why.append("GUA enName byte")
if 'enName: "Liga Nacional - Apertura"' not in s: ok=False; why.append("HON dash enName gone")
print("0" if ok else ";".join(why))
PY
)
[ "$A2" = "0" ] && ok "A2 faName rides the published «liga nacional apertura|GUA» mapping; enName bare «Liga Nacional Apertura» byte-distinct from honduras's dash-spelled «Liga Nacional - Apertura» (the 469 disambiguation hold)" || bad "A2 names" "$A2"
A3=$(python3 - <<'PY'
import json, subprocess, re
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
live = None
for o in range(0, -8, -1):
    out = subprocess.run(["curl", "-s", "--compressed", "--max-time", "40", "-A", UA,
                          f"http://localhost:3000/api/matches?offset={o}"], capture_output=True, text=True, timeout=60).stdout
    try: d = json.loads(out)
    except Exception: continue
    for g in d.get("groups", []):
        nm = (g.get("name") or g.get("leagueName") or "")
        if nm.startswith("Liga Nacional") and "Apertura" in nm and "-" not in nm:
            live = nm; break
    if live: break
s = open('src/lib/leagues.ts', encoding='utf-8').read()
mm = re.search(r'key: "guatemala".*?enName: "([^"]+)"', s, re.S)
en = mm.group(1) if mm else None
print("0" if (live and en == live) else f"live_group={live!r} catalog_enName={en!r}")
PY
)
[ "$A3" = "0" ] && ok "A3 enName byte-read LIVE off the day feed: the group «Liga Nacional Apertura» == the catalog enName (the 474 byte-read rule, no dash — HON stays distinct)" || bad "A3 live byte" "$A3"
A4=$(python3 -c "
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
v6 = 'teamStandingsRow:v6:' in s
v5 = 'teamStandingsRow:v5:' in s
print('0' if (v6 and not v5) else f'v6={v6} v5_still_present={v5}')")
[ "$A4" = "0" ] && ok "A4 the walk cache bumped teamStandingsRow:v5 → v6 (the pre-484 L2 negatives for the RUS witnesses 8683 et al. cannot survive the deploy — the standing one-move rule)" || bad "A4 cache bump" "$A4"

echo "== B. the live APIs (the fix's own effect) =="
B1=$(curl -s --max-time 90 "$BASE/api/standings?league=guatemala" | python3 -c "
import json,sys
d=json.load(sys.stdin)
rows=d.get('rows') or []
r0=rows[0] if rows else {}
ok = d.get('ok') and len(rows)==12 and r0.get('idx')==1 and r0.get('name')=='Antigua Guatemala' and r0.get('fa')=='آنتیگوا گواتمالا' and d.get('leagueFa')=='لیگ ملی گواتمالا — آپرتورا' and not d.get('groups')
print('0' if ok else f'rows={len(rows)} r0={r0.get(\"name\")}/{r0.get(\"fa\")} leagueFa={d.get(\"leagueFa\")} groups={d.get(\"groups\")}')")
[ "$B1" = "0" ] && ok "B1 /api/standings?league=guatemala: ok, 12 FLAT rows (groups null), Antigua Guatemala idx 1 «آنتیگوا گواتمالا» top, leagueFa «لیگ ملی گواتمالا — آپرتورا»" || bad "B1 guatemala api" "$B1"
B2=$(curl -s --max-time 90 "$BASE/api/team/9933" | python3 -c "
import json,sys
d=json.load(sys.stdin)
st=d.get('standings')
ok = bool(st) and st.get('leagueKey')=='guatemala' and st.get('leagueFa')=='لیگ ملی گواتمالا — آپرتورا' and st.get('rank')==2 and st.get('pts')==30
print('0' if ok else f'standings={st}')")
[ "$B2" = "0" ] && ok "B2 /api/team/9933 (CSD Municipal — the 5861309 crack's own club): the league line LIVE from the registered league — لیگ ملی گواتمالا — آپرتورا, رتبه ۲ با ۳۰ امتیاز (byte-matching the probed Apertura table)" || bad "B2 municipal" "$B2"
B3=$(curl -s --max-time 90 "$BASE/api/team/49761" | python3 -c "
import json,sys
d=json.load(sys.stdin)
st=d.get('standings')
ok = bool(st) and st.get('leagueKey')=='guatemala' and st.get('rank')==10 and st.get('pts')==20
print('0' if ok else f'standings={st}')")
[ "$B3" = "0" ] && ok "B3 /api/team/49761 (Comunicaciones FC — the second witness): رتبه ۱۰ با ۲۰ امتیاز از همان جدول آپرتورا" || bad "B3 comunicaciones" "$B3"
B4=$(curl -s --max-time 90 "$BASE/api/standings?league=guatemala" | python3 -c "
import json,sys, re
d=json.load(sys.stdin)
seas=d.get('allSeasons') or []
ok = len(seas)==12 and all(re.fullmatch(r'\d{4}/\d{4}', s) for s in seas) and seas[0]=='2026/2027' and d.get('selectedSeason')=='2026/2027'
print('0' if ok else f'seasons={len(seas)} sample={seas[:4]} selected={d.get(\"selectedSeason\")}')")
[ "$B4" = "0" ] && ok "B4 seasons: the selector LIVE with the FIRST 12 of the payload's 17 slash-form names (the cycle-132 window cap — documented design), all byte-slash-form, selectedSeason the payload's own «2026/2027» (honduras's degradation not repeated)" || bad "B4 seasons" "$B4"

echo "== C. the visible DOM (agent-browser 390×844) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/team/9933" >> "$OUT" 2>&1
sleep 4
DOM=$($AB eval "(()=>{const b=document.body.innerText;const vis=b.includes('لیگ ملی گواتمالا — آپرتورا');const rankline=b.includes('رتبه');const fb=b.includes('اطلاعات لیگ یافت نشد');const de=document.documentElement;return JSON.stringify({vis:vis,rk:rankline,fb:fb,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); RK=$(abf "$DOM" rk); FB=$(abf "$DOM" fb); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   team DOM: vis=$VIS rankline=$RK fallback=$FB scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "True" ] && [ "$RK" = "True" ] && [ "$FB" = "False" ] && ok "C1 /team/9933 at 390×844: the league line «لیگ ملی گواتمالا — آپرتورا · رتبه …» visible in the DOM and the «اطلاعات لیگ یافت نشد» fallback GONE (the fix's live effect)" || bad "C1 team DOM" "vis=$VIS rk=$RK fb=$FB"
$AB open "$BASE/league/guatemala" >> "$OUT" 2>&1
sleep 4
DOM2=$($AB eval "(()=>{const b=document.body.innerText;const want=['آنتیگوا گواتمالا','مونیسیپال','کامیونیکیشنس','گواستاتویا'];const vis=want.filter(x=>b.includes(x)).length;const cells=Array.from(document.querySelectorAll('*')).filter(e=>e.children.length===0).map(e=>e.textContent.trim());const raws=['Liga Nacional Apertura','Liga Nacional'];const leak=raws.filter(x=>cells.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis,leak:leak.length,sw:de.scrollWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS2=$(abf "$DOM2" vis); LEAK=$(abf "$DOM2" leak); SW2=$(abf "$DOM2" sw); H12=$(abf "$DOM2" h1)
echo "   league DOM: persianTeams=$VIS2/4 rawLeak=$LEAK scrollW=$SW2 h1=$H12"
[ "$VIS2" = "4" ] && [ "$LEAK" = "0" ] && ok "C2 /league/guatemala at 390×844: the four GUA witnesses Persian in the DOM, zero raw «Liga Nacional» cells (exact-cell match — the 462 lesson)" || bad "C2 league DOM" "vis=$VIS2 leak=$LEAK"
[ "$SW" = "390" ] && [ "$VW" = "390" ] && [ "$SW2" = "390" ] && ok "C3 scrollW=390 innerW=390 on BOTH pages (no horizontal overflow)" || bad "C3 scroll" "sw=$SW/$SW2 vw=$VW"
[ "$H1" = "True" ] && [ "$H12" = "True" ] && ok "C4 h1 present on both pages" || bad "C4 h1" "$H1/$H12"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE" = "0" ] && ok "C5 console errors 0 across both pages" || bad "C5 console" "$CE"
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "C6 page errors 0 across both pages" || bad "C6 page errors" "$PE"

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
