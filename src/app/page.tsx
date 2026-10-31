"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import type { LeagueGroup, StandingsData } from "@/lib/fotmob";
import { MatchesView, tehranTime } from "@/components/remontada/matches-view";
import { StandingsView } from "@/components/remontada/standings-view";
import { NewsView, type ClientNewsItem } from "@/components/remontada/news-view";
import { faDigits } from "@/lib/format";
import { GoalNotifier } from "@/components/remontada/goal-notifier";
import { FavoriteFixtures } from "@/components/remontada/favorite-fixtures";
import { SiteHeader } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { cn } from "@/lib/utils";

type Tab = "matches" | "standings" | "news";

const TABS: { key: Tab; label: string }[] = [
  { key: "matches", label: "نتایج زنده" },
  { key: "standings", label: "جدول لیگ‌ها" },
  { key: "news", label: "اخبار" },
];

export default function Home() {
  const [tab, setTab] = useState<Tab>("matches");

  // restore the last visited tab (after hydration to avoid mismatch)
  useEffect(() => {
    try {
      const saved = localStorage.getItem("remontada:home-tab");
      if (saved === "matches" || saved === "standings" || saved === "news") setTab(saved);
    } catch {
      // private mode / storage disabled — default tab stays
    }
  }, []);

  // switch tab + remember it for the next visit
  const changeTab = useCallback((t: Tab) => {
    setTab(t);
    try {
      localStorage.setItem("remontada:home-tab", t);
    } catch {
      // ignore persistence failures
    }
  }, []);

  // --- matches state ---
  const [offset, setOffset] = useState(0);
  const [groups, setGroups] = useState<LeagueGroup[]>([]);
  const [matchesLoading, setMatchesLoading] = useState(true);
  const [matchesError, setMatchesError] = useState<string | null>(null);
  const [lastFetch, setLastFetch] = useState<string | null>(null);
  const offsetRef = useRef(offset);
  offsetRef.current = offset;

  // --- standings state ---
  const [leagueKey, setLeagueKey] = useState("pl");
  const [standings, setStandings] = useState<StandingsData | null>(null);
  const [standingsLoading, setStandingsLoading] = useState(false);

  // --- news state ---
  const [news, setNews] = useState<ClientNewsItem[]>([]);
  const [newsLoading, setNewsLoading] = useState(true);

  const fetchMatches = useCallback(async (silent = false) => {
    if (!silent) setMatchesLoading(true);
    try {
      const res = await fetch(`/api/matches?offset=${offsetRef.current}`, { cache: "no-store" });
      const json = await res.json();
      if (json.ok) {
        setGroups(json.groups || []);
        setMatchesError(null);
        setLastFetch(new Date().toISOString());
      } else {
        setMatchesError(json.error || "خطا در دریافت نتایج");
      }
    } catch {
      setMatchesError("ارتباط برقرار نشد. دوباره تلاش کنید.");
    } finally {
      setMatchesLoading(false);
    }
  }, []);

  const fetchStandings = useCallback(async (key: string) => {
    setStandingsLoading(true);
    try {
      const res = await fetch(`/api/standings?league=${key}`, { cache: "no-store" });
      const json = await res.json();
      if (json.ok) setStandings(json as StandingsData);
    } catch {
      // keep old data
    } finally {
      setStandingsLoading(false);
    }
  }, []);

  const fetchNews = useCallback(async () => {
    setNewsLoading(true);
    try {
      const res = await fetch("/api/news", { cache: "no-store" });
      const json = await res.json();
      if (json.ok) setNews(json.items || []);
    } catch {
      // keep old
    } finally {
      setNewsLoading(false);
    }
  }, []);

  // initial + offset change
  useEffect(() => {
    fetchMatches();
  }, [offset, fetchMatches]);

  // initial standings & news (lazy per tab)
  useEffect(() => {
    if (tab === "standings" && !standings && !standingsLoading) fetchStandings(leagueKey);
    if (tab === "news" && newsLoading && news.length === 0) fetchNews();
  }, [tab]);

  useEffect(() => {
    if (tab === "standings") fetchStandings(leagueKey);
  }, [leagueKey]);

  // auto-refresh matches every 60s (only when visible)
  useEffect(() => {
    const iv = setInterval(() => {
      if (document.visibilityState === "visible") fetchMatches(true);
    }, 60_000);
    return () => clearInterval(iv);
  }, [fetchMatches]);

  const liveCount = groups.reduce(
    (acc, g) => acc + g.matches.filter((m) => m.live).length,
    0
  );

  // update cycle-38: reflect live matches in the browser tab title — users
  // keeping the home tab open in the background see at a glance when games
  // are in progress (e.g. «(۳ زنده) رمانتادا | …»), no state, no re-render
  useEffect(() => {
    const base = "رمانتادا | نتایج زنده فوتبال، جدول لیگ‌ها و اخبار";
    document.title = liveCount > 0 ? `(${faDigits(liveCount)} زنده) ${base}` : base;
    return () => {
      document.title = base;
    };
  }, [liveCount]);

  return (
    <div className="min-h-screen flex flex-col">
      {/* ---------- header (cycle-23: shared SiteHeader — single-source chrome) ---------- */}
      <SiteHeader>
        {(liveCount > 0 || tab === "matches") && (
          <div className="flex items-center justify-between gap-3 pt-2">
            <div className="flex items-center gap-2.5 min-w-0">
              {/* live matches counter — always visible when something is live */}
              {liveCount > 0 && (
                <button
                  onClick={() => changeTab("matches")}
                  title="نمایش بازی‌های زنده"
                  aria-label={`${faDigits(liveCount)} بازی زنده در جریان است`}
                  className="inline-flex items-center gap-1.5 text-[11px] font-black text-red-400 bg-red-500/10 border border-red-500/30 px-2.5 py-1.5 rounded-lg hover:bg-red-500/20 transition-colors cursor-pointer shrink-0"
                >
                  <span className="live-dot w-1.5 h-1.5 rounded-full bg-red-500 inline-block" />
                  <span className="tabular-persian">{faDigits(liveCount)}</span>
                  <span className="hidden xs:inline">زنده</span>
                </button>
              )}
            </div>
            <div className="flex items-center gap-2">
              {tab === "matches" && (
                <button
                  onClick={() => fetchMatches()}
                  className="flex items-center gap-1.5 text-xs font-semibold bg-card/80 border border-border px-3 py-1.5 rounded-lg hover:bg-accent transition-colors"
                  aria-label="بروزرسانی نتایج"
                >
                  <svg
                    width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                    strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
                    className={cn(matchesLoading && "animate-spin")} aria-hidden
                  >
                    <path d="M21 12a9 9 0 1 1-2.64-6.36" />
                    <path d="M21 3v6h-6" />
                  </svg>
                  بروزرسانی
                </button>
              )}
              {tab === "matches" && lastFetch && (
                <span className="hidden sm:block text-[10px] text-muted-foreground tabular-persian whitespace-nowrap">
                  آخرین بروزرسانی {tehranTime(lastFetch)}
                </span>
              )}
            </div>
          </div>
        )}

        {/* tabs */}
        <nav className="flex items-center gap-1 -mb-px overflow-x-auto" aria-label="بخش‌های صفحه اصلی">
          {TABS.map((t) => (
            <button
              key={t.key}
              onClick={() => changeTab(t.key)}
              aria-current={tab === t.key ? "page" : undefined}
              className={cn(
                "relative px-4 py-2.5 text-sm font-bold whitespace-nowrap transition-colors rounded-t-lg",
                tab === t.key
                  ? "text-primary"
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              {t.label}
              {t.key === "matches" && liveCount > 0 && (
                <span className="ms-1.5 inline-block align-top text-[10px] bg-red-500/15 text-red-400 border border-red-500/30 rounded-full px-1.5 tabular-persian">
                  {/* ui-cycle-16: render the live count with Persian digits —
                      .tabular-persian only sets font-variant-numeric, it does
                      not map 0-9 to ۰-۹; the badge was the one Latin-digit
                      leak on the site (its own aria-label already said ۵) */}
                  {faDigits(liveCount)}
                </span>
              )}
              {tab === t.key && (
                /* cycle-212: the codex flourish as the active-tab marker —
                   a hairline that fades at its ends, broken by a small gold
                   diamond (visual only, no text/testid change) */
                <span className="codex-tab-underline absolute inset-x-3 bottom-0 h-px" aria-hidden />
              )}
            </button>
          ))}
        </nav>
      </SiteHeader>

      {/* ---------- content ---------- */}
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        {/* h1 lives in the content since the shared header renders a <p> logo */}
        <h1 className="sr-only">رمانتادا — نتایج زنده فوتبال، جدول لیگ‌ها و اخبار</h1>
        {tab === "matches" && (
          <>
            {matchesError && (
              <div className="mb-4 rounded-xl border border-destructive/30 bg-destructive/10 text-destructive text-sm px-4 py-3 flex items-center justify-between gap-3">
                <span>{matchesError}</span>
                <button onClick={() => fetchMatches()} className="text-xs font-bold underline underline-offset-4">
                  تلاش مجدد
                </button>
              </div>
            )}
            {/* upcoming fixtures of favorited teams (cycle-20, renders nothing without favorites) */}
            <FavoriteFixtures />
            <MatchesView
              groups={groups}
              loading={matchesLoading}
              offset={offset}
              onOffsetChange={setOffset}
            />
          </>
        )}

        {tab === "standings" && (
          <StandingsView
            data={standings}
            loading={standingsLoading}
            leagueKey={leagueKey}
            onLeagueChange={setLeagueKey}
            onRetry={() => fetchStandings(leagueKey)}
          />
        )}

        {tab === "news" && <NewsView items={news} loading={newsLoading} />}
      </main>

      {/* goal notifications for favorite teams (opt-in chip) */}
      <GoalNotifier />

      {/* fix cycle-37: home is the portal's longest page (~17.7k px on mobile) — it was the
          only long view without the floating back-to-top after the cycle-35 rollout */}
      <BackToTop />

      {/* ---------- footer ---------- */}
      <footer className="glass-bar-footer mt-auto">
        <div className="max-w-5xl mx-auto px-4 py-6 flex flex-col items-center gap-2 text-center">
          {/* ui-cycle-13: same completed metadata as the shared SiteFooter —
              missing «بازیکنان», outbound source links, copyright line. */}
          <div className="flex items-center gap-3 text-[11px] font-bold text-muted-foreground flex-wrap justify-center">
            <Link href="/" className="hover:text-primary transition-colors">نتایج زنده</Link>
            <span aria-hidden>·</span>
            <Link href="/leagues" className="hover:text-primary transition-colors">لیگ‌ها</Link>
            <span aria-hidden>·</span>
            <Link href="/topscorers" className="hover:text-primary transition-colors">گلزنان</Link>
            <span aria-hidden>·</span>
            <Link href="/players" className="hover:text-primary transition-colors">بازیکنان</Link>
            <span aria-hidden>·</span>
            <Link href="/news" className="hover:text-primary transition-colors">اخبار</Link>
          </div>
          <p className="text-xs text-muted-foreground">
            داده‌های نتایج و جدول‌ها از{" "}
            <a href="https://www.fotmob.com/" target="_blank" rel="noopener noreferrer" className="font-bold text-foreground/80 hover:text-primary transition-colors">FotMob</a>
            {" و "}
            <a href="https://www.espn.com/" target="_blank" rel="noopener noreferrer" className="font-bold text-foreground/80 hover:text-primary transition-colors">ESPN</a>
            {" — اخبار از ESPN، BBC Sport و Sky Sports"}
          </p>
          <p className="text-[11px] text-muted-foreground/80">
            رمانتادا — ساخته‌شده با عشق به فوتبال. نتایج با تأخیر چندثانیه‌ای نمایش داده می‌شوند.
          </p>
          <p className="text-[10px] text-muted-foreground/70">© ۲۰۲۶ رمانتادا · تمامی حقوق محفوظ است.</p>
        </div>
      </footer>
    </div>
  );
}
