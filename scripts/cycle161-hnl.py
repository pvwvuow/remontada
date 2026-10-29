#!/usr/bin/env python3
# cycle-161 deep probe — Croatian HNL integration truth pack:
# (1) the D5 player-level verify for Mohammad Mohebbi (fotmob 1073012,
#     Rijeka) via our own /api/player route, (2) byte-exact club names,
#     (3) top-20 scorer window, (4) titles, (5) ESPN slug, (6) archived
#     season shapes, (7) transfer club names.
import json, gzip, urllib.request, urllib.error

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

# 1) player-level verify (the D5 rule)
try:
    p = get("https://www.fotmob.com/api/player/1073012")
    info = p.get("player") or {}
    info = info.get("info") or info
    print("MOHEBBI:", json.dumps({k: info.get(k) for k in ("name", "country", "position", "dateOfBirth") if k in info}, ensure_ascii=False))
except Exception as e:
    print("player fetch ERR:", type(e).__name__, str(e)[:100])

d = get("https://www.fotmob.com/api/data/leagues?id=252&ccode3=CRO&lang=en")
allrows = (((d.get("table") or [{}])[0].get("data") or {}).get("table") or {}).get("all") or []
print("\nCLUBS:", json.dumps([r.get("name") for r in allrows], ensure_ascii=False))

url = ""
for cat in (d.get("stats") or {}).get("players") or []:
    if isinstance(cat, dict) and "top scorer" in str(cat.get("header", "")).lower():
        url = cat.get("fetchAllUrl") or ""
        print("FETCH-ALL-URL:", url)
        break
if url:
    if url.startswith("//"): url = "https:" + url
    g = get(url)
    rl = ((g.get("TopLists") or [{}])[0].get("StatList")) or []
    print("scorer rows:", len(rl), "| row0 keys:", list(rl[0].keys())[:8] if rl else "-")
    for i, p in enumerate(rl[:20]):
        nm = p.get("ParticipantName") or p.get("name")
        tm = p.get("TeamName") or ""
        sv = p.get("StatValue") or p.get("statValue")
        print(f"{i+1}. {nm} | {tm} | {sv} | ccode={p.get('ParticipantCountryCode') or p.get('countryCode') or '-'}")

seas = d.get("seasons") or []
print("\nseasons[] n:", len(seas))
for s in seas[:3]:
    w = (s.get("winner") or {}).get("name"); l = (s.get("loser") or {}).get("name")
    print(f"  {s.get('seasonName')}: W={w} L={l}")
if len(seas) > 3:
    s = seas[-1]
    print(f"  oldest {s.get('seasonName')}: W={(s.get('winner') or {}).get('name')} L={(s.get('loser') or {}).get('name')}")

for slug in ("cro.1", "croatia.1"):
    try:
        req = urllib.request.Request(f"https://site.api.espn.com/apis/site/v2/sports/soccer/{slug}/scoreboard", headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=15) as r:
            print(f"ESPN {slug} -> {r.status}")
        break
    except urllib.error.HTTPError as e:
        print(f"ESPN {slug} -> HTTP {e.code}")
    except Exception as e:
        print(f"ESPN {slug} -> ERR {type(e).__name__}")

for q in ("2025/2026", "2023/2024"):
    da = get(f"https://www.fotmob.com/api/data/leagues?id=252&ccode3=CRO&lang=en&season={urllib.request.quote(q, safe='')}")
    tbl = (da.get("table") or [{}])[0].get("data") or {}
    rows_flat = (((tbl.get("table") or {}).get("all")) or [])
    tabs = tbl.get("tables") or []
    has_ts = any("top scorer" in str(c.get("header", "")).lower() for c in (da.get("stats") or {}).get("players") or [] if isinstance(c, dict))
    po = da.get("playoff", "absent")
    print(f"archived {q}: composite={tbl.get('composite')} flat={len(rows_flat)} tables={len(tabs)} topscorer={has_ts} playoff={'null' if po is None else ('absent' if po=='absent' else 'obj')}")
    if tabs:
        for t in tabs[:4]:
            rr = ((t.get("table") or {}).get("all") or [])
            print(f"   sub: leagueName={t.get('leagueName')!r} rows={len(rr)}")

tr = d.get("transfers") or {}
trd = tr.get("data") if isinstance(tr, dict) else None
lst = trd if isinstance(trd, list) else ((trd.get("transfers") or []) if isinstance(trd, dict) else [])
clubs = set()
for t in lst:
    for k in ("fromClubFullName", "fromClub", "toClubFullName", "toClub"):
        v = t.get(k)
        if v: clubs.add(str(v))
print(f"\nTRANSFER CLUBS({len(clubs)}):", sorted(clubs))
