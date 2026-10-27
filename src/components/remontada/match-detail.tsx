"use client";

// ------------------------------------------------------------------
// Remontada — full match detail page
// scoreboard + scorers + events timeline + stats + lineups + info
// ------------------------------------------------------------------
import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { faDigits, jalaliShort, tehranDateLong, tehranTime, formColor } from "@/lib/format";
import type { TeamSeasonStats } from "@/lib/fotmob";
import { ShareButton } from "@/components/remontada/share-button";
import { cn } from "@/lib/utils";

// ---------- API shape (mirrors /api/match/[id]) ----------
interface DetailMatch {
  id: string;
  leagueName: string;
  leagueFa: string;
  ccode: string;
  leagueId: number;
  round?: string;
  utcTime: string;
  started: boolean;
  finished: boolean;
  cancelled: boolean;
  live: boolean;
  minute?: string;
  statusText?: string;
  home: { id: number; name: string; fa: string; logo: string; score: number | null };
  away: { id: number; name: string; fa: string; logo: string; score: number | null };
}
interface DetailScorer { side: "home" | "away"; player: string; minute: string; ownGoal: boolean; penalty: boolean; assist?: string }
interface DetailEvent {
  type: string; typeFa: string; minute: string; side: "home" | "away" | "neutral";
  player?: string; card?: string; ownGoal: boolean; penalty: boolean;
  swapIn?: string; swapOut?: string; homeScore: number | null; awayScore: number | null; assist?: string;
}
interface DetailStatRow { key: string; title: string; home: string; away: string; graph: boolean; homeVal: number | null; awayVal: number | null }
interface DetailStatGroup { title: string; rows: DetailStatRow[] }
interface LineupSide {
  teamId: number; name: string; fa: string; formation?: string; coach?: string;
  rows: { players: { id: number; name: string; shirt?: string; rating?: number }[] }[];
  subs: { id: number; name: string; shirt?: string }[];
}
interface DetailData {
  ok: boolean;
  match: DetailMatch;
  scorers: DetailScorer[];
  events: DetailEvent[];
  statGroups: DetailStatGroup[];
  lineups: { home: LineupSide | null; away: LineupSide | null } | null;
  info: { stadium?: string; city?: string; referee?: string; attendance?: string; date?: string; tournament?: string; round?: string };
  form: { home: string[]; away: string[] } | null;
  momentum: { minute: number; value: number }[] | null;
  playerOfTheMatch?: {
    name: string; rating?: string | null;
    teamId?: number; teamName?: string; teamLogo?: string;
    minutes?: number; role?: string;
    stats: { title: string; display: string }[];
  } | null;
  error?: string;
}

type Tab = "events" | "stats" | "lineups" | "info" | "h2h";

const TAB_LABELS: { key: Tab; label: string }[] = [
  { key: "events", label: "رویدادها" },
  { key: "stats", label: "آمار" },
  { key: "lineups", label: "ترکیب" },
  { key: "h2h", label: "رو در رو" },
  { key: "info", label: "اطلاعات" },
];

// ---------- small icons ----------
function GoalIcon({ className }: { className?: string }) {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden>
      <circle cx="12" cy="12" r="9" fillOpacity="0.15" stroke="currentColor" strokeWidth="1.6" />
      <path d="M12 7.2l4.2 3-1.6 4.9H9.4L7.8 10.2 12 7.2z" />
    </svg>
  );
}
function CardIcon({ color }: { color: "yellow" | "red" }) {
  return <span className={cn("inline-block w-2.5 h-3.5 rounded-[2px]", color === "yellow" ? "bg-amber-400" : "bg-red-500")} aria-hidden />;
}
function SubIcon() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
      <path d="M7 4v12M7 16l-3-3M7 16l3-3" /><path d="M17 20V8m0 0l-3 3m3-3l3 3" />
    </svg>
  );
}

function eventIcon(e: DetailEvent) {
  if (e.type === "Goal") {
    return e.ownGoal ? <GoalIcon className="text-muted-foreground" /> : <GoalIcon className="text-primary" />;
  }
  if (e.type === "Card") {
    return <CardIcon color={e.card === "red" ? "red" : "yellow"} />;
  }
  if (e.type === "Substitution") return <SubIcon />;
  if (e.type === "MissedPenalty" || e.type === "Penalty") {
    return <span className="text-[10px] font-black text-destructive">پ</span>;
  }
  return <span className="w-1.5 h-1.5 rounded-full bg-muted-foreground/50 inline-block" aria-hidden />;
}

function eventText(e: DetailEvent) {
  if (e.type === "Goal") {
    const parts = [e.player || ""];
    if (e.penalty) parts.push("(پنالتی)");
    if (e.ownGoal) parts.push("(گل به خودی)");
    if (e.assist) parts.push(`(پاس: ${e.assist})`);
    return parts.filter(Boolean).join(" ");
  }
  if (e.type === "Substitution") return `${e.swapIn || "?"} ← ${e.swapOut || "?"}`;
  if (e.type === "Card") return e.player || "کارت";
  if (e.type === "MissedPenalty") return `${e.player || ""} (پنالتی از دست رفت)`;
  return e.player || e.typeFa;
}

