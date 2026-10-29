#!/bin/bash
# Remontada regression suite — rebuilt in cycle-34, re-committed into the repo in cycle-35
# baseline "28/28": 12 pages + 13 API contracts (incl. graceful 400/404/503) + 3 meta files
# usage: BASE=http://localhost:3005 bash scripts/cycle17-regression.sh
BASE="${BASE:-http://localhost:3005}"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
check() { # name, url, expected http code
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 "$BASE$2")
  [ "$code" = "$3" ] && ok "$1 ($3)" || bad "$1 (got $code, want $3)"
}
body_has() { # name, url, substring, expected http code
  local out code
  out=$(curl -s --max-time 25 -w '\n%{http_code}' "$BASE$2")
  code=$(echo "$out" | tail -1)
  if [ "$code" = "$4" ] && echo "$out" | head -n -1 | grep -q "$3"; then
    ok "$1 ($4)"
  else
    bad "$1 (code=$code, missing '$3')"
  fi
}

echo "=== pages (12) ==="
check "home"                  "/" 200
check "leagues index"         "/leagues" 200
check "league pl"             "/league/pl" 200
check "league persiangulf live"    "/league/persiangulf" 200
check "topscorers global"     "/topscorers" 200
check "topscorers pl"         "/topscorers/pl" 200
check "team real (8633)"      "/team/8633" 200
check "news"                  "/news" 200
check "team invalid noindex"  "/team/abc" 200
check "match invalid noindex" "/match/abc" 200
check "player invalid noindex" "/player/abc" 200
check "unknown league 404"    "/league/doesnotexist" 404

echo "=== api contracts (13) ==="
body_has "api matches"        "/api/matches?d=0" '"ok":true' 200
body_has "api standings pl"   "/api/standings?league=pl" '"ok":true' 200
# cycle-136: the placeholder id became the real FotMob league 523 — the
# designed-503 era ended; the home league now serves its live table
body_has "api standings persiangulf live" "/api/standings?league=persiangulf" '"ok":true' 200
body_has "api league-fixtures pl" "/api/league-fixtures?league=pl" '"ok":true' 200
body_has "api topscorers"     "/api/topscorers" '"ok":true' 200
body_has "api news"           "/api/news" '"ok":true' 200
body_has "api search fa"      "/api/search?q=%D8%B1%D8%A6%D8%A7%D9%84" '"ok":true' 200
body_has "api team real"      "/api/team/8633" '"ok":true' 200
check "api team unknown 404"  "/api/team/99999999" 404
body_has "api match malformed 400 fa" "/api/match/abc" 'نامعتبر' 400
body_has "api h2h malformed 400 fa"   "/api/match-h2h/abc" 'نامعتبر' 400
body_has "api player malformed 400 fa" "/api/player/abc" 'نامعتبر' 400
check "api match unknown 404"  "/api/match/99999999" 404

echo "=== meta (3) ==="
check "robots.txt"   "/robots.txt" 200
check "sitemap.xml"  "/sitemap.xml" 200
check "manifest"     "/manifest.webmanifest" 200

echo "=== result ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && [ "$PASS" = "28" ] && echo "REGRESSION 28/28 OK" || { echo "REGRESSION INCOMPLETE"; exit 1; }
