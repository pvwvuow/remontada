// ------------------------------------------------------------------
// Remontada — League configuration & Persian name mappings
// ------------------------------------------------------------------
import { faDigits } from "./format";

export interface LeagueConfig {
  key: string;          // internal key
  fotmobId: number;     // FotMob league id
  ccode3: string;       // FotMob country code
  faName: string;       // Persian display name
  enName: string;
  espnSlug?: string;    // ESPN fallback slug
  priority: number;     // lower = higher in list
  /** cycle-140: explicit false = excluded from the TWO global merges
   *  (getAllTopScorers race + getAllCardLeaders). Reason is contract, not
   *  taste: the cycle-132 race intersects allSeasons across participating
   *  feeds — UECL's 6-season feed (2021/2022+) would SHRINK the 12-season
   *  window to 6. The flag does NOT affect any per-league surface: standings,
   *  fixtures, bracket, titles, /topscorers/uecl (reads getStandings
   *  directly), players hub, search index all stay live. */
  globalMerge?: boolean;
  /** cycle-382: national-team tournaments serve PLAIN-YEAR season names
   *  ("2026", "2022" — the World Cup carries 23 of them). The flag lets
   *  seasonParamOk() (season.ts) accept the plain shape for THIS league
   *  only — API guards + client deep-link seeding pass it through; the
   *  slash contract stays the default for every other competition and
   *  every global surface. */
  plainYearSeasons?: boolean;
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
  // cycle-139: the cups footprint («براکت جام‌ها») gains its second live cup.
  // The matches feed exposed the real page id (parentLeagueId/primaryId = 73,
  // probe 2026-10-29 UA Chrome/124 — fotmob.com/leagues/73): full 2026/2027
  // league-phase table (36 teams), FIVE playoff rounds (playoff/1/8/1/4/1/2/
  // final), 17 historical seasons (2010/2011 → 2026/2027 — superset of the
  // global merge's 12-season window, so the intersection contract is
  // untouched; UECL's 6-season feed would have SHRUNK it and is deferred),
  // stats blocks with the same empty-topItems + fetchAllUrl shape as the
  // domestic leagues, and transfers.data = null (cups — the tab honestly
  // hides via the cycle-57 contract). Historical probe 2024/2025: 36 rows +
  // 5 rounds. All surfaces light through the existing generic plumbing:
  // standings league phase, fixtures, per-league scorers, global merge (8th
  // participant), bracket tab, /topscorers/uel, players hub, search index.
  { key: "uel",        fotmobId: 73,          ccode3: "INT",  faName: "لیگ اروپا",          enName: "Europa League",    espnSlug: "uefa.europa",    priority: 8 },
  // cycle-140: the cups footprint's third live cup. The UEL cycle-139 probe
  // already characterized it (fotmob.com/leagues/10216, UA Chrome/124,
  // 2026-10-29): full 2026/2027 league-phase table (36 teams — Hearts rides
  // the standings index now), FIVE playoff rounds, 6 historical seasons
  // (2021/2022+ — the exact reason for globalMerge: false above), domestic-
  // shaped stats blocks and transfers.data = null (cups). ESPN fallback slug
  // probed live: uefa.europa.conf → 200.
  { key: "uecl",       fotmobId: 10216,       ccode3: "INT",  faName: "کنفرانس لیگ اروپا",  enName: "Conference League", espnSlug: "uefa.europa.conf", priority: 9, globalMerge: false },
  // cycle-141: the cups footprint's fourth live cup — and the one the Persian
  // fan actually bleeds for: AFC Champions League Elite (fotmob.com/leagues/525,
  // probed live UA Chrome/124, 2026-10-29; the day-feed ids 943983/943984 are
  // the West/East day-tournaments and answer null as league pages — the real
  // page id surfaced via matchDetails content.matchFacts.infoBox.Tournament.
  // parentLeagueId = 525, the same crack UEL used in cycle-139). Feed shape:
  // COMPOSITE table (data.composite = true, data.tables[] = West 16 + East 16
  // sub-tables, data.table itself empty — the cycle-141 parser extension in
  // fotmob.ts flattens them), 128 season fixtures, stats dict exactly like
  // UCL's (players/teams with fetchAllUrl), transfers.data = null (cups) and
  // playoff = null until the knockout rounds are drawn (the honest hidden
  // bracket tab, cycle-56 contract). Seasons: only 4 modern slash-format
  // entries (2026/2027 → 2023/2024; older years are plain "2022"-style
  // strings the strict SEASON_PARAM_RE contract can never address) — joining
  // the cycle-132 race with a 4-season feed would SHRINK the 12-season
  // window, so globalMerge: false (the UECL cycle-140 flag, one meaning:
  // per-league surfaces live, the two global merges untouched). Historical
  // probe: season=2025/2026 serves the true 12-per-region table (Tractor in
  // the West top three). ESPN fallback slug probed live: afc.champions → 200.
  { key: "acl",        fotmobId: 525,         ccode3: "INT",  faName: "لیگ قهرمانان آسیا (الیت)", enName: "AFC Champions League Elite", espnSlug: "afc.champions", priority: 10, globalMerge: false },
  // cycle-145: Turkish Süper Lig — the ELEVENTH competition, and the first
  // NEW GLOBAL-RACE PARTICIPANT since cycle-132 (no globalMerge flag: the
  // live probe 2026-10-29 UA Chrome/124 showed allAvailableSeasons = 17
  // slash-format seasons 2026/2027 → 2010/2011, so the sliced-12 window
  // (2026/2027 → 2015/2016) is covered EXACTLY — the cycle-132 intersection
  // stays byte-identical while the race honestly grows to 9 participants).
  // Four blocks live-probed: flat 18-row table, Top scorer category with
  // data.fotmob.com fetchAllUrl (Gift Orban / Mohamed Salah / Victor Osimhen
  // all on 8), 70 title seasons (newest 2025/2026 Galatasaray over
  // Fenerbahçe), and transfers.data = 100 entries (DOMESTIC league — the
  // cups' honest transfers-hide contract does not apply). ESPN fallback slug
  // probed live: tur.1 → 200.
  { key: "superlig",   fotmobId: 71,          ccode3: "TUR",  faName: "سوپرلیگ ترکیه",      enName: "Süper Lig",        espnSlug: "tur.1",          priority: 11 },
  // cycle-146: Scottish Premiership — the TWELFTH competition and the SECOND
  // consecutive new global-race participant (no globalMerge flag: 17
  // slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132 window
  // exactly). Four blocks live-probed 2026-10-29: flat 12-row table (Celtic
  // top, Rangers 2nd — the Old Firm), Top scorer category with fetchAllUrl
  // (Camilo Durán, Celtic, 7; 93-goal full file), 129 title seasons (newest
  // 2025/2026 Celtic over Rangers), transfers.data = 100 entries (domestic).
  // ESPN fallback slug probed live: sco.1 → 200.
  { key: "scottish",   fotmobId: 64,          ccode3: "SCO",  faName: "لیگ برتر اسکاتلند",   enName: "Scottish Premiership", espnSlug: "sco.1",      priority: 12 },
  // cycle-147: Saudi Pro League — the THIRTEENTH competition and the THIRD
  // consecutive new global-race participant (no globalMerge flag: 17
  // slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132 window
  // exactly). Four blocks live-probed 2026-10-29: flat 18-row table
  // (الهلال top on 27, النصر 2nd — the Gulf Classic; القادسیه third),
  // Top scorer category with data.fotmob.com fetchAllUrl (Ivan Toney, Al
  // Ahli, 12; En-Nesyri/Retegui on 7 — the thin early-season full file),
  // 22 title seasons (newest 2025/2026 النصر over الهلال), and
  // transfers.data = 100 entries (DOMESTIC league — the cups' honest
  // transfers-hide contract does not apply). ESPN fallback slug probed
  // live: ksa.1 → 200. The Persian-fan pick over the Championship: the
  // Gulf neighbor league — الهلال already lives in the portal as an ACL
  // league-phase participant (the cycle-141 priority dedup keeps it
  // there, exactly like سلتیک on uel), while النصر/الاتحاد/الاهلی now
  // join the search index honestly.
  { key: "saudi",      fotmobId: 536,         ccode3: "KSA",  faName: "لیگ حرفه‌ای عربستان", enName: "Saudi Pro League", espnSlug: "ksa.1",          priority: 13 },
  // cycle-150: EFL Championship — the FOURTEENTH competition and the FOURTH
  // consecutive new global-race participant (no globalMerge flag: 17
  // slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132 window
  // exactly, byte-identical). Four blocks live-probed 2026-10-29 (UA
  // Chrome/124, /api/data/leagues?id=48&ccode3=ENG — the live path after
  // /api/leagues 404s): flat 24-row table (Middlesbrough top on 25, Swansea
  // 2nd, West Ham 3rd — the relegated giant; Derby/Preston propping up),
  // Top scorer category with a data.fotmob.com fetchAllUrl (Will Lankshear,
  // Middlesbrough, 11; Guðjohnsen 8, Larin 7 — a 208-scorer full file),
  // 123 title seasons (newest 2025/2026 Coventry City over Ipswich Town;
  // oldest 1892/1893 Birmingham City — the SECOND-oldest title history in
  // the portal after the Scottish Premiership's 129), and transfers.data =
  // 100 entries (DOMESTIC league — the cups' honest transfers-hide contract
  // does not apply). playoff = null → bracket tab honestly absent. ESPN
  // fallback slug probed live: eng.2 → 200. The Persian-fan pick that had
  // been passed over twice (cycles 145/147 in favour of the Gulf leagues):
  // the historic second tier where the relegated giants — وست‌هم/ساوتهمپتون/
  // ولورهمپتون — now ride, with کوونتری the reigning champion.
  { key: "championship", fotmobId: 48,       ccode3: "ENG",  faName: "چمپیونشیپ انگلیس",    enName: "EFL Championship", espnSlug: "eng.2",          priority: 14 },
  // cycle-151: Liga Portugal — the FIFTEENTH competition and the FIFTH
  // consecutive new global-race participant (no globalMerge flag: 17
  // slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132 window
  // exactly — same cadence as the Championship in cycle-150). Blocks
  // live-probed 2026-10-29 (UA Chrome/124, /api/data/leagues?id=61&ccode3=
  // POR): flat 18-row 2026/2027 table (پورتو top on 27, بنفیکا 2nd on 22,
  // اسپورتینگ‌لیسبون 3rd on 18; ریو آوه/استوریل propping up), Top scorer
  // category with a data.fotmob.com fetchAllUrl (پاولیدیس بنفیکا 9;
  // لوئیس سوارز 8 — a 124-scorer full goals.json file), 92 title seasons
  // (newest 2025/2026 پورتو over اسپورتینگ‌لیسبون, oldest 1934/1935
  // پورتو), and transfers.data = 100 entries (domestic). playoff = null →
  // bracket tab honestly absent. ESPN fallback slug probed live: por.1 →
  // 200. The Persian-fan pick: طارمی's league — the Iranian striker came
  // to Europe through ریو آوه and shone four seasons at پورتو (2020–2024),
  // making Liga Portugal a daily Persian follow. Feasibility sweep noted:
  // the Eredivisie guess (id 49) returned literal null and id 50 turned
  // out to be EURO — Portugal won on live data truth.
  { key: "portugal",   fotmobId: 61,          ccode3: "POR",  faName: "لیگ پرتغال",         enName: "Liga Portugal",    espnSlug: "por.1",          priority: 15 },
  // cycle-152: UAE Pro League — the SIXTEENTH competition and the SIXTH
  // consecutive new global-race participant (no globalMerge flag: 17
  // slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132 window
  // exactly — same cadence as superlig/scottish/saudi/championship/
  // portugal). Blocks live-probed 2026-10-29 (UA Chrome/124,
  // /api/data/leagues?id=538&ccode3=UAE): flat 14-row 2026/2027 table
  // (الجزیره top on 14, شباب الاهلی دبی 2nd on 13, الوصل 3rd on 13;
  // بنی‌یاس bottom on 1), Top scorer category with a data.fotmob.com
  // fetchAllUrl (ویلی سمدو 4 — an 85-scorer full goals.json file), 19
  // title seasons (newest 2025/2026 العین over شباب الاهلی دبی, oldest
  // 2005/2006), and transfers.data = 100 entries (domestic). playoff =
  // null → bracket tab honestly absent. NO espnSlug (the persiangulf
  // pattern): ESPN's full soccer index (220 leagues, 9 pages scanned
  // live) does not serve UAE Pro League fixtures — the optional field is
  // simply omitted so the fallback loop skips it gracefully. The
  // Persian-fan pick — the STRONGEST of the whole Gulf arc: SEVEN
  // Iranian internationals live in the scorer file right now (عزت‌اللهی
  // 3, طارمی 2, آزمون 2, نوراللهی 1, قایدی 1, قربانی 1, قدوس 1) —
  // daily-relevant to a Persian audience like no other candidate
  // (Qatar probed the same day: ZERO Iranians in its 76-scorer file).
  { key: "uae",        fotmobId: 538,         ccode3: "UAE",  faName: "لیگ برتر امارات",    enName: "UAE Pro League",                              priority: 16 },
  // cycle-155: Qatar Stars League — the SEVENTEENTH competition and the
  // SEVENTH consecutive new global-race participant (no globalMerge flag:
  // 17 slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132
  // window exactly — same cadence as superlig/scottish/saudi/championship/
  // portugal/uae). Blocks live-probed 2026-10-29 (UA Chrome/124,
  // /api/data/leagues?id=535&ccode3=QAT): flat 12-row 2026/2027 table
  // (الراین top on 17, السد 2nd on 15, الدحیل 3rd on 15), Top scorer
  // category with a data.fotmob.com fetchAllUrl (اکرم عفیف 7 — a
  // 76-scorer full goals.json file), 22 title seasons (newest 2025/2026
  // السد, oldest 2004/2005 الغرافه — runner rows include the defunct
  // الجیش), and transfers.data = 17 entries (domestic + regional).
  // playoff = null → bracket tab honestly absent. NO espnSlug (the
  // persiangulf/uae Gulf pattern): ESPN answers HTTP 400 for qat.1 and
  // qatar.1 — the optional field is simply omitted so the fallback loop
  // skips it gracefully. The Persian-fan pick — the Gulf-arc COMPLETION:
  // the portal now serves all four Persian-Gulf leagues (persiangulf +
  // saudi + uae + qatar), and the scorer file carries a LIVE Iranian:
  // فرهاد زوشی (Lusail SC, 3 goals, rank 9 — player.info.country = "Iran",
  // probed via /api/player/1828115 on 2026-10-29), the 152 probe's
  // runner-up finally paying off with a Persian hook of its own.
  { key: "qatar",      fotmobId: 535,         ccode3: "QAT",  faName: "لیگ ستارگان قطر",    enName: "Qatar Stars League",                          priority: 17 },
  // cycle-156: Eredivisie (league 57, ccode3 NED — primaryId recovered live
  // from the 2026-10-31 matches feed after the id=49 guess answered payload
  // null: evidence over memory, the D5 lesson). The Persian-fan pick of the
  // five cycle-155 runner-up candidates (Egyptian/Belgian/Greek/Swiss also
  // probed complete): the live 154-scorer goals.json + squads of all 18
  // clubs carry a LIVE Iranian — علیرضا جهانبخش (Excelsior, fotmob 466890,
  // squad ccode IRN + player.info.country = "Iran" verified through our own
  // /api/player/466890). Belgium's lone IRN-flagged hit («Dennis Eckert»,
  // a German-Spanish striker) is WRONG upstream ccode data — the D5
  // player-level verification killed it. Complete blocks: 18-row flat
  // 2026/2027 table (Feyenoord 24 / Ajax 21 / PSV 20), 17 slash-format
  // seasons, Top scorer category with fetchAllUrl (Willumsson 8 FC
  // Groningen), 127 title seasons (newest 2025/2026 PSV over Feyenoord,
  // oldest 1897/1898 R.U.N. — pre-war defunct names ride the honest
  // English fallback by design), transfers.data = 100, playoff = null in
  // the CURRENT window (knockout not drawn) while 2025/2026 serves a real
  // 2-round European-playoff bracket — the season-aware bracket API
  // already honors it. espnSlug ned.1 verified live (200), unlike the Gulf
  // leagues — the matches ESPN fallback covers it too.
  { key: "eredivisie", fotmobId: 57,          ccode3: "NED",  faName: "اردیویزهٔ هلند",     enName: "Eredivisie",        espnSlug: "ned.1",          priority: 18 },
  // cycle-157: AFC Champions League Two — the NINETEENTH competition, the
  // FIFTH live cup (ucl/uel/uecl/acl/acl2) and the «براکت جام‌ها» footprint's
  // Persian-club crown jewel. Probed live 2026-10-29/30 (UA Chrome/124,
  // /api/data/matchDetails?matchId=6054514 → parentLeagueId = 9469 — the
  // day-feed group id 9469 IS the page id here, unlike ACL Elite's
  // 943983/943984 day-split; five candidate European leagues were probed the
  // same window (Danish 46 / Greek 135 / Swiss 69 / Belgian 40 / Egyptian
  // 519 — all five-block complete but ZERO Iranian players in any squad
  // sweep) and lost to the ultimate Persian hook: گل‌گهر سیرجان (fotmob
  // 389880) rides Group B (with الجزیره/آرخاداغ/المحررق) and 32 of 33 squad
  // members carry cname "Iran" — player-level verified through our own
  // /api/player/196041 (مهدی رحمتی → country=Iran). Feed shape: COMPOSITE
  // group tables (data.composite = true, data.tables[] = Group A–H, 4 rows
  // each, 32 clubs; data.table itself empty — the cycle-141 parser
  // extension flattens them, COMPOSITE_REGION_FA now carries گروه A–H
  // labels), allAvailableSeasons = 13 entries but only FOUR slash-format
  // (2026/2027 → 2023/2024) — joining the cycle-132 race with a 4-season
  // feed would SHRINK the 12-season window, so globalMerge: false (the
  // uecl/acl flag: per-league surfaces live, both global merges untouched —
  // race stays 320 scorers / 16 participants in every window). Top scorer
  // category with a data.fotmob.com fetchAllUrl (91-row file, leader
  // مالکوم الجزیره 4 — the SAME Al-Jazira teamId 102101 the uae league
  // serves), 21 title seasons (top-level seasons[], newest 2025/2026
  // گامبا اوساکا over النصر; oldest 2004 — defunct champions ride the
  // honest English fallback by design, cycle-96/104 convention),
  // transfers.data = null (cups — the tab honestly hides via the cycle-57
  // contract) and playoff = null until the knockout rounds are drawn (the
  // honest hidden bracket tab, cycle-56 contract). NO espnSlug (ESPN
  // answers HTTP 400 for afc.champions.two / afc.champions.league.two —
  // the Gulf pattern). Day-feed group names ride eight exact-match keys
  // («AFC Champions League Two - A» … «- H»).
  { key: "acl2",       fotmobId: 9469,        ccode3: "INT",  faName: "لیگ قهرمانان آسیا ۲", enName: "AFC Champions League Two",                    priority: 19, globalMerge: false },
  // cycle-160: Swiss Super League — the TWENTIETH competition and the
  // EIGHTH consecutive new global-race participant (no globalMerge flag:
  // 17 slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132
  // window exactly — same cadence as superlig/scottish/saudi/championship/
  // portugal/uae/qatar/eredivisie). Blocks live-probed 2026-10-30 (UA
  // Chrome/124, /api/data/leagues?id=69&ccode3=SUI): flat 12-row 2026/2027
  // table (Lugano top on 31, Young Boys 2nd on 25, Sion 3rd on 22), Top
  // scorer category with a data.fotmob.com fetchAllUrl (Samuel Essende 12
  // — a 116-scorer full goals.json file in the PascalCase FMStatFullRow
  // shape the cycle-23 parser reads natively), 32 title seasons (newest
  // 2025/2026 Thun over St. Gallen, oldest 1994/1995 Grasshopper over
  // Lugano — the Xamax runner rows ride the existing گزانماکس map),
  // transfers.data = 100 entries (flat list — DOMESTIC league, the cups'
  // honest transfers-hide contract does not apply), playoff = null in the
  // CURRENT window → bracket tab honestly absent (cycle-56 contract;
  // archived seasons verified playoff:null too). espnSlug sui.1 verified
  // live (200) — the eredivisie pattern, NOT the Gulf one. ARCHIVED
  // seasons serve COMPOSITE tables (2025/2026: Championship Group 6 +
  // Relegation Group 6 + the 12-row overall — the cycle-141 flattening
  // handles them natively; «دور قهرمانی»/«دور سقوط» joined
  // COMPOSITE_REGION_FA). The Persian-fan pick of the six-block sweep
  // (Belgian 40 / Greek 135 / Danish 46 / Egyptian 519 / Austrian 38 all
  // four-block complete but ZERO Iranian players in any full squad sweep;
  // Norwegian 59 can't join the race — plain-year seasons): the live
  // Iranian hook — مصطفی حیدری, the 19-year-old Iranian centre-back at
  // سنت‌گالن (squad ccode IRN + cname "Iran" + nationalTeamId 6711,
  // rating 6.26 over live 2026/2027 appearances; his individual FotMob
  // profile 404s — a youth member without a player page yet, so the D5
  // player-level check rides three agreeing club-side fields with NO
  // contradicting profile — the exact evidence class the Dennis-Eckert
  // false positive lacked).
  { key: "swiss",      fotmobId: 69,          ccode3: "SUI",  faName: "سوپرلیگ سوئیس",      enName: "Swiss Super League", espnSlug: "sui.1",          priority: 20 },
  // cycle-161: Croatian HNL — the TWENTY-FIRST competition and the NINTH
  // consecutive new global-race participant (no globalMerge flag: 17
  // slash-format seasons 2026/2027 → 2010/2011 cover the cycle-132 window
  // exactly — same cadence as superlig/scottish/saudi/championship/
  // portugal/uae/qatar/eredivisie/swiss). Blocks live-probed 2026-10-30
  // (UA Chrome/124, /api/data/leagues?id=252&ccode3=CRO — the id surfaced
  // from the day feed, the acl2/UEL crack): flat 10-row 2026/2027 table
  // (هایدوک اسپلیت 23 / دیناموزاگرب 22 / واراژدین 18 — the Eternal Derby),
  // Top scorer category with a data.fotmob.com fetchAllUrl (72-row
  // PascalCase FMStatFullRow goals.json — the cycle-23 parser's native
  // shape; leader دیون درنا بلیو 12 دیناموزاگرب), 35 title seasons (newest
  // 2025/2026 دیناموزاگرب over هایدوک اسپلیت; رییکا the 2024/2025
  // champion; oldest 1992 هایدوک over the defunct ان‌کی زاگرب),
  // transfers.data = flat list → 100 entries (DOMESTIC league), playoff =
  // null in the CURRENT window → bracket tab honestly absent (cycle-56
  // contract). NO espnSlug (ESPN answers HTTP 400 for cro.1 and
  // croatia.1 — the Gulf pattern). ARCHIVED seasons serve FLAT 10-row
  // tables with the top-scorer block PRESENT (probed 2025/2026 AND
  // 2023/2024) → the 2023/2024 historical race honestly grows 16→17
  // participants. The Persian-fan pick of the day-feed id sweep (the
  // cycle-160 runner-ups Belgian/Greek/Danish/Egyptian/Austrian stay
  // zero-Iranian probed): the live Iranian hook — محمد محبی, the Iran
  // international winger wearing the Rijeka №9 (squad ccode IRN + cname
  // «Iran» + nationalTeamId 6711 + born 1998-12-20 + 187cm ST/LW with a
  // ~1.5M transferValue and live 2026/2027 stats; his individual FotMob
  // profile 404s — the documented no-page evidence class, three agreeing
  // club-side fields with NO contradicting profile, the cycle-160
  // Heydari standard). The Ex-Yugoslav footprint completes its Persian
  // sports-media relevance: هایدوک/دینامو the Eternal Derby rides the
  // portal daily. Day-feed bare «HNL» (ccode CRO) rides a plain
  // COMPETITION_FA key (unique upstream name — no AMBIGUOUS_NAMES entry
  // needed).
  { key: "hnl",        fotmobId: 252,         ccode3: "CRO",  faName: "لیگ برتر کرواسی",    enName: "Croatian HNL",                                  priority: 21 },
  // cycle-162: Malaysia Super League — the 22nd competition, the FIRST
  // merge-exempt DOMESTIC league. The live Iranian hook rides the TOP of the
  // table AND the scoring race: شهاب زاهدی (squad ccode IRN + playerData
  // countryCode IRN + nationalTeamId 6711 — the 160/161 evidence triple) is
  // Johor Darul Ta'zim's striker, 3rd in the 2026/2027 scorer file (7 goals).
  // globalMerge:false is the CYCLE-160 NORWEGIAN LESSON applied (D5-evidenced
  // probe 2026-10-30): only the three newest seasons are slash-format
  // (2026/2027, 2025/2026, 2024/2025); the 14-season plain-year archive
  // (2023…2010) would shrink the race's cycle-132 allSeasons intersection
  // from 17 slash seasons to 3 — the same regression that kept Norwegian 59
  // out entirely. Merge-exempt keeps the race at 360/18 untouched while the
  // league still serves its full page, dedicated /topscorers/mas path,
  // fixtures (132 allMatches), transfers (flat 3-item list) and archives.
  // NO espnSlug (ESPN 400 — the Gulf pattern); playoff = null → bracket tab
  // honestly absent (cycle-56 contract); seasons[] top-level EMPTY → titles
  // API honestly null → «قهرمانان» tab honestly absent (cycle-121 contract).
  // Day-feed bare «Liga Super» (ccode MAS) is a UNIQUE upstream name — plain
  // COMPETITION_FA key, no AMBIGUOUS_NAMES entry (the hnl pattern).
  { key: "mas",        fotmobId: 8985,        ccode3: "MAS",  faName: "سوپرلیگ مالزی",      enName: "Malaysia Super League",                         priority: 22, globalMerge: false },
  // cycle-165: Ekstraklasa — 23rd competition, 19th race participant. TWO live
  // Iranian hooks in ONE club (لخ پوزنان 2182): صیادمنش (887680, active since
  // 2026-07-01, rank 7 of the race window with 5 goals, cc=IRN probed in the
  // goals.json StatList) + غلی‌زاده (746018, at the club since 2023). Live-probed
  // 2026-10-30 (UA Chrome/124, page id 196 — the day-feed id 937879 is a
  // day-group id; primaryId=196 resolved from the feed, the 156 lesson):
  // flat 18-row 2026/2027 table (لخ پوزنان 28 / گورنیک زابژه 27 / پوگون شچچین 24),
  // 17 slash-format seasons 2026/2027→2010/2011 (allAvailableSeasons) covering
  // the cycle-132 window exactly, no globalMerge flag → merges into the race
  // (360→380 scorers / 18→19 perLeague); the ARCHIVED 2023/2024 payload carries
  // its own Goals fetchAllUrl (season/20954) → historical race 17→18 participants.
  // 99 title seasons (newest 2025/2026 لخ پوزنان over گورنیک زابژه, oldest
  // 1912/1913 — pre-war champions ride the honest English fallback by design,
  // cycle-96/104 convention). transfers.data=100 (91 distinct clubs).
  // playoff=null → bracket tab honestly absent (cycle-56 contract). NO espnSlug
  // (ESPN 400 for pol.1/poland.1 — Gulf pattern). Table is a NORMAL flat
  // payload (data.table.all — no composite parser needed).
  { key: "poland",     fotmobId: 196,         ccode3: "POL",  faName: "اکستراکلاسا لهستان", enName: "Ekstraklasa",                                   priority: 23 },
  // cycle-181: Belgian Pro League — 24th competition, 20th race participant.
  // ONE live Iranian hook (standard لیژ 9985): دنیس اکرت (Dennis Eckert,
  // 892709) — squad ccode=IRN / nationalTeamId=6711 AND the goals.json row
  // itself carries ParticipantCountryCode="IRN" (rank 11, 4 goals + 1 assist,
  // rating 6.91, #10 Standard Liège). Live-probed 2026-10-30 (UA Chrome/124,
  // page id 40 — the day-feed primaryId IS the page id): flat 18-row
  // 2026/2027 table (خنت 25 / کلوب بروژ 24 / یونیون سنت‌ژیلوآز 23), 17
  // slash-format seasons 2026/2027→2010/2011 covering the cycle-132 window
  // exactly → no globalMerge flag → merges into the race (380→400 scorers /
  // 19→20 perLeague); the ARCHIVED 2023/2024 payload carries its own Goals
  // fetchAllUrl (season/20957, 233 rows) → historical race 18→19 participants
  // (historical tables are COMPOSITE — Championship/ECL/Relegation groups,
  // the cycle-141 parser). 123 title seasons — the OLDEST of any portal
  // (1895/1896 اف‌سی لیژ over رویال آنتورپ; newest 2025/2026 کلوب بروژ over
  // یونیون سن‌ژیلواز). transfers.data=100 (105 distinct sides). Card files
  // live (yellow_card.json / red_card.json with fetchAllUrl — the 176
  // contract). playoff=null → bracket tab honestly absent (cycle-56
  // contract). espnSlug bel.1 answers live (ESPN «Belgian Pro League» — the
  // big-league pattern, not the Gulf one). Day feed serves «Belgian Pro
  // League» ccode=BEL (unique name — the 140/152 pattern); the second-tier
  // «First Division B» has live matches the same day and joins
  // COMPETITION_FA. Table is a NORMAL flat payload (data.table.all).
  { key: "belgium",    fotmobId: 40,          ccode3: "BEL",  faName: "لیگ بلژیک",          enName: "Belgian Pro League", espnSlug: "bel.1",          priority: 24 },
  // cycle-361: Egyptian Premier League — 25th competition, 21st race
  // participant. Found via web-search resolution of the FotMob id (519 —
  // the site search/sitemap/suggest paths carry no ids). Live-probed
  // 2026-11-01 (UA Chrome/124): flat 20-row 2026/2027 table (Pyramids FC
  // 24 / Al Ahly SC / Zamalek SC), 17 slash-format seasons
  // 2026/2027→2010/2011 (allAvailableSeasons) — the race window is 12
  // (2026/2027→2015/2016 probed on /api/topscorers) so merging does NOT
  // shrink the common window; stats.players = 39 keys → real scorers for
  // /topscorers/egypt AND the race (the Iraq 524 counter-case: stats
  // empty + hasTotw=false → recorded as a future candidate, thinner
  // surfaces); transfers.data=100; hasTotw=true → the cycle-360 «تیم
  // هفته» section lights up; historical 2019/2020 probed (18-row table,
  // Al Ahly top, stats.players present); playoff=null → bracket tab
  // honestly absent (cycle-56 contract). NO espnSlug (ESPN 400 for
  // egy.1/egypt.1 — Gulf pattern). Upstream details.name is the generic
  // "Premier League" — the catalog enName stays the canonical
  // "Egyptian Premier League" so the site never collides with pl.
  { key: "egypt",      fotmobId: 519,         ccode3: "EGY",  faName: "لیگ برتر مصر",       enName: "Egyptian Premier League",                       priority: 25 },
  // cycle-362: Iraq Stars League — 26th competition, pre-registered in the
  // cycle-361 card as the next coverage candidate (the counter-case of its
  // own probe: thin stat surfaces). Live-probed 2026-11-01 (UA Chrome/124):
  // flat 20-row 2026/2027 table (Al-Karma 27 pts top / Karbalaa 7 bottom,
  // every row carries a real team id), fixtures.allMatches = 380 (full
  // season — richer than Egypt's 190), transfers.data = 18, 17
  // slash-format seasons 2026/2027→2010/2011 (allAvailableSeasons) — the
  // engine caps allSeasons at 12 (2026/2027→2015/2016, identical to the
  // race window) so joining the merge does NOT shrink the common window;
  // the empty-scorers guard keeps perLeague at 21 (honest absence, the
  // cycle-132 feed-contract comment). stats.players ABSENT → /topscorers/
  // iraq renders the honest empty state and the race gains no Iraq row;
  // hasTotw=false → the cycle-360 «تیم هفته» section stays hidden;
  // historical depth is spotty upstream — 2024/2025 serves a full 20-row
  // table (Al Shorta 87 champion) while 2025/2026, 2023/2024 and older
  // return table=null → getStandings' optional chain (cycle-326 fmTable
  // guard) yields rows=[] honest-empty pages, no throw. playoff=null →
  // bracket tab honestly absent (cycle-56 contract). NO espnSlug (ESPN
  // 400 for iraq.1/irq.1 — Gulf pattern). Upstream details.name is the
  // generic "Stars League" — the catalog enName stays the canonical
  // "Iraq Stars League" (no collision with any sibling).
  { key: "iraq",       fotmobId: 524,         ccode3: "IRQ",  faName: "لیگ ستارگان عراق",   enName: "Iraq Stars League",                             priority: 26 },
  // cycle-376: Copa del Rey — the TWENTY-SEVENTH competition, the cups
  // footprint's FIFTH live cup and the FIRST pure knockout domestic
  // competition (no league-phase table at all). Live probe 2026-11-02 (UA
  // Chrome/124): the real page id surfaced via the day feed (fotmob.com/
  // leagues/138, ccode=ESP — matches served 2026-11-01..03), answering a
  // full 2026/2027 cup feed: table[0].data.table WITHOUT the `all` key
  // (a knockout cup's honest shape), 17 slash-format allAvailableSeasons
  // (2026/2027 → 2010/2011 — the cycle-132 window covered exactly), 122
  // title-history seasons (newest: 2025/2026 Real Sociedad over Atlético
  // Madrid), 39 player stat categories EVERY one with fetchAllUrl (Top
  // scorer → Goals conceded per 90), 56 season fixtures, playoff=null
  // (bracket tab honestly hidden until rounds are drawn — the cycle-56
  // contract) and transfers.data=null (the cups' honest transfers-hide).
  // leagueColor #D2202B (OG card), ESPN slug probed live: esp.copa_del_rey
  // → 200. The no-table shape is why getStandings grows the cycle-376
  // no-table path (see fotmob.ts): the cup's scorers/boards/seasons ride
  // the same standings payload and were unreachable while it threw.
  // globalMerge: false — one flag, one semantic (per-league surfaces live,
  // the two global merges untouched): the race's perLeague/season-intersect
  // contract assumes table feeds, and the cup enters it only after the
  // no-table path has proven itself across cycles (the UECL 140 precedent
  // of admission by evidence, not taste). faName follows the ALREADY-SHIPPED
  // home/player-filter mapping «جام حذفی اسپانیا» (COMPETITION_FA, shipped
  // pre-376) so the day feed and the league page never disagree.
  { key: "copadelrey", fotmobId: 138,         ccode3: "ESP",  faName: "جام حذفی اسپانیا",   enName: "Copa del Rey",     espnSlug: "esp.copa_del_rey", priority: 27, globalMerge: false },
  // cycle-377: DFB Pokal — the TWENTY-EIGHTH competition, the cups
  // footprint's SIXTH live cup and the SECOND pure knockout domestic cup to
  // ride the cycle-376 no-table standings path (first proof of the path's
  // genericity: zero lib/UI changes needed beyond the catalog entry). Live
  // probe 2026-11-02 (UA Chrome/124): the day-tournament id 936417 (GER,
  // 8+8 matches across 2026-10-27/28) answers NULL as a league page — the
  // real page id surfaced via the cycle-141 crack (matchDetails
  // content.matchFacts.infoBox.Tournament.parentLeagueId = 209, link
  // /leagues/209/overview/dfb-pokal). Feed shape: table[0].data itself
  // ABSENT (even thinner than Copa del Rey's keyless dict — every read is
  // the optional chain), 17 slash-format allAvailableSeasons (2026/2027 →
  // 2010/2011 — the cycle-132 window covered exactly), 83 title-history
  // seasons (newest: 2025/2026 Bayern München), 40 player stat categories
  // EVERY one with fetchAllUrl, 56 season fixtures, transfers.data=null
  // (the cups' honest hide) — and playoff SERVED: rounds[{stage:"1/8",
  // matchups[]}] in the exact cycle-56 parser shape → the bracket tab
  // RENDERS (the portal's second live cup bracket after UCL; Copa del
  // Rey's is honestly hidden until its draw). overview.selectedSeason
  // = 2026/2027 (the 141 echo-less honesty marker). leagueColor #004941
  // (OG card); ESPN slug probed live: ger.dfb_pokal → 200. faName rides
  // the ALREADY-shipped mapping «جام حذفی آلمان» (COMPETITION_FA "dfb
  // pokal", shipped pre-377) so the day feed and the league page never
  // disagree. globalMerge: false — the cycle-376 one-flag semantic
  // unchanged: per-league surfaces live, the two global merges untouched
  // (admission stays gated on the no-table path proving itself).
  { key: "dfbpokal",   fotmobId: 209,         ccode3: "GER",  faName: "جام حذفی آلمان",     enName: "DFB Pokal",        espnSlug: "ger.dfb_pokal",    priority: 28, globalMerge: false },
  // cycle-380: Coppa Italia — the 29th competition, the THIRD pure knockout
  // domestic cup riding the cycle-376 no-table path (second proof of its
  // genericity: zero UI changes, one catalog entry) and the portal's THIRD
  // live cup bracket. Feasibility first (live probes, UA Chrome/124): the
  // day feeds (2026-12-02/03) surfaced the day-tournament id 938423 (ITA,
  // Como–Cremonese / Juventus–Sassuolo) which answers NULL as a league page
  // — the real page id surfaced via the cycle-141 crack (matchDetails
  // content.matchFacts.infoBox.Tournament.parentLeagueId = 141). Feed
  // shape: table[0].data itself ABSENT (the dfbpokal-thinner shape — every
  // read is the optional chain), 17 slash-format allAvailableSeasons
  // (2026/2027 → 2010/2011 — the cycle-132 window covered exactly), 78
  // title-history seasons (newest: 2025/2026 Inter over Lazio), 37 player
  // stat categories EVERY one with fetchAllUrl (74-row goals list, top:
  // Pohjanpalo 3), 45 season fixtures (28 finished / 17 upcoming, first
  // unplayed Inter–Genoa), transfers.data=null (the cups' honest hide) —
  // and playoff SERVED: 6 rounds (1/32 → final) in the exact cycle-56
  // parser shape → the bracket tab RENDERS, with the 1/2 + final rounds
  // carrying spelled-out TBD slots «Winner QF/SF n» at BOTH matchup and leg
  // level (mapped honestly by the cycle-380 teamFa guard below; the 1/4
  // rounds use the cycle-144 slash shape). overview.selectedSeason =
  // 2026/2027 (the 141 echo-less honesty marker). leagueColor #2EA736;
  // ESPN slug probed live: ita.coppa_italia → 200. faName rides the
  // ALREADY-shipped mapping «جام حذفی ایتالیا» (COMPETITION_FA "coppa
  // italia", both spellings, pre-380) so the day feed and the league page
  // never disagree. globalMerge: false — the cycle-376 one-flag semantic
  // unchanged: per-league surfaces live, the two global merges untouched
  // (admission stays gated on the no-table path proving itself).
  { key: "coppaitalia", fotmobId: 141,        ccode3: "ITA",  faName: "جام حذفی ایتالیا",   enName: "Coppa Italia",     espnSlug: "ita.coppa_italia", priority: 29, globalMerge: false },
  // cycle-381: FA Cup — the 30th competition, the FOURTH pure knockout
  // domestic cup on the no-table path (third proof of genericity) and the
  // portal's FOURTH live cup bracket. Feasibility first (live probes, UA
  // Chrome/124): the R1 weekend day feeds (2026-11-06..09, 33+4+1+2
  // matches) surfaced day-tournament id 953430 (ENG) which answers NULL as
  // a league page — the real page id via the cycle-141 crack
  // (matchDetails parentLeagueId = 132). Feed shape: table[0].data ABSENT
  // (the 377/380 thinner shape), 17 slash allAvailableSeasons (2026/2027 →
  // 2010/2011 — the cycle-132 window covered exactly), 145 title-history
  // seasons (newest: 2025/2026 Man City over Chelsea; 2024/2025 Crystal
  // Palace's famous upset second), stats.players EMPTY (the honest 0 —
  // the «آقای گل» tab falls to its empty state), 40 season fixtures,
  // transfers.data=null (the cups' honest hide) — and playoff SERVED with
  // the numeric round shape stage:"1" (64 matchups, 40 named with legs —
  // R1 proper: Oxford City–Leicester City) → the numeric stages now map
  // honestly in BRACKET_STAGE_FA («دور اول» …; previously a raw ASCII
  // "1" would have leaked into the bracket header — the 378 K1 class).
  // leagueColor #02264C; ESPN slug probed live: eng.fa → 200 (the
  // eng.fa_cup variant 400s). faName rides the ALREADY-shipped mapping
  // «جام حذفی انگلیس» (COMPETITION_FA "fa cup" + the day-feed "fa cup|ENG"
  // line, pre-381). globalMerge: false — the 376 one-flag semantic
  // unchanged.
  { key: "facup",      fotmobId: 132,         ccode3: "ENG",  faName: "جام حذفی انگلیس",    enName: "FA Cup",           espnSlug: "eng.fa",           priority: 30, globalMerge: false },
  // cycle-382: FIFA World Cup — the 31st competition, the FIRST
  // national-team tournament on the portal and the closing of a class gap:
  // every prior entry is a club competition. Feasibility first (live
  // probes, UA Chrome/124): the 2026 final day feed (2026-07-19, Spain
  // 1–0 Argentina) surfaced day-tournament id 894789 which answers NULL
  // as a league page — the real page id via the cycle-141 crack
  // (matchDetails parentLeagueId = 77). Feed shape: the CLASSIC table
  // payload with composite:true + 13 sub-tables (12 groups 'Grp. A'..'Grp.
  // L' ×4 rows + 'Best 3rd placed teams' ×12 — Iran 3 draws, 3-3, out as
  // the 10th third-placed side), playoff SERVED in the cycle-144 slash
  // shape (1/16:16, 1/8:8, 1/4:4, 1/2:2, final:1 matchups + a bronzeFinal
  // DICT — France 4-6 England 2026 / Croatia 2-1 Morocco 2022 — parsed as
  // an honest «رده‌بندی» round), 104 finished fixtures (72 group with
  // numeric roundName + 32 knockout with NAMED roundName 'Round of
  // 32'..'Final' — the existing roundFa would have rendered «هفته ۳۲» and
  // raw Latin 'Final' → extended with the named-round map), stats
  // .categories=0 (the honest scorers empty, facup precedent),
  // transfers.data=null (the cups' honest hide), titleHistory ABSENT (the
  // seasons tab renders; the «قهرمانان» tab honestly absent, cycle-121
  // contract). THE headline gap: allAvailableSeasons are PLAIN YEARS
  // ('2026','2022',… 23 of them) — the strict SEASON_PARAM_RE filtered
  // every one out, so a plain-year season contract rides this entry:
  // plainYearSeasons:true + seasonParamOk() (season.ts) accept '2026'
  // ONLY where the flag proves it; slash seasons stay the portal default
  // and the global race/players surfaces stay strict. leagueColor
  // #06062D; ESPN slug probed live: fifa.world → 200 with the completed
  // final. faName rides the ALREADY-shipped mapping «جام جهانی»
  // (COMPETITION_FA "world cup", pre-382). The 48 national sides resolve
  // through teamFa → COUNTRY_FA (40 pre-existing) + 8 new keys. The
  // historical 2022 feed probed live: 8 groups, 64 matches, final
  // Argentina 3-3 France (winner Argentina) — the deep-link proof target.
  // globalMerge: false — the 376 one-flag semantic; a plain-year feed
  // must never enter the slash-season allSeasons intersection anyway.
  { key: "worldcup",   fotmobId: 77,          ccode3: "INT",  faName: "جام جهانی",          enName: "FIFA World Cup",   espnSlug: "fifa.world",       priority: 31, globalMerge: false, plainYearSeasons: true },
  // cycle-385: AFC Asian Cup — the SECOND national-team competition and the
  // most Iran-relevant one (Team Melli: 3 titles 1968/1972/1976 + the 2023
  // semi-final). Probed live (UA Chrome/124, 2026-11-02): the 2024 final's
  // day-tournament id 890103 answered NULL as a league page (the cycle-141
  // gap); the real catalog id 290 came from matchDetails
  // content.matchFacts.infoBox.Tournament.parentLeagueId via the
  // /api/data/matchDetails?matchId= variant (the /api/data/match/{id} path
  // 404s for this old fixture — new probe-artifact subclass). Shape:
  // composite tables (6 groups + «Best 3rd placed teams» — the 382 class),
  // the 144-slash playoff bracket (1/8→final, no bronze for 2023), 51
  // fixtures with numeric + named roundNames, 18 title seasons (1956 Hong
  // Kong → 2023 Qatar), plain-year allAvailableSeasons 2027→2011 (the 382
  // flag), transfers.data=null + empty topPlayers (honest cup hiding),
  // details.leagueColor absent (the dot hides, honest). ESPN slug probed
  // live: afc.asian.cup → 200 (the _-variant 400s). globalMerge: false —
  // the 376 one-flag semantic (the plain-year feed never enters the
  // slash-season allSeasons intersection).
  { key: "asiancup",   fotmobId: 290,         ccode3: "INT",  faName: "جام ملت‌های آسیا",   enName: "AFC Asian Cup",    espnSlug: "afc.asian.cup",    priority: 32, globalMerge: false, plainYearSeasons: true },
  // cycle-417: Hazfi Cup — the 33rd competition, the IRANIAN domestic cup
  // and the closing of a class gap for the cup footprint: every prior entry
  // covers either Europe or the continental/national NT tournaments, while
  // the knockout cup the Persian fan follows domestically rode no catalog
  // row (the persiangulf league page's cup sibling). Feasibility first
  // (scripts/cycle417-probe.sh, live UA Chrome/124, 2026-11-02): the web
  // search surfaced the page id and /api/data/leagues?id=9487&ccode3=IRN
  // answered 200 with the PURE-KNOCKOUT cup shape — details.name
  // «Hazfi Cup», country IRN, leagueColor #212121, tabs
  // [overview, playoff, fixtures, seasons], table NULL (the cycle-376
  // noTable contract renders the honest cup empty state + fixtures CTA),
  // playoff SERVED in the established slash shape (1/16: 32 participants /
  // 16 matchups + 1/8: 16/8 — the 2025/2026 round of 32 and round of 16
  // both played, 24 finished fixtures Nov 2025 → Jan 2026, roundNames
  // «Round of 32»/«Round of 16» riding the cycle-382 named-round map),
  // stats {} (the honest scorers empty — the worldcup precedent),
  // transfers.data=null (the cups' honest hide), 12 slash-format
  // allAvailableSeasons (2025/2026 → 2014/2015 — SEASON_PARAM_RE accepts
  // them byte-identical, no plainYearSeasons flag) and 14 title-history
  // editions in the top-level seasons[] list (Esteghlal 2024/2025,
  // Sepahan 2023/2024, Persepolis 2022/2023, Nassaji 2021/2022, Foolad
  // 2020/2021 — the cycle-121 «قهرمانان» contract lights up). ESPN slug
  // probed BOTH candidates 400 (iran.hazfi_cup / iran.hazfi) → the field
  // is OMITTED like persiangulf's (the fallback loop skips undefined,
  // fotmob.ts:1522). TEAM_FA census: 32 distinct names across
  // fixtures/playoff/seasons — 25 already ride the existing
  // persiangulf/azadegan blocks; the 7 second-tier cup entrants join the
  // TEAM_FA map (the «---- Hazfi Cup ----» block below). The day-feed
  // group-header name «Hazfi Cup» is globally unambiguous (no AMBIGUOUS_
  // NAMES entry needed) and rides COMPETITION_FA like coppa italia.
  { key: "hazfi",      fotmobId: 9487,        ccode3: "IRN",  faName: "جام حذفی ایران",     enName: "Hazfi Cup",                                      priority: 33, globalMerge: false },
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
  // cycle-161: the day feed serves bare «HNL» for Croatia (probed
  // 2026-10-31/11-02 ccode=CRO) — unique upstream name, no
  // AMBIGUOUS_NAMES entry needed
  "hnl": "لیگ برتر کرواسی",
  // cycle-162: the day feed serves bare «Liga Super» for Malaysia
  // (probed 2026-10-30/31 ccode=MAS) — unique upstream name (Uzbekistan
  // rides «Superliga», Romania «Superliga», Serbia «Super Liga»), no
  // AMBIGUOUS_NAMES entry needed
  "liga super": "سوپرلیگ مالزی",
  // cycle-165: the day feed serves bare «Ekstraklasa» for Poland
  // (probed 2026-10-30/11-01 ccode=POL, primaryId 196) — unique upstream
  // name (Slovakia rides «Super liga»), no AMBIGUOUS_NAMES entry needed
  // (the hnl/mas pattern)
  "ekstraklasa": "اکستراکلاسا لهستان",
  // cycle-181: the day feed serves «Belgian Pro League» for Belgium
  // (probed 2026-10-30 ccode=BEL, primaryId 40) — unique upstream name,
  // no AMBIGUOUS_NAMES entry needed. The Persian REUSES the established
  // «pro league|BEL» translation from COMPETITION_FA_CC so the same
  // competition keeps ONE name across day-feed cards and the portal
  // (the faName consistency rule — mas/liga super convention).
  "belgian pro league": "لیگ بلژیک",
  // cycle-181: the second tier has live matches the same day
  // («First Division B» ccode=BEL — Challenger Pro League upstream)
  "first division b": "دستهٔ اول بی بلژیک",
  "premier league": "پریمیرلیگ انگلیس",
  "laliga": "لالیگا",
  "la liga": "لالیگا",
  "serie a": "سری‌آ",
  "bundesliga": "بوندسلیگا",
  "ligue 1": "لیگ ۱ فرانسه",
  "persian gulf": "لیگ خلیج فارس",
  "persian gulf pro league": "لیگ خلیج فارس",
  "süper lig": "سوپرلیگ ترکیه",
  // «Premiership» is ambiguous in the daily feed (SCO vs NIR) — country-keyed
  // entries disambiguate; the plain name joins AMBIGUOUS_NAMES (cycle-146)
  "efl cup": "جام اتحادیه انگلیس",
  "carabao cup": "جام اتحادیه انگلیس",
  // cycle-389: the two upstream spellings of the CONMEBOL WC qualifiers —
  // the «CONMEBOL» token makes both GLOBALLY unambiguous (no CC guard need);
  // the tid-10199 spelling also joins the ARCHIVE_TID_FA map in fotmob.ts.
  "conmebol world cup qualifiers": "مقدماتی جام جهانی — کونمبول",
  "world cup conmebol qualification": "مقدماتی جام جهانی — کونمبول",
  // cycle-390: the bare global «asian cup» — the team-fixtures rows carry NO
  // ccode, so the 385 CC-qualified keys never reach them (probed: Iran's 2027
  // Asian Cup row served the raw literal); «Asian» self-identifies the one
  // football competition the name can mean, and the 387 group family then
  // composes «— گروه C» from the suffix.
  "asian cup": "جام ملت‌های آسیا",
  "fa cup": "جام حذفی انگلیس",
  "copa del rey": "جام حذفی اسپانیا",
  "copa italia": "جام حذفی ایتالیا",
  "coppa italia": "جام حذفی ایتالیا",
  "dfb pokal": "جام حذفی آلمان",
  // cycle-417: Hazfi Cup joins the catalog (league 9487) — the day-feed
  // group header name is globally unambiguous (one Hazfi Cup exists), so a
  // bare COMPETITION_FA key rides the coppa-italia pattern; no AMBIGUOUS_NAMES
  // entry needed.
  "hazfi cup": "جام حذفی ایران",
  "supercopa": "سوپرکاپ اسپانیا",
  "community shield": "سوپرکاپ انگلیس",
  "club friendlies": "بازی دوستانه باشگاهی",
  "friendlies": "بازی دوستانه",
  "saudi pro league": "لیگ حرفه‌ای عربستان",
  "pro league": "لیگ حرفه‌ای عربستان",
  // cycle-141: AFC CL Elite day-feed tournament names (West/East are the
  // day-level ids 943983/943984 the /matches grid renders before dedup)
  "afc champions league elite": "لیگ قهرمانان آسیا (الیت)",
  "afc champions league elite west": "لیگ قهرمانان آسیا (الیت) — غرب",
  "afc champions league elite east": "لیگ قهرمانان آسیا (الیت) — شرق",
  "afc champions league two": "لیگ قهرمانان آسیا ۲",
  // cycle-157: ACL Two day-feed group splits — the /matches grid renders one
  // day-tournament per group with a " - X" suffix (probed: «AFC Champions
  // League Two - D» @ 2026-11-03, UA Chrome/124); eight exact-match keys keep
  // the grid Persian like the Elite West/East pair above
  "afc champions league two - a": "لیگ قهرمانان آسیا ۲ — گروه A",
  "afc champions league two - b": "لیگ قهرمانان آسیا ۲ — گروه B",
  "afc champions league two - c": "لیگ قهرمانان آسیا ۲ — گروه C",
  "afc champions league two - d": "لیگ قهرمانان آسیا ۲ — گروه D",
  "afc champions league two - e": "لیگ قهرمانان آسیا ۲ — گروه E",
  "afc champions league two - f": "لیگ قهرمانان آسیا ۲ — گروه F",
  "afc champions league two - g": "لیگ قهرمانان آسیا ۲ — گروه G",
  "afc champions league two - h": "لیگ قهرمانان آسیا ۲ — گروه H",
  "eredivisie": "اردیویزهٔ هلند",
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

