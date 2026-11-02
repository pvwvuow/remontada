#!/usr/bin/env bash
# cycle416-feeprobe.sh — update cycle 416 feasibility probe (the آپدیت rule:
# live curl UA Chrome/124 BEFORE building). The cycle-415 card documented the
# real remaining footmap gap on the global transfers wire: «فیلتر مبلغ =
# چرخهٔ آینده» — the 415 probes proved `page` and `date` params are
# byte-ignored while fee/value filters (minFee) REALLY filter
# (minFee=50000000 → 38 rows, hits=38). This probe maps the preset space
# the /transfers filter chips will serve: for each candidate threshold,
# record http/size/rows/hits/first-row-fee and verify every returned row's
# fee.value (or amountEuroEstimated) actually clears the threshold — the
# honest-filter contract the UI will promise.
set -u
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
BASE='https://www.fotmob.com/api/data/transfers'
PY=/tmp/c416-probe.json

for TH in 0 1000000 5000000 20000000 50000000; do
  if [ "$TH" = "0" ]; then U="$BASE?date=20261102"; else U="$BASE?date=20261102&minFee=$TH"; fi
  curl -s -A "$UA" -H 'Accept: application/json' "$U" -o "$PY" -w "threshold=$TH http=%{http_code} bytes=%{size_download}\n"
  python3 - "$TH" <<'PY'
import json, sys
th = int(sys.argv[1])
try:
    d = json.load(open("/tmp/c416-probe.json"))
except Exception as e:
    print(f"  JSON-FAIL {e}"); raise SystemExit
rows = d.get("transfers") or []
vals = []
for r in rows:
    v = ((r.get("fee") or {}).get("value"))
    if not isinstance(v, (int, float)) or v <= 0:
        v = r.get("amountEuroEstimated")
    vals.append(v if isinstance(v, (int, float)) else None)
below = [(r.get("name"), v) for r, v in zip(rows, vals) if th > 0 and (v is None or v < th)]
print(f"  rows={len(rows)} hits={d.get('hits')} fee-bearing={sum(1 for v in vals if v)} below-threshold={len(below)}")
if below: print(f"  VIOLATION sample: {below[:2]}")
PY
done
