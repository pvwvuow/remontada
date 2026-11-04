#!/usr/bin/env python3
# cycle-487 probe4 — the ML Vitebsk identity question (BLR's would-be 3rd
# anchor): does a wikidata entity for the Vitebsk club carry the 'ML' name?
# If a Qid documents 'ML Vitebsk' / 'МЛ Витебск' as an alias/label AND its
# fawiki sitelink is باشگاه فوتبال ویتبسک or مکسلاین ویتبسک -> direct anchor
# -> BLR=3. If the 'ML' name is nowhere documented -> identity unproven ->
# the two Vitebsk fa articles are honest same-city candidates REJECTED (the
# AmaZulu-trap class: identity to the FEED's club not extract-proven).
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


qids = {}
for term in ["ML Vitebsk", "Maxline Vitebsk", "FC Vitebsk", "МЛ Витебск"]:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(term)
         + "&language=en&type=item&limit=8&format=json")
    d = api(q)
    for e in (d or {}).get("search", []):
        desc = (e.get("description") or "").lower()
        if "football" in desc or "soccer" in desc or "club" in desc:
            print(f"  search[{term}] -> {e['id']} ({e.get('label')}; "
                  f"{e.get('description')})")
            qids[e["id"]] = e.get("label")
    time.sleep(1.8)

if qids:
    ids = "|".join(sorted(qids))
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
            + ids + "&props=sitelinks|labels|aliases|claims"
                    "&languages=en|fa|ru|be&format=json")
    for qid in sorted(qids):
        ent = (g or {}).get("entities", {}).get(qid, {})
        fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
        P17 = ""
        for c in (ent.get("claims", {}).get("P17") or []):
            P17 = c.get("mainsnak", {}).get("datavalue", {}).get("value", {})\
                .get("id", "")
            break
        aliases = set()
        for lang, lst in (ent.get("aliases", {}) or {}).items():
            for a in lst:
                aliases.add(a.get("value", ""))
        ml = [a for a in aliases if "ML" in a.upper() or "МЛ" in a]
        labels = {k: v.get("value") for k, v in
                  (ent.get("labels", {}) or {}).items()}
        print(f"  {qid} labels={labels}")
        print(f"      fawiki={fa} P17={P17} ML-aliases={ml}")
        print(f"      all-aliases={sorted(aliases)[:8]}")
        time.sleep(1.8)
