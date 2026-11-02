#!/usr/bin/env python3
# cycle-426 census: live sweep of the day-feed's own ±7-day window for
# Persian-name leaks — competitions (leagueFa == raw) and teams (home.fa /
# away.fa carrying ASCII letters = honest-raw fallback leaking on the
# portal's most-visible surface). The 417 pattern, fresh surface.
import json
import re
import subprocess
import sys
import time

BASE = "http://localhost:3000"
# /api/matches takes ?offset=N (−7..+7), the cycle-297 clamp — ?date= is the
# day-calendar's language, NOT this route's (first census draft swept one
# day 14× because of that). The root `date` of each response names the day.
DATES = [str(o) for o in range(-7, 8)]
ASCII_LETTER = re.compile(r"[A-Za-z]")
# A leak = NO Persian/Arabic script at all. Designed Persian names may
# carry Latin letters inside («لیگ قهرمانان آسیا ۲ — گروه A», the cycle-157
# convention) — the first draft's [A-Za-z] predicate flagged those as
# leaks. Pure-Latin rendered names are the honest-raw fallback leaking.
PERSIAN = re.compile(r"[\u0600-\u06FF]")


def is_leak(s: str) -> bool:
    return bool(s) and not PERSIAN.search(s)

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def fetch(url: str):
    out = subprocess.run(
        ["curl", "-s", "--max-time", "40", "-A", UA, url],
        capture_output=True, text=True, timeout=60,
    ).stdout
    return json.loads(out)


def main() -> int:
    comp_leaks = {}   # (leagueName, ccode) -> {days, matches, sampleId}
    team_leaks = {}   # rawName -> {count, side, sampleId, date, league}
    day_report = []
    total_rows = 0
    total_comp_rows = 0
    fetch_fail = []

    for d in DATES:
        try:
            payload = fetch(f"{BASE}/api/matches?offset={d}")
        except Exception as e:  # noqa: BLE001
            fetch_fail.append({"offset": d, "err": str(e)[:120]})
            continue
        if not payload.get("ok") or "groups" not in payload:
            fetch_fail.append({"offset": d, "err": "not-ok-or-no-groups"})
            continue
        # the root `date` (YYYYMMDD) names the real day this offset served
        d = payload.get("date") or d
        d_rows = 0
        d_comp_leak = 0
        d_team_leak = 0
        for g in payload["groups"]:
            total_comp_rows += 1
            lfa = g.get("leagueFa") or ""
            lname = g.get("leagueName") or ""
            ccode = g.get("leagueCcode") or ""
            if is_leak(lfa):
                d_comp_leak += len(g.get("matches") or [])
                k = (lname, ccode)
                e = comp_leaks.setdefault(
                    k, {"days": set(), "matches": 0, "sampleId": None,
                        "leagueId": None, "rendered": ""})
                e["days"].add(d)
                e["matches"] += len(g.get("matches") or [])
                if e["leagueId"] is None:
                    e["leagueId"] = g.get("leagueId")
                if not e["rendered"]:
                    e["rendered"] = lfa
                ms = g.get("matches") or []
                if ms and not e["sampleId"]:
                    e["sampleId"] = ms[0].get("id")
            for m in g.get("matches") or []:
                total_rows += 1
                d_rows += 1
                mid = m.get("id")
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    fa = t.get("fa") or ""
                    if is_leak(fa):
                        d_team_leak += 1
                        e = team_leaks.setdefault(fa, {
                            "count": 0, "side": side, "sampleId": mid,
                            "date": d, "league": lname, "ccode": ccode,
                            "raw": t.get("name") or ""})
                        e["count"] += 1
        day_report.append({
            "offset": d, "matches": d_rows,
            "compLeakGroups": sum(
                1 for g in payload["groups"]
                if is_leak(g.get("leagueFa") or "")),
            "compLeakMatches": d_comp_leak,
            "teamLeakRows": d_team_leak,
        })
        time.sleep(0.4)

    for k in comp_leaks:
        comp_leaks[k]["days"] = sorted(comp_leaks[k]["days"])

    result = {
        "window": [DATES[0], DATES[-1]],
        "daysFetched": len(day_report),
        "fetchFail": fetch_fail,
        "totalMatches": total_rows,
        "totalGroups": total_comp_rows,
        "dayReport": day_report,
        "competitionLeaks": {
            f"{n}|{c}": v for (n, c), v in sorted(
                comp_leaks.items(), key=lambda kv: -kv[1]["matches"])},
        "teamLeaks": dict(sorted(
            team_leaks.items(), key=lambda kv: -kv[1]["count"])),
        "summary": {
            "compLeakDistinct": len(comp_leaks),
            "teamLeakDistinct": len(team_leaks),
            "teamLeakRows": sum(v["count"] for v in team_leaks.values()),
        },
    }
    out = "/home/z/my-project/remontada/scripts/cycle426-census.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=1)
    print(json.dumps(result["summary"], ensure_ascii=False))
    print("dayReport:", json.dumps(day_report, ensure_ascii=False))
    print("compLeakDistinct:", len(comp_leaks))
    top = list(result["competitionLeaks"].items())[:25]
    for k, v in top:
        print("COMP:", k, "→", v["matches"], "matches /", len(v["days"]), "days")
    for k, v in list(result["teamLeaks"].items())[:40]:
        print("TEAM:", k, "→", v["count"], "x", v["date"], v["league"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
