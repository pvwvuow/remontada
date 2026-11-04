# -*- coding: utf-8 -*-
# cycle-495 harvest batch 39 — the SLV tranche (the WINNER of the SVK/SLV
# 2-2 anchor tie by the 447 QUALITY tie-break on the FRESH bytes: BOTH SLV
# anchors state the country's TOP flight «لیگ برتر» + the field's strongest
# POSITIVE record marker (ایسیدرو: «۱۰ عنوان لیگ ملی»/«۱۰ قهرمانی»، «باشگاه
# غالب») vs SVK's second-tier string «لیگ دسته اول فوتبال اسلواکی» + the
# field's ONLY negative marker (دوکلا: «با مشکلات متعدد اقتصادی»); the UEFA
# axis as practiced in 491/492 ranked UEFA TOP flights above others and
# never a UEFA second tier above a non-UEFA top flight — the level-by-name
# + marker evidence decides, the 494 rotation line's own two axes).
# Byte-derivation (the 487 lesson): the two anchor renders come from the
# LIVE fa.wiki titles (prefix-stripped), not hand-typed. The two
# zero-anchor names ride the 466 UPNFM honest-phonetic rule (the census's
# single-country SLV tagging as identity evidence, the آرهوس-فرماد 485
# precedent) with the fa-search noise documented.
import json, re, subprocess, time, urllib.parse

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
        "&pageids=6438277|6638134&format=json")
titles = {}
extracts = {}
for pid, p in (d or {}).get("query", {}).get("pages", {}).items():
    titles[pid] = p.get("title") or ""
    extracts[pid] = (p.get("extract") or "").replace("\n", " ")
    print(f"pageid={pid} title={titles[pid]!r}")
    print(f"   extract[:220]={extracts[pid][:220]!r}")
time.sleep(1.8)

t_plat = titles.get("6438277", "")
t_isid = titles.get("6638134", "")
assert t_plat.startswith("باشگاه فوتبال "), f"platense prefix unexpected: {t_plat!r}"
assert t_isid.startswith("باشگاه ورزشی "), f"isidro prefix unexpected: {t_isid!r}"
r_plat = t_plat[len("باشگاه فوتبال "):].strip()
r_isid = t_isid[len("باشگاه ورزشی "):].strip()
print(f"render platense  = {r_plat!r}  (title minus the باشگاه-فوتبال prefix)")
print(f"render isidro    = {r_isid!r}  (title minus the title's OWN باشگاه-ورزشی prefix)")

# the two zero-anchor honest phonetic renders (the 466 rule; documented in
# the block comment: Q60786481 / Q2979866 P17=Q792, no fa sitelink, the
# fa-search forms zero or climate/airport noise)
r_caca = "کاکاهواتیکه"
r_fuerte = "فوئرته سان فرانسیسکو"

pairs = [
    ("cd cacahuatique", r_caca),
    ("cd platense municipal", r_plat),
    ("fuerte san francisco", r_fuerte),
    ("isidro metapan", r_isid),
]
json.dump(dict(pairs), open("/tmp/c495-pairs.json", "w"), ensure_ascii=False)
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