const ROLE_FA: Record<string, string> = {
  Goalkeeper: "دروازه‌بان",
  Defender: "مدافع",
  Midfielder: "هافبک",
  Forward: "مهاجم",
};

// ---------- best player card ----------
function PotmCard({ p }: { p: NonNullable<DetailData["playerOfTheMatch"]> }) {
  const role = p.role ? ROLE_FA[p.role] || p.role : null;
  return (
    <section className="rounded-2xl border border-chart-3/25 bg-gradient-to-bl from-chart-3/[0.09] via-card/70 to-card/70 overflow-hidden" aria-label="بهترین بازیکن زمین">
      <div className="px-4 py-3.5 flex items-center gap-3.5">
        <div className="relative w-14 h-14 rounded-full bg-chart-3/15 border border-chart-3/40 flex flex-col items-center justify-center shrink-0" title="امتیاز فوت‌ماب">
          <span className="text-[15px] font-black text-chart-3 leading-none tabular-persian">{p.rating ? faDigits(p.rating) : "—"}</span>
          <span className="text-[7.5px] font-bold text-chart-3/70 mt-0.5">امتیاز</span>
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-[9.5px] font-black text-chart-3 flex items-center gap-1">
            <span aria-hidden>★</span> بهترین بازیکن زمین
          </p>
          <p className="font-black text-[15px] leading-6 truncate">{p.name}</p>
          <p className="text-[10.5px] text-muted-foreground flex items-center gap-1.5 flex-wrap mt-0.5">
            {(p.teamId || p.teamName) && (
              <>
                {p.teamLogo && (
                   
                  <img src={p.teamLogo} alt="" width={13} height={13} className="w-[13px] h-[13px] object-contain inline-block" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                )}
                <span>{p.teamName}</span>
              </>
            )}
            {role && <span>· {role}</span>}
            {p.minutes ? <span className="tabular-persian">· {faDigits(p.minutes)} دقیقه</span> : null}
          </p>
        </div>
      </div>
      {p.stats.length > 0 && (
        <div className="grid grid-cols-2 sm:grid-cols-4 border-t border-border/40 bg-card/40">
          {p.stats.map((s, i) => (
            <div key={i} className="px-2 py-2 text-center border-b border-border/25 sm:[&:nth-child(-n+4)]:border-b-0 sm:border-e sm:last:border-e-0 [&:nth-child(odd)]:border-s sm:[&:nth-child(odd)]:border-s-0">
              <p className="font-black text-[13.5px] tabular-persian leading-5" dir="ltr">{faDigits(s.display)}</p>
              <p className="text-[9px] text-muted-foreground truncate">{s.title}</p>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

// ---------- scoreboard ----------
function Scoreboard({ m, potm }: { m: DetailMatch; potm?: DetailData["playerOfTheMatch"] }) {
  const status = m.cancelled ? "لغو شده" : m.live ? m.minute || "در جریان" : m.finished ? "پایان بازی" : tehranTime(m.utcTime);
  return (
    <section className="rounded-2xl border border-border/60 bg-card/70 overflow-hidden backdrop-blur-sm">
      <div className="flex items-center justify-between gap-2 px-4 py-2.5 border-b border-border/40 bg-muted/25 text-[11px]">
        <Link href="/" className="font-bold text-muted-foreground hover:text-primary transition-colors truncate">
          {m.leagueFa || m.leagueName}
        </Link>
        {m.round && <span className="text-muted-foreground/70 shrink-0">{m.round}</span>}
        <ShareButton
          title={`${m.home.fa || m.home.name} ${m.home.score ?? ""} - ${m.away.score ?? ""} ${m.away.fa || m.away.name} | رمانتادا`}
          path={`/match/${m.id}`}
          size={26}
        />
      </div>
      <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 sm:gap-5 px-3 sm:px-8 py-6">
        {/* home */}
        <div className="flex flex-col items-center gap-2.5 text-center min-w-0">
          { }
          <img src={m.home.logo} alt="" width={52} height={52} className="w-11 h-11 sm:w-14 sm:h-14 object-contain" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <Link
            href={`/team/${m.home.id}`}
            className="font-black text-[13px] sm:text-[15px] leading-5 hover:text-primary transition-colors"
            prefetch={false}
          >
            {m.home.fa || m.home.name}
          </Link>
        </div>
        {/* score */}
        <div className="flex flex-col items-center gap-2">
          {m.started && !m.cancelled ? (
            <div className={cn("flex items-center gap-2.5 font-black tabular-persian text-3xl sm:text-4xl", m.live && "text-red-300")}>
              <span>{m.home.score ?? "—"}</span>
              <span className="text-muted-foreground/40 text-2xl">:</span>
              <span>{m.away.score ?? "—"}</span>
            </div>
          ) : (
            <div className="font-black text-2xl sm:text-3xl text-muted-foreground tabular-persian">
              {tehranTime(m.utcTime)}
            </div>
          )}
          <span
            className={cn(
              "text-[11px] font-black rounded-lg px-2.5 py-1 border tabular-persian whitespace-nowrap",
              m.live ? "text-red-400 border-red-500/30 bg-red-500/10" : "text-muted-foreground border-border bg-muted/40"
            )}
          >
            {m.live && <span className="live-dot inline-block w-1.5 h-1.5 rounded-full bg-red-500 me-1.5 align-middle" />}
            {status}
          </span>
        </div>
        {/* away */}
        <div className="flex flex-col items-center gap-2.5 text-center min-w-0">
          { }
          <img src={m.away.logo} alt="" width={52} height={52} className="w-11 h-11 sm:w-14 sm:h-14 object-contain" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <Link
            href={`/team/${m.away.id}`}
            className="font-black text-[13px] sm:text-[15px] leading-5 hover:text-primary transition-colors"
            prefetch={false}
          >
            {m.away.fa || m.away.name}
          </Link>
        </div>
      </div>

      {/* scorers + POTM */}
      {m.started && !m.cancelled && (
        <div className="px-4 pb-4 pt-1 grid grid-cols-[1fr_auto_1fr] gap-2 text-[11px]">
          <div className="flex flex-col gap-1 items-start ps-2">
            {m.home.score !== null &&
              m.scorers.filter((s) => s.side === "home").map((s, i) => (
                <span key={i} className="flex items-center gap-1.5 text-muted-foreground tabular-persian">
                  <GoalIcon className="text-primary/80" />
                  <span className="font-semibold text-foreground/85">{s.player}</span> {faDigits(s.minute)}
                  {s.penalty && " (پ)"}
                  {s.ownGoal && " (گل به خودی)"}
                  {s.assist && <span className="text-muted-foreground/60">(پاس: {s.assist})</span>}
                </span>
              ))}
          </div>
          <div className="w-px bg-border/40" aria-hidden />
          <div className="flex flex-col gap-1 items-end pe-2">
            {m.away.score !== null &&
              m.scorers.filter((s) => s.side === "away").map((s, i) => (
                <span key={i} className="flex items-center gap-1.5 text-muted-foreground tabular-persian">
                  {s.assist && <span className="text-muted-foreground/60">(پاس: {s.assist})</span>}
                  {s.penalty && " (پ)"}
                  {s.ownGoal && " (گل به خودی)"}
                  {faDigits(s.minute)} <span className="font-semibold text-foreground/85">{s.player}</span>
                  <GoalIcon className="text-primary/80" />
                </span>
              ))}
          </div>
        </div>
      )}

      {potm && (
        <div className="border-t border-border/40 px-4 py-2.5 flex items-center justify-center gap-2 text-[11px] bg-muted/20">
          <span className="text-chart-3">★</span>
          <span className="text-muted-foreground">بهترین بازیکن زمین:</span>
          <span className="font-black">{potm.name}</span>
          {potm.rating && <span className="text-primary font-bold tabular-persian">({faDigits(potm.rating)})</span>}
        </div>
      )}
    </section>
  );
}

// ---------- events timeline ----------
function EventsTimeline({ events, match }: { events: DetailEvent[]; match: DetailMatch }) {
  if (events.length === 0) {
    return <p className="text-center text-muted-foreground text-sm py-10">رویدادی ثبت نشده است.</p>;
  }
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <div className="divide-y divide-border/25">
        {events.map((e, i) => (
          <div
            key={i}
            className={cn(
              "grid grid-cols-[1fr_auto_1fr] items-center gap-2 px-4 py-2.5 text-[12.5px]",
              e.side === "home" && "bg-accent/15"
            )}
          >
            {/* home side (right in RTL) */}
            <div className={cn("flex items-center gap-2 justify-start", e.side !== "home" && "invisible")}>
              {eventIcon(e)}
              <span className="font-semibold">{eventText(e)}</span>
            </div>
            {/* minute + score */}
            <div className="flex flex-col items-center min-w-[54px]">
              <span className="text-[11px] font-black text-muted-foreground tabular-persian">{faDigits(e.minute)}</span>
              {e.homeScore !== null && e.awayScore !== null && e.type === "Goal" && (
                <span className="text-[10px] text-muted-foreground/70 tabular-persian">
                  {faDigits(e.homeScore)}:{faDigits(e.awayScore)}
                </span>
              )}
            </div>
            {/* away side */}
            <div className={cn("flex items-center gap-2 justify-end", e.side !== "away" && "invisible")}>
              <span className="font-semibold">{eventText(e)}</span>
              {eventIcon(e)}
            </div>
          </div>
        ))}
      </div>
      <div className="px-4 py-2 text-[10px] text-muted-foreground/60 border-t border-border/25">
        {match.home.fa || match.home.name} — رویدادهای سمت راست | {match.away.fa || match.away.name} — رویدادهای سمت چپ
      </div>
    </div>
  );
}

// ---------- stats ----------
function StatBars({ groups }: { groups: DetailStatGroup[] }) {
  if (groups.length === 0) {
    return <p className="text-center text-muted-foreground text-sm py-10">آماری برای این بازی ثبت نشده است.</p>;
  }
  return (
    <div className="flex flex-col gap-4">
      {groups.map((g, gi) => (
        <div key={gi} className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
          <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 flex items-center justify-between text-[11px]">
            <span className="font-bold text-muted-foreground tabular-persian">{faDigits(g.rows[0]?.home || "0")}</span>
            <span className="font-black text-[12px]">{g.title}</span>
            <span className="font-bold text-muted-foreground tabular-persian">{faDigits(g.rows[0]?.away || "0")}</span>
          </header>
          <div className="p-3 flex flex-col gap-3">
            {g.rows.map((r, i) => {
              const hv = r.homeVal ?? 0;
              const av = r.awayVal ?? 0;
              const total = hv + av;
              const hp = total > 0 ? (hv / total) * 100 : 50;
              const numeric = r.homeVal !== null && r.awayVal !== null && total > 0;
              return (
                <div key={i} className="flex flex-col gap-1">
                  <div className="flex items-center justify-between text-[11.5px]">
                    <span className="font-black tabular-persian w-12 text-start">{r.home}</span>
                    <span className="text-muted-foreground text-[10.5px]">{r.title}</span>
                    <span className="font-black tabular-persian w-12 text-end">{r.away}</span>
                  </div>
                  {numeric && r.graph && (
                    <div className="flex h-1.5 rounded-full overflow-hidden gap-0.5" dir="ltr">
                      <div className="bg-primary h-full rounded-full transition-all" style={{ width: `${hp}%` }} />
                      <div className="flex-1" />
                      <div className="bg-chart-4 h-full rounded-full transition-all" style={{ width: `${100 - hp}%` }} />
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}

// ---------- lineups ----------
function LineupsPitch({ lineups, match }: { lineups: NonNullable<DetailData["lineups"]>; match: DetailMatch }) {
  const side = (t: LineupSide | null, isHome: boolean) => {
    if (!t) return null;
    return (
      <div className="flex-1 min-w-0 flex flex-col gap-3">
        <div className="flex items-center justify-center gap-2 text-[12px] flex-wrap">
          <span className="font-black truncate">{t.fa || t.name}</span>
          {t.formation && (
            <span className="text-[10px] font-bold text-muted-foreground border border-border rounded-md px-1.5 py-0.5" dir="ltr">
              {t.formation}
            </span>
          )}
        </div>
        <div className="rounded-2xl border border-primary/20 bg-gradient-to-b from-primary/[0.07] to-transparent p-2.5 flex flex-col gap-1.5 min-h-[240px] justify-around">
          {t.rows.map((row, ri) => (
            <div key={ri} className="flex justify-center gap-1.5 flex-wrap">
              {row.players.map((p) => (
                <div key={p.id} className="flex flex-col items-center gap-0.5 min-w-0" title={p.name}>
                  <span
                    className={cn(
                      "w-6 h-6 rounded-full border flex items-center justify-center text-[9px] font-black tabular-persian shrink-0",
                      isHome ? "bg-primary/20 border-primary/40 text-primary" : "bg-chart-4/20 border-chart-4/40 text-chart-4"
                    )}
                  >
                    {p.shirt ? faDigits(p.shirt) : "–"}
                  </span>
                  <span className="text-[8.5px] text-muted-foreground max-w-[64px] truncate leading-3">{p.name}</span>
                  {typeof p.rating === "number" && p.rating > 0 && (
                    <span className="text-[8px] font-bold text-chart-3 tabular-persian">{faDigits(p.rating.toFixed(1))}</span>
                  )}
                </div>
              ))}
            </div>
          ))}
        </div>
        {t.coach && (
          <p className="text-[10px] text-muted-foreground text-center">سرمربی: <span className="font-bold text-foreground/80">{t.coach}</span></p>
        )}
        {t.subs.length > 0 && (
          <details className="text-[11px]">
            <summary className="cursor-pointer text-muted-foreground font-bold select-none hover:text-foreground transition-colors">
              بازیکنان ذخیره ({faDigits(t.subs.length)})
            </summary>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {t.subs.map((s) => (
                <span key={s.id} className="bg-muted/60 border border-border/50 rounded-lg px-2 py-1 text-[10px] flex items-center gap-1.5">
                  {s.shirt && <span className="text-muted-foreground tabular-persian">{faDigits(s.shirt)}</span>}
                  {s.name}
                </span>
              ))}
            </div>
          </details>
        )}
      </div>
    );
  };
  return (
    <div className="flex flex-col sm:flex-row gap-5 items-start">
      {side(lineups.home, true) ?? <p className="flex-1 text-center text-muted-foreground text-xs py-8">ترکیب {match.home.fa || match.home.name} ثبت نشده</p>}
      <div className="hidden sm:block w-px self-stretch bg-border/40" aria-hidden />
      {side(lineups.away, false) ?? <p className="flex-1 text-center text-muted-foreground text-xs py-8">ترکیب {match.away.fa || match.away.name} ثبت نشده</p>}
    </div>
  );
}

// ---------- info ----------
function InfoPanel({ data }: { data: DetailData }) {
  const rows: { label: string; value?: string }[] = [
    { label: "مسابقه", value: data.info.tournament || data.match.leagueFa },
    { label: "مرحله", value: data.info.round },
    { label: "تاریخ", value: data.info.date ? tehranDateLong(data.info.date) : undefined },
    { label: "ساعت", value: data.info.date ? `${tehranTime(data.info.date)} (به وقت تهران)` : undefined },
    { label: "ورشوگاه", value: [data.info.stadium, data.info.city].filter(Boolean).join("، ") || data.info.stadium },
    { label: "داور", value: data.info.referee },
    { label: "تماشاگران", value: data.info.attendance ? faDigits(data.info.attendance) : undefined },
  ].filter((r) => r.value);

  if (rows.length === 0) {
    return <p className="text-center text-muted-foreground text-sm py-10">اطلاعات تکمیلی ثبت نشده است.</p>;
  }
  return (
    <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
      <ul className="divide-y divide-border/25">
        {rows.map((r, i) => (
          <li key={i} className="flex items-center justify-between px-4 py-3 text-[12.5px]">
            <span className="text-muted-foreground font-bold">{r.label}</span>
            <span className="font-semibold text-start">{r.value}</span>
          </li>
        ))}
      </ul>
      {data.form && (
        <div className="border-t border-border/40 px-4 py-3 flex flex-col gap-2.5">
          {(["home", "away"] as const).map((side) => (
            <div key={side} className="flex items-center gap-2.5 flex-wrap">
              <span className="text-[11px] font-bold text-muted-foreground min-w-[80px]">
                {side === "home" ? "فرم میزبان" : "فرم مهمان"}:
              </span>
              <div className="flex gap-1">
                {data.form![side].map((f, i) => (
                  <span key={i} className={cn("w-6 h-6 rounded-lg border text-[10px] font-black flex items-center justify-center", formColor(f as "W" | "D" | "L"))}>
                    {f === "W" ? "ب" : f === "D" ? "م" : "با"}
                  </span>
                ))}
                {data.form![side].length === 0 && <span className="text-[10px] text-muted-foreground/60">—</span>}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ---------- head-to-head ----------
interface H2HTeam { id: number; name: string; fa: string; logo: string }
interface H2HMeeting {
  id: string; utcTime: string; leagueFa: string;
  home: H2HTeam; away: H2HTeam;
  scoreStr?: string; winner: "home" | "away" | "draw" | null;
  reason?: string; finished: boolean;
}
interface H2HData {
  ok: boolean;
  home: H2HTeam; away: H2HTeam;
  totals: { homeWins: number; draws: number; awayWins: number; played: number };
  comparison?: {
    home: H2HTeam & { season: TeamSeasonStats | null };
    away: H2HTeam & { season: TeamSeasonStats | null };
  } | null;
  results: H2HMeeting[];
  upcoming: H2HMeeting[];
  hasData: boolean;
  error?: string;
}

// ---------- season comparison (two TeamSeasonStats side by side) ----------
function SeasonComparePanel({
  comparison,
}: {
  comparison: NonNullable<H2HData["comparison"]>;
}) {
  const hs = comparison.home.season;
  const as = comparison.away.season;
  if (!hs && !as) return null;

  const pts = (s: TeamSeasonStats | null) => (s ? s.wins * 3 + s.draws : null);
  const rows: { label: string; h: number | null; a: number | null; digits?: number }[] = [
    { label: "امتیاز", h: pts(hs), a: pts(as) },
    { label: "برد", h: hs?.wins ?? null, a: as?.wins ?? null },
    { label: "گل زده", h: hs?.goalsFor ?? null, a: as?.goalsFor ?? null },
    { label: "گل خورده", h: hs?.goalsAgainst ?? null, a: as?.goalsAgainst ?? null },
    { label: "میانگین گل", h: hs?.avgFor ?? null, a: as?.avgFor ?? null, digits: 1 },
    { label: "کلین‌شیت", h: hs?.cleanSheets ?? null, a: as?.cleanSheets ?? null },
  ];

  const fmt = (v: number | null, digits?: number) =>
    v == null ? "—" : faDigits(digits ? v.toFixed(digits) : Math.round(v));

  const sideName = (t: H2HTeam & { season: TeamSeasonStats | null }) =>
    t.fa || t.name;

  return (
    <section className="rounded-2xl border border-border/60 bg-card/60 p-4">
      <header className="flex items-center justify-between gap-2 mb-3">
        <span className="flex items-center gap-1.5 min-w-0">
          { }
          <img src={comparison.home.logo} alt="" width={20} height={20} className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <span className="font-black text-[12px] truncate">{sideName(comparison.home)}</span>
        </span>
        <span className="text-[10px] font-black text-muted-foreground whitespace-nowrap">مقایسه فصل</span>
        <span className="flex items-center gap-1.5 min-w-0 justify-end">
          <span className="font-black text-[12px] truncate">{sideName(comparison.away)}</span>
          { }
          <img src={comparison.away.logo} alt="" width={20} height={20} className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
        </span>
      </header>
      <div className="flex flex-col divide-y divide-border/20">
        {rows.map((r) => {
          const max = Math.max(r.h ?? 0, r.a ?? 0, 0.0001);
          const hw = r.h != null ? Math.max((r.h / max) * 100, r.h > 0 ? 6 : 0) : 0;
          const aw = r.a != null ? Math.max((r.a / max) * 100, r.a > 0 ? 6 : 0) : 0;
          return (
            <div key={r.label} className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 py-1.5">
              {/* home side (start = right in RTL) */}
              <div className="flex items-center justify-start gap-1.5 min-w-0">
                <div className="w-12 sm:w-20 h-1.5 rounded-full bg-muted/50 overflow-hidden flex justify-start shrink-0">
                  <div className="h-full bg-primary/80 rounded-full" style={{ width: `${hw}%` }} />
                </div>
                <span className="text-[11px] font-black tabular-persian">{fmt(r.h, r.digits)}</span>
              </div>
              <span className="text-[9.5px] font-bold text-muted-foreground w-14 sm:w-16 text-center shrink-0">{r.label}</span>
              {/* away side (end = left in RTL) */}
              <div className="flex items-center justify-end gap-1.5 min-w-0">
                <span className="text-[11px] font-black tabular-persian">{fmt(r.a, r.digits)}</span>
                <div className="w-12 sm:w-20 h-1.5 rounded-full bg-muted/50 overflow-hidden flex justify-end shrink-0">
                  <div className="h-full bg-chart-4/80 rounded-full" style={{ width: `${aw}%` }} />
                </div>
              </div>
            </div>
          );
        })}
      </div>
      <p className="text-[9px] text-muted-foreground mt-2 tabular-persian">
        {(hs?.leagueFa || as?.leagueFa) && <>{hs?.leagueFa}{hs?.leagueFa && as?.leagueFa && hs?.leagueFa !== as?.leagueFa ? " / " : ""}{as?.leagueFa !== hs?.leagueFa ? as?.leagueFa : ""} · </>}
        آمار فصل جاری هر تیم از فیکسچرهای لیگش
      </p>
    </section>
  );
}

function H2HMeetingRow({ m, curHomeId, curAwayId }: { m: H2HMeeting; curHomeId: number; curAwayId: number }) {
  const wTeamId = m.winner === "home" ? m.home.id : m.winner === "away" ? m.away.id : null;
  const homeWon = wTeamId === curHomeId;
  const awayWon = wTeamId === curAwayId;
  const j = jalaliShort(m.utcTime);

  const teams = (
    <>
      <span className={cn("flex items-center justify-end gap-1.5 min-w-0 flex-1", homeWon ? "font-black" : "font-semibold text-muted-foreground")}>
        <span className="truncate text-[12.5px]">{m.home.fa || m.home.name}</span>
        { }
        <img src={m.home.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
      </span>
      <span className={cn(
        "shrink-0 font-black text-[12.5px] tabular-persian rounded-lg px-2 py-0.5 min-w-[52px] text-center",
        m.finished ? "bg-muted/60" : "text-foreground/80"
      )}>
        {m.finished ? (m.scoreStr ? `${faDigits(m.scoreStr.split("-")[0].trim())} - ${faDigits(m.scoreStr.split("-")[1].trim())}` : "—") : tehranTime(m.utcTime)}
      </span>
      <span className={cn("flex items-center gap-1.5 min-w-0 flex-1", awayWon ? "font-black" : "font-semibold text-muted-foreground")}>
        { }
        <img src={m.away.logo} alt="" width={18} height={18} loading="lazy" className="w-[18px] h-[18px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
        <span className="truncate text-[12.5px]">{m.away.fa || m.away.name}</span>
      </span>
    </>
  );

  return (
    <div className="flex items-center gap-3 px-3 sm:px-4 py-2.5 hover:bg-accent/30 transition-colors">
      <div className="flex flex-col shrink-0 min-w-[84px]">
        <span className="text-[10px] font-bold text-muted-foreground tabular-persian whitespace-nowrap">
          {j.weekday} {faDigits(j.day)} {j.month}
        </span>
        <span className="text-[9px] text-muted-foreground/70 truncate max-w-full">{m.leagueFa}</span>
      </div>
      <div className="flex-1 flex items-center gap-2 min-w-0">{teams}</div>
      {m.finished ? (
        m.reason && m.reason !== "FT" ? (
          <span className="shrink-0 text-[9px] font-bold text-muted-foreground border border-border rounded-md px-1.5 py-0.5">{m.reason}</span>
        ) : null
      ) : (
        <span className="shrink-0 text-[9px] font-black text-primary border border-primary/30 bg-primary/10 rounded-md px-1.5 py-0.5">پیش‌رو</span>
      )}
    </div>
  );
}

function H2HPanel({ data, loading }: { data: H2HData | null; loading: boolean }) {
  if (loading && !data) {
    return (
      <div className="rounded-2xl border border-border/60 bg-card/40 p-4 flex flex-col gap-3" aria-busy="true">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="flex items-center gap-3">
            <div className="h-3 w-20 rounded bg-muted animate-pulse" />
            <div className="h-4 rounded bg-muted animate-pulse flex-1" />
            <div className="h-5 w-12 rounded bg-muted animate-pulse" />
          </div>
        ))}
      </div>
    );
  }
  if (!data || !data.ok) {
    return (
      <p className="text-center text-muted-foreground text-sm py-10">
        {data?.error || "سابقه رو در رو در دسترس نیست."}
      </p>
    );
  }
  if (!data.hasData) {
    return <p className="text-center text-muted-foreground text-sm py-10">سابقه‌ای از دیدار این دو تیم ثبت نشده است.</p>;
  }

  const { totals, home, away } = data;
  const { played } = totals;
  const pct = (n: number) => (played > 0 ? (n / played) * 100 : 0);

  return (
    <div className="flex flex-col gap-4">
      {/* summary card */}
      <section className="rounded-2xl border border-border/60 bg-card/60 p-4">
        <div className="flex items-center justify-between gap-2 mb-3">
          <span className="flex items-center gap-2 min-w-0">
            { }
            <img src={home.logo} alt="" width={22} height={22} className="w-[22px] h-[22px] object-contain" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
            <span className="font-black text-[13px] truncate">{home.fa || home.name}</span>
          </span>
          <span className="text-[10px] font-bold text-muted-foreground whitespace-nowrap tabular-persian">
            {faDigits(totals.played)} دیدار
          </span>
          <span className="flex items-center gap-2 min-w-0 justify-end">
            <span className="font-black text-[13px] truncate">{away.fa || away.name}</span>
            { }
            <img src={away.logo} alt="" width={22} height={22} className="w-[22px] h-[22px] object-contain" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          </span>
        </div>
        {/* wins bar: home | draws | away (home = right in RTL) */}
        <div className="flex h-2.5 rounded-full overflow-hidden bg-muted/40" dir="rtl" aria-hidden>
          <div className="bg-primary/80" style={{ width: `${pct(totals.homeWins)}%` }} />
          <div className="bg-muted-foreground/30" style={{ width: `${pct(totals.draws)}%` }} />
          <div className="bg-chart-4/80" style={{ width: `${pct(totals.awayWins)}%` }} />
        </div>
        <div className="flex items-center justify-between mt-2 text-[11px] font-bold tabular-persian">
          <span className="text-primary">{faDigits(totals.homeWins)} برد</span>
          <span className="text-muted-foreground">{faDigits(totals.draws)} مساوی</span>
          <span className="text-chart-4">{faDigits(totals.awayWins)} برد</span>
        </div>
      </section>

      {/* season stats comparison */}
      {data.comparison && <SeasonComparePanel comparison={data.comparison} />}

      {/* last meetings */}
      {data.results.length > 0 && (
        <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
          <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 text-[11px] font-black text-muted-foreground">
            آخرین دیدارها
          </header>
          <div className="divide-y divide-border/25">
            {data.results.map((mt) => (
              <Link key={mt.id} href={`/match/${mt.id}`} className="block" prefetch={false}>
                <H2HMeetingRow m={mt} curHomeId={home.id} curAwayId={away.id} />
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* upcoming meetings between the two teams */}
      {data.upcoming.length > 0 && (
        <div className="rounded-2xl border border-border/60 bg-card/60 overflow-hidden">
          <header className="px-4 py-2.5 border-b border-border/40 bg-muted/25 text-[11px] font-black text-muted-foreground">
            دیدارهای پیش‌روی این دو تیم
          </header>
          <div className="divide-y divide-border/25">
            {data.upcoming.map((mt) => (
              <Link key={mt.id} href={`/match/${mt.id}`} className="block" prefetch={false}>
                <H2HMeetingRow m={mt} curHomeId={home.id} curAwayId={away.id} />
              </Link>
            ))}
          </div>
        </div>
      )}

      <p className="text-[10px] text-muted-foreground px-1">
        آمار رو در رو بر اساس دیدارهای رسمی ثبت‌شده در FotMob است؛ بردهای میزبان ({home.fa || home.name}) با رنگ سبز و بردهای مهمان ({away.fa || away.name}) با رنگ آبی نمایش داده می‌شود. روی هر دیدار کلیک کنید تا صفحه‌ی آن بازی باز شود.
      </p>
    </div>
  );
}

// ---------- main ----------
export function MatchDetail({ matchId }: { matchId: string }) {
  const [data, setData] = useState<DetailData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>("events");

  // --- head-to-head (lazy per tab) ---
  const [h2h, setH2h] = useState<H2HData | null>(null);
  const [h2hLoading, setH2hLoading] = useState(false);

  const fetchH2H = useCallback(async () => {
    setH2hLoading(true);
    try {
      const res = await fetch(`/api/match-h2h/${matchId}`, { cache: "no-store" });
      const json = (await res.json()) as H2HData;
      setH2h(json);
    } catch {
      setH2h({ ok: false, error: "ارتباط برقرار نشد.", home: null as never, away: null as never, totals: { homeWins: 0, draws: 0, awayWins: 0, played: 0 }, results: [], upcoming: [], hasData: false });
    } finally {
      setH2hLoading(false);
    }
  }, [matchId]);

  useEffect(() => {
    if (tab === "h2h" && !h2h && !h2hLoading) fetchH2H();
  }, [tab, h2h, h2hLoading, fetchH2H]);

  const fetchDetail = useCallback(
    async (silent = false) => {
      if (!silent) setLoading(true);
      try {
        const res = await fetch(`/api/match/${matchId}`, { cache: "no-store" });
        const json = (await res.json()) as DetailData;
        if (json.ok) {
          setData(json);
          setError(null);
        } else {
          setError(json.error || "خطا در دریافت اطلاعات مسابقه");
        }
      } catch {
        setError("ارتباط برقرار نشد. دوباره تلاش کنید.");
      } finally {
        setLoading(false);
      }
    },
    [matchId]
  );

  useEffect(() => {
    fetchDetail();
  }, [fetchDetail]);

  // auto-refresh while live
  useEffect(() => {
    if (!data?.match.live) return;
    const iv = setInterval(() => {
      if (document.visibilityState === "visible") fetchDetail(true);
    }, 30_000);
    return () => clearInterval(iv);
  }, [data?.match.live, fetchDetail]);

  if (loading && !data) {
    return (
      <div className="flex flex-col gap-4" aria-busy="true">
        <div className="rounded-2xl border border-border/60 bg-card/40 p-8 flex flex-col items-center gap-4">
          <div className="w-14 h-14 rounded bg-muted animate-pulse" />
          <div className="h-8 w-32 rounded bg-muted animate-pulse" />
          <div className="h-4 w-48 rounded bg-muted animate-pulse" />
        </div>
        <div className="h-48 rounded-2xl border border-border/60 bg-card/40 animate-pulse" />
      </div>
    );
  }

  if (error && !data) {
    return (
      <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-5 py-8 text-center">
        <p className="font-black text-sm text-destructive mb-1">{error}</p>
        <button onClick={() => fetchDetail()} className="text-xs font-bold text-foreground underline underline-offset-4">
          تلاش مجدد
        </button>
      </div>
    );
  }

  if (!data) return null;
  const m = data.match;

  // NOTE: the SportsEvent JSON-LD is now server-rendered by /match/[id]/page.tsx
  // (cycle 18) — emitting it here too would create duplicate scripts.

  return (
    <div className="flex flex-col gap-4">
      {/* back link */}
      <Link href="/" className="inline-flex items-center gap-1.5 text-xs font-bold text-muted-foreground hover:text-primary transition-colors w-fit">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
          <path d="M9 18l6-6-6-6" />
        </svg>
        بازگشت به نتایج
      </Link>

      <Scoreboard m={m} potm={data.playerOfTheMatch} />

      {/* momentum (live) */}
      {data.momentum && data.momentum.length > 4 && (
        <section className="rounded-2xl border border-border/60 bg-card/60 p-3.5">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-[11px] font-black text-muted-foreground">فشار بازی</h3>
            <span className="text-[9px] text-muted-foreground/60">{m.home.fa} ← → {m.away.fa}</span>
          </div>
          <div className="flex items-center gap-[2px] h-8" dir="ltr">
            {data.momentum.filter((_, i) => i % Math.ceil(data.momentum!.length / 60) === 0).map((p, i) => (
              <div key={i} className="flex-1 flex flex-col justify-center h-full" title={`دقیقه ${p.minute}`}>
                <div className="flex-1 flex flex-col justify-end">
                  {p.value > 0 && <div className={cn("rounded-t-sm", p.value > 40 ? "bg-primary/80" : "bg-primary/35")} style={{ height: `${p.value}%` }} />}
                </div>
                <div className="w-full h-px bg-border/60" />
                <div className="flex-1">
                  {p.value < 0 && <div className={cn("rounded-b-sm", p.value < -40 ? "bg-chart-4/80" : "bg-chart-4/35")} style={{ height: `${-p.value}%` }} />}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* tabs */}
      <nav className="flex items-center gap-1 border-b border-border/40 -mx-1 px-1" aria-label="بخش‌های مسابقه">
        {TAB_LABELS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            aria-current={tab === t.key ? "page" : undefined}
            className={cn(
              "relative px-3.5 py-2 text-[12.5px] font-bold transition-colors",
              tab === t.key ? "text-primary" : "text-muted-foreground hover:text-foreground"
            )}
          >
            {t.label}
            {tab === t.key && <span className="absolute inset-x-3 bottom-0 h-0.5 bg-primary rounded-full" aria-hidden />}
          </button>
        ))}
      </nav>

      <div className={cn(loading && "opacity-50 transition-opacity")}>
        {tab === "events" && (
          <div className="flex flex-col gap-4">
            {data.playerOfTheMatch && <PotmCard p={data.playerOfTheMatch} />}
            <EventsTimeline events={data.events} match={m} />
          </div>
        )}
        {tab === "stats" && <StatBars groups={data.statGroups} />}
        {tab === "lineups" &&
          (data.lineups ? (
            <LineupsPitch lineups={data.lineups} match={m} />
          ) : (
            <p className="text-center text-muted-foreground text-sm py-10">ترکیب بازیکنان هنوز اعلام نشده است.</p>
          ))}
        {tab === "info" && <InfoPanel data={data} />}
        {tab === "h2h" && <H2HPanel data={h2h} loading={h2hLoading} />}
      </div>
    </div>
  );
}
