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
  /** cycle-140: explicit false = excluded from the TWO global merges
   *  (getAllTopScorers race + getAllCardLeaders). Reason is contract, not
   *  taste: the cycle-132 race intersects allSeasons across participating
   *  feeds — UECL's 6-season feed (2021/2022+) would SHRINK the 12-season
   *  window to 6. The flag does NOT affect any per-league surface: standings,
   *  fixtures, bracket, titles, /topscorers/uecl (reads getStandings
   *  directly), players hub, search index all stay live. */
  globalMerge?: boolean;
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
  // cycle-147: Saudi Pro League (league 536) — the 8 table-team spellings the
  // 2026/2027 feed serves that the block above missed (hyphen/short variants
  // are byte-exact from the live rows) + 23 more transfer-side names from the
  // 100-entry feed sweep. Zero shape change — additive keys only.
  "al-ettifaq": "الاتفاق", "al diriyah": "الدرعیه", "al hazem": "الهزمة",
  "al-faisaly": "الفیصلی", "al-fayha": "الفیحا", "al fateh fc": "الفتح",
  "neom sc": "نیوم", "abha": "ابها", "al akhdoud": "الأخدود",
  "al najma": "النجمة", "al taee": "الطایی", "al anwar": "الأنوار",
  "al jabalain": "الجبلین", "al-jeel": "الجیل",
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
};

export function countryFa(name: string | undefined | null): string {
  if (!name) return "";
  return COUNTRY_FA[name.toLowerCase().trim()] || name;
}

// FotMob team logo (kept after countryFa — cycle 45 additions above)
export function fotmobTeamLogo(teamId: number | string): string {
  return `https://images.fotmob.com/image_resources/logo/teamlogo/${teamId}.png`;
}
