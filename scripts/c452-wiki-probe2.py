#!/usr/bin/env python3
# cycle-452: resolve article TYPES (city/province/district) for the THA
# toponym anchors via short extracts — one batched call, plus the three
# rate-limited opensearch retries from the first probe pass.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def api(url, tries=3):
    for a in range(tries):
        out = subprocess.run(["curl", "-s", "--max-time", "30", "-A", UA, url],
                             capture_output=True, text=True, timeout=60).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(2 + a * 2)
    return {}


titles = ("ناخون پاتوم|ناکون پاتوم|خون کائن|ساتون|سونگخلا|شهرستان لویی|"
          "پاتایا|چاینات|کانتچانابوری")
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
       "&exintro&explaintext&redirects=1&titles="
       + urllib.parse.quote(titles) + "&format=json")
d = api(url)
print("== extracts ==")
for p in d.get("query", {}).get("pages", {}).values():
    ext = (p.get("extract") or "")[:120].replace("\n", " ")
    print(f"[{p['title']}] {ext}")
time.sleep(2)

print("== opensearch retries ==")
for q in ["باشگاه فوتبال خون کائن", "خون کائن یونایتد",
          "باشگاه فوتبال مهاساراخام", "باشگاه فوتبال سونگخلا"]:
    u = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
         + urllib.parse.quote(q) + "&limit=3&format=json")
    r = api(u)
    hits = r[1] if isinstance(r, list) and len(r) > 1 else r
    print(f"{q!r} -> {hits}")
    time.sleep(1.5)
