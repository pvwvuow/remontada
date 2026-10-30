#!/usr/bin/env python3
# cycle246-gate-edit.py — precise edits to scripts/cycle245-domproof.sh for
# the cycle-246 census refresh (22→23) + the mas/pg faces (the «»/ZWNJ byte
# lesson: Python exact-match, not Edit-tool guessing).
import io, sys

path = "/home/z/my-project/remontada/scripts/cycle245-domproof.sh"
src = io.open(path, encoding="utf-8").read()

edits = [
    # 1) mas honest face: add the tgm expectation (10 rows)
    (
        '''        if lg=="mas":
            # mas's honest four-block face: tcs=8 (the 240 floor
            # exemption), txg/tposs/tyc honestly empty (the 237/241
            # pair) — the red block is the only OTHER surface
            want=8 if field=="teamCleanSheets" else 0
            if len(rows)!=want: bad.append({"lg":lg,"field":field,"n":len(rows),"why":"mas honest face","want":want})
            continue''',
        '''        if lg=="mas":
            # mas's honest five-block face: tcs=8 (the 240 floor
            # exemption), txg/tposs/tyc honestly empty (the 237/241
            # pair) — the red (245) and goals-per-match (246) blocks
            # are the OTHER surfaces
            want=8 if field=="teamCleanSheets" else 0
            if len(rows)!=want: bad.append({"lg":lg,"field":field,"n":len(rows),"why":"mas honest face","want":want})
            continue''',
    ),
    # 2) add the tgm sweep after the trc sweep
    (
        '''    if not (4<=len(rows)<=10) or not mono or not ranks or latin or not ints:
        bad.append({"lg":lg,"field":"teamRedCards","n":len(rows),"mono":mono,"ranks":ranks,"latin":latin,"ints":ints})
print(json.dumps({"bad":bad},separators=(',',':')))''',
        '''    if not (4<=len(rows)<=10) or not mono or not ranks or latin or not ints:
        bad.append({"lg":lg,"field":"teamRedCards","n":len(rows),"mono":mono,"ranks":ranks,"latin":latin,"ints":ints})
    rows=d.get("teamGoalsPerMatch") or []
    vals=[r.get("teamGoalsPerMatch") for r in rows]
    mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
    ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
    latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
    if len(rows)!=10 or not mono or not ranks or latin:
        bad.append({"lg":lg,"field":"teamGoalsPerMatch","n":len(rows),"mono":mono,"ranks":ranks,"latin":latin})
print(json.dumps({"bad":bad},separators=(',',':')))''',
    ),
    # 3) B1 census 22→23
    (
        '''echo "$B1" | tr -d '\\\\' | grep -q '"h2n":22' \\
  && ok "B1 DOM laliga: h2n=22 [census 21→22 BY DESIGN] + the FIVE team-side blocks adjacent (tyc then trc then xgot) + 10 trc-rows + zero real overflow @390x844" || bad "B1: $B1"''',
        '''echo "$B1" | tr -d '\\\\' | grep -q '"h2n":23' \\
  && ok "B1 DOM laliga: h2n=23 [census refreshed BY DESIGN 22→23 — the 246 team goals-per-match block] + the SIX team-side blocks adjacent + 10 trc-rows + zero real overflow @390x844" || bad "B1: $B1"''',
    ),
    # 4) B4a mas exact h2s list
    (
        '''echo "$B4a" | tr -d '\\\\' | grep -q '"h2s":\\["گل نخرده‌های تیم‌ها","کارت‌های قرمز تیم‌ها","کارت‌ها"\\]' && echo "$B4a" | tr -d '\\\\' | grep -q '"n":6' && echo "$B4a" | tr -d '\\\\' | grep -q '"first":true' \\
  && ok "B4a mas exact face: h2s == [گل نخرده‌های تیم‌ها، کارت‌های قرمز تیم‌ها، کارت‌ها] + 6 trc-rows rank-1 «کوچینگ سیتی» (the file's real current size) — the SECOND mas team-surface renders live" || bad "B4a: $B4a"''',
        '''echo "$B4a" | tr -d '\\\\' | grep -q '"h2s":\\["گل به از مسابقهٔ تیم‌ها","گل نخرده‌های تیم‌ها","کارت‌های قرمز تیم‌ها","کارت‌ها"\\]' && echo "$B4a" | tr -d '\\\\' | grep -q '"n":6' && echo "$B4a" | tr -d '\\\\' | grep -q '"first":true' \\
  && ok "B4a mas exact face: h2s == [گل به از مسابقهٔ تیم‌ها، گل نخرده‌های تیم‌ها، کارت‌های قرمز تیم‌ها، کارت‌ها] + 6 trc-rows rank-1 «کوچینگ سیتی» (the file's real current size) — mas's team surfaces render live" || bad "B4a: $B4a"''',
    ),
    # 5) B4b pg face 0→1
    (
        '''echo "$B4b" | tr -d '\\\\' | grep -q '"teamH2s":0' && echo "$B4b" | tr -d '\\\\' | grep -q '"gp90":true' \\
  && ok "B4b pg zero-team face: zero team h2s (red honestly absent in DOM — the feed-driven honest []) with gp90 still active (the 227 contract)" || bad "B4b: $B4b"''',
        '''echo "$B4b" | tr -d '\\\\' | grep -q '"teamH2s":1' && echo "$B4b" | tr -d '\\\\' | grep -q '"gp90":true' \\
  && ok "B4b pg face [refreshed BY DESIGN — the 246 goals-per-match is pg's FIRST-EVER team surface]: exactly ONE team h2 with gp90 still active (the 227 contract)" || bad "B4b: $B4b"''',
    ),
]

fail = 0
for i, (old, new) in enumerate(edits, 1):
    if old not in src:
        print(f"EDIT {i}: OLD NOT FOUND")
        fail += 1
        continue
    src = src.replace(old, new, 1)
    print(f"EDIT {i}: applied")

if fail:
    sys.exit(1)
io.open(path, "w", encoding="utf-8").write(src)
print("ALL 245-domproof EDITS APPLIED")
