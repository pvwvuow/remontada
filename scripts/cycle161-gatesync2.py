#!/usr/bin/env python3
# cycle-161 gate sync v2 — the four remaining scripts (152/155/156/157/158)
import sys

def patch(path, pairs):
    s = open(path, encoding="utf-8").read()
    for old, new in pairs:
        n = s.count(old)
        if n == 0:
            print(f"MISS in {path}: {old[:70]!r}"); sys.exit(1)
        if n > 1:
            print(f"AMBIGUOUS({n}) in {path}: {old[:70]!r}"); sys.exit(1)
        s = s.replace(old, new)
    open(path, "w", encoding="utf-8").write(s)
    print(f"OK {path} ({len(pairs)})")

patch("scripts/cycle152-domproof.sh", [
    ("report('A2 race 17 participants + window byte-identical (gate-synced cycle-160: swiss joins eredivisie)',\n           len(pl) == 17 and 'swiss' in pl and 'eredivisie' in pl and 'qatar' in pl and 'uae' in pl and 'portugal' in pl and 'saudi' in pl\n           and len(scorers) == 340 and len(seas) == 12",
     "report('A2 race 18 participants + window byte-identical (gate-synced cycle-161: hnl joins swiss)',\n           len(pl) == 18 and 'hnl' in pl and 'swiss' in pl and 'eredivisie' in pl and 'qatar' in pl and 'uae' in pl and 'portugal' in pl and 'saudi' in pl\n           and len(scorers) == 360 and len(seas) == 12"),
    ("probe \"http://localhost:3000/topscorers?league=all\" \"D3 race copy ۱۷ + eredivisie chip\" \\\n\"const b=document.body.innerText;return {copy17:b.includes('۱۷ لیگ و جام برتر'),old16gone:!b.includes('۱۶ لیگ و جام برتر'),old15gone:!b.includes('۱۵ لیگ و جام برتر'),chip:b.includes('لیگ ستارگان قطر'),ere:b.includes('اردیویزهٔ هلند')}\"",
     "probe \"http://localhost:3000/topscorers?league=all\" \"D3 race copy ۱۸ + eredivisie chip\" \\\n\"const b=document.body.innerText;return {copy18:b.includes('۱۸ لیگ و جام برتر'),old17gone:!b.includes('۱۷ لیگ و جام برتر'),old16gone:!b.includes('۱۶ لیگ و جام برتر'),chip:b.includes('لیگ ستارگان قطر'),ere:b.includes('اردیویزهٔ هلند')}\""),
    ("320-scorer race now 340 (17 leagues, gate-synced cycle-160) with رافینیا still honest leader",
     "360-scorer race (18 leagues, gate-synced cycle-161) with رافینیا still honest leader"),
    ("race copy ۱۷ + players hub هفده + search guide ۲۰ + /leagues 20th card (swiss, gate-synced cycle-160)",
     "race copy ۱۸ + players hub هجده + search guide ۲۱ + /leagues 21st card (hnl, gate-synced cycle-161)"),
])

