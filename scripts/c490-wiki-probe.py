#!/usr/bin/env python3
# cycle-490 fresh anchor probes — the 489 rotation line's declared field:
# the SIX-WAY 4-tie GRE 4 / SVK 4 / BLR 4 / SVN 4 / FIN 4 / SLV 4 (all zero
# (W); ENG 7 five (W) -> 2 effective, ESP 6 four (W) -> 2 effective, INT 4
# fully (W) -> 0 effective — the 435 rule; CHI harvested at 487). The 447
# tie-break re-counted FRESH per country: direct identity-verified fa.wiki
# club articles — the country with the MOST direct anchors harvests, the
# rest wait (the 472 CZE-vs-ISR / 477 ALB-vs-PAR / 482 RUS-vs-CRC / 485
# DEN-vs-RSA / 487 CHI-vs-BLR precedents — the 487 card's own BLR 3 anchors
# re-probed fresh per the live-re-read lesson).
# A) wikidata entities (P17 country claim for identity proof).
# B) fa.wiki search fallback (zero-anchor documentation).
# C) identity verification via extracts (the strict rule: the extract must
#    name a club of THAT country).
# Gentle 1.8s cadence + backoff (the 480 429-wall lesson).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

COUNTRIES = {
    "GRE": ("Greece", "Q41", ["AE Larissa", "Atromitos", "GS Marko",
                              "Nestos Chrisoupolis"]),
    "SVK": ("Slovakia", "Q214", ["Dukla Banská Bystrica", "FC Košice",
                                 "Skalica", "Zemplín Michalovce"]),
    "BLR": ("Belarus", "Q184", ["Belshina Bobruisk", "Dinamo Minsk",
                                "Isloch", "ML Vitebsk"]),
    "SVN": ("Slovenia", "Q215", ["NK Bravo", "Nafta",
                                 "Nk Brinje Grosuplje",
                                 "Olimpija Ljubljana"]),
    "FIN": ("Finland", "Q33", ["FC Inter Turku", "HJK", "IF Gnistan",
                               "VPS"]),
    "SLV": ("El Salvador", "Q2222", ["CD Cacahuatique",
                                     "CD Platense Municipal",
                                     "Fuerte San Francisco",
                                     "Isidro Metapan"]),
}

# Persian phonetic forms for the fa.wiki search fallback (zero-anchor docs)
FA_FORMS = {
    "AE Larissa": ["لاریسا", "ای‌ای لاریسا"],
    "Atromitos": ["آترومیتوس"],
    "GS Marko": ["مارکو فوتبال"],
    "Nestos Chrisoupolis": ["نستوس"],
    "Dukla Banská Bystrica": ["دوکلا بانسکا بیستریتسا"],
    "FC Košice": ["کوشیتسه فوتبال", "اف‌سی کوشیتسه"],
    "Skalica": ["اسکالیسا"],
    "Zemplín Michalovce": ["میخالوفتسه"],
    "Belshina Bobruisk": ["بلشینا بابروسک"],
    "Dinamo Minsk": ["دینامو مینسک"],
    "Isloch": ["ایسلوچ"],
    "ML Vitebsk": ["ویتبسک"],
    "NK Bravo": ["براوو اسلوونی", "ان‌کی براوو"],
    "Nafta": ["نفتا هاجدید", "نافتا لنداوا"],
    "Nk Brinje Grosuplje": ["گروسوپلیه"],
    "Olimpija Ljubljana": ["المپیای لیوبلیانا", "المپیجا لیوبلیانا"],
    "FC Inter Turku": ["اینتر تورکو"],
    "HJK": ["اچ‌جی‌کی", "اچ‌جی‌کی هلسینکی"],
    "IF Gnistan": ["گنیستان"],
    "VPS": ["وااس وایکاوس", "وی‌پی‌اس"],
    "Audax Italiano": ["اوداکس ایتالیانو"],
    "Colo Colo": ["کولو کولو", "کولو-کولو"],
    "Coquimbo Unido": ["کوکیمبو یونیدو"],
    "Unión La Calera": ["یونین لا کالرا"],
    "CD Cacahuatique": ["کاکاهواتیکه"],
    "CD Platense Municipal": ["پلاتنسه"],
    "Fuerte San Francisco": ["فوئرته سان فرانسیسکو"],
    "Isidro Metapan": ["ایسیدرو متاپان", "ایسیدرو متاپان"],
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

print("== A) wikidata entities for ALL 28 (with the P17 country claim) ==")
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
            P17 = c.get("mainsnak", {}).get("datavalue", {}).value_id \
                if False else c.get("mainsnak", {}).get("datavalue", {}) \
                .get("value", {}).get("id", "")
            break
        cc, cname, qcc = all_names[n]
        mark = "OK" if P17 == qcc else ("**" if P17 else "--")
        print(f"  {n} [{qid}] fawiki={fa} P17={P17} want={qcc} {mark}")
        sitelink[n] = fa
    time.sleep(1.8)

print("== B) fa.wiki search fallback (zero-anchor documentation) ==")
for n, fa in sitelink.items():
    if fa:
        continue
    cc, cname, qcc = all_names[n]
    for f in FA_FORMS.get(n, [n]):
        hits = fa_search(f)
        print(f"  fa-search[{cc} | {n} | {f}] -> {hits[:4]}")
        time.sleep(1.8)

print("== C) verify fawiki candidates via extracts (identity rule) ==")
cands = {n: fa for n, fa in sitelink.items() if fa}
if cands:
    T = "|".join(sorted(set(cands.values())))
    d = api("https://fa.wikipedia.org/w/api.php?action=query"
            "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
            "&inprop=url&titles=" + urllib.parse.quote(T) + "&format=json")
    for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            print(f"  MISSING: {p.get('title')}")
            continue
        ex = (p.get("extract") or "(EMPTY)")[:280].replace("\n", " ")
        print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
        time.sleep(1.8)
else:
    print("  (no fawiki candidates from the entity stage)")

print("== D) the 447 scoreboard ==")
score = defaultdict_int = {}
for cc, (cname, qcc, names) in COUNTRIES.items():
    direct = [n for n in names if sitelink.get(n)]
    score[cc] = len(direct)
    print(f"  {cc}: {len(direct)} direct anchors -> {direct}")
best = max(score.values())
winners = [cc for cc, s in score.items() if s == best]
print(f"  WINNER(S): {winners} with {best} direct anchors")
