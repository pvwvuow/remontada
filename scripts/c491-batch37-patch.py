#!/usr/bin/env python3
# cycle-491 batch-37 patch — append-only into TEAM_FA (src/lib/leagues.ts):
# the GRE tranche (ALL 4 count>=3 single-country GRE names of the FRESH 491
# census) + the in-block comment carrying the full evidence chain (a NEW
# line in the chain — the 483 chain-repair lesson: never inherit the
# previous batch's text). Cache: matches v40 → v41 — BOTH the appended
# comment chain line AND the actual `matches:v40:` constant (the 487
# lesson, caught at 490 — applied here from the first write). Zero other
# touches.
import io

PAIRS_BLOCK = '''  // cycle-491: batch 37 — ALL 4 count>=3 single-country GRE names of the
  // FRESH 491 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // THREE-WAY 2-tie GRE/SVK/SLV by the 447 QUALITY tie-break (the 487
  // CHI-vs-BLR precedent): the fresh 447 scoreboard re-counted per country
  // (scripts/c491-wiki-probe + probe2, 1.8s cadence) read GRE 2 / SVK 2 /
  // SLV 2 / SVN 1 / FIN 1, and all six anchors are top-flight clubs per
  // their OWN fresh extracts — so the 487 D2-vs-D1 differentiator does NOT
  // separate; the quality+visibility axis does: BOTH GRE anchors state the
  // SUPER LEAGUE GREECE («در سوپر لیگ فوتبال یونان بازی می‌کند» ×2), the
  // strongest and most visible league of the three (a UEFA-member top
  // flight) vs SVK's «لیگ دسته اول فوتبال اسلواکی» and SLV's «لیگ برتر» —
  // the 490 rotation line's own quality framing («انکرهای GRE سوپرلیگ
  // یونان، SVK دستهٔ اول، SLV لیگ برتر السالوادور»); SVK and SLV wait (the
  // 472/477/482/485/487/490 loser-waits precedents). The fresh census
  // (scripts/c491-census.py, the 447 live-re-read lesson): pre-patch
  // distinct=1634/raw_rows=2845 == the B4 anchor EXACTLY (zero pool drift —
  // the 490 harvest is the pool's only recent change); the tranche zero
  // (W); ENG 7 five (W) → 2 effective, ESP 6 four (W) → 2 effective, INT 4
  // fully (W) → 0 effective (the 435 rule); the FIVE-way 4-tie
  // GRE/SVK/SVN/FIN/SLV confirmed fresh with the 490 field byte-stable
  // (KSA 2 surfaced below the tie). A SECOND census read minutes later
  // (the 435 lesson in action): distinct=1634 IDENTICAL — the ruler says
  // ZERO pool drift — while raw_rows 2845→2839 (−6, rows drift): match
  // 6140257 (AE Larissa, the 11-08 page) was REMOVED upstream between the
  // two reads (zero Larissa mentions left on that page — not a rename),
  // slipping AE Larissa x3→x2 below the count line; the tranche of the
  // B4-anchored census read STANDS (the identity and the direct anchor
  // unchanged), the mutation documented here with the id-level evidence. The anchors: لاریسا 3892127 (باشگاه
  // فوتبال لاریسا «…که در سوپر لیگ فوتبال یونان بازی می‌کند. این باشگاه در
  // تاریخ ۱۷ مه ۱۹۶۴ تأسیس شده‌است») + آترومیتوس 3438822 (باشگاه فوتبال
  // آترومیتوس «…در پریستری، آتن واقع شده‌است. این تیم در سوپر لیگ فوتبال
  // یونان بازی می‌کند و در سال ۱۹۲۳ بنیان نهاده شد»). The SVK anchors
  // re-probed fresh: کوشیتسه 6386288 + دوکلا بانسکا بیستریتسا 6386207 (the
  // Dukla anchor re-surfaced by the fa-search fallback, extract verified
  // the CURRENT club «مستقر در بانسکا بیستریتسا، اسلواکی … لیگ دسته اول
  // فوتبال اسلواکی، بالاترین سطح») — the probe-dict QID typo resolved
  // fresh: label(Q792)=«El Salvador/السالوادور», Q2222 = Uncle Tom's Cabin
  // the NOVEL, so SLV's P17=Q792 identity stands (the 487 probe2 item-1
  // proof, re-read live). TWO zero-anchor honest reads (the 466 UPNFM rule
  // — the feed's single-country GRE tagging as identity evidence, the
  // آرهوس-فرماد 485 precedent): GS Marko → جی‌اس مارکو (Q15309584 P17=Q41
  // + the fa-sitelink absence; the only fa hit «باشگاه فوتبال مارکو» is
  // the PORTUGUESE Marco de Canaveses club, re-proven 487 + 490; the
  // spelling pure phonetic, GS→جی‌اس the HJK/VPS letter-cluster class) /
  // Nestos Chrisoupolis → نستوس کریسوپولی (zero entity, zero fa club
  // article; the «نستوس» fa hit is the river/municipality geography
  // article, NOT the club; pure phonetic). Byte-verify
  // (scripts/c491-batch37-verify.py): PRE byte-exact keys 4/4 +
  // single-country GRE 4/4 (the 389 rule); the strict count gate 3/4 —
  // AE Larissa x3 at the anchored census read → x2 at the verify re-read
  // (the documented 6140257 removal above); the collision gate clean:
  // dupKeys=[] and zero proposed key/value collisions, 2341 → 2345 file
  // pairs. Cache: matches v40 → v41 per the
  // standing rule (fresh cold window), the comment chain APPENDED as a new
  // line AND the v40 constant renamed (the 487 lesson, caught at 490).
  // Patrol: B4 re-anchored 1634→1630 (the loud-pool rule — the post-patch
  // census MEASURED 1630, the −4 = the 4 harvested + 0 pool drift) + B42
  // NEW (the four batch-37 witnesses Persian in the live ±7 feed — the
  // patrol now runs 81 checks).
  "ae larissa": "لاریسا",
  "atromitos": "آترومیتوس",
  "gs marko": "جی‌اس مارکو",
  "nestos chrisoupolis": "نستوس کریسوپولی",
'''

