#!/usr/bin/env python3
# cycle-487 probe3 — the FINAL 447 scoreboard (three open questions):
# a) HJK football Q208584 fawiki sitelink (the ice-hockey trap is eaten —
#    the men's football entity found by probe2),
# b) باشگاه فوتبال دوکلا بانسکا بیستریتسا — extract identity (Slovakia /
#    Banská Bystrica; which Dukla — the feed's current club?),
# c) باشگاه فوتبال ویتبسک + باشگاه فوتبال مکسلاین ویتبسک — is either THE
#    feed's 'ML Vitebsk' (the rename documented in the extract)?
# d) 'نستوس' — noise documentation (river vs club).
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
        ex = (p.get("extract") or "(EMPTY)")[:340].replace("\n", " ")
        print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")


print("== a) HJK football Q208584 sitelink + P17 ==")
d = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=Q208584"
        "&props=sitelinks|labels|claims&languages=en|fa&format=json")
ent = (d or {}).get("entities", {}).get("Q208584", {})
fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
P17 = ""
for c in (ent.get("claims", {}).get("P17") or []):
    P17 = c.get("mainsnak", {}).get("datavalue", {}).get("value", {}) \
        .get("id", "")
    break
lab = (ent.get("labels", {}).get("en", {}) or {}).get("value", "")
print(f"  Q208584 label={lab} fawiki={fa} P17={P17} (want Q33 Finland)")
time.sleep(1.8)

print("== b) Dukla Banská Bystrica fa article ==")
extract(titles="باشگاه فوتبال دوکلا بانسکا بیستریتسا")
time.sleep(1.8)

print("== c) Vitebsk fa articles ==")
extract(titles="باشگاه فوتبال ویتبسک|باشگاه فوتبال مکسلاین ویتبسک")
time.sleep(1.8)

print("== d) 'نستوس' — the hit identity ==")
extract(titles="نستوس")
time.sleep(1.8)

print("== e) the feed club ids cross-check: ML Vitebsk is the ±7 club ==")
print("  (the census recorded ML Vitebsk ids 5215481/5215565/5215571, cc=BLR)")
