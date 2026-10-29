#!/usr/bin/env python3
# cycle-160 swiss v2 — top-20 with OUR parser's keys (ParticipantName/
# TeamName/StatValue — FMStatFullRow), titles hunt (recursive), archived
# season table via the app's own season-param convention.
import json, gzip, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

url = "https://data.fotmob.com/stats/69/season/37305/goals.json"
g = get(url)
rl = (g.get("TopLists") or [{}])[0].get("StatList") or []
print("top-20 (ParticipantName | TeamName | StatValue):")
for i, p in enumerate(rl[:20]):
    print(f"{i+1}. {p.get('ParticipantName')} | {p.get('TeamName')} | {p.get('StatValue')} | ccode={p.get('ParticipantCountryCode')}")

d = get("https://www.fotmob.com/api/data/leagues?id=69&ccode3=SUI&lang=en")

def hunt(obj, path=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if "title" in str(k).lower() and not isinstance(v, (str, int, float, bool, type(None))):
                print(f"TITLES-AT {path}.{k} -> len={len(v) if isinstance(v, list) else '?'}")
                if isinstance(v, list) and v:
                    print("   newest:", json.dumps(v[0], ensure_ascii=False)[:200])
                    print("   oldest:", json.dumps(v[-1], ensure_ascii=False)[:200])
            else:
                hunt(v, f"{path}.{k}")
    elif isinstance(obj, list):
        for i, v in enumerate(obj[:2]):
            hunt(v, f"{path}[{i}]")

hunt(d, "root")

# seasons[0] structure
seas = d.get("seasons") or []
if seas:
    print("\nseasons[0] keys:", list(seas[0].keys()))
    print("seasons[0] sample:", json.dumps(seas[0], ensure_ascii=False)[:300])

# archived table via our convention: check src/lib/season.ts format first
try:
    s = open("src/lib/season.ts").read()
    print("\nSEASON-PARAM hints:", [ln.strip() for ln in s.splitlines() if "season" in ln.lower() and "=" in ln][:6])
except Exception as e:
    print("season.ts read ERR", e)

for q in ("2025%2F2026", "2023%2F2024"):
    da = get(f"https://www.fotmob.com/api/data/leagues?id=69&ccode3=SUI&lang=en&season={q}")
    tbl = da.get("table") or []
    rows = (((tbl[0].get("data") or {}).get("table") or {}).get("all") or []) if tbl else []
    top3 = [(r.get("name"), r.get("pts")) for r in rows[:3]] if rows else []
    ntab = len(tbl)
    print(f"archived {q}: table-blocks={ntab} rows={len(rows)} top3={top3}")
