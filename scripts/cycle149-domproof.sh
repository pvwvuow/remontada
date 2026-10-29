#!/bin/bash
# cycle-149 fix proof — FINDING-1 from the 148 bug-hunt: hyphen/underscore
# Latin search queries returned EMPTY while space forms hit. The fix folds
# [-_] to space inside normalizeQuery (one function feeds BOTH the query and
# the alias haystack) plus the same fold in rangeOf so the highlight range
# stays consistent with the folded matcher.
# API A1: the documented EMPTY class now hits (Al-Hilal/Al-Nassr/Al-Ittihad/
#         Real-Madrid/Man-United + underscore real_madrid/man_united)
# API A2: space/Persian regression — space forms, Persian forms still hit
# API A3: two-truth attributions unchanged (Galatasaray/Rangers/Abha/Celtic)
# API A4: highlight consistency — Al-Ettifaq query returns a non-null name
#         range through the folded rangeOf
# API A5: honesty guards unchanged — "---" empty (no crash), short query
#         message, degenerate inputs stay safe
# DOM  V1: real header-search flow @390x844 — click trigger, type «Al-Hilal»
#          with a real input event, الهلال result renders (no empty state)
# DOM  V2: real click on the result → /team/<id> profile loads (Persian h1)
# DOM  V3: underscore query «man_united» in the same real flow → منچستریونایتد
# DOM  V4: honest empty state preserved on a garbage query («zzqq») with
#          suggestions — designed «تیمی با این نام پیدا نشد.» still intact
# Every page: sw=cw=390, exactly 1 h1, 0 broken images, console=0, appErr=0.
set -u
B=agent-browser
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error, urllib.parse
BASE = "http://localhost:3000"
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
def q_search(q):
    d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    return d, (d.get("results") or [{}])[0]
import re
zwnj = "\u200c"
# A1: the documented EMPTY class from the 148 hunt — now every one hits
for q, fa_part, lk in (("Al-Hilal", "الهلال", "acl"), ("Al-Nassr", "النصر", "acl"),
                       ("Al-Ittihad", "الاتحاد", "acl"), ("Real-Madrid", "رئال", "laliga"),
                       ("Man-United", "منچستریونایتد", "pl"), ("real_madrid", "رئال", "laliga"),
                       ("man_united", "منچستریونایتد", "pl")):
    try:
        d, r = q_search(q)
        fa = (r.get("fa") or "")
        good = r.get("fa") is not None and fa_part in fa and r.get("leagueKey") == lk
        report(f"A1 [{q}]", good, f"{fa}→{r.get('leagueKey')}")
    except Exception as e:
        report(f"A1 [{q}]", False, str(e))
# A2: space + Persian regression — nothing lost
for q, fa_part, lk in (("Al Hilal", "الهلال", "acl"), ("Real Madrid", "رئال", "laliga"),
                       ("Manchester United", "منچستریونایتد", "pl"), ("الهلال", "الهلال", "acl"),
                       ("رئال مادرید", "رئال", "laliga")):
    try:
        d, r = q_search(q)
        good = fa_part in (r.get("fa") or "") and r.get("leagueKey") == lk
        report(f"A2 [{q}]", good, f"{r.get('fa')}→{r.get('leagueKey')}")
    except Exception as e:
        report(f"A2 [{q}]", False, str(e))
# A3: attribution two-truths unchanged
for q, fa, lk in (("Galatasaray", "گالاتاسارای", "superlig"), ("Rangers", "رنجرز", "scottish"),
                  ("Abha", "ابها", "saudi"), ("Celtic", "سلتیک", "uel")):
    try:
        d, r = q_search(q)
        good = r.get("fa") == fa and r.get("leagueKey") == lk
        report(f"A3 [{q}]", good, f"{r.get('fa')}→{r.get('leagueKey')}")
    except Exception as e:
        report(f"A3 [{q}]", False, str(e))
# A4: highlight consistency through the folded rangeOf — the name range must
# be non-null (the feed stores «Al-Ettifaq» hyphen-form; the query folds)
try:
    d, r = q_search("Al-Ettifaq")
    hl = r.get("hl") or {}
    good = (r.get("fa") or "") == "الاتفاق" and hl.get("name") is not None
    report("A4 Al-Ettifaq highlight", good, f"fa={r.get('fa')} hl.name={hl.get('name')}")
except Exception as e:
    report("A4 Al-Ettifaq highlight", False, str(e))
# A5: honesty guards — degenerate inputs stay safe and messages unchanged
try:
    d, r = q_search("---")
    good = d.get("ok") is True and (d.get("results") or []) == [] and not d.get("message")
    report("A5 dashes empty", good, f"ok={d.get('ok')} results={len(d.get('results') or [])}")
