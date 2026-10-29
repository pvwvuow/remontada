#!/bin/bash
# cycle-120 DOM proof at 390x844 — «آخرین ترکیب» (team last lineup)
# API truth (8456/9825/unknown-id contract) + DOM: the new section renders
# on the team page with 11 starter rows, formation chip, yellow-card chip,
# meta line and last-match link — zero overflow, 1 h1, clean console
# (bitmask convention 88/93/98/103/108/113/118: 1=overflow 2=h1!=1 4=broken imgs).
set -u
B=agent-browser

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok &= good
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
try:
    d = get("http://localhost:3000/api/team-last-lineup/8456")
    ll = d.get("lastLineup") or {}
    st = ll.get("starters") or []
    report("8456 shape", d.get("ok") is True and ll.get("formation") == "4-2-3-1" and len(st) == 11,
           f"formation={ll.get('formation')} n={len(st)}")
    lm = ll.get("lastMatch") or {}
    report("8456 lastMatch", lm.get("matchId") == 5795486 and lm.get("opponentFa") == "استون\u200cویلا",
           f"matchId={lm.get('matchId')} opp={lm.get('opponentFa')}")
    don = [x for x in st if "دوناروما" in x["name"]]
    report("8456 Donnarumma fa", len(don) == 1 and don[0]["matchRating"] is not None and bool(don[0]["marketValueFa"]),
           f"name={don[0]['name'] if don else '-'}")
    gu = [x for x in st if x.get("yellow")]
    report("8456 yellow-card row", len(gu) >= 1 and all(x["id"] > 0 for x in st),
           f"yellow n={len(gu)} allIds>0")
    report("8456 meta", bool(ll.get("totalMarketValueFa")) and ll.get("averageAge") is not None and bool(ll.get("coachName")),
           f"tmv={ll.get('totalMarketValueFa')} age={ll.get('averageAge')} coach={ll.get('coachName')}")
except Exception as e:
    report("8456", False, str(e))
try:
    d = get("http://localhost:3000/api/team-last-lineup/9825")
    ll = d.get("lastLineup") or {}
    st = ll.get("starters") or []
    rated = [x for x in st if x.get("matchRating") is not None]
    fa_named = [x for x in st if any("\u0600" <= ch <= "\u06FF" for ch in x["name"])]
    report("9825 shape", d.get("ok") is True and len(st) == 11 and len(rated) >= 10 and bool(ll.get("formation")),
           f"n={len(st)} rated={len(rated)} formation={ll.get('formation')} faNames={len(fa_named)}")
except Exception as e:
    report("9825", False, str(e))
try:
    d = get("http://localhost:3000/api/team-last-lineup/999999999")
    report("unknown-id contract", d.get("ok") is True and d.get("lastLineup") is None,
           f"ok={d.get('ok')} lastLineup={d.get('lastLineup')} (honest-hide)")
except Exception as e:
    report("unknown-id contract", False, str(e))
print("API_TRUTH " + ("OK" if ok else "BAD"))
PY

echo "== PART B: DOM 390x844 =="
TOTAL_BAD=0
for P in "http://localhost:3000/team/8456" "http://localhost:3000/team/9825"; do
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$P" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  GOT="false"
  for i in 1 2 3 4 5 6; do
    GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=team-last-lineup]"))' 2>/dev/null | tr -d '"\\')
    [ "$GOT" = "true" ] && break
    sleep 2
  done
  FEAT=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=team-last-lineup]");if(!c)return {lastLineup:false};const t=(c.closest("section")||{}).innerText||"";const rows=c.querySelectorAll("a,div.grid").length;const body=document.body.innerText||"";return {lastLineup:true,header:t.includes("آخرین ترکیب"),formation:t.includes("4-2-3-1")||t.includes("۴-۲-۳-۱"),rows:rows,vsLast:t.includes("آخرین بازی: در برابر"),yellow:t.includes("کارت زرد"),age:t.includes("میانگین سن"),mv:t.includes("ارزش بازار ترکیب"),note:t.includes("امتیاز همان بازی"),playerLinks:c.querySelectorAll("a[href^=\"/player/\"]").length,matchLink:!!c.closest("section").querySelector("a[href^=\"/match/\"]")}})())' 2>/dev/null | tr -d '"\\')
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
  echo "$P → $OUT | feat=$FEAT | console=$C appErrors=$E"
  if [ "$E" != "0" ] || [ "$BAD" != "0" ]; then TOTAL_BAD=$((TOTAL_BAD+1)); echo "   ⚠ FLAGGED (bad=$BAD appErr=$E)"; fi
done
echo "FLAGGED_PAGES=$TOTAL_BAD of 2"
echo "==="
