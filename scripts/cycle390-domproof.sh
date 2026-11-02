#!/usr/bin/env bash
# cycle390-domproof.sh — update cycle 390: the NT-aware team surface (the
# 386 F2 update-scale decision, flipped to a working surface) + the two
# name-map heals it pulled in.
#
#   A1  /api/team/6711 (Iran NT) → 200 (386 F2 asserted the honest 404 here;
#       the update widens the contract: the -3..+10 window scan now falls
#       back to the upstream fixture archive when the window is empty)
#       — team.fa «ایران», recent ≥1, upcoming ≥1, prematch opponent Persian.
#   A2  the honest 404 contract ONLY WIDENS, never fakes: a team with
#       nothing upstream (999999999) keeps the same designed Persian 404;
#       the 400 shape guard stays.
#   A3  the Asian-Cup fixture row name heal: team-fixtures rows carry NO
#       ccode so the 385 CC-qualified keys never reached them — the bare
#       global «asian cup» + the 387 group family now compose
#       «جام ملت‌های آسیا — گروه C» (asserted on the live 6711 feed).
#   A4  «Gambia» → «گامبیا» on the same rows (the one unmapped side name).
#   A5  clubs unaffected: /api/team/10261 (Newcastle) still 200 with a
#       standings row (the fallback path is only entered when the window
#       scan comes up empty).
#   A6  the NT PAGE renders (DOM at 390x844): h1/team name Persian, the
#       fixtures groups render Persian rows, squad section reachable,
#       console clean, no horizontal overflow.
#   C   designed error contracts re-verified (400/404/502 classes).
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d390_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ A1: the NT-aware surface (the 386 F2 flip) ================"
S=$(st "/api/team/6711"); B=$(cat /tmp/d390_body.txt)
ck "A1a /api/team/6711 → 200 (was the honest 404 of the 386 F2 finding)" "$([ "$S" = 200 ] && echo 1 || echo 0)"
ck "A1b team name Persian «ایران» (teamFa covers the NT name)" "$([ "$(has "$B" '"fa":"ایران"')" = 1 ] && echo 1 || echo 0)"
RC=$(printf '%s' "$B" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('recent') or []), len(d.get('upcoming') or []))")
RN=$(printf '%s' "$RC" | cut -d' ' -f1); UN=$(printf '%s' "$RC" | cut -d' ' -f2)
echo "recent=$RN upcoming=$UN"
ck "A1c recent ≥1 and upcoming ≥1 (archive-derived rows)" "$([ "$RN" -ge 1 ] && [ "$UN" -ge 1 ] && echo 1 || echo 0)"
ck "A1d rows are fa-mapped (بازی دوستانه/فلسطین/روسیه present)" "$([ "$(has "$B" 'بازی دوستانه')" = 1 ] && [ "$(has "$B" 'فلسطین')" = 1 ] && [ "$(has "$B" 'روسیه')" = 1 ] && echo 1 || echo 0)"
ck "A1e prematch opponent Persian (فلسطین)" "$([ "$(has "$B" '"fa":"فلسطین"')" = 1 ] && echo 1 || echo 0)"

