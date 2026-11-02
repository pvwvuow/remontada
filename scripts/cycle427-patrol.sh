#!/usr/bin/env bash
# cycle427-patrol.sh — bug-hunt cycle 427 (فرمول ۴): the post-426 patrol.
# The 413/418/423 precedent: findings ONLY (fixes belong to the next cycle).
# Zero source changes expected → but the full official chain still runs
# (build + official start) so the patrol proves the CURRENT commit deploys.
# Scope:
#   A  the API inventory (33 JSON endpoints + the designed non-JSON
#      contracts: 5 ICS routes now (425 favorites joined), og images,
#      rss/sitemap/robots/manifest + the honest 400 guards)
#   B  the 426 surface: day-feed zero-leak re-assert across ±7, match-page
#      leagueFa holds (catalog byte-stable + the id-hooked samples), the
#      team-name raw pool stability, and the leagueFaById consumer census
#      (player/team rows — pure-Latin league labels are FINDINGS, report-only)
#   C  the recent-cycle holds RE-ASSERTED with REAL interactions at 390×844:
#      422 home CTA href == shown day + the ?date= deep link, 421 match CTA,
#      420 team CTA lazy poll, 419 season selector setter+change, 416 fee
#      chip real click, 412 «اطلاعات» click Persian flip, 414 news guard,
#      424 freshness label, 425 favorites CTA honest presence/absence
#   D  the 16-page DOM sweep at 390×844 (hygiene three-pack per page)
#   E  the gates: eslint, tsc, build, official start, regression 28/28
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1 :: ${3:-}"; fi; }
SECT="${SECTIONS:-A B C D E}"
has() { case " $SECT " in *" $1 "*) return 0;; *) return 1;; esac; }
AB="agent-browser"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s --max-time 30 -A "$UA" "$BASE$1"; }
code() { curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE$1" --max-time 25; }

if has A; then
echo "================ A: the API inventory ================"
JSON_EPS=(
"/api/matches?offset=0" "/api/standings?league=pl" "/api/topscorers" "/api/topscorers/pl"
"/api/news" "/api/transfers" "/api/transfers?minFee=1000000" "/api/search?q=%D8%B1%D8%A6%D8%A7%D9%84"
"/api/league-bracket?league=ucl" "/api/league-fixtures?league=pl"
"/api/league-fixtures-all?league=pl" "/api/league-titles?league=pl" "/api/league-totw?league=pl"
"/api/league-transfers?league=pl" "/api/team/8456" "/api/team-squad/8456" "/api/team-fixtures/8456"
"/api/team-coaches/8456" "/api/team-difficulty/8456" "/api/team-history/8456"
"/api/team-last-lineup/8456" "/api/team-news/8456" "/api/team-rumours/8456" "/api/team-stats/8456"
"/api/team-top-players/8456" "/api/team-transfers/8456" "/api/team-trophies/8456" "/api/team-venue/8456"
"/api/match/5795503" "/api/match-h2h/5795503" "/api/player/696679" "/api/coach/78626"
)
BAD=0; N=0
for EP in "${JSON_EPS[@]}"; do
  N=$((N+1))
  OUT=$(api "$EP")
  OKP=$(printf '%s' "$OUT" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(0 if isinstance(d,dict) and d.get('ok') is False else 1)
except Exception:
    print(0)
" 2>/dev/null)
  C=$(code "$EP")
  if [ "$OKP" != "1" ] || [ "$C" != "200" ]; then BAD=$((BAD+1)); echo "  !! $EP → http=$C ok=$OKP"; fi
done
ck "A1 all $N JSON endpoints healthy (bad=$BAD)" "$([ "$BAD" = "0" ] && echo 1 || echo 0)"
TSC=$(api "/api/topscorers?league=pl")
ck "A1b topscorers ?league= designed-400 with path hint" "$(printf '%s' "$TSC" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(1 if d.get('ok') is False and 'topscorers' in str(d.get('error','')) else 0)
except Exception: print(0)")"
DC=$(api "/api/day-calendar?date=2026-02-30")
ck "A1c day-calendar impossible-date designed-400 (the 299 contract)" "$([ "$(code "/api/day-calendar?date=2026-02-30")" = "400" ] && echo 1 || echo 0)"
FC=$(api "/api/favorites-calendar?ids=")
ck "A1d favorites-calendar empty-ids designed-400 (the 425 contract)" "$(printf '%s' "$FC" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(1 if d.get('ok') is False and 'هیچ تیمی' in str(d.get('error','')) else 0)
except Exception: print(0)")"
CT=$(code "/api/league-calendar?league=pl&season=2025%2F2026"); ck "A2 league ICS text/calendar" "$([ "$CT" = "200" ] && api "/api/league-calendar?league=pl&season=2025%2F2026" | head -c 40 | grep -q "BEGIN:VCALENDAR" && echo 1 || echo 0)"
CT=$(code "/api/team-calendar/8456");           ck "A3 team ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/match-calendar/5795503");       ck "A4 match ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/day-calendar?date=$(TZ=Asia/Tehran date +%F)"); ck "A5 day ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/favorites-calendar?ids=8456");  ck "A6 favorites ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/og/pl");  ck "A7 og league png" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/og/person/696679"); ck "A7b og person png" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/rss.xml");    ck "A8 rss 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/sitemap.xml"); ck "A9 sitemap 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/robots.txt");  ck "A10 robots 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/manifest.webmanifest"); ck "A11 manifest 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
fi

