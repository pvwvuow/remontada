#!/usr/bin/env python3
# cycle-446 batch-11 patch: insert the COLOMBIA tranche (13 pairs) into TEAM_FA
# and bump the matches cache v12 → v13. Assertive (FAIL LOUD, the 439 pattern):
# every key inserted exactly once, zero key collisions and zero value
# collisions against the WHOLE file, the anchor pair present, the bump exact.
import re, sys

LEAGUES = "src/lib/leagues.ts"
FOTMOB = "src/lib/fotmob.ts"
ANCHOR = '"hamarkameratene": "هامارکامراتنه",\n};'

PAIRS = [
    ("envigado", "انویگادو"),
    ("unión magdalena", "یونیون ماگدالنا"),
    ("américa de cali", "آمریکا د کالی"),
    ("boca juniors de cali", "بوکا جونیورز دی کالی"),
    ("chicó fc", "چیکو"),
    ("deportes quindío", "دپورتیس کیندیو"),
    ("deportivo pereira", "دپورتیوو پریرا"),
    ("fortaleza fc", "فورتالسا"),
    ("independiente valle del cauca", "ایندپندینته وایه دل کائوکا"),
    ("real cartagena", "رئال کارتاخنا"),
    ("real cundinamarca", "رئال کوندینامارکا"),
    ("tigres fc", "تیگرس"),
    ("águilas doradas", "آگیلاس دوراداس"),
]

COMMENT = """  // cycle-446: harvest batch 11 — the machine continues on the 446 census
  // (scripts/cycle430-harvest.py re-run + scripts/c446-pool-sweep.py read
  // EXACTLY 1890 distinct = the documented 445 post-census on both reads,
  // rows drifted 3951→3568 between them — the 435 lesson again: rows drift,
  // distinct is decisive; scripts/c446-batch11-verify.py byte-identity gate,
  // live UA Chrome/124): this batch takes ALL 13 single-country names with
  // count>=3 of the COLOMBIA tranche (11 count-3 + Envigado/Unión Magdalena
  // at count-4 — Primera A + Primera B; the 445 rotation line predicted the
  // KSA/AUT/ISR segment to lead but the window re-ranked again and RUS/GUA
  // tied 12 while COL's count≥3 singles reached 13 names/41 live leak rows —
  // the 435 lesson: the window decides, the prediction does not; no (W)
  // women's sides, no exclusions), 41 live leak rows covered. The count>=4
  // multi-country names stay honest-raw (Alianza FC 10/Santa Fe/Libertad/
  // Universidad Católica/Olimpia — the 389 identity-first rule). Transliteration
  // rides this file's own Spanish block: Unión → یونیون (the real unión →
  // رئال یونیون anchor) so Unión Magdalena = یونیون ماگدالنا (fa.wiki
  // «ماگدالنا»); Boca Juniors de Cali = بوکا جونیورز دی کالی (the file's
  // boca juniors → بوکا جونیورز anchor); Deportivo → دپورتیوو (the
  // deportivo pasto → دپورتیوو پاستو COLOMBIAN anchor) so Deportivo Pereira =
  // دپورتیوو پریرا (fa.wiki «پریرا (کلمبیا)»); Independiente → ایندپندینته
  // (the independiente medellín → ایندپندینته مدئین COLOMBIAN anchor) with
  // Valle → وایه riding the file's v→و rule (والنسیا/ویارئال/سلتاویگو/رایو
  // وایکانو) so Independiente Valle del Cauca = ایندپندینته وایه دل کائوکا;
  // Real + toponym full-space (the رئال اویدو/ساراگوسا/خائن rule) so Real
  // Cartagena = رئال کارتاخنا (fa.wiki «کارتاخنا (کلمبیا)» — the j → خ rule)
  // and Real Cundinamarca = رئال کوندینامارکا; Águilas → آگیلاس (the cda
  // águilas fc → آگیلاس anchor) so Águilas Doradas = آگیلاس دوراداس. THREE
  // direct fa.wiki anchors this batch: «انویگادو» (Envigado), «آمریکا د کالی»
  // (América de Cali — the article title spells de → د), «کارتاخنا (کلمبیا)».
  // The FC suffix-discipline rule (the 445 Ballklubb precedent, junior fc →
  // جونیور) drops FC: Chicó FC = چیکو (fa.wiki «چیکو»), Fortaleza FC =
  // فورتالسا (the Persian press form), Tigres FC = تیگرس (the Tigres UANL
  // press form). Deportes Quindío = دپورتیس کیندیو (Deportes plural →
  // دپورتیس; Quindío → کیندیو). Collision gate: zero key and zero value
  // collisions against the whole file (every club one distinct render —
  // «کارتاخنا» alone is FC Cartagena's, ours is «رئال کارتاخنا»). Loud-pool
  // rule: the documented 1890 census shrinks by this batch in the open (the
  // B4 ±25 band re-anchors with the next census, never silently).
"""

