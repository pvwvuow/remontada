#!/usr/bin/env python3
"""cycle-247 gate census refresh: 23 → 24 (the «کرنرهای تیم‌ها» block joins
the league page, h2 census grows BY DESIGN). The Python exact-match lesson
(«» bytes defeat Edit/MultiEdit — match on ASCII-safe fragments only).
Updates the LIVE h2n asserts in the five gates that assert the census:
238-hunt B1, 243-hunt B1, 244-fixproof B1, 245-domproof B1, 246-domproof B1.
The relative-order chains are pairwise index-inequalities (zero adjacency)
so the insertion between tgm and team-xG provably keeps them green — no
chain edits needed. mas/pg faces unchanged (corners honestly absent there)."""
import re, sys

ROOT = "/home/z/my-project/remontada/scripts"
GATES = {
    "cycle238-hunt.sh": 1,
    "cycle243-hunt.sh": 1,
    "cycle244-fixproof.sh": 1,
    "cycle245-domproof.sh": 1,
    "cycle246-domproof.sh": 1,
}
total = 0
for fn, expected in GATES.items():
    path = f"{ROOT}/{fn}"
    src = open(path, encoding="utf-8").read()
    n = src.count('"h2n":23')
    if n != expected:
        print(f"FAIL {fn}: expected {expected} occurrence(s) of '\"h2n\":23', found {n}")
        sys.exit(1)
    src = src.replace('"h2n":23', '"h2n":24')
    open(path, "w", encoding="utf-8").write(src)
    total += n
    print(f"OK  {fn}: h2n assert 23→24 ({n} occurrence)")
print(f"TOTAL {total} asserts refreshed — census 23→24 BY DESIGN")
