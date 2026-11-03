#!/usr/bin/env bash
# cycle438-patrol.sh — bug-hunt harness (built cycle 438): the standing patrol.
# The 413/418/423/427/428/432 precedent: findings ONLY (fixes belong to the
# next cycle). Zero src/ changes expected → but the full official chain still
# runs (build + official start) so the patrol proves the CURRENT commit deploys.
# cycle-440 re-anchor (the loud-pool rule — the batch that moves the pool
# re-anchors in the open): B4 1973 → 1943 (harvest batch 7, the documented −30
# Scotland tranche, zero distinct drift) + B10 NEW: four batch-7 witnesses
# Persian in the live ±7 feed — the patrol now runs 46 checks.
# cycle-441 re-anchor (the loud-pool rule): B4 1943 → 1925 (harvest batch 8,
# the documented −18 Peru Liga 1 tranche, zero distinct drift) + B11 NEW:
# four batch-8 witnesses Persian in the live ±7 feed — the patrol now runs
# 47 checks.
# cycle-442 re-anchor (the loud-pool rule): B4 1925 → 1909 (harvest batch 9,
# the documented −16 Romania Cup Grp. A-D + Liga II + Superliga tranche, zero
# distinct drift) + B12 NEW: four batch-9 witnesses Persian in the live ±7
# feed — the patrol now runs 48 checks.
# cycle-445 re-anchor (the loud-pool rule): B4 1909 → 1890 (harvest batch 10,
# the documented −11 Norway 1. Divisjon/Cup/Eliteserien tranche MINUS 8
# long-tail names the live window itself re-rendered between the two census
# reads — the count≥3 segment moved ZERO between the two reads, the isolated
# proof the −8 is upstream window drift, not a mapping fault) + B13 NEW: four
# batch-10 witnesses Persian in the live ±7 feed — the patrol now runs 51
# checks.
# cycle-446 re-anchor (the loud-pool rule): B4 1890 → 1877 (harvest batch 11,
# the documented −13 Colombia Primera A + Primera B tranche, EXACTLY −13 with
# zero long-tail drift between the two reads) + B14 NEW: four batch-11
# witnesses Persian in the live ±7 feed — the patrol now runs 52 checks.
# cycle-447 re-anchor (the loud-pool rule): B4 1877 → 1865 (harvest batch 12,
# the documented −12 Russia Premier League + Cup Grp. A-D tranche, EXACTLY
# −12 with zero long-tail drift between the reads) + B15 NEW: four batch-12
# witnesses Persian in the live ±7 feed — the patrol now runs 53 checks.
# cycle-448 promotion (bug-hunt, the C13 precedent): the 444 skip-link
# LANDING hold (post-jump main-top >= header-bottom with the hash kept —
# the scroll-margin clamp geometry) leaves its cycle-specific probe
# (scripts/c444_probe.sh + cycle444-domproof.sh B4) and becomes the C14
# permanent patrol check on home + one inner route (the two header-height
# regimes) — the last unheld link of the 439→443→444 chain. Zero product
# bugs this cycle; the landing itself re-proved live under a REAL click
# (home mt=146=hb, inner mt=68=hb, scrollY=0, hash kept). Harness lesson:
# the bash pipeline DISPLAY mangled the probe's a[href= into aref= and
# nearly triggered a phantom repair of a CORRECT file — the Read tool is
# the byte authority. The patrol now runs 54 checks.
# cycle-449 re-anchor (the loud-pool rule, the FIRST fix-cycle re-anchor):
# B4 1865 → 1864 (the byte-drift fix: the live-literal «al jeel» key added
# beside the dead hyphenated cycle-140 capture — EXACTLY −1, Al Jeel leaves
# the raw pool; the c449 fold-probe proved it the only such drift in the
# whole 1865-name pool) + B16 NEW: the fix witness «الجیل» Persian in the
# live ±7 feed — the patrol now runs 55 checks.
# cycle-450 re-anchor (the loud-pool rule): B4 1864 → 1852 (harvest batch
# 13: ALL 12 count-3 single-country names of the GUATEMALA tranche — the
# 447/448 rotation lines' own prediction, the window delivered; exactly
# −12 with zero distinct drift between the census reads) + B17 NEW: four
# batch-13 witnesses Persian in the live ±7 feed — the patrol now runs 56
# checks.
# cycle-451 re-anchor (the loud-pool rule): B4 1852 → 1841 (harvest batch
# 14: ALL 11 count-3 single-country names of the CYPRUS tranche — the
# honest CYP/THA tie broke on anchor quality per the 447 precedent, TWO
# direct club articles vs ZERO; exactly −11 with zero distinct drift
# between the census reads) + B18 NEW: four batch-14 witnesses Persian in
# the live ±7 feed — the patrol now runs 57 checks.
# cycle-452 re-anchor (the loud-pool rule): B4 1841 → 1830 (harvest batch
# 15: ALL 11 count-3 single-country names of the THAILAND tranche — the
# honest 451 runner-up now that CYP is mapped, League Cup Play-offs;
# exactly −11 with zero distinct drift between the census reads) + B19 NEW:
# four batch-15 witnesses Persian in the live ±7 feed — the patrol now runs
# 58 checks.
# cycle-443 promotion (bug-hunt, the C12 precedent): the 439 skip-link hold
# leaves its cycle-specific domproof (scripts/cycle439-domproof.sh A1/A2/
# B1–B3) and becomes TWO permanent patrol checks — C13a: the served body's
# FIRST anchor is the skip link (href=#main-content, «پرش به محتوا», parked
# via -translate-y-16 + revealed via focus:translate-y-0) and home carries
# exactly one <main id="main-content">; C13b: live at 390×844 — the skip link
# is the body's first focusable element, parked above the viewport at rest
# (rect.bottom ≤ 0) and revealed on programmatic focus (rect.top ≥ 0,
# non-zero height). If a future layout change demotes the link below another
# focusable, drops the anchor pairing or the park transform, the patrol fails
# BEFORE the keyboard a11y path silently disappears — the patrol now runs 50
# checks.
# Evolves the 432/433 harness (scripts/cycle432-patrol.sh) with ONE delta:
#   C12 NEW (a/b/c): the 434 mount-gate hold ASSERTED as a permanent patrol
#      check — until now it lived only in the cycle-specific domproof. a: the
#      served shell strip is time-invariant (15 chips / exactly 1 «امروز» /
#      zero Persian digits / zero weekday words — curl, no JS); b: hydration
#      fills all 15 day slots + the today chip (index 7) is the pressed one;
#      c: a fresh home load shows zero console errors/asserts and zero page
#      errors — the direct React #418 probe that fired 3/3 before the 434 fix.
#      If any future build regresses the gate (or a new SSR'd time-dependent
#      tree appears), the patrol fails here BEFORE midnight can re-break it.
# Kept identical to 432/433 (as re-anchored by 435/436/437):
#   1. D-section console/page-error parsers FIXED — the 427 file had a syntax
#      flaw (`len( for m in ...)`) that returned NA on EVERY page and was
#      silently accepted, AND the would-be key was wrong anyway: the live
#      probe (cycle-432 prep) shows agent-browser messages carry `type`,
#      not `level`. Both fixed; verified with a deliberate console.error probe.
#   2. B4 pool expectation: the documented census constant — 2256 (pre-430)
#      → 2160 (post-431) → 2108 (post-432 batch 3, the documented −49) →
#      2053 (post-435 batch 4, the documented −55, zero distinct drift) →
#      2013 (post-436 batch 5, the documented −40, zero distinct drift) →
#      1973 (post-437 batch 6, the documented −40, zero distinct drift) →
#      1943 (post-440 batch 7, the documented −30, zero distinct drift) →
#      1925 (post-441 batch 8, the documented −18, zero distinct drift) →
#      1909 (post-442 batch 9, the documented −16, zero distinct drift) →
#      1779 (post-460 batch 19: the −10 Poland tranche PLUS the −9 net
#      live-window churn between the pre- and post-patch reads — the
#      count-3 segment HELD at 193: −10 mapped (POL) offset by +10
#      window-side entrants (MEX 2→10 the headline, a live Liga MX batch,
#      the 445-class phenomenon) and −19 net long-tail (<3) exits; the
#      patch delta isolated at EXACTLY −10 by the segment arithmetic:
#      without the patch the post read would be 1789/203) ←
#      1788 (arithmetic expectation 1798−10, superseded by the actual
#      1779 read above) ←
#      1798 (post-457 batch 18: the −10 Ukraine tranche EXACTLY −10 in
#      the count-3 segment (203→193, the isolated proof) + 1 long-tail
#      window drift, the 445/455 precedent) ←
#      1809 (post-456 batch 17: the −10 Montenegro tranche EXACTLY −10 in
#      the count-3 segment (213→203, the isolated proof), zero long-tail
#      drift this time) ←
#      1819 (post-455 batch 16: the −10 Austria tranche EXACTLY −10 in the
#      count-3 segment (223→213, the isolated proof) + 1 long-tail window
#      drift, the 445 precedent) ←
#      1830 (post-452 batch 15: the −11 Thailand tranche, exactly −11) ←
#      1841 (post-451 batch 14: the −11 Cyprus tranche, exactly −11) ←
#      1852 (post-450 batch 13: the −12 Guatemala tranche, exactly −12) ←
#      1864 (post-449 the byte-drift fix: the −1 Al Jeel live-literal key,
#      exactly −1) ←
#      1865 (post-447 batch 12: the −12 Russia tranche, exactly −12) ←
#      1877 (post-446 batch 11: the −13 Colombia tranche, exactly −13) ←
#      1890 (post-445 batch 10: the −11 Norway tranche MINUS 8 long-tail
#      window revisions between the reads; the count≥3 segment moved ZERO —
#      the isolated proof the −8 is upstream drift, not a mapping fault) — as a
#      ±25 DRIFT BAND around it (the loud-pool rule: the constant moves WITH
#      the census, never silently — the cycle that moves the pool re-anchors
#      it here in the open; window-edge drift stays single-digit, a mapping
#      fault or a new batch moves it by ±40+ and MUST re-anchor again).
#   3. B5 NEW: the 429 trophy hold ASSERTED (player 696679: zero raw-fallback
#      leagueFa rows in the whole payload + trophies[4] byte-exact Persian).
#   4. B6 NEW: harvest batch-1 (cycle-430) and batch-2 (cycle-431) witnesses
#      present as Persian fa values in the live ±7 day feed.
# cycle-454 promotion (the Fix cycle, the C12/C13/C14 precedent + the pinned
# 453 order): the batch-15 block hold leaves the cycle-specific domproof A3
# and becomes a permanent patrol check — B20: the leagues.ts batch-15 region
# must stay byte-identical (key AND value, 11 pairs) to what commit 886f6ff
# shipped. This is the git-truth anchor that replaced the one-shot
# /tmp/c452-verified.json dependency (finding #453: the PRE byte-proof dies
# with the recycle AND with the batch's own success — the raw literals leave
# the live feed). If a future cycle legitimately edits a batch-15 value, it
# re-anchors B20 in the open (the B4 loud-pool precedent). The patrol now
# runs 59 checks.
# cycle-456/457 batch-17/18 note: the batch-15 block region read stays
# bounded to the next cycle marker (the cycle-455/456/457 blocks now
# follow it — the naive marker→}; scan would still read the later blocks'
# tails and break the hold; the lookahead guard holds).
# cycle-457 re-anchor (the loud-pool rule, the harvest-batch delta): B4
# 1809 → 1798 (harvest batch 18, the documented −10 Ukraine tranche
# EXACTLY −10 in the count-3 segment 203→193 — the isolated proof — + 1
# long-tail window drift, the 445/455 precedent) + B23 NEW: four batch-18
# witnesses Persian in the live ±7 feed. The patrol now runs 62 checks.
# cycle-460 re-anchor (the loud-pool rule, the 445 precedent): B4
# 1798 → 1779 (harvest batch 19 — the −10 Poland tranche, the 446-pick
# rule: POL 10/30 the largest pool, PAN/HON 9/27 below, the 447 tie-break
# not invoked — pre-patch census read EXACTLY 1798 = the documented 457
# post-census, ZERO distinct drift for the NINTH consecutive cycle; the
# post-patch read 1779 = the −10 batch + the −9 net live-window churn
# between the reads, the patch delta isolated at EXACTLY −10 by the
# segment arithmetic) + B24 NEW: four batch-19 witnesses Persian in the
# live ±7 feed. The patrol now runs 63 checks.
# cycle-461 re-anchor (the loud-pool rule, the 445 precedent): B4
# 1779 → 1771 (harvest batch 20 — the −8 MEX tranche AFTER the 435 skip
# line: MEX 10/30 heads the pool but two of the ten are (W) women's sides
# (Club León (W) / Santos Laguna (W)) skipped at pick time, no (W)-level
# convention yet — pre-patch census read EXACTLY 1779 = the documented 460
# post-census, ZERO distinct drift for the TENTH consecutive cycle; the
# post-patch read 1771 = EXACTLY the −8 batch with ZERO window churn this
# cycle (rows 3264→3240 = exactly the −24 mapped rows), the count-3
# segment 193→185 = EXACTLY −8, the isolated proof) + B25 NEW: four
# batch-20 witnesses Persian in the live ±7 feed. The patrol now runs 64
# checks.
# cycle-462 re-anchor (the loud-pool rule, the 445 precedent): B4
# 1771 → 1754 (harvest batch 21 — the −19 ARGENTINA tranche, the live Liga
# Profesional + Copa Argentina wave, the 446-pick rule: ARG 19/62 topped
# the pool with PAN/HON 9/27 held below, ZERO (W) sides so the 435 skip
# never fired — the pre-patch census read 1773 = the documented 461
# post-census 1771 + 2 net live-window churn (the promotion-vs-new-entrant
# split not separately observable — documented as read); the post-patch
# read 1754 = EXACTLY the −19 batch with ZERO concurrent window churn this
# cycle (rows 3272→3210 = exactly the −62 mapped rows, the count-3 segment
# 204→190 = EXACTLY −14, the isolated proof) + B26 NEW: four batch-21
# witnesses Persian in the live ±7 feed. The patrol now runs 65 checks.
# cycle-465 re-anchor (the loud-pool rule, the 445 precedent): B4
# 1754 → 1745 (harvest batch 22 — the −9 PANAMA tranche, the live LPF
# Apertura wave, the 447 tie-break WINNER over the HON 9/27 half of the
# documented tie: anchor quality five direct club articles vs two+city —
# the 447 RUS=GUA precedent — ZERO (W) sides so the 435 skip never
# fired; the pre-patch census read 1754 = EXACTLY the documented 462
# post-census with ZERO drift, rows 3210; the post-patch read 1745 =
# EXACTLY the −9 batch) + B27 NEW: four batch-22 witnesses Persian in
# the live ±7 feed. The patrol now runs 66 checks.
# cycle-466 re-anchor (the loud-pool rule, the 445 precedent): B4
# 1745 → 1736 (harvest batch 23 — the −9 HONDURAS tranche, the live
# Liga Nacional Apertura wave, the UNBROKEN half of the PAN/HON 9/27
# tie after the 465 tie-break; the FIRST ZERO-ANCHOR batch — the live
# c466 probe found no direct fa.wiki club article under any spelling,
# all 9 honest reads; the pre-patch census read 1745 = EXACTLY the
# documented 465 post-census with ZERO drift, rows 3183; the post-patch
# read 1736 = EXACTLY the −9 batch) + B28 NEW: four batch-23 witnesses
# Persian in the live ±7 feed. The patrol now runs 67 checks.
# cycle-467 re-anchor (the loud-pool rule, the 445 precedent): B4
# 1736 → 1728 (harvest batch 24 — the −8 ESTONIA tranche, the live
# Meistriliiga wave, the WINNER of the five-way CZE/EST/ISR/SWE/USA 8/24
# tie by the 447 anchor-quality rule: four direct club articles vs 3/3/2/0;
# the pre-patch census read 1736 = EXACTLY the documented 466 post-census
# with ZERO drift, rows 3156; the post-patch read 1728 = EXACTLY the −8
# batch) + B29 NEW: four batch-24 witnesses Persian in the live ±7 feed.
# The patrol now runs 68 checks.
# A API inventory, B 426 surface + harvest holds (B4 anchor 1728, B7–B29
# batch-4..24 witnesses + the 886f6ff byte-identity), C1–C14 the
# interaction holds, D the 16-page DOM sweep at 390×844, E the gates.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1 :: ${3:-}"; fi; }
SECT="${SECTIONS:-A B C D E}"
has() { case " $SECT " in *" $1 "*) return 0;; *) return 1;; esac; }
AB="agent-browser"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s --max-time 30 -A "$UA" "$BASE$1"; }
code() { curl -s -o /dev/null -w '%{http_code}' -A "$UA" "$BASE$1" --max-time 25; }

