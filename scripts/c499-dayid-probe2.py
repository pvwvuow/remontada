# -*- coding: utf-8 -*-
# cycle-499 Stage B (fixed): the 141 crack — sample matchDetails via the
# app's OWN fetch shape (fotmob.ts:7286 /api/data/matchDetails?matchId=)
# -> infoBox Tournament parentLeagueId. Stage A verdicts already in:
# all 8 sweep-top candidates answered the literal-null day-tournament class.
import json, time, urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
PACE = 1.8

def get(url, tries=3):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read().decode("utf-8", "replace")
            return json.loads(body) if body.strip() else None
        except Exception as e:
            last = e
            time.sleep(3.0)
    raise last

def find_tournament(obj, depth=0):
    """Locate the dict carrying parentLeagueId inside matchDetails."""
    if depth > 6 or not isinstance(obj, dict):
        return None
    if "parentLeagueId" in obj:
        return obj
    for v in obj.values():
        r = find_tournament(v, depth + 1)
        if r is not None:
            return r
    return None

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

print("=== Stage B: /api/data/matchDetails crack ===")
queue = []
for lid, cc, name, rows, sample in CANDIDATES:
    t = {}
    try:
        det = get(f"https://www.fotmob.com/api/data/matchDetails?matchId={sample}&lang=en")
        node = find_tournament(det or {})
        t = node or {}
    except Exception as e:
        print(f"id={lid} {name!r}: B {type(e).__name__} {e}")
        time.sleep(PACE)
        continue
    parent = t.get("parentLeagueId")
    tname = t.get("leagueName")
    lid_t = t.get("id")
    if parent in REGISTERED:
        verdict = f"DAY-ID of REGISTERED id={parent} -> EXCLUDE (queue shrink)"
    elif parent and parent != lid:
        verdict = f"DAY-ID of REAL unregistered id={parent} -> CANDIDATE"
        queue.append((parent, cc, tname, rows, sample))
    else:
        verdict = f"no parent crack (Tournament id={lid_t} name={tname!r}) -> unresolved"
    print(f"id={lid} {name!r}: Tournament id={lid_t} parentLeagueId={parent} leagueName={tname!r} -> {verdict}")
    time.sleep(PACE)

print("\n=== QUEUE (real unregistered, by sweep rows) ===")
for q in sorted(queue, key=lambda x: -x[3]):
    print(f"  real id={q[0]} cc={q[1]} name={q[2]!r} sweepRows={q[3]} sample={q[4]}")
