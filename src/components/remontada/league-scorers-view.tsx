"use client";

// ------------------------------------------------------------------
// Remontada — per-league top scorers view (/topscorers/[leagueKey])
// Full ranked list of one league with goal-share bars and rich badges
// (assists / G+A / xG / rating / minutes-per-goal). Matches the visual
// language of the global «مصاف گلزنان» page.
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { ScorerEntry } from "@/lib/fotmob";
import { LEAGUES } from "@/lib/leagues";
import { faDigits } from "@/lib/format";
import { cn } from "@/lib/utils";

interface LeagueScorersData {
  ok: boolean;
  leagueKey: string;
  leagueFa: string;
  season: string;
  scorers: ScorerEntry[];
  updatedAt: string;
}

function ScorerBadges({ s }: { s: ScorerEntry }) {
  const badges: { label: string; cls: string; title: string }[] = [];
  if (s.assists != null && s.assists > 0) {
    badges.push({ label: `${faDigits(s.assists)} پاس گل`, cls: "bg-chart-2/10 border-chart-2/25 text-chart-2", title: "پاس گل فصل" });
  }
  if (s.gPlusA != null && s.gPlusA > 0) {
    badges.push({ label: `${faDigits(s.gPlusA)} گل+پاس`, cls: "bg-primary/10 border-primary/25 text-primary", title: "مجموع گل و پاس گل" });
  }
  if (s.rating != null && s.rating > 0) {
    badges.push({ label: `ریتینگ ${faDigits(s.rating.toFixed(1))}`, cls: "bg-chart-3/10 border-chart-3/25 text-chart-3", title: "میانگین امتیاز فوت‌ماب" });
  }
  if (s.xg != null && s.xg > 0) {
    badges.push({ label: `xG ${faDigits(s.xg.toFixed(1))}`, cls: "bg-muted border-border text-muted-foreground", title: "گل مورد انتظار" });
  }
  if (s.minutes != null && s.minutes > 0 && s.goals > 0) {
    const mpg = Math.round(s.minutes / s.goals);
    if (mpg > 0) {
      badges.push({ label: `هر ${faDigits(mpg)} دقیقه یک گل`, cls: "bg-chart-4/10 border-chart-4/25 text-chart-4", title: "دقایق بازی تقسیم بر گل‌ها" });
    }
  }
  if (badges.length === 0) return null;
  return (
    <span className="flex items-center gap-1 flex-wrap">
      {badges.map((b) => (
        <span key={b.label} title={b.title} className={cn("shrink-0 rounded-md border px-1.5 py-px text-[9px] font-bold tabular-persian", b.cls)}>
          {b.label}
        </span>
      ))}
    </span>
  );
}

function Skeleton() {
  return (
    <div className="rounded-2xl border border-border/60 bg-card/40 overflow-hidden" aria-busy="true">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex items-center gap-3 px-4 py-3 border-b border-border/20 last:border-0">
          <div className="w-7 h-7 rounded-lg bg-muted animate-pulse shrink-0" />
          <div className="flex-1 flex flex-col gap-1.5">
            <div className="h-3.5 rounded bg-muted animate-pulse" style={{ width: `${30 + ((i * 13) % 45)}%` }} />
            <div className="h-2.5 rounded bg-muted animate-pulse w-1/4" />
          </div>
          <div className="w-10 h-5 rounded bg-muted animate-pulse" />
        </div>
      ))}
    </div>
  );
}

