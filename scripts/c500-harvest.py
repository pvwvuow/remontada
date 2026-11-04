#!/usr/bin/env python3
# cycle-500 harvest batch 42 — the ENG tranche (the 447 ANCHOR-COUNT
# winner of the FRESH ENG/ESP 2-2 tie — ENG 2 verified standing articles
# [Frome Town + Whitby] vs ESP 0 club anchors [La Nucia's only fa article
# is the TOWN, the نستوس-کریسوپولی 491 class; Elche Ilicitano no entity +
# zero fa hits]). Byte-derivation (the 487 lesson): the anchor renders come
# from the LIVE fa.wiki titles (prefix-stripped), not hand-typed. BOTH
# names are DIRECT anchors — zero honest-phonetic reads this batch.
import json, re, subprocess, sys, time

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

# 1) byte-exact titles of the TWO direct anchors (pageids from the probe)
d = api("https://fa.wikipedia.org/w/api.php?action=query&prop=info|extracts"
        "&exintro=1&explaintext=1&redirects=1&inprop=url"
        "&pageids=1689425|1688996&format=json")
titles = {}
extracts = {}
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    titles[pid] = p.get("title") or ""
    extracts[pid] = (p.get("extract") or "").replace("\n", " ")
    print(f"pageid={pid} title={titles[pid]!r}")
    print(f"   extract[:200]={extracts[pid][:200]!r}")
time.sleep(1.8)

t_frome = titles.get("1689425", "")
t_whitby = titles.get("1688996", "")
assert t_frome.startswith("باشگاه فوتبال "), f"frome prefix unexpected: {t_frome!r}"
assert t_whitby.startswith("باشگاه فوتبال "), f"whitby prefix unexpected: {t_whitby!r}"
assert "Frome Town Football Club" in extracts.get("1689425", ""), "frome identity extract changed"
assert "Whitby Town Football Club" in extracts.get("1688996", ""), "whitby identity extract changed"
r_frome = t_frome[len("باشگاه فوتبال "):].strip()
r_whitby = t_whitby[len("باشگاه فوتبال "):].strip()
print(f"render frome = {r_frome!r}  (title minus the باشگاه-فوتبال prefix)")
print(f"render whitby = {r_whitby!r}  (title minus the باشگاه-فوتبال prefix)")

pairs = [
    ("frome town", r_frome),
    ("whitby", r_whitby),
]
json.dump(dict(pairs), open("/tmp/c500-pairs.json", "w"), ensure_ascii=False)
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

# 3) splice the batch-42 block right after the batch-41 tail pair
anchor_line = '  "nk brinje grosuplje": "برینیه گروسوپلیه",'
assert anchor_line in src, "batch-41 tail anchor line not found"
comment = '''  // cycle-500: batch 42 — the ENG tranche (2 names) of the FRESH 500
  // census into TEAM_FA (the 446-pick rule) — the WINNER of the NEW ENG/ESP
  // 2-2 tie by the fresh 447 ANCHOR COUNT (the 496 form): the fresh census
  // (scripts/c500-census.py, the 447 live-re-read lesson) measured
  // distinct=1613 (EXACT vs the B4 anchor) / raw_rows=2783 (+1, the ±25
  // upstream drift class) DOUBLE-READ IDENTICAL; the field: ENG 7 names
  // five (W) → 2 effective [Frome Town, Whitby], ESP 6 four (W) → 2
  // effective [Elche Ilicitano, La Nucía], INT 4 fully (W) → 0 (the 435
  // rule); KSA/NED/MAR/KUW/BUL/IND/HUN/NGA 2 below; the MLS playoff wave
  // STILL below the threshold (no USA name reached count>=3 — the 494
  // observation, fresh again).
  // The fresh probe (scripts/c500-wiki-probe.py, 1.8s cadence): ENG 2
  // verified standing articles (the 490/496 scoreboard class — the
  // sitelink + the fa-search fallback both counted, identity via the
  // extracts' OWN English names) vs ESP 0 club anchors: Frome Town
  // Q5505739 → باشگاه فوتبال فروم تاون (pageid 1689425; extract «Frome
  // Town Football Club»; P17=Q145 the UK class) + Whitby Q18306 → باشگاه
  // فوتبال ویتبای تاون (pageid 1688996; extract «Whitby Town Football
  // Club»; P17=Q145); Elche Ilicitano NO wikidata entity + zero fa-search
  // hits; La Nucía Q4889929 P17=Q29 OK but ZERO fawiki sitelink and the
  // fa search hit only the TOWN article «لا نوسیا» (دهستانی در استان
  // آلیکانته — geography, NOT the club; the 491 class).
  // TWO direct anchors, every render BYTE-DERIVED from the anchor's OWN
  // title (the FC rule minus the title's OWN باشگاه-فوتبال prefix, the
  // اشدود/آمازولو precedent): Frome Town → فروم تاون (باشگاه فوتبال فروم
  // تاون 1689425) / Whitby → ویتبای تاون (باشگاه فوتبال ویتبای تاون
  // 1688996 — the title's OWN ویتبای spelling, byte-derived not hand-typed).
'''
new_pairs = "".join(f'  "{k}": "{v}",\n' for k, v in pairs)
if anchor_line in src:
    src = src.replace(anchor_line, anchor_line + "\n" + comment + new_pairs, 1)
    open("src/lib/leagues.ts", "w", encoding="utf-8").write(src)
    print("leagues.ts patched — the batch-42 block + 2 pairs spliced")
else:
    assert '"frome town"' in src, "neither the anchor line nor the spliced pairs found"
    print("leagues.ts ALREADY spliced (idempotent skip)")

# 4) the cache bump v45 → v46 — BOTH the comment-chain line AND the
#    actual constant (the 487 lesson, applied from the first write) —
#    in src/lib/fotmob.ts where the matches cache lives
fsrc = open("src/lib/fotmob.ts", encoding="utf-8").read()
if "matches:v46:" in fsrc:
    print("fotmob.ts cache ALREADY v46 (idempotent skip)")
else:
    v45_line = None
    for line in fsrc.splitlines():
        if line.strip().startswith("// cycle-497: v45 — harvest batch 41"):
            v45_line = line
            break
    assert v45_line, "v45 comment line not found in fotmob.ts"
    v46_comment = ("  // cycle-500: v46 — harvest batch 42 (2 more names, the ENG tranche: "
                   "the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT "
                   "— ENG 2 verified standing articles vs ESP 0 club anchors) changed "
                   "the normalized team-fa content again; same rule, fresh cold window "
                   "(v45 L2 rows purged + official restart).")
    fsrc = fsrc.replace(v45_line, v45_line + "\n" + v46_comment, 1)
    assert "matches:v45:" in fsrc, "v45 constant not found in fotmob.ts"
    fsrc = fsrc.replace("matches:v45:", "matches:v46:", 1)
    assert "matches:v46:" in fsrc and "matches:v45:" not in fsrc, "cache bump incomplete"
    open("src/lib/fotmob.ts", "w", encoding="utf-8").write(fsrc)
    print("fotmob.ts patched — cache v45 → v46 (chain + constant)")
