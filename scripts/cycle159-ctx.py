#!/usr/bin/env python3
# cycle-159 context drill-down for the two probe hits: /leagues '1' and
# /player/196041 'U23' — show the sentence around each Latin-digit word.
import re, subprocess

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = "http://localhost:3000"
TAG_RE = re.compile(r"<[^>]+>")
SCRIPT_RE = re.compile(r"<script[\s\S]*?</script>|<style[\s\S]*?</style>", re.I)

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

def ctx(path, needle):
    txt = visible_text(fetch(BASE + path))
    for m in re.finditer(re.escape(needle), txt):
        s, e = max(0, m.start() - 80), min(len(txt), m.end() + 80)
        print(f"{path} | …{txt[s:e]}…")

ctx("/leagues", "1")
print("---")
ctx("/player/196041", "U23")
