#!/usr/bin/env python3
# cycle-391 map generator — emits the TS VENUE_FA / VENUE_CITY_FA block.
# KEYS: byte-exact from scripts/cycle391-venues.json (the live probe output —
# never retyped, the 387 lesson). VALUES: authored Persian transliterations.
# Any venue/city without a value below hard-fails the generation (no silent gaps).
import json
import sys

SRC = "/home/z/my-project/remontada/scripts/cycle391-venues.json"
OUT = "/home/z/my-project/scripts/cycle391_map.ts"

VENUE_FA = {
    "Allianz Arena": "آلیانتس آرنا",
    "Allianz Riviera": "آلیانتس ریویرا",
    "Allianz Stadium": "ورزشگاه آلیانتس",
    "American Express Stadium": "ورزشگاه امریکن اکسپرس",
    "Anfield": "آنفیلد",
    "Azadi Stadium": "ورزشگاه آزادی",
    "BayArena": "بای‌آرنا",
    "Bluenergy Stadium": "ورزشگاه بلو‌انرژی",
    "CEPAC Vélodrome": "ورزشگاه ولودروم",
    "Campos de Sport de El Sardinero": "کامپوس د اسپورت د ال ساردینرو",
    "Coventry Building Society Arena": "آرنای کوونتری بیلدینگ سوسایتی",
    "Craven Cottage": "کریون کاتیج",
    "Decathlon Arena - Stade Pierre-Mauroy": "آرنای دیکاتلون — ورزشگاه پیر موروا",
    "Deutsche Bank Park": "ورزشگاه دویچه بانک",
    "Elland Road": "الند رود",
    "Emirates Stadium": "ورزشگاه امارات",
    "Estadio Abanca-Balaídos": "ورزشگاه آبانکا-بالاییدوس",
    "Estadio Abanca-Riazor": "ورزشگاه آبانکا-ریازور",
    "Estadio Bernabéu": "ورزشگاه برنابئو",
    "Estadio Ciudad de Valencia": "ورزشگاه سیوداد د والنسیا",
    "Estadio Coliseum": "ورزشگاه کولیسئوم",
    "Estadio El Sadar": "ورزشگاه ال سادار",
    "Estadio La Cartuja de Sevilla": "ورزشگاه لا کارتوخا سویا",
    "Estadio La Rosaleda": "ورزشگاه لا روسالدا",
    "Estadio Manuel Martínez Valero": "ورزشگاه مانوئل مارتینز والرو",
    "Estadio Municipal de Anoeta": "ورزشگاه شهری آنوئتا",
    "Estadio Ramón Sánchez Pizjuán": "ورزشگاه رامون سانچز پیسخوان",
    "Estadio de Mendizorroza": "ورزشگاه مندیسوروسا",
    "Estadio de Mestalla": "ورزشگاه مِستایا",
    "Estadio de San Mamés": "ورزشگاه سان مامس",
    "Estadio de Vallecas": "ورزشگاه بایکاس",
    "Estadio de la Cerámica": "ورزشگاه لا سرامیکا",
    "Etihad Stadium": "ورزشگاه اتحاد",
    "Europa-Park Stadion": "ورزشگاه اروپا-پارک",
    "Foolad Shahr Stadium": "ورزشگاه فولادشهر",
    "Gol Gohar Sport Complex": "مجموعهٔ ورزشی گل‌گهر",
    "Grand Shiraz Stadium": "ورزشگاه بزرگ شیراز",
    "Groupama Stadium": "ورزشگاه گروپاما",
    "Gtech Community Stadium": "ورزشگاه جی‌تک کامینیتی",
    "Hill Dickinson Stadium": "ورزشگاه هیل دیکینسون",
    "Home Deluxe Arena": "آرنای هوم دلوکس",
    "Imam Khomeini Stadium": "ورزشگاه امام خمینی",
    "MAPEI Stadium - Città del Tricolore": "ورزشگاه ماپئی — چیتا دل تریکوله",
    "MEWA ARENA": "آرنای مِوا",
    "MHPArena": "ام‌اچ‌پی آرنا",
    "MKM Stadium": "ورزشگاه ام‌کی‌ام",
    "Naghsh-e-Jahan Stadium": "ورزشگاه نقش جهان",
    "New Balance Arena": "آرنای نیوبالنس",
    "Old Trafford": "اولد ترافورد",
    "Parc des Princes": "پارک دو پرنس",
    "Portman Road": "پورتمن رود",
    "RCDE Stadium": "ورزشگاه RCDE",
    "Red Bull Arena": "ورزشگاه رد بول",
    "RheinEnergieSTADION": "ورزشگاه راین‌انرژی",
    "Riyadh Air Metropolitano": "ورزشگاه ریاض ایر متروپولیتانو",
    "Roazhon Park": "روازون پارک",
    "SIGNAL IDUNA PARK": "ورزشگاه سیگنال ایدونا",
    "SNP Arena": "آرنای اس‌ان‌پی",
    "Sardare Azadegan Stadium": "ورزشگاه سردار آزادگان",
    "Selhurst Park": "سلهرست پارک",
    "Shahid Dastgerdi Stadium": "ورزشگاه شهید دستگردی",
    "Shahid Nasiri Stadium": "ورزشگاه شهید نصیری",
    "Shohada Mes Shahrbabak Stadium": "ورزشگاه شهدای مس شهربابک",
    "Shohadaye Foolad Khoozestan": "ورزشگاه شهدای فولاد خوزستان",
    "Sirous Ghayeghran Stadium": "ورزشگاه سیروس قایقران",
    "Spotify Camp Nou": "ورزشگاه اسپاتیفای کمپ نو",
    "St. James' Park": "ورزشگاه سنت جیمز پارک",
    "Stade Bollaert-Delelis": "ورزشگاه بولارت-دللیس",
    "Stade CMA CGM Océane": "ورزشگاه اوسئان",
    "Stade Francis-Le Blé": "ورزشگاه فرانسیس لو بله",
    "Stade Jean Bouin": "ورزشگاه ژان بوین",
    "Stade Louis-II": "ورزشگاه لویی دو",
    "Stade Marie-Marvingt": "ورزشگاه ماری ماروان",
    "Stade Raymond Kopa": "ورزشگاه ریموند کوپا",
    "Stade de l'Abbé Deschamps": "ورزشگاه ابه دشان",
    "Stade de l'Aube": "ورزشگاه اوب",
    "Stade de la Meinau": "ورزشگاه لامنو",
    "Stade du Moustoir - Yves Allainmat": "ورزشگاه موستوآر — ایو الانمات",
    "Stadio Artemio Franchi": "ورزشگاه آرتمیو فرانکی",
    "Stadio Benito Stirpe": "ورزشگاه بنیتو استیرپه",
    "Stadio Comunale Luigi Ferraris": "ورزشگاه لوییجی فراریس",
    "Stadio Diego Armando Maradona": "ورزشگاه دیگو آرماندو مارادونا",
    "Stadio Ennio Tardini": "ورزشگاه انیو تاردینی",
    "Stadio Ettore Giardiniero - Via del Mare": "ورزشگاه اتوره جاردینیه‌رو — ویا دل ماره",
    "Stadio Giuseppe Meazza": "ورزشگاه جوزپه مه‌اتزا",
    "Stadio Giuseppe Sinigaglia": "ورزشگاه جوزپه سینیگالیا",
    "Stadio Olimpico": "ورزشگاه المپیکو",
    "Stadio Olimpico Grande Torino": "ورزشگاه المپیکو گرنده تورینو",
    "Stadio Pier Luigi Penzo": "ورزشگاه پیر لوییجی پنتزو",
    "Stadio Renato Dall'Ara": "ورزشگاه رناتو دال‌آرا",
    "Stadion An der Alten Försterei": "ورزشگاه آن در آلتن فورستری",
    "Stadium de Toulouse": "ورزشگاه تولوز",
    "Stadium of Light": "ورزشگاه آو لایت",
    "Stamford Bridge": "استمفورد بریج",
    "Takhti Stadium": "ورزشگاه تختی",
    "The City Ground": "ورزشگاه سیتی گراند",
    "Tottenham Hotspur Stadium": "ورزشگاه تاتنهام هاتسپر",
    "U-Power Stadium": "ورزشگاه یو-پاور",
    "URSAPHARM-Arena an der Kaiserlinde": "آرنای اورزافارم آن در کایزرلینده",
    "Unipol Domus": "ورزشگاه اونیپول دوموس",
    "VELTINS-Arena": "ورزشگاه فلتینس",
    "Vatani Stadium": "ورزشگاه وطنی",
    "Villa Park": "ویلا پارک",
    "Vitality Stadium": "ورزشگاه ویتالیتی",
    "Volksparkstadion": "ورزشگاه فولکس‌پارک",
    "WWK Arena": "ورزشگاه WWK",
    "Weserstadion": "ورزشگاه وِزِر",
    "Yadegar-e-Imam Stadium": "ورزشگاه یادگار امام",
    "ista-Borussia-Park": "ورزشگاه بوروسیا پارک",
}

