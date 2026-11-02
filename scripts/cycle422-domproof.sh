#!/usr/bin/env bash
# cycle422-domproof.sh — update cycle 422 (فرمول ۳): the DAY-level ICS
# calendar — the fourth rung of the subscription ladder (312 league →
# 420 team → 421 single fixture → 422 whole matchday). Feasibility probed
# live first (the آپدیت rule): the home day feed (getMatchesByDate, the
# SAME cached payload /api/matches reads) serves 154/163/118/501 matches
# across offsets 0/+1/+2/−1 with Persian fa names + Persian leagueFa +
# utcTime on every row. Build: /api/day-calendar?date=YYYY-MM-DD over that
# payload (zero new upstream requests) + the home CTA «دانلود تقویم این
# روز (ICS)», visible ⇔ the day feed loaded, href riding the cycle-297
# ?date= deep-link language so the file always matches the shown day.
#   A   the API contracts (file-reflects-feed counts, unique UIDs, the
#       witness event, CALNAME Jalali, fold §3.1 binary, guards incl. the
#       cycle-299 impossible dates, second-day contract, 312/420/421 holds)
#   B   DOM at 390x844: the home CTA href == the shown day (also via the
#       ?date= deep link), the 421 match CTA hold, hygiene three-pack
#   C   scope + health
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the API contracts ================"
# the day under test = whatever the home feed itself calls offset 0
D8=$(api "/api/matches?offset=0" | python3 -c "import json,sys; print(json.load(sys.stdin).get('date',''))")
D=${D8:0:4}-${D8:4:2}-${D8:6:2}
D1=$(api "/api/matches?offset=1" | python3 -c "import json,sys; print(json.load(sys.stdin).get('date',''))")
D1F=${D1:0:4}-${D1:4:2}-${D1:6:2}
echo "witness day: $D (offset+1: $D1F)"
curl -sD /tmp/c422-h.txt -o /tmp/c422-day.ics -A "$UA" "$BASE/api/day-calendar?date=$D" --max-time 25
api "/api/matches?offset=0" > /tmp/c422-feed0.json
api "/api/matches?offset=1" > /tmp/c422-feed1.json
api "$BASE/api/day-calendar?date=$D1F" > /tmp/c422-day1.ics 2>/dev/null
curl -s -o /tmp/c422-day1.ics -A "$UA" "$BASE/api/day-calendar?date=$D1F" --max-time 25
GI=0
for G in "" abc "2026-02-30" "2026-11-31" "2026-13-01" "2020-01-01"; do
  C=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/day-calendar?date=$G" --max-time 15)
  eval "GRES_$GI=\$([ \"\$C\" = 400 ] && echo 1 || echo 0)"
  GI=$((GI+1))
done
curl -s -o /tmp/c421-hold.ics -A "$UA" "$BASE/api/match-calendar/5795503" --max-time 20
api "/api/team-calendar/8456" > /tmp/c422-team.ics
api "/api/league-calendar?league=pl" > /tmp/c422-pl.ics
api "/api/league-calendar?league=hazfi" > /tmp/c422-hazfi.ics

while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, re

def unfold(path):
    raw = open(path, "rb").read().decode("utf-8")
    phys = raw.split("\r\n")
    out = []
    for ln in phys:
        if ln.startswith(" ") and out:
            out[-1] += ln[1:]
        else:
            out.append(ln)
    return raw, [l for l in out if l != ""]

def feed_count(path):
    d = json.load(open(path))
    return sum(len(g.get("matches") or []) for g in (d.get("groups") or []))

def feed_has(path, mid):
    d = json.load(open(path))
    return any(str(m.get("id")) == mid for g in (d.get("groups") or []) for m in (g.get("matches") or []))

