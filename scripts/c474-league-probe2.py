# -*- coding: utf-8 -*-
# cycle-474: live day feed -> ARG matches -> the 141 crack (parentLeagueId)
import json, urllib.request, sys, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8", "replace")

for date in sys.argv[1:] or ["20261104", "20261103"]:
    feed = json.loads(get(f"https://www.fotmob.com/api/data/matches?date={date}"))
    leagues = feed.get("leagues", [])
    arg = [lm for lm in leagues if lm.get("ccode3") == "ARG"]
    print(f"== date {date}: ARG feed leagues:", [(lm.get("id"), lm.get("parentLeagueId"), lm.get("name")) for lm in arg])
    for lm in arg:
        mids = [m.get("id") for m in feed.get("matches", {}).get(str(lm.get("id")), [])][:2]
        print("   sample match ids:", mids)
        if lm.get("parentLeagueId") and lm.get("parentLeagueId") != lm.get("id"):
            mids2 = [m["id"] for m in feed.get("matches", {}).get(str(lm["parentLeagueId"]), [])][:2]
            print("   (parent) sample match ids:", mids2)
    if arg:
        # crack every ARG match until matchDetails answers with parentLeagueId
        for m in feed.get("matches", {}).get(str(arg[0].get("id")), [])[:3]:
            try:
                d = json.loads(get(f"https://www.fotmob.com/api/matchDetails?matchId={m['id']}"))
                info = ((d.get("content") or {}).get("matchFacts") or {}).get("infoBox") or {}
                tour = info.get("Tournament") or {}
                print(f"   CRACK match {m['id']}: parentLeagueId={tour.get('parentLeagueId')} name={tour.get('leagueName')!r} round={tour.get('leagueRoundName')!r}")
                time.sleep(1)
            except Exception as e:
                print(f"   match {m['id']} error:", type(e).__name__, e)
        break
