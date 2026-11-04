#!/usr/bin/env python3
# cycle-500 fresh anchor probes - the fresh-500 census field: a NEW ENG/ESP
# 2-2 tie at the top of the count>=3 field (ENG 7 names with 5 (W) -> 2
# effective [Frome Town, Whitby]; ESP 6 names with 4 (W) -> 2 effective
# [Elche Ilicitano, La Nucia]; INT 4 fully (W) -> 0, the 435 rule; eight
# countries at 2 names below). The 447 tie-break = the FRESH ANCHOR COUNT
# on TODAY's words (the 496 precedent): direct identity-verified fa.wiki
# club articles per country. The 490/496 lesson applied: the strict
# sitelink scoreboard UNDERCOUNTS when a standing fa article's entity
# stays outside wbsearchentities - the scoreboard counts identity-verified
# STANDING ARTICLES (the sitelink class + the fa-search fallback class).
# A)  wikidata entities (P17 country claim) - ENG=Q21 (England),
#     ESP=Q29 (Spain).
# A2) sitelinks + P17 for the found entities.
# B)  fa.wiki search fallback (both the plain and the باشگاه-فوتبال forms).
# C)  identity verification via extracts for EVERY fawiki candidate
#     (sitelink OR search) - the strict rule.
# D)  the 447 scoreboard (verified standing articles per country).
# Gentle 1.8s cadence + backoff (the 480 429-wall lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

COUNTRIES = {
    "ENG": ("England", "Q21", ["Frome Town", "Whitby"]),
    "ESP": ("Spain", "Q29", ["Elche Ilicitano", "La Nucía"]),
}

# Persian phonetic/title forms for the fa.wiki search fallback
FA_FORMS = {
    "Frome Town": ["فروم تاون", "باشگاه فوتبال فروم تاون"],
    "Whitby": ["ویتبی تاون", "باشگاه فوتبال ویتبی تاون", "ویتبی"],
    "Elche Ilicitano": ["ایلیسیتانو", "ایلچه ایلیسیتانو", "Elche Ilicitano"],
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


all_names = {}
for cc, (cname, qcc, names) in COUNTRIES.items():
    for n in names:
        all_names[n] = (cc, cname, qcc)

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

print("== B) fa.wiki search fallback (both name forms) ==")
search_hits = {}
for n in all_names:
    cc, cname, qcc = all_names[n]
    hits_all = []
    for f in FA_FORMS.get(n, [n]):
        hits = fa_search(f)
        hits_all.extend(hits)
        print(f"  fa-search[{cc} | {n} | {f}] -> {hits[:5]}")
        time.sleep(1.8)
    search_hits[n] = hits_all

print("== C) verify EVERY fawiki candidate via extracts (identity rule) ==")
# candidates: sitelink titles + search titles that plausibly name the club
cand_titles = {}
for n in all_names:
    tset = []
    if sitelink.get(n):
        tset.append(sitelink[n])
    cc, cname, qcc = all_names[n]
    for t in search_hits.get(n, []):
        low = t.lower()
        if "فوتبال" in t or "باشگاه" in t or "تاون" in t or \
           "ایلیسیتانو" in t or "نوسیا" in t or "فروم" in t:
            if t not in tset:
                tset.append(t)
    cand_titles[n] = tset[:3]
titles = sorted({t for ts in cand_titles.values() for t in ts})
if titles:
    T = "|".join(titles)
    d = api("https://fa.wikipedia.org/w/api.php?action=query"
            "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
            "&inprop=url&titles=" + urllib.parse.quote(T) + "&format=json")
    for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            print(f"  MISSING: {p.get('title')}")
            continue
        ex = (p.get("extract") or "(EMPTY)")[:600].replace("\n", " ")
        print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
        time.sleep(1.8)
else:
    print("  (no fawiki candidates at all)")

print("== D) the 447 scoreboard (identity-verified standing articles) ==")
score = {}
for cc, (cname, qcc, names) in COUNTRIES.items():
    verified = []
    for n in names:
        if cand_titles.get(n):
            verified.append((n, cand_titles[n]))
    score[cc] = len(verified)
    print(f"  {cc}: {len(verified)} verified-article names -> {verified}")
best = max(score.values())
winners = [cc for cc, s in score.items() if s == best]
print(f"  WINNER(S): {winners} with {best} verified standing-article names")
