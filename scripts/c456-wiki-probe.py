#!/usr/bin/env python3
# cycle-456 batch-17 anchor probes (the MNE tranche, the 447 tie-break winner
# re-read live this cycle with 2 direct club articles vs POL 1 / UKR 1 —
# scripts/c456-wiki-tiebreak.py, documented as read; the 455 read had MNE 2 /
# UKR 1 / POL 0 — the MNE lead held). A) Wikidata: exact fawiki sitelink
# titles for the 10 clubs (the club-entity route is deterministic where the
# tie-break probe already found two). B) fa.wiki exact title existence
# (canonical titles + pageids, one batched action=query call) for the club
# titles + the city toponyms (the 452 city-title rule) + honest candidates.
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CLUBS = [
    "Budućnost Podgorica", "Dečić Tuzi", "FK Arsenal Tivat", "FK Bokelj",
    "Jezero", "Mornar", "OFK Mladost Donja Gorica", "Otrant", "Petrovac",
    "Sutjeska",
]
KNOWN_Q = {"Budućnost Podgorica": "Q219264", "FK Arsenal Tivat": "Q1354304"}


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
    "پودگوریتسا", "توزی", "تیوات", "کوتور", "پلاو", "بار", "اولتسین",
    "پتروواتس", "نیکشیچ", "دانیا گوریتسا", "پتروواتس نا مورو", "بودوچنوست",
    # honest transliteration candidates (documented-as-read fallbacks)
    "بودوچنوست پودگوریتسا", "دچیچ", "دچیچ توزی", "آرسنال تیوات",
    "بوکلی", "بوکلی کوتور", "یزرو", "یزرو پلاو", "مورنار", "مورنار بار",
    "ملادوست", "ملادوست دانیا گوریتسا", "اوترونت", "اوترونت اولتسین",
    "پتروواس", "سوتجسکا", "سوتجسکا نیکشیچ", "اوترانت",
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
          open("/tmp/c456-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c456-wiki.json")