  // ui-cycle-4 (BL-4): leagues seen verbatim in the live home feed (probed
  // 2026-10-31 04:34, 390x844) leaking through as Latin section titles —
  // the hnl/mas pattern: unique upstream names, exact-match entries, no
  // AMBIGUOUS_NAMES involvement
  "dfb pokal frauen": "جام حذفی بانوان آلمان",
  "copa libertadores femenina": "کوپا لیبرتادورس بانوان",
  "liga portugal 2": "لیگ ۲ پرتغال",
  "liga mx femenil apertura": "لیگ بانوان مکزیک — آپرتورا",
  "liga mx femenil clausura": "لیگ بانوان مکزیک — کلاسورا",
  "primera nacional": "پریمرا ناسیونال آرژانتین",
  // ui-cycle-4: MLS Next Pro playoff phases carry " - X" suffixes like the
  // AFC Two groups (cycle-157); the observed Finals phase gets an exact key
  // and competitionFa() has a startsWith fallback so future phases
  // (e.g. «MLS Next Pro - Eastern Conference - Semifinals») stay Persian
  "mls next pro - conference - finals": "لیگ نکست پرو آمریکا — فینال کنفرانس",
  // cycle-355: the player archive competition-filter («فیلتر مسابقات»,
  // matchFilters.leagues) surfaces these exact upstream names on players
  // whose recent rows leave the site's own LEAGUES catalog. Probed live
  // 2026-11-01 (UA Chrome/124, Raphinha id 696679) — only the names NOT
  // already mapped above join here (champions league / copa del rey /
  // club friendlies / friendlies existed: the 381/426/432/433 entries);
  // the generic "Super Cup" (Portuguese super cup upstream spelling) and
  // "FA Cup" (AMBIGUOUS_NAMES guard) stay on the honest Latin fallback.
  "world cup": "جام جهانی",
  "world cup qualification conmebol": "انتخابی جام جهانی (آمریکای جنوبی)",
  "supercopa de españa": "سوپرکاپ اسپانیا",
  "copa america": "کوپا آمریکا",
  // "FA Cup" deliberately NOT added: it sits in AMBIGUOUS_NAMES (the guard
  // above returns the raw name before any map lookup), so a map entry would
  // be dead code — the honest Latin fallback stays.
  "coupe de france": "جام حذفی فرانسه",
  "taça de portugal": "جام حذفی پرتغال",
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
  "eibar": "ایبار",  // cycle-247: the frozen 2020/21 corner file's rank-3 — the family's first uncovered frozen-row name
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
  // ---- Coppa Italia (cycle-380) ----
  // the 378 F2-class guard: every name the live bracket + fixtures serve
  // must find a mapping. Probed unique-name set across all 6 playoff rounds
  // + 45 fixtures; the Serie A core rides the section above, these are the
  // missing cup entrants (Serie B/C) + the two spelled-out matchup aliases
  // ("AC Milan", "SSC Napoli") the bracket uses at tie level.
  "ac milan": "آث‌میلان", "ssc napoli": "ناپولی",
  "arezzo": "آرتزو", "ascoli": "اسکولی", "benevento": "بنونتو", "catania": "کاتانیا",
  "catanzaro": "کاتانزارو", "cesena": "چزنا", "empoli": "امپولی",
  "juve stabia": "یووه استابیا", "lr vicenza": "ویتشنزا", "mantova": "مانتوا",
  "padova": "پادوا", "potenza": "پوتنتزا", "ravenna": "راونا",
  "südtirol": "زودتیرول", "union brescia": "یونیون برشا", "virtus entella": "ویرتوس انتلا",
  // ---- FA Cup (cycle-381) ----
  // the 378 F2-class guard on the R1 probed unique-name set (117 names
  // across the bracket's 64 matchups + 40 fixtures): 67 missing keys, all
  // added — lower-league + non-league England; aliases the payload serves
  // in both bare and spelled-out forms share one Persian name.
  "afc fylde": "اف‌سی فایلد", "afc rushden & diamonds": "راشدن اند دایموندز",
  "afc wimbledon": "ای‌اف‌سی ویمبلدون", "wimbledon": "ویمبلدون",
  "aldershot town": "آلدرشات", "altrincham": "آلترینچام", "alvechurch": "آلواچرچ",
  "barnet": "بارنت", "barrow": "بارو", "berkhamsted": "برکهامستد",
  "boreham wood": "بورهام وود", "bromley": "بروملی",
  "carlisle": "کارلایل", "carlisle united": "کارلایل",
  "cheltenham": "چلتنهام", "cheltenham town": "چلتنهام",
  "colchester": "کولچستر", "colchester united": "کولچستر",
  "crawley": "کرولی", "crawley town": "کرولی", "cray wanderers": "کری ونجررز",
  "crewe": "کرو", "crewe alexandra": "کرو", "dover": "دوور", "eastleigh": "ایستلی",
  "fc halifax town": "هالیفاکس",
  "forest green": "فارست گرین", "forest green rovers": "فارست گرین",
  "guiseley": "گایزلی", "harborough town fc": "هاربرو تاون", "harrogate town": "هروگیت",
  "hornchurch": "هورن‌چرچ", "huddersfield": "هادرزفیلد",
  "kidderminster harriers": "کیدرمینستر",
  "macclesfield": "مکلزفیلد", "macclesfield fc": "مکلزفیلد",
  "mansfield": "منسفیلد", "mansfield town": "منسفیلد", "marine": "مارین",
  "northampton": "نورث‌همپتون", "oldham": "اولدهام", "oxford city": "آکسفوردسیتی",
  "plymouth": "پلیموث", "plymouth argyle": "پلیموث", "plymouth parkway": "پلیموث پارک‌وی",
  "port vale": "پورت ویل", "rochdale": "روچدیل", "rotherham united": "راترهام",
  "salisbury": "سالزبری", "scunthorpe": "اسکانتورپ", "sheff wed": "شفیلد ونزدی",
  "sholing": "شولینگ", "shrewsbury": "شروزبری", "stafford rangers": "استافورد رنجرز",
  "sutton united": "ساتون", "swindon": "سوییندون",
  "tranmere": "ترنمر", "tranmere rovers": "ترنمر", "walsall": "والسال",
  "wealdstone": "ولدستون", "wigan": "ویگان", "wimborne town": "ویمبورن",
  "worcester": "ووستر", "wycombe": "وایکام",
  "yeovil": "یوویل", "yeovil town": "یوویل", "york city": "یورکسیتی",
  // ---- Bundesliga ----
  "augsburg": "آگزبورگ", "bayern munich": "بایرن‌مونیخ", "bayern": "بایرن‌مونیخ",
  "union berlin": "یونیون‌برلین", "werder bremen": "وردربرمن", "sv werder bremen": "وردربرمن", "borussia dortmund": "بروسیادورتموند",
  "dortmund": "دورتموند", "eintracht frankfurt": "اینتراخت‌فرانکفورت", "frankfurt": "فرانکفورت",
  "freiburg": "فرایبورگ", "hamburger sv": "هامبورگ", "hamburg": "هامبورگ",
  "heidenheim": "هایدنهایم", "hoffenheim": "هوفنهایم", "fc cologne": "کلن",
  // cycle-379 (bug-hunt 378 finding F2): the dfbpokal R16 tie at BOTH matchup
  // and leg level leaked Latin «Darmstadt» — the display name upstream is the
  // bare «Darmstadt» (short SVD), so the key is the bare spelling.
  "darmstadt": "دارمشتات", "sv darmstadt 98": "دارمشتات",
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
  // cycle-147: Saudi Pro League (league 536) — the 8 table-team spellings the
  // 2026/2027 feed serves that the block above missed (hyphen/short variants
  // are byte-exact from the live rows) + 23 more transfer-side names from the
  // 100-entry feed sweep. Zero shape change — additive keys only.
  "al-ettifaq": "الاتفاق", "al diriyah": "الدرعیه", "al hazem": "الهزمة",
  "al-faisaly": "الفیصلی", "al-fayha": "الفیحا", "al fateh fc": "الفتح",
  "neom sc": "نیوم", "abha": "ابها", "al akhdoud": "الأخدود",
  "al najma": "النجمة", "al taee": "الطایی", "al anwar": "الأنوار",
  "al jabalain": "الجبلین", "al-jeel": "الجیل",
  // cycle-449: the byte-drift fix — the cycle-140 capture spelled this club
  // with a HYPHEN («al-jeel») but the live day feed serves «Al Jeel» with a
  // SPACE (byte-verified on 3 live ±7 rows: 20261027 / 20261102 / 20261108,
  // Saudi First Division KSA; the c449 fold-probe shows the ONLY such drift
  // in the whole 1865-name raw pool). teamFa's exact-key lookup
  // (toLowerCase().trim() — leagues.ts:2902) never matched, so every row
  // leaked raw to Persian readers. The live-literal key rides the file's own
  // defensive-variant convention (180 same-value key groups already: «barça
  // atlètic»+«barca atletic», «nürnberg»+«nurnberg», «alavés»+«alaves»);
  // the render stays the file's own «الجیل» — same club, same league, same
  // country (the 389 identity-first rule); the hyphenated key STAYS for any
  // hyphen-spelled surface (the block itself already mixes both styles:
  // «al diriyah» spaced vs «al-faisaly» hyphenated).
  "al jeel": "الجیل",
  "al-wehda": "الوحده", "al-jazira": "الجزیره", "al ain": "العین",
  "al-duhail sc": "الدحیل", "al-rayyan": "الریان", "almería": "آلمریا",
  "américa-mg": "آمریکا مینه‌ایرو", "ceramica cleopatra": "سرامیکا کلئوپاترا",
  "cruzeiro": "کروزیرو", "gimnasia mendoza": "جیمنازیا مندوزا",
  "jerash fc": "جرش", "kalamata": "کالاماتا", "orlando pirates": "اورلاندو پایرتس",
  "pyramids fc": "پیرامیدز", "sk beveren": "بورن", "sporting charleroi": "شارلروا",
  "wydad casablanca": "وداد کازابلانکا",
  // cycle-141: AFC Champions League Elite (league 525) — exact upstream row
  // names of the live composite West/East tables not already mapped above
  // (al hilal / al ahli / al ittihad / al qadsiah / al nassr ride the Saudi
  // block; gamba osaka / kashima antlers / pohang steelers / al-gharafa ride
  // existing entries). Probed row spellings 2026-10-29, UA Chrome/124.
  "al-ain": "العین",
  "shabab al-ahli dubai fc": "شباب الاهلی دبی",
  "al-shamal": "الشمال", "al nassr fc": "النصر",
  "neftchi fargona": "نفتچی فرغانه", "al quwa al jawiya": "القوه الجویه",
  "pakhtakor tashkent": "پخاکتور تاشکند", "al-sadd": "السد",
  "al-wasl": "الوصل", "vissel kobe": "ویسل کوبه",
  "johor darul ta'zim": "جوهور دارالتعظیم", "beijing guoan": "بیجینگ گوآن",
  "kyoto sanga fc": "کیوتو سانگا", "kashiwa reysol": "کاشیوا ریسول",
  "shanghai port": "شانگهای پورت", "daejeon hana citizen": "دئژئون هانا",
  "jeonbuk hyundai motors fc": "جونبوک هیوندای", "công an hà nội": "کونگ آن هانوی",
  "buriram united": "بوریرام یونایتد", "ratchaburi fc": "راتچابوری",
  "port fc": "پورت اف‌سی", "newcastle jets": "نیوکاسل جتس",
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
  // cycle-139: the 9 UEL league-phase teams that had no map entry yet (the
  // other 27 already resolve) — without these they leak through as raw
  // English in the standings/bracket/search (probe: live UEL table rows)
  "union st.gilloise": "یونیون سنت‌ژیلوآز", "omonia nicosia": "اومونیا نیکوزیا",
  "levski sofia": "لووسکی صوفیه", "sturm graz": "اشتورم گراتس",
  "nec nijmegen": "نایمخن", "torreense": "توررنسه",
  "nk celje": "سلیه", "hapoel beer sheva": "هاپوئل بئرشبا",
  "ararat armenia": "آرارات ایروان",
  // cycle-140: the 26 UECL league-phase teams that had no map entry yet (the
  // other 10 already resolve) — without these they leak through as raw
  // English in the standings/bracket/search (probe: live UECL table rows)
  "lugano": "لوگانو", "fc twente": "تونته", "st.truiden": "سنت‌ترویدن",
  "hajduk split": "هایدوک اسپلیت", "fc københavn": "کپنهاگ",
  "universitatea craiova": "دانشگاه کرایووا", "mjällby": "میالبی",
  "borac banja luka": "بوراتس بنیالوکا", "braga": "براگا", "gent": "خنت",
  "nordsjælland": "نورشلاند", "egnatia": "اگناتیا", "riga fc": "ریگا",
  "fk crvena zvezda": "ستاره سرخ بلگراد", "cska sofia": "سسکا صوفیه",
  "jablonec": "یابلونتس", "fc midtjylland": "میدتیلند", "agf": "آرهوس",
  "pafos fc": "پافوس", "iberia 1999": "ایبریا ۱۹۹۹",
  "kairat almaty": "قیرات آلماتی", "thun": "تون",
  "lincoln red imps fc": "لینکلن رد ایمپس", "kups": "کوپس",
  "inter club d'escaldes": "اینتر اسکالدس", "fk kauno žalgiris": "کاونو ژالگیریس",

