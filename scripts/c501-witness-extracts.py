#!/usr/bin/env python3
# cycle-501 witness nailing - full extracts of the two spelling witnesses
# (the 497 strict rule: identity + spelling via the article's OWN text).
import json, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def api(url):
    for attempt in range(4):
        out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


T = "خوزه لوئیس فریازا|کنراد د لا فوئنته"
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url&titles="
        + urllib.parse.quote(T) + "&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    ex = (p.get("extract") or "(EMPTY)")[:500].replace("\n", " ")
    print(f"pageid={pid} :: {p.get('title')!r} :: {ex}")
    print("---")
    time.sleep(1.8)
