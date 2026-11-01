#!/usr/bin/env python3
# cycle-336 feasibility probe — «بازیابی توپ در هر ۹۰» (Recoveries per 90 →
# ball_recovery.json). Live-verified with UA Chrome/124 + gzip handling:
# 1) PL current (season 36781) row count + top 3 verbatim
# 2) PL historical (2025/2026) via the payload's own season-scoped fetchAllUrl
# 3) LaLiga current (id 87) — the wide-file guard needs a second serving league
# Mirrors scripts/probe-335-passes.py (the 335 precedent).
import gzip, json, urllib.request

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"


def get(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    raw = urllib.request.urlopen(req, timeout=15).read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw.decode("utf-8", "replace"))


def probe_file(url: str, label: str) -> None:
    d = get(url)
    rows = d["TopLists"][0]["StatList"]
    print(f"{label}: {url.split('data.fotmob.com')[1]} rows={len(rows)}")
    for r in rows[:3]:
        print(f"   {r['Rank']:>3}  {r['ParticipantName']:24s} {r['TeamName']:20s} {r['StatValue']}")


def league_cat(fotmob_id: int, ccode3: str, season: str | None) -> str | None:
    q = f"https://www.fotmob.com/api/data/leagues?id={fotmob_id}&ccode3={ccode3}&lang=en"
    if season:
        q += f"&season={urllib.request.quote(season, safe='')}"
    for cat in get(q)["stats"]["players"]:
        if cat.get("header", "").lower() == "recoveries per 90":
            return cat.get("fetchAllUrl")
    return None


def main() -> None:
    # 1) PL current — direct file (36781 is the 2026/27 season id)
    probe_file("https://data.fotmob.com/stats/47/season/36781/ball_recovery.json", "PL current ")
    # 2) PL historical 2025/2026 — via the payload's own fetchAllUrl
    u = league_cat(47, "ENG", "2025/2026")
    print("PL 2025/26 recoveries fetchAllUrl:", u)
    if u:
        probe_file(u, "PL history ")
    # 3) LaLiga current — second serving league for the wide-file guard
    u = league_cat(87, "ESP", None)
    print("LaLiga recoveries fetchAllUrl:", u)
    if u:
        probe_file(u, "LaLiga      ")


if __name__ == "__main__":
    main()
