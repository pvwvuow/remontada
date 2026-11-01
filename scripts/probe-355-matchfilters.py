#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-355-matchfilters.py — cycle-355 (آپدیت) live probe
«فیلتر مسابقات» آرشیو بازی‌های اخیر بازیکن — مصرف سطح آپاستریم matchFilters
+ leagueId سطرها. UA Chrome/124، بدون ساخت شکست.

فاز A (آپاستریم مستقیم): شکل matchFilters، leagueId روی همهٔ سطرهای
recentMatches، سازگاری دوطرفهٔ teams[].leagueIds ↔ leagues[]، و زیرمجموعه
بودن لیگ‌های سطرها در matchFilters.leagues.
فاز B (سطح API سایت): player.logLeagues حاضر و مرتب‌شده، جمع شمارش‌ها ==
سطرهای دارای leagueId، و سالم‌ماندن /api/coach (همان lib مشترک).

exit 1 روی هر FAIL.
"""
import json
import os
import re
import sys
import urllib.request

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = os.environ.get("BASE", "http://localhost:3000")
ANCHOR_ID = "696679"  # رافینیا — لنگر رسمی کارت

passed, failed = 0, 0


def check(name, cond, detail=""):
    global passed, failed
    tag = "PASS" if cond else "FAIL"
    if cond:
        passed += 1
    else:
        failed += 1
    print(f"[{tag}] {name}" + (f" — {detail}" if detail else ""))


def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.status, r.read()


# ---------------------------------------------------------------- فاز A
print("=== فاز A — آپاستریم مستقیم (UA Chrome/124) ===")

# انتخاب ۲ بازیکن دیگر از API سایت (آقای گل‌ها) تا پروب واقعی و تازه باشد
extra_ids = []
try:
    st, body = get(f"{BASE}/api/topscorers")
    d = json.loads(body.decode("utf-8"))
    rows = d.get("scorers") or d.get("rows") or (d.get("data") if isinstance(d.get("data"), list) else None) or []
    for row in rows:
        pid = row.get("playerId")
        if pid and str(pid) != ANCHOR_ID and str(pid) not in extra_ids:
            extra_ids.append(str(pid))
        if len(extra_ids) >= 2:
            break
    print(f"topscorers → {st}، بازیکنان اضافی: {extra_ids}")
except Exception as e:
    print(f"topscorers inaccessible ({e}) — فقط لنگر پروب می‌شود")

ids = [ANCHOR_ID] + extra_ids
for pid in ids:
    url = f"https://www.fotmob.com/api/data/playerData?id={pid}"
    try:
        st, raw = get(url)
    except Exception as e:
        check(f"A{pid}: upstream 200", False, str(e))
        continue
    nbytes = len(raw)
    check(f"A{pid}: upstream HTTP {st} + بدنهٔ غیرخالی", st == 200 and nbytes > 1000, f"{nbytes} bytes")
    try:
        d = json.loads(raw.decode("utf-8"))
    except Exception as e:
        check(f"A{pid}: JSON قابل تجزیه", False, str(e))
        continue

    name = d.get("name") or "?"
    rows = d.get("recentMatches") or []
    with_lid = [m for m in rows if isinstance(m.get("leagueId"), int)]
    check(f"A{pid} [{name}]: همهٔ سطرهای آرشیو leagueId عددی دارند",
          len(rows) == 0 or len(with_lid) == len(rows),
          f"{len(rows)} سطر، {len(with_lid)} با leagueId")

    mf = d.get("matchFilters")
    if not isinstance(mf, dict):
        check(f"A{pid} [{name}]: matchFilters حاضر", False, "غایب — fallback سطرمبنا پوشش می‌دهد")
        continue
    mf_teams = mf.get("teams") or []
    mf_leagues = mf.get("leagues") or []
    check(f"A{pid} [{name}]: matchFilters.teams/leagues هر دو لیست",
          isinstance(mf_teams, list) and isinstance(mf_leagues, list),
          f"{len(mf_teams)} تیم / {len(mf_leagues)} لیگ")

    team_lg = set()
    for t in mf_teams:
        team_lg.update(x for x in (t.get("leagueIds") or []) if isinstance(x, int))
    lg_ids = {l.get("leagueId") for l in mf_leagues if isinstance(l.get("leagueId"), int)}
    check(f"A{pid} [{name}]: سازگاری دوطرفه leagues[].id ⊆ union(teams[].leagueIds)",
          lg_ids.issubset(team_lg),
          f"{len(lg_ids)} لیگ درون {len(team_lg)} لیگِ تیم‌ها")

    row_lg = {m.get("leagueId") for m in with_lid}
    check(f"A{pid} [{name}]: لیگ‌های سطرها ⊆ matchFilters.leagues (قرارداد فیلتر)",
          row_lg.issubset(lg_ids),
          f"سطرها: {sorted(row_lg)}")

# ---------------------------------------------------------------- فاز B
print("=== فاز B — سطح API سایت ===")

st, raw = get(f"{BASE}/api/player/{ANCHOR_ID}")
check("B1: /api/player/696679 HTTP 200", st == 200, f"{st}")
d = json.loads(raw.decode("utf-8"))
p = d.get("player") or {}
recent = p.get("recent") or []
logl = p.get("logLeagues")

check("B2: player.logLeagues حاضر و غیرخالی", isinstance(logl, list) and len(logl) >= 1,
      f"{len(logl or [])} چیپ")
check("B3: هر چیپ {leagueId, fa, count} و fa غیرخالی",
      all(isinstance(l.get("leagueId"), int) and isinstance(l.get("fa"), str) and l["fa"].strip()
          and isinstance(l.get("count"), int) for l in (logl or [])),
      "، ".join(f"{l['leagueId']}:{l['fa']}×{l['count']}" for l in (logl or [])[:6]))
counts = [l.get("count", 0) for l in (logl or [])]
check("B4: مرتب‌شدهٔ نزولی بر اساس count", counts == sorted(counts, reverse=True), str(counts))
rows_with_lid = sum(1 for m in recent if isinstance(m.get("leagueId"), int))
check("B5: جمع شمارش چیپ‌ها == سطرهای دارای leagueId",
      sum(counts) == rows_with_lid,
      f"sum={sum(counts)} vs rows={rows_with_lid}")
chip_ids = {l.get("leagueId") for l in (logl or [])}
row_ids = {m.get("leagueId") for m in recent if isinstance(m.get("leagueId"), int)}
check("B6: چیپ‌ست == لیگ‌های واقعاً در سطرها (بدون چیپ بی‌پشتوانه)", chip_ids == row_ids,
      f"chips={sorted(chip_ids)} rows={sorted(row_ids)}")

st2, raw2 = get(f"{BASE}/api/coach/30889")
d2 = json.loads(raw2.decode("utf-8"))
check("B7: /api/coach/30889 سالم (همان lib مشترک)", st2 == 200 and d2.get("ok") is True, f"{st2}")

# ----------------------------------------------------------------
print(f"\n=== نتیجه: {passed} PASS / {failed} FAIL ===")
sys.exit(1 if failed else 0)
