# -*- coding: utf-8 -*-
# cycle-494 stage B2: widen the witness hunt to the sweep's own ±7 window —
# the 469 sweep (2026-11-03) registered «MLS 913550» from exactly this feed,
# so an MLS row exists somewhere in 20261028..20261111 (playoffs window).
import json, time, urllib.request
from datetime import date, timedelta

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

base = date(2026, 11, 4)
hits = []
for off in range(-7, 8):
    d = base + timedelta(days=off)
    ds = d.strftime("%Y%m%d")
    try:
        md = get(f"https://www.fotmob.com/api/data/matches?date={ds}&lang=en")
    except Exception as e:
        print(f"{ds}: {type(e).__name__} {str(e)[:80]}")
        time.sleep(1.8)
        continue
    for lg in (md.get("leagues") or []):
        lid = lg.get("leagueId")
        name = (lg.get("name") or "")
        if lid == 913550 or "MLS" in name.upper():
            matches = lg.get("matches") or []
            hits.append((ds, lid, name, lg.get("parentLeagueId"), lg.get("ccode"), len(matches)))
            if matches:
                m0 = matches[0]
                print(f"{ds} lid={lid} parent={lg.get('parentLeagueId')} ccode={lg.get('ccode')} name={name!r} n={len(matches)} first={m0.get('id')} {m0.get('home',{}).get('name')} vs {m0.get('away',{}).get('name')}")
            else:
                print(f"{ds} lid={lid} parent={lg.get('parentLeagueId')} ccode={lg.get('ccode')} name={name!r} n=0")
    time.sleep(1.8)

print("\nsummary hits:", len(hits))
