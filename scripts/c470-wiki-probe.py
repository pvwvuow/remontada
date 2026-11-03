#!/usr/bin/env python3
# cycle-470 batch-25 (the USA tranche — the four-way 8/24 tie won 4 vs 3/2/2
# by the fresh 447 re-read): A) direct fa.wiki CLUB-article hunt for the four
# clubs without a wikidata sitelink (CF Montréal / FC Dallas / Nashville SC /
# Sporting Kansas City) under ANY plausible spelling (the 466 lesson: the
# رئال اسپانیا title was the currency page — every hit identity-checked).
# B) the CITY-title spellings for the honest reads (the 452/461 rule: the
# city article's OWN spelling over press forms).
import json, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

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

CANDS = {
    "CF Montréal": ["باشگاه فوتبال مونترال", "باشگاه فوتبال مونترال امپکت",
                    "باشگاه فوتبال امپکت مونترال", "ام‌ال‌اس مونترال",
                    "باشگاه فوتبال ای‌ام‌اس مونترال"],
    "FC Dallas": ["باشگاه فوتبال دالاس", "باشگاه فوتبال دالاس برن",
                  "اف‌سی دالاس", "باشگاه فوتبال اف‌سی دالاس"],
    "Nashville SC": ["باشگاه فوتبال نشویل", "باشگاه فوتبال نشویل اس‌سی",
                     "باشگاه فوتبال ناشویل", "باشگاه فوتبال ناشویل اس‌سی"],
    "Sporting Kansas City": ["باشگاه فوتبال اسپورتینگ کانزاس‌سیتی",
                             "باشگاه فوتبال اسپورتینگ کانزاس سیتی",
                             "باشگاه فوتبال اسپورتینگ کانزاس‌سیتی (ام‌ال‌س)"],
}
CITIES = ["مونترال", "دالاس", "نشویل", "ناشویل", "کانزاس‌سیتی", "کانزاس سیتی",
          "کانزاس‌سیتی، کانزاس", "کانزاس سیتی، میزوری"]

print("== A) club-article candidates ==")
allc = [t for ts in CANDS.values() for t in ts]
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles="
        + urllib.parse.quote("|".join(allc)) + "&format=json")
found = {}
for pid, p in ((d.get("query") or {}).get("pages") or {}).items():
    if pid != "-1" and "missing" not in p:
        found[p["title"]] = p.get("lastrevid")
        print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
print(f"  ({len(allc)-len(found)} candidates missing)")

print("== B) city titles ==")
d2 = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles="
         + urllib.parse.quote("|".join(CITIES)) + "&format=json")
for pid, p in ((d2.get("query") or {}).get("pages") or {}).items():
    tag = "EXISTS" if (pid != "-1" and "missing" not in p) else "missing"
    print(f"  {tag} {p['title']!r}")

print("== C) identity of any found club page (intro 220 chars) ==")
if found:
    d3 = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts&exintro=1"
             "&explaintext=1&titles=" + urllib.parse.quote("|".join(sorted(found)))
             + "&format=json")
    for pid, p in ((d3.get("query") or {}).get("pages") or {}).items():
        if pid == "-1" or "missing" in p:
            continue
        print(f"  {p['title']} :: {(p.get('extract') or '')[:220].replace(chr(10),' ')}")
json.dump({"club": found}, open("/tmp/c470-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c470-wiki.json")
