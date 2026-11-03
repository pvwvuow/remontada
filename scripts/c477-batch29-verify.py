#!/usr/bin/env python3
# cycle-477 batch-29 pre/post verification (the 446..475 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased) and single-country across the whole ±7 window (the 389 rule).
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole file (the Logroñés rule). Batch 29 = the ALB tranche (ALL 7
# count>=3 single-country ALB names of the FRESH 477 census — the fresh
# 447 re-read dissolved the 476 card's GRE/BUL/DEN/ALB field: GRE 4, BUL
# 2, DEN 5 with its (W) side GONE from the window — and surfaced the NEW
# two-way tie ALB 7 = PAR 7; ENG's 7 carries FOUR (W) sides -> the 435
# rule leaves it 2 effective, ESP 6 -> 2 — the tie-break: ALB 4 direct
# identity-verified fa.wiki club articles vs PAR 1 (سرو پورتنیو), the 472
# CZE-vs-ISR precedent). The four DIRECT anchors: KF Tirana → تیرانا
# (باشگاه فوتبال تیرانا 43804587 «…یک باشگاه فوتبال در شهر تیرانا،
# آلبانی است… ۱۹۲۰») / FC Dinamo City → دینامو تیرانا (Q34120 KS Dinamo
# Tirana — the SAME club RENAMED Dinamo City upstream; باشگاه فوتبال
# دینامو تیرانا 42185043 — the anchor's OWN title wins, the 475
# RENAMED-upstream lesson, the FC rule minus the prefix) / Partizani →
# پارتیزانی تیرانا (باشگاه فوتبال پارتیزانی تیرانا 43805559 «FK Partizani
# Tirana… ۱۹۴۶… آلبانی») / Vllaznia → ولازنیا اشکودر (باشگاه فوتبال
# ولازنیا اشکودر 35742201 «…قدیمی‌ترین باشگاه کشور آلبانی»). Zero-anchor
# honest reads (the 452..475 precedent): Elbasani → البسان (the club's
# own article باشگاه فوتبال البسان 3990515 EXISTS but its extract's
# country adjective is an upstream TYPO «اسلواکی» for the club founded
# در الباسان، آلبانی — the strict wrong-country rule REJECTS it as a
# direct anchor; the title still evidences the spelling) / Skënderbeu →
# اسکندربو (no club article anywhere — probe3; the spelling grounded by
# the club's OWN stadium article ورزشگاه اسکندربو 5322302 whose extract
# names the club «باشگاه فوتبال اسکندربو کورچه») / Vora → وورا (no
# entity, no search hits — pure phonetic, the 466 UPNFM rule). POST mode
# (--post): after the patch, the same names must render PERSIAN in the
# live ±7 feed (zero raw literals left for this batch).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Elbasani", "FC Dinamo City", "KF Tirana", "Partizani",
    "Skënderbeu", "Vllaznia", "Vora",
]

post = "--post" in sys.argv

PROPOSED = {
    "elbasani": "البسان",
    "fc dinamo city": "دینامو تیرانا",
    "kf tirana": "تیرانا",
    "partizani": "پارتیزانی تیرانا",
    "skënderbeu": "اسکندربو",
    "vllaznia": "ولازنیا اشکودر",
    "vora": "وورا",
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
        ok = seen_rows >= 3 and len(ccs) == 1 and "ALB" in ccs
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
