#!/usr/bin/env bash
# cycle388-probe.sh — bug-hunt cycle 388: the patrol through the surfaces
# the 386/387 patrols never reached. The 383 method (UNCURATED Latin scans
# on FA-DESIGNATED display fields) applied to the never-scanned corners:
#   P1  day-feed window WIDENED to offset -3..+3 (the 387 card's special
#       patrol note: does any family fire OUTSIDE the composer tables —
#       probed early by widening the window instead of waiting for UTC flip)
#   P2  player pages (/api/player/{id}) — fa-designated fields only
#   P3  coach surface (/api/team-coaches/{id} → /api/coach/{id})
#   P4  team sub-surfaces: team, squad, venue, trophies, transfers, rumours,
#       news, stats, top-players, fixtures, history, difficulty, coaches
#   P5  match sub-surfaces: match-h2h (+ team-last-lineup with TEAM id —
#       the probe lesson: this route takes the TEAM id, not the match id)
#   P6  league sub-surfaces: league-transfers, league-totw
#   P7  news + rss.xml + sitemap.xml metadata surfaces
#   P8  designed error surfaces re-check (400/JSON contract, notFound HTML)
# probe lessons applied: heredoc python rides a temp file; pipe-separated
# outputs everywhere (no JSON+tr double-parse); raw curl -w for status.
set -u
BASE=http://localhost:3000
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
stat() { curl -s -A "$UA" -o /tmp/c388_body.txt -w '%{http_code}' "$BASE$1"; }

# ---------------- P1: widened day-feed window -3..+3 ----------------
PY=/tmp/c388_probe.py
cat > "$PY" <<'EOF'
import json, sys, re
off = sys.argv[1]
d = json.load(sys.stdin)
gs = d.get('groups') or []
irn = set(); rawH = []; other = 0; total = 0
for g in gs:
    lgname = g.get('leagueName') or ''
    if (g.get('leagueFa') or '') == lgname and lgname:
        rawH.append((lgname, g.get('ccode') or ''))
    n_irn = set(); n_other = set()
    for m in (g.get('matches') or []):
        for k in ('home', 'away'):
            v = m.get(k) or {}
            n = v.get('name') or ''
            total += 1
            if n and (v.get('fa') or '') == n:
                if (g.get('ccode') or '') == 'IRN': n_irn.add(n)
                else: n_other.add(n)
    irn |= n_irn; other += len(n_other)
print(f"OFF={off} groups={len(gs)} teams={total} rawHeaders={len(rawH)} irnRaw={len(irn)} otherRawTeams={other}")
for n, c in rawH: print(f"HDR | {n} | {c}")
for n in sorted(irn): print(f"IRN | {n}")
EOF

echo "=== P1: day-feed window offset -3..+3 (widened) ==="
for O in -3 -2 -1 0 1 2 3; do
  api "/api/matches?offset=$O" | python3 "$PY" "$O"
done | tee /tmp/c388_window.txt
echo "--- P1b: header union with day-presence (families vs one-offs) ---"
grep '^HDR | ' /tmp/c388_window.txt | sed 's/^HDR | //' | sort | uniq -c | sort -rn | tee /tmp/c388_hdr.txt
echo "--- P1c: IRN raw union across the window ---"
grep '^IRN | ' /tmp/c388_window.txt | sed 's/^IRN | //' | sort -u | tee /tmp/c388_irn.txt

# ---------------- the FA-field uncurated Latin scanner ----------------
# walks any JSON; flags [A-Za-z]{3,} inside fa-designated string values.
PY2=/tmp/c388_scan.py
cat > "$PY2" <<'EOF'
import json, sys, re
FA_KEYS = {'fa', 'nameFa', 'leagueFa', 'teamFa', 'positionFa', 'venueFa', 'cityFa',
           'countryFa', 'competitionFa', 'stageFa', 'roundFa', 'noteFa', 'reasonFa',
           'typeFa', 'titleFa', 'labelFa', 'statusFa', 'shortFa', 'longFa', 'roleFa'}
hits = []
def walk(x, path):
    if isinstance(x, dict):
        for k, v in x.items(): walk(v, f"{path}.{k}")
    elif isinstance(x, list):
        for i, v in enumerate(x[:400]): walk(v, f"{path}[{i}]")
    elif isinstance(x, str):
        base = path.rsplit('.', 1)[-1].split('[')[0]
        if base in FA_KEYS:
            for m in re.findall(r"[A-Za-z]{3,}", x):
                hits.append((base, m, x[:80]))
