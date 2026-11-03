#!/usr/bin/env python3
# cycle-479 probe2: the 141-crack (the ARG 474 precedent) — the day-feed id
# 938628 returns literal null on /api/data/leagues, so the real page id comes
# from a live GUA match's matchDetails parentLeagueId + the full page probe.
import json, subprocess, sys, time

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "40", "-A", UA, url],
                       capture_output=True, text=True, timeout=60)
    return r.stdout

print("=== 1. collect GUA match ids from the ±7 feed ===")
match_ids = []
for o in range(-7, 8):
    d = json.loads(get(f"http://localhost:3000/api/matches?offset={o}"))
    for g in d.get("groups", []):
        nm = (g.get("name") or g.get("leagueName") or "")
        if nm == "Liga Nacional Apertura":
            for m in g.get("matches", []):
                match_ids.append((d.get("date"), m.get("id"), (m.get("home") or {}).get("name"), (m.get("away") or {}).get("name"), m.get("status")))
    time.sleep(0.15)
print("GUA matches:", len(match_ids))
for row in match_ids:
    print("  ", row)

print()
print("=== 2. the 141-crack: matchDetails of a recent completed GUA match ===")
parent = None
for day, mid, hn, an, st in match_ids[:6]:
    out = get(f"https://www.fotmob.com/api/data/matchDetails?matchId={mid}")
    try:
        d = json.loads(out)
    except Exception:
        print(f"  match {mid}: parse fail ({len(out)} bytes)"); continue
    mi = d.get("general", {}).get("parentLeague", {}) or {}
    print(f"  match {mid} ({hn} vs {an}, {st}): parentLeagueId={mi.get('id')} name={mi.get('name')!r} leagueRound={d.get('general',{}).get('leagueRoundName')!r}")
    if mi.get("id") and parent is None:
        parent = mi.get("id")
    time.sleep(0.3)
    if parent:
        break

print()
print(f"=== 3. the REAL league page: id={parent} ===")
out = get(f"https://www.fotmob.com/api/data/leagues?id={parent}&ccode3=&lang=en")
print("len:", len(out))
try:
    d = json.loads(out)
    print("keys:", sorted(d.keys())[:24])
    print("name:", d.get("name"))
    ov = d.get("overview") or {}
    seas = ov.get("seasons") or []
    print("selectedSeason:", json.dumps(ov.get("selectedSeason"), ensure_ascii=False)[:160])
    print("seasons:", len(seas), [s.get("name") for s in seas][:14])
    tb = d.get("table") or []
    print("table type:", type(tb).__name__)
    if isinstance(tb, list) and tb:
        t0 = tb[0]
        data = t0.get("data") if isinstance(t0.get("data"), dict) else {}
        tables = (data or {}).get("tables") or []
        print("table[0].data.tables:", len(tables), "| tableHeader:", json.dumps(data.get("tableHeader"), ensure_ascii=False)[:120])
        for t in tables[:4]:
            tt = t.get("table") or {}
            rows = tt.get("all") or []
            print(f"  table: {t.get('tableName')!r} rows={len(rows)} composite={tt.get('composite')}")
            for r in rows[:3]:
                print("    row:", json.dumps({k: r.get(k) for k in ("idx", "name", "pts", "played", "goalConDiff", "id")}, ensure_ascii=False)[:200])
except Exception as e:
    print("PARSE FAIL:", e, out[:200])

print()
print("=== 4. ESPN slug probe (site/v2, --compressed) ===")
for slug in ("gua.1", "guatemala.1"):
    out = get(f"https://site.api.espn.com/apis/site/v2/sports/soccer/{slug}/scoreboard?dates=20261107")
    try:
        d = json.loads(out)
        lg = d.get("leagues") or []
        nm = lg[0].get("name") if lg else None
        evs = d.get("events") or []
        print(f"slug {slug}: len={len(out)} leagues={nm!r} events={len(evs)}")
        for e in evs[:4]:
            print("   event:", e.get("shortName"), "|", e.get("date"))
    except Exception as e:
        print(f"slug {slug}: FAIL {e} {out[:120]}")
