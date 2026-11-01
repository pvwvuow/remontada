#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-356-stage.py — cycle-356 (آپدیت) live probe
بج «مرحلهٔ حذفی» سطرهای آرشیو بازیکن — مصرف فیلد stage آپاستریم.

فاز A (آپاستریم، UA Chrome/124، ۷ بازیکن): مجموعهٔ واقعی کدهای stage؛
هر کد تازه‌ای که بیاید WARN (بج پنهان می‌ماند — قرارداد غیبت صادقانه).
فاز B (سطح API سایت): سطرها stage خام دارند؛ مجموعه/شمارش با آپاستریم
همان بازیکن برابر؛ بدون کد اختراعی.

exit 1 روی هر FAIL.
"""
import json
import os
import sys
import urllib.request

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = os.environ.get("BASE", "http://localhost:3000")
# کدهای نگاشت‌شده در STAGE_FA (player-recent.tsx) — فقط همین‌ها بج می‌گیرند
KNOWN = {"1/32", "1/16", "1/8", "1/4", "1/2", "final", "bronze"}
IDS = ["696679", "1417094", "1186606", "408987", "958232", "701154", "1467236"]

passed, failed, warned = 0, 0, 0


def check(name, cond, detail=""):
    global passed, failed
    tag = "PASS" if cond else "FAIL"
    if cond:
        passed += 1
    else:
        failed += 1
    print(f"[{tag}] {name}" + (f" — {detail}" if detail else ""))


def warn(name, detail=""):
    global warned
    warned += 1
    print(f"[WARN] {name}" + (f" — {detail}" if detail else ""))


def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


# ---------------------------------------------------------------- فاز A
print("=== فاز A — آپاستریم: مجموعهٔ کدهای stage ===")
upstream = {}
for pid in IDS:
    try:
        d = get(f"https://www.fotmob.com/api/data/playerData?id={pid}")
    except Exception as e:
        check(f"A{pid}: upstream", False, str(e))
        continue
    rows = d.get("recentMatches") or []
    codes = {}
    for m in rows:
        s = m.get("stage")
        if isinstance(s, str):
            codes[s] = codes.get(s, 0) + 1
    upstream[pid] = codes
    print(f"  {pid} [{d.get('name')}]: {len(rows)} سطر، کدها: {codes or '—'}")
    for c in codes:
        if c not in KNOWN:
            warn(f"A{pid}: کد ناشناختهٔ «{c}» — بج پنهان می‌ماند؛ نقشه را کامل کنید")

# ---------------------------------------------------------------- فاز B
print("=== فاز B — سطح API سایت ===")
for pid in ["696679", "1186606"]:
    st_code, raw = None, None
    try:
        req = urllib.request.Request(f"{BASE}/api/player/{pid}", headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=25) as r:
            st_code = r.status
            raw = json.loads(r.read().decode("utf-8"))
    except Exception as e:
        check(f"B{pid}: /api/player قابل خواندن", False, str(e))
        continue
    check(f"B{pid}: HTTP 200", st_code == 200, str(st_code))
    p = raw.get("player") or {}
    rows = p.get("recent") or []
    site_codes = {}
    for m in rows:
        s = m.get("stage")
        if isinstance(s, str):
            site_codes[s] = site_codes.get(s, 0) + 1
    up_codes = upstream.get(pid, {})
    check(f"B{pid}: شمارش سطرهای دارای stage == آپاستریم",
          sum(site_codes.values()) == sum(up_codes.values()),
          f"site={sum(site_codes.values())} upstream={sum(up_codes.values())}")
    check(f"B{pid}: مجموعهٔ کدهای سایت ⊆ آپاستریم همان بازیکن (بدون اختراع)",
          set(site_codes) <= set(up_codes),
          f"site={sorted(site_codes)} upstream={sorted(up_codes)}")
    check(f"B{pid}: همهٔ کدهای سایت در نقشهٔ شناخته‌شده‌اند (بج می‌گیرند)",
          set(site_codes) <= KNOWN, f"{sorted(site_codes)}")

# جمع کل فاز A باید درون KNOWN باشد وگرنه فقط WARN بالا دادیم
agg = {}
for codes in upstream.values():
    for k, v in codes.items():
        agg[k] = agg.get(k, 0) + v
print(f"\nمجموع آپاستریم: {agg}")
new_codes = set(agg) - KNOWN
if new_codes:
    warn("کدهای بیرون نقشه (بج پنهان، غیبت صادقانه):", str(sorted(new_codes)))

print(f"\n=== نتیجه: {passed} PASS / {failed} FAIL / {warned} WARN ===")
sys.exit(1 if failed else 0)
