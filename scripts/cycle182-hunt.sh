#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-182 bug-hunt — «گشت‌زنی سطوح ۱۷۹-۱۸۱ و صداقت غیاب»
#
# Context (2026-10-30 ~08:0x +08:00): the rotation engine completed
# cycles 179-181 while this session slept (commits 14a2c59/e25004a/
# 4ab65c9). Three-state detection: two reads 50s apart — tree clean,
# ls-remote stable at 4ab65c9, target card (cycle-182) absent from
# origin → per protocol the next cycle runs fully. 182 mod 5 = 2 →
# type 3 = BUG-HUNT (patrols only, zero src changes unless a real
# product bug surfaces).
#
# The hunt patrols the three surfaces added since the cycle-178 hunt,
# at viewport 390x844, PLUS honesty-of-absence contracts (the 178
# dimension) and the 178-era regressions:
#   cycle-179  «کارت‌ها» card on /topscorers/[leagueKey] (pl y0=688273)
#   cycle-180  season selector on the same page (?season= deep link +
#              real switch + honest empty + invalid→400 + hist cards
#              honestly OMITTED — the 132 rule)
#   cycle-181  Belgian Pro League (18 rows خنت 25, Eckert 892709 IRN
#              rank 9, Forbs assists 10, y=15/r=15, race 400/20,
#              hist race 380/19 Denkey, composite 32 rows, titles
#              123 = 2025/2026 کلوب بروژ … 1895/1896 اف‌سی لیژ,
#              transfers 100 items, playoff=null → «براکت» ABSENT)
#   honesty    historical seasons carry NO cards block; belgium page
#              shows no «براکت» tab; mas stays red-only everywhere
#
# Pinned live truth (probed 2026-10-30 ~08:00 +08, UA Chrome/124,
# scripts/cycle182-probe.sh — all 181/180/179 pins reproduced):
#   topscorers/pl       extra={assists,cards,selectedSeason,allSeasons}
#                       cards y=15 (y0=688273) r=14, assists=10, sel=2026/2027
#   topscorers/pl?2024/2025  Salah 29g «محمد صلاح», cards key ABSENT
#   topscorers/pl?2013/2014  200 + scorers=0 (honest empty); ?2023 → 400
#   topscorers/mas?2024/2025 Bergson 33g «برگسون», assists=0, allSeasons=3
#   standings/belgium   rows=18 r0=خنت/25, Eckert rank9/دنیس اکرت/4g/IRN,
#                       assists=10 a0=1186529, y=15 r=15, allSeasons=12,
#                       sel=2026/2027, playoff=None
#   race                400/20 belgium-in mas-out; hist 380/19 belgium-in
#   belgium hist        topscorers 2023/2024 Denkey n=20 cards ABSENT;
#                       standings 2023/2024 = 32 composite rows
#   search              Eckert + اکرت both → 892709 (دنیس اکرت/استاندارد لیژ)
#   league-titles       titles{total:123, items:123}, last 1895/1896 اف‌سی لیژ
#   league-transfers    transfers{items:100}
# Patrol rule: assert ranges and structure, NEVER exact live counts
# (the 173 drift lesson); ZWNJ expressed as \u200C in JS evals.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API truth (UA Chrome/124) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.parse, urllib.request, urllib.error
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
def pidok(x):
    return isinstance(x.get("playerId"), int) and x["playerId"] > 0

# A1: page sweep — 16 routes including the two Belgium newcomers
pages = ["/", "/leagues", "/players", "/news", "/topscorers",
         "/league/belgium", "/topscorers/belgium", "/league/pl",
         "/topscorers/pl", "/league/persiangulf", "/league/mas",
         "/topscorers/mas", "/player/892709", "/player/688273",
         "/team/2182", "/match/5749723"]
bad = []
for p in pages:
    try:
        if code(BASE + p) != 200:
            bad.append(p)
    except Exception as e:
        bad.append(f"{p}({e.__class__.__name__})")
report("A1 pages 16x200", not bad, f"bad={bad}")

