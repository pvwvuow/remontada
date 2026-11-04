#!/usr/bin/env python3
# cycle-483 batch-32 patch — purely additive: the 6 CRC pairs appended after
# the batch-31 block inside TEAM_FA (before the closing brace), with the
# in-block comment carrying the full evidence trail (the 446..482 format);
# then the standing one-move cache bump matches v35 → v36 in fotmob.ts.
# The TWO direct-anchor renders are the BYTE-EXACT FC/ورزشی-rule forms
# derived from the anchors' OWN titles; the FOUR honest phonetic reads per
# the 466 rule (the اف‌سی form carries the file's ZWNJ convention).
import re

SRC = "src/lib/leagues.ts"
FOT = "src/lib/fotmob.ts"

COMMENT = """  // cycle-483: batch 32 — ALL 6 count>=3 single-country CRC names of the
  // FRESH 483 census into TEAM_FA (the 446-pick rule) — the 482 rotation
  // line's declared field: the 477/482 tie LOSER finally harvesting ALONE
  // at the top (RUS gone after its 482 harvest; ESP 6 four (W) → 2
  // effective, ENG 7 five (W) → 2 effective — the 435 rule; DEN 5 / RSA 5
  // behind). The fresh census (scripts/c483-census.py, the 447
  // live-re-read lesson): pre-patch distinct=1658/raw_rows=2913 == the B4
  // anchor EXACTLY (zero drift). No tie — the 447 tie-break not needed for
  // SELECTION (the 482 probe already scored CRC 2 direct anchors vs RUS 5;
  // this cycle probes the FOUR remaining names: scripts/c483-wiki-probe.py
  // + the odd-title probe). The TWO direct anchors re-verified fresh with
  // their REAL pageids (the 482 probe printed lastrevids — the harness
  // mislabel documented), extracts verified Costa-Rican-club fresh, the
  // renders BYTE-DERIVED from the anchors' OWN titles: Club Sport
  // Herediano → هردیانو (باشگاه ورزشی هردیانو 6450472 «…معمولاً با نام
  // هردیانو… یک باشگاه چند ورزشی اهل کاستاریکا است… بیشتر به خاطر تیم
  // فوتبالش شناخته می‌شود» — the باشگاه-ورزشی prefix rule) / Puntarenas FC
  // → پونتاریناس (باشگاه فوتبال پونتاریناس 6398501 «یک باشگاه فوتبال
  // کاستاریکایی است که در حال حاضر در لیگ برتر کاستاریکا رقابت می‌کند…»).
  // Zero-anchor honest phonetic reads (the 452..482 precedent; the fa
  // search hits all irrelevant, the odd hit «شرکت عمومی محدود ورزشی»
  // probed and rejected — the Sociedad anónima deportiva corporate-form
  // article, 5473771; Q108179092 Escorpiones F.C. carries NO fawiki
  // sitelink AND no P17 country claim — the feed's own single-country CRC
  // tagging is the identity evidence, the 466 UPNFM rule): Deportiva San
  // Carlos → دپورتیوا سن کارلوس / Escorpiones → اسکورپیونس (the final -s
  // → س, the ترینیدنس convention) / Inter San Carlos → اینتر سن کارلوس /
  // Sporting FC → اسپورتینگ اف\u200cسی (the file's own اف\u200cسی ZWNJ
  // convention — port fc / fc seoul / paris fc). Byte-verify
  // (scripts/c483-batch32-verify.py): PRE 6/6 verified 0 bad, every name
  // single-country CRC across the whole ±7 window (3 rows each, sample ids
  // 5833818-5961130); the collision gate clean: dupKeys=[] and zero
  // proposed collisions (the five flagged valueCollisions the intentional
  // league-name homoglyphs, the 465..482 precedent), 2317 → 2323 file
  // pairs. Cache: matches v35 → v36 per the standing rule (fresh cold
  // window). Patrol: B4 re-anchor + B37 NEW (four batch-32 witnesses
  // Persian in the live ±7 feed — the patrol now runs 76 checks).
"""

PAIRS = [
    ("club sport herediano", "هردیانو"),
    ("deportiva san carlos", "دپورتیوا سن کارلوس"),
    ("escorpiones", "اسکورپیونس"),
    ("inter san carlos", "اینتر سن کارلوس"),
    ("puntarenas fc", "پونتاریناس"),
    ("sporting fc", "اسپورتینگ اف\u200cسی"),
]

s = open(SRC, encoding="utf-8").read()
assert '"volga ulyanovsk": "ولگا اولیانوفسک",' in s, "batch-31 tail not found"
assert "cycle-483: batch 32" not in s, "batch 32 already present"
block = COMMENT + "".join(f'  "{k}": "{v}",\n' for k, v in PAIRS)
anchor = '  "volga ulyanovsk": "ولگا اولیانوفسک",\n'
s2 = s.replace(anchor, anchor + block, 1)
assert s2 != s
open(SRC, "w", encoding="utf-8").write(s2)
print("leagues.ts: batch-32 block appended (6 pairs)")

f = open(FOT, encoding="utf-8").read()
assert "matches:v35:" in f, "v35 marker not found"
f2 = f.replace("matches:v35:", "matches:v36:", 1)
m = re.search(r"// cycle-482: v35[^\n]*", f2)
f2 = f2.replace(m.group(0), m.group(0).replace("cycle-482: v35", "cycle-483: v36"), 1)
open(FOT, "w", encoding="utf-8").write(f2)
print("fotmob.ts: matches cache v35 -> v36")
