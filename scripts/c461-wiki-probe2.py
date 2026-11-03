#!/usr/bin/env python3
# cycle-461 probe2: the first probe's batched title check came back EMPTY
# (pages={} — the URL was over the limit, a silent failure, 0 titles actually
# checked). This redo (A) re-checks the exact titles in chunks of 8, then
# (B) IDENTITY-VERIFIES every hit (the 456 بوکلی / 460 آدرا-Spain lessons —
# Mérida and Guadalajara are ALSO Spanish cities, La Paz is ALSO the Bolivian
# capital: wrong-country pages are unusable as anchors) and (C) opensearches
# with the Latin names (the 455 opensearch-gate pattern).
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


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


CITIES = ["دورانگو", "دورنگو", "لا پاز", "لاپاز",
          "مورلیا", "کانکون", "کانکون",
          "گوادالاخارا", "گوادالاخارا",
          "کمپچه", "تلاکسکالا", "مریدا", "مریدا", "یوکاتان"]
CLUBC = ["الاکرانس", "آلاکرانس", "الاکرانس دی دورانگو", "الاکرانس دورانگو",
         "اتلتیکو مورلیا", "اتلتیکو لا پاز",
         "کانکون اف‌سی", "کانکون اف سی",
         "لئونس نگروس", "لیونس نگروس", "شیرهای سیاه",
         "پیراتاس", "دزدای دریایی", "دزدین دریایی",
         "ونادوس", "ونادوس اف‌سی", "ونادوس اف سی",
         "تلاکسکالا اف‌سی", "تلاکسکالا اف سی"]

print("== A) exact-title existence, chunked (8 per request) ==")
present = {}
allc = sorted(set(CITIES + CLUBC))
for i in range(0, len(allc), 8):
    chunk = allc[i:i + 8]
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
           "&titles=" + urllib.parse.quote("|".join(chunk)) + "&format=json")
    d = api(url)
    pages = (d or {}).get("query", {}).get("pages", {})
    for pid, p in pages.items():
        if pid != "-1" and "missing" not in p:
            present[p["title"]] = p.get("lastrevid")
            print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
    time.sleep(0.3)
print(f"  present={len(present)} / tried={len(allc)}")

print("== B) identity extracts (first 200 chars) ==")
if present:
    tit = list(present.keys())
    for i in range(0, len(tit), 6):
        chunk = tit[i:i + 6]
        url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
               "&exintro&explaintext&exchars=200&titles="
               + urllib.parse.quote("|".join(chunk)) + "&format=json")
        d = api(url)
        for pid, p in ((d or {}).get("query", {}).get("pages", {})).items():
            if pid != "-1" and "missing" not in p:
                txt = (p.get("extract") or "").replace("\n", " ")[:200]
                print(f"  [{p['title']}] {txt}")
        time.sleep(0.3)

print("== C) opensearch (Latin queries) ==")
QUERIES = ["Alacranes de Durango", "CF Durango", "Durango",
           "Atlético La Paz", "La Paz, Baja California Sur",
           "Atlético Morelia", "Monarcas Morelia", "Morelia",
           "Cancún FC", "Cancún", "Leones Negros",
           "Universidad de Guadalajara", "Guadalajara",
           "Piratas", "Piratas de Campeche", "Campeche",
           "Tlaxcala FC", "Tlaxcala", "Venados FC", "Venados",
           "Mérida, Yucatán", "Yucatán"]
for q in QUERIES:
    url = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
           + urllib.parse.quote(q) + "&limit=6&format=json")
    d = api(url)
    res = (d or [None, None, []])[2]
    print(f"  {q} -> {res}")
    time.sleep(0.3)
