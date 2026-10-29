// ------------------------------------------------------------------
// Remontada — League configuration & Persian name mappings
// ------------------------------------------------------------------

export interface LeagueConfig {
  key: string;          // internal key
  fotmobId: number;     // FotMob league id
  ccode3: string;       // FotMob country code
  faName: string;       // Persian display name
  enName: string;
  espnSlug?: string;    // ESPN fallback slug
  priority: number;     // lower = higher in list
}

export const LEAGUES: LeagueConfig[] = [
  { key: "ucl",        fotmobId: 42,         ccode3: "UEFA", faName: "لیگ قهرمانان اروپا",  enName: "Champions League", espnSlug: "uefa.champions", priority: 1 },
  { key: "pl",         fotmobId: 47,         ccode3: "ENG",  faName: "پریمیرلیگ انگلیس",    enName: "Premier League",   espnSlug: "eng.1",          priority: 2 },
  { key: "laliga",     fotmobId: 87,         ccode3: "ESP",  faName: "لالیگا اسپانیا",      enName: "LaLiga",           espnSlug: "esp.1",          priority: 3 },
  { key: "seriea",     fotmobId: 55,         ccode3: "ITA",  faName: "سری‌آ ایتالیا",       enName: "Serie A",          espnSlug: "ita.1",          priority: 4 },
  { key: "bundesliga", fotmobId: 54,         ccode3: "GER",  faName: "بوندسلیگا آلمان",     enName: "Bundesliga",       espnSlug: "ger.1",          priority: 5 },
  { key: "ligue1",     fotmobId: 53,         ccode3: "FRA",  faName: "لیگ ۱ فرانسه",        enName: "Ligue 1",          espnSlug: "fra.1",          priority: 6 },
  // cycle-136: fotmobId 1000001715 was a PLACEHOLDER (upstream answered a
  // literal null body → the designed 503 era). Live probe 2026-10-29 (UA
  // Chrome/124) found the real id — fotmob.com/leagues/523 — serving the
  // full 2026/2027 table (18 teams, Persepolis/Sepahan/Esteghlal 20 pts),
  // 17 historical seasons, top-scorer category with fetchAllUrl, 24-entry
  // title history (2001/2002 → 2024/2025) and real transfers. One id flip
  // lights up every league surface for the home league (standings, fixtures,
  // scorers + the global merge's 6th league, transfers, titles, /players
  // all-teams mode, team index/search).
  { key: "persiangulf",fotmobId: 523,           ccode3: "IRN",  faName: "لیگ خلیج فارس ایران", enName: "Persian Gulf Pro League", priority: 7 },
];

// Persian names for well-known competitions that appear inside the
// daily matches feed (FotMob /api/data/matches)
const COMPETITION_FA: Record<string, string> = {
  "champions league": "لیگ قهرمانان اروپا",
  "uefa champions league": "لیگ قهرمانان اروپا",
  "champions league qualification": "مقدماتی لیگ قهرمانان اروپا",
  "uefa champions league qualification": "مقدماتی لیگ قهرمانان اروپا",
  "europa league": "لیگ اروپا",
  "uefa europa league": "لیگ اروپا",
  "conference league": "لیگ کنفرانس اروپا",
  "premier league": "پریمیرلیگ انگلیس",
  "laliga": "لالیگا",
  "la liga": "لالیگا",
  "serie a": "سری‌آ",
  "bundesliga": "بوندسلیگا",
  "ligue 1": "لیگ ۱ فرانسه",
  "persian gulf": "لیگ خلیج فارس",
  "persian gulf pro league": "لیگ خلیج فارس",
  "efl cup": "جام اتحادیه انگلیس",
  "carabao cup": "جام اتحادیه انگلیس",
  "fa cup": "جام حذفی انگلیس",
  "copa del rey": "جام حذفی اسپانیا",
  "copa italia": "جام حذفی ایتالیا",
  "coppa italia": "جام حذفی ایتالیا",
  "dfb pokal": "جام حذفی آلمان",
  "supercopa": "سوپرکاپ اسپانیا",
  "community shield": "سوپرکاپ انگلیس",
  "club friendlies": "بازی دوستانه باشگاهی",
  "friendlies": "بازی دوستانه",
  "saudi pro league": "لیگ حرفه‌ای عربستان",
  "pro league": "لیگ حرفه‌ای عربستان",
  "eredivisie": "اردیویزه هلند",
  "primeira liga": "لیگ پرتغال",
  "liga portugal": "لیگ پرتغال",
  "super lig": "سوپرلیگ ترکیه",
  "turkish super lig": "سوپرلیگ ترکیه",
  "jupiler pro league": "لیگ بلژیک",
  "scottish premiership": "پریمیرشیپ اسکاتلند",
  "mls": "لیگ حرفه‌ای آمریکا",
  "campeonato brasileiro": "لیگ برزیل",
  "brasileirão": "لیگ برزیل",
  "liga mx": "لیگ مکزیک",
  "super league greece": "سوپرلیگ یونان",
  "j1 league": "جی‌لیگ ژاپن",
  "azadegan league": "لیگ آزادگان",
};

