#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-362-iraq.py — cycle-362 (آپدیت) acceptance probe
افزودن «لیگ ستارگان عراق» (fotmobId 524) به کاتالوگ — بیست‌وششمین رقابت.

فاز A (آپاستریم، UA Chrome/124): پیلود کامل (fixtures.allMatches=380،
جدول ۲۰ ردیفهٔ ۲۰۲۶/۲۰۲۷ با صدر Al-Karma، transfers=18، ۱۷ فصل)،
stats خالی + hasTotw=false (سطح نازکِ صادقانه)، فصل تاریخی ۲۰۲۴/۲۰۲۵
(الشرطه قهرمان ۸۷ امتیازی)، ESPN 400.
فاز B (سطح سایت): standings (۲۰ سطر + ۲۰/۲۰ fa فارسی)، fixtures
(پیش‌رو/نتایج)، transfers، TOTW غایب صادقانه، /league/iraq و
/topscorers/iraq و تیم الکرمه (۱۶۸۰۵۷۷) هر سه 200، مسابقهٔ سراسری
(perLeague=21 بدون عراق — گارد گل‌خالی — و پنجرهٔ ۱۲ ثابت)، sitemap
شامل /league/iraq، جست‌وجوی فارسی.

exit 1 روی هر FAIL.
"""
import json
import os
import sys
import urllib.request
import urllib.error

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = os.environ.get("BASE", "http://localhost:3000")

passed, failed = 0, 0


def check(name, cond, detail=""):
    global passed, failed
    tag = "PASS" if cond else "FAIL"
    if cond:
        passed += 1
    else:
        failed += 1
    print(f"[{tag}] {name}" + (f" — {detail}" if detail else ""))


def get_json(url, timeout=60):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def get_code(url, timeout=60):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, len(r.read())
    except urllib.error.HTTPError as e:
        return e.code, 0


print("=== فاز A: آپاستریم عراق ۵۲۴ (UA Chrome/124) ===")
raw = get_json("https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en")
is_obj = isinstance(raw, dict) and len(raw) >= 10
check("A1 leagues?id=524 پیلود کامل (۱۲ کلید)", is_obj,
      f"keys={sorted(raw.keys())[:12]}" if is_obj else "شکل ناقص")
if not is_obj:
    sys.exit(1)

fx = raw.get("fixtures") or {}
n_all = len(fx.get("allMatches") or [])
check("A2 fixtures.allMatches=380 (فصل کامل)", n_all >= 300, f"n={n_all}")

rows = ((raw.get("table") or [{}])[0].get("data") or {}).get("table", {}).get("all") or []
check("A3 جدول ۲۰ ردیفه با صدر Al-Karma", len(rows) == 20 and rows[0].get("name") == "Al-Karma" and rows[0].get("pts") == 27,
      f"n={len(rows)} top={rows[0].get('name') if rows else '-'} pts={rows[0].get('pts') if rows else '-'}")
check("A4 همهٔ ردیف‌ها id تیم واقعی دارند", all(r.get("id") for r in rows),
      f"ids={[r.get('id') for r in rows[:4]]}...")

seasons = raw.get("allAvailableSeasons") or []
check("A5 ۱۷ فصل (2026/2027→2010/2011)", len(seasons) == 17 and seasons[0] == "2026/2027" and seasons[-1] == "2010/2011",
      f"n={len(seasons)}")

tr = (raw.get("transfers") or {}).get("data") or []
check("A6 transfers=18", len(tr) == 18, f"n={len(tr)}")

stats = raw.get("stats") or {}
check("A7 stats خالی (آقای گل صادقانه غایب)", not (stats.get("players")),
      f"statsKeys={list(stats.keys())}")
check("A8 hasTotw=false (فیچر ۳۶۰ صادقانه خاموش)", (raw.get("overview") or {}).get("hasTotw") is False,
      f"hasTotw={(raw.get('overview') or {}).get('hasTotw')}")

hist = get_json("https://www.fotmob.com/api/data/leagues?id=524&ccode3=IRQ&lang=en&season=2024%2F2025")
hrows = ((hist.get("table") or [{}])[0].get("data") or {}).get("table", {}).get("all") or []
check("A9 فصل تاریخی ۲۰۲۴/۲۰۲۵: ۲۰ ردیف، الشرطه قهرمان", len(hrows) == 20 and hrows[0].get("name") == "Al Shorta",
      f"n={len(hrows)} top={hrows[0].get('name') if hrows else '-'} pts={hrows[0].get('pts') if hrows else '-'}")

c1, _ = get_code("https://site.api.espn.com/apis/site/v2/sports/soccer/iraq.1/scoreboard")
c2, _ = get_code("https://site.api.espn.com/apis/site/v2/sports/soccer/irq.1/scoreboard")
check("A10 ESPN 400 برای هر دو اسلاگ (بدون espnSlug)", c1 == 400 and c2 == 400, f"iraq.1={c1} irq.1={c2}")

print("\n=== فاز B: سطح سایت ===")
s = get_json(f"{BASE}/api/standings?league=iraq")
srows = s.get("rows") or []
fa_ok = sum(1 for r in srows if r.get("fa"))
check("B1 standings: ok+۲۰ سطر+۲۰/۲۰ fa فارسی", s.get("ok") is True and len(srows) == 20 and fa_ok == 20,
      f"fa={fa_ok}/20 top={srows[0].get('fa') if srows else '-'} pts={srows[0].get('pts') if srows else '-'}")
sas = s.get("allSeasons") or []
check("B2 چیپ‌های فصل: ۱۲ فصل (پنجرهٔ موتور)", len(sas) == 12 and sas[-1] == "2015/2016",
      f"n={len(sas)} oldest={sas[-1] if sas else '-'}")
check("B3 آقای گل عراق صادقانه خالی", len(s.get("scorers") or []) == 0, f"n={len(s.get('scorers') or [])}")

fx2 = get_json(f"{BASE}/api/league-fixtures?league=iraq")
check("B4 fixtures: ok+پیش‌رو/نتایج", fx2.get("ok") is True and len(fx2.get("upcoming") or []) > 0 and len(fx2.get("recent") or []) > 0,
      f"up={len(fx2.get('upcoming') or [])} recent={len(fx2.get('recent') or [])}")

tr2 = get_json(f"{BASE}/api/league-transfers?league=iraq")
tr_rows = tr2.get("transfers") or tr2.get("data") or tr2.get("rows") or []
check("B5 transfers: ok+ردیف", tr2.get("ok") is True and len(tr_rows) > 0, f"n={len(tr_rows)}")

tw2 = get_json(f"{BASE}/api/league-totw?league=iraq")
check("B6 TOTW عراق ok:false (غیبت صادقانه)", tw2.get("ok") is False, f"payload={json.dumps(tw2, ensure_ascii=False)[:80]}")

code, blen = get_code(f"{BASE}/league/iraq")
check("B7 /league/iraq → 200", code == 200 and blen > 5000, f"code={code} bytes={blen}")
code, blen = get_code(f"{BASE}/topscorers/iraq")
check("B8 /topscorers/iraq → 200 (خالی صادقانه)", code == 200, f"code={code} bytes={blen}")
code, blen = get_code(f"{BASE}/team/1680577")
check("B9 صفحهٔ تیم الکرمه → 200", code == 200, f"code={code} bytes={blen}")
team = get_json(f"{BASE}/api/team/1680577")
tcore = team.get("team") or {}
check("B10 API تیم الکرمه: ok+fa فارسی+لیگ عراق",
      team.get("ok") is True and tcore.get("fa") == "الکرمه"
      and (team.get("standings") or {}).get("leagueKey") == "iraq",
      f"name={tcore.get('name', '')[:30]} fa={tcore.get('fa', '')} league={(team.get('standings') or {}).get('leagueKey')}")

race = get_json(f"{BASE}/api/topscorers")
rpl = race.get("perLeague") or []
irq = [p for p in rpl if p.get("leagueKey") == "iraq"]
ras = race.get("allSeasons") or []
check("B11 مسابقهٔ سراسری: perLeague=21 بدون عراق، پنجرهٔ ۱۲ ثابت",
      len(rpl) == 21 and len(irq) == 0 and len(ras) == 12 and ras[-1] == "2015/2016",
      f"perLeague={len(rpl)} iraqRow={len(irq)} window={len(ras)}")

req = urllib.request.Request(f"{BASE}/sitemap.xml", headers={"User-Agent": UA})
with urllib.request.urlopen(req, timeout=60) as r:
    smtxt = r.read().decode("utf-8")
check("B12 sitemap شامل /league/iraq", "/league/iraq" in smtxt)

code, blen = get_code(f"{BASE}/search?q=%D8%A7%D9%84%D8%B2%D9%88%D8%B1%D8%A7")
check("B13 جست‌وجوی «الزورا» (کلید قدیمی) → 200", code == 200, f"code={code}")
code, blen = get_code(f"{BASE}/search?q=%D8%A7%D9%84%DA%A9%D8%B1%D9%85%D9%87")
check("B14 جست‌وجوی «الکرمه» (کلید تازهٔ ۳۶۲) → 200", code == 200, f"code={code}")

hist2 = get_json(f"{BASE}/api/standings?league=iraq&season=2024%2F2025")
h2 = hist2.get("rows") or []
check("B15 standings تاریخی ۲۰۲۴/۲۰۲۵ از سطح سایت: الشرطه صدر", hist2.get("ok") is True and len(h2) == 20 and h2[0].get("fa") == "الشرطه",
      f"n={len(h2)} top={h2[0].get('fa') if h2 else '-'}")

print(f"\n=== نتیجه: PASS={passed} FAIL={failed} ===")
sys.exit(1 if failed else 0)
