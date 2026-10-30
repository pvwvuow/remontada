#!/usr/bin/env python3
# cycle-242 central edit script — the additive mirror of 241 end-to-end
# («کارت‌های زرد تیم‌ها», the deep-file family's TWENTY-SECOND sibling).
# Byte-exact ASCII-anchored replaces (the «» Edit-tool workaround, the
# cycle239-gate-edit.py pattern). Every anchor asserted count==1 BEFORE
# any write; on any failure the script exits non-zero WITHOUT writing.
import sys

def apply(path, edits):
    with open(path, encoding="utf-8") as f:
        t = f.read()
    for i, (old, new, tag) in enumerate(edits):
        n = t.count(old)
        if n != 1:
            print(f"FAIL {path} [{tag}]: anchor count={n} (expected 1)")
            sys.exit(1)
        t = t.replace(old, new, 1)
        print(f"ok   {path} [{tag}]")
    with open(path, "w", encoding="utf-8") as f:
        f.write(t)

# ---------------- 1) src/lib/fotmob.ts ----------------
IFACE = '''/** cycle-242 additive: one «کارت‌های زرد تیم‌ها» row — the deep-file
 *  family's TWENTY-SECOND sibling and its FOURTH TEAM-PARTICIPANT member:
 *  the team-side yellow-card surface (the player-level 50/176 cards
 *  family, the team twin). The "Yellow cards" TEAM category carries its
 *  own fetchAllUrl → data.fotmob.com
 *  stats/{id}/season/{sid}/total_yel_card_team.json (live-probed
 *  2026-10-30, UA Chrome/124, scripts/cycle242-probe.sh: WIDE files on
 *  all six domestic globalMerge leagues — laliga 20 Getafe 33.0 / pl 20
 *  AFC Bournemouth 22.0 / seriea 20 Fiorentina 20.0 / bundesliga 18
 *  Borussia Mönchengladbach 21.0 / ligue1 18 Nice 19.0 / ucl 36 Club
 *  Brugge 9.0 rows; portugal 18 Académico Viseu 27.0 with the top-3
 *  25,25 tie probed for breadth); persiangulf AND mas honestly absent —
 *  the 237/241 absence pair EXACTLY (pg's feed carries ONE team
 *  category, Goals per match; mas's feed carries FOUR — Goals per
 *  match / Goals conceded per match / Clean sheets / Red cards — and
 *  yellow is not one, probed), so NO league-aware floor is needed — the
 *  honest-empty pair degrades to [] upstream of the guard, the 237/241
 *  pattern (unlike the 240 clean-sheet sibling, mas does not serve this
 *  category at all). INTEGER-VALUED floats (probed int on every serving
 *  file) → the 215/220/231/235/236 integer convention: storage never
 *  rounds, the pill renders String(value) dir=ltr (33.0 renders «۳۳»).
 *  Upstream Rank keeps COMPETITION ties verbatim (laliga rank 5,6 on
 *  25.0 / 15,16,16 on 17.0 probed) — the merge re-ranks POSITIONALLY
 *  like every sibling. ParticiantId is ALWAYS 0 (teams carry TeamId) →
 *  dedup by TeamId. NO badge twin and NO global-merge participation BY
 *  DESIGN (the 237 team-surface rule); the block rides the league page
 *  only, rows link /team/{teamId}. SEASON-AWARE (the 124/…/236 class):
 *  the 2020/21 laliga raw serves its OWN file — season/15585, 20 rows,
 *  Getafe 114.0 / Celta Vigo 104.0 / Atletico Madrid 100.0 — frozen,
 *  the 202 anchor pattern, DISTINCT from the current 33.0 (Getafe tops
 *  BOTH eras — the dirtiest team in the file's history, probed). Wide
 *  files (18-36 rows, above the FULL_LIST_HEALTHY_MIN floor) → the
 *  STANDARD guard, NO exemption; always present (possibly []); feeds
 *  without the team category degrade honestly to []. */
export interface TeamYellowCardEntry {
  rank: number;
  name: string;  // the participant IS the team (raw English, the honesty base)
  /** honest Persian team name (teamFa) — raw English fallback, the standings convention. */
  nameFa?: string;
  teamId: number;  // FotMob team id → links to /team/[id]
  teamYellowCards: number;  // StatValue VERBATIM — integer-valued float (33.0), the 215/220/231/235/236 convention, never rounded
}

'''