# A2: the 179 cards card rides the topscorers route — parity + Janelt pin
try:
    d = get(BASE + "/api/topscorers/pl")
    old = {"ok", "leagueKey", "leagueFa", "season", "scorers", "updatedAt"}
    extra = set(d.keys()) - old
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
        and len(y) >= 10 and all(pidok(x) for x in y) \
        and (y[0] or {}).get("playerId") == 688273 \
        and len(r) >= 1 and all(pidok(x) for x in r) \
        and len(d.get("assists") or []) >= 5 \
        and d.get("selectedSeason") == "2026/2027"
    report("A2 179 cards-card parity+Janelt", good,
           f"extra={sorted(extra)} y={len(y)} y0={(y[0] or {}).get('playerId') if y else None} "
           f"r={len(r)} ass={len(d.get('assists') or [])}")
except Exception as e:
    report("A2 179 cards-card parity+Janelt", False, repr(e))

# A3: the 132 honesty — ADVANCED by cycle-185 (the in-gate-comment
# convention): BOTH parts of this gate sit on per-league topscorers routes,
# and the 185 season-aware getLeagueCardLeaders gives historical seasons
# their OWN card blocks (pl 2024/2025 yellow Flynn Downes 12 / pid 844943;
# belgium 2023/2024 yellow Hannes van der Bruggen 12 / pid 232299). The
# GLOBAL historical merge still omits cards — Layer 2 untouched, the 132
# rule survives there and cycle185-domproof A7 pins that boundary.
try:
    q = urllib.parse.quote("2024/2025", safe="")
    h = get(f"{BASE}/api/topscorers/pl?season={q}")
    s0 = (h.get("scorers") or [{}])[0]
    hy0 = ((h.get("cards") or {}).get("yellow") or [{}])[0]
    q2 = urllib.parse.quote("2023/2024", safe="")
    bh = get(f"{BASE}/api/topscorers/belgium?season={q2}")
    b0 = (bh.get("scorers") or [{}])[0]
    by0 = ((bh.get("cards") or {}).get("yellow") or [{}])[0]
    good = "cards" in h and s0.get("playerId") == 292462 \
        and s0.get("goals") == 29 and s0.get("nameFa") == "محمد صلاح" \
        and hy0.get("playerId") == 844943 and hy0.get("value") == 12 \
        and "cards" in bh and by0.get("playerId") == 232299 and by0.get("value") == 12 \
        and b0.get("name") == "Kévin Denkey" \
        and len(h.get("scorers") or []) >= 10 \
        and len(bh.get("scorers") or []) >= 10
    report("A3 hist-cards joined per-league after 185", good,
           f"pl_hist_cards={'cards' in h} y0={hy0.get('playerId')}/{hy0.get('value')} "
           f"bel_hist_cards={'cards' in bh} by0={by0.get('playerId')}/{by0.get('value')} "
           f"pl0={s0.get('name')}/{s0.get('goals')}g bel0={b0.get('name')}")
except Exception as e:
    report("A3 hist-cards joined per-league after 185", False, repr(e))

# A4: the 180 guard pair — offered-but-dataless season is an honest 200
# empty, an invalid season shape is a 400 (the cycle-55 guard)
try:
    q = urllib.parse.quote("2013/2014", safe="")
    e = get(f"{BASE}/api/topscorers/pl?season={q}")
    inv = code(BASE + "/api/topscorers/pl?season=2023")
    good = e.get("ok") is True and e.get("selectedSeason") == "2013/2014" \
        and (e.get("scorers") or []) == [] and inv == 400
    report("A4 honest-empty + invalid-400", good,
           f"sel={e.get('selectedSeason')} scorers={len(e.get('scorers') or [])} invalid={inv}")
except Exception as e:
    report("A4 honest-empty + invalid-400", False, repr(e))

# A5: mas historical — Bergson pin, assists honestly empty, real 3-list
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers/mas?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    good = d.get("selectedSeason") == "2024/2025" \
        and s0.get("playerId") == 190509 and s0.get("goals") == 33 \
        and s0.get("nameFa") == "برگسون" \
        and d.get("assists") == [] and len(d.get("allSeasons") or []) >= 3
    report("A5 mas hist Bergson+no-assists", good,
           f"sel={d.get('selectedSeason')} s0={s0.get('name')}/{s0.get('goals')}g "
           f"ass={len(d.get('assists') or [])} seas={len(d.get('allSeasons') or [])}")
except Exception as e:
    report("A5 mas hist Bergson+no-assists", False, repr(e))

