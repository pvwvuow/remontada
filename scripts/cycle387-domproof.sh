#!/usr/bin/env bash
# cycle387-domproof.sh — فیکس cycle 387: the 386 F1 findings flipped to
# zero-leak. The date-dependent day-feed tail (the 386 finding: 17 raw
# headers at offset=-1, 21 at +1, 11 at +2, 4 raw IRANIAN Azadegan names
# at -1) is healed by the 29-key CC block + 4-key TEAM_FA block + the
# bounded suffix-family composer (CUP_CC_FA / STAGE_SUFFIX_FA / group+stage
# suffix composition) — the 386 structural decision implemented.
#
#   F1a..e  every day-feed window offset -2..+2 serves ZERO raw headers and
#           ZERO raw IRN team names (the direct flip of the 386 F1
#           assertions), with Persian anchors for every probed name.
#   F1x     byte-consistency: the composer output for the eroded instances
#           (League Cup Grp. B/D EGY, Segunda Federacion - Group 4 ESP,
#           Australian Championship Grp. B/C AUS) EXACTLY equals the shape
#           of the pre-existing per-instance keys (grp. a/c, group 1/2/3/5).
#   G1-G4   the 382/380/384/385 contracts untouched (worldcup/pl/dfbpokal/
#           asiancup).
#   P1-P5   DOM hygiene at 390x844 (page-errors=0, console-errors=0,
#           scrollW=cw=390) + Persian h1 anchors.
#
# probe lessons applied (386): heredoc python rides a temp file (never
# inline inside $()); multi-part expectations composed part-for-part;
# status probes ride raw curl -w.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

# ---------- python helpers (temp files — the 386 subclass) ----------
PYV=/tmp/c387_verdict.py
cat > "$PYV" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
gs = d.get('groups') or []
rawH = 0; irn = set()
for g in gs:
    ln = g.get('leagueName') or ''
    if (g.get('leagueFa') or '') == ln and ln: rawH += 1
    if (g.get('ccode') or '') == 'IRN':
        for m in (g.get('matches') or []):
            for k in ('home', 'away'):
                v = m.get(k) or {}
                if v.get('name') and (v.get('fa') or '') == v.get('name'):
                    irn.add(v.get('name'))
print(f"{rawH}|{len(irn)}")
EOF

PYE=/tmp/c387_exact.py
cat > "$PYE" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
name = sys.argv[2]; want = sys.argv[3]
gs = d.get('groups') or []
for g in gs:
    if (g.get('leagueName') or '') == name:
        print(1 if (g.get('leagueFa') or '') == want else 0)
        sys.exit()
print('absent')
EOF

PYT=/tmp/c387_irn.py
cat > "$PYT" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
need = set(sys.argv[2:])
fa = set()
for g in (d.get('groups') or []):
    if (g.get('ccode') or '') == 'IRN':
        for m in (g.get('matches') or []):
            for k in ('home', 'away'):
                v = (m.get(k) or {}).get('fa') or ''
                if v: fa.add(v)
print(1 if need <= fa else 0)
EOF

PYA=/tmp/c387_anchor.py
cat > "$PYA" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
want = set(x for x in sys.argv[2:] if x)
have = set()
for g in (d.get('groups') or []):
    f = g.get('leagueFa') or ''
    if f: have.add(f)
missing = sorted(want - have)
print(1 if not missing else 0)
print('|'.join(missing), file=sys.stderr)
EOF

# ---------- fetch the 5-offset window ONCE ----------
for O in -2 -1 0 1 2; do
  api "/api/matches?offset=$O" > "/tmp/c387_feed_$O.json"
done

# ============ F1a offset=-1: the direct flip of the 386 finding ============
V=$(python3 "$PYV" /tmp/c387_feed_-1.json)
ck "F1a offset=-1: ZERO raw headers + zero raw IRN (was 17 + 4 at the 386 patrol) — got $V" "$([ "$V" = "0|0" ] && echo 1 || echo 0)"
T=$(python3 "$PYT" /tmp/c387_feed_-1.json "هوادار" "کارا گستر" "نفت مسجدسلیمان" "نیروی زمینی")
ck "F1a the 4 Azadegan anchors render Persian (هوادار/کارا گستر/نفت مسجدسلیمان/نیروی زمینی)" "$T"
A=$(python3 "$PYA" /tmp/c387_feed_-1.json \
  "اردیویزهٔ زنان هلند" "سگوندا فدراسیون اسپانیا — گروه ۴" "ان‌دبلیو‌اس‌ال" \
  "لیگ سه نروژ — بخش ۲" "لیگ سه نروژ — بخش ۴" "ویرسلیگا لتونی" "لیگ برتر امارات" \
  "جام لیگ زنان اسکاتلند" "لیگ A دانمارک" "جام حذفی برزیل" "لیگ برتر کانادا" \
  "قهرمانی استرالیا — گروه B" "قهرمانی استرالیا — گروه C" "جام حذفی چین" \
  "پلی‌آف ارتقا دسته اول ایرلند" "لیگ برتر زنان فرانسه" "چلنج‌لیگ سوئیس" 2>/dev/null)