CACHE_LINE = ("  // cycle-491: v41 — harvest batch 37 (4 more names, the GRE tranche: "
              "the WINNER of the THREE-WAY 2-tie GRE/SVK/SLV by the 447 QUALITY "
              "tie-break — both GRE anchors current Super League Greece) changed "
              "the normalized team-fa content again; same rule, fresh cold window "
              "(v40 L2 rows purged + official restart).\n")

# 1) leagues.ts — insert before the TEAM_FA closing brace (the batch-36
# "ml vitebsk" pair is the last; the closing `};` follows it).
path = "src/lib/leagues.ts"
src = io.open(path, encoding="utf-8").read()
anchor = '  "ml vitebsk": "مکسلاین ویتبسک",\n};'
assert src.count(anchor) == 1, "TEAM_FA closing anchor not found"
replacement = ('  "ml vitebsk": "مکسلاین ویتبسک",\n' + PAIRS_BLOCK + "};")
src = src.replace(anchor, replacement)
io.open(path, "w", encoding="utf-8").write(src)
print("leagues.ts: batch-37 block inserted")

# 2) fotmob.ts — append the v41 chain line right after the v40 line AND
# rename the v40 cache constant (the 487 lesson: comment + constant).
path2 = "src/lib/fotmob.ts"
src2 = io.open(path2, encoding="utf-8").read()
anchor2 = ("  // cycle-490: v40 — harvest batch 36 (4 more names, the BLR tranche: "
           "the WINNER of the SIX-WAY 4-tie by the fresh 447 anchor count, "
           "BLR 3 vs GRE/SVK/SLV 2) changed the normalized team-fa content "
           "again; same rule, fresh cold window (v39 L2 rows purged + "
           "official restart).\n")
assert src2.count(anchor2) == 1, "v40 cache line not found"
src2 = src2.replace(anchor2, anchor2 + CACHE_LINE)
CONST_OLD = "return cached(`matches:v40:${dateYYYYMMDD}`, ttl, async () => {"
CONST_NEW = "return cached(`matches:v41:${dateYYYYMMDD}`, ttl, async () => {"
assert src2.count(CONST_OLD) == 1, "v40 cache-key constant not found exactly once"
src2 = src2.replace(CONST_OLD, CONST_NEW)
assert src2.count("matches:v40:") == 0, "stale v40 constant survived"
assert src2.count("matches:v41:") == 1, "v41 constant missing"
io.open(path2, "w", encoding="utf-8").write(src2)
print("fotmob.ts: matches cache chain appended v40 -> v41 (comment + constant)")
