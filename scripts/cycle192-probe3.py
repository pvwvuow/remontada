#!/usr/bin/env python3
# cycle-192 probe round 3 — the two finalists:
#   F1 = content.table -> tables.ext.<lg>.fot.gz blob (new upstream surface)
#   F2 = matchFacts.topPlayers (top-5 rated per side, already in payload)
import gzip, io, json, urllib.request

BASE = "http://localhost:3000"
UP = "https://www.fotmob.com/api/data/matchDetails?matchId="
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0", "Accept": "application/json"}

def get(u, binary=False):
    req = urllib.request.Request(u, headers=UA)
    r = urllib.request.urlopen(req, timeout=30)
    return r.read() if binary else json.load(r)

print("== F1: tables.ext.55.fot.gz — fetchable? ==")
try:
    raw = get("https://data.fotmob.com/tables.ext.55.fot.gz", binary=True)
    print("HTTP 200, bytes:", len(raw))
    js = json.loads(gzip.decompress(raw).decode("utf-8"))
    print("gunzip OK — top keys:", sorted(js.keys())[:12])
    # find the serie-a table structure
    def walk(d, pre="", depth=0):
        if depth > 2 or not isinstance(d, dict):
            return
        for k, v in list(d.items())[:8]:
            t = type(v).__name__
            n = len(v) if isinstance(v, (list, dict)) else v
            print(f"{pre}{k} ({t}, {n})")
            if isinstance(v, dict):
                walk(v, pre + "  ", depth + 1)
    walk(js)
except Exception as e:
    print("FAILED:", type(e).__name__, str(e)[:200])

print("\n== F1b: locate teams 8686 (Roma) + 8529 (Cagliari) rows ==")
try:
    js2 = js
    # FotMob tables blobs: {"tables": [...]} typically; find rows lists containing 8686
    hits = []
    def hunt(d, path=""):
        if isinstance(d, list) and d and isinstance(d[0], dict) and any("id" in r and r.get("id") in (8686, 8529) for r in d[:30] if isinstance(r, dict)):
            hits.append(path)
        if isinstance(d, dict):
            for k, v in d.items():
                hunt(v, f"{path}.{k}")
        elif isinstance(d, list):
            for i, v in enumerate(d[:3]):
                hunt(v, f"{path}[{i}]")
    hunt(js2)
    print("row-list paths containing Roma/Cagliari:", hits[:6])
    if hits:
        # print one full row + its neighbors count
        node = js2
        for part in hits[0].strip(".").replace("[", ".").replace("]", "").split("."):
            if part.isdigit():
                node = node[int(part)]
            else:
                node = node[part]
        print("sample row:", json.dumps(node[0] if isinstance(node, list) else node, ensure_ascii=False)[:500])
except Exception as e:
    print("F1b FAILED:", type(e).__name__, str(e)[:200])

print("\n== F2: matchFacts.topPlayers bytes (5749721 finished) ==")
d = get(UP + "5749721")
tp = d["content"]["matchFacts"]["topPlayers"]
for side in ("homeTopPlayers", "awayTopPlayers"):
    rows = tp[side]
    print(f"{side}: n={len(rows)}")
    print("  entry0:", json.dumps(rows[0], ensure_ascii=False)[:700])

print("\n== F2b: topPlayers on upcoming 5868120 ==")
try:
    d2 = get(UP + "5868120")
    tp2 = (d2.get("content") or {}).get("matchFacts", {}).get("topPlayers")
    print(json.dumps(tp2, ensure_ascii=False)[:300] if tp2 else "ABSENT/null (honest)")
except Exception as e:
    print("5868120:", type(e).__name__, str(e)[:150])