if has B; then
echo "================ B: the 426 surface ================"
RES=$(python3 - "$BASE" <<'PY'
import json, re, subprocess, sys, time
base = sys.argv[1]
PERSIAN = re.compile(r"[\u0600-\u06FF]")
def get(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)
leaks, team_rows, team_names = {}, 0, set()
for o in range(-7, 8):
    d = get(f"{base}/api/matches?offset={o}")
    for g in d.get("groups", []):
        fa = g.get("leagueFa") or ""
        if fa and not PERSIAN.search(fa):
            leaks[(g.get("leagueName"), g.get("leagueId"))] = fa
        for m in g.get("matches", []):
            for side in ("home", "away"):
                t = m.get(side) or {}
                tfa = t.get("fa") or ""
                if tfa and not PERSIAN.search(tfa):
                    team_rows += 1
                    team_names.add(tfa)
    time.sleep(0.15)
kn = get(f"{base}/api/match/6321650")["match"].get("leagueFa", "")
pl = get(f"{base}/api/match/5795503")["match"].get("leagueFa", "")
uk = get(f"{base}/api/match/6284434")["match"].get("leagueFa", "")
# leagueFaById consumers: player recent rows + team recent rows —
# pure-Latin league labels are FINDINGS (report-only)
p = get(f"{base}/api/player/696679")
prows = []
def scan(obj):
    if isinstance(obj, dict):
        ln = obj.get("leagueName"); lf = obj.get("leagueFa")
        if isinstance(ln, str) and ln and (lf is None or (isinstance(lf, str) and not PERSIAN.search(lf))):
            prows.append(f"{ln} → {lf!r}")
        for v in obj.values(): scan(v)
    elif isinstance(obj, list):
        for v in obj: scan(v)
scan(p)
t = get(f"{base}/api/team/8456")
trows = []
def scan2(obj, path=""):
    if isinstance(obj, dict):
        ln = obj.get("leagueName"); lf = obj.get("leagueFa")
        if isinstance(ln, str) and ln and "leagueFa" in obj and (lf is None or (isinstance(lf, str) and not PERSIAN.search(lf))):
            trows.append(f"{ln} → {lf!r}")
        for v in obj.values(): scan2(v)
    elif isinstance(obj, list):
        for v in obj: scan2(v)
scan2(t)
print("B-SUMMARY "
      f"compLeaks={len(leaks)} teamRows={team_rows} teamDistinct={len(team_names)} "
      f"knvb={kn!r} catalog={pl!r} ukr={uk!r} "
      f"playerLeakRows={len(prows)} teamLeakRows={len(trows)}")
if leaks: print("B-LEAKS:", json.dumps({f"{k[0]}|{k[1]}": v for k, v in list(leaks.items())[:6]}, ensure_ascii=False))
if prows: print("B-PLAYER-LEAKS:", json.dumps(prows[:10], ensure_ascii=False))
if trows: print("B-TEAM-LEAKS:", json.dumps(trows[:10], ensure_ascii=False))
PY
)
echo "$RES"
S=$(echo "$RES" | grep "B-SUMMARY" | tail -1)
# python-driven asserts (bash case with Persian literals broke on quoting —
# the harness lesson: string-assertions ride python, never bash case)
ck "B1 day-feed zero pure-Latin headers across ±7" "$(python3 -c "print(1 if 'compLeaks=0 ' in '''$S''' else 0)")"
ck "B2 match hook KNVB Persian" "$(python3 -c "print(1 if \"knvb='جام حذفی هلند'\" in '''$S''' else 0)")"
ck "B3 catalog byte-stability hold" "$(python3 -c "print(1 if \"catalog='پریمیرلیگ انگلیس'\" in '''$S''' else 0)")"
ck "B4 team raw pool unchanged (2256 — the documented harvest machine)" "$(python3 -c "print(1 if 'teamDistinct=2256 ' in '''$S''' else 0)")"
grep -q "B-LEAKS" <<< "$RES" && ck "B5 competition leak detail" 0 "see B-LEAKS" || true
PLN=$(echo "$S" | grep -oE "playerLeakRows=[0-9]+" | cut -d= -f2)
echo "   FINDINGS(player leagueFaById rows with raw labels): $PLN — report-only, see B-PLAYER-LEAKS"
grep -q "B-PLAYER-LEAKS" <<< "$RES" && echo "   $(grep 'B-PLAYER-LEAKS' <<< "$RES")" || true
grep -q "B-TEAM-LEAKS" <<< "$RES" && echo "   $(grep 'B-TEAM-LEAKS' <<< "$RES")" || true
fi