if has A; then
echo "================ A: the API inventory ================"
JSON_EPS=(
"/api/matches?offset=0" "/api/standings?league=pl" "/api/topscorers" "/api/topscorers/pl"
"/api/news" "/api/transfers" "/api/transfers?minFee=1000000" "/api/search?q=%D8%B1%D8%A6%D8%A7%D9%84"
"/api/league-bracket?league=ucl" "/api/league-fixtures?league=pl"
"/api/league-fixtures-all?league=pl" "/api/league-titles?league=pl" "/api/league-totw?league=pl"
"/api/league-transfers?league=pl" "/api/team/8456" "/api/team-squad/8456" "/api/team-fixtures/8456"
"/api/team-coaches/8456" "/api/team-difficulty/8456" "/api/team-history/8456"
"/api/team-last-lineup/8456" "/api/team-news/8456" "/api/team-rumours/8456" "/api/team-stats/8456"
"/api/team-top-players/8456" "/api/team-transfers/8456" "/api/team-trophies/8456" "/api/team-venue/8456"
"/api/match/5795503" "/api/match-h2h/5795503" "/api/player/696679" "/api/coach/78626"
)
BAD=0; N=0
for EP in "${JSON_EPS[@]}"; do
  N=$((N+1))
  OUT=$(api "$EP")
  OKP=$(printf '%s' "$OUT" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(0 if isinstance(d,dict) and d.get('ok') is False else 1)
except Exception:
    print(0)
" 2>/dev/null)
  C=$(code "$EP")
  if [ "$OKP" != "1" ] || [ "$C" != "200" ]; then BAD=$((BAD+1)); echo "  !! $EP → http=$C ok=$OKP"; fi
done
ck "A1 all $N JSON endpoints healthy (bad=$BAD)" "$([ "$BAD" = "0" ] && echo 1 || echo 0)"
TSC=$(api "/api/topscorers?league=pl")
ck "A1b topscorers ?league= designed-400 with path hint" "$(printf '%s' "$TSC" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(1 if d.get('ok') is False and 'topscorers' in str(d.get('error','')) else 0)
except Exception: print(0)")"
DC=$(api "/api/day-calendar?date=2026-02-30")
ck "A1c day-calendar impossible-date designed-400 (the 299 contract)" "$([ "$(code "/api/day-calendar?date=2026-02-30")" = "400" ] && echo 1 || echo 0)"
FC=$(api "/api/favorites-calendar?ids=")
ck "A1d favorites-calendar empty-ids designed-400 (the 425 contract)" "$(printf '%s' "$FC" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(1 if d.get('ok') is False and 'هیچ تیمی' in str(d.get('error','')) else 0)
except Exception: print(0)")"
CT=$(code "/api/league-calendar?league=pl&season=2025%2F2026"); ck "A2 league ICS text/calendar" "$([ "$CT" = "200" ] && api "/api/league-calendar?league=pl&season=2025%2F2026" | head -c 40 | grep -q "BEGIN:VCALENDAR" && echo 1 || echo 0)"
CT=$(code "/api/team-calendar/8456");           ck "A3 team ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/match-calendar/5795503");       ck "A4 match ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/day-calendar?date=$(TZ=Asia/Tehran date +%F)"); ck "A5 day ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/favorites-calendar?ids=8456");  ck "A6 favorites ICS 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/og/pl");  ck "A7 og league png" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/api/og/person/696679"); ck "A7b og person png" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/rss.xml");    ck "A8 rss 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/sitemap.xml"); ck "A9 sitemap 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/robots.txt");  ck "A10 robots 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
CT=$(code "/manifest.webmanifest"); ck "A11 manifest 200" "$([ "$CT" = "200" ] && echo 1 || echo 0)"
fi

