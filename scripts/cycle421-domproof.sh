#!/usr/bin/env bash
# cycle421-domproof.sh — update cycle 421 (فرمول ۲): the MATCH-level ICS
# calendar — the third rung of the subscription ladder (312 league →
# 420 team → 421 single fixture). Feasibility probed live first (the
# آپدیت rule, UA Chrome/124): matchDetails 5795503 carries header utcTime,
# Persian-mappable team names, infoBox Stadium, AND the seo endDate
# (2026-11-02T22:00:00Z — the REAL end time, exactly the honest upgrade
# over the family's 2h block). Build: /api/match-calendar/[id] over the
# SAME cached getMatchLdData payload the match page's SportsEvent LD reads
# (zero new upstream requests) + the server-rendered CTA «افزودن به تقویم
# (ICS)» on the match page, hidden when the event is not schedulable.
#   A   the API contracts (single VEVENT, real DTEND, Persian summary,
#       fold §3.1 on binary lines, guards, the 312/420 holds)
#   B   DOM at 390x844: the CTA on a live match page, its absence on the
#       invalid-id shell, the 420 team CTA hold, hygiene three-pack
#   C   scope + health
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the API contracts ================"
curl -sD /tmp/c421-h.txt -o /tmp/c421-ics.txt -A "$UA" "$BASE/api/match-calendar/5795503" --max-time 20
for L in abc 12 1x; do
  C=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/match-calendar/$L" --max-time 10)
  eval "G_$L=\$([ \"\$C\" = 400 ] && echo 1 || echo 0)"
done
C404=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE/api/match-calendar/999999999" --max-time 20)
[ "$C404" = 404 ]; G404=$([ "$C404" = 404 ] && echo 1 || echo 0)

api /api/league-calendar?league=pl > /tmp/c421-pl.ics
api "/api/league-calendar?league=hazfi" > /tmp/c421-hazfi.ics
api /api/team-calendar/8456 > /tmp/c421-team.ics

while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import re

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

raw, lines = unfold("/tmp/c421-ics.txt")
s = "\n".join(lines)
fa = re.compile(r"[\u0600-\u06FF]")

checks = {}
checks["A1-content-type-text-calendar"] = 1 if "content-type: text/calendar" in open("/tmp/c421-h.txt").read().lower() else 0
checks["A2-single-VEVENT"] = 1 if s.count("BEGIN:VEVENT") == 1 and s.count("END:VEVENT") == 1 else 0
checks["A3-uid-namespace"] = 1 if "UID:remontada-match-5795503@remontada" in s else 0
checks["A4-dtstart-kickoff"] = 1 if "DTSTART:20261102T200000Z" in s else 0
checks["A5-dtend-real-seo-end"] = 1 if "DTEND:20261102T220000Z" in s else 0
checks["A6-summary-persian-leagueFa"] = 1 if "SUMMARY:نیوکاسل در برابر اورتون (پریمیرلیگ انگلیس)" in s else 0
checks["A7-calname"] = 1 if "X-WR-CALNAME:نیوکاسل در برابر اورتون" in s else 0
checks["A8-location-raw-honest"] = 1 if "St. James' Park" in s and "Newcastle upon Tyne" in s else 0
checks["A9-url-and-fa-description"] = 1 if "URL:https://remontada.zxy.site/match/5795503" in s and fa.search(next((l for l in lines if l.startswith("DESCRIPTION:")), "")) else 0
checks["A10-dtstamp"] = 1 if any(l.startswith("DTSTAMP:") and l.endswith("Z") for l in lines) else 0
checks["A11-fold-75-octets-binary"] = 1 if max((len(l.encode("utf-8")) for l in raw.split("\r\n")), default=0) <= 75 else 0

_, pl = unfold("/tmp/c421-pl.ics")
_, hazfi = unfold("/tmp/c421-hazfi.ics")
_, team = unfold("/tmp/c421-team.ics")
checks["A14-hold-312-pl-380-events"] = 1 if sum(1 for l in pl if l.startswith("BEGIN:VEVENT")) == 380 else 0
checks["A15-hold-312-hazfi-24-events"] = 1 if sum(1 for l in hazfi if l.startswith("BEGIN:VEVENT")) == 24 else 0
checks["A16-hold-420-team-8456-53-events"] = 1 if sum(1 for l in team if l.startswith("BEGIN:VEVENT")) == 53 else 0
checks["A17-hold-420-team-calname"] = 1 if "X-WR-CALNAME:منچسترسیتی — فیکسچرها" in "\n".join(team) else 0
for k, v in checks.items():
    if v is not None:
        print(f"{k} {v}")
