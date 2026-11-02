#!/usr/bin/env bash
# cycle388-domproof.sh — bug-hunt cycle 388: the patrol through the surfaces
# the 386/387 patrols never reached (the 383 method: UNCURATED Latin scans
# on FA-DESIGNATED fields + the DOM corners at 390x844).
#
# FINDINGS asserted at the CURRENT state (fix belongs to cycle-389):
#   F1  the 387 composer holds on -2..+2 (ZERO raw headers, ZERO raw IRN —
#       the 387 contract re-verified) but BREAKS at the widened edges:
#       offset -3 serves raw headers (Premier Division|IRL +
#       CONCACAF Central American Cup|INT at probe time), offset +3 serves
#       (SAFF Championship Grp. A/B|INT at probe time) — exactly the
#       family-outside-the-tables class the 387 card predicted for the
#       next-day rotation: the composer fires ONLY when the base resolves,
#       these bases have no keys. otherRaw stays documented-unscheduled.
#   F2  the player surface leaks: trophies nameFa = RAW competition names
#       (Coupe de la Ligue...), advanced-stats fa = ENGLISH labels
#       (Penalty goals / Successful crosses / Cross accuracy / Penalties
#       awarded / xGOT), related-player nameFa raw — ALL RENDERED on
#       /player/{id} (83 unique Latin words at probe time) while the MAIN
#       stat labels are Persian (گل / پاس گل) — partial-coverage class.
#   F3  the coach surface: career-team fa fields raw Latin (FC Liefering,
#       Red Bull Akademie...) — rendered on /coach/{id}.
#   F4  team sub-surfaces: trophies nameFa (EFL Cup, A-Leagues All Stars
#       Men), transfers/rumours nameFa (player names), fixtures fa
#       (Gateshead FC), team-news titleFa MIXED-SCRIPT («آرsenal») — and
#       the /team/{id} PAGE renders them (200 unique Latin words at probe
#       time: transfers 45, squad 69, club-news 70, coaches 19, lineup 16,
#       venue 5, trophies 6 per section).
#   F5  match API nameFa leaks raw player names (lineup/events) but the
#       /match/{id} PAGE does NOT render them (≤6 attribution words) —
#       API-only leak, severity note.
#   F6  league sub-surfaces: league-transfers nameFa (player names),
#       league-totw fa (player names), topscorers partial coverage
#       (رافینیا mapped vs Jack Hinshelwood raw in the same list class) —
#       rendered on /league/pl including the ENGLISH kicker «LEAGUE
#       LEADER» (a real UI-text leak) while h1 stays Persian.
#   F7  news/RSS: ~20/34 rss items Latin-flagged — classes: (a) fully
#       ENGLISH aggregated titles (ESPN/BBC/Sky sources), (b) «highlights»
#       untranslated inside Persian titles, (c) DELIBERATE: VAR + the
#       ESPN/BBC/Sky attribution line (the designed Persian collector
#       note), (d) apos/quot artifacts of the scanner itself (fixed).
# CLEAN corners: team core/squad/venue/stats/history/difficulty/coaches/
# last-lineup API fa-fields, match-h2h, the designed error contracts
# (400/400/404/400/502 Persian JSON), sitemap/robots, the Persian main
# stat labels on the player page, the Persian h1 anchors.
# probe lessons: team-last-lineup takes the TEAM id (502 = its designed
# catch); team-* routes are path-param [id] (query-param probes hit the
# framework HTML 404 — not an app bug); coach ids live in the match API
# (team-coaches tenures carry no id); NEVER assert a transient unlocated
# token (the «MATCH» observation); strip rss entities before word-scans;
# league-calendar serves ICS text (the 386 K2 class, again).
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d388_body.txt -w '%{http_code}' "$BASE$1"; }