CITY_FA = {
    "A Coruña (La Coruña)": "لاکرونیا",
    "Abadan": "آبادان",
    "Ahvāz (Ahwaz)": "اهواز",
    "Angers": "آنژه",
    "Arak": "اراک",
    "Augsburg": "آوگسبورگ",
    "Auxerre": "اوسر",
    "Bandar-e-Anzalī": "بندر انزلی",
    "Barcelona": "بارسلونا",
    "Bergamo": "برگامو",
    "Berlin": "برلین",
    "Bilbao": "بیلبائو",
    "Birmingham": "برمینگهام",
    "Bologna": "بولونیا",
    "Bournemouth, Dorset": "بورنموث",
    "Bremen": "برمن",
    "Brentford, Middlesex": "برنتفورد",
    "Brest": "برست",
    "Cagliari": "کالیاری",
    "Como": "کومو",
    "Cornella de Llobregat": "کورنلا د یوبرگات",
    "Coventry, West Midlands": "کوونتری",
    "Donostia-San Sebastián": "سان‌سباستین",
    "Dortmund": "دورتموند",
    "Décines-Charpieu": "دسین-شارپیو",
    "Elche": "الچه",
    "Esfahān (Isfahan)": "اصفهان",
    "Falmer, East Sussex": "فالمر",
    "Firenze": "فلورانس",
    "Frankfurt am Main": "فرانکفورت",
    "Freiburg im Breisgau": "فرایبورگ",
    "Frosinone": "فروزینونه",
    "Fuladshahr": "فولادشهر",
    "Gelsenkirchen": "گلزن‌کیرشن",
    "Genova": "جنوا",
    "Getafe": "ختافه",
    "Hamburg": "هامبورگ",
    "Hull": "هال",
    "Ipswich, Suffolk": "ایپسویچ",
    "Khorramabad": "خرم‌آباد",
    "Köln": "کلن",
    "Le Havre": "لو آور",
    "Le Mans": "لو مان",
    "Lecce": "لچه",
    "Leeds, West Yorkshire": "لیدز",
    "Leipzig": "لایپزیش",
    "Lens": "لانس",
    "Leverkusen": "لورکوزن",
    "Liverpool": "لیورپول",
    "Liverpool, Merseyside": "لیورپول",
    "London": "لندن",
    "Lorient": "لوریان",
    "Madrid": "مادرید",
    "Mainz": "ماینتس",
    "Manchester": "منچستر",
    "Marseille": "مارسی",
    "Milano": "میلان",
    "Monaco": "موناکو",
    "Monza": "مونزا",
    "Málaga": "مالاگا",
    "Mönchengladbach": "مونشن‌گلادباخ",
    "München": "مونیخ",
    "Napoli": "ناپل",
    "Newcastle upon Tyne": "نیوکاسل",
    "Nice": "نیس",
    "Nottingham, Nottinghamshire": "ناتینگهام",
    "Paderborn": "پادربورن",
    "Pamplona (Iruñea)": "پامپلونا",
    "Paris": "پاریس",
    "Parma": "پارما",
    "Qazvin": "قزوین",
    "Qā'em-Shahr (Ghaemshahr)": "قائم‌شهر",
    "Reggio Emilia": "رجو امیلیا",
    "Rennes": "رن",
    "Roma": "رم",
    "Santander": "سانتاندر",
    "Sevilla": "سویا",
    "Shahr-e Babak": "شهربابک",
    "Shīrāz (Shiraz)": "شیراز",
    "Sinsheim": "زینسهایم",
    "Sirjan": "سیرجان",
    "Spiesen-Elversberg": "اشپیسن-الفرسبرگ",
    "Strasbourg": "استراسبورگ",
    "Stuttgart": "اشتوتگارت",
    "Sunderland": "ساندرلند",
    "Tabrīz (Tabriz)": "تبریز",
    "Tehrān (Teheran)": "تهران",
    "Torino": "تورین",
    "Toulouse": "تولوز",
    "Troyes": "تروا",
    "Udine": "اودینه",
    "Valencia": "والنسیا",
    "Venezia": "ونیز",
    "Vigo": "ویگو",
    "Villarreal": "ویارئال",
    "Villeneuve d'Ascq": "ویلنوو داسک",
    "Vitoria-Gasteiz": "ویتوریا-گاستیس",
    "Yazd": "یزد",
}


