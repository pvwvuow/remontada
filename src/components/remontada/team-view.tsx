"use client";

// ------------------------------------------------------------------
// Remontada — team page: profile + season stats + standings row +
// recent (with venue & round) + upcoming. Cycle 10 enriched.
// ------------------------------------------------------------------
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import type { NormMatch, TeamRowInfo, TeamSeasonStats, TeamFormMatch } from "@/lib/fotmob";
import { faDigits, jalaliShort, tehranDateLong, tehranTime } from "@/lib/format";
import { FavoriteStar } from "@/components/remontada/favorite-star";
import { cn } from "@/lib/utils";

interface TeamData {
  ok: boolean;
  team: { id: number; name: string; fa: string; logo: string };
  standings: TeamRowInfo | null;
  season?: TeamSeasonStats | null;
  live: NormMatch[];
  recent: (NormMatch & { round?: string })[];
  upcoming: NormMatch[];
  error?: string;
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
  if (c === "W") return "bg-primary/15 text-primary border-primary/30";
  if (c === "D") return "bg-muted text-muted-foreground border-border";
  return "bg-destructive/15 text-destructive border-destructive/30";
}

/** tick state for live countdowns — 30s cadence, minute precision */
function useCountdown(iso?: string): { days: number; hours: number; minutes: number } | null {
  const [now, setNow] = useState<number | null>(null);
  useEffect(() => {
    if (!iso) return;
    setNow(Date.now());
    const iv = setInterval(() => setNow(Date.now()), 30_000);
    return () => clearInterval(iv);
  }, [iso]);
  if (!iso || now == null) return null;
  const diff = new Date(iso).getTime() - now;
  if (Number.isNaN(diff) || diff <= 0) return { days: 0, hours: 0, minutes: 0 };
  const mins = Math.floor(diff / 60_000);
  return { days: Math.floor(mins / 1440), hours: Math.floor((mins % 1440) / 60), minutes: mins % 60 };
}

