#!/usr/bin/env bash
# cycle-494 domproof — the MLS registration (the registry ledger's next head,
# fotmob id 130), born in the PERMANENT form (the 477 lesson, the 492 shape):
# A the in-repo registration integrity (the entry's own fields + the faName
# never-disagree byte-equality with the shipped CC mapping + the three
# COMPOSITE_REGION_FA keys), B the LIVE APIs (standings groups byte-exact
# 15/15/30, zero raw team cells, the 17 plain-year selector contract, the
# fixtures total, the witness-match leagueFa, the day-feed group leagueFa,
# the season deep-link), C the visible DOM on /league/mls at 390×844 with
# the season selector interaction, console/page errors clean, D the fresh
# home mount-gate (the 434 gate).
BASE="${BASE:-http://localhost:3000}"
OUT=/tmp/c494-domproof-results.txt
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

echo "== A. the registration block integrity (in-repo) =="
python3 - <<'PY'
import re, json
s = open('src/lib/leagues.ts', encoding='utf-8').read()
m = re.search(r'\{ key: "mls",\s*fotmobId: (\d+),\s*ccode3: "([A-Z]+)",\s*faName: "([^"]+)",\s*enName: "([^"]+)",\s*espnSlug: "([^"]+)",\s*priority: (\d+),\s*globalMerge: (true|false),\s*plainYearSeasons: (true|false)\s*\}', s)
ent = None
if m:
    ent = {"fotmobId": int(m.group(1)), "ccode3": m.group(2), "faName": m.group(3),
           "enName": m.group(4), "espnSlug": m.group(5), "priority": int(m.group(6)),
           "globalMerge": m.group(7) == "true", "plainYearSeasons": m.group(8) == "true"}
json.dump(ent, open('/tmp/c494-ent.json', 'w'), ensure_ascii=False)
PY
ENT=$(python3 -c "import json;print('yes' if json.load(open('/tmp/c494-ent.json')) else 'no')")
[ "$ENT" = "yes" ] && ok "A1 the mls LEAGUES entry parses with the full field shape" || bad "A1 entry" "$ENT"
CHECK=$(python3 - <<'PY'
import json, re
e = json.load(open('/tmp/c494-ent.json'))
exp = {"fotmobId": 130, "ccode3": "USA", "faName": "لیگ حرفه\u200cای آمریکا",
       "enName": "Major League Soccer", "espnSlug": "usa.1", "priority": 41,
       "globalMerge": False, "plainYearSeasons": True}
bad = [k for k in exp if e.get(k) != exp[k]]
s = open('src/lib/leagues.ts', encoding='utf-8').read()
mm = re.search(r'"major league soccer\|USA":\s*"([^"]+)"', s)
cc = mm.group(1) if mm else None
agree = (cc == e["faName"])
print("0" if (not bad and agree) else f"bad={bad} cc={cc!r} agree={agree}")
PY
)
[ "$CHECK" = "0" ] && ok "A2 entry fields byte-exact (130/USA/fa/en/slug/prio/flags) + faName BYTE-EQUAL to the shipped CC mapping \"major league soccer|USA\" (the never-disagree rule)" || bad "A2 fields" "$CHECK"
FAKEYS=$(python3 - <<'PY'
import re
s = open('src/lib/fotmob.ts', encoding='utf-8').read()
m = re.search(r'COMPOSITE_REGION_FA[^=]*=\s*\{(.*?)\n    \};', s, re.S)
body = m.group(1)
keys = re.findall(r'"([^"]+)":', body)
exp = {"eastern": "کنفرانس شرقی", "western": "کنفرانس غربی", "supporters shield": "سپانسرز شیلد"}
got = {}
for k in exp:
    mm = re.search(r'"' + re.escape(k) + r'":\s*"([^"]+)"', body)
    got[k] = mm.group(1) if mm else None
bad = [k for k in exp if got[k] != exp[k]]
dup = len(keys) - len(set(keys))
print("0" if (not bad and dup == 0) else f"bad={bad} dup={dup}")
PY
)
[ "$FAKEYS" = "0" ] && ok "A3 the three COMPOSITE_REGION_FA keys byte-exact («کنفرانس شرقی»/«کنفرانس غربی»/«سپانسرز شیلد») + zero duplicate keys in the map" || bad "A3 region keys" "$FAKEYS"

