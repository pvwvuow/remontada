#!/usr/bin/env python3
# cycle-457 batch-18 anchor probes, part 2: (1) the IDENTITY of the three
# surprising exact-title hits (زوریا pageid 44163684 / ورس pageid 1311780 /
# کارپات pageid 3537193 — a bare common-word hit can be the club, the word,
# or something else entirely; the 456 بوکلی lesson: a NON-club subject is
# unusable as an anchor); (2) the Kryvyi Rih spelling hunt (کریفی ریه and
# کریوی ریه both missed); (3) the opensearch gate for the eight clubs
# without a direct article (the 452 rule: an invented form dies here; a
# documented form survives).
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


print("== 1) identity of the three exact-title hits ==")
for pid in ("44163684", "1311780", "3537193"):
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
           "&explaintext=1&exintro=1&inprop=url&pageids=" + pid + "&format=json")
    d = api(url)
    try:
        p = d["query"]["pages"][pid]
        print(f"  pageid {pid}: title={p.get('title')!r}")
        print(f"    extract: {(p.get('extract') or '(no intro extract)')[:220]}")
    except Exception as e:
        print(f"  pageid {pid}: fetch failed {e}")
    time.sleep(0.3)

print("== 2) Kryvyi Rih spelling hunt ==")
CITY = [
    "کریفی ریه", "کریوی ریه", "کریفی ریهو", "کریویریه", "کریفی‌ریه",
    "کریوی‌ریه", "کریوی ریگ", "کریفی ریگ",
]
TITLES = "|".join(CITY)
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info"
       "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
d = api(url)
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if "missing" not in p:
        print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
# fallback: the Wikidata sitelink route for the city itself
url = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
       + urllib.parse.quote("Kryvyi Rih") + "&language=en&type=item&limit=5&format=json")
d = api(url)
for e in (d or {}).get("search", []):
    desc = (e.get("description") or "").lower()
    if "ukraine" in desc and ("city" in desc or "town" in desc):
        g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                + e["id"] + "&props=sitelinks&format=json")
        fa = (g["entities"][e["id"]].get("sitelinks", {}).get("fawiki") or {}).get("title")
        print(f"  Kryvyi Rih -> {e['id']} fawiki={fa}")
        break
    time.sleep(0.2)

print("== 3) opensearch gate ==")
QUERIES = [
    # Epitsentr — club + honest forms
    "اپیتسنتر", "اپیسنتر", "اپیتسنتر کامیانتس", "Epitsentr",
    # Karpaty Lviv — club forms (the city لویو pageid 44886178 verified)
    "کارپات لویو", "کارپاتی", "کارپات (فوتبال)", "Karpaty Lviv",
    # Kryvbas — club + basin forms
    "کریوباس", "کریو باس", "کریوباس کریفی", "Kryvbas",
    # LNZ Cherkasy — letter-reading forms
    "ال‌ان‌زد چرکاسی", "ال ان زد چرکاسی", "LNZ Cherkasy", "ال‌ان‌زد",
    # Liviy Bereh — honest forms
    "لیوی بره", "لوی بره", "کرانه چپ", "Liviy Bereh",
    # Polissya Zhytomyr — region + club forms
    "پولیسیا", "پولسه", "پولیسیا ژیتومیر", "Polissya",
    # Veres Rivne — club forms
    "ورس ریونه", "ورس (فوتبال)", "Veres Rivne",
    # Zorya Luhansk — club forms
    "زوریا لوگانسک", "زوریا (فوتبال)", "Zorya Luhansk",
    # FC Kharkiv — bare city already verified; club-form check
    "اف‌سی خارکوف", "خارکوف (فوتبال)",
    # Dynamo Kyiv bare form (the full باشگاه article verified)
    "دینامو کی‌یف",
]
for q in QUERIES:
    url = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
           + urllib.parse.quote(q) + "&limit=4&format=json")
    d = api(url)
    try:
        r = d[1]
    except Exception:
        r = None
    print(f"  {q!r} -> {r}")
    time.sleep(0.3)
