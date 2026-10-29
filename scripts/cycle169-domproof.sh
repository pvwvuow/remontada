#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-169 fix proof — جستجو در برابر اعراب لاتین کور است؛ فیکس: تا خوردن
# نویسه‌های لاتین اعراب‌دار (ń→n، á→a، ü→u، ó→o) در normalizeQuery + مپِ
# نمایش‌درست rangeOf برای هر دو فرم NFC و NFD.
#
# Live-probed gap (2026-10-30, old build): «Poznan» بدون ń → 0 تیم و
# «Sanchez» بدون á → 0 بازیکن، در حالی که «Poznań» → لخ پوزنان و
# «Sánchez» → خوردی سانچز (Jordi Sánchez) می‌خورد — کاربر با کیبورد لاتین
# ساده اعراب تایپ نمی‌کند.
#
# Post-fix expectations (pinned from the ACCENTED forms on the old build —
# the D5 rule: expectations from live data, never invented):
#   Poznan  → لخ پوزنان (Lech Poznań, poland)
#   Munchen → بایرن‌مونیخ (Bayern München, bundesliga)
#   Gornik  → گورنیک زابژه (Górnik Zabrze, poland)
#   Sanchez → خوردی سانچز (Jordi Sánchez, player, hl.name=[6,13] on the
#             ACCENTED original)
# Legacy byte-parity (no-diacritic paths must be untouched):
#   Rijeka → رییکا|hnl؛ Sayyadmanesh → pid 887680 + hl.name=[9,21]؛
#   صیادمنش (fa) → 1 hit؛ Al-Hilal → الهلال.
# ------------------------------------------------------------------
set -u
B=agent-browser
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
# Warmup: after a fresh start the FIRST index sweep can come back partial
# (23 upstream fetches in one burst — some 429; observed live 2026-10-30:
# /api/search answered 0 for teams for the first seconds, then self-healed).
# The cycle-169 src hardening bounds that window to ≤30s (partial sweeps are
# cached 30s + serve the last good index). Warm on the FOLD control itself
# with a 60s budget — the gates below judge the SETTLED truth, and if the
# fold were genuinely broken this loop exhausts and the gates still fail.
python3 - <<'PY'
import json, time, urllib.request, urllib.parse
ctrl = urllib.parse.quote("Munchen")
for i in range(12):
    try:
        with urllib.request.urlopen(f"http://localhost:3000/api/search?q={ctrl}", timeout=30) as r:
            d = json.load(r)
        if len(d.get("results") or []) >= 1:
            print(f"index settled after {i+1} poll(s)")
            break
    except Exception:
        pass
    time.sleep(5)
PY
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
U = lambda s: urllib.parse.quote(s)
# A1: the four plain-Latin queries that answered 0 pre-fix
# (fix D5: the API field for teams is `results`, NOT "teams" — the first gate
# draft read d.get("teams") → undefined → [] and false-flagged every team gate
# while the raw body carried the hits; field names verified against the live
# body, never from memory)
for q, kind, fa in (("Poznan", "results", "لخ پوزنان"),
                    ("Munchen", "results", "بایرن‌مونیخ"),
                    ("Gornik", "results", "گورنیک زابژه"),
                    ("Sanchez", "players", "خوردی سانچز")):
    try:
        d = get(f"http://localhost:3000/api/search?q={U(q)}")
        arr = d.get(kind) or []
        f0 = arr[0].get("fa") if arr else None
        good = len(arr) >= 1 and f0 == fa
        report(f"fold {q} → {fa}", good, f"{len(arr)} hit(s) fa={f0}")
    except Exception as e:
        report(f"fold {q}", False, str(e))
# A2: the accented spellings STILL hit (folding must not break them)
for q, kind, fa in (("Poznań", "results", "لخ پوزنان"), ("Sánchez", "players", "خوردی سانچز")):
    try:
        d = get(f"http://localhost:3000/api/search?q={U(q)}")
        arr = d.get(kind) or []
        f0 = arr[0].get("fa") if arr else None
        good = len(arr) >= 1 and f0 == fa
        report(f"accented {q} still hits", good, f"fa={f0}")
    except Exception as e:
        report(f"accented {q}", False, str(e))
# A3: highlight lands on the ACCENTED original text — hl.name=[6,13] for
# Sanchez on «Jordi Sánchez» (S at 6, 7 chars, end-exclusive)
try:
    d = get(f"http://localhost:3000/api/search?q={U('Sanchez')}")
    p0 = (d.get("players") or [{}])[0]
    hl = p0.get("hl") or {}
    good = (p0.get("name") == "Jordi Sánchez" and hl.get("name") == [6, 13])
    report("hl.name [6,13] on accented original", good, f"name={p0.get('name')} hl={hl}")
except Exception as e:
    report("hl.name [6,13]", False, str(e))
# A4: legacy byte-parity — no-diacritic paths byte-identical
try:
    d = get(f"http://localhost:3000/api/search?q={U('Rijeka')}")
    r0 = (d.get("results") or [{}])[0]
    good = r0.get("fa") == "رییکا" and r0.get("leagueKey") == "hnl"
    report("legacy Rijeka → رییکا|hnl", good, f"{r0.get('fa')}|{r0.get('leagueKey')}")
    d = get(f"http://localhost:3000/api/search?q=Sayyadmanesh")
    p0 = (d.get("players") or [{}])[0]
    good = (p0.get("playerId") == 887680 and p0.get("goals") == 5
            and (p0.get("hl") or {}).get("name") == [9, 21])
    report("legacy Sayyadmanesh pid+hl [9,21]", good, f"pid={p0.get('playerId')} hl={p0.get('hl')}")
    d = get(f"http://localhost:3000/api/search?q={U('صیادمنش')}")
    good = len(d.get("players") or []) == 1
    report("legacy fa صیادمنش 1 hit", good, f"players={len(d.get('players') or [])}")
except Exception as e:
    report("legacy parity", False, str(e))

print("API_PROOF " + ("OK" if ok else "FLAGGED"))
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_PROOF OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM proof @390x844 (real search UI) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
dom_search() { # $1=query $2=expect-fa $3=label
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE/" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
  $B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('$2'))" >/dev/null 2>&1
  sleep 1.5
  local FEAT OUT C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const btns=[...document.querySelectorAll('div[role=\"dialog\"] ul li button')];const hit=btns.find(b=>(b.innerText||'').includes('$2'));return {dialog:!!document.querySelector('div[role=\"dialog\"]'),hits:btns.length,found:!!hit,faHit:hit?(hit.innerText||'').includes('$2'):false}})())" 2>/dev/null | tr -d '"\\')
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
  [ -z "$FEAT" ] && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}
dom_search "Sanchez" "خوردی سانچز" "B1 UI Sanchez → player row"
dom_search "Poznan" "لخ پوزنان" "B2 UI Poznan → team row"
dom_search "Rijeka" "رییکا" "B3 UI Rijeka legacy guard"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-169: search folds Latin diacritics — plain-Latin keyboard queries Poznan/Munchen/Gornik/Sanchez join the accented spellings; highlight lands on the accented original; legacy paths byte-identical)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
