#!/usr/bin/env python3
# cycle-447 batch-12 patch: insert the RUSSIA tranche (12 pairs) into TEAM_FA
# and bump the matches cache v13 → v14. Assertive (FAIL LOUD, the 439 pattern):
# every key inserted exactly once, zero key collisions and zero value
# collisions against the WHOLE file, the anchor pair present, the bump exact.
import re, sys

LEAGUES = "src/lib/leagues.ts"
FOTMOB = "src/lib/fotmob.ts"
ANCHOR = '"águilas doradas": "آگیلاس دوراداس",\n};'

PAIRS = [
    ("spartak moscow", "اسپارتاک مسکو"),
    ("cska moscow", "زسکا مسکو"),
    ("lokomotiv moscow", "لوکوموتیو مسکو"),
    ("fc krasnodar", "کراسنودار"),
    ("rubin kazan", "روبین کازان"),
    ("dynamo makhachkala", "دینامو مخاچ\u200cقلعه"),
    ("krylya sovetov samara", "کرلیا سوفیتوف سامارا"),
    ("baltika", "بالتیکا"),
    ("fakel", "فاکل"),
    ("fk akhmat", "اخمت گروزنی"),
    ("akron togliatti", "آکرون تولیاتی"),
    ("fc orenburg", "اورنبورگ"),
]

COMMENT = """  // cycle-447: harvest batch 12 — the machine continues on the 447 census
  // (scripts/cycle430-harvest.py + scripts/c447-pool-sweep.py read EXACTLY
  // 1877 distinct = the documented 446 post-census in BOTH reads, zero drift;
  // rows drifted 3951→3527 — the 435 lesson: rows drift, distinct is
  // decisive; scripts/c447-batch12-verify.py byte-identity gate, live UA
  // Chrome/124): this batch takes ALL 12 count-3 single-country names of the
  // RUSSIA tranche (Premier League + Cup Grp. A-D). The window's tie with
  // GUA (12 names/36 rows/36 day-presence EACH — the honest read) broke on
  // anchor quality + visibility: this is the biggest-club pool in the map's
  // history (Spartak/CSKA/Lokomotiv Moscow, Krasnodar, Rubin) and every name
  // carries a direct Persian-Wikipedia anchor, while GUA is one league with
  // weak anchors — GUA stays next in line, the window decides next cycle
  // (the 435 lesson). The count>=4 multi-country names stay honest-raw
  // (Alianza FC 10/Santa Fe/Libertad/Universidad Católica/Olimpia — the 389
  // identity-first rule; singles Goiás/MB Rouissat wait for their tranches).
  // Transliteration rides the Persian-Wikipedia club articles (SEVEN direct
  // hits this batch — the map's richest): «باشگاه فوتبال اسپارتاک مسکو» (the
  // article spells it اسپارتاک with leading ا — the Persian sp→اسپ rule:
  // اسپانیا/اسپورتینگ), «باشگاه فوتبال زسکا مسکو» (زسکا — the Russian club's
  // fa.wiki title; the file's cska sofia → سسکا صوفیه is the BULGARIAN
  // community's spelling, the divergence is the encyclopedia's own),
  // «باشگاه فوتبال لوکوموتیو مسکو», «باشگاه فوتبال کراسنودار» (FC dropped —
  // the suffix-discipline rule), «باشگاه فوتبال روبین کازان», «باشگاه
  // فوتبال دینامو مخاچ‌قلعه» (the ZWNJ is byte-exact from the city article
  // «مخاچ‌قلعه»; Dynamo → دینامو rides the دینامو درسدن anchor — the
  // Houston MLS داینامو is the English club's own reading), «باشگاه فوتبال
  // بالتیکا کالینینگراد» (Baltika → بالتیکا), «باشگاه فوتبال اورنبورگ» (FC
  // dropped), «باشگاه فوتبال فاکل وورونژ» (the encyclopedia's وورونژ with
  // the DOUBLE و for Russian В — the literal is bare Fakel so the render is
  // فاکل). No fa.wiki article for Krylya Sovetov → کرلیا سوفیتوف سامارا (the
  // Persian press form; the toponym IS in the literal — fa.wiki «سامارا»);
  // Akron Togliatti → آکرون تولیاتی (fa.wiki «تولیاتی»); FK Akhmat → اخمت
  // گروزنی (the Persian press form + the file's crvena-zvezda → ستاره سرخ
  // بلگراد add-toponym precedent; the club's fa.wiki article is «احمد
  // گروزنی» — the renamed Terek, same club, the render keeps the feed's own
  // Akhmat transliteration). Collision gate: zero key and zero value
  // collisions against the whole file (no Logroñés case this batch).
  // Loud-pool rule: the documented 1877 census shrinks by this batch in the
  // open (the B4 ±25 band re-anchors with the next census, never silently).
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
c13 = f.count("matches:v13:")
if c13 != 1:
    fail(f"matches:v13 occurrences = {c13} (want 1)")
OLD_C = """  // cycle-446: v13 — harvest batch 11 (13 more names, the Colombia tranche:
  // Primera A + Primera B) changed the normalized team-fa content again;
  // same rule, fresh cold window (v12 L2 rows purged + official restart).
  return cached(`matches:v13:${dateYYYYMMDD}`, ttl, async () => {"""
NEW_C = """  // cycle-446: v13 — harvest batch 11 (13 more names, the Colombia tranche:
  // Primera A + Primera B) changed the normalized team-fa content again;
  // same rule, fresh cold window (v12 L2 rows purged + official restart).
  // cycle-447: v14 — harvest batch 12 (12 more names, the Russia tranche:
  // Premier League + Cup Grp. A-D) changed the normalized team-fa content
  // again; same rule, fresh cold window (v13 L2 rows purged + official
  // restart).
  return cached(`matches:v14:${dateYYYYMMDD}`, ttl, async () => {"""
if f.count(OLD_C) != 1:
    fail("fotmob v13 context block not found exactly once")
f = f.replace(OLD_C, NEW_C, 1)
open(FOTMOB, "w", encoding="utf-8").write(f)
print("fotmob.ts: matches cache v13 → v14")
print("PATCH OK: 12 pairs + cache bump")
