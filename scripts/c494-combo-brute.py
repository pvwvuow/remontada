# -*- coding: utf-8 -*-
# cycle-494: find the working /api/data/leagues combo for MLS — ccode3 brute
# (USA/MLS/INT/WOR/AME/NAM) x ids (130, 913550) x season=2026, then the
# fotmob.com league-page HTML as the ground truth (its __NEXT_DATA__ carries
# the shape the site itself uses).
import json, subprocess, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
PACE = 1.8

def raw(url, tries=3):
    for i in range(tries):
        r = subprocess.run(["curl", "-s", "--compressed", "--max-time", "30", "-A", UA, "-w", "\n%{http_code}", url],
                           capture_output=True, text=True)
        body, _, code = r.stdout.rpartition("\n")
        if code == "200":
            return body
        time.sleep(2 * (i + 1))
    return None

def try_combo(lid, cc, season=None):
    url = f"https://www.fotmob.com/api/data/leagues?id={lid}&ccode3={cc}&lang=en"
    if season:
        url += f"&season={season}"
    body = raw(url)
    time.sleep(PACE)
    if not body:
        return f"{lid}/{cc}{'+s' if season else ''}: HTTP-fail"
    try:
        d = json.loads(body)
    except Exception:
        return f"{lid}/{cc}{'+s' if season else ''}: non-JSON len={len(body)}"
    if not isinstance(d, dict) or d.get("name") is None:
        return f"{lid}/{cc}{'+s' if season else ''}: null"
    det = d.get("details") or {}
    seas = det.get("seasons") or []
    return f"{lid}/{cc}{'+s' if season else ''}: NAME={d.get('name')!r} seasons={len(seas)}"

print("=== combo brute ===")
for lid in (130, 913550):
    for cc in ("USA", "MLS", "INT", "WOR", "AME", "NAM"):
        print(try_combo(lid, cc))
print("\n=== season=2026 combos ===")
print(try_combo(130, "USA", "2026"))
print(try_combo(913550, "USA", "2026"))

print("\n=== site HTML: /leagues/130/overview/major-league-soccer ===")
html = raw("https://www.fotmob.com/leagues/130/overview/major-league-soccer")
time.sleep(PACE)
if html:
    print("HTML len:", len(html))
    # find the api call or id in __NEXT_DATA__
    idx = html.find(" Major League Soccer")
    print("title-ish:", html[html.find("<title>"):html.find("</title>") + 8][:160])
    for marker in ('"id":130', '/leagues/130', '"parentLeagueId"', 'mls'):
        p = html.find(marker)
        print(f"marker {marker!r}: pos={p}", (html[max(0, p - 80):p + 120].replace('\n', ' ') if p >= 0 else ""))
else:
    print("HTML fetch failed")