PY
)
# the shell-side checks (headers + guards) that python cannot see
DISPO=$(grep -i 'Content-Disposition' /tmp/c421-h.txt | grep -c 'filename="match-5795503.ics"')
ck "A12-content-disposition-filename" "$DISPO"
ck "A13a-guard-400-abc" "$G_abc"
ck "A13b-guard-400-12" "$G_12"
ck "A13c-guard-400-1x" "$G_1x"
ck "A13d-unknown-id-404" "$G404"

echo "================ B: DOM at 390x844 ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "$BASE/match/5795503" >/dev/null 2>&1
sleep 6
# the 412 pipe-delimited pattern (tr -d '"' mangles JSON)
R=$(agent-browser eval "var a=document.querySelector('[data-testid=\"match-ics-link\"]'); var row=a?a.closest('[data-testid=\"match-ics-row\"]:not([hidden])'):null; (a?1:0)+'|'+(a&&a.getAttribute('href')==='/api/match-calendar/5795503'?1:0)+'|'+(a&&a.innerText.indexOf('افزودن به تقویم')>=0?1:0)+'|'+(row&&row.offsetParent!==null?1:0)" | tr -d '"')
L1=${R%%|*}; R2=${R#*|}; L2=${R2%%|*}; R3=${R2#*|}; L3=${R3%%|*}; L4=${R3##*|}
ck "B1 CTA [data-testid=match-ics-link] present" "$L1"
ck "B2 CTA href=/api/match-calendar/5795503" "$L2"
ck "B3 CTA text «افزودن به تقویم (ICS)»" "$L3"
ck "B4 CTA row visible (offsetParent)" "$L4"
# the honest absence: the invalid-id shell must NOT carry the CTA
agent-browser open "$BASE/match/99999999999999999999" >/dev/null 2>&1
sleep 5
ABS=$(agent-browser eval "document.querySelector('[data-testid=\"match-ics-link\"]')?0:1" | tr -d '"')
ck "B5 invalid-id shell has NO CTA (schedulable ⇔ visible)" "$ABS"
# hygiene three-pack on the match page
agent-browser open "$BASE/match/5795503" >/dev/null 2>&1
sleep 5
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
ck "B6 /match page-errors clean" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
ck "B7 /match console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
ck "B8 /match scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"
# the 420 hold: the team CTA on the lazy fixtures-all section (8s poll — the 420 lesson)
agent-browser open "$BASE/team/8456" >/dev/null 2>&1
TEAMHOLD=0
for i in $(seq 1 8); do
  sleep 1
  T=$(agent-browser eval "document.querySelector('[data-testid=\"team-ics-link\"]')?1:0" 2>/dev/null | tr -d '"')
  [ "$T" = "1" ] && { TEAMHOLD=1; break; }
done
ck "B9 hold-420 team CTA on /team/8456 (lazy poll)" "$TEAMHOLD"
# home hygiene hold
agent-browser open "$BASE/" >/dev/null 2>&1
sleep 4
ERR2=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
SW2=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
ck "B10 home page-errors clean" "$([ -z "$ERR2" ] || [ "$ERR2" = "0" ] && echo 1 || echo 0)"
ck "B11 home scrollW=390" "$([ "$SW2" = "390" ] && echo 1 || echo 0)"

echo "================ C: scope + health ================"
H=$(curl -s -o /dev/null -w '%{http_code}' "$BASE" --max-time 10)
ck "C1 health 200" "$([ "$H" = "200" ] && echo 1 || echo 0)"
SRCN=$(git -C /home/z/my-project/remontada status --porcelain -- src | wc -l)
ck "C2 src scope exactly 2 (new route + page CTA)" "$([ "$SRCN" = "2" ] && echo 1 || echo 0)"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE421 DOMPROOF OK" || echo "CYCLE421 DOMPROOF FAILED"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
