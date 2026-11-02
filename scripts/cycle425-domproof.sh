#!/bin/bash
# cycle425-domproof.sh — the personal rung of the ICS ladder (update cycle 425)
# /api/favorites-calendar?ids= — the favorites' whole fixtures merged into ONE
# RFC 5545 file + the CTA in the favorites section (/leagues).
# Witness design: the expected event count is computed LIVE from the two
# teams' own /api/team-fixtures feeds (sum − shared), the dedupe witness is a
# REAL head-to-head fixture (live-computed intersection, probed: 8456∩10204
# has 5795502/5795626/6275368), and the DOM contract rides the favorites
# localStorage store (visible ⇔ favorites exist, exact ids-order href).
# Harness notes: single-level heredocs only (the 422 lesson), BASE via env
# (the 418 NameError lesson), results file truncated per run.
set -u
BASE="${BASE:-http://localhost:3000}"
export BASE
OUT=/home/z/my-project/remontada/scripts/cycle425-results.txt
: > "$OUT"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "PASS $1" >> "$OUT"; echo "PASS $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 :: $2" >> "$OUT"; echo "FAIL $1 :: $2"; }
AB="agent-browser"

echo "== A. API contracts =="
# A0 — live premise: expected merged count + a REAL shared fixture
PREM=$(mktemp)
python3 - > "$PREM" <<'PY'
import json, urllib.request, os
base = os.environ["BASE"]
def fx(t):
    with urllib.request.urlopen(f"{base}/api/team-fixtures/{t}", timeout=30) as r:
        f = json.load(r)["fixtures"]
    rows = (f.get("results") or []) + (f.get("upcoming") or [])
    return {x["id"] for x in rows}, len(rows)
a, ca = fx(8456)
b, cb = fx(10204)
shared = sorted(a & b)
print(f"{ca + cb - len(shared)} {ca} {cb} {shared[0] if shared else 0}")
PY
read -r EXP COUNT_A COUNT_B SHARED < "$PREM"
echo "   expected=$EXP (A=$COUNT_A B=$COUNT_B shared=$SHARED)" >> "$OUT"
if [ "$SHARED" != "0" ]; then ok "A0 live dedupe premise: 8456/10204 share fixture $SHARED"; else bad "A0 premise" "no shared fixture"; fi

curl -s -D /tmp/h1.txt -o /tmp/fav425.ics "$BASE/api/favorites-calendar?ids=8456,10204"
CT=$(tr -d '\r' < /tmp/h1.txt | rg -i '^content-type:' | head -1)
echo "$CT" | rg -qi 'text/calendar' && ok "A1 content-type text/calendar" || bad "A1 content-type" "$CT"
FN=$(tr -d '\r' < /tmp/h1.txt | rg -i '^content-disposition:' | rg -o 'favorites\.ics' | head -1)
[ "$FN" = "favorites.ics" ] && ok "A2 filename favorites.ics" || bad "A2 filename" "$FN"

# A3..A9 — the ICS body verdicts (one python pass, counted in bash)
PYSUM=$(mktemp)
python3 - /tmp/fav425.ics "$EXP" "$SHARED" > "$PYSUM" <<'PY'
import sys, re
raw = open(sys.argv[1], "rb").read().decode("utf-8")
lines = raw.split("\r\n")
unfolded, buf = [], ""
for ln in lines:
    if ln.startswith(" ") and buf:
        buf += ln[1:]
    else:
        if buf: unfolded.append(buf)
        buf = ln
if buf: unfolded.append(buf)
exp, shared = int(sys.argv[2]), sys.argv[3]
events = [l for l in unfolded if l == "BEGIN:VEVENT"]
uids = [l[4:] for l in unfolded if l.startswith("UID:")]
ok_uid = all(re.match(r"^remontada-fav-\d+-fixture-\d+@remontada$", u) for u in uids)
print("PASS A3 VEVENT count %d == live expected %d" % (len(events), exp) if len(events) == exp
      else "FAIL A3 count %d != %d" % (len(events), exp))
print("PASS A4 UIDs unique, count-match, shape-ok" if (len(uids) == len(set(uids)) and len(uids) == len(events) and ok_uid)
      else "FAIL A4 uids")
