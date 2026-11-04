#!/usr/bin/env python3
# cycle-482 batch-31 patch — purely additive: the 6 RUS pairs appended after
# the batch-30 block inside TEAM_FA (before the closing brace), with the
# in-block comment carrying the full evidence trail (the 446..480 format);
# then the standing one-move cache bump matches v34 → v35 in fotmob.ts.
# The Persian renders are the BYTE-EXACT FC-rule forms derived from the
# anchor titles (the ZWNJ inside ینی‌سئی carried via the \u200c escape).
import re

SRC = "src/lib/leagues.ts"
FOT = "src/lib/fotmob.ts"

COMMENT = """  // cycle-482: batch 31 — ALL 6 count>=3 single-country RUS names of the
  // FRESH 482 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // NEW RUS/CRC 6/6 two-way tie (the 481 rotation line's declared field):
  // both tranches zero (W); ESP 6 four (W) → 2 effective, ENG 7 five (W) →
  // 2 effective (the 435 rule). The fresh census (scripts/c482-census.py,
  // the 447 live-re-read lesson): pre-patch distinct=1664/raw_rows=2931 ==
  // the B4 anchor EXACTLY (zero pool drift; −7 long-tail rows only). The
  // 447 tie-break (the 472 CZE-vs-ISR / 477 ALB-vs-PAR precedents): RUS
  // FIVE direct identity-verified fa.wiki club articles vs CRC TWO
  // (هردیانو 43799355 + پونتاریناس 41367382) — RUS harvests, CRC waits.
  // The FIVE direct anchors, all extracts verified Russian-club fresh, the
  // FC rule minus the باشگاه فوتبال prefix, every render derived
  // BYTE-EXACT from the anchor's OWN title (scripts/c482-wiki-probe.py +
  // probe2 + probe3): FC Yenisey Krasnoyarsk → ینی‌سئی کراسنویارسک
  // (4982538 «یک باشگاه فوتبال در شهر کراسنویارسک در کشور روسیه است…
  // ۱۹۳۷» — the ZWNJ inside ینی‌سئی byte-carried) / Nizhny Novgorod →
  // نیژنی نووگورود (5972164, Q20740338 — the A-stage search missed the
  // football form; "FC Nizhny Novgorod" surfaced the sitelink; «یک باشگاه
  // فوتبال روسی است که در شهر نیژنی نووگورود قرار دارد… ۲۰۱۵» — also the
  // 461 city-grounded toponym) / SKA-Khabarovsk → زسکا خاباروفسک (4982452
  // «…یک باشگاه فوتبال نظامی در شهر خاباروفسک در کشور روسیه است… ۱۹۴۶» —
  // the anchor's OWN title spells СКА «زسکا», the 475 own-title-wins
  // lesson) / Spartak Kostroma → اسپارتاک کوستروما (6980851 «یک باشگاه
  // فوتبال روسی در کوستروما است… ۱۹۵۹») / Volga Ulyanovsk → ولگا
  // اولیانوفسک (4983513 «یک باشگاه فوتبال در شهر اولیانوفسک کشور روسیه
  // است… ۱۹۴۷» — the title found by the fa.wiki SEARCH fallback, identity
  // verified on the redirects=1 re-probe; the first extract read was a
  // transient empty API response, documented). Zero-anchor honest read
  // (the 452..480 precedent; Q54871945 FC Leningradets Leningrad Oblast
  // proves the Russian football identity AND the fa-sitelink absence, the
  // fa search hits only an irrelevant player page — the 466 UPNFM rule;
  // the A-stage wikidata hit Q139743117 was an ICE HOCKEY club — never
  // consulted): Leningradets → لنینگرادتس (pure phonetic). Byte-verify
  // (scripts/c482-batch31-verify.py): PRE 6/6 verified 0 bad, every name
  // single-country RUS across the whole ±7 window (3 rows each, sample ids
  // 5897649-5897655); the collision gate clean: dupKeys=[] and zero
  // proposed collisions (the five flagged valueCollisions the intentional
  // league-name homoglyphs, the 465..480 precedent), 2311 → 2317 file
  // pairs. Cache: matches v34 → v35 per the standing rule (fresh cold
  // window). Patrol: B4 re-anchor + B36 NEW (four batch-31 witnesses
  // Persian in the live ±7 feed — the patrol now runs 75 checks).
"""

PAIRS = [
    ("fc yenisey krasnoyarsk", "ینی\u200cسئی کراسنویارسک"),
    ("leningradets", "لنینگرادتس"),
    ("nizhny novgorod", "نیژنی نووگورود"),
    ("ska-khabarovsk", "زسکا خاباروفسک"),
    ("spartak kostroma", "اسپارتاک کوستروما"),
    ("volga ulyanovsk", "ولگا اولیانوفسک"),
]

s = open(SRC, encoding="utf-8").read()
assert '"sportivo trinidense": "اسپورتیوو ترینیدنس",' in s, "batch-30 tail not found"
assert "cycle-482: batch 31" not in s, "batch 31 already present"
block = COMMENT + "".join(f'  "{k}": "{v}",\n' for k, v in PAIRS)
anchor = '  "sportivo trinidense": "اسپورتیوو ترینیدنس",\n'
s2 = s.replace(anchor, anchor + block, 1)
assert s2 != s
open(SRC, "w", encoding="utf-8").write(s2)
print("leagues.ts: batch-31 block appended (6 pairs)")

f = open(FOT, encoding="utf-8").read()
assert "matches:v34:" in f, "v34 marker not found"
f2 = f.replace("matches:v34:", "matches:v35:", 1)
m = re.search(r"// cycle-480: v34[^\n]*", f2)
f2 = f2.replace(m.group(0), m.group(0).replace("cycle-480: v34", "cycle-482: v35"), 1)
open(FOT, "w", encoding="utf-8").write(f2)
print("fotmob.ts: matches cache v34 -> v35")
