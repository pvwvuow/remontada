#!/usr/bin/env bash
# cycle392-domproof.sh — update cycle 392: the transfers-surface player-name
# leak (388 F4/F6) flipped through the PLAYER_NAME_FA pool (428 entries).
#
#   V1  /api/team-transfers/10261 → 200; the flagship pool is Persian:
#       «نیکو گونسالس», «اسون بوتمن», «جمال لاسلز», «هیده‌ماسا موریتا» —
#       and ZERO raw rows remain on the whole 30-item feed.
#   V2  /api/league-transfers?league={pl,laliga,ligue1} → the feeds heal on
#       the live rows: «دیوید آکینتولا»/«جک گریلیش» (pl), «دانیل کارواخال»
#       (laliga), «کیتو ناکامورا» (ligue1) — witnesses located per-feed first.
#   F1  honest passthrough INTACT — the deliberately-absent ambiguous names
#       (Beto single-token class, «Shumaira Mheuka» doubtful spelling) stay
#       raw Latin, never faked; raw «name» stays byte-exact (additive).
#   C   untouched contracts: shape guard abc → 400; unknown league → 400;
#       Persepolis feed untouched.
#   D   DOM at 390x844 (house pattern: one pipe-separated eval + tr -d '"'):
#       /team/10261 renders the Persian transfer rows with NO raw Latin
#       leader; /league/pl transfers tab renders «دیوید آکینتولا»; hygiene
#       three-pack page-errors=0 + console-errors=0 + scrollW=cw=390 on both.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d392_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ V1: the flagship team-transfers feed (10261) ================"
S=$(st "/api/team-transfers/10261"); B=$(cat /tmp/d392_body.txt)
ck "V1a /api/team-transfers/10261 → 200" "$([ "$S" = 200 ] && echo 1 || echo 0)"
ck "V1b «نیکو گونسالس» (Nico González)" "$([ "$(has "$B" 'نیکو گونسالس')" = 1 ] && echo 1 || echo 0)"
ck "V1c «اسون بوتمن» (Sven Botman)" "$([ "$(has "$B" 'اسون بوتمن')" = 1 ] && echo 1 || echo 0)"
ck "V1d «جمال لاسلز» (Jamaal Lascelles)" "$([ "$(has "$B" 'جمال لاسلز')" = 1 ] && echo 1 || echo 0)"
ZERO=$(printf '%s' "$B" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(1 if all(it['nameFa']!=it['name'] for it in d['transfers']['items']) else 0)")
ck "V1e ZERO raw nameFa rows on the whole feed" "$ZERO"

B=$(api "/api/team-transfers/8667")
ck "V1f «هیده‌ماسا موریتا» heals on the 8667 feed (Morita witness)" "$([ "$(has "$B" 'هیده‌ماسا موریتا')" = 1 ] && echo 1 || echo 0)"

echo "================ V2: the league feeds heal on live rows ================"
B=$(api "/api/league-transfers?league=pl")
ck "V2a «دیوید آکینتولا» (David Akintola)" "$([ "$(has "$B" 'دیوید آکینتولا')" = 1 ] && echo 1 || echo 0)"
ck "V2b «جک گریلیش» (Jack Grealish)" "$([ "$(has "$B" 'جک گریلیش')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/league-transfers?league=laliga")
ck "V2c «دانیل کارواخال» (Daniel Carvajal, laliga)" "$([ "$(has "$B" 'دانیل کارواخال')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/league-transfers?league=ligue1")
ck "V2d «کیتو ناکامورا» (Keito Nakamura, ligue1)" "$([ "$(has "$B" 'کیتو ناکامورا')" = 1 ] && echo 1 || echo 0)"

echo "================ F1: the honest passthrough (deliberate absences) ================"
B=$(api "/api/league-transfers?league=pl")
ck "F1a single-token «Beto» stays raw on pl (ambiguous class)" "$([ "$(has "$B" '"name":"Beto"')" = 1 ] && echo 1 || echo 0)"
ck "F1b «Beto» NOT transliterated" "$([ "$(has "$B" '"nameFa":"بتو"')" = 0 ] && echo 1 || echo 0)"
B=$(api "/api/team-transfers/10261")
ck "F1c raw «name» stays byte-exact (additive)" "$([ "$(has "$B" '"name":"Nico González"')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/league-transfers?league=pl")
ck "F1d doubtful spelling «Shumaira Mheuka» stays raw" "$([ "$(has "$B" '"name":"Shumaira Mheuka"')" = 1 ] && echo 1 || echo 0)"

echo "================ C1-C2: untouched contracts ================"
S=$(st "/api/team-transfers/abc"); B=$(cat /tmp/d392_body.txt)
ck "C1a team-transfers abc → 400" "$([ "$S" = 400 ] && echo 1 || echo 0)"
ck "C1b Persian error contract" "$([ "$(has "$B" 'شناسه')" = 1 ] && echo 1 || echo 0)"
S=$(st "/api/league-transfers?league=nope"); B=$(cat /tmp/d392_body.txt)
ck "C2a unknown league key → 400" "$([ "$S" = 400 ] && echo 1 || echo 0)"
B=$(api "/api/team-transfers/101610")
ck "C2b Persepolis feed answers ok (untouched)" "$([ "$(has "$B" '"ok":true')" = 1 ] && echo 1 || echo 0)"

echo "================ D: DOM at 390x844 (house agent-browser pattern) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open http://localhost:3000/team/10261 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.querySelector('[data-testid=team-transfers]'); (t? (t.innerText.indexOf('نیکو گونسالس')>=0?1:0):0)+'|'+(t? (t.innerText.indexOf('اسون بوتمن')>=0?1:0):0)+'|'+(t? (t.innerText.indexOf('Nico González')===-1?1:0):0)" | tr -d '"')
DN=$(printf '%s' "$R" | cut -d'|' -f1); DB=$(printf '%s' "$R" | cut -d'|' -f2); DR=$(printf '%s' "$R" | cut -d'|' -f3)
ck "D1 team DOM renders «نیکو گونسالس» (got: $R)" "$([ "$DN" = "1" ] && echo 1 || echo 0)"
ck "D2 team DOM renders «اسون بوتمن»" "$([ "$DB" = "1" ] && echo 1 || echo 0)"
ck "D3 team DOM has NO raw «Nico González» row" "$([ "$DR" = "1" ] && echo 1 || echo 0)"

