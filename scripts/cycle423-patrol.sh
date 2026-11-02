#!/usr/bin/env bash
# cycle423-patrol.sh — bug-hunt cycle 423 (فرمول ۴): the post-ICS-ladder
# patrol. The 413/418 precedent: findings ONLY (fixes belong to the next
# cycle); zero source changes → the server stays on the official 422
# build (no rebuild). Scope:
#   A  the API inventory (30 JSON endpoints + the designed non-JSON
#      contracts: 4 ICS routes, 2 og images, rss/sitemap/robots/manifest)
#   B  the 16-page DOM sweep at 390x844 (hygiene three-pack per page)
#   C  the recent-cycle holds RE-ASSERTED with REAL interactions:
#      422 home CTA href == shown day (+ the ?date= deep link), 421 match
#      CTA, 420 team CTA (lazy poll), 419 season selector (native select
#      setter+change), 416 fee chip real click, 412 «اطلاعات» click with
#      the Persian venue/city/referee flip, 414 news mixed-script guard,
#      and the ICS family freshness (match single / team 53 / day == feed)
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s --max-time 30 -A "$UA" "$BASE$1"; }
code() { curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE$1" --max-time 25; }

echo "================ A: the API inventory ================"
# A1: every JSON endpoint answers 200 + parses + is not an {ok:false} body
D8=$(api "/api/matches?offset=0" | python3 -c "import json,sys; print(json.load(sys.stdin).get('date',''))" 2>/dev/null)
D=${D8:0:4}-${D8:4:2}-${D8:6:2}
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
  OUT=$(api "$EP" --max-time 25)
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
# A1b: the designed honest-400 contract (the cycle-183 lesson): ?league= on
# /api/topscorers is a PATH segment — the param must 400 with the hint
TSC=$(api "/api/topscorers?league=pl")
ck "A1b topscorers ?league= designed-400 with path hint" "$(printf '%s' "$TSC" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(1 if d.get('ok') is False and 'topscorers/pl' in (d.get('error') or '') else 0)
except Exception:
    print(0)
")"
# A2: the negative guards of the newest surfaces still honest
C1=$(code "/api/day-calendar?date=2026-02-30"); C2=$(code "/api/match-calendar/abc"); C3=$(code "/api/match-calendar/999999999")
ck "A2 guards (day 400 impossible / match 400 shape / 404 unknown)" "$([ "$C1$C2" = "400400" ] && [ "$C3" = "404" ] && echo 1 || echo 0)"
# A3: the designed non-JSON contracts
ICS_OK=0
for CT in "/api/league-calendar?league=pl" "/api/team-calendar/8456" "/api/match-calendar/5795503" "/api/day-calendar?date=$D"; do
  T=$(curl -s -o /dev/null -w '%{content_type}' -A "$UA" "$BASE$CT" --max-time 25)
  [ "${T#*text/calendar}" != "$T" ] && ICS_OK=$((ICS_OK+1))
done
ck "A3 four ICS routes text/calendar" "$([ "$ICS_OK" = "4" ] && echo 1 || echo 0)"
OG1=$(curl -s -o /dev/null -w '%{content_type}' -A "$UA" "$BASE/api/og/pl" --max-time 20)
OG2=$(curl -s -o /dev/null -w '%{content_type}' -A "$UA" "$BASE/api/og/person/78626" --max-time 20)
ck "A4 og league+person image/png" "$([ "${OG1#*image/png}" != "$OG1" ] && [ "${OG2#*image/png}" != "$OG2" ] && echo 1 || echo 0)"
ST=$(code "/rss.xml"); SM=$(code "/sitemap.xml"); RB=$(code "/robots.txt"); MF=$(code "/manifest.webmanifest")
ck "A5 rss/sitemap/robots/manifest 200" "$([ "$ST$SM$RB$MF" = "200200200200" ] && echo 1 || echo 0)"
# A6: the 414 news guard — zero defective mixed-script titles
api "/api/news" > /tmp/c423-news.json
api "/api/matches?offset=0" > /tmp/c423-feed0.json
curl -s -o /tmp/c423-m.ics -A "$UA" "$BASE/api/match-calendar/5795503" --max-time 25
api "/api/team-calendar/8456" > /tmp/c423-t.ics
curl -s -o /tmp/c423-d.ics -A "$UA" "$BASE/api/day-calendar?date=$D" --max-time 25
ck "A6 414 news guard (16 rows, zero defective)" "$(python3 - <<'PY'
import json, re
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}'); wl = re.compile(r'\b(VAR|xG)\b')
defective = lambda t: bool(fa.search(t)) and bool(lat.search(wl.sub("", t)))
try:
    d = json.load(open("/tmp/c423-news.json"))
    items = d.get("items") or []
    print(1 if d.get("ok") and len(items) == 16 and not any(defective(it.get("titleFa") or "") for it in items) else 0)
except Exception:
    print(0)
PY
)"
# A7: ICS family freshness — match single / team 53 / day == feed count
ck "A7 ICS family freshness (match=1 / team=53 / day==feed)" "$(python3 - <<'PY'
import json

