#!/usr/bin/env python3
"""cycle-335 verification probe (merge-completion of the parallel session's
in-flight work): fetch the pl CURRENT-season league raw, find the
"Accurate passes per 90" category, fetch its fetchAllUrl with UA Chrome/124,
and report row count + top rows. Mirrors the code's own read path."""
import json
import urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
BASE = "https://www.fotmob.com"

# pl ids from the codebase's league map
LG_ID, CCODE3 = 47, "ENG"


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        payload = r.read()
    if payload[:2] == b"\x1f\x8b":  # gzip magic
        import gzip
        payload = gzip.decompress(payload)
    return json.loads(payload.decode())


raw = get(f"{BASE}/api/data/leagues?id={LG_ID}&ccode3={CCODE3}&lang=en")
cats = (raw.get("stats") or {}).get("players") or []
cat = next((c for c in cats if (c.get("header") or "").lower() == "accurate passes per 90"), None)
if not cat:
    print("category NOT FOUND in raw; headers:", [c.get("header") for c in cats][:8])
    raise SystemExit(0)
url = cat.get("fetchAllUrl")
print("fetchAllUrl:", url)
data = get(BASE + url) if url.startswith("/") else get(url)
rows = ((data.get("TopLists") or [{}])[0].get("StatList")) or []
print("rows:", len(rows))
for r in rows[:3]:
    print(" ", r.get("Rank"), r.get("ParticipantName"), "|", r.get("TeamName"), "|", r.get("StatValue"))
