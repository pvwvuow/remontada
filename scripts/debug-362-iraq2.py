#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""debug-362-iraq2.py — شکل دقیق: نام ۲۰ تیم، تاریخی خام، تیم نمونه، ESPN"""
import json
import urllib.request
import urllib.parse

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read().decode("utf-8"))


def get_code(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code


p = get_json("https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en")
rows = p["table"][0]["data"]["table"]["all"]
print("TEAM NAMES (20):", [r["name"] for r in rows])
print("TEAM IDS:", [r["id"] for r in rows])
print("top:", rows[0]["name"], rows[0]["pts"], "pts |", rows[-1]["name"], rows[-1]["pts"])
print("tableFilterTypes:", p["table"][0].get("tableFilterTypes"))
print("legend:", json.dumps(p["table"][0].get("legend"), ensure_ascii=False)[:200])
print("tableHeader:", json.dumps(p["table"][0].get("tableHeader"), ensure_ascii=False)[:200])

ov = p.get("overview") or {}
print("overview keys:", list(ov.keys())[:20])
fum = ov.get("firstUnplayedMatch")
print("firstUnplayedMatch:", json.dumps(fum, ensure_ascii=False)[:250] if fum else None)
am = ov.get("allMatches")
if isinstance(am, dict):
    print("overview.allMatches keys:", list(am.keys()), "counts:",
          {k: len(v) if isinstance(v, list) else v for k, v in am.items() if not isinstance(v, dict)})

h = get_json("https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en&season=" + urllib.parse.quote("2019/2020"))
print("hist 2019/2020 table value:", json.dumps(h.get("table"), ensure_ascii=False)[:200],
      "selectedSeason:", h.get("selectedSeason"))
d20 = (h.get("table") or [])
if d20 and isinstance(d20, list):
    print("hist table[0] keys:", list(d20[0].keys()))

t = get_json(f"https://www.fotmob.com/api/data/teams?id={rows[0]['id']}")
td = t.get("details") or {}
print(f"team {rows[0]['id']} name={td.get('name', {}).get('name') if isinstance(td.get('name'), dict) else td.get('name')}")

for slug in ["iraq.1", "irq.1"]:
    print(f"ESPN {slug}:", get_code(f"https://site.api.espn.com/apis/site/v2/sports/soccer/{slug}/scoreboard"))
