#!/usr/bin/env python3
# cycle-456 batch-17 anchor probes, part 2: opensearch evidence for the eight
# clubs without a direct fa.wiki club article (Dečić Tuzi, FK Bokelj, Jezero,
# Mornar, OFK Mladost Donja Gorica, Otrant, Petrovac, Sutjeska) + the
# identity of the بوکلی page (pageid 22771837 — its pageid is far older than
# the Montenegro toponym cluster 41-44m, so its subject MUST be verified
# before any bare-بوکلی value) + the Ulcinj spelling via Wikidata sitelink +
# the city-title candidates that missed (اولتسین/پتروواس).
# The 452 opensearch-gate rule: an invented form dies here; a documented
# form (the encyclopedia's or the indexed press's own spelling) survives.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

QUERIES = [
    # Dečić — club + city candidates
    "دچیچ", "دچیچ توزی", "دکیچ", "Dečić",
    # Bokelj — the بوکلی page identity question + club forms
    "بوکلی", "بوکلی کوتور", "FK Bokelj", "بکلی",
    # Jezero — club + city forms
    "یزرو", "یزرو پلاو", "جزرو", "FK Jezero",
    # Mornar — club + city forms
    "مورنار", "مورنار بار", "FK Mornar",
    # OFK Mladost Donja Gorica — club forms + the toponym spellings
    "ملادوست", "ملادوست دانیا گوریتسا", "دانیا گوریتسا", "دونیا گوریتسا",
    "Mladost Donja Gorica",
    # Otrant — club + the Italian anchor analogy
    "اوترونت", "اوتروانت", "اوترانت", "اوترونت اولتسین", "Otrant Ulcinj",
    # Petrovac — club + toponym spellings
    "پتروواس", "پتروواس", "پتروواتس نا مورو", "پتروواس نا مورو", "FK Petrovac",
    # Sutjeska — club + city forms
    "سوتجسکا", "سوتجسکا نیکشیچ", "سوتیسکا", "FK Sutjeska",
    # Budućnost bare form candidates (the full باشگاه article already exists)
    "بودوچنوست", "بودوچنوست پودگوریتسا",
    # Ulcinj toponym spellings (city-title candidates)
    "اولتسین", "اولتسين", "اولچین", "اولتسین (شهر)",
]


def search(q: str):
    url = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
           + urllib.parse.quote(q) + "&limit=4&format=json")
    for attempt in range(3):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "20", "-A", UA, url],
            capture_output=True, text=True, timeout=30,
        ).stdout
        try:
            return json.loads(out)[1]
        except Exception:
            time.sleep(2 + attempt * 2)
    return None


for q in QUERIES:
    r = search(q)
    print(f"  {q!r} -> {r}")
    time.sleep(0.3)

print("== بوکلی page identity (pageid 22771837) ==")
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
       "&explaintext=1&exintro=1&pageids=22771837&format=json")
out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                     capture_output=True, text=True, timeout=40).stdout
try:
    d = json.loads(out)
    p = d["query"]["pages"]["22771837"]
    print("title:", p.get("title"))
    print("extract:", (p.get("extract") or "")[:400])
except Exception as e:
    print("identity fetch failed:", e)

print("== Ulcinj via Wikidata sitelink ==")
url = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
       + urllib.parse.quote("Ulcinj") + "&language=en&type=item&limit=5&format=json")
out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                     capture_output=True, text=True, timeout=40).stdout
try:
    d = json.loads(out)
    for e in d.get("search", []):
        desc = (e.get("description") or "").lower()
        if "montenegro" in desc or "town" in desc or "city" in desc:
            q2 = ("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                  + e["id"] + "&props=sitelinks&format=json")
            out2 = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, q2],
                                  capture_output=True, text=True, timeout=40).stdout
            g = json.loads(out2)
            fa = (g["entities"][e["id"]].get("sitelinks", {}).get("fawiki") or {}).get("title")
            print(f"  Ulcinj -> {e['id']} ({desc}) fawiki={fa}")
            break
except Exception as e:
    print("ulcinj wikidata failed:", e)
