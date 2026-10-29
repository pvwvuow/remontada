#!/usr/bin/env python3
# cycle-160 verification — the D5 player-level standard (cycle-156 killed
# the Belgian «Dennis Eckert» false positive this way): a squad cname hit
# is NOT proof until /api/player/<id> says player.info.country == "Iran".
# Also: identify club 10190, probe Austrian/Norwegian for the full field.
import json, gzip, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

# 1) club 10190 identity + full squad dump of its Iranian-flagged members
t = get("https://www.fotmob.com/api/data/teams?id=10190")
iname = ((t.get("page") or {}).get("title") or "") if isinstance(t.get("page"), dict) else ""
print("club 10190 =", t.get("name") or iname, "| ccode:", (t.get("userCountry") or {}))
for grp in ((t.get("squad") or {}).get("squad") or []):
    for m in (grp.get("members") or []):
        if (m.get("cname") or "").lower() == "iran":
            print("  member:", m.get("name"), "| id:", m.get("id"), "| pos:", m.get("pos") or (m.get("role") or {}).get("name") if isinstance(m.get("role"), dict) else m.get("role"), "| shirt:", m.get("shirtNumber"))
            pid = m.get("id")
            if pid:
                try:
                    p = get(f"https://www.fotmob.com/api/player/{pid}")
                    info = (p.get("player") or {}) if isinstance(p.get("player"), dict) else (p.get("info") or {})
                    print("  player.info:", json.dumps({k: info.get(k) for k in ("name", "country", "dateOfBirthTimestamp", "position") if k in info}, ensure_ascii=False))
                    print("  top-level keys:", list(p.keys())[:12])
                except Exception as e:
                    print("  player-fetch-ERR", type(e).__name__)

# 2) Austrian 38 + Norwegian 59 four-block probe (completing the field)
for pid, cc, nm in ((38, "AUT", "Austrian-BL"), (59, "NOR", "Eliteserien")):
    try:
        d = get(f"https://www.fotmob.com/api/data/leagues?id={pid}&ccode3={cc}&lang=en")
    except Exception as e:
        print(nm, "HTTP-ERR", type(e).__name__); continue
    if not isinstance(d, dict) or d.get("statusCode"):
        print(nm, "bad-payload"); continue
    seasons = d.get("allAvailableSeasons") or []
    def sname(s): return s if isinstance(s, str) else (s.get("name") or "") if isinstance(s, dict) else ""
    s_names = [sname(s) for s in seasons]
    allrows = (((d.get("table") or [{}])[0].get("data") or {}).get("table") or {}).get("all") or []
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
            if rl: lead = f"{rl[0].get('name')}({rl[0].get('statValue')})"
        except Exception: scorer_n = -1
    tr = d.get("transfers") or {}
    trd = tr.get("data") if isinstance(tr, dict) else None
    trn = len(trd.get("transfers") or []) if isinstance(trd, dict) else 0
    po = d.get("playoff", "absent"); po_s = "null" if po is None else ("yes" if po == "absent" else "obj")
    top3 = [(r.get("name"), r.get("pts")) for r in allrows[:3]]
    print(f"{nm} [{pid}/{cc}] seasons={len(seasons)}(slash={sum(1 for s in s_names if '/' in s)}) rows={len(allrows)} top3={top3} scorers={scorer_n} lead={lead} transfers={trn} playoff={po_s}")
    # squad sweep
    hits = []
    for r in allrows:
        tid = r.get("id")
        try:
            tt = get(f"https://www.fotmob.com/api/data/teams?id={tid}")
        except Exception: continue
        for grp in ((tt.get("squad") or {}).get("squad") or []):
            for m in (grp.get("members") or []):
                if (m.get("cname") or "").lower() == "iran":
                    hits.append(f"{m.get('name')}#{r.get('name')}#{m.get('id')}")
        import time; time.sleep(0.3)
    print(f"{nm} squad-sweep Iranians={';'.join(hits) or 'NONE'}")
