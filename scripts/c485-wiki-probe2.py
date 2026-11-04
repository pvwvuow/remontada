#!/usr/bin/env python3
# cycle-485 probe2 — identity verification of the THREE fa.wiki candidates
# surfaced by probe A/B: «باشگاه ورزشی هورسنس» (AC Horsens?), «باشگاه
# فوتبال اسبیرگ» (Esbjerg fB?), «باشگاه فوتبال آمازولو» (WHICH AmaZulu —
# the South African AmaZulu FC or the Zimbabwean namesake?). The strict
# rule: the extract must name the club's country/league (Denmark /
# Superliga for DEN; South Africa / Premier Soccer League for RSA).
# Also a second-pass search for the remaining anchorless DEN names with
# alternate forms (Aarhus Fremad IF, Brabrand IF, FC Roskilde roster pages
# were noise) + the RSA remainder (Durban City 2024 / Golden Arrows forms).
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


print("== C) info+extracts for the THREE candidates ==")
T = "|".join(["باشگاه ورزشی هورسنس", "باشگاه فوتبال اسبیرگ",
              "باشگاه فوتبال آمازولو"])
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts|langlinks"
        "&exintro=1&explaintext=1&redirects=1&inprop=url&titles="
        + urllib.parse.quote(T) + "&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print(f"  MISSING: {p.get('title')}")
        continue
    ex = (p.get("extract") or "(EMPTY)")[:400].replace("\n", " ")
    lls = [l.get("lang") for l in (p.get("langlinks") or [])][:6]
    print(f"  pageid={pid} :: {p.get('title')!r} :: langlinks={lls}")
    print(f"    extract: {ex}")
    time.sleep(1.8)

print("== D) second-pass fa searches (anchorless remainder, alternate forms) ==")
QUERIES = [
    ("Aarhus Fremad", "Aarhus Fremad IF"),
    ("Aarhus Fremad", "Fremad Aarhus"),
    ("Brabrand", "Brabrand IF"),
    ("Brabrand", "برابرند"),
    ("FC Roskilde", "FC Roskilde Denmark"),
    ("FC Roskilde", "اف‌سی روسکیلده"),
    ("Durban City", "Durban City FC"),
    ("Lamontville Golden Arrows", "Golden Arrows Durban"),
    ("Sekhukhune United", "Sekhukhune"),
    ("Siwelele", "Siwelele South Africa"),
]
for n, f in QUERIES:
    q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
         "&srlimit=6&srprop=snippet&format=json&srsearch="
         + urllib.parse.quote(f))
    d = api(q)
    hits = [h["title"] for h in (d or {}).get("query", {}).get("search", [])]
    print(f"  fa-search[{n} | {f}] -> {hits[:5]}")
    time.sleep(1.8)
