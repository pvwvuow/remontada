#!/usr/bin/env python3
# cycle-462 probe 2 — the B-section fix (the batched titles= query returned an
# empty page map: URL too long) + the 12 clubs without a wikidata fawiki
# sitelink: exact-title existence in SMALL batches + opensearch fallback +
# identity extracts. The 452 city-title rule candidates + the file's OWN
# phonetic-Spanish convention; every hit identity-verified before use (the
# 456 بوکلی / 460 آدرا / 461 Erzurumspor lessons).
import json
import re
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


def title_exists(titles):
    """exact-title existence in SMALL batches -> {title: pageid}"""
    res = {}
    for i in range(0, len(titles), 20):
        chunk = titles[i:i + 20]
        T = "|".join(chunk)
        url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info"
               "&titles=" + urllib.parse.quote(T) + "&format=json")
        d = api(url)
        pages = ((d or {}).get("query") or {}).get("pages", {})
        for pid, p in pages.items():
            if pid != "-1" and "missing" not in p:
                res[p["title"]] = p.get("lastrevid")
        time.sleep(0.3)
    return res


CANDIDATES = {
    "Deportivo Riestra": ["باشگاه فوتبال دپورتیوو ریسترا", "دپورتیوو ریسترا",
                          "دپورتیوو ریسترآ"],
    "Independiente Rivadavia": ["باشگاه فوتبال ایندپندینته ریواداویا",
                                "ایندپندینته ریواداویا"],
    "Club Atlético Platense": ["باشگاه فوتبال پلاتنسه", "پلاتنسه",
                               "پلاتنزه", "باشگاه فوتبال پلاتنزه"],
    "Instituto": ["باشگاه فوتبال اینستیتو", "اینستیتو",
                  "باشگاه فوتبال انستیتو", "انستیتو",
                  "اینستیتو کوردوبا", "اینستیتو د کوردوبا"],
    "Estudiantes de Río Cuarto": ["استودیانتس دی ریو کوآرتو",
                                  "استودیانتس دی ریو کوارتو",
                                  "باشگاه فوتبال استودیانتس دی ریو کوآرتو"],
    "Sarmiento": ["باشگاه فوتبال سارمینتو", "سارمینتو", "سارمنتو",
                  "باشگاه فوتبال سارمینتو (خونین)"],
    "Unión": ["باشگاه فوتبال اونیون", "اونیون", "اونیون سانتافه",
              "یونیون سانتافه", "باشگاه فوتبال اونیون (سنتافه)",
              "باشگاه فوتبال اونیون سانتا فه"],
    "Belgrano": ["باشگاه فوتبال بلگرانو", "بلگرانو",
                 "باشگاه فوتبال بلگرانو (کوردوبا)"],
    "Barracas Central": ["باشگاه فوتبال باراکاس سنترال", "باراکاس سنترال"],
    "Defensa y Justicia": ["باشگاه فوتبال دفنسا و خوستیسیا",
                           "دفنسا و خوستیسیا", "دفنزا و خوستیسیا",
                           "دفنسا ی خوستیسیا"],
    "Banfield": ["باشگاه فوتبال بانفیلد", "بانفیلد"],
    # city/context toponyms for the city-title rule candidates
    "La Plata": ["لا پلاتا", "لاپلاتا"],
    "Río Cuarto": ["ریو کوارتو", "ریو کوآرتو", "ریو چهارم"],
    "Santa Fe": ["سانتا فئ", "سانتافه", "سانتا فه"],
    "Tucumán": ["توکومان", "توسومان"],
}

print("== B2) exact-title existence (small batches) ==")
present = title_exists([t for ts in CANDIDATES.values() for t in ts])
for t, pid in sorted(present.items()):
    print(f"  EXISTS pageid={pid}: {t}")

print("== B3) opensearch fallback for clubs with NO exact hit above ==")
HITSET = set(present)
NEED = {k: v for k, v in CANDIDATES.items()
        if not any(h in HITSET for h in v)}
os_hits = {}
for club, cands in NEED.items():
    q = cands[0].replace("باشگاه فوتبال ", "")
    url = ("https://fa.wikipedia.org/w/api.php?action=opensearch&search="
           + urllib.parse.quote(q) + "&limit=6&namespace=0&format=json")
    d = api(url)
    lst = ((d or [])[1] if isinstance(d, list) else []) or []
    os_hits[club] = lst
    print(f"  {club} :: {lst}")
    time.sleep(0.3)

print("== C2) identity extracts for the NEW exact hits (club pages) ==")
CLUB_HITS = [t for club, cands in CANDIDATES.items() if club not in
             ("La Plata", "Río Cuarto", "Santa Fe", "Tucumán")
             for t in cands if t in present]
if CLUB_HITS:
    VER = title_exists(CLUB_HITS)  # noop re-check, reuse ids
    for i in range(0, len(CLUB_HITS), 10):
        chunk = CLUB_HITS[i:i + 10]
        T = "|".join(chunk)
        u2 = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
              "&exintro=1&explaintext=1&titles=" + urllib.parse.quote(T)
              + "&format=json")
        d2 = api(u2)
        for pid, p in (((d2 or {}).get("query") or {}).get("pages", {})
                       or {}).items():
            if pid == "-1" or "missing" in p:
                continue
            ex = (p.get("extract") or "")[:190].replace("\n", " ")
            print(f"  {p['title']} :: {ex}")
        time.sleep(0.3)

json.dump({"present": present, "os": os_hits},
          open("/tmp/c462-wiki2.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c462-wiki2.json")
