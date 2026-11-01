#!/usr/bin/env python3
# cycle-340 feasibility probe — the share-card family census.
# The cycle-339 fix card recorded the remaining share-card surfaces
# (player/twitter alignment, team, match, coach, news) as future polish
# candidates. This probe fetches every candidate surface live and prints
# the og:*/twitter:* state so the gap is evidenced BEFORE the code change.
# Usage: BASE=http://localhost:3000 python3 scripts/probe-340-sharecards.py

import os
import re
import sys
import urllib.request

BASE = os.environ.get("BASE", "http://localhost:3000")
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

# surface → (path, expectation key)
SURFACES = [
    ("news", "/news"),
    ("team", "/team/8650"),
    ("match", "/match/5795501"),
    ("player", "/player/696679"),
    ("coach", "/coach/30889"),  # cycle-255 probe anchor (Xabi Alonso id-space)
    # parametrization spot-checks (different entity, same generator)
    ("team-2", "/team/9825"),
    ("topscorers-ref", "/topscorers/pl"),  # cycle-339 reference shape
]

META = re.compile(
    r'<meta[^>]+(?:property|name)="(og:title|og:description|og:url|og:image|'
    r'og:site_name|og:locale|twitter:card|twitter:title|twitter:description)"'
    r'[^>]+content="([^"]*)"'
)
TITLE = re.compile(r"<title>([^<]*)</title>")


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def census(html):
    tags = dict(META.findall(html))
    t = TITLE.search(html)
    tags["<title>"] = t.group(1) if t else ""
    return tags


KEYS = ["<title>", "og:title", "og:url", "og:image", "twitter:card", "twitter:title"]

rows = []
for label, path in SURFACES:
    try:
        tags = census(fetch(BASE + path))
        rows.append((label, path, tags))
    except Exception as e:  # noqa: BLE001 — probe must never crash the audit
        rows.append((label, path, {"ERROR": str(e)[:60]}))

w = max(len(k) for _, _, t in rows for k in t) + 2
for label, path, tags in rows:
    print(f"== {label}  {path}")
    for k in KEYS:
        v = tags.get(k, "—")
        print(f"   {k:<{w}} {v[:90]}")
    og_url = tags.get("og:url", "—")
    page_specific_twitter = tags.get("twitter:title", "") not in (
        "",
        "رمانتادا | نتایج زنده فوتبال، جدول لیگ‌ها و اخبار",
    )
    page_specific_og = tags.get("og:title", "") not in (
        "",
        "رمانتادا | نتایج زنده فوتبال، جدول لیگ‌ها و اخبار",
    )
    print(f"   => og page-specific: {page_specific_og}   twitter page-specific: {page_specific_twitter}   og:url: {og_url[:60]}")
print("probe-340 done:", len(rows), "surfaces")
sys.exit(0)
