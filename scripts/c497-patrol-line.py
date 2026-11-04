#!/usr/bin/env python3
# cycle-497 patrol patch — the loud-pool re-anchor (B4 1618 → 1613, the
# MEASURED post-patch census, double-read identical: −4 harvested + 1
# upstream single-row raw name leaving the ±7 window entirely, the ±25
# tolerance class — the 492 −5 precedent in the same shape) + B46 NEW (the
# four batch-41 witnesses Persian in the live ±7 feed) + the block-comment
# patrol line in leagues.ts (the MEASURED numbers — the 491 lesson).
import io

# ---- 1) leagues.ts: append the patrol line to the batch-41 block comment
path = "src/lib/leagues.ts"
src = io.open(path, encoding="utf-8").read()
anchor = ('  // گروسوپلیه (all pure phonetic).\n'
          '  "olimpija ljubljana":')
assert src.count(anchor) == 1, "batch-41 block tail not found"
patrol_line = (
    "  // Patrol: B4 re-anchored 1618→1613 (the loud-pool rule — the\n"
    "  // post-patch census DOUBLE-READ MEASURED 1613/2782 IDENTICAL, the\n"
    "  // −5 = the 4 harvested + 1 upstream single-row raw name leaving the\n"
    "  // ±7 window entirely, the ±25 tolerance class — the 492 −5 shape,\n"
    "  // the count>=3 field itself clean: ONLY the 4 SVN names exited, zero\n"
    "  // net-new names) + B46 NEW (the four batch-41 witnesses Persian in\n"
    "  // the live ±7 feed — the patrol now runs 85 checks).\n")
src = src.replace(anchor,
                  "  // گروسوپلیه (all pure phonetic).\n" + patrol_line +
                  '  "olimpija ljubljana":')
io.open(path, "w", encoding="utf-8").write(src)
print("leagues.ts: batch-41 block patrol line appended (B4 1613 measured)")

# ---- 2) cycle438-patrol.sh: the re-anchor + B46
path2 = "scripts/cycle438-patrol.sh"
s = io.open(path2, encoding="utf-8").read()

# 2a. the header comment chain: the cycle-497 re-anchor block + the
#     summary line (B4 anchor 1613, B7–B46, 85 checks)
old_chain = ("# patrol now runs 84 checks.\n"
             "# A API inventory, B 426 surface + harvest holds (B4 anchor "
             "1618, B7–B45\n"
             "# batch-4..40 witnesses + the 886f6ff byte-identity), C1–C14 the")
assert s.count(old_chain) == 1, "header chain anchor not found"
new_chain = (
    "# patrol now runs 84 checks.\n"
    "# cycle-497 re-anchor (the loud-pool rule): B4 1618 → 1613 (harvest\n"
    "# batch 41, the SVN tranche — the −4 harvested + 1 upstream single-row\n"
    "# raw name leaving the ±7 window entirely; the post-patch census\n"
    "# DOUBLE-READ MEASURED 1613/2782 IDENTICAL — the ±25 tolerance band,\n"
    "# the 492 −5 shape; the count>=3 field clean: ONLY the 4 SVN names\n"
    "# exited) +\n"
    "# B46 NEW: the four batch-41 witnesses Persian in the live ±7 feed. The\n"
    "# patrol now runs 85 checks.\n"
    "# A API inventory, B 426 surface + harvest holds (B4 anchor 1613, "
    "B7–B46\n"
    "# batch-4..41 witnesses + the 886f6ff byte-identity), C1–C14 the")
s = s.replace(old_chain, new_chain)

# 2b. W42 after W41
old_w41 = ('# cycle-496: B45 — batch-40 witnesses (the SVK tranche, the WINNER of '
           'the SVK/SVN 4-4 tie by the fresh 447 ANCHOR COUNT — SVK 2 '
           '[کوشیتسه + دوکلا-فالبک، فرم ۴۹۰] vs SVN 1 [المپیا])\n'
           'W41 = ["دوکلا بانسکا بیستریتسا", "کوشیتسه", "اسکالیتسا", '
           '"زمپلین میخالوفتسه"]\n')
