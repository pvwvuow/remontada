#!/usr/bin/env python3
# cycle-489 فیکس — پروب زندهٔ جام حذفی روسیه (کاپ 951803) — امکان‌سنجی ثبت کاتالوگ
# قواعد: UA Chrome/124، ریتم 1.8s، بازپس‌گیری 429/5xx با backoff
import json, subprocess, sys, time, datetime

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
PACE = 1.8

def fetch(url, tries=4):
    for i in range(tries):
        r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "30", "-A", UA, "-w", "\n%{http_code}", url],
                           capture_output=True, text=True)
        body, _, code = r.stdout.rpartition("\n")
        if code == "200":
            try:
                return json.loads(body)
            except Exception as e:
                print(f"  !! JSON parse fail {e}: {body[:120]}")
                return None
        print(f"  !! HTTP {code} try={i+1} — backoff {2*(i+1)}s")
        time.sleep(2 * (i + 1))
    return None

def poke(tag, url):
    print(f"\n=== {tag} ===\n  {url}")
    t = fetch(url)
    time.sleep(PACE)
    return t

out = {}
today = datetime.date.today().strftime("%Y%m%d")

def probe_league(tag, key, lid):
    lg = poke(tag, f"https://www.fotmob.com/api/data/leagues?id={lid}")
    o = {}
    if not lg:
        return {tag: "FETCH-FAIL"}
    det = lg.get("details", {})
    o[f"{key}_name"] = det.get("name")
    o[f"{key}_ccode"] = det.get("ccode")
    seas = det.get("seasons", []) or []
    o[f"{key}_seasons_n"] = len(seas)
    o[f"{key}_season_names_head"] = [s.get("name") for s in seas[:4]]
    tbl = lg.get("table", [])
    if tbl:
        d0 = tbl[0].get("data", {})
        t = d0.get("table")
        o[f"{key}_table_dict_keys"] = sorted(t.keys()) if isinstance(t, dict) else f"list:{type(t).__name__}"
        allrows = t.get("all") if isinstance(t, dict) else None
        o[f"{key}_table_all_n"] = len(allrows) if isinstance(allrows, list) else 0
        comps = d0.get("tables")
        if isinstance(comps, list) and comps:
            o[f"{key}_composite_names"] = [c.get("leagueName") for c in comps]
    else:
        o[f"{key}_table"] = "ABSENT"
    o[f"{key}_stats_players_n"] = len((lg.get("stats") or {}).get("players", []) or [])
    fx = (lg.get("fixtures") or {}).get("allMatches", []) or []
    o[f"{key}_fixtures_n"] = len(fx)
    o[f"{key}_fixtures_head"] = [
        {"id": f.get("id"), "home": (f.get("home") or {}).get("name"), "away": (f.get("away") or {}).get("name"), "round": f.get("round")}
        for f in fx[:3]
    ]
    o[f"{key}_hasCupShape"] = o[f"{key}_stats_players_n"] > 0 or o[f"{key}_fixtures_n"] > 0 or o[f"{key}_seasons_n"] > 0
    return o

out.update(probe_league("A) fotmob leagues?id=951803", "A", 951803))
out.update(probe_league("A2) fotmob leagues?id=193 (the day-feed parent)", "A2", 193))

# B) فید زندهٔ امروز: ردیف‌های روسیه — شناسهٔ لیگِ جام امروز چیست؟
md = poke(f"B) fotmob matches date={today}", f"https://www.fotmob.com/api/data/matches?date={today}")
rus_cup_rows = []
if md:
    for lg_ in md.get("leagues", []):
        cc = (lg_.get("ccode") or "").upper()
        lid = lg_.get("id")
        nm = lg_.get("name")
        if cc == "RUS":
            ms = lg_.get("matches", []) or []
            print(f"  RUS group: leagueId={lid} name={nm!r} parent={lg_.get('parentLeagueId')} matches={len(ms)}")
            if lid == 951803 or (nm or "").lower() == "cup":
                rus_cup_rows += [{"m": m.get("id"), "h": (m.get("home") or {}).get("name"), "a": (m.get("away") or {}).get("name")} for m in ms]
out["B_today_rus_cup"] = rus_cup_rows

# C) ESPN: اسلاگ فعال است؟
for slug in ("rus.cup", "russian.cup"):
    es = poke(f"C) ESPN soccer/{slug}", f"https://site.api.espn.com/apis/site/v2/sports/soccer/{slug}/scoreboard")
    if es:
        lginfo = (es.get("leagues") or [{}])[0]
        out[f"C_espn_{slug}"] = lginfo.get("name") or lginfo.get("slug")
        break

print("\n===== RESULT =====")
print(json.dumps(out, ensure_ascii=False, indent=1))
with open("/tmp/c489-probe.json", "w") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
