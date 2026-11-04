# -*- coding: utf-8 -*-
# cycle-494 stage C: probe the REAL MLS page id 130 (day-feed parentLeagueId
# / primaryId; the 489 parent-id convenience class) + the 141 crack on the
# witness match 5071455 (LAFC vs LA Galaxy, 2026-10-26) for cross-proof.
import json, time, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

print("=== 141 crack: matchDetails 5071455 ===")
det = get("https://www.fotmob.com/api/data/matchDetails?matchId=5071455&lang=en")
info = ((det.get("content") or {}).get("matchFacts") or {}).get("infoBox") or {}
tour = info.get("Tournament") or {}
print("Tournament.name:", repr(tour.get("name")), "| leagueId:", tour.get("leagueId"),
      "| parentLeagueId:", tour.get("parentLeagueId"), "| countryCode:", tour.get("countryCode"))
time.sleep(1.8)

print("\n=== C: full shape of page id 130 (ccode3=USA) ===")
d = get("https://www.fotmob.com/api/data/leagues?id=130&ccode3=USA&lang=en")
if d.get("name") is None:
    print("-> id 130 also literal null")
else:
    print("name:", repr(d.get("name")), "| ccdata ccode3:", (d.get("ccdata") or {}).get("ccode3"),
          "| selectedSeason:", repr(d.get("selectedSeason")), "| color:", d.get("leagueColor"))
    print("pageUrl:", d.get("pageUrl"), "| tabs:", [t.get("id") for t in (d.get("tabs") or [])])
    t = d.get("table")
    if isinstance(t, list):
        t = t[0]
    if t:
        print("composite:", t.get("composite"), "| tableType:", t.get("tableType"), "| tableBlocks:", len(t.get("tables", [])))
        for tb in (t.get("tables") or [])[:4]:
            rows = tb.get("allMatches") or []
            print("  block:", repr(tb.get("groupName")), "rows:", len(rows))
            for r in rows[:3]:
                print("    ", r.get("team", {}).get("name"), "| rank:", r.get("rank"), "| pts:", r.get("pts"))
    sals = d.get("allAvailableSeasons") or []
    plain = [x for x in sals if "-" not in str(x)]
    slash = [x for x in sals if "/" in str(x) and "-" not in str(x)]
    suffixed = [x for x in sals if "-" in str(x)]
    print("seasons:", len(sals), "| plain:", len(plain), "| slash:", len(slash), "| suffixed:", len(suffixed), "| sample:", [str(x) for x in sals[:10]])
    print("playoff:", "PRESENT" if d.get("playoff") else "absent")
    if d.get("playoff"):
        po = d["playoff"]
        if isinstance(po, dict):
            print("  playoff keys:", list(po.keys())[:10])
            print("  playoff sample:", json.dumps(po, ensure_ascii=False)[:500])
        else:
            print("  playoff:", str(po)[:200])
    print("titleHistory:", "PRESENT" if d.get("titleHistory") else "absent")
    tr = d.get("transfers") or {}
    print("transfers.data:", "REAL" if tr.get("data") else "absent", "| first:", json.dumps((tr.get("data") or [{}])[0], ensure_ascii=False)[:180])
    st = d.get("stats") or {}
    print("stats:", "present" if st else "absent", "| keys:", list(st.keys())[:5])
    fx = d.get("fixtures") or {}
    print("fixtures.allMatches:", len(fx.get("allMatches") or []))
    print("titleHolder:", d.get("titleHolder"))