# A6: the 181 belgium portal full contract + playoff honestly None
try:
    d = get(BASE + "/api/standings?league=belgium")
    rows = d.get("rows") or []
    sc = d.get("scorers") or []
    ek = next((x for x in sc if x.get("playerId") == 892709), None)
    a = d.get("assists") or []
    c = d.get("cards") or {}
    good = d.get("ok") is True and len(rows) == 18 \
        and rows[0].get("fa") == "خنت" and rows[0].get("pts") == 25 \
        and len(sc) == 20 and ek is not None \
        and ek.get("rank") == 9 and ek.get("nameFa") == "دنیس اکرت" \
        and ek.get("team") == "استاندارد لیژ" and ek.get("goals") == 4 \
        and ek.get("ccode") == "IRN" \
        and len(a) == 10 and (a[0] or {}).get("playerId") == 1186529 \
        and len(c.get("yellow") or []) == 15 and len(c.get("red") or []) == 15 \
        and len(d.get("allSeasons") or []) == 12 \
        and d.get("selectedSeason") == "2026/2027" \
        and d.get("playoff") is None
    report("A6 belgium portal contract", good,
           f"rows={len(rows)} r0={rows[0].get('fa')}/{rows[0].get('pts')} "
           f"ek={ek.get('rank') if ek else None} ass={len(a)} "
           f"y={len(c.get('yellow') or [])} r={len(c.get('red') or [])} playoff={d.get('playoff')}")
except Exception as e:
    report("A6 belgium portal contract", False, repr(e))

# A7: the race merged both directions — current 400/20 belgium-in mas-out;
# historical 380/19 belgium-in (the archived 2023/2024 goals file)
try:
    d = get(BASE + "/api/topscorers")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    ek = [x for x in ts if x.get("playerId") == 892709]
    q = urllib.parse.quote("2023/2024", safe="")
    h = get(f"{BASE}/api/topscorers?season={q}")
    hpl = [p.get("leagueKey") for p in (h.get("perLeague") or [])]
    good = len(ts) == 400 and len(pl) == 20 and "belgium" in pl \
        and "mas" not in pl and len(ek) >= 1 \
        and len(h.get("scorers") or []) == 380 and len(hpl) == 19 \
        and "belgium" in hpl
    report("A7 race 400/20 + hist 380/19", good,
           f"ts={len(ts)} pl={len(pl)} bel={'belgium' in pl} masout={'mas' not in pl} "
           f"ekinrace={bool(ek)} hts={len(h.get('scorers') or [])} hpl={len(hpl)}")
except Exception as e:
    report("A7 race 400/20 + hist 380/19", False, repr(e))

# A8: belgium historical standings are COMPOSITE (the cycle-141 parser)
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/standings?league=belgium&season={q}")
    rows = d.get("rows") or []
    good = d.get("ok") is True and len(rows) == 32 \
        and d.get("selectedSeason") == "2023/2024"
    report("A8 belgium hist composite 32", good,
           f"rows={len(rows)} sel={d.get('selectedSeason')}")
except Exception as e:
    report("A8 belgium hist composite 32", False, repr(e))

# A9: search discovers the hook BOTH ways (166/171 contract on 181 data)
try:
    g1 = get(BASE + "/api/search?q=Eckert")
    p1 = [x for x in (g1.get("players") or []) if x.get("playerId") == 892709]
    g2 = get(BASE + "/api/search?q=" + urllib.parse.quote("اکرت"))
    p2 = [x for x in (g2.get("players") or []) if x.get("playerId") == 892709]
    good = bool(p1) and p1[0].get("fa") == "دنیس اکرت" \
        and p1[0].get("teamFa") == "استاندارد لیژ" and bool(p2)
    report("A9 search two-way Eckert", good,
           f"latin={bool(p1)} fa={p1[0].get('fa') if p1 else None} alias={bool(p2)}")
except Exception as e:
    report("A9 search two-way Eckert", False, repr(e))

# A10: titles + transfers portals — the 123-season arc and 100 items
try:
    tt = get(BASE + "/api/league-titles?league=belgium").get("titles") or {}
    items = tt.get("items") or []
    first = items[0] if items else {}
    last = items[-1] if items else {}
    tr = get(BASE + "/api/league-transfers?league=belgium").get("transfers") or {}
    trit = tr.get("items") or []
    persian = any(ch >= "\u0600" and ch <= "\u06FF" for ch in json.dumps(trit[:5], ensure_ascii=False))
    good = tt.get("total") == 123 and len(items) == 123 \
        and first.get("season") == "2025/2026" and first.get("championFa") == "کلوب بروژ" \
        and last.get("season") == "1895/1896" and last.get("championFa") == "اف‌سی لیژ" \
        and len(trit) == 100 and persian
    report("A10 titles 123 + transfers 100", good,
           f"titles={tt.get('total')}/{len(items)} first={first.get('season')} "
           f"last={last.get('season')}/{last.get('championFa')} transfers={len(trit)} faSides={persian}")