# 3) splice the batch-39 block right after the "vps" pair (TEAM_FA tail)
anchor_line = '  "vps": "وی‌پی‌اس",'
assert anchor_line in src, "vps anchor line not found"
comment = '''  // cycle-495: batch 39 — ALL 4 count>=3 single-country SLV names of the
  // FRESH 495 census into TEAM_FA (the 446-pick rule) — the WINNER of the
  // SVK/SLV 2-2 anchor tie by the 447 QUALITY tie-break on the FRESH bytes
  // (the 491/492 form; scripts/c495-wiki-probe.py, 1.8s cadence). The 494
  // rotation line declared the waiting tie SVK 4 / SVN 4 / SLV 4 with the
  // fresh-492 anchor scoreboard SVK 2 / SLV 2 / SVN 1 — the fresh probe
  // re-count (the 447 live-re-read lesson) confirmed the tie EXACTLY:
  // SLV 2 (پلاتینزه 6438277 + ایسیدرو متاپان 6638134, both P17=Q792
  // verified) / SVK 2 (کوشیتسه 6386288 direct + دوکلا بانسکا بیستریتسا
  // 6386207 re-surfaced by the fa-search fallback, the 490 precedent — its
  // wikidata entity NOT found by this probe's search while the fa article
  // stands, the fallback path again) / SVN 1 (المپیا 6417931; Bravo/
  // Brinje/Nafta zero entities or no sitelinks). THE TIE-BREAK ON TODAY'S
  // WORDS (the 494 rotation line's own two axes — the UEFA axis AND the
  // extracts' negative/positive markers): BOTH SLV anchors state the
  // country's TOP flight BY NAME («در حال حاضر در لیگ برتر بازی می‌کند» —
  // پلاتینزه 6438277 / «در لیگ برتر فوتبال السالوادور بازی می‌کند» —
  // ایسیدرو 6638134) + the field's strongest POSITIVE record marker
  // («آنها ۱۰ عنوان لیگ ملی را … کسب کرده‌اند»، «یک باشگاه غالب در فوتبال
  // السالوادور») — vs SVK's SECOND-TIER string («لیگ دسته اول فوتبال
  // اسلواکی», the standing 490/491 framing «SVK دستهٔ اول»; the extracts'
  // «بالاترین سطح» clause stays the 491-classified artifact the 491/492
  // cards ranked below named top flights) + the field's ONLY NEGATIVE
  // marker («از سال ۲۰۱۷ … با مشکلات متعدد اقتصادی» — دوکلا, fresh today).
  // The UEFA axis as practiced (491: GRE's UEFA top flight beat both; 492:
  // FIN's UEFA top flight beat both) never ranked a UEFA second tier above
  // a non-UEFA top flight — the level-by-name + marker evidence decides;
  // SVK and SVN wait (the 472/477/482/485/487/490/491/492 loser-waits
  // precedents; SVK's negative marker + second-tier string lose the
  // visibility contest, the 492 record-visibility rule). The fresh census
  // (scripts/c495-census.py, the 447 live-re-read lesson): pre-patch
  // distinct=1625/raw_rows=2819 vs the B4 anchor 1626/2820 — a -1/-1
  // delta, ONE single-row raw name exited the ±7 window entirely (the ±25
  // tolerance class, the 492 −1-upstream-mutation precedent in reverse);
  // the THREE-way 4-tie SVK/SVN/SLV confirmed fresh (all zero (W)); ENG 7
  // five (W) → 2 effective (Frome Town, Whitby), ESP 6 four (W) → 2
  // effective (Elche Ilicitano, La Nucía), INT 4 fully (W) → 0 effective
  // (the 435 rule); KSA/NED/MAR/KUW/BUL/IND 2 below the tie; the MLS
  // playoff wave STILL below the threshold (the 494 observation's
  // possibility — each playoff club 1-2 rows in the window, count<3; the
  // wave may reach x3 when a club's second playoff leg lands).
  // TWO direct anchors, every render BYTE-DERIVED from the anchors' OWN
  // titles (the FC rule minus the title's OWN prefix, the اشدود/آمازولو
  // precedent): CD Platense Municipal → پلاتینزه مونیسیپال زاکاتیکولوکا
  // (باشگاه فوتبال پلاتینزه مونیسیپال زاکاتیکولوکا 6438277, the extract's
  // own short-form clause «معمولاً به اختصار فقط پلاتینزه نامیده می‌شود»
  // noted, the full title kept byte-derived) / Isidro Metapan → ایسیدرو
  // متاپان (باشگاه ورزشی ایسیدرو متاپان 6638134 — the title's OWN prefix
  // is باشگاه ورزشی, NOT باشگاه فوتبال; the 487 ledger's short form).
  // TWO zero-anchor honest reads (the 466 UPNFM rule — the feed's
  // single-country SLV tagging as identity evidence, the آرهوس-فرماد 485
  // precedent): CD Cacahuatique → کاکاهواتیکه (Q60786481 P17=Q792 + the
  // fa-sitelink absence; the «کاکاهواتیکه» fa search zero hits; pure
  // phonetic) / Fuerte San Francisco → فوئرته سان فرانسیسکو (Q2979866
  // P17=Q792 + the fa-sitelink absence; the fa hits climate/airport
  // geography noise NOT the club — the نستوس-کریسوپولی 491 class; pure
  // phonetic).
'''
new_pairs = "".join(f'  "{k}": "{v}",\n' for k, v in pairs)
src = src.replace(anchor_line, anchor_line + "\n" + comment + new_pairs, 1)
open("src/lib/leagues.ts", "w", encoding="utf-8").write(src)
print("leagues.ts patched — the batch-39 block + 4 pairs spliced")