def unfold(path):
    raw = open(path, "rb").read().decode("utf-8")
    phys = raw.split("\r\n")
    out = []
    for ln in phys:
        if ln.startswith(" ") and out:
            out[-1] += ln[1:]
        else:
            out.append(ln)
    return [l for l in out if l != ""]

def ve(path):
    return sum(1 for l in unfold(path) if l.startswith("BEGIN:VEVENT"))

def ok(path, want):
    try:
        return ve(path) == want
    except Exception:
        return False

try:
    feed = json.load(open("/tmp/c423-feed0.json"))
    fc = sum(len(g.get("matches") or []) for g in (feed.get("groups") or []))
    print(1 if ok("/tmp/c423-m.ics", 1) and ok("/tmp/c423-t.ics", 53) and fc > 0 and ok("/tmp/c423-d.ics", fc) else 0)
except Exception:
    print(0)
PY
)"

echo "================ B: the 16-page DOM sweep (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
PAGES=( "/" "/?date=2026-11-03" "/leagues" "/league/pl" "/league/hazfi" "/league/ucl" "/topscorers" "/topscorers/pl" "/team/8456" "/team/8668" "/match/5795503" "/player/696679" "/news" "/transfers" "/search?q=%D8%B1%D8%A6%D8%A7%D9%84" "/coach/78626" )
DIRTY=0; SWEEPLOG=""
for P in "${PAGES[@]}"; do
  agent-browser open "$BASE$P" >/dev/null 2>&1
  sleep 4
  E=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CN=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  BADP=0
  { [ -n "$E" ] && [ "$E" != "0" ]; } && BADP=1
  [ "$CN" != "0" ] && BADP=1
  [ "$SW" != "390" ] && BADP=1
  if [ "$BADP" = "1" ]; then DIRTY=$((DIRTY+1)); SWEEPLOG="$SWEEPLOG  !! $P → errors='$E' consoleErr=$CN scrollW=$SW"$'\n'; fi
done
ck "B1 all ${#PAGES[@]} pages hygiene-clean (dirty=$DIRTY)" "$([ "$DIRTY" = "0" ] && echo 1 || echo 0)"
[ -n "$SWEEPLOG" ] && echo "$SWEEPLOG"

echo "================ C: the recent holds, real interactions ================"
# C1+C2 (422): the home CTA href == the shown day, then the deep link drives it
agent-browser open "$BASE/" >/dev/null 2>&1
H1=0; HHREF=""
for i in $(seq 1 12); do
  sleep 1
  R=$(agent-browser eval "var a=document.querySelector('[data-testid=\"home-day-ics-link\"]'); a? (a.getAttribute('href')||'')+'|1' : '|0'" 2>/dev/null | tr -d '"')
  if [ "${R##*|}" = "1" ]; then H1=1; HHREF=${R%%|*}; break; fi
done
ck "C1 422 home CTA present, href day == feed day" "$([ "$H1" = "1" ] && [ "$HHREF" = "/api/day-calendar?date=$D" ] && echo 1 || echo 0)"
agent-browser open "$BASE/?date=2026-11-03" >/dev/null 2>&1
H2=0
for i in $(seq 1 12); do
  sleep 1
  R=$(agent-browser eval "var a=document.querySelector('[data-testid=\"home-day-ics-link\"]'); a? (a.getAttribute('href')||'')+'|1' : '|0'" 2>/dev/null | tr -d '"')
  if [ "${R##*|}" = "1" ]; then [ "${R%%|*}" = "/api/day-calendar?date=2026-11-03" ] && H2=1; break; fi
