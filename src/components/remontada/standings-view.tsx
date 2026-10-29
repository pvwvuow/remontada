"use client";

// ------------------------------------------------------------------
// Remontada — league standings + top scorers view
// Phase 3 theme: glass statistics poster (studio table/scorers look)
// ------------------------------------------------------------------
import Link from "next/link";
import { Fragment, useState } from "react";
import { LEAGUES } from "@/lib/leagues";
import type { StandingsData } from "@/lib/fotmob";
import { FavoriteStar } from "@/components/remontada/favorite-star";
import { EmptyState } from "@/components/remontada/empty-state";
import { GlassLeagueHeader, GlassPosterMeta, pad2 } from "@/components/remontada/glass-stats";
import { PlayerPhoto } from "@/components/remontada/player-photo";
import { TableModeSwitch, type TableMode } from "@/components/remontada/table-mode";
import { faDigits, formColor, timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";

function QualBar({ color }: { color?: string }) {
  if (!color) return null;
  return <span className="absolute inset-y-1 right-0 w-[3px] rounded-full" style={{ backgroundColor: color }} aria-hidden />;
}

/** Last-5 league form chips (ب/م/پ) — desktop inline, next to team name. */
function FormChips({ form }: { form?: ("W" | "D" | "L")[] }) {
  if (!form || form.length === 0) return null;
  return (
    <span className="hidden md:flex items-center gap-[3px] shrink-0 ms-1" title="۵ بازی آخر در لیگ (از قدیم به جدید)">
      {form.map((c, i) => (
        <span
          key={i}
          className={cn(
            "w-[13px] h-[13px] rounded-[3px] border text-[7.5px] font-black flex items-center justify-center leading-none",
            formColor(c)
          )}
        >
          {c === "W" ? "ب" : c === "D" ? "م" : "پ"}
        </span>
      ))}
    </span>
  );
}

/** Compact form dots under the team name — mobile only. */
function FormDots({ form }: { form?: ("W" | "D" | "L")[] }) {
  if (!form || form.length === 0) return null;
  return (
    <span className="flex md:hidden items-center gap-[2.5px] mt-[3px]" title="۵ بازی آخر در لیگ (از قدیم به جدید)">
      {form.map((c, i) => (
        <span
          key={i}
          className={cn(
            "w-[7px] h-[7px] rounded-[2px] leading-none",
            c === "W" ? "bg-primary/70" : c === "D" ? "bg-muted-foreground/40" : "bg-destructive/70"
          )}
        />
      ))}
    </span>
  );
}

function StandingsTable({ data, leagueKey }: { data: StandingsData; leagueKey: string }) {
  const lg = LEAGUES.find((l) => l.key === leagueKey);
  // cycle-52: internal mode state — StandingsView keys this component by
  // leagueKey, so switching league remounts and resets to «کل فصل» cleanly
  const [mode, setMode] = useState<TableMode>("all");
  // same additive per-side rows; switch only when both splits exist
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
        leagueId={lg?.fotmobId}
        titleTag="h2"
        title={data.leagueFa}
        sub={lg ? `${lg.ccode3} · ${lg.enName}` : undefined}
        season={data.season ? `فصل ${faDigits(data.season)}` : undefined}
      />
      <GlassPosterMeta right={modeLabel} left={data.rows.length ? `${faDigits(data.rows.length)} تیم${data.updatedAt ? ` · به‌روزرسانی ${timeAgoFa(data.updatedAt)}` : ""}` : undefined} />
      {hasSides && (
        <div className="px-4 pb-2.5">
          <TableModeSwitch mode={mode} onChange={setMode} />
        </div>
      )}
      <div className="overflow-x-auto">
        <table className="w-full text-[12px] sm:text-[13px] min-w-[520px]">
          <thead>
            <tr className="glass-thead text-[9px] sm:text-[10px] border-y border-[color:var(--glass-hairline)] text-[#b6cce3]">
              <th className="py-2 pe-1 ps-3 font-bold text-start w-9">#</th>
              <th className="py-2 px-1 font-bold text-start">تیم</th>
              <th className="py-2 px-1.5 font-bold text-center" title="بازی">ب</th>
              <th className="py-2 px-1.5 font-bold text-center" title="برد">بر</th>
              <th className="py-2 px-1.5 font-bold text-center" title="مساوی">مس</th>
              <th className="py-2 px-1.5 font-bold text-center" title="باخت">با</th>
              <th className="py-2 px-1.5 font-bold text-center hidden sm:table-cell" title="گل زده">گز</th>
              <th className="py-2 px-1.5 font-bold text-center hidden sm:table-cell" title="گل خورده">گخ</th>
              <th className="py-2 px-1.5 font-bold text-center" title="تفاضل گل">تف</th>
              <th className="py-2 px-2.5 font-black text-center text-[#d6e8fb]" title="امتیاز">امتیاز</th>
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
                  style={{ animationDelay: `${Math.min(i * 28, 560)}ms` }}
                  className={cn(
                    "sb-row-in border-b border-[color:var(--glass-hairline)] last:border-0 glass-row-hover transition-colors relative",
                    leader && "glass-leader"
                  )}
                >
                  <td className="py-2.5 pe-1 ps-3 relative">
                    <QualBar color={r.qualColor || undefined} />
                    {/* cycle-64: podium medallions — the scoreboard moment */}
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
                  <td className="py-2 px-1">
                    <div className="flex items-center gap-0.5 min-w-0">
                      <Link
                        href={`/team/${r.teamId}`}
                        className="flex items-center gap-2 min-w-0 flex-1 rounded-lg px-1 -mx-1 py-0.5 hover:bg-primary/10 transition-colors group"
                        prefetch={false}
                      >
                        <img
                          src={r.logo}
                          alt=""
                          width={18}
                          height={18}
                          loading="lazy"
                          className="w-[18px] h-[18px] object-contain shrink-0"
                          onError={(e) => {
                            e.currentTarget.style.visibility = "hidden";
                          }}
                        />
                        <span className="min-w-0 flex flex-col">
                          <span className={cn("font-bold truncate group-hover:text-primary transition-colors inline-flex items-center gap-1", leader && "text-[#f1f7ff]")}>
                            {/* cycle-64: the leader wears the crown */}
                            {leader && (
                              <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" className="text-gold shrink-0" aria-label="صدرنشین">
                                <path d="M3 8l4.5 3L12 5l4.5 6L21 8l-1.6 9H4.6L3 8z" />
                              </svg>
                            )}
                            {r.fa || r.name}
                          </span>
                          <FormDots form={r.form} />
                        </span>
                      </Link>
                      <FavoriteStar
                        team={{ id: r.teamId, fa: r.fa || r.name, en: r.name }}
                        size={13}
                        className="opacity-70 hover:opacity-100"
                      />
                      <FormChips form={r.form} />
                    </div>
                  </td>
                  <td className="py-2 px-1.5 text-center tabular-persian text-[#b4c8df]/70">{faDigits(r.played)}</td>
                  <td className="py-2 px-1.5 text-center tabular-persian text-[#c3d4ea]">{faDigits(r.wins)}</td>
                  <td className="py-2 px-1.5 text-center tabular-persian text-[#b4c8df]/70">{faDigits(r.draws)}</td>
                  <td className="py-2 px-1.5 text-center tabular-persian text-[#b4c8df]/70">{faDigits(r.losses)}</td>
                  <td className="py-2 px-1.5 text-center tabular-persian text-[#b4c8df]/70 hidden sm:table-cell">{faDigits(r.goalsFor)}</td>
                  <td className="py-2 px-1.5 text-center tabular-persian text-[#b4c8df]/70 hidden sm:table-cell">{faDigits(r.goalsAgainst)}</td>
                  <td className="py-2 px-1.5 text-center tabular-persian">
                    <span className={cn(r.gd > 0 ? "text-mint" : r.gd < 0 ? "text-rose-soft" : "text-[#8da7c3]/80")}>
                      {r.gd > 0 ? `+${faDigits(r.gd)}` : faDigits(r.gd)}
                    </span>
                  </td>
                  <td className="py-2 px-2.5 text-center">
                    <span
                      className={cn(
                        "font-black tabular-persian rounded-lg px-2 py-0.5 inline-block min-w-[34px]",
                        leader
                          ? "text-[#f6efdc] bg-[#e3c7671f] shadow-[0_0_12px_oklch(0.84_0.12_85/0.22)]"
                          : "text-[#e4eefb] bg-[#9ec3e50b]"
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
      {data.legend && data.legend.length > 0 && (
        <div
          className="px-3.5 py-2.5 border-t border-[color:var(--glass-hairline)] flex flex-wrap items-center gap-x-4 gap-y-1.5"
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

function ScorersCard({ data }: { data: StandingsData }) {
  const list = data.scorers;
  if (!list || list.length === 0) return null;
  const [top, ...rest] = list;
  return (
    <div className="glass-card overflow-hidden">
      <header className="flex items-center gap-2 px-4 py-3 border-b border-[color:var(--glass-hairline)]">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className="text-chart-3" aria-hidden>
          <circle cx="12" cy="8" r="5" />
          <path d="M8.5 12.5L7 22l5-3 5 3-1.5-9.5" />
        </svg>
        <h3 className="font-black text-sm">آقای گل</h3>
        <span className="ms-auto text-[10px] text-steel">{data.leagueFa}</span>
      </header>
      <div className="p-2.5 flex flex-col">
        {/* mini hero — the studio scoring-chart leader tile */}
        <div className="glass-scorer-hero p-3 flex items-center gap-3">
          <PlayerPhoto id={top.playerId} name={top.nameFa || top.name} size={46} rounded="rounded-xl" />
          <div className="min-w-0 flex-1">
            <p className="text-[8px] font-bold tracking-[0.24em] text-[#9dbad8] uppercase">LEAGUE LEADER</p>
            {top.playerId ? (
              <Link
                href={`/player/${top.playerId}`}
                prefetch={false}
                className="block text-[13px] font-bold text-[#f1f7fd] truncate mt-0.5 hover:text-primary transition-colors w-fit max-w-full"
                title={top.nameFa && top.nameFa !== top.name ? top.name : `پروفایل ${top.name}`}
              >
                {top.nameFa || top.name}
              </Link>
            ) : (
              <p className="text-[13px] font-bold text-[#f1f7fd] truncate mt-0.5">{top.nameFa || top.name}</p>
            )}
            {top.team && <p className="text-[9.5px] text-[#92adc9] truncate mt-0.5">{top.team}</p>}
          </div>
          <div className="text-center shrink-0 ps-1">
            <p className="text-[28px] leading-none font-light text-[#dfedff] tabular-persian">{faDigits(pad2(top.goals))}</p>
            <p className="text-[8px] font-bold text-[#c6dcf3] mt-1">گل</p>
          </div>
        </div>
        <ol className="mt-1 flex flex-col">
          {rest.map((s, i) => {
            const rank = s.rank ?? i + 2;
            const inner = (
              <>
                <span className="w-6 h-6 rounded-md bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10px] font-bold shrink-0 tabular-persian">
                  {faDigits(pad2(rank))}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[12px] font-bold text-[#e5eefb] truncate">{s.nameFa || s.name}</span>
                  {s.team && <span className="block text-[9px] text-[#92adc9] truncate">{s.team}</span>}
                </span>
                <span className="shrink-0 min-w-[34px] text-center rounded-md bg-[#a9cdf611] px-1.5 py-1 text-[13px] font-semibold text-[#e0efff] tabular-persian">
                  {faDigits(s.goals)}
                </span>
              </>
            );
            const cls = "flex items-center gap-2.5 px-1.5 py-2 rounded-lg glass-row-hover w-full min-w-0 text-start";
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
  );
}

function Skeleton() {
  return (
    <div className="glass-card p-4 flex flex-col gap-3" aria-busy="true">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex items-center gap-3">
          <div className="w-5 h-4 rounded bg-muted animate-pulse" />
          <div className="w-[18px] h-[18px] rounded bg-muted animate-pulse" />
          <div className="h-4 rounded bg-muted animate-pulse" style={{ width: `${45 + ((i * 13) % 30)}%` }} />
          <div className="h-4 w-10 rounded bg-muted animate-pulse ms-auto" />
        </div>
      ))}
    </div>
  );
}

export interface StandingsViewProps {
  data: StandingsData | null;
  loading: boolean;
  leagueKey: string;
  onLeagueChange: (k: string) => void;
  onRetry?: () => void;
}

export function StandingsView({ data, loading, leagueKey, onLeagueChange, onRetry }: StandingsViewProps) {
  return (
    <div className="flex flex-col gap-4">
      {/* ---- league chips ---- */}
      <div className="flex gap-2 overflow-x-auto pb-1.5 -mx-1 px-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {LEAGUES.map((l) => (
          <Link
            key={l.key}
            href={`/league/${l.key}`}
            className={cn(
              "shrink-0 rounded-xl border px-3.5 py-2 text-xs font-bold transition-all",
              l.key === leagueKey
                ? "bg-primary/15 border-primary/40 text-primary shadow-[inset_0_1px_0_oklch(0.88_0.05_232/22%)]"
                : "bg-white/[0.035] border-glass-border-soft text-muted-foreground hover:border-glass-border hover:text-foreground"
            )}
          >
            {l.faName}
          </Link>
        ))}
      </div>

      {/* cycle-114: honest notice when the table is served from the
          last-known-good snapshot after an upstream outage (cycle-43 pattern) */}
      {data && !loading && data.stale && (
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

      {!data && loading ? (
        <Skeleton />
      ) : data ? (
        <div className={cn("grid gap-4 lg:grid-cols-[1fr_300px] xl:grid-cols-[1fr_330px] items-start transition-opacity", loading && "opacity-50")}>
          <div className="flex flex-col gap-3 min-w-0">
            <StandingsTable key={leagueKey} data={data} leagueKey={leagueKey} />
            <p className="text-[10px] text-muted-foreground px-1">
              نوار رنگی کنار رتبه‌ها نشان‌دهنده‌ی سهمیه‌های اروپایی / سقوط است. روی نام هر تیم کلیک کنید تا صفحه‌ی تیم باز شود. نقطه‌های رنگی زیر نام تیم (موبایل) و چیپ‌های ب/م/پ (دسکتاپ) نتیجه ۵ بازی آخر هر تیم در لیگ است. سوییچ «کل فصل / خانه / بیرون» رده‌بندی را فقط بر اساس بازی‌های خانگی یا خارج از خانه‌ی هر تیم نشان می‌دهد.
            </p>
          </div>
          <ScorersCard data={data} />
        </div>
      ) : (
        <EmptyState
          icon="trophy"
          title="دریافت جدول ناموفق بود"
          sub="ارتباط با منبع داده برقرار نشد؛ یک بار دیگر امتحان کنید."
          action={onRetry ? { label: "تلاش دوباره", onClick: onRetry } : undefined}
        />
      )}
    </div>
  );
}
