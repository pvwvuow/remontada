# cycle-482 batch-31 pre/post verification (the 446..480 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased) and single-country across the whole ±7 window (the 389 rule).
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole file (the Logroñés rule). Batch 31 = the RUS tranche (ALL 6
# count>=3 single-country RUS names of the FRESH 482 census) — the NEW
# two-way tie RUS 6 = CRC 6 (both zero (W); ESP 6 four (W) -> 2 effective,
# ENG 7 five (W) -> 2 effective — the 435 rule) broken by the FRESH 447
# re-read (the 472 CZE-vs-ISR / 477 ALB-vs-PAR precedents): RUS FIVE direct
# identity-verified fa.wiki club articles vs CRC TWO — RUS harvests, CRC
# waits. The census (scripts/c482-census.py): pre-patch distinct=1664/
# raw_rows=2931 == the B4 anchor EXACTLY (zero pool drift; only −7
# long-tail rows). The FIVE direct anchors (extracts verified Russian-club
# fresh, the FC rule minus the باشگاه فوتبال prefix, renders derived
# BYTE-EXACT from the anchor titles): FC Yenisey Krasnoyarsk → ینی‌سئی
# کراسنویارسک (باشگاه فوتبال ینی‌سئی کراسنویارسک 4982538 «یک باشگاه
# فوتبال در شهر کراسنویارسک در کشور روسیه است… ۱۹۳۷» — the ZWNJ inside
# ینی‌سئی byte-carried) / Nizhny Novgorod → نیژنی نووگورود (باشگاه فوتبال
# نیژنی نووگورود 5972164, Q20740338 — the A-stage entity search missed the
# football form; "FC Nizhny Novgorod" surfaced it; «یک باشگاه فوتبال روسی
# است که در شهر نیژنی نووگورود قرار دارد… ۲۰۱۵» — also the 461
# city-grounded toponym) / SKA-Khabarovsk → زسکا خاباروفسک (باشگاه فوتبال
# زسکا خاباروفسک 4982452 «…یک باشگاه فوتبال نظامی در شهر خاباروفسک در
# کشور روسیه است… ۱۹۴۶» — the anchor's OWN title spells СКА «زسکا», the
# 475 own-title-wins lesson) / Spartak Kostroma → اسپارتاک کوستروما
# (باشگاه فوتبال اسپارتاک کوستروما 6980851 «یک باشگاه فوتبال روسی در
# کوستروما است… ۱۹۵۹») / Volga Ulyanovsk → ولگا اولیانوفسک (باشگاه فوتبال
# ولگا اولیانوفسک 4983513 «یک باشگاه فوتبال در شهر اولیانوفسک کشور روسیه
# است… ۱۹۴۷» — found by the fa.wiki SEARCH title, identity verified on
# the re-probe; the first extract read was a transient empty API response,
# the redirects=1 retry verified). Zero-anchor honest read (the 452..480
# precedent; Q54871945 FC Leningradets Leningrad Oblast proves the Russian
# football identity AND the fa-sitelink absence; the fa search hits only
# an irrelevant player page — the 466 UPNFM rule): Leningradets →
# لنینگرادتس (pure phonetic; the A-stage wikidata hit Q139743117 was an
# ICE HOCKEY club — never consulted). CRC 6 (the loser half: هردیانو
# 43799355 + پونتاریناس 41367382 the two direct anchors) waits per the
# loser-waits rule. POST mode (--post): after the patch, the same names
# must render PERSIAN in the live ±7 feed (zero raw literals left for
# this batch).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "FC Yenisey Krasnoyarsk", "Leningradets", "Nizhny Novgorod",
    "SKA-Khabarovsk", "Spartak Kostroma", "Volga Ulyanovsk",
]

post = "--post" in sys.argv

PROPOSED = {
    "fc yenisey krasnoyarsk": "ینی\u200cسئی کراسنویارسک",
    "leningradets": "لنینگرادتس",
    "nizhny novgorod": "نیژنی نووگورود",
    "ska-khabarovsk": "زسکا خاباروفسک",
    "spartak kostroma": "اسپارتاک کوستروما",
    "volga ulyanovsk": "ولگا اولیانوفسک",
}


def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)


# ---- the whole file, byte-read (collision gate, the Logroñés rule)
src = open("src/lib/leagues.ts", encoding="utf-8").read()
pairs = re.findall(r'"((?:[^"\\]|\\.)+)":\s*"([^"]+)"', src)
file_keys = {}
for k, v in pairs:
    file_keys.setdefault(k, []).append(v)

if not post:
    print("== PRE: byte-exact live-literal keys + single-country ±7 ==")
    bad = 0
    samples = []
    for cand in CANDIDATES:
        key = cand.lower()
        seen_rows = 0
        ccs = set()
        sample = None
        for o in range(-7, 8):
            d = fetch(f"{BASE}/api/matches?offset={o}")
            for g in d.get("groups", []):
                for m in g.get("matches", []):
                    for side in ("home", "away"):
                        t = m.get(side) or {}
                        nm = t.get("fa") or t.get("name") or ""
                        if nm == cand:
                            seen_rows += 1
                            ccs.add(g.get("ccode") or "")
                            sample = sample or m.get("id")
        ok = seen_rows >= 3 and len(ccs) == 1 and "RUS" in ccs
        print(f"  {cand!r} key={key!r} rows={seen_rows} cc={sorted(ccs)} "
              f"sample={sample} -> {'OK' if ok else 'BAD'}")
        samples.append(sample)
        if not ok:
            bad += 1
        if key in file_keys:
            print(f"    !! key already in file: {key}")
            bad += 1
    print(f"PRE-VERIFY: {len(CANDIDATES)-bad}/{len(CANDIDATES)} verified, {bad} bad")
    print(f"sample ids: {sorted(s for s in samples if s)}")

# ---- collision gate (always) ----
print("== COLLISION GATE ==")
dup_keys = [k for k, v in file_keys.items() if len(v) > 1]
all_vals = {}
val_dups = []
for k, v in pairs:
    if v in all_vals and all_vals[v] != k:
        val_dups.append((v, all_vals[v], k))
    all_vals.setdefault(v, k)
for k in PROPOSED:
    hits = file_keys.get(k)
    if hits:
        print(f"  !! proposed key already present: {k} -> {hits}")
for k, v in PROPOSED.items():
    if v in all_vals:
        print(f"  !! proposed VALUE collision: {v!r} already = {all_vals[v]!r}")
print(f"  file pairs read: {len(pairs)}; dupKeys={dup_keys[:5]}; "
      f"valueCollisions={val_dups[:5]}")

# ---- POST: zero raw literals for the batch in the live ±7 feed ----
if post:
    print("== POST: zero raw literals in the live ±7 feed ==")
    leak = 0
    renders = {}
    for o in range(-7, 8):
        d = fetch(f"{BASE}/api/matches?offset={o}")
        for g in d.get("groups", []):
            for m in g.get("matches", []):
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    nm = t.get("fa") or t.get("name") or ""
                    for cand in CANDIDATES:
                        if nm == cand:
                            leak += 1
                            print(f"  RAW LEAK {o:+d}: {cand} in {m.get('id')}")
                        key = cand.lower()
                        if nm == PROPOSED[key]:
                            renders[cand] = renders.get(cand, 0) + 1
    print(f"  raw leaks = {leak}")
    for cand in CANDIDATES:
        print(f"  {cand} -> {PROPOSED[cand.lower()]} renders {renders.get(cand, 0)}")
    sys.exit(0 if leak == 0 else 1)

print("saved nothing to /tmp (the domproof embeds the pairs in-repo)")
