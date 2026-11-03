#!/usr/bin/env python3
# cycle-466 batch-23 anchor probes — the HON tranche (the 465-card pin: the
# unbroken half of the PAN/HON 9/27 tie; PAN was harvested in 465 by the 447
# tie-break, HON waits for THIS update). Same probe family as c465-wiki-probe:
# A) wikidata exact fawiki sitelinks for the 9 HON clubs. B) fa.wiki exact
# title existence (canonical titles + pageids, batched) for the sitelinks +
# the honest candidates (the file's OWN Spanish-phonetic convention — boca
# juniors → بوکا جونیورز, real → رئال, de → دی (462), estrella → استریا,
# genesis → خنسیس; NON-club / WRONG-COUNTRY pages must be identity-verified
# before use — the 456 بوکلی / 460 آدرا / 461 لا پاز-Argentina / 462 بلگرانو-
# ماندوزا lessons: Platense FC must NOT be the Argentine پلاتنسه (462's own
# value), Atletico Independiente must NOT be the Argentine Independiente
# (462), Estrella Roja must NOT be the Serbian/Venezuelan club).
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

HON = [
    "Estrella Roja", "Atletico Independiente", "Lobos UPNFM",
    "Genesis FC", "Real España", "Juticalpa", "CD Choloma",
    "Olancho FC", "Platense FC",
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


print("== A) wikidata exact fawiki sitelinks for the 9 HON clubs ==")
found = {}   # club -> fa title
for n in HON:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(n) + "&language=en&type=item&limit=8&format=json")
    d = api(q)
    toks = [t.lower() for t in re.split(r"[^A-Za-z]+", n) if len(t) > 2]
    qid = None
    for e in (d or {}).get("search", []):
        lab = (e.get("label") or "").lower()
        desc = (e.get("description") or "").lower()
        if any(t in lab for t in toks) and ("football" in desc or "soccer" in desc
                                            or "club" in desc or "hondur" in desc):
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
cand = sorted(set(found.values())) + [
    # honest phonetic candidates (the file's OWN Spanish convention)
    "استریا روخا", "استرخیا روخا", "ستاره سرخ",
    "اتلتیکو ایندپندینته", "ایندپندینته (هندوراس)",
    "لوبوس یو‌پی‌ان‌اف‌ام", "لوبوس UPNFM",
    "خنسیس", "جنسیس", "خنسیس (هندوراس)",
    "رئال اسپانیا", "رئال اسپانیا (هندوراس)", "رئال کلوب دپورتیوو اسپانیا",
    "خوتیکالپا", "هوتیکالپا", "جوتیکالپا",
    "چولوما", "دپورتیوو چولوما",
    "اولانچو", "اولانچو فوتبال کلوب",
    "پلاتنسه (هندوراس)", "دپورتیوو پلاتنسه", "کلوپ دپورتیوو پلاتنسه",
]
TITLES = "|".join(sorted(set(cand)))
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

print("== C) identity verification (extracts of the EXISTING candidate pages) ==")
verif = sorted(set(found.values()) | set(present))
if verif:
    T2 = "|".join(verif)
    u2 = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
          "&exintro=1&explaintext=1&titles=" + urllib.parse.quote(T2)
          + "&format=json")
    d2 = api(u2)
    for pid, p in ((d2 or {}).get("query", {}).get("pages", {}) or {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:220].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump({"found": found, "present": present},
          open("/tmp/c466-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c466-wiki.json")
print(f"ANCHOR SCORE — HON: {len(found)}/9 direct fa.wiki sitelink titles")
