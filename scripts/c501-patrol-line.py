#!/usr/bin/env python3
# cycle-501 patrol patch: B4 re-anchor 1611 → 1609 (the loud-pool rule, the
# MEASURED post-patch census DOUBLE-READ IDENTICAL 1609/2771: −2 distinct =
# the batch-43 harvest, rows −6 harvested +1 the upstream window drift —
# the ±25 tolerance band) + B48 NEW (the two batch-43 witnesses Persian in
# the live ±7 feed) — the patrol now runs 87 checks. The 497 lesson
# APPLIED: every edit replaces a FULL line, never a mid-line splice.
import io

P = "scripts/cycle438-patrol.sh"
src = open(P, encoding="utf-8").read()
orig = src


def swap(old_line, new_line):
    global src
    assert old_line in src, f"missing line: {old_line[:80]!r}"
    assert src.count(old_line) == 1, f"non-unique line: {old_line[:80]!r}"
    src = src.replace(old_line, new_line, 1)


# 1) the B4 python constant (full line)
swap("b4 = 1 if abs(len(team_names) - 1611) <= 25 else 0",
     "b4 = 1 if abs(len(team_names) - 1609) <= 25 else 0")

# 2) the W44 witness set after the W43 definition (full lines)
swap('# cycle-500: B47 — batch-42 witnesses (the ENG tranche, the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT — ENG 2 verified standing articles vs ESP 0 club anchors [La Nucia\'s only fa article is the TOWN, the 491 class])\n'
     'W43 = ["فروم تاون", "ویتبای تاون"]',
     '# cycle-500: B47 — batch-42 witnesses (the ENG tranche, the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT — ENG 2 verified standing articles vs ESP 0 club anchors [La Nucia\'s only fa article is the TOWN, the 491 class])\n'
     'W43 = ["فروم تاون", "ویتبای تاون"]\n'
     '# cycle-501: B48 — batch-43 witnesses (the ESP tranche, the waiting 500 runner-up finally ALONE at the top — both renders the honest 466 zero-anchor reads byte-derived [الچه سی اف ایلیسیتانو pageid 6235403 + the لا نوسیا town 214243])\n'
     'W44 = ["الچه ایلیسیتانو", "لا نوسیا"]')

# 3) the miss44 line after miss43 (full line)
swap("miss43 = [w for w in W43 if w not in fa_set]",
     "miss43 = [w for w in W43 if w not in fa_set]\n"
     "miss44 = [w for w in W44 if w not in fa_set]")

# 4) the b48 assert after b47 (full line)
swap("b47 = 1 if not miss43 else 0",
     "b47 = 1 if not miss43 else 0\nb48 = 1 if not miss44 else 0")

# 5) the B-ASSERTS format tail: add b48 (the whole print is one line —
#    replace its tail fragment as a FULL-CONTEXT unique substring)
swap(' b46={45} b47={46}".format(', ' b46={45} b47={46} b48={47}".format(')
swap('b45, b46, b47))', 'b45, b46, b47, b48))')

# 6) the loop range — the FULL line (the 497 splice lesson)
swap("for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47; do",
     "for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48; do")

# 7) the B4 label (full line)
swap('    4) LBL="team raw pool within the ±25 drift band of the documented 1611 census (re-anchored 500, loud-pool rule)" ;;',
     '    4) LBL="team raw pool within the ±25 drift band of the documented 1609 census (re-anchored 501, loud-pool rule)" ;;')

# 8) the case-47 tail → add case 48 (full line)
swap('    47) LBL="harvest batch-42 witnesses (the ENG tranche — the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT: ENG 2 verified standing articles vs ESP 0 club anchors) all Persian in the live ±7 feed" ;;',
     '    47) LBL="harvest batch-42 witnesses (the ENG tranche — the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT: ENG 2 verified standing articles vs ESP 0 club anchors) all Persian in the live ±7 feed" ;;\n'
     '    48) LBL="harvest batch-43 witnesses (the ESP tranche — the waiting 500 runner-up finally ALONE at the top; both renders the honest 466 zero-anchor reads byte-derived from witnesses) all Persian in the live ±7 feed" ;;')

# 9) the comment block: the cycle-501 re-anchor note after the 500 note +
#    the summary line (full lines)
swap("# B47 NEW: the two batch-42 witnesses Persian in the live ±7 feed. The",
     "# cycle-501 re-anchor (the loud-pool rule): B4 1611 → 1609 (harvest\n"
     "# batch 43, the documented −2 distinct tranche; the MEASURED post-patch\n"
     "# census DOUBLE-READ IDENTICAL 1609/2771 — the ±25 tolerance band, the\n"
     "# −6 rows harvested +1 the upstream window drift). The patrol now runs\n"
     "# 88 checks: A API inventory, B 426 surface + harvest holds (B4 anchor\n"
     "# 1609, B7–B48) + FINDINGS + C1–C14 + D 16-page sweep + E1–E6 gates.\n"
     "# B48 NEW: the two batch-43 witnesses Persian in the live ±7 feed. The")
swap("# A API inventory, B 426 surface + harvest holds (B4 anchor 1611, B7–B47",
     "# A API inventory, B 426 surface + harvest holds (B4 anchor 1609, B7–B48")

assert src != orig
with io.open(P, "w", encoding="utf-8") as fh:
    fh.write(src)
print("patrol patched: B4 → 1609, W44/b48/B48 NEW, loop → 48, labels updated")
