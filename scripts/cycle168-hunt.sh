#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-168 bug-hunt — گشت‌زنی سه‌سطح تازهٔ پس از آخرین شکار (۱۶۳):
# لهستان ۱۶۵ / جستجوی بازیکن ۱۶۶ / لینک‌شدن انتقال‌ها ۱۶۷
# در viewport 390×844 با کنسول تمیز.
#
# House contract (mirror cycle-163/158-hunt; Part C = API truth):
#   hunt(label, url, extra-waitfn, clickjs, featjs) → collect() gates:
#   feat must not contain false/null, viewport {sw:390,cw:390,h1n:1,
#   vbroken:0}, console=0, appErrors=0. Empty feat FAILS (D5).
#
# Live-truth baseline (probed 2026-10-30, UA Chrome/124 — the D5 rule:
# facts FIRST, gates second; every gate below re-verified against the
# running server before being written):
#   poland = h1 اکستراکلاسا لهستان, top لخ پوزنان ۲۸ (۱۱/۹/۱/۱), tabs
#          آقای گل+انتقال‌ها+قهرمانان present (titles 99 exist, bracket
#          null → absent); transfers tab = 100 rows ALL /player-linked
#          (100/100 nameFa + 100/100 playerId>0), from/to clubFa ZERO
#          ASCII; scorers lead خوردی سانچز ۹ پوگون شچچین;
#   team 2182 لخ پوزنان = transfers section visible WITHOUT a tab
#          button (44 /player anchors live): صیادمنش→/player/887680 +
#          غلی‌زاده→/player/746018 BOTH linked (the 167 contract);
#   search = Sayyadmanesh → dialog player row «اللهیار صیادمنش |
#          Allahyar Sayyadmanesh | لخ پوزنان | اکستراکلاسا» — REAL
#          click navigates to /player/887680 h1 «اللهیار صیادمنش»;
#          the «بازیکنان» section header is a <p> (search-box.tsx:261)
#          rendered when players.length>0 (probe-side D5: it is NOT a
#          div/h2 — select p with exact text);
#   race  = default copy «۱۹ لیگ و جام برتر» (old ۱۸ gone) + leader
#          رافینیا ۱۳ + poland IN; season 2023/2024 → «۱۸ لیگ
#          مشارکت‌کننده» + hnl in + mas honestly out; players hub =
#          «ستاره‌های نوزده لیگ و جام برتر ...» — MUST be read BEFORE
#          any mode click (probe-side D5: the copy line was read after
#          a mode click once and false-failed);
#   guard = laliga transfers: Milud Nordin (playerId=0, the 167 zero
#          case) visible as PLAIN TEXT, never /player-linked → exactly
#          99 anchors for 100 items;
#   /topscorers/poland dedicated path = h1n:1, خوردی سانچز + پوگون + ۹.
#
# V1  /league/poland → h1 + top row + tabs
# V2  poland → real «انتقال‌ها» click → 100 /player anchors
# V3  /team/2182 → both Iranian hooks linked (href-exact)
# V4  search Sayyadmanesh → real row click → /player/887680 h1
# V5  /topscorers default → copy ۱۹ + رافینیا + old ۱۸ gone
# V6  /topscorers/poland → خوردی سانچز ۹ پوگون
# V7  /players → copy نوزده read FIRST + two-step poland chip →
#     URL sync + لخ پوزنان grid
# V8  /league/laliga transfers → Milud Nordin plain (zero-pid guard)
# V9  race 2023/2024 → dynamic ۱۸ + hnl in + mas out
# Part C: API truth A1–A8 (poland standings/race cur+hist/search
#     player fa+en+backward-compat/team-transfers hooks/zero-ASCII/
#     exactly-one zero-pid/mapcheck 1077/533)
# Tail: re-run cycle167-domproof.sh + cycle164-digitsweep.sh (the two
#     freshest synced gates) as the cross-regression.
# ------------------------------------------------------------------
set -u
B=agent-browser
BASE="http://localhost:3000"
$B set viewport 390 844 >/dev/null

BAD=0

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
  [ -z "$FEAT" ] && RC=1   # D5: an empty feat (broken eval) must FAIL, not silently pass
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

hunt() { # $1=label $2=url $3=extra-waitfn $4=clickjs $5=featjs
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$2" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  [ -n "${3:-}" ] && $B wait --fn "$3" >/dev/null 2>&1
  sleep 3
  if [ -n "${4:-}" ]; then $B eval "$4" >/dev/null 2>&1; sleep 3; fi
  local FEAT
  FEAT=$($B eval "JSON.stringify(($5))" 2>/dev/null | tr -d '"\\')
  collect "$FEAT" "$1"
  return 0
}

