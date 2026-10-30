#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-183 bug-hunt — patrol of the 179-182 surfaces + honesty-of-absence
#
# The four surfaces added since the cycle-178 hunt (which covered 174-177):
#   179  per-league topscorers «کارت‌ها» block (the 174 sister pattern)
#   180  season selector on /topscorers/[leagueKey] (Salah/Haaland pins)
#   181  Belgian Pro League — 24th competition, Eckert 892709 (IRN hook)
#   182  season selector on /players stars mode (Kane historical race)
# Patrol only — ZERO src changes (the bug-hunt contract). Honesty-of-absence
# dimensions no prior gate covered together: the old-season cards omission
# (132 rule) on BOTH the API and the rendered page, the 2013/2014
# offered-but-dataless empty with NO fake error, and mas structural
# red-only (y=0) plus assists=0 on the 179-added block.
#
# Pinned live truth (probed 2026-10-30 ~08:2x-08:5x +08, UA Chrome/124,
# official start from the cycle-182 build):
#   /api/topscorers                     extra=={assists,cards,selectedSeason,
#                                       allSeasons} 400/20 sel=2026/2027
#                                       all=12 s0 Raphinha 696679 13g
#   /api/topscorers?season=2023/2024    380 scorers s0 Kane «هری کین»
#                                       بایرن‌مونیخ 36g pid=194165; assists=10
#                                       a0 pid=980381; cards ABSENT (132)
#   /api/topscorers?season=2013/2014    200 ok scorers=0 sel=2013/2014
#                                       cards ABSENT
#   /api/topscorers?season=bogus        400 (the 55 guard)
#   /api/topscorers/pl?2024%2F2025      s0 Salah «محمد صلاح» لیورپول 29g
#                                       pid=292462; 20 rows; assists=10;
#                                       cards ABSENT (old-season omission)
#   /api/topscorers/pl                  y=15 r=14 Janelt 688273 «ویتالی
#                                       یانلت» value=4; assists=10 a0 Rice
#                                       654096
#   /api/topscorers/belgium             leagueFa «لیگ بلژیک» 20 rows Eckert
#                                       892709 ccode=IRN rank=9 4g;
#                                       assists=10; cards y=15 r=15
#   /api/standings?league=belgium       18 rows top1 Gent 9991 «خنت»
#   /api/search                         q=اکرت/Eckert→892709; کین first
#                                       194165; Kane→194165; یانلت→688273
#   /players (DOM)                      selector 12 opts, «ستاره‌های بیست لیگ
#                                       و جام برتر», 400 player anchors
#   /topscorers/belgium (DOM)           لیگ بلژیک + Eckert anchor + دهندگان
#                                       + کارت‌ها + 40 anchors
#   /topscorers/pl?2024/2025 (DOM)      cards:false cr:false salah:true
#                                       selval=2024/2025 ass:true
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API patrol (10 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse, urllib.error
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
def code(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        return urllib.request.urlopen(req, timeout=30).getcode()
    except urllib.error.HTTPError as e:
        return e.code
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: current global race — 182 kept the route byte-untouched; full parity
try:
    d = get(BASE + "/api/topscorers")
    old = {"ok", "scorers", "perLeague", "updatedAt"}
    extra = set(d.keys()) - old
    s0 = (d.get("scorers") or [{}])[0]
    good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
        and len(d.get("scorers") or []) == 400 \
        and len(d.get("perLeague") or []) == 20 \
        and d.get("selectedSeason") == "2026/2027" \
        and len(d.get("allSeasons") or []) == 12 \
        and s0.get("playerId") == 696679 and s0.get("name") == "Raphinha"
    report("A1 current race parity", good,
           f"extra={sorted(extra)} sc={len(d.get('scorers') or [])} "
           f"pl={len(d.get('perLeague') or [])} s0={s0.get('name')}")
except Exception as e:
    report("A1 current race parity", False, repr(e))

# A2: historical race behind the 182 selector — Kane pin byte-exact
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    a = d.get("assists") or []
    # ADVANCED by cycle-186 (the in-gate-comment convention): the global
    # historical merge now CARRIES the season's own cards (y0 Iván Alejo
    # 17/640089 laliga, r0 Bonsu Baah 3/1452385 belgium — the 132 rule
    # retired end-to-end; the dataless 2013/2014 season keeps its honest
    # omission, pinned by A3 below).
    y0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    r0 = ((d.get("cards") or {}).get("red") or [{}])[0]
    good = d.get("selectedSeason") == "2023/2024" \
        and len(d.get("scorers") or []) == 380 \
        and s0.get("playerId") == 194165 and s0.get("name") == "Harry Kane" \
        and s0.get("nameFa") == "هری کین" and s0.get("team") == "بایرن‌مونیخ" \
        and s0.get("goals") == 36 \
        and len(a) == 10 and (a[0] or {}).get("playerId") == 980381 \
        and y0.get("name") == "Iván Alejo" and y0.get("value") == 17 \
        and y0.get("playerId") == 640089 \
        and r0.get("playerId") == 1452385
    report("A2 hist race Kane + own cards (186)", good,
           f"sel={d.get('selectedSeason')} s0={s0.get('name')}/{s0.get('goals')}g "
           f"ass={len(a)} y0={y0.get('playerId')}/{y0.get('value')} r0={r0.get('playerId')}/{r0.get('value')}")
except Exception as e:
    report("A2 hist race Kane + own cards (186)", False, repr(e))

# A3: offered-but-dataless season — honest 200-with-zero, cards ABSENT
try:
    q = urllib.parse.quote("2013/2014", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    good = d.get("ok") is True and d.get("selectedSeason") == "2013/2014" \
        and (d.get("scorers") or []) == [] and "cards" not in d
    report("A3 2013/2014 honest empty", good,
           f"sel={d.get('selectedSeason')} sc={len(d.get('scorers') or [])}")
except Exception as e:
    report("A3 2013/2014 honest empty", False, repr(e))

# A4: invalid season shape → 400 (the cycle-55 guard, global route)
try:
    try:
        get(BASE + "/api/topscorers?season=2023")
        report("A4 invalid season 400", False, "no error raised")
    except Exception as e:
        good = isinstance(e, urllib.error.HTTPError) and e.code == 400
        report("A4 invalid season 400", good, repr(e.__class__.__name__))
except Exception as e:
    report("A4 invalid season 400", False, repr(e))

# A5: the 180 surface — league topscorers OLD season: Salah pin. ADVANCED
# by cycle-185 (the in-gate-comment convention): the 132 old-season cards
# omission on the league route is LIFTED — the season-aware
# getLeagueCardLeaders serves each season's own card files (pl 2024/2025
# yellow Flynn Downes 844943/12, red Bruno Fernandes 422685/2); the
# global-merge boundary stays pinned by cycle185-domproof A7.
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers/pl?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    cy0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    cr0 = ((d.get("cards") or {}).get("red") or [{}])[0]
    good = d.get("leagueKey") == "pl" \
        and d.get("selectedSeason") == "2024/2025" \
        and len(d.get("scorers") or []) == 20 \
        and s0.get("playerId") == 292462 and s0.get("name") == "Mohamed Salah" \
        and s0.get("nameFa") == "محمد صلاح" and s0.get("team") == "لیورپول" \
        and s0.get("goals") == 29 \
        and len(d.get("assists") or []) == 10 \
        and cy0.get("playerId") == 844943 and cy0.get("value") == 12 \
        and cr0.get("playerId") == 422685 and cr0.get("value") == 2
    report("A5 pl old season Salah + own cards (185)", good,
           f"sel={d.get('selectedSeason')} s0={s0.get('name')}/{s0.get('goals')}g "
           f"y0={cy0.get('playerId')}/{cy0.get('value')} r0={cr0.get('playerId')}/{cr0.get('value')}")
except Exception as e:
    report("A5 pl old season Salah + own cards (185)", False, repr(e))

# A6: the 181 surface — belgium league-scoped: Eckert IRN hook + both kinds
try:
    d = get(f"{BASE}/api/topscorers/belgium")
    e = [r for r in d.get("scorers") or [] if r.get("playerId") == 892709]
    e = e[0] if e else {}
    c = d.get("cards") or {}
    good = d.get("leagueFa") == "لیگ بلژیک" \
        and len(d.get("scorers") or []) == 20 \
        and e.get("ccode") == "IRN" and e.get("rank") == 9 \
        and e.get("goals") == 4 and e.get("name") == "Dennis Eckert" \
        and len(d.get("assists") or []) == 10 \
        and len(c.get("yellow") or []) == 15 \
        and len(c.get("red") or []) == 15
    report("A6 belgium Eckert pin", good,
           f"rows={len(d.get('scorers') or [])} eckert={e.get('rank')}/{e.get('goals')}g "
           f"ccode={e.get('ccode')} y={len(c.get('yellow') or [])} r={len(c.get('red') or [])}")
except Exception as e:
    report("A6 belgium Eckert pin", False, repr(e))

# A7: the belgium portal table — 18 rows, Gent top (the 181 flat table)
try:
    d = get(f"{BASE}/api/standings?league=belgium")
    rows = d.get("rows") or []
    t0 = rows[0] if rows else {}
    good = len(rows) == 18 \
        and t0.get("teamId") == 9991 and t0.get("fa") == "خنت" \
        and len(d.get("scorers") or []) == 20
    report("A7 belgium table", good,
           f"rows={len(rows)} top={t0.get('fa')}/{t0.get('teamId')}")
except Exception as e:
    report("A7 belgium table", False, repr(e))

# A8: the search pool — two-way FA aliases ride the 166/171/177 folds
try:
    def search(q):
        return get(f"{BASE}/api/search?q={urllib.parse.quote(q)}").get("players") or []
    ids = lambda rs: [r.get("playerId") for r in rs]
    ack = search("اکرت"); ken = search("کین"); yan = search("یانلت")
    good = 892709 in ids(search("Eckert")) and 892709 in ids(ack) \
        and ids(ken)[:1] == [194165] and 194165 in ids(search("Kane")) \
        and 688273 in ids(yan)
    report("A8 search two-way pins", good,
           f"akert={ids(ack)} kane1={ids(ken)[:1]} yanelt={688273 in ids(yan)}")
except Exception as e:
    report("A8 search two-way pins", False, repr(e))

# A9: the 179 surface on the CURRENT season — cards block + Janelt pin +
# the 174 assists surface intact (Rice first)
try:
    d = get(f"{BASE}/api/topscorers/pl")
    c = d.get("cards") or {}
    ys = c.get("yellow") or []
    rs = c.get("red") or []
    j = [r for r in ys + rs if r.get("playerId") == 688273]
    j = j[0] if j else {}
    a = d.get("assists") or []
    good = len(ys) >= 10 and len(rs) >= 10 \
        and j.get("playerId") == 688273 and j.get("value") == 4 \
        and j.get("nameFa") == "ویتالی یانلت" \
        and len(a) == 10 and (a[0] or {}).get("playerId") == 654096
    report("A9 pl cards+assists", good,
           f"y={len(ys)} r={len(rs)} janelt={j.get('value')} "
           f"a0={(a[0] or {}).get('playerId') if a else None}")
except Exception as e:
    report("A9 pl cards+assists", False, repr(e))

# A10: the 178 honesty dimension on the 179-added block — mas is
# structurally red-only AND assist-less (y=0, assists=0 — never faked)
try:
    d = get(f"{BASE}/api/topscorers/mas")
    c = d.get("cards") or {}
    good = (c.get("yellow") or []) == [] \
        and len(c.get("red") or []) >= 5 \
        and (d.get("assists") or []) == [] \
        and len(d.get("scorers") or []) == 20
    report("A10 mas red-only honesty", good,
           f"y={len(c.get('yellow') or [])} r={len(c.get('red') or [])} "
           f"ass={len(d.get('assists') or [])}")
except Exception as e:
    report("A10 mas red-only honesty", False, repr(e))

print("API_HUNT OK" if ok else "API_HUNT FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_HUNT OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM patrol @390x844 (agent-browser, console must stay 0) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
CNT='import json,sys
try:
  d=json.load(sys.stdin); print(len(d["data"]["messages"]))
except Exception: print("ERR")'
ECNT='import json,sys
try:
  d=json.load(sys.stdin); es=d["data"]["errors"]
  print(len([e for e in es if e.get("url")]))
except Exception: print("ERR")'

open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
gate() { # shared VGATES+console closer — $1=label $2=feat
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# B1: /players plain — the 182 selector with the payload's 12 options, the
# «بیست» copy (gate-synced 158/181), the full 400-card stars grid
open_page "/players"
FEAT=$(snap 'sel:!!document.querySelector("select#season-select"),opts:document.querySelectorAll("select#season-select option").length,copy20:document.body.innerText.includes("ستاره\u200Cهای بیست لیگ و جام برتر"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'sel:true' || B1=1
echo "$FEAT" | rg -q 'opts:(1[0-9]|[2-9][0-9])' || B1=1
echo "$FEAT" | rg -q 'copy20:true' || B1=1
echo "$FEAT" | rg -q 'players:([1-9][0-9]{2,})' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /players selector" "$FEAT"

# B2: REAL season switch on /players — native setter + change event → the
# historical race renders (Kane anchor; he is in NO current surface) and
# the URL carries the season (the replaceState sync)
$B eval "(function(){const s=document.querySelector('select#season-select');if(!s)return 'no-select';const opt=[...s.options].find(o=>o.value==='2023/2024');if(!opt)return 'no-option';const d=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value');d.set.call(s,'2023/2024');s.dispatchEvent(new Event('change',{bubbles:true}));s.dispatchEvent(new Event('input',{bubbles:true}));return 'switched'})()" >/dev/null 2>&1
$B wait --fn "!!document.querySelector('a[href=\"/player/194165\"]')" >/dev/null 2>&1
sleep 2
FEAT=$(snap 'kane:!!document.querySelector("a[href=\"/player/194165\"]"),sub:document.body.innerText.includes("ستاره\u200Cهای فصل"),selval:(document.querySelector("select#season-select")||{}).value||""')
URL=$($B eval 'decodeURIComponent(location.search)' 2>/dev/null | tr -d '"\\')
B2=0
echo "$FEAT" | rg -q 'kane:true' || B2=1
echo "$FEAT" | rg -q 'sub:true' || B2=1
echo "$FEAT" | rg -q 'selval:2023/2024' || B2=1
echo "$URL" | grep -q "season=2023/2024" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 /players switch→2023/2024" "$FEAT | url=$URL"

# B3: click-through — Kane card → /player/194165 (the h1 is the mapped
# Persian هری کین, the 181 client-render lesson)
CLICKED=$($B eval '(function(){const links=[...document.querySelectorAll("a[href=\"/player/194165\"]")];const hit=links.find(l=>(l.innerText||"").includes("کین"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/194165')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL3=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B3=0
[ "$CLICKED" = "clicked" ] || B3=1
case "$URL3" in /player/194165*) : ;; *) B3=1 ;; esac
echo "$H1" | grep -q "کین" || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 click Kane" "clicked=$CLICKED url=$URL3 h1=$H1"

# B4: deep-link seeding — /players?season=2023/2024 opens the historical
# stars directly with the selector pre-set (the 99 ONE-fetch pattern)
open_page "/players?season=2023%2F2024"
FEAT=$(snap 'kane:!!document.querySelector("a[href=\"/player/194165\"]"),selval:(document.querySelector("select#season-select")||{}).value||"",sub:document.body.innerText.includes("ستاره\u200Cهای فصل")')
B4=0
echo "$FEAT" | rg -q 'kane:true' || B4=1
echo "$FEAT" | rg -q 'selval:2023/2024' || B4=1
echo "$FEAT" | rg -q 'sub:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 deep-link 2023/2024" "$FEAT"

# B5: honest empty — offered-but-dataless season shows the season-aware
# copy, the selector stays, NO fake error (the 182 contract)
open_page "/players?season=2013%2F2014"
FEAT=$(snap 'empty:document.body.innerText.includes("ستاره\u200Cای برای فصل"),sel:!!document.querySelector("select#season-select"),err:document.body.innerText.includes("داده\u200Cای برای نمایش نیست")')
B5=0
echo "$FEAT" | rg -q 'empty:true' || B5=1
echo "$FEAT" | rg -q 'sel:true' || B5=1
echo "$FEAT" | rg -q 'err:false' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 honest empty 2013/2014" "$FEAT"

# B6: the 181 surface — /topscorers/belgium league-scoped with the 180
# selector, Eckert anchor, assists + cards blocks all live
open_page "/topscorers/belgium"
FEAT=$(snap 'lg:document.body.innerText.includes("لیگ بلژیک"),eckert:!!document.querySelector("a[href=\"/player/892709\"]"),ass:document.body.innerText.includes("دهندگان"),cards:document.body.innerText.includes("کارت\u200Cها"),sel:!!document.querySelector("select#season-select"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B6=0
echo "$FEAT" | rg -q 'lg:true' || B6=1
echo "$FEAT" | rg -q 'eckert:true' || B6=1
echo "$FEAT" | rg -q 'ass:true' || B6=1
echo "$FEAT" | rg -q 'cards:true' || B6=1
echo "$FEAT" | rg -q 'sel:true' || B6=1
echo "$FEAT" | rg -q 'players:([1-9][0-9])' || B6=1
[ "$B6" -eq 0 ] || BAD=$((BAD+1))
gate "B6 /topscorers/belgium" "$FEAT"

# B7: the belgium league page — table top + both blocks + anchors (the 176
# pattern on the newest league; range-not-count, the drift lesson)
open_page "/league/belgium"
FEAT=$(snap 'gent:document.body.innerText.includes("خنت"),ass:document.body.innerText.includes("دهندگان"),cards:document.body.innerText.includes("کارت\u200Cها"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B7=0
echo "$FEAT" | rg -q 'gent:true' || B7=1
echo "$FEAT" | rg -q 'ass:true' || B7=1
echo "$FEAT" | rg -q 'cards:true' || B7=1
echo "$FEAT" | rg -q 'players:(1[5-9]|[2-9][0-9])' || B7=1
[ "$B7" -eq 0 ] || BAD=$((BAD+1))
gate "B7 /league/belgium" "$FEAT"

# B8: the 180 deep-link on the 179 surface — ADVANCED by cycle-185 (the
# in-gate-comment convention): old-season pl now CARRIES the season's own
# cards (yellow Flynn Downes 844943 / red Bruno Fernandes — the 132
# per-league omission lifted; the global-merge boundary stays pinned by
# cycle185-domproof A7). Salah + the pre-set selector still pin the 180
# surface, assists stay.
open_page "/topscorers/pl?season=2024%2F2025"
FEAT=$(snap 'salah:!!document.querySelector("a[href=\"/player/292462\"]"),selval:(document.querySelector("select#season-select")||{}).value||"",cards:document.body.innerText.includes("کارت\u200Cها"),cr:document.body.innerText.includes("کارت قرمز"),downes:!!document.querySelector("a[href=\"/player/844943\"]"),ass:document.body.innerText.includes("دهندگان")')
B8=0
echo "$FEAT" | rg -q 'salah:true' || B8=1
echo "$FEAT" | rg -q 'selval:2024/2025' || B8=1
echo "$FEAT" | rg -q 'cards:true' || B8=1
echo "$FEAT" | rg -q 'cr:true' || B8=1
echo "$FEAT" | rg -q 'downes:true' || B8=1
echo "$FEAT" | rg -q 'ass:true' || B8=1
[ "$B8" -eq 0 ] || BAD=$((BAD+1))
gate "B8 pl old-season cards joined (185)" "$FEAT"

# B9: mas structural honesty on the 179 block — red-only («کارت قرمز» in,
# «کارت زرد» out) with rows rendering
open_page "/topscorers/mas"
FEAT=$(snap 'cr:document.body.innerText.includes("کارت قرمز"),cy:document.body.innerText.includes("کارت زرد"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B9=0
echo "$FEAT" | rg -q 'cr:true' || B9=1
echo "$FEAT" | rg -q 'cy:false' || B9=1
echo "$FEAT" | rg -q 'players:([1-9][0-9])' || B9=1
[ "$B9" -eq 0 ] || BAD=$((BAD+1))
gate "B9 mas red-only honesty" "$FEAT"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-183: patrol of the 179-182 surfaces — per-league cards block, league topscorers season selector, Belgian Pro League, players-hub season selector — API 10/10 + DOM 9/9 @390x844; honesty-of-absence: old-season cards omission on API+DOM, 2013/2014 offered-but-dataless empty without the fake error, mas structural red-only + assist-less; search two-way FA aliases اکرت/کین/یانلت live; product bugs = 0)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
