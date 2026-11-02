#!/usr/bin/env python3
# cycle-426 identity probe: for each leaking day-feed competition
# (census key, day-feed leagueId, sample match id) fetch upstream
# matchDetails and harvest the REAL identity (leagueId/leagueName/
# parentLeagueId/countryCode/gender) that grounds the Persian name.
# UA Chrome/124 — the آپدیت rule. Results → scripts/cycle426-identity.json
import json
import re
import subprocess
import sys
import time

BASE_CENSUS = "/home/z/my-project/remontada/scripts/cycle426-census.json"
OUT = "/home/z/my-project/remontada/scripts/cycle426-identity.json"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def match_details(mid: str):
    out = subprocess.run(
        ["curl", "-s", "-o", "/tmp/identity-probe.json", "-w", "%{http_code}",
         "--max-time", "30", "-A", UA, "-H", "Accept: application/json",
         f"https://www.fotmob.com/api/data/matchDetails?matchId={mid}"],
        capture_output=True, text=True, timeout=60).stdout.strip()
    if out != "200":
        return None
    try:
        with open("/tmp/identity-probe.json", encoding="utf-8") as f:
            return json.load(f)
    except Exception:  # noqa: BLE001
        return None


def main() -> int:
    census = json.load(open(BASE_CENSUS, encoding="utf-8"))
    team_leaks = census.get("teamLeaks", {})
    # fallback sample ids per league day-feed name
    alt = {}
    for v in team_leaks.values():
        alt.setdefault(v.get("league") or "", [])
        bucket = alt[v.get("league") or ""]
        if v.get("sampleId") and v["sampleId"] not in bucket:
            bucket.append(v["sampleId"])

    results = []
    for key, v in census["competitionLeaks"].items():
        name, ccode = key.rsplit("|", 1)
        day_id = v.get("leagueId")
        candidates = []
        if v.get("sampleId"):
            candidates.append(str(v["sampleId"]))
        candidates.extend(str(s) for s in alt.get(name, [])[:4]
                          if str(s) not in candidates)
        rec = {"censusKey": key, "dayFeedName": name, "ccode": ccode,
               "dayFeedLeagueId": day_id, "matches": v["matches"]}
        hit = None
        for mid in candidates[:5]:
            d = match_details(mid)
            time.sleep(0.5)
            if not d:
                continue
            g = d.get("general") or {}
            if not g:
                continue
            hit = {
                "sampleMatchId": mid,
                "probeLeagueId": g.get("leagueId"),
                "probeLeagueName": g.get("leagueName"),
                "parentLeagueId": g.get("parentLeagueId"),
                "countryCode": g.get("countryCode"),
                "gender": g.get("gender"),
                "matchName": g.get("matchName"),
                "round": g.get("leagueRoundName"),
            }
            break
        rec["identity"] = hit or {"probeFailed": True, "tried": candidates[:5]}
        results.append(rec)

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=1)
    for r in results:
        i = r["identity"]
        if i.get("probeFailed"):
            print(f"FAIL {r['dayFeedName']!r} id={r['dayFeedLeagueId']} tried={i['tried']}")
        else:
            print(f"{r['dayFeedName']!r} id={r['dayFeedLeagueId']} → "
                  f"{i.get('countryCode')}/{i.get('gender')} "
                  f"probeId={i.get('probeLeagueId')} "
                  f"name={i.get('probeLeagueName')!r} "
                  f"parent={i.get('parentLeagueId')} round={i.get('round')!r}")
    ok = sum(1 for r in results if not r["identity"].get("probeFailed"))
    print(f"probed {ok}/{len(results)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
