#!/usr/bin/env python3
# cycle-160 swiss v3 — (a) dump ALL seasons[] entries (title-history
# semantics: winner/loser), (b) archived-season payload raw shape
# (table blocks / composite / keys) for 2025/2026 and 2023/2024.
import json, gzip, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

d = get("https://www.fotmob.com/api/data/leagues?id=69&ccode3=SUI&lang=en")
seas = d.get("seasons") or []
print(f"seasons[] length = {len(seas)}")
for s in seas:
    w = (s.get("winner") or {}).get("name")
    l = (s.get("loser") or {}).get("name")
    print(f"  {s.get('seasonName')}: W={w} L={l}")

print("\ntop-level keys:", list(d.keys()))
hist = d.get("history") or {}
print("history keys:", list(hist.keys()) if isinstance(hist, dict) else type(hist))
if isinstance(hist, dict):
    for k, v in list(hist.items())[:3]:
        print("  history." + k, "->", json.dumps(v, ensure_ascii=False)[:200])

for q in ("2025/2026", "2023/2024"):
    da = get(f"https://www.fotmob.com/api/data/leagues?id=69&ccode3=SUI&lang=en&season={urllib.request.quote(q, safe='')}")
    print(f"\n=== archived {q} ===")
    print("top keys:", list(da.keys()))
    tbl = da.get("table")
    if tbl:
        t0 = tbl[0]
        print("table[0] keys:", list(t0.keys()))
        dt = t0.get("data") or {}
        print("table[0].data keys:", list(dt.keys()))
        tt = dt.get("table")
        if tt is not None:
            print("table[0].data.table type:", type(tt).__name__, "keys:" if isinstance(tt, dict) else "", list(tt.keys()) if isinstance(tt, dict) else f"len={len(tt)}")
    po = da.get("playoff", "absent")
    print("archived playoff:", "null" if po is None else ("absent" if po == "absent" else "obj"))
