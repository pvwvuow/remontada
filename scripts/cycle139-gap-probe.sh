#!/usr/bin/env bash
# cycle-139 UPDATE pre-work: live surface sweep of every API route.
# Goal: find the honest remaining FotMob gap (ok:false / empty / error),
# not to invent one. UA Chrome/124 where upstream is touched directly;
# here we probe OUR app (localhost:3000) which fronts upstream.
BASE="http://localhost:3000"
pass=0; gaps=0
probe() { # name url jqexpr
  local name="$1" url="$2" expr="$3"
  local out code
  out=$(curl -s -m 25 -w '\n%{http_code}' "$url")
  code=$(printf '%s' "$out" | tail -n1)
  local body
  body=$(printf '%s' "$out" | head -n -1)
  local val
  val=$(printf '%s' "$body" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(eval(sys.argv[1], {}, {'d': d}))
except Exception as e:
    print('ERR:'+str(e)[:80])
" "$expr" 2>/dev/null)
  if [[ "$code" == "200" && "$val" != ERR:* ]]; then
    echo "OK   $name -> $val"; pass=$((pass+1))
  else
    echo "GAP  $name code=$code val=$val"; gaps=$((gaps+1))
  fi
}
echo "== core league surfaces (ucl + persiangulf) =="
probe standings-ucl        "$BASE/api/standings?league=ucl"          "len(d['table'] or d.get('rows',[]) or [])"
probe standings-pg         "$BASE/api/standings?league=persiangulf"  "len(d['table'] or d.get('rows',[]) or [])"
probe fixtures-ucl         "$BASE/api/league-fixtures?league=ucl"    "len(d.get('fixtures',d.get('matches',[])) or [])"
probe scorers-ucl          "$BASE/api/topscorers"                    "len(d.get('scorers',[]))"
probe transfers-ucl        "$BASE/api/league-transfers?league=ucl"   "len(d.get('transfers',{}).get('items',[]))"
probe titles-ucl           "$BASE/api/league-titles?league=ucl"      "len(d.get('titles',{}).get('seasons',[]) or d.get('titles',[]) )"
probe bracket-ucl          "$BASE/api/league-bracket?league=ucl"     "len(d['bracket']['rounds'])"
probe bracket-ucl-hist     "$BASE/api/league-bracket?league=ucl&season=2024%2F2025" "len(d['bracket']['rounds'])"
echo "== team surfaces (Persepolis 101610, Barcelona 8708) =="
probe team-pg              "$BASE/api/team/101610"                   "d.get('team',{}).get('name','?')"
probe team-squad-pg        "$BASE/api/team-squad/101610"             "len(d.get('squad',{}).get('groups',[]) or d.get('groups',[]) or [])"
probe team-transfers-pg    "$BASE/api/team-transfers/101610"         "len(d.get('transfers',{}).get('items',[]))"
probe team-trophies-pg     "$BASE/api/team-trophies/101610"          "len(str(d)[:1])"
probe team-stats-barca     "$BASE/api/team-stats/8708"               "len(str(d)[:1])"
probe team-topplayers-barca "$BASE/api/team-top-players/8708"        "len(str(d)[:1])"
probe team-history-barca   "$BASE/api/team-history/8708"             "len(str(d)[:1])"
probe team-venue-barca     "$BASE/api/team-venue/8708"               "len(str(d)[:1])"
probe team-coaches-barca   "$BASE/api/team-coaches/8708"             "len(str(d)[:1])"
probe team-lastlineup-barca "$BASE/api/team-last-lineup/8708"        "len(str(d)[:1])"
probe team-difficulty-barca "$BASE/api/team-difficulty/8708"         "len(str(d)[:1])"
probe team-fixtures-barca  "$BASE/api/team-fixtures/8708"            "len(str(d)[:1])"
echo "== match / player / global =="
probe matches-today        "$BASE/api/matches"                       "len(d.get('matches',[]) or [])"
probe news                 "$BASE/api/news"                          "len(d.get('items',[]))"
probe search               "$BASE/api/search?q=real"                 "len(d.get('results',d.get('teams',[])) or [])"
probe players-hub          "$BASE/api/players"                       "len(str(d)[:1])"
echo "== summary: pass=$pass gaps=$gaps =="
