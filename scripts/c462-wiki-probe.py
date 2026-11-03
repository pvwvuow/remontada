#!/usr/bin/env python3
# cycle-462 batch-21 anchor probes (the ARGENTINA tranche: 19 names / 62 rows
# — the 446-pick rule on the fresh census: pre-patch distinct=1773 (+2 net
# live-window churn vs the documented 461 post-census 1771), count-3 segment
# 185→204 (+19) with the live Liga Profesional + Copa Argentina ARG wave the
# headline: 19 names / 62 rows, 14 at count-3 and 5 at count-4, ZERO (W)
# sides, every name single-country ARG across the whole ±7 window; ARG 19/62
# tops the pool with PAN/HON 9/27 (the 461 leaders) held below). A) Wikidata
# exact fawiki sitelinks for the 19 clubs. B) fa.wiki exact title existence
# (canonical titles + pageids, batched) for the sitelinks + the city toponyms
# + the honest candidates (the 452 city-title rule / the file's OWN
# phonetic-Spanish convention — boca juniors → بوکا جونیورز, independiente
# medellín → ایندپندینته مدئین, racing → راسینگ, estudiantes → استودیانتس,
# deportivo → دپورتیوو; NON-club / WRONG-COUNTRY pages must be
# identity-verified before exclusion — the 456 بوکلی / 460 آدرا / 461
# لا پاز-Argentina lessons).
import json
import re
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CLUBS = [
    "Deportivo Riestra", "Argentinos Juniors", "Independiente Rivadavia",
    "Atlético Tucumán", "Club Atlético Platense", "Instituto",
    "Estudiantes de Río Cuarto", "Gimnasia LP", "Huracán", "Racing Club",
    "Sarmiento", "Rosario Central", "Vélez Sarsfield", "Unión", "Belgrano",
    "Barracas Central", "Defensa y Justicia", "Independiente", "Banfield",
]


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


print("== A) wikidata exact fawiki sitelinks for the 19 ARG clubs ==")
found = {}
for n in CLUBS:
    q = ("https://www.wikidata.org/w/api.php?action=wbsearchentities&search="
         + urllib.parse.quote(n) + "&language=en&type=item&limit=8&format=json")
    d = api(q)
    toks = [t.lower() for t in re.split(r"[^A-Za-z]+", n) if len(t) > 2]
    qid = None
    for e in (d or {}).get("search", []):
        lab = (e.get("label") or "").lower()
        desc = (e.get("description") or "").lower()
        if any(t in lab for t in toks) and ("football" in desc or "soccer" in desc
                                            or "argentin" in desc or "club" in desc):
            qid = e["id"]
            break
    time.sleep(0.25)
    if not qid:
        print(f"  {n} -> NO club entity found")
        continue
    g = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids="
            + qid + "&props=sitelinks|labels|descriptions&languages=en&format=json")
    time.sleep(0.25)
    ent = (g or {}).get("entities", {}).get(qid, {})
    fa = (ent.get("sitelinks", {}).get("fawiki") or {}).get("title")
    en = ent.get("labels", {}).get("en", {}).get("value")
    de = ent.get("descriptions", {}).get("en", {}).get("value")
    print(f"  {n} -> {qid} ({en} | {de}) fa={fa}")
    if fa:
        found[n] = fa

print("== B) fa.wiki exact title existence (batched) ==")
CAND = sorted(set(found.values())) + [
    # city/context toponyms (the 452 city-title rule) — spelling families
    "لا پلاتا", "لاپلاتا", "ریو کوارتو", "ریو کوآرتو", "ریو چهارم",
    "سانتا فئ", "سانتافه", "توکومان", "توسومان",
    # honest club-name candidates (the file's OWN phonetic-Spanish convention)
    "دپورتیوو ریسترا", "دپورتیوو ریسترآ",
    "آرژانتینوس جونیورز", "ارجانتینوس جونیورز",
    "ایندپندینته ریواداویا", "ایندپندینته ریواداویا",
    "اتلتیکو توکومان", "اتلتیکو تیکومان",
    "پلاتنسه", "پلاتنزه", "کلوب اتلتیکو پلاتنسه",
    "اینستیتو", "انستیتو", "اینستیتو کوردوبا",
    "استودیانتس دی ریو کوآرتو", "استودیانتس دی ریو کوارتو",
    "خیمناسیا ای اسگریما لا پلاتا", "خیمناسیا و اسگریمای لاپلاتا",
    "گیمناسیا ای اسگریما لا پلاتا", "خیمناسیا لپلاتا", "خیمناسیا لاپلاتا",
    "اوراکان", "هوراکان", "هوراکان بوینس آیرس",
    "راسینگ کلوب", "راسینگ کلاب", "راسینگ آولاندا",
    "سارمینتو", "سارمنتو", "سارمینتو خونین",
    "روزاریو سنترال", "روزاریو سنترال", "روزاریو سنتپال",
    "ولز سارسفیلد", "ولز سارسفیلد", "ولز",
    "اونیون", "یونیون سانتافه", "اونیون سانتافه", "باشگاه فوتبال اونیون",
    "بلگرانو", "بلگرانو کوردوبا",
    "باراکاس سنترال", "باراکاس سنترال",
    "دفنسا و خوستیسیا", "دفنسا ی خوستيسيا", "دفنزا و خوستیسیا",
    "ایندپندینته", "ایندپندینته آولاندا",
    "بنفیلد", "بنفیلد بوینس آیرس",
]
TITLES = "|".join(sorted(set(CAND)))
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

print("== C) identity verification (extracts of the EXISTING club pages) ==")
VERIF = sorted(set(found.values()))
if VERIF:
    T2 = "|".join(VERIF)
    u2 = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
          "&exintro=1&explaintext=1&titles=" + urllib.parse.quote(T2)
          + "&format=json")
    d2 = api(u2)
    for pid, p in ((d2 or {}).get("query", {}).get("pages", {}) or {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:180].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump({"found": found, "present": present},
          open("/tmp/c462-wiki.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c462-wiki.json")
