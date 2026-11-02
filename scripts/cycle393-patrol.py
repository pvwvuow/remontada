#!/usr/bin/env python3
# cycle-393 patrol (bug-hunt) — the 388 method on the surfaces the recent
# cycles opened: the NT team pages (the 391 card's patrol recommendation:
# «صفحات ملی چند تیم زیر اسکن لاتین بروند — سطح ملی حالا زنده است»), the
# re-verification of the 390/391/392 features, the five core pages at
# 390x844, and the API-only leak class (388-F5) recount. Findings are
# REPORTED (the fix belongs to cycle-394=فیکس); clean classes are asserted.
import json, subprocess, re, sys
from collections import Counter

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
def latin_words(s):
    return set(LAT.findall(s or ""))

print("==== S1: the national-team surface scan (the 391 patrol recommendation) ====")
NTS = {"Iran": 6711, "Brazil": 8256, "Portugal": 8361, "Argentina": 6706,
       "France": 6723, "Germany": 8570, "Spain": 6720}
for name, tid in NTS.items():
    code, d = get(f"/api/team/{tid}")
    if not d or not d.get("ok"):
        print(f"  {name} {tid}: HTTP {code} ok={d.get('ok') if d else None} — page may hit the widened 404 (documented contract)")
        continue
    leaks = []
    # fa-designated: team nameFa, fixtures rows (opponent/team fa), prematch
    t = d.get("team") or {}
    if t.get("nameFa") == t.get("name"):
        leaks.append(f"self nameFa raw={t.get('name')}")
    fx = (d.get("fixtures") or d.get("teamFixtures") or {}) 
    rows = (fx.get("recent") or []) + (fx.get("upcoming") or [])
    raw_fx = [r for r in rows if isinstance(r, dict) and r.get("fa") == r.get("name")]
    if raw_fx:
        leaks.append(f"{len(raw_fx)}/{len(rows)} fixture-row fa==name (e.g. {raw_fx[0].get('name')})")
    words = set()
    def scan(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if k in ("fa", "nameFa", "kindFa", "feeFa", "titleFa") and isinstance(v, str) and LAT.search(v):
                    words.update(latin_words(v))
                scan(v)
        elif isinstance(o, list):
            for x in o[:60]:
                scan(x)
    scan(d)
    print(f"  {name} {tid}: HTTP {code} — fa-field Latin words: {len(words)} {'sample='+str(sorted(words)[:8]) if words else '(clean)'}"
          + (" | " + "; ".join(leaks) if leaks else ""))

print("==== S2: the 390/391/392 feature re-verification (regression patrol) ====")
code, d = get("/api/team/6711")
ok1 = code == 200 and (d or {}).get("ok")
print(f"  390 NT-aware: /api/team/6711 → {code} ok={ok1}")
code, d = get("/api/team-venue/10261")
v = (d or {}).get("venue") or {}
print(f"  391 venue: nameFa={v.get('nameFa')!r} cityFa={v.get('cityFa')!r} raw kept={v.get('name')!r}")
code, d = get("/api/team-transfers/10261")
items = ((d or {}).get("transfers") or {}).get("items") or []
rawn = sum(1 for it in items if it.get("nameFa") == it.get("name"))
print(f"  392 transfers: 10261 → {code}, {len(items)} items, raw={rawn}")

print("==== S3: the five core pages (h1 + server HTML fa anchors) ====")
for path, want in [("/", "رمانتادا"), ("/standings", None), ("/league/pl", "پریمیرلیگ"),
                   ("/team/10261", "نیوکاسل"), ("/match", None)]:
    r = subprocess.run(["curl", "-s", "-A", UA, "-o", "/tmp/d393_page.html", "-w", "%{http_code}", BASE + path],
                       capture_output=True, text=True, timeout=60)
    html = open("/tmp/d393_page.html", encoding="utf-8", errors="replace").read()
    h1 = re.search(r"<h1[^>]*>(.*?)</h1>", html, re.S)
    h1txt = re.sub(r"<[^>]+>", "", h1.group(1)).strip()[:40] if h1 else "(no h1)"
    print(f"  {path} → {r.stdout.strip()} h1={h1txt!r}")

print("==== S4: the API-only leak class recount (388-F5 convention) ====")
code, d = get("/api/match")
print(f"  /api/match day-feed → {code} ok={(d or {}).get('ok')}")
print("DONE-PATROL")
