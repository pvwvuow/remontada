#!/usr/bin/env python3
# cycle-162 gate sync — patch the six older proof scripts to the new live
# truths: mas = the 22nd competition (merge-exempt domestic, the race stays
# 360/18 and the historical window stays 340/17), keys 1009/486 → 1035/511,
# search guide ۲۱ → ۲۲, hub cards 21 → 22 with the mas card presence.
# D5 byte-note: the file bytes carry a[href — the terminal display eats the
# [h two-char run (shows "aref"); every pattern below is written against the
# RAW bytes. Every pattern must hit exactly once or the patcher aborts
# loudly (the D5 fail-loud convention).
import sys

def patch(path, pairs):
    s = open(path, encoding="utf-8").read()
    applied = 0
    for old, new in pairs:
        n = s.count(old)
        if n == 0:
            if new and s.count(new) > 0:
                print(f"SKIP(already) {path}: {new[:50]!r}")
                continue
            print(f"MISS in {path}: {old[:70]!r}"); sys.exit(1)
        if n > 1:
            print(f"AMBIGUOUS({n}) in {path}: {old[:70]!r}"); sys.exit(1)
        s = s.replace(old, new)
        applied += 1
    open(path, "w", encoding="utf-8").write(s)
    print(f"OK {path} ({applied}/{len(pairs)} patches)")

A = "a[href"  # the raw byte run the display layer renders as "aref"

patch("scripts/cycle153-hunt.sh", [
    ("# V1: the hub — 21 league cards with the newest routes really present\n# (gate-synced cycle-161: hnl is the 21st card)",
     "# V1: the hub — 22 league cards with the newest routes really present\n# (gate-synced cycle-162: mas is the 22nd card — the first merge-exempt\n# DOMESTIC league, the cycle-160 Norwegian lesson applied)"),
    ('hunt "V1 leagues hub 21 cards" "http://localhost:3000/leagues" \\',
     'hunt "V1 leagues hub 22 cards" "http://localhost:3000/leagues" \\'),
    (f"&&!!document.querySelector(\\\"{A}='/league/hnl']\\\"),h1Fa:",
     f"&&!!document.querySelector(\\\"{A}='/league/hnl']\\\")&&!!document.querySelector(\\\"{A}='/league/mas']\\\"),h1Fa:"),
])

patch("scripts/cycle158-hunt.sh", [
    ('hunt "V1 leagues hub 21 cards" "$BASE/leagues" \\',
     'hunt "V1 leagues hub 22 cards" "$BASE/leagues" \\'),
    (f"!!document.querySelector(\\\"{A}='/league/eredivisie']\\\"),h1Fa:",
     f"!!document.querySelector(\\\"{A}='/league/eredivisie']\\\")&&!!document.querySelector(\\\"{A}='/league/mas']\\\"),h1Fa:"),
    ("# A9: duplicate-key guard — 1009 team / 486 player keys, zero duplicates (gate-synced cycle-161)",
     "# A9: duplicate-key guard — 1035 team / 511 player keys, zero duplicates (gate-synced cycle-162)"),
    ('report("A9 duplicate-key guard", len(tk) == 1009 and len(pk) == 486 and not td and not pd,',
     'report("A9 duplicate-key guard", len(tk) == 1035 and len(pk) == 511 and not td and not pd,'),
])

patch("scripts/cycle156-domproof.sh", [
    ("# A8: mapping-sweep duplicate-key guard — 1009 team keys / 486 player keys",
     "# A8: mapping-sweep duplicate-key guard — 1035 team keys / 511 player keys\n# (gate-synced cycle-162: the mas sweep +26/+25)"),
    ("report('A8 duplicate-key guard', len(tk) == 1009 and len(pk) == 486 and not td and not pd,",
     "report('A8 duplicate-key guard', len(tk) == 1035 and len(pk) == 511 and not td and not pd,"),
    ("# D7: /leagues — 21 cards + the eredivisie + acl2 cards (gate-synced cycle-161)",
     "# D7: /leagues — 22 cards + the eredivisie + acl2 + mas cards (gate-synced cycle-162)"),
    ("acl2Card=!!document.querySelector(\\\"a[href='/league/acl2']\\\"),h1Fa=((document.querySelector(\\\"h1\\\")||{}).innerText||'').includes('لیگ');return {cards,ereCard,acl2Card,h1Fa}",
     "acl2Card=!!document.querySelector(\\\"a[href='/league/acl2']\\\"),masCard=!!document.querySelector(\\\"a[href='/league/mas']\\\"),h1Fa=((document.querySelector(\\\"h1\\\")||{}).innerText||'').includes('لیگ');return {cards,ereCard,acl2Card,masCard,h1Fa}"),
    ("mapping sweep 1009 team / 486 player keys with ZERO duplicates; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)\"",
     "mapping sweep 1035 team / 511 player keys with ZERO duplicates (mas joined cycle-162); every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)\""),
    ("race copy ۱۸ + players hub هجده + search guide ۲۱ + /leagues 21st card (hnl, gate-synced cycle-161)",
     "race copy ۱۸ + players hub هجده + search guide ۲۲ + /leagues 22nd card (mas, gate-synced cycle-162)"),
])