sh = [l for l in uids if "fixture-%s@" % shared in l]
own = "remontada-fav-8456-fixture-%s@remontada" % shared
print("PASS A5 dedupe: shared fixture %s appears once, owned by the FIRST team" % shared if sh == [own]
      else "FAIL A5 shared-uid %r != %r" % (sh, own))
caln = [l for l in unfolded if l.startswith("X-WR-CALNAME:")]
print("PASS A6 CALNAME «بازی‌های تیم‌های منتخب من»" if caln == ["X-WR-CALNAME:بازی‌های تیم‌های منتخب من"]
      else "FAIL A6 calname %r" % caln)
starts = [l[8:] for l in unfolded if l.startswith("DTSTART:")]
print("PASS A7 chronological DTSTART (%d events)" % len(starts) if starts == sorted(starts) and starts
      else "FAIL A7 order")
long = [l for l in raw.split("\r\n") if len(l.encode("utf-8")) > 75]
print("PASS A8 zero >75-octet lines" if not long else "FAIL A8 fold %d" % len(long))
sums = [l for l in unfolded if l.startswith("SUMMARY:")]
allpair = all(" در برابر " in s and "(" in s and ")" in s for s in sums)
print("PASS A9 SUMMARY Persian pairing on %d events" % len(sums) if allpair and sums else "FAIL A9 summary")
PY
while read -r line; do
  case "$line" in
    PASS*) PASS=$((PASS+1)); echo "$line";;
    FAIL*) FAIL=$((FAIL+1)); echo "$line";;
  esac
done < "$PYSUM"

C1=$(curl -s "$BASE/api/favorites-calendar?ids=8456" | rg -c "BEGIN:VEVENT" || true); C1=${C1:-0}
T420=$(curl -s "$BASE/api/team-calendar/8456" | rg -c "BEGIN:VEVENT" || true); T420=${T420:-0}
[ "$C1" = "$COUNT_A" ] && [ "$T420" = "$COUNT_A" ] && ok "A10 single-team merge ($C1) == the 420 team feed ($T420)" || bad "A10 single-team" "fav=$C1 team420=$T420 countA=$COUNT_A"
C2=$(curl -s "$BASE/api/favorites-calendar?ids=8456,8456" | rg -c "BEGIN:VEVENT" || true); C2=${C2:-0}
[ "$C2" = "$COUNT_A" ] && ok "A11 duplicate ids dedupe to one team ($C2)" || bad "A11 dup ids" "$C2"

for case in "ids=|400" "ids=abc|400" "ids=8456,,8668|400" "ids=8456,|400" "ids=12|400"; do
  q="${case%|*}"; want="${case#*|}"
  got=$(curl -s -o /tmp/g.json -w '%{http_code}' "$BASE/api/favorites-calendar?$q")
  msg=$(python3 -c "import json;print(json.load(open('/tmp/g.json')).get('error',''))" 2>/dev/null || true)
  if [ "$got" = "$want" ] && [ -n "$msg" ]; then ok "A12 guard «$q» → $want «$msg»"; else bad "A12 guard $q" "got=$got msg=$msg"; fi
done
IDS31=$(python3 -c "print(','.join(str(845600+i) for i in range(31)))")
got=$(curl -s -o /tmp/g31.json -w '%{http_code}' "$BASE/api/favorites-calendar?ids=$IDS31")
msg=$(python3 -c "import json;print(json.load(open('/tmp/g31.json')).get('error',''))" 2>/dev/null || true)
[ "$got" = "400" ] && [ -n "$msg" ] && ok "A13 overcap 31 ids → 400 «$msg»" || bad "A13 overcap" "got=$got msg=$msg"
got=$(curl -s -o /tmp/g404.json -w '%{http_code}' "$BASE/api/favorites-calendar?ids=999999999999")
msg=$(python3 -c "import json;print(json.load(open('/tmp/g404.json')).get('error',''))" 2>/dev/null || true)
SIB=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/team-calendar/999999999999")
# the family contract: an unknown id THROWS upstream (getTeamDataRaw) — the
# 420 sibling answers 502 for the same id; the merge must behave IDENTICALLY
[ "$got" = "$SIB" ] && [ -n "$msg" ] && ok "A14 unknown id → $got, byte-consistent with the 420 sibling ($SIB) «$msg»" || bad "A14 unknown" "got=$got sibling=$SIB msg=$msg"

