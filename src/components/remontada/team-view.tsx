"use client";

// ------------------------------------------------------------------
// Remontada — team page: profile + season stats + standings row +
// recent (with venue & round) + upcoming. Cycle 10 enriched.
// ------------------------------------------------------------------
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import type { NormMatch, TeamRowInfo, TeamSeasonStats, TeamFormMatch, TeamSquad, TeamSquadPlayer, TeamTransfersData, TeamTransferItem, TeamTrophiesData, TeamTrophy, TeamVenue, TeamStatsData, TeamStatRow } from "@/lib/fotmob";
import { faDigits, jalaliShort, tehranDateLong, tehranTime } from "@/lib/format";
import { fotmobTeamLogo } from "@/lib/leagues";
import { FavoriteStar } from "@/components/remontada/favorite-star";
import { ShareButton } from "@/components/remontada/share-button";
import { EmptyState } from "@/components/remontada/empty-state";
import { cn } from "@/lib/utils";

interface TeamData {
  ok: boolean;
  team: { id: number; name: string; fa: string; logo: string };
  standings: TeamRowInfo | null;
  season?: TeamSeasonStats | null;
  live: NormMatch[];
  recent: (NormMatch & { round?: string })[];
  upcoming: NormMatch[];
  prematch?: PreMatchPayload | null;
  error?: string;
}

/** mirrors PreMatchInfo from /api/team/[id] (cycle 18) */
interface PreMatchPayload {
  matchId: string;
  kickoff: string;
  venue: "home" | "away";
  opponent: { id: number; name: string; fa: string; logo: string };
  oppRow: TeamRowInfo | null;
  oppSeason: TeamSeasonStats | null;
}

type Row = NormMatch & { round?: string };

function resultOf(m: NormMatch, teamId: number): "W" | "D" | "L" {
  const isHome = m.home.id === teamId;
  const my = isHome ? m.home.score : m.away.score;
  const op = isHome ? m.away.score : m.home.score;
  if (my === null || op === null) return "D";
  if (my > op) return "W";
  if (my < op) return "L";
  return "D";
}

function formChip(c: "W" | "D" | "L") {
  if (c === "W") return "bg-mint/15 text-mint border-mint/30";
  if (c === "D") return "bg-white/[0.04] text-steel border-glass-border-soft";
  return "bg-rose-deep/20 text-rose-soft border-rose-deep/30";
}

/** tick state for live countdowns — 30s cadence, minute precision.
 *  `started: true` once kickoff has passed — callers show a live/started
 *  state instead of a frozen ۰۰:۰۰:۰۰ (fix of cycle-16 bug #6). */
function useCountdown(iso?: string): { days: number; hours: number; minutes: number; started: boolean } | null {
  const [now, setNow] = useState<number | null>(null);
  useEffect(() => {
    if (!iso) return;
    // async first tick (setTimeout 0) — avoids synchronous setState inside
    // the effect body (react-hooks/set-state-in-effect, cycle-16 bug #4)
    const t0 = setTimeout(() => setNow(Date.now()), 0);
    const iv = setInterval(() => setNow(Date.now()), 30_000);
    return () => {
      clearTimeout(t0);
      clearInterval(iv);
    };
  }, [iso]);
  if (!iso || now == null) return null;
  const diff = new Date(iso).getTime() - now;
  if (Number.isNaN(diff)) return null;
  if (diff <= 0) return { days: 0, hours: 0, minutes: 0, started: true };
  const mins = Math.floor(diff / 60_000);
  return { days: Math.floor(mins / 1440), hours: Math.floor((mins % 1440) / 60), minutes: mins % 60, started: false };
}

function SegBox({ v, l }: { v: number; l: string }) {
  return (
    <div className="rounded-xl border border-glass-border-soft bg-white/[0.04] px-2.5 py-1.5 text-center min-w-[48px]">
      <p className="text-[16px] font-light tabular-persian text-[#dfedff] leading-none">{faDigits(String(v).padStart(2, "0"))}</p>
      <p className="text-[8.5px] font-bold text-steel/70 mt-1">{l}</p>
    </div>
  );
}

/** «بازی بعدی» — nearest upcoming fixture with Jalali date + live countdown */
function NextMatchCard({ m, teamId }: { m: NormMatch; teamId: number }) {
  const isHome = m.home.id === teamId;
  const opp = isHome ? m.away : m.home;
  const us = isHome ? m.home : m.away;
  const cd = useCountdown(m.utcTime);
  return (
    <Link
      href={`/match/${m.id}`}
      prefetch={false}
      className="glass-card block overflow-hidden transition-transform duration-200 hover:-translate-y-0.5"
    >
      <div className="px-4 py-2 border-b border-glass-border-soft bg-white/[0.02] flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black text-sky-soft">بازی بعدی</h2>
        <span className="text-[10px] font-bold text-steel/80 truncate">
          {m.leagueFa}
        </span>
      </div>
      <div className="p-4 flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-4">
        <div className="flex items-center gap-2.5 min-w-0 flex-1">
          { }
          <img src={us.logo} alt="" width={30} height={30} loading="lazy" className="w-[30px] h-[30px] object-contain shrink-0 opacity-80" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <span className="text-[10px] font-bold text-muted-foreground shrink-0">در برابر</span>
          { }
          <img src={opp.logo} alt="" width={38} height={38} loading="lazy" className="w-[38px] h-[38px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <div className="min-w-0">
            <p className="text-sm font-black truncate">{opp.fa || opp.name}</p>
            <p className="text-[10.5px] text-muted-foreground tabular-persian mt-0.5">
              {tehranDateLong(m.utcTime)} · ساعت {tehranTime(m.utcTime)}
            </p>
          </div>
          <span
            className={cn(
              "shrink-0 rounded-md border px-1.5 py-px text-[9px] font-black",
              isHome ? "bg-sky-soft/10 text-sky-soft border-sky-soft/20" : "bg-steel/10 text-steel border-steel/20"
            )}
          >
            {isHome ? "خانه" : "بیرون"}
          </span>
        </div>
        {cd ? (
          cd.started ? (
            <span className="shrink-0 inline-flex items-center gap-1.5 rounded-lg border border-red-500/30 bg-red-500/10 text-red-400 text-[10.5px] font-black px-2.5 py-1.5">
              <span className="live-dot live-dot-glow w-1.5 h-1.5 rounded-full bg-red-500 inline-block" />
              بازی شروع شده است
            </span>
          ) : (
            <div className="flex items-center gap-1.5 shrink-0" role="timer" aria-label="شمارش معکوس تا شروع بازی">
              <SegBox v={cd.days} l="روز" />
              <SegBox v={cd.hours} l="ساعت" />
              <SegBox v={cd.minutes} l="دقیقه" />
            </div>
          )
        ) : (
          <span className="text-[11px] font-bold text-muted-foreground shrink-0">در حال محاسبه…</span>
        )}
      </div>
    </Link>
  );
}

