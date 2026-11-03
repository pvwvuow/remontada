#!/usr/bin/env python3
# cycle-480 fresh anchor probes — the 479 rotation line declared field:
# PAR 7 ALONE at the top (the 477 tie loser finally harvesting; the fresh
# census re-read: PAR 7 with zero (W) sides, RUS/ESP/CRC 6, ENG 7 but
# (W)-skewed). No tie — the 447 tie-break is not needed for SELECTION, but
# the anchor QUALITY rules govern every render: direct identity-verified
# fa.wiki club articles (the extract must name a PARAGUAYAN club), the
# FC-rule minus the prefix, the renamed-upstream lesson (the anchor's OWN
# title wins), the 461 city-grounded toponyms, the 466 honest phonetic
# reads. A) wikidata exact fawiki sitelinks per club. B) fa.wiki exact
# title existence + the honest fa.wiki search fallback. C) identity
# verification (extracts).
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TRANCHES = {
    "PAR": ["2 de Mayo", "Cerro Porteño", "Guaraní", "Rubio Ñú",
            "Sportivo Ameliano", "Sportivo San Lorenzo",
            "Sportivo Trinidense"],
}


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


found = {}   # "CC:club" -> fa title (from wikidata sitelink)
searched = {}  # "CC:club" -> list of fa.wiki search hits (fallback)
for cc, clubs in TRANCHES.items():
    print(f"== A) wikidata fawiki sitelinks — {cc} ==")
    for n in clubs:
        q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
             + urllib.parse.quote(n) + "&language=en&type=item&limit=10&format=json")
        d = api(q)
        toks = [t.lower() for t in re.split(r"[^A-Za-z0-9À-ÿ]+", n) if len(t) > 2]
        qid = None
        for e in (d or {}).get("search", []):
            lab = (e.get("label") or "").lower()
            desc = (e.get("description") or "").lower()
            if any(t in lab for t in toks) and ("football" in desc or "soccer" in desc
                                                or "club" in desc):
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
    # fallback: direct fa.wiki search for clubs without a sitelink
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
        ex = (p.get("extract") or "")[:260].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump({"found": found, "searched": searched, "present": present},
          open("/tmp/c480-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c480-wiki.json")
for cc in TRANCHES:
    n_anchor = sum(1 for k in found if k.startswith(cc + ":"))
    n_verified = sum(1 for k in found if k.startswith(cc + ":")
                     and found[k] in present)
    print(f"ANCHOR SCORE — {cc}: {n_anchor} sitelinks, {n_verified} existing titles")
