#!/usr/bin/env python3
# cycle-460 probe3: (A) wikitext identity for the two stub pages (the 456
# بوکلی lesson: identity BEFORE use), (B) second exact-title batch — the
# -ce ending convention (the file's OWN میلتس reads c→تس) and further city
# spellings, (C) Persian-prefix opensearch for the four missing cities.
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


print("== A) wikitext identity (stubs) ==")
for t in ["زنیچ پروشکوف", "ادرا"]:
    u = ("https://fa.wikipedia.org/w/api.php?action=query&prop=revisions"
         "&rvprop=content&rvslots=main&rvchars=400&titles="
         + urllib.parse.quote(t) + "&format=json")
    d = api(u)
    pages = (d or {}).get("query", {}).get("pages", {})
    for pid, p in pages.items():
        if pid == "-1" or "missing" in p:
            print(f"  [{t}] MISSING")
            continue
        rev = (p.get("revisions") or [{}])[0]
        slots = rev.get("slots", {}) or {}
        content = ((slots.get("main") or {}).get("*") or "")[:400]
        print(f"  [{p['title']}] wikitext[:400]: {content}".replace("\n", " "))
    time.sleep(0.3)

print("== B) exact-title batch 2 (-ce convention + more spellings) ==")
CAND = ["شیدلتس", "سیدلتس", "شیدلتسه", "نیپووومیتس", "نیپولومیتس",
        "نیپووُمیتسه", "سوکوو", "کلچوا", "گرودزیادز", "گروجونتس",
        "گراودنتس", "کیلتس", "کیلتسه", "پودهاله", "پودحاله",
        "گورنیک ونچنا", "استال ژشوف", "پوگون شیدلچه", "ادرا اوپوله",
        "آویا شویدنگک", "زنیچ پروشکوف"]
TITLES = "|".join(sorted(set(CAND)))
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
       "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
d = api(url)
pages = (d or {}).get("query", {}).get("pages", {})
for pid, p in pages.items():
    if pid != "-1" and "missing" not in p:
        print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
miss = [t["title"] for t in pages.values() if "missing" in t]
print(f"  ({len(miss)} titles missing)")

print("== C) Persian-prefix opensearch ==")
for q in ["گرود", "گراود", "کلچ", "نیپو", "شیدل", "سیدل", "سوکو", "پودها",
          "ونچنا", "پروشکو"]:
    u = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
         + urllib.parse.quote(q) + "&limit=6&format=json")
    d = api(u)
    res = (d or [None, None, [], []])[1]
    print(f"  {q!r} -> {res}")
    time.sleep(0.3)