if has B; then
echo "================ B: the 426 surface + the harvest holds ================"
RES=$(python3 - "$BASE" <<'PY'
import json, re, subprocess, sys, time
base = sys.argv[1]
PERSIAN = re.compile(r"[\u0600-\u06FF]")
def get(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)
leaks, team_rows, team_names, fa_set = {}, 0, set(), set()
for o in range(-7, 8):
    d = get(f"{base}/api/matches?offset={o}")
    for g in d.get("groups", []):
        fa = g.get("leagueFa") or ""
        if fa and not PERSIAN.search(fa):
            leaks[(g.get("leagueName"), g.get("leagueId"))] = fa
        for m in g.get("matches", []):
            for side in ("home", "away"):
                t = m.get(side) or {}
                tfa = t.get("fa") or ""
                if tfa:
                    fa_set.add(tfa)
                    if not PERSIAN.search(tfa):
                        team_rows += 1
                        team_names.add(tfa)
    time.sleep(0.15)
kn = get(f"{base}/api/match/6321650")["match"].get("leagueFa", "")
pl = get(f"{base}/api/match/5795503")["match"].get("leagueFa", "")
uk = get(f"{base}/api/match/6284434")["match"].get("leagueFa", "")
p = get(f"{base}/api/player/696679")
prows = []
trophy4 = None
def scan(obj):
    global trophy4
    if isinstance(obj, dict):
        ln = obj.get("leagueName"); lf = obj.get("leagueFa")
        if isinstance(ln, str) and ln and "leagueFa" in obj and (lf is None or (isinstance(lf, str) and not PERSIAN.search(lf))):
            prows.append(f"{ln} → {lf!r}")
        for v in obj.values(): scan(v)
    elif isinstance(obj, list):
        for v in obj: scan(v)
scan(p)
pnode = p.get("player", p) if isinstance(p, dict) else {}
tro = pnode.get("trophies") or []
if len(tro) > 4:
    trophy4 = tro[4].get("leagueFa")
t = get(f"{base}/api/team/8456")
trows = []
def scan2(obj):
    if isinstance(obj, dict):
        ln = obj.get("leagueName"); lf = obj.get("leagueFa")
        if isinstance(ln, str) and ln and "leagueFa" in obj and (lf is None or (isinstance(lf, str) and not PERSIAN.search(lf))):
            trows.append(f"{ln} → {lf!r}")
        for v in obj.values(): scan2(v)
    elif isinstance(obj, list):
        for v in obj: scan2(v)
scan2(t)
W1 = ["چلمزفورد", "مولودیه الجزایر", "ابسفلیت یونایتد", "اتحاد بسکره"]
W2 = ["شباب قابلی", "مولودیه وهران", "اتحاد الجزائر", "شباب بلوزداد", "کاراکاس", "دپورتیوو تاچیرا"]
# cycle-435: B7 — batch-4 witnesses (the England non-league tranche) render
# Persian in the live ±7 feed (byte-exact against the 435 map block)
W4 = ["دارلینگتون", "ووکینگ", "ساوت‌پورت", "براکلی تاون"]
# cycle-436: B8 — batch-5 witnesses (the Spain Copa del Rey/Federaciones tranche)
W5 = ["زامورا", "کوردوبا", "کارتاخنا", "رکراتیوو اوئلوا"]
# cycle-437: B9 — batch-6 witnesses (the Japan J2/J3 tranche)
W6 = ["وگالتا سندای", "جوبیلو ایواتا", "یوکوهاما اف‌سی", "توکوشیما وورتیس"]
# cycle-440: B10 — batch-7 witnesses (the Scotland Challenge Cup/Lowland tranche)
W7 = ["کلاید", "ایردریونینز", "آلبیون روورز", "کویین اوف ساوت"]
# cycle-441: B11 — batch-8 witnesses (the Peru Liga 1 tranche)
W8 = ["الیانزا لیما", "اسپورتینگ کریستال", "ملگار", "یونیورسیتاریو د دپورته‌س"]
# cycle-442: B12 — batch-9 witnesses (the Romania Cup Grp. A-D + Liga II +
# Superliga tranche)
W9 = ["دینامو بخارست", "رپید بخارست", "دانشگاه کلوژ", "اف‌سی‌اس‌بی"]
# cycle-445: B13 — batch-10 witnesses (the Norway 1. Divisjon/Cup/Eliteserien
# tranche)
W10 = ["استرومسگودست", "اودز", "اوسانه", "هامارکامراتنه"]
# cycle-446: B14 — batch-11 witnesses (the Colombia Primera A + Primera B
# tranche)
W11 = ["آمریکا د کالی", "بوکا جونیورز دی کالی", "رئال کارتاخنا", "آگیلاس دوراداس"]
# cycle-447: B15 — batch-12 witnesses (the Russia Premier League + Cup
# Grp. A-D tranche)
W12 = ["اسپارتاک مسکو", "زسکا مسکو", "لوکوموتیو مسکو", "روبین کازان"]
# cycle-449: B16 — the byte-drift fix witness (the Saudi First Division
# live-literal key; the render is the file's own «الجیل»)
W13 = ["الجیل"]
# cycle-450: B17 — batch-13 witnesses (the Guatemala Liga Nacional
# Apertura tranche)
W14 = ["آنتیگوا گواتمالا", "کامیونیکیشنس", "کوبان ایمپریال", "دپورتیوو میسکو"]
# cycle-451: B18 — batch-14 witnesses (the Cyprus 2. Division + Cup tranche)
W15 = ["آئل لیماسول", "المپیاکوس نیکوزیا", "اومونیا آرادیپو", "دوکسا کاتوکوپیاس"]
# cycle-452: B19 — batch-15 witnesses (the Thailand League Cup tranche)
W16 = ["چای نات", "ناکون پاتوم", "خون کائن یونایتد", "سونگکلا یونایتد"]
# cycle-455: B21 — batch-16 witnesses (the Austria Bundesliga/2. Liga tranche)
W17 = ["آستریا وین", "فرست ویینا", "واکر اینسبروک", "تیرول"]
# cycle-456: B22 — batch-17 witnesses (the Montenegro 1. CFL tranche)
W18 = ["بودوچنوست پودگوریتسا", "آرسنال تیوات", "دچیچ توزی", "سوتجسکا نیکشیچ"]
# cycle-457: B23 — batch-18 witnesses (the Ukrainian Cup tranche)
W19 = ["دینامو کی‌یف", "کارپات لویو", "زوریا لوگانسک", "کریوباس"]
# cycle-460: B24 — batch-19 witnesses (the Poland FA Cup + II/I Liga tranche)
W20 = ["زنیچ پروشکوف", "گورنیک ونچنا", "استال ژشوف", "پوگون شدلتسه"]
# cycle-461: B25 — batch-20 witnesses (the Liga de Expansión MX tranche)
W21 = ["اتلتیکو مورلیا", "کانکون", "ونادوس", "تلاسکالا"]
# cycle-462: B26 — batch-21 witnesses (the Argentina Liga Profesional tranche)
W22 = ["راسینگ کلوب", "روزاریو سنترال", "ولز سارسفیلد", "هوراکان"]
# cycle-465: B27 — batch-22 witnesses (the Panama LPF tranche, the 447 tie-break winner)
W23 = ["عربه یونیدو", "پلازا آمادور", "اسپورتینگ سن میگلیتو", "تائورو"]
# cycle-466: B28 — batch-23 witnesses (the Honduras Liga Nacional tranche, the unbroken tie half)
W24 = ["رئال اسپانیا", "اولانچو", "خوتیکالپا", "دپورتیوو پلاتنسه"]
# cycle-467: B29 — batch-24 witnesses (the Estonia Meistriliiga tranche, the five-way-tie winner)
W25 = ["کورساره", "لوادیا تالین", "ناروا ترانس", "نومه کالیو"]
miss1 = [w for w in W1 if w not in fa_set]
miss2 = [w for w in W2 if w not in fa_set]
miss4 = [w for w in W4 if w not in fa_set]
miss5 = [w for w in W5 if w not in fa_set]
miss6 = [w for w in W6 if w not in fa_set]
miss7 = [w for w in W7 if w not in fa_set]
miss8 = [w for w in W8 if w not in fa_set]
miss9 = [w for w in W9 if w not in fa_set]
miss10 = [w for w in W10 if w not in fa_set]
miss11 = [w for w in W11 if w not in fa_set]
miss12 = [w for w in W12 if w not in fa_set]
miss13 = [w for w in W13 if w not in fa_set]
miss14 = [w for w in W14 if w not in fa_set]
miss15 = [w for w in W15 if w not in fa_set]
miss16 = [w for w in W16 if w not in fa_set]
miss17 = [w for w in W17 if w not in fa_set]
miss18 = [w for w in W18 if w not in fa_set]
miss19 = [w for w in W19 if w not in fa_set]
miss20 = [w for w in W20 if w not in fa_set]
miss21 = [w for w in W21 if w not in fa_set]
miss22 = [w for w in W22 if w not in fa_set]
miss23 = [w for w in W23 if w not in fa_set]
miss24 = [w for w in W24 if w not in fa_set]
miss25 = [w for w in W25 if w not in fa_set]
b1 = 1 if len(leaks) == 0 else 0
b2 = 1 if kn == "جام حذفی هلند" else 0
b3 = 1 if pl == "پریمیرلیگ انگلیس" else 0
b4 = 1 if abs(len(team_names) - 1728) <= 25 else 0
T4 = "لیگ ۲ پریمیرلیگ انگلیس — دستهٔ ۲"
b5 = 1 if (len(prows) == 0 and trophy4 == T4) else 0
b6 = 1 if (not miss1 and not miss2) else 0
b7 = 1 if not miss4 else 0
b8 = 1 if not miss5 else 0
b9 = 1 if not miss6 else 0
b10 = 1 if not miss7 else 0
b11 = 1 if not miss8 else 0
b12 = 1 if not miss9 else 0
b13 = 1 if not miss10 else 0
b14 = 1 if not miss11 else 0
b15 = 1 if not miss12 else 0
b16 = 1 if not miss13 else 0
b17 = 1 if not miss14 else 0
b18 = 1 if not miss15 else 0
b19 = 1 if not miss16 else 0
b21 = 1 if not miss17 else 0
b22 = 1 if not miss18 else 0
b23 = 1 if not miss19 else 0
b24 = 1 if not miss20 else 0
b25 = 1 if not miss21 else 0
b26 = 1 if not miss22 else 0
b27 = 1 if not miss23 else 0
b28 = 1 if not miss24 else 0
b29 = 1 if not miss25 else 0
# cycle-454: B20 — the batch-15 block byte-identity to commit 886f6ff (the
# 453 finding #A3 re-anchor promoted to a permanent hold: the committed
# block must never silently drift from the immutable shipped batch)
_b15d = subprocess.run(["git", "show", "886f6ff", "--", "src/lib/leagues.ts"],
                       capture_output=True, text=True).stdout
_b15 = dict(re.findall(r'^\+\s*"([^"]+)"\s*:\s*"([^"]*)"', _b15d, re.M))
_src15 = open("src/lib/leagues.ts", encoding="utf-8").read()
_m15 = re.search(r'cycle-452: harvest batch 15(.*?)(?=// cycle-|};)', _src15, re.S)
_cur15 = dict(re.findall(r'"([^"]+)":\s*"([^"]+)"', _m15.group(1))) if _m15 else {}
b20 = 1 if (len(_b15) == 11 and _cur15 == _b15) else 0
if not b20:
    print("B20-WHY gitBatch=%d curBlock=%d missing=%s drift=%s" % (
        len(_b15), len(_cur15), sorted(set(_b15) - set(_cur15))[:4],
        [k for k in _b15 if k in _cur15 and _cur15[k] != _b15[k]][:4]))
print("B-SUMMARY "
      f"compLeaks={len(leaks)} teamRows={team_rows} teamDistinct={len(team_names)} "
      f"knvb={kn!r} catalog={pl!r} ukr={uk!r} "
      f"playerLeakRows={len(prows)} teamLeakRows={len(trows)} "
      f"batch1Missing={miss1} batch2Missing={miss2} batch4Missing={miss4} batch5Missing={miss5} batch6Missing={miss6} batch7Missing={miss7} batch8Missing={miss8} batch9Missing={miss9} batch10Missing={miss10} batch11Missing={miss11} batch12Missing={miss12} fixWitnessMissing={miss13} batch13Missing={miss14} batch14Missing={miss15} batch15Missing={miss16} batch16Missing={miss17} batch17Missing={miss18} batch18Missing={miss19} batch19Missing={miss20} batch20Missing={miss21} batch21Missing={miss22} batch22Missing={miss23} batch23Missing={miss24} batch24Missing={miss25} batch15Block={'ok' if b20 else 'DRIFT'} trophy4={trophy4!r}")
print("B-ASSERTS b1={0} b2={1} b3={2} b4={3} b5={4} b6={5} b7={6} b8={7} b9={8} b10={9} b11={10} b12={11} b13={12} b14={13} b15={14} b16={15} b17={16} b18={17} b19={18} b20={19} b21={20} b22={21} b23={22} b24={23} b25={24} b26={25} b27={26} b28={27} b29={28}".format(b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18, b19, b20, b21, b22, b23, b24, b25, b26, b27, b28, b29))
if leaks: print("B-LEAKS:", json.dumps({f"{k[0]}|{k[1]}": v for k, v in list(leaks.items())[:6]}, ensure_ascii=False))
if prows: print("B-PLAYER-LEAKS:", json.dumps(prows[:10], ensure_ascii=False))
if trows: print("B-TEAM-LEAKS:", json.dumps(trows[:10], ensure_ascii=False))
PY
)
echo "$RES"
S=$(echo "$RES" | grep "B-ASSERTS" | tail -1)
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29; do
  V=$(echo "$S" | grep -oE "b$i=[01]" | cut -d= -f2)
  D=""
  [ "$i" = "20" ] && D=$(echo "$RES" | grep "B20-WHY" | tail -1 | cut -c1-200)
  case $i in
    1) LBL="day-feed zero pure-Latin competition headers across ±7" ;;
    2) LBL="match hook KNVB Persian (6321650)" ;;
    3) LBL="catalog byte-stability hold (5795503)" ;;
    4) LBL="team raw pool within the ±25 drift band of the documented 1728 census (re-anchored 467, loud-pool rule)" ;;
    5) LBL="the 429 trophy hold: zero player raw-fallback rows + trophies[4] byte-exact" ;;
    6) LBL="harvest batch-1+batch-2 witnesses all Persian in the live ±7 feed" ;;
    7) LBL="harvest batch-4 witnesses (England non-league tranche) all Persian in the live ±7 feed" ;;
    8) LBL="harvest batch-5 witnesses (Spain Copa del Rey/Federaciones tranche) all Persian in the live ±7 feed" ;;
    9) LBL="harvest batch-6 witnesses (Japan J2/J3 tranche) all Persian in the live ±7 feed" ;;
    10) LBL="harvest batch-7 witnesses (Scotland Challenge Cup/Lowland tranche) all Persian in the live ±7 feed" ;;
    11) LBL="harvest batch-8 witnesses (Peru Liga 1 tranche) all Persian in the live ±7 feed" ;;
    12) LBL="harvest batch-9 witnesses (Romania Cup Grp. A-D + Liga II + Superliga tranche) all Persian in the live ±7 feed" ;;
    13) LBL="harvest batch-10 witnesses (Norway 1. Divisjon/Cup/Eliteserien tranche) all Persian in the live ±7 feed" ;;
    14) LBL="harvest batch-11 witnesses (Colombia Primera A + Primera B tranche) all Persian in the live ±7 feed" ;;
    15) LBL="harvest batch-12 witnesses (Russia Premier League + Cup Grp. A-D tranche) all Persian in the live ±7 feed" ;;
    16) LBL="the 449 byte-drift fix witness («الجیل», the Saudi First Division live-literal key) Persian in the live ±7 feed" ;;
    17) LBL="harvest batch-13 witnesses (Guatemala Liga Nacional Apertura tranche) all Persian in the live ±7 feed" ;;
    18) LBL="harvest batch-14 witnesses (Cyprus 2. Division + Cup tranche) all Persian in the live ±7 feed" ;;
    19) LBL="harvest batch-15 witnesses (Thailand League Cup tranche) all Persian in the live ±7 feed" ;;
    20) LBL="the 454 batch-15 block hold: leagues.ts byte-identical to commit 886f6ff (11 pairs — the A3 re-anchor promoted)" ;;
    21) LBL="harvest batch-16 witnesses (Austria Bundesliga/2. Liga tranche) all Persian in the live ±7 feed" ;;
    22) LBL="harvest batch-17 witnesses (Montenegro 1. CFL tranche) all Persian in the live ±7 feed" ;;
    23) LBL="harvest batch-18 witnesses (Ukrainian Cup tranche) all Persian in the live ±7 feed" ;;
    24) LBL="harvest batch-19 witnesses (Poland FA Cup + II/I Liga tranche) all Persian in the live ±7 feed" ;;
    25) LBL="harvest batch-20 witnesses (Liga de Expansión MX tranche) all Persian in the live ±7 feed" ;;
    26) LBL="harvest batch-21 witnesses (Argentina Liga Profesional tranche) all Persian in the live ±7 feed" ;;
    27) LBL="harvest batch-22 witnesses (Panama LPF tranche, the 447 tie-break winner) all Persian in the live ±7 feed" ;;
    28) LBL="harvest batch-23 witnesses (Honduras Liga Nacional tranche, the unbroken tie half — the first zero-anchor batch) all Persian in the live ±7 feed" ;;
    29) LBL="harvest batch-24 witnesses (Estonia Meistriliiga tranche, the five-way-tie winner by the 447 anchor-quality rule) all Persian in the live ±7 feed" ;;
  esac
  ck "B$i $LBL" "${V:-0}" "$D"
