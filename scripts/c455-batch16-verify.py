#!/usr/bin/env python3
# cycle-455 batch-16 pre/post verification (the 446/447/450/451/452 gate).
# PRE mode: every intended TEAM_FA key must be byte-exact (the live feed
# literal, lowercased for the key) and single-country across the whole ±7
# window (the 389 rule: identity first, no guessing). Also runs the
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole teamFa file (the Logroñés rule) — byte-read from src/lib/leagues.ts.
# Batch 16 = the AUSTRIA tranche (all 10 count-3 single-country AUT names of
# the 455 census — Bundesliga + 2. Liga; the 447 tie-break winner: 3 direct
# fa.wiki club articles vs POL 0 / UKR 1 / MNE 2, documented as read; no
# exclusions).
# POST mode (--post): after the patch, the same names must render PERSIAN
# in the live ±7 feed (zero raw literals left for this batch).
# cycle-454 note (applies here too): PRE mode is ONE-SHOT — it only works
# BEFORE the batch ships. POST (--post) is the repeatable half. No domproof
# depends on this script's /tmp output (the 453 finding): the 455 domproof
# embeds the expected pairs and reads the in-repo block.
import json, re, subprocess, sys, time

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Altach", "Austria Wien", "FC Hertha Wels", "FC Wacker Innsbruck",
    "First Vienna FC", "Grazer AK", "Ried", "SW Bregenz", "WSG Tirol",
    "Wolfsberger AC",
]

post = "--post" in sys.argv


def window():
    seen = {}
    for o in range(-7, 8):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "40", "-A", UA,
             f"{BASE}/api/matches?offset={o}"],
            capture_output=True, text=True, timeout=60).stdout
        d = json.loads(out)
        day = str(d.get("date") or o)
        for g in d.get("groups", []):
            lg = g.get("leagueName") or ""
            lid = g.get("leagueId")
            cc = g.get("ccode") or ""
            for m in g.get("matches", []):
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    n = t.get("name") or ""
                    if n in CANDIDATES and n not in seen:
                        seen[n] = {"cc": set(), "rows": 0, "days": set(),
                                   "leagues": set(), "sampleId": lid,
                                   "sampleDate": day}
                    if n in seen:
                        e = seen[n]
                        if cc:
                            e["cc"].add(cc)
                        e["rows"] += 1
                        e["days"].add(day)
                        e["leagues"].add(lg)
        time.sleep(0.15)
    return seen


if post:
    seen = {}
    for o in range(-7, 8):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "40", "-A", UA,
             f"{BASE}/api/matches?offset={o}"],
            capture_output=True, text=True, timeout=60).stdout
        d = json.loads(out)
        for g in d.get("groups", []):
            for m in g.get("matches", []):
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    rendered = t.get("fa") or t.get("name") or ""
                    if rendered and not PERSIAN.search(rendered):
                        seen[rendered] = seen.get(rendered, 0) + 1
        time.sleep(0.15)
    # POST: the RENDERED name must be Persian; a raw leak = the English
    # literal still being served as the rendered name (the sweep's own
    # fa||name field — the pre-fix POST read the always-English name field
    # and false-FAILED; the product was already green)
    leaks = [c for c in CANDIDATES if c in seen]
    print(f"post-mode raw leaks: {len(leaks)} {leaks}")
    sys.exit(1 if leaks else 0)

seen = window()
ok, bad = [], []
for cand in CANDIDATES:
    e = seen.get(cand)
    if not e:
        bad.append((cand, "ABSENT from the live ±7 window"))
        continue
    if len(e["cc"]) != 1:
        bad.append((cand, f"MULTI-COUNTRY {sorted(e['cc'])}"))
        continue
    if sorted(e["cc"])[0] != "AUT":
        bad.append((cand, f"NOT-AUT {sorted(e['cc'])}"))
        continue
    key = cand.lower().strip()
    ok.append((cand, key, e["rows"], sorted(e["cc"])[0], len(e["days"])))

print(f"candidates={len(CANDIDATES)} verified={len(ok)} bad={len(bad)}")
for name, why in bad:
    print(f"  BAD {name}: {why}")
out = [{"key": k, "literal": n, "rows": r, "cc": c, "days": d}
       for n, k, r, c, d in ok]
json.dump(out, open("/tmp/c455-verified.json", "w"), ensure_ascii=False)
total_rows = sum(x["rows"] for x in out)
print(f"total live leak rows covered = {total_rows}")

# collision gate (the 449/451 rule): keys unique within the file block AND
# each BATCH value appears EXACTLY ONCE as a value in the whole teamFa block
src = open("src/lib/leagues.ts", encoding="utf-8").read()
m = re.search(r"const TEAM_FA[^=]*= \{([\s\S]*?)\n\};", src)
if not m:
    print("BAD could not locate TEAM_FA block")
    sys.exit(1)
block = m.group(1)
pairs = re.findall(r'"((?:[^"\\]|\\.)+)":\s*"((?:[^"\\]|\\.)+)"', block)
keys = [p[0] for p in pairs]
vals = [p[1] for p in pairs]
print(f"teamFa pairs parsed={len(keys)} dupKeys={len(keys)-len(set(keys))}")
vset = {}
for k, v in pairs:
    vset.setdefault(v, []).append(k)
PROPOSED = {
    "altach": "آلتاخ",
    "austria wien": "آستریا وین",
    "fc hertha wels": "هرتا ولس",
    "fc wacker innsbruck": "واکر اینسبروک",
    "first vienna fc": "فرست ویینا",
    "grazer ak": "گراتس",
    "ried": "رید",
    "sw bregenz": "اس‌دبلیو برگنتس",
    "wsg tirol": "تیرول",
    "wolfsberger ac": "ولفسبرگر",
}
coll = []
for k, v in PROPOSED.items():
    if k in keys:
        coll.append(f"KEY-DUP {k}")
    if v in vset:
        coll.append(f"VALUE-OWNED {v} by {vset[v][:2]}")
print(f"collision gate: {len(coll)} " + (" ".join(coll) if coll else "(clean)"))
sys.exit(1 if (bad or coll) else 0)
