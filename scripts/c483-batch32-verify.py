# cycle-483 batch-32 pre/post verification (the 446..480 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased) and single-country across the whole ±7 window (the 389 rule).
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole file (the Logroñés rule). Batch 32 = the CRC tranche (ALL 6
# count>=3 single-country CRC names of the FRESH 483 census) — the 482
# two-way tie RUS 6 = CRC 6 (both zero (W); ESP 6 four (W) -> 2 effective,
# ENG 7 five (W) -> 2 effective — the 435 rule) broken by the FRESH 447
# re-read (the 472 CZE-vs-ISR / 477 ALB-vs-PAR precedents): RUS FIVE direct
# identity-verified fa.wiki club articles vs CRC TWO — RUS harvested at
# 482 (its five direct anchors + the honest phonetic Leningradets are
# documented in the c482 harness), and the loser CRC waits and harvests
# NOW, alone at the top. The census (scripts/c483-census.py): pre-patch
# distinct=1658/raw_rows=2913 == the B4 anchor EXACTLY (zero pool drift).
# The TWO direct anchors re-verified fresh with their REAL pageids (the
# 482 probe printed lastrevids — the harness mislabel documented; the
# 482-era labels 43799355/41367382 were the WIKIDATA Qids), extracts
# verified Costa-Rican-club fresh, renders BYTE-DERIVED from the anchors'
# OWN titles: Club Sport Herediano → هردیانو (باشگاه ورزشی هردیانو
# 6450472 «…معمولاً با نام هردیانو… یک باشگاه چند ورزشی اهل کاستاریکا
# است… بیشتر به خاطر تیم فوتبالش شناخته می‌شود» — the باشگاه-ورزشی prefix
# rule) / Puntarenas FC → پونتاریناس (باشگاه فوتبال پونتاریناس 6398501
# «یک باشگاه فوتبال کاستاریکایی است که در حال حاضر در لیگ برتر کاستاریکا
# رقابت می‌کند…»). Zero-anchor honest phonetic reads (the 452..482
# precedent; the fa search hits all irrelevant, the odd hit «شرکت عمومی
# محدود ورزشی» probed and rejected — the Sociedad anónima deportiva
# corporate-form article 5473771; Q108179092 Escorpiones F.C. carries NO
# fawiki sitelink AND no P17 country claim — the feed's own single-country
# CRC tagging is the identity evidence, the 466 UPNFM rule): Deportiva San
# Carlos → دپورتیوا سن کارلوس / Escorpiones → اسکورپیونس (the final -s →
# س, the ترینیدنس convention) / Inter San Carlos → اینتر سن کارلوس /
# Sporting FC → اسپورتینگ اف‌سی (the file's own اف‌سی ZWNJ convention —
# port fc / fc seoul / paris fc). POST mode (--post): after the patch, the
# same names must render PERSIAN in the live ±7 feed (zero raw literals
# left for this batch).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Club Sport Herediano", "Deportiva San Carlos", "Escorpiones",
    "Inter San Carlos", "Puntarenas FC", "Sporting FC",
]

post = "--post" in sys.argv

PROPOSED = {
    "club sport herediano": "هردیانو",
    "deportiva san carlos": "دپورتیوا سن کارلوس",
    "escorpiones": "اسکورپیونس",
    "inter san carlos": "اینتر سن کارلوس",
    "puntarenas fc": "پونتاریناس",
    "sporting fc": "اسپورتینگ اف\u200cسی",
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
        ok = seen_rows >= 3 and len(ccs) == 1 and "CRC" in ccs
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
