#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-362-iraq-feas.py — cycle-362 (آپدیت) feasibility probe
امکان‌سنجی «لیگ ستارگان عراق» (fotmobId 524) — کاندیدای ثبت‌شدهٔ کارت ۳۶۱.

فاز A (آپاستریم، UA Chrome/124):
  A1  leagues?id=524&ccode3=IRQ → ok + details.name + جدول + تعداد فصل‌ها
  A2  allAvailableSeasons ≥ 12؟ (شرط ادغام بدون تنگ‌کردن پنجرهٔ ۱۲)
  A3  transfers.data و stats (انتظار: خالی — سطح نازک، ثبت رسمی)
  A4  hasTotw (انتظار: false)
  A5  یک فصل تاریخی (قدیمی‌ترین) → جدول واقعی
  A6  نام دقیق تیم‌های ردیف زنده (برای TEAM_FA)
exit 1 روی هر FAIL فاز A اصلی؛ A3/A4 انتظاری‌اند (بی‌خطر اگر مطابق انتظار).
"""
import json
import urllib.request
import urllib.error
import sys

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

passed, failed = 0, 0


def check(name, cond, detail=""):
    global passed, failed
    tag = "PASS" if cond else "FAIL"
    if cond:
        passed += 1
    else:
        failed += 1
    print(f"[{tag}] {name}" + (f" — {detail}" if detail else ""))


def get_json(url, timeout=40):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


print("=== فاز A: آپاستریم عراق ۵۲۴ (UA Chrome/124) ===")

payload = get_json("https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en")
ok = isinstance(payload, dict) and len(payload) > 5  # engine contract: object suffices
check("A1 leagues?id=524 payload شیء کامل", ok, f"keys={list(payload.keys())[:8]}")
if not ok:
    sys.exit(1)

details = payload.get("details", {})
name = details.get("name")
check("A1b details.name", bool(name), f"name={name!r}")
ov = (payload.get("overview") or {})
check("A1c overview.hasTotw (انتظار false)", ov.get("hasTotw") is False, f"hasTotw={ov.get('hasTotw')}")

table = payload.get("table")
rows = []
if isinstance(table, list) and table:
    rows = ((table[0].get("data") or {}).get("table") or {}).get("all") or []
check("A1d ردیف‌های جدول", len(rows) > 0, f"rows={len(rows)}")

seasons = payload.get("allAvailableSeasons") or []
check("A2 فصل‌ها ≥ 12", len(seasons) >= 12,
      f"n={len(seasons)} newest={seasons[0] if seasons else None} oldest={seasons[-1] if seasons else None}")

transfers = payload.get("transfers") or {}
tr_data = transfers.get("data") or []
n_tr = len(tr_data) if isinstance(tr_data, list) else 0
check("A3a transfers.data حاضر (لیست)", n_tr > 0, f"n={n_tr}")

stats = payload.get("stats") or {}
sp = stats.get("players")
check("A3b stats.players (انتظار خالی — سطح نازک)", True,
      f"stats keys={list(stats.keys())[:8]} players={'None' if sp is None else len(sp) if isinstance(sp, list) else type(sp).__name__}")

# A5: قدیمی‌ترین فصل
if seasons:
    oldest = seasons[-1]
    try:
        hist = get_json(
            f"https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en&season={urllib.parse.quote(oldest)}"
        )
        hok = isinstance(hist, dict) and len(hist) > 5
        htab = hist.get("table")
        hrows = []
        if isinstance(htab, list) and htab:
            hrows = ((htab[0].get("data") or {}).get("table") or {}).get("all") or []
        check("A5 فصل تاریخی جدول دارد", hok and len(hrows) > 0,
              f"season={oldest} rows={len(hrows)} selectedSeason={hist.get('selectedSeason')}")
    except Exception as e:
        check("A5 فصل تاریخی", False, f"err={e}")

# A6: نام تیم‌های زنده
if rows:
    names = []
    for r in rows:
        t = r.get("teams") or r.get("team") or {}
        if isinstance(t, dict):
            nm = t.get("name") or {}
            if isinstance(nm, dict) and nm.get("name"):
                names.append(nm["name"])
            elif isinstance(nm, str):
                names.append(nm)
    check("A6 نام تیم‌های زنده استخراج شد", len(names) > 0, f"n={len(names)}: {names[:20]}")

print(f"\n=== جمع‌بندی: PASS={passed} FAIL={failed} ===")
sys.exit(1 if failed else 0)
