"use client";

// ------------------------------------------------------------------
// Remontada — live matches view (day navigation + league groups)
// ------------------------------------------------------------------
import Link from "next/link";
import { useMemo, useState } from "react";
import type { LeagueGroup, NormMatch } from "@/lib/fotmob";
import { faDigits, jalaliShort, offsetDateISO, tehranTime } from "@/lib/format";
import { useFavorites } from "@/lib/favorites";
import { TeamLogo } from "@/components/remontada/team-logo";
import { EmptyState } from "@/components/remontada/empty-state";
import { cn } from "@/lib/utils";

export { tehranTime };

function StatusBadge({ m }: { m: NormMatch }) {
  if (m.cancelled) {
    return (
      <span className="text-[11px] font-bold text-muted-foreground/90 bg-white/[0.03] border border-glass-border-soft px-2 py-1 rounded-lg whitespace-nowrap">
        لغو شده
      </span>
    );
  }
  if (m.live) {
    const min = m.minute || "";
    const numMatch = /^\d+/.exec(min);
    return (
      <span className="inline-flex items-center gap-1.5 text-[11px] font-black text-red-300 bg-red-500/[0.08] border border-red-400/25 px-2 py-1 rounded-lg whitespace-nowrap tabular-persian">
        <span className="live-dot live-dot-glow w-1.5 h-1.5 rounded-full bg-red-500 inline-block" />
        <span className="live-glow">{min ? (numMatch ? `${faDigits(min)}` : min) : "زنده"}</span>
      </span>
    );
  }
  if (m.finished) {
    return (
      <span className="text-[10.5px] font-bold text-muted-foreground px-2 py-1 whitespace-nowrap">
        پایان
      </span>
    );
  }
  return (
    <span className="text-[11px] font-semibold text-sky-soft/90 px-2 py-1 whitespace-nowrap tabular-persian">
      {tehranTime(m.utcTime)}
    </span>
  );
}

function MiniStar({ size = 12, className }: { size?: number; className?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="currentColor"
      stroke="currentColor"
      strokeWidth="1.9"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      className={cn("text-amber-400 shrink-0", className)}
    >
      <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
    </svg>
  );
}

function MatchRow({ m, favIds }: { m: NormMatch; favIds: Set<number> }) {
  const homeFav = favIds.has(m.home.id);
  const awayFav = favIds.has(m.away.id);
  const isFav = homeFav || awayFav;
  const showScore = m.started && !m.cancelled;
  const homeWin = showScore && m.home.score !== null && m.away.score !== null && m.home.score > m.away.score;
  const awayWin = showScore && m.home.score !== null && m.away.score !== null && m.away.score > m.home.score;

  return (
    <Link
      href={`/match/${m.id}`}
      className={cn(
        "group grid grid-cols-[52px_1fr_auto_1fr_28px] items-center gap-1.5 sm:gap-3 px-2.5 sm:px-4 py-2.5 rounded-xl",
        isFav ? "bg-amber-400/[0.05] ring-1 ring-amber-400/20 hover:bg-amber-400/[0.09] hover:ring-amber-400/35 transition-colors" : "glass-row-hover"
      )}
      prefetch={false}
    >
      <div className="flex justify-center">
        <StatusBadge m={m} />
      </div>

      {/* home */}
      <div className={cn("flex items-center justify-end gap-2 min-w-0", homeWin ? "font-black" : "font-semibold")}>
        {homeFav && <MiniStar />}
        <span className={cn("truncate text-[13px] sm:text-sm", homeWin ? "text-foreground" : "text-foreground/85", homeFav && !homeWin && "text-foreground")}>
          {m.home.fa || m.home.name}
        </span>
        <TeamLogo id={m.home.id} alt="" size={20} />
      </div>

      {/* score */}
      <div className="flex items-center justify-center min-w-[46px]">
        {showScore ? (
          <span
            className={cn(
              "font-black text-sm sm:text-base rounded-lg px-2.5 py-0.5 tabular-persian tracking-wide border",
              m.live
                ? "text-red-200 bg-red-500/[0.09] border-red-400/20 live-glow"
                : "text-foreground/95 bg-white/[0.05] border-glass-border-soft"
            )}
          >
            {faDigits(m.home.score ?? "—")} : {faDigits(m.away.score ?? "—")}
          </span>
        ) : (
          <span className="text-steel/40 text-xs font-bold">—</span>
        )}
      </div>

      {/* away */}
      <div className={cn("flex items-center gap-2 min-w-0", awayWin ? "font-black" : "font-semibold")}>
        <TeamLogo id={m.away.id} alt="" size={20} />
        <span className={cn("truncate text-[13px] sm:text-sm", awayWin ? "text-foreground" : "text-foreground/85", awayFav && !awayWin && "text-foreground")}>
          {m.away.fa || m.away.name}
        </span>
        {awayFav && <MiniStar />}
      </div>

      <div className="flex justify-center text-steel/0 group-hover:text-steel/70 transition-colors">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
          <path d="M15 18l-6-6 6-6" />
        </svg>
      </div>
    </Link>
  );
}