function SegBox({ v, l }: { v: number; l: string }) {
  return (
    <div className="rounded-xl border border-primary/25 bg-primary/10 px-2.5 py-1.5 text-center min-w-[48px]">
      <p className="text-[15px] font-black tabular-persian text-primary leading-none">{faDigits(String(v).padStart(2, "0"))}</p>
      <p className="text-[8.5px] font-bold text-muted-foreground mt-1">{l}</p>
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
      className="block rounded-2xl border border-primary/25 bg-gradient-to-l from-primary/[0.12] via-card/70 to-card/40 overflow-hidden hover:border-primary/50 transition-colors"
    >
      <div className="px-4 py-2 border-b border-primary/15 bg-primary/[0.08] flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black text-primary">بازی بعدی</h2>
        <span className="text-[10px] font-bold text-muted-foreground truncate">
          {m.leagueFa}{m.round ? ` · ${faRound(m.round)}` : ""}
        </span>
      </div>
      <div className="p-4 flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-4">
        <div className="flex items-center gap-2.5 min-w-0 flex-1">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={us.logo} alt="" width={30} height={30} loading="lazy" className="w-[30px] h-[30px] object-contain shrink-0 opacity-80" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <span className="text-[10px] font-bold text-muted-foreground shrink-0">در برابر</span>
          {/* eslint-disable-next-line @next/next/no-img-element */}
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
              isHome ? "bg-primary/10 text-primary border-primary/20" : "bg-sky-500/10 text-sky-500 border-sky-500/20"
            )}
          >
            {isHome ? "خانه" : "بیرون"}
          </span>
        </div>
        {cd ? (
          <div className="flex items-center gap-1.5 shrink-0" role="timer" aria-label="شمارش معکوس تا شروع بازی">
            <SegBox v={cd.days} l="روز" />
            <SegBox v={cd.hours} l="ساعت" />
            <SegBox v={cd.minutes} l="دقیقه" />
          </div>
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
            isHome ? "bg-primary/10 text-primary border-primary/20" : "bg-sky-500/10 text-sky-500 border-sky-500/20"
          )}
        >
          {isHome ? "خانه" : "بیرون"}
        </span>
        <span className="truncate font-black">{opponent.fa || opponent.name}</span>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={opponent.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
      </div>
      {/* score / result */}
      <div className="flex justify-end">
        {label === "upcoming" && !m.started ? (
          <span className="text-[10px] text-muted-foreground/70 font-bold">پیش‌رو</span>
        ) : (
          <div className="flex items-center gap-1.5">
            {m.started && !m.cancelled && (
              <span className="font-black text-[13px] tabular-persian bg-muted/60 rounded-lg px-2 py-0.5">
                {isHome ? m.home.score ?? "—" : m.away.score ?? "—"} : {isHome ? m.away.score ?? "—" : m.home.score ?? "—"}
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
    <Link href={`/match/${m.id}`} className="hover:bg-accent/40 transition-colors block" prefetch={false}>
      {inner}
    </Link>
  );
}

function Section({ title, children, extra }: { title: string; children: React.ReactNode; extra?: React.ReactNode }) {
  return (
    <section className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black">{title}</h2>
        {extra}
      </header>
      <div className="divide-y divide-border/25">{children}</div>
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
      <div className="flex h-1.5 rounded-full overflow-hidden bg-muted">
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
        "flex-1 min-w-0 rounded-xl border px-3 py-2.5 transition-colors hover:bg-accent/40",
        tone === "win" ? "border-primary/25 bg-primary/5" : "border-destructive/25 bg-destructive/5"
      )}
      prefetch={false}
    >
      <p className={cn("text-[9.5px] font-black mb-1", tone === "win" ? "text-primary" : "text-destructive")}>{title}</p>
      <div className="flex items-center gap-2 min-w-0">
        {/* eslint-disable-next-line @next/next/no-img-element */}
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
    <section className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 flex items-center justify-between gap-2">
        <h2 className="text-[12.5px] font-black">آمار فصل</h2>
        <Link href={`/league/${s.leagueKey}`} className="text-[10px] font-bold text-muted-foreground hover:text-primary transition-colors">
          {s.leagueFa}{s.season ? ` · فصل ${faDigits(s.season)}` : ""}
        </Link>
      </header>
      <div className="p-4 flex flex-col gap-4">
        {/* KPI grid */}
        <div className="grid grid-cols-4 gap-2">
          {kpis.map((k) => (
            <div key={k.l} className="rounded-xl border border-border/50 bg-muted/25 px-2 py-2.5 text-center">
              <p className="text-[9px] text-muted-foreground font-bold">{k.l}</p>
              <p className="text-base font-black tabular-persian leading-tight mt-0.5">{k.v}</p>
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

export function TeamView({ teamId }: { teamId: number }) {
  const [data, setData] = useState<TeamData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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
        <div className="rounded-2xl border border-border/60 bg-card/40 p-8 flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded bg-muted animate-pulse" />
          <div className="h-5 w-40 rounded bg-muted animate-pulse" />
          <div className="h-3 w-24 rounded bg-muted animate-pulse" />
        </div>
        <div className="h-40 rounded-2xl border border-border/60 bg-card/40 animate-pulse" />
      </div>
    );
  }

  if (error && !data) {
    return (
      <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-5 py-8 text-center">
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
      <section className="rounded-2xl border border-border/60 bg-card/70 overflow-hidden">
        <div className="p-5 flex items-center gap-4">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={data.team.logo} alt="" width={64} height={64} className="w-16 h-16 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2 min-w-0">
              <h1 className="text-xl font-black truncate">{data.team.fa || data.team.name}</h1>
              <FavoriteStar
                team={{ id: teamId, fa: data.team.fa || data.team.name, en: data.team.name }}
                size={20}
              />
            </div>
            {st ? (
              <p className="text-[11px] text-muted-foreground mt-0.5">
                <Link href={`/league/${st.leagueKey}`} className="hover:text-primary transition-colors font-bold">
                  {st.leagueFa}
                </Link>
                {" · "}
                رتبه {faDigits(st.rank)} با {faDigits(st.pts)} امتیاز
              </p>
            ) : season ? (
              <p className="text-[11px] text-muted-foreground mt-0.5">
                <Link href={`/league/${season.leagueKey}`} className="hover:text-primary transition-colors font-bold">
                  {season.leagueFa}
                </Link>
                {season.season ? ` · فصل ${faDigits(season.season)}` : ""}
              </p>
            ) : (
              <p className="text-[11px] text-muted-foreground mt-0.5">اطلاعات لیگ یافت نشد</p>
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
                <div key={x.l} className="rounded-xl border border-border/50 bg-muted/30 px-3 py-2">
                  <p className="text-[9px] text-muted-foreground font-bold">{x.l}</p>
                  <p className="text-sm font-black tabular-persian">{typeof x.v === "number" ? faDigits(x.v) : x.v}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* next match + live countdown */}
      {data.upcoming.length > 0 && <NextMatchCard m={data.upcoming[0]} teamId={teamId} />}

      {/* season stats */}
      {season && season.played > 0 && <SeasonPanel s={season} />}

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
          <p className="text-center text-muted-foreground text-sm py-6">در ۱۰ روز آینده بازی‌ای ثبت نشده است.</p>
        )}
      </Section>

      <Section title="نتایج اخیر">
        {data.recent.length > 0 ? (
          data.recent.map((m) => <TeamMatchRow key={m.id} m={m} teamId={teamId} label="recent" />)
        ) : (
          <p className="text-center text-muted-foreground text-sm py-6">بازی پایان‌یافته‌ای در بازه‌ی اخیر یافت نشد.</p>
        )}
      </Section>

      <p className="text-[10px] text-muted-foreground px-1 text-center">
        نتایج از فید روزانه‌ی FotMob و آمار فصل از فیکسچرهای لیگ تجمیع شده است.
      </p>
    </div>
  );
}
