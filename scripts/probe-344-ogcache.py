#!/usr/bin/env python3
# ---------------------------------------------------------------------
# Remontada — probe-344-ogcache.py  (fix cycle-344)
# Verifies the cache-policy parity between the two sibling OG routes:
#   /api/og/[key]        (league cards, build-time prerendered)
#   /api/og/person/[id]  (player/coach cards, runtime rendered)
# Before this fix the league route served Next's prerender default
# "public, max-age=0, must-revalidate" while the person route served the
# designed weekly header — the mismatch documented by the cycle-343
# bug-hunt. After the fix BOTH must serve the identical weekly policy.
# Usage: python3 scripts/probe-344-ogcache.py [BASE]
# UA: Chrome/124 (house probe standard). Exits non-zero on any failure.
# ---------------------------------------------------------------------
import sys
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:3000"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
WEEKLY = "public, max-age=604800, stale-while-revalidate=86400"

results = []


def fetch(path):
    req = urllib.request.Request(BASE + path, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            # keep the HTTPMessage (case-insensitive .get) — Node serves
            # lowercase header names, a plain dict() would lose lookups
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, b""


def check(name, cond, detail):
    results.append((bool(cond), name, detail))


# --- league route: cache-control must now be the weekly policy --------
for key in ("pl", "ucl", "persiangulf"):
    st, hd, body = fetch(f"/api/og/{key}")
    check(f"league {key}: status 200", st == 200, f"status={st}")
    check(f"league {key}: image/png", hd.get("Content-Type") == "image/png",
          f"content-type={hd.get('Content-Type')}")
    check(f"league {key}: weekly cache-control", hd.get("Cache-Control") == WEEKLY,
          f"cache-control={hd.get('Cache-Control')}")
    check(f"league {key}: payload >10KB", len(body) > 10240, f"bytes={len(body)}")

# --- person route: unchanged designed policy (regression guard) -------
for path, label in (("/api/og/person/696679?k=player", "player 696679"),
                    ("/api/og/person/30889?k=coach", "coach 30889")):
    st, hd, body = fetch(path)
    check(f"person {label}: status 200", st == 200, f"status={st}")
    check(f"person {label}: image/png", hd.get("Content-Type") == "image/png",
          f"content-type={hd.get('Content-Type')}")
    check(f"person {label}: weekly cache-control preserved",
          hd.get("Cache-Control") == WEEKLY, f"cache-control={hd.get('Cache-Control')}")

# --- parity: both routes byte-identical policy ------------------------
st_l, hd_l, _ = fetch("/api/og/pl")
st_p, hd_p, _ = fetch("/api/og/person/696679?k=player")
check("parity: league == person cache-control",
      hd_l.get("Cache-Control") == hd_p.get("Cache-Control"),
      f"{hd_l.get('Cache-Control')} vs {hd_p.get('Cache-Control')}")

# --- contract guard: unknown key still hard-404 ------------------------
st, _, _ = fetch("/api/og/nonexistent")
check("unknown league key -> 404", st == 404, f"status={st}")

ok = sum(1 for passed, _, _ in results if passed)
for passed, name, detail in results:
    print(f"  [{'PASS' if passed else 'FAIL'}] {name}  ({detail})")
print(f"\n{ok}/{len(results)} green  BASE={BASE}")
sys.exit(0 if ok == len(results) else 1)
