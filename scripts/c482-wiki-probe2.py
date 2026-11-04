#!/usr/bin/env python3
# cycle-482 probe2 — the three RUS names the A-stage left anchorless:
# 1) Volga Ulyanovsk: the fa.wiki SEARCH hit exposed the club's OWN article
#    «باشگاه فوتبال ولگا اولیانوفسک» — probe its extract for the strict
#    identity verification (a RUSSIAN club).
# 2) Nizhny Novgorod: the club named after its city — the 461 city-grounded
#    toponym rule + the 477 Skënderbeu stadium rule (the stadium article
#    «ورزشگاه نیژنی نووگورود» grounds the spelling); also try the wikidata
#    entities (FC Pari NN / FC Nizhny Novgorod).
# 3) Leningradets: the A-stage entity was an ICE HOCKEY club (wrong sport,
#    never consulted) — try the football entity forms and the fa search.
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


print("== 1) Volga Ulyanovsk — the club's OWN article extract ==")
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts&exintro=1"
        "&explaintext=1&titles=" + urllib.parse.quote("باشگاه فوتبال ولگا اولیانوفسک")
        + "&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    print(f"  pageid={pid} missing={'missing' in p} title={p.get('title')}")
    print(f"  extract: {(p.get('extract') or '(EMPTY)')[:300]}")
time.sleep(1.8)

print("== 2) Nizhny Novgorod — the stadium article + wikidata ==")
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts&exintro=1"
        "&explaintext=1&titles=" + urllib.parse.quote("ورزشگاه نیژنی نووگورود")
        + "&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    print(f"  pageid={pid} missing={'missing' in p} title={p.get('title')}")
    print(f"  extract: {(p.get('extract') or '(EMPTY)')[:300]}")
time.sleep(1.8)
for q in ["Pari Nizhny Novgorod", "FC Nizhny Novgorod"]:
    d = api("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
            + urllib.parse.quote(q) + "&language=en&type=item&limit=6&format=json")
    for e in (d or {}).get("search", []):
        print(f"  wd[{q}] -> {e['id']} ({e.get('label')}; {e.get('description')})")
    time.sleep(1.8)

print("== 3) Leningradets — the football entity + fa search ==")
for q in ["FC Leningradets", "Leningradets Vyborg"]:
    d = api("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
            + urllib.parse.quote(q) + "&language=en&type=item&limit=6&format=json")
    for e in (d or {}).get("search", []):
        print(f"  wd[{q}] -> {e['id']} ({e.get('label')}; {e.get('description')})")
    time.sleep(1.8)
for q in ["Leningradets", "لنینگرادتس"]:
    d = api("https://fa.wikipedia.org/w/api.php?action=query&list=search&srlimit=6"
            "&srprop=snippet&format=json&srsearch=" + urllib.parse.quote(q))
    hits = [h["title"] for h in (d or {}).get("query", {}).get("search", [])]
    print(f"  fa-search[{q}] -> {hits}")
    time.sleep(1.8)
