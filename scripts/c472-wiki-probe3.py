#!/usr/bin/env python3
# cycle-472 anchor probe #3 — DIRECT fa.wiki existence + identity for the
# candidates the flaky search paths missed or documented earlier (the 471
# direct-fa-probe precedent). CZE: the 471-documented 4th anchor ملادا
# بولسلاف (Mladá Boleslav) + honest-read spellings for the rest; ISR: the
# 471-documented اشدود (FC Ashdod) + the remaining five clubs.
import json, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

PROBES = {
    # CZE — the 471 documented anchor re-verified + remaining tranche
    "CZE": [
        "ملادا بولسلاف", "باشگاه فوتبال ملادا بولسلاف",
        "آرتیس برنو", "پروستییوف", "اس‌کی پروستییوف",
        "تپلیتسه", "باشگاه فوتبال تپلیتسه",
        "ویسوچینا ییهلاوا", "ییهلاوا",
    ],
    # ISR — the 471 documented اشدود re-verified + remaining tranche
    "ISR": [
        "اشدود", "باشگاه فوتبال اشدود",
        "هاپوئل رعاننا", "هاپوئل کفر شالم", "ایرونی مودیعین",
        "مکابی کابیلیو یافا", "مکابی یافا", "کریات یام",
    ],
}


def api(url):
    for attempt in range(4):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "25", "-A", UA, url],
            capture_output=True, text=True, timeout=40,
        ).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


hits = {}
for cc, titles in PROBES.items():
    print(f"== [{cc}] direct fa.wiki existence ==")
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
           "&titles=" + urllib.parse.quote("|".join(titles)) + "&format=json")
    d = api(url)
    pages = ((d or {}).get("query") or {}).get("pages") or {}
    found_titles = []
    for pid, p in pages.items():
        if pid != "-1" and "missing" not in p:
            found_titles.append(p["title"])
            print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
        else:
            print(f"  missing: {p.get('title')}")
    hits[cc] = found_titles
    time.sleep(0.5)

all_found = sorted({t for v in hits.values() for t in v})
if all_found:
    print("== identity extracts ==")
    u2 = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
          "&exintro=1&explaintext=1&titles=" + urllib.parse.quote("|".join(all_found))
          + "&format=json")
    d2 = api(u2)
    for pid, p in (((d2 or {}).get("query") or {}).get("pages") or {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:220].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump(hits, open("/tmp/c472-wiki3.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c472-wiki3.json")