/* Featured "بازی ویژه / TOP MATCH" hero tile — studio fixtures poster:
   glowing glass tile, big crests, big score/time under the "vs" */
function FeaturedMatch({ m, favIds }: { m: NormMatch; favIds: Set<number> }) {
  const homeFav = favIds.has(m.home.id);
  const awayFav = favIds.has(m.away.id);
  const showScore = m.started && !m.cancelled;
  const homeWin = showScore && m.home.score !== null && m.away.score !== null && m.home.score > m.away.score;
  const awayWin = showScore && m.home.score !== null && m.away.score !== null && m.away.score > m.home.score;
  const min = m.minute || "";
  const numMatch = /^\d+/.exec(min);

  return (
    <Link
      href={`/match/${m.id}`}
      prefetch={false}
      aria-label={`بازی ویژه: ${m.home.fa || m.home.name} مقابل ${m.away.fa || m.away.name}`}
      className="glass-card glass-hero group block p-4 sm:p-5 transition-transform duration-200 hover:-translate-y-0.5"
    >
      {/* label row */}
      <div className="flex items-center gap-2 mb-3.5 min-w-0">
        <span className="inline-flex items-center gap-1.5 text-[10.5px] font-black text-sky-soft whitespace-nowrap">
          <span className="w-1.5 h-1.5 rounded-full bg-sky-soft inline-block shadow-[0_0_8px_oklch(0.8_0.08_240/90%),0_0_2px_oklch(0.85_0.07_240)]" />
          بازی ویژه
        </span>
        <span className="text-[8.5px] font-bold tracking-[0.32em] text-steel/60 uppercase whitespace-nowrap">
          Top Match
        </span>
        <span className="ms-auto truncate text-[10px] text-muted-foreground font-semibold">
          {m.leagueFa || m.leagueName}
        </span>
      </div>

      {/* teams */}
      <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-1.5 sm:gap-4">
        {/* home */}
        <div className="flex flex-col items-center gap-1.5 min-w-0">
          <img
            src={m.home.logo}
            alt=""
            width={56}
            height={56}
            loading="lazy"
            className="w-11 h-11 sm:w-14 sm:h-14 object-contain drop-shadow-[0_5px_12px_oklch(0.03_0.015_255/65%)]"
            onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
          />
          <span className={cn("flex items-center gap-1 text-[12px] sm:text-[13.5px] truncate max-w-full", homeWin ? "font-black text-foreground" : "font-bold text-foreground/90")}>
            {homeFav && <MiniStar size={10} />}
            {m.home.fa || m.home.name}
          </span>
        </div>

        {/* center: score or vs + time/minute */}
        <div className="flex flex-col items-center gap-1 min-w-[64px] sm:min-w-[86px]">
          {showScore ? (
            <>
              <span className={cn("font-black text-[26px] sm:text-3xl leading-none tabular-persian tracking-wide", m.live ? "text-red-200 live-glow" : "text-foreground")}>
                {faDigits(m.home.score ?? "—")} : {faDigits(m.away.score ?? "—")}
              </span>
              <span className={cn("text-[10.5px] font-bold tabular-persian whitespace-nowrap", m.live ? "text-red-300 live-glow" : "text-muted-foreground")}>
                {m.cancelled ? "لغو شده" : m.live ? (min ? (numMatch ? `${faDigits(min)}` : min) : "زنده") : "پایان"}
              </span>
            </>
          ) : (
            <>
              <span className="text-base sm:text-lg text-steel/70 font-semibold tracking-widest">vs</span>
              <span className="text-xl sm:text-2xl font-light text-sky-soft/95 tabular-persian leading-none">
                {tehranTime(m.utcTime)}
              </span>
            </>
          )}
          {m.live && (
            <span className="inline-flex items-center gap-1 text-[9px] font-black text-red-300/90 whitespace-nowrap">
              <span className="live-dot live-dot-glow w-1 h-1 rounded-full bg-red-500 inline-block" />
              در جریان
            </span>
          )}
        </div>

        {/* away */}
        <div className="flex flex-col items-center gap-1.5 min-w-0">
          <img
            src={m.away.logo}
            alt=""
            width={56}
            height={56}
            loading="lazy"
            className="w-11 h-11 sm:w-14 sm:h-14 object-contain drop-shadow-[0_5px_12px_oklch(0.03_0.015_255/65%)]"
            onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
          />
          <span className={cn("flex items-center gap-1 text-[12px] sm:text-[13.5px] truncate max-w-full", awayWin ? "font-black text-foreground" : "font-bold text-foreground/90")}>
            {m.away.fa || m.away.name}
            {awayFav && <MiniStar size={10} />}
          </span>
        </div>
      </div>
    </Link>
  );
}

