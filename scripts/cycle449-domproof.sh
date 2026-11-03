#!/bin/bash
# cycle449-domproof.sh — the byte-drift fix (Fix cycle 449)
#
# The work: the c449 fold-probe (scripts/c449-bytedrift.py) swept the live
# ±7 window (3948 rows / 1865 distinct = the documented 448 census) and
# found EXACTLY ONE byte-drift: the feed serves «Al Jeel» (SPACE) while the
# cycle-140 capture keyed it hyphenated («al-jeel») — teamFa's exact-key
# lookup never matched, so every Saudi First Division row leaked raw. Fix:
# the live-literal key «al jeel» added beside the dead capture (the file's
# own defensive-variant convention, 180 same-value groups; render stays the
# file's own «الجیل», same club/league/country — the 389 identity rule),
# matches cache v14 → v15 per the standing rule (fresh cold window),
# patrol B4 re-anchored 1865 → 1864 (EXACTLY −1, the loud-pool rule) + B16
# the fix witness.
#
# This domproof: the source bytes + the served API across the WHOLE ±7
# window (3 live rows: 20261027 / 20261102 / 20261108) + the visible DOM on
# the witness day (offset −1 = 2026-11-02), 390×844, console clean + the
# fresh home mount-gate hold.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c449-domproof-results.txt
: > "$OUT"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1" >> "$OUT"; echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 :: $2" >> "$OUT"; echo "FAIL $1 :: $2"; }
AB="agent-browser"

abf() {
  python3 - "$1" "$2" <<'PYEOF'
import json, sys
s = sys.argv[1].strip()
if s.startswith('"') and s.endswith('"'):
    s = s[1:-1]
s = s.replace('\\"', '"')
print(json.loads(s)[sys.argv[2]])
PYEOF
}

echo "== A. the fix source bytes + the served API =="
KEYN=$(python3 - <<'PY'
import re
s = open('src/lib/leagues.ts', encoding='utf-8').read()
m = re.search(r'const TEAM_FA: Record<string, string> = \{(.*?)\n\};', s, re.S)
body = m.group(1)
keys = re.findall(r'"((?:[^"\\]|\\.)*)"\s*:', body)
print(keys.count("al jeel"))
PY
)
[ "$KEYN" = "1" ] && ok "A1 the live-literal key «al jeel» present exactly once in TEAM_FA" || bad "A1 key count" "$KEYN"
V=$(grep -o '"al jeel": "[^"]*"' src/lib/leagues.ts | head -1)
[ "$V" = '"al jeel": "الجیل"' ] && ok "A2 the key→value pair byte-exact (value = the file's own «الجیل»)" || bad "A2 pair bytes" "$V"
OLDN=$(python3 - <<'PY'
import re
s = open('src/lib/leagues.ts', encoding='utf-8').read()
m = re.search(r'const TEAM_FA: Record<string, string> = \{(.*?)\n\};', s, re.S)
body = m.group(1)
keys = re.findall(r'"((?:[^"\\]|\\.)*)"\s*:', body)
print(keys.count("al-jeel"))
PY
)
[ "$OLDN" = "1" ] && ok "A3 the hyphenated capture STAYS (defensive-variant convention)" || bad "A3 old key" "$OLDN"
CACHE=$(grep -o 'matches:v[0-9]*' src/lib/fotmob.ts | head -1)
[ "$CACHE" = "matches:v15" ] && ok "A4 matches cache bumped to v15 (the standing rule)" || bad "A4 cache" "$CACHE"

echo "== B. the served API across the whole ±7 window (counted from the feed) =="
API=$(python3 - <<'PY'
import json, subprocess
BASE="http://localhost:3000"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
fa=0; raw=0; days=set()
for d in range(-7,8):
    try:
        out=subprocess.run(["curl","-s","--max-time","40","-A",UA,f"{BASE}/api/matches?offset={d}"],capture_output=True,text=True,timeout=60).stdout
        p=json.loads(out)
    except Exception:
        continue
    for g in p.get("groups",[]):
        for m in g.get("matches",[]):
            for side in ("home","away"):
                t=m.get(side) or {}
                f=(t.get("fa") or "").strip(); n=(t.get("name") or "").strip()
                if f=="الجیل":
                    fa+=1; days.add(p.get("date"))
                elif not f and n.lower() in ("al jeel","al-jeel"):
                    raw+=1
print(json.dumps({"fa":fa,"raw":raw,"days":sorted(days)}))
PY
)
FAN=$(echo "$API" | python3 -c "import json,sys;print(json.load(sys.stdin)['fa'])")
RAWN=$(echo "$API" | python3 -c "import json,sys;print(json.load(sys.stdin)['raw'])")
DAYS=$(echo "$API" | python3 -c "import json,sys;print(','.join(json.load(sys.stdin)['days']))")
[ "$FAN" -ge 1 ] && [ "$RAWN" = "0" ] && ok "B1 ±7 window: $FAN «الجیل» renders, 0 raw literals (witness days: $DAYS)" || bad "B1 window" "fa=$FAN raw=$RAWN"

echo "== C. the visible DOM (agent-browser 390×844, the witness day) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/?date=2026-11-02" >> "$OUT" 2>&1
sleep 3
DOM=$($AB eval "(()=>{const b=document.body.innerText;const de=document.documentElement;return JSON.stringify({fa:b.includes('الجیل'),raw:b.includes('Al Jeel'),sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
FAV=$(abf "$DOM" fa); RAWV=$(abf "$DOM" raw); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: fa=$FAV raw=$RAWV scrollW=$SW innerW=$VW h1=$H1"
[ "$FAV" = "True" ] && ok "C1 «الجیل» visible in the witness-day DOM at 390×844" || bad "C1 fa visible" "$FAV"
[ "$RAWV" = "False" ] && ok "C2 zero «Al Jeel» raw literal anywhere in the body text" || bad "C2 raw leak" "$RAWV"
[ "$SW" = "390" ] && [ "$VW" = "390" ] && ok "C3 scrollW=390 innerW=390 (no horizontal overflow)" || bad "C3 scroll" "sw=$SW vw=$VW"
[ "$H1" = "True" ] && ok "C4 h1 present" || bad "C4 h1" "$H1"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE" = "0" ] && ok "C5 console errors 0" || bad "C5 console" "$CE"
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "C6 page errors 0" || bad "C6 page errors" "$PE"

echo "== D. default home fresh load (the 434 mount-gate still clean) =="
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >> "$OUT" 2>&1
sleep 3
HD=$($AB eval "(()=>{const de=document.documentElement;return JSON.stringify({h1:!!document.querySelector('h1'),sw:de.scrollWidth})})()" 2>/dev/null)
H1H=$(abf "$HD" h1); SWH=$(abf "$HD" sw)
[ "$H1H" = "True" ] && ok "D1 home h1 present" || bad "D1 h1" "$H1H"
[ "$SWH" = "390" ] && ok "D2 home scrollW=390" || bad "D2 scroll" "$SWH"
CE2=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE2" = "0" ] && ok "D3 fresh home console errors 0 (the 434 mount-gate hold)" || bad "D3 console" "$CE2"
PE2=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE2" = "0" ] && ok "D4 fresh home page errors 0" || bad "D4 page errors" "$PE2"

echo "== result =="
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