echo "== A15. family holds =="
M1=$(curl -s "$BASE/api/match-calendar/5795503" | rg -c "BEGIN:VEVENT" || true); M1=${M1:-0}
[ "$M1" = "1" ] && ok "A15a the 421 hold: match ICS single-VEVENT" || bad "A15a match" "$M1"
TODAY=$(TZ=Asia/Tehran date +%F)
FEEDN=$(curl -s "$BASE/api/matches?offset=0" | python3 -c "import json,sys;print(sum(len(g.get('matches') or []) for g in (json.load(sys.stdin).get('groups') or [])))")
DAYN=$(curl -s "$BASE/api/day-calendar?date=$TODAY" | rg -c "BEGIN:VEVENT" || true); DAYN=${DAYN:-0}
[ "$DAYN" = "$FEEDN" ] && ok "A15b the 422 hold: day ICS ($DAYN) == live feed ($FEEDN)" || bad "A15b day" "ics=$DAYN feed=$FEEDN"

echo "== B. DOM 390×844 =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB open "$BASE/leagues" >> "$OUT" 2>&1
$AB storage local set remontada:favorites '[{"id":8456,"fa":"منچسترسیتی","ts":2},{"id":8668,"fa":"اورتون","ts":1}]' >> "$OUT" 2>&1
# the store sorts ts DESC (newest favorite first) ⇒ 8456 first — the CTA must
# carry the store's OWN order (the same ids the cards above show, same order)
$AB reload >> "$OUT" 2>&1
sleep 2
HREF=$($AB eval "document.querySelector('[data-testid=fav-ics-link]')?.getAttribute('href')||''" 2>/dev/null | tr -d '"')
[ "$HREF" = "/api/favorites-calendar?ids=8456,8668" ] && ok "B1 CTA href == the favorites' exact ids order" || bad "B1 href" "'$HREF'"
TXT=$($AB eval "document.querySelector('[data-testid=fav-ics-link]')?.textContent.trim()||''" 2>/dev/null | tr -d '"')
case "$TXT" in *"دانلود تقویم منتخب‌ها (ICS)"*) ok "B2 CTA text «دانلود تقویم منتخب‌ها (ICS)»";; *) bad "B2 text" "'$TXT'";; esac
VIS=$($AB eval "(()=>{const el=document.querySelector('[data-testid=fav-ics-link]');if(!el)return 'missing';const r=el.getBoundingClientRect(),s=getComputedStyle(el);return (r.width>0&&s.display!=='none')?'visible':'hidden'})()" 2>/dev/null | tr -d '"')
[ "$VIS" = "visible" ] && ok "B3 CTA visible at 390×844 (link-visible ⇔ favorites-present)" || bad "B3 visibility" "$VIS"
$AB storage local set remontada:favorites '[]' >> "$OUT" 2>&1
$AB reload >> "$OUT" 2>&1
sleep 2
GONE=$($AB eval "document.querySelector('[data-testid=fav-ics-row]')?'present':'absent'" 2>/dev/null | tr -d '"')
[ "$GONE" = "absent" ] && ok "B4 honest absence: no favorites ⇒ no CTA" || bad "B4 absence" "$GONE"
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "B5 page-errors zero" || bad "B5 page-errors" "$PE"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(0); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(len([x for x in m if isinstance(x,dict) and x.get('type')=='error']))")
[ "$CE" = "0" ] && ok "B6 console-errors zero" || bad "B6 console-errors" "$CE"
SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
[ "$SW" = "390" ] && ok "B7 no horizontal overflow (scrollW=390)" || bad "B7 overflow" "scrollW=$SW"
$AB close >> "$OUT" 2>&1 || true

echo "== C. health =="
H=$(curl -s -o /dev/null -w '%{http_code}' "$BASE")
[ "$H" = "200" ] && ok "C1 health 200" || bad "C1 health" "$H"

echo "=== result ===" | tee -a "$OUT"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ] && echo "CYCLE425 DOMPROOF OK" || echo "CYCLE425 DOMPROOF BROKEN"
exit $FAIL
