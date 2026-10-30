#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-196 update — the 92 season boards catalog grows 6→12 team and
# 6→12 player categories («برترین‌های رسمی فصل» گسترش می‌یابد)
#
# The probed gap (scripts/cycle196-probe.py, 2026-10-30, UA Chrome/124):
# extractLeagueBoards (cycle-92) curated only 6 of the 31 TEAM and 6 of
# the 46 PLAYER stat leaderboards riding the SAME cached data/leagues
# payload — the defensive/expected-goals/set-piece/card families never
# surfaced (8/8 new team + 6/6 new player headers absent from the served
# /api/standings boards). Fix: 8 team + 6 player catalog entries (Persian
# titles in the site's own prose) — same extraction, same chips, same
# getStandings path (season-aware: the leagueRaw season param works, 23/31
# team rows differ 2024/2025 vs current), ZERO new fetches, honest skip
# unchanged (a category a league/season lacks stays hidden).
#
# Stable byte pins (the FINISHED 2024/2025 season — values can no longer
# drift; the 193 lesson says never pin live values):
#   team conceded/match Arsenal 0.9 (9825)؛ Expected goals Liverpool 83.5
#   (8650)؛ Yellow cards Chelsea 99 (8455)؛ Set piece goals Nottm Forest 17
#   (10203)؛ Corners Man City 253؛ Penalties awarded Liverpool 9
#   player Chances created Bruno Fernandes 91 (422685)؛ xA Mbeumo 9.3
#   (923312)؛ Tackles/90 Wieffer 5.2 (970243)؛ Interceptions/90 Bentancur
#   2.2 (620618)؛ Clean sheets Raya 13 (562727)؛ Save % Flekken 73.6
#   percent (330643)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (8 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse, urllib.error
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

NEW_TEAM = {"Goals conceded per match": "گل خورده در هر بازی", "Shots on target per match": "شوت در چارچوب در هر بازی",
            "Expected goals": "گل انتظاری (xG)", "xG difference": "تفاضل گل انتظاری",
            "Corners": "کرنر", "Set piece goals": "گل از ضربات ایستگاهی",
            "Penalties awarded": "پنالتی گرفته‌شده", "Yellow cards": "کارت زرد"}
NEW_PLAYER = {"Tackles per 90": "تکل در هر ۹۰ دقیقه", "Interceptions per 90": "قطع توپ در هر ۹۰ دقیقه",
              "Chances created": "موقعیت ساخته", "Expected assist (xA)": "پاس منجر انتظاری (xA)",
              "Clean sheets": "کلین‌شیت", "Save percentage": "درصد مهار"}
OLD = ["FotMob rating", "Goals per match", "Average possession", "Clean sheets", "Attendance", "Squad value",
       "Top speed", "Accurate passes per 90", "Big chances created", "Successful dribbles per 90", "Goals prevented"]

# A1: the 8 new TEAM kinds on the current pl payload with Persian headerFa
d = get(f"{BASE}/api/standings?league=pl")
tb = {b.get("header"): b for b in (d.get("boards") or []) if b.get("kind") == "team"}
good = all(h in tb and tb[h].get("headerFa") == fa for h, fa in NEW_TEAM.items())
report("A1 8 new team boards present + headerFa", good,
       f"present={sum(1 for h in NEW_TEAM if h in tb)}/8 e.g. {tb.get('Goals conceded per match', {}).get('headerFa')!r}")

# A2: the 6 new PLAYER kinds with Persian headerFa
pb = {b.get("header"): b for b in (d.get("boards") or []) if b.get("kind") == "player"}
good = all(h in pb and pb[h].get("headerFa") == fa for h, fa in NEW_PLAYER.items())
report("A2 6 new player boards present + headerFa", good,
       f"present={sum(1 for h in NEW_PLAYER if h in pb)}/6 e.g. {pb.get('Save percentage', {}).get('headerFa')!r}")

# A3: stable byte pins on the FINISHED 2024/2025 season (team boards)
q = urllib.parse.quote("2024/2025", safe="")
d = get(f"{BASE}/api/standings?league=pl&season={q}")
tb24 = {b.get("header"): b for b in (d.get("boards") or []) if b.get("kind") == "team"}
def team_pin(h, name, value, tid):
    b = tb24.get(h) or {}
    r0 = (b.get("rows") or [{}])[0]
    return b and r0.get("name") == name and r0.get("value") == value and r0.get("teamId") == tid
