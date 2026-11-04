#!/usr/bin/env python3
# cycle-490 batch-36 patch — append-only into TEAM_FA (src/lib/leagues.ts):
# the BLR tranche (ALL 4 count>=3 single-country BLR names of the FRESH 490
# census) + the in-block comment carrying the full evidence chain (a NEW
# line in the chain — the 483 chain-repair lesson: never inherit the
# previous batch's text). Cache: matches v39 → v40 comment APPENDED in
# src/lib/fotmob.ts (fresh cold window). Zero other touches.
import io

PAIRS_BLOCK = '''  // cycle-490: batch 36 — ALL 4 count>=3 single-country BLR names of the
  // FRESH 490 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // SIX-WAY 4-tie by the 447 ANCHOR COUNT: BLR 3 direct anchors vs GRE 2 /
  // SVK 2 / SLV 2 / SVN 1 / FIN 1 — the 487 loser-waits precedent REVERSED:
  // BLR waited at 487 when CHI won the equal-count quality tie (the CRC
  // 482→483 / RSA 485→486 precedents), now it harvests alone (the 472
  // CZE-vs-ISR / 477 ALB-vs-PAR / 482 RUS-vs-CRC / 485 DEN-vs-RSA
  // precedents). The fresh census (scripts/c490-census.py, the 447
  // live-re-read lesson): pre-patch distinct=1638/raw_rows=2857 == the B4
  // anchor EXACTLY (zero pool drift — the 489 fix touched only the LEAGUES
  // catalog); the tranche zero (W); ENG 7 five (W) → 2 effective, ESP 6
  // four (W) → 2 effective, INT 4 fully (W) → 0 effective (the 435 rule;
  // the SIX-way 4-tie GRE/SVK/BLR/SVN/FIN/SLV confirmed fresh — the 489
  // rotation line's «BLR 4 alone at the top» dissolved into the tie and
  // the fresh anchor count re-decided it). The 447 scoreboard re-counted
  // fresh per country (scripts/c490-wiki-probe + probe2): BLR 3 (بلشیتا
  // بابرویسک 4982515 + دینامو مینسک 3189380 + مکسلاین ویتبسک 6968310 — the
  // ML Vitebsk anchor surfaced by the fa-search fallback AGAIN, extract
  // verified the CURRENT Maxline club «یک باشگاه فوتبال مستقر در ویتبسک،
  // بلاروس است که در حال حاضر در لیگ برتر بلاروس… به رقابت می‌پردازد»; the
  // 1960 FC Vitebsk same-city namesake 4983516 re-surfaced by the SAME
  // search and rejected AGAIN — the AmaZulu trap class) / GRE 2 (لاریسا
  // 3892127 + آترومیتوس 3438822; «باشگاه فوتبال مارکو» re-proven the
  // PORTUGUESE Marco de Canaveses club — the 487 rejection stands) / SVK 2
  // (کوشیتسه 6386288 + دوکلا بانسکا بیستریتسا 6386207 — the Dukla anchor
  // re-surfaced by the fa-search fallback, extract verified the CURRENT
  // club) / SLV 2 (پلاتینزه 6438277 + ایسیدرو متاپان 6638134; Cacahuatique/
  // Fuerte zero-anchor) / SVN 1 (المپیا لیوبلیانا 6417931) / FIN 1 (اینتر
  // تورکو 5972064; the ICE-HOCKEY HJK Q5477766 entity hit re-surfaced and
  // rejected — the 482 trap class). THREE direct anchors, every render
  // BYTE-DERIVED from the anchor's OWN title (the FC rule minus the
  // باشگاه-فوتبال prefix, the اشدود/آمازولو precedent): Belshina Bobruisk →
  // بلشیتا بابرویسک (باشگاه فوتبال بلشیتا بابرویسک 4982515 «یک باشگاه
  // فوتبال در شهر بابرویسک بلاروس است. این باشگاه در لیگ دسته اول فوتبال
  // بلاروس بازی می‌کند. این باشگاه در سال ۱۹۷۶ تأسیس شده‌است») / Dinamo
  // Minsk → دینامو مینسک (باشگاه فوتبال دینامو مینسک 3189380 «در مینسک،
  // پایتخت کشور بلاروس واقع شده است… دینامو مینسک هفت مرتبه قهرمان لیگ
  // برتر فوتبال بلاروس») / ML Vitebsk → مکسلاین ویتبسک (باشگاه فوتبال
  // مکسلاین ویتبسک 6968310 — the ex-Dnepr Rogachev club Q281780, NOT the
  // 1960 FC Vitebsk Q846362). ONE zero-anchor honest read (the 452..489
  // precedent; the feed's own single-country BLR tagging is the identity
  // evidence, the 466 UPNFM rule): Isloch → ایسلوچ (Q11624718 P17=Q184
  // proves the Belarusian identity AND the fa-sitelink absence; the fa
  // club searches player-noise only — «گریگور آقکیان»; the spelling pure
  // phonetic, the آرهوس-فرماد 485 precedent). Byte-verify
  // (scripts/c490-batch36-verify.py): PRE 4/4 verified 0 bad, every name
  // single-country BLR across the whole ±7 window (3 rows each, sample
  // ids 5215479-5215481); the collision gate clean: dupKeys=[] and zero
  // proposed collisions (the five flagged valueCollisions the intentional
  // league-name homoglyphs, the 465..489 precedent), 2337 → 2341 file
  // pairs. Cache: matches v39 → v40 per the standing rule (fresh cold
  // window), the comment chain APPENDED as a new line (the 483
  // chain-repair lesson — never inherit the previous batch's text).
  // Patrol: B4 re-anchored 1638→1634 (the loud-pool rule — the post-patch
  // census MEASURED 1634, the −4 = the 4 harvested + 0 pool drift) + B41
  // NEW (the four batch-36 witnesses Persian in the live ±7 feed — the
  // patrol now runs 80 checks).
  "belshina bobruisk": "بلشیتا بابرویسک",
  "dinamo minsk": "دینامو مینسک",
  "isloch": "ایسلوچ",
  "ml vitebsk": "مکسلاین ویتبسک",
'''

