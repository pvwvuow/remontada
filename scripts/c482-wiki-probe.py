#!/usr/bin/env python3
# cycle-482 fresh anchor probes — the NEW two-way tie: RUS 6 = CRC 6 at the
# top of the fresh 482 census (both zero (W); ESP 6 four (W) -> 2 effective,
# ENG 7 five (W) -> 2 effective — the 435 rule). The 447 tie-break rule (the
# 472 CZE-vs-ISR / 477 ALB-vs-PAR precedents): the side with MORE direct
# identity-verified fa.wiki club articles harvests, the loser waits. A)
# wikidata exact fawiki sitelinks per club. B) fa.wiki exact title existence.
# C) identity verification (the extract must name a RUSSIAN / COSTA RICAN
# club). Gentle 1.8s cadence + backoff (the 480 429-wall lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TRANCHES = {
    "RUS": ["FC Yenisey Krasnoyarsk", "Leningradets", "Nizhny Novgorod",
            "SKA-Khabarovsk", "Spartak Kostroma", "Volga Ulyanovsk"],
    "CRC": ["Club Sport Herediano", "Deportiva San Carlos", "Escorpiones",
            "Inter San Carlos", "Puntarenas FC", "Sporting FC"],
}


def api(url: str):
    for attempt in range(4):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "25", "-A", UA, url],
            capture_output=True, text=True, timeout=40,
        ).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


found = {}
searched = {}
for cc, clubs in TRANCHES.items():
    print(f"== A) wikidata fawiki sitelinks — {cc} ==")
    for n in clubs:
        q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
             + urllib.parse.quote(n) + "&language=en&type=item&limit=10&format=json")
        d = api(q)
        toks = [t.lower() for t in n.replace("-", " ").split() if len(t) > 2]
        qid = None
        for e in (d or {}).get("search", []):
            lab = (e.get("label") or "").lower()
            desc = (e.get("description") or "").lower()
            if any(t in lab for t in toks) and ("football" in desc or "soccer" in desc
                                                or "club" in desc or "fútbol" in desc):
                qid = e["id"]
                break
        time.sleep(1.8)
        if not qid:
            print(f"  [{cc}] {n} -> NO club entity found (will fallback-search)")
            continue
        g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                + qid + "&props=sitelinks|labels|descriptions&languages=en|fa&format=json")
        time.sleep(1.8)
        ent = (g or {}).get("entities", {}).get(qid, {})
        fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
        en = ent.get("labels", {}).get("en", {}).get("value")
        desc = ent.get("descriptions", {}).get("en", {}).get("value")
        print(f"  [{cc}] {n} -> {qid} ({en}; {desc}) fa={fa}")
        if fa:
            found[f"{cc}:{n}"] = fa
    print(f"== A2) fa.wiki search fallback — {cc} ==")
    for n in clubs:
        if f"{cc}:{n}" in found:
            continue
        q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
             "&srlimit=6&srprop=snippet&format=json&srsearch="
             + urllib.parse.quote(n + " فوتبال"))
        d = api(q)
        hits = []
        for h in (d or {}).get("query", {}).get("search", []):
            hits.append(h["title"])
        searched[f"{cc}:{n}"] = hits
        print(f"  [{cc}] {n} -> search hits: {hits[:4]}")
        time.sleep(1.8)

print("== B) fa.wiki exact title existence (batched) ==")
cand = sorted(set(found.values()))
TITLES = "|".join(cand)
present = {}
if TITLES:
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
           "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
    d = api(url)
    pages = (d or {}).get("query", {}).get("pages", {})
    for pid, p in pages.items():
        if pid != "-1" and "missing" not in p:
            present[p["title"]] = p.get("lastrevid")
            print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
    missing = [t["title"] for t in pages.values() if "missing" in t]
    print(f"  ({len(missing)} titles missing)")

print("== C) identity verification (extracts of the EXISTING pages) ==")
if present:
    T2 = "|".join(sorted(present))
    u2 = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
          "&exintro=1&explaintext=1&titles=" + urllib.parse.quote(T2)
          + "&format=json")
    d2 = api(u2)
    for pid, p in ((d2 or {}).get("query", {}).get("pages", {}) or {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:280].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump({"found": found, "searched": searched, "present": present},
          open("/tmp/c482-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c482-wiki.json")
for cc in TRANCHES:
    n_anchor = sum(1 for k in found if k.startswith(cc + ":"))
    n_verified = sum(1 for k in found if k.startswith(cc + ":")
                     and found[k] in present)
    print(f"ANCHOR SCORE — {cc}: {n_anchor} sitelinks, {n_verified} existing titles")