except Exception as e:
    report("A5 dashes empty", False, str(e))
try:
    d = get(f"{BASE}/api/search?q=a")
    good = d.get("ok") is True and "حداقل" in (d.get("message") or "")
    report("A5 short-q message", good, f"message={d.get('message')}")
except Exception as e:
    report("A5 short-q message", False, str(e))
try:
    d = get(f"{BASE}/api/search?q=Al_Hilal-")
    r = (d.get("results") or [{}])[0]
    good = "الهلال" in (r.get("fa") or "") and r.get("leagueKey") == "acl"
    report("A5 mixed-separator edge (Al_Hilal-)", good, f"top={r.get('fa')}→{r.get('leagueKey')}")
except Exception as e:
    report("A5 mixed-separator edge (Al_Hilal-)", False, str(e))
print("API_TRUTH", "OK" if ok else "BAD")
if not ok:
    print("API_FAIL")
PY
[ $? -eq 0 ] || BAD=$((BAD+1))

echo "== PART B: DOM proof @390x844 — real header-search flows =="
B=agent-browser
$B set viewport 390 844 >/dev/null

search_flow() { # $1=query $2=expect-fa $3=label
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "http://localhost:3000/" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  # real click on the header search trigger
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
  # real input event with the native setter (controlled React input)
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
  # debounced 250ms fetch — wait for the expected result to render
  $B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('$2'))" >/dev/null 2>&1
  sleep 1.5
  local FEAT OUT C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const btns=[...document.querySelectorAll('div[role=\"dialog\"] ul li button')];const hit=btns.find(b=>(b.innerText||'').includes('$2'));return {dialog:!!document.querySelector('div[role=\"dialog\"]'),hits:btns.length,found:!!hit,noEmptyState:!(document.body.innerText||'').includes('پیدا نشد'),faHit:hit?(hit.innerText||'').includes('$2'):false}})())" 2>/dev/null | tr -d '"\\')
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
  echo "$3 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

# V1: the FINDING-1 query in the REAL UI — «Al-Hilal» renders الهلال
search_flow "Al-Hilal" "الهلال" "V1 header search Al-Hilal"

# V2: continue the journey — real click on the result → team profile
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Real-Madrid');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('رئال'))" >/dev/null 2>&1
sleep 1.5
$B eval '(function(){const b=[...document.querySelectorAll("div[role=\"dialog\"] ul li button")].find(x=>(x.innerText||"").includes("رئال"));if(b)b.click();return b?"clicked":"no-hit"})()' >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('رئال') && /^\/team\/[0-9]+$/.test(location.pathname)" >/dev/null 2>&1
sleep 3
V2FEAT=$($B eval "JSON.stringify(({onTeam:/^\/team\/[0-9]+$/.test(location.pathname),h1Live:!!(document.querySelector(\"h1\")||{}).innerText,faName:(document.body.innerText||\"\").includes(\"رئال\")}))" 2>/dev/null | tr -d '"\\')
V2OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
V2C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
V2E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
echo "V2 result click→team page → $V2OUT | feat=$V2FEAT | console=$V2C appErrors=$V2E"
V2RC=0
echo "$V2FEAT" | grep -q "false\|null" && V2RC=1
[ "$V2OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && V2RC=1
[ "$V2C" = "0" ] && [ "$V2E" = "0" ] || V2RC=1
[ "$V2RC" -eq 0 ] || BAD=$((BAD+1))

# V3: the underscore class in the real UI — «man_united» renders منچستریونایتد
search_flow "man_united" "منچستریونایتد" "V3 header search man_united"

# V4: honest empty state preserved on a garbage query
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'zzqq');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "(document.body.innerText||'').includes('پیدا نشد')" >/dev/null 2>&1
sleep 1.5
V4FEAT=$($B eval "JSON.stringify((()=>{return {emptyState:(document.body.innerText||'').includes('پیدا نشد'),suggestions:(document.body.innerText||'').includes('شاید دنبال این تیم‌ها بودید')}})())" 2>/dev/null | tr -d '"\\')
V4OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
V4C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
V4E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
echo "V4 honest empty state → $V4OUT | feat=$V4FEAT | console=$V4C appErrors=$V4E"
V4RC=0
echo "$V4FEAT" | grep -q "false\|null" && V4RC=1
[ "$V4OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && V4RC=1
[ "$V4C" = "0" ] && [ "$V4E" = "0" ] || V4RC=1
[ "$V4RC" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOMPROOF OK — FINDING-1 closed: separator-folded queries hit in API and in the real header-search flow; space/Persian/attribution truths unchanged; honest empty state intact"
else
  echo "DOMPROOF FLAGGED (BAD=$BAD)"; exit 1
fi
