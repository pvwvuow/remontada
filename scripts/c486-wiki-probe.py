#!/usr/bin/env python3
# cycle-486 fresh anchor probes — the 485 rotation line's declared field:
# the FRESH 486 census re-read: distinct=1647/raw_rows=2880 == the B4 anchor
# EXACTLY, zero drift; DEN gone after the 485 harvest; ENG 7 five (W) -> 2
# effective, ESP 6 four (W) -> 2 effective — the 435 rule; and the top is
# RSA 5 — the DEN/RSA tie LOSER finally harvesting alone (the CRC 482→483 /
# PAR 477→479 precedents). AmaZulu's direct anchor آمازولو 6853449 was
# probed live at 485 (the Durban South-African identity, NOT the Zimbabwean
# Q2840775 namesake) — re-verified fresh here; the other FOUR names need
# probes: Durban City / Lamontville Golden Arrows / Sekhukhune United /
# Siwelele.
# A) wikidata entities (with the P17 country claim for identity proof:
#    South Africa Q258). B) fa.wiki search fallback. C) identity
#    verification (extracts — the strict rule: the extract must name a
#    SOUTH AFRICAN club).
# Gentle 1.8s cadence + backoff (the 480 429-wall lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

RSA = ["AmaZulu FC", "Durban City", "Lamontville Golden Arrows",
       "Sekhukhune United", "Siwelele"]


def api(url):
    for attempt in range(4):
        out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


print("== A) wikidata entities for ALL FIVE (with the P17 country claim) ==")
qids = {}
for n in RSA:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(n) + "&language=en&type=item&limit=10&format=json")
    d = api(q)
    toks = [t.lower() for t in n.replace("-", " ").split() if len(t) > 2]
    for e in (d or {}).get("search", []):
        lab = (e.get("label") or "").lower()
        desc = (e.get("description") or "").lower()
        if any(t in lab for t in toks) and ("football" in desc or "soccer" in desc
                                            or "club" in desc):
            qids[n] = e["id"]
            print(f"  {n} -> {e['id']} ({e.get('label')}; {e.get('description')})")
            break
    if n not in qids:
        print(f"  {n} -> NO club entity found")
    time.sleep(1.8)

if qids:
    time.sleep(1.8)
    ids = "|".join(qids.values())
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=" + ids
            + "&props=sitelinks|labels|descriptions|claims&languages=en|fa"
              "&format=json")
    for n, qid in qids.items():
        ent = (g or {}).get("entities", {}).get(qid, {})
        fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
        P17 = ""
        for c in (ent.get("claims", {}).get("P17") or []):
            P17 = c.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id", "")
            break
        print(f"  {n} [{qid}] fawiki={fa} P17(country)={P17}")
    time.sleep(1.8)

print("== B) fa.wiki search fallback for ALL FIVE ==")
QUERIES = {
    "AmaZulu FC": ["AmaZulu", "آمازولو"],
    "Durban City": ["Durban City", "Maritzburg United", "دوربان سیتی"],
    "Lamontville Golden Arrows": ["Golden Arrows", "Lamontville Golden Arrows",
                                  "پیکان طلایی"],
    "Sekhukhune United": ["Sekhukhune United", "سخوخونه یونایتد",
                          "سکوکونی یونایتد"],
    "Siwelele": ["Siwelele FC", "Siwelele", "سیوله‌له"],
}
for n, forms in QUERIES.items():
    for f in forms:
        q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
             "&srlimit=6&srprop=snippet&format=json&srsearch="
             + urllib.parse.quote(f))
        d = api(q)
        hits = [h["title"] for h in (d or {}).get("query", {}).get("search", [])]
        print(f"  fa-search[{n} | {f}] -> {hits[:5]}")
        time.sleep(1.8)

print("== C) verify any fawiki candidates via extracts (identity rule) ==")
cands = []
for n, qid in qids.items():
    ent = (g or {}).get("entities", {}).get(qid, {})
    fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
    if fa:
        cands.append((n, fa))
if cands:
    T = "|".join(sorted({fa for _, fa in cands}))
    d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
            "&exintro=1&explaintext=1&redirects=1&inprop=url&titles="
            + urllib.parse.quote(T) + "&format=json")
    for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            print(f"  MISSING: {p.get('title')}")
            continue
        ex = (p.get("extract") or "(EMPTY)")[:260].replace("\n", " ")
        print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
        time.sleep(1.8)
else:
    print("  (no fawiki candidates from the entity stage)")
