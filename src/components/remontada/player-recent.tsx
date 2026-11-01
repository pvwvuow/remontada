"use client";
// ------------------------------------------------------------------
// Remontada — recent-matches island for the player profile (cycle-86)
// The profile itself stays a pure server component; this small client
// island adds the interactive bits on top of the same SSR'd archive
// (side filter club vs national team + show-all toggle). Markup is
// still present in the initial HTML — client components SSR too.
// Data: playerData.recentMatches, full archive (probed: 68–70 rows).
// ------------------------------------------------------------------
import Link from "next/link";
import { useState } from "react";
import type { PlayerRecentMatch, PlayerRecentSide, PlayerLogLeague } from "@/lib/fotmob";
import { faDecimal, faDigits, jalaliShort } from "@/lib/format";
import { cn } from "@/lib/utils";
import { TeamLogo } from "./team-logo";

const SHOWN = 10;

// cycle-356: knockout-round labels — EXACTLY the codes probed live
// (7 players / 396 archive rows, 2026-11-01: 1/32 ×1, 1/16 ×9, 1/8 ×13,
// 1/4 ×10, 1/2 ×11, final ×8, bronze ×2 = the third-place decider).
// Any future upstream code renders NO badge (honest absence) until a
// probe collects and maps it — no invented labels.
const STAGE_FA: Record<string, string> = {
  "1/32": "یک‌سی‌ودوم نهایی",
  "1/16": "یک‌شانزدهم نهایی",
  "1/8": "یک‌هشتم نهایی",
  "1/4": "یک‌چهارم نهایی",
  "1/2": "نیمه‌نهایی",
  final: "فینال",
  bronze: "بازی رده‌بندی",
};

function ResultBadge({ r }: { r: "W" | "D" | "L" }) {
  const tone =
    r === "W"
      ? "bg-mint/10 text-mint border-mint/30"
      : r === "D"
        ? "bg-steel/10 text-steel border-steel/30"
        : "bg-red-500/10 text-red-400 border-red-500/30";
  return (
    <span
      className={cn(
        "w-[18px] h-[18px] rounded-[4px] border text-[9px] font-black flex items-center justify-center leading-none shrink-0",
        tone
      )}
      title={r === "W" ? "برد" : r === "D" ? "مساوی" : "باخت"}
    >
      {r === "W" ? "ب" : r === "D" ? "م" : "پ"}
    </span>
  );
}

