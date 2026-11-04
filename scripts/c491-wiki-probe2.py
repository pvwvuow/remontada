#!/usr/bin/env python3
# cycle-491 probe2 — completes the 447 fresh re-count that probe1's structure
# left half-covered: the five names whose wikidata A-stage found NO entity
# (Nestos Chrisoupolis / Dukla Banská Bystrica / Skalica / Nafta / VPS) were
# never entered into the sitelink dict, so probe1's B-stage fallback SKIPPED
# them — yet the 490 card records the Dukla fa anchor 6386207 via that very
# fallback. This probe:
#   1) runs the fa.wiki search fallback for ALL five zero-entity names,
#   2) extract-verifies every surfaced candidate (identity rule: the extract
#      must name a club of THAT country; Dukla expected 6386207),
#   3) resolves the SLV P17 marker fresh: label(Q792) vs label(Q2222) — the
#      487 probe2 item-1 proof, re-read live,
#   4) documents the town-article spelling for the Nestos honest read
#      (Chrisoupoli / Chrysoupoli),
#   5) recomputes the FINAL 447 scoreboard including fallback-surfaced
#      anchors, with the league statements for the 447 quality tie-break.
# Gentle 1.8s cadence + backoff (the 480 429-wall lesson), UA Chrome/124.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

# the five zero-entity names of the c491 field + their country identity
ZERO_ENTITY = [
    ("GRE", "Greece", "Q41", "Nestos Chrisoupolis",
     ["نستوس", "کریسوپولی", "نستوس کریسوپولی"]),
    ("SVK", "Slovakia", "Q214", "Dukla Banská Bystrica",
     ["دوکلا بانسکا بیستریتسا", "دوکلا باانسکا بیستریتسا"]),
    ("SVK", "Slovakia", "Q214", "Skalica",
     ["اسکالیسا", "اسکالیتسا"]),
    ("SVN", "Slovenia", "Q215", "Nafta",
     ["نفتا هاجدید", "نافتا لنداوا"]),
    ("FIN", "Finland", "Q33", "VPS",
     ["وااس وایکاوس", "وی‌پی‌اس"]),
]


def api(url):
    for attempt in range(4):
        out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None


def fa_search(term):
    q = ("https://fa.wikipedia.org/w/api.php?action=query&list=search"
         "&srlimit=6&srprop=snippet&format=json&srsearch="
         + urllib.parse.quote(term))
    d = api(q)
    return [h["title"] for h in (d or {}).get("query", {}).get("search", [])]


print("== 1) fa.wiki search fallback for ALL five zero-entity names ==")
surfaced = {}   # name -> candidate titles
for cc, cname, qcc, name, forms in ZERO_ENTITY:
    hits_all = []
    for f in forms:
        hits = fa_search(f)
        hits_all.extend(hits)
        print(f"  fa-search[{cc} | {name} | {f}] -> {hits[:5]}")
        time.sleep(1.8)
    clubish = [h for h in hits_all
               if ("باشگاه" in h or "فوتبال" in h) and "فهرست" not in h]
    surfaced[name] = clubish
    print(f"  => club-ish candidates for {name}: {clubish}")

print("== 2) extract-verify the surfaced candidates (identity rule) ==")
verify = {}
for cc, cname, qcc, name, forms in ZERO_ENTITY:
    cands = surfaced.get(name) or []
    if not cands:
        print(f"  {name} [{cc}]: ZERO candidates -> zero-anchor documented")
        continue
    for t in sorted(set(cands))[:3]:
        d = api("https://fa.wikipedia.org/w/api.php?action=query"
                "&prop=info|extracts&exintro=1&explaintext=1&redirects=1"
                "&inprop=url&titles=" + urllib.parse.quote(t) + "&format=json")
        for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
            if pid == "-1" or "missing" in p:
                print(f"  MISSING: {t}")
                continue
            ex = (p.get("extract") or "(EMPTY)")[:500].replace("\n", " ")
            ok = cname.lower()[:4] in ex.lower() or cname in ex
            mark = "IDENTITY-OK" if ok else "identity-unclear"
            print(f"  pageid={pid} [{cc}] {t!r} {mark} :: {ex}")
            verify[(name, t)] = (pid, cc, ok)
            time.sleep(1.8)

print("== 3) the SLV P17 marker fresh: label(Q792) vs label(Q2222) ==")
d = api("https://www.wikidata.org/w/api.php?action=wbgetentities&ids=Q792|Q2222"
        "&props=labels&languages=en|fa&format=json")
for qid in ("Q792", "Q2222"):
    ent = (d or {}).get("entities", {}).get(qid, {})
    en = (ent.get("labels", {}).get("en") or {}).get("value")
    fa = (ent.get("labels", {}).get("fa") or {}).get("value")
    print(f"  {qid}: en={en!r} fa={fa!r}")
time.sleep(1.8)

print("== 4) the Nestos/Chrisoupoli town-article spelling (honest-read docs) ==")
for term in ("کریسوپولی", "نستوس"):
    hits = fa_search(term)
    print(f"  fa-search[{term}] -> {hits[:5]}")
    time.sleep(1.8)

print("== 5) the FINAL 447 scoreboard (probe1 sitelinks + this fallback) ==")
# probe1 direct sitelink anchors:
direct = {
    "GRE": [("AE Larissa", "باشگاه فوتبال لاریسا", 3892127),
            ("Atromitos", "باشگاه فوتبال آترومیتوس", 3438822)],
    "SVK": [("FC Košice", "باشگاه فوتبال کوشیتسه", 6386288)],
    "SVN": [("Olimpija Ljubljana", "باشگاه فوتبال المپیا لیوبلیانا", 6417931)],
    "FIN": [("FC Inter Turku", "باشگاه فوتبال اینتر تورکو", 5972064)],
    "SLV": [("CD Platense Municipal",
             "باشگاه فوتبال پلاتینزه مونیسیپال زاکاتیکولوکا", 6438277),
            ("Isidro Metapan", "باشگاه ورزشی ایسیدرو متاپان", 6638134)],
}
for cc in ("GRE", "SVK", "SVN", "FIN", "SLV"):
    extra = []
    for name, title, pid, ok in []:
        pass
    print(f"  {cc}: {len(direct[cc])} sitelink anchors")
fallback_winners = []
for (name, t), (pid, cc, ok) in verify.items():
    if ok:
        fallback_winners.append((cc, name, t, pid))
        print(f"  FALLBACK-ANCHOR: {cc} | {name} | {t} | pageid={pid}")
score = {cc: len(v) for cc, v in direct.items()}
for cc, name, t, pid in fallback_winners:
    score[cc] = score.get(cc, 0) + 1
print("  ---- combined ----")
for cc, s in sorted(score.items(), key=lambda kv: -kv[1]):
    print(f"  {cc}: {s}")
best = max(score.values())
print(f"  WINNER(S): {[cc for cc, s in score.items() if s == best]} with {best}")