patch("scripts/cycle157-domproof.sh", [
    ("# A7: mapping-sweep duplicate-key guard — 1009 team keys / 486 player keys,",
     "# A7: mapping-sweep duplicate-key guard — 1035 team keys / 511 player keys,\n# (gate-synced cycle-162: the mas sweep +26/+25)"),
    ('report("A7 duplicate-key guard", len(tk) == 1009 and len(pk) == 486 and not td and not pd,',
     'report("A7 duplicate-key guard", len(tk) == 1035 and len(pk) == 511 and not td and not pd,'),
    (f"# B3: the hub — 19 cards + the acl2 card (gate-synced cycle-157)",
     f"# B3: the hub — 22 cards + the acl2 + mas cards (gate-synced cycle-162)"),
    ("acl2Card:!!document.querySelector(\\\"a[href='/league/acl2']\\\"),h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ')}})()",
     "acl2Card:!!document.querySelector(\\\"a[href='/league/acl2']\\\"),masCard:!!document.querySelector(\\\"a[href='/league/mas']\\\"),h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ')}})()"),
    ('return {guide21:b.includes(\'۲۱ لیگ و جام\'),old20gone:!b.includes(\'۲۰ لیگ و جام\')}',
     'return {guide22:b.includes(\'۲۲ لیگ و جام\'),old21gone:!b.includes(\'۲۱ لیگ و جام\')}'),
    ('collect "$FEAT6" "B6 search guide 21"',
     'collect "$FEAT6" "B6 search guide 22"'),
    ("# B6: the search guide — ۲۱ لیگ و جام in the real search UI (hnl joins)",
     "# B6: the search guide — ۲۲ لیگ و جام in the real search UI (mas joins)"),
    ("race copy ۱۸ honest, search guide ۲۱, /leagues 21st card; mapping sweep 1009 team / 486 player keys with ZERO duplicates;",
     "race copy ۱۸ honest, search guide ۲۲, /leagues 22nd card; mapping sweep 1035 team / 511 player keys with ZERO duplicates (mas joined cycle-162);"),
])

patch("scripts/cycle155-domproof.sh", [
    (f"# D6: /leagues — 19 cards + the qatar + eredivisie + acl2 cards (gate-synced cycle-157)",
     f"# D6: /leagues — 22 cards + the qatar + eredivisie + acl2 + mas cards (gate-synced cycle-162)"),
    ("acl2Card:!!document.querySelector(\\\"a[href='/league/acl2']\\\"),h1Fa:((document.querySelector(\\\"h1\\\")||{}).innerText||\\\"\\\").includes(\\\"لیگ\\\")}",
     "acl2Card:!!document.querySelector(\\\"a[href='/league/acl2']\\\"),masCard:!!document.querySelector(\\\"a[href='/league/mas']\\\"),h1Fa:((document.querySelector(\\\"h1\\\")||{}).innerText||\\\"\\\").includes(\\\"لیگ\\\")}"),
    ("race copy ۱۸ + players hub هجده + search guide ۲۱ + /leagues 21st card (hnl, gate-synced cycle-161)",
     "race copy ۱۸ + players hub هجده + search guide ۲۲ + /leagues 22nd card (mas, gate-synced cycle-162)"),
])

patch("scripts/cycle152-domproof.sh", [
    ("race copy ۱۸ + players hub هجده + search guide ۲۱ + /leagues 21st card (hnl, gate-synced cycle-161)",
     "race copy ۱۸ + players hub هجده + search guide ۲۲ + /leagues 22nd card (mas, gate-synced cycle-162)"),
])

print("GATESYNC COMPLETE — six scripts synced to the cycle-162 truths")
