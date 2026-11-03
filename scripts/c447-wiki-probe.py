#!/usr/bin/env python3
# cycle-447: live fa.wikipedia anchor probes for the batch-12 (RUS) renders.
# One query per candidate rendering with polite spacing; prints what the
# encyclopedia actually serves so every Persian render is anchored, not guessed.
import json
import subprocess
import time
import urllib.parse

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

QUERIES = [
    "سپارتاک مسکو", "زسکا مسکو", "سسکا مسکو", "لوکوموتیو مسکو",
    "کراسنودار", "روبین کازان", "مخاچ‌قلعه", "کرلیا سوفیتوف",
    "تولیاتی", "اورنبورگ", "فاکل ورونژ", "اخمت گروزنی", "بالتیکا",
    "آکرون تولیاتی", "دینامو مخاچ قلعه", "سامارا",
]


def search(q: str):
    url = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
           + urllib.parse.quote(q) + "&limit=3&format=json")
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
    print(f"{q!r} -> {r}")
    time.sleep(1.2)