  // cycle-144 drift sweep (live probe 2026-10-29): 2026/2027 upstream spellings
  // with no mapping — promoted sides (Málaga, Racing Santander, Köln,
  // Elversberg, Troyes), UCL league-phase spellings (hyphenated PSG, PSV
  // Eindhoven, LASK, Sabah FK, AEK Athens, Slavia Prague, FC Porto) and
  // topscorer-feed full forms (Bayer 04 Leverkusen, Sport-Club Freiburg,
  // Union Saint-Gilloise…). Zero shape change — additive keys only.
  "paris saint-germain": "پاری سن‌ژرمن",
  "psv eindhoven": "پی‌اس‌وی آیندهوون",
  "fc porto": "پورتو",
  "slavia prague": "اسلاویا پراگ",
  "aek athens": "آئک آتن",
  "lask": "لاسک",
  "sabah fk": "صباح باکو",
  "málaga": "مالاگا",
  "racing santander": "ریسینگ سانتاندر",
  "mainz 05": "ماینتس ۰۵",
  "1. fsv mainz 05": "ماینتس ۰۵",
  "1. fc köln": "کلن",
  "elversberg": "الورسبرگ",
  "sv 07 elversberg": "الورسبرگ",
  "troyes": "تروا",
  "bayer 04 leverkusen": "بایر لورکوزن",
  "fc augsburg": "آگسبورگ",
  "sport-club freiburg": "فرایبورگ",
  "sporting lisbon": "اسپورتینگ‌لیسبون",
  "n.e.c.": "نایمخن",
  "union saint-gilloise": "یونیون سن‌ژیلواز",
  "rsc anderlecht": "آندرلشت",
  "celta de vigo": "سلتاویگو",

  // cycle-145 Süper Lig onboarding (live probe 2026-10-29): the 2026/2027
  // table + stats/goals-file spellings. Already mapped before this cycle:
  // Galatasaray, Trabzonspor, Beşiktaş, Fenerbahçe, Kocaelispor, Göztepe,
  // Eyüpspor.
  "amed sportif": "آمد اسپورتیف",
  "amedspor": "آمد اسپورتیف",
  "kasımpaşa": "قاسم‌پاشا",
  "kasimpasa": "قاسم‌پاشا",
  "erzurumspor fk": "ارزروم‌اسپور",
  "bb erzurumspor": "ارزروم‌اسپور",
  "çorum fk": "چوروم",
  "corum fk": "چوروم",
  "goztepe": "گوزتپه",
  "alanyaspor": "آلانیا اسپور",
  "başakşehir": "باشاک‌شهیر",
  "basaksehir": "باشاک‌شهیر",
  "rizespor": "ریزسپور",
  "caykur rizespor": "ریزسپور",
  "konyaspor": "قونیا اسپور",
  "gaziantep fk": "غازی عینتاب",
  "gazisehir gaziantep": "غازی عینتاب",
  "gençlerbirliği": "گنچلربیرلیگی",
  "genclerbirligi": "گنچلربیرلیگی",
  "samsunspor": "سامسون‌اسپور",

  // cycle-145 transfers sweep: the LIVE Süper Lig transfer feed (100 items)
  // serves 43 distinct unmapped club names — Turkish lower-division sides
  // (relegated Kayserispor/Sivasspor, İstanbulspor, Karşıyaka…) plus the
  // loan/foreign parties (Rodina, Zenit, Servette…). «free agent» is the
  // GENERIC no-club side (fotmob id 2) — 35 occurrences across all 11
  // leagues; mapping it once fixes every league's transfers tab. Foreign
  // third-party clubs in OTHER leagues' feeds keep churning daily — the
  // honest fallback convention applies there (documented, not mapped).
  "free agent": "آزاد",
  "istanbulspor": "استانبول‌اسپور",
  "van spor kulübü": "ون‌اسپور",
  "bodrum fk": "بدروم",
  "kayserispor": "قیصریه‌اسپور",
  "adanaspor": "آدانا اسپور",
  "kırklarelispor": "کرکلارلی‌اسپور",
  "rodina": "رودینا",
  "sebatspor": "سبات‌اسپور",
  "karşıyaka": "کارشی‌یاکا",
  "pendikspor": "پندیک‌اسپور",
  "balıkesirspor": "بالیکسیر اسپور",
  "sivasspor": "سیواس‌اسپور",
  "sarıyer": "ساری‌یر",
  "yalovaspor": "یالواسپور",
  "malatyaspor": "ملاتیاسپور",
  "ağrı 1970 spor": "آغری ۱۹۷۰",
  "zonguldak kömürspor": "زونگولداغ کوموراسپور",
  "şanlıurfaspor": "شانلی‌اورفاسپور",
  "iğdır fk": "ایغدیر",
  "sakaryaspor": "ساکاریاسپور",
  "kütahyaspor": "کوتاهیاسپور",
  "esenler erokspor": "اسنلر اروک‌اسپور",
  "inegölspor": "اینگول‌اسپور",
  "muğlaspor": "موغلاسپور",
  "cercle brugge": "سرکل بروژ",
  "vitória de guimarães": "ویتوریا گیماریش",
  "zenit st. petersburg": "زنیت",
  "modena": "مودنا",
  "estrela da amadora": "استرلا آمادورا",
  "rudeš": "رودش",
  "la galaxy": "لس آنجلس گلکسی",
  "györi eto": "دیور ای‌تی‌او",
  "rapid wien": "راپید وین",
  "laçi": "لاچی",
  "slovan liberec": "اسلووان لیبرتس",
  "chaves": "شاویش",
  "fc utrecht": "اوترخت",
  "servette": "سروت",
  "sampdoria": "سمپدوریا",
  "al zawraa": "الزوراء",
  "lausanne": "لوزان",
  "gais": "گایس",

  // cycle-146 Scottish Premiership onboarding: the 2026/2027 table spellings
  // were ALREADY mapped from earlier cycles (Celtic, Rangers, Heart of
  // Midlothian, Dundee FC, Dundee United, Falkirk, St. Mirren, St.
  // Johnstone, Aberdeen, Motherwell, Hibernian, Kilmarnock) — only the
  // short-form variants from the goals file / feeds needed adding.
  "hearts": "هارتس",
  "dundee": "دندی",
  "st mirren": "سنت‌میرن",