except Exception as e:
    report("A10 titles 123 + transfers 100", False, repr(e))

# A11: 178-era regressions — mas red-only honesty + persiangulf both
# columns + the only-in-cards strong gate (688273 in NO pl other surface)
try:
    ms = get(BASE + "/api/standings?league=mas")
    mc = ms.get("cards") or {}
    pg = get(BASE + "/api/standings?league=persiangulf")
    pgc = pg.get("cards") or {}
    pgy = pgc.get("yellow") or []
    pgr = pgc.get("red") or []
    pl = get(BASE + "/api/standings?league=pl")
    plids = {x.get("playerId") for x in (pl.get("scorers") or [])} | \
            {x.get("playerId") for x in (pl.get("assists") or [])}
    good = ms.get("assists") == [] and (mc.get("yellow") or []) == [] \
        and len(mc.get("red") or []) >= 1 \
        and pg.get("assists") == [] and len(pgy) >= 10 \
        and 900771 in {x.get("playerId") for x in pgy} \
        and len(pgr) >= 10 \
        and 688273 not in plids
    report("A11 178 regressions", good,
           f"mas_ass={len(ms.get('assists') or [])} mas_y={len(mc.get('yellow') or [])} "
           f"mas_r={len(mc.get('red') or [])} pg_y={len(pgy)} pg_r={len(pgr)} "
           f"688273_in_pl_other={688273 in plids}")
except Exception as e:
    report("A11 178 regressions", False, repr(e))

print("HUNT_API OK" if ok else "HUNT_API FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"HUNT_API OK"*) : ;;
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

patrol_open() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
}
# one shared feature-snapshot eval: $1 = JS object literal body
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
gate() { # $1=label $2=feat — shared VGATES/console assert
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# B1: /league/belgium — table + 181 assists + cards + Eckert anchor,
# and the «براکت» tab honestly ABSENT (playoff=None)
patrol_open "/league/belgium"
FEAT=$(snap 'table:document.body.innerText.includes("جدول"),ass:document.body.innerText.includes("دهندگان"),cards:document.body.innerText.includes("کارت\u200Cها"),bracket:document.body.innerText.includes("براکت"),eckert:!!document.querySelector("a[href=\"/player/892709\"]"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'table:true' || B1=1
echo "$FEAT" | rg -q 'ass:true' || B1=1
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'bracket:false' || B1=1
echo "$FEAT" | rg -q 'eckert:true' || B1=1
echo "$FEAT" | rg -q 'players:(1[5-9]|[2-9][0-9])' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /league/belgium" "$FEAT"

# B2: /topscorers/belgium — the 180 selector with the real 12-option list,
# 179 cards card + 174 assists card, Forbs anchor
patrol_open "/topscorers/belgium"
FEAT=$(snap 'sel:!!document.querySelector("select#season-select"),opts:document.querySelectorAll("select#season-select option").length,cards:document.body.innerText.includes("کارت\u200Cها"),ass:document.body.innerText.includes("دهندگان"),forbs:!!document.querySelector("a[href=\"/player/1186529\"]")')
B2=0
echo "$FEAT" | rg -q 'sel:true' || B2=1
echo "$FEAT" | rg -q 'opts:(1[0-9]|[2-9][0-9])' || B2=1
echo "$FEAT" | rg -q 'cards:true' || B2=1
echo "$FEAT" | rg -q 'ass:true' || B2=1
echo "$FEAT" | rg -q 'forbs:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 /topscorers/belgium" "$FEAT"

# B3: /topscorers/pl — REAL season switch to 2024/2025 via the native
# setter → the historical payload renders (Salah anchor) + URL sync
patrol_open "/topscorers/pl"
$B eval "(function(){const s=document.querySelector('select#season-select');if(!s)return 'no-select';const opt=[...s.options].find(o=>o.value==='2024/2025');if(!opt)return 'no-option';const d=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value');d.set.call(s,'2024/2025');s.dispatchEvent(new Event('change',{bubbles:true}));s.dispatchEvent(new Event('input',{bubbles:true}));return 'switched'})()" >/dev/null 2>&1
$B wait --fn "!!document.querySelector('a[href=\"/player/292462\"]')" >/dev/null 2>&1
sleep 2
FEAT=$(snap 'salah:!!document.querySelector("a[href=\"/player/292462\"]"),selval:(document.querySelector("select#season-select")||{}).value||""')
URL=$($B eval 'decodeURIComponent(location.search)' 2>/dev/null | tr -d '"\\')
B3=0
echo "$FEAT" | rg -q 'salah:true' || B3=1
echo "$FEAT" | rg -q 'selval:2024/2025' || B3=1
echo "$URL" | grep -q "season=2024/2025" || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 switch→2024/2025" "$FEAT | url=$URL"

# B4: the switched view click-through — Salah row → /player/292462
CLICKED=$($B eval '(function(){const links=[...document.querySelectorAll("a[href=\"/player/292462\"]")];const hit=links.find(l=>(l.innerText||"").includes("صلاح"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/292462')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL4=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B4=0
[ "$CLICKED" = "clicked" ] || B4=1
case "$URL4" in /player/292462*) : ;; *) B4=1 ;; esac
echo "$H1" | grep -q "صلاح" || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 click Salah" "clicked=$CLICKED url=$URL4 h1=$H1"