assert s.count(old_w41) == 1, "W41 anchor not found"
new_w41 = (old_w41 +
           '# cycle-497: B46 — batch-41 witnesses (the SVN tranche, the '
           'LONE-LEADER form — the 496 harvest took SVK out of the raw pool, '
           'SVN 4 ALONE at the top, the 477/482/485 precedent)\n'
           'W42 = ["المپیا لیوبلیانا", "براوو", "نفتا", "برینیه گروسوپلیه"]\n')
s = s.replace(old_w41, new_w41)

# 2c. miss42 after miss41
old_miss = "miss41 = [w for w in W41 if w not in fa_set]\n"
assert s.count(old_miss) == 1, "miss41 anchor not found"
s = s.replace(old_miss, old_miss + "miss42 = [w for w in W42 if w not in fa_set]\n")

# 2d. b46 after b45
old_b45 = "b45 = 1 if not miss41 else 0\n"
assert s.count(old_b45) == 1, "b45 anchor not found"
s = s.replace(old_b45, old_b45 + "b46 = 1 if not miss42 else 0\n")

# 2e. B-SUMMARY: batch41Missing
old_sum = "batch40Missing={miss41}\")"
assert s.count(old_sum) == 1, "B-SUMMARY anchor not found"
s = s.replace(old_sum, "batch40Missing={miss41} batch41Missing={miss42}\")")

# 2f. B-ASSERTS: b46
old_asserts = "b45={44}\".format("
assert s.count(old_asserts) == 1, "B-ASSERTS head not found"
s = s.replace(old_asserts, "b45={44} b46={45}\".format(")
old_args = "b43, b44, b45))"
assert s.count(old_args) == 1, "B-ASSERTS args not found"
s = s.replace(old_args, "b43, b44, b45, b46))")

# 2g. the B4 anchor value 1618 → 1613
old_b4 = "b4 = 1 if abs(len(team_names) - 1618) <= 25 else 0"
assert s.count(old_b4) == 1, "b4 anchor line not found"
s = s.replace(old_b4,
              "b4 = 1 if abs(len(team_names) - 1613) <= 25 else 0")

# 2h. the LBL for check 4
old_lbl4 = ('4) LBL="team raw pool within the ±25 drift band of the '
            'documented 1618 census (re-anchored 496, loud-pool rule)" ;;')
assert s.count(old_lbl4) == 1, "LBL4 not found"
s = s.replace(old_lbl4,
              '4) LBL="team raw pool within the ±25 drift band of the '
              'documented 1613 census (re-anchored 497, loud-pool rule)" ;;')

# 2i. the loop range + the 46 label
old_loop = ("for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 "
            "23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 "
            "45; do")
assert s.count(old_loop) == 1, "loop range not found"
new_loop = old_loop[:-4] + "44 45 46; do"
s = s.replace(old_loop, new_loop)

old_45 = ('45) LBL="harvest batch-40 witnesses (SVK tranche, the WINNER of '
          'the SVK/SVN 4-4 tie by the fresh 447 ANCHOR COUNT — SVK 2 '
          '[کوشیتسه + دوکلا-فالبک، فرم ۴۹۰] vs SVN 1 [المپیا]) all Persian '
          'in the live ±7 feed" ;;')
assert s.count(old_45) == 1, "45 label not found"
s = s.replace(old_45, old_45 + '\n    46) LBL="harvest batch-41 witnesses '
              '(SVN tranche, the LONE-LEADER form — the 496 harvest took SVK '
              'out of the raw pool, SVN 4 ALONE at the top, the 477/482/485 '
              'precedent) all Persian in the live ±7 feed" ;;')

io.open(path2, "w", encoding="utf-8").write(s)
print("cycle438-patrol.sh: B4 1618→1613 + B46 NEW + header chain + labels")
