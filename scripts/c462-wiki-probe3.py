#!/usr/bin/env python3
# cycle-462 probe 3 — the three open questions + the in-file collision
# pre-check: (1) the انستیتو page identity (the extract came back EMPTY —
# the 456 identity rule: an unverifiable page is unusable as an anchor);
# (2) Manuel Belgrano as the Belgrano-de-Córdoba namesake anchor (the 460
# اودر-river precedent: the encyclopedia's OWN rendering of the namesake);
# (3) key/value collision pre-check of the 19 planned pairs against the
# whole TEAM_FA file (the Logroñés rule) — byte-read from src/lib/leagues.ts.
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


print("== C3) identity re-probe: انستیتو (full intro sentences) ==")
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
        "&exintro=1&explaintext=1&exlimit=1&titles="
        + urllib.parse.quote("انستیتو") + "&format=json")
for pid, p in ((d or {}).get("query", {}).get("pages", {}) or {}).items():
    if pid != "-1" and "missing" not in p:
        ex = (p.get("extract") or "")[:400].replace("\n", " ")
        print(f"  {p['title']} (pageid={p.get('lastrevid')}) :: {ex}")
    else:
        print("  انستیتو :: MISSING")

print("== C4) Manuel Belgrano namesake anchor ==")
TITLES = ["مانوئل بلگرانو", "برناردینو ریواداویا"]
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info&titles="
        + urllib.parse.quote("|".join(TITLES)) + "&format=json")
for pid, p in ((d or {}).get("query", {}).get("pages", {}) or {}).items():
    ok = pid != "-1" and "missing" not in p
    print(f"  {'EXISTS' if ok else 'MISSING'} pageid={p.get('lastrevid')}: {p.get('title')}")
time.sleep(0.3)
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
        "&exintro=1&explaintext=1&titles=" + urllib.parse.quote("مانوئل بلگرانو")
        + "&format=json")
for pid, p in ((d or {}).get("query", {}).get("pages", {}) or {}).items():
    if pid != "-1" and "missing" not in p:
        ex = (p.get("extract") or "")[:220].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

print("== C5) in-file collision pre-check (byte-read) ==")
src = open("src/lib/leagues.ts", encoding="utf-8").read()
m = re.search(r'const TEAM_FA: Record<string, string> = \{(.*?)\n\};', src, re.S)
pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', m.group(1))
keys = {k for k, _ in pairs}
vals = {}
for k, v in pairs:
    vals.setdefault(v, []).append(k)
PLANNED = {
    "deportivo riestra": "دپورتیوو ریسترا",
    "argentinos juniors": "آرژانتینوس جونیورز",
    "independiente rivadavia": "ایندپندینته ریواداویا",
    "atlético tucumán": "اتلتیکو توکومان",
    "club atlético platense": "پلاتنسه",
    "instituto": "انستیتو",
    "estudiantes de río cuarto": "استودیانتس دی ریو کوارتو",
    "gimnasia lp": "جیمناسیا لاپلاتا",
    "huracán": "هوراکان",
    "racing club": "راسینگ کلوب",
    "sarmiento": "سارمینتو",
    "rosario central": "روزاریو سنترال",
    "vélez sarsfield": "ولز سارسفیلد",
    "unión": "اونیون",
    "belgrano": "بلگرانو",
    "barracas central": "باراکاس سنترال",
    "defensa y justicia": "دفنسا و خوستیسیا",
    "independiente": "ایندپندینته",
    "banfield": "بانفیلد",
}
dup_keys = [k for k in PLANNED if k in keys]
print(f"  key dups: {dup_keys}")
val_dups = {v: vals[v] for v in PLANNED.values() if v in vals}
print(f"  value dups: {val_dups}")
print(f"  file pairs now: {len(pairs)} -> after patch: {len(pairs) + len(PLANNED)}")
