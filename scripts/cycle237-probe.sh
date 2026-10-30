#!/usr/bin/env bash
# cycle-237 probe: the update candidate = the remaining category-list
# surfaces, TEAM-SIDE LEVELS FIRST (the 236 card's probed candidate).
# As-found, UA Chrome/124, zero app changes: walk the live league feed
# (www.fotmob.com/api/data/leagues) and dump EVERY fetchAllUrl node —
# player categories AND team-side categories (the league stats Teams
# sub-tab) wherever they hide in the raw tree — then byte-count each
# target file and show its first rank-1 row.
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
OUT=/tmp/c237-probe
rm -rf "$OUT"; mkdir -p "$OUT"
# the six domestic globalMerge leagues + persiangulf + mas (the honest-absence pair)
declare -A LG=( [laliga]=87 [pl]=47 [seriea]=94 [bundesliga]=35 [ligue1]=61 [ucl]=42 [persiangulf]=82 [mas]=102 )
for key in laliga pl seriea bundesliga ligue1 ucl persiangulf mas; do
  id=${LG[$key]}
  curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=${id}&ccode3=IRN&lang=en" -o "$OUT/$key.json" &
done
wait
python3 - "$OUT" <<'PY'
import json, sys, os
out = sys.argv[1]
found = {}
for key in ["laliga","pl","seriea","bundesliga","ligue1","ucl","persiangulf","mas"]:
    p = os.path.join(out, key + ".json")
    if not os.path.exists(p) or os.path.getsize(p) < 50:
        print(f"{key}: FEED-MISSING"); continue
    raw = json.load(open(p))
    hits = []
    def walk(node, path):
        if isinstance(node, dict):
            if "fetchAllUrl" in node and isinstance(node.get("fetchAllUrl"), str):
                hits.append((path, node))
            for k, v in node.items():
                walk(v, f"{path}.{k}")
        elif isinstance(node, list):
            for i, v in enumerate(node[:40]):
                walk(v, f"{path}[{i}]")
    walk(raw, "$")
    slugs = []
    for path, node in hits:
        url = node["fetchAllUrl"]
        slug = url.rsplit("/", 1)[-1]
        # which parent section? (players vs teams)
        section = "TEAMS" if ".topTeams" in path or ".teams" in path.lower() or "team" in slug.lower() else "players"
        slugs.append((slug, section, url, node.get("statName") or node.get("name") or ""))
    uniq = {}
    for slug, section, url, name in slugs:
        uniq[slug] = (section, url, name)
    print(f"{key}: feed OK, {len(hits)} fetchAllUrl nodes")
    for slug, (section, url, name) in sorted(uniq.items()):
        print(f"  [{section}] {slug}  name={name!r}")
        found.setdefault(slug, url)
# byte-count + first row of every distinct team-side URL
print("\n--- deep-file spot checks (team-side first) ---")
for slug, url in sorted(found.items()):
    if "team" not in slug.lower() and "team" not in url.lower():
        continue
    import urllib.request, gzip, io
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36", "Accept-Encoding": "gzip"})
    try:
        blob = urllib.request.urlopen(req, timeout=15).read()
        if blob[:2] == b"\x1f\x8b": blob = gzip.decompress(blob)
        data = json.loads(blob.decode("utf-8", "replace"))
        rows = data.get(" TopList") or data.get("TopList") or []
        first = rows[0] if rows else None
        print(f"TEAMFILE {slug}: bytes={len(blob)} rows={len(rows)} first={json.dumps(first, ensure_ascii=False)[:220]}")
    except Exception as e:
        print(f"TEAMFILE {slug}: ERR {type(e).__name__} {e}")
PY
