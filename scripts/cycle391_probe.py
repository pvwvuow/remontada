#!/usr/bin/env python3
# cycle-391 probe — harvest venue name+city for the six flagship league
# rosters via OUR cached /api/team-venue route (the same data/teams payload
# the UI renders). Output: unique byte-exact (name, city) pairs the VENUE_FA
# / VENUE_CITY_FA maps will be built from. Keys are NEVER retyped from memory
# (the 387 lesson) — this script is the byte-exact source.
import json
import subprocess
import sys

LEAGUES = ["persiangulf", "pl", "laliga", "seriea", "bundesliga", "ligue1"]
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")


def curl_json(url: str, timeout: int = 40):
    try:
        out = subprocess.run(
            ["curl", "-s", "-A", UA, url, "--max-time", str(timeout)],
            capture_output=True, text=True, timeout=timeout + 5,
        )
        if out.returncode != 0 or not out.stdout.strip():
            return None
        return json.loads(out.stdout)
    except Exception:
        return None


def main() -> int:
    teams: dict[int, dict] = {}
    for lg in LEAGUES:
        d = curl_json(f"http://localhost:3000/api/standings?league={lg}")
        rows = (d or {}).get("rows") or []
        print(f"{lg}: {len(rows)} rows", flush=True)
        for r in rows:
            tid = r.get("teamId")
            if tid:
                teams[int(tid)] = {"name": r.get("name"), "fa": r.get("fa"), "league": lg}

    print(f"total teams: {len(teams)}", flush=True)
    venues: list[dict] = []
    for i, (tid, meta) in enumerate(sorted(teams.items()), 1):
        v = curl_json(f"http://localhost:3000/api/team-venue/{tid}", timeout=45)
        venue = (v or {}).get("venue") or {}
        if venue.get("name"):
            venues.append({
                "teamId": tid,
                "team": meta["name"],
                "teamFa": meta["fa"],
                "league": meta["league"],
                "venue": venue.get("name"),
                "city": venue.get("city"),
            })
        if i % 20 == 0:
            print(f"  ...{i}/{len(teams)}", flush=True)

    uniq = {}
    for x in venues:
        key = (x["venue"], x["city"])
        uniq.setdefault(key, []).append(x["team"])

    out = {
        "probedTeams": len(teams),
        "teamsWithVenue": len(venues),
        "uniqueVenues": len(uniq),
        "venues": [
            {"venue": k[0], "city": k[1], "teams": v}
            for k, v in sorted(uniq.items())
        ],
    }
    with open("/home/z/my-project/remontada/scripts/cycle391-venues.json", "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(f"UNIQUE VENUES: {len(uniq)} (teams with venue: {len(venues)}/{len(teams)})", flush=True)
    for k in sorted(uniq):
        print(f"{k[0]!r} | {k[1]!r} | teams={len(uniq[k])}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
