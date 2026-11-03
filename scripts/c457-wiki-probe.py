#!/usr/bin/env python3
# cycle-457 batch-18 anchor probes (the UKR tranche, the 447 deep tie-break
# winner re-read live this cycle: dead-even 1-1 on DIRECT club articles, so
# the read extended one documented level — CITY-TOPONYM anchor quality (the
# 452 rule): UKR 6 city hits (خارکوف Q42308، ژیتومیر Q156713، ریونه Q156739،
# چرکاسی Q157055، کامیانتس-پودیلسکی Q193965، برهوفه Q146497*) vs POL 4 —
# scripts/c457-wiki-tiebreak.py, documented as read. *the برهوفه hit is a
# WRONG-CITY probe artifact (Liviy Bereh is a Kyiv-side club; Berehove is a
# Zakarpattia town) — excluded from the value anchoring, kept in the
# tie-break score as the probe found it). A) Wikidata: exact fawiki
# sitelinks for the 10 clubs. B) fa.wiki exact title existence (canonical
# titles + pageids, batched) for the club titles + the city toponyms + the
# honest candidates.
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CLUBS = [
    "Dynamo Kyiv", "Epitsentr Kamianets-Podilskyi", "FC Kharkiv", "Karpaty",
    "Kryvbas", "LNZ Cherkasy", "Liviy Bereh", "Polissya Zhytomyr",
    "Veres Rivne", "Zorya",
]
KNOWN_Q = {"Dynamo Kyiv": "Q179075"}


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
    qid = KNOWN_Q.get(n)
    if not qid:
        q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
             + urllib.parse.quote(n) + "&language=en&type=item&limit=6&format=json")
        d = api(q)
        toks = [t.lower() for t in re.split(r"[^A-Za-z]+", n) if len(t) > 2]
        for e in (d or {}).get("search", []):
            lab = (e.get("label") or "").lower()
            desc = (e.get("description") or "").lower()
            if any(t in lab for t in toks) and ("football" in desc or "club" in desc):
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
    # city toponyms (the 452 city-title rule)
    "کی‌یف", "کامیانتس-پودیلسکی", "خارکوف", "لویو", "کریفی ریه", "کریوی ریه",
    "چرکاسی", "ژیتومیر", "ریونه", "لوگانسک", "لویو (اوکراین)",
    # honest transliteration candidates (documented-as-read fallbacks)
    "دینامو کی‌یف", "اپیتسنتر", "اپیتسنتر کامیانتس-پودیلسکی", "کارپات",
    "کارپات لویو", "کریوباس", "پولیسیا", "پولیسیا ژیتومیر", "ورس",
    "ورس ریونه", "زوریا", "زوریا لوگانسک", "لیوی بره", "ال‌ان‌زد چرکاسی",
    "رشته‌کوه کارپات",
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
          open("/tmp/c457-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c457-wiki.json")