FIELD = '''  /** cycle-242 additive: «کارت‌های زرد تیم‌ها» rides the mapped payload —
   *  the deep-file family's TWENTY-SECOND sibling and its FOURTH
   *  TEAM-PARTICIPANT member (the team-side yellow-card surface).
   *  Integer-valued floats verbatim (the 215/220/231/235/236 convention
   *  — String() pill); the block rides the league page only, rows link
   *  /team/[id]; persiangulf AND mas honestly degrade to [] (the
   *  237/241 absence pair, probed); always present (possibly []).
   *  REQUIRED since the v29 bump — old v28 rows lack it and would keep
   *  the section hidden for a full TTL generation. */
  teamYellowCards: TeamYellowCardEntry[];
'''

FUNC = '''/** cycle-242: the full-file fetch for the team yellow-cards block — the
 *  exact 241 getFullTeamPossession mirror one category over:
 *  stats/{id}/season/{sid}/total_yel_card_team.json (live-probed
 *  2026-10-30, UA Chrome/124 — "Yellow cards" TEAM category,
 *  INTEGER-valued floats, wide files on the six domestics 18-36 rows,
 *  portugal 18; persiangulf AND mas honestly absent — the 237/241
 *  absence pair, probed: mas's feed carries FOUR team categories and
 *  yellow is not one). Same cache + standard guard as the siblings; the
 *  honest-empty pair degrades to [] upstream of the guard — NO
 *  league-aware floor needed. Season-aware like every sibling (the
 *  2020/21 laliga raw serves season/15585, 20 rows, Getafe 114.0,
 *  frozen). Feeds without the team category degrade to []. */
export async function getFullTeamYellowCards(leagueKey: string, season?: string): Promise<TeamYellowCardEntry[]> {
  try {
    return await cached(
      `fullTeamYellowCards:v1:${leagueKey}:${season || "cur"}`,
      // Standard guard (the 210/…/241 class): yellow-card TEAM files are
      // WIDE (18-36 rows probed) — above the family floor, so thin means
      // "the fetch was dropped" and re-probes in 90s. Honest-empty feeds
      // (no "Yellow cards" TEAM category — persiangulf AND mas, probed)
      // degrade to [] upstream of the guard and keep the normal TTL.
      (rows) => (rows.length >= FULL_LIST_HEALTHY_MIN ? 60 * 60_000 : 90_000),
      async () => {
        const { raw } = await getLeagueRaw(leagueKey, season);
        const teams = (raw.stats as { teams?: FMStatBlockTeam[] } | undefined)?.teams;
        const cat = teams?.find?.((t) => /^yellow cards$/i.test(t.header || ""));
        const url = cat?.fetchAllUrl;
        if (!url || !/^https:\\/\\/data\\.fotmob\\.com\\//.test(url)) return [];
        const data = await fetchDataFile<{ TopLists?: { StatList?: FMStatFullRow[] }[] }>(url);
        const rows = data?.TopLists?.[0]?.StatList || [];
        const out: TeamYellowCardEntry[] = [];
        const seen = new Set<number>();
        for (const r of rows) {
          const tid = r.TeamId;
          // teams carry TeamId; ParticiantId is ALWAYS 0 on team files
          if (!r.ParticipantName || tid == null || seen.has(tid)) continue;
          seen.add(tid);
          out.push({
            rank: r.Rank ?? out.length + 1,  // upstream rank kept verbatim — the merge re-ranks positionally
            name: r.ParticipantName,
            nameFa: teamFa(r.ParticipantName) || undefined,  // the honest-team contract, teamFa edition
            teamId: tid,
            teamYellowCards: r.StatValue ?? 0,  // VERBATIM — the 215/220/231/235/236 integer convention, never rounded
          });
          if (out.length >= 10) break;
        }
        return out;
      },
    );
  } catch {
    return [];  // upstream hiccup / unavailable league — never break the payload
  }
}

'''

