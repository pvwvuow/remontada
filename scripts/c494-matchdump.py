# -*- coding: utf-8 -*-
# cycle-494: full dump of the witness match 5071455 (LAFC 2-2 LA Galaxy,
# 2026-10-26) matchDetails — the infoBox Tournament block (the 474 crack
# carried link /leagues/112/...), the general block (the 479 crack carried
# leagueId+parentLeagueId there), and every /leagues/ link string anywhere.
import json, subprocess, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def fetch(url, tries=3):
    for i in range(tries):
        r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "30", "-A", UA, "-w", "\n%{http_code}", url],
                           capture_output=True, text=True)
        body, _, code = r.stdout.rpartition("\n")
        if code == "200":
            try:
                return json.loads(body)
            except Exception:
                return None
        time.sleep(2 * (i + 1))
    return None

d = fetch("https://www.fotmob.com/api/data/matchDetails?matchId=5071455&lang=en")
time.sleep(1.8)
mf = (d.get("content") or {}).get("matchFacts") or {}
info = mf.get("infoBox") or {}
print("infoBox keys:", sorted(info.keys()))
print("infoBox.Tournament:", json.dumps(info.get("Tournament") or {}, ensure_ascii=False)[:400])
gen = mf.get("general") or {}
print("\ngeneral keys:", sorted(gen.keys())[:24])
for k in ("leagueId", "parentLeagueId", "leagueName", "leagueRoundName", "ccode", "tournamentLink", "linkage"):
    if k in gen:
        print(f"general.{k}:", repr(gen.get(k)))

# every /leagues/ occurrence in the whole payload
s = json.dumps(d, ensure_ascii=False)
import re
links = sorted(set(re.findall(r"/leagues/[^\"\\ ]+", s)))
print("\n/leagues/ links in payload:", links[:12])
ids = sorted(set(re.findall(r'"parentLeagueId":\s*(\d+)', s)))
print("parentLeagueId values:", ids)
ids2 = sorted(set(re.findall(r'"leagueId":\s*(\d+)', s)))
print("leagueId values:", ids2[:20])
