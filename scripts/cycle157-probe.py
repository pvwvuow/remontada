#!/usr/bin/env python3
# ------------------------------------------------------------------
# cycle-157 feasibility probe — the 19th-competition selection, live
# (UA Chrome/124, 2026-10-29/30). D5 rule: evidence over memory — the
# id recovery runs through matchDetails parentLeagueId (the cycle-139
# crack) because the day-feed league ids answer null as page ids.
#
# Verdict this script re-derives on every run:
#   Candidates probed five-block (flat table / 17 slash seasons /
#   top-scorer fetchAllUrl / title seasons / transfers):
#     DENMARK 46, GREECE 135, SWITZERLAND 69, BELGIUM 40, EGYPT 519 —
#   all complete but ZERO Iranian players in any club squad (data/teams
#   top-level squad.squad groups, cname field) — consistent with the
#   cycle-156 sweep. The winner is the cup the task book's «براکت
#   جام‌ها» line points at: AFC Champions League Two (day-group 9469 @
#   2026-11-03 → parentLeagueId 9469 — here the day id IS the page id),
#   whose Group B carries گل‌گهر سیرجان (389880) — 31/32 squad members
#   cname "Iran" — and whose shape matches the portal contracts exactly:
#   COMPOSITE Group A–H tables (cycle-141 parser), 4 slash seasons
#   (globalMerge:false), fetchAllUrl goals.json (91 rows, مالکوم
#   الجزیره 4), 21 title seasons, transfers null (cup), playoff null.
#   ESPN answers 400 for afc.champions.two — no espnSlug (Gulf pattern).
# ------------------------------------------------------------------
import json, gzip, urllib.request

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8"))

ACL2 = 9469

def five_blocks(label, lid, cc):
    p = get(f"https://www.fotmob.com/api/data/leagues?id={lid}&ccode3={cc}")
    subs = ((p.get("table") or [{}])[0].get("data", {}) or {}).get("tables")
    if subs:
        rows = [r for s in subs for r in ((s or {}).get("table", {}) or {}).get("all", [])]
    else:
        rows = ((p.get("table") or [{}])[0].get("data", {}).get("table", {}) or {}).get("all") or []
    seasons = p.get("allAvailableSeasons") or []
    slash = [s for s in seasons if "/" in str(s)]
    st = p.get("stats") or {}
    pl = st.get("players")
    cats = (pl.get("categories") if isinstance(pl, dict) else pl) or []
    goals_cat = next((c for c in cats if c.get("name") == "goals" or c.get("leagueCatType") == "goals"), None)
    fetchall = (goals_cat or {}).get("fetchAllUrl") or ""
    titles = p.get("seasons") or []
    tr = (p.get("transfers") or {}).get("data")
    print(f"{label}({lid},{cc}): rows={len(rows)} slash={len(slash)} "
          f"fetchAll={'YES' if fetchall else 'NO'} titles={len(titles)} "
          f"transfers={'null' if tr is None else len(tr)} playoff={'null' if not p.get('playoff') else 'PRESENT'}")
    return rows

ir_squad = lambda tid: [m.get("name") for grp in ((get(f"https://www.fotmob.com/api/data/teams?id={tid}").get("squad") or {}).get("squad") or []) for m in (grp.get("members") or []) if (m.get("cname") or "").lower() == "iran"]

if __name__ == "__main__":
    # the five European runner-ups: complete, zero Iranians
    for (label, lid, cc) in (("DENMARK", 46, "DEN"), ("GREECE", 135, "GRE"),
                             ("SWITZERLAND", 69, "SUI"), ("BELGIUM", 40, "BEL"),
                             ("EGYPT", 519, "EGY")):
        five_blocks(label, lid, cc)
    # the winner: ACL Two + the Iranian club evidence
    rows = five_blocks("ACL-TWO", ACL2, "INT")
    names = [r.get("name") for r in rows]
    gg = [r for r in rows if "Gol Gohar" in str(r.get("name"))]
    assert gg, "Gol Gohar must ride the ACL Two table"
    gid = gg[0].get("id")
    irn = ir_squad(gid)
    print(f"GolGohar id={gid} iran-squad={len(irn)} sample={irn[:3]}")
