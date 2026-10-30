"use client";

// ------------------------------------------------------------------
// Remontada — per-league top scorers view (/topscorers/[leagueKey])
// Full ranked list of one league with rich badges (assists / G+A / xG
// / rating / minutes-per-goal). Phase 3 theme: glass scoring-chart
// poster — leader hero tile + pill-ranked rows (studio look).
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { ScorerEntry, AssistEntry, LeagueCardEntry, RatingEntry, CleanSheetEntry, GPlusAEntry, GoalsPreventedEntry, MinutesEntry } from "@/lib/fotmob";
import { EmptyState } from "@/components/remontada/empty-state";
import { LEAGUES } from "@/lib/leagues";
import { GlassLeagueHeader, pad2 } from "@/components/remontada/glass-stats";
import { PlayerPhoto } from "@/components/remontada/player-photo";
import { faDigits, timeAgoFa } from "@/lib/format";
import { SEASON_PARAM_RE } from "@/lib/season";
import { cn } from "@/lib/utils";

interface LeagueScorersData {
  ok: boolean;
  leagueKey: string;
  leagueFa: string;
  season: string;
  scorers: ScorerEntry[];
  // cycle-174 additive: the assists block rides the same payload — the
  // per-league page renders it like the league page (honest absence = []).
  assists?: AssistEntry[];
  // cycle-210 additive: «آقای امتیاز» rides the same payload — the deep-file
  // family's next sibling rendered between assists and cards; decimal value
  // pill (dir=ltr), honest absence = [].
  ratings?: RatingEntry[];
  // cycle-215 additive: «گل نخرده‌ها» rides the same payload — the deep-file
  // family's next sibling rendered between ratings and cards; integer value
  // pill, honest absence = []. The portal's first goalkeeper surface.
  cleanSheets?: CleanSheetEntry[];
  // cycle-216 additive: «گل+پاس» rides the same payload — the deep-file
  // family's sixth sibling rendered between assists and ratings; the
  // upstream's OWN combined order (integer pill), honest absence = [].
  gPlusA?: GPlusAEntry[];
  // cycle-217 additive: «گل‌های پیشگیری‌شده» rides the same payload — the
  // deep-file family's SEVENTH sibling and the FIRST SIGNED one, rendered
  // right after گل نخرده‌ها (the two keeper surfaces adjacent); SIGNED
  // DECIMAL pill (dir=ltr, the rating convention), honest absence = []
  // (persiangulf has no such category — probed).
  goalsPrevented?: GoalsPreventedEntry[];
  // cycle-220 additive: «بیشترین دقایق» rides the same payload — the
  // deep-file family's EIGHTH sibling and the first PRESENCE surface,
  // rendered between امتیازها and گل نخرده‌ها (the two keeper surfaces stay
  // adjacent — the 217 contract); integer Persian pill WITHOUT dir=ltr
  // (the 170/215/216 integer convention), honest absence = [] (feeds
  // without the "Minutes played" category hide the section).
  minutes?: MinutesEntry[];
  // cycle-179 additive: the cycle-176 cards block rides the same payload —
  // sister-page consistency (the 174 pattern one surface over).
  cards?: { yellow: LeagueCardEntry[]; red: LeagueCardEntry[] };
  // cycle-180 additive: the cycle-55 season fields — the honest marker of
  // what the payload actually shows + the selector's option list.
  selectedSeason?: string;
  allSeasons?: string[];
  updatedAt: string;
}

/** cycle-180: "2024/2025" → «۲۰۲۴/۲۵» — same rule as league-view's
 * cycle-55 helper (kept local: importing from league-view would drag its
 * whole module graph into this page's bundle). */
