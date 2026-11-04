# -*- coding: utf-8 -*-
# cycle-494: FULL shape read of the warm MLS league page (id=130 ccode3=USA)
# — the app's own fetch shape — raw payload saved for byte-reading.
import json, subprocess, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def fetch(url, tries=6):
    for i in range(tries):
        r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "30", "-A", UA, "-w", "\n%{http_code}", url],
                           capture_output=True, text=True)
        body, _, code = r.stdout.rpartition("\n")
        if code == "200":
            try:
                d = json.loads(body)
            except Exception as e:
                print(f"  !! JSON parse fail {e}")
                d = None
            if d:  # retry on transient literal-null bodies (the 494 edge-cold class)
                return d
            print(f"  !! literal-null body try={i+1} — backoff {3*(i+1)}s")
            time.sleep(3 * (i + 1))
            continue
        print(f"  !! HTTP {code} try={i+1} — backoff {2*(i+1)}s")
        time.sleep(2 * (i + 1))
    return None

d = fetch("https://www.fotmob.com/api/data/leagues?id=130&ccode3=USA&lang=en")
if not d or d.get("name") is None:
    print("PAGE NULL — abort")
    raise SystemExit(1)
with open("/tmp/c494-mls-page.json", "w") as f:
    json.dump(d, f, ensure_ascii=False)
print("saved /tmp/c494-mls-page.json, bytes:", len(json.dumps(d)))

det = d.get("details") or {}
print("details.name:", repr(det.get("name")), "| selectedSeason:", repr(det.get("selectedSeason")), "| latestSeason:", repr(det.get("latestSeason")))
print("top-level name key:", repr(d.get("name")), "| pageUrl:", repr(d.get("pageUrl")), "| leagueColor:", repr(d.get("leagueColor")))
print("tabs:", [t.get("id") if isinstance(t, dict) else t for t in (d.get("tabs") or [])])
sals = d.get("allAvailableSeasons") or []
print("allAvailableSeasons:", len(sals), [str(x) for x in sals[:6]], "…", [str(x) for x in sals[-2:]])
plain = [x for x in sals if "-" not in str(x) and "/" not in str(x)]
print("plain-year:", len(plain), "| slash:", len([x for x in sals if "/" in str(x)]), "| suffixed:", len([x for x in sals if "-" in str(x)]))

tb = d.get("table") or []
if isinstance(tb, list) and tb:
    data = tb[0].get("data") or {}
    tables = data.get("tables") or []
    tflat = data.get("table")
    print("\ntable[0] composite:", data.get("composite"), "| tableType:", tb[0].get("tableType"),
          "| leagueId:", data.get("leagueId"), "| blocks:", len(tables),
          "| flat all rows:", len((tflat or {}).get("all") or []) if isinstance(tflat, dict) else "-")
    for c in tables:
        t2 = c.get("table") or {}
        rows = t2.get("all") or []
        print("  sub-table leagueName:", repr(c.get("leagueName")), "| rows:", len(rows))
        for r in rows[:3]:
            print("    ", r.get("name"), "| idx:", r.get("idx"), "| pts:", r.get("pts"))

po = d.get("playoff")
print("\nplayoff:", "ABSENT" if not po else json.dumps(po, ensure_ascii=False)[:400])
print("titleHistory:", "PRESENT" if d.get("titleHistory") else "absent")
tr = d.get("transfers") or {}
print("transfers.data:", "REAL" if tr.get("data") else "absent", "| n:", len(tr.get("data") or []),
      "| first:", json.dumps((tr.get("data") or [{}])[0], ensure_ascii=False)[:200])
st = d.get("stats") or {}
print("stats:", "present" if st else "absent", "| groups:", len(st.get("groups") or []))
fx = d.get("fixtures") or {}
am = fx.get("allMatches") or []
print("fixtures.allMatches:", len(am), "| first:", json.dumps(am[0], ensure_ascii=False)[:200] if am else "-")
print("titleHolder:", json.dumps(d.get("titleHolder"), ensure_ascii=False)[:200])
ov = d.get("overview") or {}
print("overview.pageUrl:", repr(ov.get("pageUrl")))
th = d.get("tableType")
print("tableType top:", th)
