#!/bin/bash
# cycle-121 DOM proof at 390x844 — «قهرمانان» (league title history)
# API truth (pl/ucl/seriea totals + designed persiangulf 503 + bad-key 400)
# + DOM: the new tab renders on league pages with champion/runner-up rows —
# zero overflow, 1 h1, clean console (bitmask: 1=overflow 2=h1!=1 4=broken imgs).
set -u
B=agent-browser

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok &= bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
try:
    d = get("http://localhost:3000/api/league-titles?league=pl")
    t = d.get("titles") or {}
    items = t.get("items") or []
    top = items[0] if items else {}
    report("pl shape", d.get("ok") is True and t.get("total") == 127 and len(items) == 127,
           f"total={t.get('total')} n={len(items)}")
    report("pl newest", top.get("season") == "2025/2026" and top.get("championId") == 9825,
           f"season={top.get('season')} champ={top.get('championFa')}({top.get('championId')}) run={top.get('runnerUpFa')}")
    report("pl fa-names", all(any("\u0600" <= ch <= "\u06FF" for ch in (it.get("championFa") or "")) for it in items[:10]),
           "first-10 champions Persian-mapped")
    old = items[-1] if items else {}
    report("pl oldest", bool(old.get("season")) and bool(old.get("championFa")),
           f"oldest={old.get('season')} champ={old.get('championFa')}")
except Exception as e:
    report("pl", False, str(e))
try:
    d = get("http://localhost:3000/api/league-titles?league=ucl")
    t = d.get("titles") or {}
    report("ucl shape", d.get("ok") is True and t.get("total") == 71,
           f"total={t.get('total')} newest={(t.get('items') or [{}])[0].get('championFa')}")
except Exception as e:
    report("ucl", False, str(e))
try:
    d = get("http://localhost:3000/api/league-titles?league=seriea")
    t = d.get("titles") or {}
    report("seriea shape", d.get("ok") is True and t.get("total") == 121,
           f"total={t.get('total')} newest={(t.get('items') or [{}])[0].get('championFa')}")
except Exception as e:
    report("seriea", False, str(e))
try:
    try:
        get("http://localhost:3000/api/league-titles?league=persiangulf")
        report("persiangulf designed 503", False, "expected 503, got 200")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")
        report("persiangulf designed 503", e.code == 503 and "در دسترس نیست" in body, f"designed {e.code}")
except Exception as e:
    report("persiangulf designed 503", False, str(e))
try:
    urllib.request.urlopen("http://localhost:3000/api/league-titles?league=bogus", timeout=20)
    report("bad-key 400", False, "expected 400, got 200")
except urllib.error.HTTPError as e:
    report("bad-key 400", e.code == 400, f"{e.code}")
print("API_TRUTH " + ("OK" if ok else "BAD"))
PY

echo "== PART B: DOM 390x844 =="
TOTAL_BAD=0
# B1: /league/pl — titles tab appears, renders history
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
GOT="false"
for i in 1 2 3 4 5 6; do
  GOT=$($B eval 'JSON.stringify([...document.querySelectorAll("button")].some(b=>(b.textContent||"").trim()==="قهرمانان"))' 2>/dev/null | tr -d '"\\')
  [ "$GOT" = "true" ] && break
  sleep 2
done
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="قهرمانان");if(b)b.click();return 1})()' >/dev/null 2>&1
sleep 1.5
FEAT=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=league-titles]");if(!c)return {titles:false};const t=c.innerText||"";const links=c.querySelectorAll("a[href^=\"/team/\"]").length;return {titles:true,header:t.includes("قهرمان")&&t.includes("نایب‌قهرمان"),arsenal:t.includes("آرسنال"),rows:links>0,teamLinks:links,note:t.includes("تاریخچهٔ کامل قهرمانی"),firstSeason:t.includes("۲۰۲۵/۲۰۲۶")}})())' 2>/dev/null | tr -d '"\\')
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
echo "/league/pl → $OUT | feat=$FEAT | console=$C appErrors=$E"
if [ "$E" != "0" ] || [ "$BAD" != "0" ]; then TOTAL_BAD=$((TOTAL_BAD+1)); echo "   ⚠ FLAGGED (bad=$BAD appErr=$E)"; fi

# B2: /league/persiangulf — designed 503 empty-state, NO titles tab
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/persiangulf" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 3
FEAT2=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {titlesTabAbsent:![...document.querySelectorAll("button")].some(b=>(b.textContent||"").trim()==="قهرمانان"),leagueTitle:t.includes("خلیج فارس")}})())' 2>/dev/null | tr -d '"\\')
OUT2=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null)
BAD2=$($B eval '(function(){var sw=document.documentElement.scrollWidth,cw=document.documentElement.clientWidth,h1n=document.querySelectorAll("h1").length,vb=[...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden"}).length;return (sw!=cw?1:0)+(h1n!=1?2:0)+(vb>0?4:0)})()' 2>/dev/null | tr -d '"')
C2=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
E2=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]
  print(len(app))
except Exception:
  print('ERR')")
echo "/league/persiangulf → $OUT2 | feat=$FEAT2 | console=$C2 appErrors=$E2"
if [ "$E2" != "0" ] || [ "$BAD2" != "0" ]; then TOTAL_BAD=$((TOTAL_BAD+1)); echo "   ⚠ FLAGGED (bad=$BAD2 appErr=$E2)"; fi
echo "FLAGGED_PAGES=$TOTAL_BAD of 2"
echo "==="
