#!/usr/bin/env bash
# cycle-232 probe 2: deep-file inspection for expected_goalsontarget.json
# on the six domestics + the season-aware historical raw (2020/21 laliga,
# the 202 anchor class) + decimals/precision + rank shape.
set -u
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/cycle232-probe
mkdir -p "$OUT"

get_url() { python3 - "$1" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for c in (d.get("stats") or {}).get("players") or []:
    if (c.get("header") or "").strip().lower() == sys.argv[2]:
        print(c.get("fetchAllUrl") or ""); break
PY
}

for key in ucl pl laliga seriea bundesliga ligue1; do
  url=$(get_url "$OUT/$key.json" "expected goals on target (xgot)")
  [ -z "$url" ] && { echo "$key: NO-URL"; continue; }
  curl -s --compressed --max-time 30 -A "$UA" "$url" -o "$OUT/$key-xgot.json"
  python3 - "$key" "$OUT/$key-xgot.json" <<'PY'
import json, sys
key, f = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(f))
except Exception as e:
    print(f"{key}: PARSE-FAIL {e}"); sys.exit()
rows = (d.get("TopLists") or [{}])[0].get("StatList") or []
nonint = sum(1 for r in rows if (r.get("StatValue") or 0) != int(r.get("StatValue") or 0))
dec2 = sum(1 for r in rows if round((r.get("StatValue") or 0)*100) != round((r.get("StatValue") or 0)*100))
tops = [(r.get("Rank"), r.get("ParticipantName"), r.get("StatValue"), r.get("TeamName")) for r in rows[:5]]
ranks = [r.get("Rank") for r in rows[:12]]
print(f"{key}: rows={len(rows)} nonint={nonint} ranks[:12]={ranks}")
for t in tops: print(f"   {t}")
PY
done

echo "=== HISTORICAL: laliga 2020/2021 ==="
curl -s --compressed --max-time 40 -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en&season=2020%2F2021" -o "$OUT/laliga-2020.json"
url=$(get_url "$OUT/laliga-2020.json" "expected goals on target (xgot)")
echo "hist url: ${url:-NONE}"
if [ -n "$url" ]; then
  curl -s --compressed --max-time 30 -A "$UA" "$url" -o "$OUT/laliga-2020-xgot.json"
  python3 - "$OUT/laliga-2020-xgot.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
rows = (d.get("TopLists") or [{}])[0].get("StatList") or []
nonint = sum(1 for r in rows if (r.get("StatValue") or 0) != int(r.get("StatValue") or 0))
print(f"2020/21 laliga xGOT: rows={len(rows)} nonint={nonint}")
for r in rows[:4]: print("  ", r.get("Rank"), r.get("ParticipantName"), r.get("StatValue"), r.get("TeamName"))
PY
fi
