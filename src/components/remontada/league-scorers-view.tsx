"use client";

// ------------------------------------------------------------------
// Remontada — per-league top scorers view (/topscorers/[leagueKey])
// Full ranked list of one league with rich badges (assists / G+A / xG
// / rating / minutes-per-goal). Phase 3 theme: glass scoring-chart
// poster — leader hero tile + pill-ranked rows (studio look).
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { ScorerEntry, AssistEntry, LeagueCardEntry, RatingEntry, CleanSheetEntry, GPlusAEntry, GoalsPreventedEntry, MinutesEntry, SavePercentageEntry, SavesPer90Entry, PenaltySavesEntry, XgEntry, GoalsPer90Entry, XaEntry, BigChancesCreatedEntry, XgotEntry, ChancesCreatedEntry, BigChancesMissedEntry, TeamXgEntry, TeamCleanSheetEntry, TeamPossessionEntry } from "@/lib/fotmob";
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
  // cycle-221 additive: «درصد سیو» rides the same payload — the deep-file
  // family's NINTH sibling and the THIRD keeper surface, rendered between
  // بیشترین دقایق and گل نخرده‌ها (the three keeper surfaces stay
  // adjacent — the 217 contract extended); percent decimal pill WITH
  // dir=ltr (the 210/217 decimal convention), honest absence = [] (feeds
  // without the "Save percentage" category — persiangulf, probed — hide
  // the section).
  savePercentage?: SavePercentageEntry[];
  // cycle-222 additive: «سیو در هر ۹۰» rides the same payload — the deep-
  // file family's TENTH sibling and the FOURTH keeper surface, rendered
  // right after درصد سیو so the FOUR keeper surfaces stay adjacent (the
  // 217 contract extended again); per-90 decimal pill WITH dir=ltr (the
  // 210/217/221 decimal convention), honest absence = [] (feeds without
  // the "Saves per 90" category — persiangulf, probed — hide the section).
  savesPer90?: SavesPer90Entry[];
  // cycle-225 additive: «پنالتی‌های مهارشده» rides the same payload — the
  // deep-file family's ELEVENTH sibling and the FIFTH keeper surface,
  // rendered right after گل‌های پیشگیری‌شده so the keeper run stays one
  // adjacent block (the 217 contract extended to a QUINTET); integer
  // Persian pill WITHOUT dir=ltr (the 215/216 integer convention), honest
  // absence = [] (feeds without the "Penalty saves" category — persiangulf
  // — AND every historical season, probed, hide the section; the block is
  // CURRENT-SEASON ONLY, the 132 class).
  penaltySaves?: PenaltySavesEntry[];
  // cycle-226 additive: «گل مورد انتظار» rides the same payload — the deep-
  // file family's TWELFTH sibling and the first pure-ANALYTICS surface,
  // rendered between امتیازها and بیشترین دقایق (the production/analytics
  // run, keeper run untouched); decimal pill WITH dir=ltr rendered
  // toFixed(1) (upstream precision EXACTLY one decimal, probed — the
  // 210/217/221/222 decimal convention), honest absence = [] (feeds
  // without the "Expected goals (xG)" category — persiangulf, probed —
  // hide the section). SEASON-AWARE (the 124/175/185 class): historical
  // views serve their own files (2020/21 laliga = Messi 23.9, frozen).
  xg?: XgEntry[];
  // cycle-227 additive: «گل در هر ۹۰» rides the same payload — the deep-
  // file family's THIRTEENTH sibling and the production-RATE surface,
  // rendered right after گل مورد انتظار so the two rate surfaces pair
  // (expected vs actual, per-90; keeper QUINTET untouched); decimal pill
  // WITH dir=ltr rendered toFixed(2) (upstream precision UP TO two
  // decimals, probed max 2 on every serving league — the 210/217/226
  // decimal convention), honest absence = [] (feeds without the "Goals
  // per 90" category — mas, probed — hide the section). SEASON-AWARE (the
  // 124/175/185/226 class): historical views serve their own files (2020/21
  // laliga = Messi 0.89, frozen). PERSIANGULF SERVES — 93 rows, the first
  // deep sibling besides minutes to reach the Persian Gulf.
  goalsPer90?: GoalsPer90Entry[];
  // cycle-230 additive: «پاس مورد انتظار» rides the same payload — the deep-
  // file family's FOURTEENTH sibling and the assist-side ANALYTICS twin of
  // the xg surface, rendered right after گل در هر ۹۰ so the analytics run
  // grows by one and the 226/227 expected-vs-actual pairing + the keeper
  // QUINTET stay untouched; decimal pill WITH dir=ltr rendered toFixed(1)
  // (upstream precision EXACTLY one decimal, probed — the 210/217/226
  // decimal convention), honest absence = [] (feeds without the "Expected
  // assist (xA)" category — persiangulf AND mas, probed — hide the
  // section). SEASON-AWARE (the 124/175/185/226/227 class): historical
  // views serve their own files (2020/21 laliga = Messi 13.4, frozen).
  xa?: XaEntry[];
  // cycle-231 additive: «سانس بزرگ خلق‌شده» rides the same payload — the deep-
  // file family's FIFTEENTH sibling and the production-CREATION volume
  // surface beside the analytics twins, rendered right after پاس مورد
  // انتظار so the creation trio (xG quality → xA quality → BCC volume)
  // stays together and the keeper QUINTET stays untouched; INTEGER pill
  // WITHOUT dir=ltr (the 215/220 integer convention — upstream values are
  // integer-valued floats, probed nonint=0), honest absence = [] (feeds
  // without the "Big chances created" category — persiangulf AND mas,
  // probed — hide the section). SEASON-AWARE (the
  // 124/175/185/226/227/230 class): historical views serve their own
  // files (2020/21 laliga = Messi 22.0, frozen).
  bigChancesCreated?: BigChancesCreatedEntry[];
  // cycle-232 additive: «گل مورد انتظار روی دروازه» rides the same payload —
  // the deep-file family's SIXTEENTH sibling and the third ANALYTICS
  // level, the on-target accuracy twin of the xg surface, rendered right
  // after گل مورد انتظار so the quality→accuracy pair reads together and
  // the rest of the analytics run (گل در هر ۹۰ → پاس مورد انتظار → سانس
  // بزرگ خلق‌شده) plus the keeper QUINTET stay untouched; decimal pill
  // WITH dir=ltr rendered toFixed(1) (upstream precision EXACTLY one
  // decimal, probed — the 210/217/226/230 decimal convention), honest
  // absence = [] (feeds without the "Expected goals on target (xGOT)"
  // category — persiangulf AND mas, probed — hide the section).
  // SEASON-AWARE (the 124/175/185/226/227/230/231 class): historical
  // views serve their own files (2020/21 laliga = Messi 32.8, frozen).
  xgot?: XgotEntry[];
  // cycle-235 additive: «فرصت‌های خلق‌شده» rides the same payload — the
  // deep-file family's SEVENTEENTH sibling and the TOTAL-creation VOLUME
  // twin of the BCC surface, rendered right after سانس بزرگ خلق‌شده so
  // the subset→total pair reads together (the xG→xGOT quality→accuracy
  // mirror one run over) and the keeper QUINTET stays untouched; integer
  // pill WITHOUT dir=ltr (upstream integer-valued, probed nonint=0 — the
  // 215/216/220 convention), honest absence = [] (feeds without the
  // "Chances created" category — persiangulf AND mas, probed — hide the
  // section). SEASON-AWARE (the 124/175/185/226/227/230/231/232 class):
  // historical views serve their own files (2020/21 laliga = Messi 77,
  // frozen).
  chancesCreated?: ChancesCreatedEntry[];
  // cycle-236 additive: «سانس بزرگ ازدست‌رفته» rides the same payload — the
  // deep-file family's EIGHTEENTH sibling and the MISSED-volume twin of
  // the BCC surface, rendered right after فرصت‌های خلق‌شده so the
  // creation-volume run (خلق‌شده → کل → ازدست‌رفته) reads together and
  // the keeper QUINTET stays untouched; integer pill WITHOUT dir=ltr
  // (upstream integer-valued, probed nonint=0 — the 215/216/220
  // convention), honest absence = [] (feeds without the "Big chances
  // missed" category — persiangulf AND mas, probed — hide the section).
  // SEASON-AWARE (the 124/175/185/226/227/230/231/232/235 class):
  // historical views serve their own files (2020/21 laliga = Benzema 19,
  // frozen).
  bigChancesMissed?: BigChancesMissedEntry[];
  // cycle-237 additive: «گل مورد انتظار تیم‌ها» rides the same payload — the
  // deep-file family's NINETEENTH sibling and its FIRST TEAM-PARTICIPANT
  // member: the team-side LEVEL of the xg surface (the 196 boards only
  // ever showed this category as a ≤3-row podium — the full top-10 file
  // level is new), rendered right after گل مورد انتظار so the player→team
  // pair reads together and the rest of the analytics run + the keeper
  // QUINTET stay untouched; decimal pill WITH dir=ltr rendered toFixed(1)
  // (upstream precision EXACTLY one decimal, probed — the
  // 210/217/226/230/232 decimal convention), honest absence = [] (feeds
  // without the "Expected goals" TEAM category — persiangulf AND mas,
  // probed — hide the section). NO badge twin BY DESIGN (badges key on
  // PLAYER ids). Rows link /team/[id] (the standings-view contract).
  // SEASON-AWARE (the 124/…/236 class): historical views serve their own
  // files (2020/21 laliga = Barcelona 74.3, frozen).
  teamXg?: TeamXgEntry[];
  // cycle-240 additive: «گل نخرده‌های تیم‌ها» rides the same payload — the
  // deep-file family's TWENTIETH sibling and its SECOND TEAM-PARTICIPANT
  // member: the team-side LEVEL of the keeper clean-sheets surface (215 —
  // the team twin relationship 237 established), rendered right after
  // گل مورد انتظار تیم‌ها so the two team-side blocks read together while
  // the player→team pair and the keeper QUINTET stay untouched; INTEGER
  // pill WITH dir=ltr rendered via String() (upstream integer-valued
  // floats, probed — the 215/220/231/235/236 integer convention), honest
  // absence = [] (feeds without the "Clean sheets" TEAM category —
  // persiangulf, probed — hide the section; mas serves a naturally-thin
  // 8-row file, probed). NO badge twin BY DESIGN (badges key on PLAYER
  // ids). Rows link /team/[id] (the standings-view contract).
  // SEASON-AWARE (the 124/…/236 class): historical views serve their own
  // files (2020/21 laliga = Atletico Madrid 18.0, frozen).
  teamCleanSheets?: TeamCleanSheetEntry[];
  // cycle-241 additive: «مالکیت توپ تیم‌ها» rides the same payload — the
  // deep-file family's TWENTY-FIRST sibling and its THIRD TEAM-PARTICIPANT
  // member: the team-side possession surface, rendered right after
  // گل نخرده‌های تیم‌ها so the THREE team-side blocks read together while
  // the player→team pair and the keeper QUINTET stay untouched; percent
  // pill WITH dir=ltr rendered toFixed(1) with NO appended sign (upstream
  // 1-fraction percent values, probed — the 221 percent convention),
  // honest absence = [] (feeds without the "Average possession" TEAM
  // category — persiangulf AND mas, the 237 absence pair, probed — hide
  // the section). NO badge twin BY DESIGN (badges key on PLAYER ids).
  // Rows link /team/[id] (the standings-view contract). SEASON-AWARE (the
  // 124/…/236 class): historical views serve their own files (2020/21
  // laliga = Barcelona 65.8, frozen).
  teamPossession?: TeamPossessionEntry[];
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
  // cycle-230 additive: the xA badge — the assist-side twin of the xG badge
  // (season-total from the "Expected assist (xA)" category, matched by
  // player id; one decimal, the 226 display convention)
  if (s.xa != null && s.xa > 0) {
    badges.push({ label: `xA ${faDigits(s.xa.toFixed(1))}`, cls: "bg-muted border-border text-muted-foreground", title: "پاس مورد انتظار" });
  }
  // cycle-231 additive: the big-chances badge — the creation-volume twin
  // (season-total from the "Big chances created" category, matched by
  // player id; integer, the 215 display convention)
  if (s.bigChances != null && s.bigChances > 0) {
    badges.push({ label: `${faDigits(s.bigChances)} سانس بزرگ`, cls: "bg-muted border-border text-muted-foreground", title: "سانس بزرگ خلق‌شده" });
  }
  // cycle-232 additive: the xGOT badge — the on-target accuracy twin of
  // the xG badge (season-total from the "Expected goals on target (xGOT)"
  // category, matched by player id; one decimal, the 226/230 display
  // convention)
  if (s.xgot != null && s.xgot > 0) {
    badges.push({ label: `xGOT ${faDigits(s.xgot.toFixed(1))}`, cls: "bg-muted border-border text-muted-foreground", title: "گل مورد انتظار روی دروازه" });
  }
  if (s.chancesCreated != null && s.chancesCreated > 0) {
    badges.push({ label: `${faDigits(s.chancesCreated)} فرصت‌سازی`, cls: "bg-muted border-border text-muted-foreground", title: "فرصت‌های خلق‌شده" });
  }
  if (s.bigChancesMissed != null && s.bigChancesMissed > 0) {
    badges.push({ label: `${faDigits(s.bigChancesMissed)} سانس ازدست‌رفته`, cls: "bg-muted border-border text-muted-foreground", title: "سانس بزرگ ازدست‌رفته" });
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

      {/* cycle-226: گل مورد انتظار — sister-page consistency (the
          210/215/216/217/220/221/222/225 pattern one surface over): the SAME
          cached getStandings payload now carries the xG block (the deep-file
          family's TWELFTH sibling and the first pure-ANALYTICS surface —
          stats/{id}/season/{sid}/expected_goals.json — live-probed
          2026-10-30: SIX of the seven leagues serve it with WIDE files
          (laliga 389 / ucl 479 rows), persiangulf honestly absent (no xG
          category). Decimal values kept VERBATIM — the family's FIFTH
          non-integer member (the 210/217/221/222 decimal convention — 12.2
          renders «۱۲.۲»); upstream precision is EXACTLY one decimal (probed:
          all 389 laliga rows) so the pill renders toFixed(1), dir=ltr — the
          217 display rule. SEASON-AWARE (the 124/175/185 class, NOT the 132
          one): historical views serve their OWN files (the 2020/21 laliga
          raw = 471 rows, Messi 23.9 — frozen, the 202 anchor pattern).
          Placed between امتیازها and بیشترین دقایق so the production/
          analytics run stays together and the keeper QUINTET stays adjacent
          (the 217 contract untouched). Same 170/176 link contract (playerId
          → /player with prefetch=false, title = English original when
          Persian shown), honest absence when the feed has no "Expected
          goals (xG)" category → the section simply hides. */}
      {data && !loading && (data.xg || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <circle cx="12" cy="12" r="4.5" />
              <circle cx="12" cy="12" r="0.8" fill="currentColor" stroke="none" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل مورد انتظار</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">کیفیت موقعیت‌ها</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.xg || []).map((r, i) => {
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
                    {faDigits(r.xg.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="xg-row">
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

      {/* cycle-237: گل مورد انتظار تیم‌ها — the deep-file family's
          NINETEENTH sibling and its FIRST TEAM-PARTICIPANT member: the
          team-side LEVEL of the xG surface (the 196 boards only ever
          showed this category as a ≤3-row podium — the full top-10 file
          level is new). stats/{id}/season/{sid}/expected_goals_team.json
          — live-probed 2026-10-30 (UA Chrome/124): ALL SIX domestic
          globalMerge leagues serve it (laliga 20 Barcelona 34.8 / pl 20
          Manchester City 16.7 / seriea 20 Inter 25.5 / bundesliga 18
          Bayern 23.8 / ligue1 18 PSG 20.0 / ucl 36 PSG 10.1 rows);
          persiangulf AND mas honestly absent (no "Expected goals" team
          category). Decimal 1-fraction (probed maxdec=1 on every serving
          file) → the 210/217/226/230/232 VERBATIM-decimal convention:
          the pill renders toFixed(1), dir=ltr (34.8 renders «۳۴.۸”).
          SEASON-AWARE: the 2020/21 laliga raw serves its OWN file
          (Barcelona 74.3 / Real Madrid 62.3 — frozen, the 202 anchor
          pattern). The honest-name contract rides the EXISTING teamFa
          map (the standings already curate these clubs) — zero new
          PLAYER_NAME_FA entries. Rows link /team/{teamId} (the
          standings-view contract). Placed right after گل مورد انتظار so
          the player→team pair reads together while the rest of the
          analytics run and the keeper QUINTET stay untouched — the
          older gates' relative-order asserts are inequality-based so the
          insertion provably keeps them green. Honest absence when the
          feed has no team-xG category → the section simply hides. */}
      {data && !loading && (data.teamXg || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <circle cx="12" cy="12" r="4.5" />
              <circle cx="12" cy="12" r="0.8" fill="currentColor" stroke="none" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل مورد انتظار تیم‌ها</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">کیفیت موقعیت‌ها — سطح تیم</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.teamXg || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                  </span>
                  <span dir="ltr" className="shrink-0 min-w-[46px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(r.teamXg.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="txg-row">
                  {r.teamId > 0 ? (
                    <Link href={`/team/${r.teamId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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

      {/* cycle-240: گل نخرده‌های تیم‌ها — the deep-file family's TWENTIETH
          sibling and its SECOND TEAM-PARTICIPANT member: the team-side
          LEVEL of the keeper clean-sheets surface (215), the team twin
          relationship 237 established for xG.
          stats/{id}/season/{sid}/clean_sheet_team.json — live-probed
          2026-10-30 (UA Chrome/124): ALL SIX domestic globalMerge leagues
          serve it (laliga 18 Athletic Club 6.0 / pl 18 Arsenal 5.0 /
          seriea 18 Roma 5.0 / bundesliga 16 Borussia Dortmund 5.0 /
          ligue1 14 Lorient 5.0 / ucl 17 Arsenal 2.0 rows; portugal 17
          with the THREE-WAY tie Arouca/Porto/Santa Clara 5,5,5 probed for
          breadth); persiangulf honestly absent (its feed carries ONE team
          category, goals_team_match) while mas serves a naturally-thin
          8-row file (Johor Darul Ta'zim 6.0 — the FIRST below-the-floor
          serve in the family, the 225 health-rule class). INTEGER-VALUED
          floats (StatFormat number, probed int on every serving file) →
          the 215/220/231/235/236 integer convention: the pill renders
          String(value) dir=ltr (6.0 renders «۶»). Upstream Rank keeps
          competition ties verbatim (laliga rank 2,2 Atlético+Celta) — the
          merge re-ranks POSITIONALLY. SEASON-AWARE: the 2020/21 laliga
          raw serves its OWN file (Atletico Madrid 18.0 / Real Madrid
          17.0 — frozen, the 202 anchor pattern). The honest-name contract
          rides the EXISTING teamFa map — zero new PLAYER_NAME_FA entries.
          Rows link /team/{teamId} (the standings-view contract). Placed
          right after گل مورد انتظار تیم‌ها so the two team-side blocks
          read together while the player→team pair and the keeper QUINTET
          stay untouched — the older gates' relative-order asserts are
          index-inequality-based so the insertion provably keeps them
          green. Honest absence when the feed has no "Clean sheets" team
          category → the section simply hides. */}
      {data && !loading && (data.teamCleanSheets || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <path d="M12 3l8 3.5v5c0 4.6-3.2 8.2-8 9.5-4.8-1.3-8-4.9-8-9.5v-5z" />
              <path d="M9 12l2 2 4-4" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل نخرده‌های تیم‌ها</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">دروازهٔ بسته — سطح تیم</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.teamCleanSheets || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                  </span>
                  <span dir="ltr" className="shrink-0 min-w-[46px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(String(r.teamCleanSheets))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="tcs-row">
                  {r.teamId > 0 ? (
                    <Link href={`/team/${r.teamId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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

      {/* cycle-241: مالکیت توپ تیم‌ها — the deep-file family's TWENTY-FIRST
          sibling and its THIRD TEAM-PARTICIPANT member: the team-side
          possession surface. stats/{id}/season/{sid}/
          possession_percentage_team.json — live-probed 2026-10-30 (UA
          Chrome/124): ALL SIX domestic globalMerge leagues serve it
          (laliga 20 Barcelona 69.4 / pl 20 Manchester City 64.2 / seriea
          20 Inter 63.0 / bundesliga 18 Bayern München 66.9 / ligue1 18
          Paris Saint-Germain 68.0 / ucl 36 Barcelona 65.2 rows; portugal
          18 Benfica 63.1 probed for breadth); persiangulf AND mas
          honestly absent (the 237 absence pair exactly — mas's feed
          carries FOUR team categories and possession is not one).
          PERCENT 1-fraction (probed maxdec=1, StatFormat percent) → the
          221 percent convention VERBATIM: the pill renders toFixed(1)
          dir=ltr (69.4 renders «۶۹.۴») with NO appended percent sign.
          SEASON-AWARE: the 2020/21 laliga raw serves its OWN file
          (Barcelona 65.8 / Sevilla 61.2 — frozen, the 202 anchor
          pattern). The honest-name contract rides the EXISTING teamFa
          map — zero new PLAYER_NAME_FA entries. Rows link /team/{teamId}
          (the standings-view contract). Placed right after گل نخرده‌های
          تیم‌ها so the THREE team-side blocks read together while the
          player→team pair and the keeper QUINTET stay untouched — the
          older gates' relative-order asserts are index-inequality-based
          so the insertion provably keeps them green. Honest absence when
          the feed has no "Average possession" team category → the section
          simply hides. */}
      {data && !loading && (data.teamPossession || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <path d="M12 12V3.5" />
              <path d="M12 12l6.5 5.8" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">مالکیت توپ تیم‌ها</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">کنترل توپ — سطح تیم</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.teamPossession || []).map((r, i) => {
              const rank = r.rank ?? i + 1;
              const inner = (
                <>
                  <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                    {faDigits(pad2(rank))}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{r.nameFa || r.name}</span>
                  </span>
                  <span dir="ltr" className="shrink-0 min-w-[46px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                    {faDigits(r.teamPossession.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="tposs-row">
                  {r.teamId > 0 ? (
                    <Link href={`/team/${r.teamId}`} prefetch={false} className={cls} title={r.nameFa && r.nameFa !== r.name ? r.name : `پروفایل ${r.name}`}>
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

      {/* cycle-232: گل مورد انتظار روی دروازه — sister-page consistency (the
          210/215/216/217/220/221/222/225/226/227/230/231 pattern one surface
          over): the SAME cached getStandings payload now carries the
          expected-goals-on-target block (the deep-file family's SIXTEENTH
          sibling and the third ANALYTICS level, the on-target accuracy twin
          of گل مورد انتظار — stats/{id}/season/{sid}/
          expected_goalsontarget.json — live-probed 2026-10-30: SIX of the
          seven globalMerge leagues serve it with WIDE files (ucl 305
          Tresoldi 4.5 / pl 241 Haaland 8.2 / laliga 277 Mbappé 12.8 /
          seriea 286 Malen 6.6 / bundesliga 227 Füllkrug 6.2 / ligue1 227
          Lepaul 6.0 rows), persiangulf AND mas honestly absent (no xGOT
          category — the Gulf's 5 player cats). Decimal values kept
          VERBATIM — the family's EIGHTH non-integer member (the
          210/217/221/222/226/227/230 decimal convention — 12.8 renders
          «۱۲.۸»); upstream precision is EXACTLY one decimal (probed
          decimal-counts=[1] on every serving file AND the historical raw)
          so the pill renders toFixed(1), dir=ltr — the 217 display rule.
          SEASON-AWARE (the 124/175/185/226/227/230/231 class): historical
          views serve their OWN files (the 2020/21 laliga raw = 385 rows,
          Messi 32.8 / Gerard Moreno 24.8 — frozen, the 202 anchor pattern;
          2023/24 pl = 402 rows, Haaland 27.1). Placed right after گل مورد
          انتظار so the quality→accuracy pair reads together (the xGOT
          refinement of xG) while the rest of the analytics run (گل در هر
          ۹۰ → پاس مورد انتظار → سانس بزرگ خلق‌شده) and the keeper QUINTET
          stay untouched (the 217 contract verbatim) — the relative orders
          the 230/231 gates assert are inequality-based, so the insertion
          provably keeps them green. Same 170/176 link contract (playerId →
          /player with prefetch=false, title = English original when
          Persian shown), honest absence when the feed has no "Expected
          goals on target (xGOT)" category → the section simply hides. */}
      {data && !loading && (data.xgot || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <rect x="3" y="7" width="18" height="10" rx="1" />
              <path d="M3 12h18" />
              <path d="M12 7v10" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل مورد انتظار روی دروازه</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">کیفیت شوت روی دروازه</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.xgot || []).map((r, i) => {
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
                    {faDigits(r.xgot.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="xgot-row">
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

      {/* cycle-227: گل در هر ۹۰ — sister-page consistency (the
          210/215/216/217/220/221/222/225/226 pattern one surface over): the
          SAME cached getStandings payload now carries the goals-per-90 block
          (the deep-file family's THIRTEENTH sibling and the production-RATE
          surface — stats/{id}/season/{sid}/goals_per_90.json — live-probed
          2026-10-30: 23 of the 24 leagues serve it with WIDE files (laliga
          139 rows Raphinha 1.77, championship 196), PERSIANGULF SERVES — 93
          rows, the first deep sibling besides minutes to reach the Persian
          Gulf; mas honestly absent (two player categories only). Decimal
          values kept VERBATIM — the family's SIXTH non-integer member (the
          210/217/221/222/226 decimal convention); upstream precision is UP
          TO two decimals (probed max 2 on every serving league) so the pill
          renders toFixed(2), dir=ltr — the 217 display rule. SEASON-AWARE
          (the 124/175/185/226 class, NOT the 132 one): historical views
          serve their OWN files (the 2020/21 laliga raw = 224 rows, Messi
          0.89 — frozen, the 202 anchor pattern). Placed right after گل مورد
          انتظار so the two rate surfaces pair (expected vs actual, per-90)
          and the keeper QUINTET stays adjacent (the 217 contract untouched).
          Same 170/176 link contract (playerId → /player with prefetch=false,
          title = English original when Persian shown), honest absence when
          the feed has no "Goals per 90" category → the section simply
          hides. */}
      {data && !loading && (data.goalsPer90 || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="12" cy="13" r="8" />
              <path d="M12 13l3.2-3.2" />
              <path d="M10 2h4" />
              <path d="M12 5V2" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">گل در هر ۹۰</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">بهره‌وری گلزنی</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.goalsPer90 || []).map((r, i) => {
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
                    {faDigits(r.goalsPer90.toFixed(2))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="gp90-row">
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

      {/* cycle-230: پاس مورد انتظار — sister-page consistency (the
          210/215/216/217/220/221/222/225/226/227 pattern one surface
          over): the SAME cached getStandings payload now carries the
          expected-assist block (the deep-file family's FOURTEENTH sibling
          and the assist-side ANALYTICS twin of گل مورد انتظار —
          stats/{id}/season/{sid}/expected_assists.json — live-probed
          2026-10-30: SIX of the seven globalMerge leagues serve it with
          WIDE files (ucl 721 Kimmich 1.9 / pl 448 Iwobi 2.6 / laliga 480
          Yamal 4.0 / seriea 487 Dybala 3.4 / bundesliga 399 Olise 4.1 /
          ligue1 422 Thauvin 3.8 rows), persiangulf AND mas honestly absent
          (no xA category). Decimal values kept VERBATIM — the family's
          SEVENTH non-integer member (the 210/217/221/222/226/227 decimal
          convention — 13.4 renders «۱۳.۴»); upstream precision is EXACTLY
          one decimal (probed maxdec=1 on every serving file) so the pill
          renders toFixed(1), dir=ltr — the 217 display rule. SEASON-AWARE
          (the 124/175/185/226/227 class): historical views serve their OWN
          files (the 2020/21 laliga raw = 565 rows, Messi 13.4 — frozen,
          the 202 anchor pattern). Placed right after گل در هر ۹۰ so the
          226/227 expected-vs-actual pairing and the keeper QUINTET stay
          untouched (the 217 contract verbatim) — the analytics/production
          run simply grows by one. Same 170/176 link contract (playerId →
          /player with prefetch=false, title = English original when
          Persian shown), honest absence when the feed has no "Expected
          assist (xA)" category → the section simply hides. */}
      {data && !loading && (data.xa || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <path d="M4 20h16" />
              <path d="M4 16c4-1 8-5 9-9" />
              <path d="M13 4l3 3-4 4-3-3z" />
              <circle cx="5.5" cy="18.5" r="1.2" fill="currentColor" stroke="none" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">پاس مورد انتظار</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">کیفیت خلق موقعیت</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.xa || []).map((r, i) => {
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
                    {faDigits(r.xa.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="xa-row">
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

      {/* cycle-231: سانس بزرگ خلق‌شده — sister-page consistency (the
          210/215/216/217/220/221/222/225/226/227/230 pattern one surface
          over): the SAME cached getStandings payload now carries the
          big-chances-created block (the deep-file family's FIFTEENTH
          sibling and the production-CREATION volume surface beside the
          analytics twins — stats/{id}/season/{sid}/big_chances_created.json
          — live-probed 2026-10-30: 22 of the 24 leagues.ts entries serve it
          with WIDE files (ucl 190 Yamal 5 / pl 152 Groß 7 / laliga 185
          Yamal 14 / seriea 202 Dybala 8 / bundesliga 160 Nusa+Kane 6 /
          ligue1 157 Thauvin 9 rows), persiangulf AND mas honestly absent
          (no "Big chances created" category). INTEGER-VALUED floats
          (probed nonint=0) → the 215/216/220 integer convention: rounded
          once at build, the value pill is Persian digits WITHOUT dir=ltr
          (the minutes contract — 14 renders «۱۴»). SEASON-AWARE (the
          124/175/185/226/227/230 class): historical views serve their OWN
          files (the 2020/21 laliga raw = 309 rows, Messi 22.0 — frozen,
          the 202 anchor pattern). Placed right after پاس مورد انتظار so
          the creation trio (xG quality → xA quality → BCC volume) stays
          together and the keeper QUINTET stays untouched (the 217 contract
          verbatim). Same 170/176 link contract (playerId → /player with
          prefetch=false, title = English original when Persian shown),
          honest absence when the feed has no "Big chances created"
          category → the section simply hides. */}
      {data && !loading && (data.bigChancesCreated || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <rect x="3" y="12" width="18" height="7" rx="1.5" />
              <path d="M6 12V8a2 2 0 012-2h3" />
              <path d="M9 4l2 2-2 2" />
              <circle cx="7.5" cy="15.5" r="1.1" fill="currentColor" stroke="none" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">سانس بزرگ خلق‌شده</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">حجم خلق موقعیت</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.bigChancesCreated || []).map((r, i) => {
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
                    {faDigits(String(r.bigChances))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="bcc-row">
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

      {/* cycle-235: فرصت‌های خلق‌شده — sister-page consistency (the
          210/215/216/217/220/221/222/225/226/227/230/231/232 pattern one
          surface over): the SAME cached getStandings payload now carries
          the chances-created block (the deep-file family's SEVENTEENTH
          sibling and the TOTAL-creation VOLUME twin of the BCC surface —
          stats/{id}/season/{sid}/total_att_assist.json — live-probed
          2026-10-30: WIDE on ALL SIX domestic globalMerge leagues (ucl 466
          Thauvin 15 / pl 323 Groß 23 / laliga 363 Arda Güler 33 / seriea
          382 Giacomo Calò 34 / bundesliga 308 Olise 25 / ligue1 304
          Thauvin 27 rows), persiangulf AND mas honestly absent (no
          "Chances created" category). INTEGER-VALUED floats (probed
          nonint=0) → the 215/216/220 integer convention: rounded once at
          build, the value pill is Persian digits WITHOUT dir=ltr (the
          minutes/BCC contract — 33 renders «۳۳»). SEASON-AWARE (the
          124/175/185/226/227/230/231/232 class): historical views serve
          their OWN files (the 2020/21 laliga raw = 466 rows, Lionel Messi
          77 — frozen, the 202 anchor pattern). Placed right after سانس
          بزرگ خلق‌شده so the subset→total pair reads together (the
          xG→xGOT quality→accuracy mirror one run over) and the keeper
          QUINTET stays untouched (the 217 contract verbatim) — the
          relative orders the 230/231/232/233 gates assert are
          inequality-based, so the insertion provably keeps them green.
          Same 170/176 link contract (playerId → /player with
          prefetch=false, title = English original when Persian shown),
          honest absence when the feed has no "Chances created" category →
          the section simply hides. */}
      {data && !loading && (data.chancesCreated || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="6" cy="6" r="2.2" />
              <circle cx="18" cy="6" r="2.2" />
              <path d="M7.5 8L12 20" />
              <path d="M16.5 8L12 20" />
              <path d="M8 12h8" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">فرصت‌های خلق‌شده</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">حجم کل فرصت‌سازی</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.chancesCreated || []).map((r, i) => {
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
                    {faDigits(String(r.chancesCreated))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="cc-row">
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

      {/* cycle-236: سانس بزرگ ازدست‌رفته — sister-page consistency (the
          210/215/216/217/220/221/222/225/226/227/230/231/232/235 pattern
          one surface over): the SAME cached getStandings payload now
          carries the big-chances-missed block (the deep-file family's
          EIGHTEENTH sibling and the MISSED-volume twin of the BCC surface
          — stats/{id}/season/{sid}/big_chance_missed.json — live-probed
          2026-10-30: WIDE on ALL SIX domestic globalMerge leagues (ucl 140
          Haaland 6 / pl 135 Thierno Barry 12 / laliga 142 Mbappé 13 /
          seriea 171 Malen 9 / bundesliga 126 Demirović 8 / ligue1 128
          Mafouta 6 rows), persiangulf AND mas honestly absent (no "Big
          chances missed" category). INTEGER-VALUED floats (probed
          nonint=0) → the 215/216/220 integer convention: rounded once at
          build, the value pill is Persian digits WITHOUT dir=ltr (12
          renders «۱۲»). SEASON-AWARE (the
          124/175/185/226/227/230/231/232/235 class): historical views
          serve their OWN files (the 2020/21 laliga raw = 257 rows, Karim
          Benzema 19 — frozen, the 202 anchor pattern). Placed right after
          فرصت‌های خلق‌شده so the creation-volume run (خلق‌شده → کل →
          ازدست‌رفته) reads together and the keeper QUINTET stays
          untouched (the 217 contract verbatim) — the relative orders the
          230/231/232/233/235 gates assert are inequality-based, so the
          insertion provably keeps them green. Same 170/176 link contract
          (playerId → /player with prefetch=false, title = English
          original when Persian shown), honest absence when the feed has
          no "Big chances missed" category → the section simply hides. */}
      {data && !loading && (data.bigChancesMissed || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <rect x="3" y="12" width="18" height="7" rx="1.5" />
              <path d="M6 12V8a2 2 0 012-2h3" />
              <circle cx="7.5" cy="15.5" r="1.1" fill="currentColor" stroke="none" />
              <path d="M15 5l4 4" />
              <path d="M19 5l-4 4" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">سانس بزرگ ازدست‌رفته</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">حجم سانس ازدست‌رفته</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.bigChancesMissed || []).map((r, i) => {
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
                    {faDigits(String(r.bigChancesMissed))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="bcm-row">
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

      {/* cycle-221: درصد سیو — sister-page consistency (the
          210/215/216/217/220 pattern one surface over): the SAME cached
          getStandings payload now carries the save-percentage block (the
          deep-file family's NINTH sibling and the THIRD keeper surface —
          stats/{id}/season/{sid}/_save_percentage.json — live-probed
          2026-10-30: SIX of the seven leagues serve it (ucl 45 / pl 21 /
          laliga 21 / seriea 21 / bundesliga 20 / ligue1 18 rows),
          persiangulf honestly absent (no keeper category at all);
          2025/26 frozen anchor Joan García 77.9 / Soria 75.6 / Escandell
          72.5). Percent values with one decimal kept VERBATIM (the
          210/217 decimal convention — 82.5 renders «۸۲.۵»), so the value
          pill is Persian digits WITH dir=ltr (the decimal contract, same
          as امتیازها and گل‌های پیشگیری‌شده). The file's ucl competition
          tie-ranks (1,2,3,3,5,6) are honest upstream data but the served
          top-10 re-ranks POSITIONALLY like every sibling. Placed between
          بیشترین دقایق and گل نخرده‌ها so the THREE keeper surfaces stay
          adjacent (the 217 contract extended). Same 170/176 link contract
          (playerId → /player with prefetch=false, title = English
          original when Persian shown), honest absence when the feed has
          no "Save percentage" category → the section simply hides. */}
      {data && !loading && (data.savePercentage || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <path d="M9 15l6-6" />
              <circle cx="9.4" cy="9.4" r="1" />
              <circle cx="14.6" cy="14.6" r="1" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">درصد سیو</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">دقت مهار</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.savePercentage || []).map((r, i) => {
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
                    {faDigits(r.savePercentage.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="sv-row">
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

      {/* cycle-222: سیو در هر ۹۰ — sister-page consistency (the
          210/215/216/217/220/221 pattern one surface over): the SAME cached
          getStandings payload now carries the saves-per-90 block (the
          deep-file family's TENTH sibling and the FOURTH keeper surface —
          stats/{id}/season/{sid}/saves.json — live-probed 2026-10-30: SIX
          of the seven leagues serve it (ucl 43 / pl 21 / laliga 21 / seriea
          21 / bundesliga 20 / ligue1 18 rows), persiangulf honestly absent
          (no keeper category at all); 2025/26 frozen anchor Aarón Escandell
          4.1 / Dmitrović 3.6 / Ryan 3.5). Per-90 decimal values with one
          decimal kept VERBATIM (the 210/217/221 decimal convention — 4.3
          renders «۴.۳»), so the value pill is Persian digits WITH dir=ltr
          (the decimal contract, same as امتیازها / گل‌های پیشگیری‌شده /
          درصد سیو). The file's ucl competition tie-ranks (1,1,3,4,5,5,7,
          8,8,10) are honest upstream data but the served top-10 re-ranks
          POSITIONALLY like every sibling. Placed right after درصد سیو so
          the FOUR keeper surfaces stay adjacent (the 217 contract extended
          again). Same 170/176 link contract (playerId → /player with
          prefetch=false, title = English original when Persian shown),
          honest absence when the feed has no "Saves per 90" category → the
          section simply hides. */}
      {data && !loading && (data.savesPer90 || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <path d="M12 7v6" />
              <circle cx="12" cy="15.6" r="1" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">سیو در هر ۹۰</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">مهار شوت‌ها</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.savesPer90 || []).map((r, i) => {
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
                    {faDigits(r.savesPer90.toFixed(1))}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="sp90-row">
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

      {/* cycle-225: پنالتی‌های مهارشده — sister-page consistency (the
          210/215/216/217/220/221/222 pattern one surface over): the SAME
          cached getStandings payload now carries the penalty-saves block (the
          deep-file family's ELEVENTH sibling and the FIFTH keeper surface —
          stats/{id}/season/{sid}/penalty_save.json — live-probed 2026-10-30:
          SIX of the seven leagues serve it with NATURALLY thin files (ucl 2 /
          pl 2 / laliga 5 / seriea 5 / bundesliga 4 / ligue1 3 rows — a
          penalty save is a rare event), persiangulf honestly absent (no
          keeper category at all). INTEGER values rounded once (1.0 → 1, the
          215/216 convention), so the value pill is plain Persian digits
          WITHOUT dir=ltr (the clean-sheets/minutes pill convention, NOT the
          decimal one). The file's competition tie-ranks (laliga 1,2,2,4,5)
          are honest upstream data but the served list re-ranks POSITIONALLY
          like every sibling. Placed right after گل‌های پیشگیری‌شده so the
          keeper run stays one adjacent block — now a QUINTET (the 217
          contract extended a third time). Same 170/176 link contract
          (playerId → /player with prefetch=false, title = English original
          when Persian shown), honest absence when the feed has no "Penalty
          saves" category → the section simply hides (persiangulf AND every
          historical season — the block is CURRENT-SEASON ONLY, the 132
          class, probed: the 2020/21, 2023/24 and 2025/26 raws lack the
          category). */}
      {data && !loading && (data.penaltySaves || []).length > 0 && (
        <div className="glass-card overflow-hidden">
          <div className="flex items-center gap-1.5 px-4 pt-3.5 pb-1">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <path d="M12 3l8 3.5v5c0 4.6-3.2 8.2-8 9.5-4.8-1.3-8-4.9-8-9.5v-5z" />
              <circle cx="12" cy="11.5" r="2.4" />
            </svg>
            <h2 className="text-[12.5px] font-black text-[#dceafd]">پنالتی‌های مهارشده</h2>
            <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">مهار از نقطهٔ پنالتی</span>
          </div>
          <ol className="px-2 pb-2.5 flex flex-col">
            {(data.penaltySaves || []).map((r, i) => {
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
                    {faDigits(r.penaltySaves)}
                  </span>
                </>
              );
              const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
              return (
                <li key={`${r.name}-${i}`} data-testid="ps-row">
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
