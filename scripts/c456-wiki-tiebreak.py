#!/usr/bin/env python3
# cycle-456 tie-break probe (re-read for the three-way tie) (the 447 CYP/THA precedent): the four-way tie
# AUT/POL/UKR/MNE (each 10 count-3 names / 30 rows in the 456 census,
# distinct=1830 exact) breaks on fa.wiki DIRECT CLUB-ARTICLE anchor quality.
# Route: Wikidata wbsearchentities (en) -> wbgetentities sitelinks -> the
# fawiki title of the club entity. A pool "direct article" = the entity's
# fawiki sitelink title starts with «باشگاه» (the encyclopedia's own club
# article, not a city toponym / player page). Documented as read; the
# winning tranche then gets the detailed per-name title+pageid probe.
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

POOL = json.load(open("/tmp/c451-pool.json"))["seen"]
TIES = ("POL", "UKR", "MNE")


def api(url: str):
    for attempt in range(3):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "25", "-A", UA, url],
            capture_output=True, text=True, timeout=40,
        ).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(2 + attempt * 2)
    return None


def club_fawiki(name: str):
    """Return (qid, fawiki_title) for the top football-club entity of name."""
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(name) + "&language=en&type=item&limit=5&format=json")
    d = api(q)
    if not d:
        return None
    toks = [t.lower() for t in re.split(r"[^A-Za-z]+", name) if len(t) > 2]
    for e in d.get("search", []):
        qid = e.get("id")
        lab = (e.get("label") or "").lower()
        desc = (e.get("description") or "").lower()
        if not any(t in lab for t in toks):
            continue
        if "football" not in desc and "club" not in desc:
            continue
        g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                + qid + "&props=sitelinks&format=json")
        time.sleep(0.25)
        sl = (g or {}).get("entities", {}).get(qid, {}).get("sitelinks", {})
        fa = (sl.get("fawiki") or {}).get("title")
        if fa and fa.startswith("باشگاه"):
            return (qid, fa)
    return None


summary = {}
for cc in TIES:
    names = sorted(k for k, v in POOL.items() if v["cc"] == [cc] and v["rows"] >= 3)
    hits = {}
    for n in names:
        r = club_fawiki(n)
        if r:
            hits[n] = r
        time.sleep(0.3)
    summary[cc] = hits
    print(f"== {cc}: {len(hits)}/{len(names)} direct fa.wiki club articles")
    for n, (qid, fa) in hits.items():
        print(f"   {n} -> {qid} {fa}")

json.dump(summary, open("/tmp/c456-tiebreak.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c456-tiebreak.json")
