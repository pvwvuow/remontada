#!/usr/bin/env python3
# cycle-460 probe4: (A) Wikidata fawiki sitelinks for the four missing city
# toponyms + the Odra river (the robust route when title-spelling probes
# die), (B) identity extracts for گروجونتس / گراودنتس (which is Grudziądz?),
# (C) exact-title existence for the direct club article «باشگاه فوتبال
# زنیچ پروشکوف» (the زنیچ پروشکوف page is an R-from-move redirect to it —
# the FC rule drops the descriptor) + آدرا + اودر.
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


print("== A) wikidata fawiki sitelinks for cities/river ==")
for name, desc_hint in [("Siedlce", "city Poland"), ("Kleczew", "town Poland"),
                        ("Niepołomice", "town Poland"), ("Grudziądz", "city Poland"),
                        ("Odra", "river"), ("Oder", "river")]:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(name) + "&language=en&type=item&limit=8&format=json")
    d = api(q)
    pick = None
    for e in (d or {}).get("search", []):
        desc = (e.get("description") or "").lower()
        lab = (e.get("label") or "").lower()
        if "poland" in desc or "polish" in desc or ("river" in desc and "europe" in desc) \
           or ("river" in desc and name == "Oder"):
            pick = e
            break
    time.sleep(0.2)
    if not pick:
        print(f"  {name} -> no entity with a Poland/river description")
        continue
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
            + pick["id"] + "&props=sitelinks|labels|descriptions&languages=en&format=json")
    ent = (g or {}).get("entities", {}).get(pick["id"], {})
    fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
    print(f"  {name} -> {pick['id']} ({pick.get('label')} | {pick.get('description')}) fa={fa}")
    time.sleep(0.2)

print("== B) identity extracts for the Grudziądz candidates ==")
u = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts&exintro"
     "&explaintext&exchars=200&titles=" + urllib.parse.quote("گروجونتس|گراودنتس|آدرا|اودر")
     + "&format=json")
d = api(u)
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid != "-1" and "missing" not in p:
        print(f"  [{p['title']}] {(p.get('extract') or '')[:200]}")
    else:
        print(f"  MISSING: {p.get('title')}")

print("== C) exact-title: the direct club article + river ==")
TITLES = "|".join(["باشگاه فوتبال زنیچ پروشکوف", "اودر", "اودرا (ابهام‌زدایی)"])
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
       "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
d = api(url)
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid != "-1" and "missing" not in p:
        print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
    else:
        print(f"  MISSING: {p.get('title')}")
