#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""debug-362-rowshape.py — شکل ردیف جدول عراق + فصل تاریخی میانی"""
import json
import urllib.request
import urllib.parse

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read().decode("utf-8"))


payload = get_json("https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en")
table = payload.get("table")
print("table type:", type(table).__name__, "len:", len(table) if isinstance(table, list) else "-")
t0 = table[0] if isinstance(table, list) and table else {}
print("table[0] keys:", list(t0.keys()) if isinstance(t0, dict) else "-")
data = t0.get("data") if isinstance(t0, dict) else None
print("table[0].data keys:", list(data.keys()) if isinstance(data, dict) else "-")
if isinstance(data, dict):
    tb = data.get("table")
    print("data.table type:", type(tb).__name__, "keys:", list(tb.keys()) if isinstance(tb, dict) else "-")
    all_rows = tb.get("all") if isinstance(tb, dict) else None
    if all_rows:
        print("row0:", json.dumps(all_rows[0], ensure_ascii=False)[:400])
    else:
        # شاید جدول مستقیم لیست باشد
        print("data.table sample:", json.dumps(tb, ensure_ascii=False)[:400])

# فصل تاریخی میانی
for season in ["2019/2020", "2016/2017"]:
    try:
        h = get_json(f"https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en&season={urllib.parse.quote(season)}")
        ht = h.get("table")
        n = 0
        sel = h.get("selectedSeason")
        if isinstance(ht, list) and ht:
            d = ht[0].get("data") or {}
            tb = d.get("table") or {}
            rows = tb.get("all") or []
            n = len(rows)
            if rows:
                print(f"season {season}: rows={n} row0={json.dumps(rows[0], ensure_ascii=False)[:220]}")
            else:
                print(f"season {season}: table empty, keys={list(d.keys())[:8]}")
        else:
            print(f"season {season}: no table (payload keys={list(h.keys())[:8]})")
    except Exception as e:
        print(f"season {season}: ERR {e}")