/** "Regular season - 8" / "8" / "هفته 8" → «هفته ۸» */
function faRound(r?: string): string | undefined {
  if (!r) return undefined;
  const m = /(\d+)\s*$/.exec(r);
  if (m) return `هفته ${faDigits(m[1])}`;
  return faDigits(r);
}

function TeamMatchRow({ m, teamId, label }: { m: Row; teamId: number; label: "recent" | "upcoming" }) {
  const isHome = m.home.id === teamId;
  const opponent = isHome ? m.away : m.home;
  const res = m.started && !m.cancelled ? resultOf(m, teamId) : null;
  const j = jalaliShort(m.utcTime);

  const inner = (
    <div className="grid grid-cols-[52px_1fr_auto] items-center gap-2.5 px-3 sm:px-4 py-3">
      {/* date/time */}
      <div className="flex flex-col items-center leading-tight">
        {m.live ? (
          <span className="text-[10px] font-black text-red-400 tabular-persian flex items-center gap-1">
            <span className="live-dot w-1 h-1 rounded-full bg-red-500 inline-block" />
            زنده
          </span>
        ) : m.finished ? (
          <>
            <span className="text-[10px] font-bold text-muted-foreground whitespace-nowrap">{j.day} {j.month}</span>
            {m.round && <span className="text-[9px] text-muted-foreground/60 whitespace-nowrap">{faRound(m.round)}</span>}
          </>
        ) : (
          <>
            <span className="text-[10px] font-bold text-muted-foreground">{j.weekday.slice(0, 6)}</span>
            <span className="text-[11px] font-black text-foreground/85 tabular-persian">{tehranTime(m.utcTime)}</span>
          </>
        )}
      </div>
      {/* venue + opponent */}
      <div className="flex items-center justify-end gap-2 min-w-0 text-[13px]">
        <span
          className={cn(
            "shrink-0 rounded-md border px-1.5 py-px text-[9px] font-black",
            isHome ? "bg-sky-soft/10 text-sky-soft border-sky-soft/20" : "bg-steel/10 text-steel border-steel/20"
          )}
        >
          {isHome ? "خانه" : "بیرون"}
        </span>
        <span className="truncate font-black">{opponent.fa || opponent.name}</span>
        { }
        <img src={opponent.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
      </div>
      {/* score / result */}
      <div className="flex justify-end">
        {label === "upcoming" && !m.started ? (
          <span className="text-[10px] text-muted-foreground/70 font-bold">پیش‌رو</span>
        ) : (
          <div className="flex items-center gap-1.5">
            {m.started && !m.cancelled && (
              <span className="font-black text-[13px] tabular-persian bg-white/[0.04] rounded-lg px-2 py-0.5">
                {faDigits(isHome ? m.home.score ?? "—" : m.away.score ?? "—")} : {faDigits(isHome ? m.away.score ?? "—" : m.home.score ?? "—")}
              </span>
            )}
            {res && (
              <span className={cn("w-[22px] h-[22px] rounded-md border text-[10px] font-black flex items-center justify-center", formChip(res))}>
                {res === "W" ? "ب" : res === "D" ? "م" : "پ"}
              </span>
            )}
          </div>
        )}
      </div>
    </div>
  );

  return (
    <Link href={`/match/${m.id}`} className="glass-row-hover block" prefetch={false}>
      {inner}
    </Link>
  );
}

function Section({ title, children, extra }: { title: string; children: React.ReactNode; extra?: React.ReactNode }) {
  return (
    <section className="glass-card overflow-hidden">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black text-[#ecf3fa]">{title}</h2>
        {extra}
      </header>
      <div className="glass-list">{children}</div>
    </section>
  );
}

// ---------------- season stats panel ----------------

function SplitBar({ label, d }: { label: string; d: { wins: number; draws: number; losses: number; gf: number; ga: number } }) {
  const total = d.wins + d.draws + d.losses;
  const seg = [
    { n: d.wins, cls: "bg-primary" },
    { n: d.draws, cls: "bg-muted-foreground/40" },
    { n: d.losses, cls: "bg-destructive/70" },
  ];
  return (
    <div>
      <div className="flex items-center justify-between gap-2 text-[10.5px] font-bold mb-1.5">
        <span>{label}</span>
        <span className="text-muted-foreground tabular-persian">
          {faDigits(d.wins)} ب · {faDigits(d.draws)} م · {faDigits(d.losses)} پ
          <span className="mx-1 text-border">|</span>
          گل {faDigits(d.gf)}:{faDigits(d.ga)}
        </span>
      </div>
      <div className="flex h-1.5 rounded-full overflow-hidden bg-white/[0.06]">
        {total > 0 && seg.map((x, i) => <div key={i} className={x.cls} style={{ width: `${(x.n / total) * 100}%` }} />)}
      </div>
    </div>
  );
}

function BigMatchCard({ title, m, tone }: { title: string; m: (TeamFormMatch & { diff: number }) | null; tone: "win" | "loss" }) {
  if (!m) return null;
  return (
    <Link
      href={`/match/${m.id}`}
      className={cn(
        "flex-1 min-w-0 rounded-xl border px-3 py-2.5 transition-colors",
        tone === "win" ? "border-mint/25 bg-mint/[0.05]" : "border-rose-deep/30 bg-rose-deep/[0.07]"
      )}
      prefetch={false}
    >
      <p className={cn("text-[9.5px] font-black mb-1", tone === "win" ? "text-mint" : "text-rose-soft")}>{title}</p>
      <div className="flex items-center gap-2 min-w-0">
        { }
        <img src={m.opponent.logo} alt="" width={16} height={16} loading="lazy" className="w-4 h-4 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
        <span className="text-[11px] font-black truncate">{m.opponent.fa || m.opponent.name}</span>
        <span className="text-[11px] font-black tabular-persian shrink-0 ms-auto">{faDigits(m.gf)} : {faDigits(m.ga)}</span>
      </div>
      <p className="text-[9px] text-muted-foreground mt-1 tabular-persian">
        {m.round ? faRound(m.round) : ""}{m.round ? " · " : ""}{jalaliShort(m.utcTime).day} {jalaliShort(m.utcTime).month}
      </p>
    </Link>
  );
}

function SeasonPanel({ s }: { s: TeamSeasonStats }) {
  const kpis = [
    { l: "گل زده", v: faDigits(s.goalsFor), sub: `میانگین ${faDigits(s.avgFor.toFixed(1))} در بازی` },
    { l: "گل خورده", v: faDigits(s.goalsAgainst), sub: `میانگین ${faDigits(s.avgAgainst.toFixed(1))} در بازی` },
    { l: "کلین‌شیت", v: faDigits(s.cleanSheets), sub: s.played ? `${faDigits(Math.round((s.cleanSheets / s.played) * 100))}٪ بازی‌ها` : "—" },
    { l: "بدون گل", v: faDigits(s.failedToScore), sub: s.played ? `${faDigits(Math.round((s.failedToScore / s.played) * 100))}٪ بازی‌ها` : "—" },
  ];
  return (
    <section className="glass-card overflow-hidden">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black text-[#ecf3fa]">آمار فصل</h2>
        <Link href={`/league/${s.leagueKey}`} className="text-[10px] font-bold text-steel/80 hover:text-sky-soft transition-colors">
          {s.leagueFa}{s.season ? ` · فصل ${faDigits(s.season)}` : ""}
        </Link>
      </header>
      <div className="p-4 flex flex-col gap-4">
        {/* KPI grid */}
        <div className="grid grid-cols-4 gap-2">
          {kpis.map((k) => (
            <div key={k.l} className="rounded-xl border border-glass-border-soft bg-[#a9cdf611] px-2 py-2.5 text-center">
              <p className="text-[9px] text-steel/70 font-bold">{k.l}</p>
              <p className="text-base font-medium text-[#e0efff] tabular-persian leading-tight mt-0.5">{k.v}</p>
              <p className="text-[8.5px] text-muted-foreground/80 tabular-persian mt-0.5">{k.sub}</p>
            </div>
          ))}
        </div>
        {/* home / away splits */}
        <div className="grid sm:grid-cols-2 gap-x-5 gap-y-3">
          <SplitBar label="در خانه" d={s.home} />
          <SplitBar label="بیرون از خانه" d={s.away} />
        </div>
        {/* biggest win / loss */}
        {(s.biggestWin || s.biggestLoss) && (
          <div className="flex flex-col sm:flex-row gap-2">
            <BigMatchCard title="پرامتیازترین برد فصل" m={s.biggestWin} tone="win" />
            <BigMatchCard title="سنگین‌ترین باخت فصل" m={s.biggestLoss} tone="loss" />
          </div>
        )}
      </div>
    </section>
  );
}

// ---------------- pre-match panel (cycle 18) ----------------

interface SideStats {
  fa: string;
  logo: string;
  row: TeamRowInfo | null;
  season: TeamSeasonStats | null;
  form: { res: "W" | "D" | "L"; title: string }[];
}

function seasonPts(s: TeamSeasonStats | null, r: TeamRowInfo | null): number | undefined {
  if (r) return r.pts;
  if (s && s.played > 0) return s.wins * 3 + s.draws;
  return undefined;
}

function FormChips({ items }: { items: { res: "W" | "D" | "L"; title: string }[] }) {
  if (items.length === 0) {
    return <span className="text-[10px] text-muted-foreground">در دسترس نیست</span>;
  }
  return (
    <div className="flex items-center gap-1">
      {items.map((f, i) => (
        <span
          key={i}
          title={f.title}
          className={cn(
            "w-[18px] h-[18px] rounded-md border text-[8.5px] font-black flex items-center justify-center cursor-default",
            formChip(f.res)
          )}
        >
          {f.res === "W" ? "ب" : f.res === "D" ? "م" : "پ"}
        </span>
      ))}
    </div>
  );
}

function MiniBar({ pct, cls, align }: { pct: number; cls: string; align: "end" | "start" }) {
  if (pct <= 0) return null;
  return (
    <div className={cn("h-1 mt-1 flex w-full", align === "end" ? "justify-end" : "justify-start")}>
      <div className={cn("h-1 rounded-full", cls)} style={{ width: `${Math.max(6, Math.min(100, pct))}%` }} />
    </div>
  );
}

/** «مصاف پیش از بازی» — form of both teams + season stats comparison.
 *  Graceful: sides without a data source (e.g. Iranian teams) show “—” chips. */
function PreMatchPanel({
  pm,
  teamFaName,
  teamLogo,
  row,
  season,
  formEntries,
}: {
  pm: PreMatchPayload;
  teamFaName: string;
  teamLogo: string;
  row: TeamRowInfo | null;
  season: TeamSeasonStats | null;
  formEntries: { res: "W" | "D" | "L"; title: string }[];
}) {
  const ours: SideStats = { fa: teamFaName, logo: teamLogo, row, season, form: formEntries };
  const opp: SideStats = {
    fa: pm.opponent.fa || pm.opponent.name,
    logo: pm.opponent.logo,
    row: pm.oppRow,
    season: pm.oppSeason,
    form:
      pm.oppSeason?.form.map((f) => ({
        res: f.res,
        title: `${f.opponent.fa || f.opponent.name} ${faDigits(f.gf)} - ${faDigits(f.ga)}${f.round ? ` · ${faRound(f.round)}` : ""}`,
      })) || [],
  };

  const pts = (s: SideStats) => seasonPts(s.season, s.row);
  const rowTxt = (s: SideStats) => (s.row ? `رتبه ${faDigits(s.row.rank)}` : null);
  const playedTxt = (s: SideStats) =>
    s.season?.played ? faDigits(s.season.played) : s.row?.played ? faDigits(s.row.played) : null;
  const wdlTxt = (s: SideStats) => {
    const s2 = s.season;
    const w = s2 ? s2.wins : s.row?.wins;
    const d = s2 ? s2.draws : s.row?.draws;
    const l = s2 ? s2.losses : s.row?.losses;
    if (w == null || d == null || l == null) return null;
    return `${faDigits(w)} ب · ${faDigits(d)} م · ${faDigits(l)} پ`;
  };
  const gfTxt = (s: SideStats) =>
    s.season && s.season.played > 0 ? `${faDigits(s.season.goalsFor)} : ${faDigits(s.season.goalsAgainst)}` : null;
  const csTxt = (s: SideStats) => (s.season?.played ? faDigits(s.season.cleanSheets) : null);

  const metrics: { label: string; a?: string | null; b?: string | null; pa?: number | null; pb?: number | null }[] = [
    { label: "رتبه در جدول", a: rowTxt(ours), b: rowTxt(opp) },
    { label: "امتیاز", a: pts(ours) != null ? faDigits(pts(ours)!) : null, b: pts(opp) != null ? faDigits(pts(opp)!) : null, pa: pts(ours) ?? null, pb: pts(opp) ?? null },
    { label: "بازی‌ها", a: playedTxt(ours), b: playedTxt(opp) },
    { label: "برد/مساوی/باخت", a: wdlTxt(ours), b: wdlTxt(opp) },
    { label: "گل زده : خورده", a: gfTxt(ours), b: gfTxt(opp), pa: ours.season?.goalsFor ?? null, pb: opp.season?.goalsFor ?? null },
    { label: "کلین‌شیت", a: csTxt(ours), b: csTxt(opp), pa: ours.season?.cleanSheets ?? null, pb: opp.season?.cleanSheets ?? null },
  ];

  const sideHead = (s: SideStats, align: "end" | "start") => (
    <div className={cn("flex items-center gap-2 min-w-0", align === "end" ? "flex-row" : "flex-row-reverse")}>
      <img src={s.logo} alt="" width={22} height={22} loading="lazy" className="w-[22px] h-[22px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
      <span className="text-[12px] font-black truncate">{s.fa}</span>
    </div>
  );

  return (
    <section className="glass-card overflow-hidden">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black text-[#ecf3fa]">مصاف پیش از بازی</h2>
        <Link href={`/match/${pm.matchId}`} prefetch={false} className="text-[10px] font-bold text-steel/80 hover:text-sky-soft transition-colors">
          صفحه بازی ←
        </Link>
      </header>

      <div className="p-4 flex flex-col gap-3">
        {/* two team heads + forms */}
        <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-x-3">
          <div className="flex flex-col items-end gap-1.5 min-w-0">
            {sideHead(ours, "end")}
            <FormChips items={ours.form} />
          </div>
          <span className="text-[9.5px] font-black text-steel bg-white/[0.04] rounded-lg px-2 py-1 whitespace-nowrap">
            در برابر
          </span>
          <div className="flex flex-col items-start gap-1.5 min-w-0">
            {sideHead(opp, "start")}
            <FormChips items={opp.form} />
          </div>
        </div>

        {/* season comparison */}
        {metrics.some((x) => x.a || x.b) && (
          <div className="rounded-xl border border-glass-border-soft bg-white/[0.02] px-3.5 py-2 flex flex-col glass-list">
            {metrics.map((x) => {
              if (!x.a && !x.b) return null;
              const max = Math.max(x.pa ?? 0, x.pb ?? 0, 1);
              return (
                <div key={x.label} className="grid grid-cols-[1fr_auto_1fr] items-center gap-x-3 py-1.5">
                  <div className="min-w-0">
                    <span className="font-black text-[12px] tabular-persian block text-end">{x.a ?? "—"}</span>
                    {x.pa != null && x.pb != null && <MiniBar pct={(x.pa / max) * 100} cls="bg-sky-soft/70" align="end" />}
                  </div>
                  <span className="text-[9.5px] font-bold text-muted-foreground text-center px-1 whitespace-nowrap">{x.label}</span>
                  <div className="min-w-0">
                    <span className="font-black text-[12px] tabular-persian block text-start">{x.b ?? "—"}</span>
                    {x.pa != null && x.pb != null && <MiniBar pct={((x.pb ?? 0) / max) * 100} cls="bg-sky-soft/70" align="start" />}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {!opp.season && !opp.row && (
          <p className="text-[10px] text-muted-foreground text-center">
            آمار فصل حریف از منبع داده در دسترس نیست — فرم بالا از بازی‌های اخیر است.
          </p>
        )}
      </div>
    </section>
  );
}

// ---------------- cycle-70: team squad («ترکیب تیم») ----------------
// Fantasy-minimal roster: legend-gold shirt numbers like a game menu party
// list, group rules, rating chips that glow when a player is in form.

function SquadRow({ p }: { p: TeamSquadPlayer }) {
  const inForm = (p.rating ?? 0) >= 7.5;
  return (
    <div className="flex items-center gap-2.5 rounded-xl border border-glass-border-soft bg-white/[0.02] px-2.5 py-2">
      <span
        className={cn(
          "w-7 text-center text-[12.5px] font-black tabular-persian shrink-0",
          inForm ? "text-gold" : "text-steel/80"
        )}
      >
        {p.shirt != null ? faDigits(p.shirt) : "—"}
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-[12.5px] font-bold truncate text-[#e6f0fb] flex items-center gap-1.5">
          {p.name}
          {p.injured && (
            <span className="text-[8.5px] font-black text-red-400 bg-red-400/10 border border-red-400/30 rounded-md px-1 py-px shrink-0">
              مصدوم
            </span>
          )}
        </p>
        <p className="text-[9.5px] text-steel/70 tabular-persian truncate">
          {[p.nationality, p.age != null ? `${faDigits(p.age)} ساله` : "", p.height ? `${faDigits(p.height)} سانتی‌متر` : ""]
            .filter(Boolean)
            .join(" · ")}
        </p>
      </div>
      <div className="flex items-center gap-1.5 shrink-0 tabular-persian">
        {(p.goals ?? 0) > 0 && (
          <span className="text-[9.5px] font-black text-mint" title="گل در فصل جاری">
            {faDigits(p.goals as number)} گل
          </span>
        )}
        {(p.assists ?? 0) > 0 && (
          <span className="text-[9.5px] font-black text-sky-soft" title="پاس گل در فصل جاری">
            {faDigits(p.assists as number)} پاس
          </span>
        )}
        {p.rating != null && (
          <span
            className={cn(
              "text-[10px] font-black rounded-md border px-1.5 py-0.5",
              inForm
                ? "text-gold border-gold/40 bg-gold/10"
                : "text-steel border-glass-border-soft bg-white/[0.03]"
            )}
            title="میانگین امتیاز فصل"
          >
            {faDigits(p.rating.toFixed(1))}
          </span>
        )}
      </div>
    </div>
  );
}

function SquadSection({ squad }: { squad: TeamSquad }) {
  const total = squad.groups.reduce((a, g) => a + g.players.length, 0);
  return (
    <Section
      title="ترکیب تیم"
      extra={
        total > 0 ? (
          <span className="text-[10px] text-steel/60 tabular-persian">
            {faDigits(total)} بازیکن
          </span>
        ) : undefined
      }
    >
      <div className="flex flex-col gap-3.5" data-testid="team-squad">
        {squad.coach && (
          <div className="flex items-center gap-2.5 rounded-xl border border-gold/25 bg-gold/[0.06] px-3 py-2">
            <span className="text-gold text-[11px] font-black shrink-0">سرمربی</span>
            <span className="h-3 w-px bg-gold/30 shrink-0" aria-hidden="true" />
            <p className="min-w-0 flex-1 truncate text-[12px] font-bold text-[#e6f0fb]">
              {squad.coach.name}
            </p>
            <p className="text-[9.5px] text-steel/70 tabular-persian shrink-0">
              {[squad.coach.nationality, squad.coach.age != null ? `${faDigits(squad.coach.age)} ساله` : ""]
                .filter(Boolean)
                .join(" · ")}
            </p>
          </div>
        )}
        {squad.groups.map((g) => (
          <div key={g.key}>
            <p className="text-[10.5px] font-black text-steel/85 mb-1.5 flex items-center gap-2">
              {g.titleFa}
              <span className="text-[9px] font-bold text-steel/50 tabular-persian">
                ({faDigits(g.players.length)})
              </span>
              <span className="h-px flex-1 bg-glass-border-soft/70" aria-hidden="true" />
            </p>
            <div className="flex flex-col gap-1.5">
              {g.players.map((p) => (
                <SquadRow key={p.id} p={p} />
              ))}
            </div>
          </div>
        ))}
      </div>
    </Section>
  );
}

// ---------------- team transfers («بازار انتقال‌ها», cycle-71) ----------------
// Same visual language as the league feed (league-transfers.tsx): direction
// chip mint/rose/sky, from→to club tags with tiny logos, Persian fee label
// and Jalali date. Kind «internal» in a team context means contract renewal.
const TEAM_KIND_CHIP: Record<TeamTransferItem["kind"], string> = {
  in: "text-mint border-mint/30 bg-mint/10",
  out: "text-rose-soft border-rose-soft/30 bg-rose-soft/10",
  internal: "text-sky-soft border-sky-soft/30 bg-sky-soft/10",
};

function TransferClubTag({ id, name }: { id: number; name: string }) {
  return (
    <span className="inline-flex items-center gap-1 min-w-0">
      <img
        src={fotmobTeamLogo(id)}
        alt=""
        width={14}
        height={14}
        loading="lazy"
        className="w-3.5 h-3.5 rounded-[3px] object-contain shrink-0 bg-white/10"
        onError={(e) => {
          e.currentTarget.style.visibility = "hidden";
        }}
      />
      <span className="truncate">{name}</span>
    </span>
  );
}

function TeamTransferRow({ t }: { t: TeamTransferItem }) {
  const j = t.date ? jalaliShort(t.date) : null;
  return (
    <li className="glass-card px-3 py-2.5 flex items-start gap-2.5">
      <span
        className="shrink-0 w-8 h-8 rounded-lg bg-white/[0.05] border border-[color:var(--glass-border-soft)] grid place-items-center text-[10px] font-black text-[#c3d4ea]"
        aria-hidden
      >
        {t.position || "—"}
      </span>
      <div className="flex-1 min-w-0">
        <p className="text-[12.5px] font-black truncate">{t.name}</p>
        <p className="text-[11px] text-[#b4c8df]/75 flex items-center gap-1.5 mt-0.5">
          <span className="min-w-0 flex items-center gap-1">
            <TransferClubTag id={t.from.id} name={t.from.fa} />
          </span>
          <span className="text-muted-foreground shrink-0" aria-hidden>←</span>
          <span className="min-w-0 flex items-center gap-1">
            <TransferClubTag id={t.to.id} name={t.to.fa} />
          </span>
        </p>
      </div>
      <div className="shrink-0 flex flex-col items-end gap-1">
        <span className={cn("text-[9.5px] font-black rounded-md border px-1.5 py-0.5", TEAM_KIND_CHIP[t.kind])}>
          {t.kindFa}
        </span>
        <span className="text-[10px] font-bold text-[#c3d4ea]">{t.feeFa}</span>
        {j && (
          <span className="text-[9.5px] text-muted-foreground tabular-persian whitespace-nowrap">
            {j.day} {j.month}
          </span>
        )}
      </div>
    </li>
  );
}

function TeamTransfersSection({ data }: { data: TeamTransfersData }) {
  return (
    <Section
      title="بازار انتقال‌ها"
      extra={
        <span className="text-[10px] font-bold text-muted-foreground tabular-persian">
          ورودی {faDigits(data.nIn)} · خروجی {faDigits(data.nOut)}
          {data.nInternal > 0 && <> · تمدید {faDigits(data.nInternal)}</>}
        </span>
      }
    >
      <ul className="flex flex-col gap-2" data-testid="team-transfers" aria-label="بازار انتقال‌های تیم">
        {data.items.map((t, i) => (
          <TeamTransferRow key={`${t.playerId}:${t.date}:${i}`} t={t} />
        ))}
      </ul>
    </Section>
  );
}

// ---------------- team trophies («گنجهٔ افتخارات», cycle-72) ----------------
// Game-menu achievement shelf: legend-gold glyph + count badge (×۵۶) like a
// party list, subtle runner-up line, last-title season in Persian digits.
function TeamTrophyRow({ t }: { t: TeamTrophy }) {
  return (
    <li className="glass-card px-3 py-2.5 flex items-center gap-2.5">
      <span
        className="shrink-0 w-8 h-8 rounded-lg grid place-items-center text-[13px] text-gold border border-gold/25 bg-gold/10"
        aria-hidden
      >
        ✦
      </span>
      <div className="flex-1 min-w-0">
        <p className="text-[12.5px] font-black truncate">{t.nameFa}</p>
        {t.lastWon && (
          <p className="text-[10px] text-muted-foreground tabular-persian mt-0.5">
            آخرین قهرمانی: {faDigits(t.lastWon)}
          </p>
        )}
      </div>
      <div className="shrink-0 flex flex-col items-end gap-1">
        {t.won > 0 && (
          <span className="text-[10.5px] font-black tabular-persian rounded-md border border-gold/30 bg-gold/10 text-gold px-1.5 py-0.5">
            ×{faDigits(t.won)}
          </span>
        )}
        {t.runnerup > 0 && (
          <span className="text-[9.5px] font-bold tabular-persian text-steel/80">نایب ×{faDigits(t.runnerup)}</span>
        )}
      </div>
    </li>
  );
}

function TeamTrophiesSection({ data }: { data: TeamTrophiesData }) {
  return (
    <Section
      title="گنجهٔ افتخارات"
      extra={
        data.totalWon > 0 ? (
          <span className="text-[10px] font-bold text-muted-foreground tabular-persian">
            مجموع {faDigits(data.totalWon)} جام
          </span>
        ) : undefined
      }
    >
      <ul className="flex flex-col gap-2" data-testid="team-trophies" aria-label="گنجهٔ افتخارات تیم">
        {data.items.map((t, i) => (
          <TeamTrophyRow key={`${t.name}:${i}`} t={t} />
        ))}
      </ul>
    </Section>
  );
}

// ---------------- team venue («ورزشگاه خانه», cycle-75) ----------------
// Compact home-ground card in the same game-menu language: stadium name +
// city on the first row, stat chips (ظرفیت with Persian thousands separator,
// سطح چمن, سال افتتاح) below — same chip grid as the header mini-stats.
const SURFACE_FA_UI: Record<string, string> = {
  grass: "چمن طبیعی",
  artificial: "چمن مصنوعی",
};

function TeamVenueCard({ v }: { v: TeamVenue }) {
  const chips: { l: string; val: string }[] = [];
  if (typeof v.capacity === "number") {
    chips.push({ l: "ظرفیت", val: faDigits(v.capacity.toLocaleString("en-US")).replace(/,/g, "٬") });
  }
  if (v.surface) chips.push({ l: "سطح چمن", val: SURFACE_FA_UI[v.surface.toLowerCase()] || v.surface });
  if (typeof v.opened === "number") chips.push({ l: "سال افتتاح", val: faDigits(v.opened) });
  return (
    <Section title="ورزشگاه خانه">
      <div className="px-3 py-3 flex flex-col gap-2.5" data-testid="team-venue">
        <div className="flex items-baseline justify-between gap-2 min-w-0">
          <p className="text-[13.5px] font-black truncate">{v.name}</p>
          {v.city && <p className="text-[10.5px] text-muted-foreground font-bold shrink-0">{v.city}</p>}
        </div>
        {chips.length > 0 && (
          <div className="grid grid-cols-3 gap-2">
            {chips.map((c) => (
              <div key={c.l} className="rounded-xl border border-glass-border-soft bg-white/[0.03] px-2 py-2 text-center">
                <p className="text-[9px] text-steel/70 font-bold">{c.l}</p>
                <p className="text-[12.5px] font-black tabular-persian mt-0.5">{c.val}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </Section>
  );
}

// ---------------- team season stats («آمار برتر فصل», cycle-76) ----------------
// Game-menu rows in the same language as the trophy cabinet: player leaders
// carry a mint ★ box, team-level rows a sky ◈ box; value pre-formatted
// Persian (fractions keep decimals via «٫»), league rank as the sub-line.
function TeamStatRowBox({ r }: { r: TeamStatRow }) {
  const player = r.kind === "player";
  const sub = player ? r.nameFa : typeof r.rank === "number" ? `رتبهٔ ${faDigits(r.rank)} لیگ` : "";
  return (
    <li className="glass-card px-3 py-2.5 flex flex-col gap-1">
      <div className="flex items-center gap-2.5">
        <span
          className={cn(
            "shrink-0 w-8 h-8 rounded-lg grid place-items-center text-[13px] border",
            player ? "text-mint border-mint/25 bg-mint/10" : "text-sky-soft border-sky-soft/25 bg-sky-soft/10"
          )}
          aria-hidden
        >
          {player ? "★" : "◈"}
        </span>
        <div className="flex-1 min-w-0">
          <p className="text-[12.5px] font-black truncate">{player ? r.leader : r.nameFa}</p>
          {sub && <p className="text-[10px] text-muted-foreground mt-0.5 truncate">{sub}</p>}
        </div>
        <div className="shrink-0 flex flex-col items-end gap-0.5">
          <p className="text-[14px] font-black tabular-persian leading-none">{r.value}</p>
          {player && typeof r.rank === "number" && (
            <span className="text-[9.5px] font-bold tabular-persian text-steel/80">رتبهٔ {faDigits(r.rank)} لیگ</span>
          )}
        </div>
      </div>
      {/* cycle-77: topThree context — «سپس:» next-best teammates (player rows),
          «صدر:» the league leader (team rows, hidden when we are first) */}
      {r.extras && r.extras.length > 0 && (
        <p className="text-[9.5px] font-bold text-steel/70 truncate ps-[42px] tabular-persian">
          {player ? "سپس: " : "صدر: "}
          {r.extras.join(" · ")}
        </p>
      )}
    </li>
  );
}

function TeamStatsSection({ data }: { data: TeamStatsData }) {
  const hasPlayers = data.playerRows.length > 0;
  const hasTeams = data.teamRows.length > 0;
  if (!hasPlayers && !hasTeams) return null;
  return (
    <Section title="آمار برتر فصل">
      <div className="flex flex-col gap-2" data-testid="team-stats">
        {hasPlayers && (
          <>
            <p className="text-[10px] font-bold text-steel/70 px-1">بهترین‌های تیم</p>
            <ul className="flex flex-col gap-2" aria-label="بهترین‌های تیم">
              {data.playerRows.map((r) => (
                <TeamStatRowBox key={`p:${r.key}`} r={r} />
              ))}
            </ul>
          </>
        )}
        {hasTeams && (
          <>
            <p className="text-[10px] font-bold text-steel/70 px-1">جایگاه در لیگ</p>
            <ul className="flex flex-col gap-2" aria-label="جایگاه تیم در لیگ">
              {data.teamRows.map((r) => (
                <TeamStatRowBox key={`t:${r.key}`} r={r} />
              ))}
            </ul>
          </>
        )}
      </div>
    </Section>
  );
}

export function TeamView({ teamId }: { teamId: number }) {
  const [data, setData] = useState<TeamData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // cycle-70: lazy squad («ترکیب تیم») — independent endpoint, fetched after
  // mount so the first paint stays fast; stays null → section hidden when the
  // source has no squad data (and on fetch failure the page must not break).
  const [squad, setSquad] = useState<TeamSquad | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(`/api/team-squad/${teamId}`, { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (alive && j?.ok && j.squad) setSquad(j.squad as TeamSquad);
      })
      .catch(() => {
        /* squad stays null → section hidden */
      });
    return () => {
      alive = false;
    };
  }, [teamId]);

  // cycle-71: lazy team transfers («بازار انتقال‌ها») — same data/teams
  // source as the squad (one shared upstream cache), fetched after mount;
  // stays null → section hidden when the source has no feed.
  const [transfers, setTransfers] = useState<TeamTransfersData | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(`/api/team-transfers/${teamId}`, { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (alive && j?.ok && j.transfers) setTransfers(j.transfers as TeamTransfersData);
      })
      .catch(() => {
        /* transfers stay null → section hidden */
      });
    return () => {
      alive = false;
    };
  }, [teamId]);

  // cycle-72: lazy team trophies («گنجهٔ افتخارات») — same data/teams source
  // (shared upstream cache), fetched after mount; stays null → section hidden.
  const [trophies, setTrophies] = useState<TeamTrophiesData | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(`/api/team-trophies/${teamId}`, { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (alive && j?.ok && j.trophies) setTrophies(j.trophies as TeamTrophiesData);
      })
      .catch(() => {
        /* trophies stay null → section hidden */
      });
    return () => {
      alive = false;
    };
  }, [teamId]);

  // cycle-75: lazy team venue («ورزشگاه خانه») — same data/teams source
  // (shared upstream cache), fetched after mount; stays null → section hidden.
  const [venue, setVenue] = useState<TeamVenue | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(`/api/team-venue/${teamId}`, { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (alive && j?.ok && j.venue) setVenue(j.venue as TeamVenue);
      })
      .catch(() => {
        /* venue stays null → section hidden */
      });
    return () => {
      alive = false;
    };
  }, [teamId]);

  // cycle-76: lazy team stats («آمار برتر فصل») — same data/teams source
  // (shared upstream cache), fetched after mount; stays null → section hidden.
  const [stats, setStats] = useState<TeamStatsData | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(`/api/team-stats/${teamId}`, { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (alive && j?.ok && j.stats) setStats(j.stats as TeamStatsData);
      })
      .catch(() => {
        /* stats stay null → section hidden */
      });
    return () => {
      alive = false;
    };
  }, [teamId]);

  const fetchTeam = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/team/${teamId}`, { cache: "no-store" });
      const json = (await res.json()) as TeamData;
      if (json.ok) {
        setData(json);
        setError(null);
      } else {
        setError(json.error || "خطا در دریافت اطلاعات تیم");
      }
    } catch {
      setError("ارتباط برقرار نشد. دوباره تلاش کنید.");
    } finally {
      setLoading(false);
    }
  }, [teamId]);

  useEffect(() => {
    fetchTeam();
  }, [fetchTeam]);

  if (loading && !data) {
    return (
      <div className="flex flex-col gap-4" aria-busy="true">
        <div className="glass-card p-8 flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded bg-white/[0.05] animate-pulse" />
          <div className="h-5 w-40 rounded bg-white/[0.05] animate-pulse" />
          <div className="h-3 w-24 rounded bg-white/[0.05] animate-pulse" />
        </div>
        <div className="glass-card h-40 animate-pulse" />
      </div>
    );
  }

  if (error && !data) {
    return (
      <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-5 py-8 text-center">
        {/* fix cycle-74: the team error shell had no heading (cycle-73 finding,
            same a11y class as the cycle-59 match-page fix) — sr-only h1, zero
            visual change */}
        <h1 className="sr-only">صفحه تیم</h1>
        <p className="font-black text-sm text-destructive mb-1">{error}</p>
        <button onClick={fetchTeam} className="text-xs font-bold text-foreground underline underline-offset-4">
          تلاش مجدد
        </button>
      </div>
    );
  }

  if (!data) return null;
  const st = data.standings;
  const season = data.season || null;

  // colored form — prefer the season form (has opponent + score tooltips)
  const formEntries: { res: "W" | "D" | "L"; title: string }[] = season?.form.length
    ? season.form.map((f) => ({
        res: f.res,
        title: `${f.opponent.fa || f.opponent.name} ${faDigits(f.gf)} - ${faDigits(f.ga)}${f.round ? ` · ${faRound(f.round)}` : ""}`,
      }))
    : data.recent.slice(0, 5).map((m) => ({ res: resultOf(m, teamId), title: "" }));
  const formPts = formEntries.reduce((a, f) => a + (f.res === "W" ? 3 : f.res === "D" ? 1 : 0), 0);

  return (
    <div className="flex flex-col gap-4">
      {/* profile header */}
      <section className="glass-card glass-hero overflow-hidden">
        <div className="p-5 flex items-center gap-4">
          { }
          <span className="brand-glyph w-[72px] h-[72px] flex items-center justify-center shrink-0 overflow-hidden">
            <img src={data.team.logo} alt="" width={56} height={56} className="w-14 h-14 object-contain drop-shadow-[0_5px_12px_oklch(0.03_0.015_255/65%)]" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          </span>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2 min-w-0">
              <h1 className="text-xl font-black truncate text-[#ecf3fa]">{data.team.fa || data.team.name}</h1>
              <FavoriteStar
                team={{ id: teamId, fa: data.team.fa || data.team.name, en: data.team.name }}
                size={20}
              />
              <ShareButton
                title={`${data.team.fa || data.team.name} | رمانتادا`}
                path={`/team/${teamId}`}
                size={24}
                className="!border-transparent !bg-transparent"
              />
            </div>
            {st ? (
              <p className="text-[11px] text-steel/85 mt-0.5">
                <Link href={`/league/${st.leagueKey}`} className="hover:text-sky-soft transition-colors font-bold">
                  {st.leagueFa}
                </Link>
                {" · "}
                رتبه {faDigits(st.rank)} با {faDigits(st.pts)} امتیاز
              </p>
            ) : season ? (
              <p className="text-[11px] text-steel/85 mt-0.5">
                <Link href={`/league/${season.leagueKey}`} className="hover:text-sky-soft transition-colors font-bold">
                  {season.leagueFa}
                </Link>
                {season.season ? ` · فصل ${faDigits(season.season)}` : ""}
              </p>
            ) : (
              <p className="text-[11px] text-steel/85 mt-0.5">اطلاعات لیگ یافت نشد</p>
            )}
            {formEntries.length > 0 && (
              <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                <span className="text-[10px] text-muted-foreground font-bold">فرم اخیر:</span>
                {formEntries.map((f, i) => (
                  <span
                    key={i}
                    title={f.title}
                    className={cn("w-[22px] h-[22px] rounded-md border text-[9.5px] font-black flex items-center justify-center cursor-default", formChip(f.res))}
                  >
                    {f.res === "W" ? "ب" : f.res === "D" ? "م" : "پ"}
                  </span>
                ))}
                {formEntries.length >= 3 && (
                  <span className="text-[9.5px] text-muted-foreground tabular-persian ms-1">
                    ({faDigits(formPts)} امتیاز از {faDigits(formEntries.length)} بازی)
                  </span>
                )}
              </div>
            )}
          </div>
          {/* stats mini-grid */}
          {st && (
            <div className="hidden sm:grid grid-cols-3 gap-2 text-center shrink-0">
              {[
                { l: "بازی", v: st.played },
                { l: "برد", v: st.wins },
                { l: "گل", v: `${st.gd > 0 ? "+" : ""}${st.gd}` },
              ].map((x) => (
                <div key={x.l} className="rounded-xl border border-glass-border-soft bg-white/[0.03] px-3 py-2">
                  <p className="text-[9px] text-steel/70 font-bold">{x.l}</p>
                  <p className="text-sm font-black tabular-persian">{typeof x.v === "number" ? faDigits(x.v) : x.v}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* next match + live countdown */}
      {data.upcoming.length > 0 && <NextMatchCard m={data.upcoming[0]} teamId={teamId} />}

      {/* pre-match panel: both teams' form + season comparison (cycle 18) */}
      {data.prematch && (
        <PreMatchPanel
          pm={data.prematch}
          teamFaName={data.team.fa || data.team.name}
          teamLogo={data.team.logo}
          row={st}
          season={season}
          formEntries={formEntries}
        />
      )}

      {/* season stats */}
      {season && season.played > 0 && <SeasonPanel s={season} />}

      {/* cycle-76: season stat leaders («آمار برتر فصل») — lazily probed, hidden when absent */}
      {stats && <TeamStatsSection data={stats} />}

      {/* cycle-75: home ground («ورزشگاه خانه») — lazily probed, hidden when absent */}
      {venue && venue.name && <TeamVenueCard v={venue} />}

      {data.live.length > 0 && (
        <Section title="در جریان">
          {data.live.map((m) => (
            <TeamMatchRow key={m.id} m={m} teamId={teamId} label="recent" />
          ))}
        </Section>
      )}

      <Section title="بازی‌های پیش‌رو">
        {data.upcoming.length > 0 ? (
          data.upcoming.map((m) => <TeamMatchRow key={m.id} m={m} teamId={teamId} label="upcoming" />)
        ) : (
          <EmptyState icon="calendar" compact title="در ۱۰ روز آینده بازی‌ای ثبت نشده است" sub="بعد از اعلام برنامه‌ی جدید، بازی‌ها همین‌جا نمایش داده می‌شوند." />
        )}
      </Section>

      <Section title="نتایج اخیر">
        {data.recent.length > 0 ? (
          data.recent.map((m) => <TeamMatchRow key={m.id} m={m} teamId={teamId} label="recent" />)
        ) : (
          <EmptyState icon="ball" compact title="بازی پایان‌یافته‌ای در بازه‌ی اخیر یافت نشد" sub="بازی‌های قبلی تیم پس از به‌روزرسانی فید روزانه نمایش داده می‌شوند." />
        )}
      </Section>

      {/* cycle-70: team squad («ترکیب تیم») — lazily probed, hidden when absent */}
      {squad && <SquadSection squad={squad} />}

      {/* cycle-71: team transfers («بازار انتقال‌ها») — lazily probed, hidden when absent */}
      {transfers && transfers.items.length > 0 && <TeamTransfersSection data={transfers} />}

      {/* cycle-72: team trophies («گنجهٔ افتخارات») — lazily probed, hidden when absent */}
      {trophies && trophies.items.length > 0 && <TeamTrophiesSection data={trophies} />}

      <p className="text-[10px] text-muted-foreground px-1 text-center">
        نتایج از فید روزانه‌ی FotMob و آمار فصل از فیکسچرهای لیگ تجمیع شده است.
      </p>
    </div>
  );
}
