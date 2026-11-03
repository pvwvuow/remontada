#!/usr/bin/env python3
# cycle-450: confirm the three remaining fa.wiki titles byte-exactly.
import json
import subprocess
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
TITLES = ["باشگاه فوتبال مالاکاتیکو", "باشگاه فوتبال آئورورا",
          "باشگاه فوتبال کامیونیکیشنس", "باشگاه فوتبال دپورتیوو میسکو"]
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info"
       "&redirects=1&format=json&titles=" + urllib.parse.quote("|".join(TITLES)))
out = subprocess.run(["curl", "-s", "--max-time", "20", "-A", UA, url],
                     capture_output=True, text=True, timeout=30).stdout
d = json.loads(out)
for p in d.get("query", {}).get("pages", {}).values():
    print(f"pageid={p.get('pageid', 'MISSING')} title={p.get('title')!r}")
