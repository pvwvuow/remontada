# -*- coding: utf-8 -*-
# cycle-474: ESPN slug probe — arg.1 / argentina.1 (the 469 rule: rides ONLY
# on 200 + content verification — league name + the league's own clubs in events)
import json, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

for slug in ["arg.1", "argentina.1", "arg.2"]:
    try:
        d = get(f"https://site.api.espn.com/apis/v2/sports/soccer/{slug}/league")
        name = d.get("name") or (d.get("leagues") or [{}])[0].get("name")
        abbr = (d.get("leagues") or [{}])[0].get("abbreviation")
        print(f"{slug}: 200 name={name!r} abbr={abbr!r}")
        ev = get(f"https://site.api.espn.com/apis/v2/sports/soccer/{slug}/scoreboard")
        events = ev.get("events") or []
        teams = []
        for e in events[:5]:
            for c in (e.get("competitions") or [{}])[0].get("competitors", []):
                teams.append(c.get("team", {}).get("displayName"))
        print(f"   events={len(events)} sampleTeams={teams[:6]}")
        clubs = {"Argentinos Juniors", "Boca Juniors", "River Plate", "Instituto", "Rosario Central", "Atlético Tucumán", "Vélez Sarsfield", "Racing Club"}
        hit = [t for t in teams if t in clubs]
        print(f"   content-verified club hits: {hit}")
    except Exception as e:
        print(f"{slug}: {type(e).__name__} {e}")