good = team_pin("Goals conceded per match", "Arsenal", 0.9, 9825) \
    and team_pin("Expected goals", "Liverpool", 83.5, 8650) \
    and team_pin("Yellow cards", "Chelsea", 99, 8455) \
    and team_pin("Set piece goals", "Nottingham Forest", 17, 10203)
gc = (tb24.get("Goals conceded per match") or {}).get("rows") or [{}]
report("A3 24/25 team byte pins (conceded/xG/cards/setpiece)", good,
       f"conceded r0={gc[0].get('name')}/{gc[0].get('value')} top3={[r.get('name') for r in gc[:3]]}")

# A4: stable byte pins on the finished season (player boards) + link shape
pb24 = {b.get("header"): b for b in (d.get("boards") or []) if b.get("kind") == "player"}
def player_pin(h, name, value, pid):
    b = pb24.get(h) or {}
    r0 = (b.get("rows") or [{}])[0]
    return b and r0.get("name") == name and r0.get("value") == value and r0.get("playerId") == pid
cc = (pb24.get("Chances created") or {}).get("rows") or [{}]
good = player_pin("Chances created", "Bruno Fernandes", 91, 422685) \
    and player_pin("Expected assist (xA)", "Bryan Mbeumo", 9.3, 923312) \
    and player_pin("Tackles per 90", "Mats Wieffer", 5.2, 970243) \
    and player_pin("Interceptions per 90", "Rodrigo Bentancur", 2.2, 620618) \
    and player_pin("Clean sheets", "David Raya", 13, 562727) \
    and player_pin("Save percentage", "Mark Flekken", 73.6, 330643) \
    and bool(cc[0].get("teamFa")) and cc[0].get("teamId", 0) > 0
report("A4 24/25 player byte pins + club fa", good,
       f"cc r0={cc[0].get('name')}/{cc[0].get('value')} teamFa={cc[0].get('teamFa')!r}")

# A5: the OLD 11 catalog headers all still present on current pl (no drops)
d = get(f"{BASE}/api/standings?league=pl")
allb = {b.get("header"): b for b in (d.get("boards") or [])}
good = all(h in allb for h in OLD) and len(d.get("boards") or []) >= 26
report("A5 old boards intact + count grew", good,
       f"old={sum(1 for h in OLD if h in allb)}/11 boards={len(d.get('boards') or [])}")

# A6: podium shape on new boards — ranks 1..n, distinct ids>0
gc = (allb.get("Goals conceded per match") or {}).get("rows") or []
ids = [r.get("teamId") for r in gc]
good = len(gc) >= 2 and [r.get("rank") for r in gc] == list(range(1, len(gc) + 1)) \
    and all(i and i > 0 for i in ids) and len(set(ids)) == len(ids)
report("A6 new team podium shape (ranks+distinct ids)", good,
       f"rows={len(gc)} ids={ids}")

# A7: honest skip stays — a league with fewer categories keeps a valid,
# headerFa-complete boards array (mas = the smallest portal league)
d = get(f"{BASE}/api/standings?league=mas")
mbs = d.get("boards") or []
good = isinstance(mbs, list) and all(b.get("headerFa") and (b.get("rows") or []) for b in mbs)
report("A7 honest skip on category-poor league (mas)", good,
       f"mas boards={len(mbs)} all valid")

# A8: cross-cycle anchors — the 194 king and the 195 route contract
d = get(f"{BASE}/api/search?q={urllib.parse.quote('فتای')}")
fk = [p for p in (d.get("players") or []) if p.get("playerId") == 1516458]
d2 = get(f"{BASE}/api/search?q=%D9%81")
good = len(fk) == 1 and fk[0].get("season") == "2024/2025" \
    and d2.get("ok") is True and isinstance(d2.get("message"), str)
report("A8 194 king + search contract intact", good,
       f"fetai={len(fk)} season={fk[0].get('season') if fk else None}")
print("API_ALL_OK" if ok else "API_FLAGGED")
PY
)
echo "$A_OUT"
echo "$A_OUT" | rg -q "API_ALL_OK" || BAD=$((BAD+1))