patch("scripts/cycle155-domproof.sh", [
    ("# A2: global race — 340 scorers (320 + 20 swiss rows, gate-synced\n# cycle-160), 17 perLeague incl. qatar, honest leader shape (رافینیا ۱۳ stays",
     "# A2: global race — 360 scorers (340 + 20 hnl rows, gate-synced\n# cycle-161), 18 perLeague incl. qatar, honest leader shape (رافینیا ۱۳ stays"),
    ('    good = len(ts) == 340 and len(pl) == 17 and "qatar" in pl and "eredivisie" in pl and "swiss" in pl \\',
     '    good = len(ts) == 360 and len(pl) == 18 and "qatar" in pl and "eredivisie" in pl and "swiss" in pl and "hnl" in pl \\'),
    ('    ok = ok and len(ts) == 340 and len(pl) == 17 and "qatar" in pl and "eredivisie" in pl and "swiss" in pl',
     '    ok = ok and len(ts) == 360 and len(pl) == 18 and "qatar" in pl and "eredivisie" in pl and "swiss" in pl and "hnl" in pl'),
    ('"return {h1:((document.querySelector(\\"h1\\")||{}).innerText||\\"\\").includes(\\"مصاف گلزنان\\"),copy17:(document.body.innerText||\\"\\").includes(\\"۱۷ لیگ و جام برتر\\"),noStale16:(document.body.innerText||\\"\\").includes(\\"۱۶ لیگ و جام برتر\\")===false,noStale15:(document.body.innerText||\\"\\").includes(\\"۱۵ لیگ و جام برتر\\")===false}"',
     '"return {h1:((document.querySelector(\\"h1\\")||{}).innerText||\\"\\").includes(\\"مصاف گلزنان\\"),copy18:(document.body.innerText||\\"\\").includes(\\"۱۸ لیگ و جام برتر\\"),noStale17:(document.body.innerText||\\"\\").includes(\\"۱۷ لیگ و جام برتر\\")===false,noStale16:(document.body.innerText||\\"\\").includes(\\"۱۶ لیگ و جام برتر\\")===false}"'),
    ("320-scorer race now 340 (17 leagues, gate-synced cycle-160) with رافینیا still honest leader",
     "360-scorer race (18 leagues, gate-synced cycle-161) with رافینیا still honest leader"),
    ("race copy ۱۷ + players hub هفده + search guide ۲۰ + /leagues 20th card (swiss, gate-synced cycle-160)",
     "race copy ۱۸ + players hub هجده + search guide ۲۱ + /leagues 21st card (hnl, gate-synced cycle-161)"),
])