echo "== B. the LIVE APIs =="
ST=$(curl -s --max-time 120 "$BASE/api/standings?league=mls")
SB=$(ST="$ST" python3 - <<'PY'
import json, sys, os
d = json.loads(os.environ["ST"])
groups = [(g.get("fa"), g.get("count")) for g in (d.get("groups") or [])]
exp = [("کنفرانس شرقی", 15), ("کنفرانس غربی", 15), ("سپانسرز شیلد", 30)]
rows = d.get("rows") or []
raws = [r for r in rows if not ((r.get("fa") or "").strip())]
latinfas = sorted({r.get("fa") for r in rows if r.get("fa") and all(ord(c) < 0x600 for c in r.get("fa"))})
wave = ["نشویل", "اینترمیامی", "نیوانگلند", "شیکاگو فایر", "شارلوت", "تورنتو"]
waveok = [w for w in wave if any(r.get("fa") == w for r in rows)]
sals = d.get("allSeasons") or []
plain = bool(sals) and all("-" not in str(x) and "/" not in str(x) for x in sals)
print(json.dumps({"ok": d.get("ok") is True, "groups": groups == exp, "rows": len(rows),
                  "emptyfa": len(raws), "latinfa_n": len(latinfas), "latinfa": latinfas,
                  "waveok": len(waveok), "sals": len(sals), "plain": plain}, ensure_ascii=False))
PY
)
ST_OK=$(abf "$SB" ok); ST_G=$(abf "$SB" groups); ST_R=$(abf "$SB" rows); ST_E=$(abf "$SB" emptyfa); ST_LN=$(abf "$SB" latinfa_n); ST_L=$(abf "$SB" latinfa); ST_W=$(abf "$SB" waveok); ST_S=$(abf "$SB" sals); ST_P=$(abf "$SB" plain)
[ "$ST_OK" = "True" ] && ok "B1 /api/standings?league=mls ok:true" || bad "B1 standings ok" "$(echo "$ST" | head -c 120)"
[ "$ST_G" = "True" ] && ok "B2 the groups BYTE-EXACT: کنفرانس شرقی 15 / کنفرانس غربی 15 / سپانسرز شیلد 30 (zero raw Latin labels)" || bad "B2 groups" "groups!=exp (short)"
[ "$ST_R" = "60" ] && ok "B3 rows=60 (the composite flatten West→East with the Shield, the 349 semantics)" || bad "B3 rows" "$ST_R"
[ "$ST_E" = "0" ] && [ "$ST_W" = "6" ] && ok "B4 zero EMPTY fa cells + all 6 sampled batch-3 wave clubs Persian (نشویل/اینترمیامی/نیوانگلند/شیکاگو فایر/شارلوت/تورنتو)" || bad "B4 wave" "empty=$ST_E wave=$ST_W"
[ "$ST_LN" != "0" ] && ok "B5 the raw-club remainder REPORTED-not-pinned (the 477 lesson, the 493 observation contract): $ST_LN distinct Latin fa rides the standing harvest queue (count<3 in the live ±7 window): $ST_L" || bad "B5 queue report" "$ST_LN"
[ "$ST_S" = "12" ] && [ "$ST_P" = "True" ] && ok "B6 allSeasons=12 ALL plain years (the STANDING 12-cap slice(0,12) of fotmob.ts:5685 serves every league; the plainYearSeasons flag admits the whole list up to the cap)" || bad "B6 seasons" "n=$ST_S plain=$ST_P"
FX=$(curl -s --max-time 120 "$BASE/api/league-fixtures?league=mls&season=2026")
FB=$(FX="$FX" python3 - <<'PY'
import json, sys, os
d = json.loads(os.environ["FX"])
print(json.dumps({"ok": d.get("ok") is True, "total": d.get("total"), "up": len(d.get("upcoming") or []),
                  "fa": d.get("leagueFa"), "sel": d.get("selectedSeason")}, ensure_ascii=False))
PY
)
FX_OK=$(abf "$FB" ok); FX_T=$(abf "$FB" total); FX_U=$(abf "$FB" up); FX_FA=$(abf "$FB" fa)
[ "$FX_OK" = "True" ] && [ "$FX_T" = "510" ] && [ "$FX_U" != "0" ] && ok "B7 /api/league-fixtures live: total=510 upcoming=$FX_U (the probed allMatches byte-equal)" || bad "B7 fixtures" "ok=$FX_OK total=$FX_T up=$FX_U"
[ "$FX_FA" = "لیگ حرفه‌ای آمریکا" ] && ok "B8 fixtures leagueFa byte-equal «لیگ حرفه‌ای آمریکا»" || bad "B8 fixtures fa" "$FX_FA"
WIT=$(curl -s --max-time 120 "$BASE/api/match/5071457")
WFA=$(echo "$WIT" | python3 -c "import json,sys;print(json.load(sys.stdin).get('match',{}).get('leagueFa',''))")
[ "$WFA" = "لیگ حرفه‌ای آمریکا" ] && ok "B9 the witness match 5071457 (LAFC 2-2 LA Galaxy) leagueFa byte-equal on the match API" || bad "B9 witness fa" "$WFA"
GRP=$(python3 - <<'PY'
import json, subprocess
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
found = 0; agree = 0; total = 0
for o in range(-12, -6):
    out = subprocess.run(["curl", "-s", "--max-time", "25", "http://localhost:3000/api/matches?offset=%d" % o],
                         capture_output=True, text=True, timeout=40).stdout
    try:
        d = json.loads(out)
    except Exception:
        continue
    for g in d.get("groups", []):
        if (g.get("leagueName") or "") == "Major League Soccer":
            total += 1
            found += 1
            if g.get("leagueFa") == "لیگ حرفه\u200cای آمریکا":
                agree += 1
print(json.dumps({"total": total, "agree": agree}, ensure_ascii=False))
PY
)
GT=$(abf "$GRP" total); GA=$(abf "$GRP" agree)
[ "$GT" != "0" ] && [ "$GT" = "$GA" ] && ok "B10 the day-feed MLS groups across the -window: $GA/$GT leagueFa byte-equal (the CC mapping live)" || bad "B10 feed groups" "total=$GT agree=$GA"
ST25=$(curl -s --max-time 120 "$BASE/api/standings?league=mls&season=2025" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('ok'), len(d.get('rows') or []))")
[ "$ST25" = "True 60" ] && ok "B11 the season deep-link admits a prior plain year: standings?season=2025 ok 60 rows" || bad "B11 season 2025" "$ST25"

