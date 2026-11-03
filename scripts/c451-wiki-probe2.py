#!/usr/bin/env python3
# cycle-451: exact-title existence checks for likely fa.wiki club articles of
# the two tie pools (CYP vs THA) — the 447 tiebreaker needs a count.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TITLES = [
    # CYP club variants
    "باشگاه فوتبال المپیاکوس نیکوزیا",
    "باشگاه فوتبال ای‌ای‌ال لیماسول",
    "باشگاه فوتبال آئل لیماسول",
    "باشگاه فوتبال ای‌ال لیماسول",
    "باشگاه فوتبال دوکسا کاتوکوپیاس",
    "باشگاه فوتبال ارمیس آرادیپو",
    "باشگاه فوتبال کارمیوتیسا",
    "باشگاه فوتبال اومونیا آرادیپو",
    "باشگاه فوتبال اومونیا ۲۹ می",
    "باشگاه فوتبال دیگنیس مورفو",
    "باشگاه فوتبال آپولون لیماسول",
    # THA club variants
    "باشگاه فوتبال چاینات",
    "باشگاه فوتبال خونکان یونایتد",
    "باشگاه فوتبال ناکون پاتوم",
    "باشگاه فوتبال نونگ بوآ پیچایا",
    "باشگاه فوتبال پاتایا",
    "باشگاه فوتبال سونگخلا",
    "باشگاه فوتبال کاستسارت",
    "باشگاه فوتبال ماهاساراکام",
    "باشگاه فوتبال کانجانابوری",
    "ناکون پاتوم یونایتد",
]


def titles_check(titles):
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info"
           "&redirects=1&format=json&titles="
           + urllib.parse.quote("|".join(titles)))
    for attempt in range(4):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "20", "-A", UA, url],
            capture_output=True, text=True, timeout=30,
        ).stdout
        try:
            d = json.loads(out)
            return (d.get("query", {}).get("pages", {}),
                    d.get("query", {}).get("redirects", []))
        except Exception:
            time.sleep(3 + attempt * 3)
    return None, None


for i in range(0, len(TITLES), 4):
    chunk = TITLES[i:i + 4]
    pages, reds = titles_check(chunk)
    print(f"chunk {chunk}")
    if pages:
        for p in pages.values():
            print(f"   pageid={p.get('pageid', 'MISSING')} title={p.get('title')!r}")
    if reds:
        for r in reds:
            print(f"   redirect: {r.get('from')!r} -> {r.get('to')!r}")
    time.sleep(1.5)