done
SUM=$(echo "$RES" | grep "B-SUMMARY" | tail -1)
echo "   FINDINGS(team leagueFaById rows with raw labels — report-only): $(echo "$SUM" | grep -oE 'teamLeakRows=[0-9]+' )"
grep -q "B-LEAKS" <<< "$RES" && echo "   $(grep 'B-LEAKS' <<< "$RES")" || true
grep -q "B-PLAYER-LEAKS" <<< "$RES" && echo "   $(grep 'B-PLAYER-LEAKS' <<< "$RES")" || true
grep -q "B-TEAM-LEAKS" <<< "$RES" && echo "   $(grep 'B-TEAM-LEAKS' <<< "$RES")" || true
fi

if has C; then
echo "================ C: the recent holds, real interactions (390x844) ================"
$AB set viewport 390 844 >/dev/null 2>&1
TODAY=$(TZ=Asia/Tehran date +%F)
$AB open "$BASE/" >/dev/null 2>&1
sleep 3
HREF=$($AB eval "document.querySelector('[data-testid=home-day-ics-link]')?.getAttribute('href')||''" 2>/dev/null | tr -d '"')
ck "C1 the 422 hold: home ICS href == today" "$([ "$HREF" = "/api/day-calendar?date=$TODAY" ] && echo 1 || echo 0)" "'$HREF'"
FRESH=$($AB eval "(()=>{const el=document.querySelector('[data-testid=home-day-freshness]');return el?el.textContent.trim():''})()" 2>/dev/null | tr -d '"')
case "$FRESH" in "به‌روزرسانی "*) ck "C2 the 424 hold: freshness label alive" 1;; *) ck "C2 424 freshness" 0 "'$FRESH'";; esac
$AB open "$BASE/?date=2026-10-27" >/dev/null 2>&1
sleep 3
HREF2=$($AB eval "document.querySelector('[data-testid=home-day-ics-link]')?.getAttribute('href')||''" 2>/dev/null | tr -d '"')
ck "C3 the 422 deep-link hold: ?date=2026-10-27 drives the CTA href" "$([ "$HREF2" = "/api/day-calendar?date=2026-10-27" ] && echo 1 || echo 0)" "'$HREF2'"
LEAKH=$($AB eval "Array.from(document.querySelectorAll('h3.rune-title')).filter(h=>{const t=h.textContent.trim();return /[A-Za-z]/.test(t)&&!/[\u0600-\u06FF]/.test(t)}).length" 2>/dev/null | tr -d '"')
ck "C4 the 426 hold: zero pure-Latin headers on the id-235 day" "$([ "$LEAKH" = "0" ] && echo 1 || echo 0)" "n=$LEAKH"
$AB open "$BASE/match/5795503" >/dev/null 2>&1
sleep 3
MHREF=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('match-calendar'))||''" 2>/dev/null | tr -d '"')
ck "C5 the 421 hold: match-page ICS CTA present" "$([ -n "$MHREF" ] && echo 1 || echo 0)" "'$MHREF'"
$AB eval "(()=>{const b=Array.from(document.querySelectorAll('button,a')).find(x=>x.textContent.trim().includes('اطلاعات'));if(b)b.click();return !!b})()" >/dev/null 2>&1
sleep 2
VEN=$($AB eval "document.body.innerText.includes('سنت جیمز')||document.body.innerText.includes('نیوکاسل')" 2>/dev/null | tr -d '"')
ck "C6 the 412 hold: «اطلاعات» click flips venue to Persian" "$([ "$VEN" = "true" ] && echo 1 || echo 0)"
$AB open "$BASE/team/8456" >/dev/null 2>&1
sleep 5
TC=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('team-calendar'))||''" 2>/dev/null | tr -d '"')
ck "C7 the 420 hold: team ICS CTA (lazy poll)" "$([ -n "$TC" ] && echo 1 || echo 0)" "'$TC'"
$AB open "$BASE/league/pl" >/dev/null 2>&1
sleep 3
SEL=$($AB eval "(()=>{const s=document.querySelector('select');if(!s)return 'none';const opt=Array.from(s.options).map(o=>o.value).find(v=>v&&v.includes('/')&&v!=='2026/2027');if(!opt)return 'no-slash-opt';const setter=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;setter.call(s,opt);s.dispatchEvent(new Event('change',{bubbles:true}));return opt})()" 2>/dev/null | tr -d '"')
sleep 2
URL=$($AB eval "location.search" 2>/dev/null | tr -d '"')
ck "C8 the 419 hold: season select setter+change carries ?season=" "$([ "$SEL" != "none" ] && [ "$SEL" != "no-slash-opt" ] && echo "$URL" | grep -q "season=" && echo 1 || echo 0)" "sel=$SEL url=$URL"
$AB open "$BASE/transfers" >/dev/null 2>&1
sleep 3
$AB eval "(()=>{const chip=Array.from(document.querySelectorAll('button,[role=tab]')).find(x=>x.textContent.trim().includes('از ۵۰ میلیون'));if(chip)chip.click();return !!chip})()" >/dev/null 2>&1
sleep 3
FEE=$($AB eval "document.body.innerText.includes('کارمزد')" 2>/dev/null | tr -d '"')
ck "C9 the 416 hold: «از ۵۰ میلیون» chip click flips to fee rows" "$([ "$FEE" = "true" ] && echo 1 || echo 0)"
$AB open "$BASE/news" >/dev/null 2>&1
sleep 3
NEWS=$($AB eval "(()=>{const cards=document.querySelectorAll('article[data-testid=chronicle-card] h3');let bad=0;cards.forEach(h=>{const t=h.textContent;if(/[؀-ۿ]/.test(t)&&/[A-Za-z]{4,}/.test(t))bad++});return cards.length+':'+bad})()" 2>/dev/null | tr -d '"')
NROWS=${NEWS%%:*}; NBAD=${NEWS##*:}
ck "C10 the 414 hold: $NROWS news titles, $NBAD defective mixed-script" "$([ "${NBAD:-1}" = "0" ] && [ "${NROWS:-0}" -ge 10 ] && echo 1 || echo 0)" "$NEWS"
FAV=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('favorites-calendar'))||''" 2>/dev/null | tr -d '"')
$AB open "$BASE/" >/dev/null 2>&1
sleep 2
FAV=$($AB eval "Array.from(document.querySelectorAll('a')).map(a=>a.getAttribute('href')).find(h=>h&&h.includes('favorites-calendar'))||'absent'" 2>/dev/null | tr -d '"')
if [ "$FAV" = "absent" ]; then ck "C11 the 425 hold: favorites CTA honestly ABSENT with empty store" 1; else ck "C11 the 425 hold: favorites CTA present with href" 1 "$FAV"; fi

