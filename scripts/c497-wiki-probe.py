#!/usr/bin/env python3
# cycle-497 fresh anchor probes — the 496 rotation line's declared field:
# the lone-leader SVN 4 (the fresh-496 anchor scoreboard: المپیا 6417931
# the only anchor — Bravo/Brinje entities P17=Q215 with zero fa sitelinks,
# Nafta no entity; the 477/482/485 lone-leader form). SVK harvested in
# batch 40, out of the raw pool. The 447 re-count runs FRESH on TODAY's
# words: direct identity-verified fa.wiki club articles for the SVN names.
# A0) FRESH extract of the ONE known anchor pageid (the 447
#     live-re-read lesson — the scoreboard runs on TODAY's words).
# A)  wikidata entities (P17 country claim for identity proof) — SVN fixed
#     to Q215 (Slovenia).
# A2) sitelinks + P17 for the found entities.
# B)  fa.wiki search fallback (zero-anchor documentation).
# C)  identity verification via extracts (the strict rule).
# D)  the 447 scoreboard.
# Gentle 1.8s cadence + backoff (the 480 429-wall lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

COUNTRIES = {
    "SVN": ("Slovenia", "Q215", ["NK Bravo", "Nafta",
                                 "Nk Brinje Grosuplje",
                                 "Olimpija Ljubljana"]),
}

# the ONE known anchor fa.wiki title (pageid from the 495 ledger)
KNOWN_ANCHORS = {
    "المپیا لیوبلیانا": 6417931,              # SVN (Olimpija)
}

# Persian phonetic forms for the fa.wiki search fallback (zero-anchor docs)
FA_FORMS = {
    "NK Bravo": ["براوو اسلوونی", "ان‌کی براوو"],
    "Nafta": ["نفتا هاجدید", "نافتا لنداوا"],
    "Nk Brinje Grosuplje": ["گروسوپلیه", "برینیه"],
    "Olimpija Ljubljana": ["المپیای لیوبلیانا", "المپیجا لیوبلیانا"],
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


all_names = {}
for cc, (cname, qcc, names) in COUNTRIES.items():
    for n in names:
        all_names[n] = (cc, cname, qcc)

print("== A0) FRESH extract of the ONE known anchor (scoreboard axis) ==")
pidmap = {str(pid): t for t, pid in KNOWN_ANCHORS.items()}
T = "|".join(pidmap.keys())
q = ("https://fa.wikipedia.org/w/api.php?action=query"
     "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
     "&inprop=url&pageids=" + T + "&format=json")
d = api(q)
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print(f"  MISSING: {p.get('title')}")
        continue
    ex = (p.get("extract") or "(EMPTY)")[:700].replace("\n", " ")
    print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
time.sleep(1.8)

print("== A) wikidata entities for ALL 4 (with the P17 country claim) ==")
qids = {}
for cc, (cname, qcc, names) in COUNTRIES.items():
    print(f"-- {cc} ({cname}) --")
    for n in names:
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
        cc, cname, qcc = all_names[n]
        mark = "OK" if P17 == qcc else ("**" if P17 else "--")
        print(f"  {n} [{qid}] fawiki={fa} P17={P17} want={qcc} {mark}")
        sitelink[n] = fa
    time.sleep(1.8)

print("== B) fa.wiki search fallback (zero-anchor documentation) ==")
for n in all_names:
    if sitelink.get(n):
        continue
    cc, cname, qcc = all_names[n]
    for f in FA_FORMS.get(n, [n]):
        hits = fa_search(f)
        print(f"  fa-search[{cc} | {n} | {f}] -> {hits[:4]}")
        time.sleep(1.8)

print("== C) verify NEW fawiki candidates via extracts (identity rule) ==")
known_titles = set(KNOWN_ANCHORS.keys())
cands = {n: fa for n, fa in sitelink.items()
         if fa and fa not in known_titles}
if cands:
    T = "|".join(sorted(set(cands.values())))
    d = api("https://fa.wikipedia.org/w/api.php?action=query"
            "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
            "&inprop=url&titles=" + urllib.parse.quote(T) + "&format=json")
    for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            print(f"  MISSING: {p.get('title')}")
            continue
        ex = (p.get("extract") or "(EMPTY)")[:700].replace("\n", " ")
        print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
        time.sleep(1.8)
else:
    print("  (no NEW fawiki candidates beyond the known anchors)")

print("== D) the 447 scoreboard ==")
score = {}
for cc, (cname, qcc, names) in COUNTRIES.items():
    direct = [n for n in names if sitelink.get(n)]
    score[cc] = len(direct)
    print(f"  {cc}: {len(direct)} direct anchors -> {direct}")
best = max(score.values())
winners = [cc for cc, s in score.items() if s == best]
print(f"  WINNER(S): {winners} with {best} direct anchors")
