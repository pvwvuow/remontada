#!/usr/bin/env python3
# cycle-451: live fa.wikipedia anchor probes for BOTH tie pools (CYP vs THA).
# The 447 precedent decides ties on anchor quality + visibility, documented
# as read. One opensearch query per candidate render, polite spacing.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

QUERIES = [
    # CYP pool — club article candidates
    "آ.ئ.ل لیماسول", "AEL لیماسول", "باشگاه فوتبال آ.ئ.ل لیماسول",
    "المپیاکوس نیکوزیا", "باشگاه فوتبال المپیاکوس نیکوزیا",
    "دوکسا کاتوکوپیاس", "ارمیس آرادیپو", "کارمیوتیسا",
    "اومونیا آرادیپو", "اومونیا ۲۹ می", "دیگنیس مورفو",
    "چالکانوراس", "ایراکلیس جROLAKU",
    "لیماسول", "نیکوزیا", "آرادیپو",
    # THA pool — club article candidates
    "چاینات", "باشگاه فوتبال چاینات", "کانجانابوری",
    "کاستسارت", "خون‌کان یونایتد", "خونکان یونایتد",
    "نخون پاتوم", "نونگ بوآ پیچایا", "پاتایا دلفینز",
    "سونگخلا یونایتد", "ساتون", "لویی",
    "کاسه‌سارت",
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
