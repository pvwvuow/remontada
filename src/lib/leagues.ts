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
  // cycle-469: the 468 finding's fix — the first THREE harvest-wave league
  // registrations (the finding's named ids: the two 468 witness leagues
  // EST/HON + PAN). Scope discipline (scripts/c469-league-sweep.py, live
  // ±7 window UA Chrome/124 2026-11-03: 309 distinct league ids in the
  // window, 298 unregistered — the full missing list rides the sweep
  // artifact as the one-per-cycle follow-up ledger, the 165/181/361/362/
  // 417 one-competition-per-cycle precedent; the 468 finding itself named
  // exactly these three). The DAY-feed ids (EST 1000001181 / HON 941508 /
  // PAN 941168) all answered literal NULL as league pages (the 376/377/
  // 380/381/385 day-tournament subclass) — the real page ids surfaced via
  // the cycle-141 crack (matchDetails content.matchFacts.infoBox.Tournament
  // .parentLeagueId, scripts/c469-league-probe2.py): EST 248, HON 337,
  // PAN 9039 — each page probed with the app's OWN fetch shape (scripts/
  // c469-league-probe3.py, raw payloads saved from the probe window):
  // cycle-469 — ESTONIA Premium liiga (the 468 finding's first witness
  // league, /team/1588 and friends): flat 10-row 2026 FINAL table (FCI
  // Levadia 90 pts champion / 35 played, Narva Trans 20 — the calendar
  // season is over, the table serves as the final archive), 17 PLAIN-YEAR
  // allAvailableSeasons ('2026'→'2010') → plainYearSeasons:true (the 382
  // flag; the slash contract stays the default for every other
  // competition and every global surface), titleHistory ABSENT (the
  // «قهرمانان» tab honestly hidden, the 121 contract), transfers.data
  // REAL (Adyn Torres → Nõmme JK Kalju — a 468 witness club),
  // playoff=null (bracket tab honestly absent, the 56 contract),
  // stats.players/teams present, fixtures.allMatches=180, leagueColor
  // #212121. ESPN probed BOTH candidates 400 (est.1 / estonia.1) → the
  // field is OMITTED (the Gulf pattern). faName rides the ALREADY-SHIPPED
  // mapping «لیگ برتر استونی» ("premium liiga|EST") so the day feed and
  // the league page never disagree; enName byte-identical to the day-feed
  // group name (the feed's own lowercase «liiga» casing). globalMerge:
  // false — a plain-year feed must never enter the slash-season
  // allSeasons intersection (the 382 one-flag semantic).
  { key: "estonia",    fotmobId: 248,         ccode3: "EST",  faName: "لیگ برتر استونی",    enName: "Premium liiga",                                  priority: 34, globalMerge: false, plainYearSeasons: true },
  // cycle-469 — HONDURAS Liga Nacional (the 468 finding's second witness
  // league, /team/1384118 and /team/2096910): flat 12-row LIVE 2026/2027
  // Apertura table (CD Olimpia 29 pts / 12 played top, Juticalpa 6 bottom
  // — the 466 batch's own clubs), 33 SUFFIXED allAvailableSeasons
  // ('2026/2027 - Apertura' …) — NEITHER the slash shape NOR plain years,
  // so the strict contract admits none: allSeasons=[] → the season
  // selector honestly hides (the cycle-55 "leagues without a season list
  // simply hide the control" contract) while the current season still
  // serves via the payload's own selectedSeason — documented degradation,
  // zero code change. titleHistory ABSENT, transfers.data REAL (Exon
  // Arzú → Real España), playoff=null (the Apertura playoff not yet
  // drawn), stats present, fixtures.allMatches=96, leagueColor #7ABD46.
  // ESPN hon.1 probed 200 AND content-verified («Honduran Liga Nacional»
  // — events UPNFM at Olancho FC / Motagua at Estrella Roja / Juticalpa
  // at Olimpia, the batch-23 clubs themselves) → the field RIDES;
  // honduras.1 400. faName rides the ALREADY-SHIPPED mapping «لیگ ملی
  // هندوراس — آپرتورا» ("liga nacional - apertura|HON"); enName
  // byte-identical to the day-feed group name (the dash separates it from
  // GUA's bare «Liga Nacional Apertura»). globalMerge: false — the
  // suffixed feed never enters the slash-season intersection.
  { key: "honduras",   fotmobId: 337,         ccode3: "HON",  faName: "لیگ ملی هندوراس — آپرتورا", enName: "Liga Nacional - Apertura", espnSlug: "hon.1",          priority: 35, globalMerge: false },
  // cycle-469 — PANAMA LPF (the 468 finding's third named id):
  // COMPOSITE feed (composite:true + FOUR sub-tables 'Apertura - Eastern'
  // / 'Apertura - Western' / 'Clausura - Eastern' / 'Clausura - Western',
  // 6 rows each — Plaza Amador / San Francisco FC / Veraguas United tops;
  // the cycle-141 parser flattens data.tables[] as-is) — the four zone
  // labels join COMPOSITE_REGION_FA (fotmob.ts) so the standings page
  // never leaks raw Latin. 11 MIXED allAvailableSeasons (2026/2025/2024/
  // 2023/2010 plain + 2015/2016…2010/2011 slash) → plainYearSeasons:true
  // admits the plain five, the slash six always passed (the 382 flag).
  // playoff SERVED (1/4:4 / 1/2:2 / final:1 — the bracket tab RENDERS,
  // the 56 parser shape), titleHistory ABSENT, transfers.data REAL
  // (Eduardo Anderson → Baltika), stats present, fixtures.allMatches=199,
  // leagueColor #333333. ESPN probed BOTH candidates 400 (pan.1 /
  // panama.1) → OMITTED (the Gulf pattern). faName rides the
  // ALREADY-SHIPPED mapping «لیگ فوتبال پاناما — آپرتورا» ("lpf
  // apertura|PAN"); enName byte-identical to the day-feed group name.
  // globalMerge: false — the 376 one-flag semantic unchanged.
  { key: "panama",     fotmobId: 9039,        ccode3: "PAN",  faName: "لیگ فوتبال پاناما — آپرتورا", enName: "LPF Apertura",                                   priority: 36, globalMerge: false, plainYearSeasons: true },
  // cycle-474 — ARGENTINA Liga Profesional (the 469 registration ledger's
  // HEAD, the standing fix-cycle pool "one per cycle": ARG 1000001729 /
  // GUA 938628 / RUS 63+951803 / MLS 913550). The day-feed id 1000001729
  // answers LITERAL NULL as a league page even on the app's own
  // api/data/leagues shape (the 469 day-id trap, scripts/c474-league-probe
  // .py) — the real page id 112 surfaced via the 141 crack
  // (scripts/c474-league-probe2.py: witness match 1000019617's matchDetails
  // infoBox Tournament parentLeagueId=112, link
  // /leagues/112/overview/liga-profesional, leagueName «Liga Profesional»).
  // COMPOSITE feed (composite:true + FOUR 15-row sub-tables «Clausura
  // Group A/B» + «Apertura Group A/B» — Instituto 33/15 top of A, Rosario
  // Central 31/15 top of B; BOTH fix witnesses live in Clausura B:
  // Argentinos Juniors idx 2 pts 31, Atlético Tucumán idx 10 pts 17),
  // probed live UA Chrome/124 via the app's own fetch shape
  // (scripts/c474-league-probe.py on id=112&ccode3=ARG, 915KB payload).
  // 23 MIXED allAvailableSeasons («2026 - Clausura» … suffixed 13 + plain
  // years 10) — the suffixed shape matches NEITHER season contract, the
  // plain ten admit via plainYearSeasons:true (the 382 flag, the PAN
  // mixed-shape precedent); the current season keeps serving through
  // overview.selectedSeason «2026 - Clausura» regardless (the 419 marker).
  // playoff=null (no bracket tab), titleHistory ABSENT, transfers.data
  // REAL (Hernán López → Argentinos Juniors — the 10086 witness itself),
  // stats players/teams present, fixtures.allMatches=240. ESPN arg.1
  // probed 200 AND content-verified («Argentine Liga Profesional de
  // Fútbol» — events Boca/River/Belgrano/Barracas/Newell's/Unión, the
  // probed table's own clubs, scripts/c474-espn-probe.py, the app's own
  // site/v2 scoreboard shape) → the field RIDES; argentina.1 400 → the
  // second spelling stays absent (the 469 two-candidate rule). faName
  // rides the ALREADY-SHIPPED mapping «لیگ حرفه‌ای آرژانتین» ("liga
  // profesional|ARG") so the day feed and the league page never disagree;
  // enName byte-identical to the day-feed group name «Liga Profesional»
  // (byte-read from the live team route recent[0].leagueName, 2026-11-04).
  // globalMerge: false — the composite suffixed-season feed never enters
  // the slash-season allSeasons intersection (the 382 one-flag semantic).
  { key: "argentina",  fotmobId: 112,         ccode3: "ARG",  faName: "لیگ حرفه‌ای آرژانتین", enName: "Liga Profesional", espnSlug: "arg.1",           priority: 37, globalMerge: false, plainYearSeasons: true },
  // cycle-479 — GUATEMALA Liga Nacional (the 469 registry's next head after
  // ARG): the sweep id 938628 is the DAY-FEED id and answers literal null on
  // /api/data/leagues — the SAME trap as ARG's 1000001729; the real page id
  // comes from the 141-crack via the team route: match 5861309 (CSD
  // Municipal vs Comunicaciones FC, round 17) matchDetails general carries
  // leagueId 938628 + parentLeagueId 336 + countryCode GUA
  // (scripts/c479-league-probe.py + c479-league-probe2.py, 2026-11-04).
  // Page 336 (325KB): FLAT 12-row LIVE 2026/2027 Apertura table (Antigua
  // Guatemala 35 pts / 18 played top, CD Suchitepéquez 12 bottom — all 12
  // clubs are the ±7 feed's own GUA wave, already Persian in TEAM_FA from
  // the 44x harvest tranches: مونیسیپال / کامیونیکیشنس / آنتیگوا گواتمالا /
  // گواستاتویا / شلاخو …), pageUrl /leagues/336/overview/liga-nacional,
  // leagueColor legend championship-playoff indices 0..5, playoff=null,
  // transfers.data REAL, stats present, fixtures.allMatches — all flat /
  // single-table (NO composite → zero COMPOSITE_REGION_FA additions, the
  // estonia/honduras path). allAvailableSeasons: SEVENTEEN names, every one
  // the strict SLASH shape '2026/2027' … '2011/2012' → the contract admits
  // all of them with NO flag (the 382 one-flag semantic stays
  // plain-year-only) and the payload's selectedSeason '2026/2027' serves
  // the current table — the season selector is LIVE (unlike honduras's
  // documented suffixed degradation). ESPN gua.1 probed 200 AND
  // content-verified («Guatemalan Liga Nacional» — events Aurora at
  // Municipal / Comunicaciones at Marquense, the feed's own clubs) → the
  // field RIDES; guatemala.1 400 (the 469 two-candidate rule). faName rides
  // the ALREADY-SHIPPED mapping «لیگ ملی گواتمالا — آپرتورا» ("liga
  // nacional apertura|GUA", the 384 CC-keyed block) so the day feed and the
  // league page never disagree; enName byte-identical to the day-feed group
  // name «Liga Nacional Apertura» (the BARE no-dash form — honduras's
  // dash-spelled «Liga Nacional - Apertura» keeps the two byte-distinct, the
  // 469 disambiguation comment). globalMerge: false — the feed never enters
  // the slash-season intersection of another league (the 382 semantic).
  { key: "guatemala",  fotmobId: 336,         ccode3: "GUA",  faName: "لیگ ملی گواتمالا — آپرتورا", enName: "Liga Nacional Apertura", espnSlug: "gua.1",        priority: 38, globalMerge: false },
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
  // cycle-451: harvest batch 14 — the machine continues on the 451 census
  // (scripts/c451-pool-sweep.py read EXACTLY 1852 distinct = the documented
  // 450 post-census, ZERO distinct drift for the THIRD consecutive cycle;
  // rows drifted to 3446 — the 435 lesson: rows drift, distinct is
  // decisive; scripts/c451-batch14-verify.py byte-identity gate, live UA
  // Chrome/124: 11/11 verified=0 bad): this batch takes ALL 11 count-3
  // single-country names of the CYPRUS tranche (2. Division + Cup + Cyprus
  // League). The honest CYP/THA tie (11 names/33 rows/33 day-presence EACH
  // — the documented read) broke on anchor quality + visibility per the 447
  // precedent: TWO direct Persian-Wikipedia club articles in the CYP pool
  // («باشگاه فوتبال المپیاکوس نیکوزیا» pageid 6063477 + «باشگاه فوتبال
  // ارمیس آرادیپو» pageid 6491621) plus the file's own Cypriot block
  // (اومونیا نیکوزیا/آپوئل نیکوزیا/آنورتوسیس/پافوس) riding the rest, vs a
  // THA pool with ZERO club articles; no (W) women's sides, no exclusions.
  // The count>=4 multi-country names stay honest-raw (Alianza FC 10
  // COL/INT/PAN/SLV, Santa Fe COL/INT, Libertad ECU/PAR, Universidad
  // Católica CHI/ECU, Olimpia INT/PAR, BK Häcken (W) INT/SWE — the 389
  // identity-first rule; the single MB Rouissat ALG waits for its tranche).
  // Transliteration: AEL → آئل rides the file's own آئک آتن AE→آئ reading
  // — the fa.wiki article «باشگاه ورزشی لیماسول» (the Athletic-Union
  // descriptor title, found via the az.wiki langlink) drops its باشگاه
  // ورزشی prefix like the 447 FC rule, the toponym لیماسول is the fa.wiki
  // city anchor; AEP → آئپ same rule (Polemidion → پولمیدیون, the Greek δ
  // → د like the رودس convention). Omonia rides the file's OWN اومونیا
  // نیکوزیا anchor: Omonia Aradippou = اومونیا آرادیپو (آرادیپو the fa.wiki
  // city) and Omonia 29 Maiou = اومونیا ۲۹ می (the Persian digits rule:
  // مونیخ ۱۸۶۰/ایبریا ۱۹۹۹; Μαΐου → می). Doxa Katokopia = دوکسا کاتوکوپیاس
  // (the footba11 press form with the genitive -pias kept; footba11's
  // Cyprus page renders it exactly so). Karmiotissa = کارمیوتیسا (the
  // footba11 press form exact, the آنورتوسیس σσ→س anchor). Iraklis
  // Gerolakkou = ایراکلیس جیرولاکو (Iraklis the Persian press form for the
  // Greek club family; Γερολάκκου → جیرولاکو — the γ reading rides the
  // fa.wiki جیرولامو precedent + the Arabic sofascore form جيرولاككو; the
  // Persian press has no form of its own). Chalkanoras Idaliou =
  // خالکانوراس ایدالیو and Digenis Morphou = دیگنیس مورفو (the honest
  // transliterations: χ → خ like خالکیدا, ιδάλιον → ایدالیو, Μόρφου →
  // مورفو). Collision gate: zero key and zero value collisions against the
  // whole file (المپیاکوس نیکوزیا vs the Piraeus olympiacos → المپیاکوس
  // and اومونیا آرادیپو vs اومونیا نیکوزیا are distinct full-value strings
  // — the دینامو بخارست vs دینامو مسکو precedent; no Logroñés case).
  // Loud-pool rule: the documented 1852 census shrinks by this batch in the
  // open (the B4 band re-anchors with the next census, never silently).
  "ael limassol": "آئل لیماسول",
  "aep polemidion": "آئپ پولمیدیون",
  "chalkanoras idaliou": "خالکانوراس ایدالیو",
  "digenis morphou": "دیگنیس مورفو",
  "doxa katokopia": "دوکسا کاتوکوپیاس",
  "ermis aradippou": "ارمیس آرادیپو",
  "iraklis gerolakkou": "ایراکلیس جیرولاکو",
  "karmiotissa": "کارمیوتیسا",
  "olympiakos nicosia": "المپیاکوس نیکوزیا",
  "omonia 29 maiou": "اومونیا ۲۹ می",
  "omonia aradippou": "اومونیا آرادیپو",
  // cycle-452: harvest batch 15 — the machine continues on the 452 census
  // (scripts/c452-pool-sweep.py read EXACTLY 1841 distinct = the documented
  // 451 post-census, ZERO distinct drift for the FIFTH consecutive cycle;
  // rows drifted to 3413 — the 435 lesson: rows drift, distinct is
  // decisive; scripts/c452-batch15-verify.py byte-identity gate, live UA
  // Chrome/124: 11/11 verified=0 bad): this batch takes ALL 11 count-3
  // single-country names of the THAILAND tranche (League Cup Play-offs —
  // the honest 451 runner-up: the CYP/THA tie broke on anchor quality and
  // CYP went first; with CYP gone THA stands alone as the largest pool at
  // 11 names/33 rows/33 day-presence, the 446-pick rule). Zero direct
  // Persian-Wikipedia CLUB articles in the pool — exactly the 451 read
  // («only city toponyms ناکون پاتوم/ساتون/چاینات») — so this batch rides
  // the fa.wiki CITY-TITLE toponym rule (the 451 آرادیپو/لیماسول precedent:
  // the city article's own spelling wins over press variants) + the
  // footba11 press forms where the live-score press renders the club
  // itself; no (W) women's sides, no exclusions. The count>=4 multi-country
  // names stay honest-raw (Alianza FC 10 COL/INT/PAN/SLV, Santa Fe COL/INT,
  // Libertad ECU/PAR, Universidad Católica CHI/ECU, Olimpia INT/PAR, BK
  // Häcken (W) INT/SWE — the 389 identity-first rule; the single MB
  // Rouissat ALG waits for its tranche). Transliteration: Chainat FC →
  // چای نات (the fa.wiki CITY article title pageid 481797 «چای نات یک شهر
  // در تایلند است» — the PROVINCE is چاینات pageid 3671778 and the
  // footba11 press form چینات هورنبیل stays press; FC dropped per the
  // 445/446 suffix-discipline rule). Nakhon Pathom → ناکون پاتوم (the
  // fa.wiki CITY title pageid 5035427 — «ناکون پاتوم یک منطقهٔ مسکونی در
  // تایلند است» — while ناخون پاتوم pageid 3671934 is the PROVINCE and the
  // footba11 press form ناخون پاتوم یونایتد stays press; the feed's bare
  // toponym rides the city spelling). Songkhla United FC → سونگکلا یونایتد
  // (the fa.wiki CITY title pageid 4888420 «سونگکلا یک شهر در تایلند است»
  // — the ک spelling is the city, the province is سونگخلا pageid 3671981;
  // FC dropped). PT Satun FC → پی‌تی ساتون (ساتون the fa.wiki city pageid
  // 118303 «شهری است واقع در جنوب تایلند و پایتخت استان ساتون» + PT →
  // پی‌تی; FC dropped; the full-value string پی‌تی ساتون stays distinct
  // from the English Sutton's own ساتون render — the دینامو بخارست vs
  // دینامو مسکو precedent). Kanchanaburi Power → کانتچانابوری پاور
  // (کانتچانابوری the fa.wiki city pageid 4926179 + پاور the honest
  // rendering of the club's own Power branding — no Persian press form
  // exists, documented as read). Kasetsart → کاستسارت (the fa.wiki article
  // «دانشگاه کاستسارت» — the encyclopedia's own spelling of the eponym
  // university the club belongs to; the invented کاسه‌سارت candidate died
  // at the opensearch gate). Khonkaen United FC → خون کائن یونایتد (the
  // footba11 press form, Google-indexed from the footba11 standings; FC
  // dropped; the full-value string is distinct from the fa.wiki «خون کائن»
  // FOOD-COMPANY article spelling — same toponym reading, different
  // entity, no collision). Nong Bua Pitchaya FC → نونگ بوا پیچایا (the
  // footba11 press form, Google-indexed from the footba11 team page; FC
  // dropped). Pattaya Dolphins United → پاتایا دلفینز یونایتد (پاتایا the
  // fa.wiki city pageid 156925 «پِتایا یا پاتایا شهر ساحلی کوچکی است» +
  // دلفینز honest + یونایتد; the older fa.wiki «باشگاه فوتبال پاتایا
  // یونایتد» article describes the dissolved namesake, not the Dolphins
  // entity — identity-first, no anchor theft). Mahasarakham Sam Bai Tao →
  // مهاساراخام سام بای تائو (مهاساراخام rides the BBC-syndicated press
  // form «جامعة مهاساراخام» served by three Arabic outlets + the ar.wiki
  // ماها ساراخام concurrence; سام بای تائو honest; no fa.wiki city article
  // under either spelling, documented as read). Muang Loei United → موانگ
  // لویی یونایتد (موانگ rides the file's OWN muang thong united →
  // موانگ‌تونگ یونایتد reading; لویی honest — fa.wiki has NO Thai-Loei
  // article: لوی pageid 50476 is Oman's Liwa, شهرستان لویی pageid
  // 4791610 is China's Zhoukou, استان لوی MISSING — documented as read;
  // یونایتد press). Collision gate: zero key and zero value collisions
  // against the whole file (each render one distinct full-value string —
  // no Logroñés case). Loud-pool rule: the documented 1841 census shrinks
  // by this batch in the open (the B4 band re-anchors with the next
  // census, never silently).
  "chainat fc": "چای نات",
  "kanchanaburi power": "کانتچانابوری پاور",
  "kasetsart": "کاستسارت",
  "khonkaen united fc": "خون کائن یونایتد",
  "mahasarakham sam bai tao": "مهاساراخام سام بای تائو",
  "muang loei united": "موانگ لویی یونایتد",
  "nakhon pathom": "ناکون پاتوم",
  "nong bua pitchaya fc": "نونگ بوا پیچایا",
  "pattaya dolphins united": "پاتایا دلفینز یونایتد",
  "pt satun fc": "پی‌تی ساتون",
  "songkhla united fc": "سونگکلا یونایتد",

  // cycle-455: harvest batch 16 — the machine continues on the 455 census
  // (scripts/c451-pool-sweep.py re-run read EXACTLY 1830 distinct = the
  // documented 452 post-census, ZERO distinct drift for the SIXTH
  // consecutive cycle; rows drifted to 3379 — the 435 lesson: rows drift,
  // distinct is decisive; scripts/c455-batch16-verify.py byte-identity
  // gate, live UA Chrome/124: 10/10 verified=0 bad, 30 live leak rows
  // covered): the four-way tie AUT/POL/UKR/MNE (each 10 count-3 names /
  // 30 rows) broke on fa.wiki DIRECT club-article anchor quality per the
  // 447 rule (scripts/c455-wiki-tiebreak.py: AUT 3 — آستریا وین/گراتس/
  // ولفسبرگر — vs POL 0 / UKR 1 / MNE 2, documented as read): this batch
  // takes ALL 10 count-3 single-country names of the AUSTRIA tranche
  // (Bundesliga + 2. Liga; no exclusions). Anchors
  // (scripts/c455-wiki-probe.py/2): Austria Wien → آستریا وین (the fa.wiki
  // club article «باشگاه فوتبال آستریا وین» pageid 535778 + the file's OWN
  // austria→آستریا (austria lustenau) and wien→وین (rapid wien) readings).
  // WSG Tirol → تیرول (the fa.wiki club article «باشگاه فوتبال تیرول»
  // pageid 5973388 — the entity's own spelling absorbs the WSG descriptor,
  // the FC-drop rule; distinct from the زودتیرول full value). First Vienna
  // FC → فرست ویینا (the fa.wiki club article «باشگاه فوتبال فرست ویینا»
  // pageid 5211062 — the encyclopedia's own byte-spelling ویینا wins over
  // the invented فرست وینا; FC dropped). Grazer AK → گراتس (the fa.wiki
  // club article «باشگاه ورزشی گراتس» pageid 4904665 — the باشگاه ورزشی
  // descriptor absorbs AK exactly like the 451 AEL لیماسول read; the
  // full-value string stays distinct from the file's own اشتورم گراتس; the
  // invented گراتسر form died at the opensearch gate). Wolfsberger AC →
  // ولفسبرگر (the fa.wiki club article «باشگاه ورزشی ولفسبرگر» pageid
  // 4940416; AC absorbed in the descriptor; distinct from the ولفسبرگ
  // city). FC Hertha Wels → هرتا ولس (هرتا honest + ولس the fa.wiki city
  // pageid 638927 — NOT the invented هرتا ولز which would read as Wales;
  // FC dropped). FC Wacker Innsbruck → واکر اینسبروک (واکر the fa.wiki
  // «واکر» article's own spelling + اینسبروک the fa.wiki city pageid
  // 222006; FC dropped). Ried → رید (the fa.wiki city article «رید ایم
  // اینکرایس» documented as the anchor — the feed's bare toponym rides its
  // own core; SV dropped per the file's own sv-werder/darmstadt
  // convention). SW Bregenz → اس‌دبلیو برگنتس (SW letters per the file's
  // OWN fsv→اف‌اس‌وی letter-reading convention + برگنتس the fa.wiki city
  // pageid 643035; no press form documented as read — the letters are the
  // club's distinguishing identity like psv). Altach → آلتاخ (honest
  // transliteration documented as read — fa.wiki has NO article under any
  // spelling: آلتاخ/راین‌دورف MISSING, the 452 لویی precedent). Collision
  // gate: zero key and zero value collisions against the whole 1750-pair
  // file (each render one distinct full-value string — no Logroñés case).
  // Loud-pool rule: the documented 1830 census shrinks by this batch in
  // the open (the B4 band re-anchors with the next census, never
  // silently).
  "altach": "آلتاخ",
  "austria wien": "آستریا وین",
  "fc hertha wels": "هرتا ولس",
  "fc wacker innsbruck": "واکر اینسبروک",
  "first vienna fc": "فرست ویینا",
  "grazer ak": "گراتس",
  "ried": "رید",
  "sw bregenz": "اس‌دبلیو برگنتس",
  "wsg tirol": "تیرول",
  "wolfsberger ac": "ولفسبرگر",

  // cycle-456: harvest batch 17 — the machine continues on the 456 census
  // (scripts/c451-pool-sweep.py re-run read EXACTLY 1819 distinct = the
  // documented 455 post-census, ZERO distinct drift for the SEVENTH
  // consecutive cycle; rows drifted to 3347 — the 435 lesson: rows drift,
  // distinct is decisive; scripts/c456-batch17-verify.py byte-identity
  // gate, live UA Chrome/124: 10/10 verified=0 bad, 30 live leak rows
  // covered): the three-way tie POL/UKR/MNE (each 10 count-3 names / 30
  // rows) broke on fa.wiki DIRECT club-article anchor quality per the 447
  // rule (scripts/c456-wiki-tiebreak.py RE-READ live this cycle: MNE 2 —
  // بودوچنوست پودگوریتسا/آرسنال تیوات — vs POL 1 زنیچ پروشکوف / UKR 1
  // دینامو کی‌یف, documented as read; the 455 read had MNE 2 / UKR 1 /
  // POL 0 — the MNE lead held): this batch takes ALL 10 count-3
  // single-country names of the MONTENEGRO tranche (1. CFL; no
  // exclusions). Anchors (scripts/c456-wiki-probe.py/2): Budućnost
  // Podgorica → بودوچنوست پودگوریتسا (the fa.wiki club article «باشگاه
  // فوتبال بودوچنوست پودگوریتسا» pageid 42378368; the descriptor drops per
  // the FC rule). FK Arsenal Tivat → آرسنال تیوات (the fa.wiki club
  // article «باشگاه فوتبال آرسنال تیوات» pageid 41367275; FK dropped).
  // Dečić Tuzi → دچیچ توزی (دچیچ honest read — ć→چ per the encyclopedia's
  // OWN بودوچنوست/نیکشیچ spellings; the opensearch gate dead: دریچه noise
  // only; توزی the fa.wiki city pageid 39148180). FK Bokelj → بوکلی کوتور
  // (بوکلی honest; the fa.wiki «بوکلی» page 22771837 is a NON-club subject
  // — identity verified, unusable as an anchor — so the bare form
  // disambiguates with کوتور the fa.wiki city pageid 41551328; FK
  // dropped). Jezero → یزرو پلاو (یزرو the encyclopedia's OWN toponym
  // spelling — the fa.wiki village cluster «یزرو (سینیتسا)/(دسپوتوواتس)/
  // (سوکوبانگا)» reads Jezero exactly یزرو, none of them the Montenegro
  // one; the bare value stays out — the word is hyper-generic; پلاو the
  // fa.wiki city pageid 43888965). Mornar → مورنار بار (مورنار honest —
  // opensearch dead; bare بار is a Persian common word so the value rides
  // بار the fa.wiki city pageid 41746946). OFK Mladost Donja Gorica →
  // ملادوست دونیا گوریتسا (OFK dropped; ملادوست honest; دونیا the
  // encyclopedia's OWN Donja spelling — the fa.wiki village «دونیا
  // وربیتسا» reads Donja exactly دونیا; the toponym itself has no
  // article). Otrant → اوترانت (honest read documented — spelled beside
  // the encyclopedia's OWN «اوترانتو» for the Italian Otranto, the feed's
  // bare form rides that spelling family; opensearch dead: اترنت/
  // اوترانتو noise only). Petrovac → پتروواتس (پتروواتس the
  // encyclopedia's OWN spelling — the fa.wiki «پتروواتس نا ملاوی» reads
  // Petrovac exactly پتروواتس; the bare value = club = town, the 455 رید
  // precedent; FC dropped). Sutjeska → سوتجسکا نیکشیچ (سوتجسکا honest —
  // tj→ج; the bare value stays out — the toponym is the famous BiH
  // river/battle; نیکشیچ the fa.wiki city pageid 41554198). Collision
  // gate: zero key and zero value collisions against the whole 1760-pair
  // file (each render one distinct full-value string — no Logroñés case).
  // Loud-pool rule: the documented 1819 census shrinks by this batch in
  // the open (the B4 band re-anchors with the next census, never
  // silently).
  "budućnost podgorica": "بودوچنوست پودگوریتسا",
  "dečić tuzi": "دچیچ توزی",
  "fk arsenal tivat": "آرسنال تیوات",
  "fk bokelj": "بوکلی کوتور",
  "jezero": "یزرو پلاو",
  "mornar": "مورنار بار",
  "ofk mladost donja gorica": "ملادوست دونیا گوریتسا",
  "otrant": "اوترانت",
  "petrovac": "پتروواتس",
  "sutjeska": "سوتجسکا نیکشیچ",

  // cycle-457: harvest batch 18 — the machine continues on the 457 census
  // (scripts/c451-pool-sweep.py re-run read EXACTLY 1809 distinct = the
  // documented 456 post-census, ZERO distinct drift for the EIGHTH
  // consecutive cycle; rows steady at 3317 — the 435 lesson: rows drift,
  // distinct is decisive; scripts/c457-batch18-verify.py byte-identity
  // gate, live UA Chrome/124: 10/10 verified=0 bad, 30 live leak rows
  // covered): the two-way tie POL/UKR (each 10 count-3 names / 30 rows)
  // was DEAD-EVEN on direct fa.wiki club articles (POL 1 زنیچ پروشکوف vs
  // UKR 1 دینامو کی‌یف), so the 447 read extended one documented level —
  // CITY-TOPONYM anchor quality (the 452 city-title rule, the same anchor
  // class the 451/452/455/456 batches rode): UKR 6 city hits (خارکوف
  // Q42308، ژیتومیر Q156713، ریونه Q156739، چرکاسی Q157055،
  // کامیانتس-پودیلسکی Q193965، برهوفه Q146497 — the last a WRONG-CITY
  // probe artifact for Liviy Bereh, excluded from value anchoring) vs POL
  // 4 (سویدنگک/ونچنا/اوپوله/ژشوف) — scripts/c457-wiki-tiebreak.py,
  // documented as read: this batch takes ALL 10 count-3 single-country
  // names of the UKRAINE tranche (the Ukrainian Cup field; no
  // exclusions). Anchors (scripts/c457-wiki-probe.py/2): Dynamo Kyiv →
  // دینامو کی‌یف (the fa.wiki club article «باشگاه فوتبال دینامو کی‌یف»
  // pageid 43974850 — the descriptor drops per the FC rule; distinct from
  // the file's OWN دینامو بخارست/مسکو/درسدن/مخاچ‌قلعه/دیناموزاگرب). FC
  // Kharkiv → خارکوف (FC dropped; the bare value = club = town, the 455
  // رید / 456 پتروواتس precedent; the fa.wiki city pageid 44675128). FC
  // Karpaty Lviv → کارپات لویو (the bare کارپات page 3537193 is a
  // NON-club subject — identity verified: an SS Ramsey Town SHIP article
  // — unusable as an anchor; لویو the fa.wiki city pageid 44886178 AND
  // the file's OWN lks pogoń lwów → پوگون لویو letter-reading; Karpaty
  // honest). FC Kryvbas → کریوباس (honest read documented — opensearch
  // dead: کرواسی noise only; the ore-basin namesake is unambiguous in a
  // football context). LNZ Cherkasy → ال‌ان‌زد چرکاسی (the letter-reading
  // per the encyclopedia's OWN ال‌ان‌جی LNG page family + the file's OWN
  // fsv→اف‌اس‌وی convention, ZWNJ letters; چرکاسی the fa.wiki city
  // pageid 35486135). Liviy Bereh → لیوی بره (honest transliteration
  // documented as read — the fa.wiki «برهوفه» city hit is a WRONG-CITY
  // probe artifact: the club is a Kyiv-side side, Berehove is a
  // Zakarpattia town; no fa.wiki article under any spelling — the 452
  // لویی precedent). Polissya Zhytomyr → پولیسیا ژیتومیر (پولیسیا the
  // encyclopedia's OWN derivation — the fa.wiki ethnographic «پولیسیان‌ها»
  // reads the region name; ژیتومیر the fa.wiki city pageid 44202029). NK
  // Veres Rivne → ورس ریونه (the bare ورس page 1311780 is a NON-club
  // subject — identity verified: a Category:Eva Perón — unusable as an
  // anchor; ورس honest + ریونه the fa.wiki city pageid 41341728). FC
  // Zorya Luhansk → زوریا لوگانسک (the bare زوریا page 44163684 is an
  // unresolvable redirect — unusable as an anchor; زوریا honest + لوگانسک
  // the fa.wiki city pageid 12375949). FC Epitsentr Kamianets-Podilskyi →
  // اپیسنتر کامیانتس-پودیلسکی (اپیسنتر the encyclopedia's OWN spelling of
  // the epicenter word the club is named after — the bare form is the
  // science article, so the value rides the city کامیانتس-پودیلسکی the
  // fa.wiki pageid 43825852; FC dropped). Collision gate: zero key and
  // zero value collisions against the whole 1770-pair file (each render
  // one distinct full-value string — no Logroñés case). Loud-pool rule:
  // the documented 1809 census shrinks by this batch in the open (the B4
  // band re-anchors with the next census, never silently).
  "dynamo kyiv": "دینامو کی‌یف",
  "epitsentr kamianets-podilskyi": "اپیسنتر کامیانتس-پودیلسکی",
  "fc kharkiv": "خارکوف",
  "karpaty": "کارپات لویو",
  "kryvbas": "کریوباس",
  "lnz cherkasy": "ال‌ان‌زد چرکاسی",
  "liviy bereh": "لیوی بره",
  "polissya zhytomyr": "پولیسیا ژیتومیر",
  "veres rivne": "ورس ریونه",
  "zorya": "زوریا لوگانسک",

  // cycle-460: harvest batch 19 — the machine continues on the 460 census
  // (scripts/c451-pool-sweep.py re-run read EXACTLY 1798 distinct = the
  // documented 457 post-census, ZERO distinct drift for the NINTH
  // consecutive cycle; rows steady at 3285 — the 435 lesson: rows drift,
  // distinct is decisive; scripts/c460-batch19-verify.py byte-identity
  // gate, live UA Chrome/124: 10/10 verified=0 bad, 30 live leak rows
  // covered + the collision gate clean: dupKeys=[] and zero value
  // collisions against the whole 1780-pair file): the 446-pick rule read
  // POL 10 names / 30 rows as the LARGEST count>=3 single-country pool
  // (PAN/HON 9/27 below — no tie at the top, so the 447 tie-break is NOT
  // invoked this cycle; documented as read; no exclusions): this batch
  // takes ALL 10 count-3 single-country names of the POLAND tranche (the
  // Polish FA Cup + II/I Liga field). Anchors
  // (scripts/c460-wiki-probe.py/2/3/4/5): ONE direct fa.wiki club
  // article — Znicz Pruszków → زنیچ پروشکوف («باشگاه فوتبال زنیچ
  // پروشکوف» pageid 36186560 — the bare زنیچ پروشکوف page is its
  // R-from-move redirect; the descriptor drops per the FC rule; the same
  // article the 447 tie-break documented as POL's direct club article);
  // the city-title rule (the 452 rule) — Górnik Łęczna → گورنیک ونچنا
  // (the fa.wiki city ونچنا pageid 38070173 — the encyclopedia's OWN
  // Ł→و reading), Stal Rzeszów → استال ژشوف (ژشوف 42131222), Pogoń
  // Siedlce → پوگون شدلتسه (شدلتسه 38064699 — the fawiki sitelink of
  // Q319813, the spelling the exact-title candidates missed), Avia
  // Świdnik → آویا شویدنگک (شویدنگک 41046896), Podhale Nowy Targ →
  // پودهاله نووی تارگ (نووی تارگ 39125769), Odra Opole → اودر اوپوله
  // (اوپوله 43398736), Olimpia Grudziądz → المپیا گروجونتس (گروجونتس
  // 42131175 — identity-verified: «(به لهستانی: Grudziądz)»), Sokół
  // Kleczew → سوکوو کلچو (کلچو from the gmina title گمینا کلچو 41516608
  // — the descriptor drops per the FC-rule shape); the file's OWN
  // letter-readings — گورنیک (گورنیک زابژه), استال (استال میلتس /
  // ستالووا وولا), پوگون (پوگون شچچین/لویو), المپیا (cd olimpia) — and
  // the encyclopedia's OWN river rendering اودر (رود اودر pageid
  // 43734188 — the club named for the Odra; the آدرا page is Adra Spain,
  // identity-excluded); the honest-read fallbacks (no fa.wiki article
  // under any spelling — the opensearch/wikidata gate dead, the 452 لویی
  // / 455 آلتاخ / 457 لیوی بره precedent) — پودهاله (the Podhale
  // region), آویا (the آویا page is Avaya, اویا is OUYA — both
  // identity-excluded), سوکوو (ó→و per the file's OWN گورنیک, ł→و per
  // the encyclopedia's OWN ونچنا). Cache: matches v21 → v22 per the
  // standing rule (fresh cold window).
  "górnik łęczna": "گورنیک ونچنا",
  "olimpia grudziądz": "المپیا گروجونتس",
  "sokół kleczew": "سوکوو کلچو",
  "podhale nowy targ": "پودهاله نووی تارگ",
  "puszcza niepołomice": "پوشچا نیپلومیتز",
  "znicz pruszków": "زنیچ پروشکوف",
  "pogoń siedlce": "پوگون شدلتسه",
  "avia świdnik": "آویا شویدنگک",
  "stal rzeszów": "استال ژشوف",
  "odra opole": "اودر اوپوله",
  // cycle-461: harvest batch 20 — ALL 8 count-3 single-country names of the
  // MEXICO tranche into TEAM_FA (Liga de Expansión MX — the 446-pick rule:
  // the fresh census re-run read EXACTLY 1779 distinct = the documented 460
  // post-census, ZERO distinct drift for the TENTH consecutive cycle, rows
  // 3264; MEX 10 names/30 rows heads the pool but TWO of the ten are (W)
  // women's sides — Club León (W) / Santos Laguna (W), Liga MX Femenil —
  // SKIPPED at pick time per the 435 skip line (no (W)-level convention
  // yet): the pick is the remaining 8 names / 24 rows, documented as read;
  // no exclusions), byte-verified 8/8 (scripts/c461-batch20-verify.py:
  // every key byte-exact from the live UA Chrome/124 feed — the non-ASCII
  // é/ú keys ride the file's OWN südtirol/köln/budućnost/dečić precedent —
  // every name single-country MEX across the whole ±7 window, 24 live leak
  // rows covered, the collision gate clean: dupKeys=[] and zero value
  // collisions against the whole 1790-pair file). Anchors
  // (scripts/c461-wiki-probe.py/2/3): ONE direct fa.wiki club article —
  // Atlético Morelia → اتلتیکو مورلیا («باشگاه فوتبال اتلتیکو مورلیا»
  // pageid 41466700, identity-verified «یک باشگاه فوتبال مکزیکی مستقر در
  // مورلیا، میچوآکان... در لیگا ده اکسپانسیون مکزیک بازی می‌کند»; the bare
  // اتلتیکو مورلیا page 41466701 is its R-from-move redirect; the
  // descriptor drops per the FC rule; the wikidata probe's Morelia
  // sitelink came back the ERZURUMSPOR Persian title — a wrong-country
  // artifact identity-excluded, the 460 آدرا-Spain lesson); the city-title
  // rule (the 452 rule) — Cancún FC → کانکون (کانکون 44776288, the
  // encyclopedia's OWN rendering, FC dropped per the 457 خارکوف / Thai
  // چای نات precedent), Tlaxcala FC → تلاسکالا (تلاسکالا 41256613, the
  // encyclopedia's OWN Tlaxcala-state title spelling, the article's own
  // text rendering both readings; FC dropped), Atlético La Paz →
  // اتلتیکو لاپاز (اتلتیکو the file's OWN atlético madrid form + لاپاز
  // (مکزیک) 44822373 identity-verified the Baja California Sur capital —
  // the bare لا پاز page 38968699 is an ARGENTINE settlement
  // identity-excluded, the fused لاپاز is the encyclopedia's OWN spelling
  // the disambiguation page documents); the file's OWN phonetic-Spanish
  // convention (بوکا جونیورز دی کالی، ایندپندینته مدئین، استودیانتس،
  // آلاوس) — Alacranes de Durango → آلاکرانس دی دورانگو (de→دی per the
  // boca juniors de cali precedent, initial a→آ per the alavés→آلاوس
  // precedent, دورانگو the encyclopedia's OWN state rendering 41358540
  // whose center is شهر دورانگو), Leones Negros → لئونس نگروس, Piratas →
  // پیراتاس (the Liga de Expansión MX franchise, Piratas vs Tapatío in
  // the live feed — the استودیانتس-style Spanish plural), Venados FC →
  // ونادوس (FC dropped); the Mérida/Yucatán context pages (مریدا
  // (یوکاتان) 44647020 / یوکاتان 41727782) documented, not used — the
  // club name carries no city; the honest-read fallbacks (no fa.wiki
  // article under any spelling, the opensearch/wikidata gate dead — the
  // 452 لویی / 455 آلتاخ / 457 لیوی بره / 460 پودهاله precedent):
  // آلاکرانس، لئونس نگروس، پیراتاس، ونادوس. Cache: matches v22 → v23 per
  // the standing rule (fresh cold window). Patrol: B4 re-anchored to the
  // post-patch census read (the loud-pool rule, the 445 precedent) + B25
  // NEW (four batch-20 witnesses Persian in the live ±7 feed — the patrol
  // now runs 64 checks). The post-patch census + drift story live in the
  // repo worklog card (the 455-457 pattern).
  "alacranes de durango": "آلاکرانس دی دورانگو",
  "atlético la paz": "اتلتیکو لاپاز",
  "atlético morelia": "اتلتیکو مورلیا",
  "cancún fc": "کانکون",
  "leones negros": "لئونس نگروس",
  "piratas": "پیراتاس",
  "tlaxcala fc": "تلاسکالا",
  "venados fc": "ونادوس",
  // cycle-462: harvest batch 21 — ALL 19 count>=3 single-country names of the
  // ARGENTINA tranche into TEAM_FA (the live Liga Profesional + Copa
  // Argentina wave — the 446-pick rule: the fresh census re-run read
  // distinct=1773 = the documented 461 post-census 1771 + 2 net live-window
  // churn (the 445/455/460 precedent; the promotion-vs-new-entrant split not
  // separately observable in this wake — documented as read), rows 3272; the
  // count-3 segment 185→204 = +19 with the ARG wave the headline: 19 names /
  // 62 rows (14 at count-3, 5 at count-4), ZERO (W) sides — no 435 skip
  // needed — every name single-country ARG across the whole ±7 window; ARG
  // 19/62 tops the pool with PAN/HON 9/27 (the 461 leaders) held below and
  // CZE/EST/SWE/ISR/USA 8/24 next; no tie at the top so the 447 tie-break is
  // NOT invoked — documented as read; no exclusions), byte-verified 19/19
  // (scripts/c462-batch21-verify.py: every key byte-exact from the live UA
  // Chrome/124 feed — the non-ASCII é/ó/ú keys ride the file's OWN
  // südtirol/köln/budućnost/dečić/atlético precedent — every name
  // single-country ARG across the whole ±7 window, 62 live leak rows
  // covered, the collision gate clean: dupKeys=[] and zero value collisions
  // against the whole 1798-pair file, 1798 → 1817 pairs). Anchors
  // (scripts/c462-wiki-probe.py/2/3): EIGHT direct fa.wiki club articles via
  // the wikidata sitelinks, every one identity-verified from its own intro
  // — Argentinos Juniors → آرژانتینوس جونیورز («باشگاه فوتبال آرژانتینوس
  // جونیورز» pageid 44853348, «یک باشگاه فوتبال در شهر بوئنوس آیرس،
  // آرژانتین است»; جونیورز rides the file's OWN boca juniors form),
  // Atlético Tucumán → اتلتیکو توکومان («باشگاه فوتبال اتلتیکو توکومان»
  // pageid 44676322, «یک باشگاه فوتبال در سانتیاگو دوتوکومان، استان
  // توکومان، آرژانتین است»; the descriptor drops per the FC rule; توکومان
  // the article's OWN rendering, the city page توکومان 9499834), Gimnasia
  // LP → جیمناسیا لاپلاتا («باشگاه فوتبال جیمناسیا و اسگریما لاپلاتا»
  // pageid 43107433 — the article's OWN intro SHORT form «باشگاه فوتبال
  // جیمناسیا لاپلاتا» is what the literal "Gimnasia LP" rides, «از
  // قدیمی‌ترین باشگاه‌های فوتبال کشور آرژانتین در شهر لاپلاتا می‌باشد»;
  // لاپلاتا the fused spelling the article itself uses, the city pages
  // لا پلاتا 41536486 / لاپلاتا 6789648 documented), Huracán → هوراکان
  // («باشگاه فوتبال اتلتیکو هوراکان» pageid 41152768, «یک باشگاه فوتبال
  // در شهر بوئنوس آیرس کشور آرژانتین می‌باشد که در لیگ برتر فوتبال
  // آرژانتین بازی می‌کند»; the encyclopedia's OWN rendering هوراکان — the
  // اوراکان spelling family unused), Racing Club → راسینگ کلوب («باشگاه
  // فوتبال راسینگ» pageid 44298641 — the intro's OWN first words render the
  // full name «راسینگ کلوب آویاندا»; the literal "Racing Club" rides that
  // rendering minus the city, which also keeps the existing bare
  // racing → راسینگ mapping collision-free), Rosario Central →
  // روزاریو سنترال («باشگاه فوتبال روساریو سنترال» pageid 44294156, «یک
  // باشگاه فوتبال در شهر روزاریو، سانتا فه، آرژانتین است»), Vélez Sarsfield
  // → ولز سارسفیلد («باشگاه فوتبال ولز سارسفیلد» pageid 44298647, «یک
  // باشگاه فوتبال در شهر بوئنوس آیرس کشور آرژانتین می‌باشد»),
  // Independiente → ایندپندینته («باشگاه فوتبال ایندپندینته» pageid
  // 44891429, «باشگاه اتلتیکو ایندپندینته... در شهر آویاندا قرار دارد»; the
  // value rides the file's OWN independiente medellín → ایندپندینته form) —
  // plus Banfield → بانفیلد (the direct club article «باشگاه فوتبال
  // بانفیلد» pageid 43805809 found by probe 2 after the wikidata search hit
  // the CITY entity (بانفیلد city 41574058) — a wrong-entity artifact
  // superseded by the club article itself, identity-verified «یک باشگاه
  // فوتبال در شهر بانفیلد، بوئنوس آیرس کشور آرژانتین می‌باشد»); the 460
  // اودر-river precedent for the namesake anchors — Belgrano → بلگرانو (the
  // بلگرانو page 34223211 is a MENDOZA settlement — a wrong-city artifact
  // identity-excluded, the 461 لا پاز-Argentina lesson; the namesake anchor
  // مانوئل بلگرانو pageid 43803266, the man the Córdoba club is named for);
  // the city-title context pages (سانتا فه 24987262 for the Unión club of
  // Santa Fe, ریو کوارتو 41557532 for Estudiantes de Río Cuarto) documented
  // per the 461 Mérida pattern; the honest-read fallbacks (no fa.wiki
  // article under any spelling, the opensearch/wikidata gate dead — the 452
  // لویی / 455 آلتاخ / 457 لیوی بره / 460 پودهاله / 461 آلاکرانس
  // precedent): Deportivo Riestra → دپورتیوو ریسترا (دپورتیوو per the
  // file's OWN deportivo a coruña form), Independiente Rivadavia →
  // ایندپندینته ریواداویا (ایندپندینته per the file's OWN independiente
  // medellín form; the namesake article برناردینو ریواداویا MISSING —
  // probed and documented), Club Atlético Platense → پلاتنسه, Instituto →
  // انستیتو (the bare انستیتو page 31484932 extract-UNVERIFIABLE — not used
  // as an anchor per the 456 rule; the value rides the standard Persian
  // loanword for the Spanish word the club is named for), Estudiantes de
  // Río Cuarto → استودیانتس دی ریو کوارتو (استودیانتس per the file's OWN
  // bare estudiantes form, de→دی per the boca juniors de cali precedent),
  // Sarmiento → سارمینتو, Unión → اونیون (the file's OWN union → یونیون
  // convention covers the Italian/German/English forms — brescia/berlin/
  // st.gilloise; the Spanish Unión rides the encyclopedia's OWN اونیون
  // family the opensearch itself surfaced: اونیون (فرانش-کومته)، اونیون
  // پانامریکانا، اونیونه), Barracas Central → باراکاس سنترال (سنترال per
  // the file's OWN central coast mariners form), Defensa y Justicia →
  // دفنسا و خوستیسیا. Cache: matches v23 → v24 per the standing rule (fresh
  // cold window). Patrol: B4 re-anchored to the post-patch census read (the
  // loud-pool rule, the 445 precedent) + B26 NEW (four batch-21 witnesses
  // Persian in the live ±7 feed — the patrol now runs 65 checks). The
  // post-patch census + drift story live in the repo worklog card (the
  // 455-457 pattern).
  "deportivo riestra": "دپورتیوو ریسترا",
  "argentinos juniors": "آرژانتینوس جونیورز",
  "independiente rivadavia": "ایندپندینته ریواداویا",
  "atlético tucumán": "اتلتیکو توکومان",
  "club atlético platense": "پلاتنسه",
  "instituto": "انستیتو",
  "estudiantes de río cuarto": "استودیانتس دی ریو کوارتو",
  "gimnasia lp": "جیمناسیا لاپلاتا",
  "huracán": "هوراکان",
  "racing club": "راسینگ کلوب",
  "sarmiento": "سارمینتو",
  "rosario central": "روزاریو سنترال",
  "vélez sarsfield": "ولز سارسفیلد",
  "unión": "اونیون",
  "belgrano": "بلگرانو",
  "barracas central": "باراکاس سنترال",
  "defensa y justicia": "دفنسا و خوستیسیا",
  "independiente": "ایندپندینته",
  "banfield": "بانفیلد",
  // cycle-465: batch 22 — ALL 9 count>=3 single-country PAN names of the
  // 465 census (the live LPF Apertura wave) into TEAM_FA (the 446-pick
  // rule, the 464-card pin). The fresh census read distinct=1754 = EXACTLY
  // the documented 462 post-census (zero drift, rows 3210) and the top of
  // the pool is the documented TIE: PAN 9/27 = HON 9/27 — the 447
  // tie-break invoked (anchor quality, the RUS=GUA precedent): PAN carries
  // FIVE direct fa.wiki club articles vs HON's TWO club articles + the
  // خوتیکالپا CITY page (not a club anchor per the 452/462 rule) → PAN
  // harvested, HON waits for the next update. Anchors
  // (scripts/c465-wiki-probe.py/2, every one identity-verified from its
  // own intro): CD Árabe Unido → عربه یونیدو («باشگاه فوتبال عربه یونیدو»
  // pageid 43804828, «یک باشگاه فوتبال حرفه‌ای واقع در کلون، پاناما
  // است…»), CD Plaza Amador → پلازا آمادور («باشگاه فوتبال پلازا آمادور»
  // pageid 41460671, «یک باشگاه فوتبال پانامایی… قدیمی‌ترین تیم
  // پاناما»), Sporting San Miguelito → اسپورتینگ سن میگلیتو («باشگاه
  // فوتبال اسپورتینگ سن میگلیتو» pageid 44052583, «یک تیم فوتبال
  // حرفه‌ای پانامایی است»), Tauro FC → تائورو («باشگاه فوتبال تائورو»
  // pageid 41367386, «…در ناحیه پدرگال در شرق پاناماسیتی، پاناما…»),
  // San Francisco FC → سان فرانسیسکو («باشگاه فوتبال سان فرانسیسکو»
  // pageid 41367482, «یک تیم فوتبال حرفه‌ای واقع در لا چوررا، پاناما
  // است») — every value minus the باشگاه فوتبال prefix per the FC rule.
  // The honest-read fallbacks (no fa.wiki club article under any spelling,
  // the wikidata gate dead — the 452 لویی / 455 آلتاخ / 457 لیوی بره /
  // 460 پودهاله / 461 آلاکرانس / 462 ریسترا precedent): UMECIT FC →
  // اومسیت (no club entity found), CD Universitario → یونیورسیتاریو (the
  // club entity Q2212675 carries NO fawiki sitelink; the Peruvian
  // namesake family deliberately NOT used — the wrong-country artifact
  // documented), Herrera FC → هررا (the bare-loanword rule, the انستیتو
  // 462 precedent), Independiente de La Chorrera → ایندپندینته دی لا
  // چوررا (ایندپندینته per the file's OWN independiente medellín form,
  // de→دی per the boca juniors de cali / 462 precedent, لا چوررا rides
  // the San Francisco article's OWN intro «واقع در لا چوررا، پاناما»);
  // every name single-country PAN across the whole ±7 window, 27 live
  // leak rows covered, the collision gate clean: dupKeys=[] and zero
  // value collisions against the whole 1817-pair file (the five flagged
  // hits are the intentional league-name homoglyphs), 1817 → 1826 pairs.
  // Cache: matches v25 → v26 per the standing rule (fresh cold window).
  // Patrol: B4 re-anchored (the loud-pool rule, the 445 precedent) + B27
  // NEW (four batch-22 witnesses Persian in the live ±7 feed — the patrol
  // now runs 66 checks). The post-patch census + drift story live in the
  // repo worklog card (the 455-457 pattern).
  "cd árabe unido": "عربه یونیدو",
  "cd plaza amador": "پلازا آمادور",
  "sporting san miguelito": "اسپورتینگ سن میگلیتو",
  "umecit fc": "اومسیت",
  "tauro fc": "تائورو",
  "cd universitario": "یونیورسیتاریو",
  "herrera fc": "هررا",
  "independiente de la chorrera": "ایندپندینته دی لا چوررا",
  "san francisco fc": "سان فرانسیسکو",
  // cycle-466: batch 23 — ALL 9 count>=3 single-country HON names of the
  // 466 census (the live Liga Nacional Apertura wave) into TEAM_FA (the
  // 446-pick rule, the 465-card pin) — the UNBROKEN half of the PAN/HON
  // 9/27 tie (PAN won the 447 tie-break in 465 by anchor quality). The
  // pre-census read distinct=1745 = EXACTLY the documented 465 post-census
  // (zero drift, rows 3183) and the top of the pool is HON 9/27 (CZE/EST/
  // SWE/ISR/USA 8/24 next), every row Liga Nacional - Apertura.
  // THE FIRST ZERO-ANCHOR BATCH: the live probe (scripts/c466-wiki-probe.py)
  // found NO direct fa.wiki club article under any spelling — the رئال
  // اسپانیا title is the SPANISH CURRENCY page («واحد پول در اسپانیا بود تا
  // ۱۸۶۸», the 462 بلگرانو wrong-identity lesson), اتلتیکو ایندپندینته is a
  // REDIRECT to the Argentine باشگاه فوتبال ایندپندینته (the wrong-country
  // artifact the 465 probe itself warned about), جنسیس is the music/car
  // disambiguation page, ستاره سرخ the symbol page, خوتیکالپا the CITY page
  // («یک منطقهٔ مسکونی در هندوراس… استان اولانچو») — city-grounded spelling
  // per the 461 مریدا pattern, not a club anchor per the 452/462 rule.
  // ALL 9 honest phonetic reads (the 452 لویی / 455 آلتاخ / 457 لیوی بره /
  // 460 پودهاله / 461 آلاکرانس / 462 ریسترا / 465 اومسیت precedent), each on
  // the file's OWN convention: Estrella Roja → استریا روخا (estrella→استریا
  // per the villa→ویا ll-rule, roja→روخا j→خ), Atletico Independiente →
  // اتلتیکو ایندپندینته (اتلتیکو the OWN مورلیا/توکومان form, ایندپندینته the
  // OWN medellín form — deliberately DISTINCT from 462's bare ایندپندینته),
  // Lobos UPNFM → لوبوس یو‌پی‌ان‌اف‌ام (the acronym spelled out — TEAM_FA
  // values are pure Persian, the AFC group markers the only Latin values),
  // Genesis FC → جنسیس (the standard Persian rendering of the literal — the
  // disambiguation page itself uses جنسیس for the band/Hyundai), Real
  // España → رئال اسپانیا (رئال the OWN مادرید/بتیس form; the currency page
  // NOT used), Juticalpa → خوتیکالپا (the city-grounded spelling), CD
  // Choloma → چولوما (CD prefix dropped, the 465 عربه یونیدو/یونیورسیتاریو
  // precedent), Olancho FC → اولانچو (FC suffix dropped; the spelling rides
  // the city page's OWN intro «استان اولانچو»), Platense FC → دپورتیوو
  // پلاتنسه (the club's OWN full-name Club Deportivo prefix, deliberately
  // DISTINCT from 462's Argentine پلاتنسه — the value-collision gate would
  // refuse the bare form; the 462 C2 note anticipated this harvest).
  // Byte-verify (scripts/c466-batch23-verify.py): PRE 9/9 verified=0 bad,
  // every key byte-exact from the live feed (the ñ key rides the file's OWN
  // logroñés/südtirol precedent), every name single-country HON across the
  // whole ±7 window, 27 live leak rows covered (sample ids 6365900-6365904);
  // the collision gate clean: dupKeys=[] and zero proposed-value collisions
  // against the whole 2248-pair file (the five flagged valueCollisions are
  // the intentional league-name homoglyphs, the 465 precedent), 1826 → 1835
  // TEAM_FA pairs. Cache: matches v26 → v27 per the standing rule. Patrol:
  // B4 re-anchored 1745→1736 (the loud-pool rule, the 445 precedent) + B28
  // NEW (four batch-23 witnesses Persian in the live ±7 feed — the patrol
  // now runs 67 checks). The post-patch census + drift story live in the
  // repo worklog card (the 455-457 pattern).
  "estrella roja": "استریا روخا",
  "atletico independiente": "اتلتیکو ایندپندینته",
  "lobos upnfm": "لوبوس یو‌پی‌ان‌اف‌ام",
  "genesis fc": "جنسیس",
  "real españa": "رئال اسپانیا",
  "juticalpa": "خوتیکالپا",
  "cd choloma": "چولوما",
  "olancho fc": "اولانچو",
  "platense fc": "دپورتیوو پلاتنسه",
  // cycle-467: batch 24 — ALL 8 count>=3 single-country EST names of the
  // 467 census (the live Meistriliiga wave) into TEAM_FA (the 446-pick
  // rule, the 466-card pin) — the WINNER of the FIVE-WAY CZE/EST/ISR/SWE/
  // USA 8/24 tie by the 447 tie-break (anchor quality, the RUS=GUA and
  // PAN=HON precedents): EST carries FOUR direct identity-verified fa.wiki
  // club articles vs ISR 3, SWE 3, USA 2 (one of them the CANADIAN مونترال
  // playing in MLS per the feed's own USA grouping, the 389 rule), CZE 0.
  // The pre-census read distinct=1736 = EXACTLY the documented 466
  // post-census (zero drift, rows 3156). Anchors
  // (scripts/c467-wiki-probe.py, every one identity-verified from its own
  // intro): FC Kuressaare → کورساره (pageid 36019310, «یک باشگاه فوتبال در
  // شهر کورساره، استونی است»), FCI Levadia → لوادیا تالین (pageid 44678815,
  // «باشگاهی در شهر تالین، استونی است»), Narva Trans → ناروا ترانس
  // (pageid 27014475), Nõmme JK Kalju → نومه کالیو (pageid 44763589) —
  // every value minus the باشگاه فوتبال prefix per the FC rule. The
  // honest-read fallbacks (no fa.wiki club article under any spelling, the
  // 466 zero-anchor precedent): Nõmme United → نومه یونایتد (نومه rides the
  // OWN نومه کالیو article rendering; یونایتد the standard loanword), Paide
  // Linnameeskond → پایده لیننامه‌سکوند (honest read), Pärnu JK Vaprus →
  // پارنو واپروس (پارنو the standard city rendering; JK dropped per the FC
  // rule), Tammeka → تامکا (honest read; the file's OWN تالین
  // double-consonant simplification precedent); the õ/ä keys ride the
  // file's OWN südtirol/köln/árabe/españa precedent. Byte-verify
  // (scripts/c467-batch24-verify.py): PRE 8/8 verified=0 bad, every name
  // single-country EST across the whole ±7 window, 24 live leak rows
  // covered (sample ids 1000007987-1000007991); the collision gate clean:
  // dupKeys=[] and zero proposed-value collisions against the whole
  // 2257-pair file (the five flagged valueCollisions are the intentional
  // league-name homoglyphs, the 465/466 precedent), 1835 → 1843 TEAM_FA
  // pairs. Cache: matches v27 → v28 per the standing rule. Patrol: B4
  // re-anchored 1736→1728 (the loud-pool rule, the 445 precedent) + B29
  // NEW (four batch-24 witnesses Persian in the live ±7 feed — the patrol
  // now runs 68 checks). The post-patch census + drift story live in the
  // repo worklog card (the 455-457 pattern).
  "fc kuressaare": "کورساره",
  "fci levadia": "لوادیا تالین",
  "narva trans": "ناروا ترانس",
  "nõmme jk kalju": "نومه کالیو",
  "nõmme united": "نومه یونایتد",
  "paide linnameeskond": "پایده لیننامه‌سکوند",
  "pärnu jk vaprus": "پارنو واپروس",
  "tammeka": "تامکا",
  // cycle-470: batch 25 — ALL 8 count>=3 single-country USA names of the
  // 470 census (the live MLS wave) into TEAM_FA (the 446-pick rule, the
  // 469-card pin) — the WINNER of the FOUR-WAY CZE/SWE/ISR/USA 8/24 tie by
  // the FRESH 447 re-read (scripts/c467-wiki-probe.py re-run, the 456
  // live-re-read precedent: the anchor map MOVED since 467's own read —
  // fa.wiki has grown): USA carries FOUR direct identity-verified fa.wiki
  // club articles (کلمبوس کرو 44340016 «یک تیم فوتبال در شهر کلمبوس،
  // اوهاییو در آمریکا» / سن خوزه ارث‌کوئیکز 44340008 / سیاتل ساندرز
  // 44340011 / ونکوور وایتکپس 44340045 — the last the CANADIAN city per its
  // own intro, riding the MLS grouping of the feed itself, the 389 rule +
  // the 467 مونترال line) vs SWE 3, CZE 2 (زبرویوفکا برنو + یک. اسلواتسکو
  // — NEW articles since the 467 zero-read), ISR 2. The other four clubs
  // carry their OWN identity-verified articles found under plausible
  // spellings (scripts/c470-wiki-probe.py — the 467 read had missed them):
  // CF Montréal → مونترال (44340044, «باشگاه فوتبال مونترال (به فرانسوی:
  // Club de Foot Montréal) با نام سابق مونترال ایمپکت… در کانادا… ام‌ال اس»
  // — the feed's own USA grouping, the 389 rule), FC Dallas → دالاس
  // (44340005, the intro-carrying article; the bare اف‌سی دالاس title is
  // the empty-intro redirect — the 466 wrong-identity lesson), Nashville SC
  // → نشویل (44340019 — the article's OWN ش spelling, NOT the press ناشویل
  // form), Sporting Kansas City → اسپورتینگ کانزاس سیتی (44339998, the
  // intro-carrying title's SPACE form; the ZWNJ-titled twin is the
  // redirect) — every value minus the باشگاه فوتبال prefix per the FC rule,
  // the OWN full Sporting prefix kept (the 466 دپورتیوو پلاتنسе rule). The
  // é key rides the file's OWN südtirol/köln/árabe/españa precedent.
  // Byte-verify (scripts/c470-batch25-verify.py): PRE 8/8 verified=0 bad,
  // every name single-country USA across the whole ±7 window, 24 live leak
  // rows covered (sample ids 5071456-5071469); the collision gate clean:
  // dupKeys=[] and zero proposed-key/value collisions against the whole
  // 2265-pair file (the five flagged valueCollisions the intentional
  // league-name homoglyphs, the 465/466/467 precedent), 1843 → 1851
  // TEAM_FA pairs. Cache: matches v28 → v29 per the standing rule. Patrol:
  // B4 re-anchored 1728→1720 (the loud-pool rule, the 445 precedent) + B30
  // NEW (four batch-25 witnesses Persian in the live ±7 feed — the patrol
  // now runs 69 checks).
  "cf montréal": "مونترال",
  "columbus crew": "کلمبوس کرو",
  "fc dallas": "دالاس",
  "nashville sc": "نشویل",
  "san jose earthquakes": "سن خوزه ارث‌کوئیکز",
  "seattle sounders fc": "سیاتل ساندرز",
  "sporting kansas city": "اسپورتینگ کانزاس سیتی",
  "vancouver whitecaps": "ونکوور وایتکپس",
  // cycle-471: batch 26 — ALL 8 count>=3 single-country SWE names of the
  // 471 census (the live Allsvenskan/Superettan wave) into TEAM_FA (the
  // 446-pick rule) — the WINNER of the CZE/SWE/ISR 8/24 THREE-WAY tie by
  // the FRESH 447 re-read (scripts/c471-wiki-probe.py + c471-wiki-probe2.py
  // + the direct fa existence/identity probes, the 456 live-re-read
  // precedent: the anchor map MOVED again since the 470 read): SWE carries
  // FIVE direct identity-verified fa.wiki club articles (الفسبورگ «باشگاه
  // فوتبال در کشور سوئد… شهر بوروس… ۱۹۰۴» / دیگرفوش «دیگرفوش آی‌اف یک
  // باشگاه فوتبال سوئدی… آلسنسکان» / بروماپویکارنا «یک باشگاه فوتبال مستقر
  // در بروما (سوئد)… لیگ برتر فوتبال سوئد» / هالمستاد «Halmstads BK…
  // هالمستاد، بخش هاللاند، سوئد» / هامارابی 43805003 «Hammarby Fotboll… یک
  // باشگاه فوتبال سوئدی است که در سال ۱۹۱۵ در استکهلم تأسیس شده‌است») vs
  // CZE 4 (زبرویوفکا برنو / هرادتس کرالووه / ملادا بولسلاف / یک. اسلواتسکو
  // — the تپلیتسه 43208205 and ییهلاوا 41212923 pages are the CITY
  // articles, NOT club anchors, the 466 خوتیکالپا wrong-identity lesson),
  // ISR 3 (اشدود / هاپوئل تل‌آویو / بنی یهودا تل آویو). The Hammarby
  // spelling lesson: the direct hit came under the هاماربی spelling — which
  // is a REDIRECT to باشگاه فوتبال هامارابی (the 466 اتلتیکو ایندپندینته
  // redirect lesson) — so the intro-carrying target's OWN title wins: هامارابی
  // (the c470 دالاس lesson). Values minus the باشگاه فوتبال prefix per the
  // FC rule; BK dropped per the 447 کراسنودار/اورنبورگ suffix-drop rule.
  // Zero-anchor honest reads (the 452/455/457/460/461/462/465/466
  // precedent): Landskrona BoIS → لاندسکرونا بوایز (BoIS the acronym →
  // بوایز, the 466 UPNFM spelled-out rule; no article under any probed
  // spelling), Varbergs BoIS FC → واربرگ بوایز (the CITY article واربرگ
  // 40333636 grounds the toponym per the 461 مریدا city-title rule — the
  // city's OWN spelling over the press واربریس, the 466 اولانچو pattern;
  // FC + genitive absorbed), Västerås SK → وستروس اس‌کی (no article under
  // any probed spelling — pure phonetic; SK the acronym spelled with the
  // ZWNJ per the 466 UPNFM rule). The ä key rides the file's OWN
  // südtirol/köln/árabe/españa/montreal-é precedent. Byte-verify
  // (scripts/c471-batch26-verify.py): PRE 8/8 verified=0 bad, every name
  // single-country SWE across the whole ±7 window, 24 live leak rows
  // covered (sample ids 5107637-5125663); the collision gate clean:
  // dupKeys=[] and zero proposed-key/value collisions against the whole
  // 2273-pair file (the five flagged valueCollisions the intentional
  // league-name homoglyphs, the 465/466/467/470 precedent), 1851 → 1859
  // TEAM_FA pairs. Cache: matches v29 → v30 per the standing rule. Patrol:
  // B4 re-anchored 1720→1712 (the loud-pool rule, the 445 precedent) + B31
  // NEW (four batch-26 witnesses Persian in the live ±7 feed — the patrol
  // now runs 70 checks).
  "brommapojkarna": "بروماپویکارنا",
  "degerfors": "دیگرفوش",
  "elfsborg": "الفسبورگ",
  "halmstads bk": "هالمستاد",
  "hammarby": "هامارابی",
  "landskrona bois": "لاندسکرونا بوایز",
  "varbergs bois fc": "واربرگ بوایز",
  "västerås sk": "وستروس اس‌کی",
  // cycle-472: batch 27 — ALL 8 count>=3 single-country CZE names of the
  // 472 census (the live Czech 2. Liga/ČFL wave) into TEAM_FA (the
  // 446-pick rule) — the WINNER of the CZE/ISR 8/24 TWO-WAY tie by the
  // FRESH 447 re-read (scripts/c472-wiki-probe.py + c472-wiki-probe2.py +
  // c472-wiki-probe3.py + c472-wiki-probe4.py, the 456 live-re-read
  // precedent): CZE carries FOUR direct identity-verified fa.wiki club
  // articles (زبرویوفکا برنو 43783062 «FC Zbrojovka Brno… شهر برنو، کشور
  // جمهوری چک… ۱۹۱۳» / هرادتس کرالووه 32598818 «FC Hradec Králové… شهر
  // هرادتس کرالووه» / یک. اسلواتسکو 43123547 «1. FC Slovácko… لیگ دسته
  // اول فوتبال جمهوری چک» / ملادا بولسلاف 44786128 «FK Mladá Boleslav…
  // شهر ملادا بولسلاف… لیگ برتر فوتبال جمهوری چک… ۱۹۰۲» — the last the
  // 471 documented anchor re-verified fresh) vs ISR 3 (بنی یهودا تل آویو
  // 43798549 / هاپوئل تل‌آویو 44406164 / اشدود 43349375 — the ISR tranche
  // waits; the bare اشدود page is the CITY, the club article is باشگاه
  // فوتبال اشدود, and کریات یام 42126668 the CITY too). The تپلیتسه
  // 43208205 and ییهلاوا 41212923 pages re-confirmed the CITY articles,
  // NOT club anchors (the 466 خوتیکالپا lesson). Zero-anchor honest reads
  // (the 452/455/457/460/461/462/465/466/471 precedent): Artis Brno →
  // آرتیس برنو (no article under any probed spelling; the برنو toponym
  // rides the زبرویوفکا برنو anchor's OWN intro — the city's own
  // rendering, the واربرگ 461 pattern), SK Prostějov → پروستییوف (SK
  // dropped per the 447 کراسنودار/اورنبورگ suffix rule; pure phonetic —
  // پروستیوف/باشگاه فوتبال پروستییوف/اف‌سی پروستییوف all missing),
  // Teplice → تپلیتسه (the CITY article 43208205's OWN spelling grounds
  // the toponym per the 461 مریدا city-title rule — تپلیسه the press
  // form loses; FK absorbed; no CLUB article under any probed spelling:
  // باشگاه فوتبال تپلیسه/اف‌کی تپلیتسه both missing), Vysočina Jihlava →
  // وی‌سوچینا ییهلاوا (the CITY article ییهلاوا 41212923's OWN spelling
  // grounds the toponym; Vysočina pure phonetic with the ZWNJ joint, the
  // 466 UPNFM rule). Slovácko → یک. اسلواتسکو (the anchor title's OWN
  // rendering minus the باشگاه فوتبال prefix — the 470 دالاس lesson; the
  // 466 پلاتنسه identity-distinctness rule). The á/ě/č keys ride the
  // file's OWN südtirol/köln/árabe/españa/montreal-é/ä precedent.
  // Byte-verify (scripts/c472-batch27-verify.py): PRE 8/8 verified=0 bad,
  // every name single-country CZE across the whole ±7 window, 24 live
  // leak rows covered (sample ids 5943697-6420191); the collision gate
  // clean: dupKeys=[] and zero proposed-key/value collisions against the
  // whole 2281-pair file (the five flagged valueCollisions the
  // intentional league-name homoglyphs, the
  // 465/466/467/470/471 precedent), 1859 → 1867 TEAM_FA pairs. Cache:
  // matches v30 → v31 per the standing rule. Patrol: B4 re-anchored
  // 1712→1704 (the loud-pool rule, the 445 precedent) + B32 NEW (four
  // batch-27 witnesses Persian in the live ±7 feed — the patrol now runs
  // 71 checks).
  "artis brno": "آرتیس برنو",
  "fc zbrojovka brno": "زبرویوفکا برنو",
  "hradec králové": "هرادتس کرالووه",
  "mladá boleslav": "ملادا بولسلاف",
  "sk prostějov": "پروستییوف",
  "slovácko": "یک. اسلواتسکو",
  "teplice": "تپلیتسه",
  "vysočina jihlava": "وی‌سوچینا ییهلاوا",
  // cycle-475: batch 28 — ALL 8 count>=3 single-country ISR names of the
  // 475 census (the live Liga Leumit/Liga Alef wave) into TEAM_FA (the
  // 446-pick rule) — the waiting half of the 472 CZE/ISR 8/24 two-way
  // tie, ALONE at the top since 472 (the 473/474 rotation lines), probed
  // fresh (scripts/c475-census.py + c475-wiki-probe.py +
  // c475-wiki-probe2.py + c475-wiki-probe3.py + the رعانانا single-title
  // probe, the 447 live-re-read lesson — fa.wiki MOVED under our feet):
  // THREE direct identity-verified fa.wiki club articles, ALL re-verified
  // fresh with the two Tel Aviv articles RENAMED upstream since the 472
  // read (the SAME pageids 43798549/44406164 now carry the
  // باشگاه‌پrefixed titles; the bare spellings MISSING — the
  // intro-carrying target's OWN title wins, the هامارابی/دالاس lesson;
  // the keys ride the FC rule minus the باشگاه فوتبال prefix anyway):
  // بنی یهودا تل آویو 43798549 «باشگاه فوتبال بنی یهودا تل آویو… یک
  // باشگاه فوتبال است که در شهر تل آویو کشور اسرائیل» / هاپوئل تل‌آویو
  // 44406164 «…یکی از باشگاه‌های فوتبال… که در تل‌آویو قرار دارد…
  // ۱۹۲۷» / اشدود (FC Ashdod) 43349375 «باشگاه فوتبال اشدود… ام اس
  // اشدود» (the bare اشدود 43597406 stays the CITY — re-confirmed
  // fresh). CITY-grounded toponyms (the 461 مریدا city-title rule):
  // Kiryat Yam → کریات یام (the CITY 42126668's OWN spelling,
  // re-verified fresh), Raanana → رعانانا (the CITY 41090895 — the
  // en.langlink spelling; the رعاننا/رعانا press forms BOTH missing, the
  // single-title probe settled it), Jaffa → یافا (the CITY 44825068).
  // Zero-anchor honest reads (the 452..472 precedent): Hapoel Kfar
  // Shalem → هاپوئل کفر شالم (کفر شالم/باشگاه فوتبال کفر شالم both
  // missing — pure phonetic, the 466 UPNFM rule), Ironi Modiin → ایرونی
  // مودیعین (مودیعین/مودیعین-مکابیم-رعوت/هاپوئل مودیعین all missing —
  // pure phonetic; the en-search hit Tel Aviv was the WRONG identity,
  // rejected, the 466 پلاتنسه rule), Maccabi Kabilio Jaffa → مکابی
  // کابیلیو یافا (کابیلیو pure phonetic; the مکابی یافا spelling is the
  // IDENTITY-DISTINCT club Maccabi Jaffa and MISSING anyway — the
  // distinctness rule protected the key). Hapoel Raanana → هاپوئل
  // رعانانا (هاپوئل pure phonetic + the grounded CITY toponym).
  // Byte-verify (scripts/c475-batch28-verify.py): PRE 8/8 verified 0
  // bad, every name single-country ISR across the whole ±7 window, 24
  // live leak rows covered (sample ids 6031122-6446063); the collision
  // gate clean: dupKeys=[] and zero proposed key/value collisions
  // against the whole 2289-pair file (the five flagged valueCollisions
  // the intentional league-name homoglyphs, the
  // 465/466/467/470/471/472 precedent), 1867 → 1875 TEAM_FA pairs.
  // Cache: matches v31 → v32 per the standing rule (fresh cold window).
  // Patrol: B4 re-anchored 1704→1691 (the loud-pool rule, the 445
  // precedent) + B33 NEW (four batch-28 witnesses Persian in the live
  // ±7 feed — the patrol now runs 72 checks).
  "bnei yehuda tel aviv": "بنی یهودا تل آویو",
  "fc ashdod": "اشدود",
  "hapoel kfar shalem": "هاپوئل کفر شالم",
  "hapoel raanana": "هاپوئل رعانانا",
  "hapoel tel aviv": "هاپوئل تل‌آویو",
  "ironi modiin": "ایرونی مودیعین",
  "kiryat yam": "کریات یام",
  "maccabi kabilio jaffa": "مکابی کابیلیو یافا",
  // cycle-477: batch 29 — ALL 7 count>=3 single-country ALB names of the
  // FRESH 477 census into TEAM_FA (the 446-pick rule) — the fresh 447
  // re-read (scripts/c477-census.py, the 447 live-re-read lesson) DISSOLVED
  // the 476 rotation line's GRE/BUL/DEN/ALB field with the window move (GRE
  // now 4, BUL 2, DEN 5 — its (W) side GONE from the window) and surfaced
  // the NEW two-way tie ALB 7 = PAR 7 (ENG's 7 carries FOUR (W) sides — the
  // 435 rule leaves it 2 effective; ESP 6 -> 2 effective — no (W) tranche
  // in the race). Tie-break (the 472 CZE-vs-ISR precedent): ALB 4 DIRECT
  // identity-verified fa.wiki club articles vs PAR 1 (سرو پورتنیو 41367502
  // — scripts/c477-wiki-probe.py) → ALB harvested, PAR waits. The FOUR
  // direct anchors, all extracts verified Albanian-club fresh: KF Tirana →
  // تیرانا (باشگاه فوتبال تیرانا 43804587 «…یک باشگاه فوتبال در شهر
  // تیرانا، آلبانی است… ۱۹۲۰… ۲۷ قهرمانی سوپر لیگ» — the club named after
  // its city, the FC rule minus the prefix, the fc ashdod → اشدود
  // precedent) / FC Dinamo City → دینامو تیرانا (wikidata Q34120 KS Dinamo
  // Tirana — the SAME club RENAMED Dinamo City upstream; the article
  // باشگاه فوتبال دینامو تیرانا 42185043 keeps the old name «(انگلیسی: FK
  // Dinamo Tirana)… در تیرانا، آلبانی» — the anchor's OWN title wins, the
  // 475 RENAMED-upstream lesson) / Partizani → پارتیزانی تیرانا (باشگاه
  // فوتبال پارتیزانی تیرانا 43805559 «FK Partizani Tirana… ۱۹۴۶… آلبانی»)
  // / Vllaznia → ولازنیا اشکودر (باشگاه فوتبال ولازنیا اشکودر 35742201
  // «ولازنیا اشکودر… سوپر لیگ فوتبال آلبانی… قدیمی‌ترین باشگاه کشور
  // آلبانی»). Zero-anchor honest reads (the 452..475 precedent): Elbasani
  // → البسان (the club's own article باشگاه فوتبال البسان 3990515 EXISTS —
  // «(انگلیسی: KF Elbasani)… در الباسان پایه‌گذاری شده» — but its extract's
  // country adjective is an upstream TYPO «اسلواکی»; the strict
  // wrong-country rule REJECTS it as a direct anchor, the title still
  // evidences the spelling) / Skënderbeu → اسکندربو (no club article
  // anywhere — scripts/c477-wiki-probe3.py: the bare and full spellings
  // MISSING; the spelling grounded by the club's OWN stadium article
  // ورزشگاه اسکندربو 5322302 whose extract names the club «باشگاه فوتبال
  // اسکندربو کورچه» — home club named inside the related article) / Vora →
  // وورا (no wikidata entity, no fa.wiki search hits — pure phonetic, the
  // 466 UPNFM rule). The کورچا title trap dodged (the fa.wiki کورچا page
  // is a SPANISH settlement — never consulted). Byte-verify
  // (scripts/c477-batch29-verify.py): PRE 7/7 verified 0 bad, every name
  // single-country ALB across the whole ±7 window (3 rows each, sample ids
  // 5944198-5944202); the collision gate clean: dupKeys=[] and zero
  // proposed key/value collisions against the whole 2297-pair file (the
  // five flagged valueCollisions the intentional league-name homoglyphs,
  // the 465..475 precedent), 1875 → 1882 TEAM_FA pairs. Cache: matches v32
  // → v33 per the standing rule (fresh cold window). Patrol: B4 re-anchored
  // 1691→1671 (the loud-pool rule, the 445 precedent — the post-patch
  // census MEASURED 1671/2959, the −8 = the 7 harvested + 1 window drift;
  // the pre-patch census read 1679/2982) + B34 NEW (four
  // batch-29 witnesses Persian in the live ±7 feed — the patrol now runs
  // 73 checks).
  "elbasani": "البسان",
  "fc dinamo city": "دینامو تیرانا",
  "kf tirana": "تیرانا",
  "partizani": "پارتیزانی تیرانا",
  "skënderbeu": "اسکندربو",
  "vllaznia": "ولازنیا اشکودر",
  "vora": "وورا",
  // cycle-480: batch 30 — ALL 7 count>=3 single-country PAR names of the
  // FRESH 480 census into TEAM_FA (the 446-pick rule) — the 479 rotation
  // line's declared field: PAR 7 ALONE at the top, the 477 tie loser
  // finally harvesting. The fresh census (scripts/c480-census.py, the 447
  // live-re-read lesson): pre-patch distinct=1671/raw_rows=2959 == the B4
  // anchor EXACTLY (zero drift), RUS 6 / ESP 6 (with a (W) side) / CRC 6
  // behind, ENG 7 but FOUR (W) sides → 2 effective (the 435 rule) — no
  // (W) tranche in the race, PAR harvested whole. The Wikimedia 429 wall
  // (documented honestly): the probes hit a ~50-minute IP-wide rate limit
  // (fa.wiki action+REST, en.wiki, wikidata ALL HTTP 429 from 06:13 to
  // ~07:04 Tehran, gentle single-title retries try1..try4 logged) —
  // cleared at the 51-minute mark; the full probe re-ran at 1.8s cadence
  // (scripts/c480-wiki-probe.py + c480-wiki-probe2.py + the single-title
  // re-probe of the three empty-intro pages). The TWO direct anchors,
  // both extracts verified Paraguayan-club fresh: Cerro Porteño → سرو
  // پورتنیو (Q914086 → باشگاه فوتبال سرو پورتنیو 41367502 — the
  // 477-documented pageid RENAMED upstream to the باشگاه-پrefixed form
  // since the 477 read, the bare spelling now a separate EMPTY stub
  // 6956335 — the anchor's OWN title wins, the 475 RENAMED-upstream
  // lesson; the FC rule minus the prefix; extract «…یک باشگاه فوتبال
  // حرفه‌ای اهل پاراگوئه است… ۱۹۱۲…») / Guaraní → گوارانی (باشگاه فوتبال
  // گوارانی (پاراگوئه) 6305735 «یک تیم فوتبال از پاراگوئه است که در محله
  // پینوزا در آسونسیون… ۱۹۰۳…» — the FC rule minus the prefix AND the
  // (پاراگوئه) disambiguator; the bare گوارانی 7003177 an empty stub,
  // never consulted). City-grounded toponym (the 461 مریدا rule):
  // Sportivo San Lorenzo → اسپورتیوو سن لورنزو (سن لورنزو (پاراگوئه)
  // 1071973 the city article grounds the toponym; its intro EMPTY — the
  // title still evidences the spelling, the 477 Elbasani rule). Zero-
  // anchor honest reads (the 452..477 precedent; the wikidata entities
  // prove the Paraguayan identity AND the fa-sitelink absence, the fa
  // search hits all irrelevant player pages — the 466 UPNFM rule): 2 de
  // Mayo → ۲ د مایو (Q1926287 Club Sportivo 2 de Mayo) / Rubio Ñú → روبیو
  // نیو (Q603085) / Sportivo Ameliano → اسپورتیوو آملیانو (Q15294976) /
  // Sportivo Trinidense → اسپورتیوو ترینیدنس (Q2980011). Byte-verify
  // (scripts/c480-batch30-verify.py): PRE 7/7 verified 0 bad, every name
  // single-country PAR across the whole ±7 window (3 rows each, sample
  // ids 1000017447-1000017452); the collision gate clean: dupKeys=[] and
  // zero proposed key/value collisions against the whole 2304-pair file
  // (the five flagged valueCollisions the intentional league-name
  // homoglyphs, the 465..477 precedent), 2304 → 2311 file pairs. Cache:
  // matches v33 → v34 per the standing rule (fresh cold window). Patrol:
  // B4 re-anchor + B35 NEW (four batch-30 witnesses Persian in the live
  // ±7 feed — the patrol now runs 74 checks).
  "2 de mayo": "۲ د مایو",
  "cerro porteño": "سرو پورتنیو",
  "guaraní": "گوارانی",
  "rubio ñú": "روبیو نیو",
  "sportivo ameliano": "اسپورتیوو آملیانو",
  "sportivo san lorenzo": "اسپورتیوو سن لورنزو",
  "sportivo trinidense": "اسپورتیوو ترینیدنس",
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
