"use client";

// ------------------------------------------------------------------
// Remontada — team page: profile + standings row + recent + upcoming
// ------------------------------------------------------------------
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import type { NormMatch, TeamRowInfo } from "@/lib/fotmob";
import { faDigits, jalaliShort, tehranTime } from "@/lib/format";
import { cn } from "@/lib/utils";

interface TeamData {
  ok: boolean;
  team: { id: number; name: string; fa: string; logo: string };
  standings: TeamRowInfo | null;
  live: NormMatch[];
  recent: NormMatch[];
  upcoming: NormMatch[];
  error?: string;
}

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

function TeamMatchRow({ m, teamId, label }: { m: NormMatch; teamId: number; label: "recent" | "upcoming" }) {
  const isHome = m.home.id === teamId;
  const opponent = isHome ? m.away : m.home;
  const res = m.started && !m.cancelled ? resultOf(m, teamId) : null;
  const j = jalaliShort(m.utcTime);

  const inner = (
    <div className="grid grid-cols-[44px_1fr_auto] items-center gap-2.5 px-3 sm:px-4 py-3">
      {/* date/time */}
      <div className="flex flex-col items-center">
        {m.live ? (
          <span className="text-[10px] font-black text-red-400 tabular-persian flex items-center gap-1">
            <span className="live-dot w-1 h-1 rounded-full bg-red-500 inline-block" />
            زنده
          </span>
        ) : m.finished ? (
          <span className="text-[10px] font-bold text-muted-foreground">پایان</span>
        ) : (
          <>
            <span className="text-[10px] font-bold text-muted-foreground">{j.weekday.slice(0, 6)}</span>
            <span className="text-[11px] font-black text-foreground/85 tabular-persian">{tehranTime(m.utcTime)}</span>
          </>
        )}
      </div>
      {/* teams */}
      <div className="flex items-center justify-end gap-2 min-w-0 text-[13px]">
        <span className={cn("truncate", isHome ? "font-black" : "font-semibold text-foreground/75")}>
          {isHome ? m.home.fa || m.home.name : m.away.fa || m.away.name}
        </span>
        <span className="text-[10px] text-muted-foreground/60 font-bold shrink-0">در برابر</span>
        <span className={cn("truncate", !isHome ? "font-black" : "font-semibold text-foreground/75")}>
          {opponent.fa || opponent.name}
        </span>
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
              <span className={cn("w-5.5 h-5.5 w-[22px] h-[22px] rounded-md border text-[10px] font-black flex items-center justify-center", formChip(res))}>
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

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25">
        <h2 className="text-[12.5px] font-black">{title}</h2>
      </header>
      <div className="divide-y divide-border/25">{children}</div>
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
  const recentForm = data.recent.slice(0, 5).map((m) => resultOf(m, teamId));

  return (
    <div className="flex flex-col gap-4">
      {/* profile header */}
      <section className="rounded-2xl border border-border/60 bg-card/70 overflow-hidden">
        <div className="p-5 flex items-center gap-4">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={data.team.logo} alt="" width={64} height={64} className="w-16 h-16 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <div className="min-w-0 flex-1">
            <h1 className="text-xl font-black truncate">{data.team.fa || data.team.name}</h1>
            {st ? (
              <p className="text-[11px] text-muted-foreground mt-0.5">
                <Link href={`/league/${st.leagueKey}`} className="hover:text-primary transition-colors font-bold">
                  {st.leagueFa}
                </Link>
                {" · "}
                رتبه {faDigits(st.rank)} با {faDigits(st.pts)} امتیاز
              </p>
            ) : (
              <p className="text-[11px] text-muted-foreground mt-0.5">اطلاعات لیگ یافت نشد</p>
            )}
            {recentForm.length > 0 && (
              <div className="flex items-center gap-1.5 mt-2">
                <span className="text-[10px] text-muted-foreground font-bold">فرم اخیر:</span>
                {recentForm.map((f, i) => (
                  <span key={i} className={cn("w-[20px] h-[20px] rounded-md border text-[9px] font-black flex items-center justify-center", formChip(f))}>
                    {f === "W" ? "ب" : f === "D" ? "م" : "پ"}
                  </span>
                ))}
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
        نتایج و برنامه از بازی‌های روزانه‌ی FotMob تجمیع شده است (۳ روز گذشته تا ۱۰ روز آینده).
      </p>
    </div>
  );
}
