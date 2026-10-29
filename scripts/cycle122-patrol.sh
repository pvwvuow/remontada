#!/bin/bash
# Cycle-122 bug-hunt DOM patrol at 390x844 — 18 routes + client-side
# interaction contracts + API truth checks. Baseline = the hardened 118
# patrol (115→117 arc: referee/stadium, unavailable/lineup facts, season
# top scorers; 110-112: insights / standings legend / fixture difficulty;
# 95-108: top-players, honest injury, weather/zones, boards, season deep
# link + league-switch reset) EXTENDED with the two newest surfaces:
# cycle-120 «آخرین ترکیب» (overview.lastLineupStats on team pages,
# data-testid=team-last-lineup) and cycle-121 «قهرمانان» (top-level
# seasons[] title history on league pages, data-testid=league-titles).
# Bitmask contract (88/93/98/103/108/113): 1=overflow 2=h1!=1 4=broken imgs.
set -u
B=agent-browser

PAGES=(
  "http://localhost:3000/"
  "http://localhost:3000/news"
  "http://localhost:3000/leagues"
  "http://localhost:3000/topscorers"
  "http://localhost:3000/league/pl"
  "http://localhost:3000/league/seriea"
  "http://localhost:3000/league/ucl"
  "http://localhost:3000/league/laliga"
  "http://localhost:3000/league/bundesliga"
  "http://localhost:3000/league/ligue1"
  "http://localhost:3000/league/persiangulf"
  "http://localhost:3000/team/8456"
  "http://localhost:3000/team/9925"
  "http://localhost:3000/team/9826"
  "http://localhost:3000/player/604982"
  "http://localhost:3000/player/737066"
  "http://localhost:3000/match/5749720"
  "http://localhost:3000/match/5071457"
)

