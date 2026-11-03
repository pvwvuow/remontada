#!/usr/bin/env python3
# cycle-469 probe 3: full defensive dump of the three REAL league pages
# (EST 248 / HON 337 / PAN 9039) — every field the catalog entry + the
# comment evidence needs: table shape, season names (slash vs plain-year
# vs suffixed — the plainYearSeasons decision), titleHistory, transfers,
# playoff, stats, hasTotw, leagueColor, selectedSeason.
import json, subprocess, sys

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

def fetch(url):
    r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "40", "-A", UA, url],
                       capture_output=True, text=True, timeout=60)
    return r.stdout

for lid, cc, tag in (("248", "EST", "estonia"), ("337", "HON", "honduras"), ("9039", "PAN", "panama")):
    body = fetch(f"https://www.fotmob.com/api/data/leagues?id={lid}&ccode3={cc}&lang=en")
    d = json.loads(body)
    open(f"/tmp/c469-page-{cc}.json", "w").write(body)
    det = d.get("details") or {}
    ov = d.get("overview") or {}
    print(f"##### {tag} id={lid} ccode3={cc} bytes={len(body)}")
    print(f"  topKeys={sorted(d.keys())}")
    print(f"  details.name={det.get('name')!r} color={det.get('leagueColor')!r} "
          f"country={det.get('country')!r} hasTotw={det.get('hasTotw')!r}")
    print(f"  tabs={[t.get('id') if isinstance(t, dict) else t for t in (det.get('tabs') or [])]}")
    tables = d.get("table") or []
    print(f"  tableBlocks={len(tables)}")
    if tables:
        t0 = tables[0] if isinstance(tables[0], dict) else {}
        tdata = t0.get("data") or {}
        print(f"  block0 keys={sorted(tdata.keys())} composite={tdata.get('composite')!r} "
              f"selectedSeason={tdata.get('selectedSeason')!r} ongoing={tdata.get('ongoing')!r}")
        tb = tdata.get("table")
        rows = None
        if isinstance(tb, dict) and isinstance(tb.get("all"), list):
            rows = tb["all"]                      # the flat domestic shape
        elif isinstance(tb, list) and tb and isinstance(tb[0], dict):
            rows = tb[0].get("data", {}).get("table") or []
        elif isinstance(tb, list):
            rows = tb
        if rows:
            print(f"  table.all rows={len(rows)}")
            r0 = rows[0] if isinstance(rows[0], dict) else {}
            print(f"  row0={json.dumps({k: r0.get(k) for k in ('name','shortName','pts','idx','played')}, ensure_ascii=False)[:220]}")
            if rows[-1] is not None and isinstance(rows[-1], dict):
                print(f"  rowN={json.dumps({k: rows[-1].get(k) for k in ('name','pts')}, ensure_ascii=False)[:140]}")
    seasons = d.get("allAvailableSeasons") or []
    names = [(s.get("name") if isinstance(s, dict) else s) for s in seasons]
    print(f"  seasons={len(seasons)} names={names}")
    print(f"  selectedSeason={ov.get('selectedSeason')!r}")
    th = d.get("titleHistory") or []
    print(f"  titleHistory={len(th)}")
    if th and isinstance(th, list):
        e0 = th[0]
        if isinstance(e0, dict):
            print(f"  title0={json.dumps({k: e0.get(k) for k in ('season','titlePlaceholder')}, ensure_ascii=False)[:200]}")
    tr = d.get("transfers")
    print(f"  transfers={'ABSENT' if tr is None else tr.get('data')}")
    po = d.get("playoff")
    print(f"  playoff={'null' if po is None else type(po).__name__}")
    st = d.get("stats") or {}
    cats = st.get("categories") if isinstance(st, dict) else None
    print(f"  statsKeys={sorted(st.keys()) if isinstance(st, dict) else '-'} "
          f"categories={len(cats) if isinstance(cats, list) else cats!r}")
    fx = d.get("fixtures") or {}
    if fx:
        am = fx.get("allMatches") or []
        print(f"  fixtures.allMatches={len(am)}")
print("saved raw pages -> /tmp/c469-page-{EST,HON,PAN}.json")
sys.exit(0)
