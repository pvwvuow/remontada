#!/usr/bin/env python3
# ------------------------------------------------------------------
# cycle-181 gate sync — precise per-file pin advances (the 165
# convention: advance what the additive change moves, never weaken).
# Numbers: race 380/19 → 400/20, historical 360/18 → 380/19, dynamic
# «۱۸ لیگ مشارکت‌کننده» → ۱۹, hub copy نوزده/هفده → بیست, race copy
# ۱۹/۱۸/۱۷-era → ۲۰, search guide ۲۰/۲۳ → ۲۴. Negative (old-gone) pins
# stay true and keep their old numbers where the old copy is still
# absent. Stale pins broken by the 165/166 copy moves (cycle160 guide20/
# هفده, cycle161 copy18) jump straight to the new truth.
# ------------------------------------------------------------------
import pathlib

FILES = {
    "scripts/cycle152-domproof.sh": [
        ("len(pl) == 19 and 'hnl' in pl", "len(pl) == 20 and 'hnl' in pl"),
        ("copy19:b.includes('۱۹ لیگ و جام برتر')", "copy20:b.includes('۲۰ لیگ و جام برتر')"),
    ],
    "scripts/cycle153-hunt.sh": [
        ("len(ts) == 360 and len(pl) == 18", "len(ts) == 380 and len(pl) == 19"),
    ],
    "scripts/cycle155-domproof.sh": [
        ("len(ts) == 380 and len(pl) == 19", "len(ts) == 400 and len(pl) == 20"),
        ('copy19:(document.body.innerText||"").includes("۱۹ لیگ و جام برتر")',
         'copy20:(document.body.innerText||"").includes("۲۰ لیگ و جام برتر")'),
    ],
    "scripts/cycle156-domproof.sh": [
        ("len(pl) == 19 and 'hnl' in pl", "len(pl) == 20 and 'hnl' in pl"),
        ("len(pl) == 18 and 'eredivisie' in pl", "len(pl) == 19 and 'eredivisie' in pl"),
        ("'نوزده لیگ و جام برتر'", "'بیست لیگ و جام برتر'"),
    ],
    "scripts/cycle157-domproof.sh": [
        ("len(ts) == 380 and len(pl) == 19", "len(ts) == 400 and len(pl) == 20"),
        ("copy19:b.includes('۱۹ لیگ و جام برتر')", "copy20:b.includes('۲۰ لیگ و جام برتر')"),
        ("guide23:b.includes('۲۳ لیگ و جام')", "guide24:b.includes('۲۴ لیگ و جام')"),
        ("old22gone:!b.includes('۲۲ لیگ و جام')", "old23gone:!b.includes('۲۳ لیگ و جام')"),
    ],
    "scripts/cycle158-hunt.sh": [
        ("document.body.innerText.includes('۱۹ لیگ و جام برتر')", "document.body.innerText.includes('۲۰ لیگ و جام برتر')"),
        ('copy19:document.body.innerText.includes("۱۹ لیگ و جام برتر")', 'copy20:document.body.innerText.includes("۲۰ لیگ و جام برتر")'),
        ("len(ts) == 380 and len(pl) == 19", "len(ts) == 400 and len(pl) == 20"),
        ("len(ts) == 360 and len(pl) == 18", "len(ts) == 380 and len(pl) == 19"),
        ("«ستاره‌های نوزده لیگ و جام برتر»", "«ستاره‌های بیست لیگ و جام برتر»"),
        ("ستاره‌های نوزده", "ستاره‌های بیست"),
        ("includes('ستاره‌های نوزده')", "includes('ستاره‌های بیست')"),
        ("نوزده لیگ و جام برتر", "بیست لیگ و جام برتر"),
        ("«۱۸ لیگ مشارکت‌کننده»", "«۱۹ لیگ مشارکت‌کننده»"),
        ('dyn18:document.body.innerText.includes("۱۸ لیگ مشارکت‌کننده")', 'dyn19:document.body.innerText.includes("۱۹ لیگ مشارکت‌کننده")'),
    ],
    "scripts/cycle160-domproof.sh": [
        ("guide20:b.includes('۲۰ لیگ و جام')", "guide24:b.includes('۲۴ لیگ و جام')"),
        ("old19gone:!b.includes('۱۹ لیگ و جام')", "old23gone:!b.includes('۲۳ لیگ و جام')"),
        ("ستاره‌های هفده", "ستاره‌های بیست"),
        ("players hub هفده + search guide ۲۰ + race copy ۱۷", "players hub بیست + search guide ۲۴ + race copy ۲۰"),
    ],
    "scripts/cycle161-domproof.sh": [
        ("copy18:b.includes('۱۸ لیگ و جام برتر')", "copy20:b.includes('۲۰ لیگ و جام برتر')"),
    ],
    "scripts/cycle162-domproof.sh": [
        ("len(pl)==19 and len(sc)==380", "len(pl)==20 and len(sc)==400"),
        ("len(pl)==18 and len(sc)==360", "len(pl)==19 and len(sc)==380"),
        ("copy19:b.includes('۱۹ لیگ و جام برتر')", "copy20:b.includes('۲۰ لیگ و جام برتر')"),
    ],
    "scripts/cycle163-hunt.sh": [
        ("نوزده لیگ و جام برتر", "بیست لیگ و جام برتر"),
    ],
    "scripts/cycle165-domproof.sh": [
        ("len(ts)==380 and len(pl)==19", "len(ts)==400 and len(pl)==20"),
        ("len(ts)==360 and len(pl)==18", "len(ts)==380 and len(pl)==19"),
        ("copy19:(document.body.innerText||'').includes('۱۹ لیگ و جام برتر')", "copy20:(document.body.innerText||'').includes('۲۰ لیگ و جام برتر')"),
        ("old18gone:!(document.body.innerText||'').includes('۱۸ لیگ و جام برتر')", "old19gone:!(document.body.innerText||'').includes('۱۹ لیگ و جام برتر')"),
        ("guide23:(document.body.innerText||'').includes('۲۳ لیگ و جام')", "guide24:(document.body.innerText||'').includes('۲۴ لیگ و جام')"),
        ("old22gone:!(document.body.innerText||'').includes('۲۲ لیگ و جام')", "old23gone:!(document.body.innerText||'').includes('۲۳ لیگ و جام')"),
        ("A2 race 380/19", "A2 race 400/20"),
        ("A3 race 360/18", "A3 race 380/19"),
    ],
    "scripts/cycle166-domproof.sh": [
        ("آقای گل‌های ۲۳ لیگ و جام", "آقای گل‌های ۲۴ لیگ و جام"),
    ],
    "scripts/cycle168-hunt.sh": [
        ("len(ts) == 380 and len(pl) == 19", "len(ts) == 400 and len(pl) == 20"),
        ("len(ts) == 360 and len(pl) == 18", "len(ts) == 380 and len(pl) == 19"),
        ("copy19:(document.body.innerText||'').includes('۱۹ لیگ و جام برتر')", "copy20:(document.body.innerText||'').includes('۲۰ لیگ و جام برتر')"),
        ("old18gone:!(document.body.innerText||'').includes('۱۸ لیگ و جام برتر')", "old19gone:!(document.body.innerText||'').includes('۱۹ لیگ و جام برتر')"),
        ("copy19p:b.includes('نوزده لیگ و جام برتر')", "copy20p:b.includes('بیست لیگ و جام برتر')"),
        ("«ستاره‌های نوزده لیگ و جام برتر ...»", "«ستاره‌های بیست لیگ و جام برتر ...»"),
        ("copy نوزده read FIRST", "copy بیست read FIRST"),
        ("«۱۸ لیگ", "«۱۹ لیگ"),
        ("dyn18:", "dyn19:"),
    ],
}

for f, repls in FILES.items():
    p = pathlib.Path(f)
    src = p.read_text(encoding="utf-8")
    out = src
    hits = []
    missed = []
    for a, b in repls:
        if a in out:
            out = out.replace(a, b)
            hits.append(a[:40])
        else:
            missed.append(a[:40])
    if out != src:
        p.write_text(out, encoding="utf-8")
    print(f"{f}: {len(hits)} applied, {len(missed)} missed")
    for m in missed:
        print(f"   MISSED: {m}")
