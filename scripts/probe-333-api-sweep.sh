#!/bin/bash
# cycle-333 bug-hunt: systematic sweep of ALL /api routes (live evidence, 2026-11-01).
# RESULT: zero 500s; every anomaly was a probe false-positive, documented in worklog cycle-333:
#  - team-*/coach/player/match are DYNAMIC [id] path routes (use /api/team-stats/8650 etc.)
#  - /api/topscorers is /api/topscorers/[leagueKey] — a ?league= query politely 400s with a hint
#  - /api/league-calendar deliberately serves text/calendar (iCal; 380 VEVENTs = 380 PL matches)
#  - /api/league-bracket honestly returns {"ok":true,"bracket":null} for round-robin leagues

BASE=http://localhost:3000
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

probe() {
  local name="$1"; local url="$2"
  local code; code=$(curl -s -o /tmp/probe333.json -w '%{http_code}' -A "$UA" --max-time 25 "$url")
  local valid="?"
  if [ "$code" = "200" ]; then
    if python3 -c "import json;json.load(open('/tmp/probe333.json'))" 2>/dev/null; then valid="JSON-OK"; else valid="NOT-JSON"; fi
  fi
  local size; size=$(stat -c%s /tmp/probe333.json 2>/dev/null || echo 0)
  echo "$code $valid ${size}B $name"
}

echo "=== league-level APIs ==="
probe "bracket pl"            "$BASE/api/league-bracket?league=pl"
probe "bracket pl+season"     "$BASE/api/league-bracket?league=pl&season=2026%2F2027"
probe "transfers pl"          "$BASE/api/league-transfers?league=pl"
probe "titles pl"             "$BASE/api/league-titles?league=pl"
probe "calendar pl"           "$BASE/api/league-calendar?league=pl"
probe "fixtures pl"           "$BASE/api/league-fixtures?league=pl"
probe "fixtures-all pl"       "$BASE/api/league-fixtures-all?league=pl"
probe "standings pl"          "$BASE/api/standings?league=pl"
probe "topscorers pl"         "$BASE/api/topscorers?league=pl"

echo "=== entity APIs (corrected ID index + new surfaces) ==="
probe "team-stats 8650"       "$BASE/api/team-stats?team=8650"
probe "team-squad 8650"       "$BASE/api/team-squad?team=8650"
probe "team-fixtures 8650"    "$BASE/api/team-fixtures?team=8650"
probe "team-transfers 8650"   "$BASE/api/team-transfers?team=8650"
probe "team-trophies 8650"    "$BASE/api/team-trophies?team=8650"
probe "team-top-players 8650" "$BASE/api/team-top-players?team=8650"
probe "team-venue 8650"       "$BASE/api/team-venue?team=8650"
probe "team-history 8650"     "$BASE/api/team-history?team=8650"
probe "team-news 8650"        "$BASE/api/team-news?team=8650"
probe "team-rumours 8650"     "$BASE/api/team-rumours?team=8650"
probe "team-last-lineup 8650" "$BASE/api/team-last-lineup?team=8650"
probe "team-coaches 8650"     "$BASE/api/team-coaches?team=8650"
probe "coach 78719"           "$BASE/api/coach?id=78719"
probe "player 696679"         "$BASE/api/player?id=696679"

echo "=== dynamic [id] APIs ==="
probe "match-h2h 5795501"     "$BASE/api/match-h2h/5795501"
probe "team-difficulty 8650"  "$BASE/api/team-difficulty/8650"
probe "match 5795501"         "$BASE/api/match?id=5795501"

echo "=== core/global APIs ==="
probe "matches"               "$BASE/api/matches"
probe "news"                  "$BASE/api/news"
probe "search لیورپول"        "$BASE/api/search?q=%D9%84%DB%8C%D9%88%D8%B1%D9%BE%D9%88%D9%84"
probe "rss.xml"               "$BASE/rss.xml"
probe "sitemap"               "$BASE/sitemap.xml"
probe "manifest"              "$BASE/manifest.webmanifest"
