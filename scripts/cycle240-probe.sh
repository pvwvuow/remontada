#!/usr/bin/env bash
# cycle-240 probe: the update round's feasibility sweep over the THREE
# remaining honest FotMob gaps, as-found, UA Chrome/124, zero app changes:
#   G1 season selector  — does the live league feed expose the available
#                         seasons list (id+name) the UI selector needs?
#   G2 cup brackets     — does the ucl feed carry round/bracket structures?
#   G3 transfers        — does a transfers endpoint serve league/team-level?
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/c240-probe
rm -rf "$OUT"; mkdir -p "$OUT"

# G1+G2 source feeds
curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=IRN&lang=en" -o "$OUT/laliga.json" &
curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=42&ccode3=IRN&lang=en" -o "$OUT/ucl.json" &
# G3 candidates: team-level transfers (Barcelona 8634) + legacy league endpoint
curl -s --compressed -A "$UA" "https://www.fotmob.com/api/transfers?id=8634" -o "$OUT/transfers-team.json" &
curl -s --compressed -A "$UA" "https://www.fotmob.com/api/leagues?id=42&ccode3=IRN&lang=en" -o "$OUT/ucl-v1.json" &
wait

python3 - "$OUT" <<'PY'
import json, os, sys
out = sys.argv[1]

def load(name):
    p = os.path.join(out, name)
    if not os.path.exists(p) or os.path.getsize(p) < 50:
        return None
    try:
        return json.load(open(p))
    except Exception:
        return None

print("== G1 SEASON SELECTOR ==")
raw = load("laliga.json")
if raw is None:
    print("laliga feed MISSING")
else:
    seasons = raw.get("availableSeasons") or []
    print("availableSeasons:", len(seasons), seasons[:3], "...", seasons[-2:] if len(seasons) > 3 else "")
    # any other season-shaped nodes?
    def walk(node, path):
        if isinstance(node, dict):
            for k, v in node.items():
                if "season" in k.lower() and isinstance(v, list) and v:
                    print(f"  node {path}.{k}: len={len(v)} first={json.dumps(v[0], ensure_ascii=False)[:120]}")
                walk(v, f"{path}.{k}")
        elif isinstance(node, list):
            for v in node[:20]:
                walk(v, path)
    walk(raw, "$")

print("== G2 CUP BRACKETS (ucl) ==")
ucl = load("ucl.json")
if ucl is None:
    print("ucl data-feed MISSING")
else:
    print("top-level keys:", sorted(ucl.keys())[:25])
    rounds = ucl.get("rounds") or []
    print("data-feed rounds:", len(rounds), json.dumps(rounds[0], ensure_ascii=False)[:150] if rounds else "")
uclv1 = load("ucl-v1.json")
if uclv1 is None:
    print("ucl v1 feed MISSING")
else:
    print("v1 top-level keys:", sorted(uclv1.keys())[:30])
    vt = uclv1.get("matches") or {}
    if isinstance(vt, dict):
        allr = vt.get("allMatches") or []
        print("v1 allMatches:", len(allr), json.dumps(allr[0], ensure_ascii=False)[:200] if allr else "")

print("== G3 TRANSFERS ==")
tr = load("transfers-team.json")
if tr is None:
    print("team transfers MISSING")
else:
    print("keys:", sorted(tr.keys())[:15])
    totn = sum(len(v) for v in tr.values() if isinstance(v, list))
    print("total list rows:", totn)
    for k, v in tr.items():
        if isinstance(v, list) and v:
            print(f"  {k}: {len(v)} first={json.dumps(v[0], ensure_ascii=False)[:160]}")
PY
echo "PROBE DONE"
