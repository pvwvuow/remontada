# -*- coding: utf-8 -*-
# cycle-494: the team-route crack — /api/data/teams?id=6637 (LA Galaxy, the
# app's own bare shape per fotmob.ts:10028) — dump every league-ish field:
# tableData, fixtures rows, and any parentLeagueId that differs from 130.
import json, subprocess, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
PACE = 1.8

def fetch(url, tries=4):
    for i in range(tries):
        r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "30", "-A", UA, "-w", "\n%{http_code}", url],
                           capture_output=True, text=True)
        body, _, code = r.stdout.rpartition("\n")
        if code == "200":
            try:
                return json.loads(body)
            except Exception as e:
                print(f"  !! JSON parse fail {e}: {body[:120]}")
                return None
        print(f"  !! HTTP {code} try={i+1} — backoff {2*(i+1)}s")
        time.sleep(2 * (i + 1))
    return None

d = fetch("https://www.fotmob.com/api/data/teams?id=6637")
time.sleep(PACE)
if not d:
    print("team fetch failed")
    raise SystemExit(1)

print("top keys:", sorted(d.keys()))
print("name:", d.get("name"), "| ccdata:", json.dumps(d.get("ccdata") or {}, ensure_ascii=False)[:160])
td = d.get("tableData") or {}
print("tableData:", json.dumps(td, ensure_ascii=False)[:400])

fx = d.get("fixtures") or {}
print("\nfixtures keys:", sorted(fx.keys()) if isinstance(fx, dict) else type(fx).__name__)
seen = set()
for k in (["recent", "next", "allMatches"] if isinstance(fx, dict) else []):
    rows = fx.get(k) or []
    print(f"{k}: {len(rows)} rows")
    for r in rows[:40]:
        if not isinstance(r, dict):
            continue
        lid = r.get("leagueId")
        plid = r.get("parentLeagueId")
        lname = r.get("leagueName") or r.get("league", {}).get("name") if isinstance(r.get("league"), dict) else r.get("leagueName")
        cc = r.get("ccode")
        key = (lid, plid, lname, cc)
        if key not in seen:
            seen.add(key)
            print(f"  {k} row league: leagueId={lid} parentLeagueId={plid} name={lname!r} ccode={cc}")
        # also scan nested dicts one level deep for parentLeagueId
        for kk, vv in r.items():
            if isinstance(vv, dict) and "parentLeagueId" in vv:
                k2 = (vv.get("leagueId") or vv.get("id"), vv.get("parentLeagueId"), vv.get("name") or vv.get("leagueName"))
                if k2 not in seen:
                    seen.add(k2)
                    print(f"  {k} nested[{kk}]: {k2}")

# brute scan: find every parentLeagueId occurrence anywhere in the payload
def walk(o, path=""):
    if isinstance(o, dict):
        for k, v in o.items():
            if k in ("parentLeagueId", "leagueId", "primaryId") and isinstance(v, int):
                print(f"  WALK {path}.{k} = {v}")
            walk(v, f"{path}.{k}")
    elif isinstance(o, list):
        for i, v in enumerate(o[:30]):
            walk(v, f"{path}[{i}]")

print("\n=== WALK every id-ish field ===")
walk(d)
