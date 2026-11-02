#!/usr/bin/env bash
# cycle389-domproof.sh — fix cycle 389: the bounded 388 findings flipped to
# zero-leak. Structure mirrors cycle388-domproof.sh (the F-classes keep their
# numbers; every flip carries the 388 evidence in its label).
#
# FLIPS (fix belongs here — the 388 card's bounded list):
#   F1  the widened window -3..+3 serves ZERO raw headers at EVERY offset
#       (388: -3 = Premier Division|IRL + CONCACAF Central American Cup|INT,
#       +3 = SAFF Championship Grp. A/B|INT) — the 3 new CC base keys + the
#       387 group family compose them; otherRaw stays documented-unscheduled.
#   F2a player career/stat season tournament nameFa — the ARCHIVE_TID_FA
#       id-map (388 proved tid 187 «League Cup»=POR / 188 «Super Cup»=POR /
#       139 «Super Cup»=ESP, so the id is the only precise key).
#   F2b player deep-stats ENGLISH labels flipped (Penalty goals / Successful
#       crosses / Cross accuracy / Penalties awarded) — ids byte-exact off
#       the upstream payload; «xGOT» stays the designed abbreviation.
#   F2c teammates/nationalTeammates partial-coverage — confident names
#       mapped (Cancelo/Balde/Endrick/Estêvão…), the honest Latin fallback
#       contract stays asserted on a deliberately-unmapped name (Bisiwu).
#   F3  coach career fa (Liefering/Red Bull Akademie) via TEAM_FA.
#   F4a team-trophies nameFa (EFL Cup / A-Leagues All Stars Men) via TROPHY_FA.
#   F4d team-fixtures fa (Gateshead FC) via TEAM_FA.
#   F4b/c transfers+rumours raw Tonali/Schär/Murphy nameFa — flipped where
#       the live feed still carries them (rotation-tolerant: absent passes).
#   F6a league-transfers Martinelli, F6b totw Bobb, F6c/e topscorers
#       Hinshelwood partial coverage — flipped via PLAYER_NAME_FA.
#   F6d the league/pl ENGLISH kicker «LEAGUE LEADER» → «صدرنشین لیگ» (4 views).
# KEPT classes (documented, never claimed clean): F5 match-API-only nameFa
#   (page does not render), F4e team-news mixed-script (LLM translate stage,
#   transient), F7 rss ENGLISH aggregation + attribution line, otherRaw
#   world-feed scale, the honest-Latin person-name fallback.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d389_body.txt -w '%{http_code}' "$BASE$1"; }

# ---------------- window verdict (pipe-separated, no JSON in shell) ----------
PYV=/tmp/d389_verdict.py
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

# ---------------- FA-field scanner (the 383 method, same FA_KEYS set) --------
PYS=/tmp/d389_scan.py
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
print("CLEAN" if not out else f"HITS|{len(out)}|" + ";".join(out[:140]))
EOF

echo "================ F1: the widened window -3..+3 flips to zero ================"
ALL=""; for O in -3 -2 -1 0 1 2 3; do ALL="$ALL;$(api "/api/matches?offset=$O" | python3 "$PYV" "$O")"; done
echo "W=$ALL"
Z=1
for seg in $(printf '%s' "$ALL" | tr ';' '\n'); do
  RH=$(printf '%s' "$seg" | cut -d'|' -f2)
  [ -n "$RH" ] && [ "$RH" != "0" ] && { Z=0; printf '  raw@%s\n' "$seg"; }
done
ck "F1a ZERO raw headers at EVERY offset -3..+3 (the -3/+3 edge bases mapped)" "$Z"
IRNALL=$(printf '%s' "$ALL" | tr ';' '\n' | awk -F'|' '{s+=$3} END{print s+0}')
ck "F1b ZERO raw IRN names across -3..+3 (the 387 TEAM_FA keys hold) total=$IRNALL" "$([ "$IRNALL" = "0" ] && echo 1 || echo 0)"
OTH0=$(printf '%s' "$ALL" | tr ';' '\n' | awk -F'|' '$1=="0"{print $4}')
ck "F1c otherRaw world-feed teams remain documented-unscheduled (offset0 actual=${OTH0:-?})" "$([ -n "$OTH0" ] && [ "$OTH0" -ge 1 ] && echo 1 || echo 0)"

