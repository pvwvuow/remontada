#!/usr/bin/env python3
# ---------------------------------------------------------------------
# Remontada — probe-345-coachtenures.py  (update cycle-345)
# Verifies the new per-tenure bench record («کارنامه‌ی نیمکت‌های قبلی»)
# surfaced from FotMob's coachStats.historicalCareerEntries — a block the
# payloads always carried but nothing consumed before this cycle.
# Checks: /api/coach/30889 (Xabi Alonso) exposes tenures with real W/D/L,
# winPct 0..100, ppg>0 and the internal invariant wins+draws+losses ==
# matches; the additive-no-break sweep runs the WHOLE seeded coach family
# (tenures must be a list on every coach, empty allowed); the unknown-id
# 404 contract still holds. Usage: python3 scripts/probe-345-coachtenures.py [BASE]
# UA: Chrome/124 (house probe standard). Exits non-zero on any failure.
# ---------------------------------------------------------------------
import json
import sys
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:3000"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
# the seeded coach family from lib/fotmob.ts COACH_SEED (additive sweep)
SEED_COACHES = [24011, 2642, 131509, 1515447, 1415967, 33072, 38711]

results = []


def check(name, cond, detail):
    results.append((bool(cond), name, detail))


def get_json(path):
    req = urllib.request.Request(BASE + path, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return -1, {"_err": str(e)}


# --- anchor: Xabi Alonso — real per-tenure records ---------------------
st, d = get_json("/api/coach/30889")
check("coach 30889: status 200", st == 200, f"status={st}")
coach = (d or {}).get("coach") if isinstance(d, dict) else None
tenures = (coach or {}).get("tenures") if isinstance(coach, dict) else None
check("coach 30889: tenures is a list", isinstance(tenures, list),
      f"type={type(tenures).__name__}")
if isinstance(tenures, list) and tenures:
    check("coach 30889: >=1 historical tenure", len(tenures) >= 1, f"n={len(tenures)}")
    invariant_ok = all(
        t.get("wins", 0) + t.get("draws", 0) + t.get("losses", 0) == t.get("matches", 0)
        for t in tenures
    )
    check("coach 30889: W+D+L == matches on every tenure", invariant_ok,
          "invariant")
    pct_ok = all(
        t.get("winPct") is None or (0 <= t["winPct"] <= 100) for t in tenures
    )
    check("coach 30889: winPct within 0..100", pct_ok, "range")
    ppg_ok = all(t.get("ppg") is None or t["ppg"] > 0 for t in tenures)
    check("coach 30889: ppg positive", ppg_ok, "range")
    fa_ok = all(isinstance(t.get("fa"), str) and t["fa"] for t in tenures)
    check("coach 30889: every tenure has a fa name", fa_ok, "names")
    # the active bench must NOT leak into the past-tenures section
    active_id = (coach or {}).get("team", {}).get("id") if isinstance(coach, dict) else None
    no_active = active_id is None or all(t.get("teamId") != active_id for t in tenures)
    check("coach 30889: active bench excluded from tenures", no_active,
          f"active={active_id}")
    first = tenures[0]
    print(f"    sample tenure: {first.get('fa')} — {first.get('matches')} بازی "
          f"({first.get('wins')}W/{first.get('draws')}D/{first.get('losses')}L), "
          f"winPct={first.get('winPct')}, ppg={first.get('ppg')}")
elif isinstance(tenures, list):
    check("coach 30889: payload has historical entries", False, "tenures EMPTY")
else:
    check("coach 30889: payload readable", False, "no coach payload")

# --- additive-no-break sweep: whole seeded coach family ----------------
for cid in SEED_COACHES:
    st, d = get_json(f"/api/coach/{cid}")
    ok = st == 200 and isinstance(d, dict)
    t = (d or {}).get("coach", {}).get("tenures") if ok else None
    check(f"sweep coach {cid}: 200 + tenures list", ok and isinstance(t, list),
          f"status={st} tenures={'list' if isinstance(t, list) else type(t).__name__}")

# --- contract guard: unknown id still 404 ------------------------------
st, _ = get_json("/api/coach/999999999")
check("unknown coach id -> 404", st == 404, f"status={st}")

ok = sum(1 for passed, _, _ in results if passed)
for passed, name, detail in results:
    print(f"  [{'PASS' if passed else 'FAIL'}] {name}  ({detail})")
print(f"\n{ok}/{len(results)} green  BASE={BASE}")
sys.exit(0 if ok == len(results) else 1)
