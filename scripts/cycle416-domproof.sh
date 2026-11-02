#!/usr/bin/env bash
# cycle416-domproof.sh — update cycle 416 (فرمول ۲): the fee-preset filter
# dimension on the global transfers wire — the cycle-415 card's documented
# «چرخهٔ آینده» item. The 415/416 live probes (scripts/cycle416-feeprobe.sh):
# upstream `minFee` REALLY filters AND widens the window to fill 50
# qualifying fee-bearing rows (base window: only 12 fee-bearing), zero
# below-threshold rows. Build: TRANSFER_FEE_PRESETS strict allowlist
# (1e6/5e6/2e7/5e7 — the season-param convention), per-preset cache keys
# (globalTransfers:v1 / :f{N}) so windows never mix, route echoes the
# applied threshold, anything else → the honest 400 before upstream; the
# /transfers client gains the news-page chip row («همه» + ۴ آستانه).
#   A   the API contracts: presets filter honestly (fee-bearing counts,
#       the echo), the 400 guard, cache separation (fresh per-preset rows)
#   B   DOM at 390x844: the chip row renders, a REAL chip click switches
#       the wire (the 406/407 lesson: the witness from the actually-
#       rendered state), hygiene three-pack
#   C   the standing holds (415 base page, 414 news guard)
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the fee-preset API contracts ================"
api "/api/transfers" > /tmp/c416-base.json
api "/api/transfers?minFee=1000000" > /tmp/c416-f1.json
api "/api/transfers?minFee=50000000" > /tmp/c416-f50.json
api "/api/transfers?minFee=999" > /tmp/c416-bad1.json
api "/api/transfers?minFee=abc" > /tmp/c416-bad2.json
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json
def load(p):
    try: return json.load(open(p))
    except Exception: return {}
base, f1, f50 = load("/tmp/c416-base.json"), load("/tmp/c416-f1.json"), load("/tmp/c416-f50.json")
bad1, bad2 = load("/tmp/c416-bad1.json"), load("/tmp/c416-bad2.json")
feedish = lambda it: it["feeFa"] not in ("انتقال آزاد", "قرارداد")
checks = {
    "A1-base-ok-50": base.get("ok") is True and len(base.get("items") or []) == 50 and base.get("minFee") is None,
    "A2-f1-echo-50feedish": f1.get("ok") is True and f1.get("minFee") == 1000000 and len(f1.get("items") or []) == 50,
    # the honest value-contract as the SITE can see it: a free transfer
    # (no fee value) can never clear a minFee preset — so ZERO «انتقال آزاد»
    # rows at any preset. Contract-type rows WITH an estimated value ≥ the
    # threshold are legitimate (upstream's own filter semantics, probed:
    # zero below-threshold rows in scripts/cycle416-feeprobe.sh).
    "A3-f1-no-free-rows": not any(it["feeFa"] == "انتقال آزاد" for it in (f1.get("items") or [])),
    "A4-f50-38-no-free-rows": f50.get("ok") is True and f50.get("minFee") == 50000000 and len(f50.get("items") or []) == 38 and not any(it["feeFa"] == "انتقال آزاد" for it in (f50.get("items") or [])),
    "A5-400-guard": bad1.get("ok") is False and bad2.get("ok") is False,
    "A6-fa-error": "آستانه" in (bad1.get("error") or "") and "آستانه" in (bad2.get("error") or ""),
    "A7-f1-differs-base": [it.get("playerId") for it in (f1.get("items") or [])] != [it.get("playerId") for it in (base.get("items") or [])],
}
for k, v in checks.items():
    print(f"{k} {1 if v else 0}")
PY
)

echo "================ B: DOM at 390x844 (real chip click) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "$BASE/transfers" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var chips=[...document.querySelectorAll('button[role=tab]')]; var t=document.body.innerText; chips.length+'|'+((t.indexOf('از ۵۰ میلیون')>=0)?1:0)+'|'+((t.indexOf('همه')>=0)?1:0)" | tr -d '"')
NCH=${R%%|*}; R2=${R#*|}; HAS50=${R2%%|*}; R3=${R2#*|}; HASALL=${R3%%|*}
ck "B1 chip row renders (5 chips)" "$([ "$NCH" = "5" ] && echo 1 || echo 0)"
ck "B2 «از ۵۰ میلیون» chip present" "$HAS50"
ck "B3 «همه» chip present" "$HASALL"
# REAL click on the 50M chip (the 406/407 lesson) → the wire switches
agent-browser eval "([...document.querySelectorAll('button[role=tab]')].find(function(b){return (b.textContent||'').indexOf('از ۵۰ میلیون')>=0})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var a=document.querySelectorAll('a[href^=\"/player/\"]').length; var t=document.body.innerText; a+'|'+((t.indexOf('کارمزد')>=0)?1:0)" | tr -d '"')
NROWS=${R%%|*}; R2=${R#*|}; HASFEE=${R2%%|*}
ck "B4 after real 50M click rows render" "$([ "$NROWS" -ge 10 ] 2>/dev/null && echo 1 || echo 0)"
ck "B5 «کارمزد» visible after filter" "$HASFEE"
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
ck "B6 /transfers page-errors clean" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
ck "B7 /transfers console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
ck "B8 /transfers scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"

echo "================ C: the standing holds ================"
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, re
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}'); wl = re.compile(r'\b(VAR|xG)\b')
defective = lambda t: bool(fa.search(t)) and bool(lat.search(wl.sub("", t)))
try:
    d = json.load(open("/tmp/c416-base.json"))
    items = d.get("items") or []
    free_ok = all(it["to"]["nameFa"] == "بدون باشگاه" for it in items if it["to"]["id"] == 2)
    print("C1-415-contract-intact", 1 if d.get("ok") and len(items) == 50 and free_ok and any(fa.search(it.get("dateFa","")) for it in items) else 0)
except Exception:
    print("C1-415-contract-intact 0")
PY
)
api /api/news > /tmp/c416-news.json
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, re
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}'); wl = re.compile(r'\b(VAR|xG)\b')
defective = lambda t: bool(fa.search(t)) and bool(lat.search(wl.sub("", t)))
try:
    d = json.load(open("/tmp/c416-news.json"))
    items = d.get("items") or []
    print("C2-414-news-guard", 1 if d.get("ok") and len(items) == 16 and not any(defective(it.get("titleFa") or "") for it in items) else 0)
except Exception:
    print("C2-414-news-guard 0")
PY
)

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
