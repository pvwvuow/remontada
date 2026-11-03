#!/usr/bin/env python3
# cycle-455 batch-16 anchor probes (the AUT tranche, the 447 tie-break winner
# with 3 direct club articles vs POL 0 / UKR 1 / MNE 2 — documented as read).
# A) Wikidata: exact fawiki sitelink titles for the 10 clubs (the club-entity
#    route is deterministic where the tie-break probe already found three).
# B) fa.wiki exact title existence (canonical titles + pageids, one batched
#    action=query call) for the club titles + the city toponyms (the 452
#    city-title rule) + the file's own reading candidates.
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CLUBS = [
    "Altach", "Austria Wien", "FC Hertha Wels", "FC Wacker Innsbruck",
    "First Vienna FC", "Grazer AK", "Ried", "SW Bregenz", "WSG Tirol",
    "Wolfsberger AC",
]
KNOWN_Q = {"Austria Wien": "Q131209", "Grazer AK": "Q659780",
           "Wolfsberger AC": "Q694484"}


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
             + urllib.parse.quote(n) + "&language=en&type=item&limit=5&format=json")
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
            + qid + "&props=sitelinks|labels&languages=en&format=json")
    time.sleep(0.25)
    ent = (g or {}).get("entities", {}).get(qid, {})
    fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
    en = ent.get("labels", {}).get("en", {}).get("value")
    print(f"  {n} -> {qid} ({en}) fa={fa}")
    if fa:
        found[n] = fa

print("== B) fa.wiki exact title existence (batched) ==")
CAND = sorted(set(found.values())) + [
    # city toponyms (the 452 city-title rule) + file-reading candidates
    "آلتاخ", "ولز", "ولس", "اینسبروک", "وین", "گراتس", "رید ام اینکرایس",
    "برگنتس", "تیرول", "فرست وینا", "اولر وینا ۱۸۹۴", "واکر اینسبروک",
    "هرتا ولز", "هرتا ولس", "آستریا وین", "راید آلتاخ",
    "دبلیو اس جی تیرول", "واسگ تیرول", "اس‌دبلیو برگنتس", "اسی‌وی رید",
    "س‌و برگنتس", "گراتسر آک",
]
TITLES = "|".join(CAND)
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
       "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
d = api(url)
for p in (d or {}).get("query", {}).get("pages", {}).values():
    miss = "MISSING" if int(p.get("pageid", -1)) < 0 else f"pageid={p['pageid']}"
    print(f"  {p['title']}  ->  {miss}")
