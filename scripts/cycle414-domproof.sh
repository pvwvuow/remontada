#!/usr/bin/env bash
# cycle414-domproof.sh — fix cycle 414 (فرمول ۵): the mixed-script hygiene
# guard for the LLM translate stage. The cycle-414 probe caught 4 of the 16
# live news titles carrying DEFECTIVE partial transliterations — Persian-
# dominant strings with an embedded Latin run where a name was split mid-word
# across alphabets («آستون villa», «فerguson», «مikel آرتا», «فان دیjk») —
# served from the poisoned news:v3 row. Fix = (1) the guard: defectiveFaTitle()
# inside translateBatch (BOTH consumers inherit — the feed's translateTitles
# and the /api/team-news digest) rejects such rows; the slot stays null → the
# caller keeps the honest English original (the cycle-104 convention: a
# dubious transliteration is worse than the honest English name); deterministic,
# free, no second LLM round-trip (the 134/135 cold-budget class stays safe);
# a tiny case-sensitive whitelist keeps VAR/xG legal; (2) the keys:
# news:v3→v4 + teamNewsFa:{id}→teamNewsFaV2:{id} shed the poisoned pre-guard
# rows (the 294/414 move). The guard's TWO honest outcomes per row: the
# English original (titleFa === title) or a clean Persian title — never a mix.
#   A   the LIVE invariant: zero mixed-script titleFa rows; honest English
#       fallbacks present; Persian titles still flowing (guard not overfiring).
#   B   the contracts: guard unit test 12/12 on the four live defects + clean
#       rows + whitelist + pure-English; the warm news:v4 search fold; rss;
#       the guarded team digest on its V2 key; diff scope; fetchedAt freshness.
#   C   DOM at 390x844: /news renders, Persian + honest-English rows visible,
#       h1=1, console clean, no overflow + the standing anchors (real tab
#       clicks — the 407/412 lesson).
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
info_tab_click() {
  agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='اطلاعات'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
}

echo "================ A: the 414 live invariant (API level) ================"
api /api/news > /tmp/c414-news.json
while read -r k v; do ck "A $k" "$v"; done < <(python3 - <<'PY'
import json, re
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}'); wl = re.compile(r'\b(VAR|xG)\b')
defective = lambda t: bool(fa.search(t)) and bool(lat.search(wl.sub("", t)))
try:
    d = json.load(open("/tmp/c414-news.json"))
except Exception:
    for k in ("json","count16","invariant","persian","enfallback","en4present","en4shape"):
        print(f"{k} 0")
    raise SystemExit
items = d.get("items", [])
checks = {
    "json": bool(d.get("ok")),
    "count16": len(items) == 16,
    "invariant": not any(defective(it.get("titleFa") or "") for it in items),
    "persian": any(fa.search(it.get("titleFa") or "") for it in items),
    "enfallback": any((it.get("titleFa") or "") == (it.get("title") or "") for it in items),
}
needles = ["Aston Villa's Pau Torres", "post-Ferguson", "Mikel Arteta told me", "van Dijk after Arsenal"]
hits = [it for it in items if any(n in (it.get("title") or "") for n in needles)]
checks["en4present"] = len(hits) >= 1
checks["en4shape"] = all(
    (it.get("titleFa") or "") == (it.get("title") or "") or not defective(it.get("titleFa") or "")
    for it in hits
) if hits else False
for k, v in checks.items():
    print(f"{k} {1 if v else 0}")
PY
)

echo "================ B: the fix contracts ================"
BUN=$(bun scripts/cycle414-guard-test.ts 2>&1 | tail -1)
echo "$BUN"
ck "B1 guard-unit GUARD-TEST PASS 12/12" "$([ -n "$BUN" ] && echo "$BUN" | grep -q 'GUARD-TEST PASS 12/12' && echo 1 || echo 0)"
# B2: the warm news:v4 search fold (رایس percent-encoded — the B15 lesson)
api "/api/search?q=%D8%B1%D8%A7%DB%8C%D8%B3" > /tmp/c414-search.json
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json
try:
    d = json.load(open("/tmp/c414-search.json"))
    n = d.get("news") or []
    print("B2-warm-search-fold-news-v4", 1 if d.get("ok") and len(n) >= 1 else 0)
