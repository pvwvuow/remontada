#!/usr/bin/env python3
# cycle-477 fresh 447 tie-break probes — the NEW two-way tie the fresh
# census surfaced (the 476 card's GRE/BUL/DEN/ALB field DISSOLVED with the
# window move: GRE now 4, BUL 2, DEN 5 — its (W) side GONE — and the new
# top is ALB 7 = PAR 7; ENG's 7 carries FOUR (W) sides -> the 435 rule
# leaves it 2 effective, ESP 6 -> 2 effective, so no (W) tranche is in the
# race). The 447 tie-break (the 472 CZE-vs-ISR precedent): the side with
# more DIRECT identity-verified fa.wiki club-article anchors is harvested.
# A) wikidata exact fawiki sitelinks per club. B) fa.wiki exact title
# existence for the sitelinks + the honest fa.wiki search fallback. C)
# identity verification (extracts) — wrong-country pages rejected (the
# 456/460/461/462/465/466/471 lessons): ALB pages must be ALBANIAN clubs,
# PAR pages must be PARAGUAYAN clubs.
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TRANCHES = {
    "ALB": ["Elbasani", "FC Dinamo City", "KF Tirana", "Partizani",
            "Skënderbeu", "Vllaznia", "Vora"],
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
        time.sleep(0.2)
        if not qid:
            print(f"  [{cc}] {n} -> NO club entity found (will fallback-search)")
            continue
        g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                + qid + "&props=sitelinks|labels|descriptions&languages=en|fa&format=json")
        time.sleep(0.2)
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
        time.sleep(0.2)

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
          open("/tmp/c477-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c477-wiki.json")
for cc in TRANCHES:
    n_anchor = sum(1 for k in found if k.startswith(cc + ":"))
    n_verified = sum(1 for k in found if k.startswith(cc + ":")
                     and found[k] in present)
    print(f"ANCHOR SCORE — {cc}: {n_anchor} sitelinks, {n_verified} existing titles")