def g2j(y, m, d):
    g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    gy, gm, gd = (y - 1600, m - 1, d - 1)
    g_day_no = 365 * gy + (gy + 3) // 4 - (gy + 99) // 100 + (gy + 399) // 400
    g_day_no += g_d_m[gm]
    if gm > 1 and ((y % 4 == 0 and y % 100 != 0) or (y % 400 == 0)):
        g_day_no += 1
    g_day_no += gd
    j_day_no = g_day_no - 79
    j_np = j_day_no // 12053
    j_day_no %= 12053
    jy = 979 + 33 * j_np + 4 * (j_day_no // 1461)
    j_day_no %= 1461
    if j_day_no >= 366:
        jy += (j_day_no - 1) // 365
        j_day_no = (j_day_no - 1) % 365
    if j_day_no < 186:
        jm = 1 + j_day_no // 31
        jd = 1 + (j_day_no % 31)
    else:
        jm = 7 + (j_day_no - 186) // 30
        jd = 1 + ((j_day_no - 186) % 30)
    return jy, jm, jd

FA = "۰۱۲۳۴۵۶۷۸۹"
def fadig(n):
    return "".join(FA[int(c)] for c in str(n))

MONTHS = ["فروردین","اردیبهشت","خرداد","تیر","مرداد","شهریور","مهر","آبان","آذر","دی","بهمن","اسفند"]

checks = {}
hdr = open("/tmp/c422-h.txt").read().lower()
checks["A1-200-text-calendar"] = 1 if ("content-type: text/calendar" in hdr and " 200" in hdr.splitlines()[0]) else 0
raw, lines = unfold("/tmp/c422-day.ics")
s = "\n".join(lines)
ve = sum(1 for l in lines if l.startswith("BEGIN:VEVENT"))
fc = feed_count("/tmp/c422-feed0.json")
checks["A2-file-reflects-feed-count"] = 1 if ve == fc and ve > 0 else 0
uids = [l for l in lines if l.startswith("UID:remontada-day-")]
checks["A3-unique-uid-namespace"] = 1 if len(uids) == ve and len(set(uids)) == ve else 0
_, d1 = unfold("/tmp/c422-day1.ics")
ve1 = sum(1 for l in d1 if l.startswith("BEGIN:VEVENT"))
checks["A10-second-day-count"] = 1 if ve1 == feed_count("/tmp/c422-feed1.json") and ve1 > 0 else 0
calm = next((l for l in lines if l.startswith("X-WR-CALNAME:")), "")
dparts = calm.split(":", 1)[1] if ":" in calm else ""
# structural: بازی‌های + Persian digits + Persian month + Persian digits
checks["A4-calname-jalali-structure"] = 1 if bool(re.fullmatch(r"بازی‌های [۰-۹]+ [\u0600-\u06FF]+ [۰-۹]+", dparts)) else 0
# exact: the jalali label must be the truthful jalali of the FEED's own date
fd = json.load(open("/tmp/c422-feed0.json")).get("date", "")
if re.fullmatch(r"\d{8}", fd or ""):
    jy_, jm_, jd_ = g2j(int(fd[:4]), int(fd[4:6]), int(fd[6:8]))
    checks["A5-calname-exact"] = 1 if dparts == f"بازی‌های {fadig(jd_)} {MONTHS[jm_-1]} {fadig(jy_)}" else 0
else:
    checks["A5-calname-exact"] = 0
checks["A6-dtend-per-event"] = 1 if sum(1 for l in lines if l.startswith("DTEND:")) == ve else 0
checks["A7-fold-75-octets-binary"] = 1 if max((len(l.encode("utf-8")) for l in raw.split("\r\n")), default=0) <= 75 else 0
summ = sum(1 for l in lines if l.startswith("SUMMARY:") and "در برابر" in l and re.search(r"[\u0600-\u06FF]", l))
checks["A8-summary-persian-per-event"] = 1 if summ == ve else 0
if feed_has("/tmp/c422-feed0.json", "5795503"):
    checks["A9-witness-5795503"] = 1 if "UID:remontada-day-20261102-fixture-5795503@remontada" in s and "DTSTART:20261102T200000Z" in s and "SUMMARY:نیوکاسل در برابر اورتون (پریمیرلیگ انگلیس)" in s else 0
else:
    checks["A9-witness-5795503"] = 1
# the 312/420/421 holds
_, hold421 = unfold("/tmp/c421-hold.ics")
checks["A11-hold-421-match-single"] = 1 if sum(1 for l in hold421 if l.startswith("BEGIN:VEVENT")) == 1 else 0
_, team = unfold("/tmp/c422-team.ics")
checks["A12-hold-420-team-53"] = 1 if sum(1 for l in team if l.startswith("BEGIN:VEVENT")) == 53 else 0
_, pl = unfold("/tmp/c422-pl.ics")
_, hazfi = unfold("/tmp/c422-hazfi.ics")
checks["A13-hold-312-pl-380"] = 1 if sum(1 for l in pl if l.startswith("BEGIN:VEVENT")) == 380 else 0
checks["A14-hold-312-hazfi-24"] = 1 if sum(1 for l in hazfi if l.startswith("BEGIN:VEVENT")) == 24 else 0
for k, v in checks.items():
    print(f"{k} {v}")
PY
)
ck "A15-guard-400-empty" "$GRES_0"
ck "A16-guard-400-abc" "$GRES_1"
ck "A17-guard-400-impossible-0230" "$GRES_2"
ck "A18-guard-400-impossible-1131" "$GRES_3"
ck "A19-guard-400-month13" "$GRES_4"
ck "A20-guard-400-outside-window" "$GRES_5"
DISPO=$(grep -i 'Content-Disposition' /tmp/c422-h.txt | grep -c "filename=\"day-${D8}.ics\"")
ck "A21-filename-day-ics" "$DISPO"