$B set viewport 390 844 >/dev/null
TOTAL_BAD=0
for P in "${PAGES[@]}"; do
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$P" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
  FEAT=""
  case "$P" in
    */topscorers)
      FEAT=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {globalTitle:t.includes("مصاف گلزنان"),assistTitle:t.includes("پاس گل")}})())' 2>/dev/null | tr -d '"')
      ;;
    */league/pl)
      LEG=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=standings-legend]");if(!c)return {legend:false};const t=c.textContent||"";return {legend:true,cl:t.includes("لیگ قهرمانان اروپا"),el:t.includes("لیگ اروپا"),rel:t.includes("سقوط")}})())' 2>/dev/null | tr -d '"')
      $B eval '(()=>{const t=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آمار فصل");if(t)t.click();return 1})()' >/dev/null 2>&1
      sleep 1.2
      A=$($B eval 'JSON.stringify((()=>{const boards=!!document.querySelector("[data-testid=league-boards]");return {boards}})())' 2>/dev/null | tr -d '"')
      # cycle-121: «قهرمانان» tab — newest-first title history (آرسنال ۲۰۲۵/۲۰۲۶ on top)
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="قهرمانان");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      T=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=league-titles]");if(!c)return {titles:false};const t=c.innerText||"";return {titles:true,cols:t.includes("قهرمان")&&t.includes("نایب‌قهرمان"),arsenalTop:t.includes("آرسنال"),newest:t.includes("۲۰۲۵/۲۰۲۶"),teamLinks:c.querySelectorAll("a[href^=\"/team/\"]").length,note:t.includes("تاریخچهٔ کامل قهرمانی")}})())' 2>/dev/null | tr -d '"\\')
      FEAT="$LEG | boards=$A | titles=$T"
      ;;
    */league/seriea)
      LEG=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=standings-legend]");const t=(c&&c.textContent)||"";const rows=document.querySelectorAll("table tbody tr").length;return {tableRows:rows,hasInter:(document.body.innerText||"").includes("اینتر"),legend:!!c,conf:t.includes("سهمیهٔ کنفرانس‌لیگ")}})())' 2>/dev/null | tr -d '"')
      # cycle-121 regression: titles tab present on seriea too (121 seasons)
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="قهرمانان");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      T=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=league-titles]");if(!c)return {titles:false};const t=c.innerText||"";return {titles:true,inter:t.includes("اینتر"),teamLinks:c.querySelectorAll("a[href^=\"/team/\"]").length}})())' 2>/dev/null | tr -d '"\\')
      FEAT="$LEG | titles=$T"
      ;;
    */league/ucl)
      LEG=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=standings-legend]");const t=(c&&c.textContent)||"";return {tableRows:document.querySelectorAll("table tbody tr").length,legend:!!c,r16:t.includes("یک‌هشتم نهایی")}})())' 2>/dev/null | tr -d '"')
      FEAT="$LEG"
      ;;
    */league/persiangulf)
      # honest absence: 503 league → standings AND titles tab both absent
      LEG=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasLeagueTitle:t.includes("خلیج فارس"),legendHidden:!document.querySelector("[data-testid=standings-legend]"),titlesTabAbsent:![...document.querySelectorAll("button")].some(b=>(b.textContent||"").trim()==="قهرمانان")}})())' 2>/dev/null | tr -d '"')
      FEAT="$LEG"
      ;;
    */team/8456)
      for i in 1 2 3 4 5 6; do
        GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=team-last-lineup]"))' 2>/dev/null | tr -d '"\\')
        [ "$GOT" = "true" ] && break
        sleep 2
      done
      # cycle-120 extension: «آخرین ترکیب» (formation + 11 rows + chips + meta)
      FEAT=$($B eval 'JSON.stringify((()=>{const tp=document.querySelector("[data-testid=team-top-players]");const co=document.querySelector("[data-testid=team-coaches]");const df=document.querySelector("[data-testid=team-difficulty]");const ll=document.querySelector("[data-testid=team-last-lineup]");const out={topPlayers:!!tp,coaches:!!co,difficulty:!!df};if(ll){const s=(ll.closest("section")||{}).innerText||"";out.lastLineup=true;out.header=s.includes("آخرین ترکیب");out.formation=s.includes("4-2-3-1")||s.includes("۴-۲-۳-۱");out.vsLast=s.includes("آخرین بازی: در برابر");out.yellow=s.includes("کارت زرد");out.age=s.includes("میانگین سن");out.mv=s.includes("ارزش بازار ترکیب");out.playerLinks=ll.querySelectorAll("a[href^=\"/player/\"]").length;out.matchLink=!!(ll.closest("section")||{}).querySelector("a[href^=\"/match/\"]")}else{out.lastLineup=false}if(df){const dsec=(df.closest("section")||{}).innerText||"";out.diffVerdict=dsec.includes("میانه");out.diffLeague=dsec.includes("پریمیرلیگ")}return out})())' 2>/dev/null | tr -d '"\\')
      ;;
    */team/9925)
      for i in 1 2 3 4 5; do
        GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=team-difficulty]"))' 2>/dev/null | tr -d '"\\')
        [ "$GOT" = "true" ] && break
        sleep 2
      done
      FEAT=$($B eval 'JSON.stringify((()=>{const co=document.querySelector("[data-testid=team-coaches]");const df=document.querySelector("[data-testid=team-difficulty]");const dsec=df?(df.closest("section")||{}).innerText||"":"";return {coaches:!!co,difficulty:!!df,diffVerdict:dsec.includes("مدیریت‌پذیر")}})())' 2>/dev/null | tr -d '"\\')
      ;;
    */team/9826)
      for i in 1 2 3 4 5; do
        GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=team-difficulty]"))' 2>/dev/null | tr -d '"\\')
        [ "$GOT" = "true" ] && break
        sleep 2
      done
      FEAT=$($B eval 'JSON.stringify((()=>{const co=document.querySelector("[data-testid=team-coaches]");const df=document.querySelector("[data-testid=team-difficulty]");return {coaches:!!co,difficulty:!!df}})())' 2>/dev/null | tr -d '"\\')
      ;;
    */player/604982)
      FEAT=$($B eval 'JSON.stringify((()=>{const s=document.querySelector("[data-testid=player-injury]");const h=(document.querySelector("h1")||{}).textContent||"";const out={h1HonestEn:h.includes("Loftus-Cheek")};if(!s){out.injury=false}else{out.injury=true}return out})())' 2>/dev/null | tr -d '"')
      ;;
    */player/737066)
      FEAT=$($B eval 'JSON.stringify((()=>{const h=(document.querySelector("h1")||{}).textContent||"";return {h1Fa:h.includes("ارلینگ هالند"),injuryHidden:!document.querySelector("[data-testid=player-injury]")}})())' 2>/dev/null | tr -d '"')
      ;;
    */match/5749720)
      # cycle-117: h2h tab — «گلزنان فصل دو تیم» (Rabiot / Bernardeschi)
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="رو در رو");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      TS=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-topscorers]");if(!c)return {topscorers:false};const t=c.innerText||"";return {topscorers:true,header:t.includes("گلزنان فصل دو تیم"),rabiot:t.includes("رابیو"),bernardeschi:t.includes("برناردسکی"),games:t.includes("بازی در فصل"),rating:t.includes("امتیاز فصل")}})())' 2>/dev/null | tr -d '"\\')
      # cycle-115: info tab — «داور و ورزشگاه»
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="اطلاعات");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      RF=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-referee]");if(!c)return {referee:false};const t=c.innerText||"";return {referee:true,header:t.includes("داور و ورزشگاه"),matches:t.includes("بازی داوری‌شده"),yellow:t.includes("میانگین کارت زرد"),vsChip:t.includes("پایین‌تر از میانگین لیگ"),cap:t.includes("ظرفیت ورزشگاه"),grass:t.includes("چمن طبیعی")}})())' 2>/dev/null | tr -d '"\\')
      I=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-insights]");if(!c)return {insights:false};const t=c.textContent||"";return {insights:true,hasTitle:t.includes("بینش")}})())' 2>/dev/null | tr -d '"\\')
      W=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-weather]");if(!c)return {weather:false};return {weather:true}})())' 2>/dev/null | tr -d '"\\')
      # cycle-116: lineups tab — «غایبان» + starter facts (106/116 regression)
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="ترکیب");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      U=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-unavailable]");if(!c)return {unavailable:false};const t=c.innerText||"";const body=document.body.innerText||"";return {unavailable:true,injury:t.includes("مصدومیت"),links:c.querySelectorAll("a").length,age:body.includes("میانگین سن"),mv:body.includes("ارزش بازار ترکیب")}})())' 2>/dev/null | tr -d '"\\')
      FEAT="$TS $RF $I $W $U"
      ;;
    */match/5071457)
      # cycle-117 on the live/finished MLS fixture: Messi / Denkey
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="رو در رو");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      TS=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-topscorers]");if(!c)return {topscorers:false};const t=c.innerText||"";return {topscorers:true,messi:t.includes("Messi"),denkey:t.includes("Denkey"),goals25:t.includes("۲۵")}})())' 2>/dev/null | tr -d '"\\')
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="اطلاعات");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      RF=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-referee]");if(!c)return {referee:false};return {referee:true}})())' 2>/dev/null | tr -d '"\\')
      FEAT="$TS $RF"
      ;;
  esac
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null)
  BAD=$($B eval '(function(){var sw=document.documentElement.scrollWidth,cw=document.documentElement.clientWidth,h1n=document.querySelectorAll("h1").length,vb=[...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden"}).length;return (sw!=cw?1:0)+(h1n!=1?2:0)+(vb>0?4:0)})()' 2>/dev/null | tr -d '"')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]
  print(len(app))
