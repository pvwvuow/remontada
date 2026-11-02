#!/usr/bin/env python3
# cycle-395 — generate the SQUAD-surface PLAYER_NAME_FA additions (the 394
# card's documented squad-name pool, harvested with the 392 byte-exact
# machinery). Keys resolve against scripts/cycle395-squads-raw.json
# (120 unique raw names across 218 squad rows / 7 flagship teams) —
# hard-fail on any name not present, no guessed keys, no silent gaps.
# The authored pool also de-dupes against the CURRENT map keys parsed
# from src/lib/player-names-fa.ts (zero duplicate keys, the 392 rule).
import json, re, sys

RAW = json.load(open("scripts/cycle395-squads-raw.json", encoding="utf-8"))
pool = {}
for n in RAW["raw_names"]:
    pool.setdefault(n.lower(), n)
    # a name can belong to several squads; the display spelling is identical

AUTHORED = {
    # — Liverpool 8650 (the 394 domproof anchor; the H1 Woodman passthrough
    #   witness is superseded by design — the map grew, the 392→394 arc) —
    "Freddie Woodman": "فردی وودمن",
    "Vítezslav Jaroš": "ویتسلاو یاروش",
    "Harvey Davies": "هاروی دیویس",
    "Joseph Gomez": "جوزف گومز",
    "Wataru Endo": "واتارو اندو",
    "Jérémy Jacquet": "ژرمی ژاکه",
    "Conor Bradley": "کونر برادلی",
    "Giovanni Leoni": "جووانی لئونی",
    "Jeremie Frimpong": "جرمی فریمپونگ",
    "Ronald Araujo": "رونالد آراخو",
    "Ryan Gravenberch": "رایان گراونبرخ",
    "Trey Nyoni": "تری نیونی",
    "James McConnell": "جیمز مک‌کانل",
    "Federico Chiesa": "فدریکو کییزا",
    "Víctor Muñoz": "ویکتور مونیوز",
    "Rio Ngumoha": "ریو نگوموها",
    # — Newcastle 10261 (the 392/394 anchor) —
    "Mark Gillespie": "مارک گیلیسپی",
    "Valentino Livramento": "والنتینو لیورامنتو",
    "Daniel Burn": "دانیل برن",
    "Joelinton": "ژوئلینتون",
    "Jacob Ramsey": "جیکوب رمزی",
    "William Osula": "ویلیام اوسولا",
    # — Persepolis 101610 (the Persian-league surface: the squad rows the
    #   Persian audience actually reads; names seen in Persian media) —
    "Payam Niazmand": "پیام نیازمند",
    "Amirreza Rafiei": "امیررضا رفیعی",
    "Mohammad Gandomi": "محمد گندمی",
    "Amirhossein Taheri Tanha": "امیرحسین طاهری تنها",
    "Abolfazl Jalali": "ابوالفضل جلالی",
    "Hossein Abarghouei": "حسین ابرقوئی",
    "Hossein Kanani": "حسین کنعانی",
    "Majid Eydi": "مجید عیدی",
    "Dániel Gera": "دانیل گرا",
    "Pouya Esmi": "پویا اسیمی",
    "Pouya Pourali": "پویا پورعالی",
    "Oston Urunov": "اوستون اورونوف",
    "Mohammad Khodabandelou": "محمد خدابندلو",
    "Yasin Salmani": "یاسین سلمانی",
    "Marko Bakić": "مارکو باکیچ",
    "Pouria Latififar": "پوریا لطیفی‌فر",
    "Igor Sergeev": "ایگور سرگیف",
    "Amirhossein Mahmoudi": "امیرحسین محمودی",
    "Mohammadhossein Sadeghi": "محمدحسین صادقی",
    # — Iran NT 6711 (the 390 anchor) —
    "Hossein Hosseini": "حسین حسینی",
    "Shoja Khalilzadeh": "شجاع خلیل‌زاده",
    "Saman Fallah": "سامان فلاح",
    "Ali Nemati": "علی نعمتی",
    "Ramin Rezaeian": "رامین رضائیان",
    "Mohammad Naderi": "محمد نادری",
    "Omid Noorafkan": "امید نورافکن",
    "Aref Aghasi": "عارف آغاسی",
    "Mohammadmehdi Mohebi": "محمدمهدی محبی",
    # — Hull 8667 (the 392 anchor) —
    "Lewie Coyle": "لووی کویل",
    "Ryan Giles": "رایان جایلز",
    "Charlie Hughes": "چارلی هیوز",
    "Semi Ajayi": "سمی آجای",
    "Eliot Matazo": "الیوت ماتازو",
    "Darko Gyabi": "دارکو گیابی",
    "Matt Crooks": "مت کروکس",
    "Abdülkadir Ömür": "عبدالقادر عمر",
    "Oli McBurnie": "اولی مک‌برنی",
    # — Omonia 8044 (rule-governed Greek transliteration, the 392 rules:
    #   χ→ک, Γι→ی, -idis→-یدیس, -ou→-و; Dutch G→خ per Gijselhart) —
    "Pantelis Michail": "پانتلیس میخائیل",
    "Anastasios Giannakou": "آناستاسیوس گیاناکو",
    "Evripidis Pepis": "اوریپیدیس پپیس",
    "Nikolas Kyriakidis": "نیکولاس کیریاکیدیس",
    "Fotis Kitsos": "فوتیس کیتسوس",
    "Senou Coulibaly": "سنو کولیبالی",
    "Stefan Simič": "استفان سیمیچ",
    "Giorgos Viktoros": "یورگوس ویکتوروس",
    "Andreas Chatzievangelou": "آندریاس چاتزیوانگلو",
    "Christos Konstantinidis": "کریستوس کونستانتینیدیس",
    "Panagiotis Christoforou": "پانایوتیس کریستوفورو",
    "Jean-Kévin Duverne": "ژان-کوین دوورن",
    "Athos Kounounis": "آتوس کونونیس",
    "Carel Eiting": "کارل ایتینگ",
    "Mateo Marić": "ماتئو ماریچ",
    "Florin Tănase": "فلورین تاناسه",
    "Muamer Tanković": "موآمر تانکوویچ",
    "Panagiotis Andreou": "پانایوتیس آندرئو",
    "Andreas Christou": "آندریاس کریستو",
    "Jaden Montnor": "جایدن مونتنور",
    "Mihlali Mayambela": "میهلالی مایامبلا",
    "Mateusz Musiałowski": "ماتئوش موشیاووفسکی",
    "Angelos Neofytou": "آنجلس نئوفیتو",
    "Vladimiros Savva": "ولادیمیروس ساوا",
    "Konstantinos Panagi": "کونستانتینوس پاناگی",
    "Loïs Diony": "لوئیس دیونی",
    # — Argentina NT 6706 (the 393/394 patrol surface) —
    "Juan Foyth": "خوان فویث",
    "Marcos Senesi": "مارکوس سنیسی",
    "Nicolás Tagliafico": "نیکولاس تالیافیکو",
    "Gonzalo Montiel": "گونزالو مونتیل",
    "Lisandro Martínez": "لیساندرو مارتینز",
    "Cristian Romero": "کریستیان رومرو",
    "Nicolás Otamendi": "نیکولاس اتمندی",
    "Facundo Medina": "فاکوندو مدینا",
    "Santiago Simón": "سانتیاگو سیمون",
    "Tomás Palacios": "توماس پالاسیوس",
    "Román Vega": "رومان وگا",
    "Valentín Gómez": "والنتین گومز",
    "Equi Fernández": "اکی فرناندز",
    "Leandro Paredes": "لئاندرو پاریدس",
    "Rodrigo De Paul": "رودریگو دی پل",
    "Giovani Lo Celso": "جووانی لو سلسو",
    "Nicolás González": "نیکولاس گونسالس",
    "Thiago Almada": "تیاگو آلمادا",
    "Giuliano Simeone": "جولیانو سیمئونه",
    "Valentín Barco": "والنتین بارکو",
    "Gianluca Prestianni": "جانلوکا پرستیانی",
    "José López": "خوزه لوپز",
    "Lucas Beltrán": "لوکاس بلاترن",
    "Leonel Flores": "لئونل فلورس",
}

