"use client";

// ------------------------------------------------------------------
// Remontada — league standings + top scorers view
// ------------------------------------------------------------------
import Link from "next/link";
import { LEAGUES } from "@/lib/leagues";
import type { StandingsData } from "@/lib/fotmob";
import { FavoriteStar } from "@/components/remontada/favorite-star";
import { faDigits } from "@/lib/format";
import { cn } from "@/lib/utils";

function QualBar({ color }: { color?: string }) {
  if (!color) return null;
  return <span className="absolute inset-y-1 right-0 w-[3px] rounded-full" style={{ backgroundColor: color }} aria-hidden />;
}

function StandingsTable({ data }: { data: StandingsData }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-[12px] sm:text-[13px] min-w-[520px]">
          <thead>
            <tr className="text-muted-foreground text-[10px] sm:text-[11px] border-b border-border/40 bg-muted/25">
              <th className="py-2.5 pe-1 ps-3 font-bold text-start w-8">#</th>
              <th className="py-2.5 px-1 font-bold text-start">تیم</th>
              <th className="py-2.5 px-1.5 font-bold text-center" title="بازی">ب</th>
              <th className="py-2.5 px-1.5 font-bold text-center" title="برد">بر</th>
              <th className="py-2.5 px-1.5 font-bold text-center" title="مساوی">مس</th>
              <th className="py-2.5 px-1.5 font-bold text-center" title="باخت">با</th>
              <th className="py-2.5 px-1.5 font-bold text-center hidden sm:table-cell" title="گل زده">گز</th>
              <th className="py-2.5 px-1.5 font-bold text-center hidden sm:table-cell" title="گل خورده">گخ</th>
              <th className="py-2.5 px-1.5 font-bold text-center" title="تفاضل گل">تف</th>
              <th className="py-2.5 px-2.5 font-black text-center" title="امتیاز">امتیاز</th>
            </tr>
          </thead>
          <tbody>
            {data.rows.map((r) => (
              <tr key={r.teamId} className="border-b border-border/25 last:border-0 hover:bg-accent/30 transition-colors relative">
                <td className="py-2.5 pe-1 ps-3 relative">
                  <QualBar color={r.qualColor || undefined} />
                  <span className="font-bold text-muted-foreground tabular-persian">{faDigits(r.idx)}</span>
                </td>
                <td className="py-2 px-1">
                  <div className="flex items-center gap-0.5 min-w-0">
                    <Link
                      href={`/team/${r.teamId}`}
                      className="flex items-center gap-2 min-w-0 flex-1 rounded-lg px-1 -mx-1 py-0.5 hover:bg-primary/10 transition-colors group"
                      prefetch={false}
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={r.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                      <span className="font-bold truncate group-hover:text-primary transition-colors">{r.fa || r.name}</span>
                    </Link>
                    <FavoriteStar
                      team={{ id: r.teamId, fa: r.fa || r.name, en: r.name }}
                      size={13}
                      className="opacity-70 hover:opacity-100"
                    />
                  </div>
                </td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.played)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian">{faDigits(r.wins)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.draws)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{faDigits(r.losses)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground hidden sm:table-cell">{faDigits(r.goalsFor)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground hidden sm:table-cell">{faDigits(r.goalsAgainst)}</td>
                <td className="py-2 px-1.5 text-center tabular-persian text-muted-foreground">{r.gd > 0 ? `+${faDigits(r.gd)}` : faDigits(r.gd)}</td>
                <td className="py-2 px-2.5 text-center">
                  <span className="font-black text-primary tabular-persian bg-primary/10 rounded-lg px-2 py-0.5 inline-block min-w-[34px]">
                    {faDigits(r.pts)}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function ScorersCard({ data }: { data: StandingsData }) {
  if (!data.scorers || data.scorers.length === 0) return null;
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <header className="flex items-center gap-2 px-4 py-3 border-b border-border/40 bg-muted/25">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className="text-chart-3" aria-hidden>
          <circle cx="12" cy="8" r="5" />
          <path d="M8.5 12.5L7 22l5-3 5 3-1.5-9.5" />
        </svg>
        <h3 className="font-black text-sm">آقای گل</h3>
        <span className="ms-auto text-[10px] text-muted-foreground">{data.leagueFa}</span>
      </header>
      <ol className="p-1.5 flex flex-col">
        {data.scorers.map((s, i) => (
          <li key={`${s.name}-${i}`} className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-accent/30 transition-colors">
            <span
              className={cn(
                "w-6 h-6 rounded-lg flex items-center justify-center text-[11px] font-black shrink-0 tabular-persian",
                i === 0 ? "bg-chart-3/20 text-chart-3 border border-chart-3/30" : "bg-muted text-muted-foreground"
              )}
            >
              {faDigits(s.rank)}
            </span>
            <div className="min-w-0 flex-1">
              <p className="font-bold text-[13px] truncate">{s.name}</p>
              {s.team && <p className="text-[10px] text-muted-foreground truncate">{s.team}</p>}
            </div>
            <span className="font-black text-sm text-primary tabular-persian">
              {faDigits(s.goals)}
              <span className="text-[9px] font-bold text-muted-foreground ms-1">گل</span>
            </span>
          </li>
        ))}
      </ol>
    </div>
  );
}

function Skeleton() {
  return (
    <div className="flex flex-col gap-4" aria-busy="true">
      <div className="rounded-2xl border border-border/60 bg-card/40 p-4 flex flex-col gap-3">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="flex items-center gap-3">
            <div className="w-5 h-4 rounded bg-muted animate-pulse" />
            <div className="w-[18px] h-[18px] rounded bg-muted animate-pulse" />
            <div className="h-4 rounded bg-muted animate-pulse" style={{ width: `${45 + ((i * 13) % 30)}%` }} />
            <div className="h-4 w-10 rounded bg-muted animate-pulse ms-auto" />
          </div>
        ))}
      </div>
    </div>
  );
}

export interface StandingsViewProps {
  data: StandingsData | null;
  loading: boolean;
  leagueKey: string;
  onLeagueChange: (k: string) => void;
}

export function StandingsView({ data, loading, leagueKey, onLeagueChange }: StandingsViewProps) {
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
                ? "bg-primary/15 border-primary/40 text-primary"
                : "bg-card/50 border-border/50 text-muted-foreground hover:border-border hover:text-foreground"
            )}
          >
            {l.faName}
          </Link>
        ))}
      </div>

      {!data && loading ? (
        <Skeleton />
      ) : data ? (
        <div className={cn("grid gap-4 lg:grid-cols-[1fr_300px] xl:grid-cols-[1fr_330px] items-start transition-opacity", loading && "opacity-50")}>
          <div className="flex flex-col gap-3 min-w-0">
            <div className="flex items-center justify-between px-1">
              <h2 className="text-sm font-black">{data.leagueFa}</h2>
              {data.season && (
                <span className="text-[10px] text-muted-foreground border border-border rounded-md px-1.5 py-0.5 tabular-persian">
                  فصل {faDigits(data.season)}
                </span>
              )}
            </div>
            <StandingsTable data={data} />
            <p className="text-[10px] text-muted-foreground px-1">
              نوار رنگی کنار رتبه‌ها نشان‌دهنده‌ی سهمیه‌های اروپایی / سقوط است. روی نام هر تیم کلیک کنید تا صفحه‌ی تیم باز شود.
            </p>
          </div>
          <ScorersCard data={data} />
        </div>
      ) : (
        <p className="text-sm text-muted-foreground text-center py-10">دریافت جدول ناموفق بود.</p>
      )}
    </div>
  );
}