function LeagueGroupCard({ g, favIds }: { g: LeagueGroup; favIds: Set<number> }) {
  const live = g.matches.filter((m) => m.live).length;
  const sorted = useMemo(() => {
    const arr = [...g.matches];
    arr.sort((a, b) => {
      const aFav = favIds.has(a.home.id) || favIds.has(a.away.id);
      const bFav = favIds.has(b.home.id) || favIds.has(b.away.id);
      if (aFav !== bFav) return aFav ? -1 : 1; // favorites float to top
      if (a.live !== b.live) return a.live ? -1 : 1;
      if (a.finished !== b.finished) return a.finished ? 1 : -1;
      return (a.utcTime || "").localeCompare(b.utcTime || "");
    });
    return arr;
  }, [g.matches, favIds]);

  return (
    <section className="glass-card overflow-hidden">
      <header className="flex items-center gap-2.5 px-3 sm:px-4 py-2.5 border-b border-glass-border-soft bg-white/[0.02]">
        {/* league chip: crest over a glyph tile (crest hides on error) */}
        <div className="relative w-8 h-8 shrink-0 flex items-center justify-center">
          <div className="brand-glyph absolute inset-0 flex items-center justify-center">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="text-sky-soft/80" aria-hidden>
              <path d="M12 3l9 4.5v9L12 21l-9-4.5v-9L12 3z" />
              <path d="M12 8l4.5 3.2-1.7 5.3H9.2L7.5 11.2 12 8z" />
            </svg>
          </div>
          <img
            src={`https://images.fotmob.com/image_resources/logo/leaguelogo/${g.leagueId}.png`}
            alt=""
            width={18}
            height={18}
            loading="lazy"
            className="relative w-[18px] h-[18px] object-contain"
            onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
          />
        </div>
        <h3 className="font-extrabold text-sm sm:text-[15px] truncate">{g.leagueFa || g.leagueName}</h3>
        <span className="text-[10px] text-steel font-bold border border-glass-border-soft bg-white/[0.03] rounded-md px-1.5 py-0.5 tracking-wide">
          {g.ccode}
        </span>
        {live > 0 ? (
          <span className="ms-auto inline-flex items-center gap-1 text-[10px] font-black text-red-300 bg-red-500/[0.08] border border-red-400/25 rounded-full px-2 py-0.5 tabular-persian">
            <span className="live-dot live-dot-glow w-1 h-1 rounded-full bg-red-500" />
            {faDigits(live)} زنده
          </span>
        ) : (
          <span className="ms-auto text-[10px] text-muted-foreground tabular-persian">
            {faDigits(g.matches.length)} بازی
          </span>
        )}
      </header>
      <div className="glass-list py-1 flex flex-col">
        {sorted.map((m) => (
          <MatchRow key={m.id} m={m} favIds={favIds} />
        ))}
      </div>
    </section>
  );
}

