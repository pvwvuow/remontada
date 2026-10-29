#!/usr/bin/env bash
# cycle-178 bug-hunt pre-probe (D5: observed bytes BEFORE gates)
set -u
python3 - <<'PY'
import json, urllib.parse, urllib.request
BASE = "http://localhost:3000"
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
def code(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return urllib.request.urlopen(req, timeout=30).getcode()

for lg in ("persiangulf", "mas"):
    d = get(f"{BASE}/api/standings?league={lg}")
    rows = d.get("rows") or []
    ass = d.get("assists") or []
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    print(f"{lg}: rows={len(rows)} assists={len(ass)} cardsY={len(y)} cardsR={len(r)}")
    if y: print(f"  yellow[0] = {y[0].get('playerId')} {(y[0].get('nameFa') or y[0].get('name'))!r} value={y[0].get('value')}")
    if r: print(f"  red[0]    = {r[0].get('playerId')} {(r[0].get('nameFa') or r[0].get('name'))!r} value={r[0].get('value')}")
    if ass: print(f"  assists[0]= {ass[0].get('playerId')} {(ass[0].get('nameFa') or ass[0].get('name'))!r} assists={ass[0].get('assists')}")

for lg in ("persiangulf", "mas", "pl"):
    d = get(f"{BASE}/api/topscorers/{lg}")
    sc = d.get("scorers") or []
    ass = d.get("assists") or []
    print(f"topscorers/{lg}: scorers={len(sc)} assists={len(ass)}" + (f" assists[0]={ass[0].get('playerId')}" if ass else ""))

print("player/688273 page code =", code(f"{BASE}/player/688273"))
print("player/900771 page code =", code(f"{BASE}/player/900771"))
print("player/694010 page code =", code(f"{BASE}/player/694010"))
d = get(f"{BASE}/api/search?q=" + urllib.parse.quote("یانلت"))
ps = d.get("players") or []
print("search یانلت:", [(x.get("playerId"), x.get("fa")) for x in ps[:3]])
PY