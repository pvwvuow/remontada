# -*- coding: utf-8 -*-
# cycle-494: the registry ledger's next head — MLS (day-feed id 913550, the
# 474 ledger line «MLS 913550», one-per-cycle after russia-cup 193 in 489).
# The 469/474/479/484/489 registration path, re-proven live 2026-11-04
# UA Chrome/124 with the app's OWN fetch shape (api/data/leagues id&ccode3).
# Stage A: does the day-feed id 913550 answer a real page or the literal-null
# day-tournament trap (the 469/474/479 class)? Stage B (only on trap): a
# witness MLS match from the live day feed -> the 141 crack (matchDetails
# infoBox Tournament parentLeagueId). Stage C: full shape read of the real
# page (table/composite, seasons shape, playoff, titleHistory, transfers,
# stats, fixtures, leagueColor, pageUrl). Stage D: ESPN slug candidates.
import json, time, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
PACE = 1.8

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

def pause():
    time.sleep(PACE)

# ---------------- Stage A: the day-feed id directly ----------------
print("=== A: /api/data/leagues?id=913550&ccode3=USA ===")
d = None
try:
    d = get("https://www.fotmob.com/api/data/leagues?id=913550&ccode3=USA&lang=en")
    print("HTTP 200 | body name:", repr(d.get("name")))
    if d.get("name") is None:
        print("-> LITERAL-NULL: the day-tournament id trap class (469/474/479). Stage B needed.")
    else:
        print("-> REAL PAGE on the day-feed id itself (the 489 parent-193 convenience class).")
except Exception as e:
    print(f"{type(e).__name__} {e}")
    d = None
pause()

if d and d.get("name"):
    # ---------------- Stage C on id 913550 directly ----------------
    print("\n=== C: full shape of id 913550 ===")
    print("name:", d.get("name"), "| ccdata ccode3:", (d.get("ccdata") or {}).get("ccode3"),
          "| selectedSeason:", repr(d.get("selectedSeason")), "| color:", d.get("leagueColor"))
    print("pageUrl:", d.get("pageUrl"), "| tabs:", [t.get("id") for t in (d.get("tabs") or [])])
    t = d.get("table")
    if isinstance(t, list):
        t = t[0]
    if t:
        print("composite:", t.get("composite"), "| tableType:", t.get("tableType"), "| tableBlocks:", len(t.get("tables", [])))
        for tb in (t.get("tables") or [])[:3]:
            rows = tb.get("allMatches") or []
            print("  block:", repr(tb.get("groupName")), "rows:", len(rows))
            for r in rows[:4]:
                print("    ", r.get("team", {}).get("name"), "| rank:", r.get("rank"), "| pts:", r.get("pts"))
    sals = d.get("allAvailableSeasons") or []
    plain = [s for s in sals if "-" not in str(s)]
    slash = [s for s in sals if "/" in str(s) and "-" not in str(s)]
    suffixed = [s for s in sals if "-" in str(s)]
    print("seasons:", len(sals), "| plain:", len(plain), "| slash:", len(slash), "| suffixed:", len(suffixed), "| sample:", [str(s) for s in sals[:8]])
    print("playoff:", "PRESENT" if d.get("playoff") else "absent")
    if d.get("playoff"):
        po = d["playoff"]
        print("  playoff type:", type(po).__name__, "| top keys:", list(po.keys())[:8] if isinstance(po, dict) else str(po)[:120])
    print("titleHistory:", "PRESENT" if d.get("titleHistory") else "absent")
    tr = d.get("transfers") or {}
    print("transfers.data:", "REAL" if tr.get("data") else "absent", "| first:", json.dumps((tr.get("data") or [{}])[0], ensure_ascii=False)[:160])
    st = d.get("stats") or {}
    print("stats:", "present" if st else "absent", "| keys:", list(st.keys())[:5])
    print("fixtures.allMatches:", len(((d.get("fixtures") or {}).get("allMatches")) or []))
    print("titleHolder:", d.get("titleHolder"))
