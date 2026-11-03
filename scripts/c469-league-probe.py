#!/usr/bin/env python3
# cycle-469 fix probe: the 468 finding's three missing league ids MUST prove
# themselves as REAL fotmob league pages before registration (the 136/376/
# 377/380/381/385 lesson: day-feed ids often answer NULL as a league page).
# Probe = the app's OWN fetch (api/data/leagues?id=X&ccode3=Y&lang=en, UA
# Chrome/124) so the evidence is the exact feed the catalog entry will serve.
import json, subprocess, sys

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

def fetch(url):
    r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "40", "-A", UA,
                        "-w", "\n%{http_code}", url],
                       capture_output=True, text=True, timeout=60)
    body = r.stdout.rsplit("\n", 1)[0]
    code = r.stdout.rsplit("\n", 1)[-1].strip()
    return code, body

def probe_league(lid, cc):
    code, body = fetch(f"https://www.fotmob.com/api/data/leagues?id={lid}&ccode3={cc}&lang=en")
    print(f"=== id={lid} ccode3={cc} -> HTTP {code} bytes={len(body)}")
    try:
        d = json.loads(body)
    except Exception as e:
        print(f"    body not JSON: {body[:120]!r}")
        return None
    if not d or not isinstance(d, dict):
        print(f"    NULL/falsey payload: {body[:120]!r}")
        return None
    det = d.get("details") or {}
    ov = d.get("overview") or {}
    tables = d.get("table") or []
    seasons = d.get("allAvailableSeasons") or []
    th = d.get("titleHistory") or []
    po = d.get("playoff")
    tr = d.get("transfers")
    st = d.get("stats") or {}
    print(f"    top keys: {sorted(d.keys())[:18]}")
    print(f"    details.name={det.get('name')!r} leagueColor={det.get('leagueColor')!r} "
          f"country={ (det.get('country') or {}).get('name') if isinstance(det.get('country'), dict) else det.get('country')!r} "
          f"ccode={(det.get('country') or {}).get('ccode') if isinstance(det.get('country'), dict) else None!r}")
    print(f"    tabs={ [t.get('id') for t in (det.get('tabs') or [])] }")
    if tables:
        t0 = tables[0] if isinstance(tables, list) else {}
        tdata = t0.get("data") or {} if isinstance(t0, dict) else {}
        tlist = tdata.get("table") or []
        comp = tdata.get("composite")
        if tlist and isinstance(tlist, list):
            tbl = tlist[0].get("data", {}).get("table", []) if isinstance(tlist[0], dict) else []
        else:
            tbl = tdata.get("all") or tdata.get("table") or []
        nrows = len(tbl) if isinstance(tbl, list) else 0
        print(f"    table blocks={len(tables)} composite={comp} rows0={nrows} "
              f"sampleRow={ (tbl[0].get('name') if tbl and isinstance(tbl[0], dict) else None)!r }")
    else:
        print(f"    table ABSENT (no-table cup shape)")
    print(f"    seasons={len(seasons)} first3={[s.get('name') if isinstance(s, dict) else s for s in seasons[:3]]}")
    fmt = [s.get('name') if isinstance(s, dict) else str(s) for s in seasons[:2]]
    slash = all('/' in str(x) for x in fmt) if fmt else False
    print(f"    seasonFormat slash={slash} selectedSeason={ov.get('selectedSeason')!r}")
    print(f"    titleHistory={len(th)} transfers={'null' if tr is None or tr.get('data') is None else tr.get('data')} "
          f"playoff={'null' if po is None else type(po).__name__} statsKeys={len(st)} "
          f"hasTotw={det.get('hasTotw')!r}")
    return {"id": lid, "cc": cc, "http": code, "name": det.get("name"),
            "color": det.get("leagueColor"), "rows": len(tables),
            "seasons": len(seasons), "slash": slash, "titles": len(th)}

# ESPN slug candidates (the 361/417 pattern: probe both, 400 -> omit field)
for slug in ("est.1", "estonia.1", "hon.1", "honduras.1", "pan.1", "panama.1"):
    code, body = fetch(f"https://site.api.espn.com/apis/site/v2/sports/soccer/{slug}/scoreboard")
    print(f"ESPN {slug} -> {code}")

out = []
for lid, cc in (("1000001181", "EST"), ("941508", "HON"), ("941168", "PAN")):
    r = probe_league(lid, cc)
    out.append(r or {"id": lid, "cc": cc, "http": "NULL", "name": None})
json.dump(out, open("/tmp/c469-probe.json", "w"), ensure_ascii=False, indent=1)
print("saved -> /tmp/c469-probe.json")
sys.exit(0)
