#!/usr/bin/env python3
# cycle-398 patrol (bug-hunt) — the 393/396 method on the 397-flipped coach
# surfaces (players panel coach fa-first, last-lineup coachNameFa, bench
# tenure fa) + the standing holds (390-395) + the not-yet-patrolled ground
# (/coach, /player, /leagues, /topscorers, /search, team-top-players honesty).
# Findings are REPORTED only — the fix belongs to cycle-399=فیکس.
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
FA = lambda s: any("\u0600" <= c <= "\u06FF" for c in s)

TEAMS = {
    "8650": "liverpool", "10261": "newcastle", "101610": "persepolis",
    "8667": "hull", "8044": "omonio", "6711": "iran-nt", "6706": "argentina-nt",
    "8634": "barcelona", "8256": "brazil-nt", "6720": "spain-nt",
}

print("==== S1: the 397 flips hold (API level) ====")
coach_ok, coach_bad = 0, []
ll_ok, ll_bad = 0, []
for tid, label in TEAMS.items():
    code, d = get(f"/api/team-squad/{tid}")
    c = ((d or {}).get("squad") or {}).get("coach") or {}
    n, fa = (c.get("name") or "").strip(), (c.get("fa") or "").strip()
    if n:
        if fa:
            coach_ok += 1
        else:
            coach_bad.append((label, tid, n))
    code, d = get(f"/api/team-last-lineup/{tid}")
    ll = ((d or {}).get("lastLineup") or {})
    cn, cf = (ll.get("coachName") or "").strip(), (ll.get("coachNameFa") or "").strip()
    if cn:
        if cf:
            ll_ok += 1
        else:
            ll_bad.append((label, tid, cn))
print(f"  squad coach fa present: {coach_ok}/10 (the 397 C hold) — missing: {coach_bad}")
print(f"  last-lineup coachNameFa present: {ll_ok}/10 (the 397 B hold) — missing: {ll_bad}")
# the byte-exact raw contract: coachName stays the upstream raw string
code, d = get("/api/team-last-lineup/8650")
cn = ((d or {}).get("lastLineup") or {}).get("coachName")
print(f"  raw contract: 8650 coachName={cn!r} (upstream raw, must stay Latin)")

print("==== S2: bench-history fa coverage (the 397 C9-C11 surface — the fresh gap) ====")
for tid, label in (("6706", "argentina-nt"), ("8650", "liverpool")):
    code, d = get(f"/api/team-coaches/{tid}")
    ts = ((d or {}).get("coaches") or {}).get("tenures") or []
    with_fa = [t for t in ts if (t.get("fa") or "").strip()]
    without = [t.get("name") for t in ts if not (t.get("fa") or "").strip()]
    print(f"  {label} {tid}: tenures={len(ts)} fa={len(with_fa)} raw={len(without)} — raw names: {without}")
print("  probed upstream ids for the 399 fix: Martino=80651, Sampaoli=335697 (6706 coachHistory)")

print("==== S3: the not-yet-patrolled surfaces ====")
# /api/coach/:id — ok + fa + career-row fa coverage
for cid, label in (("9012", "jakirovic"), ("38922", "scaloni"), ("504132", "ghalenoei"), ("78619", "ancelotti")):
    code, d = get(f"/api/coach/{cid}")
    c = (d or {}).get("coach") or {}
    fa = (c.get("fa") or "").strip()
    career = c.get("career") or []
    career_raw = [r.get("team") for r in career if not (r.get("fa") or "").strip()]
    team = c.get("team") or {}
    team_fa = bool((team.get("fa") or "").strip())
    print(f"  coach {label} {cid}: ok={d.get('ok')} fa={'YES' if fa else 'NO'} career={len(career)} career_raw={len(career_raw)} team_fa={team_fa}")
    for t in career_raw[:4]:
        print(f"    raw career row: {t!r}")
