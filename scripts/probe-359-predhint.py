#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-359-predhint.py — cycle-359 (فیکس/پولیش) live probe
hint «ترکیب پیش‌بینی‌شده ثبت شده است» روی تب رویدادهای مسابقهٔ پیش از شروع.

قرارداد (باید روی هر مسابقه برقرار باشد):
  hint_cond = (not started) and (not cancelled) and (lineups.predicted is True)
  — پیش‌بازی با ترکیب پیش‌بینی‌شده  → hint باید رندر شود (فاز B این را با DOM
  جداگانه ثابت می‌کند؛ اینجا شرط payload بررسی می‌شود)
  — هر حالت دیگر (شروع‌شده، تمام‌شده، لغو، پیش‌بازی بدون پرچم ۳۵۲) → شرط غلط
  = مارکاپ قدیمی بایت‌به‌بایت (غیبت صادقانه).

exit 1 روی هر FAIL.
"""
import json
import os
import sys
import urllib.request

BASE = os.environ.get("BASE", "http://localhost:3000")
# ۴ مسابقهٔ مرجع کارت ۳۵۸ + لغو/بدون ترکیب اگر آپاستریم داد
IDS = ["5795501", "5749733", "5868116", "5868111"]

passed, failed = 0, 0


def check(name, cond, detail=""):
    global passed, failed
    tag = "PASS" if cond else "FAIL"
    if cond:
        passed += 1
    else:
        failed += 1
    print(f"[{tag}] {name}" + (f" — {detail}" if detail else ""))


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (remontada-probe)"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


print("=== فاز A: قرارداد payload روی مسابقه‌های مرجع ===")
hint_true, hint_false = [], []
for mid in IDS:
    try:
        d = get(f"{BASE}/api/match/{mid}")
    except Exception as e:
        check(f"match {mid} fetch", False, str(e))
        continue
    ok = d.get("ok") is True
    m = d.get("match") or {}
    started = bool(m.get("started"))
    finished = bool(m.get("finished"))
    cancelled = bool(m.get("cancelled"))
    lu = d.get("lineups")
    predicted = bool(lu and lu.get("predicted") is True)
    has_sides = bool(lu and lu.get("home") is not None and lu.get("away") is not None)
    cond = (not started) and (not cancelled) and predicted and has_sides
    state = "لغو" if cancelled else ("تمام‌شده" if finished else ("شروع‌شده/زنده" if started else "پیش‌بازی"))
    check(f"match {mid} ok+shape", ok and "lineups" in d, f"state={state} predicted={predicted} sides={has_sides}")
    if cond:
        hint_true.append((mid, state))
    else:
        hint_false.append((mid, state))

# ۳۵۸: ۵۷۹۵۵۰۱ پیش‌بازی است و بنر ۳۵۲ دارد → شرط hint باید TRUE باشد
check("5795501 (پیش‌بازی مرجع) hint_cond=True", any(mid == "5795501" for mid, _ in hint_true),
      f"hint_true={[m for m, _ in hint_true]}")
# ۳۵۸: ۵۷۴۹۷۳۳ تمام‌شده است (۱۹ رویداد) → شرط hint باید FALSE باشد
check("5749733 (تمام‌شدهٔ مرجع) hint_cond=False", any(mid == "5749733" for mid, _ in hint_false),
      f"hint_false={[m for m, _ in hint_false]}")

print(f"--- hint_true={hint_true}")
print(f"--- hint_false={hint_false}")

print("=== فاز A2: خودپایداری پیش‌بازی مرجع (بنر ۳۵۲ همان payload) ===")
d = get(f"{BASE}/api/match/5795501")
lu = d["lineups"]
home = lu.get("home") or {}
check("5795501 lineups.predicted is True", lu.get("predicted") is True)
check("5795501 home side has formation+rows", bool(home.get("formation")) and isinstance(home.get("rows"), list) and len(home.get("rows", [])) > 0,
      f"formation={home.get('formation')} rows={len(home.get('rows', []) or [])}")
coach = home.get("coach")
check("5795501 home coach id present (354 contract intact)", isinstance(coach, str) and coach.strip() != "" or isinstance(coach, (int, float)),
      f"coach={coach!r} coachId={home.get('coachId')!r}")

print(f"=== نتیجه: PASS={passed} FAIL={failed} ===")
sys.exit(1 if failed else 0)
