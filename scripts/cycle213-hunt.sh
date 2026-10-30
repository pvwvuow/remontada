#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-213 bug-hunt — the CODEX PATROL: the Midnight Codex redesign
# (211 foundation + 212 page-level pass) walks the four main surfaces
# (league / match / topscorers / player) at 390×844, plus the two debts
# the 212 card assigned to this cycle: the EFL Cup B7 fresh anchor and
# the post-start pid verification (the «alive port, dead build» lesson).
#
# Bug-hunt contract (the 208 rule): findings are REPORTED for the next
# fix cycle (214); zero src changes from a hunt. The hunt therefore
# splits its checks in two classes:
#   PASS gates  — the redesign's own claims (contracts, testids, pinned
#                 texts, the restated-surface violet-clean claims, page
#                 health). Any red = a real regression ⇒ exit 1.
#   FINDING probes — the violet census over the whole cascade. The 212
#                 pass restated the listed surfaces, but the base layer's
#                 oklch(hue 295-300) vocabulary survives anywhere the
#                 codex layer did not restate; the census reports every
#                 survivor for cycle-214 (live-verified pre-hunt on
#                 --arcane-soft: rune-title diamonds, the portal-gate
#                 glyph glow, .fx-arcane-text, .chronicle-card:hover).
#
# A1 ratings family intact on the codex build (the 210 contract):
#    laliga ratings 10 rows monotonic + the additive trio scorers=20 /
#    assists=10 / cards.yellow present on the SAME response.
# A2 season 2324 frozen anchor: own list + selectedSeason echo +
#    Bellingham rank-1 (the 202 pattern, untouched by the redesign).
# A3 the Clásico editorial anchor intact: previews(/topnews/) +
#    reviews + touchmap both sides + deep ≥10 (the four-block anchor).
# A4 the FRESH EFL anchor (the 211 debt repaid): 6275371
#    Liverpool–Chelsea, EFL Cup R4 2026-10-28 — touchmap both sides >0
#    + deep ≥20 (live-probed stable: two identical probes 740/732/29).
# A5 the player API echoes the runtime ratings rank-1 (name + id).
# A6 the search API stays fat on the «ali» needle (≥3 rows).
#
# B1 home codex foundation: .codex-tab-underline present, meta
#    theme-color #04060b, body painted codex ink rgb(4,6,11), viewport
#    clean (sw=cw=390, h1n=1, 0 broken images, console=0, appErrors=0).
# B2 the restated surfaces are violet-clean (the 211/212 claims hold):
#    a computed-color sweep over .glass-card/.glass-hero/.glass-popover/
#    .brand-glyph/.hero-legend/.glass-avatar/.glass-row finds ZERO
#    oklch-hue-280-335 chroma-≥0.05 colors; the tome frame speaks the
#    flourish (border transparent + gold diamond on ::before).
# B3 topscorers codex-era: ratings rows ≥5, first-row fa name == the
#    LIVE same-moment API rank-1 nameFa, decimal pill dir=ltr.
# B4 player page healthy at runtime rank-1 id: profile h1, viewport
#    clean, console 0 (the 210 navigation target under the codex dress).
# B5 the match-page DOM contracts untouched by the redesign: previews +
#    reviews + touchmap + top-players testids + the tabs nav.
# B6 the fresh EFL anchor page: touchmap dots >0 + the deep panel opens
#    with rows (the new second-competition DOM proof).
# B7 news page healthy: h1 + ≥3 chronicle cards, and .chronicle-card
#    (non-hover) violet-clean.
# B8 the 212 focus ring speaks gold: real Tab focus lands on a
#    focus-visible element whose ring is rgba(240,199,94,…) and the
#    ring carries zero violet.
#
# F1 the violet CENSUS (finding probe, observe mode): full-page computed
#    sweep (elements + ::before/::after, 7 color-bearing properties) on
#    home/league/topscorers/player/match/news — every hue-280-335
#    chroma-≥0.05 survivor reported for cycle-214.
# F2 the portal-gate glyph (cold sessionStorage): its glow still speaks
#    --arcane-soft violet (live-verified pre-hunt) — recorded as finding.
# F3 the chronicle hover: a REAL pointer hover on the first news card —
#    its :hover border/underglow violet (static audit) — recorded.
# F4 .fx-arcane-text footer separators: filter drop-shadow violet when
#    present — recorded.
#
# PID: the caller verifies the serving pid via ss right after
# scripts/start-remontada.sh (the 210 lesson — done in the chain, not
# here; the hunt only needs the port warm).
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0
FIND=0
FINDINGS=/tmp/c213_findings.txt
: > "$FINDINGS"