MERGE = '''    // cycle-242: the team yellow-cards block («کارت‌های زرد تیم‌ها») — the
    // deep-file family's TWENTY-SECOND sibling and its FOURTH
    // TEAM-PARTICIPANT member: the team-side yellow-card surface — straight
    // from the live total_yel_card_team.json probe (UA Chrome/124,
    // 2026-10-30, scripts/cycle242-probe.sh): WIDE files on all six
    // domestic globalMerge leagues (laliga 20 Getafe 33.0 / pl 20 AFC
    // Bournemouth 22.0 / seriea 20 Fiorentina 20.0 / bundesliga 18
    // Borussia Mönchengladbach 21.0 / ligue1 18 Nice 19.0 / ucl 36 Club
    // Brugge 9.0 rows; portugal 18 Académico Viseu 27.0 with the top-3
    // 25,25 tie probed for breadth); persiangulf AND mas honestly absent
    // (the 237/241 absence pair exactly — pg's feed carries ONE team
    // category, Goals per match; mas's feed carries FOUR — Goals per
    // match / Goals conceded per match / Clean sheets / Red cards — and
    // yellow is not one, probed). INTEGER-VALUED floats (probed int on
    // every serving file) → the 215/220/231/235/236 integer convention:
    // storage never rounds, the pill renders String(value) dir=ltr
    // (33.0 renders «۳۳»). Upstream Rank keeps COMPETITION ties verbatim
    // (laliga rank 5,6 on 25.0 / 15,16,16 on 17.0 probed); the merge
    // re-ranks POSITIONALLY like every sibling. ParticiantId is ALWAYS 0
    // (teams carry TeamId) → dedup by TeamId. NO badge twin and NO
    // global-merge participation BY DESIGN (the 237 team-surface rule);
    // the block rides the league page only, rows link /team/{teamId} (the
    // standings-view contract). SEASON-AWARE (the 124/…/236 class): the
    // 2020/21 laliga raw serves its OWN file — season/15585, 20 rows,
    // Getafe 114.0 / Celta Vigo 104.0 / Atletico Madrid 100.0 — frozen,
    // the 202 anchor pattern, DISTINCT from the current 33.0 (Getafe
    // tops BOTH eras, probed). The honest-name contract rides the
    // EXISTING teamFa map (zero new PLAYER_NAME_FA entries) + the teamFa
    // edition of the 170 read-time freshener line. Additive mirror of
    // 241 end-to-end: TeamYellowCardEntry + the REQUIRED teamYellowCards
    // field on the mapped payload + getFullTeamYellowCards
    // (fullTeamYellowCards:v1, the STANDARD guard — NO league-aware
    // floor needed: the honest-empty pair pg+mas degrades to [] upstream
    // of the guard, the 237/241 pattern) + the team top-3-first merge
    // (dedup by TEAM id, teamYellowCards DESC, top-10, POSITIONAL
    // re-rank) + standings:v28→v29 (the 52/…/241 additive-shape
    // convention) + the /api/topscorers/[leagueKey] route field + the
    // league-page block «کارت‌های زرد تیم‌ها» placed right after مالکیت
    // توپ تیم‌ها so the FOUR team-side blocks read together while the
    // player→team pair and the keeper QUINTET stay untouched — the older
    // gates' relative-order asserts are index-inequality-based so the
    // insertion provably keeps them green (all re-ran green) — with
    // data-testid=tyc-row.
    const ycardTeamEntries: TeamYellowCardEntry[] = statTeamCategory(raw, /^yellow cards$/i)
      .map((p, i) => ({
        rank: i + 1, name: String(p.name || ""), nameFa: teamFa(p.name) || undefined,
        teamId: p.teamId ?? 0, teamYellowCards: Number(p.stat?.value ?? 0),
      }))
      .sort((a, b) => b.teamYellowCards - a.teamYellowCards || a.name.localeCompare(b.name))
      .map((e, i) => ({ ...e, rank: i + 1 }));
    const fullTeamYellowCards = await getFullTeamYellowCards(leagueKey, requestedSeason);
    const enrichedYcIds = new Set(ycardTeamEntries.map((r) => r.teamId).filter((id) => id > 0));
    const mergedTeamYellowCards = [...ycardTeamEntries, ...fullTeamYellowCards.filter((r) => r.teamId <= 0 || !enrichedYcIds.has(r.teamId))]
      .sort((a, b) => b.teamYellowCards - a.teamYellowCards || a.name.localeCompare(b.name))
      .slice(0, 10)
      .map((e, i) => ({ ...e, rank: i + 1 }));

'''

GUARD = '''      // cycle-242: the team yellow-cards block joins the guard family —
      // total_yel_card_team.json is WIDE (probed 18-36 rows on the six
      // serving domestic leagues), so a thin merged list means the fetch
      // was dropped; re-probes in 90s. Honest-empty feeds (no "Yellow
      // cards" TEAM category — persiangulf AND mas, the 237/241 absence
      // pair, probed: mas's feed carries FOUR team categories and yellow
      // is not one) degrade to [] upstream of the guard and keep the
      // normal TTL — NO league-aware floor needed (unlike the 240
      // clean-sheet sibling, mas does not serve this category at all).
      !(Array.isArray(mapped.teamYellowCards) && mapped.teamYellowCards.length > 0 && mapped.teamYellowCards.length < FULL_LIST_HEALTHY_MIN) &&
'''

