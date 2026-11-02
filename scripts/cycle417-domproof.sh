#!/usr/bin/env bash
# cycle417-domproof.sh — update cycle 417 (فرمول ((417 mod 5)+1)=۳ — the
# 416 card's «417=بررسی باگ» line was a counting slip, corrected per the
# rotation law): «جام حذفی ایران» joins the catalog — the 33rd competition,
# fotmob league 9487, the Iranian domestic knockout cup. ONE catalog entry
# + 7 TEAM_FA keys + 1 COMPETITION_FA key; every surface rides the generic
# plumbing (the 382 growth pattern). Probe artifact: repo-external
# scripts/cycle417-probe.sh (live UA Chrome/124, 2026-11-02).
#   A   the API contracts: the pure-knockout shape served honestly
#       (noTable rows=[], 24 fixtures, 2 bracket rounds with stageFa,
#       14 title editions all-Persian), the deep-link season dimension
#       (2024/2025 → 31 fixtures), the negative guards (plain year /
#       two-digit second year → 400)
#   B   DOM at 390x844 on /league/hazfi: h1, the honest cup empty state
#       with the fixtures CTA (the cycle-376 contract), REAL tab clicks
#       (the 406/407 lesson) for براکت/قهرمانان, the season selector,
#       the honest ABSENCE of the transfers tab, the honest-empty
#       /topscorers/hazfi, sitemap rows, hygiene three-pack
#   C   the standing holds (home, 414 news guard, facup sibling cup,
#       persiangulf sibling league, 416 transfers)
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
code() { curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE$1"; }

echo "================ A: the Hazfi Cup API contracts ================"
api "/api/standings?league=hazfi" > /tmp/c417-st.json
api "/api/league-fixtures?league=hazfi" > /tmp/c417-fx.json
api "/api/league-bracket?league=hazfi" > /tmp/c417-br.json
api "/api/league-titles?league=hazfi" > /tmp/c417-ti.json
api "/api/standings?league=hazfi&season=2024/2025" > /tmp/c417-st24.json
api "/api/league-fixtures?league=hazfi&season=2024/2025" > /tmp/c417-fx24.json
C1=$(code "/api/standings?league=hazfi&season=2026"); C2=$(code "/api/standings?league=hazfi&season=2020%2F21")
while read -r k v; do ck "$k" "$v"; done < <(python3 - "$C1" "$C2" <<'PY'
import json, re, sys
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}')
def load(p):
    try: return json.load(open(p))
    except Exception: return {}
st, fx, br, ti = load("/tmp/c417-st.json"), load("/tmp/c417-fx.json"), load("/tmp/c417-br.json"), load("/tmp/c417-ti.json")
st24, fx24 = load("/tmp/c417-st24.json"), load("/tmp/c417-fx24.json")
brd = (br.get("bracket") or {})
rounds = brd.get("rounds") or []
recent = fx.get("recent") or []
names = []
for it in recent:
    for side in ("home", "away"):
        t = it.get(side) or {}
        names.append(t.get("fa") or "")
ti_items = ((ti.get("titles") or {}).get("items")) or []
checks = {
    # the pure-knockout contract (cycle-376): rows=[] + noTable + honest color/seasons
    "A1-standings-noTable-shape": st.get("ok") is True and st.get("rows") == [] and st.get("noTable") is True
        and st.get("color") == "#212121" and st.get("selectedSeason") == "2025/2026"
        and len(st.get("allSeasons") or []) == 12,
    "A2-leagueFa-persian": st.get("leagueFa") == "جام حذفی ایران" and fx.get("leagueFa") == "جام حذفی ایران",
    # the fixture dimension: 24 finished matches, recent tab filled, upcoming honestly empty
    # (the 1/4 round is not drawn yet upstream — the honest state)
    "A3-fixtures-24-recent10": fx.get("ok") is True and fx.get("total") == 24 and len(recent) == 10 and fx.get("upcoming") == [],
    "A4-roundFa-named-rounds": all("نهایی" in (it.get("round") or "") for it in recent),
    "A5-teamFa-fixture-rows-persian": len(recent) > 0 and all(n and fa.search(n) and not lat.search(n) for n in names),
    # the bracket dimension: 2 played rounds with the BRACKET_STAGE_FA labels
    "A6-bracket-2-rounds-stageFa": br.get("ok") is True and len(rounds) == 2
        and rounds[0].get("stageFa") == "یک‌شانزدهم نهایی" and rounds[1].get("stageFa") == "یک‌هشتم نهایی"
        and len(rounds[0].get("matchups") or []) == 16 and len(rounds[1].get("matchups") or []) == 8,
    "A7-bracket-winners-resolved": all(isinstance(m.get("winnerId"), int) and m.get("winnerId", 0) > 0
        for r in rounds for m in (r.get("matchups") or [])),
    # the title-history dimension (cycle-121): 14 editions, every name Persian
    "A8-titles-14-persian": ti.get("ok") is True and (ti.get("titles") or {}).get("total") == 14
        and all(fa.search((it.get("championFa") or "")) and not lat.search(it.get("championFa") or "")
                and (it.get("runnerUpFa") in (None, "") or (fa.search(it.get("runnerUpFa") or "x") and not lat.search(it.get("runnerUpFa") or "")))
                for it in ti_items),
    "A9-titles-champion-esteghlal": ti_items and ti_items[0].get("championFa") == "استقلال" and ti_items[0].get("runnerUpFa") == "ملوان",
    # the deep-link season dimension: the 2024/2025 edition answers with its own data
    "A10-season-2425-echo": st24.get("ok") is True and st24.get("selectedSeason") == "2024/2025",
    "A11-fixtures-2425-31rows": fx24.get("ok") is True and fx24.get("total") == 31 and fx24.get("selectedSeason") == "2024/2025",
    # the negative guards: plain year (the 382 contract) and the two-digit second year
    "A12-negative-guards-400": sys.argv[1] == "400" and sys.argv[2] == "400",
}
for k, v in checks.items():
    print(f"{k} {1 if v else 0}")
PY
)

