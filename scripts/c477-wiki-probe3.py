#!/usr/bin/env python3
# cycle-477 probe3 — the Skënderbeu settlement: direct existence + extract
# of «ورزشگاه اسکندربو» (the club's own stadium — the spelling evidence for
# the zero-anchor honest read, the 475 رعانانا single-title-probe lesson)
# and a direct existence check of the bare club spellings the searches
# missed (اسکندربو / باشگاه فوتبال اسکندربو) to leave NO stone unturned.
import json
import subprocess
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def api(url: str):
    out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                         capture_output=True, text=True, timeout=40).stdout
    try:
        return json.loads(out)
    except Exception:
        return None


TITLES = ["ورزشگاه اسکندربو", "اسکندربو", "باشگاه فوتبال اسکندربو",
          "اسکندربو کورچه", "کورچا"]
u = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
     "&exintro=1&explaintext=1&titles="
     + urllib.parse.quote("|".join(TITLES)) + "&format=json")
d = api(u)
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print(f"  MISSING: {p.get('title')!r}")
    else:
        print(f"  EXISTS pageid={pid} title={p['title']!r} rev={p.get('lastrevid')}")
        print(f"    extract: {(p.get('extract') or '')[:280]}")
