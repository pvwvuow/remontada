#!/usr/bin/env bash
# cycle183-probe.sh — D5 observed-bytes-before-gates probe (cycle-183 bug-hunt)
# Patrol target: the four surfaces added since the cycle-178 hunt (179/180/181/182).
# Pins live truth BEFORE any gate is written (the D5 rule).
# UA Chrome/124 convention (the 178/181/182 probe pattern).
set -u
BASE="${BASE:-http://localhost:3000}"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/cycle183-probe.out
: > "$OUT"
p() { echo "== $1" | tee -a "$OUT"; }
jp() { python3 -c "$1" 2>&1 | tee -a "$OUT"; }
code() { curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE$1"; }

p "P1 global /api/topscorers (current race): keys/scorers/sel/allSeasons"
curl -s -A "$UA" "$BASE/api/topscorers" | jp '
import sys,json
d=json.load(sys.stdin)
print("keys",sorted(d.keys()))
print("scorers",len(d.get("scorers",[])))
print("sel",d.get("selectedSeason"))
print("allSeasons",d.get("allSeasons"))
s=d.get("scorers",[])
if s: print("top1",json.dumps(s[0],ensure_ascii=False)[:220])
'

p "P2 global /api/topscorers?season=2023/2024 (historical race — Kane pin)"
curl -s -A "$UA" "$BASE/api/topscorers?season=2023%2F2024" | jp '
import sys,json
d=json.load(sys.stdin)
s=d.get("scorers",[])
print("scorers",len(s),"sel",d.get("selectedSeason"))
for r in s[:3]: print("row",json.dumps(r,ensure_ascii=False)[:200])
k=[r for r in s if r.get("playerId")==194165]
print("kane194165",json.dumps(k[0],ensure_ascii=False)[:220] if k else "ABSENT")
'

p "P3 global /api/topscorers?season=2013/2014 (honest empty)"
curl -s -A "$UA" "$BASE/api/topscorers?season=2013%2F2014" | jp '
import sys,json
d=json.load(sys.stdin)
print("keys",sorted(d.keys()))
print("scorers",len(d.get("scorers",[])),"sel",d.get("selectedSeason"),"ok",d.get("ok"))
'

p "P4 global /api/topscorers?season=bogus (expect 400)"
echo "code=$(code "/api/topscorers?season=bogus")" | tee -a "$OUT"

p "P5 league topscorers pl OLD SEASON 2024/2025 (PATH segment; Salah pin; cards ABSENT on old season — the 132 rule)"
curl -s -A "$UA" "$BASE/api/topscorers/pl?season=2024%2F2025" | jp '
import sys,json
d=json.load(sys.stdin)
s=d.get("scorers",[])
print("keys",sorted(d.keys()))
print("scorers",len(s),"sel",d.get("selectedSeason"),"cards" in d and "cards-PRESENT" or "cards-ABSENT")
print("top1",json.dumps(s[0],ensure_ascii=False)[:220] if s else "none")
sa=[r for r in d.get("assists",[])[:3]]
print("assists_n",len(d.get("assists",[])))
'

p "P6 league topscorers belgium (PATH segment; Eckert league-scoped; assists + cards kinds)"
curl -s -A "$UA" "$BASE/api/topscorers/belgium" | jp '
import sys,json
d=json.load(sys.stdin)
s=d.get("scorers",[])
print("keys",sorted(d.keys()),"leagueFa",d.get("leagueFa"),"season",d.get("season"))
print("scorers",len(s))
for r in s[:3]: print("row",json.dumps(r,ensure_ascii=False)[:180])
e=[r for r in s if r.get("playerId")==892709]
print("eckert892709",json.dumps(e[0],ensure_ascii=False)[:220] if e else "ABSENT")
print("assists_n",len(d.get("assists",[])))
c=d.get("cards")
if c: print("cards y",len(c.get("yellow",[])),"r",len(c.get("red",[])),"y1",json.dumps(c.get("yellow",[{}])[0],ensure_ascii=False)[:150],"r1",json.dumps(c.get("red",[{}])[0],ensure_ascii=False)[:150])
'

p "P7 standings belgium (table 18 rows, خنت top)"
curl -s -A "$UA" "$BASE/api/standings?league=belgium" | jp '
import sys,json
d=json.load(sys.stdin)
rows=d.get("rows") or d.get("standings") or []
print("keys",sorted(d.keys()),"rows",len(rows))
if rows: print("top1",json.dumps(rows[0],ensure_ascii=False)[:200])
'

p "P8 search API shape + FA aliases: اکرت (Eckert) + کین (Kane) + Eckert EN"
for q in "%D8%A7%DA%A9%D8%B1%D8%AA" "%DA%A9%DB%8C%D9%86" "Eckert"; do
  echo "-- q=$q" | tee -a "$OUT"
  curl -s -A "$UA" "$BASE/api/search?q=$q" | jp '
import sys,json
d=json.load(sys.stdin)
print("keys",sorted(d.keys()))
rs=d.get("results",d.get("rows",d.get("players",d.get("items",[]))))
print("n",len(rs))
for r in rs[:3]: print("row",json.dumps(r,ensure_ascii=False)[:160])
'
done

p "P9 page 200 patrol (15 pages incl. new belgium + players season deep-link)"
for pg in "/" "/players" "/players?season=2023%2F2024" "/players?season=2013%2F2014" "/topscorers" "/topscorers/belgium" "/topscorers/pl" "/topscorers/mas" "/topscorers/persiangulf" "/league/belgium" "/league/pl" "/league/mas" "/league/persiangulf" "/player/194165" "/player/892709"; do
  echo "$pg -> $(code "$pg")" | tee -a "$OUT"
done

p "P10 /players SSR shell: h1 + season marker bytes"
curl -s -A "$UA" "$BASE/players" | jp '
import sys,re
h=sys.stdin.read()
m=re.search(r"<h1[^>]*>(.*?)</h1>",h,re.S)
print("h1",(m.group(1).strip()[:120] if m else "NONE"))
print("has_stars_copy","ستاره" in h)
print("n_player_links",len(re.findall(r"href=\"/player/",h)))
'
p "P11 /players?season=2023/2024 SSR shell: subtitle bytes"
curl -s -A "$UA" "$BASE/players?season=2023%2F2024" | jp '
import sys,re
h=sys.stdin.read()
m=re.search(r"<h1[^>]*>(.*?)</h1>",h,re.S)
print("h1",(m.group(1).strip()[:120] if m else "NONE"))
print("kane_in_html","194165" in h)
print("n_player_links",len(re.findall(r"href=\"/player/",h)))
'

echo "PROBE DONE" | tee -a "$OUT"
