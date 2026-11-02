#!/usr/bin/env bash
# cycle389-probe.sh — fix cycle 389: the live-probe method behind the maps.
# NOT an assertion suite (that is cycle389-domproof.sh) — this is the
# byte-exactness tool: every key added in cycle-389 was read off these
# outputs, never retyped from memory (the F2-378 guard).
#
#   S1  upstream playerData (id=696679): the deep-stat (localizedTitleId,
#       title) pairs that fell to the raw-English fallback + every
#       (leagueId/leagueName) pair for the archive tournaments + the tid →
#       country CONTEXT (team + season of each seasonEntry) — the proof that
#       tid 187 «League Cup» = POR (Sporting/Vitória) while the SAME literal
#       on other rows = EFL Cup, so only the id-keyed map is precise.
#   S2  the served player API: full JSON paths of every raw fa-designated
#       field (deepStats labels / careerSeasons+statSeasons tournaments /
#       teammates / nationalTeammates).
#   S3  the coach payload: the exact career fa strings (the 388 card's
#       «Red Bull Akademie» rides inside the fuller
#       «Red Bull Akademie Under 18 (FC Salzburg Under 18)» spelling).
#   S4  the widened day-feed edges -3/+3: the raw headers live (the CC base
#       keys: premier division|IRL + concacaf central american cup|INT +
#       saff championship|INT — the «Grp. A/B» suffixes ride the 387 family).
set -u
BASE=http://localhost:3000
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

echo "=== S1: upstream playerData — missing stat ids + archive tids + context ==="
curl -s -A "$UA" "https://www.fotmob.com/api/data/playerData?id=696679" > /tmp/c389_up.json
python3 - <<'EOF'
import json
d = json.load(open('/tmp/c389_up.json'))
want = {'xgot','penalty goals','successful crosses','cross accuracy','penalties awarded'}
print("-- deep-stat ids falling to the raw-title fallback:")
for g in (d.get('firstSeasonStats') or {}).get('statsSection', {}).get('items') or []:
    for it in (g.get('items') or []):
        if str(it.get('title') or '').lower() in want:
            print(f"   id={it.get('localizedTitleId')!r} title={it.get('title')!r} group={g.get('title')!r}")
want2 = {'coupe de la ligue','super cup','league cup','conmebol world cup qualifiers',
         'world cup conmebol qualification','premier league 2 div 2'}
print("-- archive tournament (tid, name, team-context):")
ci = d.get('careerHistory', {}).get('careerItems', {})
for kind in ('senior', 'youth', 'national team'):
    for se in (ci.get(kind) or {}).get('seasonEntries') or []:
        for t in se.get('tournamentStats') or []:
            if str(t.get('leagueName') or '').lower() in want2:
                print(f"   tid={t.get('leagueId')} {t.get('leagueName')!r} team={se.get('team')!r} season={se.get('seasonName')!r}")
for ss in d.get('statSeasons') or []:
    for t in ss.get('tournaments') or []:
        if str(t.get('name') or '').lower() in want2:
            print(f"   tid={t.get('tournamentId')} {t.get('name')!r} (statSeasons {ss.get('seasonName')!r})")
EOF

echo "=== S2: served player API — raw fa-designated field paths ==="
curl -s -A "$UA" "$BASE/api/player/696679" > /tmp/c389_api.json
python3 - <<'EOF'
import json, re
d = json.load(open('/tmp/c389_api.json'))
FA = {'fa','nameFa','leagueFa','teamFa'}
def walk(x, p):
    if isinstance(x, dict):
        for k, v in x.items(): walk(v, f"{p}.{k}")
    elif isinstance(x, list):
        for i, v in enumerate(x[:300]): walk(v, f"{p}[{i}]")
    elif isinstance(x, str):
        if p.rsplit('.',1)[-1] in FA and re.search(r'[A-Za-z]{3,}', x):
            print(f"   {p} = {x[:60]}")
walk(d, '$')
EOF

echo "=== S3: coach career fa strings (exact upstream spellings) ==="
curl -s -A "$UA" "$BASE/api/coach/59582" | python3 -c "
import json, sys, re
d = json.load(sys.stdin)
def walk(x):
    if isinstance(x, dict):
        for k, v in x.items():
            if k == 'fa' and isinstance(v, str) and re.search(r'[A-Za-z]{3,}', v): print('   raw fa =', v)
            else: walk(v)
    elif isinstance(x, list):
        for v in x: walk(v)
walk(d)"
echo "   (empty = no raw career fa values served)"

echo "=== S4: the widened day-feed edges ==="
for O in -3 3; do
  curl -s -A "$UA" "$BASE/api/matches?offset=$O" | python3 -c "
import json, sys
d = json.load(sys.stdin)
raw = []
for g in d.get('groups') or []:
    ln = g.get('leagueName') or ''
    if (g.get('leagueFa') or '') == ln and ln: raw.append(f\"{ln}|{g.get('ccode') or ''}\")
print(f'   offset=$O source={d.get(\"source\")} rawHeaders={len(raw)}' + (' -> ' + '; '.join(raw) if raw else ''))"
done

echo "=== probe complete ==="