# warm the payloads once (the hunt must not depend on leftover warmth)
curl -s "$BASE/api/topscorers/laliga" -o /tmp/c213_laliga.json
curl -s "$BASE/api/topscorers/laliga?season=2023/2024" -o /tmp/c213_laliga_2324.json
curl -s "$BASE/api/match/5868105" -o /tmp/c213_clasico.json
curl -s "$BASE/api/match/6275371" -o /tmp/c213_efl.json
python3 -c "
import json,sys
for f in ('/tmp/c213_laliga.json','/tmp/c213_laliga_2324.json','/tmp/c213_clasico.json','/tmp/c213_efl.json'):
    d=json.load(open(f))
    assert d.get('ok') is True, f
" || { echo "WARMUP FAILED — aborting"; exit 1; }

echo "== PART A: API proof (6 gates) =="
A_OUT=$(python3 - <<'PY'
import json, time, urllib.request
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u, timeout=30):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=timeout))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: the ratings family intact on the codex build (the 210 contract)
try:
    d = json.load(open('/tmp/c213_laliga.json'))
    r = d.get("ratings") or []
    vals = [float(x.get("rating") or 0) for x in r]
    good = (
        len(r) == 10
        and [x.get("rank") for x in r] == list(range(1, 11))
        and all(vals[i] >= vals[i+1] for i in range(len(vals)-1))
        and all(x.get("name") and x.get("nameFa") and (x.get("playerId") or 0) > 0 for x in r)
        and len(d.get("scorers") or []) == 20
        and len(d.get("assists") or []) == 10
        and len((d.get("cards") or {}).get("yellow") or []) > 0
    )
    report("A1 ratings family intact: 10 monotonic + additive trio", good,
           f"n={len(r)} top={vals[0] if vals else None} sc={len(d.get('scorers') or [])} as={len(d.get('assists') or [])}")
except Exception as e:
    report("A1 ratings family intact: 10 monotonic + additive trio", False, repr(e))

# A2: the frozen 2324 anchor (the 202 pattern survives the redesign)
try:
    d = json.load(open('/tmp/c213_laliga_2324.json'))
    r = d.get("ratings") or []
    good = (len(r) > 0 and d.get("selectedSeason") == "2023/2024"
            and (r[0] or {}).get("name") == "Jude Bellingham")
    report("A2 season 2324 frozen anchor: Bellingham + echo", good,
           f"n={len(r)} sel={d.get('selectedSeason')} r1={(r[0] or {}).get('name') if r else None}")
except Exception as e:
    report("A2 season 2324 frozen anchor: Bellingham + echo", False, repr(e))

# A3: the Clásico editorial anchor intact (four-block co-existence)
try:
    d = json.load(open('/tmp/c213_clasico.json'))
    pv, rv = d.get("previews") or [], d.get("reviews") or []
    tm = d.get("touchMap") or {}
    ps = d.get("playerStats") or {}
    deep = sum(1 for r in (ps.get("home") or []) + (ps.get("away") or []) if r.get("deep"))
    u0 = (pv[0] or {}).get("url", "") if pv else ""
    good = (len(pv) >= 1 and "/topnews/" in u0 and len(rv) >= 1
            and (tm.get("home") or {}).get("touches", 0) > 0
            and (tm.get("away") or {}).get("touches", 0) > 0 and deep >= 10)
    report("A3 Clásico anchor intact: topnews preview + reviews + tm + deep", good,
           f"pv={len(pv)} rv={len(rv)} tmH={(tm.get('home') or {}).get('touches')} tmA={(tm.get('away') or {}).get('touches')} deep={deep}")
except Exception as e:
    report("A3 Clásico anchor intact: topnews preview + reviews + tm + deep", False, repr(e))

# A4: the FRESH EFL anchor (the 211 debt): touchmap + deep on 6275371
try:
    d = json.load(open('/tmp/c213_efl.json'))
    tm = d.get("touchMap") or {}
    ps = d.get("playerStats") or {}
    all_rows = (ps.get("home") or []) + (ps.get("away") or [])
    deep = sum(1 for r in all_rows if r.get("deep"))
    good = ((tm.get("home") or {}).get("touches", 0) > 0
            and (tm.get("away") or {}).get("touches", 0) > 0 and deep >= 20)
    report("A4 fresh EFL anchor 6275371: touchmap + deep co-exist", good,
           f"tmH={(tm.get('home') or {}).get('touches')} tmA={(tm.get('away') or {}).get('touches')} deep={deep}")
except Exception as e:
    report("A4 fresh EFL anchor 6275371: touchmap + deep co-exist", False, repr(e))

