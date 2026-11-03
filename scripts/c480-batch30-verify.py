# cycle-480 batch-30 pre/post verification (the 446..477 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased) and single-country across the whole ±7 window (the 389 rule).
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole file (the Logroñés rule). Batch 30 = the PAR tranche (ALL 7
# count>=3 single-country PAR names of the FRESH 480 census — the 479
# rotation line's declared field: PAR 7 ALONE at the top, the 477 tie
# loser finally harvesting; the fresh census re-read distinct=1671/
# raw_rows=2959 == the B4 anchor, zero drift; RUS/ESP/CRC 6, ENG 7 but
# (W)-skewed to 2 effective — the 435 rule). The Wikimedia 429 wall: the
# probes hit a ~50-minute IP-wide rate limit (fa.wiki action+REST,
# en.wiki, wikidata all HTTP 429 from 06:13 to ~07:04 Tehran; try1..try4
# documented) — cleared at the 51-minute mark, probes re-run at 1.8s
# cadence (scripts/c480-wiki-probe.py + probe2 + the single-title
# re-probe). The TWO direct anchors, both extracts verified Paraguayan-club
# fresh: Cerro Porteño → سرو پورتنیو (Q914086 → باشگاه فوتبال سرو پورتنیو
# 41367502 — the 477-documented pageid RENAMED upstream to the باشگاه-
# prefixed form since the 477 read, the bare spelling now a separate EMPTY
# stub 6956335 — the anchor's OWN title wins, the 475 RENAMED-upstream
# lesson; the FC rule minus the prefix; extract «…اهل پاراگوئه است…
# ۱۹۱۲…») / Guaraní → گوارانی (باشگاه فوتبال گوارانی (پاراگوئه) 6305735
# «یک تیم فوتبال از پاراگوئه است… ۱۹۰۳…» — the FC rule minus the prefix
# AND the (پاراگوئه) disambiguator; the bare گوارانی 7003177 an empty
# stub, never consulted). City-grounded toponym (the 461 مریدا rule):
# Sportivo San Lorenzo → اسپورتیوو سن لورنزو (سن لورنزو (پاراگوئه) 1071973
# the city article grounds the toponym; intro EMPTY — the title still
# evidences the spelling, the 477 Elbasani rule). Zero-anchor honest reads
# (the 452..477 precedent; the wikidata entities prove the Paraguayan
# identity AND the fa-sitelink absence, the fa search hits all irrelevant
# player pages): 2 de Mayo → ۲ د مایو (Q1926287) / Rubio Ñú → روبیو نیو
# (Q603085) / Sportivo Ameliano → اسپورتیوو آملیانو (Q15294976) /
# Sportivo Trinidense → اسپورتیوو ترینیدنس (Q2980011) — pure phonetic, the
# 466 UPNFM rule. POST mode (--post): after the patch, the same names must
# render PERSIAN in the live ±7 feed (zero raw literals left for this
# batch).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "2 de Mayo", "Cerro Porteño", "Guaraní", "Rubio Ñú",
    "Sportivo Ameliano", "Sportivo San Lorenzo", "Sportivo Trinidense",
]

post = "--post" in sys.argv

PROPOSED = {
    "2 de mayo": "۲ د مایو",
    "cerro porteño": "سرو پورتنیو",
    "guaraní": "گوارانی",
    "rubio ñú": "روبیو نیو",
    "sportivo ameliano": "اسپورتیوو آملیانو",
    "sportivo san lorenzo": "اسپورتیوو سن لورنزو",
    "sportivo trinidense": "اسپورتیوو ترینیدنس",
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
        ok = seen_rows >= 3 and len(ccs) == 1 and "PAR" in ccs
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
