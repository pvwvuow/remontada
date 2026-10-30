#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle214-fixproof.sh — the fix cycle's own 4-root proof (cycle 214).
# The cycle-213 census collapsed 47 violet survivors into 4 roots; this
# fix cycle closes them ADDITIVELY (one token line + three override
# blocks; nav-dock.tsx untouched, zero DOM/testid/pinned-text changes):
#   root 1/4  --arcane-soft never re-mapped by the codex layer
#             (rune diamonds / fx-arcane-text / portal-gate glyph +
#             keyframes / rune-spin all drank violet)
#   root 2/4  .chronicle-card:hover violet border + underglow (cycle-67)
#   root 3/4  nav-dock.tsx:85 arbitrary shadow-[0_0_16px_oklch(0.7 0.1
#             300/0.28)] on the active dock item
#   root 4/4  .rune-glow violet gradient tail (unused class)
# PART A: the BUILT css carries all four restatements (last-wins).
# PART B: computed-style proof @390x844 with the cycle-213 violet parser
#         (same window: hue 280-335, c>=0.05, a>=0.06) + clean console.
# The server must already be up via scripts/start-remontada.sh (the 210
# lesson — done in the chain, not here; the proof only needs the port).
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0
CSSDIR=".next/static/chunks"

echo "== PART A: the built css carries the 4 restatements (last-wins) =="
CSS=$(cat "$CSSDIR"/*.css 2>/dev/null)
A=0
echo "$CSS" | grep -q -- "--arcane-soft:var(--codex-gold-dim)" \
  && echo "A1 root1 token: --arcane-soft → var(--codex-gold-dim) OK" \
  || { echo "A1 root1 token MISSING"; A=1; }
echo "$CSS" | grep -q 'chronicle-card:hover{box-shadow:var(--glass-halo),inset 0 1px 0 var(--glass-highlight),0 10px 30px #0000006b,0 0 18px #f0c75e1f;border-color:#f0c75e47}' \
  && echo "A2 root2 chronicle hover: gold border + gold-dust tail OK" \
  || { echo "A2 root2 chronicle hover MISSING"; A=1; }
echo "$CSS" | grep -q 'nav\[aria-label=منوی\\ بازی\] a\[aria-current=page\]{box-shadow:0 0 16px #f0c75e47}' \
  && echo "A3 root3 dock glow: gold 16px halo on aria-current=page OK" \
  || { echo "A3 root3 dock glow MISSING"; A=1; }
echo "$CSS" | grep -q 'rune-glow{color:#0000;background:linear-gradient(100deg,#f9ecc0 30%,#f0c75e 70%,#f0c75ee6)' \
  && echo "A4 root4 rune-glow: parchment→gold melt tail OK" \
  || { echo "A4 root4 rune-glow MISSING"; A=1; }
[ "$A" -eq 0 ] || BAD=$((BAD+1))

echo "== PART B: computed proof @390x844 (agent-browser, violet parser of 213) =="
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
congate() {
  local label="$1" C E
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  if [ "$C" = "0" ] && [ "$E" = "0" ]; then
    echo "$label → console=0 appErrors=0 OK"; else
    echo "$label → console=$C appErrors=$E BAD"; BAD=$((BAD+1)); fi
}
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

# ---- home: the dock glow + rune/separator filters + the full census ----
open_page "/"
install_violet
CEN=$($B eval "window.__sweep(2500,null)" 2>/dev/null | tr -d '"\\')
echo "B1 home violet census (root 1+3 heartbeat): $CEN"
[ "$CEN" = "[]" ] || BAD=$((BAD+1))

# B2: root 3/4 — the ACTIVE dock item's computed glow is the gold halo
DOCK=$($B eval '(function(){var a=document.querySelector("nav[aria-label=\"منوی بازی\"] a[aria-current=page]");if(!a)return JSON.stringify({n:0});var cs=getComputedStyle(a);return JSON.stringify({n:1,txt:a.textContent.trim().slice(0,12),shadow:(cs.boxShadow||"").slice(0,60)})})()' 2>/dev/null | tr -d '"\\')
echo "B2 dock active glow (root 3/4): $DOCK"
echo "$DOCK" | rg -q "rgba\(240, 199, 94, 0.28\)" || BAD=$((BAD+1))
echo "$DOCK" | rg -q "n:0" && BAD=$((BAD+1))

# B3: root 1/4 — the rune diamond and the footer separators glow gold
RUNE=$($B eval '(function(){var t=document.querySelector(".rune-title");if(!t)return JSON.stringify({n:0});var cs=getComputedStyle(t,"::before");return JSON.stringify({n:1,filter:(cs.filter||"").slice(0,60)})})()' 2>/dev/null | tr -d '"\\')
echo "B3 rune-title::before filter (root 1/4): $RUNE"
echo "$RUNE" | rg -q "rgba\(240, 199, 94, 0.32\)" || BAD=$((BAD+1))
congate "B5 home console"

# ---- news: the chronicle hover speaks gold (root 2/4) ----
open_page "/news"
install_violet
CH=$($B eval "window.__sweep(2500,null)" 2>/dev/null | tr -d '"\\')
echo "B6 news violet census (pre-hover): $CH"
[ "$CH" = "[]" ] || BAD=$((BAD+1))
# B9: root 1/4 — the footer separators render here (not on home; the
# 213 hunt also found them on /news with n=3)
FX=$($B eval '(function(){var els=document.querySelectorAll(".fx-arcane-text");if(!els.length)return JSON.stringify({n:0});var cs=getComputedStyle(els[0]);return JSON.stringify({n:els.length,filter:(cs.filter||"").slice(0,60)})})()' 2>/dev/null | tr -d '"\\')
echo "B9 fx-arcane-text filter on /news (root 1/4): $FX"
echo "$FX" | rg -q "rgba\(240, 199, 94, 0.32\)" || BAD=$((BAD+1))
echo "$FX" | rg -q "n:0" && BAD=$((BAD+1))
agent-browser hover ".chronicle-card" >/dev/null 2>&1
sleep 0.6
HOV=$($B eval '(function(){var c=document.querySelector(".chronicle-card");if(!c)return JSON.stringify({n:0});var cs=getComputedStyle(c);var sw=window.__sweep?window.__sweep(400,".chronicle-card"):"noparse";return JSON.stringify({n:1,border:cs.borderTopColor,shadow:(cs.boxShadow||"").slice(0,110),sweep:sw})})()' 2>/dev/null | tr -d '"\\')
echo "B7 chronicle hover (root 2/4): $HOV"
echo "$HOV" | rg -q "rgba\(240, 199, 94, 0.28\)" || BAD=$((BAD+1))
echo "$HOV" | rg -q "sweep:\[\]" || BAD=$((BAD+1))
congate "B10 news console"

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "FIXPROOF 214 COMPLETE — the 4 violet roots restated gold in the built css (A1-A4) and in the computed cascade @390x844 (census=[] home+news, dock/rune/separator/hover all gold, console=0)"
else
  echo "FIXPROOF 214 FLAGGED — BAD=$BAD"
  exit 1
fi
