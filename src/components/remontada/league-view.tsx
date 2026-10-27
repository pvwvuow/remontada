"use client";

// ------------------------------------------------------------------
// Remontada — league page: standings | fixtures | recent | scorers
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { StandingsData, StandingsRow, LeagueFixturesData, NormFixture, LeagueStats } from "@/lib/fotmob";
import { LEAGUES } from "@/lib/leagues";
import { SITE_URL } from "@/lib/site";
import { JsonLd } from "@/components/remontada/json-ld";
import { faDigits, jalaliShort, offsetDateISO, tehranDateKey, tehranTime } from "@/lib/format";
import { cn } from "@/lib/utils";

type Tab = "standings" | "stats" | "fixtures" | "recent" | "scorers";

/** Current-week progress bar («هفته ۱۲ از ۳۸») — numeric rounds only. */
function SeasonProgress({ progress }: { progress: { current: number; total: number } }) {
  const pct = Math.min(100, Math.round((progress.current / progress.total) * 100));
  return (
    <section
      className="rounded-2xl border border-border/60 bg-card/60 px-4 py-3 flex items-center gap-3"
      aria-label="پیشرفت هفته جاری فصل"
    >
      <div className="flex items-center gap-2 shrink-0">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" className="text-primary" aria-hidden>
          <rect x="3.5" y="4.5" width="17" height="16" rx="3" />
          <path d="M8 2.5v4M16 2.5v4M3.5 10.5h17" />
        </svg>
        <span className="text-[12px] font-black whitespace-nowrap">
          هفته {faDigits(progress.current)} <span className="text-muted-foreground font-bold">از {faDigits(progress.total)}</span>
        </span>
      </div>
      <div
        className="flex-1 h-2 rounded-full bg-muted overflow-hidden"
        role="progressbar"
        aria-valuemin={1}
        aria-valuemax={progress.total}
        aria-valuenow={progress.current}
      >
        <div className="h-full bg-primary/70 rounded-full transition-all" style={{ width: `${pct}%` }} />
      </div>
      <span className="text-[10.5px] font-bold text-muted-foreground tabular-persian shrink-0">{faDigits(pct)}٪ فصل</span>
    </section>
  );
}

const TABS: { key: Tab; label: string }[] = [
  { key: "standings", label: "جدول" },
  { key: "stats", label: "آمار فصل" },
  { key: "fixtures", label: "بازی‌های پیش‌رو" },
  { key: "recent", label: "نتایج اخیر" },
  { key: "scorers", label: "آقای گل" },
];