echo "== PART B: DOM proof @390x844 (agent-browser, console must stay 0) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
CNT='import json,sys
try:
  d=json.load(sys.stdin); print(len(d["data"]["messages"]))
except Exception: print("ERR")'
ECNT='import json,sys
try:
  d=json.load(sys.stdin); es=d["data"]["errors"]
  print(len([e for e in es if e.get("url")]))
except Exception: print("ERR")'

open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
gate() {
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}
click_tab() {
  $B eval "(function(){var b=[...document.querySelectorAll('button')].find(function(x){return x.innerText.trim().indexOf('$1')===0;});if(!b)return 'notab';b.click();return 'clicked';})()" >/dev/null 2>&1
  sleep 1.2
}
click_chip() {
  $B eval "(function(){var b=[...document.querySelectorAll('[data-testid=league-boards] button')].find(function(x){return x.innerText.indexOf('$1')>=0;});if(!b)return 'nochip';b.click();return 'clicked';})()" >/dev/null 2>&1
  sleep 0.8
}
clean_ls

# B1: current season — stats tab → the new «گل خورده در هر بازی» chip →
# podium with team links (drift-tolerant: no leader name pinned)
open_page "/league/pl"
click_tab "آمار فصل"
$B wait --fn '!!document.querySelector("[data-testid=league-boards]")' >/dev/null 2>&1
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=league-boards]"),chip:[...document.querySelectorAll("[data-testid=league-boards] button")].some(function(b){return b.innerText.indexOf("گل خورده در هر بازی")>=0;})')
click_chip "گل خورده در هر بازی"
FEAT="$FEAT,$(snap 'title:document.body.innerText.indexOf("استحکام خط دفاع فصل")>=0,teamlinks:[...document.querySelectorAll("[data-testid=league-boards] a[href^=\"/team/\"]")].length')"
B1=0
echo "$FEAT" | rg -q 'sec:true' || B1=1
echo "$FEAT" | rg -q 'chip:true' || B1=1
echo "$FEAT" | rg -q 'title:true' || B1=1
echo "$FEAT" | rg -q 'teamlinks:[2-9]' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 stats tab → new chip → podium w/ team links" "$FEAT"
clean_ls

# B2: the FINISHED 2024/2025 season — stable leader: «تفاضل گل انتظاری»
# podium head = لیورپول (44.8, the 193 lesson: only finished-season pins)
open_page "/league/pl?season=2024%2F2025"
click_tab "آمار فصل"
$B wait --fn '!!document.querySelector("[data-testid=league-boards]")' >/dev/null 2>&1
click_chip "تفاضل گل انتظاری"
FEAT=$(snap 'lead:(document.querySelector("[data-testid=league-boards] a[href^=\"/team/\"]")||{}).innerText||"",xgchip:[...document.querySelectorAll("[data-testid=league-boards] button")].some(function(b){return b.innerText.indexOf("تفاضل گل انتظاری")>=0;})')
B2=0
echo "$FEAT" | rg -q 'xgchip:true' || B2=1
# team board rows render the honest upstream Latin name (the 92 contract —
# nameFa is player-rows-only per cycle-107) → the needle is Latin
echo "$FEAT" | grep -q "Liverpool" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 24/25 xG-diff podium head = لیورپول" "$FEAT"
clean_ls

# B3: player kind — the new «تکل در هر ۹۰ دقیقه» chip → podium rows link
# to /player/{id} with the Persian club sub-line
open_page "/league/pl"
click_tab "آمار فصل"
$B wait --fn '!!document.querySelector("[data-testid=league-boards]")' >/dev/null 2>&1
click_tab "بازیکنان"
sleep 0.6
click_chip "تکل در هر ۹۰ دقیقه"
FEAT=$(snap 'pl:[...document.querySelectorAll("[data-testid=league-boards] a[href^=\"/player/\"]")].length,sub:document.body.innerText.indexOf("برندگی در تن‌به‌تن")>=0')
B3=0
echo "$FEAT" | rg -q 'pl:[2-9]' || B3=1
echo "$FEAT" | rg -q 'sub:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 player chip → /player links + sub" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-196 update proven (A 8/8 + B 3/3 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