done
ck "C2 422 deep-link ?date=2026-11-03 drives CTA" "$H2"
# C3 (421): the match CTA server-rendered with the exact href
agent-browser open "$BASE/match/5795503" >/dev/null 2>&1
sleep 5
M=$(agent-browser eval "var a=document.querySelector('[data-testid=\"match-ics-link\"]'); a&&a.getAttribute('href')==='/api/match-calendar/5795503'?1:0" 2>/dev/null | tr -d '"')
ck "C3 421 match CTA href exact" "$M"
# C4 (420): the team CTA on the lazy fixtures-all section
agent-browser open "$BASE/team/8456" >/dev/null 2>&1
T=0
for i in $(seq 1 8); do
  sleep 1
  X=$(agent-browser eval "document.querySelector('[data-testid=\"team-ics-link\"]')?1:0" 2>/dev/null | tr -d '"')
  [ "$X" = "1" ] && { T=1; break; }
done
ck "C4 420 team CTA (lazy poll)" "$T"
# C5 (419): REAL native-select season interaction on /league/pl
agent-browser open "$BASE/league/pl" >/dev/null 2>&1
sleep 5
S=$(agent-browser eval "var s=document.querySelector('select'); if(!s){'0'} else {var st=Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype,'value').set; st.call(s,'2024/2025'); s.dispatchEvent(new Event('change',{bubbles:true})); '1'}" 2>/dev/null | tr -d '"')
sleep 3
URL=$(agent-browser eval "location.search" 2>/dev/null | tr -d '"')
ck "C5 419 season select real interaction → URL ?season=" "$([ "$S" = "1" ] && echo "$URL" | grep -q "season=2024" && echo 1 || echo 0)"
# C6 (416): REAL fee-chip click on /transfers
agent-browser open "$BASE/transfers" >/dev/null 2>&1
sleep 5
F=$(agent-browser eval "var chips=[...document.querySelectorAll('[role=\"tab\"]')]; var c=chips.find(function(x){return x.innerText.indexOf('۵۰ میلیون')>=0}); if(!c){'0'} else {c.click(); '1'}" 2>/dev/null | tr -d '"')
sleep 3
FEE=$(agent-browser eval "document.body.innerText.indexOf('کارمزد')>=0?1:0" 2>/dev/null | tr -d '"')
ck "C6 416 fee chip real click → fee rows" "$([ "$F" = "1" ] && [ "$FEE" = "1" ] && echo 1 || echo 0)"
# C7 (412): REAL «اطلاعات» click on the match page → Persian venue/city/referee
agent-browser open "$BASE/match/5795503" >/dev/null 2>&1
sleep 5
I=$(agent-browser eval "var bs=[...document.querySelectorAll('button')]; var b=bs.find(function(x){return (x.innerText||'').indexOf('اطلاعات')>=0}); if(!b){'0'} else {b.click(); '1'}" 2>/dev/null | tr -d '"')
sleep 3
V=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('سنت جیمز')>=0?1:0)+'|'+((t.indexOf('نیوکاسل')>=0)?1:0)" 2>/dev/null | tr -d '"')
V1=${V%%|*}
ck "C7 412 venue Persian flip after real click" "$([ "$I" = "1" ] && [ "$V1" = "1" ] && echo 1 || echo 0)"

echo "================ D: scope + health ================"
H=$(curl -s -o /dev/null -w '%{http_code}' "$BASE" --max-time 10)
ck "D1 health 200" "$([ "$H" = "200" ] && echo 1 || echo 0)"
SRCN=$(git -C /home/z/my-project/remontada status --porcelain -- src | wc -l)
ck "D2 zero src changes (bug-hunt reports, fixes next cycle)" "$([ "$SRCN" = "0" ] && echo 1 || echo 0)"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE423 PATROL OK" || echo "CYCLE423 PATROL FINDINGS"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
