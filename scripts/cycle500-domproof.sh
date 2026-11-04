#!/usr/bin/env bash
# cycle500-domproof.sh — born cycle 500: harvest batch 42 (the ENG tranche,
# the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT —
# ENG 2 verified standing articles vs ESP 0 club anchors). Sections:
# A in-repo byte-landing · B the live ±7 feed (zero raw leaks + the renders
# with the permanent spread, reported-not-pinned) · C the visible DOM at
# 390×844 on the witness team pages (dynamic ids, the c493-battery lesson)
# + the fresh-home mount-gate.
BASE=http://localhost:3000
AB="agent-browser"
OUT=/tmp/c500-domproof.log
: > "$OUT"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "PASS $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 :: ${2:-}"; }
# agent-browser eval prints a JSON-QUOTED escaped string — decode twice.
abjson() { python3 -c "
import json,sys
s=sys.stdin.read().strip()
try:
    d=json.loads(s)
    if isinstance(d,str): d=json.loads(d)
    print(json.dumps(d, ensure_ascii=False))
except Exception: print('{}')" 2>/dev/null; }
abfield() { python3 -c "
import json,sys
s=sys.stdin.read().strip()
try:
    d=json.loads(s)
    if isinstance(d,str): d=json.loads(d)
    print(d.get('$1',''))
except Exception: print('')" 2>/dev/null; }

echo "== A. in-repo byte-landing =="
grep -q '"frome town": "فروم تاون",' src/lib/leagues.ts \
  && ok "A1 the frome-town key byte-exact in TEAM_FA" || bad "A1" "missing"
grep -q '"whitby": "ویتبای تاون",' src/lib/leagues.ts \
  && ok "A2 the whitby key byte-exact in TEAM_FA (the anchor title's OWN ویتبای spelling)" || bad "A2" "missing"
grep -q "cycle-500: batch 42 — the ENG tranche" src/lib/leagues.ts \
  && ok "A3 the batch-42 block comment present" || bad "A3" "missing"
grep -q "matches:v46:" src/lib/fotmob.ts && ! grep -q "matches:v45:" src/lib/fotmob.ts \
  && ok "A4 the cache constant v46 (v45 purged)" || bad "A4" "cache constant"
grep -q "cycle-500: v46 — harvest batch 42" src/lib/fotmob.ts \
  && ok "A5 the cache comment-chain v46 line present (the 487 lesson: chain + constant)" || bad "A5" "chain line"
DK=$(python3 -c "
import re
src=open('src/lib/leagues.ts',encoding='utf-8').read()
m=re.search(r'const TEAM_FA: Record<string, string> = \{(.*?)\n\};', src, re.S)
keys=re.findall(r'\"((?:[^\"\\\\]|\\\\.)+)\":\s*\"', m.group(1))
dups=sorted({k for k in keys if keys.count(k)>1})
print(len(dups))")
[ "$DK" = "0" ] && ok "A6 zero TEAM_FA key duplicates" || bad "A6" "dups=$DK"

echo "== B. the live ±7 feed =="
RES=$(python3 - << 'PYEOF'
import json, subprocess, urllib.parse
BASE="http://localhost:3000"
UA=("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
def fetch(u):
    return json.loads(subprocess.run(["curl","-s","--max-time","40","-A",UA,u],
        capture_output=True,text=True,timeout=60).stdout)
RAWS=["Frome Town","Whitby"]
FA={"frome town":"فروم تاون","whitby":"ویتبای تاون"}
leak=0; hits=0; per={}; tids={}
for o in range(-7,8):
    d=fetch(f"{BASE}/api/matches?offset={o}")
    for g in d.get("groups",[]):
        for m in g.get("matches",[]):
            for side in ("home","away"):
                t=m.get(side) or {}
                nm=t.get("fa") or t.get("name") or ""
                if nm in RAWS:
                    leak+=1
                elif nm in FA.values():
                    hits+=1
                    per[nm]=per.get(nm,0)+1
                    if nm not in tids: tids[nm]=t.get("id")
print(f"leak={leak} hits={hits} per={json.dumps(per,ensure_ascii=False)} tids={json.dumps(tids,ensure_ascii=False)}")
PYEOF
)
echo "   $RES"
L=$(echo "$RES" | grep -oE "leak=[0-9]+" | cut -d= -f2)
H=$(echo "$RES" | grep -oE "hits=[0-9]+" | cut -d= -f2)
PF=$(echo "$RES" | sed "s/.*per=//" | sed "s/ tids=.*//")
MINNAME=$(echo "$PF" | python3 -c "
import json,sys
try: d=json.load(sys.stdin); print(min(d.values()) if d else 0)
except Exception: print(0)")
[ "$L" = "0" ] && ok "B1 zero batch-42 raw literals anywhere in the ±7 feed" || bad "B1 raw leak" "$L"
[ "$H" -ge 6 ] && [ "$MINNAME" = "3" ] && ok "B2 the PERMANENT spread (reported, not pinned — the 477 form): hits=$H min-per-club=$MINNAME (فروم تاون + ویتبای تاون)" || bad "B2 spread" "hits=$H min=$MINNAME"
TIDF=$(echo "$RES" | sed "s/.*tids=//" | python3 -c "import json,sys;print(json.load(sys.stdin).get('فروم تاون',''))")
TIDW=$(echo "$RES" | sed "s/.*tids=//" | python3 -c "import json,sys;print(json.load(sys.stdin).get('ویتبای تاون',''))")
[ -n "$TIDF" ] && [ -n "$TIDW" ] && ok "B3 the witness team ids discovered live: فروم تاون=$TIDF ویتبای تاون=$TIDW" || bad "B3 tids" "f=$TIDF w=$TIDW"

echo "== C. the visible DOM (agent-browser 390×844) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
for PAIR in "فروم تاون:$TIDF" "ویتبای تاون:$TIDW"; do
  NAME="${PAIR%%:*}"; TID="${PAIR##*:}"
  $AB console --clear >/dev/null 2>&1
  $AB open "$BASE/team/$TID" >> "$OUT" 2>&1
  sleep 3
  DOM=$($AB eval "(()=>{const h=document.querySelector('h1');const de=document.documentElement;return JSON.stringify({h1:h?h.innerText.trim():'',sw:de.scrollWidth,vw:window.innerWidth})})()" 2>/dev/null | abjson)
  H1=$(echo "$DOM" | abfield h1); SW=$(echo "$DOM" | abfield sw); VW=$(echo "$DOM" | abfield vw)
  [ "$H1" = "$NAME" ] && ok "C-$NAME /team/$TID h1 Persian byte-exact: «$H1»" || bad "C-$NAME h1" "got=$H1 want=$NAME"
  [ "$SW" = "390" ] && [ "$VW" = "390" ] && ok "C-$NAME viewport scrollW=390 innerW=390" || bad "C-$NAME viewport" "sw=$SW vw=$VW"
  CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
  PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
  [ "$CE" = "0" ] && [ "$PE" = "0" ] && ok "C-$NAME console 0 + page errors 0" || bad "C-$NAME console" "console=$CE page=$PE"
done
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >> "$OUT" 2>&1
sleep 2
CE2=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE2" = "0" ] && ok "D1 the fresh-home mount-gate clean (console 0)" || bad "D1 console" "$CE2"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
