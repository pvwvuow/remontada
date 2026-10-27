"use client";

// ------------------------------------------------------------------
// Remontada — league page: standings | fixtures | recent | scorers
// ------------------------------------------------------------------
import { useEffect, useState } from "react";
import Link from "next/link";
import type { StandingsData, LeagueFixturesData, NormFixture } from "@/lib/fotmob";
import { LEAGUES } from "@/lib/leagues";
import { faDigits, jalaliShort, tehranTime } from "@/lib/format";
import { cn } from "@/lib/utils";

type Tab = "standings" | "fixtures" | "recent" | "scorers";

const TABS: { key: Tab; label: string }[] = [
  { key: "standings", label: "جدول" },
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
        {/* eslint-disable-next-line @next/next/no-img-element */}
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
        {/* eslint-disable-next-line @next/next/no-img-element */}
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
    return (
      <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden divide-y divide-border/25">
        {items.map((f) => (
          <FixtureRow key={f.id} f={f} showResult={showResult} />
        ))}
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
    <div className="flex flex-col gap-4">
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

function ScorersList({ data }: { data: StandingsData }) {
  if (!data.scorers?.length) {
    return <p className="text-center text-muted-foreground text-sm py-10">آقای گل این لیگ هنوز ثبت نشده است.</p>;
  }
  const max = Math.max(...data.scorers.map((s) => s.goals), 1);
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
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
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={r.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                    <span className="font-bold truncate group-hover:text-primary transition-colors">{r.fa || r.name}</span>
                  </Link>
                </td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.played)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian">{faDigits(r.wins)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.draws)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.losses)}</td>
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

  return (
    <div className="flex flex-col gap-4">
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
          {tab === "standings" && (standings ? <StandingsTable data={standings} /> : <p className="text-center text-muted-foreground text-sm py-10">جدولی برای این لیگ ثبت نشده است.</p>)}
          {tab === "fixtures" && <FixtureList items={fixtures?.upcoming || []} showResult={false} dateGrouped />}
          {tab === "recent" && <FixtureList items={fixtures?.recent || []} showResult />}
          {tab === "scorers" && (standings ? <ScorersList data={standings} /> : <p className="text-center text-muted-foreground text-sm py-10">—</p>)}
        </div>
      )}
    </div>
  );
}
