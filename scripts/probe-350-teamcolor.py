#!/usr/bin/env python3
# probe-350: live feasibility probe for the cycle-350 team OFFICIAL color
# feature (overview.teamColors / details.teamColor on data/teams payloads).
# UA Chrome/124, honest byte-count printing so limited responses cannot
# masquerade as absence. Anchors: exact probed hexes + strict-hex-or-absent
# on a broad set + payload sanity alongside (the color is additive, the
# payload must stay intact).
import json
import re
import sys
import time
import urllib.request

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)
HDRS = {"User-Agent": UA, "Accept": "application/json"}

# live-probed anchor: Liverpool 8650 = #911712 (overview + details)
EXACT = {8650: "#911712"}
# broad set: majors + a couple of smaller clubs (hex-or-absent, never garbage)
BROAD = [8650, 9825, 8455, 8634, 8633, 9866, 8302, 8560, 9925, 9865]

checks = []


def check(name, ok, detail=""):
    checks.append((name, bool(ok), detail))
    print(f"[{'PASS' if ok else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))


def fetch(url, timeout=15, retries=3):
    last = None
    for _ in range(retries):
        try:
            req = urllib.request.Request(url, headers=HDRS)
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return r.read(), r.status
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(3.0)
    raise RuntimeError(f"fetch failed for {url}: {last}")


HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")

for tid in BROAD:
    try:
        body, status = fetch(f"https://www.fotmob.com/api/data/teams?id={tid}")
        if len(body) < 500:
            check(f"team {tid} payload size sane", False, f"HTTP {status}, {len(body)} B")
            continue
        d = json.loads(body)
        ov = (d.get("overview") or {}).get("teamColors") or {}
        light = ov.get("lightMode")
        dark = ov.get("darkMode")
        det = (d.get("details") or {}).get("teamColor")
        vals = [v for v in (light, dark, det) if isinstance(v, str) and v]
        sane = all(HEX_RE.match(v) for v in vals)
        check(f"team {tid} colors strict-hex-or-absent", sane,
              f"light={light} dark={dark} details={det}")
        if tid in EXACT:
            got = light or dark or det
            check(f"team {tid} exact official anchor", got == EXACT[tid],
                  f"expected {EXACT[tid]}, got {got}")
            check(f"team {tid} light==dark==details (probed consistency)",
                  light == dark == det if (light and dark and det) else False,
                  f"{light} / {dark} / {det}")
        # payload sanity: the color block rides a payload that still carries
        # the families every consumer reads (overview/fixtures/history)
        fam = sum(1 for k in ("overview", "fixtures", "history", "squad", "transfers") if k in d)
        check(f"team {tid} payload families intact (≥3/5)", fam >= 3, f"{fam}/5 present")
        time.sleep(2.0)
    except Exception as e:  # noqa: BLE001
        check(f"team {tid} fetched", False, str(e)[:120])

n_ok = sum(1 for _, ok, _ in checks if ok)
print(f"\n=== {n_ok}/{len(checks)} checks passed ===")
sys.exit(0 if n_ok == len(checks) else 1)
