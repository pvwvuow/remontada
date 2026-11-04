#!/usr/bin/env python3
# cycle-487 probe2 — resolves the 447 scoreboard to a SINGLE winner:
# 1) Q792 label (El Salvador identity for the SLV P17s),
# 2) Colo Colo MEN's fa article باشگاه فوتبال کولو-کولو (the entity stage had
#    surfaced the WOMEN's namesake Q2979975 — the AmaZulu-trap class),
# 3) HJK FOOTBALL entity (the entity stage hit the ICE-HOCKEY club Q5477766 —
#    the 482 trap class; the football form is Helsingin Jalkapalloklubi),
# 4) باشگاه فوتبال مارکو (the GS Marko fa-search hit — which club is it?),
# 5) fa-search coverage for the six zero-entity names my stage-B missed,
# 6) extracts for every new candidate.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


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


def extract(titles=None, pageids=None):
    if titles:
        u = ("https://fa.wikipedia.org/w/api.php?action=query"
             "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
             "&inprop=url&titles=" + urllib.parse.quote(titles))
    else:
        u = ("https://fa.wikipedia.org/w/api.php?action=query"
             "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
             "&inprop=url&pageids=" + pageids)
    d = api(u + "&format=json")
    for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            print(f"  MISSING: {p.get('title')}")
            continue
        ex = (p.get("extract") or "(EMPTY)")[:300].replace("\n", " ")
        print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")


print("== 1) Q792 label ==")
d = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=Q792"
        "&props=labels&languages=en|fa&format=json")
ent = (d or {}).get("entities", {}).get("Q792", {})
print(f"  Q792 = {ent.get('labels', {}).get('en', {}).get('value')} / "
      f"{ent.get('labels', {}).get('fa', {}).get('value')}")
time.sleep(1.8)

print("== 2) Colo Colo MEN's fa article ==")
extract(titles="باشگاه فوتبال کولو-کولو")
time.sleep(1.8)

print("== 3) HJK football entity (sitelink?) ==")
for term in ["Helsingin Jalkapalloklubi", "HJK Helsinki football"]:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(term)
         + "&language=en&type=item&limit=6&format=json")
    d = api(q)
    for e in (d or {}).get("search", []):
        desc = (e.get("description") or "").lower()
        if "football" in desc or "soccer" in desc:
            print(f"  {term} -> {e['id']} ({e.get('label')}; "
                  f"{e.get('description')})")
    time.sleep(1.8)
d = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=Q190435"
        "&props=sitelinks|labels|claims&languages=en|fa&format=json")
ent = (d or {}).get("entities", {}).get("Q190435", {})
fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
P17 = ""
for c in (ent.get("claims", {}).get("P17") or []):
    P17 = c.get("mainsnak", {}).get("datavalue", {}).get("value", {}) \
        .get("id", "")
    break
lab = (ent.get("labels", {}).get("en", {}) or {}).get("value", "")
print(f"  Q190435 (HJK football) label={lab} fawiki={fa} P17={P17}")
time.sleep(1.8)

print("== 4) باشگاه فوتبال مارکو — which club? ==")
extract(titles="باشگاه فوتبال مارکو")
time.sleep(1.8)

print("== 5) fa-search for the six zero-entity names ==")
MISSED = {
    "Nestos Chrisoupolis (GRE)": ["نیستوس خریسوپولی", "نستوس کاوالا",
                                  "Chrisoupolis"],
    "Dukla Banská Bystrica (SVK)": ["دوکلا بانسکا بیستریتسا", "Dukla Banská"],
    "Skalica (SVK)": ["اسکالیسا فوتبال", "FC Skalica"],
    "ML Vitebsk (BLR)": ["ویتبسک فوتبال", "FC Vitebsk"],
    "Nafta (SVN)": ["نفتا لنداوا فوتبال", "Nafta Lendava"],
    "VPS (FIN)": ["وآ‌اس وایکاوس", "VPS Vaasa"],
}
for n, forms in MISSED.items():
    for f in forms:
        hits = fa_search(f)
        print(f"  fa-search[{n} | {f}] -> {hits[:4]}")
        time.sleep(1.8)

print("== 6) Unión La Calera extra forms (the honest read needs depth) ==")
for f in ["لا کالرا فوتبال", "Unión La Calera club", "کالرا شیلی"]:
    hits = fa_search(f)
    print(f"  fa-search[Unión La Calera | {f}] -> {hits[:4]}")
    time.sleep(1.8)
