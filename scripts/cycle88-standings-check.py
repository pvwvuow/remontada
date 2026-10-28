#!/usr/bin/env python3
# cycle-88 bug-hunt: cross-check app /api/standings vs live FotMob league payload
# — exact app URL (id + ccode3 + lang=en) and correct fotmobIds from src/lib/leagues.ts
import json, urllib.request

BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"}

LEAGUES = (
    ("pl", 47, "ENG"), ("laliga", 87, "ESP"), ("seriea", 55, "ITA"),
    ("bundesliga", 54, "GER"), ("ligue1", 53, "FRA"), ("persiangulf", 1000001715, "IRN"),
)

def live_rows(lid, ccode3):
    url = f"https://www.fotmob.com/api/data/leagues?id={lid}&ccode3={ccode3}&lang=en"
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        d = json.load(r)
    t = d["table"][0]["data"]["table"]
    # shape varies: list-of-groups vs plain dict — handle both like the mapper
    if isinstance(t, list) and t:
        t = t[0]
    return t["all"] if isinstance(t, dict) else []

def app_rows(slug):
    with urllib.request.urlopen(f"{BASE}/api/standings?league={slug}", timeout=30) as r:
        return json.load(r)["rows"]

issues = []
total_cmp = 0
for slug, lid, cc in LEAGUES:
    try:
        lr = live_rows(lid, cc)
        ar = app_rows(slug)
        n = min(len(lr), len(ar))
        mismatch = 0
        for i in range(n):
            l, a = lr[i], ar[i]
            gf, ga = (l.get("scoresStr") or "0-0").split("-")[0:2]
            exp = (l.get("name"), l.get("pts"), l.get("played"), int(gf or 0), int(ga or 0))
            got = (a.get("name"), a.get("pts"), a.get("played"), a.get("goalsFor"), a.get("goalsAgainst"))
            if exp != got:
                issues.append(f"{slug} row {i+1}: live {exp} vs app {got}")
                mismatch += 1
        total_cmp += n
        status = "OK" if mismatch == 0 and len(lr) == len(ar) and n > 0 else f"CHECK (mismatch={mismatch}, live={len(lr)}, app={len(ar)})"
        print(f"== {slug}: compared {n} rows → {status}")
    except Exception as e:
        issues.append(f"{slug}: EXC {type(e).__name__} {e}")
        print(f"== {slug}: EXC {type(e).__name__} {e}")

print()
print(f"total rows compared: {total_cmp}")
if issues:
    print(f"ISSUES ({len(issues)}):")
    for i in issues[:15]:
        print(" -", i)
else:
    print("STANDINGS ALL PASS — app matches live truth (6 leagues)")