CACHE_LINE = ("  // cycle-490: v40 — harvest batch 36 (4 more names, the BLR tranche: "
              "the WINNER of the SIX-WAY 4-tie by the fresh 447 anchor count, "
              "BLR 3 vs GRE/SVK/SLV 2) changed the normalized team-fa content "
              "again; same rule, fresh cold window (v39 L2 rows purged + "
              "official restart).\n")

# 1) leagues.ts — insert before the TEAM_FA closing brace (the "unión la
# calera" pair is the last; the closing `};` follows it).
path = "src/lib/leagues.ts"
src = io.open(path, encoding="utf-8").read()
anchor = '  "unión la calera": "یونیون لا کالرا",\n};'
assert src.count(anchor) == 1, "TEAM_FA closing anchor not found"
replacement = ('  "unión la calera": "یونیون لا کالرا",\n' + PAIRS_BLOCK + "};")
src = src.replace(anchor, replacement)
io.open(path, "w", encoding="utf-8").write(src)
print("leagues.ts: batch-36 block inserted")

# 2) fotmob.ts — append the v40 chain line right after the v39 line.
path2 = "src/lib/fotmob.ts"
src2 = io.open(path2, encoding="utf-8").read()
anchor2 = ("  // cycle-487: v39 — harvest batch 35 (4 more names, the CHI tranche: "
           "the WINNER of the FIRST equal-count 447 tie, CHI 3 vs BLR 3 by the "
           "447 original's quality+visibility rule) changed the normalized "
           "team-fa content again; same rule, fresh cold window (v38 L2 rows "
           "purged + official restart).\n")
assert src2.count(anchor2) == 1, "v39 cache line not found"
src2 = src2.replace(anchor2, anchor2 + CACHE_LINE)
io.open(path2, "w", encoding="utf-8").write(src2)
print("fotmob.ts: matches cache chain appended v39 -> v40")
