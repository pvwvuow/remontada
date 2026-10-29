#!/usr/bin/env python3
# cycle-160 Swiss deep probe — the integration truth pack:
# top-20 scorer window (name+team, byte-exact), title seasons newest/oldest,
# ESPN slug live probe (sui.1), byte-exact club names from the table feed.
import json, gzip, urllib.request, time

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

def get(url, timeout=25):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))

d = get("https://www.fotmob.com/api/data/leagues?id=69&ccode3=SUI&lang=en")

# byte-exact club names
allrows = (((d.get("table") or [{}])[0].get("data") or {}).get("table") or {}).get("all") or []
print("CLUBS:", json.dumps([r.get("name") for r in allrows], ensure_ascii=False))

# top scorer file
url = ""
for cat in (d.get("stats") or {}).get("players") or []:
    if isinstance(cat, dict) and "top scorer" in str(cat.get("header", "")).lower():
        url = cat.get("fetchAllUrl") or ""
        print("FETCH-ALL-URL:", url)
        break
if url:
    if url.startswith("//"): url = "https:" + url
    g = get(url)
    tl = g.get("TopLists") or []
    rl = (tl[0].get("StatList") if tl else []) or []
    print("scorer rows:", len(rl))
    for i, p in enumerate(rl[:20]):
        # raw keys of first row to learn the shape
        if i == 0:
            print("ROW0-KEYS:", list(p.keys()))
        team = ""
        pt = p.get("participation") or {}
        if isinstance(pt, dict):
            team = (pt.get("team") or {}).get("name") or ""
        print(f"{i+1}. {p.get('name')} | team={team} | stat={p.get('statValue')} | keys-fallback: teamName={p.get('teamName')}")

# titles
seasons = d.get("seasons") or []
if seasons:
    titles = seasons[0].get("titles") or []
    print("\nTITLE seasons:", len(titles))
    for t in titles[:3]:
        print("  newest:", json.dumps(t, ensure_ascii=False)[:220])
    if len(titles) > 3:
        print("  oldest:", json.dumps(titles[-1], ensure_ascii=False)[:220])

# transfers shape
tr = d.get("transfers") or {}
trd = tr.get("data") if isinstance(tr, dict) else None
trn = (trd.get("transfers") or []) if isinstance(trd, dict) else []
print("\ntransfers:", len(trn), "| sample:", json.dumps(trn[0], ensure_ascii=False)[:150] if trn else "-")

# ESPN slug live probe
import urllib.error
for slug in ("sui.1", "swiss.1", "switzerland.1"):
    try:
        req = urllib.request.Request(f"https://site.api.espn.com/apis/site/v2/sports/soccer/{slug}/scoreboard", headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=15) as r:
            code = r.status
        print(f"ESPN {slug} -> {code}")
        break
    except urllib.error.HTTPError as e:
        print(f"ESPN {slug} -> HTTP {e.code}")
    except Exception as e:
        print(f"ESPN {slug} -> ERR {type(e).__name__}")
    time.sleep(0.5)

# playoff
po = d.get("playoff", "absent")
print("playoff:", "null" if po is None else ("absent" if po == "absent" else f"obj({len(po) if isinstance(po, (list, dict)) else '?'})"))

# archived 2023/2024 top-scorer block check (the qatar/eredivisie historical-honesty probe)
try:
    d24 = get("https://www.fotmob.com/api/data/leagues?id=69&ccode3=SUI&lang=en&season=2023%2F2024")
    has_ts = any("top scorer" in str(c.get("header", "")).lower() for c in (d24.get("stats") or {}).get("players") or [] if isinstance(c, dict))
    rows24 = len((((d24.get("table") or [{}])[0].get("data") or {}).get("table") or {}).get("all") or [])
    print(f"archived 2023/2024: rows={rows24} top-scorer-block={has_ts}")
except Exception as e:
    print("archived probe ERR", type(e).__name__)