# ---- C12 NEW (cycle 438): the 434 mount-gate hold, permanent patrol level ----
# cnt(): occurrence count of $2 in string $1 (grep -c counts LINES — the strip
# is one minified line; the 434 first-run lesson)
cnt() { printf '%s' "$1" | python3 -c "import sys;print(sys.stdin.read().count(sys.argv[1]))" "$2"; }
# strip extraction identical to cycle434-domproof.sh: from the day-nav
# container mark to the status-filter role="group"
curl -s --max-time 25 "$BASE/" > /tmp/c438-served.html
STRIP=$(python3 - /tmp/c438-served.html <<'PY'
import sys
h = open(sys.argv[1], encoding='utf-8').read()
i = h.find('flex gap-2 overflow-x-auto pb-1.5')
k = h.find('role="group"', i)
print(h[i:k] if i >= 0 and k > i else "")
PY
)
NB=$(cnt "$STRIP" "<button"); AM=$(cnt "$STRIP" "امروز")
DIG=$(cnt "$STRIP" "۰"); for d in ۱۲۳۴۵۶۷۸۹; do DIG=$((DIG + $(cnt "$STRIP" "$d"))); done
WDHIT=$(printf '%s' "$STRIP" | python3 -c "
import sys, re
s = sys.stdin.read()
print('|'.join(sorted(set(re.findall(r'(یکشنبه|دوشنبه|سه‌شنبه|چهارشنبه|پنجشنبه|جمعه|شنبه)', s)))) or '')" 2>/dev/null)
ck "C12a the 434 mount-gate hold: served strip time-invariant (15 chips / 1 امروز / 0 digits / 0 weekdays)" \
  "$([ "$NB" = "15" ] && [ "$AM" = "1" ] && [ "$DIG" = "0" ] && [ -z "$WDHIT" ] && echo 1 || echo 0)" \
  "chips=$NB today=$AM digits=$DIG weekdays='$WDHIT'"
CHIPS_JS='(()=>{const b=[...document.querySelectorAll("button")].filter(x=>(x.className||"").includes("min-w-[62px]"));if(!b.length)return JSON.stringify({err:"no chips"});return JSON.stringify({n:b.length,nonEmpty:b.filter(x=>x.children[1]&&x.children[1].textContent.trim()).length,today:b[7]?b[7].children[0].textContent.trim():"",day:b[7]?b[7].children[1].textContent.trim():"",act:b.findIndex(x=>x.getAttribute("aria-pressed")==="true")})})()'
CH=$($AB eval "$CHIPS_JS" 2>/dev/null)
NE=$(printf '%s' "$CH" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
if s.startswith('\"') and s.endswith('\"'): s = s[1:-1]
s = s.replace('\\\\\"', '\"')
try: print(json.loads(s).get('nonEmpty'))
except Exception: print('NA')" 2>/dev/null)
ACT=$(printf '%s' "$CH" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
if s.startswith('\"') and s.endswith('\"'): s = s[1:-1]
s = s.replace('\\\\\"', '\"')
try: print(json.loads(s).get('act'))
except Exception: print('NA')" 2>/dev/null)
ck "C12b the 434 mount-gate hold: hydration fills 15/15 day slots, today chip (idx 7) pressed" \
  "$([ "$NE" = "15" ] && [ "$ACT" = "7" ] && echo 1 || echo 0)" "nonEmpty=$NE act=$ACT raw=${CH:0:120}"
$AB errors --clear >/dev/null 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >/dev/null 2>&1
sleep 3
PE=$($AB errors --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    e=(d.get('data') or {}).get('errors', [])
    print(len(e) if isinstance(e,list) else 0)
except Exception: print('NA')")
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    msgs=(d.get('data') or {}).get('messages', [])
    print(sum(1 for m in msgs if isinstance(m,dict) and m.get('type') in ('error','assert')))
except Exception: print('NA')")
ck "C12c the 434 mount-gate hold: fresh home load — zero console errors/asserts + zero page errors (the direct #418 probe)" \
  "$([ "$PE" = "0" ] && [ "$CE" = "0" ] && echo 1 || echo 0)" "console=$CE pageErrors=$PE"

# ---- C13 NEW (cycle 443): the 439 skip-link hold, permanent patrol level ----
# Promotion precedent = C12: a hold that lived only in a cycle-specific
# domproof becomes a standing check. C13a reuses the C12a served fetch (same
# moment, /tmp/c438-served.html); C13b runs live on a fresh home load.
SKIP=$(python3 - /tmp/c438-served.html <<'PY'
import re, sys
h = open(sys.argv[1], encoding='utf-8').read()
b = h.find('<body')
i = h.find('<a', b)
j = h.find('</a>', i)
seg = h[i:j] if i >= 0 and j > i else ''
m = re.search(r'href="([^"]*)"', seg)
ok = (m is not None and m.group(1) == '#main-content'
      and 'پرش به محتوا' in seg
      and '-translate-y-16' in seg and 'focus:translate-y-0' in seg
      and h.count('<main id="main-content"') == 1)
print(1 if ok else 0)
PY
)
ck "C13a the 439 skip-link hold: served body's first anchor = پرش به محتوا → #main-content (park/reveal classes, exactly 1 id'd main)" \
  "$([ "$SKIP" = "1" ] && echo 1 || echo 0)"
$AB open "$BASE/" >/dev/null 2>&1
sleep 2
# the reveal rides transition-transform (the 439 B3 lesson): focus inside the
# FIRST eval, wait for the transition, measure in a SECOND eval — one
# synchronous eval reads the start of the animation (revealed=false).
SKIP_JS1='(()=>{const a=document.body.querySelector("a");if(!a||a.getAttribute("href")!=="#main-content")return JSON.stringify({err:"no skip link"});const f=[...document.body.querySelectorAll("a,button,input,select,textarea,[tabindex]")].filter(x=>!x.disabled&&x.tabIndex>=0);const first=f.length>0&&f[0]===a;const r=a.getBoundingClientRect();const parked=r.bottom<=0;a.focus();return JSON.stringify({first:first,parked:parked})})()'
S1=$($AB eval "$SKIP_JS1" 2>/dev/null)
sleep 1
SKIP_JS2='(()=>{const a=document.body.querySelector("a");if(!a)return JSON.stringify({err:"absent"});const r=a.getBoundingClientRect();return JSON.stringify({revealed:r.top>=0&&r.bottom>0&&r.height>0,text:a.textContent.trim()})})()'
S2=$($AB eval "$SKIP_JS2" 2>/dev/null)
S1V=$(printf '%s' "$S1" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
if s.startswith('\"') and s.endswith('\"'): s = s[1:-1]
s = s.replace('\\\\\"', '\"')
try:
    d = json.loads(s)
    print(d.get('first'), d.get('parked'))
except Exception: print('NA NA')" 2>/dev/null)
S2V=$(printf '%s' "$S2" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
if s.startswith('\"') and s.endswith('\"'): s = s[1:-1]
s = s.replace('\\\\\"', '\"')
try:
    d = json.loads(s)
    print(d.get('revealed'), d.get('text'))
except Exception: print('NA NA')" 2>/dev/null)
ck "C13b the 439 skip-link hold: live 390×844 — first focusable, parked at rest, revealed on focus (post-transition)" \
  "$([ "$S1V" = "True True" ] && printf '%s' "$S2V" | grep -q '^True پرش به محتوا$' && echo 1 || echo 0)" "rest=[$S1V] focus=[$S2V]"
# cycle-448 promotion (bug-hunt, the C13 precedent): the 444 skip-link
# LANDING hold leaves its cycle-specific probe (scripts/c444_probe.sh +
# cycle444-domproof.sh B4) and becomes a permanent patrol check — C14: live
# at 390×844 the REAL anchor jump (the actual <a href=#main-content> click
# from the page bottom) must land #main-content VISIBLE: post-jump
# main rect.top >= header rect.bottom with the hash retained (the 444
# geometry: in the document flow ONLY the sticky header precedes
# #main-content, so any scroll-margin larger than its offsetTop drives the
# anchor target negative and the browser clamps to the document top —
# value-independent, holds for every header height; the standing ±1px
# header-height drift 145→146 is harmless by the same argument). Home + one
# inner route cover the two header-height regimes (home nav wraps at 390px
# vs the 68px inner chrome). If a future layout change re-breaks the
# landing (the pre-444 state: the sticky top-0 z-40 header painting over
# the first row, main-top=0 COVERED), the patrol fails BEFORE keyboard
# users silently lose the target. Harness lesson banked the same cycle: the
# bash pipeline DISPLAY mangled the probe's a[href= into aref= and nearly
# triggered a phantom repair of a CORRECT file — the Read tool is the byte
# authority; verify file bytes with Read before declaring a file broken.
C14BAD=0; C14DETAIL=""
for C14P in "/" "/league/pl"; do
  $AB open "$BASE$C14P" >/dev/null 2>&1
  sleep 3
  RH=$($AB eval 'JSON.stringify({hb:Math.round(document.querySelector("header").getBoundingClientRect().bottom)})' 2>/dev/null)
  HB14=$(printf '%s' "$RH" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
if s.startswith('\"') and s.endswith('\"'): s = s[1:-1]
s = s.replace('\\\\\"', '\"')
try: print(json.loads(s).get('hb'))
except Exception: print('NA')" 2>/dev/null)
  $AB eval "window.scrollTo(0, document.body.scrollHeight)" >/dev/null 2>&1
  sleep 1
  $AB eval "(()=>{const el=document.querySelector('a[href=\"#main-content\"]');if(el){el.click();return 'clicked'}return 'missing'})()" >/dev/null 2>&1
  sleep 1.5
  RM=$($AB eval 'JSON.stringify({mt:Math.round(document.getElementById("main-content").getBoundingClientRect().top),h:location.hash})' 2>/dev/null)
  MT14=$(printf '%s' "$RM" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
if s.startswith('\"') and s.endswith('\"'): s = s[1:-1]
s = s.replace('\\\\\"', '\"')
try: print(json.loads(s).get('mt'))
except Exception: print('NA')" 2>/dev/null)
  HS14=$(printf '%s' "$RM" | python3 -c "
import json, sys
s = sys.stdin.read().strip()
if s.startswith('\"') and s.endswith('\"'): s = s[1:-1]
s = s.replace('\\\\\"', '\"')
try: print(json.loads(s).get('h'))
except Exception: print('NA')" 2>/dev/null)
  if [ "$MT14" != "NA" ] && [ "$HB14" != "NA" ] && [ "$HS14" = "#main-content" ] && [ "$MT14" -ge $((HB14 - 2)) ] 2>/dev/null; then
    C14DETAIL="$C14DETAIL $C14P(hb=$HB14,mt=$MT14,ok)"
  else
    C14BAD=$((C14BAD+1)); C14DETAIL="$C14DETAIL $C14P(hb=$HB14,mt=$MT14,h=$HS14,BAD)"
  fi
done
ck "C14 the 444 landing hold: real skip-link click lands main below the header bottom, hash kept (home+inner)" \
  "$([ "$C14BAD" = "0" ] && echo 1 || echo 0)" "bad=$C14BAD$C14DETAIL"
fi

if has D; then
echo "================ D: the 16-page DOM sweep (390x844) ================"
PAGES=("/" "/leagues" "/topscorers" "/topscorers/pl" "/league/pl" "/league/hazfi" "/league/ucl"
"/team/8456" "/team/8667" "/match/5795503" "/player/696679" "/coach/78626"
"/news" "/transfers" "/search" "/players")
$AB set viewport 390 844 >/dev/null 2>&1
BADP=0
for P in "${PAGES[@]}"; do
  # the buffers are session-cumulative (cycle-432 probe: my own console.error
  # probe stayed in the buffer for every later page) — clear per page so the
  # counts are FRESH per navigation
  $AB errors --clear >/dev/null 2>&1
  $AB console --clear >/dev/null 2>&1
  $AB open "$BASE$P" >/dev/null 2>&1
  sleep 2
  SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  PE=$($AB errors --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    e=(d.get('data') or {}).get('errors', [])
    print(len(e) if isinstance(e,list) else 0)
except Exception: print('NA')")
  CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    msgs=(d.get('data') or {}).get('messages', [])
    print(sum(1 for m in msgs if isinstance(m,dict) and m.get('type') in ('error','assert')))
except Exception: print('NA')")
  H1=$($AB eval "document.querySelector('h1')?1:0" 2>/dev/null | tr -d '"')
  if [ "$SW" != "390" ] || { [ "$PE" != "0" ] && [ "$PE" != "NA" ]; } || { [ "$CE" != "0" ] && [ "$CE" != "NA" ]; } || [ "$H1" != "1" ]; then
    BADP=$((BADP+1)); echo "  !! $P sw=$SW pe=$PE ce=$CE h1=$H1"
  fi
done
ck "D1 all ${#PAGES[@]} pages clean (sw=390, errors 0, h1) bad=$BADP" "$([ "$BADP" = "0" ] && echo 1 || echo 0)"
fi

if has E; then
echo "================ E: the gates ================"
cd /home/z/my-project/remontada
bunx eslint src >/dev/null 2>&1; ck "E1 eslint 0/0" "$([ $? = "0" ] && echo 1 || echo 0)"
rm -rf .next/types && bunx tsc --noEmit >/dev/null 2>&1; ck "E2 tsc 0" "$([ $? = "0" ] && echo 1 || echo 0)"
bun run build >/dev/null 2>&1; ck "E3 build 0" "$([ $? = "0" ] && echo 1 || echo 0)"
bash /home/z/my-project/scripts/start-remontada.sh >/dev/null 2>&1
sleep 2
H=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$BASE")
ck "E4 official start → 200" "$([ "$H" = "200" ] && echo 1 || echo 0)" "http=$H"
R=$(BASE=http://localhost:3000 bash scripts/cycle17-regression.sh 2>/dev/null | grep -E "^PASS=" | tail -1)
echo "   $R"
ck "E5 regression 28/28" "$(echo "$R" | grep -q "PASS=28 FAIL=0" && echo 1 || echo 0)"
CH=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$BASE")
ck "E6 final health 200" "$([ "$CH" = "200" ] && echo 1 || echo 0)"
fi

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
