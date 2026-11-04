#!/usr/bin/env python3
# cycle-486 probe2 — (1) the FRESH re-verification of the RSA single direct
# anchor: the fa.wiki article «باشگاه فوتبال آمازولو» pageid 6853449 (the
# 485 probe verified the Durban South-African identity; the 447 lesson: the
# live re-read is mandatory); (2) ZWNJ/space fa-search variants for the four
# zero-anchor names (Durban City / Lamontville Golden Arrows / Sekhukhune
# United / Siwelele) to prove the club-article absence one more time; (3)
# the city articles that ground toponyms (دوربان).
import json, subprocess, time, urllib.parse

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


print("== 1) FRESH extract of the direct anchor pageid 6853449 ==")
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url&pageids=6853449&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print(f"  MISSING pageid {pid}")
        continue
    ex = (p.get("extract") or "(EMPTY)")[:300].replace("\n", " ")
    print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
time.sleep(1.8)

print("== 2) fa-search variants for the four zero-anchor names ==")
QUERIES = {
    "Durban City": ["دوربان سیتی", "دوربان city"],
    "Lamontville Golden Arrows": ["لامونت‌ویل", "لامونتویل", "گلدن اروز"],
    "Sekhukhune United": ["سخوخونه", "سخوخونه یونایتد"],
    "Siwelele": ["سیوله له", "سیوله"],
}
for n, forms in QUERIES.items():
    for f in forms:
        q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
             "&srlimit=6&srprop=snippet&format=json&srsearch="
             + urllib.parse.quote(f))
        d = api(q)
        hits = [h["title"] for h in (d or {}).get("query", {}).get("search", [])]
        print(f"  fa-search[{n} | {f}] -> {hits[:5]}")
        time.sleep(1.8)

print("== 3) the toponym grounding: the city article دوربان ==")
d = api("https://fa.wikipedia.org/w/api.php?action=query&list=search"
        "&srlimit=3&srprop=snippet&format=json&srsearch="
        + urllib.parse.quote("دوربان آفریقای جنوبی"))
hits = [h["title"] for h in (d or {}).get("query", {}).get("search", [])]
print(f"  fa-search[دوربان آفریقای جنوبی] -> {hits[:3]}")
time.sleep(1.8)
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url&titles="
        + urllib.parse.quote("دوربان") + "&format=json")
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print(f"  MISSING: {p.get('title')}")
        continue
    ex = (p.get("extract") or "(EMPTY)")[:200].replace("\n", " ")
    print(f"  pageid={pid} :: {p.get('title')!r} :: {ex}")