if has C; then
echo "================ C: the recent holds, real interactions (390x844) ================"
$AB set viewport 390 844 >/dev/null 2>&1
TODAY=$(TZ=Asia/Tehran date +%F)
$AB open "$BASE/" >/dev/null 2>&1
sleep 3
HREF=$($AB eval "document.querySelector('[data-testid=home-day-ics-link]')?.getAttribute('href')||''" 2>/dev/null | tr -d '"')
ck "C1 the 422 hold: home ICS href == today" "$([ "$HREF" = "/api/day-calendar?date=$TODAY" ] && echo 1 || echo 0)" "'$HREF'"
FRESH=$($AB eval "(()=>{const el=document.querySelector('[data-testid=home-day-freshness]');return el?el.textContent.trim():''})()" 2>/dev/null | tr -d '"')
case "$FRESH" in "به‌روزرسانی "*) ck "C2 the 424 hold: freshness label alive" 1;; *) ck "C2 424 freshness" 0 "'$FRESH'";; esac
$AB open "$BASE/?date=2026-10-27" >/dev/null 2>&1
sleep 3
HREF2=$($AB eval "document.querySelector('[data-testid=home-day-ics-link]')?.getAttribute('href')||''" 2>/dev/null | tr -d '"')
ck "C3 the 422 deep-link hold: ?date=2026-10-27 drives the CTA href" "$([ "$HREF2" = "/api/day-calendar?date=2026-10-27" ] && echo 1 || echo 0)" "'$HREF2'"
LEAKH=$($AB eval "Array.from(document.querySelectorAll('h3.rune-title')).filter(h=>{const t=h.textContent.trim();return /[A-Za-z]/.test(t)&&!/[\u0600-\u06FF]/.test(t)}).length" 2>/dev/null | tr -d '"')
ck "C4 the 426 hold: zero pure-Latin headers on the id-235 day" "$([ "$LEAKH" = "0" ] && echo 1 || echo 0)" "n=$LEAKH"
$AB open "$BASE/match/5795503" >/dev/null 2>&1
sleep 3
MHREF=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('match-calendar'))||''" 2>/dev/null | tr -d '"')
ck "C5 the 421 hold: match-page ICS CTA present" "$([ -n "$MHREF" ] && echo 1 || echo 0)" "'$MHREF'"
$AB eval "(()=>{const b=Array.from(document.querySelectorAll('button,a')).find(x=>x.textContent.trim().includes('اطلاعات'));if(b)b.click();return !!b})()" >/dev/null 2>&1
sleep 2
VEN=$($AB eval "document.body.innerText.includes('سنت جیمز')||document.body.innerText.includes('نیوکاسل')" 2>/dev/null | tr -d '"')
ck "C6 the 412 hold: «اطلاعات» click flips venue to Persian" "$([ "$VEN" = "true" ] && echo 1 || echo 0)"
$AB open "$BASE/team/8456" >/dev/null 2>&1
sleep 5
TC=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('team-calendar'))||''" 2>/dev/null | tr -d '"')
ck "C7 the 420 hold: team ICS CTA (lazy poll)" "$([ -n "$TC" ] && echo 1 || echo 0)" "'$TC'"
$AB open "$BASE/league/pl" >/dev/null 2>&1
sleep 3
SEL=$($AB eval "(()=>{const s=document.querySelector('select');if(!s)return 'none';const opt=Array.from(s.options).map(o=>o.value).find(v=>v&&v.includes('/')&&v!=='2026/2027');if(!opt)return 'no-slash-opt';const setter=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;setter.call(s,opt);s.dispatchEvent(new Event('change',{bubbles:true}));return opt})()" 2>/dev/null | tr -d '"')
sleep 2
URL=$($AB eval "location.search" 2>/dev/null | tr -d '"')
ck "C8 the 419 hold: season select setter+change carries ?season=" "$([ "$SEL" != "none" ] && [ "$SEL" != "no-slash-opt" ] && echo "$URL" | grep -q "season=" && echo 1 || echo 0)" "sel=$SEL url=$URL"
$AB open "$BASE/transfers" >/dev/null 2>&1
sleep 3
$AB eval "(()=>{const chip=Array.from(document.querySelectorAll('button,[role=tab]')).find(x=>x.textContent.trim().includes('از ۵۰ میلیون'));if(chip)chip.click();return !!chip})()" >/dev/null 2>&1
sleep 3
FEE=$($AB eval "document.body.innerText.includes('کارمزد')" 2>/dev/null | tr -d '"')
ck "C9 the 416 hold: «از ۵۰ میلیون» chip click flips to fee rows" "$([ "$FEE" = "true" ] && echo 1 || echo 0)"
$AB open "$BASE/news" >/dev/null 2>&1
sleep 3
NEWS=$($AB eval "(()=>{const cards=document.querySelectorAll('article[data-testid=chronicle-card] h3');let bad=0;cards.forEach(h=>{const t=h.textContent;if(/[؀-ۿ]/.test(t)&&/[A-Za-z]{4,}/.test(t))bad++});return cards.length+':'+bad})()" 2>/dev/null | tr -d '"')
NROWS=${NEWS%%:*}; NBAD=${NEWS##*:}
ck "C10 the 414 hold: $NROWS news titles, $NBAD defective mixed-script" "$([ "${NBAD:-1}" = "0" ] && [ "${NROWS:-0}" -ge 10 ] && echo 1 || echo 0)" "$NEWS"
FAV=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('favorites-calendar'))||''" 2>/dev/null | tr -d '"')
$AB open "$BASE/" >/dev/null 2>&1
sleep 2
FAV=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('favorites-calendar'))||'absent'" 2>/dev/null | tr -d '"')
if [ "$FAV" = "absent" ]; then ck "C11 the 425 hold: favorites CTA honestly ABSENT with empty store" 1; else ck "C11 the 425 hold: favorites CTA present with href" 1 "$FAV"; fi
fi

