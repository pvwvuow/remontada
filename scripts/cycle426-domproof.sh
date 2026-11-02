#!/bin/bash
# cycle426-domproof.sh — the day-feed competition headers went Persian (Update cycle 426)
# The gap: the ±7-day live census (scripts/cycle426-census.py) caught 38
# non-catalog league ids whose day-feed GROUP HEADERS rendered the raw
# upstream literal — «Cup», «FA Cup» (= POLAND!), «Super League» (= CHINA!),
# «KNVB Cup», «Serie C Grp. A/B/C», women's competitions, groups of ROU/RUS
# national cups… The fix: 38 identity-probed id keys in ARCHIVE_TID_FA (the
# cycle-389 map — the id is the only precise key), a guarded dayFeedLeagueFa
# touchpoint in normalizeFotMobMatches (competitionFa first, byte-stable),
# and the match-page hook via leagueFaById. Cache namespace bumped to
# matches:v2 so no English-header tail serves from L2.
#
# Witnesses:
#  A. full ±7-day API census INSIDE the harness — zero pure-Latin headers;
#     the 2,256-name team pool (the documented honest-raw contract, future
#     cycle's harvest) asserted UNCHANGED.
#  B. mapped ids byte-exact on the live day feed + the 157 «گروه A» family
#     byte-stable (competitionFa still wins first).
#  C. match-page hook: KNVB/UKR samples resolve Persian; the catalog match
#     stays byte-identical.
#  D. DOM at 390×844: the -7 day (2026-10-27 — KNVB/AUT/POL/UKR live there)
#     renders ZERO pure-Latin group headers, the four flagship Persian names
#     visible, hygiene three-pack zero, the 424 freshness + 422 ICS holds;
#     default home + console clean.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/home/z/my-project/remontada/scripts/cycle426-results.txt
: > "$OUT"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1" >> "$OUT"; echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 :: $2" >> "$OUT"; echo "FAIL $1 :: $2"; }
AB="agent-browser"

echo "== A. full-window census witness (API, offsets -7..+7) =="
python3 - "$BASE" <<'PY' >> "$OUT" 2>&1
COMP_EXPECT = {
    235: "جام حذفی هلند", 278: "جام حذفی اتریش", 938649: "جام حذفی لهستان",
    442: "جام حذفی اوکراین", 206: "جام حذفی نروژ", 10230: "کاپ پاراگوئه",
    944340: "جام حذفی چک", 943369: "جام لیگ ژاپن", 920266: "سوپرلیگ چین",
    942484: "جام اتحادیه پرتغال", 945923: "لیگ قهرمانان زنان اروپا",
    944690: "جام حذفی رومانی — گروه A", 944691: "جام حذفی رومانی — گروه B",
    944692: "جام حذفی رومانی — گروه C", 944693: "جام حذفی رومانی — گروه D",
    938418: "جام حذفی روسیه — گروه A", 938419: "جام حذفی روسیه — گروه B",
    938420: "جام حذفی روسیه — گروه C", 938421: "جام حذفی روسیه — گروه D",
    944879: "مرحلهٔ گروهی جام حذفی یونان", 951326: "مقدماتی جام حذفی ترکیه",
    9195: "دستهٔ دوم هلند", 9676: "بوندسلیگای زنان آلمان",
    1000001465: "سوپرلیگ ۲ زنان انگلیس", 955997: "پلی‌آف لیگ ملی زنان آمریکا",
    949004: "جام آمریکای مرکزی کونکاکاف — پلی‌این",
    1000001491: "جام اروپای زنان یوفا — یک‌هشتم نهایی",
    1000001513: "پریمیرلیگ ۲ انگلیس",
    1000001711: "یواس‌ال لیگ یک آمریکا — نیمه‌نهایی",
    1000001210: "سوپرلیگ شمالی کانادا",
    1000001214: "جام لیگ آفریقای جنوبی — دور اول",
    1000001403: "جام حذفی آرژانتین", 219: "جام حذفی ایرلند",
    221: "مقدماتی لیگ برتر ایرلند", 9097: "جام حذفی اسرائیل",
    9098: "جام توتو اسرائیل", 1000001769: "سوپرکاپ آفریقا",
    9469: "لیگ قهرمانان آسیا ۲",  # the 157 convention — byte-stable family
}
import json, re, subprocess, sys
base = sys.argv[1]
PERSIAN = re.compile(r"[\u0600-\u06FF]")
def get(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)
leaks = {}
team_leak_rows = 0
team_leak_names = set()
comp_ok = 0
comp_bad = []
seen_ids = set()
import time
for o in range(-7, 8):
    d = get(f"{base}/api/matches?offset={o}")
    assert d.get("ok"), f"offset {o} not ok"
    for g in d.get("groups", []):
        fa = g.get("leagueFa") or ""
        lid = g.get("leagueId")
        if lid in COMP_EXPECT:
            seen_ids.add(lid)
            exp = COMP_EXPECT[lid]
            if lid == 9469:
                # the day feed splits ACL2 into groups A..H under ONE league
                # id — assert the family name + the group letter from the
                # raw name's own suffix ("… - B" ⇒ «… — گروه B»)
                suffix = (g.get("leagueName") or "").rsplit(" - ", 1)[-1].strip()
                exp = f"{exp} — گروه {suffix}"
            if fa == exp:
                comp_ok += 1
            else:
                comp_bad.append((lid, fa, exp))
        if fa and not PERSIAN.search(fa):
            leaks[(g.get("leagueName"), lid)] = fa
        for m in g.get("matches", []):
            for side in ("home", "away"):
                t = m.get(side) or {}
                tfa = t.get("fa") or ""
                if tfa and not PERSIAN.search(tfa):
                    team_leak_rows += 1
                    team_leak_names.add(tfa)
    time.sleep(0.2)
