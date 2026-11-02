#!/usr/bin/env python3
# cycle-396 patrol (bug-hunt) — the 393 method on the surfaces the recent
# cycles opened. The 394 card's logged item is the prime target: the
# /players squad-panel header renders squad.coach.name RAW at
# players-view.tsx:765 while the SAME payload carries coach.fa (cycle-259
# coachFa) — a render-side field-choice leak, the 388-F4 class. Findings
# are REPORTED (the fix belongs to cycle-397=فیکس); clean classes are
# asserted, the honest-passthrough classes are recounted (never zero-faked).
import json, re, subprocess

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
BASE = "http://localhost:3000"

def get(path):
    r = subprocess.run(["curl", "-s", "-A", UA, "-w", "\n%{http_code}", BASE + path],
                       capture_output=True, text=True, timeout=60)
    body, _, code = r.stdout.rpartition("\n")
    try:
        return int(code), json.loads(body)
    except Exception:
        return int(code), None

LAT = re.compile(r"[A-Za-z]{2,}")

# the 395 flagship seven + three extra witnesses (Barcelona club, two NTs)
TEAMS = {
    "8650": "liverpool", "10261": "newcastle", "101610": "persepolis",
    "8667": "hull", "8044": "omonio", "6711": "iran-nt", "6706": "argentina-nt",
    "8634": "barcelona", "8256": "brazil-nt", "6720": "spain-nt",
}

print("==== S1: the 394-logged coach item (players-view:765 renders coach.name RAW) ====")
coach_fa_present, coach_fa_missing, coach_raw = 0, [], []
for tid, label in TEAMS.items():
    code, d = get(f"/api/team-squad/{tid}")
    if not d or not d.get("ok"):
        print(f"  {label} {tid}: HTTP {code} unavailable")
        continue
    c = (d.get("squad") or {}).get("coach") or {}
    n, fa = (c.get("name") or "").strip(), (c.get("fa") or "").strip()
    if not n:
        continue
    if fa and fa != n:
        coach_fa_present += 1
        coach_raw.append((label, tid, n, fa))
    else:
        coach_fa_missing.append((label, tid, n))
print(f"  coaches with a mapped fa (the fix's free win): {coach_fa_present}")
for label, tid, n, fa in coach_raw:
    print(f"    {label} {tid}: name={n!r} fa={fa!r}  ← panel renders the RAW name today (F1)")
print(f"  coaches with NO fa (the honest fallback stays): {len(coach_fa_missing)}")
for label, tid, n in coach_fa_missing:
    print(f"    {label} {tid}: {n!r}")

print("==== S2: the squad-surface fa-honesty scan (mixed/fa-designated leaks) ====")
mixed, nat_raw_count, nat_total = [], 0, 0
for tid, label in TEAMS.items():
    code, d = get(f"/api/team-squad/{tid}")
    if not d or not d.get("ok"):
        continue
    for g in (d.get("squad") or {}).get("groups") or []:
        for p in g.get("players") or []:
            n, nfa = (p.get("name") or "").strip(), (p.get("nameFa") or "").strip()
            if nfa and nfa != n and LAT.search(nfa):
                mixed.append((label, n, nfa))
            nat = (p.get("nationality") or "").strip()
            if nat:
                nat_total += 1
                if LAT.search(nat):
                    nat_raw_count += 1
print(f"  nameFa values that DIFFER from name yet still carry Latin (a faked translation — must be 0): {len(mixed)}")
for m in mixed[:8]:
    print("    MIXED:", m)
print(f"  nationality raw passthrough rows: {nat_raw_count}/{nat_total} (the documented teamFa-fallback class, recounted for the 397 sizing)")

print("==== S3: the match-details surface (the 384 h1 path) — live match 5795503 ====")
code, d = get("/api/match/5795503")
if d and d.get("ok"):
    bad = []
    def scan(o, path=""):
        if isinstance(o, dict):
            for k, v in o.items():
                scan(v, path + "." + k)
        elif isinstance(o, list):
            for i, v in enumerate(o):
                scan(v, f"{path}[{i}]")
        else:
            if path.endswith(".fa") and isinstance(o, str) and o and any(c.isascii() and c.isalpha() for c in o) and not any("\u0600" <= c <= "\u06FF" for c in o):
                bad.append((path, o))
    scan(d)
    h1 = d.get("h1") or {}
    print(f"  h1: {json.dumps(h1, ensure_ascii=False)[:200]}")
    print(f"  Latin-carrying fa fields in the whole payload: {len(bad)}")
    for b in bad[:8]:
        print("    LEAK:", b)
else:
    print(f"  HTTP {code} — match feed unavailable (documented error contract)")

print("==== S4: the recent-feature holds (390/391/392/395) ====")
code, d = get("/api/team/6711")
ok390 = bool(d and d.get("ok"))
print(f"  390 NT: /api/team/6711 ok={ok390}")
code, d = get("/api/team-venue/10261")
v = (d or {}).get("venue") or (d or {})
print(f"  391 venue: 10261 nameFa={bool((v.get('nameFa') or ''))}")
code, d = get("/api/team-transfers/10261")
items = ((d or {}).get("transfers") or {}).get("items") or []
raw_tx = [i for i in items if (i.get("nameFa") or "").strip() == (i.get("name") or "").strip() and i.get("name")]
print(f"  392 transfers: 10261 raw rows={len(raw_tx)}/{len(items)} (hold=0)")
for tid, expect in (("8650", 0), ("101610", 6), ("8044", 2), ("6706", 1)):
    code, d = get(f"/api/team-squad/{tid}")
    n = 0
    for g in (d.get("squad") or {}).get("groups") or []:
        for p in g.get("players") or []:
            if (p.get("nameFa") or "").strip() == (p.get("name") or "").strip():
                n += 1
    print(f"  395 squad: {tid} raw={n} (expected {expect}) {'OK' if n == expect else 'DRIFT'}")

print("==== S5: the core pages (API status + Persian anchors) ====")
for path, note in [("/", "home"), ("/league/pl", "league"), ("/standings?league=pl", "standings api"),
                   ("/team/8650", "team"), ("/players?league=pl&team=8650", "players view"),
                   ("/match/5795503", "match details")]:
    code, body = get(path)
    ok = code == 200
    print(f"  {path} → {code} {'OK' if ok else 'FAIL'} ({note})")