ck "F1a all 17 probed −1 headers render Persian (composer + point keys)" "$A"
X=$(python3 "$PYE" /tmp/c387_feed_-1.json "Segunda Federacion - Group 4" "سگوندا فدراسیون اسپانیا — گروه ۴")
ck "F1x Segunda Federacion - Group 4 == «سگوندا فدراسیون اسپانیا — گروه ۴» (byte-consistent with the 1/2/3/5 keys)" "$([ "$X" = "1" ] && echo 1 || echo 0)"
X=$(python3 "$PYE" /tmp/c387_feed_-1.json "Australian Championship Grp. B" "قهرمانی استرالیا — گروه B")
ck "F1x Australian Championship Grp. B == «قهرمانی استرالیا — گروه B» (byte-consistent with the grp. a/d keys)" "$([ "$X" = "1" ] && echo 1 || echo 0)"

# ============ F1b offset=+1: was 21 raw ============
V=$(python3 "$PYV" /tmp/c387_feed_1.json)
ck "F1b offset=+1: ZERO raw headers (was 21) — got $V" "$([ "${V%%|*}" = "0" ] && echo 1 || echo 0)"
A=$(python3 "$PYA" /tmp/c387_feed_1.json \
  "جام چلنج اسکاتلند" "لیگ جوانان اروپا — مرحلهٔ لیگی" "لیگ جوانان اروپا — دور دوم" \
  "جام اتحادیه تایلند — پلی‌آف" "جام لیگ ملی انگلیس — گروه A" "جام لیگ ملی انگلیس — گروه B" \
  "جام لیگ ملی انگلیس — گروه C" "جام لیگ ملی انگلیس — گروه D" "جام حذفی قبرس" \
  "جام اتحادیه مصر — گروه B" "جام اتحادیه مصر — گروه D" "جام حذفی کرواسی — یک‌شانزدهم نهایی" \
  "لیگ A دانمارک" "جام حذفی زنان اسپانیا" "جام حذفی دانمارک" \
  "جام ای‌اف‌ال شمالی — گروه C" "جام ای‌اف‌ال شمالی — گروه H" "جام ای‌اف‌ال جنوبی — گروه E" \
  "جام ای‌اف‌ال جنوبی — گروه G" "لیگ ۱ تونس" "جام اتحادیه آفریقای جنوبی" 2>/dev/null)
ck "F1b all 21 probed +1 headers render Persian" "$A"
X=$(python3 "$PYE" /tmp/c387_feed_1.json "League Cup Grp. B" "جام اتحادیه مصر — گروه B")
ck "F1x League Cup Grp. B (EGY) == «جام اتحادیه مصر — گروه B» (byte-consistent with the grp. a/c keys)" "$([ "$X" = "1" ] && echo 1 || echo 0)"

# ============ F1c offset=+2: was 11 raw ============
V=$(python3 "$PYV" /tmp/c387_feed_2.json)
ck "F1c offset=+2: ZERO raw headers (was 11) — got $V" "$([ "${V%%|*}" = "0" ] && echo 1 || echo 0)"
A=$(python3 "$PYA" /tmp/c387_feed_2.json \
  "لیگ جوانان اروپا — مرحلهٔ لیگی" "لیگ جوانان اروپا — دور دوم" "جام اتحادیه تایلند — پلی‌آف" \
  "جام حذفی زنان اسپانیا" "لیگ گسترش مکزیک — آپرتورا — یک‌چهارم نهایی" "دسته دوم قطر" \
  "جام حذفی اروگوئه" "جام حذفی اسلواکی" "لیگ برتر زنان اسکاتلند" "جام حذفی مصر" "جام حذفی قبرس" 2>/dev/null)
ck "F1c all 11 probed +2 headers render Persian (the chained stage «آپرتورا — یک‌چهارم نهایی» included)" "$A"