export function LeagueScorersView({ leagueKey }: { leagueKey: string }) {
  const [data, setData] = useState<LeagueScorersData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(`/api/topscorers/${leagueKey}`, { cache: "no-store" });
        const json = await res.json();
        if (cancelled) return;
        if (json.ok) setData(json as LeagueScorersData);
        else setError(json.error || "دریافت داده گلزنان ناموفق بود.");
      } catch {
        if (!cancelled) setError("ارتباط برقرار نشد.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [leagueKey]);

  const maxGoals = useMemo(
    () => (data?.scorers || []).reduce((m, s) => Math.max(m, s.goals), 0),
    [data]
  );

  return (
    <div className="flex flex-col gap-4">
      {/* header */}
      <div className="flex items-start justify-between gap-3 px-1">
        <div className="min-w-0">
          <Link
            href="/topscorers"
            className="text-[11px] font-bold text-muted-foreground hover:text-primary transition-colors inline-flex items-center gap-1"
          >
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" aria-hidden>
              <path d="M9 5l7 7-7 7" />
            </svg>
            همه گلزنان
          </Link>
          <h1 className="text-lg font-black mt-1">
            آقای گلان {data?.leagueFa || LEAGUES.find((l) => l.key === leagueKey)?.faName || "لیگ"}
          </h1>
          <p className="text-[11px] text-muted-foreground mt-0.5">
            {loading
              ? "در حال دریافت…"
              : data?.scorers.length
                ? <>بهترین گلزن‌های فصل{data.season ? <> — فصل {faDigits(data.season)}</> : null} — {faDigits(data.scorers.length)} بازیکن</>
                : "گلزنی برای این فصل ثبت نشده است."}
          </p>
        </div>
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" className="text-chart-3 shrink-0 mt-1" aria-hidden>
          <circle cx="12" cy="8" r="5" />
          <path d="M8.5 12.5L7 22l5-3 5 3-1.5-9.5" />
        </svg>
      </div>

      {/* quick links */}
      <div className="flex gap-2 flex-wrap">
        <Link
          href={`/league/${leagueKey}`}
          className="rounded-xl border border-border/50 bg-card/50 px-3.5 py-2 text-xs font-bold text-muted-foreground hover:text-primary hover:border-primary/40 transition-all"
        >
          جدول و برنامه
        </Link>
        {(LEAGUES.filter((l) => l.key !== leagueKey)).map((l) => (
          <Link
            key={l.key}
            href={`/topscorers/${l.key}`}
            className="shrink-0 rounded-xl border border-border/50 bg-card/50 px-3 py-2 text-[11px] font-bold text-muted-foreground hover:border-border hover:text-foreground transition-all"
          >
            {l.faName}
          </Link>
        ))}
      </div>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 text-destructive text-sm px-4 py-3">
          {error}
        </div>
      )}

      {loading ? (
        <Skeleton />
      ) : data && data.scorers.length > 0 ? (
        <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
          <ol className="divide-y divide-border/25">
            {data.scorers.map((s, i) => (
              <li key={`${s.name}-${i}`} className="px-3 sm:px-4 py-3 hover:bg-accent/30 transition-colors">
                <div className="flex items-center gap-3">
                  <span
                    className={cn(
                      "w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0 tabular-persian",
                      i === 0
                        ? "bg-chart-3/20 text-chart-3 border border-chart-3/30"
                        : i <= 2
                          ? "bg-chart-3/10 text-chart-3/90 border border-chart-3/20"
                          : "bg-muted text-muted-foreground"
                    )}
                  >
                    {faDigits(s.rank || i + 1)}
                  </span>
                  <div className="min-w-0 flex-1">
                    {s.playerId ? (
                      <Link
                        href={`/player/${s.playerId}`}
                        prefetch={false}
                        className="font-bold text-[13px] truncate block hover:text-primary transition-colors w-fit max-w-full"
                        title="مشاهده پروفایل بازیکن"
                      >
                        {s.name}
                      </Link>
                    ) : (
                      <p className="font-bold text-[13px] truncate">{s.name}</p>
                    )}
                    <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground mt-0.5 flex-wrap">
                      {s.team && <span className="truncate">{s.team}</span>}
                      <ScorerBadges s={s} />
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
            ))}
          </ol>
        </div>
      ) : (
        !error && (
          <p className="text-center text-muted-foreground text-sm py-12">
            داده گلزنان این لیگ هنوز منتشر نشده است.
          </p>
        )
      )}

      {data && !loading && (
        <p className="text-[10px] text-muted-foreground px-1">
          رتبه‌ها مخصوص همین لیگ است. بج‌ها: پاس گل، مجموع گل+پاس، ریتینگ فوت‌ماب، xG و میانگین دقایق هر گل. نوار زیر هر ردیف سهم گل بازیکن از صدرنشین لیگ را نشان می‌دهد. منبع داده: فوت‌ماب.
        </p>
      )}
    </div>
  );
}
