#!/usr/bin/env python3
# cycle-475 anchor probe #3 — the follow-up chunks: (1) the redirect
# resolution for the two langlink-carried club anchors (بنی یهودا / هاپوئل
# تل‌آویو — the هامارابی lesson: the intro-carrying target's OWN title
# wins), (2) the رعانانا spelling from the langlink (my first list probed
# رعاننا — wrong), (3) the Modiin city spelling variants for the Ironi
# Modiin toponym grounding.
import json, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

PROBES = [
    "بنی یهودا تل آویو", "باشگاه فوتبال بنی یهودا تل آویو",
    "هاپوئل تل‌آویو", "باشگاه فوتبال هاپوئل تل‌آویو",
    "رعانانا", "هاپوئل رعانانا",
    "مودیعین-مکابیم-رعوت", "مودیعین مکابیم رعوت", "موديعين",
    "هاپوئل کفر شالم",
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


print("== existence ==")
present = {}
CH = 4
for i in range(0, len(PROBES), CH):
    chunk = PROBES[i:i + CH]
    d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
            "&titles=" + urllib.parse.quote("|".join(chunk)) + "&format=json")
    for pid, p in ((d or {}).get("query", {}) or {}).get("pages", {}).items():
        if pid != "-1" and "missing" not in p:
            present[p["title"]] = {"revid": p.get("lastrevid"), "redirect": p.get("redirect", False)}
            print(f"  EXISTS pageid={p.get('lastrevid')} redirect={p.get('redirect', False)}: {p['title']}")
    time.sleep(1.5)

print("== extracts (identity) ==")
titles = sorted(present)
for i in range(0, len(titles), CH):
    chunk = titles[i:i + CH]
    d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
            "&exintro=1&explaintext=1&titles=" + urllib.parse.quote("|".join(chunk)) + "&format=json")
    for pid, p in ((d or {}).get("query", {}) or {}).get("pages", {}).items():
        if pid == "-1" or "missing" in p:
            continue
        ex = (p.get("extract") or "")[:200].replace("\n", " ")
        print(f"  {p['title']} :: {ex}")
    time.sleep(1.5)

json.dump(present, open("/tmp/c475-wiki3.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c475-wiki3.json")
