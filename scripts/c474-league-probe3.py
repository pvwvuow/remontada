# -*- coding: utf-8 -*-
# cycle-474: find the REAL Liga Profesional (ARG) league PAGE id —
# search-suggest probe first, then known-id candidates with identity checks
import json, urllib.request, sys

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8", "replace")

# --- search suggest (two historical shapes) ---
for u in ["https://www.fotmob.com/api/searchapi/suggest?term=liga%20profesional",
          "https://www.fotmob.com/api/data/search?term=liga%20profesional"]:
    try:
        raw = get(u)
        d = json.loads(raw)
        s = json.dumps(d, ensure_ascii=False)
        print("SUGGEST OK", u.split("api/")[1][:30], "->", s[:400])
        # extract league candidates
        def walk(o):
            if isinstance(o, dict):
                if "leagueId" in o or (o.get("type") == "league"):
                    yield o
                for v in o.values():
                    yield from walk(v)
            elif isinstance(o, list):
                for v in o:
                    yield from walk(v)
        for hit in list(walk(d))[:8]:
            print("   hit:", {k: hit.get(k) for k in ("name", "leagueId", "id", "type", "ccode", "country") if k in hit})
        break
    except Exception as e:
        print("SUGGEST FAIL", u.split("api/")[1][:30], type(e).__name__, e)

# --- known-id candidates, identity-verified ---
print("\n== candidate page probes:")
for lid in [107, 109, 249, 250, 103]:
    try:
        d = json.loads(get(f"https://www.fotmob.com/api/leagues?id={lid}"))
        if not d or d.get("pageError") or not d.get("table"):
            print(f"  {lid}: pageError/page null")
            continue
        cc = (d.get("ccdata") or {}).get("ccode3")
        nm = d.get("name")
        print(f"  {lid}: name={nm!r} cc={cc} matchesARG={cc=='ARG' or 'argent' in str(nm).lower()}")
        if cc == "ARG":
            print(f"  >>> ARG LEAGUE FOUND: id={lid} name={nm!r}")
            t = d["table"][0] if isinstance(d["table"], list) else d["table"]
            tables = t.get("tables", [])
            print("      table blocks:", len(tables), "| composite:", t.get("composite"))
            for tb in tables[:2]:
                rows = tb.get("allMatches", [])
                print("      block:", tb.get("groupName"), "rows:", len(rows))
                for r in rows[:3]:
                    print("        ", r.get("team", {}).get("name"), "| rank:", r.get("rank"), "| pts:", r.get("pts"))
            sals = d.get("allAvailableSeasons") or []
            plain = [s["name"] for s in sals if "-" not in str(s.get("name"))]
            slash = [s["name"] for s in sals if "-" in str(s.get("name"))]
            print("      seasons:", len(sals), "plain:", len(plain), "slash:", len(slash), "sample:", [s.get("name") for s in sals[:5]])
            print("      playoff:", "PRESENT" if d.get("playoff") else "absent",
                  "| titleHistory:", "PRESENT" if d.get("titleHistory") else "absent",
                  "| transfers:", "REAL" if (d.get("transfers") or {}).get("data") else "absent",
                  "| stats:", "present" if d.get("stats") else "absent",
                  "| selectedSeason:", d.get("selectedSeason"),
                  "| color:", d.get("leagueColor"),
                  "| allMatches:", len((d.get("fixtures") or {}).get("allMatches") or []))
            break
    except Exception as e:
        print(f"  {lid}: {type(e).__name__} {e}")