echo "== PART A: DOM hunt @390x844 =="
# V1: poland — h1, live top لخ پوزنان, scorers+transfers tabs
hunt "V1 poland page tabs" "$BASE/league/poland" \
"(document.body.innerText||\"\").includes(\"لخ پوزنان\")" "" \
"({h1:((document.querySelector('h1')||{}).innerText||'').includes('اکستراکلاسا لهستان'),top:((document.querySelector('table tbody tr')||{}).innerText||'').includes('لخ پوزنان'),scorersTab:[...document.querySelectorAll('button')].some(b=>(b.textContent||'').trim()==='آقای گل'),transfersTab:[...document.querySelectorAll('button')].some(b=>(b.textContent||'').trim()==='انتقال‌ها')})"

# V2: poland — REAL transfers click → 100 /player anchors
hunt "V2 poland transfers click links" "$BASE/league/poland" \
"(document.body.innerText||\"\").includes(\"لخ پوزنان\")" \
"(function(){const t=[...document.querySelectorAll('button')].find(x=>(x.textContent||'').trim()==='انتقال‌ها');if(t)t.click();return t?'clicked':'no-tab'})()" \
"({anchors:document.querySelectorAll('a[href*=\"/player/\"]').length,many:document.querySelectorAll('a[href*=\"/player/\"]').length>=90,panelAlive:(document.body.innerText||'').length>200})"

# V3: /team/2182 — both Iranian hooks linked href-exact (no tab; section inline)
hunt "V3 lech team hooks linked" "$BASE/team/2182" \
"(document.body.innerText||\"\").includes(\"لخ پوزنان\")" "" \
"({anchors:document.querySelectorAll('a[href*=\"/player/\"]').length>=20,sayyadHref:(()=>{const l=document.querySelector('a[href=\"/player/887680\"]');return l?(l.textContent||'').includes('صیادمنش'):'missing'})(),gholiHref:(()=>{const l=document.querySelector('a[href=\"/player/746018\"]');return l?(l.textContent||'').includes('غلی‌زاده'):'missing'})()})"

# V4: search player flow — real typing → real row click → player page (166 arc)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Sayyadmanesh');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('صیادمنش'))" >/dev/null 2>&1
sleep 1.5
ROW4=$($B eval "JSON.stringify((()=>{const dlg=document.querySelector('div[role=\"dialog\"]');const hit=[...dlg.querySelectorAll('ul li button')].find(b=>(b.innerText||'').includes('صیادمنش'));const pTag=[...dlg.querySelectorAll('p')].some(p=>(p.textContent||'').trim()==='بازیکنان');return {dialog:!!dlg,playersHeaderP:pTag,row:!!hit}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const dlg=document.querySelector("div[role=\"dialog\"]");const hit=[...dlg.querySelectorAll("ul li button")].find(b=>(b.innerText||"").includes("صیادمنش"));if(hit)hit.click();return hit?"clicked":"no-row"})()' >/dev/null 2>&1
sleep 3
FEAT4=$($B eval "JSON.stringify((()=>{return {url:location.pathname==='/player/887680',h1:((document.querySelector('h1')||{}).innerText||'').includes('اللهیار صیادمنش')}})())" 2>/dev/null | tr -d '"\\')
collect "$ROW4 $FEAT4" "V4 search Sayyadmanesh row→click→player h1"

# V5: race default — copy ۱۹ + رافینیا + old ۱۸ gone (read BEFORE any click)
hunt "V5 race default copy 19" "$BASE/topscorers" \
"(document.body.innerText||\"\").includes(\"رافینیا\")" "" \
"({copy19:(document.body.innerText||'').includes('۱۹ لیگ و جام برتر'),old18gone:!(document.body.innerText||'').includes('۱۸ لیگ و جام برتر'),leader:(document.body.innerText||'').includes('رافینیا')})"

# V6: /topscorers/poland dedicated path
hunt "V6 poland scorers path" "$BASE/topscorers/poland" \
"(document.body.innerText||\"\").includes(\"خوردی\")" "" \
"({leader:(document.body.innerText||'').includes('خوردی سانچز'),team:(document.body.innerText||'').includes('پوگون'),goals9:(document.body.innerText||'').includes('۹')})"

# V7: players hub — copy read FIRST (D5), then two-step poland chip
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 3
COPY7=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';return {copy19p:b.includes('نوزده لیگ و جام برتر')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").includes("تیم‌ها")||(x.textContent||"").includes("اسکواد"));if(b)b.click();return b?"teams":"no-mode"})()' >/dev/null 2>&1
sleep 2
$B eval '(function(){const c=document.querySelector("[data-testid=\"league-poland\"]");if(c)c.click();return c?"clicked":"no-chip"})()' >/dev/null 2>&1
sleep 3
FEAT7=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';return {urlSync:location.search.includes('league=poland'),lechGrid:b.includes('لخ پوزنان')}})())" 2>/dev/null | tr -d '"\\')
collect "$COPY7 $FEAT7" "V7 players hub copy19 + teams→poland click"

