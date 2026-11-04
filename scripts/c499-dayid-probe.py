# -*- coding: utf-8 -*-
# cycle-499: the fresh sweep's day-id trap filter (the 469/474/494 lesson —
# the day feed carries leagueId=DAY-ID while the registry holds the REAL id;
# MLS 913550->130, EST 1000001181->248). The sweep (scripts/c499-league-sweep.py)
# top missing candidates go through:
#   Stage A: /api/data/leagues?id=X&ccode3=CC — real page (name!=null) or the
#            literal-null day-tournament trap?
#   Stage B: sample matchDetails -> infoBox Tournament {id, parentLeagueId,
#            leagueName} — the 141 crack of the real id.
#   Verdict: day-id-of-registered (EXCLUDE) vs real-unregistered (the queue).
# 1.8s cadence + backoff (the 480 429-wall lesson). UA Chrome/124.
import json, time, urllib.request, sys

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
PACE = 1.8

def get(url, tries=3):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode("utf-8", "replace"))
        except Exception as e:
            last = e
            time.sleep(3.0)
    raise last

CANDIDATES = [
    (953430, "ENG", "FA Cup", 40, 6469281),
    (516, "ALG", "Ligue 1", 32, 5989869),
    (941118, "ENG", "Southern Premier Division South", 36, 5953964),
    (938215, "JPN", "J. League 2", 30, 5836339),
    (9136, "JPN", "J. League 3", 30, 5987218),
    (1000001801, "ENG", "Championship(day?)", 36, 5836904),
    (940374, "ENG", "National League South", 31, 5907651),
    (1000001729, "ARG", "Liga Profesional(day?)", 30, 1000019614),
]
REGISTERED = {42, 47, 48, 87, 55, 54, 53, 69, 71, 64, 536, 61, 538, 535, 57, 9469, 40, 519, 524,
              138, 209, 141, 132, 77, 290, 9487, 248, 337, 9039, 112, 336, 63, 193, 130, 523, 525,
              10216, 8985, 196, 252}

print("=== Stage A+B per candidate ===")
queue = []
for lid, cc, name, rows, sample in CANDIDATES:
    print(f"\n--- id={lid} cc={cc} name={name!r} rows={rows} sample={sample}")
    real_page = None
    try:
        d = get(f"https://www.fotmob.com/api/data/leagues?id={lid}&ccode3={cc}&lang=en")
        nm = d.get("name")
        print(f"  A: HTTP 200 name={nm!r}")
        if nm is not None:
            real_page = d
    except Exception as e:
        print(f"  A: {type(e).__name__} {e}")
    time.sleep(PACE)
    parent = None
    tname = None
    try:
        det = get(f"https://www.fotmob.com/api/matchDetails?matchId={sample}&lang=en")
        ib = (det.get("content", {}) or {}).get("matchFacts", {}) or {}
        info = None
        for k in ("infoBox", "InfoBox"):
            if isinstance(ib.get(k), dict):
                info = ib[k]
                break
        if info is None:
            c = det.get("content", {}) or {}
            info = ((c.get("matchFacts", {}) or {}).get("infoBox", {})) or {}
        t = info.get("Tournament") or info.get("tournament") or {}
        parent = t.get("parentLeagueId")
        tname = t.get("leagueName")
        print(f"  B: matchDetails Tournament id={t.get('id')} parentLeagueId={parent} leagueName={tname!r}")
    except Exception as e:
        print(f"  B: {type(e).__name__} {e}")
    time.sleep(PACE)
    verdict = None
    if parent in REGISTERED:
        verdict = f"DAY-ID of REGISTERED id={parent} -> EXCLUDE"
    elif parent is not None and parent != lid:
        verdict = f"DAY-ID of REAL id={parent} (unregistered) -> real candidate {parent}"
    elif real_page is not None:
        verdict = f"REAL PAGE on the day id itself -> candidate {lid}"
    else:
        verdict = "UNRESOLVED"
    print(f"  VERDICT: {verdict}")
    if real_page is not None or (parent is not None and parent not in REGISTERED):
        queue.append((parent or lid, cc, tname or name, rows, real_page is not None))
    time.sleep(PACE)

print("\n=== QUEUE (real unregistered) ===")
for q in queue:
    print(" ", q)
