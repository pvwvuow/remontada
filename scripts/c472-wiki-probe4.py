#!/usr/bin/env python3
# cycle-472 anchor probe #4 (v2, chunked) — the honest-read documentation
# pass for the three zero-club-anchor CZE names (Artis Brno / SK Prostějov
# / Vysočina Jihlava) + the Teplice club-article spelling check. Wikimedia
# rate-limits bursts, so: chunks of 4 titles + sleeps + retries.
import json, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CHUNKS = [
    ["آرتیس برنو", "برنو آرتیس", "باشگاه فوتبال آرتیس برنو", "پروستیوف"],
    ["باشگاه فوتبال پروستییوف", "اف‌سی پروستییوف", "ویسوچینا ییهلاوا",
     "باشگاه فوتبال ویسوچینا ییهلاوا"],
    ["باشگاه فوتبال تپلیسه", "اف‌کی تپلیتسه", "باشگاه فوتبال ویسوچینا ییهاوا"],
]


def api(url):
    for attempt in range(5):
        out = subprocess.run(["curl", "-s", "--max-time", "30", "-A", UA, url],
                             capture_output=True, text=True, timeout=50).stdout
        if out.strip().startswith("{"):
            try:
                return json.loads(out)
            except Exception:
                pass
        time.sleep(6 + attempt * 6)   # rate-limit backoff
    return None


for i, chunk in enumerate(CHUNKS):
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
           "&titles=" + urllib.parse.quote("|".join(chunk)) + "&format=json")
    d = api(url)
    time.sleep(8)
    if not d:
        print(f"chunk {i}: UNRESOLVED (rate-limited)")
        continue
    for pid, p in d.get("query", {}).get("pages", {}).items():
        if pid != "-1" and "missing" not in p:
            print(f"EXISTS pageid={p.get('lastrevid')}: {p['title']}")
        else:
            print(f"missing: {p.get('title')}")