  // cycle-146 transfers sweep: the LIVE Scottish transfer feed (100 items)
  // serves 43 distinct unmapped club names — Scottish lower-division sides
  // (Arbroath, Dumbarton, Raith Rovers, Ross County, Livingston — relegated
  // out of the 12-team table, Dunfermline…) plus loan parties (Leicester
  // City and Leyton Orient were NEVER mapped by any earlier cycle — the
  // portal's pre-2026/2027 maps only covered current-squad teams; Maccabi
  // Tel Aviv, Grasshopper, Željezničar…). Bounded, honest, currently-served.
  "aalesund": "اوله‌سوند",
  "alloa athletic": "آلوآ اتلتیک",
  "arbroath": "آربروت",
  "austin fc": "آستین",
  "ayr united": "آیر یونایتد",
  "botoșani": "بوتوشانی",
  "bradford city": "برادفورد سیتی",
  "bristol rovers": "بریستول راورز",
  "charleston battery": "چارلستون بتتری",
  "dumbarton": "دامبارتون",
  "dunfermline athletic": "دانفرملین اتلتیک",
  "fk neftchi": "نفتچی باکو",
  "fortuna düsseldorf": "فورتونا دوسلدورف",
  "gillingham": "گیلیگام",
  "glentoran": "گلنتوران",
  "grasshopper": "گراس‌هاپر",
  "górnik zabrze": "گورنیک زابژه",
  "hermannstadt": "هرمانشتات",
  "ilves": "ایلوس",
  "kolding if": "کولدینگ",
  "leicester city": "لسترسیتی",
  "leyton orient": "لیتون اورینت",
  "livingston": "لیوینگستون",
  "macarthur fc": "مک‌آرتور",
  "maccabi tel aviv": "مکابی تل‌آویو",
  "nk varazdin": "واراژدین",
  "nk varaždin": "واراژدین",
  "portland timbers": "پورتلند تیمبرز",
  "preston north end": "پرستون نورث اند",
  "raith rovers": "ریث راورز",
  "rhode island fc": "رود آیلند",
  "ross county": "راس کانتی",
  "sharjah cultural club": "الشارجه",
  "stenhousemuir": "استن‌هاوس‌مور",
  "stockport county": "استوکپورت کانتی",
  "swindon town": "سویندون تاون",
  "tondela": "توندلا",
  "víkingur": "ویکینگور",
  "wehen wiesbaden": "وهن ویس‌بادن",
  "wycombe wanderers": "وایکام ونجرز",
  "xamax": "گزانماکس",
  "yverdon": "ایوردون",
  "željezničar": "ژلجوزنیچار",
  "žilina": "ژیلیانا",
  // cycle-150: EFL Championship (league 48) — the 4 table-team spellings the
  // blocks above missed + the transfer-feed sweep (100 entries, 126 distinct
  // club names) + the 123-season title-history sweep (winner AND runner-up
  // sides — both go through teamFa). Byte-exact from the live feed; additive
  // keys only, zero shape change.
  "accrington": "اکرینگتون", "accrington stanley": "اکرینگتون استنلی",
  "américa": "آمریکا", "cf américa": "آمریکا",
  "barnsley": "بارنزلی", "birmingham": "بیرمنگام", "blackburn": "بلکبرن",
  "blackpool": "بلکپول", "bolton": "بولتون", "bolton wanderers": "بولتون واندررز",
  "botev plovdiv": "بوتف پلوودیو", "bradford": "برادفورد",
  "bradford pa": "برادفورد پارک اونیو", "burton": "برتون",
  "burton albion": "برتون آلبیون", "bury": "بوری",
  "cambridge": "کمبریج", "cambridge united": "کمبریج یونایتد",
  "cardiff": "کاردیف", "charlton athletic": "چارلتون اتلتیک", // "charlton" already lives in the PL block (line 381) — kept, no dup
  "chesterfield": "چسترفیلد", "clermont foot": "کلرمون فوت",
  "colorado": "کلرادو", "colorado rapids": "کلرادو رپیدز", "colwyn bay": "کولوین بی",
  "coventry": "کوونتری", // "coventry city" already lives in the PL block («کاونتری», line 380) — kept, no dup
  "derby": "دربی", "doncaster": "دانکاستر", "doncaster rovers": "دانکاستر روورز",
  "exeter": "اکستر", "exeter city": "اکستر سیتی",
  "fleetwood": "فلیتوود", "fleetwood town": "فلیتوود تاون",
  "glossop north end": "گلوسوپ نورث اند",
  "grimsby": "گریمزبی", "grimsby town": "گریمزبی تاون",
  "houston": "هیوستون", "houston dynamo fc": "هیوستون داینامو",
  "huddersfield town": "هادرزفیلد تاون", "hull": "هال", "ipswich": "ایپسویچ",
  "leicester": "لستر", "lincoln": "لینکلن", "lincoln city": "لینکلن سیتی",
  "luton town": "لوتون تاون", "milton keynes dons": "میلتون کینز داونز",
  "mk dons": "ام‌کی داونز", "montpellier": "مونپلیه",
  "newport": "نیوپورت", "newport county": "نیوپورت کانتی",
  "northampton town": "نورث‌همپتون تاون", "norwich": "نوریچ",
  "nottm forest": "ناتینگهام فارست", "notts county": "ناتس کانتی",
  "oldham athletic": "اولدهام اتلتیک", "oxford united": "آکسفورد یونایتد",
  "oxford utd": "آکسفورد یونایتد", "peterborough": "پیتربورو",
  "peterborough united": "پیتربورو یونایتد", "preston": "پرستون",
  "qpr": "کویینز پارک رنجرز", "queens park rangers": "کویینز پارک رنجرز",
  "raków częstochowa": "راکوف چنستوخووا", "reading": "ردینگ",
  "salford": "سالفورد", "salford city": "سالفورد سیتی",
  "san diego fc": "سن دیگو", "sheff utd": "شفیلد یونایتد",
  "sheffield wednesday": "شفیلد ونزدی", "southend": "ساوتند",
  "southend united": "ساوتند یونایتد", "st. louis city": "سنت لوئیس سیتی",
  "stevenage": "استیونج", "stoke": "استوک", "swansea": "سوانزی",
  "sydney fc": "سیدنی", "são paulo": "سائوپائولو", "tokyo verdy": "وردی توکیو",
  "west brom": "وست برومویچ آلبیون", "wigan athletic": "ویگان اتلتیک",
  // cycle-151: Liga Portugal (league 61) — the 18-row table sweep (spellings
  // the blocks above missed) + the 100-entry transfer-feed sweep (110 distinct
  // club names after dedup) + the 92-season title-history sweep (winner AND
  // runner-up sides — both go through teamFa) + the alternate spellings the
  // 41 stat files serve (CD Nacional / Estoril Praia / Estrela / Sporting
  // Braga). "FC Porto B" rides the qualifier fallback («پورتو دوم»); "sporting
  // lisbon" already lived in an earlier block (اسپورتینگ‌لیسبون). Byte-exact
  // from the live feed; additive keys only, zero shape change.
  "aik": "آیک", "avs futebol sad": "ای‌وی‌اس",
  "académica": "آکادمیکا", "académico viseu": "آکادمیکو ویزئو",
  "alverca": "آلورکا", "amarante fc": "آمارانته", "arouca": "آروکا",
  "athletic club mg": "اتلتیک میناس", "atlético madrileño": "اتلتیکو مادریلنیو",
  "atlético nacional": "اتلتیکو ناسیونال", "avaí": "آوایی",
  "beerschot": "بیرشات", "boavista": "بوآویشتا", "botafogo": "بوتافوگو",
  "camacha": "کاماشا", "casa pia ac": "کازا پیا", "düsseldorf": "دوسلدورف",
  "estoril": "استوریل", "estoril praia": "استوریل", "estrela": "استرلا",
  "famalicão": "فامالیکاو", "feirense": "فیرنسه", "felgueiras": "فلگیراس",
  "gil vicente": "ژیل ویسنته", "grenoble": "گرونوبل", "grêmio": "گرمیو",
  "hnk gorica": "اچ‌ان‌کی گوریتسا", "kv mechelen": "مشلن",
  "laval": "لاوال", "leixões": "لیشویش", "lommel": "لومل", "mas fès": "ام‌ای‌اس فاس",
  "marítimo": "ماریتیمو", "moreirense": "موریرنسه", "nacional": "ناسیونال",
  "cd nacional": "ناسیونال", "new england": "نیو انگلند",
  "os belenenses sad": "بلننسس", "osijek": "اوسیک", "ourense": "اورنسه",
  "racing": "راسینگ", "racing de ferrol": "راسینگ د فرول",
  "real zaragoza": "رئال ساراگوسا", "rijeka": "رییکا", "rio ave": "ریو آوه",
  "rodez": "رودز", "santa clara": "سانتا کلارا", "santarém": "سانتارم",
  "sporting braga": "اسپورتینگ براگا", "sporting covilhã": "اسپورتینگ کوویلیا",
  "unionistas de salamanca": "یونیونیستاس سالامانکا", "vianense": "ویاننزه",
  "vitória de setúbal": "ویتوریا ستوبال", "zeleziarne podbrezová": "پودبرزووا",
  // cycle-152: UAE Pro League (league 538) — the 14-row table sweep + the
  // 100-entry transfer-feed sweep (72 distinct club names after dedup) +
  // the 19-season title-history sweep including the historic runner-up /
  // folded sides (Al Shabab Dubai merged into شباب الاهلی in 2017). The
  // five UAE clubs already mapped by the cycle-140 ACL West sweep
  // (al-jazira / shabab al-ahli dubai fc / al-wasl / al-ain / sharjah
  // cultural club) stay untouched. "al-nasr sc" (Dubai) is deliberately
  // disambiguated as «النصر امارات» — the famous Saudi Al-Nassr keeps
  // «النصر» under its own keys. Byte-exact from the live feed; additive
  // keys only, zero shape change.
  "ajman": "عجمان", "al bataeh": "البطایه", "al dhafra": "الظفره",
  "al-dhafra": "الظفره", "al fujairah": "الفجیره", "al nasr": "النصر",
  "al-nasr sc": "النصر امارات", "al shabab (dubai)": "الشباب دبی",
  "al shorta": "الشرطه", "al wahda": "الوحده", "al-wahda": "الوحده",
  "athletico paranaense": "اتلتیکو پارانونسه", "baniyas": "بنی‌یاس",
  "cruz azul": "کروز آزول", "difaâ el jadida": "الجدیده", "dinamo": "دینامو",
  "dinamo moscow": "دینامو مسکو", "fk sarajevo": "سارایوو",
  "flamengo": "فلامنگو", "gulf united": "گلف یونایتد", "hatta": "حتا",
  "kalba fc": "کلبا", "khorfakkan": "خورفکان", "ldu de quito": "ال‌دی‌یو کیتو",
  "las palmas": "لاس پالماس", "maribor": "ماریبور", "oh leuven": "لوون",
  "orlando": "اورلاندو", "orlando city": "اورلاندو سیتی",
  "pardubice": "پاردوبیتسه", "rs berkane": "برکان",
  "raja casablanca": "رجا کازابلانکا", "saint-étienne": "سن‌اتین",
  "san lorenzo": "سان لورنزو", "shimizu s-pulse": "شیمیزو اس‌پالس",
  "united fc": "یونایتد", "zamalek sc": "زمالک",
  // cycle-155: Qatar Stars League (league 535) — exact upstream row names of
  // the live 12-team 2026/2027 table + the 17-item transfer feed + the 22
  // title seasons not already mapped above (al-sadd / al-duhail sc /
  // al-rayyan / al-gharafa / al-ahli / al-shamal / abha / al qadsiah ride
  // existing entries — «Al-Ahli» is the SAME raw string in the Saudi table,
  // so Qatar's side honestly shares «الاهلی»; teamId keeps attribution
  // distinct). Probed row spellings 2026-10-29, UA Chrome/124.
  "al-arabi": "العربی", "al arabi": "العربی",
  "al-wakrah": "الوکره", "al wakrah": "الوکره",
  "al-shahaniya": "الشحانیه", "al shahaniya": "الشحانیه",
  "lusail sc": "لوسیل",
  "al gharafa": "الغرافه",
  "qatar sc": "قطر",
  "al-sailiya": "السیلیه", "al sailiya": "السیلیه",
  "el jaish": "الجیش", // defunct Lekhwiya-era side (merged into الدحیل 2017) — title-runner rows 2011–2015
  "far rabat": "فار رباط",
  "zulte waregem": "زولته وارخم",
  // cycle-156: Eredivisie (league 57) — exact upstream spellings of the
  // live 18-team 2026/2027 table + the top-20 window of the 154-scorer
  // goals.json + the 89-distinct-club transfer sweep + the 127 title
  // seasons not already mapped above (ajax / feyenoord / psv / az alkmaar /
  // fc twente / fortuna sittard / sc heerenveen / excelsior / sparta
  // rotterdam / pec zwolle / nec nijmegen / fc utrecht ride existing ACL+
  // UCL-era entries; scorer-file spellings «PSV» and «AZ» are the short
  // variants of the same clubs). Pre-war defunct champions (R.U.N. Amstels
  // en Progress, HVV Den Haag, Be Quick 1887…) deliberately ride the
  // honest English fallback — a 19th-century transliteration nobody uses
  // is worse than the source name (cycle-96/104 convention). Probed
  // 2026-10-29, UA Chrome/124. Zero duplicate keys against the 776
  // pre-existing team keys (guard asserted in cycle156-domproof).
  "fc groningen": "خرونینگن",
  "go ahead eagles": "گوآهد ایگلز",
  "cambuur": "کامبور", "sc cambuur": "کامبور",
  "telstar": "تلستار",
  "ado den haag": "آدو دن‌هاگ",
  "willem ii": "ویلم دوم",
  "fc volendam": "فولندام",
  "fc eindhoven": "آیندهوون",
  "de graafschap": "دِ خرافسخاپ",
  "heracles": "هراکلس",
  "mvv maastricht": "ام‌وی‌و ماستریخت",
  "roda jc kerkrade": "رودا",
  "az": "آلکمار", // scorer-file short spelling of AZ Alkmaar
  "hfc haarlem": "هارلم",
  "rkc waalwijk": "آر‌کی‌سی والویک",
  // transfer-feed foreign clubs not covered by earlier sweeps (23 distinct
  // unmapped in the 100-item feed — the mapped majority ride existing keys)
  "aab": "آلبورگ", "randers fc": "رانرس",
  "arminia bielefeld": "آرمینیا بیله‌فلد", "greuther fürth": "گرویتر فورث",
  "breiðablik": "بریدابلیک", "if karlstad": "ایف کارلستاد",
  "machida zelvia": "ماچیدا زلویا", "nk lokomotiva": "لوکوموتیوا",
  "rotherham": "روترام", "śląsk wrocław": "شلونسک وروتسواو",
  "salt lake": "رئال سالت‌لیک", // short spelling of Real Salt Lake
  // cycle-157: AFC Champions League Two (league 9469) — exact upstream
  // spellings of the 32-club composite table (Groups A–H) not already
  // mapped above (الجزیره/الریان/التعاون/الوحده/الفیصلی/ماچیدا زلویا/FC
  // Seoul/گل‌گهر ride existing entries — گل‌گهر سیرجان is a Persian Gulf
  // Pro League club) + the 21 title seasons' clubs not covered earlier
  // (2025/2026 گامبا اوساکا rides a match-feed-era key). Defunct/obscure
  // champions keep the honest English fallback only where no confident
  // transliteration exists (cycle-96/104 convention). Probed 2026-10-29,
  // UA Chrome/124. Zero duplicate keys against the 804 pre-existing team
  // keys (guard asserted in cycle157-domproof).
  "kuwait sc": "الکویت",
  "nasaf qarshi": "نسف قرشی",
  "al khalidiyah": "الخالدیه",
  "arkadag": "آرخاداغ",
  "muharraq": "المحررق",
  "al-nahda": "النهده",
  "al-hussein sc": "الحسین اردن",
  "east bengal fc": "ایست بنگال",
  "al-seeb": "السیب",
  "persib bandung": "پرسیب باندونگ",
  "melbourne victory": "ملبورن ویکتوری",
  "viettel": "ویت‌تل",
  "lion city sailors fc": "لایون سیتی سیلرز",
  "adelaide united": "آدلاید یونایتد",
  "bg pathum united": "بی‌جی پاتوم یونایتد",
  "tai po": "تای پو",
  "svay rieng": "سوای رینگ",
  "shanghai shenhua": "شانگهای شنهوا",
  "tampines rovers fc": "تامپینیز راورز",
  "phnom penh": "پنوم‌پن",
  "gangwon fc": "گانگ‌وون",
  "kitchee": "کیتچی",
  "kuching city": "کوچینگ سیتی",
  // title-history-only clubs (ACL Two seasons[] winners/runners 2004 →
  // 2025/2026; استقلال دوشنبه carries the city qualifier so it can never
  // be confused with Tehran's استقلال)
  "al karama sc": "الکرامه",
  "al-ahed": "العهد",
  "al-jaish": "الجیش",
  "al-nejmeh": "النجمه",
  "al-qadsia": "القادسیه",
  "altyn asyr": "آلتین اسیر",
  "april 25 sc": "آوریل ۲۵",
  "bengaluru fc": "بنگلورو",
  "central coast mariners": "سنترال کوست مارینرز",
  "erbil": "اربیل",
  "fc istiklol": "استقلال دوشنبه",
  "kuala lumpur city": "کوالالامپور سیتی",
  "safa beirut sc": "صفا بیروت",
  "shabab al ordon al quadisiya": "شباب اردن",
  // "al nassr fc" rides the existing saudi entry (النصر — the FC-suffixed
  // spelling was already mapped by the cycle-147 sweep; duplicate-key guard
  // caught the re-add and it was removed, the 152/155 sweep convention)
  // ---- cycle-159: player-career Latin-leak sweep (D5 live probe, 31 player
  // feeds: 101 distinct unmapped career rows). Sub-class D = historic foreign
  // club stops. Accented keys are the byte-exact lowercased feed forms
  // (norm() strips only U+0307 — the cycle-145 İ lesson); plain-ASCII
  // variants added defensively where feeds alternate spellings.
  "shahr khodrou fc": "شهرخودرو", "shahr khodrou": "شهرخودرو",
  "al mokawloon al arab": "المکاولون العرب",
  "barça atlètic": "بارسلونا اتلتیک", "barca atletic": "بارسلونا اتلتیک",
  "real madrid castilla": "رئال مادرید کاستیا",
  "sl benfica": "بنفیکا", "paok thessaloniki fc": "پائوک",
  "jong psv": "یونگ پی‌اس‌وی",
  "bochum": "بوخوم", "nürnberg": "نورنبرگ", "nurnberg": "نورنبرگ",
  "crotone": "کروتونه", "salernitana": "سالرنیتانا", "spezia": "اسپتزیا",
  "ternana": "ترنانا",
  "giresunspor": "گیرسون‌اسپور",
  "cd mirandés": "میراندس", "cd mirandes": "میراندس",
  "gimnàstic": "خیمناستیک", "gimnastic": "خیمناستیک",
  "sporting gijón": "اسپورتینگ خیخون", "sporting gijon": "اسپورتینگ خیخون",
  "boca juniors": "بوکا جونیورز", "estudiantes": "استودیانتس",
  // cycle-400: the coach-trophies harvest surfaced these two — established
  // transliterations, the honest passthrough shrinks to zero on the set
  "river plate": "ریور پلات", "newell's old boys": "نیولز اولد بویز",
  "talleres": "تایرس", "tigre": "تیگره", "leones": "لئونس",
  "lyngby": "لینگبی", "silkeborg": "سیلکبورگ", "ifk norrköping": "نورشوپینگ",
  "ifk norrkoping": "نورشوپینگ",
  "bryne": "برینه", "kristiansund": "کریستیان‌سوند", "stabæk": "استابک",
  "stabak": "استابک", "breidablik": "بریدابلیک",
  "pogoń szczecin": "پوگون شچچین", "pogon szczecin": "پوگون شچچین",
  "chrobry głogów": "خروبری گووگوف", "chrobry glogow": "خروبری گووگوف",
  "scunthorpe united": "اسکانتورپ‌یونایتد", "shrewsbury town": "شروزبری‌تاون",
  "portimonense": "پورتیموننزه", "eupen": "یوپن",
  "qarabağ fk": "قره‌باغ", "qarabag fk": "قره‌باغ",
  "fc rostov": "روستوف", "rostov": "روستوف",
  "bunyodkor tashkent": "بونیودکار تاشکند", "bunyodkor": "بونیودکار",
  "fk mash'al mubarek": "ماشال مبارک",
  "inter zapresic": "اینتر زاپرشیچ",
  "ks besa kavajë": "بسا کاواجه", "ks besa kavaje": "بسا کاواجه",
  "teuta durrës": "تئوتا دراج", "teuta durres": "تئوتا دراج",
  "sc lusitânia": "لوزیتانیا", "sc lusitania": "لوزیتانیا",
  "union touarga sportif": "یونیون توارگا",
  "mls all-stars": "ستارگان ام‌ال‌اس", "mls all stars": "ستارگان ام‌ال‌اس",
  "orléans": "اورلئان", "orleans": "اورلئان",
  "us orléans loiret": "اورلئان", "us orleans loiret": "اورلئان",
  "vitória sc guimarães": "ویتوریا گیمارایش", "vitoria sc guimaraes": "ویتوریا گیمارایش",
  "épinal": "اپینال", "epinal": "اپینال",
  // cycle-160: Swiss Super League — five unmapped table clubs with
  // byte-exact AND plain-ASCII variants (the cycle-145 İ lesson: ü never
  // lowercases to u, so «FC Zürich» and «FC Zurich» both need keys), the
  // scorer-file long forms (BSC Young Boys / FC Basel / FC Vaduz — the
  // table feed's short «Young Boys»/«Basel» were already mapped by earlier
  // sweeps, as were lugano/thun/servette/lausanne/grasshopper/xamax), and
  // the 96-distinct-club transfer sweep (the Swiss winter clubs first:
  // Winterthur/Wil/Kriens/Etoile Carouge/Rapperswil-Jona/Stade
  // Lausanne-Ouchy/Stade Nyonnais/Yverdon, then the foreign partners).
  "sion": "سیون",
  "fc zürich": "زوریخ", "fc zurich": "زوریخ",
  "st. gallen": "سنت‌گالن", "st gallen": "سنت‌گالن", "saint gallen": "سنت‌گالن",
  "luzern": "لوتسرن",
  "fc vaduz": "وادوتس",
  "bsc young boys": "یانگ‌بویز", "fc basel": "بازل",
  "winterthur": "وینترتور", "wil": "ویل", "kriens": "کرینس",
  "etoile carouge": "اتوال کاروژ",
  "fc rapperswil-jona": "راپرسویل یونا",
  "fc stade lausanne-ouchy": "استاد لوزان اوشی",
  "stade nyonnais": "استاد نیون",
  "austria lustenau": "آستریا لوستناو",
  "amiens": "امیان",
  "baník ostrava": "بانیک اوستراوا", "banik ostrava": "بانیک اوستراوا",
  "batman petrolspor": "باتمان پترول‌اسپور",
  "carrarese": "کارارزه",
  "castellón": "کاستلون", "castellon": "کاستلون",
  "enosis paralimni": "انوزیس پارالیمنی",
  "fc andorra": "آندورا",
  "fc heidenheim": "هایدنهایم",
  "juventus next gen": "یوونتوس نکست‌جن",
  "kalmar ff": "کالمار",
  "kortrijk": "کورتریک",
  "lechia gdańsk": "لخیا گدانسک", "lechia gdansk": "لخیا گدانسک",
  "nycfc": "نیویورک‌سیتی",
  "red star": "رد استار",
  "royal antwerp": "رویال آنتورپ",
  "start": "استارت",
  "union touarga sport": "یونیون توارگا",
  "westerlo": "وسترلو",
  "widzew łódź": "ویدزف ووتس", "widzew lodz": "ویدزف ووتس",
  "wisła kraków": "ویسوا کراکوف", "wisla krakow": "ویسوا کراکوف",
  "örgryte": "اورگریته", "orgryte": "اورگریته",
  "železničar pančevo": "ژلزنیچار پانچوو", "zeleznicar pancevo": "ژلزنیچار پانچوو",
  "1.fc köln": "کلن", "1.fc koln": "کلن",
  // cycle-161: Croatian HNL — the table's short forms are mostly mapped by
  // earlier sweeps (dinamo zagreb / hajduk split / rijeka / osijek /
  // nk lokomotiva / nk varaždin / rudeš / hnk gorica) — the missing two
  // table clubs + the scorer-file long forms ride the SAME Persian values
  // (byte-exact key families, the cycle-159 convention), the defunct 1992
  // runner-up ان‌کی زاگرب stays distinct from دیناموزاگرب, and the
  // 85-distinct-club transfer sweep fills the rest.
  "nk istra 1961": "ایسترا ۱۹۶۱", "istra 1961": "ایسترا ۱۹۶۱",
  "slaven": "اسلاون بلوپو", "slaven belupo koprivnica": "اسلاون بلوپو",
  "nk osijek": "اوسیک", "hnk rijeka": "رییکا", "lokomotiva zagreb": "لوکوموتیوا",
  "nk zagreb": "ان‌کی زاگرب",
  "apoel nicosia": "آپوئل نیکوزیا",
  "al ahly sc": "الاهلی مصر",
  "aldosivi": "آلدوسیوی",
  "aluminij": "آلومینی",
  "anorthosis": "آنورتوسیس",
  "asia talas": "آسیا تالاس",
  "bursaspor": "بورسااسپور",
  "cibalia": "تسیبالیا",
  "dac 1904 dunajska streda": "داک ۱۹۰۴ دونای‌سکا استردا",
  "dukagjini": "دوکاجینی",
  "dukla praha": "دوکلا پراگ",
  "fc arges pitesti": "آرژ پیتشتی",
  "hapoel ironi kiryat shmona": "هاپوئل کریات‌شمونه",
  "independiente medellín": "ایندپندینته مدئین", "independiente medellin": "ایندپندینته مدئین",
  "kispest honvéd": "کیس‌پشت هونود", "kispest honved": "کیس‌پشت هونود",
  "koper": "کوپر",
  "lugo": "لوگو",
  "milan futuro": "میلان فیوتورو",
  "mura": "مورا",
  "nfc volos": "ولوس",
  "nk radomlje": "رادوملیه",
  "oțelul galați": "تسلول گالاتس", "otelul galati": "تسلول گالاتس",
  "pfc sochi": "سوچی", "sochi": "سوچی",
  "persija jakarta": "پرسیجا جاکارتا",
  "rfs": "آر‌اف‌اس ریگا",
  "sv lafnitz": "لافنیتس",
  "sigma olomouc": "سیگما اولوموتس",
  "vejle boldklub": "وایله",
  "vukovar 91": "ووکوار ۹۱",
  "wieczysta kraków": "ویچیستا کراکوف", "wieczysta krakow": "ویچیستا کراکوف",
  "zabbar st. patrick fc": "زاببار سنت پاتریک",
  "zira": "زیرا",
  "újpest": "اوی‌پشت", "ujpest": "اوی‌پشت",
  "široki brijeg": "شیروکی بریگ", "siroki brijeg": "شیروکی بریگ",
  // ---- cycle-162: Malaysia Super League sweep (D5 live probe 2026-10-30,
  // UA Chrome/124): 26 unmapped distinct clubs across the current 12-row
  // table + the 2026/2027→2018 archived tables + the 63-row PascalCase
  // scorer files + the 3-item transfer list (Maccabi Haifa; Telstar and
  // Malmö FF already mapped by the eredivisie/hnl sweeps). All keys ASCII —
  // no plain-ASCII variants needed (the cycle-145 İ lesson applies to
  // accented feeds only). Malaysian state clubs keep their standard
  // Persian-football transliterations.
  "brunei dpmm": "برونئی دی‌پی‌ام‌ام",
  "felda united fc": "فلدا یونایتد",
  "imigresen fc": "ایمیگرسن",
  "kedah darul aman": "کداح دارالامان",
  "kelantan": "کلانتان",
  "kelantan dnfc": "کلانتان دی‌ان‌اف‌سی",
  "kelantan red warrior": "کلانتان رد واریور",
  "kelantan the real warriors fc": "کلانتان رئال واریرز",
  "kelantan united": "کلانتان یونایتد",
  "maccabi haifa": "مکابی حیفا",
  "melaka fc": "ملاکا",
  "melaka united": "ملاکا یونایتد",
  "negeri sembilan": "نگری سمبیلان",
  "pdrm": "پی‌دی‌آرام",
  "penang": "پنانگ",
  "perak": "پراک",
  "perak ii": "پراک ۲",
  "petaling jaya city fc": "پتالینگ جایا سیتی",
  "sabah": "صباح",
  "sarawak united": "ساراواک یونایتد",
  "selangor": "سلانگور",
  "selangor ii": "سلانگور ۲",
  "sri pahang": "سری پاهنگ",
  "star city": "استار سیتی",
  "terengganu": "ترنگگانو",
  "uitm": "اوی‌تی‌ام",
  // ---- cycle-165: Ekstraklasa (Poland) — table (8 unmapped of 18; the
  // other 10 ride earlier sweeps: لخ پوزنان/گورنیک زابژه/پوگون شچچین/لگیا
  // ورشو/ویسوا کراکوف/یگیلونیا/ویدزف ووتس/شلونسک وروتسواو/
  // ویچیستا کراکوف/راکوف چنستوخووا) + the goals-file «Legia Warsaw»
  // spelling + title-only clubs + the 91-club transfer sweep (23 unmapped).
  // Diacritics preserved in keys per the teamFa norm (lowercase only).
  "piast gliwice": "پیاست گلیویتسه",
  "zagłębie lubin": "زاگوله لوبین",
  "gks katowice": "گکس کاتوویتسه",
  "korona kielce": "کورونا کیلتسه",
  "wisła płock": "ویسوا پلوک",
  "motor lublin": "موتور لوبلین",
  "cracovia": "کراکوویا",
  "radomiak radom": "رادومیاک رادوم",
  // goals.json spells the Warsaw club «Legia Warsaw» while the table/titles
  // carry «Legia Warszawa» — both keys, same club (the al-nassr collision
  // class caught by the 157 guard)
  "legia warsaw": "لگیا ورشو",
  // title-only clubs (99-season history; pre-war ones ride the honest
  // English fallback by design — these ten are confident)
  "polonia bytom": "پولونیا بیتوم",
  "polonia warszawa": "پولونیا ورشو",
  "ruch chorzów": "روخ خوشوف",
  "stal mielec": "استال میلتس",
  "warta poznań": "وارتا پوزنان",
  "zagłębie sosnowiec": "زاگوله سوسنوویتس",
  "łks łódź": "ال‌کی‌اس وودز",
  "gks bełchatów": "گکس بلاتشاتوف",
  "lks pogoń lwów": "پوگون لویو",
  // transfer-sweep clubs (unmapped of the 91 distinct from/to clubs across
  // transfers.data=100)
  "al-ula fc": "العلا",
  "arka gdynia": "آرکا گدینیا",
  "athens kallithea fc": "کالیتئا آتن",
  "brøndby if": "بروندبی",
  "cúcuta": "کوکوتا",
  "fcv dender eh": "دندر",
  "fredrikstad": "فردریکستاد",
  "gks tychy": "گکس تیشی",
  "luton": "لوتون",
  "mardinspor": "ماردین‌اسپور",
  "miedź legnica": "میج لگنیتسا",
  "minnesota": "مینه‌سوتا",
  "ny red bulls": "نیویورک ردبولز",
  "ob": "اودنسه",
  "psim yogyakarta": "پسیم یوگیاکارتا",
  "paços de ferreira": "پاسوش دی فرییرا",
  "sabadell": "سابادل",
  "stal stalowa wola": "استال ستالووا وولا",
  "standard liège": "استاندارد لیژ",
  "ts podbeskidzie bielsko-biała": "پودبسکیدزه بیلسکو-بیاوا",
  "termalica nieciecza": "ترمالیکا نیه‌چیتسا",
  "ud ibiza": "ایبیزا",
  "vfl osnabrück": "اسنابروک",
  // ghost-id (-1) club surfaced by the live zero-ASCII sweep of OUR OWN
  // /api/league-transfers?league=poland panel (the 92nd distinct club —
  // a transfer target outside the 91-id sweep because upstream omits its id)
  "busko-zdroj": "بوسکو زدروی",
  // ---- cycle-181: Belgian Pro League — the 1 unmapped TABLE club (RAAL
  // La Louvière; the other 17 ride earlier sweeps: خنت/کلوب بروژ/یونیون
  // سنت‌ژیلوآز/شارلروا/آندرلشت/خنک/وسترلو/لومل/استاندارد لیژ/زولته وارخم/
  // رویال آنتورپ/بورن/سنت‌ترویدن/مشلن/لوون/کورتریک/سرکل بروژ) + the
  // goals/card-file team spellings (TeamName differs from the table: KAA
  // Gent, KVC Westerlo, KRC Genk, Sint-Truidense VV, Sporting de Charleroi,
  // SV Zulte Waregem, Waasland-Beveren — same-club variants take the SAME
  // Persian as their table twin, the goals.json spelling sweep of 165) +
  // the 123-season title sweep (12 unmapped, incl. the OLDEST champion of
  // any portal: FC Liège 1895/1896) + the 105-side transfer sweep (24
  // unmapped). Diacritics preserved in keys per the teamFa norm
  // (lowercase only). Zero duplicate-key collisions (build-time guard).
  // table club (18th of 18)
  "raal la louvière": "رآل لا لوویر",
  // goals/card-file spellings (same clubs as table rows)
  "kaa gent": "خنت",
  "kvc westerlo": "وسترلو",
  "krc genk": "خنک",
  "sint-truidense vv": "سنت‌ترویدن",
  "sporting de charleroi": "شارلروا",
  "sv zulte waregem": "زولته وارخم",
  // Waasland-Beveren is the pre-2022 name of SK Beveren — one club, one
  // Persian (the collision-class comment of 165, probed spelling pair)
  "waasland-beveren": "بورن",
  // title-only clubs (123-season history; FC Liège is the 1895/1896
  // champion — the oldest title row of any portal)
  "fc liège": "اف‌سی لیژ",
  "ksk beveren": "بورن",
  "lierse": "لییرس",
  "k. lierse sk": "لییرس",
  "lokeren": "لوکرن",
  "berchem sport 2004": "برخم اسپورت",
  "koninklijke beerschot vac": "بیرشوت",
  "koninklijke beringen fc": "برینخن",
  "olympic de charleroi": "المپیک شارلروا",
  "r. léopold fc": "لئوپولد",
  "rwdm brussels": "آر‌دبلیو‌دی‌ام بروکسل",
  "racing white daring molenbeek": "راسینگ وایت دارینگ مولن‌بیک",
  "royal racing white": "رویال راسینگ وایت",
  // transfer-sweep clubs (unmapped of the 105 distinct from/to sides
  // across transfers.data=100)
  "ac oulu": "آ‌سی اولو",
  "aarau": "آراو",
  "annecy fc": "آنسی",
  "avellino": "آولینو",
  "debrecen": "دبرتسن",
  "dunkerque": "دانکرک",
  "francs borains": "فران بورن",
  "helmond sport": "هلموند اسپورت",
  "hoek": "هوک",
  "karviná": "کاروینا",
  "lanús": "لانوس",
  "londrina": "لوندرینا",
  "patro eisden": "پاترو آیدن",
  "puebla": "پوئبلا",
  "pumas": "پوماس",
  "reggiana": "رجیانا",
  "royal knokke fc": "رویال کنوکه",
  "sk austria klagenfurt": "آستریا کلاگن‌فورت",
  "skn st. pölten": "سانکت پولتن",
  "sirius": "سیریوس",
  "sporting hasselt": "اسپورتینگ هاسلت",
  "ut arad": "یوت آراد",
  "umm salal": "ام صلال",
  // cycle-361: Egyptian Premier League (fotmobId 519) — the EXACT upstream
  // row names of the live 519 table; five clubs were already mapped for the
  // CAF surfaces (pyramids fc, al ahly sc, zamalek sc, ceramica cleopatra,
  // al mokawloon al arab) and are NOT repeated here. Persian forms are the
  // standard press transliterations.
  "al ittihad alexandria": "الاتحاد اسکندریه",
  "modern sport fc": "مدرن اسپورت",
  "zed fc": "زد",
  "national bank": "بانک ملی",
  "smouha sc": "سموحه",
  "petrojet-suez": "پتروجت سوئز",
  "al masry sc": "المصری",
  "tala'ea el gaish": "طلائع الجیش",
  "olympic el qanah fc": "المپیک",
  "wadi degla fc": "وادی دجله",
  "ghazl al mahalla": "غزل المحله",
  "al sharkeyah-enppi": "الشرکیه",
  "asyut petroleum": "پترول اسیوط",
  "abo qir semad": "ابو قیر",
  "el gouna fc": "الجونه",
  // cycle-362: Iraq Stars League (fotmobId 524) — the EXACT upstream row
  // names of the live 524 table; four clubs were already mapped for the
  // ACL/ACL2/gulf surfaces (al quwa al jawiya, al zawraa, al shorta,
  // erbil) and are NOT repeated here. Persian forms are the standard
  // press transliterations.
  "al-karma": "الکرمه",
  "al naft": "النفت",
  "newroz": "نیوروز",
  "al-jolan sc": "الجولان",
  "al minaa": "المیناء",
  "duhok": "دهوک",
  "ghaz al-shamal sc": "غاز الشمال",
  "al talaba": "الطلبه",
  "diyala": "دیالی",
  "zakho": "زاخو",
  "al-gharraf": "الغراف",
  "al-mosul": "الموصل",
  "al karkh": "الکرخ",
  "naft maysan": "نفت میسان",
  "al kahrabaa": "الکهربا",
  "karbalaa": "کربلا",