patch("scripts/cycle156-domproof.sh", [
    ("    good = (len(pl) == 17 and 'swiss' in pl and 'eredivisie' in pl and 'qatar' in pl and 'uae' in pl\n            and len(scorers) == 340 and len(seas) == 12",
     "    good = (len(pl) == 18 and 'hnl' in pl and 'swiss' in pl and 'eredivisie' in pl and 'qatar' in pl and 'uae' in pl\n            and len(scorers) == 360 and len(seas) == 12"),
    ("    report('A2 race 17 participants', good,", "    report('A2 race 18 participants', good,"),
    ("    report('A2 race 17 participants', False, str(e))", "    report('A2 race 18 participants', False, str(e))"),
    ("    good = (len(pl) == 16 and 'eredivisie' in pl and 'qatar' not in pl and 'swiss' in pl\n            and ts[0].get('nameFa') == 'هری کین' and ts[0].get('goals') == 36",
     "    good = (len(pl) == 17 and 'eredivisie' in pl and 'qatar' not in pl and 'swiss' in pl and 'hnl' in pl\n            and ts[0].get('nameFa') == 'هری کین' and ts[0].get('goals') == 36"),
    ("    report('A6 historical race 16 participants (swiss, cycle-160)', good", "    report('A6 historical race 17 participants (hnl, cycle-161)', good"),
    ("    report('A6 historical race 16 participants (swiss, cycle-160)', False, str(e))", "    report('A6 historical race 17 participants (hnl, cycle-161)', False, str(e))"),
    ("historical 2023/2024 race honestly 16 participants (swiss joined cycle-160)", "historical 2023/2024 race honestly 17 participants (hnl joined cycle-161)"),
    ("# A8: mapping-sweep duplicate-key guard — 960 team keys / 458 player keys\n# zero duplicates (the 152/155/159 sweep guard, re-run at the new totals;\n# gate-synced cycle-160: swiss +49 team / +27 player keys)",
     "# A8: mapping-sweep duplicate-key guard — 1009 team keys / 486 player keys\n# zero duplicates (the 152/155/159 sweep guard, re-run at the new totals;\n# gate-synced cycle-161: hnl +49 team / +28 player keys)"),
    ("report('A8 duplicate-key guard', len(tk) == 960 and len(pk) == 458 and not td and not pd,",
     "report('A8 duplicate-key guard', len(tk) == 1009 and len(pk) == 486 and not td and not pd,"),
    ('probe "http://localhost:3000/topscorers?league=all" "D4 race copy ۱۷" \\',
     'probe "http://localhost:3000/topscorers?league=all" "D4 race copy ۱۸" \\'),
    ('"b=document.body.innerText;return {copy17:b.includes(\'۱۷ لیگ و جام برتر\'),old16gone:!b.includes(\'۱۶ لیگ و جام برتر\'),old15gone:!b.includes(\'۱۵ لیگ و جام برتر\'),chip:b.includes(\'اردیویزهٔ هلند\'),raphinha:b.includes(\'رافینیا\')}"',
     '"b=document.body.innerText;return {copy18:b.includes(\'۱۸ لیگ و جام برتر\'),old17gone:!b.includes(\'۱۷ لیگ و جام برتر\'),old16gone:!b.includes(\'۱۶ لیگ و جام برتر\'),chip:b.includes(\'اردیویزهٔ هلند\'),raphinha:b.includes(\'رافینیا\')}"'),
    ("# D6: players hub — هفده copy (gate-synced cycle-160) + the eredivisie chip",
     "# D6: players hub — هجده copy (gate-synced cycle-161) + the eredivisie chip"),
    ("'هفده لیگ و جام برتر'))\" 2>/dev/null | tr -d '\"\\\\')",
     "'هجده لیگ و جام برتر'))\" 2>/dev/null | tr -d '\"\\\\')"),
    ('echo "D6 players hub eredivisie click → $OUT6 | copy17=$COPY16 feat=$FEAT6 | console=$C6 appErrors=$E6"',
     'echo "D6 players hub eredivisie click → $OUT6 | copy18=$COPY16 feat=$FEAT6 | console=$C6 appErrors=$E6"'),
    ("# D7: /leagues — 20 cards + the eredivisie + acl2 cards (gate-synced cycle-160)\nprobe \"http://localhost:3000/leagues\" \"D7 leagues hub 20 cards\" \\",
     "# D7: /leagues — 21 cards + the eredivisie + acl2 cards (gate-synced cycle-161)\nprobe \"http://localhost:3000/leagues\" \"D7 leagues hub 21 cards\" \\"),
    ("320-scorer race now 340 (17 leagues) with رافینیا still honest leader",
     "360-scorer race (18 leagues) with رافینیا still honest leader"),
    ("race copy ۱۷ + players hub هفده + search guide ۲۰ + /leagues 20th card (swiss, gate-synced cycle-160), mapping sweep 960 team / 458 player keys with ZERO duplicates",
     "race copy ۱۸ + players hub هجده + search guide ۲۱ + /leagues 21st card (hnl, gate-synced cycle-161), mapping sweep 1009 team / 486 player keys with ZERO duplicates"),
])

