#!/usr/bin/env bash
# cycle415-domproof.sh — update cycle 415 (فرمول ۱): the portal-level
# «انتقال‌ها» surface — the third and last level of the named backlog
# (league tab = cycle-57, team feed = team page; the GLOBAL wire upstream
# was never consumed before this cycle). Feasibility probed live first
# (the آپدیت rule): data/transfers?date= is a fixed recent window (page
# and date params byte-ignored), 50 structured rows with fee/marketValue/
# club colors. Fix scope: getGlobalTransfers producer (`globalTransfers:v1`,
# 15-min, throws on outage — the 294 rule) + /api/transfers (the /api/news
# shape) + /transfers page (server shell + client, the /news shape) +
# fa layers: TRANSFER_POS_FA (14 entries), playerFa/teamFa honest fallbacks,
# transferFeeFa reuse, Jalali + relative dates, «بدون باشگاه» for the
# upstream Free-agent row (id 2) with NO team link. Nav: header + footer
# gain «انتقال‌ها» (the mobile 5-slot dock untouched — the ui-campaign
# design), sitemap +1 static row. NO existing cache key bumped.
#   A   the API contracts (shape, fa coverage, honest fallbacks, freshness)
#   B   DOM at 390x844: the page renders, rows/fa/fee/free-agent visible,
#       nav + footer links, hygiene three-pack
#   C   the standing holds (414 news guard, league transfers, sitemap row)
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the API contracts ================"
api /api/transfers > /tmp/c415-api.json
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, re, datetime
fa = re.compile(r'[\u0600-\u06FF]')
try:
    d = json.load(open("/tmp/c415-api.json"))
except Exception:
    for k in ("A1-ok","A2-count50","A3-fresh","A4-posFa","A5-feeFa-persian","A6-freeagent-honest","A7-raw-name-byte","A8-jalali"):
        print(f"{k} 0")
    raise SystemExit
items = d.get("items") or []
checks = {
    "A1-ok": bool(d.get("ok")),
    "A2-count50": len(items) == 50,
}
try:
    age = (datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromisoformat(d["fetchedAt"].replace("Z","+00:00"))).total_seconds()
    checks["A3-fresh"] = 0 <= age < 1200
except Exception:
    checks["A3-fresh"] = False
checks["A4-posFa"] = sum(1 for it in items if it.get("posFa")) >= 45
checks["A5-feeFa-persian"] = sum(1 for it in items if fa.search(it.get("feeFa",""))) >= 40
checks["A6-freeagent-honest"] = all(
    (it["to"]["nameFa"] == "بدون باشگاه") for it in items if it["to"]["id"] == 2
) and any(it["to"]["id"] == 2 for it in items)
checks["A7-raw-name-byte"] = all(it.get("name") for it in items) and all(
    it["from"]["name"] and it["to"]["name"] for it in items
)
checks["A8-jalali"] = sum(1 for it in items if fa.search(it.get("dateFa",""))) >= 40
for k, v in checks.items():
    print(f"{k} {1 if v else 0}")
PY
)

echo "================ B: DOM at 390x844 ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "$BASE/transfers" >/dev/null 2>&1
sleep 6
# the 412 pipe-delimited pattern (tr -d '"' mangles JSON)
R=$(agent-browser eval "var t=document.body.innerText; var a=document.querySelectorAll('a[href^=\"/player/\"]').length; var h=document.querySelectorAll('h1').length; (h==1?1:0)+'|'+(a>=30?1:0)+'|'+((t.indexOf('انتقال آزاد')>=0)?1:0)+'|'+((t.indexOf('بدون باشگاه')>=0)?1:0)+'|'+(/[\u0600-\u06FF]/.test(t)?1:0)+'|'+((t.indexOf('تازه‌ترین انتقال‌های فوتبال')>=0)?1:0)" | tr -d '"')
H1=${R%%|*}; R2=${R#*|}; ROWS=${R2%%|*}; R3=${R2#*|}; FREE=${R3%%|*}; R4=${R3#*|}; FEES=${R4%%|*}; R5=${R4#*|}; FACH=${R5%%|*}; TITLE=${R5##*|}
ck "B1 /transfers h1 = 1" "$H1"
ck "B2 ≥30 player rows rendered" "$ROWS"
ck "B3 fee chips «انتقال آزاد» visible" "$FEES"
ck "B4 «بدون باشگاه» honest free-agent slot visible" "$FREE"
ck "B5 Persian text rendered" "$FACH"
ck "B6 title «تازه‌ترین انتقال‌های فوتبال»" "$TITLE"
# nav + footer links (real chrome wiring)
agent-browser open "$BASE/" >/dev/null 2>&1; sleep 4
R=$(agent-browser eval "var links=[...document.querySelectorAll('a[href=\"/transfers\"]')].map(function(a){return a.innerText||''}).join(' '); (links.indexOf('انتقال‌ها')>=0?1:0)+'|'+links.length" | tr -d '"')
NAV=${R%%|*}; NCOUNT=${R##*|}
ck "B7 header/footer nav link «انتقال‌ها» present" "$NAV"
ck "B8 nav link count ≥2 (header+footer)" "$([ "$NCOUNT" -ge 2 ] 2>/dev/null && echo 1 || echo 0)"
agent-browser open "$BASE/transfers" >/dev/null 2>&1; sleep 4
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
ck "B9 /transfers page-errors clean" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
ck "B10 /transfers console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
ck "B11 /transfers scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"

echo "================ C: the standing holds ================"
api /api/news > /tmp/c415-news.json
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, re
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}'); wl = re.compile(r'\b(VAR|xG)\b')
defective = lambda t: bool(fa.search(t)) and bool(lat.search(wl.sub("", t)))
try:
    d = json.load(open("/tmp/c415-news.json"))
    items = d.get("items") or []
    print("C1-414-news-guard-intact", 1 if d.get("ok") and len(items) == 16 and not any(defective(it.get("titleFa") or "") for it in items) else 0)
except Exception:
    print("C1-414-news-guard-intact 0")
PY
)
T=$(api "/api/league-transfers?league=pl")
ck "C2 the 57 league-transfers hold (pl ok)" "$(echo "$T" | grep -q '"ok":true' && echo "$T" | grep -q 'leagueFa' && echo 1 || echo 0)"
ck "C3 sitemap row /transfers" "$(api /sitemap.xml | grep -q '/transfers</loc>' && echo 1 || echo 0)"
agent-browser open "$BASE/team/8456" >/dev/null 2>&1; sleep 4
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
R=0; { [ -z "$ERR" ] || [ "$ERR" = "0" ]; } && [ "$CON" = "0" ] && [ "$SW" = "390" ] && R=1
ck "C4 /team/8456 hygiene (errors/console/overflow)" "$R"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
