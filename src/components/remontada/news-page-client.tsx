"use client";

// ------------------------------------------------------------------
// Remontada — dedicated news page client (fetch + refresh + filters)
// Filter chips by source (with counts) + league + chronological order
// ------------------------------------------------------------------
import { useCallback, useEffect, useMemo, useState } from "react";
import type { ReactNode } from "react";
import { NewsView, sourceStyle, type ClientNewsItem } from "@/components/remontada/news-view";
import { faDigits, timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";

const ALL = "all";
type Sort = "newest" | "oldest";

function Chip({
  active,
  onClick,
  className,
  children,
}: {
  active: boolean;
  onClick: () => void;
  className?: string;
  children: ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      aria-pressed={active}
      className={cn(
        "shrink-0 inline-flex items-center gap-1.5 rounded-xl border px-3.5 py-2 text-xs font-bold transition-all",
        active
          ? "bg-sky-soft/15 border-sky-soft/40 text-sky-soft"
          : cn("bg-white/[0.03] border-[color:var(--glass-border-soft)] text-steel hover:border-[color:var(--glass-border)] hover:text-foreground", className)
      )}
    >
      {children}
    </button>
  );
}

function CountBadge({ n, active }: { n: number; active: boolean }) {
  return (
    <span
      className={cn(
        "rounded-md px-1.5 py-px text-[10px] font-black tabular-persian border",
        active ? "bg-sky-soft/10 border-sky-soft/30 text-sky-soft" : "bg-white/[0.05] border-[color:var(--glass-border-soft)] text-muted-foreground"
      )}
    >
      {faDigits(n)}
    </span>
  );
}

export function NewsPageClient() {
  const [items, setItems] = useState<ClientNewsItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [source, setSource] = useState<string>(ALL);
  const [league, setLeague] = useState<string>(ALL);
  const [sort, setSort] = useState<Sort>("newest");

  const fetchNews = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const res = await fetch("/api/news", { cache: "no-store" });
      const json = await res.json();
      if (json.ok) setItems(json.items || []);
    } catch {
      // keep old
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchNews();
  }, [fetchNews]);

  // ---- counts per source (chronologically stable feed) ----
  const sourceCounts = useMemo(() => {
    const m = new Map<string, number>();
    for (const it of items) m.set(it.source, (m.get(it.source) || 0) + 1);
    return [...m.entries()].sort((a, b) => b[1] - a[1]);
  }, [items]);

  // ---- leagues present in the feed (ESPN items carry league) ----
  const leagueCounts = useMemo(() => {
    const m = new Map<string, number>();
    for (const it of items) {
      if (it.league) m.set(it.league, (m.get(it.league) || 0) + 1);
    }
    return [...m.entries()].sort((a, b) => b[1] - a[1]);
  }, [items]);

  // ---- filter + chronological sort ----
  const visible = useMemo(() => {
    let arr = items;
    if (source !== ALL) arr = arr.filter((i) => i.source === source);
    if (league !== ALL) arr = arr.filter((i) => i.league === league);
    const t = (x: ClientNewsItem) => new Date(x.publishedAt).getTime() || 0;
    return [...arr].sort((a, b) => (sort === "newest" ? t(b) - t(a) : t(a) - t(b)));
  }, [items, source, league, sort]);

  const filtered = source !== ALL || league !== ALL;
  const newestItem = useMemo(() => {
    if (items.length === 0) return null;
    return items.reduce((a, b) => (new Date(b.publishedAt).getTime() > new Date(a.publishedAt).getTime() ? b : a));
  }, [items]);

  return (
    <div className="flex flex-col gap-4">
      {/* ---- filter bar: source chips + sort toggle ---- */}
      <div className="flex items-center gap-2 px-1">
        <div
          className="flex gap-2 overflow-x-auto pb-1.5 flex-1 min-w-0 -me-1 pe-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          role="group"
          aria-label="فیلتر منبع خبر"
        >
          <Chip active={source === ALL} onClick={() => setSource(ALL)}>
            همه منابع
            <CountBadge n={items.length} active={source === ALL} />
          </Chip>
          {sourceCounts.map(([s, n]) => (
            <Chip
              key={s}
              active={source === s}
              onClick={() => setSource(source === s ? ALL : s)}
              className={source === s ? "" : sourceStyle(s)}
            >
              {s}
              <CountBadge n={n} active={source === s} />
            </Chip>
          ))}
        </div>

        {/* chronological order toggle */}
        <div className="shrink-0 flex rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.03] p-0.5" role="group" aria-label="ترتیب زمانی">
          {(
            [
              { key: "newest", label: "تازه‌ترین" },
              { key: "oldest", label: "قدیمی‌ترین" },
            ] as { key: Sort; label: string }[]
          ).map((o) => (
            <button
              key={o.key}
              onClick={() => setSort(o.key)}
              aria-pressed={sort === o.key}
              className={cn(
                "px-2.5 py-1.5 rounded-lg text-[11px] font-bold transition-colors whitespace-nowrap",
                sort === o.key ? "bg-sky-soft/[0.12] text-sky-soft" : "text-muted-foreground hover:text-foreground"
              )}
            >
              {o.label}
            </button>
          ))}
        </div>
      </div>

      {/* ---- secondary league chips (only when data exists) ---- */}
      {leagueCounts.length > 0 && (
        <div
          className="flex gap-2 overflow-x-auto pb-1.5 -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          role="group"
          aria-label="فیلتر مسابقات"
        >
          <Chip active={league === ALL} onClick={() => setLeague(ALL)}>
            همه مسابقات
            <CountBadge n={items.length} active={league === ALL} />
          </Chip>
          {leagueCounts.map(([lg, n]) => (
            <Chip key={lg} active={league === lg} onClick={() => setLeague(league === lg ? ALL : lg)}>
              {lg}
              <CountBadge n={n} active={league === lg} />
            </Chip>
          ))}
        </div>
      )}

      {/* ---- status line ---- */}
      <div className="flex items-center justify-between gap-2 px-1 text-[10px] text-muted-foreground">
        <span className="tabular-persian">
          {filtered ? (
            <>
              نمایش {faDigits(visible.length)} خبر فیلترشده از {faDigits(items.length)} خبر
            </>
          ) : (
            <>{faDigits(items.length)} خبر از ESPN، BBC Sport و Sky Sports</>
          )}
        </span>
        {newestItem && !loading && (
          <span className="whitespace-nowrap">
            جدیدترین: {timeAgoFa(newestItem.publishedAt)}
          </span>
        )}
      </div>

      <div className="flex justify-end">
        <button
          onClick={() => fetchNews()}
          className="flex items-center gap-1.5 text-xs font-semibold bg-white/[0.04] border border-[color:var(--glass-border-soft)] px-3 py-1.5 rounded-lg hover:bg-white/[0.08] hover:border-[color:var(--glass-border)] transition-colors"
        >
          <svg
            width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
            className={cn(loading && "animate-spin")} aria-hidden
          >
            <path d="M21 12a9 9 0 1 1-2.64-6.36" />
            <path d="M21 3v6h-6" />
          </svg>
          بروزرسانی
        </button>
      </div>

      <NewsView
        items={visible}
        loading={loading}
        emptyHint={filtered ? "با این فیلتر خبری پیدا نشد — فیلتر دیگری را امتحان کنید" : undefined}
      />
    </div>
  );
}