function faSeasonShort(s: string): string {
  const m = /^(\d{4})\/(\d{4})$/.exec(s);
  return m ? faDigits(`${m[1]}/${m[2].slice(2)}`) : faDigits(s);
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
  // cycle-180: selected historical season ("2024/2025") — null = current.
  // Same shape as the league page's cycle-55/99 selector: deep-link seeded,
  // URL-synced on change, honesty-snapped when the payload's own marker
  // disagrees with the request (upstream serves the current season for a
  // well-formed season it does not offer — the marker tells the truth).
  const [season, setSeason] = useState<string | null>(null);
  const [seeded, setSeeded] = useState(false);

  // cycle-180: read the deep-linked season once on mount — strict
  // SEASON_PARAM_RE shape (the same guard the API route applies); anything
  // else is ignored and the current season loads. Gated on `seeded` so a
  // deep link performs exactly ONE fetch with the right season.
  useEffect(() => {
    if (seeded) return;
    setSeeded(true);
    try {
      const raw = new URLSearchParams(window.location.search).get("season");
      if (raw && SEASON_PARAM_RE.test(raw)) setSeason(raw);
    } catch { /* no window — ignore */ }
  }, [seeded]);

  useEffect(() => {
    if (!seeded) return; // cycle-180: wait for the URL seed pass
    let cancelled = false;
    (async () => {
      try {
        const sp = season ? `?season=${encodeURIComponent(season)}` : "";
        const res = await fetch(`/api/topscorers/${leagueKey}${sp}`, { cache: "no-store" });
        const json = await res.json();
        if (cancelled) return;
        if (json.ok) {
          // cycle-99 honesty snap, scorers-page edition: when the payload's
          // own marker disagrees with the requested season, upstream served
          // the current season — snap the selector back and strip the stale
          // URL param so selector, label and URL never contradict the data
          // on screen. One extra fetch only in this bogus-param case.
          if (season && json.selectedSeason && json.selectedSeason !== season) {
            setSeason(null);
            try {
              const usp = new URLSearchParams(window.location.search);
              usp.delete("season");
              const qs = usp.toString();
              window.history.replaceState(null, "", `${window.location.pathname}${qs ? `?${qs}` : ""}`);
            } catch { /* ignore */ }
          }
          setData(json as LeagueScorersData);
        } else setError(json.error || "دریافت داده گلزنان ناموفق بود.");
      } catch {
        if (!cancelled) setError("ارتباط برقرار نشد.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [leagueKey, seeded, season]);

  const lgCfg = LEAGUES.find((l) => l.key === leagueKey);

  // cycle-180: selector options from the payload itself (the cycle-55 rule);
  // a deep-linked season upstream really serves but that sits outside the
  // 12-season cap is appended so the selector never contradicts the screen.
  const allSeasons = data?.allSeasons || [];
  const seasonOptions =
    season && data?.selectedSeason === season && !allSeasons.includes(season)
      ? [...allSeasons, season]
      : allSeasons;
  // cycle-99 URL-sync rule, scorers-page edition: replaceState (no history
  // entries) so a copied link carries the exact season being viewed.
  const applySeason = (s: string | null) => {
    setSeason(s);
    try {
      const usp = new URLSearchParams(window.location.search);
      if (s) usp.set("season", s);
      else usp.delete("season");
      const qs = usp.toString();
      window.history.replaceState(null, "", `${window.location.pathname}${qs ? `?${qs}` : ""}`);
    } catch { /* ignore */ }
  };
  // the payload's own honest label — data.season is "" on current-season
  // payloads, selectedSeason always tells the truth (the cycle-55 marker).
  const shownSeason = data?.selectedSeason || data?.season || "";

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
                ? <>بهترین گلزن‌های فصل{shownSeason ? <> — فصل {faDigits(shownSeason)}</> : null} — {faDigits(data.scorers.length)} بازیکن{/* cycle-43: data freshness */}{data.updatedAt ? <> · به‌روزرسانی {timeAgoFa(data.updatedAt)}</> : null}</>
                : shownSeason
                  ? <>گلزنی برای فصل {faDigits(shownSeason)} ثبت نشده است.</>
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

      {/* cycle-180: season selector — the league page has had it since
          cycle-55; the per-league topscorers page was the only league-scoped
          surface still stuck on the current season. Options come from the
          payload itself, so leagues without a season list simply hide the
          control (the cycle-55 rule). URL stays in sync (replaceState) so a
          copied link carries the exact season being viewed. */}
      {seasonOptions.length > 1 && (
        <div className="flex items-center gap-2 px-1">
          <label htmlFor="season-select" className="text-[11px] font-bold text-muted-foreground flex items-center gap-1.5 shrink-0">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" aria-hidden>
              <rect x="3.5" y="4.5" width="17" height="16" rx="3" />
              <path d="M8 2.5v4M16 2.5v4M3.5 10.5h17" />
            </svg>
            فصل
          </label>
          <select
            id="season-select"
            value={season ?? seasonOptions[0]}
            onChange={(e) => {
              applySeason(e.target.value === allSeasons[0] ? null : e.target.value);
            }}
            className="text-[12px] font-bold text-foreground bg-white/[0.04] border border-[color:var(--glass-border-soft)] rounded-lg px-2 py-1.5 outline-none focus:border-sky-soft/50 cursor-pointer"
          >
            {seasonOptions.map((s) => (
              <option key={s} value={s} className="bg-[#10161f] text-foreground">
                {faSeasonShort(s)}{s === allSeasons[0] ? " (فعلی)" : ""}
              </option>
            ))}
          </select>
          {loading && season != null && (
            <span className="text-[10px] text-muted-foreground animate-pulse">در حال بارگذاری…</span>
          )}
        </div>
      )}

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
                  <PlayerPhoto id={top.playerId} name={top.nameFa || top.name} size={60} />
                  <div className="min-w-0 flex-1">
                    <p className="text-[8px] font-bold tracking-[0.24em] text-[#9dbad8] uppercase">LEAGUE LEADER</p>
                    {top.playerId ? (
                      <Link
                        href={`/player/${top.playerId}`}
                        prefetch={false}
                        className="block text-lg sm:text-2xl font-bold text-[#f1f7fd] truncate mt-1 hover:text-primary transition-colors w-fit max-w-full"
                        title={top.nameFa && top.nameFa !== top.name ? top.name : `پروفایل ${top.name}`}
                      >
                        {top.nameFa || top.name}
                      </Link>
                    ) : (
                      <p className="text-lg sm:text-2xl font-bold text-[#f1f7fd] truncate mt-1">{top.nameFa || top.name}</p>
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
                      <span className="block text-[13px] font-bold text-[#e5eefb] truncate">{s.nameFa || s.name}</span>
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
                      <Link href={`/player/${s.playerId}`} prefetch={false} className={cls} title={s.nameFa && s.nameFa !== s.name ? s.name : `پروفایل ${s.name}`}>
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

      {/* cycle-174: بهترین پاس‌دهندگان — the per-league topscorers page joins its
          sister page: the SAME cached getStandings payload already carried the
          freshened assists block (the route just dropped it); compact card
          under the scorers poster, same 170 link contract (playerId → /player
          with prefetch=false, title = English original when Persian shown),
          honest absence when the feed has no assists (mas). */}
      {data && !loading && (data.assists || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" className="text-chart-2" aria-hidden>
              <path d="M4 19h16" />
              <path d="M5 15l5-5 4 3 5-7" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">بهترین پاس‌دهندگان</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">پاس گل فصل</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.assists || []).map((a, i) => {
              const rank = a.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{a.nameFa || a.name}</span>
                    {a.team && <span className="block text-[9.5px] text-[#92adc9] truncate">{a.team}</span>}
                  </span>
                  <span className="shrink-0 min-w-[36px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[14px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(a.assists)}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${a.name}-${i}`}>
                  {a.playerId ? (
                    <Link href={`/player/${a.playerId}`} prefetch={false} className={cls} title={a.nameFa && a.nameFa !== a.name ? a.name : `پروفایل ${a.name}`}>
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
      )}

      {/* cycle-216: گل+پاس — sister-page consistency (the 215 pattern one
          surface over): the SAME cached getStandings payload now carries the
          combined-participation block (the deep-file family's sixth
          sibling, stats/{id}/season/{sid}/_goals_and_goal_assist.json —
          the upstream's OWN combined ORDER, never recomputed from the
          scorers list; integer values — the goals/assists convention, so
          the value pill is plain Persian digits WITHOUT dir=ltr). Same
          170/215 link contract (playerId → /player with prefetch=false,
          title = English original when Persian shown), honest absence when
          the feed has no G+A category (→ the section simply hides). */}
      {data && !loading && (data.gPlusA || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="9" cy="9" r="5.2" />
              <path d="M15.5 8.5h6M18.5 5.5v6" />
              <path d="M4.5 20.5l6.5-6.5" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل+پاس</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">گل و پاسِ فصل</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.gPlusA || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                    {r.team && <span className="block text-[9.5px] text-[#92adc9] truncate">{r.team}</span>}
                  </span>
                  <span className="shrink-0 min-w-[36px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[14px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(r.gPlusA)}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="gpa-row">
                  {r.playerId ? (
                    <Link href={`/player/${r.playerId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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
      )}

      {/* cycle-210: برترین امتیازها — sister-page consistency (the 174/179
          pattern one surface over): the SAME cached getStandings payload now
          carries the ratings block (the deep-file family's next sibling,
          stats/{id}/season/{sid}/rating.json, decimal values verbatim — the
          ONLY non-integer family member, so the value pill is Persian digits
          with the decimal dot, dir=ltr). Same 170/176 link contract
          (playerId → /player with prefetch=false, title = English original
          when Persian shown), honest absence when the feed has no rating
          category (mas → the section simply hides). */}
      {data && !loading && (data.ratings || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <path d="M12 3l2.7 5.7 6.3.8-4.6 4.3 1.2 6.2-5.6-3.1-5.6 3.1 1.2-6.2L3 9.5l6.3-.8z" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">برترین امتیازها</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">ریتینگ فوت‌ماب فصل</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.ratings || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                    {r.team && <span className="block text-[9.5px] text-[#92adc9] truncate">{r.team}</span>}
                  </span>
                  <span dir="ltr" className="shrink-0 min-w-[46px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(r.rating.toFixed(2))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="rating-row">
                  {r.playerId ? (
                    <Link href={`/player/${r.playerId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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
      )}

      {/* cycle-220: بیشترین دقایق — sister-page consistency (the
          210/215/216/217 pattern one surface over): the SAME cached
          getStandings payload now carries the minutes-played block (the
          deep-file family's EIGHTH sibling and the first PRESENCE surface —
          not production, not keeping, just minutes on the pitch;
          stats/{id}/season/{sid}/mins_played.json — live-probed 2026-10-30:
          laliga 38843 = 482 rows, 2025/26 frozen anchor Sivera/Soria/Radu
          3420 = 38×90). Integer values rounded once at build (the 215/216
          convention, NOT the float one), so the value pill is Persian digits
          WITHOUT dir=ltr (the integer contract; 900 renders «۹۰۰»). The
          file's competition tie-ranks (1,1,1,4,4,4…) are honest upstream
          data but the served top-10 re-ranks POSITIONALLY like every
          sibling. Placed between امتیازها and گل نخرده‌ها so the two keeper
          surfaces stay adjacent (the 217 contract). Same 170/176 link
          contract (playerId → /player with prefetch=false, title = English
          original when Persian shown), honest absence when the feed has no
          "Minutes played" category → the section simply hides. */}
      {data && !loading && (data.minutes || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <path d="M12 7v5l3.5 2" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">بیشترین دقایق</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">حضور در میدان</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.minutes || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                    {r.team && <span className="block text-[9.5px] text-[#92adc9] truncate">{r.team}</span>}
                  </span>
                  <span className="shrink-0 min-w-[46px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(String(r.minutes))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="mp-row">
                  {r.playerId ? (
                    <Link href={`/player/${r.playerId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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
      )}

      {/* cycle-215: گل نخرده‌ها — sister-page consistency (the 210
          pattern one surface over): the SAME cached getStandings payload now
          carries the clean-sheets block (the deep-file family's next
          sibling, stats/{id}/season/{sid}/clean_sheet.json, integer values
          — the goals/assists convention, so the value pill is plain Persian
          digits WITHOUT dir=ltr). Same 170/210 link contract (playerId →
          /player with prefetch=false, title = English original when Persian
          shown), honest absence when the feed has no clean-sheet category
          (→ the section simply hides). The portal's first goalkeeper
          surface. */}
      {data && !loading && (data.cleanSheets || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <path d="M12 3l8 3.5v5c0 4.6-3.2 8.2-8 9.5-4.8-1.3-8-4.9-8-9.5v-5z" />
              <path d="M9 12l2 2 4-4" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل نخرده‌ها</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">دروازه‌بان‌های فصل</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.cleanSheets || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                    {r.team && <span className="block text-[9.5px] text-[#92adc9] truncate">{r.team}</span>}
                  </span>
                  <span className="shrink-0 min-w-[36px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[14px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(r.cleanSheets)}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="clean-sheet-row">
                  {r.playerId ? (
                    <Link href={`/player/${r.playerId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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
      )}

      {/* cycle-217: گل‌های پیشگیری‌شده — sister-page consistency (the
          215/216 pattern one surface over): the SAME cached getStandings
          payload now carries the goals-prevented block (the deep-file
          family's SEVENTH sibling and the keeper QUALITY surface — the 215
          clean-sheet block is the keeper's COUNT, this is the keeper's
          WORTH, stats/{id}/season/{sid}/_goals_prevented.json). SIGNED
          DECIMAL values kept verbatim — the family's FIRST negative-capable
          leaderboard (live-probed laliga 38843: David Soria −2.4 at rank
          21) — so the value pill is Persian digits with the decimal dot AND
          the minus sign, dir=ltr (the rating convention, NOT the integer
          one; display toFixed(1) matches the upstream's own precision,
          storage never rounds). Same 170/176 link contract (playerId →
          /player with prefetch=false, title = English original when Persian
          shown), honest absence when the feed has no "Goals prevented"
          category (persiangulf, probed → the section simply hides). */}
      {data && !loading && (data.goalsPrevented || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <path d="M12 3l8 3.5v5c0 4.6-3.2 8.2-8 9.5-4.8-1.3-8-4.9-8-9.5v-5z" />
              <path d="M9 12h6" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل‌های پیشگیری‌شده</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">xG منهای گل خورده</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.goalsPrevented || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                    {r.team && <span className="block text-[9.5px] text-[#92adc9] truncate">{r.team}</span>}
                  </span>
                  <span dir="ltr" className="shrink-0 min-w-[46px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(r.goalsPrevented.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="gp-row">
                  {r.playerId ? (
                    <Link href={`/player/${r.playerId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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
      )}

      {/* cycle-179: کارت‌ها — sister-page consistency (the 174 pattern one
          surface over): the SAME cached getStandings payload has carried the
          cycle-176 cards block since the v8 bump; the route dropped it exactly
          like it dropped assists before 174. Two compact columns (زرد/قرمز,
          top 5 each), same 170/176 link contract (playerId → /player with
          prefetch=false, title = English original when Persian shown, id>0
          guard — the 167 lesson), per-kind honest absence (mas = red-only,
          old seasons hide the whole card with the payload's own omission). */}
      {data && !loading && data.cards && ((data.cards.yellow || []).length > 0 || (data.cards.red || []).length > 0) && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <span className="flex gap-1" aria-hidden>
              <span className="w-1.5 h-2.5 rounded-[2px] bg-[#f2c94c]" />
              <span className="w-1.5 h-2.5 rounded-[2px] bg-[#eb5757]" />
            </span>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">کارت‌ها</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">زرد / قرمز فصل</span>
          </div>
          <div className="grid grid-cols-2 gap-2 px-2 pb-2.5">
            {(["yellow", "red"] as const).map((kind) => {
              const rows = (data.cards?.[kind] || []).slice(0, 5);
              if (rows.length === 0) return null;
              const dot = kind === "yellow" ? "bg-[#f2c94c]" : "bg-[#eb5757]";
              const label = kind === "yellow" ? "کارت زرد" : "کارت قرمز";
              return (
                <div key={kind} className="min-w-0">
                  <div className="flex items-center gap-1 px-0.5 pb-1">
                    <span className={`w-1.5 h-2.5 rounded-[2px] ${dot}`} aria-hidden />
                    <span className="text-[9.5px] font-bold text-[#92adc9]">{label}</span>
                  </div>
                  <ol className="flex flex-col">
                    {rows.map((c, i) => {
                      const inner = (
                        <>
                          <span className="w-5 h-5 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[9.5px] font-bold shrink-0 tabular-persian">
                            {faDigits(i + 1)}
                          </span>
                          <span className="min-w-0 flex-1 text-[11px] font-bold text-[#e5eefb] truncate">{c.nameFa || c.name}</span>
                          <span className="shrink-0 min-w-[26px] text-center rounded-md bg-[#a9cdf611] px-1.5 py-0.5 text-[11.5px] font-semibold text-[#e0efff] tabular-persian">
                            {faDigits(c.value)}
                          </span>
                        </>
                      );
                      const cls = "flex items-center gap-1.5 px-1.5 py-1.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
                      return (
                        <li key={`${c.name}-${i}`}>
                          {c.playerId && c.playerId > 0 ? (
                            <Link href={`/player/${c.playerId}`} prefetch={false} className={cls} title={c.nameFa && c.nameFa !== c.name ? c.name : `پروفایل ${c.name}`}>
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
              );
            })}
          </div>
        </div>
      )}

      {data && !loading && (
        <p className="text-[10px] text-muted-foreground px-1">
          رتبه‌ها مخصوص همین لیگ است. بج‌ها: پاس گل، مجموع گل+پاس، ریتینگ فوت‌ماب، xG و میانگین دقایق هر گل. منبع داده: فوت‌ماب.
        </p>
      )}
    </div>
  );
}