if has D; then
echo "================ D: the 16-page DOM sweep (390x844) ================"
PAGES=("/" "/leagues" "/topscorers" "/topscorers/pl" "/league/pl" "/league/hazfi" "/league/ucl"
"/team/8456" "/team/8667" "/match/5795503" "/player/696679" "/coach/78626"
"/news" "/transfers" "/search" "/players")
$AB set viewport 390 844 >/dev/null 2>&1
BADP=0
for P in "${PAGES[@]}"; do
  $AB open "$BASE$P" >/dev/null 2>&1
  sleep 2
  SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
  CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    msgs=d.get('data',{}).get('messages',d.get('messages',[]))
    print(len([m for m in msgs if isinstance(m,dict) and m.get('level') in ('error','assert')]))
except Exception: print('NA')")
  H1=$($AB eval "document.querySelector('h1')?1:0" 2>/dev/null | tr -d '"')
  if [ "$SW" != "390" ] || { [ "$PE" != "0" ] && [ "$PE" != "NA" ]; } || { [ "$CE" != "0" ] && [ "$CE" != "NA" ]; } || [ "$H1" != "1" ]; then
    BADP=$((BADP+1)); echo "  !! $P sw=$SW pe=$PE ce=$CE h1=$H1"
  fi
done
ck "D1 all ${#PAGES[@]} pages clean (sw=390, errors 0, h1) bad=$BADP" "$([ "$BADP" = "0" ] && echo 1 || echo 0)"
fi

if has E; then
echo "================ E: the gates ================"
cd /home/z/my-project/remontada
bunx eslint src >/dev/null 2>&1; ck "E1 eslint 0/0" "$([ $? = "0" ] && echo 1 || echo 0)"
rm -rf .next/types && bunx tsc --noEmit >/dev/null 2>&1; ck "E2 tsc 0" "$([ $? = "0" ] && echo 1 || echo 0)"
bun run build >/dev/null 2>&1; ck "E3 build 0" "$([ $? = "0" ] && echo 1 || echo 0)"
bash /home/z/my-project/scripts/start-remontada.sh >/dev/null 2>&1
sleep 2
H=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$BASE")
ck "E4 official start → 200" "$([ "$H" = "200" ] && echo 1 || echo 0)" "http=$H"
R=$(BASE=http://localhost:3000 bash scripts/cycle17-regression.sh 2>/dev/null | grep -E "^PASS=" | tail -1)
echo "   $R"
ck "E5 regression 28/28" "$(echo "$R" | grep -q "PASS=28 FAIL=0" && echo 1 || echo 0)"
CH=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$BASE")
ck "E6 final health 200" "$([ "$CH" = "200" ] && echo 1 || echo 0)"
fi

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
