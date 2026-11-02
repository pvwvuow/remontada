#!/usr/bin/env python3
# cycle-430 harvest probe: the 426 card's documented «harvest machine» —
# sweep the day-feed ±7 window and rank the honest-raw TEAM names by
# frequency, carrying league + country identity context per name so every
# TEAM_FA candidate is probed, not guessed (the 389 rule: identity first).
import json
import re
import subprocess
import sys

BASE = "http://localhost:3000"
DATES = [str(o) for o in range(-7, 8)]
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def is_leak(s: str) -> bool:
    return bool(s) and not PERSIAN.search(s)


def fetch(url: str):
    out = subprocess.run(
        ["curl", "-s", "--max-time", "40", "-A", UA, url],
        capture_output=True, text=True, timeout=60,
    ).stdout
    return json.loads(out)


def main() -> int:
    leaks = {}  # rawName -> {count, leagues: {league: ccode}, days, sampleId}
    total = 0
    for d in DATES:
        try:
            payload = fetch(f"{BASE}/api/matches?offset={d}")
        except Exception:
            continue
        for g in payload.get("groups", []):
            lg = g.get("leagueName") or ""
            cc = g.get("ccode") or ""
            for m in g.get("matches", []):
                total += 1
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    name = t.get("fa") or t.get("name") or ""
                    if is_leak(name):
                        e = leaks.setdefault(
                            name, {"count": 0, "leagues": {}, "sampleId": m.get("id"), "sampleDate": payload.get("date")}
                        )
                        e["count"] += 1
                        e["leagues"][lg] = cc
    ranked = sorted(leaks.items(), key=lambda kv: -kv[1]["count"])
    print(json.dumps({
        "totalRows": total,
        "distinct": len(leaks),
        "top": [
            {
                "name": n,
                "count": e["count"],
                "leagues": [{"lg": lg, "cc": cc} for lg, cc in sorted(e["leagues"].items())][:4],
                "sampleId": e["sampleId"],
                "sampleDate": e["sampleDate"],
            }
            for n, e in ranked[:90]
        ],
    }, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
