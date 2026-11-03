#!/usr/bin/env python3
# cycle-445 batch-10 patch: insert the NORWAY tranche (11 pairs) into TEAM_FA
# and bump the matches cache v11 → v12. Assertive (FAIL LOUD, the 439 pattern):
# every key inserted exactly once, zero key collisions and zero value
# collisions against the WHOLE file, the anchor pair present, the bump exact.
import re, sys, json

LEAGUES = "src/lib/leagues.ts"
FOTMOB = "src/lib/fotmob.ts"
ANCHOR = '"uta arad": "یوتا آراد",\n};'

PAIRS = [
    ("lyn", "لین"),
    ("åsane", "اوسانه"),
    ("hødd", "هود"),
    ("egersund", "اگرسوند"),
    ("sogndal", "سوگندال"),
    ("strømsgodset", "استرومسگودست"),
    ("odds ballklubb", "اودز"),
    ("sandefjord", "سانفیورد"),
    ("kongsvinger", "کونگزوینگر"),
    ("ranheim", "رانهایم"),
    ("hamarkameratene", "هامارکامراتنه"),
]

COMMENT = """  // cycle-445: harvest batch 10 — the machine continues on the 445 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 1909 distinct = the
  // documented 442 post-census, totalRows 3951 on the census read — the 435
  // lesson: rows drift (3948→3951), distinct is decisive;
  // scripts/cycle445-batch10-verify.py byte-identity gate, live UA Chrome/124):
  // this batch takes ALL 11 count-3 single-country names of the NORWAY
  // tranche (1. Divisjon + Cup + Eliteserien — the live ±7 window's biggest
  // single-country pool; the 442/443 rotation lines predicted COL 13 > RUS
  // 12 > GUA 12 > NOR 11, but the window re-ranked and the rivals dropped
  // under 3 — exactly what the 435 lesson demands: the window decides, the
  // prediction does not; no (W) women's sides, no exclusions), 33 live leak
  // rows covered. Transliteration rides the standing Eliteserien block
  // (the 969/971 renders): ø → و (بودو/ترومسو/لیلهستروم) so Hødd = هود; the
  // site's own aalesund → اوله‌سوند anchor gives Å its /oː/ reading (the
  // Ålesund IPA), so Åsane = اوسانه; Strømsgodset = استرومسگودست (the
  // Persian-Wikipedia article title — this batch's ONE direct fa.wiki
  // anchor); Odds Ballklubb = اودز (the literal genitive s kept — the
  // هارتس/رنجرز/کویینز plural rule — with Ballklubb dropped, the BK/IL/FC
  // suffix-discipline rule, the Rosenborg BK → روزنبورگ precedent);
  // Sandefjord = سانفیورد (fjord → فیورد), Kongsvinger = کونگزوینگر,
  // Ranheim = رانهایم (heim → هایم), Hamarkameratene = هامارکامراتنه (the
  // full feed literal, -tene → تنه), Egersund = اگرسوند, Sogndal = سوگندال,
  // Lyn = لین (the Persian press form for the Oslo club). Collision gate:
  // zero key and zero value collisions against the whole file (every club
  // one distinct render — no Logroñés case this batch). Loud-pool rule: the
  // documented 1909 census shrinks by this batch in the open (the B4 ±25
  // band re-anchors with the next census, never silently).
"""

def fail(msg):
    print("FAIL LOUD:", msg)
    sys.exit(1)

s = open(LEAGUES, encoding="utf-8").read()
n = s.count(ANCHOR)
if n != 1:
    fail(f"anchor occurrences = {n} (want 1)")

# collision pre-gate against the whole file (keys and values)
existing_pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', s)
existing_keys = {k for k, _ in existing_pairs}
existing_vals = {}
for k, v in existing_pairs:
    existing_vals.setdefault(v, []).append(k)
for k, v in PAIRS:
    if k in existing_keys:
        fail(f"key collision: {k}")
    if v in existing_vals:
        fail(f"value collision: {v} (already mapped from {existing_vals[v]})")

block = COMMENT + "".join(f'  "{k}": "{v}",\n' for k, v in PAIRS)
new = s.replace(ANCHOR, ANCHOR[:-3] + "\n" + block + "};", 1)
# sanity: each new key exactly once in the whole file
for k, v in PAIRS:
    c = new.count(f'"{k}": "{v}"')
    if c != 1:
        fail(f"insert count for {k} = {c} (want 1)")
if new.count(ANCHOR) != 0:
    fail("anchor survived the replace")
open(LEAGUES, "w", encoding="utf-8").write(new)
print(f"leagues.ts: inserted {len(PAIRS)} pairs, collisions 0/0")

f = open(FOTMOB, encoding="utf-8").read()
c11 = f.count("matches:v11:")
if c11 != 1:
    fail(f"matches:v11 occurrences = {c11} (want 1)")
OLD_C = """  // cycle-442: v11 — harvest batch 9 (16 more names, the Romania Cup
  // Grp. A-D + Liga II + Superliga tranche) changed the normalized team-fa
  // content again; same rule, fresh cold window (v10 L2 rows purged +
  // official restart).
  return cached(`matches:v11:${dateYYYYMMDD}`, ttl, async () => {"""
NEW_C = """  // cycle-442: v11 — harvest batch 9 (16 more names, the Romania Cup
  // Grp. A-D + Liga II + Superliga tranche) changed the normalized team-fa
  // content again; same rule, fresh cold window (v10 L2 rows purged +
  // official restart).
  // cycle-445: v12 — harvest batch 10 (11 more names, the Norway tranche:
  // 1. Divisjon + Cup + Eliteserien) changed the normalized team-fa content
  // again; same rule, fresh cold window (v11 L2 rows purged + official
  // restart).
  return cached(`matches:v12:${dateYYYYMMDD}`, ttl, async () => {"""
if f.count(OLD_C) != 1:
    fail("fotmob v11 context block not found exactly once")
f = f.replace(OLD_C, NEW_C, 1)
open(FOTMOB, "w", encoding="utf-8").write(f)
print("fotmob.ts: matches cache v11 → v12")
print("PATCH OK: 11 pairs + cache bump")