// Persian team-name mapping (FotMob English names → فارسی)
// Matching is done on lower-cased name / shortName / longName.
const TEAM_FA: Record<string, string> = {
  // ---- Premier League ----
  "arsenal": "آرسنال", "aston villa": "استون‌ویلا", "bournemouth": "بورنموث",
  "afc bournemouth": "بورنموث",
  "brentford": "برنتفورد", "brighton": "برایتون", "brighton and hove albion": "برایتون",
  "brighton & hove albion": "برایتون",
  "burnley": "بارنلی", "chelsea": "چلسی", "crystal palace": "کریستال‌پالاس",
  "everton": "اورتون", "fulham": "فولام", "leeds": "لیدز", "leeds united": "لیدز",
  "liverpool": "لیورپول", "man city": "منچسترسیتی", "manchester city": "منچسترسیتی",
  "man united": "منچستریونایتد", "man utd": "منچستریونایتد", "manchester united": "منچستریونایتد",
  "newcastle": "نیوکاسل", "newcastle united": "نیوکاسل",
  "nottingham forest": "ناتینگهام‌فارست", "sunderland": "ساندرلند",
  "tottenham": "تاتنهام", "tottenham hotspur": "تاتنهام", "west ham": "وستهام",
  "west ham united": "وستهام", "wolves": "ولوز", "wolverhampton wanderers": "ولوز",
  // ---- La Liga ----
  "alavés": "آلاوس", "alaves": "آلاوس", "athletic club": "اتلتیک‌بیلبائو",
  "athletic bilbao": "اتلتیک‌بیلبائو", "atlético madrid": "اتلتیکومادرید",
  "atletico madrid": "اتلتیکومادرید", "barcelona": "بارسلونا", "real betis": "رئال‌بتیس",
  "celta vigo": "سلتاویگو", "elche": "الچه", "espanyol": "اسپانیول",
  "getafe": "ختافه", "girona": "خیرونا", "levante": "لوانته", "mallorca": "مایورکا",
  "osasuna": "اوساسونا", "rayo vallecano": "رایووایکانو", "real madrid": "رئال‌مادرید",
  "real oviedo": "رئال اویدو", "real sociedad": "رئال‌سوسیداد", "sevilla": "سویا",
  "valencia": "والنسیا", "villarreal": "ویارئال",
  "deportivo a coruña": "دپورتیوو لاکرونیا", "racing de santander": "راسینگ سانتاندر",
  // ---- Serie A ----
  "atalanta": "آتالانتا", "bologna": "بولونیا", "cagliari": "کالیاری", "como": "کومو",
  "cremonese": "کرمونزه", "fiorentina": "فیورنتینا", "frosinone": "فروزینونه", "genoa": "جنوا",
  "hellas verona": "هلاس‌ورونا", "inter": "اینتر", "inter milan": "اینتر", "internazionale": "اینتر",
  "juventus": "یوونتوس", "lazio": "لاتزیو", "lecce": "لچه", "milan": "آث‌میلان",
  "napoli": "ناپولی", "parma": "پارما", "pisa": "پیزا", "roma": "رم", "as roma": "رم",
  "sassuolo": "ساسوولو", "torino": "تورینو", "udinese": "اودینزه",
  // ---- Bundesliga ----
  "augsburg": "آگزبورگ", "bayern munich": "بایرن‌مونیخ", "bayern": "بایرن‌مونیخ",
  "union berlin": "یونیون‌برلین", "werder bremen": "وردربرمن", "sv werder bremen": "وردربرمن", "borussia dortmund": "بروسیادورتموند",
  "dortmund": "دورتموند", "eintracht frankfurt": "اینتراخت‌فرانکفورت", "frankfurt": "فرانکفورت",
  "freiburg": "فرایبورگ", "hamburger sv": "هامبورگ", "hamburg": "هامبورگ",
  "heidenheim": "هایدنهایم", "hoffenheim": "هوفنهایم", "fc cologne": "کلن",
  "köln": "کلن", "koln": "کلن", "rb leipzig": "لایپزیش", "leipzig": "لایپزیش",
  "bayer leverkusen": "لورکوزن", "leverkusen": "لورکوزن", "mainz": "ماینتس",
  "st. pauli": "سنت‌پائولی", "vfb stuttgart": "اشتوتگارت", "stuttgart": "اشتوتگارت",
  "borussia mönchengladbach": "مونشن‌گلادباخ", "m'gladbach": "مونشن‌گلادباخ",
  // ---- Ligue 1 ----
  "angers": "انژه", "brest": "برست", "le havre": "لوآور", "lens": "لانس",
  "lille": "لیل", "lorient": "لوریان", "lyon": "لیون", "olympique lyon": "لیون",
  "marseille": "مارسی", "olympique marseille": "مارسی", "metz": "متز",
  "monaco": "موناکو", "nantes": "نانت", "nice": "نیس", "paris fc": "پاریس‌اف‌سی",
  "paris saint germain": "پاری‌سن‌ژرمن", "paris sg": "پاری‌سن‌ژرمن", "psg": "پاری‌سن‌ژرمن",
  "rennes": "رن", "strasbourg": "استراسبورگ", "toulouse": "تولوز", "auxerre": "اوشر",
  "le mans": "لومان",
  // ---- Iranian Persian Gulf Pro League ----
  "persepolis": "پرسپولیس", "esteghlal": "استقلال", "tractor": "تراکتور",
  "tractor sazi": "تراکتور", "sepahan": "سپاهان", "foolad": "فولاد خوزستان",
  // cycle-136: exact upstream row names of the live 523 table (teamFa matches
  // on the exact lower-cased name, so the historical aliases above are not
  // enough) — probed row names: Persepolis, Sepahan, Esteghlal, Tractor,
  // Foolad Khuzestan, Aluminium Arak, Kheybar Khorramabad, Fajr Sepasi,
  // Gol Gohar, Chadormalu Ardakan SC, Nassaji Mazandaran FC, Malavan,
  // Paykan, Esteghlal Khuzestan, Zob Ahan, Shams Azar Qazvin,
  // Sanat Naft Abadan, Mes Shahr Babak
  "foolad khuzestan": "فولاد خوزستان",
  // ("gol gohar" already mapped below — FotMob spelling variant block)
  "aluminium arak": "آلومینیوم اراک", "aluminum arak": "آلومینیوم اراک",
  "kheybar khorramabad": "خیبر خرم‌آباد",
  "chadormalu ardakan sc": "چادرملو اردکان",
  "nassaji mazandaran fc": "نساجی مازندران",
  "shams azar qazvin": "شمس‌آذر قزوین",
  "sanat naft abadan": "صنعت نفت آبادان",
  "mes shahr babak": "مس شهربابک",
  "golgohar": "گل‌گهر", "esteghlal khuzestan": "استقلال خوزستان",
  "zob ahan": "ذوب‌آهن", "aluminum": "آلومینیوم هرمزگان", "malavan": "ملوان",
  "havadar": "هوادار", "shams azar": "شمس‌آذر قزوین", "kheybar": "خیبر خرم‌آباد",
  "paykan": "پیکان", "chadormalu": "چادرملو", "mes rafsanjan": "مس‌رفسنجان",
  "nassaji": "نساجی مازندران", "sanat naft": "صنعت نفت آبادان",
  "esteghlal molasani": "استقلال ملاسانی",
  "saipa": "سایپا", "naft gachsaran": "نفت و گاز گچساران",
  "shahr khodro": "شهرخودرو", "pars jonoubi": "پارس جنوبی جام جم",
  "machine sazi": "ماشین‌سازی تبریز", "machine sazi tabriz": "ماشین‌سازی تبریز",
  "gol gohar sirjan": "گل‌گهر سیرجان", "mes sookht": "مص‌سوخت و پتروشیمی",
  "shahin bushehr": "شهین بوشهر", "damash gilan": "داماش گیلان",
  "fajr sepasi": "فجر سپاسی شیراز", "rahem abadan": "رهیم آبادان",
  "baadma": "بادما", "khooshe talaei": "خوشه طلایی ساوه",
  "pars va mokhaberat": "پارس و مخابرات", "mokhaberat": "پارس و مخابرات",
  // ---- Saudi ----
  "al hilal": "الهلال", "al-nassr": "النصر", "al nassr": "النصر",
  "al ittihad": "الاتحاد", "al-ittihad": "الاتحاد", "al ahli": "الاهلی",
  "al-ahli": "الاهلی", "al shabab": "الشباب", "al-shabab": "الشباب",
  "al ettifaq": "الاتفاق", "al-etifaq": "الاتفاق", "al fateh": "الفتح",
  "al taawoun": "التعاون", "al khaleej": "الخلیج", "al riyadh": "الریاض",
  "al okhdood": "الاخدود", "al kholood": "الخلود", "damac": "دامک",
  "neom": "نیوم", "al qadsiah": "القادسیه",
  // ---- Turkey / Netherlands / Portugal / Greece ----
  "galatasaray": "گالاتاسارای", "fenerbahçe": "فنرباغچه", "fenerbahce": "فنرباغچه",
  "beşiktaş": "بشیک‌تاش", "besiktas": "بشیک‌تاش", "trabzonspor": "ترابزون‌اسپور",
  "ajax": "آژاکس", "psv": "پی‌اس‌وی", "feyenoord": "فاینورد", "az alkmaar": "آلکمار",
  "benfica": "بنفیکا", "porto": "پورتو", "sporting cp": "اسپورتینگ‌لیسبون",
  "sporting": "اسپورتینگ", "olympiacos": "المپیاکوس", "paok": "پاوک",
  "panathinaikos": "پاناتینایکوس", "aeK athens": "آک آتن",
  // ---- Other big clubs ----
  "celtic": "سلتیک", "rangers": "رنجرز", "club brugge": "کلوب بروژ",
  "anderlecht": "آندرلشت", "genk": "خنک", "red bull salzburg": "زالتسبورگ",
  "shakhtar donetsk": "شاختار دونتسک", "dinamo zagreb": "دیناموزاگرب",
  "young boys": "یانگ‌بویز", "basel": "بازل", "salzburg": "زالتسبورگ",
  "bruges": "بروژ", "qarabağ": "قره‌باغ", "qarabag": "قره‌باغ",
  // ---- cycle 45: teams spotted untranslated in live feeds (Serie A, 2.Bundesliga,
  // LaLiga 2, Eredivisie, Süper Lig, Scottish, MLS, Brasileirão, J1, K League, …)
  "venezia": "ونتزیا", "monza": "مونزا", "palermo": "پالرمو",
  "bayern münchen": "بایرن‌مونیخ", "schalke 04": "شالکه", "wolfsburg": "وولفسبورگ",
  "vfl wolfsburg": "وولفسبورگ", "hertha bsc": "هرتابرلین", "1. fc nürnberg": "نورنبرگ",
  "hannover 96": "هانوفر", "kaiserslautern": "کایزرسلاوترن", "holstein kiel": "هولشتاین‌کیل",
  "magdeburg": "ماگدبورگ", "dynamo dresden": "دینامو درسدن", "paderborn": "پادربورن",
  "deportivo alavés": "آلاوس", "deportivo alaves": "آلاوس", "real valladolid": "رئال‌والادولید",
  "leganés": "لگانس", "leganes": "لگانس", "granada": "گرانادا", "cádiz": "کادیز",
  "cadiz": "کادیز", "tenerife": "تنریفه", "albacete": "آلباسته", "sd huesca": "اوئسکا",
  "huesca": "اوئسکا", "sparta rotterdam": "اسپارتا روتردام", "fortuna sittard": "فورتونا سیتارد",
  "fc dordrecht": "دوردخت", "nac breda": "ناک‌بردا", "pec zwolle": "زفوله",
  "vvv-venlo": "فنلو", "vitesse": "ویتس", "sc heerenveen": "هیرنوین", "excelsior": "اکسلسیور",
  "aberdeen": "آبردین", "falkirk": "فالکیرک", "dundee united": "دندی‌یونایتد",
  "dundee fc": "دندی", "kilmarnock": "کیلمارنوک", "st. johnstone": "سنت‌جانستون",
  "motherwell": "مادرول", "st. mirren": "سنت‌میرن", "hibernian": "هیبرنین",
  "heart of midlothian": "هارتس", "inter miami cf": "اینترمیامی", "charlotte fc": "شارلوت",
  "atlanta united": "آتلانتا یونایتد", "toronto fc": "تورنتو", "dc united": "دی‌سی‌یونایتد",
  "fc cincinnati": "سینسیناتی", "new england revolution": "نیوانگلند",
  "new york city fc": "نیویورک‌سیتی", "red bull new york": "ردبول نیویورک",
  "corinthians": "کورینتیانس", "fluminense": "فلومیننزه", "internacional": "اینترناسیونال",
  "santos": "سانتوس", "palmeiras": "پالمیراس", "rb bragantino": "براگانتینو",
  "chapecoense": "شاپه‌کوئنزه", "gamba osaka": "گامبا اوساکا", "kashima antlers": "کاشیما",
  "cerezo osaka": "سرزو اوساکا", "kawasaki frontale": "کاوازاکی فرونتاله",
  "urawa red diamonds": "اوراوا", "yokohama f.marinos": "یوکوهاما مارینوس",
  "sanfrecce hiroshima": "هیروشیما", "nagoya grampus": "ناگویا", "sagan tosu": "ساگان توسو",
  "fc seoul": "اف‌سی سئول", "pohang steelers": "پوهانگ", "antalyaspor": "آنتالیااسپور",
  "eyüpspor": "عیوپ‌اسپور", "eyupspor": "عیوپ‌اسپور", "fatih karagümrük": "کاراگومروک",
  "kocaelispor": "کوکائلی‌اسپور", "göztepe": "گوزتپه", "aris thessaloniki": "آریس",
  "ofi crete": "اوفی کرت", "levadiakos": "لوادیاکوس", "paok thessaloniki": "پاوک",
  "rosenborg": "روزنبورگ", "molde": "مولده", "brann": "بران", "bodø/glimt": "بودو/گلیمت",
  "bodo/glimt": "بودو/گلیمت", "vålerenga": "والرنگا", "valerenga": "والرنگا",
  "viking": "وایکینگ", "lillestrøm": "لیلهستروم", "tromsø": "ترومسو",
  "fk haugesund": "هاوگسوند", "sarpsborg 08": "سارپسبورگ", "malmö ff": "مالمو",
  "malmo ff": "مالمو", "ifk göteborg": "یوتبوری", "ifk goteborg": "یوتبوری",
  "djurgården": "یورگوردن", "djurgarden": "یورگوردن", "häcken": "هاکن",
  "hammarby if": "هامربی", "crvena zvezda": "ستاره‌سرخ", "partizan beograd": "پارتیزان",
  "slovan bratislava": "اسلوان براتیسلاوا", "sparta prague": "اسپارتا پراگ",
  "viktoria plzeň": "پلزن", "viktoria plzen": "پلزن", "legia warszawa": "لگیا ورشو",
  "lech poznań": "لخ پوزنان", "jagiellonia białystok": "یگیلونیا", "cfr cluj": "کلوژ",
  "ferencváros": "فرنتس‌واروش", "ferencvaros": "فرنتس‌واروش",
  // Championship clubs seen in cup draws & women's brackets
  "sheffield united": "شفیلدیونایتد", "cardiff city": "کاردیف‌سیتی",
  "swansea city": "سوانزی", "norwich city": "نورویچ",
  "west bromwich albion": "وست‌بروم", "millwall": "میلوال", "middlesbrough": "میدلزبورو",
  "coventry city": "کاونتری", "hull city": "هال‌سیتی", "stoke city": "استوک",
  "portsmouth": "پورتسموث", "charlton": "چارلتون", "watford": "واتفورد",
  "derby county": "دربی‌کانتی", "bristol city": "بریستول‌سیتی",
  "blackburn rovers": "بلکبرن", "wrexham": "رکسام", "birmingham city": "بیرمنگام‌سیتی",
  "ipswich town": "ایپسوییچ", "southampton": "ساوتهمپتون", "burnley fc": "بارنلی",
  // Persian Gulf Pro League — FotMob spelling variant ("Gol Gohar")
  "gol gohar": "گل‌گهر",
  // Saudi / Qatar spelling variants seen in feed
  "al-taawoun": "التعاون", "damac fc": "دامک", "al-raed": "الراید",
  "junior fc": "جونیور", "once caldas": "اونس کالداس", "al-gharafa": "الغرافه",
};

