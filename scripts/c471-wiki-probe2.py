#!/usr/bin/env python3
# cycle-471 anchor probe #2 — the wikidata search path answered nearly all
# NO (flaky), so this one walks en.wikipedia search -> langlinks (fa) ->
# fa.wiki existence -> identity extracts. Same 24 clubs of the CZE/SWE/ISR
# 8/24 three-way rest (the 470 card rotation line).
import json, re, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

TRANCHES = {
    "CZE": ["Artis Brno", "FC Zbrojovka Brno", "Hradec Králové",
            "Mladá Boleslav", "SK Prostějov", "Slovácko", "Teplice",
            "Vysočina Jihlava"],
    "SWE": ["Brommapojkarna", "Degerfors", "Elfsborg", "Halmstads BK",
            "Hammarby", "Landskrona BoIS", "Varbergs BoIS FC", "Västerås SK"],
    "ISR": ["Bnei Yehuda Tel Aviv", "FC Ashdod", "Hapoel Kfar Shalem",
            "Hapoel Raanana", "Hapoel Tel Aviv", "Ironi Modiin", "Kiryat Yam",
            "Maccabi Kabilio Jaffa"],
}


def api(url):
    for attempt in range(4):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "25", "-A", UA, url],
            capture_output=True, text=True, timeout=40,
        ).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


found = {}    # "CC:club" -> fa title (from en langlinks)
en_title = {}  # "CC:club" -> en article used
for cc, clubs in TRANCHES.items():
    for n in clubs:
        toks = [t for t in re.split(r"[^A-Za-zÀ-ž0-9]+", n) if len(t) > 2]
        q = ("https://en.wikipedia.org/w/api.php?action=query&list=search"
             "&srsearch=" + urllib.parse.quote(n + " football club")
             + "&srlimit=6&format=json")
        d = api(q)
        hits = ((d or {}).get("query") or {}).get("search") or []
        pick = None
        for h in hits:
            ti = h.get("title") or ""
            low = ti.lower()
            if any(t.lower() in low for t in toks) and (
                    "football" in low or "F.C." in ti or "FC" in ti
                    or "BK" in ti or "IF" in ti or "SK" in ti or "BoIS" in ti):
                pick = ti
                break
        if not pick:
            print(f"  [{cc}] {n} -> NO en article picked ({[h.get('title') for h in hits]})")
            time.sleep(0.3)
            continue
        q2 = ("https://en.wikipedia.org/w/api.php?action=query&prop=langlinks"
              "&lllang=fa&titles=" + urllib.parse.quote(pick) + "&format=json")
        d2 = api(q2)
        pages = ((d2 or {}).get("query") or {}).get("pages") or {}
        fa = None
        for p in pages.values():
            for ll in p.get("langlinks") or []:
                if ll.get("lang") == "fa":
                    fa = ll.get("*")
        print(f"  [{cc}] {n} -> en={pick!r} fa={fa}")
        en_title[f"{cc}:{n}"] = pick
        if fa:
            found[f"{cc}:{n}"] = fa
        time.sleep(0.3)

print("== fa.wiki existence (batched) ==")
cand = sorted(set(found.values()))
present = {}
if cand:
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
           "&titles=" + urllib.parse.quote("|".join(cand)) + "&format=json")
    d = api(url)
    for pid, p in (((d or {}).get("query") or {}).get("pages") or {}).items():
        if pid != "-1" and "missing" not in p:
            present[p["title"]] = p.get("lastrevid")
            print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
missing = [t for t in cand if t not in present]
print(f"  ({len(missing)} titles missing)")

print("== identity extracts ==")
if present:
    u2 = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
          "&exintro=1&explaintext=1&titles=" + urllib.parse.quote("|".join(sorted(present)))
          + "&format=json")
    d2 = api(u2)
    for pid, p in (((d2 or {}).get("query") or {}).get("pages") or {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:200].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")

json.dump({"found": found, "present": present, "en": en_title},
          open("/tmp/c471-wiki2.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c471-wiki2.json")
for cc in TRANCHES:
    n_a = sum(1 for k in found if k.startswith(cc + ":"))
    n_v = sum(1 for k in found if k.startswith(cc + ":") and found[k] in present)
    print(f"ANCHOR SCORE — {cc}: {n_a} langlinks, {n_v} existing titles")
