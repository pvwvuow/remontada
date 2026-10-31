"use client";

// ------------------------------------------------------------------
// Remontada — cup knockout bracket view (cycle-56 «براکت جام‌ها»)
// Horizontal round columns (RTL flow: first round on the right), each
// matchup = its legs (with per-leg scores) + aggregate + winner chip.
// Undrawn matchups show the draw date instead — honest empty state.
// ------------------------------------------------------------------
import Link from "next/link";
import type { BracketMatchup, BracketLeg, LeagueBracketData } from "@/lib/fotmob";
import { faDigits, jalaliShort } from "@/lib/format";
import { cn } from "@/lib/utils";

function LegRow({ leg, isFinal }: { leg: BracketLeg; isFinal: boolean }) {
  const homeWin = leg.home.winner === true;
  const awayWin = leg.away.winner === true;
  const inner = (
    <>
      <span className={cn("flex items-center justify-end gap-1.5 min-w-0 font-semibold text-[12px]", awayWin && "text-muted-foreground/80", homeWin && "text-[#eaf4ff]")}>
        <span className="truncate">{leg.home.name}</span>
      </span>
      <span className={cn("flex flex-col items-center min-w-[58px] shrink-0")}>
        <span className={cn("font-black text-[12.5px] tabular-persian rounded-md px-2 py-0.5 border", leg.finished ? "text-[#e0efff] bg-[#a9cdf611] border-[color:var(--glass-border-soft)]" : "text-foreground/70 bg-white/[0.03] border-[color:var(--glass-border-soft)]")}>
          {leg.home.score ?? "—"} : {leg.away.score ?? "—"}
        </span>
      </span>
      <span className={cn("flex items-center gap-1.5 min-w-0 font-semibold text-[12px]", homeWin && "text-muted-foreground/80", awayWin && "text-[#eaf4ff]")}>
        <span className="truncate">{leg.away.name}</span>
      </span>
    </>
  );
  if (leg.matchId) {
    return (
      <Link href={`/match/${leg.matchId}`} prefetch={false} className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 px-3 py-2 glass-row-hover transition-colors">
        {inner}
      </Link>
    );
  }
  return <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 px-3 py-2">{inner}</div>;
}

function MatchupCard({ m }: { m: BracketMatchup }) {
  // tie with played/drawn legs → legs + aggregate + qualified chip
  if (m.legs.length > 0) {
    const winnerName = m.winnerId != null && m.winnerId !== 0
      ? (m.winnerId === m.home.id ? m.home.name : m.away.name)
      : null;
    const showAgg = m.aggHome != null && m.aggAway != null;
    return (
      <div className="glass-card overflow-hidden">
        <div className="flex flex-col divide-y divide-[color:var(--glass-hairline)]">
          {m.legs.map((leg, i) => (
            <LegRow key={leg.matchId || i} leg={leg} isFinal={false} />
          ))}
        </div>
        {(showAgg || winnerName) && (
          <div className="px-3 py-1.5 border-t border-[color:var(--glass-hairline)] bg-white/[0.02] flex items-center justify-between gap-2">
            {showAgg && (
              <span className="text-[10px] font-bold text-muted-foreground tabular-persian">
                مجموع: {faDigits(m.aggHome as number)}–{faDigits(m.aggAway as number)}
              </span>
            )}
            {winnerName && (
              <span className="text-[10px] font-black text-mint">صعود: {winnerName}</span>
            )}
          </div>
        )}
      </div>
    );
  }
  // undrawn tie → draw date (honest placeholder)
  const draw = m.drawDate ? jalaliShort(m.drawDate) : null;
  return (
    <div className="glass-card border-dashed px-3 py-2.5 flex flex-col items-center gap-0.5 text-center">
      <span className="text-[11px] font-bold text-muted-foreground">قرعه هنوز نریخته</span>
      {draw && (
        <span className="text-[10px] text-muted-foreground/80 tabular-persian">
          قرعه: {draw.weekday} {draw.day} {draw.month}
        </span>
      )}
    </div>
  );
}

export function LeagueBracket({ data }: { data: LeagueBracketData }) {
  if (!data.rounds?.length) {
    return null;
  }
  return (
    <div className="flex gap-3 overflow-x-auto pb-2 -mx-1 px-1" aria-label="براکت حذفی">
      {data.rounds.map((r) => (
        <section key={r.stage} className="w-[250px] sm:w-[270px] shrink-0 flex flex-col gap-2" aria-label={r.stageFa}>
          <h3 className="text-[11.5px] font-black text-[#b6cce3] px-1 flex items-center gap-1.5 shrink-0">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-soft/80" aria-hidden />
            {r.stageFa}
            <span className="text-[9.5px] font-bold text-muted-foreground/80 tabular-persian">({faDigits(r.matchups.length)} دیدار)</span>
          </h3>
          <div className="flex flex-col gap-2">
            {r.matchups.map((m, i) => (
              <MatchupCard key={i} m={m} />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
