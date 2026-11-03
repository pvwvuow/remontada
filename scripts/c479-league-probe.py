#!/usr/bin/env python3
# cycle-479 fix probe: the 469 registry head GUA 938628 (Guatemala) — the
# league page shape (the correct endpoint /api/data/leagues per the 474
# lesson), the ±7 feed witnesses + the byte-exact group name, ESPN slug.
import json, subprocess, sys

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "40", "-A", UA, url],
                       capture_output=True, text=True, timeout=60)
    return r.stdout

print("=== 1. the league page 938628 (the correct /api/data/leagues shape) ===")
out = get("https://www.fotmob.com/api/data/leagues?id=938628&ccode3=&lang=en")
print("len:", len(out))
try:
    d = json.loads(out)
    print("keys:", sorted(d.keys())[:24])
    print("name:", d.get("name"))
    ov = d.get("overview") or {}
    print("overview keys:", sorted(ov.keys())[:30])
    print("selectedSeason:", json.dumps(ov.get("selectedSeason"), ensure_ascii=False)[:200])
    # seasons list
    seas = ov.get("seasons") or []
    print("seasons:", len(seas), [s.get("name") for s in seas][:12])
    # table shape
    tb = d.get("table") or []
    print("table type:", type(tb).__name__, "len:", len(tb) if hasattr(tb, "__len__") else "-")
    if isinstance(tb, list) and tb:
        t0 = tb[0]
        print("table[0] keys:", sorted(t0.keys())[:12])
        data = t0.get("data") if isinstance(t0.get("data"), dict) else None
        if data:
            print("table[0].data keys:", sorted(data.keys())[:12])
            tables = data.get("tables") or []
            print("tables:", len(tables))
            for t in tables[:6]:
                nm = t.get("tableName") or t.get("name")
                rows = (t.get("table") or {}).get("all") or []
                print("  table:", nm, "rows:", len(rows), "comp:", (t.get("table") or {}).get("composite"))
                if rows:
                    r0 = rows[0]
                    print("    row0:", json.dumps({k: r0.get(k) for k in ("idx", "name", "pts", "played", "goalConDiff", "id")}, ensure_ascii=False)[:220])
    elif isinstance(tb, dict):
        print("table dict keys:", sorted(tb.keys())[:12])
except Exception as e:
    print("PARSE FAIL:", e, out[:300])

print()
print("=== 2. the ±7 feed: GUA fixtures, group name bytes, witnesses ===")
import time
guadays = {}
for o in range(-7, 8):
    out = get(f"http://localhost:3000/api/matches?offset={o}")
    try:
        d = json.loads(out)
    except Exception:
        continue
    day = d.get("date") or str(o)
    for g in d.get("groups", []):
        nm = (g.get("name") or g.get("leagueName") or "")
        if "gua" in nm.lower() or "national" in nm.lower() or "Liga Nacional" in nm:
            ms = g.get("matches", [])
            guadays.setdefault(day, []).append((nm, len(ms)))
            for m in ms:
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    print(f"  {day} off={o} grp={nm!r} {side}: id={t.get('id')} fa={t.get('fa')!r} name={t.get('name')!r}")
    time.sleep(0.2)
print("GUA group summary:", json.dumps(guadays, ensure_ascii=False)[:800])

print()
print("=== 3. ESPN slug probe (the app's site/v2 shape, the 474 lesson) ===")
import datetime
today = datetime.date(2026, 11, 4)
for slug in ("gua.1", "guatemala.1"):
    ds = (today + datetime.timedelta(days=3)).strftime("%Y%m%d")
    out = get(f"https://site.api.espn.com/apis/site/v2/sports/soccer/{slug}/scoreboard?dates={ds}")
    try:
        d = json.loads(out)
        lg = d.get("leagues") or []
        nm = lg[0].get("name") if lg else None
        evs = d.get("events") or []
        print(f"slug {slug}: HTTP-len {len(out)} leagues={nm} events={len(evs)}")
        for e in evs[:4]:
            print("   event:", e.get("name"), "|", e.get("date"))
    except Exception as e:
        print(f"slug {slug}: FAIL {e} {out[:150]}")