except Exception:
  print('ERR')")
  echo "$P → $OUT ${FEAT:+| feat=$FEAT} | console=$C appErrors=$E"
  if [ "$E" != "0" ] || [ "$BAD" != "0" ]; then TOTAL_BAD=$((TOTAL_BAD+1)); echo "   ⚠ FLAGGED (bad=$BAD appErr=$E)"; fi
done
echo "==="
echo "FLAGGED_PAGES=$TOTAL_BAD of ${#PAGES[@]}"

echo "== PART B: interaction contracts =="
IBAD=0
# B1) cycle-99 season deep link
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/pl?season=2024/2025" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
# cycle-122 hunt: title history IS season-independent by design, but the
# cycle-121 fetch-array regression hides the tab on historic views (FINDING-1)
B1=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,hasHistLabel:txt.includes("فصل ۲۰۲۴/۲۰۲۵"),falseBanner:txt.includes("ارتباط برقرار نشد."),titlesTab:[...document.querySelectorAll("button")].some(b=>(b.textContent||"").trim()==="قهرمانان")}})())' 2>/dev/null | tr -d '"\\')
echo "B1 deep-link → $B1"
echo "$B1" | grep -q 'hasHistLabel:true' && echo "$B1" | grep -q 'h1n:1' || { echo "   ⚠ B1 FAIL"; IBAD=$((IBAD+1)); }
# FINDING-1 (cycle-122 hunt) FIXED in cycle-123: the conditional transfers
# spread moved to the tail of the allSettled array (titles owns the fixed
# slot) + symmetric optional chaining — historic deep-links must now show
# NO false banner AND the «قهرمانان» tab. Hard regression guard since 123.
echo "$B1" | grep -q 'falseBanner:false' && echo "$B1" | grep -q 'titlesTab:true' \
  && echo "   FINDING-1 closed (cycle-123): no false banner + titles tab renders on historic deep-link" \
  || { echo "   ⚠ B1 FAIL: FINDING-1 regression — false banner or missing titles tab on historic deep-link"; IBAD=$((IBAD+1)); }
