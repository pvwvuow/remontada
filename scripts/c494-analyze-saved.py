# -*- coding: utf-8 -*-
# cycle-494: analyze the SAVED MLS league-page payload (/tmp/c494-raw-body.txt,
# 1.3MB, the app's own fetch shape ?id=130&ccode3=USA&lang=en) — zero extra
# upstream requests. The registration facts table.
import json

with open("/tmp/c494-raw-body.txt") as f:
    d = json.load(f)

det = d.get("details") or {}
print("details.name:", repr(det.get("name")), "| shortName:", repr(det.get("shortName")),
      "| country:", repr(det.get("country")), "| selectedSeason:", repr(det.get("selectedSeason")),
      "| latestSeason:", repr(det.get("latestSeason")))
print("top-level keys:", sorted(d.keys()))
print("pageUrl:", repr(d.get("pageUrl")), "| leagueColor:", repr(d.get("leagueColor")))
print("tabs:", [t if isinstance(t, str) else t.get("id") for t in (d.get("tabs") or [])])
sals = d.get("allAvailableSeasons") or []
plain = [x for x in sals if "-" not in str(x) and "/" not in str(x)]
slash = [x for x in sals if "/" in str(x)]
suffixed = [x for x in sals if "-" in str(x)]
print(f"allAvailableSeasons: n={len(sals)} plain={len(plain)} slash={len(slash)} suffixed={len(suffixed)} head={[str(x) for x in sals[:5]]}")

tb = d.get("table") or []
if isinstance(tb, list) and tb:
    data = tb[0].get("data") or {}
    tables = data.get("tables") or []
    tflat = data.get("table")
    print(f"\ntable[0]: composite={data.get('composite')} tableType={tb[0].get('tableType')!r} "
          f"leagueId={data.get('leagueId')} blocks={len(tables)} "
          f"flatAll={len((tflat or {}).get('all') or []) if isinstance(tflat, dict) else '-'}")
    for c in tables:
        t2 = c.get("table") or {}
        rows = t2.get("all") or []
        print(f"  sub leagueName={c.get('leagueName')!r} leagueId={c.get('leagueId')} rows={len(rows)}")
        for r in rows[:3]:
            print(f"    {r.get('name')!r} idx={r.get('idx')} pts={r.get('pts')}")

po = d.get("playoff")
print("\nplayoff:", "ABSENT" if not po else ("keys=" + str(sorted(po.keys())) if isinstance(po, dict) else type(po).__name__))
if isinstance(po, dict):
    print("playoff sample:", json.dumps(po, ensure_ascii=False)[:600])
print("titleHistory:", "PRESENT" if d.get("titleHistory") else "absent")
tr = d.get("transfers") or {}
trd = tr.get("data") or []
print(f"transfers.data: n={len(trd)}", "| first:", json.dumps(trd[0], ensure_ascii=False)[:220] if trd else "-")
st = d.get("stats") or {}
print("stats:", "present" if st else "absent", "| groups:", len(st.get("groups") or []))
fx = d.get("fixtures") or {}
am = fx.get("allMatches") or []
print("fixtures.allMatches:", len(am))
if am:
    print("  first:", json.dumps(am[0], ensure_ascii=False)[:220])
    print("  rounds:", sorted({str(a.get("round")) for a in am})[:14])
print("titleHolder:", json.dumps(d.get("titleHolder"), ensure_ascii=False)[:260])
ov = d.get("overview") or {}
print("overview.pageUrl:", repr(ov.get("pageUrl")))
print("overview keys head:", sorted(ov.keys())[:18])
