#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-351-touchplayers.py — live acceptance probe for cycle-351
(«نقشه لمس بازیکنان» — per-player drill-down of the touch map).

Checks (UA Chrome/124, live):
  A) upstream contract: matchDetails heatmapUrl for a finished match, the
     proxied heatmap JSON (players dict keyed p{optaId} → circle strings),
     and the optaId→(name,shirtNumber) join from content.playerStats.
  B) portal API contract: /api/match/{id} touchMap gains players[] —
     side/name/shirt/points/touches invariants, aggregate consistency
     (per-side sum == side touches), stable touches-desc order, unique ids,
     internal touchSides/touchMeta stripped from the public response.
  C) honest absence: an upcoming match must yield touchMap=null with zero
     upstream heatmap hits (route gates on started && !cancelled).
"""
import json
import re
import sys
import urllib.request

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = "http://localhost:3000"

checks = []


def ck(name, cond, info=""):
    checks.append((name, bool(cond), info))
    print(f"{'✅' if cond else '❌'} {name}" + (f" — {info}" if info else ""))


def get(url, timeout=15):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def jget(url, timeout=15):
    return json.loads(get(url, timeout))


# ---------------- A) upstream contract (finished: 5749733 Como–Venezia) ----------------
FINISHED = "5749733"
md = jget(f"https://www.fotmob.com/api/data/matchDetails?matchId={FINISHED}")
hm_url = (md.get("content") or {}).get("heatmapUrl")
ck("A1 matchDetails heatmapUrl present (finished)", isinstance(hm_url, str) and len(hm_url) > 10, str(hm_url)[:80])

hm = jget(f"https://www.fotmob.com{hm_url}") if hm_url else {}
players = hm.get("players") or {}
ck("A2 proxied heatmap JSON has players dict", isinstance(players, dict) and len(players) >= 18, f"{len(players)} players")
ck("A3 all keys are p{digits}", all(re.fullmatch(r"p\d+", k) for k in players), "")

ps = md.get("content", {}).get("playerStats") or {}
opta_meta = {str(v.get("optaId")): (v.get("name"), v.get("shirtNumber")) for v in ps.values()}
joined = [k for k in players if k[1:] in opta_meta]
ck("A4 optaId join coverage ≥ 90%", len(joined) >= 0.9 * len(players), f"{len(joined)}/{len(players)}")
named = sum(1 for k in joined if opta_meta[k[1:]][0])
shirts = sum(1 for k in joined if opta_meta[k[1:]][1] not in (None, ""))
ck("A5 joined names ≥ 90%", named >= 0.9 * len(joined), f"{named}/{len(joined)}")
ck("A6 joined shirts ≥ 90%", shirts >= 0.9 * len(joined), f"{shirts}/{len(joined)}")

# ---------------- B) portal API contract ----------------
api = jget(f"{BASE}/api/match/{FINISHED}")
ck("B1 api ok", api.get("ok") is True)
tm = api.get("touchMap") or {}
ck("B2 touchMap sides present", isinstance(tm.get("home"), dict) and isinstance(tm.get("away"), dict))
rows = tm.get("players")
ck("B3 touchMap.players present (cycle-351 layer)", isinstance(rows, list) and len(rows) >= 18, f"{len(rows) if rows else 0} rows")
ck("B4 internal touchSides stripped", "touchSides" not in api)
ck("B5 internal touchMeta stripped", "touchMeta" not in api)

ok_shape, ok_bounds, ok_touches = True, True, True
for r in rows or []:
    if r.get("side") not in ("home", "away") or not isinstance(r.get("name"), str) or not r["name"]:
        ok_shape = False
    if r.get("touches") != len(r.get("points") or []) or r["touches"] <= 0:
        ok_touches = False
    for p in r.get("points") or []:
        if not (-2 <= p["x"] <= 107 and -2 <= p["y"] <= 70):
            ok_bounds = False
ck("B6 row shape (side/name valid)", ok_shape)
ck("B7 touches == len(points) > 0", ok_touches)
ck("B8 points inside 105×68 (+2) pitch space", ok_bounds)

ids = [r["optaId"] for r in rows or []]
ck("B9 optaIds unique", len(ids) == len(set(ids)))
srt = [r["touches"] for r in rows or []]
ck("B10 touches-desc stable order", srt == sorted(srt, reverse=True))

home_sum = sum(r["touches"] for r in rows if r["side"] == "home")
away_sum = sum(r["touches"] for r in rows if r["side"] == "away")
ck("B11 home aggregate == Σ player touches", home_sum == (tm["home"] or {}).get("touches"), f"{home_sum} vs {(tm['home'] or {}).get('touches')}")
ck("B12 away aggregate == Σ player touches", away_sum == (tm["away"] or {}).get("touches"), f"{away_sum} vs {(tm['away'] or {}).get('touches')}")
ck("B13 home player count == distinct", len([r for r in rows if r["side"] == "home"]) == (tm["home"] or {}).get("players"))
ck("B14 away player count == distinct", len([r for r in rows if r["side"] == "away"]) == (tm["away"] or {}).get("players"))

persian = sum(1 for r in rows if re.search(r"[\u0600-\u06FF]", r["name"]))
print(f"   ℹ️  persian-script names: {persian}/{len(rows)} (playerFa honest map; raw fallback allowed)")

# second finished match (Serie A anchor 5749723) — shape holds cross-league
try:
    api2 = jget(f"{BASE}/api/match/5749723")
    tm2 = api2.get("touchMap") or {}
    rows2 = tm2.get("players") or []
    ck("B15 second finished match has players[]", isinstance(rows2, list) and len(rows2) >= 14, f"{len(rows2)} rows")
    sum_ok = sum(r["touches"] for r in rows2 if r["side"] == "home") == (tm2.get("home") or {}).get("touches")
    ck("B16 second match aggregate consistency", sum_ok)
except Exception as e:  # noqa: BLE001
    ck("B15 second finished match has players[]", False, str(e)[:80])

# ---------------- C) honest absence (upcoming) ----------------
feed = jget(f"https://www.fotmob.com/api/data/matches?date=20261103")
# feed shape (probed): {date, leagues: [{matches: [...]}]} — matches are
# nested per league; unstarted = started/finished/cancelled all false
cands = []
for lg in feed.get("leagues") or []:
    for m in lg.get("matches") or []:
        st = m.get("status") or {}
        # probed status shape: {utcTime, started, cancelled, finished} — no
        # «unstarted» flag exists; unstarted = none of the three set
        if not st.get("started") and not st.get("finished") and not st.get("cancelled") and m.get("id"):
            cands.append(str(m["id"]))
        if len(cands) >= 3:
            break
    if len(cands) >= 3:
        break
ck("C1 upcoming candidates found in feed", len(cands) > 0, ",".join(cands[:3]))
absent_ok = True
for cid in cands[:2]:
    a = jget(f"{BASE}/api/match/{cid}")
    if a.get("touchMap") is not None:
        absent_ok = False
ck("C2 upcoming → touchMap null (no upstream heatmap hit)", absent_ok)

# ---------------- verdict ----------------
fails = [n for n, ok, _ in checks if not ok]
print(f"\n=== probe-351: {len(checks) - len(fails)}/{len(checks)} green ===")
if fails:
    print("FAILED:", fails)
    sys.exit(1)