patch("scripts/cycle157-domproof.sh", [
    ("# A2: the race honestly grown by swiss (cycle-160) — 340 scorers / 17\n# participants, honest leader رافینیا 13, acl2 NOT in perLeague",
     "# A2: the race honestly grown by swiss (160) + hnl (161) — 360 scorers / 18\n# participants, honest leader رافینیا 13, acl2 NOT in perLeague"),
    ('       len(ts) == 340 and len(pl) == 17 and not ("acl2" in pl) and ("swiss" in pl)',
     '       len(ts) == 360 and len(pl) == 18 and not ("acl2" in pl) and ("swiss" in pl) and ("hnl" in pl)'),
    ("# A7: mapping-sweep duplicate-key guard — 960 team keys / 458 player keys,\n# zero duplicates (the 152/155/156/159 sweep guard at the new totals;\n# gate-synced cycle-160: swiss +47 team / +27 player keys)",
     "# A7: mapping-sweep duplicate-key guard — 1009 team keys / 486 player keys,\n# zero duplicates (the 152/155/156/159 sweep guard at the new totals;\n# gate-synced cycle-161: hnl +49 team / +28 player keys)"),
    ('report("A7 duplicate-key guard", len(tk) == 960 and len(pk) == 458 and not td and not pd,',
     'report("A7 duplicate-key guard", len(tk) == 1009 and len(pk) == 486 and not td and not pd,'),
    ("# B4: /topscorers default — race copy ۱۷ (swiss joined cycle-160) and the\n# search guide grew to ۱۹ on the home search flow",
     "# B4: /topscorers default — race copy ۱۸ (hnl joined cycle-161) and the\n# search guide grew to ۲۱ on the home search flow"),
    ('probe "$BASE/topscorers" "B4 race copy 16 honest" \\',
     'probe "$BASE/topscorers" "B4 race copy 18 honest" \\'),
    ('"(function(){const b=document.body.innerText||\'\';return {copy17:b.includes(\'۱۷ لیگ و جام برتر\'),old16gone:!b.includes(\'۱۶ لیگ و جام برتر\'),noAcl2InRace:(function(){const t=b;return t.indexOf(\'لیگ قهرمانان آسیا ۲\')===-1})()}})()"',
     '"(function(){const b=document.body.innerText||\'\';return {copy18:b.includes(\'۱۸ لیگ و جام برتر\'),old17gone:!b.includes(\'۱۷ لیگ و جام برتر\'),noAcl2InRace:(function(){const t=b;return t.indexOf(\'لیگ قهرمانان آسیا ۲\')===-1})()}})()"'),
    ("return {guide20:b.includes('۲۰ لیگ و جام'),old19gone:!b.includes('۱۹ لیگ و جام')}",
     "return {guide21:b.includes('۲۱ لیگ و جام'),old20gone:!b.includes('۲۰ لیگ و جام')}"),
    ('collect "$FEAT6" "B6 search guide 20"', 'collect "$FEAT6" "B6 search guide 21"'),
    ("# B6: the search guide — ۲۰ لیگ و جام in the real search UI (swiss joins)",
     "# B6: the search guide — ۲۱ لیگ و جام in the real search UI (hnl joins)"),
    ("the race 340 scorers / 17 participants (swiss cycle-160) with رافینیا honest leader in every window",
     "the race 360 scorers / 18 participants (hnl cycle-161) with رافینیا honest leader in every window"),
    ("race copy ۱۷ honest, search guide ۲۰, /leagues 20th card; mapping sweep 960 team / 458 player keys with ZERO duplicates",
     "race copy ۱۸ honest, search guide ۲۱, /leagues 21st card; mapping sweep 1009 team / 486 player keys with ZERO duplicates"),
])

