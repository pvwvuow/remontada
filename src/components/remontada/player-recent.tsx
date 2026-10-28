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
import type { PlayerRecentMatch, PlayerRecentSide } from "@/lib/fotmob";
import { faDigits, jalaliShort } from "@/lib/format";
import { cn } from "@/lib/utils";
import { TeamLogo } from "./team-logo";

const SHOWN = 10;

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
}: {
  recent: PlayerRecentMatch[];
  teams: PlayerRecentSide[];
}) {
  const [team, setTeam] = useState<number | null>(null);
  const [all, setAll] = useState(false);

  const filtered = team ? recent.filter((m) => m.sideId === team) : recent;
  const visible = all ? filtered : filtered.slice(0, SHOWN);
  const multiSide = teams.length > 1;

  const pick = (id: number | null) => {
    setTeam(id);
    setAll(false); // a fresh filter starts collapsed again
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
            <div className="flex flex-wrap gap-1.5 px-3 sm:px-4 pt-2.5" role="tablist" aria-label="فیلتر تیم بازیکن">
              <button
                type="button"
                onClick={() => pick(null)}
                className={cn(
                  "rounded-md border px-2 py-0.5 text-[10px] font-black transition-colors cursor-pointer",
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
                    "rounded-md border px-2 py-0.5 text-[10px] font-black transition-colors cursor-pointer",
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
                        <span className="shrink-0 rounded-md border border-border bg-white/[0.04] px-1.5 py-px text-[8.5px] font-bold text-muted-foreground max-w-[64px] truncate">
                          {m.sideName}
                        </span>
                      )}
                      <TeamLogo id={m.opponentId} alt="" size={16} />
                      <span className="truncate text-[12px] font-bold group-hover:text-sky-soft transition-colors">
                        {m.isHome ? "میزبان" : "بیرون"} · {m.opponent}
                      </span>
                      {m.onBench && !m.played && (
                        <span className="text-[8.5px] font-bold text-muted-foreground border border-border rounded px-1 py-px shrink-0">روی نیمکت</span>
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
                      {m.rating && <span className="font-black text-chart-3">{faDigits(m.rating)}</span>}
                    </span>
                    <span className="text-[9.5px] text-muted-foreground/70 tabular-persian shrink-0 w-14 text-end">
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
