#!/usr/bin/env python3
# cycle-98 bug-hunt cross-check — cycle-97 zones card vs RAW probe on a SECOND
# finished match (Parma–Udinese 5749726, raw captured live in the cycle-97
# sweep). The app /api/match/[id] zones must equal content.attackingZones
# home/away TOTAL splits exactly.
import json, urllib.request

RAW = "/home/z/my-project/scripts/cycle97-m5749726.json"
MID = 5749726

raw = json.load(open(RAW, encoding="utf-8"))
az = raw["content"]["attackingZones"]
want = {
    "home": {k: az["home"]["total"][k] for k in ("left", "center", "right")},
    "away": {k: az["away"]["total"][k] for k in ("left", "center", "right")},
}
with urllib.request.urlopen(f"http://localhost:3000/api/match/{MID}", timeout=20) as r:
    app = json.load(r)
got = app.get("zones") or (app.get("data") or {}).get("zones")
ok = got == want
print(f"match={MID} match={ok}\n  want={json.dumps(want)}\n  got ={json.dumps(got)}")
print("ALL-CHECKS-OK" if ok else "MISMATCH")
