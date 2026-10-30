#!/usr/bin/env bash
# cycle-232 probe: feasibility of the two probed-candidates named by the
# cycle-231 card — «Chances created» (the total-chances volume twin) and
# «Expected goals on target (xGOT)» (the third analytics level).
# UA Chrome/124, live, per-league category listing + fetchAllUrl resolution
# + full-file row counts and top values. Read-only.
set -u
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/cycle232-probe
mkdir -p "$OUT"

leagues=(ucl:42:UEFA pl:47:ENG laliga:87:ESP seriea:55:ITA bundesliga:54:GER ligue1:53:FRA persiangulf:523:IRN mas:1000001715:MAS)

for spec in "${leagues[@]}"; do
  key="${spec%%:*}"; rest="${spec#*:}"; id="${rest%%:*}"; cc="${rest#*:}"
  f="$OUT/$key.json"
  curl -s --max-time 30 -A "$UA" "https://www.fotmob.com/api/data/leagues?id=${id}&ccode3=${cc}&lang=en" -o "$f"
  echo "=== $key (id=$id) bytes=$(wc -c < "$f") ==="
  python3 - "$f" <<'PY'
import json, sys, re
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print("  PARSE-FAIL", e); sys.exit()
cats = (d.get("stats") or {}).get("players") or []
if not cats:
    print("  no stats.players"); sys.exit()
print(f"  player cats = {len(cats)}")
for c in cats:
    h = (c.get("header") or "")
    low = h.lower()
    if re.search(r"chances created|xgot|goals on target|chance conversion|big chances", low):
        u = c.get("fetchAllUrl") or ""
        fn = u.rsplit("/", 1)[-1] if u else "-"
        print(f"  MATCH header={h!r} file={fn}")
# full inventory line for the honest-absence check
print("  all:", " | ".join((c.get("header") or "?") for c in cats))
PY
done
