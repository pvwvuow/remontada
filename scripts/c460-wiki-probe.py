#!/usr/bin/env python3
# cycle-460 batch-19 anchor probes (the POL tranche, the 446-pick rule:
# the live ±7 census re-read this cycle answered POL 10 names / 30 rows as
# the LARGEST count>=3 single-country pool — no tie at the top, PAN/HON 9/27
# below, so the 447 tie-break is NOT invoked this cycle; documented as read).
# A) Wikidata: exact fawiki sitelinks for the 10 clubs. B) fa.wiki exact
# title existence (canonical titles + pageids, batched) for the city
# toponyms + the honest candidates (the 452 city-title rule / the 455-457
# honest-read + letter-reading precedents; NON-club pages must be
# identity-verified before exclusion — the 456 بوکلی lesson).
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CLUBS = [
    "Avia Świdnik", "Górnik Łęczna", "Odra Opole", "Olimpia Grudziądz",
    "Podhale Nowy Targ", "Pogoń Siedlce", "Puszcza Niepołomice",
    "Sokół Kleczew", "Stal Rzeszów", "Znicz Pruszków",
]


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


print("== A) wikidata exact fawiki sitelinks for the 10 clubs ==")
found = {}
for n in CLUBS:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(n) + "&language=en&type=item&limit=8&format=json")
    d = api(q)
    toks = [t.lower() for t in re.split(r"[^A-Za-z]+", n) if len(t) > 2]
    qid = None
    for e in (d or {}).get("search", []):
        lab = (e.get("label") or "").lower()
        desc = (e.get("description") or "").lower()
        if any(t in lab for t in toks) and ("football" in desc or "club" in desc
                                            or "polish" in desc):
            qid = e["id"]
            break
    time.sleep(0.25)
    if not qid:
        print(f"  {n} -> NO club entity found")
        continue
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
            + qid + "&props=sitelinks|labels|descriptions&languages=en&format=json")
    time.sleep(0.25)
    ent = (g or {}).get("entities", {}).get(qid, {})
    fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
    en = ent.get("labels", {}).get("en", {}).get("value")
    de = ent.get("descriptions", {}).get("en", {}).get("value")
    print(f"  {n} -> {qid} ({en} | {de}) fa={fa}")
    if fa:
        found[n] = fa

print("== B) fa.wiki exact title existence (batched) ==")
CAND = sorted(set(found.values())) + [
    # city toponyms (the 452 city-title rule) — spelling families
    "لچنا", "لِچنا", "ونچنا",
    "گرودیونتس", "گرودزیادز", "گرودژیادز",
    "کلچف", "کلچو",
    "نووی تارگ", "نو تارگ",
    "نیپووومیتسه", "نیپولومیتسه",
    "پروشکوف", "پروسکوو",
    "شیدلچه", "سیدلچه", "شیدلتسه",
    "شویدنگک", "سویدنگک",
    "ژشوف", "رشوف",
    "اوپوله", "اپوله",
    # honest club-name candidates
    "گورنیک", "گورنیک لچنا", "گورنیک ونچنا",
    "المپیا", "المپیا گرودیونتس",
    "سوکوو", "سوکول", "سوکوو کلچف",
    "پودهاله", "پود هاله", "پودهاله نووی تارگ",
    "پوشچا", "پوشچا نیپووومیتسه",
    "زنیچ", "زنیچ پروشکوف", "زنیچ پروشکوف",
    "پوگون", "پوگون شیدلچه",
    "آویا", "اویا", "آویا شویدنگک",
    "استال", "استال ژشوف",
    "ادرا", "اودرا", "ادرا اوپوله",
]
TITLES = "|".join(sorted(set(CAND)))
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
       "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
d = api(url)
pages = (d or {}).get("query", {}).get("pages", {})
present = {}
for pid, p in pages.items():
    if pid != "-1" and "missing" not in p:
        present[p["title"]] = p.get("lastrevid")
        print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
missing = [t["title"] for t in pages.values() if "missing" in t]
print(f"  ({len(missing)} titles missing)")
json.dump({"found": found, "present": present},
          open("/tmp/c460-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c460-wiki.json")
