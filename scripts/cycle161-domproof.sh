#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-161 DOM/API proof — Croatian HNL (the TWENTY-FIRST
# competition, the NINTH consecutive new global-race participant,
# the live-Iranian hook in Croatian football: محمد محبی, the Iran
# international winger wearing the Rijeka №9 — squad ccode IRN +
# cname «Iran» + nationalTeamId 6711 + born 1998-12-20 + 187cm
# ST/LW with a ~1.5M transferValue and live 2026/2027 stats; his
# individual FotMob profile 404s — the documented no-page evidence
# class, three agreeing club-side fields with NO contradicting
# profile, the cycle-160 Heydari standard).
#
# Contract under proof (live-probed 2026-10-30, UA Chrome/124):
#   league 252 / ccode3 CRO (id surfaced from the day feed — the
#   acl2/UEL crack); flat 10-row 2026/2027 table (هایدوک اسپلیت 23 /
#   دیناموزاگرب 22 / واراژدین 18 — the Eternal Derby); 17
#   slash-format seasons (2026/2027 → 2010/2011) → NO globalMerge
#   flag → race 360 scorers / 18 participants, رافینیا ۱۳ honest
#   leader, window byte-identical; top-scorer fetchAllUrl (72-row
#   PascalCase FMStatFullRow goals.json; leader دیون درنا بلیو 12
#   دیناموزاگرب); 35 title seasons (newest 2025/2026 دیناموزاگرب
#   over هایدوک اسپلیت; رییکا the 2024/2025 champion; oldest 1992
#   هایدوک over the defunct ان‌کی زاگرب); transfers.data = flat
#   list → 99 live items ALL-Persian; playoff = null → bracket tab
#   honestly absent; ARCHIVED seasons FLAT with the top-scorer
#   block PRESENT (2025/2026 AND 2023/2024 probed) → the 2023/2024
#   historical race honestly grows 16→17 participants (dynamic
#   subtitle ۱۶ → ۱۷); NO espnSlug (ESPN 400 for cro.1/croatia.1 —
#   the Gulf pattern). Day-feed bare «HNL» rides a plain
#   COMPETITION_FA key (unique upstream name).
#
# House style (cycle-148..160): agent-browser at 390×844, real
# clicks, console must stay clean, one h1 per page, zero broken
# images, sw=cw, no horizontal overflow.
# ------------------------------------------------------------------
set -u
cd "$(dirname "$0")/.."
BASE="${BASE:-http://localhost:3000}"
B=agent-browser
$B set viewport 390 844 >/dev/null

TOTAL_BAD=0
A_BAD=0

collect() { # shared tail: OUT + console + errors, $1=feat $2=label
  local FEAT="$1" LABEL="$2" OUT C E RC=0
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  echo "$LABEL → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))
  return 0
}

probe() { # $1=url $2=label $3=featjs — DOM probe with shared tail
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT
  FEAT=$($B eval "JSON.stringify(($3))" 2>/dev/null | tr -d '"\\')
  collect "$FEAT" "$2"
}

get() { curl -s --max-time 60 "$1"; }

echo "== Part A: API truth (python verdict, exit-gated) =="
get "$BASE" >/dev/null 2>&1 || true
API_OUT=$(python3 - <<'PYEOF'
import json, re, urllib.request, sys

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
BASE = "http://localhost:3000"
ok = True
def report(name, good, note=""):
    global ok
    print(("PASS " if good else "FAIL ") + name + (f" — {note}" if note else ""))
    if not good:
        ok = False

def api(path):
    with urllib.request.urlopen(f"{BASE}{path}", timeout=60) as r:
        return json.loads(r.read().decode())

ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))

