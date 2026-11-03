#!/usr/bin/env python3
# cycle-460 probe2: (A) IDENTITY VERIFICATION of the bare-form pages the
# first probe found (the 456 بوکلی lesson: a NON-club bare page is unusable
# as an anchor — the spelling may still be documented as the encyclopedia's
# OWN letter-reading, the 457 اپیسنتر precedent) + the city pages confirmed
# as the right cities. (B) opensearch for the four city titles my exact
# candidates missed (Grudziądz / Kleczew / Niepołomice / Siedlce) using the
# Latin names (the 455 opensearch-gate pattern).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def api(url: str):
    for attempt in range(3):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "25", "-A", UA, url],
            capture_output=True, text=True, timeout=40,
        ).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(2 + attempt * 2)
    return None


print("== A) identity: intro extracts (first 240 chars) ==")
IDENT = ["آویا", "اویا", "ادرا", "استال", "المپیا", "زنیچ پروشکوف",
         "ونچنا", "شویدنگک", "نووی تارگ", "پروشکوف", "ژشوف", "اوپوله"]
TITLES = "|".join(IDENT)
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts&exintro"
       "&explaintext&exchars=240&titles=" + urllib.parse.quote(TITLES)
       + "&format=json")
d = api(url)
pages = (d or {}).get("query", {}).get("pages", {})
for pid, p in pages.items():
    if pid != "-1" and "missing" not in p:
        txt = (p.get("extract") or "").replace("\n", " ")[:240]
        print(f"  [{p['title']}] {txt}")
    time.sleep(0.1)

print("== B) opensearch for the missing cities (Latin queries) ==")
for q, fam in [("Grudziądz", "grudziadz"), ("Kleczew", "kleczew"),
               ("Niepołomice", "niepolomice"), ("Siedlce", "siedlce"),
               ("Górnik Łęczna", "gornik"), ("Olimpia Grudziądz", "olimpia"),
               ("Sokół Kleczew", "sokol"), ("Podhale Nowy Targ", "podhale"),
               ("Puszcza Niepołomice", "puszcza"), ("Pogoń Siedlce", "pogon"),
               ("Avia Świdnik", "avia"), ("Stal Rzeszów", "stal"),
               ("Odra Opole", "odra")]:
    u = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
         + urllib.parse.quote(q) + "&limit=5&format=json")
    d = api(u)
    res = (d or [None, None, [], []])[1]
    print(f"  {q!r} -> {res}")
    time.sleep(0.3)
