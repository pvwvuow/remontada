#!/usr/bin/env python3
# cycle-185 D5 probe — historical card files feasibility + pins (observed
# bytes BEFORE gates). Probes the season-scoped league raw for three leagues
# and dumps the card categories' fetchAllUrl + top rows.
import json, urllib.request, urllib.error

UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"}

def get(url):
    req = urllib.request.Request(url, headers=UA)
    return urllib.request.urlopen(req, timeout=30)

LEAGUES = {"pl": (47, "ENG"), "belgium": (40, "BEL"), "mas": (8985, "MAS")}

for key, (fid, ccode) in LEAGUES.items():
    for season in ("2024/2025", "2023/2024"):
        try:
            raw = json.load(get(
                f"https://www.fotmob.com/api/data/leagues?id={fid}&ccode3={ccode}&lang=en&season={urllib.parse.quote(season, safe='')}"
            ))
        except Exception as e:
            print(f"{key} {season}: RAW FAIL {e!r}")
            continue
        cats = (raw.get("stats", {}).get("players") or [])
        for c in cats:
            h = (c.get("header") or "").lower()
            if "card" in h:
                url = c.get("fetchAllUrl")
                kind = "yellow" if "yellow" in h else "red"
                if not url:
                    print(f"{key} {season} {kind}: category present, fetchAllUrl NONE")
                    continue
                try:
                    data = json.load(get(url))
                    rows = (data.get("TopLists") or [{}])[0].get("StatList") or []
                    r0 = rows[0] if rows else {}
                    pid = r0.get("ParticiantId") or r0.get("ParticipantId")
                    print(f"{key} {season} {kind}: rows={len(rows)} top={r0.get('ParticipantName')!r} "
                          f"team={r0.get('TeamName')!r} value={r0.get('StatValue')} pid={pid}")
                except Exception as e:
                    print(f"{key} {season} {kind}: FILE FAIL {e!r} url={url[:80]}")
print("PROBE DONE")
