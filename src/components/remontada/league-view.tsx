"use client";

// ------------------------------------------------------------------
// Remontada — league page: standings | fixtures | recent | scorers
// ------------------------------------------------------------------
import { Fragment, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { StandingsData, StandingsRow, LeagueFixturesData, NormFixture, LeagueStats, LeagueBracketData, LeagueTransfersData, LeagueBoard, LeagueTitleHistory } from "@/lib/fotmob";
// cycle-99: same strict season shape as the API guard — one regex, one
// contract (client-safe module; a value import from fotmob.ts would drag
// the server graph into the client bundle — caught in this cycle's build)
import { SEASON_PARAM_RE } from "@/lib/season";
import { LEAGUES, fotmobTeamLogo, type LeagueConfig } from "@/lib/leagues";
import { SITE_URL } from "@/lib/site";
import { JsonLd } from "@/components/remontada/json-ld";
import { LeagueBracket } from "@/components/remontada/league-bracket";
import { LeagueTransfersList } from "@/components/remontada/league-transfers";
import { faDigits, jalaliShort, offsetDateISO, tehranDateKey, tehranTime, timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";
import { EmptyState } from "@/components/remontada/empty-state";
import { GlassLeagueHeader, GlassPosterMeta, pad2 } from "@/components/remontada/glass-stats";
import { PlayerPhoto } from "@/components/remontada/player-photo";
import { TableModeSwitch, type TableMode } from "@/components/remontada/table-mode";

type Tab = "standings" | "stats" | "fixtures" | "recent" | "scorers" | "bracket" | "transfers" | "titles";

/** Current-week progress bar («هفته ۱۲ از ۳۸») — numeric rounds only. */
function SeasonProgress({ progress }: { progress: { current: number; total: number } }) {
  const pct = Math.min(100, Math.round((progress.current / progress.total) * 100));
  return (
    <section
      className="glass-card px-4 py-3 flex items-center gap-3"
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
        className="flex-1 h-2 rounded-full bg-white/[0.07] overflow-hidden"
        role="progressbar"
        aria-valuemin={1}
        aria-valuemax={progress.total}
        aria-valuenow={progress.current}
      >
        <div className="h-full bg-sky-soft/70 rounded-full transition-all" style={{ width: `${pct}%` }} />
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

/** cycle-55: "2024/2025" → «۲۰۲۴/۲۵» — Persian digits, short second year. */
function faSeasonShort(s: string): string {
  const m = /^(\d{4})\/(\d{4})$/.exec(s);
  return m ? faDigits(`${m[1]}/${m[2].slice(2)}`) : faDigits(s);
}

function FixtureRow({ f, showResult }: { f: NormFixture; showResult: boolean }) {
  const j = jalaliShort(f.utcTime);
  return (
    <Link
      href={`/match/${f.id}`}
      className="group grid grid-cols-[1fr_auto_1fr] items-center gap-2 px-3 sm:px-4 py-3 glass-row-hover transition-colors"
      prefetch={false}
    >
      <div className="flex items-center justify-end gap-2 min-w-0 font-semibold">
        <span className="truncate text-[13px]">{f.home.fa || f.home.name}</span>
        { }
        <img src={f.home.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
      </div>
      <div className="flex flex-col items-center min-w-[86px]">
        {showResult ? (
          <span className="font-black text-sm tabular-persian text-[#e0efff] bg-[#a9cdf611] border border-[color:var(--glass-border-soft)] rounded-lg px-2.5 py-0.5">
            {f.home.score ?? "—"} : {f.away.score ?? "—"}
          </span>
        ) : (
          <span className="text-[11px] font-black text-foreground/80 tabular-persian">
            {tehranTime(f.utcTime)}
          </span>
        )}
        {f.round && <span className="text-[9px] text-muted-foreground/80 mt-0.5">{f.round}</span>}
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
    return (
      <EmptyState
        icon="calendar"
        compact
        title={showResult ? "بازی پایان‌یافته‌ای در بازه‌ی اخیر نیست" : "برنامه‌ی بازی‌های پیش‌رو ثبت نشده است"}
        sub={showResult ? "به محض پایان بازی‌ها، نتایج همین‌جا ثبت می‌شود." : "به محض اعلام برنامه، بازی‌ها همین‌جا نمایش داده می‌شوند."}
      />
    );
  }
  if (!dateGrouped) {
    // desktop: split into two columns inside one card; mobile: single list
    const mid = Math.ceil(items.length / 2);
    return (
      <div className="glass-card overflow-hidden">
        <div className="glass-list lg:hidden">
          {items.map((f) => (
            <FixtureRow key={f.id} f={f} showResult={showResult} />
          ))}
        </div>
        <div className="hidden lg:grid lg:grid-cols-2">
          <div className="glass-list">
            {items.slice(0, mid).map((f) => (
              <FixtureRow key={f.id} f={f} showResult={showResult} />
            ))}
          </div>
          <div className="glass-list border-s border-[color:var(--glass-hairline)]">
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
          <div key={date} className="glass-card overflow-hidden">
            <header className="px-4 py-2 border-b border-[color:var(--glass-hairline)] glass-thead text-[11px] font-black text-[#b6cce3]">
              {j.weekday} {j.day} {j.month}
            </header>
            <div className="glass-list">
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
    <div className="glass-card overflow-hidden">
      <header className="px-4 py-2.5 border-b border-[color:var(--glass-hairline)] glass-thead text-[11px] font-black text-[#b6cce3] flex items-center gap-1.5">
        <span aria-hidden>{tone === "home" ? "🏟️" : "✈️"}</span>
        {title}
      </header>
      <ol className="glass-list">
        {items.map((t, i) => (
          <li key={t.teamId} className="flex items-center gap-3 px-4 py-2.5">
            <span className="w-5 text-[11px] font-black text-muted-foreground tabular-persian shrink-0">{faDigits(i + 1)}</span>
            { }
            <img src={t.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
            <div className="min-w-0 flex-1">
              <div className="flex items-center justify-between gap-2">
                <Link href={`/team/${t.teamId}`} className="tap-hit-name font-bold text-[12.5px] truncate hover:text-primary transition-colors" prefetch={false}>
                  {t.fa || t.short}
                </Link>
                <span className="text-[11px] font-black text-sky-soft tabular-persian shrink-0">{faDigits(t.wins)} برد</span>
              </div>
              <div className="mt-1 h-1 rounded-full bg-white/[0.07] overflow-hidden">
                <div className={cn("h-full rounded-full", tone === "home" ? "bg-sky-soft/80" : "bg-steel/80")} style={{ width: `${(t.wins / max) * 100}%` }} />
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
    <div className="rounded-xl border border-[color:var(--glass-border-soft)] bg-[#a9cdf611] px-3 py-3 text-center">
      <p className="text-lg sm:text-xl font-black text-[#dfedff] tabular-persian leading-6">{value}</p>
      <p className="text-[10.5px] font-bold mt-0.5">{label}</p>
      {sub && <p className="text-[9px] text-muted-foreground mt-0.5 tabular-persian">{sub}</p>}
    </div>
  );
}

// ---------------- upstream season boards («برترین‌های رسمی فصل», cycle-92) ----------------
// Podiums from the SAME leagueRaw payload's stats blocks (team + player),
// formatted with the payload's own stat.format/stat.fractions hints so the
// numbers stay honest (percent/number/currency/kph/fraction).
function boardValue(v: number, fmt: string, fractions: number): string {
  if (fmt === "percent") return `${faDigits(v.toFixed(1))}٪`;
  if (fmt === "kph") return faDigits(v.toFixed(1));
  if (fmt === "currency") {
    const abs = Math.abs(v);
    if (abs >= 1e9) return `${faDigits((v / 1e9).toFixed(2))} میلیارد`;
    if (abs >= 1e6) return `${faDigits((v / 1e6).toFixed(1))} میلیون`;
    return faDigits(Math.round(v).toString().replace(/\B(?=(\d{3})+(?!\d))/g, "٬"));
  }
  if (fmt === "number") {
    return faDigits(Math.round(v).toString().replace(/\B(?=(\d{3})+(?!\d))/g, "٬"));
  }
  return faDigits(v.toFixed(Math.max(0, Math.min(fractions, 2))));
}

function BoardRow({ row, kind }: { row: LeagueBoard["rows"][number] & { _v: string }; kind: "team" | "player" }) {
  const first = row.rank === 1;
  const href = kind === "player" && row.playerId ? `/player/${row.playerId}` : row.teamId ? `/team/${row.teamId}` : null;
  const body = (
    <>
      <span
        className={cn(
          "shrink-0 w-6 h-6 rounded-md grid place-items-center text-[10px] font-black tabular-persian border",
          first ? "glass-leader" : "text-[#c3d4ea] border-[color:var(--glass-border-soft)] bg-white/[0.05]"
        )}
        aria-hidden
      >
        {faDigits(row.rank)}
      </span>
      <div className="flex-1 min-w-0">
        <p className="text-[12.5px] font-black truncate">{row.nameFa || row.name}</p>
        {kind === "player" && row.teamFa && (
          <p className="text-[10px] text-muted-foreground truncate mt-0.5">{row.teamFa}</p>
        )}
      </div>
      <p className="shrink-0 text-[13px] font-black tabular-persian" aria-label="مقدار آماره">
        {row._v}
      </p>
    </>
  );
  const cls = cn(
    "flex items-center gap-2.5 rounded-xl px-2.5 py-2",
    first ? "glass-leader" : "bg-white/[0.03] border border-[color:var(--glass-border-soft)]"
  );
  return href ? (
    <Link href={href} prefetch={false} className={cn(cls, "glass-row-hover block")}>
      {body}
    </Link>
  ) : (
    <div className={cls}>{body}</div>
  );
}

function SeasonBoards({ boards, season }: { boards: LeagueBoard[]; season?: string }) {
  const kinds: ("team" | "player")[] = [];
  if (boards.some((b) => b.kind === "team")) kinds.push("team");
  if (boards.some((b) => b.kind === "player")) kinds.push("player");
  const [kind, setKind] = useState<"team" | "player">(kinds[0] || "team");
  const [header, setHeader] = useState<string | null>(null);
  const avail = boards.filter((b) => b.kind === kind);
  const active = avail.find((b) => b.header === header) || avail[0] || null;
  if (!active) return null;
  return (
    <section className="glass-card p-4" data-testid="league-boards" aria-label="برترین‌های رسمی فصل">
      <div className="flex items-center justify-between gap-2 flex-wrap mb-3">
        {/* cycle-199 additive: the honest season marker (the 55 convention)
            reaches the boards header — on a deep-linked historical season the
            podiums switch while the title stayed ambiguous; same chip style
            as the sibling GlassLeagueHeader sections (آقای گل et al). */}
        <div className="flex items-center gap-2 min-w-0">
          <h3 className="text-[11px] font-black text-[#b6cce3]">برترین‌های رسمی فصل</h3>
          {season && (
            <span className="text-[9.5px] font-bold text-steel/90 border border-glass-border-soft bg-white/[0.03] rounded-md px-2 py-1 tabular-persian whitespace-nowrap">
              {season}
            </span>
          )}
        </div>
        {kinds.length > 1 && (
          <div className="flex gap-1" role="tablist" aria-label="نوع برترین‌ها">
            {kinds.map((k) => (
              <button
                key={k}
                role="tab"
                aria-selected={kind === k}
                onClick={() => {
                  setKind(k);
                  setHeader(null);
                }}
                className={cn(
                  "rounded-full border px-2.5 py-1 text-[10px] font-black transition-colors",
                  kind === k ? "text-sky-soft border-sky-soft/30 bg-sky-soft/10" : "text-muted-foreground border-[color:var(--glass-border-soft)] bg-white/[0.03] hover:text-foreground"
                )}
              >
                {k === "team" ? "تیم‌ها" : "بازیکنان"}
              </button>
            ))}
          </div>
        )}
      </div>
      <div className="flex gap-1.5 flex-wrap mb-3" role="tablist" aria-label="دستهٔ آماری">
        {avail.map((b) => (
          <button
            key={b.header}
            role="tab"
            aria-selected={active.header === b.header}
            onClick={() => setHeader(b.header)}
            className={cn(
              "rounded-full border px-2.5 py-1 text-[10px] font-black transition-colors",
              active.header === b.header ? "text-foreground border-gold/30 bg-gold/10" : "text-muted-foreground border-[color:var(--glass-border-soft)] bg-white/[0.03] hover:text-foreground"
            )}
          >
            {b.headerFa}
          </button>
        ))}
      </div>
      <p className="text-[10px] text-muted-foreground mb-2">{active.subFa || ""}{active.subFa ? " · " : ""}سه نفر برتر فصل طبق دادهٔ FotMob</p>
      <div className="flex flex-col gap-1.5">
        {active.rows.map((r) => (
          <BoardRow key={`${r.rank}:${r.name}`} row={{ ...r, _v: boardValue(r.value, active.fmt, active.fractions) }} kind={active.kind} />
        ))}
      </div>
    </section>
  );
}

function StatsPanel({ stats, leagueFa }: { stats: LeagueStats; leagueFa: string }) {
  const n = stats.finished;
  const pct = (x: number) => (n > 0 ? Math.round((x / n) * 100) : 0);
  const maxRoundGoals = Math.max(...stats.topRounds.map((r) => r.goals), 1);

  if (n === 0) {
    return <EmptyState icon="calendar" compact title="هنوز بازی‌ای از این فصل به پایان نرسیده است" sub="آمار لیگ بعد از شروع فصل و پایان نخستین بازی‌ها فعال می‌شود." />;
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
      <section className="glass-card p-4">
        <h3 className="text-[11px] font-black text-[#b6cce3] mb-3">ترکیب نتایج {leagueFa} این فصل</h3>
        <div className="flex h-2.5 rounded-full overflow-hidden bg-white/[0.07]" dir="rtl" aria-hidden>
          <div className="bg-sky-soft/85" style={{ width: `${pct(stats.homeWins)}%` }} />
          <div className="bg-white/[0.14]" style={{ width: `${pct(stats.draws)}%` }} />
          <div className="bg-steel/80" style={{ width: `${pct(stats.awayWins)}%` }} />
        </div>
        <div className="flex items-center justify-between mt-2 text-[11px] font-bold tabular-persian">
          <span className="text-sky-soft">{faDigits(stats.homeWins)} برد میزبان</span>
          <span className="text-muted-foreground">{faDigits(stats.draws)} مساوی</span>
          <span className="text-steel">{faDigits(stats.awayWins)} برد مهمان</span>
        </div>
      </section>

      {/* most home/away wins */}
      <div className="grid gap-4 lg:grid-cols-2 lg:items-start">
        {stats.topHomeWins.length > 0 && <WinStatList title="بیشترین برد در خانه" items={stats.topHomeWins} tone="home" />}
        {stats.topAwayWins.length > 0 && <WinStatList title="بیشترین برد در بیرون از خانه" items={stats.topAwayWins} tone="away" />}
      </div>

      {/* highest scoring rounds */}
      {stats.topRounds.length > 0 && (
        <div className="glass-card overflow-hidden">
          <header className="px-4 py-2.5 border-b border-[color:var(--glass-hairline)] glass-thead text-[11px] font-black text-[#b6cce3]">پرگل‌ترین هفته‌های فصل</header>
          <ol className="glass-list">
            {stats.topRounds.map((r, i) => (
              <li key={r.round} className="flex items-center gap-3 px-4 py-2.5">
                <span className={cn(
                  "w-6 h-6 rounded-lg flex items-center justify-center text-[10px] font-black shrink-0 tabular-persian",
                  i === 0 ? "bg-chart-3/20 text-chart-3 border border-chart-3/30" : "bg-white/[0.05] text-muted-foreground"
                )}>
                  {faDigits(i + 1)}
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-bold text-[12.5px] truncate">{r.round}</span>
                    <span className="text-[11px] font-black tabular-persian shrink-0">{faDigits(r.goals)} گل</span>
                  </div>
                  <div className="mt-1 h-1 rounded-full bg-white/[0.07] overflow-hidden">
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
        <div className="glass-card overflow-hidden">
          <header className="px-4 py-2.5 border-b border-[color:var(--glass-hairline)] glass-thead text-[11px] font-black text-[#b6cce3]">پرامتیازترین برد فصل</header>
          <Link href={`/match/${stats.biggestWin.id}`} className="flex items-center gap-3 px-4 py-3 glass-row-hover transition-colors" prefetch={false}>
            <span className="flex items-center justify-end gap-2 flex-1 min-w-0 font-black text-[12.5px]">
              <span className="truncate">{stats.biggestWin.home.fa || stats.biggestWin.home.short}</span>
              { }
              <img src={stats.biggestWin.home.logo} alt="" width={20} height={20} loading="lazy" className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
            </span>
            <span className="font-black text-sm tabular-persian text-[#e0efff] bg-[#a9cdf611] border border-[color:var(--glass-border-soft)] rounded-lg px-2.5 py-1 shrink-0">
              {faDigits(stats.biggestWin.home.score ?? 0)} : {faDigits(stats.biggestWin.away.score ?? 0)}
            </span>
            <span className="flex items-center gap-2 flex-1 min-w-0 font-semibold text-[12.5px] text-muted-foreground">
              { }
              <img src={stats.biggestWin.away.logo} alt="" width={20} height={20} loading="lazy" className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
              <span className="truncate">{stats.biggestWin.away.fa || stats.biggestWin.away.short}</span>
            </span>
          </Link>
          {stats.biggestWin.round && <p className="px-4 pb-2.5 text-[9px] text-muted-foreground/80 tabular-persian">{faDigits(stats.biggestWin.round)}</p>}
        </div>
      )}

      <p className="text-[10px] text-muted-foreground px-1">
        آمار فصل از مجموع {faDigits(n)} بازی به‌پایان‌رسیده‌ی {leagueFa} محاسبه می‌شود و با هر بازی جدید به‌روز می‌شود.
      </p>
    </div>
  );
}

function ScorersList({ data, leagueKey }: { data: StandingsData; leagueKey: string }) {
  const list = data.scorers;
  if (!list || list.length === 0) {
    return <EmptyState icon="medal" compact title="آقای گل این لیگ هنوز ثبت نشده است" sub="گلزنان پس از ثبت داده‌ی فصل از سوی منبع نمایش داده می‌شوند." />;
  }
  const lgCfg = LEAGUES.find((l) => l.key === leagueKey);
  const [top, ...rest] = list;
  return (
    /* Ninth-generation tap-hit-row: the two small links of the «آقای گل» card —
       the 15px header action and the 22px leader-name link — get the transparent
       ::after extension; both sit amid ≥2px of non-interactive padding/text and
       ≥8px from the nearest interactive neighbour, so the zone never covers one. */
    <div className="glass-card overflow-hidden">
      <GlassLeagueHeader
        leagueId={lgCfg?.fotmobId}
        title="آقای گل"
        sub={lgCfg ? `${lgCfg.ccode3} · ${lgCfg.enName}` : undefined}
        season={(data.selectedSeason || data.season) ? `فصل ${faDigits(data.selectedSeason || data.season)}` : undefined}
      >
        <Link
          href={`/topscorers/${leagueKey}`}
          className="tap-hit-row leading-5 inline-flex items-center gap-1 text-[10px] font-bold text-chart-3 hover:text-primary transition-colors"
        >
          صفحه کامل گلزنان
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" aria-hidden>
            <path d="M15 5l-7 7 7 7" />
          </svg>
        </Link>
      </GlassLeagueHeader>
      <div className="p-2.5 flex flex-col">
        {/* hero — the studio scoring-chart leader tile with the big metric */}
        <div className="glass-scorer-hero p-3.5 flex items-center gap-3">
          <PlayerPhoto id={top.playerId} name={top.nameFa || top.name} size={56} />
          <div className="min-w-0 flex-1">
            <p className="text-[8px] font-bold tracking-[0.24em] text-[#9dbad8] uppercase">LEAGUE LEADER</p>
            {top.playerId ? (
              <Link
                href={`/player/${top.playerId}`}
                prefetch={false}
                className="tap-hit-row block w-fit max-w-full mt-0.5 hover:text-primary transition-colors"
                title={top.nameFa && top.nameFa !== top.name ? top.name : `پروفایل ${top.name}`}
              >
                {/* truncate lives on the inner span: overflow:hidden on the link itself
                    would clip the tap-hit-row ::after zone entirely (measured live) */}
                <span className="block text-[14.5px] font-bold text-[#f1f7fd] truncate">
                  {top.nameFa || top.name}
                </span>
              </Link>
            ) : (
              <p className="text-[14.5px] font-bold text-[#f1f7fd] truncate mt-0.5">{top.nameFa || top.name}</p>
            )}
            {top.team && <p className="text-[10px] text-[#92adc9] truncate mt-0.5">{top.team}</p>}
          </div>
          <div className="text-center shrink-0 ps-1">
            <p className="text-[34px] leading-none font-light text-[#dfedff] tabular-persian">{faDigits(pad2(top.goals))}</p>
            {/* ui-cycle-18: data floor 9px */}
            <p className="text-[9px] font-bold text-[#c6dcf3] mt-1">گل</p>
          </div>
        </div>
        <ol className="mt-1 flex flex-col">
          {rest.map((s, i) => {
            const rank = s.rank ?? i + 2;
            const inner = (
              <>
                <span className="w-7 h-7 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10.5px] font-bold shrink-0 tabular-persian">
                  {faDigits(pad2(rank))}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[12.5px] font-bold text-[#e5eefb] truncate">{s.nameFa || s.name}</span>
                  {s.team && <span className="block text-[9.5px] text-[#92adc9] truncate">{s.team}</span>}
                </span>
                <span className="shrink-0 min-w-[36px] text-center rounded-md bg-[#a9cdf611] px-2 py-1 text-[14px] font-semibold text-[#e0efff] tabular-persian">
                  {faDigits(s.goals)}
                </span>
              </>
            );
            const cls = "flex items-center gap-2.5 px-2 py-2.5 rounded-lg glass-row-hover w-full min-w-0 text-start";
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
        {/* cycle-170: بهترین پاس‌دهندگان — the standings payload always carried the
            assists block (freshenHonestNames freshened only the team) but the
            league page dropped it; compact 3-row list under the scorers table,
            same link contract (playerId → /player, title = English original when
            Persian shown), honest absence when the feed has no assists (mas) */}
        {(data.assists || []).length > 0 && (
          <div className="mt-2 border-t border-[color:var(--glass-hairline)] pt-2.5">
            <div className="flex items-center gap-1.5 px-0.5 pb-1.5">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" className="text-chart-2" aria-hidden>
                <path d="M4 19h16" />
                <path d="M5 15l5-5 4 3 5-7" />
              </svg>
              <h3 className="text-[11.5px] font-black text-[#dceafd]">بهترین پاس‌دهندگان</h3>
              <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">پاس گل فصل</span>
            </div>
            <ol className="flex flex-col">
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
        {/* cycle-176: کارت‌ها — the cycle-50 card pipeline (deep fetchAllUrl
            files + cycle-127 thin-TTL + fresh names) had exactly one consumer
            (the global /topscorers merge); the league's own yellow/red leaders
            now ride the standings payload. Two compact columns (زرد/قرمز),
            top 5 each, same link contract as 170/174 (playerId → /player with
            prefetch=false, title = English original when Persian shown,
            id>0 guard — the 167 lesson), per-kind honest absence (mas has no
            "Yellow cards" category → red-only column). */}
        {data.cards && ((data.cards.yellow || []).length > 0 || (data.cards.red || []).length > 0) && (
          <div className="mt-2 border-t border-[color:var(--glass-hairline)] pt-2.5">
            <div className="flex items-center gap-1.5 px-0.5 pb-1.5">
              <span className="flex gap-1" aria-hidden>
                <span className="w-1.5 h-2.5 rounded-[2px] bg-[#f2c94c]" />
                <span className="w-1.5 h-2.5 rounded-[2px] bg-[#eb5757]" />
              </span>
              <h3 className="text-[11.5px] font-black text-[#dceafd]">کارت‌ها</h3>
              <span className="ms-auto text-[9px] text-[#8fa8c1] tabular-persian">زرد / قرمز فصل</span>
            </div>
            <div className="grid grid-cols-2 gap-2">
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
      </div>
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
            f === "W" ? "bg-mint" : f === "D" ? "bg-white/[0.16]" : "bg-rose-soft/90"
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
      <Link href={`/team/${team.id}`} prefetch={false} className="tap-hit-row flex items-center gap-2 min-w-0 group">
        {/* ui-cycle-19: tap-hit-row — preview side team links 22px → 30px */}
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
        <span className="text-[10px] text-muted-foreground/80">خارج از جدول</span>
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
    <section className="glass-card overflow-hidden" aria-label="پیش‌نمایش بازی‌های امروز">
      <header className="px-4 py-2 border-b border-[color:var(--glass-hairline)] bg-primary/[0.06] flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black text-primary">پیش‌نمایش بازی‌های امروز</h2>
        <span className="text-[10px] font-bold text-muted-foreground tabular-persian">{faDigits(todays.length)} بازی</span>
      </header>
      <div className="glass-list">
        {shown.map((f) => (
          <div key={f.id} className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 sm:gap-4 px-3 sm:px-5 py-3.5">
            <PreviewSide team={f.home} row={rowsById.get(f.home.id)} />
            <Link
              href={`/match/${f.id}`}
              prefetch={false}
              className="flex flex-col items-center gap-1 shrink-0 min-w-[62px] rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.04] px-2.5 py-2 hover:border-sky-soft/40 hover:bg-sky-soft/10 transition-colors"
              title="صفحه بازی"
            >
              <span className="text-[12px] font-black tabular-persian">{tehranTime(f.utcTime)}</span>
              <span className="text-[9px] text-muted-foreground font-bold">امروز</span>
            </Link>
            <PreviewSide team={f.away} row={rowsById.get(f.away.id)} />
          </div>
        ))}
      </div>
      {todays.length > shown.length && (
        <p className="text-[10px] text-muted-foreground px-4 py-2 border-t border-[color:var(--glass-hairline)] tabular-persian">
          و {faDigits(todays.length - shown.length)} بازی دیگر امروز — در تب «بازی‌های پیش‌رو»
        </p>
      )}
    </section>
  );
}

function StandingsTable({ data, league }: { data: StandingsData; league: LeagueConfig }) {
  // cycle-52: internal mode state — parent keys this component by leagueKey,
  // so switching league remounts and resets to «کل فصل» without any effect
  const [mode, setMode] = useState<TableMode>("all");
  // per-side rows come straight from the same /api/standings payload
  // (additive `home`/`away`); switch renders only when the source really has
  // both splits — otherwise the control would lie about available data
  const hasSides = !!(data.home?.length && data.away?.length);
  const rows = mode === "home" && hasSides ? data.home! : mode === "away" && hasSides ? data.away! : data.rows;
  const modeLabel = hasSides && mode === "home" ? "جدول خانه" : hasSides && mode === "away" ? "جدول بیرون" : "جدول رده‌بندی";
  // cycle-141: composite league-phase feeds (AFC CL Elite — West/East) — the
  // lib flattens the regional sub-tables into `rows` and records the segment
  // boundaries in data.groups; the walk draws a full-width region header row
  // at each boundary. Absent on every flat feed → zero rendering change.
  const groupStarts = new Map<number, string>();
  if (data.groups) {
    let off = 0;
    for (const g of data.groups) {
      if (g.fa) groupStarts.set(off, g.fa);
      off += g.count;
    }
  }
  return (
    <div className="glass-card overflow-hidden">
      <GlassLeagueHeader
        leagueId={league.fotmobId}
        title={data.leagueFa}
        sub={`${league.ccode3} · ${league.enName}`}
        season={(data.selectedSeason || data.season) ? `فصل ${faDigits(data.selectedSeason || data.season)}` : undefined}
      />
      <GlassPosterMeta right={modeLabel} left={data.rows.length ? `${faDigits(data.rows.length)} تیم${data.updatedAt ? ` · به‌روزرسانی ${timeAgoFa(data.updatedAt)}` : ""}` : undefined} />
      {hasSides && (
        <div className="px-4 pb-2.5">
          <TableModeSwitch mode={mode} onChange={setMode} />
        </div>
      )}
      <div className="overflow-x-auto">
        {/* ui-cycle-1: same mobile-fit contract as standings-view — the hard
            min-w-[480px] pushed the امتیاز column off a 390px screen (the
            wrapper is ~364px); min-w-0 + tightened paddings + a capped team
            cell keep every VISIBLE column inside the card on phones, sm+
            restores the roomy layout. Same 10 columns in the DOM, no testid
            touched. */}
        <table className="w-full text-[12px] sm:text-[13px] min-w-0 sm:min-w-[480px]">
          <thead>
            <tr className="glass-thead text-[9px] sm:text-[10px] border-y border-[color:var(--glass-hairline)] text-[#b6cce3]">
              <th className="py-2 pe-1 ps-2.5 sm:ps-3 font-bold text-start w-8 sm:w-9">#</th>
              <th className="py-2 px-1 font-bold text-start max-w-[132px] sm:max-w-none">تیم</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center">ب</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center">بر</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center">مس</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center">با</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center hidden lg:table-cell" title="گل زده">گز</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center hidden lg:table-cell" title="گل خورده">گخ</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center hidden sm:table-cell">تف</th>
              <th className="py-2 px-2 sm:px-2.5 font-black text-center text-[#d6e8fb]">امتیاز</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => {
              const leader = r.idx === 1;
              const groupHeader = groupStarts.get(i);
              return (
                <Fragment key={r.teamId}>
                {groupHeader && (
                  <tr data-testid="standings-group-row" className="border-y border-[color:var(--glass-hairline)] bg-[#9ec3e50d]">
                    <td colSpan={10} className="py-1.5 ps-3 text-[10px] sm:text-[11px] font-black text-[#b6cce3] tracking-wide">
                      {groupHeader}
                    </td>
                  </tr>
                )}
                <tr
                  className={cn(
                    "border-b border-[color:var(--glass-hairline)] last:border-0 glass-row-hover transition-colors",
                    leader && "glass-leader"
                  )}
                >
                  <td className="py-2.5 pe-1 ps-2.5 sm:ps-3 relative">
                    {r.qualColor && <span className="absolute inset-y-1 right-0 w-[3px] rounded-full" style={{ backgroundColor: r.qualColor }} aria-hidden />}
                    {/* ui-cycle-12: podium medallions — the home-page standings
                        (standings-view, cycle-64) already celebrates top-3 with
                        gold/silver/bronze medals; the /league/* table (this one,
                        the surface users actually open) showed a bare number.
                        Same classes, same CSS, now consistent across both. */}
                    {r.idx <= 3 ? (
                      <span
                        className={cn(
                          "rank-medal tabular-persian",
                          r.idx === 1 ? "rank-medal-gold" : r.idx === 2 ? "rank-medal-silver" : "rank-medal-bronze"
                        )}
                      >
                        {faDigits(r.idx)}
                      </span>
                    ) : (
                      <span className={cn("font-bold tabular-persian text-[11px]", r.idx <= 3 ? "text-[#deedfc]" : "text-[#8da7c3]/90")}>
                        {faDigits(pad2(r.idx))}
                      </span>
                    )}
                  </td>
                  <td className="py-2 px-1 max-w-[132px] sm:max-w-none">
                    <Link href={`/team/${r.teamId}`} className="tap-hit-row flex items-center gap-2 min-w-0 group" prefetch={false}>
                      <img src={r.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                      {/* ui-cycle-12: the leader wears the crown — same mark as
                          standings-view; inline-flex+gap-1 keeps it glued to the
                          name without breaking truncate. */}
                      <span className={cn("font-bold truncate group-hover:text-primary transition-colors inline-flex items-center gap-1", leader && "text-[#f1f7ff]")}>
                        {leader && (
                          <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" className="text-gold shrink-0" aria-label="صدرنشین">
                            <path d="M3 8l4.5 3L12 5l4.5 6L21 8l-1.6 9H4.6L3 8z" />
                          </svg>
                        )}
                        {r.fa || r.name}
                      </span>
                    </Link>
                  </td>
                  <td className="py-2 px-1 sm:px-1.5 text-center tabular-persian text-[#b4c8df]/70">{faDigits(r.played)}</td>
                  <td className="py-2 px-1 sm:px-1.5 text-center tabular-persian text-[#c3d4ea]">{faDigits(r.wins)}</td>
                  <td className="py-2 px-1 sm:px-1.5 text-center tabular-persian text-[#b4c8df]/70">{faDigits(r.draws)}</td>
                  <td className="py-2 px-1 sm:px-1.5 text-center tabular-persian text-[#b4c8df]/70">{faDigits(r.losses)}</td>
                  <td className="py-2 px-1 sm:px-1.5 text-center tabular-persian text-[#b4c8df]/70 hidden lg:table-cell">{faDigits(r.goalsFor)}</td>
                  <td className="py-2 px-1 sm:px-1.5 text-center tabular-persian text-[#b4c8df]/70 hidden lg:table-cell">{faDigits(r.goalsAgainst)}</td>
                  <td className="py-2 px-1 sm:px-1.5 text-center tabular-persian hidden sm:table-cell">
                    <span className={cn(r.gd > 0 ? "text-mint" : r.gd < 0 ? "text-rose-soft" : "text-[#8da7c3]/80")}>
                      {r.gd > 0 ? `+${faDigits(r.gd)}` : faDigits(r.gd)}
                    </span>
                  </td>
                  <td className="py-2 px-2 sm:px-2.5 text-center">
                    <span
                      // ui-cycle-12: leader points pill goes gold (matches
                      // standings-view) — the blue tint read as a normal
                      // hover state, the gold reads as the scoreboard moment.
                      className={cn(
                        "font-black tabular-persian rounded-lg px-1.5 sm:px-2 py-0.5 inline-block min-w-[30px] sm:min-w-[34px]",
                        leader ? "text-[#f6efdc] bg-[#e3c7671f] shadow-[0_0_12px_oklch(0.84_0.12_85/0.22)]" : "text-[#e4eefb] bg-[#9ec3e50b]"
                      )}
                    >
                      {faDigits(r.pts)}
                    </span>
                  </td>
                </tr>
                </Fragment>
              );
            })}
          </tbody>
        </table>
      </div>
      {/* update cycle-111: zone legend («راهنمای سهمیه‌ها») — explains the
          per-row qualColor strips; curated Persian titles, unknown tKeys
          never reach here (honest drop in the lib). Hidden when the feed
          lacks a legend (persiangulf) or the cached entry predates 111. */}
      {/* ui-cycle-6 (BL-6): ≥5 zones wrapped into a ragged cramped cluster at
          390 — two lines of floating swatches. Crowded legends (≥5) now get
          an aligned two-column grid on mobile (every swatch on a fixed x,
          row gap 8px), one-line flow at sm+ and for ≤4-item legends. Same
          change as standings-view — the two legend sites stay identical. */}
      {data.legend && data.legend.length > 0 && (
        <div
          className={cn(
            "px-3.5 py-2.5 border-t border-[color:var(--glass-hairline)]",
            data.legend.length >= 5
              ? "grid grid-cols-2 gap-x-3 gap-y-2 sm:flex sm:flex-wrap sm:items-center sm:gap-x-4 sm:gap-y-1.5"
              : "flex flex-wrap items-center gap-x-4 gap-y-1.5"
          )}
          data-testid="standings-legend"
          aria-label="راهنمای سهمیه‌ها"
        >
          {data.legend.map((l) => (
            <span key={l.fa} className="flex items-center gap-1.5 text-[10px] font-bold text-[#92adc9]">
              <span aria-hidden className="h-2 w-2 rounded-[3px] shrink-0" style={{ backgroundColor: l.color }} />
              {l.fa}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}

// ---------- cycle-90: xG table («جدول xG») --------------------------------
// FotMob mirrors the league table with an expected-goals variant (xg /
// xgConceded / xPoints), joined into the standings rows by team id in
// getStandings (same cached payload, zero extra upstream). Rendered below
// the main table in the SAME order for row-by-row comparison; hidden
// entirely when the source has no xG data (Persian Gulf, some historical
// seasons). Delta = real points − expected points: positive = the team
// earned more than its chances deserved (clinical / lucky), negative =
// underperforming — sign convention matches FotMob's own xPointsDiff.
function XgTable({ rows }: { rows: StandingsRow[] }) {
  const withXg = useMemo(() => rows.filter((r) => typeof r.xg === "number"), [rows]);
  if (withXg.length === 0) return null;
  const fmt1 = (v: number) => faDigits(v.toFixed(1));
  return (
    <div className="glass-card overflow-hidden" data-testid="league-xg">
      <header className="px-4 pt-3.5 pb-2 flex items-baseline justify-between gap-2">
        <h2 className="text-sm font-black text-[#deedfc]">جدول xG</h2>
        <span className="text-[9px] text-muted-foreground">کل فصل · ترتیب مطابق جدول اصلی</span>
      </header>
      <div className="overflow-x-auto">
        {/* ui-cycle-2: same mobile-fit contract as the standings tables — the
            hard min-w-[420px] overflowed a 390px phone by ~56px, clipping the
            اختلاف (delta) pill; min-w-0 + tightened paddings + a capped team
            cell keep all SIX columns inside the card on phones, sm+ restores
            the roomy layout. Same DOM, testid league-xg untouched. */}
        <table className="w-full text-[12px] sm:text-[13px] min-w-0 sm:min-w-[420px]">
          <thead>
            <tr className="glass-thead text-[9px] sm:text-[10px] border-y border-[color:var(--glass-hairline)] text-[#b6cce3]">
              <th className="py-2 pe-1 ps-2.5 sm:ps-3 font-bold text-start w-8 sm:w-9">#</th>
              <th className="py-2 px-1 font-bold text-start max-w-[128px] sm:max-w-none">تیم</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center" title="گل مورد انتظار زده">xG</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center" title="گل مورد انتظار خورده">xGA</th>
              <th className="py-2 px-1 sm:px-1.5 font-bold text-center" title="امتیاز مورد انتظار بر پایهٔ کیفیت موقعیت‌ها">امتیاز x</th>
              <th className="py-2 px-2 sm:px-2.5 font-black text-center" title="امتیاز واقعی منهای امتیاز x — مثبت: بیش از عملکرد، منفی: کمتر از عملکرد">اختلاف</th>
            </tr>
          </thead>
          <tbody>
            {withXg.map((r) => {
              const delta = r.xPts != null ? r.pts - r.xPts : null;
              return (
                <tr
                  key={r.teamId}
                  className={cn(
                    "border-b border-[color:var(--glass-hairline)] last:border-0 glass-row-hover transition-colors",
                    r.idx === 1 && "glass-leader"
                  )}
                >
                  <td className="py-2.5 pe-1 ps-2.5 sm:ps-3">
                    {/* ui-cycle-12: same podium medallions as the main table —
                        the xG mirror shares the league ordering, one rank
                        language across the page. */}
                    {r.idx <= 3 ? (
                      <span
                        className={cn(
                          "rank-medal tabular-persian",
                          r.idx === 1 ? "rank-medal-gold" : r.idx === 2 ? "rank-medal-silver" : "rank-medal-bronze"
                        )}
                      >
                        {faDigits(r.idx)}
                      </span>
                    ) : (
                      <span className={cn("font-bold tabular-persian text-[11px]", r.idx <= 3 ? "text-[#deedfc]" : "text-[#8da7c3]/90")}>
                        {faDigits(pad2(r.idx))}
                      </span>
                    )}
                  </td>
                  <td className="py-2.5 px-1 max-w-[128px] sm:max-w-none">
                    <span className="flex items-center gap-2 min-w-0">
                      <img src={r.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" />
                      <span className="font-bold text-[#e4eefb] truncate">{r.fa}</span>
                    </span>
                  </td>
                  <td className="py-2.5 px-1 sm:px-1.5 text-center tabular-persian text-[#c9dcf1]">{r.xg != null ? fmt1(r.xg) : "—"}</td>
                  <td className="py-2.5 px-1 sm:px-1.5 text-center tabular-persian text-[#c9dcf1]">{r.xga != null ? fmt1(r.xga) : "—"}</td>
                  <td className="py-2.5 px-1 sm:px-1.5 text-center tabular-persian text-[#c9dcf1]">{r.xPts != null ? fmt1(r.xPts) : "—"}</td>
                  <td className="py-2.5 px-2 sm:px-2.5 text-center">
                    {delta == null ? (
                      <span className="text-muted-foreground">—</span>
                    ) : (
                      <span
                        className={cn(
                          "inline-block min-w-[40px] sm:min-w-[46px] px-1.5 py-0.5 rounded-md border text-[11px] font-black tabular-persian",
                          delta >= 0
                            ? "text-gold border-gold/30 bg-gold/10"
                            : "text-[#8da7c3] border-[#8da7c3]/25 bg-[#8da7c3]/10"
                        )}
                        title={delta >= 0 ? "بیش از عملکرد — امتیاز واقعی بالاتر از کیفیت موقعیت‌ها" : "کمتر از عملکرد — امتیاز واقعی پایین‌تر از کیفیت موقعیت‌ها"}
                      >
                        {delta >= 0 ? "+" : "−"}{fmt1(Math.abs(delta))}
                      </span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <p className="px-4 pb-3 pt-2 text-[10px] leading-5 text-muted-foreground">
        امتیاز x برداشت آماری فوت‌ماب از امتیازات بر پایهٔ کیفیت موقعیت‌های هر تیم است؛ اختلاف مثبت یعنی تیم بیش از آن‌چه سزاوارش بوده امتیاز گرفته و منفی یعنی کمتر.
      </p>
    </div>
  );
}

// ---------------- cycle-121: league title history («قهرمانان») ----------------
// The league's full per-season champions from the SAME cached data/leagues
// payload (top-level seasons[]: winner = champion, loser = runner-up —
// probed uniform across pl/seriea/laliga/ucl; since cycle-136 persiangulf
// serves 24 too). Newest first; the tab is hidden
// when the source has no list (legend-111 contract). Champion bold with a
// /team/ link, runner-up muted, honest legend note at the tail.
function LeagueTitles({ data }: { data: LeagueTitleHistory }) {
  return (
    <div className="glass-card overflow-hidden" data-testid="league-titles">
      <div className="grid grid-cols-[58px_1fr_1fr] items-center gap-2 px-3 sm:px-4 py-2.5 border-b border-[color:var(--glass-border-soft)] text-[9px] font-black text-steel/80">
        <span>فصل</span>
        <span className="text-start">قهرمان</span>
        <span className="text-start">نایب‌قهرمان</span>
      </div>
      {data.items.map((s, i) => (
        <div key={`${s.season}-${i}`} className={cn("grid grid-cols-[58px_1fr_1fr] items-center gap-2 px-3 sm:px-4 py-2", i % 2 ? "bg-white/[0.02]" : "")}>
          <span className="text-[10px] font-black text-steel/80 tabular-persian">{faDigits(s.season)}</span>
          {s.championId > 0 ? (
            <Link href={`/team/${s.championId}`} prefetch={false} className="tap-hit-row flex items-center gap-1.5 min-w-0 group">
              <img src={fotmobTeamLogo(s.championId)} alt="" width={16} height={16} loading="lazy" className="w-4 h-4 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
              <span className="truncate text-[11.5px] font-black group-hover:text-sky-soft transition-colors">{s.championFa}</span>
            </Link>
          ) : (
            <span className="truncate text-[11.5px] font-black">{s.championFa}</span>
          )}
          {s.runnerUpId != null && s.runnerUpFa ? (
            <Link href={`/team/${s.runnerUpId}`} prefetch={false} className="tap-hit-row flex items-center gap-1.5 min-w-0 group">
              <img src={fotmobTeamLogo(s.runnerUpId)} alt="" width={16} height={16} loading="lazy" className="w-4 h-4 object-contain shrink-0 opacity-80" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
              <span className="truncate text-[11px] font-bold text-steel/80 group-hover:text-sky-soft transition-colors">{s.runnerUpFa}</span>
            </Link>
          ) : (
            <span className="text-[11px] text-steel/80">—</span>
          )}
        </div>
      ))}
      <p className="text-[9px] text-muted-foreground px-3 sm:px-4 py-2 border-t border-[color:var(--glass-border-soft)]">
        تاریخچهٔ کامل قهرمانی به روایت فوت‌ماب — {faDigits(data.total)} فصل؛ قهرمان پررنگ و نایب‌قهرمان کم‌رنگ.
      </p>
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
  const [attempt, setAttempt] = useState(0); // «تلاش دوباره» re-runs the fetch effect
  // cycle-55: selected historical season ("2024/2025") — null = current season
  const [season, setSeason] = useState<string | null>(null);
  // cycle-99: deep-link seeding — /league/pl?season=2024/2025 opens the
  // historical view directly. The API family has honored &season= since
  // cycle-55 but the page never read the URL param, so a shared or bookmarked
  // season link silently showed the current season. Seeding is client-only
  // (static shell + client fetch by design) and gated on `seeded` so a deep
  // link performs exactly ONE fetch with the right season.
  const [seeded, setSeeded] = useState(false);
  // cycle-56: cup knockout bracket (null → tab hidden for domestic leagues)
  const [bracket, setBracket] = useState<LeagueBracketData | null>(null);
  // cycle-57: current-season transfers (null → tab hidden; historical seasons unsupported by the source)
  const [transfers, setTransfers] = useState<LeagueTransfersData | null>(null);
  // cycle-121: full title history («قهرمانان») — season-independent, so the
  // tab shows on historical views too (null → tab hidden)
  const [titles, setTitles] = useState<LeagueTitleHistory | null>(null);

  // cycle-99: read the deep-linked season once on mount — strict SEASON_PARAM_RE
  // shape (same guard as the API routes); anything else is ignored and the
  // current season loads. Probed upstream contract (cycle-99): a well-formed
  // season the league does not offer is silently served as the CURRENT season
  // (200 + payload marker selectedSeason=actual) — the honesty snap inside the
  // fetch effect keeps the selector consistent with what is actually shown.
  useEffect(() => {
    if (seeded) return;
    setSeeded(true);
    try {
      const raw = new URLSearchParams(window.location.search).get("season");
      if (raw && SEASON_PARAM_RE.test(raw)) setSeason(raw);
    } catch { /* no window — ignore */ }
  }, [seeded]);

  useEffect(() => {
    if (!seeded) return; // cycle-99: wait for the URL seed pass (one fetch per deep link)
    let cancelled = false;
    setLoading(true);
    setError(null);
    setBracket(null);
    setTransfers(null);
    setTitles(null);
    (async () => {
      try {
        const sp = season ? `&season=${encodeURIComponent(season)}` : "";
        // cycle-57: transfers feed is current-season only (probed) — fetched
        // without the season param and skipped entirely in historical views
        // cycle-123 FIX (FINDING-1, hunted in cycle-122, blame 89ee488c): the
        // conditional transfers spread used to sit BEFORE the titles fetch,
        // shifting every later element left on historic views — the 5-way
        // destructure then read tiRes at a fixed index and got undefined →
        // TypeError at tiRes.status → catch → false «ارتباط برقرار نشد.»
        // banner + «قهرمانان» tab never rendered (setTitles unreached) while
        // the data itself loaded fine. Invariant since this fix: season-
        // independent fetches own FIXED slots BEFORE any conditional spread;
        // conditional elements go LAST; every positional result beyond the
        // first three is optional-chained so a future reorder degrades to the
        // honest hidden-surface (legend-111), never a false error banner.
        const [stRes, fxRes, brRes, tiRes, trRes] = await Promise.allSettled([
          fetch(`/api/standings?league=${leagueKey}${sp}`, { cache: "no-store" }).then((r) => r.json()),
          fetch(`/api/league-fixtures?league=${leagueKey}${sp}`, { cache: "no-store" }).then((r) => r.json()),
          fetch(`/api/league-bracket?league=${leagueKey}${sp}`, { cache: "no-store" }).then((r) => r.json()),
          // cycle-121: title history is season-independent — fetched without
          // the season param (same cached raw as the current-season reads)
          fetch(`/api/league-titles?league=${leagueKey}`, { cache: "no-store" }).then((r) => r.json()),
          ...(season ? [] : [fetch(`/api/league-transfers?league=${leagueKey}`, { cache: "no-store" }).then((r) => r.json())]),
        ]);
        if (cancelled) return;
        if (stRes.status === "fulfilled" && stRes.value.ok) setStandings(stRes.value as StandingsData);
        // cycle-99 honesty snap: upstream serves the CURRENT season for a
        // well-formed season it does not offer (live-probed fallback contract:
        // 200, table = current rows, marker selectedSeason = actual season).
        // When the payload's own marker disagrees with the requested season,
        // snap the selector back to the current season and strip the stale
        // URL param so selector, label and URL never contradict the data on
        // screen. One extra fetch only in this bogus-param case.
        if (stRes.status === "fulfilled" && stRes.value.ok) {
          const sel = (stRes.value as StandingsData).selectedSeason;
          if (season && sel && sel !== season) {
            setSeason(null);
            try {
              const usp = new URLSearchParams(window.location.search);
              usp.delete("season");
              const qs = usp.toString();
              window.history.replaceState(null, "", `${window.location.pathname}${qs ? `?${qs}` : ""}`);
            } catch { /* ignore */ }
          }
        }
        if (fxRes.status === "fulfilled" && fxRes.value.ok) setFixtures(fxRes.value as LeagueFixturesData);
        if (brRes.status === "fulfilled" && brRes.value.ok && brRes.value.bracket) {
          setBracket(brRes.value.bracket as LeagueBracketData);
        }
        if (trRes?.status === "fulfilled" && trRes.value.ok && trRes.value.transfers) {
          setTransfers(trRes.value.transfers as LeagueTransfersData);
        }
        // cycle-123: tiRes?. — belt-and-suspenders symmetric with trRes (see
        // the invariant comment above): a future positional hazard must
        // degrade to a hidden tab, never to the false error banner
        if (tiRes?.status === "fulfilled" && tiRes.value.ok && tiRes.value.titles) {
          setTitles(tiRes.value.titles as LeagueTitleHistory);
        }
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
  }, [leagueKey, attempt, season, seeded]);

  if (!lg) {
    return (
      <EmptyState
        icon="search"
        title="لیگ مورد نظر یافت نشد"
        sub="کلید لیگ نامعتبر است؛ از میان لیگ‌های پرطرفدار یکی را انتخاب کنید."
        action={{ label: "مشاهده‌ی لیگ‌ها", href: "/leagues" }}
      />
    );
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

  // cycle-55: season label follows the payload's own selected-season marker
  const shownSeason = standings?.selectedSeason || standings?.season || "";
  const allSeasons = standings?.allSeasons || [];
  // cycle-99: a deep-linked season upstream really serves (payload marker
  // matches the request) but that sits outside the selector's 12-season cap
  // (e.g. 2013/2014 — upstream offers 17) is appended so the selector never
  // contradicts the data on screen; bogus seasons were already snapped back
  // in the fetch effect's honesty snap. Plain derivation (no hook — this runs
  // after the `if (!lg)` early return, so hooks are not allowed here).
  const seasonOptions =
    season && standings?.selectedSeason === season && !allSeasons.includes(season)
      ? [...allSeasons, season]
      : allSeasons;
  // cycle-99: selector changes update the URL in place (replaceState — no
  // history entries, no navigation) so a copied link carries the exact season
  // being viewed; any other query params are preserved as-is.
  const applySeason = (s: string | null) => {
    setSeason(s);
    // transfers tab only exists in current-season views — fall back to standings
    setTab((t) => (s !== null && t === "transfers" ? "standings" : t));
    try {
      const usp = new URLSearchParams(window.location.search);
      if (s) usp.set("season", s);
      else usp.delete("season");
      const qs = usp.toString();
      window.history.replaceState(null, "", `${window.location.pathname}${qs ? `?${qs}` : ""}`);
    } catch { /* ignore */ }
  };
  // cycle-56: «براکت» tab appears only when the payload really has playoff rounds
  const visibleTabs: { key: Tab; label: string }[] = [
    ...TABS,
    ...(bracket ? [{ key: "bracket" as Tab, label: "براکت" }] : []),
    ...(titles ? [{ key: "titles" as Tab, label: "قهرمانان" }] : []),
    ...(transfers && !season ? [{ key: "transfers" as Tab, label: "انتقال‌ها" }] : []),
  ];

  return (
    <div className="flex flex-col gap-4">
      <JsonLd data={standingsLd} />
      {/* league header */}
      <div className="flex items-center justify-between gap-3 px-1">
        <div>
          <h1 className="text-lg font-black">{lg.faName}</h1>
          <p className="text-[11px] text-muted-foreground">
            {shownSeason && <>فصل {faDigits(shownSeason)} · </>}
            {fixtures && <>در مجموع {faDigits(fixtures.total)} بازی</>}
          </p>
        </div>
        <span className="text-[10px] font-bold text-[#b6cce3] border border-[color:var(--glass-border-soft)] bg-white/[0.03] rounded-lg px-2 py-1">
          {lg.ccode3}
        </span>
      </div>

      {/* cycle-55: season selector — options come from the payload itself, so
          leagues without a season list simply hide the control */}
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
              const s = e.target.value === allSeasons[0] ? null : e.target.value;
              applySeason(s);
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

      {/* current-week progress (hidden for cup/non-numeric rounds or missing data) */}
      {fixtures?.progress && <SeasonProgress progress={fixtures.progress} />}

      {/* pre-match preview for today's fixtures (no extra network calls) */}
      <PreMatchPreview fixtures={fixtures?.upcoming || []} standings={standings} />

      {/* tabs */}
      <nav className="flex items-center gap-1 overflow-x-auto border-b border-[color:var(--glass-border-soft)] -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" aria-label="بخش‌های لیگ">
        {visibleTabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            aria-current={tab === t.key ? "page" : undefined}
            className={cn(
              "relative px-3.5 py-2 text-[12.5px] font-bold whitespace-nowrap transition-colors press-fx tab-rune",
              tab === t.key ? "text-sky-soft" : "text-muted-foreground hover:text-foreground"
            )}
          >
            {t.label}
          </button>
        ))}
      </nav>

      {error && (
        <div className="glass-card border-rose-soft/25 text-rose-soft text-sm px-4 py-3 flex items-center justify-between gap-3 flex-wrap">
          <span>{error}</span>
          <button
            type="button"
            onClick={() => setAttempt((a) => a + 1)}
            className="text-xs font-bold underline underline-offset-4 cursor-pointer"
          >
            تلاش دوباره
          </button>
        </div>
      )}

      {loading && !standings && !fixtures ? (
        <div className="glass-card p-4 flex flex-col gap-3" aria-busy="true">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="h-4 rounded bg-white/[0.06] animate-pulse" style={{ width: `${40 + ((i * 17) % 45)}%` }} />
          ))}
        </div>
      ) : loading && season != null ? (
        /* ui-cycle-9 (BL-9): season-switch skeleton. The old season's table
           used to stay on screen dimmed to opacity-50 while the new season
           fetched — rows of ۲۰۲۴/۲۰۲۵ impersonating the selected «فصل
           ۲۰۲۳/۲۰۲۴», with only a 10px «در حال بارگذاری…» hint. A real
           table-shaped skeleton (rank chip + name bar + RTL-aligned number
           bars, aria-busy) now owns the content area until the payload
           lands, so the label and the rows on screen can never disagree. */
        <div className="flex flex-col gap-4" aria-busy="true">
          <div className="glass-card p-4 flex flex-col gap-2.5">
            {Array.from({ length: 10 }).map((_, i) => (
              <div key={i} className="flex items-center gap-3 animate-pulse">
                <div className="w-6 h-6 rounded-md bg-white/[0.07] shrink-0" />
                <div className="h-3.5 rounded bg-white/[0.06]" style={{ width: `${30 + ((i * 23) % 40)}%` }} />
                <div className="ms-auto flex gap-2 shrink-0">
                  <div className="w-8 h-3.5 rounded bg-white/[0.05]" />
                  <div className="w-8 h-3.5 rounded bg-white/[0.05]" />
                  <div className="w-8 h-3.5 rounded bg-white/[0.05]" />
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className={cn("transition-opacity", loading && "opacity-50")}>
          {tab === "standings" && (standings ? (
            <div className="grid gap-4 lg:grid-cols-[1fr_300px] lg:items-start">
              <div className="grid gap-4 min-w-0">
                {/* cycle-114: honest notice when the table is served from the
                    last-known-good snapshot after an upstream outage (cycle-43 pattern) */}
                {standings.stale && (
                  <div
                    role="status"
                    className="rounded-xl border border-chart-2/30 bg-chart-2/10 text-chart-2 px-4 py-2.5 flex items-center gap-2 text-[11.5px] font-bold"
                  >
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="shrink-0" aria-hidden>
                      <circle cx="12" cy="12" r="9" />
                      <path d="M12 7v5l3 2" />
                    </svg>
                    نمایش آخرین داده‌های ذخیره‌شده — نسخه زنده به‌زودی به‌روزرسانی می‌شود.
                  </div>
                )}
                <StandingsTable key={`${leagueKey}:${standings.selectedSeason || season || "cur"}`} data={standings} league={lg} />
                {/* cycle-90: expected-goals mirror table — hidden when the source has no xG variant */}
                <XgTable rows={standings.rows} />
              </div>
              {standings.scorers?.length > 0 && <ScorersList data={standings} leagueKey={lg.key} />}
            </div>
          ) : <EmptyState icon="trophy" compact title="جدولی برای این لیگ ثبت نشده است" sub="رده‌بندی پس از انتشار داده‌ی فصل از سوی منبع نمایش داده می‌شود." />)}
          {tab === "stats" && (
            <div className="flex flex-col gap-4">
              {standings?.boards && standings.boards.length > 0 && (
                <SeasonBoards
                  boards={standings.boards}
                  season={(standings.selectedSeason || standings.season) ? `فصل ${faDigits(standings.selectedSeason || standings.season)}` : undefined}
                />
              )}
              {fixtures?.stats ? (
                <StatsPanel stats={fixtures.stats} leagueFa={lg.faName} />
              ) : (
                <EmptyState icon="ball" compact title="آماری برای این لیگ ثبت نشده است" sub="آمار فصل از بازی‌های پایان‌یافته محاسبه می‌شود." />
              )}
            </div>
          )}
          {tab === "fixtures" && <FixtureList items={fixtures?.upcoming || []} showResult={false} dateGrouped />}
          {tab === "recent" && <FixtureList items={fixtures?.recent || []} showResult />}
          {tab === "scorers" && (standings ? <ScorersList data={standings} leagueKey={lg.key} /> : <EmptyState icon="medal" compact title="داده گلزنان در دسترس نیست" sub="ابتدا جدول لیگ بارگیری شود تا آقای گل نیز نمایش داده شود." />)}
          {tab === "bracket" && (bracket ? <LeagueBracket data={bracket} /> : null)}
          {tab === "titles" && (titles ? <LeagueTitles data={titles} /> : null)}
          {tab === "transfers" && (transfers ? <LeagueTransfersList data={transfers} /> : null)}
        </div>
      )}
    </div>
  );
}
