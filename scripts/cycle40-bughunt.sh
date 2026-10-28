#!/usr/bin/env bash
# cycle-40 bug-hunt patrol — report-only, no fixes
BASE="${BASE:-http://localhost:3000}"
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS  $1"; }
bad() { fail=$((fail+1)); echo "FAIL  $1"; }
chk() { # chk <name> <condition-result(0=pass)>
  if [ "$2" -eq 0 ]; then ok "$1"; else bad "$1"; fi
}

echo "=== 1) core pages (status + ms) ==="
for p in "/" "/leagues" "/topscorers" "/news" "/topscorers/pl" "/topscorers/laliga" "/league/pl" "/league/laliga" "/league/persiangulf" "/team/8633" "/team/8634" "/player/696679" "/match/5749720" "/robots.txt" "/sitemap.xml" "/manifest.webmanifest"; do
  code=$(curl -s -o /dev/null -w '%{http_code} %{time_total}' "$BASE$p")
  s=$(echo "$code" | cut -d' ' -f1); t=$(echo "$code" | cut -d' ' -f2)
  [ "$s" = "200" ] && ok "$p -> $s (${t}ms)" || bad "$p -> $s"
done

echo "=== 2) cycle-33 SEO contracts (invalid ids) ==="
for id in "" "abc" "1" "99999999999999999999"; do
  u="$BASE/match/${id}x"
  html=$(curl -s "$u")
  nox=$(echo "$html" | rg -c 'noindex' || true); nox=${nox:-0}
  can=$(echo "$html" | rg -c 'rel="canonical"' || true); can=${can:-0}
  [ "$nox" -ge 1 ] && [ "$can" = "0" ] && ok "/match/${id}x noindex=1 canonical=0" || bad "/match/${id}x noindex=$nox canonical=$can"
done

echo "=== 3) persiangulf graceful 503 ==="
code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/api/standings?league=persiangulf")
[ "$code" = "503" ] && ok "api/standings persiangulf -> 503" || bad "persiangulf -> $code"
msg=$(curl -s "$BASE/api/standings?league=persiangulf" | rg -o 'موقتاً در دسترس نیست' | head -1)
[ -n "$msg" ] && ok "persiangulf Persian message present" || bad "persiangulf message missing"

echo "=== 4) cycle-37 feature: /api/search min-length message ==="
r=$(curl -s "$BASE/api/search?q=x")
echo "$r" | rg -q 'حداقل ۲ کاراکتر' && ok "1-char -> explicit Persian message" || bad "1-char message missing: $r"
echo "$r" | rg -q '"ok":true' && echo "$r" | rg -q '"results":\[\]' && ok "ok:true + results:[] compat kept" || bad "compat fields changed: $r"
r2=$(curl -s "$BASE/api/search?q=re")
echo "$r2" | rg -q '"teamId"' && ok "2-char -> real results" || bad "2-char results broken"

echo "=== 5) cycle-39 feature: Persian 404 ==="
code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/bogus-xyz-404")
[ "$code" = "404" ] && ok "bogus path -> HTTP 404" || bad "bogus path -> $code"
h=$(curl -s "$BASE/bogus-xyz-404")
echo "$h" | rg -q 'توپ از خط بیرون رفت' && ok "404 Persian card rendered" || bad "404 card missing"
echo "$h" | rg -q '۴۰۴' && ok "404 fa digits" || bad "fa digits missing"
echo "$h" | rg -q 'نتایج زنده امروز' && ok "404 action link present" || bad "404 action missing"
nox=$(echo "$h" | rg -c 'noindex' || true); [ "$nox" -ge 1 ] && ok "404 page noindex" || bad "404 noindex missing"

echo "=== 6) sitemap teams (cycle-33) ==="
sm=$(curl -s "$BASE/sitemap.xml")
cnt=$(echo "$sm" | rg -c '/team/' || true); [ "$cnt" -ge 7 ] && ok "sitemap team urls >= 7 ($cnt)" || bad "sitemap teams = $cnt"

echo "=== 7) JSON-LD coverage ==="
h=$(curl -s "$BASE/league/pl")
echo "$h" | rg -q '"@type":"?SportsLeague' && ok "league page LD SportsLeague" || bad "league LD SportsLeague missing"
h=$(curl -s "$BASE/team/8633")
echo "$h" | rg -q '"@type":"?SportsTeam' && ok "team LD SportsTeam" || bad "team LD missing"
h=$(curl -s "$BASE/match/5749720")
echo "$h" | rg -q '"@type":"?SportsEvent' && ok "match LD SportsEvent" || bad "match LD missing"

echo "=== 8) regression suite ==="
if BASE="$BASE" bash /home/z/my-project/scripts/cycle17-regression.sh > /tmp/rm-reg40.log 2>&1; then
  ok "cycle17-regression 28/28"
else
  bad "regression failed — see /tmp/rm-reg40.log"
fi

echo "=== result ==="
echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] && echo "BUGHUNT PATROL ALL OK" || echo "BUGHUNT PATROL HAS FAILURES"
