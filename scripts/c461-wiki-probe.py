#!/usr/bin/env python3
# cycle-461 batch-20 anchor probes (the MEX tranche AFTER the 435 skip line:
# 8 names / 24 rows — the two count-3 (W) sides Club León (W) / Santos Laguna
# (W) are SKIPPED at pick time per the 435 line, no (W)-level convention yet;
# the fresh census re-read answered distinct=1779 EXACTLY = the documented
# 460 post-census, ZERO distinct drift for the TENTH consecutive cycle, and
# MEX 10/30 heads the pool with the two (W) names inside). A) Wikidata exact
# fawiki sitelinks for the 8 clubs. B) fa.wiki exact title existence
# (canonical titles + pageids, batched) for the city toponyms + the honest
# candidates (the 452 city-title rule / the file's OWN phonetic-Spanish
# convention — boca juniors de cali → بوکا جونیورز دی کالی, estudiantes →
# استودیانتس; NON-club / WRONG-COUNTRY pages must be identity-verified before
# exclusion — the 456 بوکلی / 460 آدرا-Spain lessons).
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CLUBS = [
    "Alacranes de Durango", "Atlético La Paz", "Atlético Morelia",
    "Cancún FC", "Leones Negros", "Piratas", "Tlaxcala FC", "Venados FC",
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


print("== A) wikidata exact fawiki sitelinks for the 8 MEX clubs ==")
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
                                            or "mexican" in desc):
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
    "دورانگو", "دورنگو", "لا پاز", "لاپاز",
    "مورلیا", "کانکون", "کانکون",
    "گوادالاخارا", "گوادالاخارا",
    "کمپچه", "تلاکسکالا", "مریدا", "مریدا", "یوکاتان",
    # honest club-name candidates (the file's OWN phonetic-Spanish convention)
    "الاکرانس", "آلاکرانس", "الاکرانس دی دورانگو", "الاکرانس دورانگو",
    "اتلتیکو مورلیا", "اتلتیکو لا پاز",
    "کانکون اف‌سی", "کانکون اف سی",
    "لئونس نگروس", "لیونس نگروس", "شیرهای سیاه",
    "پیراتاس", "دزدای دریایی", "دزدین دریایی",
    "ونادوس", "ونادوس اف‌سی", "ونادوس اف سی",
    "تلاکسکالا اف‌سی", "تلاکسکالا اف سی",
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
          open("/tmp/c461-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c461-wiki.json")