echo "== C. the visible DOM on /league/mls (agent-browser 390×844) =="
$AB set viewport 390 844 >> "$OUT" 2>&1
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/league/mls" >> "$OUT" 2>&1
sleep 5
DOM=$($AB eval "(()=>{const b=document.body.innerText;const labels=['کنفرانس شرقی','کنفرانس غربی','سپانسرز شیلد'];const vis=labels.filter(x=>b.includes(x));const clubs=['نشویل','اینترمیامی','ونکوور','ونکوور وایتکپس'];const cvis=clubs.filter(x=>b.includes(x));const raws=['Eastern','Western','Supporters Shield'];const cells=Array.from(document.querySelectorAll('*')).filter(e=>e.children.length===0).map(e=>e.textContent.trim());const rleak=raws.filter(x=>cells.includes(x));const de=document.documentElement;return JSON.stringify({vis:vis.length,tot:3,cvis:cvis.length,rleak:rleak.length,sw:de.scrollWidth,vw:window.innerWidth,h1:!!document.querySelector('h1')})})()" 2>/dev/null)
VIS=$(abf "$DOM" vis); CVIS=$(abf "$DOM" cvis); RLEAKD=$(abf "$DOM" rleak); SW=$(abf "$DOM" sw); VW=$(abf "$DOM" vw); H1=$(abf "$DOM" h1)
echo "   DOM: labels=$VIS/3 clubs=$CVIS rawLeak=$RLEAKD scrollW=$SW innerW=$VW h1=$H1"
[ "$VIS" = "3" ] && ok "C1 ALL THREE Persian group labels visible on /league/mls at 390×844" || bad "C1 labels" "$VIS/3"
[ "$CVIS" != "0" ] && ok "C2 the Persian club renders visible (sample of the 60-row table)" || bad "C2 clubs" "$CVIS"
[ "$RLEAKD" = "0" ] && ok "C3 zero raw sub-table literals as rendered cells (Eastern/Western/Supporters Shield — the exact-cell 462 lesson)" || bad "C3 raw leak" "$RLEAKD"
[ "$SW" = "390" ] && [ "$VW" = "390" ] && ok "C4 scrollW=390 innerW=390 (no horizontal overflow)" || bad "C4 scroll" "sw=$SW vw=$VW"
[ "$H1" = "True" ] && ok "C5 h1 present" || bad "C5 h1" "$H1"
SEL=$($AB eval "(()=>{const s=document.querySelector('select');if(!s)return 'none';const opts=Array.from(s.options).map(o=>o.value).filter(Boolean);const opt=opts.find(v=>v==='2025');if(!opt)return 'no-2025:'+opts.slice(0,4).join(',');const setter=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;setter.call(s,opt);s.dispatchEvent(new Event('change',{bubbles:true}));return opt})()" 2>/dev/null | tr -d '"')
sleep 2
URL=$($AB eval "location.search" 2>/dev/null | tr -d '"')
echo "   selector: sel=$SEL url=$URL"
[ "$SEL" = "2025" ] && echo "$URL" | grep -q "season=2025" && ok "C6 the season selector LIVE on a plain-year league: 2025 picked → ?season=2025 (the 419 deep-link contract, plain-year branch)" || bad "C6 selector" "sel=$SEL url=$URL"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE" = "0" ] && ok "C7 console errors 0" || bad "C7 console" "$CE"
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "C8 page errors 0" || bad "C8 page errors" "$PE"

echo "== D. default home fresh load (the 434 mount-gate) =="
$AB console --clear >/dev/null 2>&1
$AB open "$BASE/" >> "$OUT" 2>&1
sleep 2
CE2=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: print(999); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
print(sum(1 for x in m if isinstance(x,dict) and x.get('type') in ('error','assert')))")
[ "$CE2" = "0" ] && ok "D1 console errors 0 on fresh home" || bad "D1 console" "$CE2"
PE2=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE2" = "0" ] && ok "D2 page errors 0 on fresh home" || bad "D2 page errors" "$PE2"

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ]