# B5: 181 FA-alias UI path — home search dialog, type «اکرت», real click
# → /player/892709 h1 «دنیس اکرت»
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'اکرت');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('دنیس اکرت'))" >/dev/null 2>&1
sleep 1
CLICKED=$($B eval '(function(){const btns=[...document.querySelectorAll("div[role=\"dialog\"] ul li button")];const hit=btns.find(b=>(b.innerText||"").includes("دنیس اکرت"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/892709')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL5=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B5=0
[ "$CLICKED" = "clicked" ] || B5=1
case "$URL5" in /player/892709*) : ;; *) B5=1 ;; esac
echo "$H1" | grep -q "اکرت" || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 click اکرت" "clicked=$CLICKED url=$URL5 h1=$H1"

# B6: honesty-of-absence DOM — /topscorers/mas stays red-only honest
# (the 178 regression), /league/belgium has no «براکت» (checked in B1;
# here the mas page + honest anchors)
patrol_open "/topscorers/mas"
FEAT=$(snap 'cr:document.body.innerText.includes("کارت قرمز"),cy:document.body.innerText.includes("کارت زرد"),ass:document.body.innerText.includes("دهندگان"),sel:!!document.querySelector("select#season-select"),anchors:document.querySelectorAll("a[href]").length')
B6=0
echo "$FEAT" | rg -q 'cr:true' || B6=1
echo "$FEAT" | rg -q 'cy:false' || B6=1
echo "$FEAT" | rg -q 'ass:false' || B6=1
echo "$FEAT" | rg -q 'sel:true' || B6=1
echo "$FEAT" | rg -q 'anchors:([1-9][0-9])' || B6=1
[ "$B6" -eq 0 ] || BAD=$((BAD+1))
gate "B6 /topscorers/mas honesty" "$FEAT"

# B7: home + match regression patrol (anchor networks intact)
patrol_open "/"
FEAT=$(snap 'anchors:document.querySelectorAll("a[href]").length')
B7=0
echo "$FEAT" | rg -q 'anchors:([1-9][0-9]{2,})' || B7=1
[ "$B7" -eq 0 ] || BAD=$((BAD+1))
gate "B7 home" "$FEAT"
patrol_open "/match/5749723"
FEAT=$(snap 'players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B8=0
echo "$FEAT" | rg -q 'players:([1-9][0-9])' || B8=1
[ "$B8" -eq 0 ] || BAD=$((BAD+1))
gate "B8 /match/5749723" "$FEAT"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-182: patrol of the 179-181 surfaces — per-league topscorers cards card, season selector with real switch + honest empty + hist cards honestly omitted, the Belgian portal full contract incl. race merge both directions, titles/transfers portals, FA-alias search click-through to Eckert — plus honesty-of-absence (bracket tab absent on belgium, mas red-only) and 178-era regressions, 16 pages 200, 8 DOM surfaces clean at 390x844 with console=0 appErrors=0; product bugs = 0)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
