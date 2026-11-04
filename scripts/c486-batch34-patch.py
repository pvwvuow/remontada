#!/usr/bin/env python3
# cycle-486 batch-34 patch — purely additive: the 5 RSA pairs appended after
# the batch-33 block inside TEAM_FA (before the closing brace), with the
# in-block comment carrying the full evidence trail (the 446..485 format);
# then the standing one-move cache bump matches v37 → v38 in fotmob.ts —
# the comment chain APPENDED (a new line after the v37 entry), the 483
# chain-repair lesson (never inherit the previous batch's text again).
# The ONE direct-anchor render is the BYTE-EXACT FC-minus-prefix form
# derived from the anchor's OWN title; the FOUR honest reads per the 466
# rule carry the media-verified spellings.
import re

SRC = "src/lib/leagues.ts"
FOT = "src/lib/fotmob.ts"

COMMENT = """  // cycle-486: batch 34 — ALL 5 count>=3 single-country RSA names of the
  // FRESH 486 census into TEAM_FA (the 446-pick rule) — the DEN/RSA 5/5
  // tie LOSER finally harvesting alone at the top (the CRC 482→483 / PAR
  // 477→479 precedents; the 485 rotation line's declared field): the RSA
  // tranche zero (W); ENG 7 five (W) → 2 effective, ESP 6 four (W) → 2
  // effective, INT 4 fully (W) → 0 effective (the 435 rule; GRE/SVK/BLR/
  // SVN/FIN/CHI/SLV 4 behind). The fresh census (scripts/c486-census.py,
  // the 447 live-re-read lesson): pre-patch distinct=1647/raw_rows=2880 ==
  // the B4 anchor EXACTLY (zero pool drift — the 485 update touched only
  // TEAM_FA). The ONE direct anchor, extract verified South-African-club
  // fresh (scripts/c486-wiki-probe2.py), render BYTE-DERIVED from the
  // anchor's OWN title: AmaZulu FC → آمازولو (باشگاه فوتبال آمازولو
  // 6853449 «یک باشگاه فوتبال مستقر در دوربان، آفریقای جنوبی است که در
  // حال حاضر در لیگ برتر فوتبال آفریقای جنوبی…» — the FC rule minus the
  // باشگاه فوتبال prefix, the اشدود precedent; NOT the Zimbabwean
  // Q2840775 namesake, P17=Q954 — the 485 probe already documented the
  // trap and the entity search re-hit it this cycle). FOUR zero-anchor
  // honest reads (the 452..485 precedent; the feed's own single-country
  // RSA tagging is the identity evidence, the 466 UPNFM rule; the spell-
  // ings carry the Persian-media convention): Durban City → دوربان سیتی
  // (no club article; the toponym grounded by the city article دوربان
  // 165952 «نام سومین شهر بزرگ آفریقای جنوبی است» — the 483 اسبیرگ-city
  // precedent; the 1959 namesake Q5316279 P17=Q258 documents the name's
  // RSA identity while the CURRENT 2024 Maritzburg United rebrand has no
  // own entity/sitelink — probed live, scripts/c486-wiki-probe.py) /
  // Lamontville Golden Arrows → لامونتویل گلدن اروز (Q1525804 P17=Q258
  // proves the RSA identity AND the fa-sitelink absence; the لامونتویل
  // fa hits pure noise; «گلدن اروز» the media convention — the
  // footba11.co team page «آمار تیم گلدن اروز · لیگ برتر آفریقای جنوبی»)
  // / Sekhukhune United → سخوخونه یونایتد (Q107615997 description names
  // South Africa AND the fa-sitelink absence; both سخوخونه fa searches
  // zero hits; the iffhs.com/gozaresh3/livescore11 convention سخوخونه
  // یونایتد) / Siwelele → سیوله له (Q135404226 P17=Q258 proves the RSA
  // identity AND the fa-sitelink absence; the fa article سیوله is an
  // Iranian place — not the club; the ورزش۳/ghatreh/khabarfarsi
  // convention سیوله له). Byte-verify (scripts/c486-batch34-verify.py):
  // PRE 5/5 verified 0 bad, every name single-country RSA across the
  // whole ±7 window (3 rows each, sample ids 5955109-1000022915); the
  // collision gate clean: dupKeys=[] and zero proposed collisions (the
  // flagged valueCollisions the intentional league-name homoglyphs, the
  // 465..485 precedent), 2328 → 2333 file pairs. Cache: matches v37 →
  // v38 per the standing rule (fresh cold window; the chain APPENDED as
  // a new line, the 483 chain-repair lesson). Patrol: B4 re-anchor +
  // B39 NEW (the five batch-34 witnesses Persian in the live ±7 feed —
  // the patrol now runs 78 checks).
"""

PAIRS = [
    ("amazulu fc", "آمازولو"),
    ("durban city", "دوربان سیتی"),
    ("lamontville golden arrows", "لامونتویل گلدن اروز"),
    ("sekhukhune united", "سخوخونه یونایتد"),
    ("siwelele", "سیوله له"),
]

s = open(SRC, encoding="utf-8").read()
assert '"fc roskilde": "اف\u200cسی راسکیله",' in s, "batch-33 tail not found"
assert "cycle-486: batch 34" not in s, "batch 34 already present"
block = COMMENT + "".join(f'  "{k}": "{v}",\n' for k, v in PAIRS)
anchor = '  "fc roskilde": "اف\u200cسی راسکیله",\n'
s2 = s.replace(anchor, anchor + block, 1)
assert s2 != s
open(SRC, "w", encoding="utf-8").write(s2)
print("leagues.ts: batch-34 block appended (5 pairs)")

f = open(FOT, encoding="utf-8").read()
assert "matches:v37:" in f, "v37 marker not found"
assert "cycle-486: v38" not in f, "v38 comment already present"
f2 = f.replace("matches:v37:", "matches:v38:", 1)
# APPEND the chain entry after the v37 line (never replace it — the 483 lesson)
m = re.search(r"// cycle-485: v37[^\n]*\n", f2)
assert m, "v37 chain comment not found"
entry = ("  // cycle-486: v38 — harvest batch 34 (5 more names, the RSA tranche: "
         "the DEN/RSA tie loser finally harvesting alone at the top) changed "
         "the normalized team-fa content again; same rule, fresh cold window "
         "(v37 L2 rows purged + official restart).\n")
f2 = f2.replace(m.group(0), m.group(0) + entry, 1)
open(FOT, "w", encoding="utf-8").write(f2)
print("fotmob.ts: matches cache v37 -> v38 (chain line APPENDED)")