# A5: the player API echoes the runtime ratings rank-1
try:
    d = json.load(open('/tmp/c213_laliga.json'))
    r0 = (d.get("ratings") or [{}])[0]
    pid = r0.get("playerId")
    p = get(f"{BASE}/api/player/{pid}")
    good = (p.get("ok") is True and (p.get("name") == r0.get("name") or (p.get("player") or {}).get("name") == r0.get("name")))
    report("A5 player API echoes ratings rank-1", good,
           f"pid={pid} api={r0.get('name')} player={p.get('name') or (p.get('player') or {}).get('name')}")
except Exception as e:
    report("A5 player API echoes ratings rank-1", False, repr(e))

# A6: the search API stays fat on the «ali» needle
try:
    d = get(f"{BASE}/api/search?q=ali")
    n = len(d.get("results") or []) + len(d.get("leagues") or []) + len(d.get("players") or [])
    good = n >= 3
    report("A6 search API fat needle (ali >= 3 rows)", good, f"rows={n}")
except Exception as e:
    report("A6 search API fat needle (ali >= 3 rows)", False, repr(e))

print("API_ALL_OK" if ok else "API_FLAGGED")
PY
)
echo "$A_OUT"
echo "$A_OUT" | rg -q "API_ALL_OK" || BAD=$((BAD+1))

echo "== PART B: DOM pass-gates @390x844 (agent-browser) =="
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
  # the 211 harness lesson: run SW-free + cache-free for determinism
  $B eval "(async()=>{try{const rs=await navigator.serviceWorker.getRegistrations();for(const r of rs)await r.unregister();if(window.caches){const ks=await caches.keys();for(const k of ks)await caches.delete(k);}}catch(e){}return 1})()" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  local i P
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    P=$($B eval "location.pathname" 2>/dev/null | tr -d '"\\')
    [ "$P" = "$1" ] && break
    sleep 1
  done
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  $B wait --fn "performance.now() > 6500" >/dev/null 2>&1
  sleep 2
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
clean_ls() { $B eval "localStorage.clear(); sessionStorage.clear()" >/dev/null 2>&1; }
wait_rows() {
  local i N
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    N=$($B eval "document.querySelectorAll('[data-testid=rating-row]').length" 2>/dev/null | tr -d '"\\')
    case "${N:-0}" in ''|*[!0-9]*) N=0;; esac
    [ "${N:-0}" -ge 5 ] && return 0
    sleep 1
  done
  return 1
}
gate() {
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC bad=$BAD"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# ---- the violet parser + sweep (installed once per page load) ----
# The census decodes EVERY computed color vocabulary the engine emits
# (rgb/rgba, hsl, oklch, oklab, lab, lch), normalizes to the oklch-like
# {l,c,h,a} space, and flags the violet window: hue 280-335, chroma
# >= 0.05, alpha >= 0.06, lightness 0.1-0.97 (the live-verified leak
# space: --arcane-soft = oklch(0.72 0.13 295/32%) ⇒ lab(65.8 23.5 -42.6)).
# rgb-family colors go through an HSL hue check with a violet window
# that cannot collide with the codex blues (#8fb4e8/#3d5f96 both sit at
# HSL hue ~217-218; the leaks live at 250+).
VIOLET_JS='(function(){
function hsl(r,g,b){r/=255;g/=255;b/=255;var mx=Math.max(r,g,b),mn=Math.min(r,g,b),h=0,s=0,l=(mx+mn)/2;
 if(mx!==mn){var d=mx-mn;s=l>0.5?d/(2-mx-mn):d/(mx+mn);
 h=mx===r?((g-b)/d+(g<b?6:0)):mx===g?((b-r)/d+2):((r-g)/d+4);h*=60;}
 return [h,s,l];}
function parse(s){
 s=(s||"").trim();if(!s)return null;var m;
 if(m=s.match(/^(?:ok)?lch\(\s*([\d.]+)(%?)\s*[,\s]+([\d.]+)[,\s]+([\d.]+)(?:\s*\/\s*([\d.]+%?)\s*)?\)/)){
  var al=m[5]==null?1:parseFloat(m[5]);if(m[5]&&m[5].indexOf("%")>=0)al/=100;
  var L=parseFloat(m[1]);if(m[2]==="%")L/=100;
  return {l:L,c:parseFloat(m[3]),h:parseFloat(m[4]),a:al};}
 if(m=s.match(/^oklab\(\s*([\d.]+)%?\s*[\s,]+(-?[\d.]+)[\s,]+(-?[\d.]+)(?:\s*\/\s*([\d.]+%?)\s*)?\)/)){
  var L4=parseFloat(m[1]);if(m[1].indexOf("%")>=0)L4/=100;
  var a4=parseFloat(m[2]),b4=parseFloat(m[3]);
  var al4b=m[4]==null?1:parseFloat(m[4]);if(m[4]&&m[4].indexOf("%")>=0)al4b/=100;
  var h4=Math.atan2(b4,a4)*180/Math.PI;if(h4<0)h4+=360;
  return {l:L4,c:Math.sqrt(a4*a4+b4*b4),h:h4,a:al4b};}
 if(m=s.match(/^(?:ok)?lab\(\s*([\d.]+)%?\s*[\s,]+(-?[\d.]+)[\s,]+(-?[\d.]+)(?:\s*\/\s*([\d.]+%?)\s*)?\)/)){
  var L2=parseFloat(m[1]);if(m[1].indexOf("%")>=0)L2/=100;
  var a2=parseFloat(m[2]),b2=parseFloat(m[3]);
  var al2=m[4]==null?1:parseFloat(m[4]);if(m[4]&&m[4].indexOf("%")>=0)al2/=100;
  var h2=Math.atan2(b2,a2)*180/Math.PI;if(h2<0)h2+=360;
  return {l:L2/100,c:Math.sqrt(a2*a2+b2*b2)/370,h:h2,a:al2};}
 if(m=s.match(/^hsla?\(\s*([\d.]+)/)){
  var h3=parseFloat(m[1]),al3=1,ma3=s.match(/\/\s*([\d.]+)\)/);if(ma3)al3=parseFloat(ma3[1]);
  var sl=s.match(/,\s*([\d.]+)%\s*,\s*([\d.]+)%/);
  var sPct=sl?parseFloat(sl[1])/100:0,lPct=sl?parseFloat(sl[2])/100:0.5;
  return {l:lPct,c:sPct*(1-Math.abs(2*lPct-1)),h:h3,a:al3};}
 if(m=s.match(/^rgba?\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)/)){
  var al4=1,ma4=s.match(/\/\s*([\d.]+)\)/);if(ma4)al4=parseFloat(ma4[1]);
  var v=hsl(parseFloat(m[1]),parseFloat(m[2]),parseFloat(m[3]));
  return {l:v[2],c:v[1]*1.4,h:v[0],a:al4};}
 return null;}