function FixtureRow({ f, showResult }: { f: NormFixture; showResult: boolean }) {
  const j = jalaliShort(f.utcTime);
  return (
    <Link
      href={`/match/${f.id}`}
      className="group grid grid-cols-[1fr_auto_1fr] items-center gap-2 px-3 sm:px-4 py-3 hover:bg-accent/40 transition-colors"
      prefetch={false}
    >
      <div className="flex items-center justify-end gap-2 min-w-0 font-semibold">
        <span className="truncate text-[13px]">{f.home.fa || f.home.name}</span>
        { }
        <img src={f.home.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
      </div>
      <div className="flex flex-col items-center min-w-[86px]">
        {showResult ? (
          <span className="font-black text-sm tabular-persian bg-muted/60 rounded-lg px-2.5 py-0.5">
            {f.home.score ?? "—"} : {f.away.score ?? "—"}
          </span>
        ) : (
          <span className="text-[11px] font-black text-foreground/80 tabular-persian">
            {tehranTime(f.utcTime)}
          </span>
        )}
        {f.round && <span className="text-[9px] text-muted-foreground/60 mt-0.5">{f.round}</span>}
      </div>
      <div className="flex items-center gap-2 min-w-0 font-semibold">
        { }
        <img src={f.away.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
        <span className="truncate text-[13px]">{f.away.fa || f.away.name}</span>
      </div>
    </Link>
  );
}

function FixtureList({ items, showResult, dateGrouped }: { items: NormFixture[]; showResult: boolean; dateGrouped?: boolean }) {
  if (items.length === 0) {
    return <p className="text-center text-muted-foreground text-sm py-10">موردی برای نمایش نیست.</p>;
  }
  if (!dateGrouped) {
    // desktop: split into two columns inside one card; mobile: single list
    const mid = Math.ceil(items.length / 2);
    return (
      <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
        <div className="divide-y divide-border/25 lg:hidden">
          {items.map((f) => (
            <FixtureRow key={f.id} f={f} showResult={showResult} />
          ))}
        </div>
        <div className="hidden lg:grid lg:grid-cols-2">
          <div className="divide-y divide-border/25">
            {items.slice(0, mid).map((f) => (
              <FixtureRow key={f.id} f={f} showResult={showResult} />
            ))}
          </div>
          <div className="divide-y divide-border/25 border-s border-border/25">
            {items.slice(mid).map((f) => (
              <FixtureRow key={f.id} f={f} showResult={showResult} />
            ))}
          </div>
        </div>
      </div>
    );
  }
  // group by date for upcoming fixtures
  const byDate = new Map<string, NormFixture[]>();
  for (const f of items) {
    const k = f.utcTime.slice(0, 10);
    if (!byDate.has(k)) byDate.set(k, []);
    byDate.get(k)!.push(f);
  }
  return (
    <div className="flex flex-col gap-4 lg:grid lg:grid-cols-2 lg:items-start">
      {[...byDate.entries()].map(([date, list]) => {
        const j = jalaliShort(`${date}T12:00:00Z`);
        return (
          <div key={date} className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
            <header className="px-4 py-2 border-b border-border/40 bg-muted/25 text-[11px] font-black text-muted-foreground">
              {j.weekday} {j.day} {j.month}
            </header>
            <div className="divide-y divide-border/25">
              {list.map((f) => (
                <FixtureRow key={f.id} f={f} showResult={showResult} />
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ---------- season advanced stats ----------
function WinStatList({ title, items, tone }: { title: string; items: LeagueStats["topHomeWins"]; tone: "home" | "away" }) {
  const max = Math.max(...items.map((i) => i.wins), 1);
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 text-[11px] font-black flex items-center gap-1.5">
        <span aria-hidden>{tone === "home" ? "🏟️" : "✈️"}</span>
        {title}
      </header>
      <ol className="divide-y divide-border/25">
        {items.map((t, i) => (
          <li key={t.teamId} className="flex items-center gap-3 px-4 py-2.5">
            <span className="w-5 text-[11px] font-black text-muted-foreground tabular-persian shrink-0">{faDigits(i + 1)}</span>
            { }
            <img src={t.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
            <div className="min-w-0 flex-1">
              <div className="flex items-center justify-between gap-2">
                <Link href={`/team/${t.teamId}`} className="font-bold text-[12.5px] truncate hover:text-primary transition-colors" prefetch={false}>
                  {t.fa || t.short}
                </Link>
                <span className="text-[11px] font-black text-primary tabular-persian shrink-0">{faDigits(t.wins)} برد</span>
              </div>
              <div className="mt-1 h-1 rounded-full bg-muted overflow-hidden">
                <div className={cn("h-full rounded-full", tone === "home" ? "bg-primary/70" : "bg-chart-4/70")} style={{ width: `${(t.wins / max) * 100}%` }} />
              </div>
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}

function KpiCard({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 px-3 py-3 text-center">
      <p className="text-lg sm:text-xl font-black text-primary tabular-persian leading-6">{value}</p>
      <p className="text-[10.5px] font-bold mt-0.5">{label}</p>
      {sub && <p className="text-[9px] text-muted-foreground mt-0.5 tabular-persian">{sub}</p>}
    </div>
  );
}

function StatsPanel({ stats, leagueFa }: { stats: LeagueStats; leagueFa: string }) {
  const n = stats.finished;
  const pct = (x: number) => (n > 0 ? Math.round((x / n) * 100) : 0);
  const maxRoundGoals = Math.max(...stats.topRounds.map((r) => r.goals), 1);

  if (n === 0) {
    return <p className="text-center text-muted-foreground text-sm py-10">هنوز بازی‌ای از این فصل به پایان نرسیده است؛ آمار بعد از شروع لیگ فعال می‌شود.</p>;
  }

  return (
    <div className="flex flex-col gap-4">
      {/* KPI row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2.5">
        <KpiCard label="میانگین گل هر بازی" value={faDigits(stats.avgGoals.toFixed(2))} sub={`${faDigits(stats.totalGoals)} گل در ${faDigits(n)} بازی`} />
        <KpiCard label="هر دو تیم گل زدند" value={`${faDigits(Math.round(stats.bttsPct))}٪`} sub="از بازی‌های برگزارشده" />
        <KpiCard label="برد میزبان‌ها" value={`${faDigits(pct(stats.homeWins))}٪`} sub={`${faDigits(stats.homeWins)} بازی`} />
        <KpiCard label="برد مهمان‌ها" value={`${faDigits(pct(stats.awayWins))}٪`} sub={`${faDigits(stats.awayWins)} بازی`} />
      </div>

      {/* result split bar */}
      <section className="rounded-2xl border border-border/60 bg-card/60 p-4">
        <h3 className="text-[11px] font-black text-muted-foreground mb-3">ترکیب نتایج {leagueFa} این فصل</h3>
        <div className="flex h-2.5 rounded-full overflow-hidden bg-muted/40" dir="rtl" aria-hidden>
          <div className="bg-primary/80" style={{ width: `${pct(stats.homeWins)}%` }} />
          <div className="bg-muted-foreground/30" style={{ width: `${pct(stats.draws)}%` }} />
          <div className="bg-chart-4/80" style={{ width: `${pct(stats.awayWins)}%` }} />
        </div>
        <div className="flex items-center justify-between mt-2 text-[11px] font-bold tabular-persian">
          <span className="text-primary">{faDigits(stats.homeWins)} برد میزبان</span>
          <span className="text-muted-foreground">{faDigits(stats.draws)} مساوی</span>
          <span className="text-chart-4">{faDigits(stats.awayWins)} برد مهمان</span>
        </div>
      </section>

      {/* most home/away wins */}
      <div className="grid gap-4 lg:grid-cols-2 lg:items-start">
        {stats.topHomeWins.length > 0 && <WinStatList title="بیشترین برد در خانه" items={stats.topHomeWins} tone="home" />}
        {stats.topAwayWins.length > 0 && <WinStatList title="بیشترین برد در بیرون از خانه" items={stats.topAwayWins} tone="away" />}
      </div>

      {/* highest scoring rounds */}
      {stats.topRounds.length > 0 && (
        <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
          <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 text-[11px] font-black">پرگل‌ترین هفته‌های فصل</header>
          <ol className="divide-y divide-border/25">
            {stats.topRounds.map((r, i) => (
              <li key={r.round} className="flex items-center gap-3 px-4 py-2.5">
                <span className={cn(
                  "w-6 h-6 rounded-lg flex items-center justify-center text-[10px] font-black shrink-0 tabular-persian",
                  i === 0 ? "bg-chart-3/20 text-chart-3 border border-chart-3/30" : "bg-muted text-muted-foreground"
                )}>
                  {faDigits(i + 1)}
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-bold text-[12.5px] truncate">{r.round}</span>
                    <span className="text-[11px] font-black tabular-persian shrink-0">{faDigits(r.goals)} گل</span>
                  </div>
                  <div className="mt-1 h-1 rounded-full bg-muted overflow-hidden">
                    <div className="h-full bg-chart-3/60 rounded-full" style={{ width: `${(r.goals / maxRoundGoals) * 100}%` }} />
                  </div>
                  <p className="text-[9px] text-muted-foreground mt-1 tabular-persian">{faDigits(r.games)} بازی · میانگین {faDigits(r.avg.toFixed(1))} گل</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      )}

      {/* biggest win */}
      {stats.biggestWin && (
        <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
          <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 text-[11px] font-black">پرامتیازترین برد فصل</header>
          <Link href={`/match/${stats.biggestWin.id}`} className="flex items-center gap-3 px-4 py-3 hover:bg-accent/30 transition-colors" prefetch={false}>
            <span className="flex items-center justify-end gap-2 flex-1 min-w-0 font-black text-[12.5px]">
              <span className="truncate">{stats.biggestWin.home.fa || stats.biggestWin.home.short}</span>
              { }
              <img src={stats.biggestWin.home.logo} alt="" width={20} height={20} loading="lazy" className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
            </span>
            <span className="font-black text-sm tabular-persian bg-primary/10 text-primary rounded-lg px-2.5 py-1 shrink-0">
              {faDigits(stats.biggestWin.home.score ?? 0)} : {faDigits(stats.biggestWin.away.score ?? 0)}
            </span>
            <span className="flex items-center gap-2 flex-1 min-w-0 font-semibold text-[12.5px] text-muted-foreground">
              { }
              <img src={stats.biggestWin.away.logo} alt="" width={20} height={20} loading="lazy" className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
              <span className="truncate">{stats.biggestWin.away.fa || stats.biggestWin.away.short}</span>
            </span>
          </Link>
          {stats.biggestWin.round && <p className="px-4 pb-2.5 text-[9px] text-muted-foreground/70 tabular-persian">{faDigits(stats.biggestWin.round)}</p>}
        </div>
      )}

      <p className="text-[10px] text-muted-foreground px-1">
        آمار فصل از مجموع {faDigits(n)} بازی به‌پایان‌رسیده‌ی {leagueFa} محاسبه می‌شود و با هر بازی جدید به‌روز می‌شود.
      </p>
    </div>
  );
}

function ScorersList({ data, leagueKey }: { data: StandingsData; leagueKey: string }) {
  if (!data.scorers?.length) {
    return <p className="text-center text-muted-foreground text-sm py-10">آقای گل این لیگ هنوز ثبت نشده است.</p>;
  }
  const max = Math.max(...data.scorers.map((s) => s.goals), 1);
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <header className="flex items-center gap-2 px-4 py-2.5 border-b border-border/40 bg-muted/25">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className="text-chart-3" aria-hidden>
          <circle cx="12" cy="8" r="5" />
          <path d="M8.5 12.5L7 22l5-3 5 3-1.5-9.5" />
        </svg>
        <h3 className="font-black text-[12.5px]">آقای گل</h3>
        <Link
          href={`/topscorers/${leagueKey}`}
          className="ms-auto inline-flex items-center gap-1 text-[10px] font-bold text-chart-3 hover:text-primary transition-colors"
        >
          صفحه کامل گلزنان
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" aria-hidden>
            <path d="M15 5l-7 7 7 7" />
          </svg>
        </Link>
      </header>
      <ol className="divide-y divide-border/25">
        {data.scorers.map((s, i) => (
          <li key={`${s.name}-${i}`} className="flex items-center gap-3 px-4 py-3">
            <span
              className={cn(
                "w-7 h-7 rounded-lg flex items-center justify-center text-xs font-black shrink-0 tabular-persian",
                i === 0 ? "bg-chart-3/20 text-chart-3 border border-chart-3/30" : "bg-muted text-muted-foreground"
              )}
            >
              {faDigits(s.rank ?? i + 1)}
            </span>
            <div className="min-w-0 flex-1">
              <p className="font-bold text-[13px] truncate">{s.name}</p>
              {s.team && <p className="text-[10px] text-muted-foreground truncate">{s.team}</p>}
              <div className="mt-1.5 h-1 rounded-full bg-muted overflow-hidden">
                <div className="h-full bg-chart-3/70 rounded-full" style={{ width: `${(s.goals / max) * 100}%` }} />
              </div>
            </div>
            <span className="font-black text-primary tabular-persian text-lg">{faDigits(s.goals)}</span>
          </li>
        ))}
      </ol>
    </div>
  );
}

// ---------- pre-match preview: today's fixtures enriched from cached standings ----------

function FormDotsMini({ form }: { form?: ("W" | "D" | "L")[] }) {
  if (!form || form.length === 0) return null;
  return (
    <span className="flex items-center gap-1" title="پنج بازی آخر در لیگ" aria-label="فرم پنج بازی اخیر">
      {form.slice(-5).map((f, i) => (
        <span
          key={i}
          className={cn(
            "w-[7px] h-[7px] rounded-full",
            f === "W" ? "bg-primary/80" : f === "D" ? "bg-muted-foreground/40" : "bg-destructive/70"
          )}
        />
      ))}
    </span>
  );
}

function PreviewSide({
  team,
  row,
}: {
  team: { id: number; name: string; fa: string; logo: string };
  row?: StandingsRow;
}) {
  return (
    <div className="flex flex-col items-center gap-1.5 text-center min-w-0">
      <Link href={`/team/${team.id}`} prefetch={false} className="flex items-center gap-2 min-w-0 group">
        { }
        <img src={team.logo} alt="" width={22} height={22} loading="lazy" className="w-[22px] h-[22px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
        <span className="font-black text-[12.5px] sm:text-[13px] truncate group-hover:text-primary transition-colors">
          {team.fa || team.name}
        </span>
      </Link>
      {row ? (
        <>
          <span className="text-[10px] font-bold text-muted-foreground tabular-persian whitespace-nowrap">
            رتبه {faDigits(row.idx)} · {faDigits(row.pts)} امتیاز
          </span>
          <div className="flex items-center gap-2">
            <FormDotsMini form={row.form} />
            <span className="text-[9.5px] text-muted-foreground tabular-persian" title="گل زده : گل خورده در لیگ">
              گل {faDigits(row.goalsFor)}:{faDigits(row.goalsAgainst)}
            </span>
          </div>
        </>
      ) : (
        <span className="text-[10px] text-muted-foreground/70">خارج از جدول</span>
      )}
    </div>
  );
}

/** today's not-started fixtures with rank / form / goals from the same cached standings */
function PreMatchPreview({ fixtures, standings }: { fixtures: NormFixture[]; standings: StandingsData | null }) {
  const rowsById = useMemo(
    () => new Map((standings?.rows || []).map((r) => [r.teamId, r])),
    [standings]
  );
  const today = offsetDateISO(0);
  const todays = fixtures.filter((f) => !f.cancelled && !f.started && tehranDateKey(f.utcTime) === today);
  if (todays.length === 0) return null;
  const shown = todays.slice(0, 4);

  return (
    <section className="rounded-2xl border border-primary/25 bg-gradient-to-l from-primary/[0.1] via-card/60 to-card/40 overflow-hidden" aria-label="پیش‌نمایش بازی‌های امروز">
      <header className="px-4 py-2 border-b border-primary/15 bg-primary/[0.08] flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black text-primary">پیش‌نمایش بازی‌های امروز</h2>
        <span className="text-[10px] font-bold text-muted-foreground tabular-persian">{faDigits(todays.length)} بازی</span>
      </header>
      <div className="divide-y divide-border/25">
        {shown.map((f) => (
          <div key={f.id} className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 sm:gap-4 px-3 sm:px-5 py-3.5">
            <PreviewSide team={f.home} row={rowsById.get(f.home.id)} />
            <Link
              href={`/match/${f.id}`}
              prefetch={false}
              className="flex flex-col items-center gap-1 shrink-0 min-w-[62px] rounded-xl border border-border/50 bg-muted/30 px-2.5 py-2 hover:border-primary/40 hover:bg-primary/5 transition-colors"
              title="صفحه بازی"
            >
              <span className="text-[12px] font-black tabular-persian">{tehranTime(f.utcTime)}</span>
              <span className="text-[8.5px] text-muted-foreground font-bold">امروز</span>
            </Link>
            <PreviewSide team={f.away} row={rowsById.get(f.away.id)} />
          </div>
        ))}
      </div>
      {todays.length > shown.length && (
        <p className="text-[10px] text-muted-foreground px-4 py-2 border-t border-border/25 tabular-persian">
          و {faDigits(todays.length - shown.length)} بازی دیگر امروز — در تب «بازی‌های پیش‌رو»
        </p>
      )}
    </section>
  );
}

function StandingsTable({ data }: { data: StandingsData }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-[12px] sm:text-[13px] min-w-[480px]">
          <thead>
            <tr className="text-muted-foreground text-[10px] sm:text-[11px] border-b border-border/40 bg-muted/25">
              <th className="py-2.5 pe-1 ps-3 font-bold text-start w-8">#</th>
              <th className="py-2.5 px-1 font-bold text-start">تیم</th>
              <th className="py-2.5 px-1.5 font-bold text-center">ب</th>
              <th className="py-2.5 px-1.5 font-bold text-center">بر</th>
              <th className="py-2.5 px-1.5 font-bold text-center">مس</th>
              <th className="py-2.5 px-1.5 font-bold text-center">با</th>
              <th className="py-2.5 px-1.5 font-bold text-center hidden lg:table-cell" title="گل زده">گز</th>
              <th className="py-2.5 px-1.5 font-bold text-center hidden lg:table-cell" title="گل خورده">گخ</th>
              <th className="py-2.5 px-1.5 font-bold text-center hidden sm:table-cell">تف</th>
              <th className="py-2.5 px-2.5 font-black text-center">امتیاز</th>
            </tr>
          </thead>
          <tbody>
            {data.rows.map((r) => (
              <tr key={r.teamId} className="border-b border-border/25 last:border-0 hover:bg-accent/30 transition-colors">
                <td className="py-2.5 pe-1 ps-3 relative">
                  {r.qualColor && <span className="absolute inset-y-1 right-0 w-[3px] rounded-full" style={{ backgroundColor: r.qualColor }} aria-hidden />}
                  <span className="font-bold text-muted-foreground tabular-persian">{faDigits(r.idx)}</span>
                </td>
                <td className="py-2 px-1">
                  <Link href={`/team/${r.teamId}`} className="flex items-center gap-2 min-w-0 group" prefetch={false}>
                    { }
                    <img src={r.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                    <span className="font-bold truncate group-hover:text-primary transition-colors">{r.fa || r.name}</span>
                  </Link>
                </td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.played)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian">{faDigits(r.wins)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.draws)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.losses)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground hidden lg:table-cell">{faDigits(r.goalsFor)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground hidden lg:table-cell">{faDigits(r.goalsAgainst)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground hidden sm:table-cell">{r.gd > 0 ? `+${faDigits(r.gd)}` : faDigits(r.gd)}</td>
                <td className="py-2 px-2.5 text-center">
                  <span className="font-black text-primary tabular-persian bg-primary/10 rounded-lg px-2 py-0.5 inline-block min-w-[34px]">{faDigits(r.pts)}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function LeagueView({ leagueKey }: { leagueKey: string }) {
  const lg = LEAGUES.find((l) => l.key === leagueKey);
  const [tab, setTab] = useState<Tab>("standings");
  const [standings, setStandings] = useState<StandingsData | null>(null);
  const [fixtures, setFixtures] = useState<LeagueFixturesData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    (async () => {
      try {
        const [stRes, fxRes] = await Promise.allSettled([
          fetch(`/api/standings?league=${leagueKey}`, { cache: "no-store" }).then((r) => r.json()),
          fetch(`/api/league-fixtures?league=${leagueKey}`, { cache: "no-store" }).then((r) => r.json()),
        ]);
        if (cancelled) return;
        if (stRes.status === "fulfilled" && stRes.value.ok) setStandings(stRes.value as StandingsData);
        if (fxRes.status === "fulfilled" && fxRes.value.ok) setFixtures(fxRes.value as LeagueFixturesData);
        if ((stRes.status === "fulfilled" && !stRes.value.ok) && (fxRes.status === "fulfilled" && !fxRes.value.ok)) {
          setError("دریافت داده‌های لیگ ناموفق بود.");
        }
      } catch {
        if (!cancelled) setError("ارتباط برقرار نشد.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [leagueKey]);

  if (!lg) {
    return <p className="text-center text-muted-foreground text-sm py-16">لیگ مورد نظر یافت نشد.</p>;
  }

  // JSON-LD: standings table as ItemList of SportsTeam (client-rendered, read by crawlers)
  const standingsLd = standings?.rows?.length
    ? {
        "@context": "https://schema.org",
        "@type": "ItemList",
        "name": `جدول رده‌بندی ${lg.faName}`,
        "numberOfItems": standings.rows.length,
        "itemListElement": standings.rows.map((r, i) => ({
          "@type": "ListItem",
          "position": i + 1,
          "item": {
            "@type": "SportsTeam",
            "name": r.name,
            "alternateName": r.fa || r.name,
            "url": `${SITE_URL}/team/${r.teamId}`,
          },
        })),
      }
    : null;

  return (
    <div className="flex flex-col gap-4">
      <JsonLd data={standingsLd} />
      {/* league header */}
      <div className="flex items-center justify-between gap-3 px-1">
        <div>
          <h1 className="text-lg font-black">{lg.faName}</h1>
          <p className="text-[11px] text-muted-foreground">
            {standings?.season && <>فصل {faDigits(standings.season)} · </>}
            {fixtures && <>در مجموع {faDigits(fixtures.total)} بازی</>}
          </p>
        </div>
        <span className="text-[10px] font-bold text-muted-foreground border border-border rounded-lg px-2 py-1">
          {lg.ccode3}
        </span>
      </div>

      {/* current-week progress (hidden for cup/non-numeric rounds or missing data) */}
      {fixtures?.progress && <SeasonProgress progress={fixtures.progress} />}

      {/* pre-match preview for today's fixtures (no extra network calls) */}
      <PreMatchPreview fixtures={fixtures?.upcoming || []} standings={standings} />

      {/* tabs */}
      <nav className="flex items-center gap-1 overflow-x-auto border-b border-border/40 -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" aria-label="بخش‌های لیگ">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            aria-current={tab === t.key ? "page" : undefined}
            className={cn(
              "relative px-3.5 py-2 text-[12.5px] font-bold whitespace-nowrap transition-colors",
              tab === t.key ? "text-primary" : "text-muted-foreground hover:text-foreground"
            )}
          >
            {t.label}
            {tab === t.key && <span className="absolute inset-x-3 bottom-0 h-0.5 bg-primary rounded-full" aria-hidden />}
          </button>
        ))}
      </nav>

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 text-destructive text-sm px-4 py-3">
          {error}
        </div>
      )}

      {loading && !standings && !fixtures ? (
        <div className="rounded-2xl border border-border/60 bg-card/40 p-4 flex flex-col gap-3" aria-busy="true">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="h-4 rounded bg-muted animate-pulse" style={{ width: `${40 + ((i * 17) % 45)}%` }} />
          ))}
        </div>
      ) : (
        <div className={cn("transition-opacity", loading && "opacity-50")}>
          {tab === "standings" && (standings ? (
            <div className="grid gap-4 lg:grid-cols-[1fr_300px] lg:items-start">
              <StandingsTable data={standings} />
              {standings.scorers?.length > 0 && <ScorersList data={standings} leagueKey={lg.key} />}
            </div>
          ) : <p className="text-center text-muted-foreground text-sm py-10">جدولی برای این لیگ ثبت نشده است.</p>)}
          {tab === "stats" && (fixtures?.stats ? <StatsPanel stats={fixtures.stats} leagueFa={lg.faName} /> : <p className="text-center text-muted-foreground text-sm py-10">آماری برای این لیگ ثبت نشده است.</p>)}
          {tab === "fixtures" && <FixtureList items={fixtures?.upcoming || []} showResult={false} dateGrouped />}
          {tab === "recent" && <FixtureList items={fixtures?.recent || []} showResult />}
          {tab === "scorers" && (standings ? <ScorersList data={standings} leagueKey={lg.key} /> : <p className="text-center text-muted-foreground text-sm py-10">—</p>)}
        </div>
      )}
    </div>
  );
}
