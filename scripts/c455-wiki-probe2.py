#!/usr/bin/env python3
# cycle-455 batch-16 anchor probes, part 2: opensearch evidence for the five
# clubs without a direct fa.wiki club article (Altach, FC Hertha Wels, FC
# Wacker Innsbruck, Ried, SW Bregenz) + the GAK/WAC abbreviation-form reads.
# The 452 opensearch-gate rule: an invented form dies here; a documented
# form (the encyclopedia's or the indexed press's own spelling) survives.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

QUERIES = [
    # Altach — city/club candidates
    "آلتاخ", "راین‌دورف آلتاخ", "اس‌سی راین‌دورف آلتاخ", "Altach",
    # Hertha Wels — the city ولس (pageid 638927) + club forms
    "هرتا ولس", "هرتا Wels", "باشگاه هرتا ولس", "WSC Hertha Wels",
    # Wacker Innsbruck — the city اینسبروک (pageid 222006) + club forms
    "واکر اینسبروک", "باشگاه فوتبال واکر اینسبروک", "FC Wacker Innsbruck",
    "واکر", "ایننسبروک",
    # Ried — city + club forms
    "رید", "رید ایم اینکرایس", "اسی وی رید", "SV Ried", "رید ایم اینکرایس",
    # SW Bregenz — the city برگنتس (pageid 643035) + club forms
    "برگنتس", "شوارتز وایس برگنتس", "SW Bregenz", "اس دبلیو برگنتس",
    # abbreviation-form reads for the two club-article clubs
    "گراتس", "گراتسر", "ولفسبرگر", "ولفسبرگر آک", "تیرول", "تیروول",
    "فرست ویینا", "ویینا",
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
