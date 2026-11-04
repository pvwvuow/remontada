# -*- coding: utf-8 -*-
# cycle-494: dump the tournament/linkage objects from the LA Galaxy team
# payload — the real MLS pageUrl/id lives in tournament objects.
import json, subprocess, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def fetch(url, tries=4):
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

d = fetch("https://www.fotmob.com/api/data/teams?id=6637")
time.sleep(1.8)
print("details:", json.dumps(d.get("details") or {}, ensure_ascii=False)[:500])
print("seostr:", d.get("seostr"))
print("allAvailableSeasons:", json.dumps(d.get("allAvailableSeasons") or [], ensure_ascii=False)[:400])

fx = (d.get("fixtures") or {}).get("allFixtures") or {}
print("\nprimaryTournamentId:", fx.get("primaryTournamentId"))
seen = set()
for f in (fx.get("fixtures") or []):
    t = f.get("tournament") or {}
    key = (t.get("leagueId"), t.get("name"), t.get("linkage"), t.get("isCup"), t.get("ccode"))
    if key not in seen:
        seen.add(key)
        print("tournament:", json.dumps(t, ensure_ascii=False)[:300])

ov = d.get("overview") or {}
lm = ov.get("lastMatch") or {}
print("\nlastMatch.tournament:", json.dumps(lm.get("tournament") or {}, ensure_ascii=False)[:300])
print("lastMatch:", lm.get("id"), (lm.get("home") or {}).get("name"), "vs", (lm.get("away") or {}).get("name"), lm.get("status"))

# the table block inside the team payload — MLS standings shape
tb = d.get("table") or []
if isinstance(tb, list) and tb:
    data = tb[0].get("data") or {}
    print("\nteam-payload table[0]: tableType:", tb[0].get("tableType"), "| leagueId:", data.get("leagueId"),
          "| name:", repr(data.get("name")), "| composite:", data.get("composite"))
    for c in (data.get("tables") or [])[:4]:
        t2 = c.get("table") or {}
        rows = t2.get("all") or []
        print("  sub-table:", repr(c.get("leagueName") or c.get("tableName")), "| leagueId:", c.get("leagueId"),
              "| rows:", len(rows), "| comp flag:", t2.get("composite"))
        for r in rows[:3]:
            print("    ", r.get("name"), "| idx:", r.get("idx"), "| pts:", r.get("pts"))
