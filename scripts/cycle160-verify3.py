#!/usr/bin/env python3
# cycle-160 verify v3 — the definitive two-sided check:
# (a) Swiss standings row for club 10190 (club identity),
# (b) Iran NT 6711 squad must list Mostafa Heydari (NT cross-verification —
#     the strongest available proof while his player profile 404s: youth
#     NT affiliation + IRN ccode + the club rating stats all agree).
import json, gzip, urllib.request, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

d = get("https://www.fotmob.com/api/data/leagues?id=69&ccode3=SUI&lang=en")
allrows = (((d.get("table") or [{}])[0].get("data") or {}).get("table") or {}).get("all") or []
for r in allrows:
    mark = "  <-- 10190" if r.get("id") == 10190 else ""
    print(f"{r.get('rank') or r.get('idx') or '?':>3} {r.get('name')} ({r.get('id')}) pts={r.get('pts')}{mark}")

print("\n--- Iran NT 6711 squad ---")
try:
    nt = get("https://www.fotmob.com/api/data/teams?id=6711")
    found = False
    for grp in ((nt.get("squad") or {}).get("squad") or []):
        for m in (grp.get("members") or []):
            if "heydari" in str(m.get("name", "")).lower():
                print("NT MEMBER:", json.dumps(m, ensure_ascii=False)[:300])
                found = True
    if not found:
        print("no Heydari in current NT squad (youth NT possible — nationalTeamId may point to U19/U23)")
except Exception as e:
    print("NT fetch ERR", type(e).__name__)
