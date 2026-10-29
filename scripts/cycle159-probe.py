#!/usr/bin/env python3
# cycle-159 live probe (D5: facts before fixes) — Latin-digit leak sweep over
# SSR text of every major surface. A digit leak inside Persian text = the
# class cycle-154 started covering (team page GD chip + formation) — this
# probe sweeps the REST of the surfaces.
import re, subprocess, sys

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = "http://localhost:3000"

PAGES = [
    "/", "/matches", "/news", "/topscorers", "/players", "/leagues",
    "/league/acl2", "/league/superlig", "/league/persiangulf",
    "/league/championship", "/league/portugal", "/league/uae",
    "/league/qatar", "/league/eredivisie",
    "/team/389880", "/team/102101", "/player/196041",
    "/match/6054514",
]

TAG_RE = re.compile(r"<[^>]+>")
SCRIPT_RE = re.compile(r"<script[\s\S]*?</script>|<style[\s\S]*?</style>", re.I)
# a "word" = maximal run of non-space chars containing at least one ASCII digit
LATIN_WORD_RE = re.compile(r"[^\s]*[0-9][^\s]*")

def fetch(url):
    p = subprocess.run(["curl", "-s", "-A", UA, "--max-time", "60", url],
                       capture_output=True, text=True)
    return p.stdout

def visible_text(html):
    html = SCRIPT_RE.sub(" ", html)
    html = TAG_RE.sub(" ", html)
    html = html.replace("&nbsp;", " ").replace("&amp;", "&")
    html = html.replace("&quot;", '"').replace("&#x27;", "'").replace("&lt;", "<").replace("&gt;", ">")
    return re.sub(r"\s+", " ", html)

def page_leaks(url):
    html = fetch(url)
    if not html or len(html) < 500:
        return ["__FETCH_FAIL__"]
    txt = visible_text(html)
    # skip Persian-digit words; report words with ASCII digits
    words = [w for w in LATIN_WORD_RE.findall(txt)]
    # filter out pure URLs / srcs leftovers (should be none after tag strip)
    words = [w for w in words if not w.startswith(("http", "/", "www."))]
    # collapse duplicates, keep order
    seen, out = set(), []
    for w in words:
        if w not in seen:
            seen.add(w)
            out.append(w)
    return out

total_pages_bad = 0
for path in PAGES:
    leaks = page_leaks(BASE + path)
    if leaks == ["__FETCH_FAIL__"]:
        print(f"[FETCH-FAIL] {path}")
        continue
    if leaks:
        total_pages_bad += 1
        print(f"[LATIN] {path}: {leaks[:12]}")
    else:
        print(f"[ok] {path}")

print(f"\nSUMMARY: {total_pages_bad}/{len(PAGES)} pages with Latin-digit leaks in SSR text")
sys.exit(0)
