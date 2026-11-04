#!/usr/bin/env python3
# cycle-490 probe2 — resolves the 447 scoreboard (probe1: GRE 2 / BLR 2 /
# SLV 2 — the three-way tie) to a SINGLE winner:
# 1) fa-search coverage for the six zero-entity names stage-B missed
#    (Nestos/Dukla/Skalica/ML Vitebsk/Nafta/VPS),
# 2) extracts for every NEW candidate surfaced (the 487 pageids 6386207
#    Dukla / 6968310 ML Vitebsk as the cross-checks),
# 3) the «باشگاه فوتبال مارکو» identity re-check (the 487 PORTUGUESE
#    namesake rejection keeps GRE honest at 2),
# 4) the SLV depth (Cacahuatique / Fuerte — expected zero),
# 5) the final scoreboard.
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


print("== 1) fa-search for the six zero-entity names ==")
MISSED = {
    "Nestos Chrisoupolis (GRE)": ["نیستوس خریسوپولی", "نستوس کاوالا",
                                  "Chrisoupolis"],
    "Dukla Banská Bystrica (SVK)": ["دوکلا بانسکا بیستریتسا", "Dukla Banská"],
    "Skalica (SVK)": ["اسکالیسا فوتبال", "FC Skalica"],
    "ML Vitebsk (BLR)": ["ویتبسک فوتبال", "FC Vitebsk", "МЛ Витебск"],
    "Nafta (SVN)": ["نفتا لنداوا فوتبال", "Nafta Lendava"],
    "VPS (FIN)": ["وآ‌اس وایکاوس", "VPS Vaasa"],
}
cands = {}
for n, forms in MISSED.items():
    for f in forms:
        hits = fa_search(f)
        print(f"  fa-search[{n} | {f}] -> {hits[:4]}")
        time.sleep(1.8)
        for h in hits:
            if "باشگاه" in h or "فوتبال" in h:
                cands.setdefault(n, []).append(h)

print("== 2) extracts for the NEW candidates ==")
if cands:
    T = "|".join(sorted({h for v in cands.values() for h in v}))
    extract(titles=T)
else:
    print("  (no club-looking hits at all)")
time.sleep(1.8)

print("== 3) باشگاه فوتبال مارکو — identity re-check (the 487 rejection) ==")
extract(titles="باشگاه فوتبال مارکو")
time.sleep(1.8)

print("== 4) the SLV depth (Cacahuatique / Fuerte — expected zero) ==")
for n, forms in {
    "CD Cacahuatique (SLV)": ["کاکاهواتیکه فوتبال", "Cacahuatique"],
    "Fuerte San Francisco (SLV)": ["فوئرته فوتبال السالوادور",
                                   "Fuerte San Francisco club"],
}.items():
    for f in forms:
        hits = fa_search(f)
        print(f"  fa-search[{n} | {f}] -> {hits[:4]}")
        time.sleep(1.8)

print("== 5) the final 447 scoreboard (probe1 + probe2 evidence) ==")
print("""  probe1 direct anchors:
    GRE 2: AE Larissa (3892127 لاریسا) + Atromitos (3438822 آترومیتوس)
    BLR 2: Belshina (4982515 بلشیتا بابرویسک) + Dinamo Minsk (3189380 دینامو مینسک)
    SLV 2: Platense (6438277 پلاتینزه) + Isidro Metapan (6638134 ایسیدرو متاپان)
    SVK 1 / SVN 1 / FIN 1
  probe2 decides: ML Vitebsk / Dukla / Nestos / Cacahuatique / Fuerte""")