# V8: laliga transfers — the zero-pid guard (Milud Nordin pid=0 stays plain)
hunt "V8 laliga zero-pid guard" "$BASE/league/laliga" \
"(document.body.innerText||\"\").includes(\"رئال\")" \
"(function(){const t=[...document.querySelectorAll('button')].find(x=>(x.textContent||'').trim()==='انتقال‌ها');if(t)t.click();return t?'clicked':'no-tab'})()" \
"({miludVisible:(document.body.innerText||'').includes('Milud Nordin'),miludNotLinked:!document.evaluate(\"//a[.//text()[contains(.,'Milud Nordin')]]\",document,null,XPathResult.BOOLEAN_TYPE,null).booleanValue,anchors:document.querySelectorAll('a[href*=\"/player/\"]').length>=90})"

# V9: race season 2023/2024 — dynamic ۱۸ + hnl in + mas out
hunt "V9 race season dyn-18" "$BASE/topscorers?league=all&season=2023/2024" \
"(document.body.innerText||\"\").includes(\"۲۰۲۳\")" "" \
"({dyn18:(document.body.innerText||'').includes('۱۸ لیگ مشارکت‌کننده'),hnlRow:(document.body.innerText||'').includes('هایدوک')||(document.body.innerText||'').includes('دیناموزاگرب'),noMas:(document.body.innerText||'').indexOf('سوپرلیگ مالزی')===-1})"

echo "== PART C: API truth =="
API_OUT=$(python3 - <<'PY'
import json, urllib.request, re, subprocess
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))
# A1: poland standings — 18 rows لخ پوزنان ۲۸ + scorer block خوردی سانچز ۹
try:
    d = get("http://localhost:3000/api/standings?league=poland")
    rows = d.get("rows") or []
    sc = d.get("scorers") or []
    lead = sc[0] if sc else {}
    good = (d.get("ok") and len(rows) == 18 and rows[0].get("fa") == "لخ پوزنان" and rows[0].get("pts") == 28
            and len(sc) == 20 and lead.get("nameFa") == "خوردی سانچز" and lead.get("goals") == 9
            and not any(ascii_leak(r.get("fa")) for r in rows[:5]) and not ascii_leak(lead.get("team")))
    report("standings poland 18 لخ پوزنان ۲۸ خوردی ۹", good, f"rows={len(rows)} top={rows[0].get('fa') if rows else None}({rows[0].get('pts') if rows else None}) scorer={lead.get('nameFa')}({lead.get('goals')})")
except Exception as e:
    report("standings poland", False, str(e))
