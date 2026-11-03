#!/usr/bin/env python3
# cycle-465 probe 2: pageid capture for the five identity-verified PAN club
# articles (probe 1's B-block batch was too large and came back empty-page —
# the C-block extracts already carried the identity; this re-probe is small
# and batched to 5 titles only, the house small-batch lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TITLES = [
    "باشگاه فوتبال عربه یونیدو",
    "باشگاه فوتبال پلازا آمادور",
    "باشگاه فوتبال اسپورتینگ سن میگلیتو",
    "باشگاه فوتبال تائورو",
    "باشگاه فوتبال سان فرانسیسکو",
]

d = None
for attempt in range(4):
    out = subprocess.run(
        ["curl", "-s", "--max-time", "25", "-A", UA,
         "https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles="
         + urllib.parse.quote("|".join(TITLES)) + "&format=json"],
        capture_output=True, text=True, timeout=40).stdout
    try:
        d = json.loads(out)
        break
    except Exception:
        print(f"  attempt {attempt+1} empty/bad ({len(out)} bytes), retrying…")
        time.sleep(3 + attempt * 3)
if d is None:
    raise SystemExit("fa.wiki unreachable after retries")
for pid, p in d.get("query", {}).get("pages", {}).items():
    if pid != "-1" and "missing" not in p:
        print("EXISTS pageid=", p.get("lastrevid"), ":", p["title"])
    else:
        print("MISSING:", p.get("title"))
res = {}
for pid, p in d.get("query", {}).get("pages", {}).items():
    if pid != "-1" and "missing" not in p:
        res[p["title"]] = p.get("lastrevid")
json.dump(res, open("/tmp/c465-wiki2.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c465-wiki2.json")