patch("scripts/cycle158-hunt.sh", [
    ("#   race cur 340 scorers / 17 participants (swiss cycle-160), leader رافینیا ۱۳, acl2 NOT\n#   in perLeague; race 2023/2024 = 320/16 with acl2 out (merge-exempt);",
     "#   race cur 360 scorers / 18 participants (hnl cycle-161), leader رافینیا ۱۳, acl2 NOT\n#   in perLeague; race 2023/2024 = 340/17 with acl2 out (merge-exempt);"),
    ("# V1: the hub — 20 league cards, the acl2 card really present\nhunt \"V1 leagues hub 20 cards\" \"$BASE/leagues\" \\",
     "# V1: the hub — 21 league cards, the acl2 card really present\nhunt \"V1 leagues hub 21 cards\" \"$BASE/leagues\" \\"),
    ('"document.body.innerText.includes(\'ستاره‌های هفده\')" >/dev/null 2>&1',
     '"document.body.innerText.includes(\'ستاره‌های هجده\')" >/dev/null 2>&1'),
    ("# V8: players hub — «ستاره‌های هفده» copy + REAL two-step click",
     "# V8: players hub — «ستاره‌های هجده» copy + REAL two-step click"),
    ("# «ستاره‌های هفده» copy belongs to STARS mode — clicking mode-teams",
     "# «ستاره‌های هجده» copy belongs to STARS mode — clicking mode-teams"),
    ('COPY8=$($B eval \'JSON.stringify({c:document.body.innerText.includes("ستاره‌های هفده لیگ و جام برتر")})\' 2>/dev/null | tr -d \'"\\\')',
     'COPY8=$($B eval \'JSON.stringify({c:document.body.innerText.includes("ستاره‌های هجده لیگ و جام برتر")})\' 2>/dev/null | tr -d \'"\\\')'),
    ('# V6a: race page — honest ۱۷ copy (swiss cycle-160), no stale copies, NO acl2 section\nhunt "V6a race copy 17 honest" "$BASE/topscorers" \\\n"document.body.innerText.includes(\'۱۷ لیگ و جام برتر\')" "" \\\n"({copy17:document.body.innerText.includes(\\"۱۷ لیگ و جام برتر\\"),old16gone:!document.body.innerText.includes(\\"۱۶ لیگ و جام برتر\\"),leader:document.body.innerText.includes(\\"رافینیا\\"),noAcl2Section:document.body.innerText.indexOf(\\"لیگ قهرمانان آسیا ۲\\")===-1})"',
     '# V6a: race page — honest ۱۸ copy (hnl cycle-161), no stale copies, NO acl2 section\nhunt "V6a race copy 18 honest" "$BASE/topscorers" \\\n"document.body.innerText.includes(\'۱۸ لیگ و جام برتر\')" "" \\\n"({copy18:document.body.innerText.includes(\\"۱۸ لیگ و جام برتر\\"),old17gone:!document.body.innerText.includes(\\"۱۷ لیگ و جام برتر\\"),leader:document.body.innerText.includes(\\"رافینیا\\"),noAcl2Section:document.body.innerText.indexOf(\\"لیگ قهرمانان آسیا ۲\\")===-1})"'),
    ('# V6b: season-selected 2023/2024 — dynamic «۱۶ لیگ مشارکت‌کننده» (acl2\n# merge-exempt even in the historical window; swiss joined cycle-160)\nhunt "V6b historical race 16" "$BASE/topscorers?season=2023%2F2024" \\\n"document.body.innerText.includes(\'۲۰۲۳/۲۴\')" "" \\\n"({dyn16:document.body.innerText.includes(\\"۱۶ لیگ مشارکت‌کننده\\"),season:document.body.innerText.includes(\\"۲۰۲۳/۲۴\\")})"',
     '# V6b: season-selected 2023/2024 — dynamic «۱۷ لیگ مشارکت‌کننده» (acl2\n# merge-exempt even in the historical window; hnl joined cycle-161)\nhunt "V6b historical race 17" "$BASE/topscorers?season=2023%2F2024" \\\n"document.body.innerText.includes(\'۲۰۲۳/۲۴\')" "" \\\n"({dyn17:document.body.innerText.includes(\\"۱۷ لیگ مشارکت‌کننده\\"),season:document.body.innerText.includes(\\"۲۰۲۳/۲۴\\")})"'),
    ('report("race current",\n       len(ts) == 340 and len(pl) == 17 and "acl2" not in pl and "swiss" in pl',
     'report("race current",\n       len(ts) == 360 and len(pl) == 18 and "acl2" not in pl and "swiss" in pl and "hnl" in pl'),
    ("# A3: historical 2023/2024 window — 320/16 with acl2 honestly out\n# (swiss's archived season HAS the scorer block — gate-synced cycle-160)",
     "# A3: historical 2023/2024 window — 340/17 with acl2 honestly out\n# (hnl's archived season HAS the scorer block — gate-synced cycle-161)"),
    ('       len(ts) == 320 and len(pl) == 16 and "acl2" not in pl and "swiss" in pl,',
     '       len(ts) == 340 and len(pl) == 17 and "acl2" not in pl and "swiss" in pl and "hnl" in pl,'),
    ("# A9: duplicate-key guard — 960 team / 458 player keys, zero duplicates (gate-synced cycle-160)",
     "# A9: duplicate-key guard — 1009 team / 486 player keys, zero duplicates (gate-synced cycle-161)"),
    ('report("A9 duplicate-key guard", len(tk) == 960 and len(pk) == 458 and not td and not pd,',
     'report("A9 duplicate-key guard", len(tk) == 1009 and len(pk) == 486 and not td and not pd,'),
])

print("ALL FIVE SCRIPTS SYNCED")