except Exception:
    print("B2-warm-search-fold-news-v4 0")
PY
)
# B3: rss renders the guarded feed (200 + Persian + valid channel)
api /rss.xml > /tmp/c414-rss.txt
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
t = open("/tmp/c414-rss.txt", encoding="utf-8", errors="replace").read()
ok = t.startswith("<?xml") and any("\u0600" <= c <= "\u06FF" for c in t)
print("B3-rss-200-persian", 1 if ok else 0)
PY
)
# B4: the team digest on its guarded V2 key — zero defective titleFa
api /api/team-news/8456 > /tmp/c414-teamnews.json
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, re
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}'); wl = re.compile(r'\b(VAR|xG)\b')
defective = lambda t: bool(fa.search(t)) and bool(lat.search(wl.sub("", t)))
try:
    d = json.load(open("/tmp/c414-teamnews.json"))
    items = (d.get("news") or {}).get("items") or []
    print("B4-team-digest-guarded", 1 if d.get("ok") and len(items) >= 1 and not any(defective(it.get("titleFa") or "") for it in items) else 0)
except Exception:
    print("B4-team-digest-guarded 0")
PY
)
# B5: diff scope = exactly the five src files
MOD=$(git diff --name-only | sort | tr '\n' ',' )
ck "B5 diff scope 5 src files" "$([ "$MOD" = "src/app/api/news/route.ts,src/app/api/search/route.ts,src/app/api/team-news/[id]/route.ts,src/app/rss.xml/route.ts,src/lib/news.ts," ] && echo 1 || echo 0)"
# B6: fetchedAt freshness (< 20 min)
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, datetime
try:
    d = json.load(open("/tmp/c414-news.json"))
    age = (datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromisoformat(d["fetchedAt"].replace("Z", "+00:00"))).total_seconds()
    print("B6-fetchedAt-fresh", 1 if 0 <= age < 1200 else 0)
except Exception:
    print("B6-fetchedAt-fresh 0")
PY
)

echo "================ C: DOM at 390x844 ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "$BASE/news" >/dev/null 2>&1
sleep 6
# the 412 pattern: a pipe-delimited triple, not JSON (tr -d '"' mangles JSON)
R=$(agent-browser eval "var t=document.body.innerText; var h=document.querySelectorAll('h1').length; (h==1?1:0)+'|'+(/[\u0600-\u06FF]/.test(t)?1:0)+'|'+((t.indexOf('Aston Villa')>=0||t.indexOf('post-Ferguson')>=0||t.indexOf('Mikel Arteta')>=0||t.indexOf('van Dijk')>=0)?1:0)" | tr -d '"')
H1=${R%%|*}; REST=${R#*|}; FA=${REST%%|*}; EN=${REST##*|}
ck "C1 /news h1 count = 1" "$H1"
ck "C2 /news Persian title rendered in DOM" "$FA"
ck "C3 /news honest-English fallback row visible" "$EN"
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
ck "C4 /news page-errors clean (empty or 0)" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
ck "C5 /news console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
ck "C6 /news scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"
# standing anchors — the 412 hold re-asserted with a REAL «اطلاعات» click
agent-browser open "$BASE/match/5795503" >/dev/null 2>&1; sleep 4
info_tab_click; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ورزشگاه')>=0&&t.indexOf('داور')>=0)?1:0" | tr -d '"')
ck "C7 the 412 hold: venue/referee rows still fa-first (real click)" "$R"
agent-browser open "$BASE/team/8456" >/dev/null 2>&1; sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('اخبار باشگاه')>=0||t.indexOf('سیتی')>=0||t.indexOf('مانچستر')>=0)?1:0" | tr -d '"')
ck "C8 /team/8456 anchor renders" "$R"
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
R=0; { [ -z "$ERR" ] || [ "$ERR" = "0" ]; } && [ "$CON" = "0" ] && [ "$SW" = "390" ] && R=1
cat /dev/null; ck "C9 /team/8456 hygiene (errors/console/overflow)" "$R"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