def js(s: str) -> str:
    return json.dumps(s, ensure_ascii=False)


def main() -> int:
    data = json.load(open(SRC))
    venues = {v["venue"] for v in data["venues"] if v["venue"]}
    cities = {v["city"] for v in data["venues"] if v["city"]}

    missing_v = sorted(venues - set(VENUE_FA))
    extra_v = sorted(set(VENUE_FA) - venues)
    missing_c = sorted(cities - set(CITY_FA))
    extra_c = sorted(set(CITY_FA) - cities)
    if missing_v or missing_c:
        for k in missing_v:
            print("MISSING VENUE VALUE:", repr(k), file=sys.stderr)
        for k in missing_c:
            print("MISSING CITY VALUE:", repr(k), file=sys.stderr)
        return 1
    if extra_v or extra_c:
        for k in extra_v:
            print("WARN extra venue (dropped):", repr(k), file=sys.stderr)
        for k in extra_c:
            print("WARN extra city (dropped):", repr(k), file=sys.stderr)

    lines: list[str] = []
    lines.append("// cycle-391: venue + city Persian maps — the 388-F4 venue field-choice")
    lines.append("// leak flipped: the «ورزشگاه خانه» card rendered the raw upstream name/city")
    lines.append("// (probed 2026-11-02: the data/teams venue widget carries NO fa fields even")
    lines.append("// for Iranian clubs — Persepolis serves «Azadi Stadium / Tehrān (Teheran)»),")
    lines.append("// so a name-only point map is the only honest heal. KEYS are byte-exact from")
    lines.append("// the live harvest of the six flagship rosters (scripts/cycle391-venues.json:")
    lines.append("// 114/114 teams carried a venue, 110 unique names, 98 unique cities —")
    lines.append("// persiangulf/pl/laliga/seriea/bundesliga/ligue1 via the cached team-venue")
    lines.append("// route). Everything beyond keeps the honest Latin passthrough (the 388")
    lines.append("// documented-unscheduled convention — never faked, never claimed zero).")
    lines.append("// «Takhti Stadium» is intentionally ONE key: the Persian name is identical")
    lines.append("// for both Abadan and Khorramabad, the city line differentiates.")
    lines.append("const VENUE_FA: Record<string, string> = {")
    for k in sorted(VENUE_FA):
        lines.append(f"  {js(k)}: {js(VENUE_FA[k])},")
    lines.append("};")
    lines.append("")
    lines.append("const VENUE_CITY_FA: Record<string, string> = {")
    for k in sorted(CITY_FA):
        lines.append(f"  {js(k)}: {js(CITY_FA[k])},")
    lines.append("};")
    lines.append("")
    lines.append("/** cycle-391: Persian venue name, null = honest Latin passthrough */")
    lines.append("export function venueFa(name: string | null | undefined): string | null {")
    lines.append("  const key = typeof name === \"string\" ? name.trim() : \"\";")
    lines.append("  return key ? (VENUE_FA[key] ?? null) : null;")
    lines.append("}")
    lines.append("")
    lines.append("/** cycle-391: Persian venue city, null = honest Latin passthrough */")
    lines.append("export function venueCityFa(city: string | null | undefined): string | null {")
    lines.append("  const key = typeof city === \"string\" ? city.trim() : \"\";")
    lines.append("  return key ? (VENUE_CITY_FA[key] ?? null) : null;")
    lines.append("}")
    lines.append("")
    with open(OUT, "w") as f:
        f.write("\n".join(lines))
    print(f"OK wrote {OUT}: {len(VENUE_FA)} venues, {len(CITY_FA)} cities")
    return 0


if __name__ == "__main__":
    sys.exit(main())
