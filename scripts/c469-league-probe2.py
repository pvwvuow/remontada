#!/usr/bin/env python3
# cycle-469 probe 2: the three day-ids answered NULL as league pages (the
# 936417/938423/953430/890103/894789 subclass) — resolve the REAL page ids
# via the cycle-141 crack: matchDetails content.matchFacts.infoBox.Tournament.
# parentLeagueId, then probe each resolved id as a league page (the app's OWN
# fetch shape) and dump the full feed-shape evidence for the catalog entry.
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

CANDIDATES = [
    ("EST", "1000001181", "1000007987", "Premium liiga"),
    ("HON", "941508",     "6365900",    "Liga Nacional - Apertura"),
    ("PAN", "941168",     "5954363",    "LPF Apertura"),
]

results = []
for cc, dayid, sample, feedname in CANDIDATES:
    print(f"##### {cc} day-id={dayid} feed-name={feedname!r} sample-match={sample}")
    code, body = fetch(f"https://www.fotmob.com/api/data/matchDetails?matchId={sample}")
    print(f"  matchDetails -> HTTP {code} bytes={len(body)}")
    parent = None
    try:
        d = json.loads(body)
        info = (((d.get("content") or {}).get("matchFacts") or {}).get("infoBox")) or {}
        tournaments = info.get("Tournament")
        print(f"  infoBox.Tournament = {json.dumps(tournaments, ensure_ascii=False)[:400]}")
        if isinstance(tournaments, dict):
            parent = tournaments.get("parentLeagueId")
        elif isinstance(tournaments, list) and tournaments:
            parent = tournaments[0].get("parentLeagueId")
    except Exception as e:
        print(f"  parse fail: {e}; head={body[:150]!r}")
    print(f"  parentLeagueId = {parent}")
    if not parent:
        results.append({"cc": cc, "dayId": dayid, "parentId": None})
        continue
    # now the REAL page probe (the app's own fetch shape)
    code, body = fetch(f"https://www.fotmob.com/api/data/leagues?id={parent}&ccode3={cc}&lang=en")
    print(f"  PAGE probe id={parent} ccode3={cc} -> HTTP {code} bytes={len(body)}")
    rec = {"cc": cc, "dayId": dayid, "parentId": parent, "http": code}
    try:
        d = json.loads(body)
        if d and isinstance(d, dict):
            det = d.get("details") or {}
            ov = d.get("overview") or {}
            tables = d.get("table") or []
            seasons = d.get("allAvailableSeasons") or []
            th = d.get("titleHistory") or []
            tr = d.get("transfers")
            po = d.get("playoff")
            st = d.get("stats") or {}
            nrows = 0; comp = None; tbl0 = None
            if isinstance(tables, list) and tables:
                tdata = tables[0].get("data") or {}
                comp = tdata.get("composite")
                allr = tdata.get("all") or []
                if allr and isinstance(allr[0], dict) and "data" in allr[0]:
                    tbl0 = allr[0]
                elif tdata.get("table") and isinstance(tdata.get("table"), list):
                    tbl0 = tdata["table"][0]
                if isinstance(tbl0, dict):
                    nrows = len(tbl0.get("data", {}).get("table") or tbl0.get("data", {}).get("all") or [])
            print(f"    details.name={det.get('name')!r} color={det.get('leagueColor')!r} "
                  f"country={(det.get('country') or {}).get('name')!r}")
            print(f"    tabs={[t.get('id') for t in (det.get('tabs') or [])]}")
            print(f"    tableBlocks={len(tables)} composite={comp} rowsTable0={nrows}")
            print(f"    seasons={len(seasons)} names={[ (s.get('name') if isinstance(s,dict) else s) for s in seasons[:4]]}")
            print(f"    selectedSeason={ov.get('selectedSeason')!r}")
            print(f"    titleHistory={len(th)} transfersData={'null' if tr is None or tr.get('data') is None else tr.get('data')} "
                  f"playoff={'null' if po is None else type(po).__name__} statsKeys={len(st)} hasTotw={det.get('hasTotw')!r}")
            rec.update({"name": det.get("name"), "color": det.get("leagueColor"),
                        "rows": nrows, "nTables": len(tables), "composite": comp,
                        "seasons": len(seasons),
                        "seasonNames": [(s.get('name') if isinstance(s, dict) else s) for s in seasons[:4]],
                        "selected": ov.get("selectedSeason"), "titles": len(th),
                        "transfers": (tr or {}).get("data"), "playoff": po is not None,
                        "statsKeys": len(st), "hasTotw": det.get("hasTotw")})
            rec["raw"] = {k: d.get(k) for k in ("table",)}
            rec["seasonsFull"] = seasons
        else:
            print(f"    NULL payload: {body[:120]!r}")
            rec["null"] = True
    except Exception as e:
        print(f"    parse fail: {e}")
        rec["null"] = True
    results.append(rec)

json.dump(results, open("/tmp/c469-probe2.json", "w"), ensure_ascii=False, indent=1)
print("saved -> /tmp/c469-probe2.json")
sys.exit(0)
