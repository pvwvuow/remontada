#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-357-historylinks.py — cycle-357 (آپدیت) live probe
«سوابق لیگ تیم ↔ آرشیو فصلی لیگ» — مصرف فیلد templateId ردیف‌های
historicalTableData (۰ مصرف سابق) برای لینک عمقی به فصل تاریخی لیگ.

فاز A (آپاستریم، UA Chrome/124): templateId روی همهٔ ردیف‌های ranks چند تیم
موجود است و به کاتالوگ سایت (LEAGUES keys معلوم) می‌خورد.
فاز B (سطح API سایت): /api/team-history/[id] هر آیتم leagueKey دارد؛
leagueKey ∈ کاتالوگ یا null؛ برای یک جفت (key, season) هدف، صفحهٔ
/league/<key>?season=... روی سایت 200 می‌دهد (لینک مرده ممنوع).

exit 1 روی هر FAIL.
"""
import json
import os
import sys
import urllib.request
import urllib.parse

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = os.environ.get("BASE", "http://localhost:3000")
# تیم‌های مرجع: لیورپول (۱۷ فصل PL)، تیم‌های با تاریخچهٔ دستهٔ دوم/دیگر
IDS = ["8650", "9826", "8456"]  # Liverpool, Crystal Palace, Man City
CATALOG_KEYS = {  # زیرمجموعهٔ شناخته‌شدهٔ کاتالوگ برای صحت‌سنجی
    "pl", "championship", "laliga", "segunda", "bundesliga", "2bundesliga",
    "seriea", "serieb", "ligue1", "ligue2", "ucl", "uel", "portugal",
    "eredivisie", "belgium", "turkey", "scotland", "brasileirao", "argentina",
}

passed, failed = 0, 0


def check(name, cond, detail=""):
    global passed, failed
    tag = "PASS" if cond else "FAIL"
    if cond:
        passed += 1
    else:
        failed += 1
    print(f"[{tag}] {name}" + (f" — {detail}" if detail else ""))


def get(url, timeout=25, ua=UA):
    req = urllib.request.Request(url, headers={"User-Agent": ua, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.status, r.read()


# ---------------------------------------------------------------- فاز A
print("=== فاز A — آپاستریم: templateId روی ردیف‌های سوابق ===")
for pid in IDS:
    try:
        st, raw = get(f"https://www.fotmob.com/api/data/teams?id={pid}")
        d = json.loads(raw.decode("utf-8"))
    except Exception as e:
        check(f"A{pid}: upstream", False, str(e))
        continue
    ranks = (d.get("history", {}).get("historicalTableData", {}) or {}).get("ranks") or []
    with_tid = [r for r in ranks if isinstance(r.get("templateId"), int)]
    check(f"A{pid} [{d.get('details', {}).get('name')}]: همهٔ ردیف‌های ranks templateId دارند",
          len(ranks) > 0 and len(with_tid) == len(ranks),
          f"{len(ranks)} ردیف، {len(with_tid)} با templateId")

# ---------------------------------------------------------------- فاز B
print("=== فاز B — سطح API سایت ===")
sample_link = None
for pid in IDS:
    try:
        st, raw = get(f"{BASE}/api/team-history/{pid}")
        d = json.loads(raw.decode("utf-8"))
    except Exception as e:
        check(f"B{pid}: /api/team-history قابل خواندن", False, str(e))
        continue
    check(f"B{pid}: HTTP 200 + ok", st == 200 and d.get("ok") is True, str(st))
    items = (d.get("history") or {}).get("items") or []
    check(f"B{pid}: {len(items)} آیتم سوابق", len(items) > 0)
    bad = [it.get("season") for it in items if it.get("leagueKey") not in (CATALOG_KEYS | {None})]
    check(f"B{pid}: leagueKey ∈ کاتالوگ یا null (بدون مقدار بیگانه)", not bad, f"bad={bad[:3]}")
    linked = [it for it in items if it.get("leagueKey")]
    check(f"B{pid}: حداقل یک ردیف لینک‌دار (کاتالوگ لیورپول/پالاس/سیتی)", len(linked) > 0,
          f"{len(linked)}/{len(items)} لینک‌دار")
    if linked and sample_link is None:
        sample_link = (linked[0]["leagueKey"], linked[0]["season"], pid)

if sample_link:
    key, season, pid = sample_link
else:
    key, season, pid = None, None, None

# عمیق‌ترین فصل لینک‌دار (قدیمی‌ترین) — اثبات واقعی آرشیو تاریخی
oldest = None
for pid2 in IDS:
    try:
        st, raw = get(f"{BASE}/api/team-history/{pid2}")
        d = json.loads(raw.decode("utf-8"))
        items = (d.get("history") or {}).get("items") or []
        linked = [it for it in items if it.get("leagueKey")]
        if linked:
            cand = min(linked, key=lambda it: it["season"])
            if oldest is None or cand["season"] < oldest[1]:
                oldest = (cand["leagueKey"], cand["season"], pid2)
    except Exception:
        pass
if oldest:
    key, season, pid = oldest

FA_DIGITS = str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹")
if key and season:
    url = f"{BASE}/league/{key}?season={urllib.parse.quote(season)}"
    try:
        st, body = get(url, ua="Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36")
        ok = st == 200 and len(body) > 5000
        check(f"B-target: صفحهٔ {url} روی سایت 200 و غیرخالی", ok, f"{st}, {len(body)} bytes")
        # نکته: LeagueView فصل را سمت کلاینت از URL می‌خواند (قرارداد cycle-99)
        # — محتوای فصل‌دار در SSR نمی‌آید؛ اثبات رندر فصل در DOM (agent-browser)
        # انجام می‌شود. اینجا فقط مونت اولیهٔ صفحه لیگ + سشن و روتینگ چک می‌شود.
        check("B-target: HTML مونت اولیهٔ LeagueView/شل لیگ را دارد",
              b"LeagueView" in body or b"league-view" in body or "رمانتادا".encode() in body,
              "shell markers")
    except Exception as e:
        check(f"B-target: صفحهٔ {url}", False, str(e))

print(f"\n=== نتیجه: {passed} PASS / {failed} FAIL ===")
sys.exit(1 if failed else 0)