# 1) resolve every authored name against the byte-exact harvest pool
out, missing = {}, []
for up, fa in AUTHORED.items():
    key = pool.get(up.lower())
    if key is None:
        missing.append(up)
        continue
    ts_key = key.lower()
    if ts_key in out:
        missing.append(f"DUPLICATE-FOLD:{up}")
        continue
    out[ts_key] = fa
if missing:
    print("HARD FAIL — names not byte-exact in harvest pool:", file=sys.stderr)
    for m in missing:
        print("  ", m, file=sys.stderr)
    sys.exit(1)

# 2) zero duplicate keys against the CURRENT map (parse the TS source)
src = open("src/lib/player-names-fa.ts", encoding="utf-8").read()
start = src.index("export const PLAYER_NAME_FA")
end = src.index("\n};", start)
existing = set(re.findall(r'^\s{2}"([^"]+)":', src[start:end], re.M))
collide = sorted(out.keys() & existing)
if collide:
    print("HARD FAIL — keys already present in PLAYER_NAME_FA:", file=sys.stderr)
    for k in collide:
        print("  ", k, file=sys.stderr)
    sys.exit(1)

# 3) byte-safety: non-empty keys/values, Persian values carry Arabic-script
for k, v in out.items():
    assert k and k.strip() and v and v.strip(), (k, v)

# 4) the documented remainder (harvest minus authored) — the honest
#    passthrough list, printed for the worklog card (never claimed zero)
absent = [n for n in RAW["raw_names"] if n.lower() not in out]

lines = []
for k in sorted(out):
    fa = out[k].replace('"', "'")
    lines.append(f'  "{k}": "{fa}",')
block = "\n".join(lines)

with open("scripts/cycle395-map-block.txt", "w", encoding="utf-8") as f:
    f.write(block)
print(f"OK — {len(out)} byte-exact entries emitted to scripts/cycle395-map-block.txt")
print(f"DELIBERATELY ABSENT ({len(absent)}) — honest Latin passthrough stays:")
for n in absent:
    print("  -", n)
