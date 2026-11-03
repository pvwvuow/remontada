#!/usr/bin/env python3
# cycle-450 round 2: exact-title existence checks (titles= API, redirects on)
# for the remaining batch-13 (GUA) render candidates.
import json
import subprocess
import time
import urllib.parse

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

TITLES = [
    "کوبان ایمپریال", "باشگاه فوتبال آنتیگوا گواتمالا", "گواستاتویا",
    "دپورتیوو مارکوئنزه", "مالاکاتان", "میسکو", "سن پدرو ساکاتپکز",
    "شلاجو", "شلاخو", "کومونیکیسیونس", "کومونی‌کاسیونس",
    "باشگاه فوتبال مونیسیپال", "سوچیتپکز", "آئورورا (ابهام‌زدایی)",
    "لیگ ملی گواتمالا", "کسیلاخو",
]


def titles_check(titles):
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info"
           "&redirects=1&format=json&titles="
           + urllib.parse.quote("|".join(titles)))
    for attempt in range(3):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "20", "-A", UA, url],
            capture_output=True, text=True, timeout=30,
        ).stdout
        try:
            d = json.loads(out)
            pages = d.get("query", {}).get("pages", {})
            red = d.get("query", {}).get("redirects", [])
            return pages, red
        except Exception:
            time.sleep(2 + attempt * 2)
    return None, None


for i in range(0, len(TITLES), 5):
    chunk = TITLES[i:i + 5]
    pages, reds = titles_check(chunk)
    print(f"chunk {chunk}")
    if pages:
        for pid, p in pages.items():
            print(f"   pageid={p.get('pageid', 'MISSING')} title={p.get('title')!r}")
    if reds:
        for r in reds:
            print(f"   redirect: {r.get('from')!r} -> {r.get('to')!r}")
    time.sleep(1.5)