# ============ F1d offset=-2: was 2 raw ============
V=$(python3 "$PYV" /tmp/c387_feed_-2.json)
ck "F1d offset=-2: ZERO raw headers (was 2) — got $V" "$([ "${V%%|*}" = "0" ] && echo 1 || echo 0)"
A=$(python3 "$PYA" /tmp/c387_feed_-2.json "لیگ برتر زنان فرانسه" "لیگ A دانمارک" 2>/dev/null)
ck "F1d the 2 probed −2 headers render Persian (Premiere Ligue/A-Liga)" "$A"

# ============ F1e TODAY stays clean (the extended key set holds) ============
V=$(python3 "$PYV" /tmp/c387_feed_0.json)
ck "F1e TODAY's feed: zero raw headers + zero IRN raw (the 384+387 key set, contrast guard)" "$([ "$V" = "0|0" ] && echo 1 || echo 0)"

# ============ G1-G4: prior contracts untouched ============
D=$(api "/api/standings?league=worldcup&season=2026" | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=(d.get('rows') or [])
bad=[r for r in rows if any(ch.isalpha() and ord(ch)<0x0600 for ch in (r.get('fa') or ''))]
print(1 if (d.get('ok') and len(rows)==60 and not bad) else 0); print(' rows:',len(rows),'bad:',len(bad),file=sys.stderr)")
ck "G1 worldcup 2026 standings rows=60 zero raw fa (the 382 contract)" "$D"
D=$(api "/api/standings?league=pl" | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=(d.get('rows') or [])
ok=any(r.get('fa')=='آرسنال' for r in rows)
bad=[r for r in rows if any(ch.isalpha() and ord(ch)<0x0600 for ch in (r.get('fa') or ''))]
print(1 if (d.get('ok') and len(rows)==20 and ok and not bad) else 0); print(' rows:',len(rows),file=sys.stderr)")
ck "G2 pl standings rows=20 + آرسنال zero raw (sibling untouched)" "$D"
D=$(api "/api/league-fixtures-all?league=dfbpokal" | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
bad=[f for f in rows for k in ('home','away') if any(ch.isalpha() and ord(ch)<0x0600 for ch in ((f.get(k) or {}).get('fa') or ''))]
print(1 if (len(rows)==56 and not bad) else 0); print(' rows:',len(rows),'bad:',len(bad),file=sys.stderr)")
ck "G3 dfbpokal fixtures rows=56 zero raw .fa (the 384 contract)" "$D"
D=$(api "/api/standings?league=asiancup&season=2023" | python3 -c "
import json,sys; d=json.load(sys.stdin)
rows=d.get('rows') or []
iran=[r for r in rows if (r.get('name') or '')=='Iran']
ok=(d.get('ok') and len(rows)==30 and iran and iran[0].get('fa')=='ایران' and iran[0].get('wins')==3 and iran[0].get('idx')==1)
print(1 if ok else 0); print(' iran fa:',(iran[0] or {}).get('fa') if iran else '-',file=sys.stderr)")
ck "G4 asiancup 2023: Iran tops C fa=ایران 3wins (the 385 contract)" "$D"

# ============ P1-P5: DOM hygiene at 390x844 ============
fresh() {
  agent-browser close --all >/dev/null 2>&1
  agent-browser open "$BASE$1" >/dev/null 2>&1
  agent-browser set viewport 390 844 >/dev/null 2>&1
  agent-browser errors --clear >/dev/null 2>&1
  agent-browser console --clear >/dev/null 2>&1
  sleep 3
}
hygiene() {
  local ERR CON SW CW H1="$2"
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  local OK=1
  [ -z "$ERR" ] || OK=0
  [ "$CON" = "0" ] || OK=0
  [ "$SW" = "$CW" ] || OK=0
  if [ -n "$H1" ]; then
    local H=$(agent-browser eval "document.querySelector('h1') ? document.querySelector('h1').innerText : ''" 2>/dev/null | tr -d '"')
    case "$H" in *"$H1"*) ;; *) OK=0 ;; esac
  fi
  ck "P $1 (page-errors=0 console-errors=0 scrollW=cw=390${H1:+ h1~$H1})" "$OK"
}
fresh "/"
hygiene "P1 home" ""
fresh "/league/dfbpokal"
hygiene "P2 /league/dfbpokal" "جام حذفی آلمان"
fresh "/league/asiancup"
hygiene "P3 /league/asiancup" "جام ملت‌های آسیا"
fresh "/match/5750685"
hygiene "P4 /match/5750685" "پروسن مونستر"
fresh "/league/pl"
hygiene "P5 /league/pl" "پریمیرلیگ انگلیس"

echo "=== result ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "DOMPROOF 387 OK" || echo "DOMPROOF 387 INCOMPLETE"
