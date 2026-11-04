# -*- coding: utf-8 -*-
# cycle-497 harvest batch 41 — the SVN tranche (the LONE-LEADER form, the
# 477/482/485 precedents): the 496 harvest took SVK out of the raw pool and
# the post-harvest field left SVN 4 ALONE at the top (the 496 rotation
# line's own words). Byte-derivation (the 487 lesson): the anchor render
# comes from the LIVE fa.wiki title (prefix-stripped), not hand-typed. The
# three zero-anchor names ride the 466 UPNFM honest-phonetic rule (the
# census's single-country SVN tagging as identity evidence, the آرهوس-
# فرماد 485 precedent) with the fa-search noise documented; the NK-prefix
# strip consistent with the file's OWN nk celje / nk varazdin / nk
# lokomotiva renders.
import json, re, subprocess, sys, time, urllib.parse

SPLICE = "--splice" in sys.argv   # without the flag: probe + gate + pairs file ONLY
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

def api(url):
    for attempt in range(4):
        out = subprocess.run(["curl", "-s", "--max-time", "25", "-A", UA, url],
                             capture_output=True, text=True, timeout=40).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(3 + attempt * 3)
    return None

# 1) byte-exact title of the one direct anchor
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url"
        "&pageids=6417931&format=json")
titles = {}
extracts = {}
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    titles[pid] = p.get("title") or ""
    extracts[pid] = (p.get("extract") or "").replace("\n", " ")
    print(f"pageid={pid} title={titles[pid]!r}")
    print(f"   extract[:200]={extracts[pid][:200]!r}")
time.sleep(1.8)

t_olimpija = titles.get("6417931", "")
assert t_olimpija.startswith("باشگاه فوتبال "), f"olimpija prefix unexpected: {t_olimpija!r}"
r_olimpija = t_olimpija[len("باشگاه فوتبال "):].strip()
print(f"render olimpija = {r_olimpija!r}  (title minus the باشگاه-فوتبال prefix)")

# the three zero-anchor honest phonetic renders (the 466 rule; documented
# in the block comment: no fa sitelink + no fa-search club hit; the NK
# strip consistent with the file's OWN nk celje/nk varazdin/nk lokomotiva
# renders)
r_bravo = "براوو"
r_nafta = "نفتا"
r_brinje = "برینیه گروسوپلیه"

pairs = [
    ("olimpija ljubljana", r_olimpija),
    ("nk bravo", r_bravo),
    ("nafta", r_nafta),
    ("nk brinje grosuplje", r_brinje),
]
json.dump(dict(pairs), open("/tmp/c497-pairs.json", "w"), ensure_ascii=False)
print("pairs:", json.dumps(dict(pairs), ensure_ascii=False))

# 2) the collision gate on the FULL TEAM_FA map (the c492 verify form)
src = open("src/lib/leagues.ts", encoding="utf-8").read()
m = re.search(r"const TEAM_FA: Record<string, string> = \{(.*?)\n\};", src, re.S)
assert m, "TEAM_FA block not found"
body = m.group(1)
existing = re.findall(r'"([^"]+)":\s*"([^"]+)"', body)
print(f"existing TEAM_FA pairs: {len(existing)}")
keys = [k for k, _ in existing]
vals = [v for _, v in existing]
dup_keys = sorted({k for k in keys if keys.count(k) > 1})
print("dupKeys:", dup_keys)
proposed = dict(pairs)
key_coll = [k for k in proposed if k in keys]
val_coll = [(k, v) for k, v in proposed.items() if v in vals]
print("proposed key collisions:", key_coll)
print("proposed value collisions:", val_coll)
assert not dup_keys and not key_coll and not val_coll, "collision gate FAILED"
print("collision gate CLEAN")

if not SPLICE:
    print("--probe-only: pairs file written, splice NOT performed "
          "(run again with --splice after the PRE-verify)")
    raise SystemExit(0)

# 3) splice the batch-41 block right after the batch-40 tail pair
anchor_line = '  "zemplín michalovce": "زمپلین میخالوفتسه",'
assert anchor_line in src, "batch-40 tail anchor line not found"
comment = '''  // cycle-497: batch 41 — ALL 4 count>=3 single-country SVN names of the
  // FRESH 497 census into TEAM_FA (the 446-pick rule) — the LONE-LEADER
  // form (the 477/482/485 precedents): the 496 harvest took SVK out of
  // the raw pool and the post-harvest field left SVN 4 ALONE at the top
  // (the 496 rotation line's own words). The fresh census
  // (scripts/c497-census.py, the 447 live-re-read lesson): pre-patch
  // distinct=1618/raw_rows=2796 vs the B4 anchor 1618/2796 — EXACT, ZERO
  // pool drift; the field confirmed fresh: SVN 4 (all zero (W)), ENG 7
  // five (W) → 2 effective, ESP 6 four (W) → 2 effective, INT 4 fully
  // (W) → 0 (the 435 rule); KSA/NED/MAR/KUW/BUL 2 below; the MLS playoff
  // wave STILL below the threshold (no USA name reached count>=3 in the
  // window — the 494 observation).
  // The fresh probe (scripts/c497-wiki-probe.py, 1.8s cadence): SVN 1
  // direct anchor — المپیا لیوبلیانا 6417931 (Q31932 P17=Q215 verified +
  // the fawiki sitelink; identity via the extract's own «Olimpija
  // Ljubljana Football Club»; the extract again carries the «بالاترین
  // سطح» clause — the 491-classified artifact, ladder context irrelevant
  // here since SVN is the sole tranche). Bravo Q64363556 + Brinje
  // Q16828238 entities P17=Q215 with ZERO fawiki sitelinks; Nafta NO
  // wikidata entity (the 495/496 probe finding, fresh again).
  // fa-search fallback (zero-anchor documentation): «براوو اسلوونی» /
  // «ان‌کی براوو» zero hits; «نفتا هاجدید» / «نافتا لنداوا» zero hits;
  // «گروسوپلیه» hit the geography entry «ولیکا لوکا، گروسوپلیه» NOT the
  // club (the نستوس-کریسوپولی 491 class) — «برینیه» zero hits.
  // ONE direct anchor, the render BYTE-DERIVED from the anchor's OWN
  // title (the FC rule minus the title's OWN باشگاه-فوتبال prefix, the
  // اشدود/آمازولو precedent): Olimpija Ljubljana → المپیا لیوبلیانا
  // (باشگاه فوتبال المپیا لیوبلیانا 6417931).
  // THREE zero-anchor honest reads (the 466 UPNFM rule — the feed's
  // single-country SVN tagging as identity evidence, the آرهوس-فرماد 485
  // precedent; the NK-prefix strip consistent with the file's OWN nk
  // celje → سلیه / nk varazdin → واراژدین / nk lokomotiva → لوکوموتیوا):
  // NK Bravo → براوو / Nafta → نفتا / Nk Brinje Grosuplje → برینیه
  // گروسوپلیه (all pure phonetic).
'''
new_pairs = "".join(f'  "{k}": "{v}",\n' for k, v in pairs)
src = src.replace(anchor_line, anchor_line + "\n" + comment + new_pairs, 1)
open("src/lib/leagues.ts", "w", encoding="utf-8").write(src)
print("leagues.ts patched — the batch-41 block + 4 pairs spliced")
