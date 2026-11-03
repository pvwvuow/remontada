#!/usr/bin/env python3
# cycle-477 probe2 — the follow-ups before the patch: (1) the Elbasani
# search hit «باشگاه فوتبال البسان» — existence + identity extract (the
# fifth direct anchor if verified); (2) Skënderbeu re-search under the
# fuller spellings (اسکندربو کورچا / Skënderbeu Korçë) — the 475
# single-title-probe lesson: settle it BEFORE the patch; (3) the collision
# pre-check: تیرانا / ولازنیا اشکودر / پارتیزانی تیرانا / دینامو تیرانا /
# البسان / اسکندربو / وورا against the whole 2289-pair file values.
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


print("== 1) the Elbasani candidate: existence + extract ==")
u = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
     "&exintro=1&explaintext=1&inprop=url&titles="
     + urllib.parse.quote("باشگاه فوتبال البسان") + "&format=json")
d = api(u)
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    if pid == "-1" or "missing" in p:
        print("  MISSING")
    else:
        print(f"  EXISTS pageid={pid} title={p['title']!r} rev={p.get('lastrevid')}")
        print(f"  extract: {(p.get('extract') or '')[:300]}")

print("== 2) Skënderbeu re-search (fuller spellings) ==")
for term in ("اسکندربو کورچا", "Skënderbeu Korçë", "اسکندربو"):
    q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
         "&srlimit=8&srprop=snippet&format=json&srsearch=" + urllib.parse.quote(term))
    d = api(q)
    hits = [h["title"] for h in (d or {}).get("query", {}).get("search", [])]
    print(f"  search {term!r} -> {hits}")
    time.sleep(0.3)

print("== 3) the collision pre-check against the whole file ==")
src = open("src/lib/leagues.ts", encoding="utf-8").read()
pairs = re.findall(r'"((?:[^"\\]|\\.)+)":\s*"([^"]+)"', src)
vals = {}
for k, v in pairs:
    vals.setdefault(v, []).append(k)
for v in ("تیرانا", "ولازنیا اشکودر", "پارتیزانی تیرانا", "دینامو تیرانا",
          "البسان", "اسکندربو", "وورا"):
    print(f"  value {v!r} -> existing keys: {vals.get(v, [])}")
keys = {}
for k, _ in pairs:
    keys.setdefault(k, 0)
    keys[k] += 1
for k in ("elbasani", "fc dinamo city", "kf tirana", "partizani",
          "skënderbeu", "vllaznia", "vora"):
    print(f"  key {k!r} present: {k in keys}")
print(f"  file pairs total: {len(pairs)}")