echo "================ B: DOM at 390x844 ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "$BASE/" >/dev/null 2>&1
# the home CTA is a post-fetch render — poll, don't sleep (the 420 lesson)
CTA=0; HREF=""; TEXT=""
for i in $(seq 1 12); do
  sleep 1
  R=$(agent-browser eval "var a=document.querySelector('[data-testid=\"home-day-ics-link\"]'); a? (a.getAttribute('href')||'')+'|'+(a.innerText||'')+'|1' : '||0'" 2>/dev/null | tr -d '"')
  if [ "${R##*|}" = "1" ]; then CTA=1; HREF=${R%%|*}; R2=${R#*|}; TEXT=${R2%%|*}; break; fi
done
ck "B1 home CTA present after feed load" "$CTA"
WANT="/api/day-calendar?date=$D"
ck "B2 CTA href == shown day ($WANT)" "$([ "$HREF" = "$WANT" ] && echo 1 || echo 0)"
ck "B3 CTA text «دانلود تقویم این روز (ICS)»" "$([ "${TEXT#*دانلود تقویم}" != "$TEXT" ] && echo 1 || echo 0)"
# the ?date= deep link drives the CTA (the 297 URL contract reaches the ICS)
agent-browser open "$BASE/?date=$D1F" >/dev/null 2>&1
DCTA=0; DHREF=""
for i in $(seq 1 12); do
  sleep 1
  R=$(agent-browser eval "var a=document.querySelector('[data-testid=\"home-day-ics-link\"]'); a? (a.getAttribute('href')||'')+'|1' : '|0'" 2>/dev/null | tr -d '"')
  if [ "${R##*|}" = "1" ]; then DCTA=1; DHREF=${R%%|*}; break; fi
done
ck "B4 deep-link ?date drives CTA href" "$([ "$DCTA" = "1" ] && [ "$DHREF" = "/api/day-calendar?date=$D1F" ] && echo 1 || echo 0)"
# hygiene three-pack on home
agent-browser open "$BASE/" >/dev/null 2>&1
sleep 4
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
ck "B5 home page-errors clean" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
ck "B6 home console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
ck "B7 home scrollW=cw=390" "$([ "$SW" = "390" ] && echo 1 || echo 0)"
# hold-421: the match-page CTA still server-rendered
agent-browser open "$BASE/match/5795503" >/dev/null 2>&1
sleep 5
M=$(agent-browser eval "document.querySelector('[data-testid=\"match-ics-link\"]')?1:0" 2>/dev/null | tr -d '"')
ck "B8 hold-421 match CTA present" "$M"

echo "================ C: scope + health ================"
H=$(curl -s -o /dev/null -w '%{http_code}' "$BASE" --max-time 10)
ck "C1 health 200" "$([ "$H" = "200" ] && echo 1 || echo 0)"
SRCN=$(git -C /home/z/my-project/remontada status --porcelain -- src | wc -l)
ck "C2 src scope exactly 2 (new route + home CTA)" "$([ "$SRCN" = "2" ] && echo 1 || echo 0)"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE422 DOMPROOF OK" || echo "CYCLE422 DOMPROOF FAILED"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
