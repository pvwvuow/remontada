#!/usr/bin/env python3
# cycle-460 probe5 (final gap-closer): (A) exact pageids for the five city
# anchors + the direct club article «باشگاه فوتبال زنیچ پروشکوف» (the
# redirect target; the earlier batched query with a parenthesized title
# silently failed — retried with plain titles), (B) wikidata fawiki
# sitelinks for the Podhale region and the Avia aircraft maker (the last
# two letter-reading candidates).
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


print("== A) exact pageids (plain titles, batched) ==")
TITLES = ["باشگاه فوتبال زنیچ پروشکوف", "شدلتسه", "گمینا کلچو",
          "نیپلومیتز", "گروجونتس", "اودر", "ونچنا", "شویدنگک",
          "نووی تارگ", "پروشکوف", "ژشوف", "اوپوله"]
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
       "&titles=" + urllib.parse.quote("|".join(TITLES)) + "&format=json")
d = api(url)
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid != "-1" and "missing" not in p:
        print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
    else:
        print(f"  MISSING: {p.get('title')}")

print("== B) wikidata sitelinks: Podhale region / Avia maker ==")
for name, filt in [("Podhale", None), ("Avia", "aircraft")]:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(name) + "&language=en&type=item&limit=8&format=json")
    d = api(q)
    pick = None
    for e in (d or {}).get("search", []):
        desc = (e.get("description") or "").lower()
        if (filt and filt in desc) or (not filt and ("region" in desc or "poland" in desc)):
            pick = e
            break
    time.sleep(0.2)
    if not pick:
        print(f"  {name} -> no matching entity")
        continue
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
            + pick["id"] + "&props=sitelinks|labels|descriptions&languages=en&format=json")
    ent = (g or {}).get("entities", {}).get(pick["id"], {})
    fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
    print(f"  {name} -> {pick['id']} ({pick.get('label')} | {pick.get('description')}) fa={fa}")
    time.sleep(0.2)
