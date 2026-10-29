#!/usr/bin/env python3
# cycle-161 probe — the three new candidate ids from the day feed
# (Azerbaijan 262 / Croatia 252 / Serbia 1000001612): four-block check +
# full squad sweep for Iranian players (the cycle-160 standard).
import json, gzip, urllib.request, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

for pid, cc, nm in ((262, "AZE", "Azerbaijan-PL"), (252, "CRO", "Croatian-HNL"), (1000001612, "SRB", "Serbian-SuperLiga")):
    try:
        d = get(f"https://www.fotmob.com/api/data/leagues?id={pid}&ccode3={cc}&lang=en")
    except Exception as e:
        print(f"{nm} [{pid}/{cc}] HTTP-ERR({type(e).__name__})"); continue
    if not isinstance(d, dict) or d.get("statusCode"):
        print(f"{nm} [{pid}/{cc}] bad-payload"); continue
    seasons = d.get("allAvailableSeasons") or []
    def sname(s): return s if isinstance(s, str) else (s.get("name") or "") if isinstance(s, dict) else ""
    s_names = [sname(s) for s in seasons]
    allrows = (((d.get("table") or [{}])[0].get("data") or {}).get("table") or {}).get("all") or []
    composite = ((d.get("table") or [{}])[0].get("data") or {}).get("composite")
    url = ""
    for cat in (d.get("stats") or {}).get("players") or []:
        if isinstance(cat, dict) and "top scorer" in str(cat.get("header", "")).lower():
            url = cat.get("fetchAllUrl") or ""; break
    scorer_n, lead = 0, None
    if url:
        if url.startswith("//"): url = "https:" + url
        try:
            g = get(url)
            rl = ((g.get("TopLists") or [{}])[0].get("StatList")) or []
            scorer_n = len(rl)
            if rl: lead = f"{rl[0].get('ParticipantName') or rl[0].get('name')}({rl[0].get('StatValue') or rl[0].get('statValue')})"
        except Exception: scorer_n = -1
    tr = d.get("transfers") or {}
    trd = tr.get("data") if isinstance(tr, dict) else None
    trn = len(trd.get("transfers") or []) if isinstance(trd, dict) else (len(trd) if isinstance(trd, list) else 0)
    po = d.get("playoff", "absent"); po_s = "null" if po is None else ("yes" if po == "absent" else "obj")
    top3 = [(r.get("name"), r.get("pts")) for r in allrows[:3]]
    print(f"{nm} [{pid}/{cc}] seasons={len(seasons)}(slash={sum(1 for s in s_names if '/' in s)} first={s_names[0] if s_names else '-'}) rows={len(allrows)} composite={composite} top3={top3} scorers={scorer_n} lead={lead} transfers={trn} playoff={po_s}")
    if len(allrows) == 0:
        continue
    # squad sweep
    hits = []
    for r in allrows[:24]:
        tid = r.get("id")
        try:
            t = get(f"https://www.fotmob.com/api/data/teams?id={tid}")
        except Exception: continue
        for grp in ((t.get("squad") or {}).get("squad") or []):
            for m in (grp.get("members") or []):
                if (m.get("cname") or "").lower() == "iran":
                    hits.append(f"{m.get('name')}#{r.get('name')}#{m.get('id')}")
        time.sleep(0.3)
    print(f"{nm} squad-sweep Iranians={';'.join(hits) or 'NONE'}")
    time.sleep(1.0)