  // ---- cycle-384 (bug-hunt 383 findings F1+F2+F3): one TEAM_FA block ----
  // the 383 uncurated Latin scans found the same root cause through THREE
  // display paths — title-history championFa/runnerUpFa, fixtures .fa and
  // the matchDetails h1 — every name below was probed live from the exact
  // upstream spelling (scripts/cycle384-probe.sh, 2026-11-02). Persian
  // forms follow the press transliterations; cup-era prefix noise (FC/AFC/
  // SC) is dropped when the city/club name is the natural Persian form.
  // F1 facup: the 9 amateur-era names of the 145-season history.
  "blackburn olympic fc": "بلکبرن المپیک",
  "clapham rovers fc": "کلافام روورز",
  "old carthusians fc": "اولد کارتوزیانز",
  "old etonians fc": "اولد ایتونیانز",
  "oxford university afc": "آکسفورد یونیورسیتی",
  "queen's park": "کوئینز پارک",
  "royal engineers afc": "رویال انجینیرز",
  "wanderers football club": "واندررز",
  "wimbledon fc": "ویمبلدون", // bare "wimbledon" already rides the 381 block
  // F1 coppaitalia: the 7 historic names of the 78-season history.
  "ac ancona": "آنکونا",
  "alessandria": "الساندریا",
  "football padova spa": "پادوا", // shares "padova" (380)
  "novara": "نووارا",
  "spal": "اسپال",
  "vado": "وادو",
  "vicenza": "ویتشنزا", // shares "lr vicenza" (380)
  // F1 dfbpokal: the 18 historic names of the 83-season history.
  "1860 münchen": "مونیخ ۱۸۶۰",
  "alemannia aachen": "آلمانیا آخن",
  "dresdner sc": "درسدنر",
  "etb schwarz-weiß essen": "شوارتز وایس اسن",
  "energie cottbus": "انرژی کوتبوس",
  "fsv frankfurt": "اف‌اس‌وی فرانکفورت",
  "first vienna fc 1894": "فرست وینا ۱۸۹۴",
  "fortuna köln": "فورتونا کلن",
  "kfc uerdingen": "کی‌اف‌سی اردینگن",
  "karlsruher sc": "کارلسروهه",
  "kickers offenbach": "کیکرز اوفنباخ",
  "luftwaffen-sv hamburg": "لوفت‌وافن هامبورگ",
  "msv duisburg": "ام‌اس‌وی دویسبورگ",
  "rw essen": "روت‌وایس اسن",
  "stuttgarter kickers": "اشتوتگارتر کیکرز",
  "vfb borussia neunkirchen": "بروسیا نوین‌کیرشن",
  "vfb leipzig": "لایپزیش", // city-name consistent with "rb leipzig"/"leipzig"
  "waldhof mannheim": "والدهوف مانهایم",
  // F2 dfbpokal: the 23 fixture-only minnows of the 2026/2027 first
  // rounds (the 6 titles-list overlaps above are not repeated).
  "1. fc phönix lübeck": "فونیکس لوبک",
  "bahlinger sc": "باهلینگن",
  "carl zeiss jena": "کارل زایس ینا",
  "eintracht braunschweig": "اینتراخت برانشوایگ",
  "eintracht trier": "اینتراخت تری‌یر",
  "erzgebirge aue": "ارتس‌گبیرگ آئوه",
  "fc hansa lüneburg": "هانزا لونه‌بورگ",
  "hebc hamburg": "اچ‌ای‌بی‌سی هامبورگ",
  "hallescher fc": "هالشر",
  "hansa rostock": "هانزا روستوک",
  "preussen münster": "پروسن مونستر",
  "sc st. tönis": "سنت تونیس",
  "sc verl": "فرل",
  "ssv jeddeloh": "یدلوه",
  "sv hemelingen": "هملینگن",
  "saarbrücken": "زاربروکن",
  "sonnenhof großaspach": "زوننهوف گروس‌آسپاخ",
  "tsv schott mainz": "شوت ماینتس",
  "vsg altglienicke": "آلت‌گلینیک",
  "vfb krieschow": "کریشو",
  "viktoria köln 1904": "ویکتوریا کلن",
  "westfalia rhynern": "وستفالیا رینرن",
  "würzburger kickers": "وورتسبورگر کیکرز",
  // F4b: the 7 Azadegan League sides the home day-feed serves raw —
  // audience-critical on a Persian portal (the Persian Gulf Pro League
  // table teams were mapped in cycle-136; these ride the SAME map).
  "mes kerman": "مس کرمان",
  "naft bandar abbas": "نفت بندرعباس",
  "qeshm island": "جزیره قشم",
  "beasat kermanshah": "بیسات کرمانشاه",
  "ario islamshahr": "آریو اسلامشهر",
  "fc fard": "اف‌سی فرد",
  "shahin bandar ameri": "شهین بندر عامری",
  // cycle-387: the multi-day window (offset -2..+2, scripts/cycle387-probe.sh)
  // found exactly these 4 recurring raw Azadegan names beyond the 384 set —
  // every key is the exact live-probed upstream spelling (the F2-378 guard):
  // «Havadar SC» is the suffixed spelling the bare «havadar» key can't reach.
  "havadar sc": "هوادار",
  "kara gostar": "کارا گستر",
  "naft masjed soleyman fc": "نفت مسجدسلیمان",
  "niroye zamini": "نیروی زمینی",
  // cycle-389: the 388 patrol's surfaced team names — Gateshead (team-fixtures
  // fa) and the coach-career pair (teamFa-routed stints on /coach/{id}); keys
  // are the exact live-probed upstream spellings (the F2-378 guard).
  "gateshead fc": "گیتس‌هد",
  "fc liefering": "اف‌سی لیفرینگ",
  "red bull akademie": "آکادمی ردبول",
  // the fuller live spelling the /coach/{id} career serves (389 probe) — the
  // 388 card's «Red Bull Akademie» rides inside this upstream string.
  "red bull akademie under 18 (fc salzburg under 18)": "آکادمی ردبول زیر ۱۸ سالزبرگ",
  // cycle-390: the one unmapped side name on the NT fixture rows (Iran 6711
  // probe: every side mapped but «Gambia»).
  "gambia": "گامبیا",