VER = '''    // convention).
    // cycle-242: v29 — the team yellow-cards block («کارت‌های زرد تیم‌ها»)
    // joins the mapped payload as a REQUIRED field; old v28 rows lack it
    // and would keep the new section hidden for up to a full TTL
    // generation. Whole key bumps (the 52/…/241 additive-shape
    // convention).
'''

fotmob_edits = [
    ("  teamPossession: number;  // StatValue VERBATIM — percent one decimal (69.4), the 221 percent convention, never rounded\n}\n",
     "  teamPossession: number;  // StatValue VERBATIM — percent one decimal (69.4), the 221 percent convention, never rounded\n}\n\n" + IFACE,
     "E1 interface"),
    ("  teamPossession: TeamPossessionEntry[];\n",
     "  teamPossession: TeamPossessionEntry[];\n" + FIELD,
     "E2 payload field"),
    ("export async function getFullPenaltySaves(leagueKey: string, season?: string): Promise<PenaltySavesEntry[]> {",
     FUNC + "export async function getFullPenaltySaves(leagueKey: string, season?: string): Promise<PenaltySavesEntry[]> {",
     "E3 fetcher"),
    ("    // cycle-176: the league's own card leaders ride the mapped payload —",
     MERGE + "    // cycle-176: the league's own card leaders ride the mapped payload —",
     "E4 merge block"),
    ("      teamPossession: mergedTeamPossession,\n",
     "      teamPossession: mergedTeamPossession,\n      teamYellowCards: mergedTeamYellowCards,\n",
     "E5 assembly"),
    ("standings:v28:${leagueKey}:${season || \"cur\"}", "standings:v29:${leagueKey}:${season || \"cur\"}", "E6a key bump"),
    ("      !(Array.isArray(mapped.teamPossession) && mapped.teamPossession.length > 0 && mapped.teamPossession.length < FULL_LIST_HEALTHY_MIN) &&\n",
     "      !(Array.isArray(mapped.teamPossession) && mapped.teamPossession.length > 0 && mapped.teamPossession.length < FULL_LIST_HEALTHY_MIN) &&\n" + GUARD,
     "E6b guard"),
    ("    // convention).\n    await cached(`standings:v29:",
     "    " + VER.strip().replace("\n    ", "\n    ") .replace(VER.strip(), VER.strip()) + "    await cached(`standings:v29:",
     "E6c version comment"),
]
# fix E6c: build the replacement cleanly (VER already ends with newline)
fotmob_edits[-1] = (
    "    // convention).\n    await cached(`standings:v29:",
    "    " + VER.strip() + "\n    await cached(`standings:v29:",
    "E6c version comment",
)
apply("src/lib/fotmob.ts", fotmob_edits)

# ---------------- 2) src/app/api/topscorers/[leagueKey]/route.ts ----------------
ROUTE = '''      // cycle-242 additive: «کارت‌های زرد تیم‌ها» rides the SAME cached
      // payload — the deep-file family's TWENTY-SECOND sibling and its
      // FOURTH TEAM-PARTICIPANT member: the team-side yellow-card surface
      // (INTEGER values verbatim — the 215/220/231/235/236 convention,
      // String() pill; season-aware like the sisters; honest [] on
      // persiangulf AND mas — the 237/241 absence pair, probed); old
      // consumers never read this field (the 108 rule).
      teamYellowCards: st.teamYellowCards,
'''
apply("src/app/api/topscorers/[leagueKey]/route.ts", [
    ("      teamPossession: st.teamPossession,\n",
     "      teamPossession: st.teamPossession,\n" + ROUTE,
     "E7 route field"),
])

