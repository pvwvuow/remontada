#!/usr/bin/env python3
# cycle-457 deep tie-break probe (the 447 rule extended): the two-way tie
# POL/UKR (each 10 count-3 names / 30 rows in the 457 census, distinct=1809
# exact) is dead-even on DIRECT club articles (POL 1 زنیچ پروشکوف vs UKR 1
# دینامو کی‌یف — both re-read this cycle). The read extends one documented
# level deeper: per-pool CITY-TOPONYM anchor quality (the 452 city-title
# rule — the encyclopedia's own town articles are the same anchor class the
# 451/452/455/456 batches rode). Route per name: Wikidata club entity →
# fawiki sitelink (direct); if none, the city token → city entity →
# fawiki sitelink (city). A pool's score = direct + city hits, each
# pageid-verified by the batched fa.wiki existence read. Documented as
# read; the winning tranche then gets the detailed per-name probe.
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

POOL = json.load(open("/tmp/c451-pool.json"))["seen"]
TIES = ("POL", "UKR")


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


def entity_fawiki(name: str, want_club: bool):
    """Return (qid, fawiki_title) for the top matching entity of name."""
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(name) + "&language=en&type=item&limit=6&format=json")
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
        if want_club and ("football" not in desc and "club" not in desc
                          and "sports" not in desc):
            continue
        if not want_club and not any(
                k in desc for k in ("city", "town", "village", "commune",
                                    "gmina", "urban", "rural", "municipality",
                                    "settlement", "locality")):
            continue
        g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                + qid + "&props=sitelinks&format=json")
        time.sleep(0.25)
        sl = (g or {}).get("entities", {}).get(qid, {}).get("sitelinks", {})
        fa = (sl.get("fawiki") or {}).get("title")
        if fa:
            return (qid, fa)
    return None


summary = {}
for cc in TIES:
    names = sorted(k for k, v in POOL.items() if v["cc"] == [cc] and v["rows"] >= 3)
    rows = []
    direct = city = 0
    for n in names:
        r = entity_fawiki(n, want_club=True)
        kind, qid, fa = "none", None, None
        if r and r[1].startswith("باشگاه"):
            kind, qid, fa = "direct", r[0], r[1]
            direct += 1
        if not r:
            # city token: last Latin token of the name (Świdnik, Opole, ...)
            ctok = re.split(r"\s+", n)[-1]
            r2 = entity_fawiki(ctok, want_club=False)
            if r2:
                kind, qid, fa = "city", r2[0], r2[1]
                city += 1
        rows.append((n, kind, qid, fa))
        time.sleep(0.3)
    summary[cc] = {"direct": direct, "city": city,
                   "score": direct + city, "rows": rows}
    print(f"== {cc}: direct={direct} city={city} score={direct+city}/10")
    for n, kind, qid, fa in rows:
        print(f"   [{kind}] {n} -> {qid or '-'} {fa or '-'}")

json.dump(summary, open("/tmp/c457-tiebreak.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c457-tiebreak.json")
