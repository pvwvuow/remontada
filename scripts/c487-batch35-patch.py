#!/usr/bin/env python3
# cycle-487 batch-35 patch — append-only into TEAM_FA (src/lib/leagues.ts):
# the CHI tranche (ALL 4 count>=3 single-country CHI names of the FRESH 487
# census) + the in-block comment carrying the full evidence chain (a NEW
# line in the chain — the 483 chain-repair lesson: never inherit the
# previous batch's text). Cache: matches v38 → v39 comment APPENDED in
# src/lib/fotmob.ts (fresh cold window). Zero other touches.
import io

PAIRS_BLOCK = '''  // cycle-487: batch 35 — ALL 4 count>=3 single-country CHI names of the
  // FRESH 487 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // FIRST equal-count 447 tie: CHI 3 direct anchors vs BLR 3, resolved by
  // the 447 original's own equal-count rule (کیفیت لنگر + دید — the RUS/
  // GUA 12/12 precedent): CHI's three anchors are ALL top-flight Primera
  // clubs and its head is Colo Colo «پر افتخارترین باشگاه فوتبال شیلی»,
  // while BLR's Belshina plays D2 («لیگ دسته اول فوتبال بلاروس») — CHI
  // harvests, BLR waits (the CRC 482→483 / RSA 485→486 loser-waits
  // precedents). The fresh census (scripts/c487-census.py, the 447
  // live-re-read lesson): pre-patch distinct=1642/raw_rows=2865 == the B4
  // anchor EXACTLY (zero pool drift — the 486 update touched only
  // TEAM_FA); the tranche zero (W); ENG 7 five (W) → 2 effective, ESP 6
  // four (W) → 2 effective, INT 4 fully (W) → 0 effective (the 435 rule;
  // the seven-way 4-tie GRE/SVK/BLR/SVN/FIN/CHI/SLV confirmed fresh). The
  // 447 scoreboard re-counted fresh per country (scripts/c487-wiki-probe
  // + probe2 + probe3 + probe4): CHI 3 / BLR 3 / GRE 2 (لاریسا 3892127 +
  // آترومیتوس 3438822; the fa hit «باشگاه فوتبال مارکو» is the PORTUGUESE
  // club Marco de Canaveses — the namesake rejected) / SVK 2 (کوشیتسه
  // 6386288 + دوکلا بانسکا بیستریتسا 6386207 — the Dukla anchor surfaced
  // by the fa-search fallback, extract verified the CURRENT club) / FIN 2
  // (اینتر تورکو 5972064 + باشگاه فوتبال هلسینکی via the football entity
  // Q208584 — the ICE-HOCKEY Q5477766 entity hit rejected, the 482 trap
  // class) / SLV 2 (پلاتینزه 6438277 + ایسیدرو متاپان 6638134; P17=Q792
  // label-verified El السالوادور) / SVN 1 (المپیا لیوبلیانا 6417931); BLR
  // 3 = بلشیتا بابرویسک 4982515 + دینامو مینسک 3189380 + مکسلاین ویتبسک
  // 6968310 (the feed's «ML Vitebsk» = Q281780 whose RUSSIAN label is
  // «МЛ Витебск» — the EXACT feed literal; the ex-Dnepr Rogachev club,
  // NOT the 1960 FC Vitebsk Q846362 whose article lacks the ML name — the
  // same-city namesake rejected, the AmaZulu trap class; Isloch its
  // zero-anchor). THREE direct anchors, every render BYTE-DERIVED from
  // the anchor's OWN title (scripts/c487-wiki-probe2.py + probe3, extracts
  // verified Chilean-club fresh): Audax Italiano → آئوداکس ایتالیانو
  // (باشگاه ورزشی آئوداکس ایتالیانو 4336642 «یک باشگاه فوتبال است که در
  // شهر لا فلوریدا شیلی پایه‌گذاری شده‌است» — the باشگاه-ورزشی prefix
  // rule, the هردیانو 483 precedent) / Colo Colo → کولو-کولو (باشگاه
  // فوتبال کولو-کولو 2700443 «یک باشگاه فوتبال در شهر ماکول (شیلی) است که
  // در سال ۱۹۲۵ تاسیس شد… پر افتخارترین باشگاه فوتبال شیلی» — the FC rule
  // minus the باشگاه فوتبال prefix, the hyphen byte-carried, the footba11
  // team page «تیم فوتبال کولو-کولو» the convention; NOT the WOMEN'S
  // namesake Q2979975 the entity stage surfaced — the trap documented)
  // / Coquimbo Unido → کوکیمبو یونیدو (باشگاه فوتبال کوکیمبو یونیدو
  // 6614858 «یک باشگاه فوتبال مستقر در کوکیمبو، شیلی است… لیگ برتر»). ONE
  // zero-anchor honest read (the 452..486 precedent; the feed's own
  // single-country CHI tagging is the identity evidence, the 466 UPNFM
  // rule): Unión La Calera → یونیون لا کالرا (Q719383 P17=Q298 proves the
  // Chilean identity AND the fa-sitelink absence; the fa club searches
  // player-noise only; the spelling the fa.wiki player article ویسنته
  // فرناندز convention «برای باشگاه فوتبال یونیون لا کالرا در لیگ برتر
  // فوتبال شیلی» + footba11.co «آمار تیم یونیون لا کالرا» / futball90;
  // the toponym grounded by the city article لا کالرا). Byte-verify
  // (scripts/c487-batch35-verify.py): PRE 4/4 verified 0 bad, every name
  // single-country CHI across the whole ±7 window (3 rows each, sample
  // ids 1000013237-1000013255); the collision gate clean: dupKeys=[] and
  // zero proposed collisions (the five flagged valueCollisions the
  // intentional league-name homoglyphs, the 465..486 precedent), 2333 →
  // 2337 file pairs. Cache: matches v38 → v39 per the standing rule
  // (fresh cold window), the comment chain APPENDED as a new line (the
  // 483 chain-repair lesson — never inherit the previous batch's text).
  // Patrol: B4 re-anchored 1642→1638 (the loud-pool rule — the post-patch
  // census MEASURED 1638/2865, the −4 = the 4 harvested + 0 pool drift) +
  // B40 NEW (the four batch-35 witnesses Persian in the live ±7 feed —
  // the patrol now runs 79 checks).
  "audax italiano": "آئوداکس ایتالیانو",
  "colo colo": "کولو-کولو",
  "coquimbo unido": "کوکیمبو یونیدو",
  "unión la calera": "یونیون لا کالرا",
'''

