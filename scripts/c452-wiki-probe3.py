#!/usr/bin/env python3
# cycle-452: the batched extract endpoint is flaky — fall back to the REST
# summary endpoint per page (description field carries the type: شهر/استان/...)
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

PAGES = ["ناخون پاتوم", "ناکون پاتوم", "خون کائن", "ساتون", "سونگخلا",
         "شهرستان لویی", "پاتایا", "چاینات", "کانتچانابوری"]

for t in PAGES:
    url = ("https://fa.wikipedia.org/api/rest_v1/page/summary/"
           + urllib.parse.quote(t))
    for a in range(3):
        out = subprocess.run(["curl", "-sL", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            d = json.loads(out)
            desc = d.get("description", "")
            ext = (d.get("extract") or "")[:90].replace("\n", " ")
            print(f"[{t}] desc={desc!r} | {ext}")
            break
        except Exception:
            time.sleep(2 + a * 2)
    else:
        print(f"[{t}] FAILED")
    time.sleep(1.2)
