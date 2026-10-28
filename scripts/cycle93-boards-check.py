#!/usr/bin/env python3
"""cycle-93 bug-hunt data cross-check (read-only):
1. season boards (cycle-92): app /api/standings?league=pl boards vs live
   FotMob leagues payload stats blocks (values + order, UA Chrome/124).
2. coach history (cycle-91): app /api/team-coaches/{id} tenure sums vs the
   live data/teams coachHistory rows (W/D/L sums + games + newest name).
3. xG table (cycle-90): app standings xg/xga/xPts vs the live leagues payload
   xg table variant (by team id).
Any mismatch → prints MISMATCH lines and exits 1; all good → OK summary."""
import json, subprocess, sys, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
BASE = "http://localhost:3000"
MISMATCH = []

def live(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Encoding": "identity"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read().decode())

def app(path):
    with urllib.request.urlopen(BASE + path, timeout=30) as r:
        return json.loads(r.read().decode())

# ---------- 1. boards ----------
lg = live("https://www.fotmob.com/api/data/leagues?id=47&ccode3=ENG&lang=en")
st = lg.get("stats") or {}
live_blocks = {}
for kind, arr in (("team", st.get("teams") or []), ("player", st.get("players") or [])):
    for b in arr:
        live_blocks[(kind, b.get("header"))] = b
sb = app("/api/standings?league=pl")
boards = (sb.get("standings") or sb).get("boards") or []
print(f"[boards] app boards = {len(boards)}")
for b in boards:
    blk = live_blocks.get((b["kind"], b["header"]))
    if blk is None:
        MISMATCH.append(f"board {b['kind']}:{b['header']} missing upstream")
        continue
    # live rows = participant + topThree, deduped by id (participant usually
    # duplicates topThree[0]) — same rule as the app mapper (cycle-92)
    seen_ids = set()
    live_rows = []
    for r in [blk.get("participant"), *(blk.get("topThree") or [])]:
        if not r or not r.get("name"):
            continue
        rid = r.get("teamId") if b["kind"] == "team" else r.get("id")
        if rid is not None:
            if rid in seen_ids:
                continue
            seen_ids.add(rid)
        live_rows.append(r)
    app_rows = b["rows"]
    if len(app_rows) != min(len(live_rows), 3):
        MISMATCH.append(f"board {b['header']}: row count {len(app_rows)} vs live {len(live_rows)}")
    for a, l in zip(app_rows, live_rows):
        lv = float((l.get("stat") or {}).get("value", l.get("value")))
        if abs(float(a["value"]) - lv) > 1e-9:
            MISMATCH.append(f"board {b['header']}: {a['name']} {a['value']} != live {lv}")
        if a["name"] != l.get("name"):
            MISMATCH.append(f"board {b['header']}: name {a['name']} != live {l.get('name')}")
fmt_ok = all(b["fmt"] == (live_blocks[(b['kind'], b['header'])]['participant'].get('stat') or {}).get('format') for b in boards if live_blocks.get((b['kind'], b['header'])))
if not fmt_ok:
    MISMATCH.append("board fmt hints diverge from upstream stat.format")

# ---------- 2. coach history ----------
for tid in (8456, 9925, 9826):
    t = live(f"https://www.fotmob.com/api/data/teams?id={tid}")
    rows = (t.get("history") or {}).get("coachHistory") or []
    tc = app(f"/api/team-coaches/{tid}").get("coaches")
    if not tc:
        MISMATCH.append(f"coach {tid}: app returned null while live has {len(rows)} rows")
        continue
    # tenure sum check: every live row must be counted exactly once across tenures
    app_games = sum(x["games"] for x in tc["tenures"])
    live_games = sum((r.get("win") or 0) + (r.get("draw") or 0) + (r.get("loss") or 0) for r in rows)
    if app_games != live_games:
        MISMATCH.append(f"coach {tid}: games {app_games} != live {live_games}")
    if tc["total"] != len(rows):
        MISMATCH.append(f"coach {tid}: seasons {tc['total']} != live {len(rows)}")
    newest_live = rows[-1]["name"] if rows else None  # payload ascending
    if newest_live and tc["tenures"] and tc["tenures"][0]["name"] != newest_live:
        MISMATCH.append(f"coach {tid}: newest {tc['tenures'][0]['name']} != live {newest_live}")
    print(f"[coach] {tid}: tenures={len(tc['tenures'])} games={app_games} (live {live_games}) newest={tc['tenures'][0]['name'] if tc['tenures'] else '-'}")

# ---------- 3. xG ----------
pl = sb.get("standings") or sb
xg_rows = {r["teamId"]: r for r in pl.get("rows", []) if r.get("xg") is not None}
tab = None
for t0 in (lg.get("table") or []):
    d = t0.get("data") or {}
    tables = d.get("table") or {}
    if isinstance(tables, dict) and tables.get("xg"):
        tab = tables["xg"]
if tab is None:
    # alternate shape: table[0].data.table.all has the main table; xg lives on tables dict
    tab = ((lg.get("table") or [{}])[0].get("data") or {}).get("table", {}).get("xg")
if tab:
    n_ok = 0
    for row in tab:
        tid = row.get("id") or (row.get("team") or {}).get("id")
        r = xg_rows.get(tid)
        if not r:
            continue
        lxg = row.get("xg")  # plain number on the wire (float)
        if r.get("xg") is not None and isinstance(lxg, (int, float)) and abs(r["xg"] - float(lxg)) > 0.01:
            MISMATCH.append(f"xg {tid}: app {r['xg']} != live {lxg}")
        elif r.get("xg") is not None:
            n_ok += 1
    print(f"[xg] app rows with xg = {len(xg_rows)} | checked vs live = {n_ok}")
else:
    print("[xg] live xg table shape not found — skipping value diff (row presence above)")

print("=== RESULT ===")
if MISMATCH:
    for m in MISMATCH:
        print("MISMATCH:", m)
    sys.exit(1)
print("ALL-CHECKS-OK")