# B2) cycle-101 season-state reset on client-side league switch
$B open "http://localhost:3000/leagues" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2
$B eval 'JSON.stringify((()=>{const a=[...document.querySelectorAll("a[href=\"/league/ucl\"]")][0];if(!a)return {found:false};a.click();return {found:true}})())' >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('لیگ قهرمانان اروپا')" >/dev/null 2>&1
sleep 4
B2=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {url:location.pathname+location.search,searchEmpty:location.search==="",hasCarriedLabel:txt.includes("۲۰۲۴/۲۰۲۵"),sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth}})())' 2>/dev/null | tr -d '"\\')
echo "B2 league-switch reset → $B2"
echo "$B2" | grep -q 'searchEmpty:true' && echo "$B2" | grep -q 'hasCarriedLabel:false' || { echo "   ⚠ B2 FAIL"; IBAD=$((IBAD+1)); }
echo "INTERACTION_BAD=$IBAD"

echo "== PART C: API truth (110-117 + 120/121 surfaces) =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    with urllib.request.urlopen(u, timeout=20) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
# cycle-111 legends (persiangulf checked separately: since cycle-136 the
# placeholder id became the real FotMob league 523 — the home league serves
# its own table, so its legend is the AFC trio, not a designed 503)
want = {"pl": 3, "seriea": 4, "ucl": 2}
for lk, n in want.items():
    try:
        leg = get(f"http://localhost:3000/api/standings?league={lk}").get("legend") or []
        report(f"legend {lk}", len(leg) == n, f"n={len(leg)} want={n}")
    except Exception as e:
        report(f"legend {lk}", False, str(e))
try:
    d = get("http://localhost:3000/api/standings?league=persiangulf")
    leg = d.get("legend") or []
    titles = [x.get("fa") for x in leg]
    good = d.get("ok") is True and len(leg) == 3 and "لیگ قهرمانان آسیا" in titles
    report("legend persiangulf", good, f"n={len(leg)} titles={titles}")
except Exception as e:
    report("legend persiangulf", False, str(e))
# cycle-110 insights
try:
    ins = get("http://localhost:3000/api/match/5749720").get("insights") or []
    report("insights 5749720", len(ins) >= 3 and all(i.get("text") for i in ins), f"n={len(ins)}")
except Exception as e:
    report("insights 5749720", False, str(e))
# cycle-112 difficulty
try:
    fd = get("http://localhost:3000/api/team-difficulty/8456").get("difficulty") or {}
    report("difficulty 8456", fd.get("verdictFa") == "میانه" and len(fd.get("fixtures") or []) == 5,
           f"verdict={fd.get('verdictFa')} n={len(fd.get('fixtures') or [])}")
except Exception as e:
    report("difficulty 8456", False, str(e))
# cycle-115 refereeStats + stadiumExtra
for mid in ("5749720", "5071457"):
    try:
        d = get(f"http://localhost:3000/api/match/{mid}")
        rs = (d.get("info") or {}).get("refereeStats") or {}
        se = (d.get("info") or {}).get("stadiumExtra") or {}
        good = rs.get("matches") is not None and rs.get("yellowPerMatch") is not None and se.get("capacity") is not None
        report(f"refereeStats {mid}", good, f"matches={rs.get('matches')} yellow={rs.get('yellowPerMatch')} cap={se.get('capacity')}")
    except Exception as e:
        report(f"refereeStats {mid}", False, str(e))
