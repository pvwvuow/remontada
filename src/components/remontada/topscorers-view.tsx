"use client";

// ------------------------------------------------------------------
// Remontada — global top scorers page (merged race across 7 leagues)
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { GlobalScorer, GlobalScorersData } from "@/lib/fotmob";
import { LEAGUES } from "@/lib/leagues";
import { faDigits } from "@/lib/format";
import { cn } from "@/lib/utils";

const ALL_KEY = "all";

function ScorerRow({ s, maxGoals, medal }: { s: GlobalScorer; maxGoals: number; medal: boolean }) {
  return (
    <li className="px-3 sm:px-4 py-3 hover:bg-accent/30 transition-colors">
      <div className="flex items-center gap-3">
        <span
          className={cn(
            "w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0 tabular-persian",
            medal
              ? "bg-chart-3/20 text-chart-3 border border-chart-3/30"
              : "bg-muted text-muted-foreground"
          )}
        >
          {faDigits(s.rank)}
        </span>
        <div className="min-w-0 flex-1">
          <p className="font-bold text-[13px] truncate">{s.name}</p>
          <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground mt-0.5">
            <span className="truncate">{s.team}</span>
            <span aria-hidden>·</span>
            <Link
              href={`/league/${s.leagueKey}`}
              className="shrink-0 rounded-md border border-border/60 px-1.5 py-px font-bold hover:text-primary hover:border-primary/40 transition-colors"
            >
              {s.leagueFa}
            </Link>
          </div>
        </div>
        <span className="font-black text-primary tabular-persian text-lg shrink-0">
          {faDigits(s.goals)}
          <span className="text-[9px] font-bold text-muted-foreground ms-1">گل</span>
        </span>
      </div>
      <div className="mt-1.5 ms-10 h-1 rounded-full bg-muted overflow-hidden">
        <div className="h-full bg-chart-3/70 rounded-full" style={{ width: `${maxGoals > 0 ? (s.goals / maxGoals) * 100 : 0}%` }} />
      </div>
    </li>
  );
}

function Skeleton() {
  return (
    <div className="rounded-2xl border border-border/60 bg-card/40 overflow-hidden" aria-busy="true">
      {Array.from({ length: 10 }).map((_, i) => (
        <div key={i} className="flex items-center gap-3 px-4 py-3 border-b border-border/20 last:border-0">
          <div className="w-7 h-7 rounded-lg bg-muted animate-pulse shrink-0" />
          <div className="flex-1 flex flex-col gap-1.5">
            <div className="h-3.5 rounded bg-muted animate-pulse" style={{ width: `${35 + ((i * 11) % 40)}%` }} />
            <div className="h-2.5 rounded bg-muted animate-pulse w-1/4" />
          </div>
          <div className="w-10 h-5 rounded bg-muted animate-pulse" />
        </div>
      ))}
    </div>
  );
}

export function TopScorersView() {
  const [data, setData] = useState<GlobalScorersData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<string>(ALL_KEY);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/topscorers", { cache: "no-store" });
        const json = await res.json();
        if (cancelled) return;
        if (json.ok) setData(json as GlobalScorersData);
        else setError("دریافت داده گلزنان ناموفق بود.");
      } catch {
        if (!cancelled) setError("ارتباط برقرار نشد.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, []);

  const leaguesWithScorers = useMemo(
    () => LEAGUES.filter((l) => data?.perLeague.some((p) => p.leagueKey === l.key)),
    [data]
  );

  const visible: GlobalScorer[] = useMemo(() => {
    if (!data) return [];
    if (filter === ALL_KEY) return data.scorers;
    return data.scorers.filter((s) => s.leagueKey === filter);
  }, [data, filter]);

  const maxGoals = useMemo(() => visible.reduce((m, s) => Math.max(m, s.goals), 0), [visible]);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3 px-1">
        <div>
          <h1 className="text-lg font-black">مصاف گلزنان</h1>
          <p className="text-[11px] text-muted-foreground mt-0.5">
            بهترین گلزنان {faDigits(7)} لیگ بزرگ در یک جدول واحد
            {data?.scorers.length ? <> — {faDigits(data.scorers.length)} بازیکن</> : null}
          </p>
        </div>
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" className="text-chart-3 shrink-0" aria-hidden>
          <circle cx="12" cy="8" r="5" />
          <path d="M8.5 12.5L7 22l5-3 5 3-1.5-9.5" />
        </svg>
      </div>

      {/* filter chips */}
      <div className="flex gap-2 overflow-x-auto pb-1.5 -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" role="tablist" aria-label="فیلتر لیگ">
        <button
          onClick={() => setFilter(ALL_KEY)}
          className={cn(
            "shrink-0 rounded-xl border px-3.5 py-2 text-xs font-bold transition-all",
            filter === ALL_KEY
              ? "bg-primary/15 border-primary/40 text-primary"
              : "bg-card/50 border-border/50 text-muted-foreground hover:border-border hover:text-foreground"
          )}
        >
          همه لیگ‌ها
        </button>
        {(data ? leaguesWithScorers : LEAGUES).map((l) => (
          <button
            key={l.key}
            onClick={() => setFilter(l.key)}
            className={cn(
              "shrink-0 rounded-xl border px-3.5 py-2 text-xs font-bold transition-all",
              filter === l.key
                ? "bg-primary/15 border-primary/40 text-primary"
                : "bg-card/50 border-border/50 text-muted-foreground hover:border-border hover:text-foreground"
            )}
          >
            {l.faName}
          </button>
        ))}
      </div>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 text-destructive text-sm px-4 py-3">
          {error}
        </div>
      )}

      {loading ? (
        <Skeleton />
      ) : visible.length > 0 ? (
        <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden divide-y divide-border/25">
          {visible.map((s) => (
            <ScorerRow key={`${s.leagueKey}-${s.name}`} s={s} maxGoals={maxGoals} medal={filter === ALL_KEY ? s.rank <= 3 : s.rank <= 3} />
          ))}
        </div>
      ) : (
        <p className="text-center text-muted-foreground text-sm py-12">
          داده گلزنان این بخش هنوز منتشر نشده است.
        </p>
      )}

      {data && !loading && (
        <p className="text-[10px] text-muted-foreground px-1">
          رتبه‌بندی بر اساس تعداد گل ثبت‌شده در فصل جاری هر لیگ است. برای دیدن گلزنان بیشتر، صفحه‌ی همان لیگ را باز کنید.
        </p>
      )}
    </div>
  );
}
