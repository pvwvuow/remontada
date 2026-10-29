#!/usr/bin/env python3
# cycle-160 verify v2 — dump the club payload shape (name key?), the full
# member object, and try player endpoint variants for id 2097467.
import json, gzip, urllib.request, urllib.error

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

t = get("https://www.fotmob.com/api/data/teams?id=10190")
print("top keys:", list(t.keys()))
print("name-ish:", {k: t.get(k) for k in ("name", "fullName", "shortName", "cname") if k in t})
print("teamColorCode:", t.get("teamColorCode"), "| type:", t.get("type"))
# find the full member object + club name in nested shapes
for grp in ((t.get("squad") or {}).get("squad") or []):
    for m in (grp.get("members") or []):
        if (m.get("cname") or "").lower() == "iran":
            print("MEMBER FULL:", json.dumps(m, ensure_ascii=False))
# club name often under page.title of the HTML page, or in 'details'
pg = t.get("page") or {}
print("page keys:", list(pg.keys())[:10] if isinstance(pg, dict) else type(pg))

# player endpoint variants
for path in ("https://www.fotmob.com/api/player/2097467",
             "https://www.fotmob.com/api/data/players?id=2097467"):
    try:
        p = get(path)
        print(path, "-> OK keys:", list(p.keys())[:12])
        pl = p.get("player") or {}
        if isinstance(pl, dict):
            print("  player sub-keys:", list(pl.keys())[:20])
            print("  player.info:", json.dumps((pl.get("info") or {}), ensure_ascii=False)[:400])
    except urllib.error.HTTPError as e:
        print(path, "-> HTTP", e.code)
    except Exception as e:
        print(path, "-> ERR", type(e).__name__)