# ---------------- helpers (temp files — the 386 subclass) ----------------
PYV=/tmp/d388_verdict.py
cat > "$PYV" <<'EOF'
import json, sys
off = sys.argv[1]
d = json.load(sys.stdin)
gs = d.get('groups') or []
rawH = []; irn = set(); other = set()
for g in gs:
    ln = g.get('leagueName') or ''
    if (g.get('leagueFa') or '') == ln and ln: rawH.append(f"{ln}|{g.get('ccode') or ''}")
    if (g.get('ccode') or '') == 'IRN':
        for m in (g.get('matches') or []):
            for k in ('home', 'away'):
                v = m.get(k) or {}
                if v.get('name') and (v.get('fa') or '') == v.get('name'):
                    irn.add(v.get('name'))
    else:
        for m in (g.get('matches') or []):
            for k in ('home', 'away'):
                v = m.get(k) or {}
                if v.get('name') and (v.get('fa') or '') == v.get('name'):
                    other.add(v.get('name'))
print(f"{off}|{len(rawH)}|{len(irn)}|{len(other)}")
for h in rawH: print(f"HDR {off} | {h}")
EOF

PYS=/tmp/d388_scan.py
cat > "$PYS" <<'EOF'
import json, sys, re
FA_KEYS = {'fa', 'nameFa', 'leagueFa', 'teamFa', 'positionFa', 'venueFa', 'cityFa',
           'countryFa', 'competitionFa', 'stageFa', 'roundFa', 'noteFa', 'reasonFa',
           'typeFa', 'titleFa', 'labelFa', 'statusFa', 'shortFa', 'longFa', 'roleFa'}
hits = []
def walk(x, path):
    if isinstance(x, dict):
        for k, v in x.items(): walk(v, f"{path}.{k}")
    elif isinstance(x, list):
        for i, v in enumerate(x[:500]): walk(v, f"{path}[{i}]")
    elif isinstance(x, str):
        base = path.rsplit('.', 1)[-1].split('[')[0]
        if base in FA_KEYS:
            for m in re.findall(r"[A-Za-z]{3,}", x):
                hits.append((base, m, x[:80]))
try:
    d = json.load(sys.stdin)
except Exception as e:
    print(f"PARSE-FAIL|{e}"); sys.exit(0)
walk(d, '$')
seen = set(); out = []
for base, w, val in hits:
    if (base, w, val) in seen: continue
    seen.add((base, w, val)); out.append(f"{base}={w}")
print("CLEAN" if not out else f"HITS|{len(out)}|" + ";".join(out[:120]))
EOF

echo "================ F1: the widened day-feed window -3..+3 ================"
W3=$(api "/api/matches?offset=-3" | python3 "$PYV" -3)
P3=$(api "/api/matches?offset=3" | python3 "$PYV" 3)
W2=""; for O in -2 -1 0 1 2; do W2="$W2;$(api "/api/matches?offset=$O" | python3 "$PYV" "$O")"; done
echo "W3=$W3"; echo "P3=$P3"; echo "W2=$W2"
H3=$(printf '%s' "$W3" | head -1 | cut -d'|' -f2)
P3H=$(printf '%s' "$P3" | head -1 | cut -d'|' -f2)
IRNALL=$(printf '%s%s%s' "$W3" "$P3" "$W2" | awk -F'|' '{s+=$3} END{print s}')
ck "F1a offset -3 serves raw headers (probe time: Premier Division|IRL + CONCACAF Central American Cup|INT) actual=$H3" "$([ "$H3" -ge 1 ] && echo 1 || echo 0)"
ck "F1b offset +3 serves raw headers (probe time: SAFF Championship Grp. A/B|INT) actual=$P3H" "$([ "$P3H" -ge 1 ] && echo 1 || echo 0)"
Z2=1; for seg in $(printf '%s' "$W2" | tr ';' '\n'); do
  RH=$(printf '%s' "$seg" | cut -d'|' -f2)
  [ -n "$RH" ] && [ "$RH" != "0" ] && Z2=0
done
ck "F1c offsets -2..+2 serve ZERO raw headers (the 387 contract re-verified)" "$Z2"
ck "F1d ZERO raw IRN names across -3..+3 (the 387 TEAM_FA keys hold) total=$IRNALL" "$([ "$IRNALL" = "0" ] && echo 1 || echo 0)"
OTH0=$(printf '%s' "$W2" | tr ';' '\n' | awk -F'|' '$1=="0"{print $4}')
ck "F1e otherRaw world-feed teams remain documented-unscheduled (offset0 actual=${OTH0:-?})" "$([ -n "$OTH0" ] && [ "$OTH0" -ge 1 ] && echo 1 || echo 0)"