  // cycle-394 (the 393 bug-hunt F1 flip): Argentina 6706 NT fixture rows served
  // the OPPONENT fa raw — teamFa had no key for these four confederate sides
  // (live-probed: recent[0..2].away.fa = Benin/Burkina Faso/Bolivia,
  // upcoming[1].away.fa = Costa Rica; the other six probed NTs were clean).
  // TEAM_FA-first per the 393 card — teamFa checks this map before COUNTRY_FA.
  "benin": "بنین",
  "burkina faso": "بورکینافاسو",
  "bolivia": "بولیوی",
  "costa rica": "کاستاریکا",
  // cycle-417: the 7 Hazfi Cup second-tier entrants the league-9487 payload
  // serves that no earlier block reaches (the 25 other distinct names ride
  // the persiangulf/azadegan/384/387 sets already — census in
  // scripts/cycle417-probe.sh output). Keys are the exact live-probed
  // upstream spellings (the F2-378 guard); honest, long-established Persian
  // club names.
  "bargh shiraz": "برق شیراز",
  "chooka talesh": "چوکا تالش",
  "damash": "داماش",
  "foolad hormozgan": "فولاد هرمزگان",
  "kia fc": "کیا",
  "padyab khalkhal": "پادیاب خلخال",
  "shahrdari nowshahr": "شهرداری نوشهر",
  // cycle-405: transfer/rumour side-club leaks (probe: scripts/cycle405_leakscan.py — Tijuana/Hartberg/… were the Latin passthroughs on the 8650 surfaces) — honest city/club names, byte-exact keys.
  "tijuana": "تیخوانا",
  "chicago fire fc": "شیکاگو فایر",
  "philadelphia union": "فیلادلفیا یونیون",
  "hartberg": "هارتبرگ",
  "fk riga": "اف‌کی ریگا",
  "djurgaarden": "یورگاردن",
  "defensor sporting": "دفنسور اسپورتینگ",
  "club brugge nxt": "کلوب بروژ دوم",
  "bari": "باری",
  "latina": "لاتینا",
  "sorrento": "سورنتو",
  "casertana": "کازرتانا",
  // cycle-430: the 426 card's documented «harvest machine» opens — the ±7-day
  // day-feed census (scripts/cycle430-harvest.py, live UA Chrome/124) ranked
  // the honest-raw team fallback pool (baseline byte-stable at
  // teamLeakDistinct=2256 / rows=4818, the 426 A2 hold) and this batch takes
  // the 40 highest-frequency names whose identity is SINGLE-COUNTRY in the
  // window: every key byte-verified against the live feed (167 leak rows
  // covered) and every value an established Persian club name (the
  // تیخوانا j→خ rule, the مولودیه/اتحاد Algerian convention, the یونایتد/
  // تاون suffix-keeping style of the ساوتند یونایتد/نورث‌همپتون تاون blocks).
  // The 389 rule applied to the harvest: multi-country literals stay honest-
  // raw and are deliberately NOT here — «Alianza FC» (PAN/SLV both real in
  // the CONCACAF Central American Cup), «Libertad», «Santa Fe», «Olimpia»,
  // «Universidad Católica» (CHI vs ECU both seen in the window) — they need
  // id-keyed infrastructure first. Loud-pool rule: this batch SHRINKS the
  // documented 2256 pool by 40 distinct names — the 426 A2 hold will flag
  // exactly this change (that is its job: never silently 'fixed').
  "chelmsford": "چلمزفورد",
  "ebbsfleet united": "ابسفلیت یونایتد",
  "hampton & richmond": "همپتون و ریچموند",
  "braintree town": "برینتری تاون",
  "farnham town": "فارنام تاون",
  "truro city": "ترورو سیتی",
  "anstey nomads": "آنستی نومادز",
  "bishop's stortford": "بیشاپز استورتفورد",
  "stamford afc": "استمفورد",
  "bromsgrove sporting": "برومسگرو اسپورتینگ",
  "kettering town fc": "کترینگ تاون",
  "peterborough sports": "پیتربورو اسپورتس",
  "redditch united": "ردیچ یونایتد",
  "real bedford": "رئال بدفورد",
  "tamworth": "تمورث",
  "uxbridge": "یوکسبریج",
  "bracknell town": "براکنل تاون",
  "poole town fc": "پول تاون",
  "chertsey town": "چرتی تاون",
  "hanwell town": "هانول تاون",
  "brentwood town": "برنتوود تاون",
  "eastbourne borough": "ایستبورن بورو",
  "st albans": "سنت آلبنز",
  "burgess hill town": "برگس هیل تاون",
  "stanway rovers": "استنوی روورز",
  "leek town": "لیک تاون",
  "cumbernauld colts": "کامبرنولد کولتس",
  "clydebank": "کلایدبنک",
  "mc alger": "مولودیه الجزایر",
  "us biskra": "اتحاد بسکره",
  "atlético-mg": "اتلتیکو مینیرو",
  "ld alajuelense": "آلاخوئلنسه",
  "municipal pérez zeledón": "مونیسیپال پرز زلدون",
  "cd jaguares": "خاگوارس",
  "deportivo pasto": "دپورتیوو پاستو",
  "burgos cf": "بورگوس",
  "sepsi osk": "سپسی اوسک",
  "muang thong united": "موانگ‌تونگ یونایتد",
  "police tero fc": "پولیس تیرو",
  "universidad de chile": "یونیورسیداد شیلی",
  // cycle-431: harvest batch 2 — the machine continues on the 431 census
  // (scripts/cycle430-harvest.py re-run, live UA Chrome/124): the pool read
  // 2216 distinct after batch 1 (byte-exact −40/−167) and this batch takes
  // the 54 next single-country names (214 live leak rows, byte-verified
  // keys): the whole Algeria Ligue 1 cluster (the JS=شباب / CR=شباب /
  // USM=اتحاد / MC=مولودیه prefix conventions — شباب قابلی، مولودیه وهران،
  // اتحاد الجزائر، شباب بلوزداد…), the Venezuela/Colombia Primera cluster,
  // the CONCACAF Central American Cup sides (HON/CRC/SLV), Panama LPF,
  // the Paraguay short literals (لوکینیو/رکولتا — single-country in the
  // window), South Africa PSL (کایزر چیفس/ماملودی ساندوانز), the Scottish
  // Lowland/League clusters (پارتیک تیسل، همیلتون آکادمیکال…), and the
  // established singles (واسکو دوگاما، بریسبن رور، بوهمیانس ۱۹۰۵، هجر…).
  // The 389 rule again rules the skip line: «Alianza FC» (PAN/COL/INT — a
  // third country surfaced this window), «Libertad», «Santa Fe», «Olimpia»,
  // «Universidad Católica» stay honest-raw pending id-keyed infrastructure;
  // «MB Rouissat» skipped on uncertain identity (no established form probed).
  "js kabylie": "شباب قابلی",
  "mc oran": "مولودیه وهران",
  "usm alger": "اتحاد الجزائر",
  "cr bélouizdad": "شباب بلوزداد",
  "js saoura": "شباب ساوره",
  "cs constantine": "قسنطینه",
  "usm khenchela": "اتحاد خنشله",
  "cr temouchent": "شباب تموشنت",
  "js el biar": "شباب البیار",
  "es sétif": "ستیف",
  "es ben aknoun": "بن اکنون",
  "aso chlef": "المپیک شلف",
  "olympique akbou": "المپیک آکبو",
  "bucaramanga": "بوکارامانگا",
  "academia puerto cabello": "آکادمیا پورتو کابلو",
  "caracas": "کاراکاس",
  "deportivo táchira": "دپورتیوو تاچیرا",
  "monagas sc": "موناگاس",
  "carabobo fc": "کارابوبو",
  "deportivo la guaira": "دپورتیوو لا گوایرا",
  "metropolitanos fc": "متروپولیتانوس",
  "portuguesa fc": "پورتوگسا",
  "cd marathón": "ماراتن",
  "cd olimpia": "المپیا",
  "fc motagua": "موتاگوا",
  "c.s. cartaginés": "کارتاگینس",
  "deportivo saprissa": "دپورتیوو ساپریسا",
  "firpo": "فیرپو",
  "veraguas united": "وراگواس یونایتد",
  "union cocle": "یونین کوکله",
  "luqueño": "لوکینیو",
  "recoleta": "رکولتا",
  "mamelodi sundowns fc": "ماملودی ساندوانز",
  "kaizer chiefs": "کایزر چیفس",
  "stellenbosch fc": "استلنبوش",
  "musselburgh athletic": "ماسلبرو اتلتیک",
  "bonnyrigg rose": "بونریگ روز",
  "hamilton academical": "همیلتون آکادمیکال",
  "berwick rangers": "برویک رنجرز",
  "hill of beath hawthorn": "هیل اوف بیث هاثورن",
  "johnstone burgh": "جانستون بورو",
  "pollok": "پولوک",
  "montrose": "مونتروز",
  "spartans fc": "اسپارتانز",
  "partick thistle": "پارتیک تیسل",
  "curzon": "کورزون",
  "farnborough": "فارنبرو",
  "bohemians 1905": "بوهمیانس ۱۹۰۵",
  "trenčín": "ترنتشین",
  "kifisia fc": "کیفیسیا",
  "vasco da gama": "واسکو دوگاما",
  "brisbane roar fc": "بریسبن رور",
  "al bukayriyah": "البکیریه",
  "hajer": "هجر",
  // cycle-432: harvest batch 3 — the machine continues on the 432 census
  // (scripts/cycle430-harvest.py re-run + scripts/cycle432-batch3-verify.py
  // byte-identity gate, live UA Chrome/124): the pool read 2157 distinct
  // after batch 2 and this batch takes the 48 next single-country names
  // (175 live leak rows, every key byte-verified, 48/48 verified=0 bad):
  // the whole England National League System cluster (National League North/
  // South, Southern Premier Central/South, Isthmian, Northern Premier — the
  // یونایتد/تاون/سیتی suffix-keeping style) and the Spain Copa del Rey
  // first-round cluster (Segunda/Primera Federacion sides — خیمناستیکا/
  // کولتورال Spanish conventions). The 389 rule again rules the skip line:
  // the multi-country top of the pool stays honest-raw — «Alianza FC» (now
  // FOUR countries in-window: INT/PAN/COL/SLV), «Santa Fe» (COL+INT),
  // «Libertad» (PAR+ECU), «Universidad Católica» (CHI+ECU), «Olimpia»
  // (PAR+INT); «MB Rouissat» still skipped on uncertain identity (the 431
  // hold). Loud-pool rule: the documented 2160 census shrinks by this batch
  // in the open (the B4 ±25 band will flag exactly this: re-anchor with the
  // next census, never silently).
  "hereford": "هرفورد",
  "morecambe": "مورکم",
  "torquay united": "تورکی یونایتد",
  "hemel hempstead": "همل همپستد",
  "walton and hersham": "والتون و هرشام",
  "banbury united": "بنبری یونایتد",
  "stratford town": "استراتفورد تاون",
  "halesowen town fc": "هالسوون تاون",
  "leamington": "لمینگتون",
  "rushall olympic": "راشال المپیک",
  "needham market": "نیدهام مارکت",
  "leiston": "لیستون",
  "racing club warwick": "ریسینگ کلاب وارویک",
  "stourbridge": "استوربریج",
  "chichester city fc": "چیچستر سیتی",
  "hanworth villa": "هنورث ویلا",
  "gloucester city": "گلاستر سیتی",
  "yate town": "ییت تاون",
  "havant and waterlooville": "هاوانت و واترلوویل",
  "enfield town": "انفیلد تاون",
  "chatham town": "چتم تاون",
  "welling united": "ولینگ یونایتد",
  "leatherhead": "لدرهد",
  "whitehawk": "وایت‌هاوک",
  "dulwich hamlet": "دالیویچ هملت",
  "quorn": "کوورن",
  "lewes": "لوئیس",
  "bamber bridge": "بمبر بریج",
  "bury town": "بری تاون",
  "evesham united": "ایوشام یونایتد",
  "chippenham town": "چیپنهم تاون",
  "cf calamocha": "کالاموچا",
  "ce europa": "اوریوپا",
  "sestao": "سستائو",
  "castellonense": "کاستلوننس",
  "atlético tordesillas": "اتلتیکو تردسیاس",
  "ciudad lucena": "سیوداد لوچنا",
  "rayo majadahonda": "رایو ماخاداهوندا",
  "gimnástica segoviana": "خیمناستیکا سگوویانا",
  "cultural leonesa": "کولتورال لئونسا",
  "rsd alcalá": "آلکالا",
  "ud llanera": "لانرا",
  "ponferradina": "پونفرادینا",
  "ce manresa": "مانرسا",
  "sant andreu": "سنت آندرئو",
  "don benito": "دون بنیتو",
  "cd extremadura": "اکسترمادورا",
  "arosa sc": "آروسا",
  // cycle-435: harvest batch 4 — the machine continues on the 435 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 2108 distinct = the
  // documented 432 post-census; scripts/cycle435-batch4-verify.py byte-identity
  // gate, live UA Chrome/124): this batch takes the 55 count-3 single-country
  // names of the England non-league tranche (National League + North/South +
  // Isthmian + Northern/Southern Premier — the ای‌اف‌سی/تاون/یونایتد
  // suffix-keeping style, & → و per the batch-3 convention, of → اوف per the
  // hill-of-beath precedent), 165 live leak rows covered. The count≤2 tail
  // stays honest-raw: the Baller League novelty names (VZN FC, P17 FC, N5
  // FC…) and the (W) women's sides (no (W) surface convention yet — the
  // London City Lionesses tranche waits for one). Loud-pool rule: the
  // documented 2108 census shrinks by this batch in the open (the B4 ±25
  // band re-anchors with the next census, never silently).
  "afc telford united": "ای‌اف‌سی تلفورد یونایتد",
  "afc totton": "ای‌اف‌سی تاتون",
  "alfreton town": "آلفرتون تاون",
  "ashton united": "اشتون یونایتد",
  "aveley": "ایولی",
  "avro": "آورو",
  "basingstoke": "باسینگ‌استوک",
  "bath city": "بث سیتی",
  "billericay": "بیلریکی",
  "boston united": "بوستون یونایتد",
  "brackley town": "براکلی تاون",
  "buxton": "باکستون",
  "chesham united": "چشام یونایتد",
  "cheshunt": "چشانت",
  "chester fc": "چستر",
  "chorley": "چورلی",
  "cleethorpes town": "کلیتورپس تاون",
  "dagenham & redbridge": "داگنم و ردبریج",
  "darlington": "دارلینگتون",
  "dartford": "دارتفورد",
  "dorking wanderers": "دورکینگ واندررز",
  "emley": "املی",
  "fc united of manchester": "اف‌سی یونایتد اوف منچستر",
  "folkestone invicta": "فولکستون اینویکتا",
  "gainsborough": "گینزبورو",
  "gosport borough": "گاسپورت بورو",
  "hartlepool united": "هارتلپول یونایتد",
  "hednesford": "هدنسفورد",
  "horsham": "هورشام",
  "ilkeston town": "ایلکستون تاون",
  "king's lynn town": "کینگز لین تاون",
  "leighton town": "لیتون تاون",
  "maidenhead united": "میدنهد یونایتد",
  "maidstone united": "میدستون یونایتد",
  "maldon & tiptree": "مالدون و تیپتری",
  "malvern town": "مالورن تاون",
  "merthyr town": "مرثر تاون",
  "redcar athletic": "ردکار اتلتیک",
  "scarborough athletic": "اسکاربرو اتلتیک",
  "slough town": "اسلاو تاون",
  "south shields": "ساوت شیلدز",
  "southport": "ساوت‌پورت",
  "spalding united": "اسپالدینگ یونایتد",
  "spennymoor town fc": "اسپنی‌مور تاون",
  "stockton town": "استوکتون تاون",
  "taunton town": "تاونتون تاون",
  "three bridges": "تری بریجز",
  "tonbridge angels": "تونبریج انجلس",
  "warrington rylands": "وارینگتون رایلندز",
  "warrington town": "وارینگتون تاون",
  "weston super mare": "وستون سوپر مار",
  "wingate & finchley": "وینگیت و فینچلی",
  "woking": "ووکینگ",
  "workington": "ورکینگتون",
  "worthing": "ورتینگ",
  // cycle-436: harvest batch 5 — the machine continues on the 436 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 2053 distinct = the
  // documented 435 post-census; scripts/cycle436-batch5-verify.py byte-identity
  // gate, live UA Chrome/124): this batch takes the 40 count-3 single-country
  // names of the Spain Copa del Rey / Federaciones tranche (Primera/Segunda
  // Federacion groups + LaLiga2 — the خ/س Spanish letter conventions of the
  // batch-3 block: Cartagena→کارتاخنا, Náxara→ناخارا, Ourense→اورنسه),
  // 120 live leak rows covered. Prefix discipline follows the map: CD/SD/UD/
  // RS/CDA/AD/CS drop (رئال kept, the Real- is identity), bare-city renders
  // per the rsd-alcalá precedent (سئوتا، کوریا، زامورا). «Logroñés» and
  // «SD Logroñés» are two feed spellings of one club — one value (لاگرونیس),
  // the batch's single intentional value-dup. The (W) women's sides stay
  // honest-raw per the 435 skip line (no (W) surface convention yet).
  // Loud-pool rule: the documented 2053 census shrinks by this batch in the
  // open (the B4 ±25 band re-anchors with the next census, never silently).
  "ad ceuta fc": "سئوتا",
  "alcoyano": "آلکویانو",
  "antequera": "آنتکرا",
  "atlético baleares": "اتلتیکو بائلارس",
  "barakaldo": "باراکالدو",
  "cd atlético paso": "اتلتیکو پاسو",
  "cd badajoz": "باداخوس",
  "cd coria": "کوریا",
  "cda águilas fc": "آگیلاس",
  "cs puertollano": "پوئرتویانو",
  "cartagena": "کارتاخنا",
  "cieza": "سیزا",
  "conquense": "کونکنسه",
  "coruxo fc": "کوروشو",
  "córdoba": "کوردوبا",
  "deportiva minera": "دپورتیوا مینرا",
  "eldense": "الدنسه",
  "logroñés": "لاگرونیس",
  "mijas-las lagunas": "میخاس لاس لاگوناس",
  "numancia": "نومانسیا",
  "náxara": "ناخارا",
  "peña sport": "پنیا اسپورت",
  "poblense": "پوبلنسه",
  "pontevedra": "پونته‌ودرا",
  "portugalete": "پورتوالته",
  "rs gimnástica": "خیمناستیکا",
  "rayo cantabria": "رایو کانتابریا",
  "real jaén": "رئال خائن",
  "real unión": "رئال یونیون",
  "real ávila": "رئال آویلا",
  "recreativo huelva": "رکراتیوو اوئلوا",
  "reus": "ریوس",
  "sd amorebieta": "آموربیتا",
  "sd logroñés": "لاگرونیس",
  "san sebastian de los reyes": "سان سباستیان د لوس ریس",
  "tudelano": "تودلانو",
  "ud ourense": "اورنسه",
  "utebo": "اوتبو",
  "xerez": "خرز",
  "zamora": "زامورا",
  // cycle-437: harvest batch 6 — the machine continues on the 437 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 2013 distinct = the
  // documented 436 post-census; scripts/cycle437-batch6-verify.py byte-identity
  // gate, live UA Chrome/124): this batch takes the 40 count-3 single-country
  // names of the JAPAN tranche (J2 + J3 — the two WE League women's sides of
  // the 42-name pool, NTV Tokyo Verdy Beleza + Omiya Ardija Ventus, stay
  // honest-raw per the 435 skip line), 120 live leak rows covered.
  // Transliteration: Latin-brand reading in the established J-League block
  // style (کیوتو سانگا/ساگان توسو/گامبا اوساکا precedents) — FC prefix kept
  // (اف‌سی گیفو, the fc-seoul precedent), FC/SC suffix dropped (اهیمه/
  // ایواکی/توچیگی/ساگامیهارا, the kyoto-sanga + macclesfield + 436 prefix
  // discipline), City kept like the batch-4 Town-keeping (توچیگی سیتی),
  // letter brands as identity (ام‌وای‌اف‌سی، آر‌بی — the Red Bull rename,
  // the ای‌اف‌سی ویمبلدون style), یوکوهاما اف‌سی kept whole for
  // disambiguation against یوکوهاما مارینوس (one feed spelling, no dup).
  // Loud-pool rule: the documented 2013 census shrinks by this batch in the
  // open (the B4 ±25 band re-anchors with the next census, never silently).
  "albirex niigata": "آلبیرکس نییگاتا",
  "blaublitz akita": "بلاوبلیتز آکیتا",
  "ehime fc": "اهیمه",
  "fc gifu": "اف‌سی گیفو",
  "fc imabari": "اف‌سی ایماباری",
  "fc osaka": "اف‌سی اوساکا",
  "fc ryūkyū": "اف‌سی ریوکیو",
  "fujieda myfc": "فوجی‌ئدا ام‌وای‌اف‌سی",
  "fukushima united": "فوکوشیما یونایتد",
  "gainare tottori": "گایناره توتوری",
  "giravanz kitakyushu": "گیروانز کیتاکیوشو",
  "hokkaido consadole sapporo": "هوکایدو کونسادوله ساپورو",
  "iwaki fc": "ایواکی",
  "júbilo iwata": "جوبیلو ایواتا",
  "kagoshima united": "کاگوشیما یونایتد",
  "kamatamare sanuki": "کاماتاماره سانوکی",
  "kataller toyama": "کاتارله تویاما",
  "kochi united sc": "کوشی یونایتد",
  "matsumoto yamaga": "ماتسوموتو یاماگا",
  "mito hollyhock": "میتو هولیهوک",
  "montedio yamagata": "مونتدیو یاماگاتا",
  "nagano parceiro": "ناگانو پارسه‌یرو",
  "nara club": "نارا کلاب",
  "oita trinita": "اویتا ترینیتا",
  "rb omiya ardija": "آر‌بی اومیا آردیجا",
  "reilac shiga": "ریلاک شیگا",
  "renofa yamaguchi": "رنوفا یاماگوچی",
  "roasso kumamoto": "روآسو کوماموتو",
  "sc sagamihara": "ساگامیهارا",
  "shonan bellmare": "شونان بلماره",
  "tegevajaro miyazaki": "تگه‌وا جارو میازاکی",
  "thespa gunma": "تسپا گونما",
  "tochigi city fc": "توچیگی سیتی",
  "tochigi sc": "توچیگی",
  "tokushima vortis": "توکوشیما وورتیس",
  "vanraure hachinohe": "ون‌راوره هاچینوهه",
  "vegalta sendai": "وگالتا سندای",
  "ventforet kofu": "ونت‌فورت کوفو",
  "yokohama fc": "یوکوهاما اف‌سی",
  "zweigen kanazawa": "زوایگن کانازاوا",

  // cycle-440: harvest batch 7 — the machine continues on the 440 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 1973 distinct = the
  // documented 437 post-census, totalRows 3948 — zero window drift;
  // scripts/cycle440-batch7-verify.py byte-identity gate, live UA Chrome/124):
  // this batch takes ALL 30 count-3 single-country names of the SCOTLAND
  // tranche (Challenge Cup 13 + FA Cup 1 + Lowland League East/West 16 — the
  // live ±7 window's biggest single-country pool; no (W) women's sides, no
  // exclusions), 90 live leak rows covered. The 437/439 rotation line named
  // NOR 124 as the next pool, but the live window re-rank (the 435 lesson:
  // rows drift, the window decides) shows NOR at 11 — SCO 30 is the honest
  // pick. Transliteration: تاون/یونایتد/سیتی suffix-keeping per the batch-4/5
  // discipline (فورمارترین یونایتد، ادینبرو سیتی، الجین سیتی، برخین سیتی),
  // Rangers/Hearts/Rovers/Albion/Athletic per the standing renders (کو
  // رنجرز/کلتی هارتس/آلبیون روورز/استیرلینگ آلبیون/انان اتلتیک — the
  // stafford-rangers + heart-of-midlothian + burton-albion + wigan-athletic
  // precedents), FC/SC suffix dropped (استیرلینگ یونیورسیتی، رنفرو، گرتنا
  // ۲۰۰۸ — the kyoto-sanga + 436 prefix discipline; the year kept in Persian
  // digits like the 57 existing digit-bearing values), Queen of the South →
  // کویین اوف ساوت (the کویینز پارک رنجرز reading), and the two NEW Scottish
  // suffix anchors: Thistle → تیسل (لارگس تیسل، اینورنس کالدونین تیسل) and
  // Juniors → جونیورز (ترون جونیورز، کامناک جونیورز — the Scottish junior
  // football identity term), Bo'ness → بونس (the apostrophe is silent).
  // Loud-pool rule: the documented 1973 census shrinks by this batch in the
  // open (the B4 ±25 band re-anchors with the next census, never silently).
  "airdrieonians": "ایردریونینز",
  "albion rovers": "آلبیون روورز",
  "annan athletic": "انان اتلتیک",
  "bo'ness united": "بونس یونایتد",
  "brechin city": "برخین سیتی",
  "broxburn athletic": "بروکسبرن اتلتیک",
  "caledonian braves": "کالدونیان بریوز",
  "civil service strollers": "سیویل سرویس استرولرز",
  "clyde": "کلاید",
  "cove rangers": "کو رنجرز",
  "cumnock juniors": "کامناک جونیورز",
  "east kilbride": "ایست کیلبراید",
  "east stirlingshire": "ایست استیرلینگشایر",
  "edinburgh city": "ادینبرو سیتی",
  "elgin city": "الجین سیتی",
  "formartine united": "فورمارترین یونایتد",
  "gala fairydean rovers": "گالا فیریدین روورز",
  "greenock morton": "گرینوک مورتون",
  "gretna fc 2008": "گرتنا ۲۰۰۸",
  "inverness caledonian thistle": "اینورنس کالدونین تیسل",
  "kelty hearts": "کلتی هارتس",
  "largs thistle": "لارگس تیسل",
  "linlithgow rose": "لینلیتگو روز",
  "newton stewart": "نیوتن استوارت",
  "peterhead": "پیترهد",
  "queen of the south": "کویین اوف ساوت",
  "renfrew fc": "رنفرو",
  "stirling albion": "استیرلینگ آلبیون",
  "stirling university fc": "استیرلینگ یونیورسیتی",
  "troon juniors": "ترون جونیورز",

  // cycle-441: harvest batch 8 — the machine continues on the 441 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 1943 distinct = the
  // documented 440 post-census, totalRows 3948 — zero window drift;
  // scripts/cycle441-batch8-verify.py byte-identity gate, live UA Chrome/124):
  // this batch takes ALL 18 count-3 single-country names of the PERU tranche
  // (every one from Liga 1 — the live ±7 window's biggest single-country pool,
  // exactly as the 440 card's rotation line predicted: PER 18 > ROU 16 >
  // COL 13 > RUS 12; no (W) women's sides, no exclusions), 54 live leak rows
  // covered. Transliteration: the Spanish-block conventions — دپورتیوو
  // (دپورتیوو گارسیلاسو, the táchira precedent), اتلتیکو (اتلتیکو گراو، الیانزا
  // اتلتیکو — the ناسیونال/مینیرو/بائلارس precedents), اسپورتینگ (اسپورتینگ
  // کریستال — the براگا/کوویلیا/خیخون precedents), the Spanish «de» as د
  // (یونیورسیتاریو د دپورته‌س — the راسینگ د فرول precedent), prefix/suffix
  // discipline: ADC/CD/FBC/CUSCO-FC dropped (خوان پابلوی دوم، موکگوا، ملگار،
  // کوسکو — the 436 prefix rule + the bare-city rsd-alcalá render), FC
  // Cajamarca → کاخامارکا bare vs CD UT Cajamarca → یوتی کاخامارکا (the UT
  // letter brand kept per the ام‌وای‌اف‌سی/آر‌بی letter-identity rule — one
  // club each, distinct renders, no collision), ADT as the letter brand
  // (ای‌دی‌تی تارما — the club's universal initials), الیانزا as the new
  // Alianza anchor (الیانزا لیما، الیانزا اتلتیکو). Loud-pool rule: the
  // documented 1943 census shrinks by this batch in the open (the B4 ±25 band
  // re-anchors with the next census, never silently).
  "adc juan pablo ii": "خوان پابلوی دوم",
  "alianza atlético": "الیانزا اتلتیکو",
  "alianza lima": "الیانزا لیما",
  "asociación deportiva tarma": "ای‌دی‌تی تارما",
  "atlético grau": "اتلتیکو گراو",
  "cd ut cajamarca": "یوتی کاخامارکا",
  "cienciano": "سینسینو",
  "club deportivo moquegua": "موکگوا",
  "comerciantes unidos": "کامرسیانته‌س یونیدوس",
  "cusco fc": "کوسکو",
  "deportivo garcilaso": "دپورتیوو گارسیلاسو",
  "fbc melgar": "ملگار",
  "fc cajamarca": "کاخامارکا",
  "los chankas": "لوس چانکاس",
  "sport boys": "اسپورت بویز",
  "sport huancayo": "اسپورت هوانکایو",
  "sporting cristal": "اسپورتینگ کریستال",
  "universitario de deportes": "یونیورسیتاریو د دپورته‌س",

