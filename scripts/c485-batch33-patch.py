#!/usr/bin/env python3
# cycle-485 batch-33 patch — purely additive: the 5 DEN pairs appended after
# the batch-32 block inside TEAM_FA (before the closing brace), with the
# in-block comment carrying the full evidence trail (the 446..483 format);
# then the standing one-move cache bump matches v36 → v37 in fotmob.ts —
# the comment chain APPENDED (a new line after the v36 entry), the 483
# chain-repair lesson (never inherit the previous batch's text again).
# The TWO direct-anchor renders are the BYTE-EXACT ورزشی/FC-rule forms
# derived from the anchors' OWN titles; the THREE honest phonetic reads per
# the 466 rule (the اف‌سی form carries the file's ZWNJ convention).
import re

SRC = "src/lib/leagues.ts"
FOT = "src/lib/fotmob.ts"

COMMENT = """  // cycle-485: batch 33 — ALL 5 count>=3 single-country DEN names of the
  // FRESH 485 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // NEW DEN/RSA 5/5 two-way tie (the 484 rotation line's declared field):
  // both tranches zero (W); ESP 6 four (W) → 2 effective, ENG 7 five (W) →
  // 2 effective (the 435 rule; GRE/SVK/BLR/SVN/FIN/CHI/SLV 4 behind). The
  // fresh census (scripts/c485-census.py, the 447 live-re-read lesson):
  // pre-patch distinct=1652/raw_rows=2895 == the B4 anchor EXACTLY (zero
  // pool drift — the 484 fix touched only the LEAGUES catalog). The 447
  // tie-break (the 472 CZE-vs-ISR / 477 ALB-vs-PAR / 482 RUS-vs-CRC
  // precedents): DEN TWO direct identity-verified fa.wiki club articles vs
  // RSA ONE (آمازولو 6853449 «…مستقر در دوربان، آفریقای جنوبی… لیگ برتر
  // فوتبال آفریقای جنوبی» — probed live, scripts/c485-wiki-probe.py +
  // probe2) — DEN harvests, RSA waits (the CRC 482→483 precedent). The TWO
  // direct anchors, extracts verified Danish-club fresh, renders
  // BYTE-DERIVED from the anchors' OWN titles: AC Horsens → هورسنس
  // (باشگاه ورزشی هورسنس 6217839 «یک باشگاه فعال در سوپر لیگ فوتبال
  // دانمارک است که در شهر هورسنس واقع شده‌است» — the باشگاه-ورزشی prefix
  // rule, the هردیانو 483 precedent) / Esbjerg fB → اسبیرگ (باشگاه فوتبال
  // اسبیرگ 5562829 «یک باشگاه فوتبال است که در اسبیرگ کشور دانمارک
  // پایه‌گذاری شده‌است» — the FC rule minus the باشگاه فوتبال prefix, the
  // fc ashdod → اشدود precedent; the city article اسبیرگ 492488 grounds the
  // toponym). THREE zero-anchor honest reads (the 452..483 precedent; the
  // feed's own single-country DEN tagging is the identity evidence, the
  // 466 UPNFM rule): Aarhus Fremad → آرهوس فرماد (no club entity at all,
  // fa searches player-noise only; آرهوس grounded by the city article
  // 492451 AND the file's own agf → آرهوس mapping, Fremad pure phonetic) /
  // Brabrand → برابرند (Q848827 Brabrand IF proves the Danish identity AND
  // the fa-sitelink absence; the برابرند fa hits pure noise) / FC Roskilde
  // → اف‌سی راسکیله (Q737633 proves the Danish identity AND the sitelink
  // absence; the CITY article راسکیله Q26563 grounds the spelling — the
  // upstream split دانشگاه روسکیلد/فرودگاه راسکیلد settled by the 475
  // own-title-wins lesson; the اف‌سی ZWNJ convention, the 483 sporting-fc
  // precedent). Byte-verify (scripts/c485-batch33-verify.py): PRE 5/5
  // verified 0 bad, every name single-country DEN across the whole ±7
  // window (3 rows each, sample ids 5739540-5864746); the collision gate
  // clean: dupKeys=[] and zero proposed collisions (the five flagged
  // valueCollisions the intentional league-name homoglyphs, the
  // 465..483 precedent), 2323 → 2328 file pairs. Cache: matches v36 → v37
  // per the standing rule (fresh cold window; the chain APPENDED as a new
  // line, the 483 chain-repair lesson). Patrol: B4 re-anchor + B38 NEW
  // (four batch-33 witnesses Persian in the live ±7 feed — the patrol now
  // runs 77 checks).
"""

PAIRS = [
    ("aarhus fremad", "آرهوس فرماد"),
    ("ac horsens", "هورسنس"),
    ("brabrand", "برابرند"),
    ("esbjerg fb", "اسبیرگ"),
    ("fc roskilde", "اف‌سی راسکیله"),
]

s = open(SRC, encoding="utf-8").read()
assert '"sporting fc": "اسپورتینگ اف\u200cسی",' in s, "batch-32 tail not found"
assert "cycle-485: batch 33" not in s, "batch 33 already present"
block = COMMENT + "".join(f'  "{k}": "{v}",\n' for k, v in PAIRS)
anchor = '  "sporting fc": "اسپورتینگ اف\u200cسی",\n'
s2 = s.replace(anchor, anchor + block, 1)
assert s2 != s
open(SRC, "w", encoding="utf-8").write(s2)
print("leagues.ts: batch-33 block appended (5 pairs)")

f = open(FOT, encoding="utf-8").read()
assert "matches:v36:" in f, "v36 marker not found"
assert "cycle-485: v37" not in f, "v37 comment already present"
f2 = f.replace("matches:v36:", "matches:v37:", 1)
# APPEND the chain entry after the v36 line (never replace it — the 483 lesson)
m = re.search(r"// cycle-483: v36[^\n]*\n", f2)
assert m, "v36 chain comment not found"
entry = ("  // cycle-485: v37 — harvest batch 33 (5 more names, the DEN tranche: "
         "the winner of the NEW DEN/RSA two-way tie by the fresh 447 re-read) "
         "changed the normalized team-fa content again; same rule, fresh cold "
         "window (v36 L2 rows purged + official restart).\n")
f2 = f2.replace(m.group(0), m.group(0) + entry, 1)
open(FOT, "w", encoding="utf-8").write(f2)
print("fotmob.ts: matches cache v36 -> v37 (chain line APPENDED)")
