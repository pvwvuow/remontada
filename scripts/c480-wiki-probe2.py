#!/usr/bin/env python3
# cycle-480 probe2 — the single-title verifications (the 475 رعانانا
# single-title probe pattern): (1) the Guaraní search hit «باشگاه فوتبال
# گوارانی (پاراگوئه)» — exact existence + pageid + identity extract; (2)
# the San Lorenzo city toponym (the 461 city-grounded rule) for the
# Sportivo San Lorenzo render; (3) the bare-«سرو پورتنیو» page 6956335
# (what IS it now — the renamed-upstream evidence for the 477-documented
# anchor); (4) Assunción toponym for 2 de Mayo? (no — phonetic).
import json, subprocess, time, urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

def api(url):
    for attempt in range(3):
        out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(2 + attempt * 2)
    return None

TITLES = [
    "باشگاه فوتبال گوارانی (پاراگوئه)",
    "سن لورنزو (پاراگوئه)",
    "سرو پورتنیو",
    "گوارانی",
]
T = "|".join(TITLES)
print("== existence (batched, one call) ==")
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url&titles="
        + urllib.parse.quote(T) + "&format=json")
present = {}
for pid, p in ((d or {}).get("query", {}).get("pages", {}) or {}).items():
    if pid != "-1" and "missing" not in p:
        present[p["title"]] = pid
        print(f"  EXISTS pageid={pid}: {p['title']}")
    else:
        print(f"  MISSING: {p.get('title')}")
time.sleep(2)

print("== extracts ==")
P = "|".join(sorted(present))
d2 = api("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts&exintro=1"
         "&explaintext=1&titles=" + urllib.parse.quote(P) + "&format=json")
for pid, p in ((d2 or {}).get("query", {}).get("pages", {}) or {}).items():
    if pid == "-1" or "missing" in p:
        continue
    ex = (p.get("extract") or "")[:300].replace("\n", " ")
    print(f"  {p['title']} ({pid}) :: {ex}")