  // cycle-442: harvest batch 9 — the machine continues on the 442 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 1925 distinct = the
  // documented 441 post-census, totalRows 3948 on the census read; the pool
  // sweep's row count drifted (3651) but the DISTINCT pool stayed byte-stable
  // — the 435 lesson: rows drift, distinct is decisive;
  // scripts/cycle442-batch9-verify.py byte-identity gate, live UA Chrome/124):
  // this batch takes ALL 16 count-3 single-country names of the ROMANIA
  // tranche (Cup Grp. A-D + Liga II + Superliga — the live ±7 window's
  // biggest single-country pool, exactly as the 440/441 rotation lines
  // predicted: ROU 16 > COL 13 > RUS 12 > GUA 12; no (W) women's sides, no
  // exclusions), 48 live leak rows covered. Transliteration: بخارست (the
  // established Persian exonym for București), دانشگاه (the
  // universitatea-craiova precedent) + کلوژ (the cfr-cluj anchor), the
  // ț/ș comma-below renders (پلویشت، بیستریتا، ترگوویشته، تیمیشوارا — the
  // Persian-Wikipedia readings), the Hungarian cs/sz reading چیکسردا
  // (Csikszereda), prefix/suffix discipline: FC dropped (آرژ پیتشتی، باکائو،
  // بیهور اورادیا، ولونتاری — the 436 rule + the bare-city rsd-alcalá
  // render), letter brands kept (اف‌سی‌اس‌بی — the FCSB initials identity
  // per the ای‌دی‌تی/یوتی letter-brand rule; یوتا آراد — UTA + city).
  // Two documented anchors: رپید بخارست (the press-standard Persian form for
  // the Bucharest club — the older راپید وین render for the Vienna club rides
  // its own block unchanged; two distinct clubs, two distinct renders, no
  // collision), and آرژ پیتشتی as this batch's ONE cross-block value-dup:
  // the older ASCII spelling "fc arges pitesti" (the cup-era block above)
  // already maps to the same render — two upstream spellings, one club, one
  // value (the Logroñés precedent; the live feed serves the comma-below
  // spelling, which the ASCII key can never byte-reach). Loud-pool rule: the
  // documented 1925 census shrinks by this batch in the open (the B4 ±25
  // band re-anchors with the next census, never silently).
  "asu politehnica timișoara": "آسو پلی‌تکنیکا تیمیشوارا",
  "chindia târgoviște": "چیندیا ترگوویشته",
  "concordia chiajna": "کونکوردیا کیاجنا",
  "corvinul hunedoara": "کوروینول هوندوارا",
  "csikszereda miercurea ciuc": "چیکسردا میرکوره چوک",
  "dinamo bucurești": "دینامو بخارست",
  "fc argeș pitesti": "آرژ پیتشتی",
  "fc bacău": "باکائو",
  "fc bihor oradea": "بیهور اورادیا",
  "fcsb": "اف‌سی‌اس‌بی",
  "fc voluntari": "ولونتاری",
  "gloria bistrița": "گلوریا بیستریتا",
  "petrolul ploiești": "پترولول پلویشت",
  "rapid bucurești": "رپید بخارست",
  "universitatea cluj": "دانشگاه کلوژ",
  "uta arad": "یوتا آراد",
  // cycle-445: harvest batch 10 — the machine continues on the 445 census
  // (scripts/cycle430-harvest.py re-run read EXACTLY 1909 distinct = the
  // documented 442 post-census, totalRows 3951 on the census read — the 435
  // lesson: rows drift (3948→3951), distinct is decisive;
  // scripts/cycle445-batch10-verify.py byte-identity gate, live UA Chrome/124):
  // this batch takes ALL 11 count-3 single-country names of the NORWAY
  // tranche (1. Divisjon + Cup + Eliteserien — the live ±7 window's biggest
  // single-country pool; the 442/443 rotation lines predicted COL 13 > RUS
  // 12 > GUA 12 > NOR 11, but the window re-ranked and the rivals dropped
  // under 3 — exactly what the 435 lesson demands: the window decides, the
  // prediction does not; no (W) women's sides, no exclusions), 33 live leak
  // rows covered. Transliteration rides the standing Eliteserien block
  // (the 969/971 renders): ø → و (بودو/ترومسو/لیلهستروم) so Hødd = هود; the
  // site's own aalesund → اوله‌سوند anchor gives Å its /oː/ reading (the
  // Ålesund IPA), so Åsane = اوسانه; Strømsgodset = استرومسگودست (the
  // Persian-Wikipedia article title — this batch's ONE direct fa.wiki
  // anchor); Odds Ballklubb = اودز (the literal genitive s kept — the
  // هارتس/رنجرز/کویینز plural rule — with Ballklubb dropped, the BK/IL/FC
  // suffix-discipline rule, the Rosenborg BK → روزنبورگ precedent);
  // Sandefjord = سانفیورد (fjord → فیورد), Kongsvinger = کونگزوینگر,
  // Ranheim = رانهایم (heim → هایم), Hamarkameratene = هامارکامراتنه (the
  // full feed literal, -tene → تنه), Egersund = اگرسوند, Sogndal = سوگندال,
  // Lyn = لین (the Persian press form for the Oslo club). Collision gate:
  // zero key and zero value collisions against the whole file (every club
  // one distinct render — no Logroñés case this batch). Loud-pool rule: the
  // documented 1909 census shrinks by this batch in the open (the B4 ±25
  // band re-anchors with the next census, never silently).
  "lyn": "لین",
  "åsane": "اوسانه",
  "hødd": "هود",
  "egersund": "اگرسوند",
  "sogndal": "سوگندال",
  "strømsgodset": "استرومسگودست",
  "odds ballklubb": "اودز",
  "sandefjord": "سانفیورد",
  "kongsvinger": "کونگزوینگر",
  "ranheim": "رانهایم",
  "hamarkameratene": "هامارکامراتنه",
  // cycle-446: harvest batch 11 — the machine continues on the 446 census
  // (scripts/cycle430-harvest.py re-run + scripts/c446-pool-sweep.py read
  // EXACTLY 1890 distinct = the documented 445 post-census on both reads,
  // rows drifted 3951→3568 between them — the 435 lesson again: rows drift,
  // distinct is decisive; scripts/c446-batch11-verify.py byte-identity gate,
  // live UA Chrome/124): this batch takes ALL 13 single-country names with
  // count>=3 of the COLOMBIA tranche (11 count-3 + Envigado/Unión Magdalena
  // at count-4 — Primera A + Primera B; the 445 rotation line predicted the
  // KSA/AUT/ISR segment to lead but the window re-ranked again and RUS/GUA
  // tied 12 while COL's count≥3 singles reached 13 names/41 live leak rows —
  // the 435 lesson: the window decides, the prediction does not; no (W)
  // women's sides, no exclusions), 41 live leak rows covered. The count>=4
  // multi-country names stay honest-raw (Alianza FC 10/Santa Fe/Libertad/
  // Universidad Católica/Olimpia — the 389 identity-first rule). Transliteration
  // rides this file's own Spanish block: Unión → یونیون (the real unión →
  // رئال یونیون anchor) so Unión Magdalena = یونیون ماگدالنا (fa.wiki
  // «ماگدالنا»); Boca Juniors de Cali = بوکا جونیورز دی کالی (the file's
  // boca juniors → بوکا جونیورز anchor); Deportivo → دپورتیوو (the
  // deportivo pasto → دپورتیوو پاستو COLOMBIAN anchor) so Deportivo Pereira =
  // دپورتیوو پریرا (fa.wiki «پریرا (کلمبیا)»); Independiente → ایندپندینته
  // (the independiente medellín → ایندپندینته مدئین COLOMBIAN anchor) with
  // Valle → وایه riding the file's v→و rule (والنسیا/ویارئال/سلتاویگو/رایو
  // وایکانو) so Independiente Valle del Cauca = ایندپندینته وایه دل کائوکا;
  // Real + toponym full-space (the رئال اویدو/ساراگوسا/خائن rule) so Real
  // Cartagena = رئال کارتاخنا (fa.wiki «کارتاخنا (کلمبیا)» — the j → خ rule)
  // and Real Cundinamarca = رئال کوندینامارکا; Águilas → آگیلاس (the cda
  // águilas fc → آگیلاس anchor) so Águilas Doradas = آگیلاس دوراداس. THREE
  // direct fa.wiki anchors this batch: «انویگادو» (Envigado), «آمریکا د کالی»
  // (América de Cali — the article title spells de → د), «کارتاخنا (کلمبیا)».
  // The FC suffix-discipline rule (the 445 Ballklubb precedent, junior fc →
  // جونیور) drops FC: Chicó FC = چیکو (fa.wiki «چیکو»), Fortaleza FC =
  // فورتالسا (the Persian press form), Tigres FC = تیگرس (the Tigres UANL
  // press form). Deportes Quindío = دپورتیس کیندیو (Deportes plural →
  // دپورتیس; Quindío → کیندیو). Collision gate: zero key and zero value
  // collisions against the whole file (every club one distinct render —
  // «کارتاخنا» alone is FC Cartagena's, ours is «رئال کارتاخنا»). Loud-pool
  // rule: the documented 1890 census shrinks by this batch in the open (the
  // B4 ±25 band re-anchors with the next census, never silently).
  "envigado": "انویگادو",
  "unión magdalena": "یونیون ماگدالنا",
  "américa de cali": "آمریکا د کالی",
  "boca juniors de cali": "بوکا جونیورز دی کالی",
  "chicó fc": "چیکو",
  "deportes quindío": "دپورتیس کیندیو",
  "deportivo pereira": "دپورتیوو پریرا",
  "fortaleza fc": "فورتالسا",
  "independiente valle del cauca": "ایندپندینته وایه دل کائوکا",
  "real cartagena": "رئال کارتاخنا",
  "real cundinamarca": "رئال کوندینامارکا",
  "tigres fc": "تیگرس",
  "águilas doradas": "آگیلاس دوراداس",
  // cycle-447: harvest batch 12 — the machine continues on the 447 census
  // (scripts/cycle430-harvest.py + scripts/c447-pool-sweep.py read EXACTLY
  // 1877 distinct = the documented 446 post-census in BOTH reads, zero drift;
  // rows drifted 3951→3527 — the 435 lesson: rows drift, distinct is
  // decisive; scripts/c447-batch12-verify.py byte-identity gate, live UA
  // Chrome/124): this batch takes ALL 12 count-3 single-country names of the
  // RUSSIA tranche (Premier League + Cup Grp. A-D). The window's tie with
  // GUA (12 names/36 rows/36 day-presence EACH — the honest read) broke on
  // anchor quality + visibility: this is the biggest-club pool in the map's
  // history (Spartak/CSKA/Lokomotiv Moscow, Krasnodar, Rubin) and every name
  // carries a direct Persian-Wikipedia anchor, while GUA is one league with
  // weak anchors — GUA stays next in line, the window decides next cycle
  // (the 435 lesson). The count>=4 multi-country names stay honest-raw
  // (Alianza FC 10/Santa Fe/Libertad/Universidad Católica/Olimpia — the 389
  // identity-first rule; singles Goiás/MB Rouissat wait for their tranches).
  // Transliteration rides the Persian-Wikipedia club articles (SEVEN direct
  // hits this batch — the map's richest): «باشگاه فوتبال اسپارتاک مسکو» (the
  // article spells it اسپارتاک with leading ا — the Persian sp→اسپ rule:
  // اسپانیا/اسپورتینگ), «باشگاه فوتبال زسکا مسکو» (زسکا — the Russian club's
  // fa.wiki title; the file's cska sofia → سسکا صوفیه is the BULGARIAN
  // community's spelling, the divergence is the encyclopedia's own),
  // «باشگاه فوتبال لوکوموتیو مسکو», «باشگاه فوتبال کراسنودار» (FC dropped —
  // the suffix-discipline rule), «باشگاه فوتبال روبین کازان», «باشگاه
  // فوتبال دینامو مخاچ‌قلعه» (the ZWNJ is byte-exact from the city article
  // «مخاچ‌قلعه»; Dynamo → دینامو rides the دینامو درسدن anchor — the
  // Houston MLS داینامو is the English club's own reading), «باشگاه فوتبال
  // بالتیکا کالینینگراد» (Baltika → بالتیکا), «باشگاه فوتبال اورنبورگ» (FC
  // dropped), «باشگاه فوتبال فاکل وورونژ» (the encyclopedia's وورونژ with
  // the DOUBLE و for Russian В — the literal is bare Fakel so the render is
  // فاکل). No fa.wiki article for Krylya Sovetov → کرلیا سوفیتوف سامارا (the
  // Persian press form; the toponym IS in the literal — fa.wiki «سامارا»);
  // Akron Togliatti → آکرون تولیاتی (fa.wiki «تولیاتی»); FK Akhmat → اخمت
  // گروزنی (the Persian press form + the file's crvena-zvezda → ستاره سرخ
  // بلگراد add-toponym precedent; the club's fa.wiki article is «احمد
  // گروزنی» — the renamed Terek, same club, the render keeps the feed's own
  // Akhmat transliteration). Collision gate: zero key and zero value
  // collisions against the whole file (no Logroñés case this batch).
  // Loud-pool rule: the documented 1877 census shrinks by this batch in the
  // open (the B4 ±25 band re-anchors with the next census, never silently).
  "spartak moscow": "اسپارتاک مسکو",
  "cska moscow": "زسکا مسکو",
  "lokomotiv moscow": "لوکوموتیو مسکو",
  "fc krasnodar": "کراسنودار",
  "rubin kazan": "روبین کازان",
  "dynamo makhachkala": "دینامو مخاچ‌قلعه",
  "krylya sovetov samara": "کرلیا سوفیتوف سامارا",
  "baltika": "بالتیکا",
  "fakel": "فاکل",
  "fk akhmat": "اخمت گروزنی",
  "akron togliatti": "آکرون تولیاتی",
  "fc orenburg": "اورنبورگ",
  // cycle-450: harvest batch 13 — the machine continues on the 450 census
  // (scripts/c450-pool-sweep.py read EXACTLY 1864 distinct = the documented
  // 449 post-census in the live ±7 walk, ZERO distinct drift for the second
  // consecutive cycle; rows drifted to 3482 — the 435 lesson: rows drift,
  // distinct is decisive; scripts/c450-batch13-verify.py byte-identity gate,
  // live UA Chrome/124: 12/12 verified=0 bad): this batch takes ALL 12
  // count-3 single-country names of the GUATEMALA tranche (Liga Nacional
  // Apertura) — exactly what the 447/448 rotation lines predicted («GUA ۱۲
  // در نوبت است») and the window now delivers: GUA 12 names/36 rows >
  // CYP 11/33 = THA 11/33; no (W) women's sides, no exclusions. The
  // count>=4 multi-country names stay honest-raw (Alianza FC 10
  // COL/INT/PAN/SLV, Santa Fe COL/INT, Libertad ECU/PAR, Universidad
  // Católica CHI/ECU, Olimpia INT/PAR, BK Häcken (W) INT/SWE — the 389
  // identity-first rule; the single MB Rouissat ALG waits for its tranche).
  // Transliteration rides NINE direct Persian-Wikipedia anchors (the map's
  // new record, batch 12's seven beaten): «باشگاه فوتبال آنتیگوا گواتمالا»,
  // «باشگاه فوتبال آئورورا» (Aurora — FC dropped, the 445/446
  // suffix-discipline rule), «باشگاه فوتبال کوبان ایمپریال», «باشگاه
  // فوتبال کامیونیکیشنس» (Comunicaciones — the article is the GUATEMALAN
  // club, Los Cremas 1949; the encyclopedia's own spelling rides the 447
  // زسکا rule, the press کومونیکاسیونس forms stay press; FC dropped),
  // «باشگاه فوتبال مونیسیپال» (the extract opens «در گواتمالاسیتی،
  // گواتمالا» — the Guatemala club; CSD dropped like cd olimpia → المپیا;
  // the file's مونیسیپال پرز زلدون anchor concurs), «باشگاه فوتبال
  // دپورتیوو مالاکاتکو» (the article lead's own spelling — its slug-title
  // is the مالاکاتیکو variant; footba11's مالاکاتکو concurs), «باشگاه
  // فوتبال دپورتیوو مارکوئنزه», «باشگاه فوتبال دپورتیوو میسکو»,
  // «گواستاتویا» (the toponym anchor). No article: CD Suchitepéquez →
  // سوچیتپکز (CD dropped like cd nacional → ناسیونال; the -péquez → پکز
  // fold rides the Spanish -ez convention: میراندس/پرز); Club Xelajú →
  // شلاخو (the Persian live-score press form — footba11 and hazaran both
  // serve شلاخو for this exact fixture; Club dropped like club deportivo
  // moquegua → موکگوا; the bookmaker machine form ژلاجو is not press);
  // San Pedro → سن پدرو (footba11's own team-page title «سن پدرو»;
  // scoreyab's «دپورتیوو سن پدرو» confirms the club). Collision gate: zero
  // key and zero value collisions against the whole file (each render one
  // distinct string — no Logroñés case this batch).
  // Loud-pool rule: the documented 1864 census shrinks by this batch in the
  // open (the B4 band re-anchors with the next census, never silently).
  "antigua guatemala": "آنتیگوا گواتمالا",
  "aurora fc": "آئورورا",
  "cd suchitepéquez": "سوچیتپکز",
  "club xelajú": "شلاخو",
  "coban imperial": "کوبان ایمپریال",
  "comunicaciones fc": "کامیونیکیشنس",
  "csd municipal": "مونیسیپال",
  "deportivo malacateco": "دپورتیوو مالاکاتکو",
  "deportivo marquense": "دپورتیوو مارکوئنزه",
  "deportivo mixco": "دپورتیوو میسکو",
  "guastatoya": "گواستاتویا",
  "san pedro": "سن پدرو",
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
  // cycle-387: the bounded suffix-family composer (the 386 F1 structural
  // decision — see the block comment above competitionFaComposed)
  const composed = competitionFaComposed(n, cc);
  if (composed) return composed;
  // ui-cycle-4: MLS Next Pro playoff phases beyond the exact key above
  if (n.startsWith("mls next pro")) return "لیگ نکست پرو آمریکا";
  return name;
}

// names whose translation depends on the country
const AMBIGUOUS_NAMES = new Set([
  "premier league", "serie a", "super league", "pro league", "first division",
  "championship", "prva liga", "first league", "fa cup", "super lig", "league one", "league two",
  "premiership",
]);

