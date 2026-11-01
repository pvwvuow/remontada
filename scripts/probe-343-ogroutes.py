#!/usr/bin/env python3
# probe-343-ogroutes.py — bug-hunt census of the NEW dynamic OG routes (shipped 341/342)
# /api/og/[key] (24 league keys) + /api/og/person/[id] (k contract) + wiring + coach BreadcrumbList
import json, struct, subprocess, sys, urllib.request

BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"}
LEAGUE_KEYS = ["ucl","pl","laliga","seriea","bundesliga","ligue1","persiangulf","uel","uecl","acl",
               "superlig","scottish","saudi","championship","portugal","uae","qatar","eredivisie",
               "acl2","swiss","hnl","mas","poland","belgium"]
ok = fail = 0
findings = []

def get(path):
    req = urllib.request.Request(BASE + path, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, dict(r.headers), r.read()
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read()
    except Exception as e:
        return -1, {}, str(e).encode()

def png_dims(b):
    if len(b) < 33 or b[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    w, h = struct.unpack(">II", b[16:24])
    return (w, h)

def check(label, cond, detail=""):
    global ok, fail
    if cond:
        ok += 1
        print(f"  OK   {label} {detail}")
    else:
        fail += 1
        findings.append(f"{label} {detail}")
        print(f"  FAIL {label} {detail}")

print("== A. /api/og/[key] census (24 LEAGUES keys) ==")
sizes = {}
for k in LEAGUE_KEYS:
    st, hd, b = get(f"/api/og/{k}")
    dims = png_dims(b)
    ct = hd.get("Content-Type", hd.get("content-type", "?"))
    good = st == 200 and ct == "image/png" and dims == (1200, 630) and len(b) > 10000
    sizes[k] = len(b)
    if not good:
        check(f"og/{k}", False, f"status={st} ct={ct} dims={dims} size={len(b)}")
check("og/24-keys all 200+png+1200x630+>10KB", fail == 0, f"(distinct sizes: {len(set(sizes.values()))})")

st, hd, b = get("/api/og/nonexistent")
check("og/unknown-key -> 404", st == 404, f"status={st}")
st, hd, b = get("/api/og/PL")  # case sensitivity probe
check("og/case-PL -> 404", st == 404, f"status={st}")

print("== B. person route + k contract ==")
cases = [
    ("/api/og/person/696679?k=player", 200),
    ("/api/og/person/30889?k=coach", 200),
    ("/api/og/person/696679", 200),          # no-hint fallback
    ("/api/og/person/999999999", 404),       # unknown id
]
for p, want in cases:
    st, hd, b = get(p)
    dims = png_dims(b)
    check(f"{p} -> {want} png1200x630", st == want and (want != 200 or dims == (1200, 630)),
          f"status={st} dims={dims} size={len(b)}")
# edge probes: bogus k, non-numeric id
st, hd, b = get("/api/og/person/696679?k=bogus")
check("person/696679?k=bogus -> 200 (fallback) png", st == 200 and png_dims(b) == (1200, 630), f"status={st} dims={png_dims(b)}")
st, hd, b = get("/api/og/person/abc")
check("person/abc -> 404", st == 404, f"status={st}")

print("== C. cache headers ==")
for p in ["/api/og/pl", "/api/og/person/696679?k=player"]:
    st, hd, b = get(p)
    cc = hd.get("Cache-Control", hd.get("cache-control", "(none)"))
    print(f"  {p}: Cache-Control={cc}")
    check(f"cache-control present on {p}", "max-age" in cc or "s-maxage" in cc, "")

print("== D. byte-distinctness of league cards ==")
pairs = [("pl","laliga"),("ucl","uel"),("persiangulf","mas")]
for a, c in pairs:
    check(f"cards differ {a} vs {c}", sizes.get(a) != sizes.get(c), f"{sizes.get(a)} vs {sizes.get(c)}")

print("== E. og:image wiring across surfaces ==")
wiring = [
    ("/league/pl",        "https://remontada.vercel.app/api/og/pl"),
    ("/league/ucl",       "https://remontada.vercel.app/api/og/ucl"),
    ("/league/persiangulf","https://remontada.vercel.app/api/og/persiangulf"),
    ("/topscorers/pl",    "https://remontada.vercel.app/api/og/pl"),
    ("/topscorers/acl",   "https://remontada.vercel.app/api/og/acl"),
    ("/player/696679",    "https://remontada.vercel.app/api/og/person/696679?k=player"),
    ("/coach/30889",      "https://remontada.vercel.app/api/og/person/30889?k=coach"),
]
for page, want in wiring:
    st, hd, b = get(page)
    html = b.decode("utf-8", "replace")
    has = want in html
    check(f"og:image wiring {page}", st == 200 and has, f"status={st} want={want}")

print("== F. coach BreadcrumbList JSON-LD ==")
st, hd, b = get("/coach/30889")
html = b.decode("utf-8", "replace")
import re
blocks = re.findall(r'<script type="application/ld\+json"[^>]*>(.*?)</script>', html, re.S)
crumb = None
for blk in blocks:
    try:
        j = json.loads(blk)
    except Exception:
        findings.append("unparseable ld+json block on /coach/30889"); continue
    g = j.get("@graph", [j])
    for node in (g if isinstance(g, list) else [g]):
        if node.get("@type") == "BreadcrumbList":
            crumb = node
check("coach BreadcrumbList present+valid", crumb is not None,
      f"blocks={len(blocks)}")
if crumb:
    names = [it.get("name") for it in crumb.get("itemListElement", [])]
    print(f"  crumb names: {names}")
    check("crumb starts خانه", bool(names) and names[0] == "خانه", f"{names}")

print(f"\n== RESULT: ok={ok} fail={fail} ==")
if findings:
    print("FINDINGS:")
    for f in findings:
        print(" -", f)