# A2: race cur — 380/19, poland IN, leader رافینیا ۱۳
try:
    d = get("http://localhost:3000/api/topscorers")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    lead = ts[0] if ts else {}
    good = (len(ts) == 380 and len(pl) == 19 and "poland" in pl and lead.get("nameFa") == "رافینیا"
            and lead.get("goals") == 13 and not ascii_leak(lead.get("team")))
    report("race cur 380/19 poland-in", good, f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")
except Exception as e:
    report("race cur", False, str(e))
# A3: race 2023/2024 — 360/18, poland+hnl in, mas out
try:
    d = get("http://localhost:3000/api/topscorers?season=2023/2024")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    good = len(ts) == 360 and len(pl) == 18 and "poland" in pl and "hnl" in pl and "mas" not in pl
    report("race 2023/2024 360/18 poland+hnl mas-out", good, f"n={len(ts)} perLeague={len(pl)}")
except Exception as e:
    report("race 2023/2024", False, str(e))
# A4: player search — fa query + en query (the 166 contract) + teams backward-compat
try:
    d = get("http://localhost:3000/api/search?q=%D8%B5%DB%8C%D8%A7%D8%AF%D9%85%D9%86%D8%B4")
    ps = d.get("players") or []
    p0 = ps[0] if ps else {}
    good = (len(ps) == 1 and p0.get("fa") == "اللهیار صیادمنش" and p0.get("playerId") == 887680
            and p0.get("teamFa") == "لخ پوزنان" and p0.get("leagueKey") == "poland" and p0.get("goals") == 5)
    report("search fa صیادمنش 1 hit pid 887680", good, f"players={len(ps)} fa={p0.get('fa')} goals={p0.get('goals')}")
    d = get("http://localhost:3000/api/search?q=Sayyadmanesh")
    ps = d.get("players") or []
    p0 = ps[0] if ps else {}
    good = (len(ps) >= 1 and p0.get("playerId") == 887680 and p0.get("name") == "Allahyar Sayyadmanesh"
            and isinstance(p0.get("hl"), dict))
    report("search en Sayyadmanesh pid+hl", good, f"players={len(ps)} pid={p0.get('playerId')}")
    d = get("http://localhost:3000/api/search?q=Rijeka")
    r = d.get("results") or []
    f0 = r[0] if r else {}
    good = f0.get("fa") == "رییکا" and f0.get("leagueKey") == "hnl"
    report("search teams backward-compat Rijeka", good, f"{f0.get('fa')}|{f0.get('leagueKey')}")
except Exception as e:
    report("search player/teams", False, str(e))
# A5: team-transfers 2182 — BOTH Iranian hooks pid>0 (the 167 team-page contract)
try:
    d = get("http://localhost:3000/api/team-transfers/2182")
    p = d.get("transfers") or {}
    its = p.get("items") or []
    say = [x for x in its if x.get("playerId") == 887680]
    gho = [x for x in its if x.get("playerId") == 746018]
    good = (d.get("ok") and len(its) >= 20 and len(say) == 1 and say[0].get("nameFa") == "اللهیار صیادمنش"
            and len(gho) == 1 and gho[0].get("nameFa") == "علی غلی‌زاده")
    report("team-transfers 2182 hooks pid>0", good, f"items={len(its)} sayyad={len(say)} gholizadeh={len(gho)}")
except Exception as e:
    report("team-transfers 2182", False, str(e))
# A6: poland league-transfers — invariant ALL nameFa + ALL pid>0 + club-fa zero-ASCII
try:
    d = get("http://localhost:3000/api/league-transfers?league=poland")
    p = d.get("transfers") or {}
    its = p.get("items") or []
    noname = [x for x in its if not (x.get("nameFa") or "")]
    zeroid = [x for x in its if (x.get("playerId") or 0) <= 0]
    leak = [x for x in its if ascii_leak((x.get("fromClubFa") or "") + (x.get("toClubFa") or ""))]
    good = (d.get("ok") and len(its) >= 90 and not noname and not zeroid and not leak)
    report("transfers poland all-nameFa all-pid>0 zero-ASCII", good, f"items={len(its)} noname={len(noname)} zeroid={len(zeroid)} leak={len(leak)}")
except Exception as e:
    report("transfers poland", False, str(e))
# A7: laliga — EXACTLY one zero-pid case (Milud Nordin, nameFa stays raw upstream)
try:
    d = get("http://localhost:3000/api/league-transfers?league=laliga")
    its = ((d.get("transfers") or {}).get("items")) or []
    zero = [x for x in its if (x.get("playerId") or 0) <= 0]
    good = (len(its) >= 90 and len(zero) == 1 and zero[0].get("name") == "Milud Nordin"
            and zero[0].get("nameFa") == "Milud Nordin")
    report("transfers laliga exactly-1 zero-pid raw", good, f"items={len(its)} zero={len(zero)} name={zero[0].get('nameFa') if zero else None}")
except Exception as e:
    report("transfers laliga zero-pid", False, str(e))
# A8: mapping keys — the duplicate guard at cycle-165 totals 1077/533
try:
    r = subprocess.run(["python3", "scripts/cycle162-mapcheck.py"], capture_output=True, text=True, timeout=120)
    report("mapcheck 1077/533 zero-dups", r.returncode == 0, f"rc={r.returncode}")
except Exception as e:
    report("mapcheck 1077/533 zero-dups", False, str(e))

print("API_TRUTH " + ("OK" if ok else "FLAGGED"))
PY
)
echo "$API_OUT"
case "$API_OUT" in
  *"API_TRUTH OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART D: cross-gate re-runs (the two freshest synced gates) =="
bash scripts/cycle167-domproof.sh >/tmp/c168-g167.log 2>&1 && G167=$? || G167=$?
grep -q "DOM_PROOF OK" /tmp/c168-g167.log && G167PASS=1 || G167PASS=0
echo "cycle167-domproof re-run rc=$G167 green=$G167PASS"
[ "$G167PASS" = "1" ] || BAD=$((BAD+1))
bash scripts/cycle164-digitsweep.sh >/tmp/c168-g164.log 2>&1 && G164=$? || G164=$?
grep -q "nleaks:0" /tmp/c168-g164.log && G164PASS=1 || G164PASS=0
echo "cycle164-digitsweep re-run rc=$G164 nleaks:0 green=$G164PASS"
[ "$G164PASS" = "1" ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-168: the surfaces born after the last hunt — poland 165 / player search 166 / transfer links 167 — walked the fan way @390x844: V1–V9 green with console=0/appErrors=0 everywhere, plus API truth A1–A8 and both cross-gates (167-domproof + 164-digitsweep) re-run green)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