function Skeleton() {
  return (
    <div className="flex flex-col gap-4" aria-busy="true" aria-label="در حال بارگذاری نتایج">
      {[0, 1, 2].map((g) => (
        <div key={g} className="rounded-2xl border border-glass-border-soft bg-white/[0.03] overflow-hidden">
          <div className="px-4 py-3 border-b border-glass-border-soft flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-white/[0.05] animate-pulse" />
            <div className="h-4 w-36 rounded bg-white/[0.05] animate-pulse" />
          </div>
          <div className="py-1 flex flex-col">
            {Array.from({ length: 3 + (g % 2) }).map((_, i) => (
              <div key={i} className="grid grid-cols-[52px_1fr_auto_1fr_28px] gap-3 px-4 py-3 items-center">
                <div className="h-3.5 w-9 rounded bg-white/[0.05] animate-pulse mx-auto" />
                <div className="h-4 rounded bg-white/[0.05] animate-pulse ms-auto w-24" />
                <div className="h-5 w-12 rounded bg-white/[0.05] animate-pulse" />
                <div className="h-4 rounded bg-white/[0.05] animate-pulse w-24" />
                <div />
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

/** maps day/filters context to the shared EmptyState (cycle-34) */
function MatchesEmptyState({
  favsOnly,
  statusFilter,
  offset,
  onToday,
  onShowAll,
}: {
  favsOnly?: boolean;
  statusFilter: "all" | "live" | "finished";
  offset: number;
  onToday: () => void;
  onShowAll: () => void;
}) {
  let title = "بازی‌ای برای این روز پیدا نشد";
  let sub = "روز دیگری را از نوار بالا انتخاب کنید";
  let icon: "ball" | "star" | "live" = "ball";
  let action: React.ComponentProps<typeof EmptyState>["action"];
  if (statusFilter === "live") {
    title = "الان بازی زنده‌ای جریان ندارد";
    sub = "چند دقیقه دیگر دوباره سر بزنید یا فیلتر را روی «همه» بگذارید";
    icon = "live";
  } else if (statusFilter === "finished") {
    title = "هنوز بازی‌ای به پایان نرسیده است";
    sub = "بازی‌ها معمولاً بعدازظهر و شب به پایان می‌رسند";
  } else if (favsOnly) {
    title = "امروز بازی تیم‌های مورد علاقه‌ی شما نیست";
    sub = "روز دیگری را از نوار بالا امتحان کنید یا فیلتر را بردارید";
    icon = "star";
    action = { label: "نمایش همه‌ی بازی‌ها", onClick: onShowAll };
  } else if (offset !== 0) {
    action = { label: "رفتن به بازی‌های امروز", onClick: onToday };
  }
  return <EmptyState icon={icon} title={title} sub={sub} action={action} />;
}

export interface MatchesViewProps {
  groups: LeagueGroup[];
  loading: boolean;
  offset: number;
  onOffsetChange: (n: number) => void;
}

const OFFSETS = Array.from({ length: 15 }, (_, i) => i - 7);

export function MatchesView({ groups, loading, offset, onOffsetChange }: MatchesViewProps) {
  const favs = useFavorites();
  const favIds = useMemo(() => new Set(favs.map((f) => f.id)), [favs]);
  const [onlyFavs, setOnlyFavs] = useState(false);
  const [statusFilter, setStatusFilter] = useState<"all" | "live" | "finished">("all");

  // status counts (for the همه/زنده/پایان‌یافته chips)
  const statusCounts = useMemo(() => {
    let live = 0, finished = 0, total = 0;
    for (const g of groups) {
      for (const m of g.matches) {
        total++;
        if (m.live) live++;
        if (m.finished) finished++;
      }
    }
    return { live, finished, total };
  }, [groups]);

  // status filter — drop groups left with no matches
  const statusFiltered = useMemo(() => {
    if (statusFilter === "all") return groups;
    return groups
      .map((g) => ({
        ...g,
        matches: g.matches.filter((m) => (statusFilter === "live" ? m.live : m.finished)),
      }))
      .filter((g) => g.matches.length > 0);
  }, [groups, statusFilter]);

  // matches involving favorite teams within the active status scope
  const favMatchCount = useMemo(() => {
    if (favIds.size === 0) return 0;
    return statusFiltered.reduce(
      (acc, g) => acc + g.matches.filter((m) => favIds.has(m.home.id) || favIds.has(m.away.id)).length,
      0
    );
  }, [statusFiltered, favIds]);

  const shownGroups = useMemo(() => {
    if (!onlyFavs || favIds.size === 0) return statusFiltered;
    return statusFiltered
      .map((g) => ({ ...g, matches: g.matches.filter((m) => favIds.has(m.home.id) || favIds.has(m.away.id)) }))
      .filter((g) => g.matches.length > 0);
  }, [statusFiltered, onlyFavs, favIds]);

  // featured "بازی ویژه" pick — pure presentation score over the currently
  // visible (filter-respecting) matches: live games first, then goals,
  // then favorites; falls back to the first visible match
  const featured = useMemo(() => {
    const all = shownGroups.flatMap((g) => g.matches);
    if (all.length === 0) return null;
    const weight = (m: NormMatch) =>
      (m.live ? 100 : 0) +
      ((m.home.score ?? 0) + (m.away.score ?? 0)) * 3 +
      (m.finished ? 8 : 0) +
      (favIds.has(m.home.id) || favIds.has(m.away.id) ? 40 : 0);
    return [...all].sort((a, b) => weight(b) - weight(a))[0];
  }, [shownGroups, favIds]);

  const todayISO = offsetDateISO(0);
  const chips = useMemo(
    () =>
      OFFSETS.map((o) => {
        const iso = offsetDateISO(o);
        const j = jalaliShort(`${iso}T12:00:00Z`);
        return { offset: o, iso, ...j, isToday: o === 0 };
      }),
    [todayISO]  
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
                ? "bg-primary/15 border-primary/40 text-primary shadow-[inset_0_1px_0_oklch(0.88_0.05_232/22%)]"
                : "bg-white/[0.03] border-glass-border-soft text-muted-foreground hover:border-glass-border hover:text-foreground"
            )}
          >
            <span className="text-[10px] font-bold">{c.isToday ? "امروز" : c.weekday.slice(0, 6)}</span>
            <span className={cn("text-sm font-black tabular-persian", c.isToday && "text-primary")}>{c.day}</span>
          </button>
        ))}
      </div>

      {/* ---- status filter: همه / زنده / پایان‌یافته ---- */}
      <div className="flex items-center gap-1.5 flex-wrap" role="group" aria-label="فیلتر وضعیت بازی‌ها">
        {([
          { key: "all", label: "همه" },
          { key: "live", label: "زنده" },
          { key: "finished", label: "پایان‌یافته" },
        ] as const).map((t) => {
          const active = statusFilter === t.key;
          const count =
            t.key === "all" ? statusCounts.total : t.key === "live" ? statusCounts.live : statusCounts.finished;
          return (
            <button
              key={t.key}
              onClick={() => setStatusFilter(t.key)}
              aria-pressed={active}
              className={cn(
                "inline-flex items-center gap-1.5 text-[11px] font-black rounded-lg border px-2.5 py-1.5 transition-all cursor-pointer",
                active
                  ? t.key === "live"
                    ? "text-red-300 bg-red-500/[0.08] border-red-400/35"
                    : "text-primary bg-primary/12 border-primary/35 shadow-[inset_0_1px_0_oklch(0.88_0.05_232/20%)]"
                  : "text-muted-foreground bg-white/[0.03] border-glass-border-soft hover:text-foreground hover:border-glass-border"
              )}
            >
              {t.key === "live" && <span className="live-dot live-dot-glow w-1.5 h-1.5 rounded-full bg-red-500 inline-block" />}
              {t.label}
              <span
                className={cn(
                  "rounded-md px-1.5 py-0.5 text-[10px] tabular-persian",
                  active ? "bg-background/50" : "bg-white/[0.05] text-muted-foreground"
                )}
              >
                {faDigits(count)}
              </span>
            </button>
          );
        })}
      </div>

      {/* ---- selected day title ---- */}
      <div className="flex items-center justify-between gap-2 px-1 flex-wrap">
        <p className="text-xs text-muted-foreground font-semibold">
          بازی‌های{" "}
          <span className="text-foreground font-black">
            {offset === 0 ? "امروز" : `${activeJ.weekday} ${activeJ.day} ${activeJ.month}`}
          </span>
        </p>
        <div className="flex items-center gap-2">
          {favIds.size > 0 && (
            <button
              onClick={() => setOnlyFavs((v) => !v)}
              aria-pressed={onlyFavs}
              className={cn(
                "inline-flex items-center gap-1.5 text-[11px] font-black rounded-lg border px-2.5 py-1.5 transition-all tabular-persian cursor-pointer",
                onlyFavs
                  ? "text-amber-300 bg-amber-400/[0.08] border-amber-400/35 shadow-[inset_0_1px_0_oklch(0.88_0.05_232/18%)]"
                  : "text-muted-foreground bg-white/[0.03] border-glass-border-soft hover:text-amber-300/90 hover:border-amber-400/30"
              )}
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill={onlyFavs ? "currentColor" : "none"} stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
              </svg>
              فقط علاقه‌مندی‌ها
              <span className={cn("rounded-md px-1.5 py-0.5 text-[10px]", onlyFavs ? "bg-amber-400/15" : "bg-white/[0.05] text-muted-foreground")}>
                {faDigits(favMatchCount)}
              </span>
            </button>
          )}
          {shownGroups.length > 0 && (
            <p className="text-[10px] text-muted-foreground/70 tabular-persian">
              {faDigits(shownGroups.reduce((a, g) => a + g.matches.length, 0))} بازی در {faDigits(shownGroups.length)} لیگ و جام
            </p>
          )}
        </div>
      </div>

      {/* ---- featured top match (studio hero tile) ---- */}
      {featured && <FeaturedMatch m={featured} favIds={favIds} />}

      {/* ---- groups ---- */}
      {loading && groups.length === 0 ? (
        <Skeleton />
      ) : shownGroups.length === 0 ? (
        <MatchesEmptyState
          favsOnly={onlyFavs && favIds.size > 0}
          statusFilter={statusFilter}
          offset={offset}
          onToday={() => onOffsetChange(0)}
          onShowAll={() => setOnlyFavs(false)}
        />
      ) : (
        <div className={cn("grid gap-4 lg:grid-cols-2 lg:items-start transition-opacity", loading && "opacity-50 pointer-events-none")}>
          {shownGroups.map((g) => (
            <LeagueGroupCard key={`${g.leagueId}-${g.ccode}`} g={g} favIds={favIds} />
          ))}
        </div>
      )}
    </div>
  );
}
