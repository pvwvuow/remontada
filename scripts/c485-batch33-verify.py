# cycle-485 batch-33 pre/post verification (the 446..483 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased) and single-country across the whole ±7 window (the 389 rule).
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole file (the Logroñés rule). Batch 33 = the DEN tranche (ALL 5
# count>=3 single-country DEN names of the FRESH 485 census) — the NEW
# DEN/RSA 5/5 two-way tie (both zero (W); ESP 6 four (W) -> 2 effective,
# ENG 7 five (W) -> 2 effective — the 435 rule) broken by the 447 rule
# (the 472 CZE-vs-ISR / 477 ALB-vs-PAR / 482 RUS-vs-CRC precedents): DEN
# TWO direct identity-verified fa.wiki club articles vs RSA ONE (آمازولو
# 6853449, the Durban South-African identity) — DEN harvested at 485, the
# loser RSA waits (the CRC 482→483 precedent). The census
# (scripts/c485-census.py): pre-patch distinct=1652/raw_rows=2895 == the
# B4 anchor EXACTLY (zero pool drift). The TWO direct anchors, extracts
# verified Danish-club fresh, renders BYTE-DERIVED from the anchors' OWN
# titles: AC Horsens → هورسنس (باشگاه ورزشی هورسنس 6217839 «یک باشگاه
# فعال در سوپر لیگ فوتبال دانمارک است که در شهر هورسنس واقع شده‌است» — the
# باشگاه-ورزشی prefix rule, the هردیانو precedent) / Esbjerg fB → اسبیرگ
# (باشگاه فوتبال اسبیرگ 5562829 «یک باشگاه فوتبال است که در اسبیرگ کشور
# دانمارک پایه‌گذاری شده‌است» — the FC rule minus the باشگاه فوتبال
# prefix; the city article اسبیرگ 492488 grounds the toponym). THREE
# zero-anchor honest reads (the 452..483 precedent; the feed's own
# single-country DEN tagging is the identity evidence, the 466 UPNFM
# rule): Aarhus Fremad → آرهوس فرماد (no club entity, fa searches
# player-noise only; آرهوس grounded by the city article 492451 + the
# file's own agf → آرهوس mapping) / Brabrand → برابرند (Q848827 proves
# the Danish identity AND the fa-sitelink absence) / FC Roskilde →
# اف‌سی راسکیله (Q737633 proves the Danish identity AND the sitelink
# absence; the CITY article راسکیله Q26563 grounds the spelling, the 475
# own-title-wins lesson; the اف‌سی ZWNJ convention). POST mode (--post):
# after the patch, the same names must render PERSIAN in the live ±7 feed
# (zero raw literals left for this batch).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "AC Horsens", "Aarhus Fremad", "Brabrand", "Esbjerg fB", "FC Roskilde",
]

post = "--post" in sys.argv

PROPOSED = {
    "aarhus fremad": "آرهوس فرماد",
    "ac horsens": "هورسنس",
    "brabrand": "برابرند",
    "esbjerg fb": "اسبیرگ",
    "fc roskilde": "اف\u200cسی راسکیله",
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
        ok = seen_rows >= 3 and len(ccs) == 1 and "DEN" in ccs
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
