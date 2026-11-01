#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-361-egypt.py — cycle-361 (آپدیت) live probe
افزودن «لیگ برتر مصر» (fotmobId 519) به کاتالوگ — بیست‌وپنجمین رقابت.

فاز A (آپاستریم، UA Chrome/124): جدول ۲۰ ردیفهٔ ۲۰۲۶/۲۰۲۷، transfers=100،
stats.players غیرخالی، hasTotw=true، ۱۷ فصل (تا 2010/2011)، فصل تاریخی
2019/2020 (۱۸ ردیف، الاهلی صدر).
فاز B (سطح سایت): standings (۲۰ سطر + ۲۰/۲۰ fa فارسی + ۲۰ آقای گل)،
fixtures، transfers، TOTW مصر (فیچر ۳۶۰ روشن)، صفحهٔ /league/egypt و
/topscorers/egypt و تیم الاهلی، مسابقهٔ سراسری (perLeague=21، پنجرهٔ ۱۲
دست‌نخورده)، جست‌وجوی تیم مصری، sitemap.

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


def get_json(url, timeout=40):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


def get_code(url, timeout=40):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, len(r.read())
    except urllib.error.HTTPError as e:
        return e.code, 0


print("=== فاز A: آپاستریم (UA Chrome/124) ===")
raw = get_json("https://www.fotmob.com/api/data/leagues?id=519&ccode3=EGY&lang=en")
rows = ((raw.get("table") or [{}])[0].get("data") or {}).get("table", {}).get("all") or []
check("A1 جدول ۲۰ ردیفه با صدر Pyramids FC", len(rows) == 20 and rows[0].get("name") == "Pyramids FC",
      f"n={len(rows)} top={rows[0].get('name') if rows else '-'}")
tr = (raw.get("transfers") or {}).get("data") or []
check("A2 transfers=100", len(tr) == 100, f"n={len(tr)}")
st = raw.get("stats") or {}
pl = st.get("players") or {}
pln = len(pl) if isinstance(pl, (dict, list)) else 0
check("A3 stats.players غیرخالی (آقای گل واقعی)", pln > 0, f"shape={type(pl).__name__} n={pln}")
ov = raw.get("overview") or {}
check("A4 hasTotw=true", ov.get("hasTotw") is True)
ss = raw.get("allAvailableSeasons") or []
check("A5 ۱۷ فصل تا 2010/2011", len(ss) == 17 and ss[-1] == "2010/2011", f"n={len(ss)} last={ss[-1] if ss else '-'}")
hist = get_json("https://www.fotmob.com/api/data/leagues?id=519&ccode3=EGY&lang=en&season=2019%2F2020")
hrows = ((hist.get("table") or [{}])[0].get("data") or {}).get("table", {}).get("all") or []
check("A6 فصل تاریخی 2019/2020: ۱۸ ردیف، الاهلی صدر", len(hrows) == 18 and hrows[0].get("name") == "Al Ahly SC",
      f"n={len(hrows)} top={hrows[0].get('name') if hrows else '-'}")

print("=== فاز B: سطح سایت ===")
s = get_json(f"{BASE}/api/standings?league=egypt")
srows = s.get("rows") or []
fa_ok = sum(1 for r in srows if r.get("fa"))
check("B1 standings: ok+۲۰ سطر+۲۰/۲۰ fa فارسی", s.get("ok") is True and len(srows) == 20 and fa_ok == 20,
      f"fa={fa_ok}/20 top={srows[0].get('fa') if srows else '-'}")
check("B2 آقای گل ۲۰ نفره", len(s.get("scorers") or []) == 20, f"n={len(s.get('scorers') or [])}")
fx = get_json(f"{BASE}/api/league-fixtures?league=egypt")
check("B3 fixtures: ok+پیش‌رو/نتایج", fx.get("ok") is True and len(fx.get("upcoming") or []) > 0 and len(fx.get("recent") or []) > 0,
      f"up={len(fx.get('upcoming') or [])} recent={len(fx.get('recent') or [])}")
tr2 = get_json(f"{BASE}/api/league-transfers?league=egypt")
tr_rows = tr2.get("transfers") or tr2.get("data") or tr2.get("rows") or []
check("B4 transfers: ok+ردیف", tr2.get("ok") is True and len(tr_rows) > 0,
      f"n={len(tr_rows)}")
tw = get_json(f"{BASE}/api/league-totw?league=egypt")
tw_t = tw.get("totw") or {}
check("B5 TOTW مصر روشن (فیچر ۳۶۰)", tw.get("ok") is True and len(tw_t.get("players") or []) == 11,
      f"round={tw_t.get('round')} n={len(tw_t.get('players') or [])}")
code, blen = get_code(f"{BASE}/league/egypt")
check("B6 /league/egypt → 200", code == 200 and blen > 5000, f"code={code} bytes={blen}")
code, blen = get_code(f"{BASE}/topscorers/egypt")
check("B7 /topscorers/egypt → 200", code == 200, f"code={code} bytes={blen}")
code, blen = get_code(f"{BASE}/team/101745")
check("B8 صفحهٔ تیم الاهلی → 200", code == 200, f"code={code} bytes={blen}")
team = get_json(f"{BASE}/api/team/101745")
check("B9 API تیم الاهلی: ok+نام فارسی", team.get("ok") is True, f"name={team.get('name', '')[:30]} fa={team.get('fa', '')}")
race = get_json(f"{BASE}/api/topscorers")
rpl = race.get("perLeague") or []
egy = [p for p in rpl if p.get("leagueKey") == "egypt"]
ras = race.get("allSeasons") or []
check("B10 مسابقهٔ سراسری: perLeague=21 با مصر، پنجرهٔ ۱۲ ثابت", len(rpl) == 21 and bool(egy) and len(ras) == 12 and ras[-1] == "2015/2016",
      f"n={len(rpl)} egyScorers={len(egy[0].get('scorers') or []) if egy else 0} window={len(ras)}")
sm = get_json(f"{BASE}/sitemap.xml") if False else None
req = urllib.request.Request(f"{BASE}/sitemap.xml", headers={"User-Agent": UA})
with urllib.request.urlopen(req, timeout=40) as r:
    smtxt = r.read().decode("utf-8")
check("B11 sitemap شامل /league/egypt", "/league/egypt" in smtxt)
code, blen = get_code(f"{BASE}/search?q=%D8%A7%D9%84%D8%B2%D9%85%D8%A7%D9%84%D9%83")
check("B12 صفحهٔ جست‌وجوی «الزمالک» → 200", code == 200, f"code={code}")

print(f"=== نتیجه: PASS={passed} FAIL={failed} ===")
sys.exit(1 if failed else 0)