echo "================ B: DOM at 390x844 (/league/hazfi) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "$BASE/league/hazfi" >/dev/null 2>&1
sleep 7
R=$(agent-browser eval "var h=document.querySelector('h1'); var t=document.body.innerText; (h?h.textContent.trim():'')+'|'+((t.indexOf('جدولی برای این لیگ ثبت نشده است')>=0)?1:0)+'|'+((t.indexOf('مسابقات حذفی جدول رده‌بندی ندارند')>=0)?1:0)+'|'+((t.indexOf('مشاهده‌ی برنامه‌ی بازی‌ها')>=0)?1:0)+'|'+(([...document.querySelectorAll('button')].some(function(b){return (b.textContent||'').trim()==='انتقال‌ها'}))?1:0)" | tr -d '"')
H1=${R%%|*}; R2=${R#*|}; EMPTY=${R2%%|*}; R3=${R2#*|}; NOTBL=${R3%%|*}; R4=${R3#*|}; CTA=${R4%%|*}; R5=${R4#*|}; HASTRANS=${R5%%|*}
ck "B1 h1 «جام حذفی ایران»" "$([ "$H1" = "جام حذفی ایران" ] && echo 1 || echo 0)"
ck "B2 honest cup empty state (cycle-376 copy)" "$EMPTY"
ck "B3 noTable sub-copy present" "$NOTBL"
ck "B4 fixtures CTA present" "$CTA"
ck "B5 no «انتقال‌ها» TAB (nav link must not count)" "$([ "$HASTRANS" = "0" ] && echo 1 || echo 0)"
# REAL CTA click → the fixtures tab becomes ACTIVE with the honest upcoming
# empty state (quarter-finals not drawn yet — zero upcoming is the truthful
# state), then the «فصل کامل» expander serves the real 24-row witness
# (the 406/407 lesson: the witness from the actually-rendered state)
agent-browser eval "var b=[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').indexOf('مشاهده‌ی برنامه‌ی بازی‌ها')>=0}); (b||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var tabs=[...document.querySelectorAll('nav button')]; var act=tabs.find(function(x){return x.getAttribute('aria-current')==='page'}); var t=document.body.innerText; (act?act.textContent.trim():'')+'|'+((t.indexOf('برنامه‌ی بازی‌های پیش‌رو ثبت نشده است')>=0)?1:0)" | tr -d '"')
ACT=${R%%|*}; R2=${R#*|}; UPEMPTY=${R2%%|*}
ck "B6 CTA opens «بازی‌های پیش‌رو» tab (aria-selected)" "$([ "$ACT" = "بازی‌های پیش‌رو" ] && echo 1 || echo 0)"
ck "B7 honest upcoming-empty copy (no draws yet upstream)" "$UPEMPTY"
agent-browser eval "var b=[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').indexOf('نمایش همهٔ مسابقه‌های فصل')>=0}); (b||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var t=document.body.innerText; var faRow=(t.indexOf('استقلال')>=0||t.indexOf('تراکتور')>=0)?1:0; var rnd=((t.indexOf('یک‌هشتم نهایی')>=0||t.indexOf('یک‌شانزدهم نهایی')>=0)||t.indexOf('هفتهٔ')>=0)?1:0; faRow+'|'+rnd" | tr -d '"')
FAROW=${R%%|*}; RND=${R#*|}
ck "B8 full-season list renders Persian teams" "$FAROW"
ck "B9 full-season list renders round labels" "$RND"
# REAL «براکت» tab click
agent-browser eval "var b=[...document.querySelectorAll('button[role=tab]')].find(function(x){return (x.textContent||'').trim()==='براکت'})||[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').trim()==='براکت'}); (b||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; ((t.indexOf('یک‌شانزدهم نهایی')>=0)?1:0)+'|'+((t.indexOf('یک‌هشتم نهایی')>=0)?1:0)+'|'+((t.indexOf('هوادار')>=0||t.indexOf('برق شیراز')>=0)?1:0)" | tr -d '"')
S16=${R%%|*}; R2=${R#*|}; S18=${R2%%|*}; R3=${R2#*|}; TM=${R3%%|*}
ck "B10 bracket tab: «یک‌شانزدهم نهایی» renders" "$S16"
ck "B11 bracket tab: «یک‌هشتم نهایی» renders" "$S18"
ck "B12 bracket matchup teams Persian in DOM" "$TM"
# REAL «قهرمانان» tab click
agent-browser eval "var b=[...document.querySelectorAll('button')].find(function(x){return (x.textContent||'').trim()==='قهرمانان'}); (b||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; ((t.indexOf('استقلال')>=0)?1:0)+'|'+((t.indexOf('۲۰۲۴/۲۵')>=0||t.indexOf('۲۰۲۴/۲۰۲۵')>=0)?1:0)+'|'+((t.indexOf('مس‌رفسنجان')>=0)?1:0)" | tr -d '"')
EST=${R%%|*}; R2=${R#*|}; SEAS=${R2%%|*}; R3=${R2#*|}; RAF=${R3%%|*}
ck "B13 titles tab: «استقلال» champion renders" "$EST"
ck "B14 titles tab: faDigits season renders" "$SEAS"
ck "B15 titles tab: «مس‌رفسنجان» (the new-map name family) renders" "$RAF"
# season selector (the 99/101 contract) — 12 slash seasons offered
R=$(agent-browser eval "var sels=[...document.querySelectorAll('select option')].length; var cur=(document.body.innerText.indexOf('فعلی')>=0)?1:0; sels+'|'+cur" | tr -d '"')
NOPT=${R%%|*}; R2=${R#*|}; CUR=${R2%%|*}
ck "B16 season selector options ≥12" "$([ "$NOPT" -ge 12 ] 2>/dev/null && echo 1 || echo 0)"
ck "B17 «(فعلی)» current-season marker" "$CUR"
# hygiene three-pack
ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
CON=$(agent-browser console 2>/dev/null | grep -ci error)
SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
ck "B18 page-errors clean" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
ck "B19 console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
ck "B20 no overflow scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"
# the honest-empty scorers page + sitemap rows + sibling hold
TSC=$(code "/topscorers/hazfi")
ck "B21 /topscorers/hazfi 200" "$([ "$TSC" = "200" ] && echo 1 || echo 0)"
api "/sitemap.xml" > /tmp/c417-sm.xml
SMH=$(grep -c '/league/hazfi</loc>' /tmp/c417-sm.xml 2>/dev/null || echo 0)
ck "B22 sitemap /league/hazfi" "$([ "${SMH:-0}" -ge 1 ] 2>/dev/null && echo 1 || echo 0)"
agent-browser open "$BASE/topscorers/hazfi" >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; ((t.indexOf('جام حذفی ایران')>=0)?1:0)+'|'+((t.indexOf('آقای گل')>=0||t.indexOf('گلزن')>=0)?1:0)" | tr -d '"')
H=${R%%|*}; R2=${R#*|}; G=${R2%%|*}
ck "B23 topscorers h1 league name renders" "$H"
ck "B24 topscorers honest-empty block renders" "$G"

echo "================ C: the standing holds ================"
api "/api/news" > /tmp/c417-news.json
api "/api/transfers" > /tmp/c417-tr.json
api "/api/standings?league=facup" > /tmp/c417-facup.json
api "/api/standings?league=persiangulf" > /tmp/c417-pg.json
while read -r k v; do ck "$k" "$v"; done < <(python3 - <<'PY'
import json, re
fa = re.compile(r'[\u0600-\u06FF]'); lat = re.compile(r'[A-Za-z]{2,}'); wl = re.compile(r'\b(VAR|xG)\b')
defective = lambda t: bool(fa.search(t)) and bool(lat.search(wl.sub("", t)))
def load(p):
    try: return json.load(open(p))
    except Exception: return {}
news, tr, facup, pg = load("/tmp/c417-news.json"), load("/tmp/c417-tr.json"), load("/tmp/c417-facup.json"), load("/tmp/c417-pg.json")
checks = {
    "C1-414-news-guard-intact": news.get("ok") is True and len(news.get("items") or []) == 16
        and not any(defective(it.get("titleFa") or "") for it in news.get("items") or []),
    "C2-416-transfers-50-intact": tr.get("ok") is True and len(tr.get("items") or []) == 50 and tr.get("minFee") is None,
    "C3-facup-sibling-cup-hold": facup.get("ok") is True and facup.get("rows") == [] and facup.get("noTable") is True,
    "C4-persiangulf-sibling-hold": pg.get("ok") is True and len(pg.get("rows") or []) >= 16,
}
for k, v in checks.items():
    print(f"{k} {1 if v else 0}")
PY
)
HOM=$(code "/")
ck "C5 home 200" "$([ "$HOM" = "200" ] && echo 1 || echo 0)"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
