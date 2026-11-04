# -*- coding: utf-8 -*-
# cycle-494 diag: dump the RAW Major League Soccer league block from the
# 20261026 day feed — the id keys live somewhere else than leagueId.
import json, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

md = get("https://www.fotmob.com/api/data/matches?date=20261026&lang=en")
for lg in (md.get("leagues") or []):
    if (lg.get("name") or "") == "Major League Soccer":
        print("top keys:", sorted(lg.keys()))
        print(json.dumps({k: v for k, v in lg.items() if k != "matches"}, ensure_ascii=False)[:600])
        ms = lg.get("matches") or []
        print("matches:", len(ms))
        for m in ms[:8]:
            print("  match keys:", sorted(m.keys()))
            print("  raw:", json.dumps(m, ensure_ascii=False)[:400])
        break
