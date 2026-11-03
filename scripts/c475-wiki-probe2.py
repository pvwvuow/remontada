#!/usr/bin/env python3
# cycle-475 anchor probes (the 472 multi-shape ritual, fresh per the 447
# live-re-read lesson — fa.wiki has grown since the 472 read). Shape A:
# en.wikipedia search -> langlinks(fa) -> fa existence -> identity extracts.
# Shape B: DIRECT fa.wiki existence for the documented + honest-read
# candidate spellings (chunked + sleeps, the probe4 rate-limit lesson).
import json, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CLUBS = ["Bnei Yehuda Tel Aviv", "FC Ashdod", "Hapoel Kfar Shalem",
         "Hapoel Raanana", "Hapoel Tel Aviv", "Ironi Modiin", "Kiryat Yam",
         "Maccabi Kabilio Jaffa"]

SPELLINGS = [
    # documented 472 anchors (re-verify fresh)
    "بنی یهودا تل آویو", "هاپوئل تل‌آویو", "باشگاه فوتبال اشدود",
    # documented 472 CITY pages (toponym grounding only)
    "اشدود", "کریات یام",
    # honest-read candidates for the zero-anchor five
    "هاپوئل کفر شالم", "کفر شالم",
    "هاپوئل رعاننا", "رعاننا", "هاپوئل رعانا",
    "ایرونی مودیعین", "مودیعین", "مودئین", "هاپوئل مودیعین",
    "مکابی کابیلیو یافا", "کابیلیو یافا", "یافا",
    "مکابی یافا",  # the IDENTITY-DISTINCT club — must NOT be used for Kabilio Jaffa
]


def api(url, tries=5):
    for attempt in range(tries):
        out = subprocess.run(["curl", "-s", "--max-time", "30", "-A", UA, url],
                             capture_output=True, text=True, timeout=50).stdout
        if out.strip().startswith("{"):
            try:
                return json.loads(out)
            except Exception:
                pass
        time.sleep(3 + attempt * 3)
    return None


print("== A) en.wikipedia -> langlinks(fa) ==")
en_fa = {}
for n in CLUBS:
    q = ("https://en.wikipedia.org/w/api.php?action=query&list=search"
         "&srsearch=" + urllib.parse.quote(n) + "&srlimit=3&format=json")
    d = api(q)
    hits = [h["title"] for h in ((d or {}).get("query", {}) or {}).get("search", [])]
    fa = None
    for t in hits:
        l = api("https://en.wikipedia.org/w/api.php?action=query&prop=langlinks"
                "&titles=" + urllib.parse.quote(t) + "&lllang=fa&format=json")
        pages = (l or {}).get("query", {}).get("pages", {})
        for p in pages.values():
            for ll in p.get("langlinks", []):
                if ll.get("lang") == "fa":
                    fa = ll.get("*")
        if fa:
            en_fa[n] = (t, fa)
            break
        time.sleep(0.3)
    print(f"  {n} -> en={en_fa.get(n, (hits[:1], None))[0] if hits else None} fa={en_fa.get(n, (None, None))[1]}")
    time.sleep(0.5)

print("== B) direct fa.wiki existence (chunked) ==")
present = {}
CH = 4
for i in range(0, len(SPELLINGS), CH):
    chunk = SPELLINGS[i:i + CH]
    T = "|".join(chunk)
    d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
            "&titles=" + urllib.parse.quote(T) + "&format=json")
    for pid, p in ((d or {}).get("query", {}) or {}).get("pages", {}).items():
        if pid != "-1" and "missing" not in p:
            present[p["title"]] = p.get("lastrevid")
            print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
    time.sleep(1.5)

print("== C) identity extracts (chunked) ==")
titles = sorted(present)
for i in range(0, len(titles), CH):
    chunk = titles[i:i + CH]
    T = "|".join(chunk)
    d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
            "&exintro=1&explaintext=1&titles=" + urllib.parse.quote(T) + "&format=json")
    for pid, p in ((d or {}).get("query", {}) or {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:170].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")
    time.sleep(1.5)

json.dump({"en_fa": en_fa, "present": present},
          open("/tmp/c475-wiki2.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c475-wiki2.json")