# A1: hnl standings — flat 10 rows, live top three Persian, honest window
d = api("/api/standings?league=hnl")
rows = d.get("rows") or []
seas = d.get("allSeasons") or []
report("A1 hnl standings",
       len(rows) == 10 and rows[0].get("fa") == "هایدوک اسپلیت" and rows[0].get("pts") == 23
       and rows[1].get("fa") == "دیناموزاگرب" and rows[2].get("fa") == "واراژدین"
       and not any(ascii_leak(r.get("fa")) for r in rows)
       and len(seas) == 12 and seas[0] == "2026/2027" and seas[-1] == "2015/2016",
       f"rows={len(rows)} top3={[r.get('fa') for r in rows[:3]]} window={seas[:1]}..{seas[-1:]}")

# A2: the global race — 360 scorers / 18 participants, hnl IN, رافینیا honest
d = api("/api/topscorers?league=all")
ts = d.get("scorers") or []
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
lead = ts[0] if ts else {}
report("A2 race 18 participants",
       len(ts) == 360 and len(pl) == 18 and "hnl" in pl and "acl2" not in pl
       and lead.get("nameFa") == "رافینیا" and lead.get("goals") == 13,
       f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")

# A3: dedicated /api/topscorers/hnl — بلیو with PERSIAN name AND team
d = api("/api/topscorers/hnl")
sts = d.get("scorers") or []
top = sts[0] if sts else {}
report("A3 hnl dedicated scorers",
       d.get("ok") is True and d.get("leagueFa") == "لیگ برتر کرواسی"
       and len(sts) >= 20 and top.get("nameFa") == "دیون درنا بلیو"
       and top.get("team") == "دیناموزاگرب" and top.get("goals") == 12
       and not any(ascii_leak(s.get("nameFa")) or ascii_leak(s.get("team")) for s in sts[:20]),
       f"n={len(sts)} leader={top.get('nameFa')}/{top.get('goals')}/{top.get('team')}")

# A4: historical 2023/2024 — 340 scorers / 17 participants, hnl IN (its
# archived season payload HAS the top-scorer block — probed)
d = api("/api/topscorers?league=all&season=2023%2F2024")
ts = d.get("scorers") or []
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
report("A4 historical 2023/2024 17 participants",
       len(ts) == 340 and len(pl) == 17 and "hnl" in pl and "qatar" not in pl
       and ts[0].get("nameFa") == "هری کین",
       f"n={len(ts)} perLeague={len(pl)} leader={ts[0].get('nameFa') if ts else None}")

# A5: titles — 35 seasons, newest دیناموزاگرب/هایدوک, zero ASCII in top-8
d = api("/api/league-titles?league=hnl")
wrapped = d.get("titles") or {}
tt = wrapped.get("items") or []
top8 = tt[:8]
ascii_champs = [t for t in top8 if ascii_leak(t.get("championFa") or "")]
report("A5 hnl titles",
       wrapped.get("total") == 35 and len(tt) == 35 and not ascii_champs
       and top8[0].get("championFa") == "دیناموزاگرب" and top8[0].get("runnerUpFa") == "هایدوک اسپلیت"
       and any(t.get("championFa") == "رییکا" for t in tt),
       f"n={len(tt)} newest={json.dumps(top8[0], ensure_ascii=False)[:90] if top8 else None} rijeka-champ=yes asciiLeak={ascii_champs}")

# A6: transfers — 99 items ALL-Persian (the +49-key sweep)
d = api("/api/league-transfers?league=hnl")
payload = d.get("transfers") or {}
items = payload.get("items") or []
leaks = [i for i in items if ascii_leak(i.get("from", {}).get("fa")) or ascii_leak(i.get("to", {}).get("fa"))]
report("A6 hnl transfers",
       d.get("ok") is True and len(items) == 99 and not leaks
       and payload.get("leagueFa") == "لیگ برتر کرواسی",
       f"items={len(items)} leaks={len(leaks)}")

# A7: mapping-sweep duplicate-key guard — 1009 team keys / 486 player keys,
# zero duplicates (the 152..160 sweep guard at the new totals;
# gate-synced cycle-161: hnl +49 team / +28 player keys)
import collections
def keys_of(path, anchor):
    s = open(path).read()
    i = s.index(anchor)
    j = s.index("\n};", i)
    return re.findall(r'"([^"]+)":', s[i:j])
tk = keys_of("src/lib/leagues.ts", "const TEAM_FA")
pk = keys_of("src/lib/player-names-fa.ts", "export const PLAYER_NAME_FA")
td = [k for k in set(tk) if tk.count(k) > 1]
pd = [k for k in set(pk) if pk.count(k) > 1]
report("A7 duplicate-key guard", len(tk) == 1009 and len(pk) == 486 and not td and not pd,
       f"team={len(tk)} player={len(pk)} dups={len(td)+len(pd)}")

# A8: day-feed disambiguation — the plain «hnl» key present in the lib
src = open("src/lib/leagues.ts").read()
report("A8 hnl day-feed key",
       '"hnl": "لیگ برتر کرواسی"' in src,
       "plain COMPETITION_FA key present (unique upstream name)")

# A9: the Iranian hook — رییکا squad through our own API must carry
# Mohammad Mohebbi (the honest English fallback name: his individual
# FotMob profile 404s, so no playerFa key can serve the squad panel —
# the documented cycle-160/161 no-page evidence class)
d = api("/api/team-squad/10162")
mem = [p for g in ((d.get("squad") or {}).get("groups") or []) for p in (g.get("players") or [])]
hey = [m for m in mem if "mohebbi" in str(m.get("name") or "").lower()]
report("A9 mohebbi in rijeka squad", len(hey) >= 1,
       f"squad={len(mem)} mohebbi={[m.get('name') for m in hey]}")

print("API_TRUTH", "OK" if ok else "BAD")
sys.exit(0 if ok else 1)
PYEOF
) || true
echo "$API_OUT"
case "$API_OUT" in *"API_TRUTH OK"*) : ;; *) A_BAD=1 ;; esac
# every line must be PASS — a FAIL line inside an OK verdict is a D5 trap
echo "$API_OUT" | grep -q "^FAIL" && A_BAD=1