echo "================ F2: the player surface ================"
PL=$(api "/api/player/696679")
R=$(printf '%s' "$PL" | python3 "$PYS"); echo "player696679: $R"
ck "F2a player trophies nameFa leaks raw competition names (Coupe de la Ligue class)" "$([ "$(has "$R" 'nameFa=Coupe')" = 1 ] && echo 1 || echo 0)"
ck "F2b player advanced-stats fa = ENGLISH labels (xGOT/Penalty goals/Successful crosses/Cross accuracy/Penalties awarded)" "$([ "$(has "$R" 'fa=xGOT')" = 1 ] && [ "$(has "$R" 'fa=Penalty')" = 1 ] && [ "$(has "$R" 'fa=Successful')" = 1 ] && [ "$(has "$R" 'fa=Cross')" = 1 ] && [ "$(has "$R" 'fa=Penalties')" = 1 ] && echo 1 || echo 0)"
ck "F2c player related-players nameFa raw Latin (Cancelo/Balde class)" "$([ "$(has "$R" 'nameFa=Cancelo')" = 1 ] && echo 1 || echo 0)"

echo "================ F3: the coach surface ================"
CR=$(api "/api/coach/59582" | python3 "$PYS"); echo "coach59582: $CR"
ck "F3a coach career fa fields raw Latin (Liefering/Red Bull Akademie class)" "$([ "$(has "$CR" 'Liefering')" = 1 ] && echo 1 || echo 0)"

