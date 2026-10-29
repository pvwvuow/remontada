#!/usr/bin/env python3
# cycle-159 probe part 2 — Persian character hygiene sweep over SSR visible
# text of every major surface. Fresh class never swept by cycles 144-158:
#   U+064A Arabic Yeh ي  / U+0643 Arabic Kaf ك  (must be Persian ی ک U+06CC/U+06A9)
#   U+0660-0669 Arabic-Indic digits ٠-٩    (must be Persian ۰-۹ U+06F0-06F9)
#   U+0640 Tatweel ـ                       (never valid in UI text)
#   U+200E/U+200F/U+202A-202E/U+2066-2069 bidi controls (invisible hazards)
import re, subprocess, sys

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = "http://localhost:3000"
TAG_RE = re.compile(r"<[^>]+>")
SCRIPT_RE = re.compile(r"<script[\s\S]*?</script>|<style[\s\S]*?</style>", re.I)

HARAZDS = {
    "arabic-yeh": "\u064a", "arabic-kaf": "\u0643",
    "arabic-digit": "[\u0660-\u0669]", "tatweel": "\u0640",
    "bidi-ctrl": "[\u200e\u200f\u202a-\u202e\u2066-\u2069]",
}

PAGES = [
    "/", "/matches", "/news", "/topscorers", "/players", "/leagues",
    "/league/acl2", "/league/superlig", "/league/persiangulf",
    "/league/championship", "/league/portugal", "/league/uae",
    "/league/qatar", "/league/eredivisie", "/league/laliga", "/league/seriea",
    "/league/bundesliga", "/league/ligue1", "/league/europa", "/league/acl",
    "/league/uel", "/league/saudi", "/league/scottish",
    "/team/389880", "/team/102101", "/team/196041",
    "/player/196041", "/player/196041",
    "/match/6054514",
]

def fetch(url):
    return subprocess.run(["curl", "-s", "-A", UA, "--max-time", "60", url],
                          capture_output=True, text=True).stdout

def visible_text(html):
    html = SCRIPT_RE.sub(" ", html)
    html = TAG_RE.sub(" ", html)
    for a, b in [("&nbsp;", " "), ("&amp;", "&"), ("&quot;", '"'),
                 ("&#x27;", "'"), ("&lt;", "<"), ("&gt;", ">")]:
        html = html.replace(a, b)
    return re.sub(r"\s+", " ", html)

bad = 0
for path in PAGES:
    txt = visible_text(fetch(BASE + path))
    if len(txt) < 200:
        print(f"[FETCH-FAIL/EMPTY] {path}")
        continue
    hits = []
    for name, pat in HARAZDS.items():
        for m in re.finditer(pat, txt):
            s, e = max(0, m.start() - 40), min(len(txt), m.end() + 40)
            hits.append(f"{name}:…{txt[s:e]}…")
            break  # first hit per class per page is enough
    if hits:
        bad += 1
        print(f"[HIT] {path}: {hits}")
print(f"\nSUMMARY: {bad} pages with Persian character hygiene hazards")
