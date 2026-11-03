#!/usr/bin/env python3
# cycle-452 batch-15 anchor probes (the THA tranche, the 451 tie runner-up).
# Two gates, both live fa.wikipedia, UA Chrome/124:
#  A) exact TITLE EXISTENCE for the toponym candidates — one batched
#     action=query call returns the canonical titles + missing flags (the
#     byte-authority read; opensearch alone cannot tell article vs redirect
#     ordering).
#  B) opensearch for club-article candidates per pool name.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

# A) toponym title existence (canonical titles come back normalized)
TITLES = ("ناکون پاتوم|ناخون پاتوم|چاینات|کانتچانابوری|ساتون|سونگخلا|"
          "لویی (تایلند)|استان لویی|شهرستان لویی|دانشگاه کاسه‌سارت|کاسه‌سارت|"
          "مهاساراخام|ماهاساراکام|پاتایا|خون کائن|نونگ بوا")

url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
       "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                     capture_output=True, text=True, timeout=40).stdout
d = json.loads(out)
print("== A) exact title existence ==")
for p in d["query"]["pages"].values():
    miss = "MISSING" if int(p.get("pageid", -1)) < 0 else f"pageid={p['pageid']}"
    print(f"  {p['title']}  ->  {miss}")
time.sleep(1.5)

# B) opensearch club-article candidates
QUERIES = [
    "باشگاه فوتبال چاینات هورنبیل", "چاینات هورنبیل",
    "باشگاه فوتبال کانتچانابوری پاور", "کانتچانابوری پاور",
    "باشگاه فوتبال کاسه‌سارت", "کاسه‌سارت", "کستسارت",
    "باشگاه فوتبال خون کائن", "خون کائن یونایتد",
    "باشگاه فوتبال مهاساراخام", "مهاساراخام سام بای تائو",
    "باشگاه فوتبال موانگ لویی", "موانگ لویی یونایتد",
    "باشگاه فوتبال ناخون پاتوم یونایتد", "باشگاه فوتبال ناکون پاتوم",
    "باشگاه فوتبال نونگ بوا پیچایا", "نونگ بوا پیچایا",
    "باشگاه فوتبال پی تی ساتون", "پی‌تی ساتون",
    "باشگاه فوتبال پاتایا دلفینز", "پاتایا دلفینز یونایتد",
    "باشگاه فوتبال سونگخلا", "سونگخلا یونایتد",
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
