"use client";

// ------------------------------------------------------------------
// Remontada — global top scorers page (merged race across 7 leagues)
// Cycle 10: league filter persists in localStorage; each scorer shows
// their global rank, and inside a league filter the league-local rank
// plus a «جهانی #» badge.
// Phase 3 theme: glass scoring-chart poster — leader hero tile with
// the oversized light metric + pill-ranked rows (studio look).
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { GlobalScorer, GlobalScorersData } from "@/lib/fotmob";
import { LEAGUES } from "@/lib/leagues";
import { ScorerAvatarTile, GlassPosterMeta, pad2 } from "@/components/remontada/glass-stats";
import { faDigits } from "@/lib/format";
import { cn } from "@/lib/utils";

const ALL_KEY = "all";
const FILTER_STORAGE_KEY = "remontada:topscorers-filter";

function ScorerBadges({ s }: { s: GlobalScorer }) {
  const badges: { label: string; cls: string; title: string }[] = [];
  if (s.assists != null && s.assists > 0) {
    badges.push({ label: `${faDigits(s.assists)} پاس گل`, cls: "bg-chart-2/10 border-chart-2/25 text-chart-2", title: "پاس گل فصل" });
  }
  if (s.gPlusA != null && s.gPlusA > 0) {
    badges.push({ label: `${faDigits(s.gPlusA)} گل+پاس`, cls: "bg-primary/10 border-primary/25 text-primary", title: "مجموع گل و پاس گل" });
  }
  if (s.xg != null && s.xg > 0) {
    badges.push({ label: `xG ${faDigits(s.xg.toFixed(1))}`, cls: "bg-muted border-border text-muted-foreground", title: "گل مورد انتظار" });
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

function ScorerRow({ s, mainRank, showGlobal }: { s: GlobalScorer; mainRank: number; showGlobal: boolean }) {
  return (
    <li className="px-2.5 sm:px-3 py-2.5 glass-row-hover">
      <div className="flex items-center gap-3">
        <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[11px] font-bold shrink-0 tabular-persian">
          {faDigits(pad2(mainRank))}
        </span>
        <div className="min-w-0 flex-1">
          {s.playerId ? (
            <Link
              href={`/player/${s.playerId}`}
              prefetch={false}
              className="font-bold text-[13px] truncate block hover:text-primary transition-colors w-fit max-w-full text-[#e5eefb]"
              title="مشاهده پروفایل بازیکن"
            >
              {s.name}
            </Link>
          ) : (
            <p className="font-bold text-[13px] truncate text-[#e5eefb]">{s.name}</p>
          )}
          <div className="flex items-center gap-1.5 text-[10px] text-[#92adc9] mt-0.5 flex-wrap">
            <span className="truncate">{s.team}</span>
            <span aria-hidden>·</span>
            <Link
              href={`/league/${s.leagueKey}`}
              className="shrink-0 rounded-md border border-glass-border-soft bg-white/[0.03] px-1.5 py-px font-bold hover:text-primary hover:border-primary/40 transition-colors"
            >
              {s.leagueFa}
            </Link>
            {showGlobal && (
              <span
                title={`رتبه جهانی در میان گلزنان همه لیگ‌ها`}
                className="shrink-0 rounded-md bg-chart-3/10 border border-chart-3/25 text-chart-3 px-1.5 py-px font-bold tabular-persian"
              >
                جهانی {faDigits(s.rank)}
              </span>
            )}
            <ScorerBadges s={s} />
          </div>
        </div>
        <span className="shrink-0 min-w-[44px] text-center rounded-lg bg-[#a9cdf611] px-2 py-1.5">
          <span className="font-semibold text-[#e0efff] tabular-persian text-[15px]">{faDigits(s.goals)}</span>
          <span className="text-[8px] font-bold text-[#8fa8c1] ms-1">گل</span>
        </span>
      </div>
    </li>
  );
}

function AssistsCard({ data }: { data: GlobalScorersData }) {
  const list = data.assists || [];
  if (list.length === 0) return null;
  return (
    <div className="glass-card overflow-hidden">
      <header className="flex items-center gap-2 px-4 py-2.5 border-b border-[color:var(--glass-hairline)]">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" className="text-chart-2" aria-hidden>
          <path d="M4 19h16" />
          <path d="M5 15l5-5 4 3 5-7" />
        </svg>
        <h2 className="text-[12.5px] font-black">مسابقه پاس گل</h2>
        <span className="ms-auto text-[10px] text-steel tabular-persian">{faDigits(list.length)} بازیکن برتر</span>
      </header>
      <ol className="p-1.5 flex flex-col">
        {list.slice(0, 8).map((a) => (
          <li key={`${a.leagueKey}-${a.name}`} className="flex items-center gap-3 px-2 sm:px-2.5 py-2.5 rounded-lg glass-row-hover">
            <span className="w-[26px] h-[26px] rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
              {faDigits(pad2(a.rank))}
            </span>
            <div className="min-w-0 flex-1">
              {a.playerId ? (
                <Link
                  href={`/player/${a.playerId}`}
                  prefetch={false}
                  className="font-bold text-[12.5px] truncate block hover:text-primary transition-colors w-fit max-w-full text-[#e5eefb]"
                  title="مشاهده پروفایل بازیکن"
                >
                  {a.name}
                </Link>
              ) : (
                <p className="font-bold text-[12.5px] truncate text-[#e5eefb]">{a.name}</p>
              )}
              <div className="flex items-center gap-1.5 text-[9.5px] text-[#92adc9] mt-0.5 min-w-0">
                <span className="truncate">{a.team}</span>
                <span aria-hidden>·</span>
                <Link href={`/league/${a.leagueKey}`} className="shrink-0 hover:text-primary transition-colors font-bold">
                  {a.leagueFa}
                </Link>
              </div>
            </div>
            <span className="shrink-0 min-w-[38px] text-center rounded-lg bg-[#a9cdf611] px-2 py-1">
              <span className="font-semibold text-[#e0efff] tabular-persian text-[14px]">{faDigits(a.value)}</span>
              <span className="text-[8px] font-bold text-[#8fa8c1] ms-1">پاس</span>
            </span>
          </li>
        ))}
      </ol>
    </div>
  );
}

function Skeleton() {
  return (
    <div className="glass-card overflow-hidden" aria-busy="true">
      {Array.from({ length: 10 }).map((_, i) => (
        <div key={i} className="flex items-center gap-3 px-4 py-3 border-b border-[color:var(--glass-hairline)] last:border-0">
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
  const [filterReady, setFilterReady] = useState(false);

  // restore the league filter once on mount — URL ?league= takes precedence over localStorage
  useEffect(() => {
    let restored = false;
    try {
      const q = new URLSearchParams(window.location.search).get("league");
      if (q && (q === ALL_KEY || LEAGUES.some((l) => l.key === q))) {
        setFilter(q);
        restored = true;
      }
    } catch {
      // URL parsing unavailable — fall back to storage
    }
    if (!restored) {
      try {
        const v = window.localStorage.getItem(FILTER_STORAGE_KEY);
        if (v && (v === ALL_KEY || LEAGUES.some((l) => l.key === v))) setFilter(v);
      } catch {
        // storage unavailable — default filter
      }
    }
    setFilterReady(true);
  }, []);

  // persist on every change: localStorage + shareable ?league= URL (after hydration)
  useEffect(() => {
    if (!filterReady) return;
    try {
      window.localStorage.setItem(FILTER_STORAGE_KEY, filter);
    } catch {
      // quota / private mode — non-critical
    }
    try {
      const url = new URL(window.location.href);
      if (filter === ALL_KEY) url.searchParams.delete("league");
      else url.searchParams.set("league", filter);
      window.history.replaceState(null, "", url.toString());
    } catch {
      // history API unavailable — non-critical
    }
  }, [filter, filterReady]);

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

  const showGlobal = filter === ALL_KEY;

  const withMainRank = useMemo(
    () => visible.map((s, i) => ({ s, mainRank: showGlobal ? s.rank : s.leagueRank || i + 1 })),
    [visible, showGlobal]
  );

  const heroScorer = withMainRank.length > 0 ? withMainRank[0] : null;
  const restRank = withMainRank.slice(1);

  const countOf = (key: string) =>
    key === ALL_KEY
      ? data?.scorers.length
      : data?.perLeague.find((p) => p.leagueKey === key)?.scorers.length;

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

      {/* filter chips (persisted in localStorage) */}
      <div className="flex gap-2 overflow-x-auto pb-1.5 -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" role="tablist" aria-label="فیلتر لیگ">
        <button
          onClick={() => setFilter(ALL_KEY)}
          className={cn(
            "shrink-0 rounded-xl border px-3.5 py-2 text-xs font-bold transition-all",
            filter === ALL_KEY
              ? "bg-primary/15 border-primary/40 text-primary shadow-[inset_0_1px_0_oklch(0.88_0.05_232/22%)]"
              : "bg-white/[0.035] border-glass-border-soft text-muted-foreground hover:border-glass-border hover:text-foreground"
          )}
        >
          همه لیگ‌ها
          {data?.scorers.length ? <span className="ms-1.5 text-[9px] opacity-60 tabular-persian">{faDigits(data.scorers.length)}</span> : null}
        </button>
        {(data ? leaguesWithScorers : LEAGUES).map((l) => {
          const n = countOf(l.key);
          return (
            <button
              key={l.key}
              onClick={() => setFilter(l.key)}
              className={cn(
                "shrink-0 rounded-xl border px-3.5 py-2 text-xs font-bold transition-all",
                filter === l.key
                  ? "bg-primary/15 border-primary/40 text-primary shadow-[inset_0_1px_0_oklch(0.88_0.05_232/22%)]"
                  : "bg-white/[0.035] border-glass-border-soft text-muted-foreground hover:border-glass-border hover:text-foreground"
              )}
            >
              {l.faName}
              {n != null && n > 0 ? <span className="ms-1.5 text-[9px] opacity-60 tabular-persian">{faDigits(n)}</span> : null}
            </button>
          );
        })}
      </div>

      {/* dedicated per-league scorers page link (visible when a league filter is active) */}
      {filter !== ALL_KEY && (
        <Link
          href={`/topscorers/${filter}`}
          className="self-start inline-flex items-center gap-1.5 rounded-xl border border-chart-3/30 bg-chart-3/10 px-3.5 py-2 text-xs font-bold text-chart-3 hover:bg-chart-3/15 transition-all"
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden>
            <circle cx="12" cy="8" r="5" />
            <path d="M8.5 12.5L7 22l5-3 5 3-1.5-9.5" />
          </svg>
          صفحه اختصاصی گلزنان {LEAGUES.find((l) => l.key === filter)?.faName || ""}
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" aria-hidden>
            <path d="M15 5l-7 7 7 7" />
          </svg>
        </Link>
      )}

      {error && (
        <div className="rounded-xl border border-destructive/30 bg-destructive/10 text-destructive text-sm px-4 py-3">
          {error}
        </div>
      )}

      {loading ? (
        <Skeleton />
      ) : withMainRank.length > 0 ? (
        <div className="glass-card overflow-hidden">
          {/* hero — the studio scoring-chart leader tile */}
          {heroScorer && (
            <>
              <GlassPosterMeta
                className="mt-3"
                right="رتبه‌بندی گلزنان"
                left={`${faDigits(withMainRank.length)} بازیکن`}
              />
              <div className="m-3 mt-2 glass-scorer-hero p-3.5 sm:p-5 flex items-center gap-3.5 sm:gap-5">
                <ScorerAvatarTile name={heroScorer.s.name} size={56} />
                <div className="min-w-0 flex-1">
                  <p className="text-[8px] font-bold tracking-[0.24em] text-[#9dbad8] uppercase">
                    {showGlobal ? "GLOBAL TOP SCORER" : "LEAGUE LEADER"}
                  </p>
                  {heroScorer.s.playerId ? (
                    <Link
                      href={`/player/${heroScorer.s.playerId}`}
                      prefetch={false}
                      className="block text-lg sm:text-2xl font-bold text-[#f1f7fd] truncate mt-1 hover:text-primary transition-colors w-fit max-w-full"
                      title="مشاهده پروفایل بازیکن"
                    >
                      {heroScorer.s.name}
                    </Link>
                  ) : (
                    <p className="text-lg sm:text-2xl font-bold text-[#f1f7fd] truncate mt-1">{heroScorer.s.name}</p>
                  )}
                  <div className="flex items-center gap-1.5 text-[10.5px] text-[#b1c9e2] mt-1.5 flex-wrap">
                    <span className="truncate">{heroScorer.s.team}</span>
                    {showGlobal && (
                      <span className="shrink-0 rounded-md border border-glass-border-soft bg-white/[0.04] px-1.5 py-px text-[9px] font-bold">
                        {heroScorer.s.leagueFa}
                      </span>
                    )}
                    <ScorerBadges s={heroScorer.s} />
                  </div>
                </div>
                <div className="text-center shrink-0">
                  <p className="text-[44px] sm:text-[56px] leading-none font-light text-[#dfedff] tabular-persian">
                    {faDigits(pad2(heroScorer.s.goals))}
                  </p>
                  <p className="text-[8.5px] font-bold text-[#c6dcf3] mt-1.5">گل</p>
                </div>
              </div>
            </>
          )}
          {/* mobile / tablet: single ranked list */}
          <ol className="lg:hidden mt-1">
            {restRank.map(({ s, mainRank }) => (
              <ScorerRow key={`${s.leagueKey}-${s.name}`} s={s} mainRank={mainRank} showGlobal={showGlobal} />
            ))}
          </ol>
          {/* desktop: two ranked columns (right column = first half, RTL-aware) */}
          <div className="hidden lg:grid lg:grid-cols-2 mt-1">
            <ol>
              {restRank.slice(0, Math.ceil(restRank.length / 2)).map(({ s, mainRank }) => (
                <ScorerRow key={`${s.leagueKey}-${s.name}`} s={s} mainRank={mainRank} showGlobal={showGlobal} />
              ))}
            </ol>
            <ol className="border-s border-[color:var(--glass-hairline)]">
              {restRank.slice(Math.ceil(restRank.length / 2)).map(({ s, mainRank }) => (
                <ScorerRow key={`${s.leagueKey}-${s.name}`} s={s} mainRank={mainRank} showGlobal={showGlobal} />
              ))}
            </ol>
          </div>
        </div>
      ) : (
        <p className="text-center text-muted-foreground text-sm py-12">
          داده گلزنان این بخش هنوز منتشر نشده است.
        </p>
      )}

      {data && !loading && <AssistsCard data={data} />}

      {data && !loading && (
        <p className="text-[10px] text-muted-foreground px-1">
          در نمای «همه لیگ‌ها» رتبه‌ی جهانی هر گلزن دیده می‌شود؛ با انتخاب یک لیگ، رتبه در همان لیگ به‌همراه نشان «جهانی» نمایش داده می‌شود. بج‌های سبز/فیروزه‌ای پاس گل و گل+پاس و xG هر گلزن را نشان می‌دهند. فیلتر انتخابی شما ذخیره می‌ماند و در آدرس صفحه هم منعکس می‌شود تا بتوانید لینک مستقیم هر لیگ را به‌اشتراک بگذارید.
        </p>
      )}
    </div>
  );
}