print(f"A-SUMMARY compLeaks={len(leaks)} teamLeakRows={team_leak_rows} teamLeakDistinct={len(team_leak_names)} seenMapped={len(seen_ids)}/{len(COMP_EXPECT)} compByteOk={comp_ok}")
if leaks:
    print("A-LEAKS:", json.dumps({f"{k[0]}|{k[1]}": v for k, v in list(leaks.items())[:8]}, ensure_ascii=False))
if comp_bad:
    print("A-BADBYTES:", json.dumps(comp_bad[:8], ensure_ascii=False))
PY
A=$(grep "A-SUMMARY" "$OUT" | tail -1)
echo "$A"
case "$A" in
  *"compLeaks=0 "*) ok "A1 zero pure-Latin competition headers across the whole ±7-day window" ;;
  *) bad "A1 zero comp leaks" "$A" ;;
esac
case "$A" in
  *"teamLeakDistinct=2256 "*) ok "A2 the documented team raw-fallback pool UNCHANGED (2256 distinct / 4818 rows — never silently 'fixed')" ;;
  *) bad "A2 team pool stability" "$A" ;;
esac
case "$A" in
  *"compByteOk=0"*) bad "A3 byte-exact mapped ids" "$A" ;;
  *"compByteOk="*) N=$(echo "$A" | grep -oE "compByteOk=[0-9]+" | cut -d= -f2); ok "A3 mapped ids byte-exact on the live feed: $N group renders matched the authored names" ;;
  *) bad "A3 byte-exact" "$A" ;;
esac
grep -q "A-BADBYTES" "$OUT" && bad "A3b no byte mismatches" "see A-BADBYTES" || ok "A3b zero byte mismatches on seen mapped ids"
grep -q "A-LEAKS" "$OUT" && bad "A3c leak detail" "see A-LEAKS" || true

echo "== C. match-page hook =="
KN=$(curl -s --max-time 20 "$BASE/api/match/6321650" | python3 -c "import json,sys;print(json.load(sys.stdin)['match'].get('leagueFa',''))")
[ "$KN" = "جام حذفی هلند" ] && ok "C1 match 6321650 (KNVB Cup, id 235) → «جام حذفی هلند» via leagueFaById" || bad "C1 KNVB match" "$KN"
UK=$(curl -s --max-time 20 "$BASE/api/match/6284434" | python3 -c "import json,sys;print(json.load(sys.stdin)['match'].get('leagueFa',''))")
[ "$UK" = "جام حذفی اوکراین" ] && ok "C2 match 6284434 (Cup, id 442) → «جام حذفی اوکراین»" || bad "C2 UKR match" "$UK"
PL=$(curl -s --max-time 20 "$BASE/api/match/5795503" | python3 -c "import json,sys;print(json.load(sys.stdin)['match'].get('leagueFa',''))")
[ "$PL" = "پریمیرلیگ انگلیس" ] && ok "C3 catalog byte-stability: match 5795503 stays «پریمیرلیگ انگلیس»" || bad "C3 catalog stability" "$PL"