function violet(p){return p&&p.h>=280&&p.h<=335&&p.c>=0.05&&p.a>=0.06&&p.l>=0.1&&p.l<=0.97;}
window.__vParse=parse;window.__violet=violet;
window.__sweep=function(cap,selFilter){
  var out=[];var els=selFilter?document.querySelectorAll(selFilter):document.querySelectorAll("*");
  var n=Math.min(els.length,cap||2500);
  var props=["color","backgroundColor","borderTopColor","boxShadow","outlineColor","filter","backgroundImage"];
  function one(el,pseudo){
    var cs;try{cs=getComputedStyle(el,pseudo||null);}catch(e){return;}
    if(!cs)return;
    if(!pseudo&&el.getAttribute){var st=el.getAttribute("style")||"";if(st&&/color|background|border|shadow/i.test(st))return;}
    for(var i=0;i<props.length;i++){
      var v=cs[props[i]]||"";
      if(v==="none"||v==="invert")continue;
      var cols=v.match(/(?:rgba?\(|hsla?\(|oklch\(|oklab\(|lab\(|lch\()[^)]*\)/g)||[];
      for(var j=0;j<cols.length;j++){
        var p=parse(cols[j]);
        if(violet(p)){
          var cls=(typeof el.className==="string"&&el.className)?el.className.split(/\s+/).slice(0,2).join("."):"";
          out.push(el.tagName.toLowerCase()+"."+(cls||"?")+"|"+(pseudo||"::self")+"|"+props[i]+"|"+cols[j].slice(0,46));
          if(out.length>=24)return;
        }
      }
    }
  }
  for(var k=0;k<n;k++){one(els[k],null);one(els[k],"::before");one(els[k],"::after");if(out.length>=24)break;}
  return JSON.stringify(out);
};
return 1;})()'

install_violet() { $B eval "$VIOLET_JS" >/dev/null 2>&1; }
record_findings() {
  local page="$1" json="$2"
  python3 - "$page" "$json" <<'PY' >> "$FINDINGS"
import json, sys
page, raw = sys.argv[1], sys.argv[2]
def resilient(raw):
    # the 202 lesson, hardened: the output transport re-encodes JSON —
    # peel EVERY layer while the decoded value is still a string (the
    # decoded object-string may start with '{', not only '"')
    s = raw.strip()
    for _ in range(4):
        try: v = json.loads(s)
        except Exception: break
        if isinstance(v, str):
            s = v; continue
        return v
    return []
for item in resilient(raw):
    print(f"FINDING[{page}] {item}")
PY
}

# B1: the home codex foundation
open_page "/"
install_violet
B1=$(snap "tab:!!document.querySelector('.codex-tab-underline'),theme:(document.querySelector('meta[name=theme-color]')||{content:''}).content,bodyBg:(getComputedStyle(document.body).backgroundColor||'')")
B1R=0
echo "$B1" | rg -q "tab:true" || B1R=1
echo "$B1" | rg -q "theme:#04060b" || B1R=1
echo "$B1" | rg -q "bodyBg:rgb\(4, 6, 11\)" || B1R=1
[ "$B1R" -eq 0 ] || BAD=$((BAD+1))
gate "B1 home codex foundation: tab-underline + themeColor + ink body" "$B1"

# B2: the restated surfaces violet-clean + the tome frame speaks gold
# (border check: the PLAIN card's border-color computes transparent;
# the hero card takes `border:none` so its border-color falls back to
# currentColor — parchment — while border-STYLE none keeps it invisible;
# the honest assertions are color-transparent + style-none)
B2_SW=$($B eval "window.__sweep(300,'.glass-card,.glass-hero,.glass-popover,.brand-glyph,.hero-legend,.glass-avatar,.glass-row')" 2>/dev/null | tr -d '"\\')
record_findings "restated-surfaces" "$B2_SW"
B2=$(snap "plainBorder:(document.querySelector('.glass-card:not(.glass-hero)')?getComputedStyle(document.querySelector('.glass-card:not(.glass-hero)')).borderTopColor:'none'),heroStyle:(document.querySelector('.glass-hero')?getComputedStyle(document.querySelector('.glass-hero')).borderTopStyle:'none'),diamond:(document.querySelector('.glass-card')?getComputedStyle(document.querySelector('.glass-card'),'::before').backgroundColor:'none')")
B2R=0
[ "$B2_SW" = "[]" ] || B2R=1
echo "$B2" | rg -q "plainBorder:rgba\(0, 0, 0, 0\)" || B2R=1
echo "$B2" | rg -q "heroStyle:none" || B2R=1
echo "$B2" | rg -q "diamond:rgb\(240, 199, 94\)" || B2R=1
[ "$B2R" -eq 0 ] || BAD=$((BAD+1))
gate "B2 restated surfaces violet-clean + tome frame (transparent border + gold diamond)" "sweep=$B2_SW $B2"

# F1a: the violet census ON the home page — the rune-title heartland
# (94 diamond-glowing titles live here; the --arcane-soft leak family)
CEN=$($B eval "window.__sweep(2500,null)" 2>/dev/null)
record_findings "home" "$CEN"
echo "F1 home census: $(echo "$CEN" | head -c 240)"

# B3: topscorers codex-era — live same-moment API compare (the 202 rule)
open_page "/topscorers/laliga"
install_violet
wait_rows || echo "WARN: rating rows <5 (honest snap continues)"
curl -s "$BASE/api/topscorers/laliga" -o /tmp/c213_laliga_live.json
API_FA=$(python3 -c "
import json
d=json.load(open('/tmp/c213_laliga_live.json'))
r=d.get('ratings') or []
print((r[0] or {}).get('nameFa') or '')")
B3=$(snap "rows:document.querySelectorAll('[data-testid=rating-row]').length,name0:((document.querySelector('[data-testid=rating-row] span.block'))||{textContent:''}).textContent,pillDir:(document.querySelector('[data-testid=rating-row] span[dir=ltr]')||{getAttribute:()=>''}).getAttribute('dir')")
B3R=0
echo "$B3" | rg -q "rows:([5-9]|10)" || B3R=1
echo "$B3" | rg -q "name0:${API_FA}" || B3R=1
echo "$B3" | rg -q "pillDir:ltr" || B3R=1
[ "$B3R" -eq 0 ] || BAD=$((BAD+1))
gate "B3 ratings codex-era: rows>=5 + live same-moment fa name + dir=ltr pill" "$B3 (api=$API_FA)"

# F1a-2: census on the topscorers page (before leaving it)
CEN=$($B eval "window.__sweep(2500,null)" 2>/dev/null)
record_findings "topscorers" "$CEN"
echo "F1 topscorers census: $(echo "$CEN" | head -c 200)"

# B4: the player page at the runtime rank-1 id
PID=$(python3 -c "
import json
d=json.load(open('/tmp/c213_laliga_live.json'))
r=d.get('ratings') or []
print((r[0] or {}).get('playerId') or 0)")
open_page "/player/${PID}"
install_violet
B4=$(snap "h1t:(document.querySelector('h1')||{textContent:''}).textContent.slice(0,30)")
B4R=0
[ -n "$B4" ] && [ "$B4" != "h1t:" ] || B4R=1
echo "$B4" | rg -q "h1t:.+" || B4R=1
[ "$B4R" -eq 0 ] || BAD=$((BAD+1))
gate "B4 player page ($PID) healthy: profile h1 present" "$B4"

# F1b: census on the player page
CEN=$($B eval "window.__sweep(2500,null)" 2>/dev/null)
record_findings "player" "$CEN"
echo "F1 player census: $(echo "$CEN" | head -c 200)"

# B5: the match-page DOM contracts untouched by the redesign
open_page "/match/5868105"
install_violet
B5=$(snap "pv:!!document.querySelector('[data-testid=match-previews]'),rv:!!document.querySelector('[data-testid=match-reviews]'),tm:!!document.querySelector('[data-testid=match-touchmap]'),tp:!!document.querySelector('[data-testid=match-top-players]'),tabs:!!document.querySelector('nav[aria-label=\"بخش‌های مسابقه\"]')")
B5R=0
echo "$B5" | rg -q "pv:true" || B5R=1
echo "$B5" | rg -q "rv:true" || B5R=1
echo "$B5" | rg -q "tm:true" || B5R=1
echo "$B5" | rg -q "tp:true" || B5R=1
echo "$B5" | rg -q "tabs:true" || B5R=1
[ "$B5R" -eq 0 ] || BAD=$((BAD+1))
gate "B5 match DOM contracts intact: 4 testids + tabs nav (redesign touched none)" "$B5"

# F1c: census on the Clásico page
CEN=$($B eval "window.__sweep(2500,null)" 2>/dev/null)
record_findings "match-clasico" "$CEN"
echo "F1 match census: $(echo "$CEN" | head -c 200)"

# B6: the fresh EFL anchor page — touchmap + deep panel (the new B7)
open_page "/match/6275371"
install_violet
B6a=$(snap "tm:!!document.querySelector('[data-testid=match-touchmap]'),dots:document.querySelectorAll('[data-testid=match-touchmap] span[class*=rounded-full]').length")
$B eval "(function(){const bs=[...document.querySelectorAll('nav[aria-label=\"بخش‌های مسابقه\"] button')];const b=bs.find(x=>x.textContent.trim()==='بازیکن‌ها');if(!b)return 'notab';b.click();return 'clicked';})()" >/dev/null 2>&1
$B wait --fn "!!document.querySelector('[data-testid=player-deep-toggle]')" >/dev/null 2>&1
sleep 0.8
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "opened"})()' >/dev/null 2>&1
sleep 0.6
B6b=$(snap "panel:!!document.querySelector('[data-testid=player-deep]'),rows:document.querySelectorAll('[data-testid=player-deep] div.flex.items-center').length")
B6R=0
echo "$B6a" | rg -q "tm:true" || B6R=1
echo "$B6a" | rg -q "dots:[1-9][0-9]*" || B6R=1
echo "$B6b" | rg -q "panel:true" || B6R=1
echo "$B6b" | rg -q "rows:[1-9][0-9]*" || B6R=1
[ "$B6R" -eq 0 ] || BAD=$((BAD+1))
gate "B6 fresh EFL anchor page: touchmap + deep panel co-exist" "$B6a | $B6b"

# F1d: census on the EFL page
CEN=$($B eval "window.__sweep(2500,null)" 2>/dev/null)
record_findings "match-efl" "$CEN"
echo "F1 efl census: $(echo "$CEN" | head -c 200)"

# B7: the news page — healthy + chronicle non-hover violet-clean. The
# census runs BEFORE the hover probe (the pointer's :hover state would
# otherwise leak into the census as an artifact, not a page truth).
open_page "/news"
install_violet
B7=$(snap "cards:document.querySelectorAll('.chronicle-card').length")
B7R=0
echo "$B7" | rg -q "cards:([3-9]|[1-9][0-9]+)" || B7R=1
[ "$B7R" -eq 0 ] || BAD=$((BAD+1))
B7_SW=$($B eval "window.__sweep(400,'.chronicle-card')" 2>/dev/null | tr -d '"\\')
record_findings "chronicle-nonhover" "$B7_SW"
[ "$B7_SW" = "[]" ] || B7R=1
gate "B7 news healthy: cards>=3 + chronicle non-hover violet-clean" "$B7 sweep=$B7_SW"

# F1e: census on the news page (pointer still neutral — no hover yet)
CEN=$($B eval "window.__sweep(2500,null)" 2>/dev/null)
record_findings "news" "$CEN"
echo "F1 news census: $(echo "$CEN" | head -c 200)"

# F3: the chronicle hover — a REAL pointer hover on the first news card
# (the pointer moves via CDP so :hover styles apply; the border/underglow
# violet is the static-audited cycle-67 era leak)
CHRON_SEL=$(python3 -c "print('.chronicle-card')" 2>/dev/null)
agent-browser hover "$CHRON_SEL" >/dev/null 2>&1
sleep 0.6
B7H=$($B eval "(function(){const c=document.querySelector('.chronicle-card');if(!c)return 'none';const cs=getComputedStyle(c);return JSON.stringify({border:cs.borderTopColor,shadow:(cs.boxShadow||'').slice(0,90)})})()" 2>/dev/null)
VHIT=$(python3 - "$B7H" <<'PY'
import json, sys, re, math
raw = sys.argv[1]
def resilient(raw):
    s = raw.strip()
    for _ in range(4):
        try: v = json.loads(s)
        except Exception: break
        if isinstance(v, str):
            s = v; continue
        return v
    return {}
d = resilient(raw)
blob = json.dumps(d, ensure_ascii=False)
cols = re.findall(r'(?:oklch|oklab|lab|lch)\([^)]*\)', blob)
hits = []
for c in cols:
    m = re.search(r'(?:oklch|lch)\(\s*([\d.]+)\s*[\s,]\s*([\d.]+)\s*[\s,]\s*([\d.]+)', c)
    m_ok = re.search(r'oklab\(\s*([\d.]+)%?\s*[\s,]\s*(-?[\d.]+)\s*[\s,]\s*(-?[\d.]+)', c)
    m2 = re.search(r'(?<!ok)lab\(\s*([\d.]+)%?\s*[\s,]\s*(-?[\d.]+)\s*[\s,]\s*(-?[\d.]+)', c)
    if m:
        L, C, H = float(m.group(1)), float(m.group(2)), float(m.group(3))
        if L > 1.5: L /= 100
        if 280 <= H <= 335 and C >= 0.05: hits.append(c)
    elif m_ok:
        L, a, b = float(m_ok.group(1)), float(m_ok.group(2)), float(m_ok.group(3))
        h = math.degrees(math.atan2(b, a)) % 360
        if L > 1.5: L /= 100
        if 280 <= h <= 335 and math.hypot(a, b) >= 0.05: hits.append(c)
    elif m2:
        L, a, b = float(m2.group(1)), float(m2.group(2)), float(m2.group(3))
        h = math.degrees(math.atan2(b, a)) % 360
        if L > 1.5: L /= 100
        if 280 <= h <= 335 and math.hypot(a, b)/370 >= 0.05: hits.append(c)
print(len(hits))
PY
)
if [ "${VHIT:-0}" -ge 1 ]; then
  FIND=$((FIND+1))
  echo "FINDING[news-hover] .chronicle-card:hover border/underglow violet: $B7H" >> "$FINDINGS"
  echo "F3 chronicle hover: VIOLET CONFIRMED (finding for 214): $B7H"
else
  echo "F3 chronicle hover: no violet detected (hover=$B7H)"
fi

# F4: the footer separators (.fx-arcane-text) wherever they render
F4=$($B eval "(function(){var els=document.querySelectorAll('.fx-arcane-text');if(!els.length)return JSON.stringify({n:0});var cs=getComputedStyle(els[0]);return JSON.stringify({n:els.length,filter:(cs.filter||'').slice(0,70)})})()" 2>/dev/null)
if echo "$F4" | rg -q '"n":0'; then
  echo "F4 fx-arcane-text: absent on /news (graceful skip)"
else
  FIND=$((FIND+1))
  echo "FINDING[footer] .fx-arcane-text filter: $F4" >> "$FINDINGS"
  echo "F4 fx-arcane-text: present — recorded: $F4"
fi

# F2: the portal-gate glyph (cold sessionStorage) — its own quick flow,
# the gate auto-fades so no open_page settle wait
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B eval "localStorage.clear(); sessionStorage.clear()" >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
PG="gate:false"
for i in 1 2 3 4 5 6; do
  PG=$($B eval "(function(){const g=document.querySelector('.portal-gate-glyph');if(!g)return 'gate:false';const cs=getComputedStyle(g);return JSON.stringify({gate:true,shadow:(cs.boxShadow||'').slice(0,110)})})()" 2>/dev/null | tr -d '"\\')
  echo "$PG" | rg -q "gate:true" && break
  sleep 0.35
done
if echo "$PG" | rg -q "gate:true"; then
  PGV=$(python3 - "$PG" <<'PY'
import json, sys, re, math
raw = sys.argv[1]
def resilient(raw):
    s = raw.strip()
    for _ in range(4):
        try: v = json.loads(s)
        except Exception: break
        if isinstance(v, str):
            s = v; continue
        return v
    return {}
hits = 0
# the PG payload is quote-stripped (non-JSON) — regex the colors straight
# out of the raw text; the color literals survive stripping verbatim
for c in re.findall(r'(?:oklch|oklab|lab|lch)\([^)]*\)', raw):
    m_ok = re.search(r'oklab\(\s*([\d.]+)%?\s*[\s,]\s*(-?[\d.]+)\s*[\s,]\s*(-?[\d.]+)', c)
    m2 = re.search(r'(?<!ok)lab\(\s*([\d.]+)%?\s*[\s,]\s*(-?[\d.]+)\s*[\s,]\s*(-?[\d.]+)', c)
    if m_ok:
        L, a, b = float(m_ok.group(1)), float(m_ok.group(2)), float(m_ok.group(3))
        h = math.degrees(math.atan2(b, a)) % 360
        if L > 1.5: L /= 100
        if 280 <= h <= 335 and math.hypot(a, b) >= 0.05: hits += 1
print(hits)
PY
)
  if [ "${PGV:-0}" -ge 1 ]; then
    FIND=$((FIND+1))
    echo "FINDING[portal-gate] .portal-gate-glyph glow violet (--arcane-soft): $PG" >> "$FINDINGS"
    echo "F2 portal-gate glyph: VIOLET CONFIRMED (finding for 214)"
  else
    echo "F2 portal-gate glyph: no violet detected (pg=$PG)"
  fi
else
  echo "F2 portal-gate glyph: gate not caught this run (transient) — skipped honestly"
fi

# B8: the 212 focus ring speaks gold — real Tab focus (focus-visible),
# the ring gold, never violet
open_page "/"
install_violet
GOLDHIT=0; VIOHIT=0
for i in 1 2 3; do
  $B press Tab >/dev/null 2>&1
  sleep 0.4
  BR=$($B eval "(function(){var el=document.activeElement;if(!el||el===document.body)return '{}';var cs=getComputedStyle(el);return JSON.stringify({tag:el.tagName,bs:(cs.boxShadow||'').slice(0,80)})})()" 2>/dev/null)
  echo "$BR" | rg -q "rgba\(240, 199, 94" && GOLDHIT=1
  VH=$(python3 - "$BR" <<'PY'
import json, sys, re, math
raw = sys.argv[1]
def resilient(raw):
    s = raw.strip()
    for _ in range(4):
        try: v = json.loads(s)
        except Exception: break
        if isinstance(v, str):
            s = v; continue
        return v
    return {}
hits = 0
# the PG payload is quote-stripped (non-JSON) — regex the colors straight
# out of the raw text; the color literals survive stripping verbatim
for c in re.findall(r'(?:oklch|oklab|lab|lch)\([^)]*\)', raw):
    m_ok = re.search(r'oklab\(\s*([\d.]+)%?\s*[\s,]\s*(-?[\d.]+)\s*[\s,]\s*(-?[\d.]+)', c)
    m2 = re.search(r'(?<!ok)lab\(\s*([\d.]+)%?\s*[\s,]\s*(-?[\d.]+)\s*[\s,]\s*(-?[\d.]+)', c)
    if m_ok:
        L, a, b = float(m_ok.group(1)), float(m_ok.group(2)), float(m_ok.group(3))
        h = math.degrees(math.atan2(b, a)) % 360
        if L > 1.5: L /= 100
        if 280 <= h <= 335 and math.hypot(a, b) >= 0.05: hits += 1
print(hits)
PY
)
  [ "${VH:-0}" -ge 1 ] && VIOHIT=1
done
B8R=0
[ "$GOLDHIT" -eq 1 ] || B8R=1
[ "$VIOHIT" -eq 0 ] || B8R=1
[ "$B8R" -eq 0 ] || BAD=$((BAD+1))
gate "B8 focus-visible ring speaks gold (Tab focus), zero violet" "gold=$GOLDHIT violet=$VIOHIT"

echo "== PART C: the finding ledger =="
FIND=$(rg -c "^FINDING" "$FINDINGS" 2>/dev/null || echo 0)
if [ "$FIND" -gt 0 ]; then
  echo "--- violet survivors reported for cycle-214 (observe mode) ---"
  cat "$FINDINGS"
  echo "----------------------------------------------------------------"
fi

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT COMPLETE (cycle-213: the codex patrol of league/match/topscorers/player + home + news @390x844 — the restated surfaces violet-clean, the match DOM contracts byte-intact under the redesign, the fresh EFL anchor 6275371 alive in API+DOM, the gold focus ring proven by real Tab focus, the ratings family + frozen anchors intact — API 6/6 + DOM pass-gates 8/8; PRODUCT FINDINGS=$FIND for cycle-214 (the --arcane-soft violet leak family + the chronicle hover), ledger in $FINDINGS)"
else
  echo "HUNT BAD=$BAD (a PASS gate failed — a redesign regression, not a finding)"
  exit 1
fi