export function competitionFa(name: string, ccode?: string): string {
  const n = (name || "").toLowerCase().trim();
  const cc = (ccode || "").toUpperCase().trim();
  // country-qualified entries first (disambiguates e.g. "Premier League" ENG vs TAN)
  if (cc) {
    const key = `${n}|${cc}`;
    if (COMPETITION_FA_CC[key]) return COMPETITION_FA_CC[key];
  }
  // ambiguous names must match their country, otherwise keep original
  if (AMBIGUOUS_NAMES.has(n)) return name;
  if (COMPETITION_FA[n]) return COMPETITION_FA[n];
  return name;
}

// names whose translation depends on the country
const AMBIGUOUS_NAMES = new Set([
  "premier league", "serie a", "super league", "pro league", "first division",
  "championship", "prva liga", "first league", "fa cup", "super lig", "league one", "league two",
]);

const COMPETITION_FA_CC: Record<string, string> = {
  "premier league|ENG": "پریمیرلیگ انگلیس",
  "serie a|ITA": "سری‌آ ایتالیا",
  "super league|GRE": "سوپرلیگ یونان",
  "pro league|BEL": "لیگ بلژیک",
  "pro league|SAU": "لیگ حرفه‌ای عربستان",
  "first division|CYP": "دسته اول قبرس",
  "fa cup|ENG": "جام حذفی انگلیس",
  "super lig|TUR": "سوپرلیگ ترکیه",
  "championship|ENG": "چمپیونشیپ انگلیس",
  "league one|ENG": "لیگ یک انگلیس",
  "league two|ENG": "لیگ دو انگلیس",
};

