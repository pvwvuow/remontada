#!/usr/bin/env python3
# probe-347: live feasibility probe for the cycle-347 «جایگاه در جدول» feature
# (closing the cycle-192 documented set-aside). Verifies with UA Chrome/124:
#   1) which match payloads carry content.table (pointer: url + team ids)
#   2) the pointed blob (data.fotmob.com/tables.ext.<lid>.fot.gz) fetches,
#      gunzips, and contains <t id p w d l g c> rows in rank order
#   3) the parsed rows actually contain both sides of a real match
# Honest probe — prints byte counts so empty/limited responses cannot
# masquerade as "ABSENT" (learned the hard way this session).
import gzip
import io
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

MATCHES = [
    ("5795501", "Liverpool vs Arsenal (PL)"),
    ("5868118", "Racing Santander vs Real Madrid (LaLiga)"),
    ("5749733", "Como vs Venezia (Serie A)"),
    ("5868111", "Athletic Club vs Real Sociedad (LaLiga)"),
    ("5749736", "Lazio vs Cagliari (Serie A)"),
    ("5868116", "Getafe vs Sevilla (LaLiga)"),
]

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
            time.sleep(3.5)
    raise RuntimeError(f"fetch failed for {url}: {last}")


payloads = {}
for mid, label in MATCHES:
    try:
        body, status = fetch(f"https://www.fotmob.com/api/data/matchDetails?matchId={mid}")
        if len(body) < 500:
            check(f"match {mid} payload size sane", False, f"HTTP {status}, {len(body)} B (limited?)")
            continue
        d = json.loads(body)
        payloads[mid] = d
        c = d.get("content") or {}
        t = c.get("table")
        check(
            f"match {mid} ({label}) fetched",
            True,
            f"{len(body)} B, content keys={len(c)}, content.table="
            + (json.dumps(t)[:130] if t else "ABSENT"),
        )
        time.sleep(2.2)
    except Exception as e:  # noqa: BLE001
        check(f"match {mid} ({label}) fetched", False, str(e)[:120])

with_table = {mid: d for mid, d in payloads.items() if (d.get("content") or {}).get("table")}
check(
    "at least one league-match payload carries content.table",
    len(with_table) > 0,
    f"{len(with_table)}/{len(payloads)} probed payloads",
)

blob_url = None
blobs = {}
for mid, d in with_table.items():
    t = d["content"]["table"]
    url = t.get("url") if isinstance(t, dict) else None
    gen = d.get("general") or {}
    home_id = (gen.get("homeTeam") or {}).get("id")
    away_id = (gen.get("awayTeam") or {}).get("id")
    teams = t.get("teams") if isinstance(t, dict) else None
    check(
        f"match {mid} pointer shape",
        isinstance(url, str) and bool(teams),
        f"url={url} teams={teams} home={home_id} away={away_id}",
    )
    check(
        f"match {mid} pointer host allowlisted",
        bool(re.match(r"^https://data\.fotmob\.com/", url or "")),
        url or "",
    )
    if url and url not in blobs:
        try:
            gz, status = fetch(url)
            xml = gzip.decompress(gz).decode("utf8", "replace")
            blobs[url] = xml
            check(f"blob fetch+gunzip {url.rsplit('/',1)[-1]}", status == 200 and len(xml) > 500,
                  f"{len(gz)} B gz → {len(xml)} B xml")
        except Exception as e:  # noqa: BLE001
            check(f"blob fetch+gunzip {url}", False, str(e)[:120])
    xml = blobs.get(url, "")
    rows = re.findall(r'<t\s+[^>]*>', xml)
    # anchored attr regex — unanchored, `d="…"` matches inside `id="…"`
    # (team id poisoning draws/played/points; found the hard way live)
    def at(s, n):
        m2 = re.search(r'(?:^|\s)' + n + r'="([^"]*)"', s)
        return m2.group(1) if m2 else ""
    parsed = []
    for m in rows:
        s = m.group(0) if hasattr(m, "group") else m
        parsed.append({k: at(s, k) for k in ("id", "p", "w", "d", "l", "g", "c")})
    # semantic validation: every fully-numeric row must satisfy
    # points == 3*w+d and w+d+l == played-consistency vs p (=points)
    sem_bad = []
    sem_ok = 0
    for r in parsed:
        if not all(r[k].isdigit() for k in ("p", "w", "d", "l", "g", "c")):
            continue
        p, w, d, l = int(r["p"]), int(r["w"]), int(r["d"]), int(r["l"])
        if 3 * w + d != p or w + d + l <= 0:
            sem_bad.append(r)
        else:
            sem_ok += 1
    check(f"match {mid} blob rows semantically consistent (3w+d==p)",
          len(rows) >= 10 and sem_ok >= 10 and not sem_bad,
          f"{len(rows)} rows, {sem_ok} consistent, bad={sem_bad[:2]}")
    check(f"match {mid} both sides present in rows",
          str(home_id) in [r['id'] for r in parsed] and str(away_id) in [r['id'] for r in parsed],
          f"home={home_id} away={away_id} parsed_ids_sample={[r['id'] for r in parsed[:6]]}")
    name = re.search(r'<table\b[^>]*\bname="([^"]*)"', xml)
    check(f"match {mid} blob league name", bool(name), name.group(1) if name else "ABSENT")
    time.sleep(2.0)

n_ok = sum(1 for _, ok, _ in checks if ok)
print(f"\n=== {n_ok}/{len(checks)} checks passed ===")
sys.exit(0 if n_ok == len(checks) else 1)
