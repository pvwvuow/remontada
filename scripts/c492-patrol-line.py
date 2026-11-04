#!/usr/bin/env python3
# cycle-492 patrol patch — the loud-pool re-anchor (B4 1631 → 1626, the
# MEASURED post-patch census, double-read identical) + B43 NEW (the four
# batch-38 witnesses Persian in the live ±7 feed) + the block-comment
# patrol line in leagues.ts (the MEASURED numbers — the 491 block/patrol
# 1630-vs-1631 inconsistency lesson, not repeated here).
import io

# ---- 1) leagues.ts: append the patrol line to the batch-38 block comment
path = "src/lib/leagues.ts"
src = io.open(path, encoding="utf-8").read()
anchor = ('  // constant renamed (the 487 lesson, applied from the first '
          'write).\n  "fc inter turku":')
assert src.count(anchor) == 1, "batch-38 block tail not found"
patrol_line = (
    "  // Patrol: B4 re-anchored 1631→1626 (the loud-pool rule — the\n"
    "  // post-patch census DOUBLE-READ MEASURED 1626/2820 IDENTICAL, the −5\n"
    "  // = the 4 harvested + 1 upstream pool mutation leaving the ±7 window\n"
    "  // entirely, the ±25 tolerance class — the 491 +1 net-new class in\n"
    "  // reverse) + B43 NEW (the four batch-38 witnesses Persian in the\n"
    "  // live ±7 feed — the patrol now runs 82 checks).\n")
src = src.replace(anchor,
                  "  // constant renamed (the 487 lesson, applied from the first "
                  "write).\n" + patrol_line + '  "fc inter turku":')
io.open(path, "w", encoding="utf-8").write(src)
print("leagues.ts: batch-38 block patrol line appended (B4 1626 measured)")

# ---- 2) cycle438-patrol.sh: the re-anchor + B43
path2 = "scripts/cycle438-patrol.sh"
s = io.open(path2, encoding="utf-8").read()

# 2a. the header comment chain: the cycle-492 re-anchor block + the
#     summary line (B4 anchor 1626, B7–B43, 82 checks)
old_chain = ("# patrol now runs 81 checks.\n"
             "# A API inventory, B 426 surface + harvest holds (B4 anchor "
             "1631, B7–B42\n"
             "# batch-4..37 witnesses + the 886f6ff byte-identity), C1–C14 the")
assert s.count(old_chain) == 1, "header chain anchor not found"
new_chain = (
    "# patrol now runs 81 checks.\n"
    "# cycle-492 re-anchor (the loud-pool rule): B4 1631 → 1626 (harvest\n"
    "# batch 38, the FIN tranche — the −4 harvested + 1 upstream pool\n"
    "# mutation leaving the ±7 window entirely; the post-patch census\n"
    "# DOUBLE-READ MEASURED 1626/2820 IDENTICAL — the 491 +1 net-new class\n"
    "# in reverse, the ±25 tolerance band) +\n"
    "# B43 NEW: the four batch-38 witnesses Persian in the live ±7 feed. The\n"
    "# patrol now runs 82 checks.\n"
    "# A API inventory, B 426 surface + harvest holds (B4 anchor 1626, "
    "B7–B43\n"
    "# batch-4..38 witnesses + the 886f6ff byte-identity), C1–C14 the")
s = s.replace(old_chain, new_chain)

# 2b. W39 after W38
old_w38 = ('# cycle-491: B42 — batch-37 witnesses (the GRE tranche, the WINNER of '
           'the THREE-WAY 2-tie GRE/SVK/SLV by the 447 QUALITY tie-break — both '
           'GRE anchors current Super League Greece)\n'
           'W38 = ["لاریسا", "آترومیتوس", "جی\\u200cاس مارکو", "نستوس کریسوپولی"]\n')
