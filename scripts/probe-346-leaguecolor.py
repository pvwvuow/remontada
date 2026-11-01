#!/usr/bin/env python3
# ---------------------------------------------------------------------
# Remontada — probe-346-leaguecolor.py  (update cycle-346)
# Verifies the OFFICIAL brand color of each competition (upstream
# details.leagueColor — probed live UA Chrome/124: pl #3F1152, ucl #162E58,
# laliga #345DDF, ligue1 #085FFF) is surfaced through the standings payload
# (cycle-346) and hard-guarded: only strict 6-digit hex ever reaches the API,
# leagues whose upstream payload lacks/mangles the field hide the accent.
# Usage: python3 scripts/probe-346-leaguecolor.py [BASE]
# UA: Chrome/124 (house probe standard). Exits non-zero on any failure.
# ---------------------------------------------------------------------
import json
import re
import sys
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:3000"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
# anchors probed live from the upstream payload (2026-11-01)
OFFICIAL = {"pl": "#3F1152", "ucl": "#162E58", "laliga": "#345DDF", "ligue1": "#085FFF"}
# leagues whose payload was not probed upstream — structural assertions only
STRUCTURAL = ["bundesliga", "seriea", "superlig", "scottish", "persiangulf", "acl"]

results = []


def check(name, cond, detail):
    results.append((bool(cond), name, detail))


def get_json(path):
    req = urllib.request.Request(BASE + path, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=40) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return -1, {"_err": str(e)}


# --- anchors: exact official colors -----------------------------------
for key, expected in OFFICIAL.items():
    st, d = get_json(f"/api/standings?league={key}")
    ok = st == 200 and isinstance(d, dict)
    color = d.get("color") if ok else None
    check(f"{key}: 200", ok, f"status={st}")
    check(f"{key}: official color {expected}", color == expected, f"color={color}")
    rows_ok = ok and isinstance(d.get("rows"), list) and len(d["rows"]) > 0
    check(f"{key}: standings payload intact alongside", rows_ok,
          f"rows={len(d.get('rows') or [])}" if ok else "no payload")

# --- structural sweep: strict hex or absent, nothing else -------------
for key in STRUCTURAL:
    st, d = get_json(f"/api/standings?league={key}")
    ok = st == 200 and isinstance(d, dict)
    color = d.get("color") if ok else None
    check(f"{key}: 200", ok, f"status={st}")
    check(f"{key}: color strict-hex or absent",
          color is None or bool(HEX.match(color)), f"color={color}")

# --- contract guard: unknown league still 400 --------------------------
st, _ = get_json("/api/standings?league=nonexistent")
check("unknown league -> 400", st == 400, f"status={st}")

ok = sum(1 for passed, _, _ in results if passed)
for passed, name, detail in results:
    print(f"  [{'PASS' if passed else 'FAIL'}] {name}  ({detail})")
print(f"\n{ok}/{len(results)} green  BASE={BASE}")
sys.exit(0 if ok == len(results) else 1)
