#!/usr/bin/env python3
# ------------------------------------------------------------------
# cycle-181 feasibility probe — the 24th-competition selection, live
# (UA Chrome/124, 2026-10-30). D5 rule: evidence over memory — the
# cycle-157 sweep recorded ZERO Iranian players across the 76 clubs of
# the five European runner-ups, but that verdict must be re-derived,
# not remembered: transfers happen. Re-sweep the four remaining
# candidates (DENMARK 46, GREECE 135, BELGIUM 40, EGYPT 519 — the 5th,
# SWITZERLAND 69, joined as cycle-160) club-by-club via data/teams
# squad.cname, and dump the FULL squad entry of any Iranian hit.
# ------------------------------------------------------------------
import json, gzip, urllib.request, time

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8"))

def five_blocks(lid, cc):
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
    # D5 2026-10-30: transfers.data IS the list directly (not {transfers: []})
    print(f"league({lid},{cc}): rows={len(rows)} slash={len(slash)} "
          f"fetchAll={'YES' if fetchall else 'NO'} titles={len(titles)} "
          f"transfers={'null' if tr is None else len(tr)} playoff={'null' if not p.get('playoff') else 'PRESENT'}")
    return rows

def sweep_clubs(rows, label):
    """sweep every club's data/teams squad for cname == iran; dump full entries"""
    hits = []
    for i, r in enumerate(rows):
        tid, tname = r.get("id"), r.get("name")
        try:
            t = get(f"https://www.fotmob.com/api/data/teams?id={tid}")
        except Exception as e:
            print(f"  [{i+1}/{len(rows)}] {tname} ({tid}): squad ERROR {e}")
            continue
        members = [m for grp in ((t.get("squad") or {}).get("squad") or []) for m in (grp.get("members") or [])]
        iran = [m for m in members if (m.get("cname") or "").strip().lower() == "iran"]
        print(f"  [{i+1}/{len(rows)}] {tname} ({tid}): squad={len(members)} iran={len(iran)}")
        for m in iran:
            print(f"    IRAN HIT (full entry): {json.dumps(m, ensure_ascii=False)}")
            hits.append({"club": tname, "clubId": tid, **m})
        time.sleep(0.35)
    return hits

if __name__ == "__main__":
    CANDS = (("GREECE", 135, "GRE"), ("DENMARK", 46, "DEN"), ("BELGIUM", 40, "BEL"), ("EGYPT", 519, "EGY"))
    for label, lid, cc in CANDS:
        print(f"\n=== {label} ({lid}/{cc}) ===")
        try:
            rows = five_blocks(lid, cc)
        except Exception as e:
            print(f"  league page ERROR: {e}")
            continue
        hits = sweep_clubs(rows, label)
        print(f"{label} TOTAL IRANIAN HITS: {len(hits)}")
