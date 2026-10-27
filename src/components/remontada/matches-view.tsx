"use client";

// ------------------------------------------------------------------
// Remontada — live matches view (day navigation + league groups)
// ------------------------------------------------------------------
import Link from "next/link";
import { useMemo } from "react";
import type { LeagueGroup, NormMatch } from "@/lib/fotmob";
import { faDigits, jalaliShort, offsetDateISO, tehranTime } from "@/lib/format";
import { cn } from "@/lib/utils";

export { tehranTime };

function StatusBadge({ m }: { m: NormMatch }) {
  if (m.cancelled) {
    return (
      <span className="text-[11px] font-bold text-muted-foreground bg-muted px-2 py-1 rounded-lg whitespace-nowrap">
        لغو شده
      </span>
    );
  }
  if (m.live) {
    const min = m.minute || "";
    const numMatch = /^\d+/.exec(min);
    return (
      <span className="inline-flex items-center gap-1.5 text-[11px] font-black text-red-400 bg-red-500/10 border border-red-500/30 px-2 py-1 rounded-lg whitespace-nowrap tabular-persian">
        <span className="live-dot w-1.5 h-1.5 rounded-full bg-red-500 inline-block" />
        {min ? (numMatch ? `${faDigits(min)}` : min) : "زنده"}
      </span>
    );
  }
  if (m.finished) {
    return (
      <span className="text-[11px] font-bold text-muted-foreground px-2 py-1 whitespace-nowrap">
        پایان
      </span>
    );
  }
  return (
    <span className="text-[11px] font-bold text-foreground/80 px-2 py-1 whitespace-nowrap tabular-persian">
      {tehranTime(m.utcTime)}
    </span>
  );
}

function MatchRow({ m }: { m: NormMatch }) {
  const showScore = m.started && !m.cancelled;
  const homeWin = showScore && m.home.score !== null && m.away.score !== null && m.home.score > m.away.score;
  const awayWin = showScore && m.home.score !== null && m.away.score !== null && m.away.score > m.home.score;

  return (
    <Link
      href={`/match/${m.id}`}
      className="group grid grid-cols-[52px_1fr_auto_1fr_28px] items-center gap-1.5 sm:gap-3 px-2.5 sm:px-4 py-2.5 hover:bg-accent/40 transition-colors rounded-xl"
      prefetch={false}
    >
      <div className="flex justify-center">
        <StatusBadge m={m} />
      </div>

      {/* home */}
      <div className={cn("flex items-center justify-end gap-2 min-w-0", homeWin ? "font-black" : "font-semibold")}>
        <span className={cn("truncate text-[13px] sm:text-sm", homeWin ? "text-foreground" : "text-foreground/85")}>
          {m.home.fa || m.home.name}
        </span>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={m.home.logo}
          alt=""
          width={20}
          height={20}
          loading="lazy"
          className="w-5 h-5 object-contain shrink-0"
          onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
        />
      </div>

      {/* score */}
      <div className="flex items-center justify-center min-w-[46px]">
        {showScore ? (
          <span
            className={cn(
              "font-black text-sm sm:text-base rounded-lg px-2.5 py-0.5 tabular-persian tracking-wide",
              m.live ? "text-red-300 bg-red-500/10" : "text-foreground bg-muted/60"
            )}
          >
            {m.home.score ?? "—"} : {m.away.score ?? "—"}
          </span>
        ) : (
          <span className="text-muted-foreground/50 text-xs font-bold">—</span>
        )}
      </div>

      {/* away */}
      <div className={cn("flex items-center gap-2 min-w-0", awayWin ? "font-black" : "font-semibold")}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={m.away.logo}
          alt=""
          width={20}
          height={20}
          loading="lazy"
          className="w-5 h-5 object-contain shrink-0"
          onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
        />
        <span className={cn("truncate text-[13px] sm:text-sm", awayWin ? "text-foreground" : "text-foreground/85")}>
          {m.away.fa || m.away.name}
        </span>
      </div>

      <div className="flex justify-center text-muted-foreground/0 group-hover:text-muted-foreground transition-colors">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
          <path d="M15 18l-6-6 6-6" />
        </svg>
      </div>
    </Link>
  );
}

function LeagueGroupCard({ g }: { g: LeagueGroup }) {
  const live = g.matches.filter((m) => m.live).length;
  const sorted = useMemo(() => {
    const arr = [...g.matches];
    arr.sort((a, b) => {
      if (a.live !== b.live) return a.live ? -1 : 1;
      if (a.finished !== b.finished) return a.finished ? 1 : -1;
      return (a.utcTime || "").localeCompare(b.utcTime || "");
    });
    return arr;
  }, [g.matches]);

  return (
    <section className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden backdrop-blur-sm">
      <header className="flex items-center gap-2.5 px-3 sm:px-4 py-3 border-b border-border/40 bg-muted/25">
        <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/20 flex items-center justify-center shrink-0">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="text-primary" aria-hidden>
            <path d="M12 3l9 4.5v9L12 21l-9-4.5v-9L12 3z" />
            <path d="M12 8l4.5 3.2-1.7 5.3H9.2L7.5 11.2 12 8z" />
          </svg>
        </div>
        <h3 className="font-black text-sm sm:text-[15px] truncate">{g.leagueFa || g.leagueName}</h3>
        <span className="text-[10px] text-muted-foreground font-bold border border-border rounded-md px-1.5 py-0.5">
          {g.ccode}
        </span>
        {live > 0 ? (
          <span className="ms-auto inline-flex items-center gap-1 text-[10px] font-black text-red-400 bg-red-500/10 border border-red-500/25 rounded-full px-2 py-0.5 tabular-persian">
            <span className="live-dot w-1 h-1 rounded-full bg-red-500" />
            {faDigits(live)} زنده
          </span>
        ) : (
          <span className="ms-auto text-[10px] text-muted-foreground tabular-persian">
            {faDigits(g.matches.length)} بازی
          </span>
        )}
      </header>
      <div className="p-1.5 flex flex-col">
        {sorted.map((m) => (
          <MatchRow key={m.id} m={m} />
        ))}
      </div>
    </section>
  );
}