// youth / women / reserve suffixes — translate the base name and append a
// Persian qualifier so «Chelsea (W)», «Hoffenheim U19», «Werder Bremen II»
// stop leaking through as raw English (cycle 45).
// Every regex REQUIRES a leading space so names like «Millwall» (ends in ll)
// can never be split accidentally.
const TEAM_QUALIFIERS: { re: RegExp; fa: string }[] = [
  { re: /\s\((?:w|women)\)$/i, fa: " (زنان)" },
  { re: /\s(?:fc\s+)?women$/i, fa: " (زنان)" },
  { re: /\sladies$/i, fa: " (زنان)" },
  { re: /\su1[789]$/i, fa: " جوانان" },
  { re: /\su2[013]$/i, fa: " جوانان" },
  { re: /\s(?:ii|ll)$/i, fa: " دوم" },
  { re: /\s(?:b|2)$/i, fa: " دوم" },
];

export function teamFa(...candidates: (string | undefined)[]): string {
  for (const c of candidates) {
    if (!c) continue;
    const key = c.toLowerCase().trim();
    if (TEAM_FA[key]) return TEAM_FA[key];
    // cycle-86: national teams («Norway» → «نروژ») ride the country map —
    // probed via player recentMatches sides (club vs national team rows)
    if (COUNTRY_FA[key]) return COUNTRY_FA[key];
  }
  // qualifier fallback: known base + Persian qualifier (U19 / women / reserve)
  for (const c of candidates) {
    if (!c) continue;
    const key = c.toLowerCase().trim();
    for (const q of TEAM_QUALIFIERS) {
      const m = key.match(q.re);
      if (m && m.index !== undefined) {
        const base = key.slice(0, m.index).trim();
        if (TEAM_FA[base]) return `${TEAM_FA[base]}${q.fa}`;
      }
    }
  }
  // try first candidate as-is
  return candidates[0] || "";
}

