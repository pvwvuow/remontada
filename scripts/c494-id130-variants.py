# -*- coding: utf-8 -*-
# cycle-494: MLS page-id 130 — request-shape variants (the 489 discipline:
# curl --compressed + UA Chrome/124 + 1.8s pace + backoff). The 474 shape
# (?id=112&ccode3=ARG) answered null for 130; the 489 shape (?id=951803 bare)
# is the alternative read.
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

for tag, url in [
    ("bare id=130", "https://www.fotmob.com/api/data/leagues?id=130"),
    ("empty ccode3", "https://www.fotmob.com/api/data/leagues?id=130&ccode3=&lang=en"),
    ("ccode3=USA", "https://www.fotmob.com/api/data/leagues?id=130&ccode3=USA&lang=en"),
]:
    print(f"\n=== {tag} ===")
    d = fetch(url)
    time.sleep(PACE)
    if d is None:
        print("  -> no JSON / fetch fail")
        continue
    if d.get("name") is None:
        print("  -> literal null body")
        continue
    det = d.get("details") or {}
    print("  name:", repr(d.get("name")), "| details.name:", repr(det.get("name")), "| details.ccode:", det.get("ccode"))
    seas = det.get("seasons") or []
    print("  seasons:", len(seas), [s.get("name") for s in seas[:6]])
    print("  allAvailableSeasons:", len(d.get("allAvailableSeasons") or []), [str(x) for x in (d.get("allAvailableSeasons") or [])[:6]])
    print("  selectedSeason:", json.dumps(d.get("selectedSeason"), ensure_ascii=False)[:160])
    tbl = d.get("table") or []
    if isinstance(tbl, list) and tbl:
        t0 = tbl[0]
        data = t0.get("data") or {}
        tables = data.get("tables") or []
        tt = data.get("table")
        print("  table[0] composite:", data.get("composite") if isinstance(data, dict) else None,
              "| tableType:", t0.get("tableType"), "| blocks:", len(tables),
              "| flat all rows:", len((tt or {}).get("all") or []) if isinstance(tt, dict) else "-")
        for c in tables[:5]:
            rows = ((c.get("table") or {}).get("all")) or []
            print("   block:", repr(c.get("leagueName") or c.get("tableName")), "rows:", len(rows))
    print("  playoff:", "PRESENT" if d.get("playoff") else "absent")
    if d.get("playoff"):
        po = d["playoff"]
        print("   playoff:", json.dumps(po, ensure_ascii=False)[:400])
    print("  titleHistory:", "PRESENT" if d.get("titleHistory") else "absent")
    tr = d.get("transfers") or {}
    print("  transfers.data:", "REAL" if tr.get("data") else "absent")
    print("  stats:", "present" if d.get("stats") else "absent")
    print("  fixtures.allMatches:", len(((d.get("fixtures") or {}).get("allMatches")) or []))
    ov = d.get("overview") or {}
    print("  overview.pageUrl:", ov.get("pageUrl"), "| overview keys head:", sorted(ov.keys())[:14])
    print("  leagueColor:", d.get("leagueColor"))