agent-browser open http://localhost:3000/team/8667 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.querySelector('[data-testid=team-transfers]'); (t? (t.innerText.indexOf('هیده‌ماسا موریتا')>=0?1:0):0)" | tr -d '"')
ck "D4 /team/8667 DOM renders «هیده‌ماسا موریتا» (got: $R)" "$([ "$R" = "1" ] && echo 1 || echo 0)"

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
hyg "team/10261"

agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var b=[].slice.call(document.querySelectorAll('button')); var x=b.find(function(e){return e.textContent.trim()==='انتقال‌ها'}); x?(x.click(),'1'):'0'" | tr -d '"')
ck "D5 league «انتقال‌ها» tab found+clicked" "$([ "$R" = "1" ] && echo 1 || echo 0)"
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('دیوید آکینتولا')>=0?1:0)+'|'+(t.indexOf('David Akintola')===-1?1:0)" | tr -d '"')
DA=$(printf '%s' "$R" | cut -d'|' -f1); DN2=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D6 league transfers tab renders «دیوید آکینتولا» (got: $R)" "$([ "$DA" = "1" ] && echo 1 || echo 0)"
ck "D7 league transfers tab has NO raw «David Akintola»" "$([ "$DN2" = "1" ] && echo 1 || echo 0)"
hyg "league/pl"

echo "=== result ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE392 DOMPROOF OK" || echo "CYCLE392 DOMPROOF FAILED"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