echo "================ F4: team sub-surfaces ================"
TR=$(api "/api/team-trophies/10261" | python3 "$PYS"); echo "trophies: $TR"
ck "F4a team-trophies nameFa leaks competition names (EFL Cup/A-Leagues class)" "$([ "$(has "$TR" 'nameFa=EFL')" = 1 ] && echo 1 || echo 0)"
TF=$(api "/api/team-transfers/10261" | python3 "$PYS"); echo "transfers: $(printf '%s' "$TF" | cut -c1-90)"
ck "F4b team-transfers nameFa leaks raw player names (Tonali/Schar class)" "$([ "$(has "$TF" 'nameFa=Tonali')" = 1 ] && echo 1 || echo 0)"
TR2=$(api "/api/team-rumours/10261" | python3 "$PYS"); echo "rumours: $TR2"
ck "F4c team-rumours nameFa leaks raw player names (Murphy/Morton class)" "$([ "$(has "$TR2" 'nameFa=Murphy')" = 1 ] && echo 1 || echo 0)"
TFX=$(api "/api/team-fixtures/10261" | python3 "$PYS"); echo "fixtures: $TFX"
ck "F4d team-fixtures fa leaks raw opponent names (Gateshead FC class)" "$([ "$(has "$TFX" 'fa=Gateshead')" = 1 ] && echo 1 || echo 0)"
TN=$(api "/api/team-news/10261" | python3 -c "
import json, sys, re
d = json.load(sys.stdin)
items = d.get('news') or d.get('items') or []
mixed = []
def txt(x):
    if isinstance(x, dict):
        for k in ('titleFa', 'title', 'nameFa'):
            v = x.get(k)
            if isinstance(v, str): return v
    return ''
def collect(x):
    if isinstance(x, list):
        for i in x: collect(i)
    elif isinstance(x, dict):
        t = txt(x)
        if t and re.search(r'[\u0600-\u06FF]', t) and re.search(r'[A-Za-z]{4,}', t): mixed.append(t)
        for v in x.values(): collect(v)
collect(d)
print('MIXED|' + ' ;; '.join(mixed[:4]) if mixed else 'NOMIXED')
"); echo "team-news: $TN"
ck "F4e team-news titleFa MIXED-SCRIPT class (Persian + Latin4 in one title, probe time: «آرsenal»)" "$([ "$(has "$TN" 'MIXED')" = 1 ] && echo 1 || echo 0)"

echo "================ F5: match sub-surface ================"
MR=$(api "/api/match/5795503" | python3 "$PYS"); echo "match5795503: $(printf '%s' "$MR" | cut -c1-100)"
ck "F5a match API nameFa leaks raw player names (Branthwaite/Dewsbury-Hall class)" "$([ "$(has "$MR" 'nameFa=Branthwaite')" = 1 ] && echo 1 || echo 0)"
H2H=$(api "/api/match-h2h/5795503" | python3 "$PYS"); echo "h2h: $H2H"
ck "C1 match-h2h fa-fields CLEAN" "$([ "$H2H" = "CLEAN" ] && echo 1 || echo 0)"

echo "================ F6: league sub-surfaces + topscorers ================"
LT=$(api "/api/league-transfers?leagueId=17&ccode=ENG" | python3 "$PYS"); echo "league-transfers: $(printf '%s' "$LT" | cut -c1-90)"
ck "F6a league-transfers nameFa leaks raw player names (Martinelli/Mudryk class)" "$([ "$(has "$LT" 'nameFa=Martinelli')" = 1 ] && echo 1 || echo 0)"
TT=$(api "/api/league-totw?leagueId=17&ccode=ENG" | python3 "$PYS"); echo "league-totw: $TT"
ck "F6b league-totw fa leaks raw player names (Oscar Bobb class)" "$([ "$(has "$TT" 'fa=Bobb')" = 1 ] && echo 1 || echo 0)"
TS=$(api "/api/topscorers?limit=3")
ck "F6c topscorers partial coverage: رافینیا mapped anchor" "$([ "$(has "$TS" 'رافینیا')" = 1 ] && echo 1 || echo 0)"

echo "================ F7: news/RSS metadata ================"
RS=$(curl -s -A "$UA" "$BASE/rss.xml" | python3 -c "
import sys, re
t = sys.stdin.read()
titles = re.findall(r'<title>(.*?)</title>', t, re.S) + re.findall(r'<description>(.*?)</description>', t, re.S)
en = 0; hl = 0
for x in titles:
    x2 = re.sub(r'<!\[CDATA\[|\]\]>', '', x).strip()
    x2 = re.sub(r'&(apos|quot|amp|lt|gt|#39|#x27);', ' ', x2)
    if re.search(r'[\u0600-\u06FF]', x2): continue
    ws = re.findall(r'[A-Za-z]{3,}', x2)
    if len(ws) >= 5: en += 1
    if 'highlights' in x2 and re.search(r'[\u0600-\u06FF]', x2): hl += 1
print(f'{en}|{hl}|{len(titles)}')
")
EN=$(printf '%s' "$RS" | cut -d'|' -f1); HL=$(printf '%s' "$RS" | cut -d'|' -f2); TI=$(printf '%s' "$RS" | cut -d'|' -f3)
echo "rss: english-titles=$EN highlights-in-fa=$HL items=$TI"
ck "F7a rss serves fully-ENGLISH aggregated titles (probe time 17/34; actual=$EN of $TI)" "$([ "$EN" -ge 5 ] && echo 1 || echo 0)"
# F7b «highlights» inside Persian titles — PROBE-TIME observation, NOT hard-asserted:
# the class ROTATES with the news window (the 386 date-dependent lesson, again).
# Probe time evidence (2 exact titles): «بازی اتلتیک بیلبائو مقابل رئال سوسیداد -
# highlights بازی» + «ببینید: highlights فالکیرک مقابل سلتیک در اسپورت اسین»;
# the domproof run minutes later found 0 — the feed window had rotated. Documented
# in the card as a probe-time finding for the 389 fix to address at the class level.
echo "NOTE F7b (probe-time class, not asserted): highlights-in-Persian-title observed=$HL at this run (probe time 2)"
RSSRAW=$(curl -s -A "$UA" "$BASE/rss.xml")
ck "F7c2 rss keeps the designed Persian attribution line (جمع‌آوری از ESPN…)" "$([ "$(has "$RSSRAW" 'جمع‌آوری از ESPN')" = 1 ] && echo 1 || echo 0)"
ck "F7c3 rss keeps the VAR-in-Persian-media convention item" "$([ "$(has "$RSSRAW" 'آیا VAR')" = 1 ] && echo 1 || echo 0)"

echo "================ CLEAN: designed error contracts ================"
S1=$(st "/api/team-last-lineup/0"); B1=$(head -c 80 /tmp/d388_body.txt)
ck "C2 team-last-lineup/0 → 400 Persian designed error" "$([ "$S1" = 400 ] && [ "$(has "$B1" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S2=$(st "/api/team-squad/notanumber"); B2=$(head -c 80 /tmp/d388_body.txt)
ck "C3 team-squad/notanumber → 400 Persian designed error" "$([ "$S2" = 400 ] && [ "$(has "$B2" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S3=$(st "/api/match-h2h/999999999"); B3=$(head -c 80 /tmp/d388_body.txt)
ck "C4 match-h2h/999999999 → 404 Persian designed error" "$([ "$S3" = 404 ] && [ "$(has "$B3" 'تیم‌های مسابقه یافت نشد.')" = 1 ] && echo 1 || echo 0)"
S4=$(st "/api/coach/0"); B4=$(head -c 80 /tmp/d388_body.txt)
ck "C5 coach/0 → 400 Persian designed error" "$([ "$S4" = 400 ] && [ "$(has "$B4" 'شناسه مربی نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S5=$(st "/api/team-last-lineup/5795503"); B5=$(head -c 80 /tmp/d388_body.txt)
ck "C6 team-last-lineup MATCH-id → 502 its DESIGNED catch (probe-lesson re-verified)" "$([ "$S5" = 502 ] && [ "$(has "$B5" 'دریافت آخرین ترکیب ناموفق بود.')" = 1 ] && echo 1 || echo 0)"
SS=$(st "/sitemap.xml"); SR=$(st "/robots.txt")
ck "C7 sitemap.xml + robots.txt both 200" "$([ "$SS" = 200 ] && [ "$SR" = 200 ] && echo 1 || echo 0)"

echo "================ CLEAN: the unscanned-but-clean API corners ================"
for EP in team team-squad team-venue team-stats team-history team-difficulty team-coaches team-last-lineup; do
  R=$(api "/api/$EP/10261" | python3 "$PYS")
  ck "C8-$EP fa-fields CLEAN" "$([ "$R" = "CLEAN" ] && echo 1 || echo 0)"
done

echo "================ DOM: 390x844 patrol + evidence ================"
agent-browser set viewport 390 844 >/dev/null 2>&1

hyg() { local ERR CON SW CW
  sleep 3
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "$1 page-errors=0" "$([ -z "$ERR" ] && echo 1 || echo 0)"
  ck "$1 console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "$1 scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "390" ] && [ "$CW" = "390" ] && echo 1 || echo 0)"
}

# --- home (the 387 day-feed at DOM + otherRaw rendered scale) ---
agent-browser open http://localhost:3000/ >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; t.length+'|'+ws.length+'|'+(t.indexOf('پریمیرلیگ انگلیس')>=0?1:0)" | tr -d '"')
HNLEN=$(printf '%s' "$R" | cut -d'|' -f1); HNLAT=$(printf '%s' "$R" | cut -d'|' -f2); HNFA=$(printf '%s' "$R" | cut -d'|' -f3)
echo "home: len=$HNLEN latinUnique=$HNLAT faAnchor=$HNFA"
ck "G3 home renders the mapped header anchor «پریمیرلیگ انگلیس»" "$([ "$HNFA" = "1" ] && echo 1 || echo 0)"
ck "F1f home RENDERS the documented otherRaw scale (latinUnique=$HNLAT — recorded, never claimed clean)" "$([ "$HNLAT" -ge 100 ] && echo 1 || echo 0)"
hyg "home"

# --- league/pl (F6 DOM + G5) ---
agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; var h1=document.querySelector('h1'); (h1?h1.textContent.trim():'none')+'|'+ws.length+'|'+(t.indexOf('LEAGUE LEADER')>=0?1:0)+'|'+(t.indexOf('Hinshelwood')>=0?1:0)" | tr -d '"')
LH1=$(printf '%s' "$R" | cut -d'|' -f1); LLAT=$(printf '%s' "$R" | cut -d'|' -f2); LLDR=$(printf '%s' "$R" | cut -d'|' -f3); LHIN=$(printf '%s' "$R" | cut -d'|' -f4)
echo "league: h1=$LH1 latinUnique=$LLAT leagueLeader=$LLDR hinshelwood=$LHIN"
ck "G5 league h1 fully Persian «پریمیرلیگ انگلیس»" "$([ "$(has "$LH1" 'پریمیرلیگ انگلیس')" = 1 ] && echo 1 || echo 0)"
ck "F6d league page renders the ENGLISH kicker «LEAGUE LEADER» (real UI-text leak)" "$([ "$LLDR" = "1" ] && echo 1 || echo 0)"
ck "F6e league آقای گل renders raw player names (Hinshelwood class)" "$([ "$LHIN" = "1" ] && echo 1 || echo 0)"
hyg "league/pl"

# --- team page per-section evidence ---
agent-browser open http://localhost:3000/team/10261 >/dev/null 2>&1
R=$(agent-browser eval "
function secLat(p){var hs=[...document.querySelectorAll('h2,h3')];for(var i=0;i<hs.length;i++){if(hs[i].textContent.indexOf(p)>=0){var s=hs[i].closest('section')||hs[i].parentElement.parentElement;var t=s?s.innerText:'';return (t.match(/[A-Za-z]{3,}/g)||[]).length}}return -1}
[secLat('بازار انتقال'),secLat('شایعات'),secLat('گنجهٔ افتخارات'),secLat('تاریخچهٔ نیمکت'),secLat('ورزشگاه خانه'),secLat('ترکیب تیم'),secLat('آخرین ترکیب'),secLat('اخبار باشگاه')].join('|')" | tr -d '"')
TRN=$(printf '%s' "$R" | cut -d'|' -f1); RUM=$(printf '%s' "$R" | cut -d'|' -f2); TRP=$(printf '%s' "$R" | cut -d'|' -f3); COA=$(printf '%s' "$R" | cut -d'|' -f4); VEN=$(printf '%s' "$R" | cut -d'|' -f5); SQD=$(printf '%s' "$R" | cut -d'|' -f6); LIN=$(printf '%s' "$R" | cut -d'|' -f7); CNW=$(printf '%s' "$R" | cut -d'|' -f8)
echo "team sections: transfers=$TRN rumours=$RUM trophies=$TRP coaches=$COA venue=$VEN squad=$SQD lineup=$LIN clubnews=$CNW"
ck "F4f team PAGE renders raw transfer names (بازار انتقال‌ها=$TRN)" "$([ "$TRN" -ge 10 ] && echo 1 || echo 0)"
ck "F4g team PAGE renders raw rumour names (شایعات=$RUM)" "$([ "$RUM" -ge 5 ] && echo 1 || echo 0)"
ck "F4h team PAGE renders raw trophy names (گنجهٔ افتخارات=$TRP)" "$([ "$TRP" -ge 2 ] && echo 1 || echo 0)"
ck "F4i team PAGE renders raw coach/tenure names (تاریخچهٔ نیمکت=$COA)" "$([ "$COA" -ge 5 ] && echo 1 || echo 0)"
ck "F4j team PAGE renders raw venue names (ورزشگاه خانه=$VEN — St James Park class)" "$([ "$VEN" -ge 2 ] && echo 1 || echo 0)"
ck "F4k team PAGE renders raw squad names (ترکیب تیم=$SQD)" "$([ "$SQD" -ge 30 ] && echo 1 || echo 0)"
ck "F4l team PAGE renders raw lineup names (آخرین ترکیب=$LIN)" "$([ "$LIN" -ge 5 ] && echo 1 || echo 0)"
ck "F4m team PAGE renders ENGLISH club-news titles (اخبار باشگاه=$CNW)" "$([ "$CNW" -ge 20 ] && echo 1 || echo 0)"
hyg "team/10261"

# --- player page (F2 DOM + Persian anchors) ---
agent-browser open http://localhost:3000/player/696679 >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; ws.length+'|'+(t.indexOf('Penalty goals')>=0?1:0)+'|'+(t.indexOf('Cross accuracy')>=0?1:0)+'|'+(t.indexOf('پاس گل')>=0?1:0)+'|'+(t.indexOf('ترکیب اصلی')>=0?1:0)+'|'+(t.indexOf('رافینیا')>=0?1:0)" | tr -d '"')
PNLAT=$(printf '%s' "$R" | cut -d'|' -f1); PPG=$(printf '%s' "$R" | cut -d'|' -f2); PCA=$(printf '%s' "$R" | cut -d'|' -f3); PFG=$(printf '%s' "$R" | cut -d'|' -f4); PTM=$(printf '%s' "$R" | cut -d'|' -f5); PNM=$(printf '%s' "$R" | cut -d'|' -f6)
echo "player: latinUnique=$PNLAT penaltyGoals=$PPG crossAcc=$PCA faGol=$PFG faTarkib=$PTM nameFa=$PNM"
ck "F2d player PAGE renders the ENGLISH stat labels (Penalty goals + Cross accuracy)" "$([ "$PPG" = "1" ] && [ "$PCA" = "1" ] && echo 1 || echo 0)"
ck "F2e player PAGE keeps the Persian MAIN stat anchors (گل/پاس گل/ترکیب اصلی)" "$([ "$PFG" = "1" ] && [ "$PTM" = "1" ] && echo 1 || echo 0)"
ck "F2f player PAGE nameFa anchor «رافینیا» (partial-coverage contrast)" "$([ "$PNM" = "1" ] && echo 1 || echo 0)"
ck "F2g player PAGE renders the leak scale (latinUnique=$PNLAT, probe time 83)" "$([ "$PNLAT" -ge 30 ] && echo 1 || echo 0)"
hyg "player/696679"

# --- coach page (F3 DOM) ---
agent-browser open http://localhost:3000/coach/59582 >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; ws.length+'|'+(t.indexOf('Liefering')>=0?1:0)" | tr -d '"')
CLAT=$(printf '%s' "$R" | cut -d'|' -f1); CLIE=$(printf '%s' "$R" | cut -d'|' -f2)
echo "coach: latinUnique=$CLAT liefering=$CLIE"
ck "F3b coach PAGE renders raw career-team names (Liefering class, latinUnique=$CLAT)" "$([ "$CLIE" = "1" ] && echo 1 || echo 0)"
hyg "coach/59582"

# --- match page (G1 + the API-only-leak severity note) ---
agent-browser open http://localhost:3000/match/5795503 >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; var h1=document.querySelector('h1'); (h1?h1.textContent.trim():'none')+'|'+ws.length+'|'+(t.indexOf('Branthwaite')>=0?1:0)" | tr -d '"')
MH1=$(printf '%s' "$R" | cut -d'|' -f1); MLAT=$(printf '%s' "$R" | cut -d'|' -f2); MBR=$(printf '%s' "$R" | cut -d'|' -f3)
echo "match: h1=$MH1 latinUnique=$MLAT branthwaite=$MBR"
ck "G1 match h1 fully Persian «نیوکاسل در برابر اورتون — پریمیرلیگ انگلیس»" "$([ "$(has "$MH1" 'نیوکاسل در برابر اورتون')" = 1 ] && echo 1 || echo 0)"
ck "F5b match PAGE does NOT render the API nameFa leak (Branthwaite absent; latinUnique=$MLAT ≤8 — API-only leak)" "$([ "$MBR" = "0" ] && [ "$MLAT" -le 8 ] && echo 1 || echo 0)"
hyg "match/5795503"

# --- news page (F7 DOM) ---
agent-browser open http://localhost:3000/news >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; ws.length" | tr -d '"')
NLAT=$(printf '%s' "$R" | tail -1)
echo "news: latinUnique=$NLAT"
ck "F7d news PAGE renders the ENGLISH-title scale (latinUnique=$NLAT, probe time 213)" "$([ "$NLAT" -ge 50 ] && echo 1 || echo 0)"
hyg "news"

echo "================ summary ================"
echo "DOMPROF388 RESULT PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "ALL-CHECKS-GREEN" || echo "HAS-FAILURES"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
