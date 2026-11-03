# -*- coding: utf-8 -*-
# cycle-474: crack the REAL Liga Profesional ARG page id from witness
# team fixtures (the day-feed id 1000001729 answers literal null — the
# 469 day-id trap; no ARG matches in the current ±7 window, so the
# matchDetails crack needs a fixture/lastMatch league context instead)
import json, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

for tid, nm in [("10086", "Argentinos Juniors"), ("161727", "Tucuman witness")]:
    try:
        d = get(f"https://www.fotmob.com/api/data/teams?id={tid}")
    except Exception as e:
        print(nm, tid, "ERR", type(e).__name__, e)
        continue
    print(f"== {nm} ({tid}): name={d.get('name')!r} cc={(d.get('ccdata') or {}).get('ccode3')}")
    fx = d.get("fixtures") or {}
    seen = set()

    def scan(ms, tag):
        for m in ms or []:
            tr = m.get("tournament") or {}
            lid = tr.get("id")
            plid = tr.get("parentLeagueId")
            ln = tr.get("leagueName") or tr.get("name")
            key = (lid, plid, ln)
            if key not in seen and ("profesional" in str(ln).lower() or "argentin" in str(ln).lower() or tr.get("ccode") == "ARG"):
                seen.add(key)
                print(f"   {tag}: leagueId={lid} parentLeagueId={plid} name={ln!r} round={m.get('roundName')!r} matchId={m.get('id')}")

    scan(fx.get("lastMatches"), "last")
    scan(fx.get("nextMatches"), "next")
    # also the raw json keys for league info
    s = json.dumps(d, ensure_ascii=False)
    import re
    m = re.findall(r'"parentLeagueId":\s*(\d+)', s)
    print("   ALL parentLeagueIds in payload:", sorted(set(m))[:10])
