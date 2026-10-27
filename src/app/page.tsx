"use client";

import Link from "next/link";
import { useCallback, useEffect, useRef, useState } from "react";
import type { LeagueGroup, StandingsData } from "@/lib/fotmob";
import { MatchesView, tehranTime } from "@/components/remontada/matches-view";
import { StandingsView } from "@/components/remontada/standings-view";
import { NewsView, type ClientNewsItem } from "@/components/remontada/news-view";
import { faDigits } from "@/lib/format";
import { SearchBox } from "@/components/remontada/search-box";
import { GoalNotifier } from "@/components/remontada/goal-notifier";
import { FavoriteFixtures } from "@/components/remontada/favorite-fixtures";
import { cn } from "@/lib/utils";

type Tab = "matches" | "standings" | "news";

const TABS: { key: Tab; label: string }[] = [
  { key: "matches", label: "نتایج زنده" },
  { key: "standings", label: "جدول لیگ‌ها" },
  { key: "news", label: "اخبار" },
];

function Logo() {
  return (
    <div className="flex items-center gap-2.5">
      <div className="relative w-10 h-10 rounded-xl bg-primary/15 border border-primary/30 flex items-center justify-center overflow-hidden pitch-lines">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="text-primary" aria-hidden>
          <circle cx="12" cy="12" r="10" />
          <path d="M12 7l4.5 3.2-1.7 5.3H9.2L7.5 10.2 12 7z" />
        </svg>
      </div>
      <div className="leading-tight">
        <h1 className="text-lg sm:text-xl font-black tracking-tight">
          رمانتادا
          <span className="text-primary">.</span>
        </h1>
        <p className="text-[10px] text-muted-foreground font-medium">فوتبال، بی‌وقفه و زنده</p>
      </div>
    </div>
  );
}

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

  return (
    <div className="min-h-screen flex flex-col">
      {/* ---------- header ---------- */}
      <header className="sticky top-0 z-40 backdrop-blur-xl bg-background/75 border-b border-border/50">
        <div className="max-w-5xl mx-auto px-3 sm:px-5">
          <div className="flex items-center justify-between gap-3 py-3">
            <div className="flex items-center gap-2.5 min-w-0">
              <Logo />
              {/* live matches counter — always visible next to the logo */}
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
              <SearchBox />
              <Link
                href="/leagues"
                className="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-muted-foreground hover:text-primary border border-border/60 rounded-lg px-2.5 py-1.5 transition-colors"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                  <path d="M8 21h8M12 17v4" />
                  <path d="M7 4h10v5a5 5 0 0 1-10 0V4z" />
                  <path d="M17 5h3a2 2 0 0 1-2 4h-1M7 5H4a2 2 0 0 0 2 4h1" />
                </svg>
                لیگ‌ها
              </Link>
              <Link
                href="/news"
                className="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-muted-foreground hover:text-primary border border-border/60 rounded-lg px-2.5 py-1.5 transition-colors"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
                  <path d="M4 5h16M4 10h16M4 15h10M4 20h7" />
                </svg>
                صفحه کامل اخبار
              </Link>
              {tab === "matches" && (
                <div className="flex items-center gap-2">
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
                </div>
              )}
              {tab === "matches" && lastFetch && (
                <span className="hidden sm:block text-[10px] text-muted-foreground tabular-persian whitespace-nowrap">
                  آخرین بروزرسانی {tehranTime(lastFetch)}
                </span>
              )}
            </div>
          </div>

          {/* tabs */}
          <nav className="flex items-center gap-1 -mb-px overflow-x-auto" aria-label="بخش‌های سایت">
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
                    {liveCount}
                  </span>
                )}
                {tab === t.key && (
                  <span className="absolute inset-x-3 bottom-0 h-0.5 bg-primary rounded-full" aria-hidden />
                )}
              </button>
            ))}
          </nav>
        </div>
      </header>

      {/* ---------- content ---------- */}
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
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
          />
        )}

        {tab === "news" && <NewsView items={news} loading={newsLoading} />}
      </main>

      {/* goal notifications for favorite teams (opt-in chip) */}
      <GoalNotifier />

      {/* ---------- footer ---------- */}
      <footer className="mt-auto border-t border-border/50 bg-background/60">
        <div className="max-w-5xl mx-auto px-4 py-6 flex flex-col items-center gap-2 text-center">
          <div className="flex items-center gap-3 text-[11px] font-bold text-muted-foreground">
            <Link href="/" className="hover:text-primary transition-colors">نتایج زنده</Link>
            <span aria-hidden>·</span>
            <Link href="/leagues" className="hover:text-primary transition-colors">لیگ‌ها</Link>
            <span aria-hidden>·</span>
            <Link href="/topscorers" className="hover:text-primary transition-colors">گلزنان</Link>
            <span aria-hidden>·</span>
            <Link href="/news" className="hover:text-primary transition-colors">اخبار</Link>
          </div>
          <p className="text-xs text-muted-foreground">
            داده‌های نتایج و جدول‌ها از <span className="font-bold text-foreground/80">FotMob</span> و
            <span className="font-bold text-foreground/80"> ESPN</span> — اخبار از ESPN، BBC Sport و Sky Sports
          </p>
          <p className="text-[11px] text-muted-foreground/70">
            رمانتادا — ساخته‌شده با عشق به فوتبال. نتایج با تأخیر چندثانیه‌ای نمایش داده می‌شوند.
          </p>
        </div>
      </footer>
    </div>
  );
}
