#!/usr/bin/env bash
# cycle-474 domproof (the 452..472 harness family) — the ledger's HEAD
# registration: ARGENTINA Liga Profesional (fotmob page id 112, cracked via
# the 141 matchDetails parentLeagueId crack — the day-feed id 1000001729
# answers literal null). A the in-repo registry integrity (catalog 37, the
# argentina entry fields, the published faName/enName bytes, the four
# composite group labels, the walk-cache v3 bump), B the LIVE APIs
# (/api/standings?league=argentina composite flatten + the two fix
# witnesses' team pages byte-matching the probed Clausura B table), C the
# visible DOM at 390×844 (the league line live on /team/10086, the fallback
# gone, the four Persian group labels on /league/argentina, zero raw Latin,
# no overflow, clean console), D the fresh home (the 434 mount-gate).
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c474-domproof-results.txt
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
m = re.search(r'export const LEAGUES: LeagueConfig\[\] = \[(.*?)\n\];', s, re.S)
body = m.group(1)
entries = re.findall(r'\{ key: "([a-z0-9]+)",\s*fotmobId: (\d+),\s*ccode3: "([A-Z0-9]+)",\s*faName: "([^"]+)",\s*enName: "([^"]+)",?(.*?)\},', body)
d = {e[0]: e for e in entries}
ok = True; why = []
if len(entries) != 39: ok=False; why.append(f"entries={len(entries)}!=39")  # cycle-484: the registry's next head (russia 63) — the count legitimately grows one-per-fix-cycle
e = d.get("argentina")
if not e: ok=False; why.append("argentina missing")
else:
    if e[1]!="112" or e[2]!="ARG": ok=False; why.append(f"argentina id/cc={e[1]}/{e[2]}")
    if e[3]!="لیگ حرفه‌ای آرژانتین": ok=False; why.append("argentina faName")
    if e[4]!="Liga Profesional": ok=False; why.append(f"argentina enName={e[4]}")
    tail=e[5]
    if 'espnSlug: "arg.1"' not in tail: ok=False; why.append("argentina espnSlug")
    if "priority: 37" not in tail: ok=False; why.append("argentina priority")
    if "globalMerge: false" not in tail: ok=False; why.append("argentina globalMerge")
    if "plainYearSeasons: true" not in tail: ok=False; why.append("argentina plainYear")
# the 469 trio stays byte-intact
for k,(fid,cc,pr) in {"estonia":("248","EST","34"),"honduras":("337","HON","35"),"panama":("9039","PAN","36")}.items():
    x=d.get(k)
    if not x: ok=False; why.append(f"{k} missing"); continue
    if x[1]!=fid or x[2]!=cc: ok=False; why.append(f"{k} id/cc")
