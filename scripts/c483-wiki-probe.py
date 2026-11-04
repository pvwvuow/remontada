#!/usr/bin/env python3
# cycle-483 fresh anchor probes — the 482 rotation line's declared field:
# CRC 6 ALONE at the top (the fresh 483 census re-read: distinct=1658/
# raw_rows=2913 == the B4 anchor EXACTLY, zero drift; RUS gone after the
# 482 harvest; ESP 6 four (W) -> 2 effective, ENG 7 five (W) -> 2 effective
# — the 435 rule; DEN 5 / RSA 5 behind). No tie — the 447 tie-break is not
# needed for SELECTION. TWO direct anchors already verified in the 482
# probe (re-verified fresh here + the renders byte-derived from the
# anchors' OWN titles): Club Sport Herediano (باشگاه ورزشی هردیانو — the
# intro itself says «معمولاً با نام هردیانو») / Puntarenas FC (باشگاه
# فوتبال پونتاریناس). The FOUR anchorless names probed now: Deportiva San
# Carlos / Escorpiones (Q108179092, no sitelink in the 482 read) / Inter
# San Carlos / Sporting FC. A) wikidata entities (with the P17 country
# claim for identity proof). B) fa.wiki search fallback. C) identity
# verification (extracts — the strict rule: the extract must name a COSTA
# RICAN club). Gentle 1.8s cadence + backoff (the 480 429-wall lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

KNOWN = {
    "Club Sport Herediano": "باشگاه ورزشی هردیانو",
    "Puntarenas FC": "باشگاه فوتبال پونتاریناس",
}
FOUR = ["Deportiva San Carlos", "Escorpiones", "Inter San Carlos",
        "Sporting FC"]


def api(url):
    for attempt in range(4):
        out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


print("== A0) the TWO known anchors re-verified (info + extract) ==")
T = "|".join(KNOWN.values())
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url&titles="
        + urllib.parse.quote(T) + "&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print(f"  MISSING: {p.get('title')}")
        continue
    ex = (p.get("extract") or "(EMPTY)")[:220].replace("\n", " ")
    print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
    time.sleep(1.8)

print("== A) wikidata entities for the FOUR (with the P17 country claim) ==")
qids = {}
for n in FOUR:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(n) + "&language=en&type=item&limit=10&format=json")
    d = api(q)
    toks = [t.lower() for t in n.replace("-", " ").split() if len(t) > 2]
    for e in (d or {}).get("search", []):
        lab = (e.get("label") or "").lower()
        desc = (e.get("description") or "").lower()
        if any(t in lab for t in toks) and ("football" in desc or "soccer" in desc
                                            or "club" in desc or "fútbol" in desc):
            qids[n] = e["id"]
            print(f"  {n} -> {e['id']} ({e.get('label')}; {e.get('description')})")
            break
    if n not in qids:
        print(f"  {n} -> NO club entity found")
    time.sleep(1.8)

if qids:
    ids = "|".join(qids.values())
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=" + ids
            + "&props=sitelinks|labels|descriptions|claims&languages=en|fa"
              "&format=json")
    time.sleep(1.8)
    for n, qid in qids.items():
        ent = (g or {}).get("entities", {}).get(qid, {})
        fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
        P17 = ""
        for c in (ent.get("claims", {}).get("P17") or []):
            P17 = c.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id", "")
            break
        print(f"  {n} [{qid}] fawiki={fa} P17(country)={P17}")

print("== B) fa.wiki search fallback for ALL FOUR (incl. entity-less forms) ==")
QUERIES = {
    "Deportiva San Carlos": ["Deportiva San Carlos", "San Carlos Costa Rica fútbol",
                             "A.D. San Carlos"],
    "Escorpiones": ["Escorpiones Costa Rica", "Escorpiones Belén", "اسکورپیونس"],
    "Inter San Carlos": ["Inter San Carlos", "اینتر سن کارلوس"],
    "Sporting FC": ["Sporting FC Costa Rica", "Sporting San José", "اسپورتینگ سن خوزه"],
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