CACHE_LINE = ("  // cycle-487: v39 — harvest batch 35 (4 more names, the CHI tranche: "
              "the WINNER of the FIRST equal-count 447 tie, CHI 3 vs BLR 3 by the "
              "447 original's quality+visibility rule) changed the normalized "
              "team-fa content again; same rule, fresh cold window (v38 L2 rows "
              "purged + official restart).\n")

# 1) leagues.ts — insert before the TEAM_FA closing brace (the "siwelele"
# pair is the last; the closing `};` follows it).
path = "src/lib/leagues.ts"
src = io.open(path, encoding="utf-8").read()
anchor = '  "siwelele": "سیوله له",\n};'
assert src.count(anchor) == 1, "TEAM_FA closing anchor not found"
replacement = ('  "siwelele": "سیوله له",\n' + PAIRS_BLOCK + "};")
src = src.replace(anchor, replacement)
io.open(path, "w", encoding="utf-8").write(src)
print("leagues.ts: batch-35 block inserted")

# 2) fotmob.ts — append the v39 chain line right after the v38 line.
path2 = "src/lib/fotmob.ts"
src2 = io.open(path2, encoding="utf-8").read()
anchor2 = ("  // cycle-486: v38 — harvest batch 34 (5 more names, the RSA tranche: "
           "the DEN/RSA tie loser finally harvesting alone at the top) changed "
           "the normalized team-fa content again; same rule, fresh cold window "
           "(v37 L2 rows purged + official restart).\n")
assert src2.count(anchor2) == 1, "v38 cache line not found"
src2 = src2.replace(anchor2, anchor2 + CACHE_LINE)
io.open(path2, "w", encoding="utf-8").write(src2)
print("fotmob.ts: matches cache chain appended v38 -> v39")