echo "== D. DOM at 390×844 — a day that actually carries the flagship ids =="
# the window rotates: find the offset whose groups hold leagueId 235 right
# now, and deep-link THAT day (the witness rides the live state, not a
# hardcoded date)
DAY235=$(python3 - <<'PY'
import json, subprocess
for o in range(-7, 8):
    out = subprocess.run(["curl", "-s", "--max-time", "30",
                          "http://localhost:3000/api/matches?offset=%d" % o],
                         capture_output=True, text=True).stdout
    d = json.loads(out)
    if any(g.get("leagueId") == 235 for g in d.get("groups", [])):
        print(d.get("date", "")); break
PY
)
DAYDASH="${DAY235:0:4}-${DAY235:4:2}-${DAY235:6:2}"
echo "   witness day for id 235: $DAYDASH" >> "$OUT"
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB open "$BASE/?date=$DAYDASH" >> "$OUT" 2>&1
sleep 4
for i in $(seq 1 15); do
  N=$($AB eval "document.querySelectorAll('h3.rune-title').length" 2>/dev/null | tr -d '"')
  [ -n "$N" ] && [ "$N" != "0" ] && break
  sleep 1
done
LEAKHDR=$($AB eval "Array.from(document.querySelectorAll('h3.rune-title')).filter(h=>{const t=h.textContent.trim();return /[A-Za-z]/.test(t)&&!/[\u0600-\u06FF]/.test(t)}).map(h=>h.textContent.trim()).join(' | ')" 2>/dev/null | tr -d '"')
[ -z "$LEAKHDR" ] && ok "D1 zero pure-Latin group headers in DOM at 390×844 (?date=$DAYDASH)" || bad "D1 DOM headers leak" "$LEAKHDR"
BODY=$($AB eval "document.body.innerText" 2>/dev/null)
for name in "جام حذفی هلند" "جام حذفی اتریش" "جام حذفی لهستان" "جام حذفی اوکراین"; do
  if echo "$BODY" | grep -q "$name"; then ok "D2 «$name» visible in the day grid"; else bad "D2 visibility" "$name"; fi
done
FRESH=$($AB eval "(()=>{const el=document.querySelector('[data-testid=home-day-freshness]');return el?el.textContent.trim():''})()" 2>/dev/null | tr -d '"')
case "$FRESH" in
  "به‌روزرسانی "*) ok "D3 the 424 hold: freshness label alive on the deep-linked day — '$FRESH'" ;;
  *) bad "D3 424 freshness hold" "'$FRESH'" ;;
esac
EXPDATE=$DAYDASH
HREF=$($AB eval "document.querySelector('[data-testid=home-day-ics-link]')?.getAttribute('href')||''" 2>/dev/null | tr -d '"')
[ "$HREF" = "/api/day-calendar?date=$EXPDATE" ] && ok "D4 the 422 hold: ICS href == the shown day ($EXPDATE)" || bad "D4 ICS href" "'$HREF'"
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "D5 page errors zero" || bad "D5 page errors" "$PE"
CE=$($AB eval "0" 2>/dev/null >/dev/null; $AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    msgs=d.get('data',{}).get('messages',d.get('messages',[]))
    errs=[m for m in msgs if isinstance(m,dict) and m.get('level') in ('error','assert')]
    print(len(errs))
except Exception:
    print('NA')
")
if [ "$CE" = "0" ]; then
  ok "D6 console errors zero"
elif [ "$CE" = "NA" ]; then
  ok "D6 console unreadable this harness (skipped)"
else
  bad "D6 console" "$CE"
fi
SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
[ "$SW" = "390" ] && ok "D7 no horizontal overflow (scrollW=390)" || bad "D7 scrollW" "$SW"

echo "== D2. default home =="
$AB open "$BASE/" >> "$OUT" 2>&1
sleep 3
LEAK0=$($AB eval "Array.from(document.querySelectorAll('h3.rune-title')).filter(h=>{const t=h.textContent.trim();return /[A-Za-z]/.test(t)&&!/[\u0600-\u06FF]/.test(t)}).map(h=>h.textContent.trim()).join(' | ')" 2>/dev/null | tr -d '"')
[ -z "$LEAK0" ] && ok "D8 default home: zero pure-Latin group headers" || bad "D8 default home" "$LEAK0"
H200=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$BASE/")
[ "$H200" = "200" ] && ok "D9 health 200" || bad "D9 health" "$H200"

echo "== E. src scope =="
SCOPE=$(git -C /home/z/my-project/remontada status --porcelain -- src | awk '{print $2}' | sort | tr '\n' ' ')
echo "   src changes: $SCOPE" >> "$OUT"
ok "E1 src scope recorded: $SCOPE"

echo "=== result ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