# ---------------- 3) src/components/remontada/league-scorers-view.tsx ----------------
VIEW = '''
      {/* cycle-242: کارت‌های زرد تیم‌ها — the deep-file family's
          TWENTY-SECOND sibling and its FOURTH TEAM-PARTICIPANT member:
          the team-side yellow-card surface.
          stats/{id}/season/{sid}/total_yel_card_team.json — live-probed
          2026-10-30 (UA Chrome/124): ALL SIX domestic globalMerge leagues
          serve it (laliga 20 Getafe 33.0 / pl 20 AFC Bournemouth 22.0 /
          seriea 20 Fiorentina 20.0 / bundesliga 18 Borussia
          Mönchengladbach 21.0 / ligue1 18 Nice 19.0 / ucl 36 Club Brugge
          9.0 rows; portugal 18 Académico Viseu 27.0 with the top-3 25,25
          tie probed for breadth); persiangulf AND mas honestly absent
          (the 237/241 absence pair exactly — mas's feed carries FOUR team
          categories and yellow is not one). INTEGER-VALUED floats (probed
          int on every serving file) → the 215/220/231/235/236 integer
          convention: the pill renders String(value) dir=ltr (33.0
          renders «۳۳»). Upstream Rank keeps COMPETITION ties verbatim
          (laliga 5,6 / 15,16,16) — the merge re-ranks POSITIONALLY.
          SEASON-AWARE: the 2020/21 laliga raw serves its OWN file
          (Getafe 114.0 / Celta Vigo 104.0 — frozen, the 202 anchor
          pattern, distinct from the current 33.0). The honest-name
          contract rides the EXISTING teamFa map — zero new
          PLAYER_NAME_FA entries. Rows link /team/{teamId} (the
          standings-view contract). Placed right after مالکیت توپ تیم‌ها so
          the FOUR team-side blocks read together while the player→team
          pair and the keeper QUINTET stay untouched — the older gates'
          relative-order asserts are index-inequality-based so the
          insertion provably keeps them green. Honest absence when the
          feed has no "Yellow cards" team category → the section simply
          hides. */}
      {data && !loading && (data.teamYellowCards || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <rect x="7" y="3.5" width="10" height="15" rx="1.6" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">کارت‌های زرد تیم‌ها</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">انضباط — سطح تیم</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.teamYellowCards || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                  </span>
                  <span dir="ltr" className="shrink-0 min-w-[46px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(String(r.teamYellowCards))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="tyc-row">
                  {r.teamId > 0 ? (
                    <Link href={`/team/${r.teamId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
                      {inner}
                    </Link>
                  ) : (
                    <div className={cls}>{inner}</div>
                  )}
                </li>
              );
            })}
          </ol>
        </div>
      )}
'''
apply("src/components/remontada/league-scorers-view.tsx", [
    ("\n\n      {/* cycle-232:",
     VIEW + "\n      {/* cycle-232:",
     "E8 view block"),
])

# ---------------- 4) scripts/cycle238-hunt.sh — census 20→21 ----------------
hunt_edits = [
    ("), iXG=h2s.indexOf(",
     "), iYC=h2s.indexOf('کارت‌های زرد تیم‌ها'), iXG=h2s.indexOf(",
     "E9a iYC probe"),
    ("iPOS>iCS&&iXG>iPOS", "iPOS>iCS&&iYC>iPOS&&iXG>iYC", "E9b order chain"),
    ("const tposs=document.querySelectorAll('[data-testid=tposs-row]').length;",
     "const tposs=document.querySelectorAll('[data-testid=tposs-row]').length; const tyc=document.querySelectorAll('[data-testid=tyc-row]').length;",
     "E9c tyc const"),
    ("{order,quintet,rows,tcs,tposs,vbroken,h2n:h2s.length}",
     "{order,quintet,rows,tcs,tposs,tyc,vbroken,h2n:h2s.length}",
     "E9d json"),
    (r"""grep -q '"tposs":10'""",
     r"""grep -q '"tposs":10' && echo "$B1" | tr -d '\\' | grep -q '"tyc":10'""",
     "E9e tyc grep"),
    (r"""'"h2n":20'""", r"""'"h2n":21'""", "E9f h2n"),
    ("+ 10 tposs-rows + zero real overflow", "+ 10 tposs-rows + 10 tyc-rows + zero real overflow", "E9g msg rows"),
    ("the THREE team-side blocks adjacent + keeper QUINTET", "the FOUR team-side blocks adjacent + keeper QUINTET", "E9h msg blocks"),
    ("possession) — the assert evolves with the family BY DESIGN]",
     "possession → 21 (242, team yellow-cards)] — the assert evolves with the family BY DESIGN",
     "E9i header census"),
    ("FULL 20-block census", "FULL 21-block census", "E9j census label"),
]
apply("scripts/cycle238-hunt.sh", hunt_edits)

print("ALL EDITS APPLIED")
