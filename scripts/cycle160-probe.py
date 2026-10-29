#!/usr/bin/env python3
# cycle-160 update probe — stage 1: four-block completeness for 20th
# competition candidates (house probe shape: UA Chrome/124, /api/data/
# leagues?id=&ccode3=). Stage 2: squad sweep (data/teams squad.squad
# groups, cname=="iran") only for complete candidates — the cycle-156
# player-level verification standard. Evidence over memory.
import json, sys, time, gzip, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

CANDS = [
    (51, "GER", "2.Bundesliga"), (305, "BRA", "Brasileirao"), (113, "ARG", "Liga-Profesional"),
    (130, "USA", "MLS"), (34, "CRO", "HNL"), (45, "RUS", "RPL"),
    (132, "AUS", "A-League"), (588, "JPN", "J1-League"), (40, "BEL", "Belgian-Pro"),
    (135, "GRE", "Greek-SL"), (69, "SUI", "Swiss-SL"), (46, "DEN", "Danish-SL"),
    (519, "EGY", "Egypt-Premier"),
]

complete = []
for pid, cc, nm in CANDS:
    try:
        d = get(f"https://www.fotmob.com/api/data/leagues?id={pid}&ccode3={cc}&lang=en")
    except Exception as e:
        print(f"{nm} [{pid}/{cc}] HTTP-ERR({type(e).__name__})")
        continue
    if not isinstance(d, dict) or d.get("statusCode"):
        print(f"{nm} [{pid}/{cc}] bad-payload")
        continue
    seasons = d.get("allAvailableSeasons") or []
    def sname(s):
        return s if isinstance(s, str) else (s.get("name") or "") if isinstance(s, dict) else ""
    s_names = [sname(s) for s in seasons]
    rows, top3, club_ids = 0, [], []
    allrows = (((d.get("table") or [{}])[0].get("data") or {}).get("table") or {}).get("all") or []
    rows = len(allrows)
    top3 = [(r.get("name"), r.get("pts")) for r in allrows[:3]]
    club_ids = [r.get("id") for r in allrows]
    url = ""
    for cat in (d.get("stats") or {}).get("players") or []:
        if isinstance(cat, dict) and "top scorer" in str(cat.get("header", "")).lower():
            url = cat.get("fetchAllUrl") or ""
            break
    scorer_n, lead = 0, None
    if url:
        if url.startswith("//"): url = "https:" + url
        try:
            g = get(url)
            rl = ((g.get("TopLists") or [{}])[0].get("StatList")) or []
            scorer_n = len(rl)
            if rl: lead = f"{rl[0].get('name')}({rl[0].get('statValue')})"
        except Exception:
            scorer_n = -1
    tr = d.get("transfers") or {}
    trd = tr.get("data") if isinstance(tr, dict) else None
    trn = len(trd.get("transfers") or []) if isinstance(trd, dict) else (len(trd) if isinstance(trd, list) else 0)
    po = d.get("playoff", "absent")
    po_s = "null" if po is None else ("yes" if po == "absent" else "obj")
    titles = len((d.get("seasons") or [{}])[0].get("titles") or []) if d.get("seasons") else 0
    ok = rows > 0 and scorer_n > 0 and po_s == "null"
    if rows and scorer_n > 0:
        complete.append((nm, pid, cc, club_ids, s_names))
    print(f"{nm} [{pid}/{cc}] seasons={len(seasons)}(slash={sum(1 for s in s_names if '/' in s)} first={s_names[0] if s_names else '-'}) rows={rows} top3={top3} scorers={scorer_n} lead={lead} titles={titles} transfers={trn} playoff={po_s}")
    time.sleep(1.2)

# stage 2: squad sweep of complete candidates — Iranian-hook hunt
print("\n=== stage2: squad sweep (cname==iran) ===")
for nm, pid, cc, club_ids, s_names in complete:
    hits = []
    for tid in club_ids[:24]:
        try:
            t = get(f"https://www.fotmob.com/api/data/teams?id={tid}")
        except Exception:
            continue
        for grp in ((t.get("squad") or {}).get("squad") or []):
            for m in (grp.get("members") or []):
                if (m.get("cname") or "").lower() == "iran":
                    hits.append(f"{m.get('name')}#{tid}")
        time.sleep(0.4)
    print(f"{nm} [{pid}/{cc}] squads={len(club_ids)} Iranians={';'.join(hits) or 'NONE'}")
    sys.stdout.flush()
    time.sleep(1.0)
