#!/usr/bin/env python3
# cycle-500 patrol patch: B4 re-anchor 1613 → 1611 (the loud-pool rule,
# the MEASURED post-patch census DOUBLE-READ IDENTICAL 1611/2776) + B47 NEW
# (the two batch-42 witnesses Persian in the live ±7 feed) — the patrol now
# runs 86 checks. The 497 lesson APPLIED: every edit replaces a FULL line,
# never a mid-line splice.
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
swap("b4 = 1 if abs(len(team_names) - 1613) <= 25 else 0",
     "b4 = 1 if abs(len(team_names) - 1611) <= 25 else 0")

# 2) the W43 witness set after the W42 definition (full lines)
swap('# cycle-497: B46 — batch-41 witnesses (the SVN tranche, the LONE-LEADER form — the 496 harvest took SVK out of the raw pool, SVN 4 ALONE at the top, the 477/482/485 precedent)\nW42 = ["المپیا لیوبلیانا", "براوو", "نفتا", "برینیه گروسوپلیه"]',
     '# cycle-497: B46 — batch-41 witnesses (the SVN tranche, the LONE-LEADER form — the 496 harvest took SVK out of the raw pool, SVN 4 ALONE at the top, the 477/482/485 precedent)\n'
     'W42 = ["المپیا لیوبلیانا", "براوو", "نفتا", "برینیه گروسوپلیه"]\n'
     '# cycle-500: B47 — batch-42 witnesses (the ENG tranche, the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT — ENG 2 verified standing articles vs ESP 0 club anchors [La Nucia\'s only fa article is the TOWN, the 491 class])\n'
     'W43 = ["فروم تاون", "ویتبای تاون"]')

# 3) the miss43 line after miss42 (full line)
swap("miss42 = [w for w in W42 if w not in fa_set]",
     "miss42 = [w for w in W42 if w not in fa_set]\nmiss43 = [w for w in W43 if w not in fa_set]")

# 4) the b47 assert after b46 (full line)
swap("b46 = 1 if not miss42 else 0",
     "b46 = 1 if not miss42 else 0\nb47 = 1 if not miss43 else 0")

# 5) the B-ASSERTS format tail: add b47 (the whole print is one line —
#    replace its tail fragment as a FULL-CONTEXT unique substring)
swap(' b45={44} b46={45}".format(', ' b45={44} b46={45} b47={46}".format(')
swap('b44, b45, b46))', 'b44, b45, b46, b47))')

# 6) the loop range — the FULL line (the 497 splice lesson)
swap("for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46; do",
     "for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47; do")

# 7) the B4 label (full line)
swap('    4) LBL="team raw pool within the ±25 drift band of the documented 1613 census (re-anchored 497, loud-pool rule)" ;;',
     '    4) LBL="team raw pool within the ±25 drift band of the documented 1611 census (re-anchored 500, loud-pool rule)" ;;')

# 8) the case-46 tail → add case 47 (full line)
swap('    46) LBL="harvest batch-41 witnesses (SVN tranche, the LONE-LEADER form — the 496 harvest took SVK out of the raw pool, SVN 4 ALONE at the top, the 477/482/485 precedent) all Persian in the live ±7 feed" ;;',
     '    46) LBL="harvest batch-41 witnesses (SVN tranche, the LONE-LEADER form — the 496 harvest took SVK out of the raw pool, SVN 4 ALONE at the top, the 477/482/485 precedent) all Persian in the live ±7 feed" ;;\n'
     '    47) LBL="harvest batch-42 witnesses (the ENG tranche — the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT: ENG 2 verified standing articles vs ESP 0 club anchors) all Persian in the live ±7 feed" ;;')

# 9) the comment block: the cycle-500 re-anchor note after the 497 note +
#    the summary line (full lines)
swap("# B46 NEW: the four batch-41 witnesses Persian in the live ±7 feed. The",
     "# cycle-500 re-anchor (the loud-pool rule): B4 1613 → 1611 (harvest\n"
     "# batch 42, the documented −2 distinct tranche; the MEASURED post-patch\n"
     "# census DOUBLE-READ IDENTICAL 1611/2776 — the ±25 tolerance band, the\n"
     "# −1 row the upstream window drift). The patrol now runs 87 checks:\n"
     "# A API inventory, B 426 surface + harvest holds (B4 anchor 1611,\n"
     "# B7–B47) + FINDINGS + C1–C14 + D 16-page sweep + E1–E6 gates.\n"
     "# B47 NEW: the two batch-42 witnesses Persian in the live ±7 feed. The")
swap("# A API inventory, B 426 surface + harvest holds (B4 anchor 1613, B7–B46",
     "# A API inventory, B 426 surface + harvest holds (B4 anchor 1611, B7–B47")

assert src != orig
open(P, "w", encoding="utf-8").write(src)
print("patrol patched: B4 → 1611, W43/b47/B47 NEW, loop → 47, labels updated")