function Skeleton() {
  return (
    <div className="flex flex-col gap-4" aria-busy="true" aria-label="در حال بارگذاری نتایج">
      {[0, 1, 2].map((g) => (
        <div key={g} className="rounded-2xl border border-border/60 bg-card/40 overflow-hidden">
          <div className="px-4 py-3 border-b border-border/40 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-muted animate-pulse" />
            <div className="h-4 w-36 rounded bg-muted animate-pulse" />
          </div>
          <div className="p-2 flex flex-col gap-1">
            {Array.from({ length: 3 + (g % 2) }).map((_, i) => (
              <div key={i} className="grid grid-cols-[52px_1fr_auto_1fr_28px] gap-3 px-4 py-3 items-center">
                <div className="h-3.5 w-9 rounded bg-muted animate-pulse mx-auto" />
                <div className="h-4 rounded bg-muted animate-pulse ms-auto w-24" />
                <div className="h-5 w-12 rounded bg-muted animate-pulse" />
                <div className="h-4 rounded bg-muted animate-pulse w-24" />
                <div />
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function EmptyState() {
  return (
    <div className="rounded-2xl border border-dashed border-border/70 bg-card/30 px-6 py-14 text-center">
      <div className="mx-auto w-14 h-14 rounded-2xl bg-muted/60 flex items-center justify-center mb-4">
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" className="text-muted-foreground" aria-hidden>
          <circle cx="12" cy="12" r="9" />
          <path d="M12 7l4.5 3.2-1.7 5.3H9.2L7.5 10.2 12 7z" />
        </svg>
      </div>
      <p className="font-black text-sm mb-1">بازی‌ای برای این روز پیدا نشد</p>
      <p className="text-xs text-muted-foreground">روز دیگری را از نوار بالا انتخاب کنید</p>
    </div>
  );
}

export interface MatchesViewProps {
  groups: LeagueGroup[];
  loading: boolean;
  offset: number;
  onOffsetChange: (n: number) => void;
}

const OFFSETS = Array.from({ length: 15 }, (_, i) => i - 7);

export function MatchesView({ groups, loading, offset, onOffsetChange }: MatchesViewProps) {
  const todayISO = offsetDateISO(0);
  const chips = useMemo(
    () =>
      OFFSETS.map((o) => {
        const iso = offsetDateISO(o);
        const j = jalaliShort(`${iso}T12:00:00Z`);
        return { offset: o, iso, ...j, isToday: o === 0 };
      }),
    [todayISO] // eslint-disable-line react-hooks/exhaustive-deps
  );

  const activeJ = jalaliShort(`${offsetDateISO(offset)}T12:00:00Z`);

  return (
    <div className="flex flex-col gap-4">
      {/* ---- day navigation ---- */}
      <div className="flex gap-2 overflow-x-auto pb-1.5 -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {chips.map((c) => (
          <button
            key={c.offset}
            onClick={() => onOffsetChange(c.offset)}
            aria-pressed={c.offset === offset}
            className={cn(
              "shrink-0 flex flex-col items-center gap-0.5 rounded-xl border px-3.5 py-2 min-w-[62px] transition-all",
              c.offset === offset
                ? "bg-primary/15 border-primary/40 text-primary"
                : "bg-card/50 border-border/50 text-muted-foreground hover:border-border hover:text-foreground"
            )}
          >
            <span className="text-[10px] font-bold">{c.isToday ? "امروز" : c.weekday.slice(0, 6)}</span>
            <span className={cn("text-sm font-black tabular-persian", c.isToday && "text-primary")}>{c.day}</span>
          </button>
        ))}
      </div>

      {/* ---- selected day title ---- */}
      <div className="flex items-center justify-between gap-2 px-1">
        <p className="text-xs text-muted-foreground font-semibold">
          بازی‌های{" "}
          <span className="text-foreground font-black">
            {offset === 0 ? "امروز" : `${activeJ.weekday} ${activeJ.day} ${activeJ.month}`}
          </span>
        </p>
        {groups.length > 0 && (
          <p className="text-[10px] text-muted-foreground/70 tabular-persian">
            {faDigits(groups.reduce((a, g) => a + g.matches.length, 0))} بازی در {faDigits(groups.length)} لیگ و جام
          </p>
        )}
      </div>

      {/* ---- groups ---- */}
      {loading && groups.length === 0 ? (
        <Skeleton />
      ) : groups.length === 0 ? (
        <EmptyState />
      ) : (
        <div className={cn("grid gap-4 lg:grid-cols-2 lg:items-start transition-opacity", loading && "opacity-50 pointer-events-none")}>
          {groups.map((g) => (
            <LeagueGroupCard key={`${g.leagueId}-${g.ccode}`} g={g} />
          ))}
        </div>
      )}
    </div>
  );
}
