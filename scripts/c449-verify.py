#!/usr/bin/env python3
# cycle-449 fix verify: two modes.
#   --pre : byte-verify the new TEAM_FA key against the live feed literal
#           (must run BEFORE build; proves the fix bytes are right) + zero
#           key/value collisions in the file.
#   --post: re-sweep the live ±7 window AFTER rebuild+restart — zero raw
#           'Al Jeel' rows remain and every row renders «الجیل».
import json
import re
import subprocess
import sys

BASE = "http://localhost:3000"
DATES = [str(o) for o in range(-7, 8)]
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
SRC = "/home/z/my-project/remontada/src/lib/leagues.ts"
RAW = "Al Jeel"
KEY = "al jeel"
FA = "الجیل"


def fetch(url):
    out = subprocess.run(
        ["curl", "-s", "--max-time", "40", "-A", UA, url],
        capture_output=True, text=True, timeout=60,
    ).stdout
    return json.loads(out)


def live_literals():
    """Fetch the raw feed name bytes for our target from the ±7 window."""
    hits = []
    for d in DATES:
        try:
            payload = fetch(f"{BASE}/api/matches?offset={d}")
        except Exception:
            continue
        for g in payload.get("groups", []):
            for m in g.get("matches", []):
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    name = t.get("fa") or t.get("name") or ""
                    if name.strip().lower() in (KEY, KEY.replace(" ", "-")):
                        hits.append((d, payload.get("date"), name))
    return hits


def pre():
    txt = open(SRC, encoding="utf-8").read()
    m = re.search(r"const TEAM_FA: Record<string, string> = \{(.*?)\n\};", txt, re.S)
    body = m.group(1)
    keys = re.findall(r'"((?:[^"\\]|\\.)*)"\s*:', body)
    pairs = dict(re.findall(r'"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"', body))
    fails = 0

    # 1) the new key exists exactly once (no duplicate-key rewrite)
    n = keys.count(KEY)
    ok = n == 1
    print(("PASS" if ok else "FAIL") + f" A1 key '{KEY}' present exactly once ({n})")
    fails += 0 if ok else 1

    # 2) the key bytes equal the lowercased live feed literal
    hits = live_literals()
    ok = len(hits) >= 1 and all(name.lower() == KEY for _, _, name in hits)
    print(("PASS" if ok else "FAIL") +
          f" A2 live literal byte-match ({len(hits)} rows: " +
          ", ".join(f"{dt}@{d}" for d, dt, _ in hits) + ")")
    fails += 0 if ok else 1

    # 3) the value is the file's own anchor render
    ok = pairs.get(KEY) == FA
    print(("PASS" if ok else "FAIL") + f" A3 value = file's own «{FA}» ({pairs.get(KEY)!r})")
    fails += 0 if ok else 1

    # 4) zero exact-duplicate keys in the whole file (the collision gate)
    dups = {k for k in keys if keys.count(k) > 1}
    ok = not dups
    print(("PASS" if ok else "FAIL") + f" A4 zero duplicate keys ({len(dups)} found)")
    fails += 0 if ok else 1

    print(f"RESULT pre: {'PASS' if fails == 0 else 'FAIL'} ({fails} fails)")
    return 0 if fails == 0 else 1


def post():
    # post-fix the row carries fa=«الجیل» (the mapped render) while an
    # UNmapped row would fall back to name='Al Jeel' — count BOTH fields.
    raw_left = 0
    fa_rows = 0
    other = {}
    for d in DATES:
        try:
            payload = fetch(f"{BASE}/api/matches?offset={d}")
        except Exception:
            continue
        for g in payload.get("groups", []):
            for m in g.get("matches", []):
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    fa = t.get("fa") or ""
                    name = t.get("name") or ""
                    if fa.strip() == FA:
                        fa_rows += 1
                    elif not fa and name.strip().lower() in (KEY, KEY.replace(" ", "-")):
                        raw_left += 1
                        other.setdefault(repr(name), 0)
                        other[repr(name)] += 1
    ok = raw_left == 0 and fa_rows >= 1
    print(("PASS" if ok else "FAIL") +
          f" B1 ±7 window: {fa_rows} «{FA}» renders, {raw_left} raw literals left {other if other else ''}")
    print(f"RESULT post: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(pre() if "--pre" in sys.argv else post())