const COMPETITION_FA_CC: Record<string, string> = {
  "premier league|ENG": "پریمیرلیگ انگلیس",
  "serie a|ITA": "سری‌آ ایتالیا",
  "super league|GRE": "سوپرلیگ یونان",
  // cycle-160: the day feed serves bare «Super League» for Switzerland too
  // (probed 2026-10-31/11-01 ccode=SUI) — country-qualified like Greece
  "super league|SUI": "سوپرلیگ سوئیس",
  "pro league|BEL": "لیگ بلژیک",
  "pro league|SAU": "لیگ حرفه‌ای عربستان",
  "first division|CYP": "دسته اول قبرس",
  "fa cup|ENG": "جام حذفی انگلیس",
  "super lig|TUR": "سوپرلیگ ترکیه",
  "championship|ENG": "چمپیونشیپ انگلیس",
  "league one|ENG": "لیگ یک انگلیس",
  "league two|ENG": "لیگ دو انگلیس",
  // cycle-146: the daily feed serves «Premiership» for both Scotland and
  // Northern Ireland — country-keyed Persian names, plain name ambiguous
  "premiership|SCO": "لیگ برتر اسکاتلند",
  "premiership|NIR": "لیگ برتر ایرلند شمالی",
  // ui-cycle-4: youth tier of the premier-league family rides the
  // country-qualified convention (live home feed, ccode=ENG)
  "premier league u18|ENG": "پریمیرلیگ انگلیس زیر ۱۸ سال",

  // ui-cycle-4 batch 3: last confident entries of today's probe
  // (the true remainder is recorded in the cycle card as future work)
  "1. division|DEN": "لیگ یک دانمارک",
  "1. lig|TUR": "لیگ یک ترکیه",
  "2. division|DEN": "لیگ دو دانمارک",
  "2. divisjon avd. 1|NOR": "دیویژن ۲ نروژ — بخش ۱",
  "2. divisjon avd. 2|NOR": "دیویژن ۲ نروژ — بخش ۲",
  "3. divisjon avd. 1|NOR": "دیویژن ۳ نروژ — بخش ۱",
  "3. divisjon avd. 3|NOR": "دیویژن ۳ نروژ — بخش ۳",
  "3. divisjon avd. 5|NOR": "دیویژن ۳ نروژ — بخش ۵",
  "3. divisjon avd. 6|NOR": "دیویژن ۳ نروژ — بخش ۶",
  "a-league women|AUS": "ای‌لیگ بانوان استرالیا",
  "australian championship grp. a|AUS": "قهرمانی استرالیا — گروه A",
  "australian championship grp. d|AUS": "قهرمانی استرالیا — گروه D",
  "cyprus league|CYP": "لیگ برتر قبرس",
  "division profesional|PAR": "لیگ حرفه‌ای پاراگوئه",
  "eerste divisie|NED": "لیگ یک هلند",
  "erovnuli liga|GEO": "لیگ ملی گرجستان",
  "ettan norra|SWE": "اِتان شمال سوئد",
  "ettan soedra|SWE": "اِتان جنوب سوئد",
  "fa cup|SCO": "جام حذفی اسکاتلند",
  "federal a promotion playoff|ARG": "فدرال آ آرژانتین — پلی‌آف ارتقا",
  "first league|RUS": "لیگ یک روسیه",
  "first professional league|BUL": "لیگ حرفه‌ای اول بلغارستان",
  "fnl|CZE": "اف‌ان‌ال چک",
  "i league|IND": "آی‌لیگ هند",
  "i liga|POL": "لیگ یک لهستان",
  "indian super league|IND": "سوپرلیگ هند",
  "liga 3 zona a|POR": "لیگ ۳ پرتغال — منطقهٔ A",
  "liga 3 zona b|POR": "لیگ ۳ پرتغال — منطقهٔ B",
  "liga de expansión mx|MEX": "لیگ اکسپانسیون مکزیک",
  "second professional league|BUL": "لیگ حرفه‌ای دوم بلغارستان",

  // ui-cycle-4 batch 2: country-qualified entries for the world-feed
  // long tail, keys generated from the LIVE /api/matches probe
  // (2026-10-31 04:34) so upstream spellings match exactly; Persian
  // names curated for well-known competitions only
  "1. liga|CZE": "لیگ یک چک",
  "1. liga|SVK": "لیگ یک اسلواکی",
  "2. bundesliga|GER": "بوندسلیگا ۲ آلمان",
  "2. division|CYP": "لیگ دو قبرس",
  "2. liga|AUT": "لیگ دو اتریش",
  "3. division|DEN": "لیگ ۳ دانمارک",
  "3. liga|GER": "لیگ ۳ آلمان",
  "a lyga|LTU": "ای لیگا لیتوانی",
  "a-league|AUS": "ای‌لیگ استرالیا",
  "botola pro|MAR": "بوطولا پرو مراکش",
  "championship|SCO": "چمپیونشیپ اسکاتلند",
  "china league|CHN": "لیگ چین",
  "damallsvenskan|SWE": "لیگ برتر بانوان سوئد",
  "eliteserien|NOR": "الیته‌سریان نروژ",
  "elitettan|SWE": "لیگ یک بانوان سوئد",
  "highland league|SCO": "لیگ هایلند اسکاتلند",
  "ii liga|POL": "لیگ دو لهستان",
  "isthmian premier division|ENG": "دستهٔ برتر ایستمین انگلیس",
  "j. league 2|JPN": "جی‌لیگ ۲ ژاپن",
  "j. league 3|JPN": "جی‌لیگ ۳ ژاپن",
  "j. league|JPN": "جی‌لیگ ژاپن",
  "k league 2|KOR": "کلیگ ۲ کره جنوبی",
  "k-league 1 final group a|KOR": "کلیگ ۱ کره جنوبی — فینال گروه A",
  "k-league 1 final group b|KOR": "کلیگ ۱ کره جنوبی — فینال گروه B",
  "k3 league|KOR": "کی۳ لیگ کره جنوبی",
  "laliga2|ESP": "لالیگا ۲ اسپانیا",
  "league cup|SCO": "جام اتحادیه اسکاتلند",
  "league one|SCO": "لیگ یک اسکاتلند",
  "league two|SCO": "لیگ دو اسکاتلند",
  "liga 1|PER": "لیگ ۱ پرو",
  "liga auf uruguaya clausura|URU": "لیگ برتر اروگوئه — کلاسورا",
  "liga f|ESP": "لیگ برتر بانوان اسپانیا",
  "liga ii|ROU": "لیگ ۲ رومانی",
  "liga nacional - apertura|HON": "لیگ ملی هندوراس — آپرتورا",
  "liga profesional|ARG": "لیگ حرفه‌ای آرژانتین",
  "ligat ha'al|ISR": "لیگ برتر اسرائیل",
  "ligue 2|FRA": "لیگ ۲ فرانسه",
  "ligue 3|FRA": "لیگ ۳ فرانسه",
  "lowland league east|SCO": "لیگ لولند شرق اسکاتلند",
  "lowland league west|SCO": "لیگ لولند غرب اسکاتلند",
  "lpf apertura|PAN": "لیگ فوتبال پاناما — آپرتورا",
  "major league soccer|USA": "لیگ حرفه‌ای آمریکا",
  "national division|LUX": "نشنال دیویژن لوکزامبورگ",
  "national league championship|NZL": "نشنال لیگ نیوزیلند — دور قهرمانی",
  "national league north|ENG": "نشنال لیگ شمال انگلیس",
  "national league south|ENG": "نشنال لیگ جنوب انگلیس",
  "national league|ENG": "نشنال لیگ انگلیس",
  "nb ii|HUN": "لیگ دو مجارستان",
  "nb i|HUN": "لیگ برتر مجارستان",
  "northern premier division|ENG": "دستهٔ برتر شمالی انگلیس",
  "northern super league - championship - semi-finals|CAN": "سوپرلیگ شمالی کانادا — نیمه‌نهایی",
  "npfl|NGA": "لیگ برتر نیجریه",
  "premier league|ARM": "لیگ برتر ارمنستان",
  "premier league|AZE": "لیگ برتر آذربایجان",
  "premier league|BIH": "لیگ برتر بوسنی و هرزگوین",
  "premier league|BLR": "لیگ برتر بلاروس",
  "premier league|EGY": "لیگ برتر مصر",
  "premier league|FRO": "لیگ برتر جزایر فارو",
  "premier league|GHA": "لیگ برتر غنا",
  "premier league|KAZ": "لیگ برتر قزاقستان",
  "premier league|KUW": "لیگ برتر کویت",
  "premier league|RUS": "لیگ برتر روسیه",
  "premier league|SIN": "لیگ برتر سنگاپور",
  "premier league|TAN": "لیگ برتر تانزانیا",
  "premier league|UKR": "لیگ برتر اوکراین",
  "premier league|WAL": "لیگ برتر ولز",
  "premier soccer league|RSA": "لیگ برتر آفریقای جنوبی",
  "premium liiga|EST": "لیگ برتر استونی",
  "primera a|COL": "پریمرا آ کلمبیا",
  "primera b metropolitana|ARG": "پریمرا بی متروپولیتانا آرژانتین",
  "primera b|CHI": "پریمرا بی شیلی",
  "primera division - apertura|SLV": "لیگ برتر السالوادور — آپرتورا",
  "primera division apertura|CRC": "لیگ برتر کاستاریکا — آپرتورا",
  "primera división|BOL": "لیگ برتر بولیوی",
  "primera división|CHI": "لیگ برتر شیلی",
  "primera división|VEN": "لیگ برتر ونزوئلا",
  "primera federacion - group 1|ESP": "پریمرا فدراسیون اسپانیا — گروه ۱",
  "primera federacion - group 2|ESP": "پریمرا فدراسیون اسپانیا — گروه ۲",
  "prva liga|SVN": "لیگ برتر اسلوونی",
  "qatar stars league|QAT": "لیگ ستارگان قطر",
  "regionalliga bayern|GER": "رگیونال‌لیگا آلمان — باواریا",
  "regionalliga northeast|GER": "رگیونال‌لیگا آلمان — شمال شرق",
  "regionalliga north|GER": "رگیونال‌لیگا آلمان — شمال",
  "regionalliga southwest|GER": "رگیونال‌لیگا آلمان — جنوب غرب",
  "regionalliga west|GER": "رگیونال‌لیگا آلمان — غرب",
  "segunda division|URU": "سگوندا دیویسیون اروگوئه",
  "segunda federacion - group 1|ESP": "سگوندا فدراسیون اسپانیا — گروه ۱",
  "segunda federacion - group 2|ESP": "سگوندا فدراسیون اسپانیا — گروه ۲",
  "segunda federacion - group 3|ESP": "سگوندا فدراسیون اسپانیا — گروه ۳",
  "segunda federacion - group 5|ESP": "سگوندا فدراسیون اسپانیا — گروه ۵",
  "serie a - championship round|ECU": "سری آ اکوادور — دور قهرمانی",
  "serie a - copa sudamericana play-off|ECU": "سری آ اکوادور — پلی‌آف سودامریکانا",
  "serie a - relegation round|ECU": "سری آ اکوادور — دور سقوط",
  "serie a femminile|ITA": "سری آ بانوان ایتالیا",
  "serie b|ITA": "سری بی ایتالیا",
  "serie c grp. a|ITA": "سری سی ایتالیا — گروه A",
  "serie c grp. b|ITA": "سری سی ایتالیا — گروه B",
  "serie c grp. c|ITA": "سری سی ایتالیا — گروه C",
  "southern premier division central|ENG": "دستهٔ برتر جنوبی — مرکز انگلیس",
  "southern premier division south|ENG": "دستهٔ برتر جنوبی — جنوب انگلیس",
  "stars league|IRQ": "لیگ برتر عراق",
  "super league 2|GRE": "سوپرلیگ ۲ یونان",
  "super league|IDN": "سوپرلیگ اندونزی",
  "super liga|MDA": "سوپر لیگ مولداوی",
  "super liga|SRB": "سوپر لیگ صربستان",
  "superettan|SWE": "سوپرتان سوئد",
  "superliga|ROU": "سوپرلیگ رومانی",
  "superliga|UZB": "سوپرلیگ ازبکستان",
  "série a|BRA": "سری آ برزیل",
  "série b|BRA": "سری بی برزیل",
  "thai league 2|THA": "لیگ ۲ تایلند",
  "thai league|THA": "لیگ برتر تایلند",
  "toppserien qualification|NOR": "لیگ برتر بانوان نروژ — مقدماتی",
  "toppserien|NOR": "لیگ برتر بانوان نروژ",
  "usl championship playoff|USA": "یواس‌ال چمپیونشیپ آمریکا — پلی‌آف",
  "usl super league|USA": "سوپرلیگ یواس‌ال آمریکا",
  "v-league|VIE": "لیگ برتر ویتنام",
  "we league|JPN": "لیگ بانوان ژاپن",
  "women's league cup|ENG": "جام اتحادیه بانوان انگلیس",
  "wsl|ENG": "سوپرلیگ بانوان انگلیس",

  // cycle-384 (bug-hunt 383 finding F4a): the 18 raw group headers the
  // home day-feed served on the 2026-11-02 probe (date-dependent list —
  // the 383 card documented 17 the day before). Every key is the exact
  // lowercase upstream name + the ccode the feed rides; group letters
  // keep the Latin-letter convention («— گروه A»). The AMBIGUOUS_NAMES
  // gate ("prva liga") makes the country-qualified form mandatory there;
  // the same shape is used throughout for consistency and safety ("cup"
  // alone must never map globally).
  "1. cfl|MNE": "لیگ اول مونته‌نگرو",
  "1. divisjon|NOR": "لیگ یک نروژ",
  "allsvenskan|SWE": "آلوسونسکان سوئد",
  "baller league|ENG": "بالر لیگ",
  "caf women's champions league|INT": "لیگ قهرمانان بانوان آفریقا",
  "cup|CHI": "جام حذفی شیلی",
  "cup|COL": "جام حذفی کلمبیا",
  "kategoria superiore|ALB": "سوپرلیگ آلبانی",
  "league cup grp. a|EGY": "جام اتحادیه مصر — گروه A",
  "league cup grp. c|EGY": "جام اتحادیه مصر — گروه C",
  "leumit league|ISR": "لیگ لومییت اسرائیل",
  "liga nacional apertura|GUA": "لیگ ملی گواتمالا — آپرتورا",
  "prva liga|MKD": "لیگ اول مقدونیه شمالی",
  "primera b|COL": "پریمرا بی کلمبیا",
  "saudi first division|KSA": "دسته اول عربستان",
  "superligaen|DEN": "سوپرلیگ دانمارک",
  // cycle-389: the widened-window (-3..+3) edge bases the 387 composer could
  // not resolve (F1 of the 388 patrol) — live-probed headers at offsets -3/+3
  // (Premier Division|IRL + CONCACAF Central American Cup|INT + SAFF
  // Championship|INT; the «Grp. A/B» suffixes ride the 387 group family).
  "premier division|IRL": "لیگ برتر ایرلند",
  "concacaf central american cup|INT": "جام آمریکای مرکزی کونکاکاف",
  "saff championship|INT": "قهرمانی ساف",
  "usl league one - championship - quarter-finals|USA": "یواس‌ال لیگ یک آمریکا — یک‌چهارم نهایی",
  "veikkausliiga championship group|FIN": "ویکاس‌لییگا فنلاند — گروه قهرمانی",

  // cycle-385: the AFC Asian Cup day-feed shapes — the group stage serves
  // the bare name, the knockout rounds ride the «Final Stage» suffix
  // (probed live: the 2024-02-10 final rode day-tournament 890103 as
  // «Asian Cup Final Stage» cc=INT). Country-qualified like every
  // day-feed entry so the league page and the feed never disagree.
  "asian cup|INT": "جام ملت‌های آسیا",
  "asian cup final stage|INT": "جام ملت‌های آسیا — مرحلهٔ حذفی",

  // cycle-387: the multi-day window's (offset -2..+2) point keys — the bases
  // the suffix-family composer composes from, plus the one-off headers no
  // family reaches. Every Persian name follows the established in-file
  // conventions (جام حذفی X for domestic cups, X — گروه A Latin letter /
  // X — گروه ۴ Persian digit, X — آپرتورا, پلی‌آف ارتقا).
  "eredivisie vrouwen|NED": "اردیویزهٔ زنان هلند",
  "premiere ligue|FRA": "لیگ برتر زنان فرانسه",
  "nwsl|USA": "ان‌دبلیو‌اس‌ال",
  "virsliga|LVA": "ویرسلیگا لتونی",
  "pro league|UAE": "لیگ برتر امارات",
  "premier league|CAN": "لیگ برتر کانادا",
  "challenge league|SUI": "چلنج‌لیگ سوئیس",
  "copa de la reina|ESP": "جام حذفی زنان اسپانیا",
  "copa do brasil|BRA": "جام حذفی برزیل",
  "dbu pokalen|DEN": "جام حذفی دانمارک",
  "ligue i|TUN": "لیگ ۱ تونس",
  "challenge cup|SCO": "جام چلنج اسکاتلند",
  "fa cup|SVK": "جام حذفی اسلواکی",
  "second division|QAT": "دسته دوم قطر",
  "a-liga|DEN": "لیگ A دانمارک",
  "swpl cup|SCO": "جام لیگ زنان اسکاتلند",
  "swpl 1|SCO": "لیگ برتر زنان اسکاتلند",
  "first division promotion playoff|IRL": "پلی‌آف ارتقا دسته اول ایرلند",
  // composer bases — the per-instance keys above (australian championship
  // grp. a/d|AUS, segunda federacion - group 1/2/3/5|ESP, league cup
  // grp. a/c|EGY) proved the erosion class: the next day mints grp. b/c,
  // group 4, grp. b/d. The base + composer heals the whole family with
  // byte-consistent output instead of minting one key per day.
  "australian championship|AUS": "قهرمانی استرالیا",
  "segunda federacion|ESP": "سگوندا فدراسیون اسپانیا",
  "liga de expansión mx - apertura|MEX": "لیگ گسترش مکزیک — آپرتورا",
  "national league cup|ENG": "جام لیگ ملی انگلیس",
  "efl trophy northern|ENG": "جام ای‌اف‌ال شمالی",
  "efl trophy southern|ENG": "جام ای‌اف‌ال جنوبی",
  "league cup|EGY": "جام اتحادیه مصر",
  "league cup|THA": "جام اتحادیه تایلند",
  "league cup|RSA": "جام اتحادیه آفریقای جنوبی",
  "croatian cup|CRO": "جام حذفی کرواسی",
  "uefa youth league|INT": "لیگ جوانان اروپا",
};

// cycle-387: THE structural decision for the day-feed header churn (the 386
// F1 finding): the header list rotates daily (17 raw at offset=-1, 21 at
// +1, 11 at +2 on the probe day) and point-mapping per day erodes — the
// 383 root cause with a new dimension. Instead of minting one key per
// (competition, stage) pair per day, competitionFa now COMPOSES a Persian
// name from a verified base + an explicit suffix table, generalizing the
// exact shapes the keys already established:
//   «X — گروه A» Latin letter (the K1 convention) / «X — گروه ۴» Persian
//   digit / «X — یک‌چهارم نهایی» / «X — پلی‌آف» / bare «Cup|CC» →
//   «جام حذفی {country}» (the 384 cup|CHI/COL family).
// It fires ONLY after the exact-key lookups fail, ONLY when the base
// resolves through the verified maps (CC-qualified first, AMBIGUOUS-guarded
// global next) and ONLY for suffixes in the explicit tables — anything
// else keeps the honest raw passthrough. The mls-next-pro prefix rule
// (ui-cycle-4) predates this and stays.
const CUP_CC_FA: Record<string, string> = {
  chi: "شیلی", col: "کلمبیا", egy: "مصر", cyp: "قبرس", chn: "چین", uru: "اروگوئه",
};

const STAGE_SUFFIX_FA: Record<string, string> = {
  "league stage": "مرحلهٔ لیگی",
  "2nd round": "دور دوم",
  "8th finals": "یک‌شانزدهم نهایی",
  "16th finals": "یک‌سی‌ودویم نهایی",
  "quarter-finals": "یک‌چهارم نهایی",
  "semi-finals": "نیمه‌نهایی",
  "final": "فینال",
  "play-offs": "پلی‌آف",
  "playoff": "پلی‌آف",
  "promotion playoff": "پلی‌آف ارتقا",
  "championship group": "گروه قهرمانی",
  "championship round": "دور قهرمانی",
  "relegation round": "دور سقوط",
  "relegation playoff": "پلی‌آف سقوط",
};

function competitionFaBase(n: string, cc: string): string | null {
  if (cc && COMPETITION_FA_CC[`${n}|${cc}`]) return COMPETITION_FA_CC[`${n}|${cc}`];
  if (AMBIGUOUS_NAMES.has(n)) return null;
  return COMPETITION_FA[n] || null;
}

function competitionFaComposed(n: string, cc: string): string | null {
  // bare national cup: «Cup|CC» → «جام حذفی {country}» — verified whitelist
  if (n === "cup" && cc && CUP_CC_FA[cc.toLowerCase()]) {
    return `جام حذفی ${CUP_CC_FA[cc.toLowerCase()]}`;
  }
  // Norwegian division sections: «3. Divisjon Avd. 2» → «لیگ سه نروژ — بخش ۲»
  const avd = n.match(/^([123])\. divisjon avd\. ([0-9]+)$/);
  if (avd && cc === "NOR") {
    const tier = avd[1] === "1" ? "یک" : avd[1] === "2" ? "دو" : "سه";
    return `لیگ ${tier} نروژ — بخش ${faDigits(avd[2])}`;
  }
  // group suffix: «X Group A / X Grp. B / X - Group 4» → «X — گروه A/۴»
  const grp = n.match(/^(.*?)(?: - |\s)(?:grp\. |group )([a-z0-9]+)$/);
  if (grp) {
    const base = competitionFaBase(grp[1].trim(), cc);
    if (base) {
      const t = grp[2];
      const label = /^[0-9]+$/.test(t) ? faDigits(t) : t.toUpperCase();
      return `${base} — گروه ${label}`;
    }
  }
  // stage suffix: «X - Apertura - Quarter-finals» → «X — آپرتورا — یک‌چهارم نهایی»
  // walk the « - » segments from the RIGHTMOST (shortest) suffix so a
  // chained name finds «quarter-finals» even though «apertura -
  // quarter-finals» (the first split) is not a stage — probed live on
  // «Liga de Expansión MX - Apertura - Quarter-finals» (MEX).
  const segs = n.split(" - ");
  for (let k = segs.length - 1; k >= 1; k--) {
    const stage = STAGE_SUFFIX_FA[segs.slice(k).join(" - ")];
    if (!stage) continue;
    const base = competitionFaBase(segs.slice(0, k).join(" - "), cc);
    if (base) return `${base} — ${stage}`;
  }
  return null;
}

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
  // cycle-159: live feeds also spell youth sides out — «Iceland Under 20»,
  // «Morocco Under 19», «SL Benfica Under 21» all leaked through the bare
  // U-regexes before this line
  { re: /\sunder\s(?:1[789]|20|2[013])$/i, fa: " جوانان" },
  { re: /\s(?:ii|ll)$/i, fa: " دوم" },
  { re: /\s(?:b|2)$/i, fa: " دوم" },
];

export function teamFa(...candidates: (string | undefined)[]): string {
  // cycle-145: Turkish «İ» lowercases to i + COMBINING DOT ABOVE (U+0307) —
  // probed live: «İstanbulspor».toLowerCase() = "i\u0307stanbulspor", which
  // never byte-matches a plain-i key. Strip the combining dot at key build
  // time so every dotted-capital spelling finds its mapping (no TEAM_FA or
  // COUNTRY_FA key legitimately contains U+0307).
  const norm = (s: string) => s.toLowerCase().trim().replace(/\u0307/g, "");
  for (const c of candidates) {
    if (!c) continue;
    const key = norm(c);
    if (TEAM_FA[key]) return TEAM_FA[key];
    // cycle-86: national teams («Norway» → «نروژ») ride the country map —
    // probed via player recentMatches sides (club vs national team rows)
    if (COUNTRY_FA[key]) return COUNTRY_FA[key];
    // cycle-380: cup-bracket undrawn slots ALSO arrive spelled out as
    // «Winner QF 1» / «Winner SF 2» — Coppa Italia serves them at BOTH
    // matchup and leg level for the 1/2 + final rounds (probed live;
    // the 1/4 rounds use the cycle-144 slash shape instead). Map honestly
    // instead of leaking Latin — same honesty class as the 159/144 guards.
    const wq = /^winner (qf|sf) ([1-9])$/.exec(key);
    if (wq) {
      return `برنده ${wq[1] === "qf" ? "یک‌چهارم نهایی" : "نیمه‌نهایی"} ${faDigits(wq[2])}`;
    }
    // cycle-385: the AFC Asian Cup bracket rides GROUP-POSITION codes —
    // «1A»/«2D» (group winners/runners-up), «3CDE» (a best-3rd
    // combination) and their composed winner strings «Winner 1A/3CDE»
    // (probed live on league 290, season 2027 — the 2023 edition's R16
    // carries the same 1X/3XYZ slots). Map honestly — the same class as
    // the 380 guard above; letters keep the Latin-letter «گروه A»
    // convention (COMPOSITE_REGION_FA, cycle-382).
    const posFa = (code: string): string | null => {
      const p = /^([123])([a-f])$/.exec(code);
      if (p) return `${["اول", "دوم", "سوم"][Number(p[1]) - 1]} گروه ${p[2].toUpperCase()}`;
      const t = /^3([a-f]{2,3})$/.exec(code);
      if (t) return `سوم گروه‌های ${t[1].toUpperCase().split("").join("، ")}`;
      return null;
    };
    const pos = posFa(key);
    if (pos) return pos;
    const wslot = /^winner ([123][a-f]\/(?:3[a-f]{2,3}|[123][a-f]))$/.exec(key);
    if (wslot) {
      const sides = wslot[1].split("/").map((s) => posFa(s) || s);
      return `برنده ${sides.join("/")}`;
    }
  }
  // qualifier fallback: known base + Persian qualifier (U19 / women / reserve)
  // cycle-159: the base must also ride COUNTRY_FA — national youth sides
  // («Iran U23», «Qatar U19», «Poland U21»…) build on country names that live
  // in the cycle-86 map, not TEAM_FA; the TEAM_FA-only probe left every one
  // of them leaking Latin through player career grids (D5 probe: 43 rows).
  for (const c of candidates) {
    if (!c) continue;
    const key = norm(c);
    for (const q of TEAM_QUALIFIERS) {
      const m = key.match(q.re);
      if (m && m.index !== undefined) {
        const base = key.slice(0, m.index).trim();
        const baseFa = TEAM_FA[base] || COUNTRY_FA[base];
        if (baseFa) return `${baseFa}${q.fa}`;
      }
    }
  }
  // cycle-144: cup-bracket TBD slots arrive as one string «Side A/Side B»
  // (upstream joins the two possible teams with a slash). Map each side
  // honestly; a side with no mapping keeps its upstream name.
  if (candidates[0]?.includes("/")) {
    return candidates[0]
      .split("/")
      .map((s) => teamFa(s.trim()) || s.trim())
      .join("/");
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
  // cycle-159: Iceland leaked through player careers (senior + U17/U19/U21
  // + «Iceland Under 20» — the D5 career sweep found it unmapped)
  "iceland": "آیسلند",
  // cycle-382: the World Cup's 48-side roster — 40 of the national names
  // already resolve through the map above; these eight rode the WC
  // bracket/tables/fixtures as raw Latin (probed live: the unique-name set
  // across the 2026 feed's 13 sub-tables + 6 bracket rounds + 104
  // fixtures). They join COUNTRY_FA (not TEAM_FA) — the national-teams
  // map — so player-page country rows for the same nations heal with the
  // same entry (the cycle-86 convention). "turkiye" is the bare upstream
  // spelling (the diaeresis variant "türkiye" already rides this map).
  "cape verde": "کیپ‌ورد", "curacao": "کوراسائو", "haiti": "هائیتی",
  "jordan": "اردن", "new zealand": "نیوزیلند", "panama": "پاناما",
  "south africa": "آفریقای جنوبی", "turkiye": "ترکیه",
  // cycle-382 (titles sweep): the WC title history rides raw.seasons back
  // to 1930 — the 1934/1962 runner-up is the DEFUNCT «Czechoslovakia»,
  // unmapped by design until now; one entry heals both rows (Czechia's
  // modern keys already ride this map).
  "czechoslovakia": "چکسلواکی",
  // cycle-385: the AFC Asian Cup's unique-name set (probed live on league
  // 290 across the 2027 default + 2023/2019 historical feeds: 6+6 groups,
  // best-3rd table, the 1/8→final bracket and the 18-season title history
  // back to 1956 Hong Kong). 22 missing keys join COUNTRY_FA (not TEAM_FA)
  // — the national-teams convention — so the 3-title Iran history (1968/
  // 1972/1976), the 2023 semi-final run and every player-page country row
  // for the same nations heal with one entry each. "uae" is the bare
  // upstream spelling ("United Arab Emirates" already rides this map).
  "uae": "امارات", "bahrain": "بحرین", "kuwait": "کویت", "oman": "عمان",
  "china": "چین", "hong kong": "هنگ‌کنگ", "india": "هند", "indonesia": "اندونزی",
  "kyrgyzstan": "قرقیزستان", "lebanon": "لبنان", "malaysia": "مالزی",
  "myanmar": "میانمار", "north korea": "کره شمالی", "palestine": "فلسطین",
  "philippines": "فیلیپین", "singapore": "سنگاپور", "syria": "سوریه",
  "tajikistan": "تاجیکستان", "thailand": "تایلند", "turkmenistan": "ترکمنستان",
  "vietnam": "ویتنام", "yemen": "یمن",

  // cycle-394 (the 393 F2 render-wire flip, nationality completion): squad rows
  // now wire nationality through teamFa — a 3-flagship-squad probe (8650/10261/
  // 101610) showed these two were the ONLY live nationality values missing from
  // this map (25 of 27 already rode cycle-86+); unmapped values keep the honest
  // Latin passthrough.
  "congo": "کنگو", "northern ireland": "ایرلند شمالی",
};

export function countryFa(name: string | undefined | null): string {
  if (!name) return "";
  return COUNTRY_FA[name.toLowerCase().trim()] || name;
}

// FotMob team logo (kept after countryFa — cycle 45 additions above)
export function fotmobTeamLogo(teamId: number | string): string {
  return `https://images.fotmob.com/image_resources/logo/teamlogo/${teamId}.png`;
}