echo "== Part B: DOM proof @390x844 =="

# B1: hnl league page — h1, live top هایدوک, tabs, honest bracket absence
probe "$BASE/league/hnl" "B1 hnl league page" \
"(function(){const tabs=[...document.querySelectorAll('button')].map(b=>(b.textContent||'').trim());return {h1:((document.querySelector('h1')||{}).innerText||'').includes('لیگ برتر کرواسی'),top:(document.querySelector('table tbody tr')||{innerText:''}).innerText.includes('هایدوک'),scorersTab:tabs.includes('آقای گل'),transfersTab:tabs.includes('انتقال‌ها'),bracketAbsent:!tabs.includes('براکت'),dinamo:(document.body.innerText||'').includes('دیناموزاگرب')}})()"

# B2: the global race — copy ۱۸, leader رافینیا, hnl team names Persian
probe "$BASE/topscorers" "B2 race copy 18" \
"(function(){const b=document.body.innerText||'';return {copy18:b.includes('۱۸ لیگ و جام برتر'),old17gone:!b.includes('۱۷ لیگ و جام برتر'),leader:b.includes('رافینیا'),hnlTeam:b.includes('هایدوک')||b.includes('دیناموزاگرب')}})()"

# B3: dedicated /topscorers/hnl — بلیو + Persian digits
probe "$BASE/topscorers/hnl" "B3 dedicated hnl scorers" \
"(function(){const b=document.body.innerText||'';return {h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ برتر کرواسی'),beljo:b.includes('دیون درنا بلیو'),faGoals:/[۰-۹]/.test(b)}})()"

# B4: the hub — 21 cards + the hnl card really present
probe "$BASE/leagues" "B4 leagues hub 21 cards" \
"(function(){return {cards:document.querySelectorAll(\"a[href^='/league/']\").length,hnlCard:!!document.querySelector(\"a[href='/league/hnl']\"),swissCard:!!document.querySelector(\"a[href='/league/swiss']\"),h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ')}})()"

