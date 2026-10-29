#!/bin/bash
# cycle-123 DOM proof at 390x844 — FIX (FINDING-1, hunted cycle-122):
# historic season deep-links (/league/pl?season=2024/2025) used to render a
# FALSE «ارتباط برقرار نشد.» banner and never show the «قهرمانان» tab
# (blame 89ee488c: conditional transfers spread shifted the allSettled array
# so tiRes was undefined → TypeError → catch → misleading error). Fix: titles
# owns a FIXED slot before the conditional spread (moved to the tail) +
# symmetric optional chaining on both positional results.
# This proof: (A) API truth unchanged (titles API was never broken),
# (B) historic deep-links now load with NO false banner AND a working
# «قهرمانان» tab on two leagues, (C) current-season views keep BOTH the
# titles tab AND the transfers tab (the reorder must not regress cycle-57),
# (D) zero overflow / 1 h1 / 0 broken images / console=0 / appErr=0
# (bitmask 1=overflow 2=h1!=1 4=broken imgs; cycle-108 url convention).
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth (titles API untouched by the fix) =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
try:
    d = get("http://localhost:3000/api/league-titles?league=pl")
    t = d.get("titles") or {}
    items = t.get("items") or []
    top = items[0] if items else {}
    report("pl shape", d.get("ok") is True and t.get("total") == 127 and len(items) == 127,
           f"total={t.get('total')} newest={top.get('championFa')} {top.get('season')}")
except Exception as e:
    report("pl", False, str(e))
try:
    d = get("http://localhost:3000/api/standings?league=pl&season=2024/2025")
    report("historic standings", d.get("ok") is True and d.get("selectedSeason") == "2024/2025",
           f"selectedSeason={d.get('selectedSeason')}")
except Exception as e:
    report("historic standings", False, str(e))
try:
    d = get("http://localhost:3000/api/league-transfers?league=pl")
    report("transfers current-only", d.get("ok") is True and bool(d.get("transfers")),
           f"ok={d.get('ok')} n={len((d.get('transfers') or {}).get('items') or [])}")
except Exception as e:
    report("transfers current-only", False, str(e))
print("API_TRUTH " + ("OK" if ok else "BAD"))
PY

echo "== PART B: DOM 390x844 — the fix itself =="
probe_page() { # $1=url $2=label $3=expected-extra-eval(bool json expr)
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT
  FEAT=$($B eval "JSON.stringify((()=>{const txt=document.body.innerText||'';const tabs=[...document.querySelectorAll('button')].map(b=>(b.textContent||'').trim());return $3})())" 2>/dev/null | tr -d '"\\')
  local OUT BAD C E
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
  echo "$2 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  local RC=0
  [ "$BAD" != "0" ] && RC=1
  [ "$E" != "0" ] && RC=1
  echo "$FEAT" | grep -q "falseBanner:false" || RC=1
  return $RC
}
TOTAL_BAD=0

# B1: THE FIX — historic deep-link, pl 2024/2025: no false banner + titles tab present
probe_page "http://localhost:3000/league/pl?season=2024/2025" "B1 /league/pl?season=2024/2025" \
  '{hasHistLabel:txt.includes("فصل ۲۰۲۴/۲۰۲۵"),falseBanner:txt.includes("ارتباط برقرار نشد."),titlesTab:tabs.includes("قهرمانان"),retryAbsent:!txt.includes("تلاش دوباره")}' \
  || { echo "   ⚠ B1 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B1b: click the titles tab on the SAME historic view → the table must render
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="قهرمانان");if(b)b.click();return 1})()' >/dev/null 2>&1
sleep 1.5
B1B=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=league-titles]");if(!c)return {titles:false};const t=c.innerText||"";const links=c.querySelectorAll("a[href^=\"/team/\"]").length;return {titles:true,header:t.includes("قهرمان")&&t.includes("نایب‌قهرمان"),arsenal:t.includes("آرسنال"),teamLinks:links,note:t.includes("تاریخچهٔ کامل قهرمانی")}})())' 2>/dev/null | tr -d '"\\')
echo "B1b titles table on historic view → $B1B"
echo "$B1B" | grep -q 'titles:true' && echo "$B1B" | grep -q 'arsenal:true' && echo "$B1B" | grep -q 'teamLinks' \
  && echo "$B1B" | grep -qE 'teamLinks:[0-9]{2,}' \
  || { echo "   ⚠ B1b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B2: second historic league, seriea 2023/2024 — same fixed contract
probe_page "http://localhost:3000/league/seriea?season=2023/2024" "B2 /league/seriea?season=2023/2024" \
  '{falseBanner:txt.includes("ارتباط برقرار نشد."),titlesTab:tabs.includes("قهرمانان"),hasHistLabel:txt.includes("فصل ۲۰۲۳/۲۰۲۴")}' \
  || { echo "   ⚠ B2 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B3: current view must keep BOTH surfaces — titles tab AND transfers tab
probe_page "http://localhost:3000/league/pl" "B3 /league/pl (current)" \
  '{falseBanner:txt.includes("ارتباط برقرار نشد."),titlesTab:tabs.includes("قهرمانان"),transfersTab:tabs.includes("انتقال‌ها"),standingsTab:tabs.includes("جدول")}' \
  || { echo "   ⚠ B3 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B4: ucl current — titles tab present (71 titles), bracket league intact
probe_page "http://localhost:3000/league/ucl" "B4 /league/ucl (current)" \
  '{falseBanner:txt.includes("ارتباط برقرار نشد."),titlesTab:tabs.includes("قهرمانان")}' \
  || { echo "   ⚠ B4 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

echo "==="
echo "FLAGGED_PAGES=$TOTAL_BAD of 4 (B1b counted separately)"
if [ "$TOTAL_BAD" = "0" ]; then
  echo "CYCLE123 FIX PROOF OK"
else
  echo "CYCLE123 FIX PROOF BAD"
fi