# cycle-116 unavailable + starter facts
try:
    lu = get("http://localhost:3000/api/match/5749720").get("lineups") or {}
    h = lu.get("home") or {}
    un = h.get("unavailable") or []
    good = len(un) == 8 and h.get("starterAge") is not None and (h.get("totalMarketValueFa") or "").endswith("یورو")
    report("unavailable 5749720", good, f"n={len(un)} age={h.get('starterAge')} mv={h.get('totalMarketValueFa')}")
except Exception as e:
    report("unavailable 5749720", False, str(e))
# cycle-117 topScorers
for mid, hg in (("5749720", 4), ("5071457", 25)):
    try:
        ts = get(f"http://localhost:3000/api/match/{mid}").get("topScorers") or {}
        hh = ts.get("home") or {}
        aa = ts.get("away") or {}
        good = hh.get("goals") == hg and aa.get("goals") is not None and hh.get("playerId") is not None
        report(f"topScorers {mid}", good, f"home={hh.get('name')}({hh.get('goals')}) away={aa.get('name')}({aa.get('goals')})")
    except Exception as e:
        report(f"topScorers {mid}", False, str(e))
# cycle-121 league titles: pl=127 newest-first (آرسنال ۲۰۲۵/۲۰۲۶), ucl=71,
# since cycle-136 persiangulf serves 24 live (newest 2024/2025 تراکتور),
# 400 on unknown key
# real contract (route + domproof-121): titles = LeagueTitleHistory {total, items[] newest-first}
try:
    t = get("http://localhost:3000/api/league-titles?league=pl").get("titles") or {}
    items = t.get("items") or []
    top = items[0] if items else {}
    good = t.get("total") == 127 and len(items) == 127 and "آرسنال" in (top.get("championFa") or "") and top.get("season") == "2025/2026"
    report("titles pl", good, f"total={t.get('total')} n={len(items)} newest={top.get('season')}/{top.get('championFa')} oldest={items[-1].get('season') if items else None}")
except Exception as e:
    report("titles pl", False, str(e))
try:
    t = get("http://localhost:3000/api/league-titles?league=ucl").get("titles") or {}
    report("titles ucl", t.get("total") == 71 and len(t.get("items") or []) == 71, f"total={t.get('total')} n={len(t.get('items') or [])} want=71")
except Exception as e:
    report("titles ucl", False, str(e))
try:
    t = get("http://localhost:3000/api/league-titles?league=persiangulf").get("titles") or {}
    titems = t.get("items") or []
    ttop = titems[0] if titems else {}
    good = t.get("total") == 24 and len(titems) == 24 and ttop.get("season") == "2024/2025" and "تراکتور" in (ttop.get("championFa") or "")
    report("titles persiangulf", good, f"total={t.get('total')} n={len(titems)} newest={ttop.get('season')}/{ttop.get('championFa')}")
except Exception as e:
    report("titles persiangulf", False, str(e))
try:
    urllib.request.urlopen("http://localhost:3000/api/league-titles?league=bogus", timeout=20)
    report("titles bad-key", False, "expected 400, got 200")
except urllib.error.HTTPError as e:
    report("titles bad-key", e.code == 400, f"designed {e.code}")
except Exception as e:
    report("titles bad-key", False, str(e))
# cycle-120 last lineup: 8456 formation+11 starters, unknown-id honest-hide
# real contract (domproof-120): lastMatch is an OBJECT {matchId, opponentId, opponentFa}
try:
    ll = get("http://localhost:3000/api/team-last-lineup/8456").get("lastLineup") or {}
    st = ll.get("starters") or []
    lm = ll.get("lastMatch") or {}
    good = ll.get("formation") == "4-2-3-1" and len(st) == 11 and ll.get("coachName") and lm.get("matchId")
    report("lastLineup 8456", good, f"formation={ll.get('formation')} starters={len(st)} coach={ll.get('coachName')} lastMatch={lm.get('matchId')} vs={lm.get('opponentFa')}")
except Exception as e:
    report("lastLineup 8456", False, str(e))
try:
    d = get("http://localhost:3000/api/team-last-lineup/999999999")
    report("lastLineup unknown-id", d.get("ok") is True and d.get("lastLineup") is None,
           f"ok={d.get('ok')} lastLineup={d.get('lastLineup')} (honest-hide)")
except Exception as e:
    report("lastLineup unknown-id", False, str(e))
print("API_TRUTH", "OK" if ok else "BAD")
PY