assert s.count(old_w38) == 1, "W38 anchor not found"
new_w38 = (old_w38 +
           '# cycle-492: B43 — batch-38 witnesses (the FIN tranche, the WINNER '
           'of the THREE-WAY 2-tie SVK/FIN/SLV by the 447 QUALITY tie-break — '
           'both FIN anchors state «لیگ برتر فوتبال فنلاند» + the HJK 27-titles '
           'record)\n'
           'W39 = ["اینتر تورکو", "هلسینکی", "گنیستان", "وی\\u200cپی\\u200cاس"]\n')
s = s.replace(old_w38, new_w38)

# 2c. miss39 after miss38
old_miss = "miss38 = [w for w in W38 if w not in fa_set]\n"
assert s.count(old_miss) == 1, "miss38 anchor not found"
s = s.replace(old_miss, old_miss + "miss39 = [w for w in W39 if w not in fa_set]\n")

# 2d. b43 after b42
old_b42 = "b42 = 1 if not miss38 else 0\n"
assert s.count(old_b42) == 1, "b42 anchor not found"
s = s.replace(old_b42, old_b42 + "b43 = 1 if not miss39 else 0\n")

# 2e. B-SUMMARY: batch38Missing
old_sum = "batch36Missing={miss37} batch37Missing={miss38}\")"
assert s.count(old_sum) == 1, "B-SUMMARY anchor not found"
s = s.replace(old_sum, "batch36Missing={miss37} batch37Missing={miss38} "
                       "batch38Missing={miss39}\")")

# 2f. B-ASSERTS: b43
old_asserts = "b41={40} b42={41}\".format("
assert s.count(old_asserts) == 1, "B-ASSERTS head not found"
s = s.replace(old_asserts, "b41={40} b42={41} b43={42}\".format(")
old_args = "b40, b41, b42))"
assert s.count(old_args) == 1, "B-ASSERTS args not found"
s = s.replace(old_args, "b40, b41, b42, b43))")

# 2g. the B4 anchor value 1631 → 1626
old_b4 = "b4 = 1 if abs(len(team_names) - 1631) <= 25 else 0"
assert s.count(old_b4) == 1, "b4 anchor line not found"
s = s.replace(old_b4,
              "b4 = 1 if abs(len(team_names) - 1626) <= 25 else 0")

# 2h. the LBL for check 4
old_lbl4 = ('4) LBL="team raw pool within the ±25 drift band of the '
            'documented 1631 census (re-anchored 491, loud-pool rule)" ;;')
assert s.count(old_lbl4) == 1, "LBL4 not found"
s = s.replace(old_lbl4,
              '4) LBL="team raw pool within the ±25 drift band of the '
              'documented 1626 census (re-anchored 492, loud-pool rule)" ;;')

# 2i. the loop range + the 43 label
old_loop = ("for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 "
            "22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42; do")
assert s.count(old_loop) == 1, "loop range not found"
new_loop = old_loop[:-4] + "41 42 43; do"
s = s.replace(old_loop, new_loop)

old_42 = ('42) LBL="harvest batch-37 witnesses (GRE tranche, the WINNER of '
          'the THREE-WAY 2-tie GRE/SVK/SLV by the 447 QUALITY tie-break — '
          'both GRE anchors current Super League Greece) all Persian in the '
          'live ±7 feed" ;;')
assert s.count(old_42) == 1, "42 label not found"
s = s.replace(old_42, old_42 + '\n    43) LBL="harvest batch-38 witnesses '
              '(FIN tranche, the WINNER of the THREE-WAY 2-tie SVK/FIN/SLV '
              'by the 447 QUALITY tie-break — both FIN anchors state «لیگ '
              'برتر فوتبال فنلاند» + the HJK 27-titles record) all Persian '
              'in the live ±7 feed" ;;')

io.open(path2, "w", encoding="utf-8").write(s)
print("cycle438-patrol.sh: B4 1631→1626 + B43 NEW + header chain + labels")