try:
    d = json.load(sys.stdin)
except Exception as e:
    print(f"PARSE-FAIL | {e}"); sys.exit(0)
walk(d, '$')
seen = set()
for base, w, val in hits:
    key = (base, w, val)
    if key in seen: continue
    seen.add(key)
    print(f"LATIN | {base} | {w} | {val}")
if not hits: print("CLEAN")
EOF

echo
echo "=== P2: player surface (3 players from topscorers + 1 Iranian) ==="
for PID in 696679 81329 1090557; do
  echo "-- /api/player/$PID"
  api "/api/player/$PID" | python3 "$PY2"
done
echo
echo "=== P3: coach surface (id sourced from the match API — the team-coaches tenures carry NO id, probe lesson) ==="
CID=$(api "/api/match/5795503" | python3 -c "
import json, sys, re
m = re.search(r'\"coachId\":(\d+)', sys.stdin.read())
print(m.group(1) if m else '')
" 2>/dev/null)
echo "coach id: $CID"
if [ -n "$CID" ]; then api "/api/coach/$CID" | python3 "$PY2"; fi
echo
echo "=== P4: team sub-surfaces (teamId 10261 Newcastle) ==="
for EP in "team/10261" "team-squad/10261" "team-venue/10261" "team-trophies/10261" "team-transfers/10261" "team-rumours/10261" "team-news/10261" "team-stats/10261" "team-top-players/10261" "team-fixtures/10261" "team-history/10261" "team-difficulty/10261" "team-coaches/10261" "team-last-lineup/10261"; do
  echo "-- /api/$EP"
  api "/api/$EP" | python3 "$PY2"
done
echo
echo "=== P5: match sub-surfaces ==="
for EP in "match-h2h/5795503" "match/5795503"; do
  echo "-- /api/$EP"
  api "/api/$EP" | python3 "$PY2"
done
echo
echo "=== P6: league sub-surfaces (ENG PL 17) ==="
for EP in "league-transfers?leagueId=17&ccode=ENG" "league-totw?leagueId=17&ccode=ENG"; do
  echo "-- /api/$EP"
  api "/api/$EP" | python3 "$PY2"
done
echo
echo "=== P7: metadata surfaces ==="
echo "-- /api/news"
api "/api/news" | python3 "$PY2"
echo "-- /rss.xml Latin words in <title>/<description> of fa feeds"
curl -s -A "$UA" "$BASE/rss.xml" | python3 -c "
import sys, re
t = sys.stdin.read()
titles = re.findall(r'<title>(.*?)</title>', t, re.S) + re.findall(r'<description>(.*?)</description>', t, re.S)
bad = 0
for x in titles:
    x2 = re.sub(r'<!\[CDATA\[|\]\]>', '', x).strip()
    x2 = re.sub(r'&(apos|quot|amp|lt|gt|#39|#x27);', ' ', x2)
    ws = re.findall(r'[A-Za-z\u00C0-\u024F]{3,}', x2)
    if ws:
        bad += 1
        print(f'RSS-LATIN | {x2[:90]} | {ws[:6]}')
print(f'rss items={len(titles)} latin-flagged={bad}')
"
echo "-- /sitemap.xml + /robots.txt status"
stat "/sitemap.xml" | tr -d '\n'; echo " sitemap.xml"
stat "/robots.txt" | tr -d '\n'; echo " robots.txt"
echo
echo "=== P8: designed error surfaces ==="
echo "-- /api/team-last-lineup/0 (400 expected)"
stat "/api/team-last-lineup/0"; echo " body: $(head -c 120 /tmp/c388_body.txt)"
echo "-- /api/team-squad/notanumber (400 expected)"
stat "/api/team-squad/notanumber"; echo " body: $(head -c 120 /tmp/c388_body.txt)"
echo "-- /api/match-h2h/999999999 (upstream-missing class)"
stat "/api/match-h2h/999999999"; echo " body: $(head -c 120 /tmp/c388_body.txt)"
echo "-- /api/coach/0 (designed 400 JSON expected)"
stat "/api/coach/0"; echo " body: $(head -c 120 /tmp/c388_body.txt)"
echo "-- /api/team-last-lineup/5795503 (MATCH id into TEAM route — the probe-error class, 502 designed catch expected)"
stat "/api/team-last-lineup/5795503"; echo " body: $(head -c 120 /tmp/c388_body.txt)"
echo
echo "=== probe complete ==="
