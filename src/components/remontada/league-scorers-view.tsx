"use client";

// ------------------------------------------------------------------
// Remontada — per-league top scorers view (/topscorers/[leagueKey])
// Full ranked list of one league with rich badges (assists / G+A / xG
// / rating / minutes-per-goal). Phase 3 theme: glass scoring-chart
// poster — leader hero tile + pill-ranked rows (studio look).
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { ScorerEntry } from "@/lib/fotmob";
import { EmptyState } from "@/components/remontada/empty-state";
import { LEAGUES } from "@/lib/leagues";
import { ScorerAvatarTile, GlassLeagueHeader, pad2 } from "@/components/remontada/glass-stats";
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
    <div className="glass-card overflow-hidden" aria-busy="true">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex items-center gap-3 px-4 py-3 border-b border-[color:var(--glass-hairline)] last:border-0">
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

  const lgCfg = LEAGUES.find((l) => l.key === leagueKey);

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
            آقای گلان {data?.leagueFa || lgCfg?.faName || "لیگ"}
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
          className="rounded-xl border border-glass-border-soft bg-white/[0.035] px-3.5 py-2 text-xs font-bold text-muted-foreground hover:text-primary hover:border-primary/40 transition-all"
        >
          جدول و برنامه
        </Link>
        {(LEAGUES.filter((l) => l.key !== leagueKey)).map((l) => (
          <Link
            key={l.key}
            href={`/topscorers/${l.key}`}
            className="shrink-0 rounded-xl border border-glass-border-soft bg-white/[0.035] px-3 py-2 text-[11px] font-bold text-muted-foreground hover:border-glass-border hover:text-foreground transition-all"
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
        <div className="glass-card overflow-hidden">
          <GlassLeagueHeader
            leagueId={lgCfg?.fotmobId}
            title={`آقای گل ${data.leagueFa}`}
            sub={lgCfg ? `${lgCfg.ccode3} · ${lgCfg.enName}` : undefined}
            season={data.season ? `فصل ${faDigits(data.season)}` : undefined}
          />
          <div className="p-2.5 flex flex-col">
            {/* hero — the studio scoring-chart leader tile */}
            {(() => {
              const top = data.scorers[0];
              return (
                <div className="glass-scorer-hero p-4 sm:p-5 flex items-center gap-3.5 sm:gap-5">
                  <ScorerAvatarTile name={top.name} size={60} />
                  <div className="min-w-0 flex-1">
                    <p className="text-[8px] font-bold tracking-[0.24em] text-[#9dbad8] uppercase">LEAGUE LEADER</p>
                    {top.playerId ? (
                      <Link
                        href={`/player/${top.playerId}`}
                        prefetch={false}
                        className="block text-lg sm:text-2xl font-bold text-[#f1f7fd] truncate mt-1 hover:text-primary transition-colors w-fit max-w-full"
                        title={`پروفایل ${top.name}`}
                      >
                        {top.name}
                      </Link>
                    ) : (
                      <p className="text-lg sm:text-2xl font-bold text-[#f1f7fd] truncate mt-1">{top.name}</p>
                    )}
                    <div className="flex items-center gap-1.5 text-[10.5px] text-[#b1c9e2] mt-1.5 flex-wrap">
                      {top.team && <span className="truncate">{top.team}</span>}
                      <ScorerBadges s={top} />
                    </div>
                  </div>
                  <div className="text-center shrink-0">
                    <p className="text-[44px] sm:text-[56px] leading-none font-light text-[#dfedff] tabular-persian">
                      {faDigits(pad2(top.goals))}
                    </p>
                    <p className="text-[8.5px] font-bold text-[#c6dcf3] mt-1.5">گل</p>
                  </div>
                </div>
              );
            })()}
            <ol className="mt-1.5 flex flex-col">
              {data.scorers.slice(1).map((s, i) => {
                const rank = s.rank ?? i + 2;
                const inner = (
                  <>
                    <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[11px] font-bold shrink-0 tabular-persian">
                      {faDigits(pad2(rank))}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-[13px] font-bold text-[#e5eefb] truncate">{s.name}</span>
                      <span className="flex items-center gap-1.5 text-[9.5px] text-[#92adc9] mt-0.5 flex-wrap">
                        {s.team && <span className="truncate">{s.team}</span>}
                        <ScorerBadges s={s} />
                      </span>
                    </span>
                    <span className="shrink-0 min-w-[40px] text-center rounded-lg bg-[#a9cdf611] px-2 py-1.5">
                      <span className="font-semibold text-[#e0efff] tabular-persian text-[15px]">{faDigits(s.goals)}</span>
                      <span className="text-[8px] font-bold text-[#8fa8c1] ms-1">گل</span>
                    </span>
                  </>
                );
                const cls = "flex items-center gap-3 px-2 sm:px-3 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
                return (
                  <li key={`${s.name}-${i}`}>
                    {s.playerId ? (
                      <Link href={`/player/${s.playerId}`} prefetch={false} className={cls} title={`پروفایل ${s.name}`}>
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
        </div>
      ) : (
        !error && (
          <EmptyState
            icon="medal"
            compact
            title="داده گلزنان این لیگ هنوز منتشر نشده است"
            sub="معمولاً پس از شروع فصل و پایان هفته‌ی نخست منتشر می‌شود."
          />
        )
      )}

      {data && !loading && (
        <p className="text-[10px] text-muted-foreground px-1">
          رتبه‌ها مخصوص همین لیگ است. بج‌ها: پاس گل، مجموع گل+پاس، ریتینگ فوت‌ماب، xG و میانگین دقایق هر گل. منبع داده: فوت‌ماب.
        </p>
      )}
    </div>
  );
}