def fail(msg):
    print("FAIL LOUD:", msg)
    sys.exit(1)

s = open(LEAGUES, encoding="utf-8").read()
n = s.count(ANCHOR)
if n != 1:
    fail(f"anchor occurrences = {n} (want 1)")

# collision pre-gate against the whole file (keys and values)
existing_pairs = re.findall(r'"([^"]+)":\s*"([^"]+)"', s)
existing_keys = {k for k, _ in existing_pairs}
existing_vals = {}
for k, v in existing_pairs:
    existing_vals.setdefault(v, []).append(k)
for k, v in PAIRS:
    if k in existing_keys:
        fail(f"key collision: {k}")
    if v in existing_vals:
        fail(f"value collision: {v} (already mapped from {existing_vals[v]})")

block = COMMENT + "".join(f'  "{k}": "{v}",\n' for k, v in PAIRS)
new = s.replace(ANCHOR, ANCHOR[:-3] + "\n" + block + "};", 1)
# sanity: each new key exactly once in the whole file
for k, v in PAIRS:
    c = new.count(f'"{k}": "{v}"')
    if c != 1:
        fail(f"insert count for {k} = {c} (want 1)")
if new.count(ANCHOR) != 0:
    fail("anchor survived the replace")
open(LEAGUES, "w", encoding="utf-8").write(new)
print(f"leagues.ts: inserted {len(PAIRS)} pairs, collisions 0/0")

f = open(FOTMOB, encoding="utf-8").read()
c12 = f.count("matches:v12:")
if c12 != 1:
    fail(f"matches:v12 occurrences = {c12} (want 1)")
OLD_C = """  // cycle-445: v12 — harvest batch 10 (11 more names, the Norway tranche:
  // 1. Divisjon + Cup + Eliteserien) changed the normalized team-fa content
  // again; same rule, fresh cold window (v11 L2 rows purged + official
  // restart).
  return cached(`matches:v12:${dateYYYYMMDD}`, ttl, async () => {"""
NEW_C = """  // cycle-445: v12 — harvest batch 10 (11 more names, the Norway tranche:
  // 1. Divisjon + Cup + Eliteserien) changed the normalized team-fa content
  // again; same rule, fresh cold window (v11 L2 rows purged + official
  // restart).
  // cycle-446: v13 — harvest batch 11 (13 more names, the Colombia tranche:
  // Primera A + Primera B) changed the normalized team-fa content again;
  // same rule, fresh cold window (v12 L2 rows purged + official restart).
  return cached(`matches:v13:${dateYYYYMMDD}`, ttl, async () => {"""
if f.count(OLD_C) != 1:
    fail("fotmob v12 context block not found exactly once")
f = f.replace(OLD_C, NEW_C, 1)
open(FOTMOB, "w", encoding="utf-8").write(f)
print("fotmob.ts: matches cache v12 → v13")
print("PATCH OK: 13 pairs + cache bump")
