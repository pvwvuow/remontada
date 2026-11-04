#!/usr/bin/env python3
# cycle-501 fresh anchor probe - the FRESH 501 census field: ESP 6 names
# four (W) -> 2 effective [Elche Ilicitano, La Nucia] ALONE at the top
# (the 500 rotation line's declared batch 43), the MLS playoff wave STILL
# below the threshold (no USA name in the count>=3 field). The 500 probe
# scored ESP 0 club anchors (Elche Ilicitano no entity, La Nucia entity
# P17=Q29 without the sitelink, fa search hitting only the TOWN) - the 496
# lesson: the fresh re-read on TODAY's words, then the 466-rule HONEST
# SPELLING WITNESS hunt (the آرهوس-فرماد 485 precedent: the render must be
# byte-derived from a witness, never hand-typed):
#  A) wikidata entities (P17=Q29 Spain) - fresh.
#  A2) sitelinks + P17 for the found entities - fresh.
#  B) fa.wiki search fallback (the plain/باشگاه-فوتبال/phonetic forms).
#  C) identity verification via extracts for every fawiki candidate.
#  D) the SPELLING WITNESS hunt: the Elche CF article + player articles for
#     «الچه/ایلچه ایلیسیتانو», the La Nucia TOWN article for the toponym
#     (the شهر-لنگر اسبیرگ 483 / آرهوس 485 / دوربان 486 class).
# Gentle 1.8s cadence + backoff (the 480 429-wall lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

NAMES = ["Elche Ilicitano", "La Nucía"]

FA_FORMS = {
    "Elche Ilicitano": ["الچه ایلیسیتانو", "ایلچه ایلیسیتانو", "ایلیسیتانو",
                        "Elche Ilicitano"],
    "La Nucía": ["لا نوسیا", "باشگاه فوتبال لا نوسیا", "La Nucia"],
}


def api(url):
    for attempt in range(4):
        out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


def fa_search(term):
    q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
         "&srlimit=6&srprop=snippet&format=json&srsearch="
         + urllib.parse.quote(term))
    d = api(q)
    return [h["title"] for h in (d or {}).get("query", {}).get("search", [])]


print("== A) wikidata entities (fresh, P17=Q29 wanted) ==")
qids = {}
for n in NAMES:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities"
         "&search=" + urllib.parse.quote(n)
         + "&language=en&type=item&limit=10&format=json")
    d = api(q)
    toks = [t.lower() for t in n.replace("-", " ").split() if len(t) > 2]
    found = None
    for e in (d or {}).get("search", []):
        lab = (e.get("label") or "").lower()
        desc = (e.get("description") or "").lower()
        if any(t in lab for t in toks) and (
                "football" in desc or "soccer" in desc
                or "club" in desc or "futbol" in desc):
            found = e
            break
    if found:
        qids[n] = found["id"]
        print(f"  {n} -> {found['id']} ({found.get('label')}; "
              f"{found.get('description')})")
    else:
        print(f"  {n} -> NO club entity found")
    time.sleep(1.8)

print("== A2) sitelinks + P17 for the found entities ==")
sitelink = {}
if qids:
    ids = "|".join(qids.values())
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
            + ids + "&props=sitelinks|labels|descriptions|claims"
                    "&languages=en|fa&format=json")
    for n, qid in qids.items():
        ent = (g or {}).get("entities", {}).get(qid, {})
        fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
        P17 = ""
        for c in (ent.get("claims", {}).get("P17") or []):
            P17 = c.get("mainsnak", {}).get("datavalue", {}) \
                .get("value", {}).get("id", "")
            break
        mark = "OK" if P17 == "Q29" else ("**" if P17 else "--")
        print(f"  {n} [{qid}] fawiki={fa} P17={P17} want=Q29 {mark}")
        sitelink[n] = fa
    time.sleep(1.8)

print("== B) fa.wiki search fallback (all forms) ==")
search_hits = {}
for n in NAMES:
    hits_all = []
    for f in FA_FORMS.get(n, [n]):
        hits = fa_search(f)
        hits_all.extend(hits)
        print(f"  fa-search[{n} | {f}] -> {hits[:6]}")
        time.sleep(1.8)
    search_hits[n] = hits_all

print("== C) verify every fawiki candidate via extracts (identity rule) ==")
cand_titles = {}
for n in NAMES:
    tset = []
    if sitelink.get(n):
        tset.append(sitelink[n])
    for t in search_hits.get(n, []):
        low = t.lower()
        if ("فوتبال" in t or "باشگاه" in t or "نوسیا" in t
                or "ایلیسیتانو" in t or "الچه" in t or "ایلچه" in t):
            if t not in tset:
                tset.append(t)
    cand_titles[n] = tset[:4]
titles = sorted({t for ts in cand_titles.values() for t in ts})
pages = {}
if titles:
    T = "|".join(titles)
    d = api("https://fa.wikipedia.org/w/api.php?action=query"
            "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
            "&inprop=url&titles=" + urllib.parse.quote(T) + "&format=json")
    for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            print(f"  MISSING: {p.get('title')}")
            continue
        ex = (p.get("extract") or "(EMPTY)")[:700].replace("\n", " ")
        pages[p.get("title")] = (pid, ex)
        print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
        time.sleep(1.8)
else:
    print("  (no fawiki candidates at all)")

print("== D) the SPELLING WITNESS hunt (the 466 rule, byte-derived) ==")
# D1: the Elche CF club article + the city article — how does fa.wiki write
# «Elche» and does any article text mention the reserve side Ilicitano?
for term in ["باشگاه فوتبال الچه", "الچه", "ایلیسیتانو"]:
    hits = fa_search(term)
    print(f"  D1 fa-search[{term}] -> {hits[:6]}")
    time.sleep(1.8)
# D2: the full-text search INSIDE fa.wiki for «ایلیسیتانو» (any article
# whose SNIPPET carries the spelling — the player-article witness class)
q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
     "&srlimit=8&srprop=snippet&format=json&srsearch="
     + urllib.parse.quote("ایلیسیتانو"))
d = api(q)
for h in (d or {}).get("query", {}).get("search", []):
    sn = (h.get("snippet") or "").replace('<span class="searchmatch">', "«") \
        .replace("</span>", "»")
    print(f"  D2 hit {h['title']!r} :: {sn[:220]}")
    time.sleep(1.8)
# D3: the La Nucia TOWN article extract (the toponym witness)
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url&titles="
        + urllib.parse.quote("لا نوسیا") + "&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print("  D3 MISSING: لا نوسیا")
        continue
    ex = (p.get("extract") or "(EMPTY)")[:500].replace("\n", " ")
    print(f"  D3 pageid={pid} :: {p.get('title')!r} :: {ex}")

print("== E) the verdict ==")
for n in NAMES:
    print(f"  {n}: direct-anchor candidates = {cand_titles.get(n)}")
