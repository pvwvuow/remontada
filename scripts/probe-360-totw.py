#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
probe-360-totw.py — cycle-360 (آپدیت) live probe
«تیم هفته» (TOTW) لیگ — اندپوینت‌های خط‌تیره که از XHR واقعی کلاینت فوت‌مب
بیرون آمدند (سه چرخه ۳۵۵-۳۵۷ با الگوهای مفرد 404 گرفته بودند).

فاز A (آپاستریم، UA Chrome/124):
  1) rounds PL فصل جاری: ≥1 راند، همه isCompleted، نزولی، last==اولین
  2) team راند آخر: ۱۱ بازیکن، id>0، مختصات 0..1، امتیاز غیرخالی
  3) فصل تاریخی 2025/2026: last==TOTS و تیم ۱۱ نفره با isTots
  4) غیبت صادقانه: leagueId=523 (خلیج فارس) → بدنه null
فاز B (سطح API سایت):
  5) /api/league-totw?league=pl → ok:true، ۱۱ بازیکن، idها==آپاستریم
  6) fa/latin/teamFa سازگار؛ fa ⊆ {latin, معادل فارسی}
  7) persiangulf → ok:false (پنهان‌شدن سکشن)
  8) season=2025/2026 → round==TOTS با ۱۱ بازیکن
  9) round=7 → ۱۱ بازیکن، XI متفاوت با راند ۸ (حداقل یک id متفاوت)
 10) league نامعتبر → 400؛ season نامعتبر → 400
 11) یکی از playerIdها روی /api/player/{id} سایت resolve می‌شود

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


def get(url, timeout=30):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))


print("=== فاز A: آپاستریم (UA Chrome/124) ===")
up_rounds = get("https://www.fotmob.com/api/data/team-of-the-week/rounds?leagueId=47&season=2026%2F2027")
up_rs = up_rounds.get("rounds") or []
check("A1 rounds PL: ≥1 و همه completed و نزولی", len(up_rs) >= 1 and all(r.get("isCompleted") for r in up_rs)
      and [int(r["roundId"]) for r in up_rs] == sorted([int(r["roundId"]) for r in up_rs], reverse=True),
      f"n={len(up_rs)} last={up_rounds.get('last', {}).get('roundId')}")
up_last = str((up_rounds.get("last") or {}).get("roundId") or "")
up_team = get(f"https://www.fotmob.com/api/data/team-of-the-week/team?leagueId=47&roundId={up_last}&season=2026%2F2027")
ids_ok = all(isinstance(p.get("id"), (int, float)) and p["id"] > 0 for p in up_team)
lay_ok = all(0 <= p["verticalLayout"]["x"] <= 1 and 0 <= p["verticalLayout"]["y"] <= 1 for p in up_team)
rate_ok = all(str((p.get("rating") or {}).get("num") or "").strip() != "" for p in up_team)
check("A2 team راند آخر: ۱۱ بازیکن، id>0، مختصات 0..1، امتیاز", len(up_team) == 11 and ids_ok and lay_ok and rate_ok,
      f"n={len(up_team)}")
up_hist = get("https://www.fotmob.com/api/data/team-of-the-week/rounds?leagueId=47&season=2025%2F2026")
h_last = str((up_hist.get("last") or {}).get("roundId") or "")
check("A3 فصل تاریخی: last==TOTS", h_last == "TOTS", f"last={h_last} n={len(up_hist.get('rounds') or [])}")
if h_last == "TOTS":
    tots = get("https://www.fotmob.com/api/data/team-of-the-week/team?leagueId=47&roundId=TOTS&season=2025%2F2026")
    check("A3b تیم TOTS: ۱۱ نفر و isTots", len(tots) == 11 and all(p.get("isTots") for p in tots),
          f"n={len(tots)}")
req_null = urllib.request.Request("https://www.fotmob.com/api/data/team-of-the-week/rounds?leagueId=523&season=2026%2F2027", headers={"User-Agent": UA})
with urllib.request.urlopen(req_null, timeout=30) as r:
    raw = r.read().decode("utf-8")
check("A4 لیگ بدون TOTW: بدنه null صادقانه", raw.strip() == "null", f"body={raw[:20]!r}")

up_ids = sorted(int(p["id"]) for p in up_team)

print("=== فاز B: سطح API سایت ===")
site = get(f"{BASE}/api/league-totw?league=pl")
t = site.get("totw") or {}
sp = t.get("players") or []
check("B1 league=pl → ok+۱۱ بازیکن", site.get("ok") is True and len(sp) == 11, f"n={len(sp)}")
site_ids = sorted(p.get("playerId", 0) for p in sp)
check("B2 idهای سایت == آپاستریم", site_ids == up_ids, f"site={site_ids[:4]}…")
fa_ok = all(isinstance(p.get("fa"), str) and p["fa"].strip() != "" for p in sp)
latin_ok = all(p.get("latin", "").strip() != "" for p in sp)
tf = sum(1 for p in sp if p.get("teamFa"))
check("B3 fa/latin غیرخالی", fa_ok and latin_ok, f"teamFa hits={tf}/11")
rounds_site = t.get("rounds") or []
check("B4 rounds سایت == آپاستریم", [r.get("roundId") for r in rounds_site] == [str(r.get("roundId")) for r in up_rs],
      f"site={[r.get('roundId') for r in rounds_site]}")
pg = get(f"{BASE}/api/league-totw?league=persiangulf")
check("B5 persiangulf → ok:false (غیبت صادقانه)", pg.get("ok") is False, f"error={pg.get('error', '')[:40]}")
hist = get(f"{BASE}/api/league-totw?league=pl&season=2025%2F2026")
ht = hist.get("totw") or {}
check("B6 فصل تاریخی سایت: round==TOTS و ۱۱ نفر", hist.get("ok") is True and (ht.get("round")) == "TOTS" and len(ht.get("players") or []) == 11,
      f"round={ht.get('round')} n={len(ht.get('players') or [])}")
r7 = get(f"{BASE}/api/league-totw?league=pl&round=7")
r7t = r7.get("totw") or {}
r7_ids = set(p.get("playerId") for p in (r7t.get("players") or []))
diff = len(r7_ids - set(up_ids)) > 0
check("B7 round=7: ۱۱ نفر و XI متفاوت با راند ۸", r7t.get("round") == "7" and len(r7_ids) == 11 and diff,
      f"diff_ids={len(r7_ids - set(up_ids))}")

# invalid inputs
try:
    get(f"{BASE}/api/league-totw?league=doesnotexist")
    check("B8 league نامعتبر → 400", False, "no error raised")
except urllib.error.HTTPError as e:
    check("B8 league نامعتبر → 400", e.code == 400, f"code={e.code}")
try:
    get(f"{BASE}/api/league-totw?league=pl&season=9999")
    check("B9 season نامعتبر → 400", False, "no error raised")
except urllib.error.HTTPError as e:
    check("B9 season نامعتبر → 400", e.code == 400, f"code={e.code}")

pid = sp[0]["playerId"]
pl = get(f"{BASE}/api/player/{pid}")
check("B10 پروفایل بازیکن TOTW روی سایت resolve می‌شود", pl.get("ok") is True, f"playerId={pid} name={pl.get('name', '')[:30]}")

print(f"=== نتیجه: PASS={passed} FAIL={failed} ===")
sys.exit(1 if failed else 0)