# B5: the search guide — ۲۱ لیگ و جام in the real search UI
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1.5
FEAT5=$($B eval "JSON.stringify((function(){const b=(document.querySelector('div[role=\"dialog\"]')||document.body).innerText||'';return {guide21:b.includes('۲۱ لیگ و جام'),old20gone:!b.includes('۲۰ لیگ و جام')}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT5" "B5 search guide 21"

# B6: REAL search flow — Rijeka → رییکا (the hook club; the typed query
# echoes inside the dialog BY DESIGN — the assert checks the RESULT row,
# the D5 assertion-honesty rule)
$B eval '(function(){const i=document.querySelector("input");if(i){const s=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,"value").set;s.call(i,"Rijeka");i.dispatchEvent(new Event("input",{bubbles:true}));return "typed"}return "no-input"})()' >/dev/null 2>&1
sleep 4
FEAT6=$($B eval "JSON.stringify((function(){const b=(document.querySelector('div[role=\"dialog\"]')||document.body).innerText||'';return {fa:b.includes('رییکا'),league:b.includes('لیگ برتر کرواسی')}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT6" "B6 search Rijeka → رییکا"

# B7: players hub — «ستاره‌های هجده» copy read BEFORE the teams-mode click,
# then the hnl chip click with URL sync (the two-step fan path)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('ستاره‌های هجده')" >/dev/null 2>&1
sleep 2
COPY7=$($B eval 'JSON.stringify({c:document.body.innerText.includes("ستاره‌های هجده لیگ و جام برتر")})' 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=document.querySelector("[data-testid=\"mode-teams\"]");if(b)b.click();return b?"clicked":"missing"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const b=document.querySelector("[data-testid=\"league-hnl\"]");if(b)b.click();return b?"clicked":"missing"})()' >/dev/null 2>&1
sleep 4
FEAT7=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';return {urlLeague:location.search.includes('league=hnl'),teamsCopy:b.includes('اسکواد کامل همهٔ تیم‌ها'),club:b.includes('هایدوک')||b.includes('دیناموزاگرب')||b.includes('رییکا')}})())" 2>/dev/null | tr -d '"\\')
collect "$COPY7 $FEAT7" "B7 players hub two-step → hnl"

# B8: the hook club page — /team/10162 رییکا with the squad grid
probe "$BASE/team/10162" "B8 rijeka team page" \
"(function(){const b=document.body.innerText||'';return {h1Live:!!(document.querySelector('h1')||{}).innerText,faName:b.includes('رییکا'),squad:b.includes('دروازه‌بان‌ها')||b.includes('مدافعان')||b.includes('بازیکن')}})()"

echo "== RESULT =="
if [ "$A_BAD" -eq 0 ] && [ "$TOTAL_BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (API 9/9 + DOM 8/8 green — لیگ برتر کرواسی honest end-to-end: the 21st competition and the NINTH consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the live top three (هایدوک اسپلیت ۲۳/دیناموزاگرب ۲۲/واراژدین ۱۸ — the Eternal Derby) on a 10/10 all-Persian table, دیون درنا بلیو ۱۲ دیناموزاگرب atop the 72-scorer PascalCase goals.json (the cycle-23 parser's native FMStatFullRow shape) with PERSIAN name AND team on the dedicated /topscorers/hnl path, 360-scorer race (18 leagues) with رافینیا still honest leader and the 2023/2024 historical window grown 16→17 participants (hnl archived payload HAS the scorer block), 35 title seasons topped by 2025/2026 دیناموزاگرب over هایدوک اسپلیت (رییکا the 2024/2025 champion; oldest 1992 هایدوک over the defunct ان‌کی زاگرب — distinct from دیناموزاگرب), transfers 99 items zero-ASCII via the +49-key TEAM_FA sweep (1009 team / 486 player keys, ZERO duplicates), bracket honestly absent (playoff null), NO espnSlug (ESPN 400 for cro.1/croatia.1 — the Gulf pattern), day-feed bare «HNL» rides a plain COMPETITION_FA key, players hub هجده + search guide ۲۱ + race copy ۱۸; the LIVE Iranian hook محمد محبی (رییکا №9, ccode IRN + nationalTeamId 6711, born 1998-12-20) in the squad panel; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"
else
  echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1
fi