else:
    # ---------------- Stage B: witness match -> the 141 crack ----------------
    print("\n=== B: day-feed witness -> 141 crack ===")
    # today in the site's own timezone; try 20261104 then neighbours
    day = None
    for date in ["20261104", "20261105", "20261103"]:
        try:
            md = get(f"https://www.fotmob.com/api/data/matches?date={date}&lang=en")
        except Exception as e:
            print(f"{date}: {type(e).__name__} {e}")
            continue
        leagues = (md.get("leagues") or [])
        for lg in leagues:
            if lg.get("leagueId") == 913550 or (lg.get("name") == "MLS"):
                matches = (lg.get("matches") or [])
                if matches:
                    day = (date, lg, matches)
                    break
        if day:
            break
        pause()
    if not day:
        print("no MLS match found in the three-day window day feed")
    else:
        date, lg, matches = day
        print("day:", date, "| leagueId:", lg.get("leagueId"), "| parentLeagueId:", lg.get("parentLeagueId"),
              "| ccode:", lg.get("ccode"), "| name:", repr(lg.get("name")), "| matches:", len(matches))
        m0 = matches[0]
        print("witness match:", m0.get("id"), m0.get("home", {}).get("name"), "vs", m0.get("away", {}).get("name"))
        pause()
        det = get(f"https://www.fotmob.com/api/matchDetails?matchId={m0.get('id')}&lang=en")
        info = ((det.get("content") or {}).get("matchFacts") or {}).get("infoBox") or {}
        tour = info.get("Tournament") or {}
        print("141 crack: Tournament.name:", repr(tour.get("name")),
              "| parentLeagueId:", tour.get("parentLeagueId"),
              "| leagueId:", tour.get("leagueId"), "| linkage:", tour.get("linkage"))
        pause()
        real = tour.get("parentLeagueId")
        if real and real != 913550:
            print(f"\n=== C: full shape of the REAL page id {real} ===")
            cc = tour.get("countryCode") or "USA"
            dd = get(f"https://www.fotmob.com/api/data/leagues?id={real}&ccode3={cc}&lang=en")
            print("name:", dd.get("name"), "| ccdata ccode3:", (dd.get("ccdata") or {}).get("ccode3"),
                  "| selectedSeason:", repr(dd.get("selectedSeason")), "| color:", dd.get("leagueColor"))
            print("pageUrl:", dd.get("pageUrl"), "| tabs:", [t.get("id") for t in (dd.get("tabs") or [])])
            t = dd.get("table")
            if isinstance(t, list):
                t = t[0]
            if t:
                print("composite:", t.get("composite"), "| tableType:", t.get("tableType"), "| tableBlocks:", len(t.get("tables", [])))
                for tb in (t.get("tables") or [])[:3]:
                    rows = tb.get("allMatches") or []
                    print("  block:", repr(tb.get("groupName")), "rows:", len(rows))
                    for r in rows[:4]:
                        print("    ", r.get("team", {}).get("name"), "| rank:", r.get("rank"), "| pts:", r.get("pts"))
            sals = dd.get("allAvailableSeasons") or []
            plain = [s for s in sals if "-" not in str(s)]
            slash = [s for s in sals if "/" in str(s) and "-" not in str(s)]
            suffixed = [s for s in sals if "-" in str(s)]
            print("seasons:", len(sals), "| plain:", len(plain), "| slash:", len(slash), "| suffixed:", len(suffixed), "| sample:", [str(s) for s in sals[:8]])
            print("playoff:", "PRESENT" if dd.get("playoff") else "absent")
            print("titleHistory:", "PRESENT" if dd.get("titleHistory") else "absent")
            tr = dd.get("transfers") or {}
            print("transfers.data:", "REAL" if tr.get("data") else "absent", "| first:", json.dumps((tr.get("data") or [{}])[0], ensure_ascii=False)[:160])
            st = dd.get("stats") or {}
            print("stats:", "present" if st else "absent", "| keys:", list(st.keys())[:5])
            print("fixtures.allMatches:", len(((dd.get("fixtures") or {}).get("allMatches")) or []))
            print("titleHolder:", dd.get("titleHolder"))

# ---------------- Stage D: ESPN slug candidates ----------------
print("\n=== D: ESPN slug probe (the 474/479 rule: rides ONLY on 200 + content verification) ===")
time.sleep(PACE)
for slug in ["mls.1", "usa.1", "usa.mls"]:
    try:
        dd = get(f"https://site.api.espn.com/apis/v2/sports/soccer/{slug}/league")
        name = dd.get("name") or (dd.get("leagues") or [{}])[0].get("name")
        abbr = (dd.get("leagues") or [{}])[0].get("abbreviation")
        print(f"{slug}: 200 name={name!r} abbr={abbr!r}")
        ev = get(f"https://site.api.espn.com/apis/v2/sports/soccer/{slug}/scoreboard")
        events = ev.get("events") or []
        teams = []
        for e in events[:6]:
            for c in (e.get("competitions") or [{}])[0].get("competitors", []):
                teams.append(c.get("team", {}).get("displayName"))
        print(f"   events={len(events)} sampleTeams={teams[:8]}")
    except Exception as e:
        print(f"{slug}: {type(e).__name__} {str(e)[:120]}")
    time.sleep(PACE)