echo "================ A2: the widened-never-faked 404 contract ================"
S2=$(st "/api/team/999999999"); B2=$(head -c 80 /tmp/d390_body.txt)
ck "A2a team with nothing upstream keeps the designed 404" "$([ "$S2" = 404 ] && [ "$(has "$B2" 'بازی‌ای برای این تیم')" = 1 ] && echo 1 || echo 0)"
S3=$(st "/api/team/0"); B3=$(head -c 80 /tmp/d390_body.txt)
ck "A2b the 400 shape guard stays (شناسه تیم نامعتبر است)" "$([ "$S3" = 400 ] && [ "$(has "$B3" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"

echo "================ A3/A4: the name-map heals on the same feed ================"
TF=$(api "/api/team-fixtures/6711")
ck "A3a Asian Cup row composes Persian («جام ملت‌های آسیا — گروه C»)" "$([ "$(has "$TF" 'جام ملت‌های آسیا — گروه C')" = 1 ] && echo 1 || echo 0)"
ck "A3b the raw literal «Asian Cup Grp. C» is GONE" "$([ "$(has "$TF" 'Asian Cup Grp')" = 0 ] && echo 1 || echo 0)"
ck "A4 «گامبیا» renders (Gambia mapped)" "$([ "$(has "$TF" 'گامبیا')" = 1 ] && echo 1 || echo 0)"

echo "================ A5: clubs unaffected ================"
S4=$(st "/api/team/10261"); B4=$(cat /tmp/d390_body.txt)
ck "A5a /api/team/10261 (Newcastle) still 200" "$([ "$S4" = 200 ] && echo 1 || echo 0)"
ck "A5b club page keeps its standings context (rank/points block present)" "$([ "$(has "$B4" '"standings"')" = 1 ] && echo 1 || echo 0)"

echo "================ C: designed error contracts re-verified ================"
S5=$(st "/api/team-last-lineup/0"); B5=$(head -c 80 /tmp/d390_body.txt)
ck "C1 team-last-lineup/0 → 400 Persian" "$([ "$S5" = 400 ] && [ "$(has "$B5" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S6=$(st "/api/team-squad/notanumber"); B6=$(head -c 80 /tmp/d390_body.txt)
ck "C2 team-squad/notanumber → 400 Persian" "$([ "$S6" = 400 ] && [ "$(has "$B6" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S7=$(st "/api/team-last-lineup/5795503"); B7=$(head -c 80 /tmp/d390_body.txt)
ck "C3 team-last-lineup MATCH-id → 502 designed catch" "$([ "$S7" = 502 ] && [ "$(has "$B7" 'دریافت آخرین ترکیب ناموفق بود.')" = 1 ] && echo 1 || echo 0)"
SS=$(st "/sitemap.xml"); SR=$(st "/robots.txt")
ck "C4 sitemap.xml + robots.txt both 200" "$([ "$SS" = 200 ] && [ "$SR" = 200 ] && echo 1 || echo 0)"

echo "================ DOM: the NT team page at 390x844 ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open http://localhost:3000/team/6711 >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var t=document.body.innerText; var h1=document.querySelector('h1'); (h1?h1.textContent.trim():'none')+'|'+(t.indexOf('ایران')>=0?1:0)+'|'+(t.indexOf('بازی دوستانه')>=0?1:0)+'|'+(t.indexOf('ترکیب تیم')>=0?1:0)+'|'+(t.indexOf('تلاش مجدد')>=0?1:0)+'|'+(t.indexOf('فلسطین')>=0?1:0)" | tr -d '"')
H1=$(printf '%s' "$R" | cut -d'|' -f1); FIRA=$(printf '%s' "$R" | cut -d'|' -f2); FFRI=$(printf '%s' "$R" | cut -d'|' -f3); FSQ=$(printf '%s' "$R" | cut -d'|' -f4); FERR=$(printf '%s' "$R" | cut -d'|' -f5); FPAL=$(printf '%s' "$R" | cut -d'|' -f6)
echo "nt page: h1=$H1 faIran=$FIRA friendly=$FFRI squad=$FSQ errorState=$FERR palestine=$FPAL"
ck "D1 the NT page h1 renders «ایران» (got: $H1)" "$([ "$(has "$H1" 'ایران')" = 1 ] && echo 1 || echo 0)"
ck "D2 no honest-404 error state (تلاش مجدد absent)" "$([ "$FERR" = "0" ] && echo 1 || echo 0)"
ck "D3 fixture rows render Persian (بازی دوستانه + فلسطین)" "$([ "$FFRI" = "1" ] && [ "$FPAL" = "1" ] && echo 1 || echo 0)"
ck "D4 squad section reachable (ترکیب تیم)" "$([ "$FSQ" = "1" ] && echo 1 || echo 0)"
hyg() { local ERR CON SW CW
  sleep 3
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "$1 page-errors=0" "$([ -z "$ERR" ] && echo 1 || echo 0)"
  ck "$1 console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "$1 scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "390" ] && [ "$CW" = "390" ] && echo 1 || echo 0)"
}
hyg "team/6711"

# --- the club page still renders its own sections ---
agent-browser open http://localhost:3000/team/10261 >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; var h1=document.querySelector('h1'); (h1?h1.textContent.trim():'none')+'|'+(t.indexOf('گنجهٔ افتخارات')>=0?1:0)" | tr -d '"')
CH1=$(printf '%s' "$R" | cut -d'|' -f1); CTR=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D5 club page intact (h1 + گنجهٔ افتخارات)" "$([ -n "$CH1" ] && [ "$CTR" = "1" ] && echo 1 || echo 0)"
hyg "team/10261"

echo "================ summary ================"
echo "DOMPROF390 RESULT PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "ALL-CHECKS-GREEN" || echo "HAS-FAILURES"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