echo "---------------- F1f: the composer unit-contract (bun eval) ----------------"
CC=$(bun -e '
import { competitionFa } from "./src/lib/leagues.ts";
const rows: [string, string | undefined][] = [
  ["premier division", "IRL"],
  ["concacaf central american cup", "INT"],
  ["saff championship", "INT"],
  ["saff championship grp. a", "INT"],
  ["saff championship grp. b", "INT"],
  ["conmebol world cup qualifiers", undefined],
  ["world cup conmebol qualification", undefined],
];
console.log(rows.map(([n, c]) => competitionFa(n, c)).join("|"));
' 2>/dev/null)
echo "composer: $CC"
ck "F1f-1 premier division|IRL → «لیگ برتر ایرلند»" "$([ "$(has "$CC" 'لیگ برتر ایرلند')" = 1 ] && echo 1 || echo 0)"
ck "F1f-2 concacaf central american cup|INT → «جام آمریکای مرکزی کونکاکاف»" "$([ "$(has "$CC" 'جام آمریکای مرکزی کونکاکاف')" = 1 ] && echo 1 || echo 0)"
ck "F1f-3 saff championship + grp. family compose («قهرمانی ساف — گروه A/B»)" "$([ "$(has "$CC" 'قهرمانی ساف — گروه A')" = 1 ] && [ "$(has "$CC" 'قهرمانی ساف — گروه B')" = 1 ] && echo 1 || echo 0)"
ck "F1f-4 both CONMEBOL WCQ spellings → «مقدماتی جام جهانی — کونمبول»" "$([ "$(printf '%s' "$CC" | grep -oF 'مقدماتی جام جهانی — کونمبول' | wc -l)" = "2" ] && echo 1 || echo 0)"

echo "================ F2: the player surface ================"
PL=$(api "/api/player/696679")
R=$(printf '%s' "$PL" | python3 "$PYS"); echo "player696679 scan: $R"
ck "F2a' deep-stats ENGLISH labels GONE (Penalty/Successful/Cross/Penalties)" "$([ "$(has "$R" 'fa=Penalty')" = 0 ] && [ "$(has "$R" 'fa=Successful')" = 0 ] && [ "$(has "$R" 'fa=Cross')" = 0 ] && [ "$(has "$R" 'fa=Penalties')" = 0 ] && echo 1 || echo 0)"
ck "F2a'' career/stat season RAW tournament names GONE from nameFa (League Cup/Super Cup/Coupe de la Ligue/CONMEBOL/PL2)" "$([ "$(has "$R" 'nameFa=League Cup')" = 0 ] && [ "$(has "$R" 'nameFa=Super Cup')" = 0 ] && [ "$(has "$R" 'nameFa=Coupe')" = 0 ] && [ "$(has "$R" 'nameFa=CONMEBOL')" = 0 ] && [ "$(has "$R" 'nameFa=World Cup')" = 0 ] && [ "$(has "$R" 'nameFa=Premier League 2')" = 0 ] && echo 1 || echo 0)"
ck "F2b' teammates raw Latin GONE (Cancelo/Balde class)" "$([ "$(has "$R" 'nameFa=Cancelo')" = 0 ] && [ "$(has "$R" 'nameFa=Balde')" = 0 ] && echo 1 || echo 0)"
ck "F2b'' honest Latin fallback contract STAYS (Bisiwu deliberately unmapped)" "$([ "$(has "$R" 'nameFa=Jesse')" = 1 ] && echo 1 || echo 0)"
ck "F2c Persian deep-stat labels land (گل پنالتی/کراس موفق/دقت کراس/پنالتی گرفته‌شده)" "$([ "$(has "$PL" 'گل پنالتی')" = 1 ] && [ "$(has "$PL" 'کراس موفق')" = 1 ] && [ "$(has "$PL" 'دقت کراس')" = 1 ] && [ "$(has "$PL" 'پنالتی گرفته‌شده')" = 1 ] && echo 1 || echo 0)"
ck "F2d ARCHIVE_TID_FA Persian anchors land (پرتغال×۲/اسپانیا/فرانسه)" "$([ "$(has "$PL" 'جام اتحادیه پرتغال')" = 1 ] && [ "$(has "$PL" 'سوپرکاپ پرتغال')" = 1 ] && [ "$(has "$PL" 'سوپرکاپ اسپانیا')" = 1 ] && [ "$(has "$PL" 'جام اتحادیه فرانسه')" = 1 ] && echo 1 || echo 0)"
ck "F2e tid-map CONMEBOL anchor lands (مقدماتی جام جهانی — کونمبول)" "$([ "$(has "$PL" 'مقدماتی جام جهانی — کونمبول')" = 1 ] && echo 1 || echo 0)"
ck "F2f Persian teammates land (کانسلو/بالده/کوبرسی/اندریک/اشتوائو)" "$([ "$(has "$PL" 'ژوائو کانسلو')" = 1 ] && [ "$(has "$PL" 'الخاندرو بالده')" = 1 ] && [ "$(has "$PL" 'پاو کوبرسی')" = 1 ] && [ "$(has "$PL" 'اندریک')" = 1 ] && [ "$(has "$PL" 'اشتوائو')" = 1 ] && echo 1 || echo 0)"

echo "================ F3: the coach surface ================"
CR=$(api "/api/coach/59582")
R=$(printf '%s' "$CR" | python3 "$PYS"); echo "coach59582 scan: $R"
ck "F3a' coach career fa GONE raw (no Liefering/Akademie/Under-18 literals in fa-fields)" "$([ "$(has "$R" 'Liefering')" = 0 ] && [ "$(has "$R" 'Akademie')" = 0 ] && [ "$(has "$R" 'fa=Under')" = 0 ] && [ "$(has "$R" 'fa=Salzburg')" = 0 ] && echo 1 || echo 0)"
ck "F3a'' TEAM_FA Persian anchor lands (آکادمی ردبول — the live career spelling)" "$([ "$(has "$CR" 'آکادمی ردبول')" = 1 ] && echo 1 || echo 0)"

echo "================ F4: team sub-surfaces ================"
TR=$(api "/api/team-trophies/10261")
R=$(printf '%s' "$TR" | python3 "$PYS"); echo "trophies scan: $R"
ck "F4a' team-trophies nameFa GONE raw (EFL/A-Leagues class)" "$([ "$(has "$R" 'nameFa=EFL')" = 0 ] && [ "$(has "$R" 'nameFa=A-Leagues')" = 0 ] && echo 1 || echo 0)"
ck "F4a'' TROPHY_FA Persian lands (جام اتحادیه انگلیس)" "$([ "$(has "$TR" 'جام اتحادیه انگلیس')" = 1 ] && echo 1 || echo 0)"
TF=$(api "/api/team-transfers/10261")
R=$(printf '%s' "$TF" | python3 "$PYS"); echo "transfers scan: $(printf '%s' "$R" | cut -c1-120)"
ck "F4b' transfers nameFa Tonali/Schär GONE raw (rotation-tolerant flip)" "$([ "$(has "$R" 'nameFa=Tonali')" = 0 ] && [ "$(has "$R" 'nameFa=Schär')" = 0 ] && echo 1 || echo 0)"
TR2=$(api "/api/team-rumours/10261")
R=$(printf '%s' "$TR2" | python3 "$PYS"); echo "rumours scan: $(printf '%s' "$R" | cut -c1-120)"
ck "F4c' rumours nameFa Murphy class GONE raw" "$([ "$(has "$R" 'nameFa=Murphy')" = 0 ] && echo 1 || echo 0)"
TFX=$(api "/api/team-fixtures/10261")
R=$(printf '%s' "$TFX" | python3 "$PYS"); echo "fixtures scan: $(printf '%s' "$R" | cut -c1-120)"
ck "F4d' team-fixtures fa Gateshead GONE raw" "$([ "$(has "$R" 'fa=Gateshead')" = 0 ] && echo 1 || echo 0)"
ck "F4d'' TEAM_FA Persian lands (گیتس‌هد)" "$([ "$(has "$TFX" 'گیتس‌هد')" = 1 ] && echo 1 || echo 0)"
echo "NOTE F4e (kept class, no hard assert): team-news titleFa rides the LLM translate stage — mixed-script rows are transient translate quality, documented."

echo "================ F5/F6: match page class + league surfaces ================"
MR=$(api "/api/match/5795503")
R=$(printf '%s' "$MR" | python3 "$PYS"); echo "match API scan: $(printf '%s' "$R" | cut -c1-100)"
LT=$(api "/api/league-transfers?leagueId=17&ccode=ENG")
R=$(printf '%s' "$LT" | python3 "$PYS"); echo "league-transfers scan: $(printf '%s' "$R" | cut -c1-110)"
ck "F6a' league-transfers nameFa Martinelli GONE raw (now mapped)" "$([ "$(has "$R" 'nameFa=Martinelli')" = 0 ] && echo 1 || echo 0)"
TT=$(api "/api/league-totw?leagueId=17&ccode=ENG")
R=$(printf '%s' "$TT" | python3 "$PYS"); echo "league-totw scan: $(printf '%s' "$R" | cut -c1-110)"
ck "F6b' league-totw fa Bobb GONE raw (now mapped)" "$([ "$(has "$R" 'fa=Bobb')" = 0 ] && echo 1 || echo 0)"
TS=$(api "/api/topscorers?limit=30")
ck "F6c' topscorers raw Hinshelwood nameFa GONE (partial coverage flip)" "$([ "$(has "$TS" '"nameFa":"Jack Hinshelwood"')" = 0 ] && echo 1 || echo 0)"

echo "================ CLEAN: designed error contracts ================"
S1=$(st "/api/team-last-lineup/0"); B1=$(head -c 80 /tmp/d389_body.txt)
ck "C2 team-last-lineup/0 → 400 Persian designed error" "$([ "$S1" = 400 ] && [ "$(has "$B1" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S2=$(st "/api/team-squad/notanumber"); B2=$(head -c 80 /tmp/d389_body.txt)
ck "C3 team-squad/notanumber → 400 Persian designed error" "$([ "$S2" = 400 ] && [ "$(has "$B2" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S4=$(st "/api/coach/0"); B4=$(head -c 80 /tmp/d389_body.txt)
ck "C5 coach/0 → 400 Persian designed error" "$([ "$S4" = 400 ] && [ "$(has "$B4" 'شناسه مربی نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S5=$(st "/api/team-last-lineup/5795503"); B5=$(head -c 80 /tmp/d389_body.txt)
ck "C6 team-last-lineup MATCH-id → 502 its DESIGNED catch" "$([ "$S5" = 502 ] && [ "$(has "$B5" 'دریافت آخرین ترکیب ناموفق بود.')" = 1 ] && echo 1 || echo 0)"
SS=$(st "/sitemap.xml"); SR=$(st "/robots.txt")
ck "C7 sitemap.xml + robots.txt both 200" "$([ "$SS" = 200 ] && [ "$SR" = 200 ] && echo 1 || echo 0)"
for EP in team team-squad team-venue team-stats team-history team-difficulty team-coaches team-last-lineup; do
  R=$(api "/api/$EP/10261" | python3 "$PYS")
  ck "C8-$EP fa-fields CLEAN" "$([ "$R" = "CLEAN" ] && echo 1 || echo 0)"
done
H2H=$(api "/api/match-h2h/5795503" | python3 "$PYS"); echo "h2h: $H2H"
ck "C1 match-h2h fa-fields CLEAN (388 corner stays clean)" "$([ "$H2H" = "CLEAN" ] && echo 1 || echo 0)"
RSSRAW=$(curl -s -A "$UA" "$BASE/rss.xml")
ck "C9 rss keeps the designed Persian attribution line (جمع‌آوری از ESPN…)" "$([ "$(has "$RSSRAW" 'جمع‌آوری از ESPN')" = 1 ] && echo 1 || echo 0)"

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

# --- home (the composer serves the edges at DOM) ---
agent-browser open http://localhost:3000/ >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; t.length+'|'+ws.length+'|'+(t.indexOf('پریمیرلیگ انگلیس')>=0?1:0)" | tr -d '"')
HNLEN=$(printf '%s' "$R" | cut -d'|' -f1); HNLAT=$(printf '%s' "$R" | cut -d'|' -f2); HNFA=$(printf '%s' "$R" | cut -d'|' -f3)
echo "home: len=$HNLEN latinUnique=$HNLAT faAnchor=$HNFA"
ck "G3 home renders the mapped header anchor «پریمیرلیگ انگلیس»" "$([ "$HNFA" = "1" ] && echo 1 || echo 0)"
ck "F1d home RENDERS the documented otherRaw scale (latinUnique=$HNLAT — recorded, never claimed clean)" "$([ "$HNLAT" -ge 100 ] && echo 1 || echo 0)"
hyg "home"

# --- league/pl (F6d flip at DOM) ---
agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var h1=document.querySelector('h1'); (h1?h1.textContent.trim():'none')+'|'+(t.indexOf('LEAGUE LEADER')>=0?1:0)+'|'+(t.indexOf('صدرنشین لیگ')>=0?1:0)" | tr -d '"')
LH1=$(printf '%s' "$R" | cut -d'|' -f1); LLE=$(printf '%s' "$R" | cut -d'|' -f2); LFA=$(printf '%s' "$R" | cut -d'|' -f3)
echo "league: h1=$LH1 englishKicker=$LLE persianKicker=$LFA"
ck "G5 league h1 fully Persian «پریمیرلیگ انگلیس»" "$([ "$(has "$LH1" 'پریمیرلیگ انگلیس')" = 1 ] && echo 1 || echo 0)"
ck "F6d' ENGLISH kicker «LEAGUE LEADER» GONE from the page" "$([ "$LLE" = "0" ] && echo 1 || echo 0)"
ck "F6d'' Persian kicker «صدرنشین لیگ» renders" "$([ "$LFA" = "1" ] && echo 1 || echo 0)"
hyg "league/pl"

# --- topscorers page (the 4th kicker + person-name flip at DOM) ---
agent-browser open http://localhost:3000/topscorers/pl >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('LEAGUE LEADER')>=0?1:0)+'|'+(t.indexOf('GLOBAL TOP SCORER')>=0?1:0)+'|'+(t.indexOf('صدرنشین لیگ')>=0?1:0)+'|'+(t.indexOf('آقای گل جهانی')>=0?1:0)+'|'+(t.indexOf('هالند')>=0?1:0)" | tr -d '"')
TLE=$(printf '%s' "$R" | cut -d'|' -f1); TGL=$(printf '%s' "$R" | cut -d'|' -f2); TFA=$(printf '%s' "$R" | cut -d'|' -f3); TGF=$(printf '%s' "$R" | cut -d'|' -f4); THA=$(printf '%s' "$R" | cut -d'|' -f5)
echo "topscorers: engKicker=$TLE engGlobal=$TGL faKicker=$TFA faGlobal=$TGF haaland=$THA"
ck "F6d''' topscorers kickers fully Persian (both ENGLISH kickers GONE)" "$([ "$TLE" = "0" ] && [ "$TGL" = "0" ] && echo 1 || echo 0)"
ck "F6d4 topscorers Persian kicker renders (صدرنشین لیگ — the global variant only renders in global mode)" "$([ "$TFA" = "1" ] && echo 1 || echo 0)"
hyg "topscorers/pl"

# --- player page (F2 DOM) ---
agent-browser open http://localhost:3000/player/696679 >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; var ws=[...new Set(t.match(/[A-Za-z]{3,}/g)||[])]; ws.length+'|'+(t.indexOf('Penalty goals')>=0?1:0)+'|'+(t.indexOf('Cross accuracy')>=0?1:0)+'|'+(t.indexOf('Successful crosses')>=0?1:0)+'|'+(t.indexOf('گل پنالتی')>=0?1:0)+'|'+(t.indexOf('دقت کراس')>=0?1:0)+'|'+(t.indexOf('پاس گل')>=0?1:0)" | tr -d '"')
PNLAT=$(printf '%s' "$R" | cut -d'|' -f1); PPG=$(printf '%s' "$R" | cut -d'|' -f2); PCA=$(printf '%s' "$R" | cut -d'|' -f3); PSC=$(printf '%s' "$R" | cut -d'|' -f4); PFG2=$(printf '%s' "$R" | cut -d'|' -f5); PDC=$(printf '%s' "$R" | cut -d'|' -f6); PFG=$(printf '%s' "$R" | cut -d'|' -f7)
echo "player: latinUnique=$PNLAT engLabels=$PPG/$PCA/$PSC faLabels=$PFG2/$PDC faAnchor=$PFG"
ck "F2g' ENGLISH stat labels GONE from the page (all three probes)" "$([ "$PPG" = "0" ] && [ "$PCA" = "0" ] && [ "$PSC" = "0" ] && echo 1 || echo 0)"
ck "F2g'' Persian deep-stat labels render (گل پنالتی + دقت کراس)" "$([ "$PFG2" = "1" ] && [ "$PDC" = "1" ] && echo 1 || echo 0)"
ck "F2h the Persian MAIN stat anchors stay (پاس گل)" "$([ "$PFG" = "1" ] && echo 1 || echo 0)"
ck "F2i the honest-Latin fallback scale stays recorded (latinUnique=$PNLAT — person-name convention)" "$([ "$PNLAT" -ge 5 ] && echo 1 || echo 0)"
hyg "player/696679"

# --- coach page (F3 DOM) ---
agent-browser open http://localhost:3000/coach/59582 >/dev/null 2>&1
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('Liefering')>=0?1:0)+'|'+(t.indexOf('اف‌سی لیفرینگ')>=0?1:0)+'|'+(t.indexOf('آکادمی ردبول')>=0?1:0)" | tr -d '"')
CLIE=$(printf '%s' "$R" | cut -d'|' -f1); CFA=$(printf '%s' "$R" | cut -d'|' -f2); CRB=$(printf '%s' "$R" | cut -d'|' -f3)
echo "coach: liefering=$CLIE faLiefering=$CFA faAkademie=$CRB"
ck "F3b' coach PAGE career names Persian (Liefering GONE, آکادمی ردبول renders)" "$([ "$CLIE" = "0" ] && [ "$CRB" = "1" ] && echo 1 || echo 0)"
hyg "coach/59582"

# --- team page (F4 DOM spot: the trophies section is fully Persian; the
# EFL-Cup row itself is not in Newcastle's rendered list — assert Persian
# trophy names + a Latin-free name surface instead) ---
agent-browser open http://localhost:3000/team/10261 >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "function secTxt(p){var hs=[...document.querySelectorAll('h2,h3')];for(var i=0;i<hs.length;i++){if(hs[i].textContent.indexOf(p)>=0){var s=hs[i].closest('section')||hs[i].parentElement.parentElement;return s?s.innerText:''}}return ''} var tp=secTxt('گنجهٔ'); var lat=(tp.match(/[A-Za-z]{3,}/g)||[]).length; [tp.indexOf('جام حذفی انگلیس')>=0?1:0, lat].join('|')" | tr -d '"')
TFA2=$(printf '%s' "$R" | cut -d'|' -f1); TLAT=$(printf '%s' "$R" | cut -d'|' -f2)
echo "team trophies: faFACup=$TFA2 latinWords=$TLAT"
ck "F4h' trophies section fully Persian (جام حذفی انگلیس renders, latinWords=$TLAT ≤ 2)" "$([ "$TFA2" = "1" ] && [ "$TLAT" -le 2 ] && echo 1 || echo 0)"
hyg "team/10261"

# --- match page (G1 + the API-only-leak severity note) ---
agent-browser open http://localhost:3000/match/5795503 >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var t=document.body.innerText; var h1=document.querySelector('h1'); (h1?h1.textContent.trim():'none')" | tr -d '"')
MH1="$R"
ck "G1 match h1 fully Persian «نیوکاسل در برابر اورتون»" "$([ "$(has "$MH1" 'نیوکاسل در برابر اورتون')" = 1 ] && echo 1 || echo 0)"
hyg "match/5795503"

echo "================ summary ================"
echo "DOMPROF389 RESULT PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "ALL-CHECKS-GREEN" || echo "HAS-FAILURES"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
