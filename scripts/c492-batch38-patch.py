#!/usr/bin/env python3
# cycle-492 batch-38 patch — append-only into TEAM_FA (src/lib/leagues.ts):
# the FIN tranche (ALL 4 count>=3 single-country FIN names of the FRESH 492
# census) + the in-block comment carrying the full evidence chain (a NEW
# line in the chain — the 483 chain-repair lesson: never inherit the
# previous batch's text). Cache: matches v41 → v42 — BOTH the appended
# comment chain line AND the actual `matches:v41:` constant (the 487
# lesson, applied from the first write). Zero other touches. The patrol
# line is appended to the block comment by c492-patrol-line.py AFTER the
# post-patch census MEASURES the new pool (the loud-pool rule — the 491
# block/patrol 1630-vs-1631 inconsistency lesson, not repeated here).
import io

PAIRS_BLOCK = '''  // cycle-492: batch 38 — ALL 4 count>=3 single-country FIN names of the
  // FRESH 492 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // THREE-WAY 2-tie SVK/FIN/SLV by the 447 QUALITY tie-break (the 491
  // form). The 491 rotation line expected «SVK wins by the anchor count» —
  // the fresh 447 re-count (the 447 live-re-read lesson; the 491 card's
  // own dissolution of the 490 «BLR 4 alone» line)
  // (scripts/c492-wiki-probe.py, 1.8s cadence) DISSOLVED it: the Dukla
  // anchor re-surfaced by the fa-search fallback (the 490 precedent; A0
  // pageid 6386207 extract verified the CURRENT club) → SVK 2 (کوشیتسه
  // 6386288 + دوکلا بانسکا بیستریتسا 6386207); the HJK-FIX — the
  // ICE-HOCKEY Q5477766 entity hit REJECTED (the 482/487 trap class) and
  // the FOOTBALL entity Q208584 explicitly resolved (label Helsingin
  // Jalkapalloklubi, fawiki=باشگاه فوتبال هلسینکی, P17=Q33) — the 487
  // standard → FIN 2 (اینتر تورکو 5972064 + هلسینکی 3318721); SLV 2
  // (پلاتینزه 6438277 + ایسیدرو متاپان 6638134); SVN 1 (المپیا لیوبلیانا
  // 6417931). The three-way 2-tie resolved by the 447 QUALITY tie-break
  // on the anchors' OWN fresh extracts: BOTH FIN anchors state «لیگ برتر
  // فوتبال فنلاند» (a UEFA-member top flight — the exact 491 winning
  // axis) + the record-visibility marker «سابقه ۲۷ قهرمانی در لیگ برتر
  // فوتبال فنلاند و ۱۲ قهرمانی در جام حذفی فوتبال فنلاند» (باشگاه فوتبال
  // هلسینکی) — the strongest visibility evidence of the field; SVK's
  // anchors state the SAME «لیگ دسته اول فوتبال اسلواکی» string the 491
  // card ranked below its winner (the 490 framing «SVK دستهٔ اول»; the
  // «بالاترین سطح» clause present, but the Dukla extract carries the
  // field's ONLY negative quality marker: «از سال ۲۰۱۷ … با مشکلات متعدد
  // اقتصادی») / SLV's «لیگ برتر» the CONCACAF top flight (the 491
  // UEFA-axis ranks it below FIN's UEFA league statements; Isidro's ۱۰
  // domestic titles are real but CONCACAF). FIN harvests; SVK and SLV
  // wait (the 472/477/482/485/487/490/491 loser-waits precedents); SVN 1
  // behind. The fresh census (scripts/c492-census.py, the 447
  // live-re-read lesson): pre-patch distinct=1631/raw_rows=2834 == the B4
  // anchor EXACTLY, zero pool drift (the 491 harvest is the pool's only
  // recent change); the FOUR-way 4-tie SVK/SVN/FIN/SLV confirmed fresh —
  // SLV RETURNED exactly as the 491 rotation line allowed («the window
  // decides, the 435 lesson; it may return»), all four tranches zero
  // (W); ENG 7 five (W) → 2 effective (Frome Town, Whitby), ESP 6 four
  // (W) → 2 effective (Elche Ilicitano, La Nucía), INT 4 fully (W) → 0
  // effective (the 435 rule); KSA/NED/MAR/KUW/BUL/IND/HUN/NGA 2 below
  // the tie. TWO direct anchors, every render BYTE-DERIVED from the
  // anchors' OWN titles (the FC rule minus the باشگاه-فوتبال prefix, the
  // اشدود/آمازولو precedent): FC Inter Turku → اینتر تورکو (باشگاه
  // فوتبال اینتر تورکو 5972064, «سابقه یک قهرمانی در لیگ برتر فوتبال
  // فنلاند») / HJK → هلسینکی (باشگاه فوتبال هلسینکی 3318721, the
  // football entity Q208584, the extract's own parenthetical «به
  // انگلیسی: HJK Helsinki» — the 487 anchor standard). TWO zero-anchor
  // honest reads (the 466 UPNFM rule — the feed's single-country FIN
  // tagging as identity evidence, the آرهوس-فرماد 485 precedent): IF
  // Gnistan → گنیستان (Q5970899 P17=Q33 + the fa-sitelink absence; the
  // «گنیستان» fa hit player-noise only — the ماتیاس سیلتانن page; pure
  // phonetic) / VPS → وی‌پی‌اس (zero club entity, both fa forms zero or
  // noise; the letter-cluster class, the GS→جی‌اس 491 precedent).
  // Byte-verify (scripts/c492-batch38-verify.py): PRE byte-exact keys 4/4
  // + single-country FIN 4/4 (the 389 rule, sample ids 6145887-6145895);
  // the collision gate clean: dupKeys=[] and zero proposed key/value
  // collisions (the five flagged valueCollisions the intentional
  // league-name homoglyphs, the 465..491 precedent), 2345 → 2349 file
  // pairs. Cache: matches v41 → v42 per the standing rule (fresh cold
  // window), the comment chain APPENDED as a new line AND the v41
  // constant renamed (the 487 lesson, applied from the first write).
  "fc inter turku": "اینتر تورکو",
  "hjk": "هلسینکی",
  "if gnistan": "گنیستان",
  "vps": "وی‌پی‌اس",
'''

