#!/usr/bin/env python3
# cycle-467 batch-24 anchor probes — the FIVE-WAY TIE (the 466-card pin:
# CZE/EST/ISR/SWE/USA all 8/24 atop the post-466 census). The 447 tie-break
# (the RUS=GUA / PAN=HON precedent): anchor quality — the side with more
# direct fa.wiki club-article anchors is harvested, the others wait. A)
# wikidata exact fawiki sitelinks for all 40 clubs. B) fa.wiki exact title
# existence for the sitelinks + the honest candidates. C) identity
# verification (extracts) — WRONG-COUNTRY pages must be rejected (the 456/
# 460/461/462/465/466 lessons; the 466 probe: رئال اسپانیا was the CURRENCY,
# اتلتیکو ایندپندینته a REDIRECT to the Argentine club).
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TRANCHES = {
    "CZE": ["Artis Brno", "FC Zbrojovka Brno", "Hradec Králové",
            "Mladá Boleslav", "SK Prostějov", "Slovácko", "Teplice",
            "Vysočina Jihlava"],
    "EST": ["FC Kuressaare", "FCI Levadia", "Narva Trans", "Nõmme JK Kalju",
            "Nõmme United", "Paide Linnameeskond", "Pärnu JK Vaprus",
            "Tammeka"],
    "ISR": ["Bnei Yehuda Tel Aviv", "FC Ashdod", "Hapoel Kfar Shalem",
            "Hapoel Raanana", "Hapoel Tel Aviv", "Ironi Modiin", "Kiryat Yam",
            "Maccabi Kabilio Jaffa"],
    "SWE": ["Brommapojkarna", "Degerfors", "Elfsborg", "Halmstads BK",
            "Hammarby", "Landskrona BoIS", "Varbergs BoIS FC", "Västerås SK"],
    "USA": ["CF Montréal", "Columbus Crew", "FC Dallas", "Nashville SC",
            "San Jose Earthquakes", "Seattle Sounders FC",
            "Sporting Kansas City", "Vancouver Whitecaps"],
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


print("== A) wikidata exact fawiki sitelinks for the 40 tie clubs ==")
found = {}   # club -> fa title
for cc, clubs in TRANCHES.items():
    for n in clubs:
        q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
             + urllib.parse.quote(n) + "&language=en&type=item&limit=8&format=json")
        d = api(q)
        toks = [t.lower() for t in re.split(r"[^A-Za-z]+", n) if len(t) > 2]
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
            print(f"  [{cc}] {n} -> NO club entity found")
            continue
        g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
                + qid + "&props=sitelinks|labels|descriptions&languages=en&format=json")
        time.sleep(0.2)
        ent = (g or {}).get("entities", {}).get(qid, {})
        fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
        en = ent.get("labels", {}).get("en", {}).get("value")
        print(f"  [{cc}] {n} -> {qid} ({en}) fa={fa}")
        if fa:
            found[f"{cc}:{n}"] = fa

print("== B) fa.wiki exact title existence (batched) ==")
cand = sorted(set(found.values()))
TITLES = "|".join(cand)
if TITLES:
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
           "&titles=" + urllib.parse.quote(TITLES) + "&format=json")
    d = api(url)
    pages = (d or {}).get("query", {}).get("pages", {})
    present = {}
    for pid, p in pages.items():
        if pid != "-1" and "missing" not in p:
            present[p["title"]] = p.get("lastrevid")
            print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
    missing = [t["title"] for t in pages.values() if "missing" in t]
    print(f"  ({len(missing)} titles missing)")
else:
    present = {}

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
        ex = (p.get("extract") or "")[:200].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump({"found": found, "present": present},
          open("/tmp/c467-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c467-wiki.json")
for cc in TRANCHES:
    n_anchor = sum(1 for k in found if k.startswith(cc + ":"))
    n_verified = sum(1 for k in found if k.startswith(cc + ":")
                     and found[k] in present)
    print(f"ANCHOR SCORE — {cc}: {n_anchor} sitelinks, {n_verified} existing titles")
