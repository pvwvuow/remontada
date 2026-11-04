#!/usr/bin/env python3
# cycle-501 splice: batch 43 (the ESP tranche, 2 honest-466 renders) into
# TEAM_FA + the matches cache bump v46 → v47 (BOTH the appended comment-
# chain line AND the actual matches:v47: constant — the 487 lesson applied
# from the first write). Idempotent: a re-run lands nothing twice (the 500
# harness lesson — the WRITE is explicit and guarded).
import io

L = "src/lib/leagues.ts"
F = "src/lib/fotmob.ts"

# ---- 1) the TEAM_FA splice ----
src = open(L, encoding="utf-8").read()
if "cycle-501: batch 43" in src:
    print("leagues.ts: cycle-501 block ALREADY spliced — skip")
else:
    anchor = '  "whitby": "ویتبای تاون",\n'
    assert src.count(anchor) == 1, "whitby anchor not unique"
    block = (
        '  // cycle-501: batch 43 — the ESP tranche (2 names) of the FRESH 501\n'
        '  // census into TEAM_FA (the 446-pick rule) — the waiting 500 runner-up\n'
        '  // FINALLY ALONE at the top (the 477/482/485 loser-waits precedent): the\n'
        '  // fresh census (scripts/c501-census.py, the 447 live-re-read lesson)\n'
        '  // measured distinct=1611 / raw_rows=2776 == the 500 post-patch MEASURED\n'
        '  // numbers EXACT (zero upstream drift) DOUBLE-READ IDENTICAL; the field:\n'
        '  // ESP 6 names four (W) → 2 effective [Elche Ilicitano, La Nucía] ALONE,\n'
        '  // ENG 5 names ALL (W) → 0 (the 435 rule — the 500 harvest took Frome\n'
        '  // Town + Whitby out of the raw pool), INT 4 fully (W) → 0; KSA/NED/MAR/\n'
        '  // KUW/BUL/IND/HUN 2 below; the MLS playoff wave STILL below the\n'
        '  // threshold (no USA name in the count>=3 field — the 494 observation,\n'
        '  // fresh a third time).\n'
        '  // The fresh probe (scripts/c501-wiki-probe.py, 1.8s cadence): ESP 0\n'
        '  // direct anchors CONFIRMED fresh — Elche Ilicitano NO wikidata club\n'
        '  // entity + zero direct fa hits; La Nucía Q4889929 P17=Q29 OK but ZERO\n'
        '  // fawiki sitelink (fresh again) and the fa search hitting only the\n'
        '  // TOWN article. BOTH renders are the 466-rule honest reads,\n'
        '  // BYTE-DERIVED from witnesses (never hand-typed):\n'
        '  // • Elche Ilicitano → الچه ایلیسیتانو — the fa.wiki article\'s OWN\n'
        '  //   phrase «الچه سی اف ایلیسیتانو» (خوزه لوئیس فریازا pageid 6235403:\n'
        '  //   «...برای الچه سی اف ایلیسیتانو بازی می‌کند»; the same spelling in\n'
        '  //   خوان مودستو + پاتریک گراف) minus the «سی اف» the feed\'s raw does\n'
        '  //   not carry — the FC-rule-minus-prefix class, the اشدود/آمازولو\n'
        '  //   precedent.\n'
        '  // • La Nucía → لا نوسیا — the TOWN article 214243\'s OWN title (the\n'
        '  //   آرهوس 485 / دوربان 486 town-grounding class; the club named after\n'
        '  //   the town, the raw carries no suffix).\n'
        '  "elche ilicitano": "الچه ایلیسیتانو",\n'
        '  "la nucía": "لا نوسیا",\n'
    )
    src = src.replace(anchor, anchor + block, 1)
    with io.open(L, "w", encoding="utf-8") as fh:
        fh.write(src)
    print("leagues.ts: batch-43 block + 2 pairs WRITTEN")

# ---- 2) the cache comment chain (append AFTER the v46 line, full line) ----
fsrc = open(F, encoding="utf-8").read()
chain_line = (
    '  // cycle-501: v47 — harvest batch 43 (2 more names, the ESP tranche: the '
    'waiting 500 runner-up finally ALONE at the top, the 477/482/485 precedent; '
    'both renders the honest 466 zero-anchor reads byte-derived from witnesses '
    '[الچه سی اف ایلیسیتانو pageid 6235403 + the لا نوسیا town 214243]) changed '
    'the normalized team-fa content again; same rule, fresh cold window (v46 L2 '
    'rows purged + official restart).\n'
)
if "cycle-501: v47 — harvest batch 43" in fsrc:
    print("fotmob.ts: v47 chain line ALREADY appended — skip")
else:
    anchor46 = ('  // cycle-500: v46 — harvest batch 42 (2 more names, the ENG tranche: '
                'the WINNER of the NEW ENG/ESP 2-2 tie by the fresh 447 ANCHOR COUNT — ENG 2 '
                'verified standing articles vs ESP 0 club anchors) changed the normalized '
                'team-fa content again; same rule, fresh cold window (v45 L2 rows purged + '
                'official restart).\n')
    assert fsrc.count(anchor46) == 1, "v46 chain line not unique"
    fsrc = fsrc.replace(anchor46, anchor46 + chain_line, 1)
    with io.open(F, "w", encoding="utf-8") as fh:
        fh.write(fsrc)
    print("fotmob.ts: v47 chain line APPENDED")

# ---- 3) the cache constant v46 → v47 ----
fsrc = open(F, encoding="utf-8").read()
if "matches:v47:" in fsrc:
    print("fotmob.ts: matches:v47 constant ALREADY set — skip")
else:
    assert fsrc.count("matches:v46:") == 1, "v46 constant not unique"
    fsrc = fsrc.replace("matches:v46:", "matches:v47:", 1)
    assert fsrc.count("matches:v45:") == 0, "v45 residue present"
    with io.open(F, "w", encoding="utf-8") as fh:
        fh.write(fsrc)
    print("fotmob.ts: cache constant → matches:v47 WRITTEN")
