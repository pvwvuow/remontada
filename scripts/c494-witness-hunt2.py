# -*- coding: utf-8 -*-
# cycle-494 stage B4: the 469 sweep ran 2026-11-03 over Oct 27..Nov 9; today's
# ±7 scan covered Oct 28..Nov 11 and found NO 913550 — the missing dates are
# Oct 25/26/27. Scan exactly those for the MLS row + a witness match id.
import json, time, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

for ds in ["20261025", "20261026", "20261027"]:
    md = get(f"https://www.fotmob.com/api/data/matches?date={ds}&lang=en")
    found = False
    for lg in (md.get("leagues") or []):
        lid = lg.get("leagueId")
        name = (lg.get("name") or "")
        if lid == 913550 or (lid and "mls" in name.lower() and "next" not in name.lower()):
            ms = lg.get("matches") or []
            print(f"{ds} lid={lid} parent={lg.get('parentLeagueId')} ccode={lg.get('ccode')} name={name!r} n={len(ms)}")
            for m in ms[:6]:
                print(f"   {m.get('id')}: {m.get('home',{}).get('name')} {m.get('score',{}).get('full')} {m.get('away',{}).get('name')} | status {m.get('status',{}).get('type') if isinstance(m.get('status'),dict) else m.get('status')}")
            found = True
    if not found:
        print(f"{ds}: no MLS row")
        # diag: USA-grouped leagues present that day
        us = [(lg.get("leagueId"), lg.get("name")) for lg in (md.get("leagues") or []) if lg.get("ccode") in ("USA", "USA1")]
        print("   USA-grouped:", us[:10])
    time.sleep(1.8)
