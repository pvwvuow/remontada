#!/usr/bin/env bash
# cycle-469 domproof — the 468 finding's fix: the first THREE harvest-wave
# league registrations (estonia 248 / honduras 337 / panama 9039 — the day
# ids 1000001181/941508/941168 answered NULL as league pages; the real ids
# surfaced via the cycle-141 crack). A the catalog integrity (in-repo,
# byte-level), B the standings APIs (row counts, the honest HON seasons
# hide, the Persian PAN zone groups) + the 9-team witness sweep (5 EST + 2
# HON + 1 PAN + the استقلال control), C the visible DOM at 390×844 (the
# league lines live on the very pages the 468 finding pinned, the fallback
# string GONE, the PAN zones Persian) and the console clean, D fresh home.
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c469-domproof-results.txt
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

echo "== A. the catalog integrity (in-repo) =="
A1=$(python3 - <<'PY'
import re
s = open('src/lib/leagues.ts', encoding='utf-8').read()
m = re.search(r'export const LEAGUES: LeagueConfig\[\] = \[(.*?)\n\];', s, re.S)
body = m.group(1)
entries = re.findall(r'\{ key: "([a-z0-9]+)",\s*fotmobId: (\d+),\s*ccode3: "([A-Z0-9]+)",\s*faName: "([^"]+)",\s*enName: "([^"]+)",?(.*?)\},', body)
d = {e[0]: e for e in entries}
ok = True; why = []
if len(entries) != 38: ok=False; why.append(f"entries={len(entries)}!=38")  # cycle-479: the registry's next head (guatemala 336) — the count legitimately grows one-per-fix-cycle
want = {"estonia": ("248","EST","34"), "honduras": ("337","HON","35"), "panama": ("9039","PAN","36")}
for k,(fid,cc,pr) in want.items():
    if k not in d: ok=False; why.append(f"{k} missing"); continue
    e = d[k]
    if e[1]!=fid or e[2]!=cc: ok=False; why.append(f"{k} id/cc {e[1]}/{e[2]}")
    if f"priority: {pr}" not in e[5]: ok=False; why.append(f"{k} priority!= {pr}")
    if "globalMerge: false" not in e[5]: ok=False; why.append(f"{k} globalMerge")
    if k in ("estonia","panama") and "plainYearSeasons: true" not in e[5]: ok=False; why.append(f"{k} plainYear")
    if k=="honduras" and 'espnSlug: "hon.1"' not in e[5]: ok=False; why.append(f"{k} espnSlug")
    if k in ("estonia","panama") and "espnSlug" in e[5]: ok=False; why.append(f"{k} espnSlug must be absent")
print("0" if ok else ";".join(why))
PY
)
[ "$A1" = "0" ] && ok "A1 LEAGUES parses to exactly 38 entries (36 since 469 + the 474 ledger HEAD argentina 112 + the 479 registry head guatemala 336); estonia=248/EST/34, honduras=337/HON/35 (espnSlug hon.1), panama=9039/PAN/36; all globalMerge:false; plainYearSeasons only on estonia+panama" || bad "A1 catalog" "$A1"
A2=$(python3 - <<'PY'
s = open('src/lib/leagues.ts', encoding='utf-8').read()
fa = {"estonia": "لیگ برتر استونی", "honduras": "لیگ ملی هندوراس — آپرتورا", "panama": "لیگ فوتبال پاناما — آپرتورا"}
nm = {"estonia": '"premium liiga|EST": "لیگ برتر استونی"',
      "honduras": '"liga nacional - apertura|HON": "لیگ ملی هندوراس — آپرتورا"',
      "panama": '"lpf apertura|PAN": "لیگ فوتبال پاناما — آپرتورا"'}
bad = []
for k, v in fa.items():
    if f'faName: "{v}"' not in s: bad.append(f"{k} faName")
    if nm[k] not in s: bad.append(f"{k} name-map")
print("0" if not bad else ";".join(bad))
PY
)
[ "$A2" = "0" ] && ok "A2 the three faNames are byte-identical to the ALREADY-SHIPPED name-map values (the day feed and the league pages never disagree)" || bad "A2 faName" "$A2"
A3=$(python3 -c "
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
need = ['\"apertura - eastern\": \"آپرتورا — شرقی\"', '\"apertura - western\": \"آپرتورا — غربی\"', '\"clausura - eastern\": \"کلاسورا — شرقی\"', '\"clausura - western\": \"کلاسورا — غربی\"']
miss = [x for x in need if x not in s]
print('0' if not miss else miss)")
[ "$A3" = "0" ] && ok "A3 COMPOSITE_REGION_FA carries the four PAN zone labels (no raw Latin on the composite standings page)" || bad "A3 zone labels" "$A3"
A4=$(python3 -c "
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
v4 = 'teamStandingsRow:v4:' in s
v3 = 'teamStandingsRow:v3:' in s
print('0' if (v4 and not v3) else f'v4={v4} v3_still_present={v3}')")
[ "$A4" = "0" ] && ok "A4 the walk cache bumped teamStandingsRow past the 474 v3 (currently v4 per the 479 registry head guatemala 336 — stale pre-registration negatives cannot survive the deploy)" || bad "A4 cache bump" "$A4"

echo "== B. the standings APIs + the witness sweep =="
api() { curl -s --max-time 90 "$BASE/api/standings?league=$1"; }
B1=$(api estonia | python3 -c "
import json,sys
d=json.load(sys.stdin)
rows=d.get('rows') or []
ok = len(rows)==10 and (d.get('allSeasons') or [''])[0]=='2026' and len(d.get('allSeasons') or [])==12 and d.get('color')=='#212121' and (rows[0] or {}).get('pts')==90
print('0' if ok else f'rows={len(rows)} seasons={d.get(\"allSeasons\")} color={d.get(\"color\")}')")
[ "$B1" = "0" ] && ok "B1 /api/standings?league=estonia: 10 rows, 12 plain-year seasons ('2026' first — the 382 flag live), color #212121, leader 90 pts (FCI Levadia, the final 2026 table)" || bad "B1 estonia api" "$B1"
B2=$(api honduras | python3 -c "
import json,sys
d=json.load(sys.stdin)
rows=d.get('rows') or []
ok = len(rows)==12 and d.get('allSeasons') is None and d.get('selectedSeason')=='2026/2027 - Apertura' and d.get('color')=='#7ABD46'
print('0' if ok else f'rows={len(rows)} seasons={d.get(\"allSeasons\")} selected={d.get(\"selectedSeason\")}')")
[ "$B2" = "0" ] && ok "B2 /api/standings?league=honduras: 12 live Apertura rows, allSeasons honestly absent (the suffixed shape admits none — the cycle-55 selector hides), selectedSeason the payload's own" || bad "B2 honduras api" "$B2"
B3=$(api panama | python3 -c "
import json,sys
d=json.load(sys.stdin)
rows=d.get('rows') or []
g=d.get('groups') or []
fa=[x.get('fa') for x in g]
ok = len(rows)==24 and len(g)==4 and fa==['آپرتورا — شرقی','آپرتورا — غربی','کلاسورا — شرقی','کلاسورا — غربی'] and len(d.get('allSeasons') or [])==11
print('0' if ok else f'rows={len(rows)} groups={fa} seasons={len(d.get(\"allSeasons\") or [])}')")
[ "$B3" = "0" ] && ok "B3 /api/standings?league=panama: 24 flattened composite rows, the FOUR zone groups Persian (آپرتورا/کلاسورا — شرقی/غربی), 11 mixed seasons" || bad "B3 panama api" "$B3"
B4=$(python3 - <<'PY'
import json, subprocess
BASE="http://localhost:3000"
# the five EST 468 witnesses — the FINAL 2026 table, so rank/pts are stable;
# tuple = (the team's own fa, expected rank, expected pts)
exp = {"1588": ("لوادیا تالین",1,90), "4146": ("کورساره",9,36), "4147": ("تامکا",5,53),
       "112484": ("نومه کالیو",4,60), "828265": ("پارنو واپروس",8,37)}
bad=[]
for t,(teamfa,rank,pts) in exp.items():
    d=json.loads(subprocess.run(["curl","-s","--max-time","90",f"{BASE}/api/team/{t}"],capture_output=True,text=True,timeout=120).stdout)
    st=d.get("standings")
    if not st: bad.append(f"{t} no standings"); continue
    if (d.get("team") or {}).get("fa")!=teamfa: bad.append(f"{t} team={(d.get('team') or {}).get('fa')}")
    elif st.get("leagueKey")!="estonia": bad.append(f"{t} key={st.get('leagueKey')}")
    elif st.get("leagueFa")!="لیگ برتر استونی": bad.append(f"{t} leagueFa={st.get('leagueFa')}")
    elif st.get("rank")!=rank or st.get("pts")!=pts: bad.append(f"{t} rank/pts={st.get('rank')}/{st.get('pts')}!={rank}/{pts}")
print("0" if not bad else ";".join(bad))
PY
)
[ "$B4" = "0" ] && ok "B4 the five EST witnesses (1588/4146/4147/112484/828265): standings rows live from the registered league — لوادیا تالین رتبه ۱ با ۹۰ امتیاز, every rank/pts byte-matching the probed final table" || bad "B4 est witnesses" "$B4"
B5=$(python3 - <<'PY'
import json, subprocess
BASE="http://localhost:3000"
# live tables — assert the league line + a sane rank, never exact pts
exp = {"1384118": ("لیگ ملی هندوراس — آپرتورا","honduras",12),
       "2096910": ("لیگ ملی هندوراس — آپرتورا","honduras",12),
       "165476": ("لیگ فوتبال پاناما — آپرتورا","panama",24),
       "101614": ("لیگ خلیج فارس ایران","persiangulf",None)}
bad=[]
for t,(fa,key,maxr) in exp.items():
    d=json.loads(subprocess.run(["curl","-s","--max-time","90",f"{BASE}/api/team/{t}"],capture_output=True,text=True,timeout=120).stdout)
    st=d.get("standings")
    if not st: bad.append(f"{t} no standings"); continue
    if st.get("leagueFa")!=fa or st.get("leagueKey")!=key: bad.append(f"{t} league={st.get('leagueFa')}/{st.get('leagueKey')}")
    elif maxr and not (1 <= st.get("rank",0) <= maxr): bad.append(f"{t} rank out of range={st.get('rank')}")
print("0" if not bad else ";".join(bad))
PY
)
[ "$B5" = "0" ] && ok "B5 the HON witnesses (1384118 اولانچو / 2096910 استریا روخا) + PAN witness (165476 پلازا آمادور) carry their Persian league lines with sane live ranks; the control /team/101614 استقلال unchanged (persiangulf)" || bad "B5 hon/pan witnesses" "$B5"

echo "== C. the visible DOM (agent-browser 390×844) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
teamcheck() {  # url, needle, forbidden -> "vis,fb,sw,vw,h1"
  $AB console --clear >/dev/null 2>&1
  $AB open "$BASE$1" >> "$OUT" 2>&1
  sleep 5
  $AB eval "(()=>{const b=document.body.innerText;const de=document.documentElement;return JSON.stringify({vis:b.includes('$2'),fb:b.includes('اطلاعات لیگ یافت نشد'),sw:de.scrollWidth,vw:window.innerWidth,h1:(document.querySelector('h1')||{}).textContent||''})})()" 2>/dev/null
}
C1=$(teamcheck "/team/1588" "لیگ برتر استونی")
V=$(abf "$C1" vis); FB=$(abf "$C1" fb); SW=$(abf "$C1" sw); VW=$(abf "$C1" vw); H1=$(abf "$C1" h1)
echo "   /team/1588: vis=$V fallback=$FB sw=$SW h1=$H1"
[ "$V" = "True" ] && [ "$FB" = "False" ] && [ "$SW" = "390" ] && [ "$VW" = "390" ] && ok "C1 /team/1588 لوادیا تالین: the «لیگ برتر استونی · رتبه ۱ با ۹۰ امتیاز» line VISIBLE at 390×844, the «اطلاعات لیگ یافت نشد» fallback GONE, no overflow" || bad "C1 levadia dom" "vis=$V fb=$FB sw=$SW h1=$H1"
C2=$(teamcheck "/team/1384118" "لیگ ملی هندوراس — آپرتورا")
V2=$(abf "$C2" vis); FB2=$(abf "$C2" fb)
echo "   /team/1384118: vis=$V2 fallback=$FB2"
[ "$V2" = "True" ] && [ "$FB2" = "False" ] && ok "C2 /team/1384118 اولانچو: the «لیگ ملی هندوراس — آپرتورا» line visible, fallback gone (the 468 witness #2 fixed)" || bad "C2 olancho dom" "vis=$V2 fb=$FB2"
C3=$(teamcheck "/team/165476" "لیگ فوتبال پاناما — آپرتورا")
V3=$(abf "$C3" vis); FB3=$(abf "$C3" fb)
echo "   /team/165476: vis=$V3 fallback=$FB3"
[ "$V3" = "True" ] && [ "$FB3" = "False" ] && ok "C3 /team/165476 پلازا آمادور: the «لیگ فوتبال پاناما — آپرتورا» line visible, fallback gone" || bad "C3 plazam dom" "vis=$V3 fb=$FB3"
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/league/panama" >> "$OUT" 2>&1
sleep 7
C4=$($AB eval "(()=>{const b=document.body.innerText;const de=document.documentElement;return JSON.stringify({fa:['آپرتورا — شرقی','آپرتورا — غربی','کلاسورا — شرقی','کلاسورا — غربی'].every(x=>b.includes(x)),leak:b.includes('Apertura - Eastern')||b.includes('Clausura - Western'),plaza:b.includes('پلازا آمادور'),sw:de.scrollWidth})})()" 2>/dev/null)
FA=$(abf "$C4" fa); LEAK=$(abf "$C4" leak); PLAZA=$(abf "$C4" plaza); SW4=$(abf "$C4" sw)
echo "   /league/panama: faGroups=$FA latinLeak=$LEAK plaza=$PLAZA sw=$SW4"
[ "$FA" = "True" ] && [ "$LEAK" = "False" ] && [ "$PLAZA" = "True" ] && ok "C4 /league/panama: all four zone groups render Persian (آپرتورا — شرقی…), zero raw Latin zone leak, the harvested club پلازا آمادور visible in the live table" || bad "C4 panama page" "fa=$FA leak=$LEAK plaza=$PLAZA sw=$SW4"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$CE" = "0" ] && [ "$PE" = "0" ] && ok "C5 console + page errors 0 on the panama league page (the new composite surface clean)" || bad "C5 console" "console=$CE page=$PE"

echo "== D. fresh home (the 434 mount-gate) =="
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

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