// FotMob player country (English) → فارسی (cycle 45 — player page honesty)
const COUNTRY_FA: Record<string, string> = {
  "brazil": "برزیل", "argentina": "آرژانتین", "france": "فرانسه", "spain": "اسپانیا",
  "germany": "آلمان", "england": "انگلیس", "italy": "ایتالیا", "portugal": "پرتغال",
  "netherlands": "هلند", "belgium": "بلژیک", "croatia": "کرواسی", "serbia": "صربستان",
  "poland": "لهستان", "sweden": "سوئد", "norway": "نروژ", "denmark": "دانمارک",
  "finland": "فنلاند", "turkey": "ترکیه", "türkiye": "ترکیه", "greece": "یونان",
  "ukraine": "اوکراین", "russia": "روسیه", "japan": "ژاپن", "south korea": "کره جنوبی",
  "korea republic": "کره جنوبی", "iran": "ایران", "morocco": "مراکش", "egypt": "مصر",
  "nigeria": "نیجریه", "senegal": "سنگال", "ghana": "غنا", "ivory coast": "ساحل عاج",
  "côte d'ivoire": "ساحل عاج", "algeria": "الجزیره", "tunisia": "تونس", "cameroon": "کامرون",
  "mali": "مالی", "usa": "آمریکا", "united states": "آمریکا", "mexico": "مکزیک",
  "colombia": "کلمبیا", "uruguay": "اروگوئه", "ecuador": "اکوادور", "chile": "شیلی",
  "peru": "پرو", "paraguay": "پاراگوئه", "venezuela": "ونزوئلا", "australia": "استرالیا",
  "austria": "اتریش", "switzerland": "سوئیس", "scotland": "اسکاتلند", "wales": "ولز",
  "ireland": "ایرلند", "republic of ireland": "ایرلند", "czech republic": "چک",
  "czechia": "چک", "slovakia": "اسلواکی", "slovenia": "اسلوونی", "hungary": "مجارستان",
  "romania": "رومانی", "bulgaria": "بلغارستان", "israel": "اسرائیل", "saudi arabia": "عربستان",
  "qatar": "قطر", "united arab emirates": "امارات", "iraq": "عراق", "guinea": "گینه",
  "dr congo": "کنگو دموکراتیک", "gabon": "گابن", "bosnia and herzegovina": "بوسنی",
  "north macedonia": "مقدونیه شمالی", "albania": "آلبانی", "kosovo": "کوزوو",
  "georgia": "گرجستان", "cyprus": "قبرس", "jamaica": "جامائیکا", "canada": "کانادا",
  "montenegro": "مونته‌نگرو", "kazakhstan": "قزاقستان", "uzbekistan": "ازبکستان",
};

export function countryFa(name: string | undefined | null): string {
  if (!name) return "";
  return COUNTRY_FA[name.toLowerCase().trim()] || name;
}

// FotMob team logo (kept after countryFa — cycle 45 additions above)
export function fotmobTeamLogo(teamId: number | string): string {
  return `https://images.fotmob.com/image_resources/logo/teamlogo/${teamId}.png`;
}
