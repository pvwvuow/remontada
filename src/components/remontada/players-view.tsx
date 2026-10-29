"use client";

// ------------------------------------------------------------------
// Remontada — «بازیکنان» hub (out-of-cycle user request: «صفحهٔ بازیکنان
// را طراحی کن»). Photo-centric grid of the star players across the 7
// covered leagues, built on the same live /api/topscorers merge the
// گلزنان page uses (scorers + assists) — every card with a known FotMob
// player id shows the real player photo and deep-links to /player/[id].
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { GlobalScorer, GlobalAssist, GlobalScorersData } from "@/lib/fotmob";
import { EmptyState } from "@/components/remontada/empty-state";
import { TeamLogo } from "@/components/remontada/team-logo";
import { PlayerPhoto } from "@/components/remontada/player-photo";
import { faDigits, timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";

type Metric = "goals" | "assists";
const METRIC_FA: Record<Metric, string> = { goals: "گل", assists: "پاس گل" };

// unified card row — scorers and assists flatten into the same shape
interface Row {
  key: string;
  playerId?: number;
  name: string;
  nameFa?: string;
  team: string;
  teamId: number;
  leagueFa: string;
  value: number;        // active metric value (goals or assists)
  extraAssists?: number; // scorers only
  gPlusA?: number;       // scorers only
  rating?: number;       // scorers only
}

function toRows(metric: Metric, scorers: GlobalScorer[], assists: GlobalAssist[]): Row[] {
  if (metric === "goals") {
    return scorers
      .filter((s) => s.goals > 0)
      .map((s) => ({
        key: `${s.leagueKey}-${s.playerId ?? s.name}`,
        playerId: s.playerId,
        name: s.name,
        nameFa: s.nameFa,
        team: s.team,
        teamId: s.teamId,
        leagueFa: s.leagueFa,
        value: s.goals,
        extraAssists: s.assists ?? undefined,
        gPlusA: s.gPlusA ?? undefined,
        rating: s.rating ?? undefined,
      }));
  }
  return assists
    .filter((a) => a.value > 0)
    .map((a) => ({
      key: `${a.leagueKey}-${a.playerId ?? a.name}`,
      playerId: a.playerId,
      name: a.name,
      nameFa: a.nameFa,
      team: a.team,
      teamId: a.teamId,
      leagueFa: a.leagueFa,
      value: a.value,
    }));
}

function PlayerCard({ p, rank, metric, big = false }: { p: Row; rank: number; metric: Metric; big?: boolean }) {
  const name = p.nameFa || p.name;
  const chips: { label: string; value: string; cls: string; title: string }[] = [
    { label: METRIC_FA[metric], value: faDigits(p.value), cls: "bg-primary/10 border-primary/25 text-primary", title: `${METRIC_FA[metric]} فصل` },
  ];
  if (metric === "goals" && p.extraAssists) {
    chips.push({ label: "پاس گل", value: faDigits(p.extraAssists), cls: "bg-chart-2/10 border-chart-2/25 text-chart-2", title: "پاس گل فصل" });
  }
  if (metric === "goals" && p.gPlusA != null && p.gPlusA > 0) {
    chips.push({ label: "گل+پاس", value: faDigits(p.gPlusA), cls: "bg-muted border-border text-muted-foreground", title: "مجموع گل و پاس گل" });
  }
  if (p.rating != null && p.rating > 0) {
    chips.push({ label: "امتیاز", value: faDigits(p.rating.toFixed(1)), cls: "bg-gold/10 border-gold/25 text-gold", title: "میانگین امتیاز فصل" });
  }

  const inner = (
    <>
      <span className="absolute top-2 right-2 w-6 h-6 rounded-lg bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10px] font-bold tabular-persian z-10">
        {faDigits(rank)}
      </span>
      <div className="flex flex-col items-center gap-2 pt-2 w-full min-w-0">
        <PlayerPhoto id={p.playerId} name={name} size={big ? 88 : 60} rounded="rounded-2xl" />
        <div className="min-w-0 text-center w-full">
          <p className="font-black text-[12.5px] truncate text-[#eef5fd]" dir="auto" title={p.nameFa && p.nameFa !== p.name ? p.name : undefined}>
            {name}
          </p>
          <p className="text-[9.5px] text-steel/80 truncate mt-0.5 flex items-center justify-center gap-1" title={`${p.team} — ${p.leagueFa}`}>
            <TeamLogo id={p.teamId} alt="" size={11} />
            <span className="truncate">{p.team}</span>
          </p>
        </div>
        <div className="flex items-center gap-1 flex-wrap justify-center">
          {chips.map((c) => (
            <span key={c.label} title={c.title} className={cn("shrink-0 rounded-md border px-1.5 py-px text-[9px] font-bold tabular-persian", c.cls)}>
              {c.label} {c.value}
            </span>
          ))}
        </div>
      </div>
    </>
  );
  const cls = cn(
    "glass-popover relative rounded-2xl p-3 flex flex-col items-center gap-2",
    p.playerId ? "glass-row-hover" : "opacity-90"
  );
  return p.playerId ? (
    <Link href={`/player/${p.playerId}`} prefetch={false} className={cls} title={`پروفایل ${name}`}>
      {inner}
    </Link>
  ) : (
    <div className={cls}>{inner}</div>
  );
}

export function PlayersView() {
  const [data, setData] = useState<GlobalScorersData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [metric, setMetric] = useState<Metric>("goals");

  useEffect(() => {
    let alive = true;
    fetch("/api/topscorers", { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`))))
      .then((j) => {
        if (!alive) return;
        if (j?.ok && Array.isArray(j.scorers) && j.scorers.length > 0) setData(j as GlobalScorersData);
        else setError("داده‌ای برای نمایش نیست.");
      })
      .catch((e) => alive && setError(e?.message ? `خطا در دریافت بازیکنان (${e.message})` : "خطا در دریافت بازیکنان"));
    return () => {
      alive = false;
    };
  }, []);

  const list: Row[] = useMemo(() => {
    if (!data) return [];
    return toRows(metric, data.scorers ?? [], data.assists ?? []);
  }, [data, metric]);

  if (error) return <EmptyState title="بازیکنان" sub={error} />;

  const hero = list.slice(0, 3);
  const rest = list.slice(3);

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-end justify-between gap-2 flex-wrap">
        <div>
          <h1 className="text-lg font-black">بازیکنان</h1>
          <p className="text-[10.5px] text-steel mt-0.5">ستاره‌های هفت لیگ بزرگ با عکس و پروفایل کامل</p>
        </div>
        {data?.updatedAt && (
          <span className="text-[9px] text-steel/70 tabular-persian">{timeAgoFa(data.updatedAt)}</span>
        )}
      </div>

      {/* metric tabs */}
      <div className="flex items-center gap-1.5" role="tablist" aria-label="انتخاب سنجه">
        {(["goals", "assists"] as Metric[]).map((m) => (
          <button
            key={m}
            type="button"
            role="tab"
            aria-selected={metric === m}
            onClick={() => setMetric(m)}
            className={cn(
              "rounded-xl border px-3 py-1.5 text-[11.5px] font-black transition-all duration-200 active:scale-95",
              metric === m
                ? "text-primary bg-primary/10 border-primary/30 shadow-[0_0_16px_oklch(0.7_0.1_300/0.28)]"
                : "text-muted-foreground border-border hover:text-foreground"
            )}
          >
            {METRIC_FA[m]}
          </button>
        ))}
      </div>

      {!data ? (
        <div className="glass-popover rounded-2xl p-6 text-center text-[12px] text-steel" role="status">
          در حال دریافت بازیکنان…
        </div>
      ) : list.length === 0 ? (
        <EmptyState title="بازیکنان" sub="هنوز آماری برای این سنجه ثبت نشده است." />
      ) : (
        <>
          {/* hero trio */}
          <div className="grid grid-cols-3 gap-2">
            {hero.map((p, i) => (
              <PlayerCard key={p.key} p={p} rank={i + 1} metric={metric} big />
            ))}
          </div>
          {/* grid */}
          {rest.length > 0 && (
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
              {rest.map((p, i) => (
                <PlayerCard key={p.key} p={p} rank={i + 4} metric={metric} />
              ))}
            </div>
          )}
          <p className="text-[9.5px] text-steel/70 text-center pb-1">
            آمار از FotMob — با هر بار بازکردن صفحه خودکار به‌روز می‌شود.
          </p>
        </>
      )}
    </div>
  );
}