print("0" if ok else ";".join(why))
PY
)
[ "$A1" = "0" ] && ok "A1 LEAGUES parses to exactly 39 entries (the 479 registry head guatemala 336 + the 484 registry head russia 63 joined); argentina=112/ARG/37 (espnSlug arg.1, globalMerge:false, plainYearSeasons:true); the 469 trio byte-intact" || bad "A1 catalog" "$A1"
A2=$(python3 - <<'PY'
s = open('src/lib/leagues.ts', encoding='utf-8').read()
ok = True; why = []
# faName rides the ALREADY-SHIPPED mapping — one source of truth, day feed
# and league page never disagree
if '"liga profesional|ARG": "لیگ حرفه‌ای آرژانتین"' not in s: ok=False; why.append("published mapping missing")
# enName byte-identical to the day-feed group name (read live off the team
# route's recent[0].leagueName 2026-11-04)
if 'enName: "Liga Profesional"' not in s: ok=False; why.append("enName byte")
print("0" if ok else ";".join(why))
PY
)
[ "$A2" = "0" ] && ok "A2 faName rides the published «liga profesional|ARG» mapping; enName byte-identical to the day-feed group name «Liga Profesional»" || bad "A2 names" "$A2"
A3=$(python3 -c "
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
need = ['\"clausura group a\": \"کلاسورا — گروه A\"', '\"clausura group b\": \"کلاسورا — گروه B\"', '\"apertura group a\": \"آپرتورا — گروه A\"', '\"apertura group b\": \"آپرتورا — گروه B\"']
miss = [x for x in need if x not in s]
print('0' if not miss else miss)")
[ "$A3" = "0" ] && ok "A3 COMPOSITE_REGION_FA carries the four ARG group labels (no raw Latin on the composite standings page)" || bad "A3 group labels" "$A3"
A4=$(python3 -c "
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
v5 = 'teamStandingsRow:v5:' in s
v4 = 'teamStandingsRow:v4:' in s
print('0' if (v5 and not v4) else f'v5={v5} v4_still_present={v4}')")
[ "$A4" = "0" ] && ok "A4 the walk cache bumped teamStandingsRow past the 479 v4 (currently v5 per the 484 registry head — the pre-474 L2 negatives for the ARG witnesses cannot survive the deploy)" || bad "A4 cache bump" "$A4"

echo "== B. the live APIs (the fix's own effect) =="
B1=$(curl -s --max-time 90 "$BASE/api/standings?league=argentina" | python3 -c "
import json,sys
d=json.load(sys.stdin)
rows=d.get('rows') or []
g=d.get('groups') or []
fa=[x.get('fa') for x in g]
exp=['کلاسورا — گروه A','کلاسورا — گروه B','آپرتورا — گروه A','آپرتورا — گروه B']
ok = len(rows)==60 and fa==exp
print('0' if ok else f'rows={len(rows)} groups={fa}')")
[ "$B1" = "0" ] && ok "B1 /api/standings?league=argentina: 60 flattened composite rows, the FOUR groups Persian (کلاسورا/آپرتورا — گروه A/B)" || bad "B1 argentina api" "$B1"
B2=$(curl -s --max-time 90 "$BASE/api/team/10086" | python3 -c "
import json,sys
d=json.load(sys.stdin)
st=d.get('standings')
ok = bool(st) and st.get('leagueKey')=='argentina' and st.get('leagueFa')=='لیگ حرفه‌ای آرژانتین' and st.get('rank')==2 and st.get('pts')==31
print('0' if ok else f'standings={st}')")
[ "$B2" = "0" ] && ok "B2 /api/team/10086 (Argentinos Juniors — the ledger's own witness): the league line LIVE from the registered league — لیگ حرفه‌ای آرژانتین, رتبه ۲ با ۳۱ امتیاز (byte-matching the probed Clausura B table)" || bad "B2 argentinos" "$B2"
B3=$(curl -s --max-time 90 "$BASE/api/team/161727" | python3 -c "
import json,sys
d=json.load(sys.stdin)
st=d.get('standings')
ok = bool(st) and st.get('leagueKey')=='argentina' and st.get('rank')==10 and st.get('pts')==17
print('0' if ok else f'standings={st}')")
[ "$B3" = "0" ] && ok "B3 /api/team/161727 (Atlético Tucumán — the second witness): رتبه ۱۰ با ۱۷ امتیاز از همان جدول کلاسورا B" || bad "B3 tucuman" "$B3"
B4=$(curl -s --max-time 90 "$BASE/api/standings?league=argentina" | python3 -c "
import json,sys
d=json.load(sys.stdin)
seas=d.get('allSeasons') or []
ok = len(seas)==10 and '2024' in seas and d.get('selectedSeason')=='2026 - Clausura'
print('0' if ok else f'seasons={len(seas)} sample={seas[:4]} selected={d.get(\"selectedSeason\")}')")
[ "$B4" = "0" ] && ok "B4 seasons: the 10 plain years admitted (the 382 flag live), the 13 «YYYY - Clausura/Apertura» suffixed honestly out of the selector, current marker the payload's own «2026 - Clausura» (the 419 honesty)" || bad "B4 seasons" "$B4"

echo "== C. the visible DOM (agent-browser 390×844) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/team/10086" >> "$OUT" 2>&1
sleep 4
DOM=$($AB eval "(()=>{const b=document.body.innerText;const vis=b.includes('لیگ حرفه‌ای آرژانتین');const rankline=b.includes('رتبه');const fb=b.includes('اطلاعات لیگ یافت نشد');const de=document.documentElement;return JSON.stringify({vis:vis,rk:rankline,fb:fb,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); RK=$(abf "$DOM" rk); FB=$(abf "$DOM" fb); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   team DOM: vis=$VIS rankline=$RK fallback=$FB scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "True" ] && [ "$RK" = "True" ] && [ "$FB" = "False" ] && ok "C1 /team/10086 at 390×844: the league line «لیگ حرفه‌ای آرژانتین · رتبه …» visible in the DOM and the «اطلاعات لیگ یافت نشد» fallback GONE (the fix's live effect)" || bad "C1 team DOM" "vis=$VIS rk=$RK fb=$FB"
$AB open "$BASE/league/argentina" >> "$OUT" 2>&1
sleep 4
DOM2=$($AB eval "(()=>{const b=document.body.innerText;const want=['کلاسورا — گروه A','کلاسورا — گروه B','آپرتورا — گروه A','آپرتورا — گروه B'];const vis=want.filter(x=>b.includes(x)).length;const cells=Array.from(document.querySelectorAll('*')).filter(e=>e.children.length===0).map(e=>e.textContent.trim());const raws=['Clausura Group A','Clausura Group B','Apertura Group A','Apertura Group B'];const leak=raws.filter(x=>cells.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis,leak:leak.length,sw:de.scrollWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS2=$(abf "$DOM2" vis); LEAK=$(abf "$DOM2" leak); SW2=$(abf "$DOM2" sw); H12=$(abf "$DOM2" h1)
echo "   league DOM: groups=$VIS2/4 rawLeak=$LEAK scrollW=$SW2 h1=$H12"
[ "$VIS2" = "4" ] && [ "$LEAK" = "0" ] && ok "C2 /league/argentina at 390×844: all FOUR group labels Persian in the DOM, zero raw «Clausura/Apertura Group» cells (exact-cell match — the 462 lesson)" || bad "C2 league DOM" "vis=$VIS2 leak=$LEAK"
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
