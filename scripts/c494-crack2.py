# -*- coding: utf-8 -*-
# cycle-494 stage B3: the team-route crack — search a known MLS club, open
# its team page (the app's own api/data/teams shape) and read the recent
# rows' leagueId + parentLeagueId (the REAL page id, the 479 matchDetails
# crack's team-route equivalent — the 141-crack family).
import json, time, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8", "replace"))

# 1) search the club
s = get("https://www.fotmob.com/api/data/search?lang=en&term=Inter%20Miami")
results = (s.get("results") or [])
team = None
for blk in results:
    if blk.get("type") == "team":
        for t in (blk.get("results") or []):
            if "Inter Miami" in (t.get("name") or ""):
                team = t
                break
    if team:
        break
print("search hit:", team and (team.get("id"), team.get("name"), team.get("ccode") or team.get("countryCode")))
time.sleep(1.8)

if not team:
    # dump the search block types for diagnosis
    for blk in results:
        print("block type:", blk.get("type"), "n:", len(blk.get("results") or []))
else:
    tid = team.get("id")
    tcc = team.get("ccode") or team.get("countryCode") or "USA"
    tp = get(f"https://www.fotmob.com/api/data/teams?id={tid}&ccode3={tcc}&lang=en")
    print("team page name:", tp.get("name"), "| ccode:", (tp.get("ccdata") or {}).get("ccode3"))
    # find recent / fixtures rows carrying league info
    fx = tp.get("fixtures") or {}
    rows = []
    for k in ("recent", "next"):
        for r in (fx.get(k) or []):
            rows.append(r)
    print("fixture rows:", len(rows))
    seen = set()
    for r in rows:
        lid = r.get("leagueId") or r.get("league", {}).get("id")
        plid = r.get("parentLeagueId") or r.get("league", {}).get("parentLeagueId")
        lname = r.get("leagueName") or r.get("league", {}).get("name")
        cc = r.get("ccode") or r.get("league", {}).get("ccode")
        key = (lid, plid, lname, cc)
        if key not in seen:
            seen.add(key)
            print("  row league:", key)
    time.sleep(1.8)
    # any parentLeagueId != 913550 -> probe that page
    plids = {(r.get("parentLeagueId") or r.get("league", {}).get("parentLeagueId")) for r in rows}
    plids.discard(None)
    for plid in sorted(plids):
        if plid == 913550:
            continue
        cc = tcc
        print(f"\n=== C: full shape of the REAL page id {plid} (ccode3={cc}) ===")
        dd = get(f"https://www.fotmob.com/api/data/leagues?id={plid}&ccode3={cc}&lang=en")
        if dd.get("name") is None:
            print("  -> literal null; trying ccode3 variants")
            for cc2 in ["USA", "MLS", "INT"]:
                time.sleep(1.8)
                try:
                    dd = get(f"https://www.fotmob.com/api/data/leagues?id={plid}&ccode3={cc2}&lang=en")
                except Exception as e:
                    print(f"  {cc2}: {type(e).__name__} {str(e)[:80]}")
                    continue
                if dd.get("name") is not None:
                    print(f"  ccode3={cc2} works")
                    break
        if dd.get("name") is None:
            print("  still null — abort this id")
            continue
        print("name:", dd.get("name"), "| ccdata ccode3:", (dd.get("ccdata") or {}).get("ccode3"),
              "| selectedSeason:", repr(dd.get("selectedSeason")), "| color:", dd.get("leagueColor"))
        print("pageUrl:", dd.get("pageUrl"), "| tabs:", [t.get("id") for t in (dd.get("tabs") or [])])
        t = dd.get("table")
        if isinstance(t, list):
            t = t[0]
        if t:
            print("composite:", t.get("composite"), "| tableType:", t.get("tableType"), "| tableBlocks:", len(t.get("tables", [])))
            for tb in (t.get("tables") or [])[:3]:
                rows2 = tb.get("allMatches") or []
                print("  block:", repr(tb.get("groupName")), "rows:", len(rows2))
                for r in rows2[:4]:
                    print("    ", r.get("team", {}).get("name"), "| rank:", r.get("rank"), "| pts:", r.get("pts"))
        sals = dd.get("allAvailableSeasons") or []
        plain = [x for x in sals if "-" not in str(x)]
        slash = [x for x in sals if "/" in str(x) and "-" not in str(x)]
        suffixed = [x for x in sals if "-" in str(x)]
        print("seasons:", len(sals), "| plain:", len(plain), "| slash:", len(slash), "| suffixed:", len(suffixed), "| sample:", [str(x) for x in sals[:8]])
        print("playoff:", "PRESENT" if dd.get("playoff") else "absent")
        if dd.get("playoff"):
            po = dd["playoff"]
            print("  playoff keys:", list(po.keys())[:8] if isinstance(po, dict) else str(po)[:120])
            if isinstance(po, dict):
                print("  playoff sample:", json.dumps(po, ensure_ascii=False)[:300])
        print("titleHistory:", "PRESENT" if dd.get("titleHistory") else "absent")
        tr = dd.get("transfers") or {}
        print("transfers.data:", "REAL" if tr.get("data") else "absent", "| first:", json.dumps((tr.get("data") or [{}])[0], ensure_ascii=False)[:160])
        st = dd.get("stats") or {}
        print("stats:", "present" if st else "absent", "| keys:", list(st.keys())[:5])
        print("fixtures.allMatches:", len(((dd.get("fixtures") or {}).get("allMatches")) or []))
        print("titleHolder:", dd.get("titleHolder"))