# /api/player/:id — the honesty contract on the player surface
code, d = get("/api/player/319784")
p = (d or {}).get("player") or {}
nfa = (p.get("nameFa") or "").strip()
mixed = nfa and nfa != (p.get("name") or "").strip() and LAT.search(nfa)
print(f"  player 319784: ok={d.get('ok')} name={p.get('name')!r} nameFa={nfa!r} mixed={bool(mixed)}")
# team-top-players honesty (the same mixed-nameFa contract, zero tolerated)
mixed_tp, total_tp = 0, 0
for tid in ("8650", "101610"):
    code, d = get(f"/api/team-top-players/{tid}")
    tp = (d or {}).get("topPlayers") or {}
    def walk(o):
        global mixed_tp, total_tp
        if isinstance(o, dict):
            nm, nf = (o.get("name") or "").strip(), (o.get("nameFa") or "").strip()
            if nm and nf and nf != nm:
                total_tp += 1
                if LAT.search(nf):
                    mixed_tp += 1
            for v in o.values(): walk(v)
        elif isinstance(o, list):
            for v in o: walk(v)
    walk(tp)
print(f"  team-top-players: mixed nameFa={mixed_tp}/{total_tp} differing rows across 8650+101610 (must be 0)")

print("==== S4: the standing holds (390-395) ====")
code, d = get("/api/team/6711")
print(f"  390 NT: /api/team/6711 ok={bool(d and d.get('ok'))}")
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
    for g in ((d or {}).get("squad") or {}).get("groups") or []:
        for p in g.get("players") or []:
            if (p.get("nameFa") or "").strip() == (p.get("name") or "").strip():
                n += 1
    print(f"  395 squad: {tid} raw={n} (expected {expect}) {'OK' if n == expect else 'DRIFT'}")
for mid in ("5795503", "5795501"):
    code, d = get(f"/api/match/{mid}")
    if d and d.get("ok"):
        bad = []
        def scan(o, path=""):
            if isinstance(o, dict):
                for k, val in o.items(): scan(val, path + "." + k)
            elif isinstance(o, list):
                for i, val in enumerate(o): scan(val, f"{path}[{i}]")
            else:
                if path.endswith(".fa") and isinstance(o, str) and o and any(c.isascii() and c.isalpha() for c in o) and not FA(o):
                    bad.append((path, o))
        scan(d)
        print(f"  match {mid}: Latin-carrying fa fields={len(bad)} (hold=0)")
        for b in bad[:4]: print("    LEAK:", b)
    else:
        print(f"  match {mid}: HTTP {code} (documented error contract)")

print("==== S5: the core pages (status + Persian title anchor) ====")
for path, note in [("/", "home"), ("/league/pl", "league"), ("/standings?league=pl", "designed 404"),
                   ("/team/8650", "team"), ("/players?league=pl&team=8650", "players view"),
                   ("/match/5795503", "match"), ("/coach/9012", "coach NEW"), ("/player/319784", "player NEW"),
                   ("/leagues", "leagues NEW"), ("/topscorers", "topscorers NEW"), ("/search?q=%D8%A7%DB%8C%D8%B1%D8%A7%D9%86", "search NEW")]:
    r = subprocess.run(["curl", "-s", "-A", UA, "-o", "/dev/null", "-w", "%{http_code}", BASE + path],
                       capture_output=True, text=True, timeout=60)
    print(f"  {path} → {r.stdout.strip()} ({note})")
# titles of the NEW pages must render Persian
for path, frag in (("/coach/9012", "سرگی یاکیروویچ"), ("/player/319784", "آلیسون بکر")):
    r = subprocess.run(["curl", "-s", "-A", UA, BASE + path], capture_output=True, text=True, timeout=60)
    t = re.search(r"<title>(.*?)</title>", r.stdout, re.S)
    title = t.group(1).strip() if t else ""
    print(f"  title {path}: {title!r} persian_anchor={'OK' if frag in title else 'MISS'}")