export function RecentMatchesSection({
  recent,
  teams,
  logLeagues,
}: {
  recent: PlayerRecentMatch[];
  teams: PlayerRecentSide[];
  logLeagues: PlayerLogLeague[];
}) {
  const [team, setTeam] = useState<number | null>(null);
  const [all, setAll] = useState(false);
  // cycle-355: the competition filter («فیلتر مسابقات») — composes with the
  // side filter as AND. Picking a side resets it so a hidden league can
  // never strand the list at an empty state (every visible chip is backed
  // by ≥1 row of the current side view).
  const [league, setLeague] = useState<number | null>(null);

  const teamRows = team ? recent.filter((m) => m.sideId === team) : recent;
  const filtered = league ? teamRows.filter((m) => m.leagueId === league) : teamRows;
  const visible = all ? filtered : filtered.slice(0, SHOWN);
  const multiSide = teams.length > 1;

  // league chips: the server set (upstream matchFilters.leagues ∩ rows)
  // keeps name + order; counts are recomputed against the CURRENT side
  // view so a chip never shows a number the list can't back. The row only
  // renders when the current view spans >1 competition (a single-league
  // archive needs no filter).
  const viewLeagueIds = new Set(
    teamRows.map((m) => m.leagueId).filter((id): id is number => id !== null)
  );
  const leagueChips = logLeagues.filter((l) => viewLeagueIds.has(l.leagueId));
  const showLeagueRow = viewLeagueIds.size > 1;

  const pick = (id: number | null) => {
    setTeam(id);
    setLeague(null); // side switch resets the competition filter (AND safety)
    setAll(false); // a fresh filter starts collapsed again
  };

  const pickLeague = (id: number | null) => {
    setLeague(id);
    setAll(false);
  };

  return (
    <section className="glass-card overflow-hidden" aria-label="بازی‌های اخیر" data-testid="player-recent">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft text-[12px] font-black">
        بازی‌های اخیر{" "}
        {recent.length > 0 && (
          <span className="text-muted-foreground font-bold text-[10.5px]">
            ({faDigits(recent.length)} بازی اخیر)
          </span>
        )}
      </header>
      {recent.length === 0 ? (
        <p className="text-center text-muted-foreground text-sm py-8">بازی اخیری برای این بازیکن ثبت نشده است.</p>
      ) : (
        <>
          {multiSide && (
            /* Eighth-generation tap-hit-row: ::after extends 6px horizontally --
               gap-x-1.5 (6px) tiles it exactly against neighbour pills; gap-y-2 (8px)
               tiles the 4px+4px vertical extension of wrapped rows; pb-1 (4px) lets the
               downward zone end exactly at the first match row's top edge so the
               interactive list is never covered (cycle-24 meet-exactly convention). */
            <div className="flex flex-wrap gap-x-1.5 gap-y-2 px-3 sm:px-4 pt-2.5 pb-1" role="tablist" aria-label="فیلتر تیم بازیکن">
              <button
                type="button"
                onClick={() => pick(null)}
                className={cn(
                  "tap-hit-row rounded-md border px-2 py-0.5 text-[10px] font-black transition-colors cursor-pointer",
                  team === null ? "border-sky-soft/40 bg-sky-soft/10 text-sky-soft" : "border-border bg-white/[0.03] text-muted-foreground hover:text-foreground"
                )}
              >
                همه <span className="tabular-persian">({faDigits(recent.length)})</span>
              </button>
              {teams.map((t) => (
                <button
                  key={t.id}
                  type="button"
                  onClick={() => pick(t.id)}
                  className={cn(
                    "tap-hit-row rounded-md border px-2 py-0.5 text-[10px] font-black transition-colors cursor-pointer",
                    team === t.id ? "border-sky-soft/40 bg-sky-soft/10 text-sky-soft" : "border-border bg-white/[0.03] text-muted-foreground hover:text-foreground"
                  )}
                >
                  {t.fa}{" "}
                  <span className="tabular-persian">
                    ({faDigits(recent.filter((m) => m.sideId === t.id).length)})
                  </span>
                </button>
              ))}
            </div>
          )}
          {showLeagueRow && (
            /* cycle-355: the competition filter row — same tap-hit-row
               geometry as the side row above (the meet-exactly convention).
               Chips come from the server logLeagues set (upstream
               matchFilters.leagues ∩ archive rows); counts live against the
               current side view. */
            <div className="flex flex-wrap gap-x-1.5 gap-y-2 px-3 sm:px-4 pt-2.5 pb-1" role="tablist" aria-label="فیلتر مسابقات آرشیو" data-testid="player-recent-leagues">
              <button
                type="button"
                onClick={() => pickLeague(null)}
                className={cn(
                  "tap-hit-row rounded-md border px-2 py-0.5 text-[10px] font-black transition-colors cursor-pointer",
                  league === null ? "border-chart-3/40 bg-chart-3/10 text-chart-3" : "border-border bg-white/[0.03] text-muted-foreground hover:text-foreground"
                )}
              >
                همهٔ مسابقه‌ها <span className="tabular-persian">({faDigits(teamRows.length)})</span>
              </button>
              {leagueChips.map((l) => (
                <button
                  key={l.leagueId}
                  type="button"
                  onClick={() => pickLeague(l.leagueId)}
                  className={cn(
                    "tap-hit-row rounded-md border px-2 py-0.5 text-[10px] font-black transition-colors cursor-pointer",
                    league === l.leagueId ? "border-chart-3/40 bg-chart-3/10 text-chart-3" : "border-border bg-white/[0.03] text-muted-foreground hover:text-foreground"
                  )}
                >
                  {l.fa} <span className="tabular-persian">({faDigits(teamRows.filter((m) => m.leagueId === l.leagueId).length)})</span>
                </button>
              ))}
            </div>
          )}
          <ul className="glass-list">
            {visible.map((m) => {
              const jd = jalaliShort(m.utcTime);
              return (
                <li key={m.id}>
                  <Link
                    href={`/match/${m.id}`}
                    prefetch={false}
                    className="glass-row-hover group flex items-center gap-2.5 px-3 sm:px-4 py-2.5"
                  >
                    {m.result ? <ResultBadge r={m.result} /> : <span className="w-[18px] shrink-0" aria-hidden />}
                    <span className="text-[11px] tabular-persian font-black text-muted-foreground w-12 text-center shrink-0" dir="ltr">
                      {m.homeScore !== null && m.awayScore !== null ? `${faDigits(m.homeScore)} - ${faDigits(m.awayScore)}` : "—"}
                    </span>
                    <span className="flex items-center gap-1.5 min-w-0 flex-1">
                      {multiSide && team === null && m.sideName && (
                        <span className="shrink-0 rounded-md border border-border bg-white/[0.04] px-1.5 py-px text-[9px] font-bold text-muted-foreground max-w-[64px] truncate">
                          {m.sideName}
                        </span>
                      )}
                      <TeamLogo id={m.opponentId} alt="" size={16} />
                      <span className="truncate text-[12px] font-bold group-hover:text-sky-soft transition-colors">
                        {m.isHome ? "میزبان" : "بیرون"} · {m.opponent}
                      </span>
                      {m.stage && STAGE_FA[m.stage] && (
                        <span
                          data-testid="player-recent-stage"
                          title="مرحلهٔ حذفی"
                          className="text-[9px] font-bold text-muted-foreground border border-border rounded px-1 py-px shrink-0"
                        >
                          {STAGE_FA[m.stage]}
                        </span>
                      )}
                      {m.onBench && !m.played && (
                        <span className="text-[9px] font-bold text-muted-foreground border border-border rounded px-1 py-px shrink-0">روی نیمکت</span>
                      )}
                      {m.potm && <span className="text-[9px] font-black text-chart-3 shrink-0" title="بهترین بازیکن زمین">★</span>}
                    </span>
                    <span className="hidden sm:flex items-center gap-2 shrink-0 text-[10px] text-muted-foreground tabular-persian">
                      {m.goals > 0 && (
                        <span className="font-black text-mint" title="گل">⚽ {faDigits(m.goals)}</span>
                      )}
                      {m.assists > 0 && (
                        <span className="font-bold" title="پاس گل">🅰 {faDigits(m.assists)}</span>
                      )}
                      {m.yellow > 0 && <span className="w-2 h-2.5 rounded-[2px] bg-amber-400 inline-block" title="کارت زرد" />}
                      {m.red > 0 && <span className="w-2 h-2.5 rounded-[2px] bg-red-500 inline-block" title="کارت قرمز" />}
                      {m.minutes !== null && m.played && <span title="دقیقه بازی">{faDigits(m.minutes)}′</span>}
                    </span>
                    <span className="sm:hidden flex items-center gap-1.5 shrink-0 text-[10px] tabular-persian">
                      {m.goals > 0 && <span className="font-black text-mint">⚽{faDigits(m.goals)}</span>}
                      {m.rating && <span className="font-black text-chart-3">{faDecimal(m.rating)}</span>}
                    </span>
                    <span className="text-[9.5px] text-muted-foreground/80 tabular-persian shrink-0 w-14 text-end">
                      {jd.day} {jd.month}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
          {filtered.length > SHOWN && (
            <button
              type="button"
              onClick={() => setAll((v) => !v)}
              className="mx-auto block py-2.5 text-[10.5px] font-bold text-sky-soft hover:text-foreground transition-colors cursor-pointer"
            >
              {all ? "نمایش کمتر" : `نمایش همهٔ ${faDigits(filtered.length)} بازی`}
            </button>
          )}
        </>
      )}
    </section>
  );
}
