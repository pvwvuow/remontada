# -*- coding: utf-8 -*-
# cycle-496 harvest batch 40 — the SVK tranche (the WINNER of the SVK/SVN
# 4-4 tie by the fresh 447 ANCHOR COUNT, the 490 form exactly: SVK 2 vs
# SVN 1 — the 495 rotation line's own words «اگر گره ماند، SVK با شمارش
# لنگر برندهٔ فرمولی است»). Byte-derivation (the 487 lesson): the two
# anchor renders come from the LIVE fa.wiki titles (prefix-stripped), not
# hand-typed. The two zero-anchor names ride the 466 UPNFM honest-phonetic
# rule (the census's single-country SVK tagging as identity evidence, the
# آرهوس-فرماد 485 precedent) with the fa-search noise documented.
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

# 1) byte-exact titles of the two direct anchors
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url"
        "&pageids=6386207|6386288&format=json")
titles = {}
extracts = {}
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    titles[pid] = p.get("title") or ""
    extracts[pid] = (p.get("extract") or "").replace("\n", " ")
    print(f"pageid={pid} title={titles[pid]!r}")
    print(f"   extract[:200]={extracts[pid][:200]!r}")
time.sleep(1.8)

t_dukla = titles.get("6386207", "")
t_kosice = titles.get("6386288", "")
assert t_dukla.startswith("باشگاه فوتبال "), f"dukla prefix unexpected: {t_dukla!r}"
assert t_kosice.startswith("باشگاه فوتبال "), f"kosice prefix unexpected: {t_kosice!r}"
r_dukla = t_dukla[len("باشگاه فوتبال "):].strip()
r_kosice = t_kosice[len("باشگاه فوتبال "):].strip()
print(f"render dukla   = {r_dukla!r}  (title minus the باشگاه-فوتبال prefix)")
print(f"render kosice  = {r_kosice!r}  (title minus the باشگاه-فوتبال prefix)")

# the two zero-anchor honest phonetic renders (the 466 rule; documented in
# the block comment: no wikidata club entity + no fa sitelink; the fa
# search noise = a universities-list page / geography + biologist noise)
r_skalica = "اسکالیتسا"
r_zemplin = "زمپلین میخالوفتسه"

pairs = [
    ("dukla banská bystrica", r_dukla),
    ("fc košice", r_kosice),
    ("skalica", r_skalica),
    ("zemplín michalovce", r_zemplin),
]
json.dump(dict(pairs), open("/tmp/c496-pairs.json", "w"), ensure_ascii=False)
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

# 3) splice the batch-40 block right after the batch-39 tail pair
anchor_line = '  "isidro metapan": "ایسیدرو متاپان",'
assert anchor_line in src, "batch-39 tail anchor line not found"
comment = '''  // cycle-496: batch 40 — ALL 4 count>=3 single-country SVK names of the
  // FRESH 496 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // SVK/SVN 4-4 tie by the fresh 447 ANCHOR COUNT (the 490 form exactly:
  // SVK 2 vs SVN 1; scripts/c496-wiki-probe.py, 1.8s cadence). The 495
  // rotation line declared the waiting tie SVK 4 / SVN 4 with the fresh-495
  // anchor scoreboard SVK 2 (کوشیتسه + دوکلا-فالبک) vs SVN 1 (المپیا) —
  // the fresh probe re-count (the 447 live-re-read lesson) confirmed the
  // tie EXACTLY: the strict sitelink scoreboard read 1-1 (کوشیتسه 6386288 —
  // Q5426448 P17=Q214 verified + the fawiki sitelink; المپیا 6417931 —
  // Q31932 P17=Q215 + the sitelink) and the fallback class (the 490
  // precedent — the fa article standing IS the direct anchor) restored the
  // standing 2-1: دوکلا بانسکا بیستریتسا 6386207 — the fa article STANDS,
  // the FIRST hit of the fa-search fallback for the exact form, identity
  // verified via its extract's English name «FK Dukla Banská Bystrica»,
  // its wikidata entity again NOT found by the probe's search while the fa
  // article stands (the same probe behavior as 495) — so SVK 2 beats SVN 1
  // by the anchor count (the 447/490/492 precedents); SVN waits (Bravo
  // Q64363556 + Brinje Q16828238 entities exist P17=Q215 but ZERO fawiki
  // sitelinks; Nafta no entity — the loser-waits precedents 472/477/482/
  // 485/487/490/491/492/495). The fresh census (scripts/c496-census.py,
  // the 447 live-re-read lesson): pre-patch distinct=1622/raw_rows=2808 vs
  // the B4 anchor 1622/2808 — EXACT, ZERO pool drift (the first exact-match
  // census since the 492 re-anchor); the tie confirmed fresh: SVK 4 / SVN 4
  // (both zero (W)); ENG 7 five (W) → 2 effective (Frome Town, Whitby),
  // ESP 6 four (W) → 2 effective (Elche Ilicitano, La Nucía), INT 4 fully
  // (W) → 0 effective (the 435 rule); KSA/NED/MAR/KUW/BUL/IND/HUN/NGA 2
  // below the tie; the MLS playoff wave STILL below the threshold (the 494
  // observation — no USA name reached count>=3 in the window).
  // TWO direct anchors, every render BYTE-DERIVED from the anchors' OWN
  // titles (the FC rule minus the title's OWN باشگاه-فوتبال prefix, the
  // اشدود/آمازولو precedent): Dukla Banská Bystrica → دوکلا بانسکا
  // بیستریتسا (باشگاه فوتبال دوکلا بانسکا بیستریتسا 6386207) / FC Košice →
  // کوشیتسه (باشگاه فوتبال کوشیتسه 6386288).
  // TWO zero-anchor honest reads (the 466 UPNFM rule — the feed's
  // single-country SVK tagging as identity evidence, the آرهوس-فرماد 485
  // precedent): Skalica → اسکالیتسا (no wikidata club entity + no fa
  // sitelink; the fa search «اسکالیتسا» hit a universities-list page only,
  // «اسکالیسا» zero hits; pure phonetic — the «تس» transliteration
  // consistent with the field's OWN بیستریتسا from the Dukla anchor title)
  // / Zemplín Michalovce → زمپلین میخالوفتسه (no entity + no sitelink; the
  // fa hits geography noise «اسلواکی/جغرافیای اسلواکی» and a biologist
  // «بیورن زمپلین» NOT the club — the نستوس-کریسوپولی 491 class; pure
  // phonetic).
'''
new_pairs = "".join(f'  "{k}": "{v}",\n' for k, v in pairs)
src = src.replace(anchor_line, anchor_line + "\n" + comment + new_pairs, 1)
open("src/lib/leagues.ts", "w", encoding="utf-8").write(src)
print("leagues.ts patched — the batch-40 block + 4 pairs spliced")
