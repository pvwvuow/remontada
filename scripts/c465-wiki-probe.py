#!/usr/bin/env python3
# cycle-465 batch-22 anchor probes — the PAN=HON TIE (the 464-card pin: the
# 462 census held PAN/HON 9/27 below the ARG wave; the fresh 465 census:
# distinct=1754 EXACTLY = the documented 462 post-census, ZERO drift, rows
# 3210; the count>=3 single-country pool tops with PAN 9/27 = HON 9/27 —
# a TIE, so the 447 tie-break IS invoked: anchor quality — the side with
# more direct fa.wiki club-article anchors is harvested, the other waits
# for the next update). The 447 precedent: RUS 12 = GUA 12 was broken by
# "کیفیت لنگر شکست" (seven direct club-article anchors). A) wikidata exact
# fawiki sitelinks for both 9-club tranches. B) fa.wiki exact title
# existence (canonical titles + pageids, batched) for the sitelinks + the
# honest candidates (the file's OWN Spanish-phonetic convention — boca
# juniors → بوکا جونیورز, real → رئال, de → دی (462), ll → لی; NON-club /
# WRONG-COUNTRY pages must be identity-verified before use — the 456
# بوکلی / 460 آدرا / 461 لا پاز-Argentina / 462 بلگرانو-مندوزا lessons:
# Estrella Roja must NOT be the Serbian/Venezuelan club, Platense FC must
# NOT be the Argentine پلاتنسه, CD Universitario must NOT be the Peruvian
# Universitario de Deportes, Atletico Independiente must NOT be the
# Argentine Independiente).
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TRANCHES = {
    "PAN": [
        "CD Árabe Unido", "CD Plaza Amador", "Sporting San Miguelito",
        "UMECIT FC", "Tauro FC", "CD Universitario", "Herrera FC",
        "Independiente de La Chorrera", "San Francisco FC",
    ],
    "HON": [
        "Estrella Roja", "Atletico Independiente", "Lobos UPNFM",
        "Genesis FC", "Real España", "Juticalpa", "CD Choloma",
        "Olancho FC", "Platense FC",
    ],
}


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


print("== A) wikidata exact fawiki sitelinks for the 18 tie clubs ==")
found = {}   # club -> fa title
for cc, clubs in TRANCHES.items():
    for n in clubs:
        q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
             + urllib.parse.quote(n) + "&language=en&type=item&limit=8&format=json")
        d = api(q)
        toks = [t.lower() for t in re.split(r"[^A-Za-z]+", n) if len(t) > 2]
        qid = None
        for e in (d or {}).get("search", []):
            lab = (e.get("label") or "").lower()
            desc = (e.get("description") or "").lower()
            if any(t in lab for t in toks) and ("football" in desc or "soccer" in desc
                                                or "club" in desc or cc.lower() in desc
                                                or "panama" in desc or "hondur" in desc):
                qid = e["id"]
                break
        time.sleep(0.25)
        if not qid:
            print(f"  [{cc}] {n} -> NO club entity found")
            continue
        g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                + qid + "&props=sitelinks|labels|descriptions&languages=en&format=json")
        time.sleep(0.25)
        ent = (g or {}).get("entities", {}).get(qid, {})
        fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
        en = ent.get("labels", {}).get("en", {}).get("value")
        de = ent.get("descriptions", {}).get("en", {}).get("value")
        print(f"  [{cc}] {n} -> {qid} ({en} | {de}) fa={fa}")
        if fa:
            found[f"{cc}:{n}"] = fa

print("== B) fa.wiki exact title existence (batched) ==")
cand = sorted(set(found.values())) + [
    # honest phonetic candidates (the file's OWN Spanish convention)
    "آراوه اونیدو", "آراب اونیدو", "دپورتیوو آراوه اونیدو",
    "تائورو", "تاورو", "تائورو فوتبال کلوب",
    "پلازا آمادور", "پلازا آمادور",
    "اسپورتینگ سان میگل", "اسپورتینگ سان میگویتو", "اسپورتینگ اس‌ام",
    "اومسیت", "ومیسیت", "یومسیت",
    "یونیورسیتاریو", "یونیورسیتاریو پاناما", "یونیورسیتاریو (پاناما)",
    "هررا", "هررا فوتبال کلوب", "هررا اف‌سی",
    "ایندپندینته دی لا چوررا", "ایندپندینته د لا چوررا",
    "سان فرانسیسکو (پاناما)", "سان فرانسیسکو فوتبال کلوب",
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

print("== C) identity verification (extracts of the EXISTING club pages) ==")
verif = sorted(set(found.values()) | {t for t in present
                 if any(k in t for k in ("پلاتنسه", "ستاره", "یونیورسیتاریو",
                                          "ایندپندینته", "اسپانیا", "خنسیس"))})
if verif:
    T2 = "|".join(verif)
    u2 = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
          "&exintro=1&explaintext=1&titles=" + urllib.parse.quote(T2)
          + "&format=json")
    d2 = api(u2)
    for pid, p in ((d2 or {}).get("query", {}).get("pages", {}) or {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:200].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump({"found": found, "present": present},
          open("/tmp/c465-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c465-wiki.json")

pan_a = sum(1 for k in found if k.startswith("PAN:"))
hon_a = sum(1 for k in found if k.startswith("HON:"))
print(f"ANCHOR SCORE — PAN: {pan_a}/9 direct fa.wiki club articles, "
      f"HON: {hon_a}/9 direct fa.wiki club articles")
print("447 tie-break: the richer side is harvested (a real tie needs the "
      "identity-verified C-block; excluded/absent pages do not count)")