CACHE_LINE = ("  // cycle-492: v42 — harvest batch 38 (4 more names, the FIN tranche: "
              "the WINNER of the THREE-WAY 2-tie SVK/FIN/SLV by the 447 QUALITY "
              "tie-break — both FIN anchors state «لیگ برتر فوتبال فنلاند» + "
              "the HJK 27-titles record) changed the normalized team-fa content "
              "again; same rule, fresh cold window (v41 L2 rows purged + "
              "official restart).\n")

# 1) leagues.ts — insert before the TEAM_FA closing brace (the batch-37
# "nestos chrisoupolis" pair is the last; the closing `};` follows it).
path = "src/lib/leagues.ts"
src = io.open(path, encoding="utf-8").read()
anchor = '  "nestos chrisoupolis": "نستوس کریسوپولی",\n};'
assert src.count(anchor) == 1, "TEAM_FA closing anchor not found"
replacement = ('  "nestos chrisoupolis": "نستوس کریسوپولی",\n'
               + PAIRS_BLOCK + "};")
src = src.replace(anchor, replacement)
io.open(path, "w", encoding="utf-8").write(src)
print("leagues.ts: batch-38 block inserted")

# 2) fotmob.ts — append the v42 chain line right after the v41 line AND
# rename the v41 cache constant (the 487 lesson: comment + constant).
path2 = "src/lib/fotmob.ts"
src2 = io.open(path2, encoding="utf-8").read()
anchor2 = ("  // cycle-491: v41 — harvest batch 37 (4 more names, the GRE tranche: "
           "the WINNER of the THREE-WAY 2-tie GRE/SVK/SLV by the 447 QUALITY "
           "tie-break — both GRE anchors current Super League Greece) changed "
           "the normalized team-fa content again; same rule, fresh cold window "
           "(v40 L2 rows purged + official restart).\n")
assert src2.count(anchor2) == 1, "v41 cache line not found"
src2 = src2.replace(anchor2, anchor2 + CACHE_LINE)
CONST_OLD = "return cached(`matches:v41:${dateYYYYMMDD}`, ttl, async () => {"
CONST_NEW = "return cached(`matches:v42:${dateYYYYMMDD}`, ttl, async () => {"
assert src2.count(CONST_OLD) == 1, "v41 cache-key constant not found exactly once"
src2 = src2.replace(CONST_OLD, CONST_NEW)
assert src2.count("matches:v41:") == 0, "stale v41 constant survived"
assert src2.count("matches:v42:") == 1, "v42 constant missing"
io.open(path2, "w", encoding="utf-8").write(src2)
print("fotmob.ts: matches cache chain appended v41 -> v42 (comment + constant)")
