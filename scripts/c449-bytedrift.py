#!/usr/bin/env python3
# cycle-449 fix probe: byte-drift detector — sweep the live ±7 window and find
# raw names whose NORMALIZED form matches an existing TEAM_FA key but whose
# literal bytes do not (case, punctuation, accent, spacing variants). Such a
# row renders raw to Persian readers although a mapping exists = a real bug.
# Also: exact-key matches that STILL render raw (mapping-not-hit proof).
import json
import re
import subprocess
import unicodedata

BASE = "http://localhost:3000"
DATES = [str(o) for o in range(-7, 8)]
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
SRC = "/home/z/my-project/remontada/src/lib/leagues.ts"


def is_leak(s: str) -> bool:
    return bool(s) and not PERSIAN.search(s)


def fetch(url: str):
    out = subprocess.run(
        ["curl", "-s", "--max-time", "40", "-A", UA, url],
        capture_output=True, text=True, timeout=60,
    ).stdout
    return json.loads(out)


def load_keys():
    txt = open(SRC, encoding="utf-8").read()
    m = re.search(r"const TEAM_FA: Record<string, string> = \{(.*?)\n\};", txt, re.S)
    body = m.group(1)
    keys = set()
    for km in re.finditer(r'"((?:[^"\\]|\\.)*)"\s*:', body):
        keys.add(km.group(1))
    return keys


def fold(s: str) -> str:
    # aggressive normalization: strip accents, lowercase, drop all
    # non-alphanumeric chars, collapse spaces
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "", s)
    return s


def main():
    keys = load_keys()
    keyset_fold = {fold(k): k for k in keys}
    leaks = {}
    total = 0
    for d in DATES:
        try:
            payload = fetch(f"{BASE}/api/matches?offset={d}")
        except Exception:
            continue
        for g in payload.get("groups", []):
            for m in g.get("matches", []):
                total += 1
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    name = t.get("fa") or t.get("name") or ""
                    if is_leak(name):
                        e = leaks.setdefault(name, {"count": 0})
                        e["count"] += 1

    print(f"totalRows={total} rawDistinct={len(leaks)} teamFaKeys={len(keys)}")

    # A) exact-key hits that still leak = mapping-not-hit (impossible via code,
    #    but prove it anyway)
    exact_hits = [n for n in leaks if n.lower() in keys]
    # B) fold-hits = byte drift (the real fix candidates)
    fold_hits = []
    for n in leaks:
        f = fold(n)
        if f in keyset_fold and n.lower() not in keys:
            fold_hits.append((n, keyset_fold[f]))
    # C) near-hits on lowercase only (case drift)
    case_hits = [n for n in leaks if n.lower() in keys]

    print(f"A) exact-key still-leaking: {len(exact_hits)} {exact_hits[:10]}")
    print(f"B) fold-match byte-drift candidates: {len(fold_hits)}")
    for n, k in sorted(fold_hits):
        print(f"   raw={n!r}  key={k!r}")
    print(f"C) case-only drift: {len(case_hits)} {case_hits[:10]}")


if __name__ == "__main__":
    main()
