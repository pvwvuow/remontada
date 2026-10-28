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
import { EmptyState } from "@/components/remontada/empty-state";
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
  // fix cycle-45: penalty shootout (was dropped entirely before)
  shootout?: {
    home: number;
    away: number;
    attempts: { side: "home" | "away" | "neutral"; player?: string; scored: boolean; noteFa: string }[];
  } | null;
  // update cycle-46: normalized shotmap (null when the match has no shot data)
  shots?: {
    side: "home" | "away";
    minute: string;
    player?: string;
    x: number;
    y: number;
    isGoal: boolean;
    onTarget: boolean;
    blocked: boolean;
    post: boolean;
    xg?: number;
  }[] | null;
  // update cycle-51: complete team xG («اسکوآپ تیم») — mirrors /api/match/[id]
  xg?: {
    home: number | null;
    away: number | null;
    source: "stats" | "shotmap";
    homeBreakdown: {
      total: number; onTarget: number; blocked: number; post: number; goals: number;
    } | null;
    awayBreakdown: {
      total: number; onTarget: number; blocked: number; post: number; goals: number;
    } | null;
  } | null;
  // update cycle-47: per-player match stats (mirrors /api/match/[id])
  playerStats?: {
    home: PlayerStatRow[];
    away: PlayerStatRow[];
  } | null;
  // update cycle-97: attacking zones («جهت حملات») — mirrors /api/match/[id]
  zones?: {
    home: { left: number; center: number; right: number };
    away: { left: number; center: number; right: number };
  } | null;
  // update cycle-100: match weather («وضعیت هوا») — mirrors /api/match/[id];
  // only the honest subset (no wind/precip units asserted upstream-side)
  weather?: {
    condition: string;
    conditionSource: "localized" | "upstream";
    temperature?: number;
    humidity?: number;
    cloudCover?: number;
    precipChance?: number;
    forecast: boolean;
  } | null;
  playerOfTheMatch?: {
    id?: number;
    name: string; rating?: string | null;
    teamId?: number; teamName?: string; teamLogo?: string;
    minutes?: number; role?: string;
    stats: { title: string; display: string }[];
  } | null;
  error?: string;
}

interface PlayerStatRow {
  id: number;
  name: string;
  shirt?: string;
  side: "home" | "away";
  isGk: boolean;
  starter: boolean;
  rating?: number;
  minutes?: number;
  goals?: number;
  assists?: number;
  passesAcc?: number;
  passesTotal?: number;
  chances?: number;
  defActions?: number;
  saves?: number;
  conceded?: number;
  goalsPrevented?: number;
}

type Tab = "events" | "shots" | "players" | "stats" | "lineups" | "info" | "h2h";

const TAB_LABELS: { key: Tab; label: string }[] = [
  { key: "events", label: "رویدادها" },
  { key: "shots", label: "شوت‌ها" },
  { key: "players", label: "بازیکن‌ها" },
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
    <section className="glass-scorer-hero overflow-hidden" aria-label="بهترین بازیکن زمین">
      <div className="px-4 py-3.5 flex items-center gap-3.5">
        <div className="glass-avatar relative w-16 h-16 rounded-full flex flex-col items-center justify-center shrink-0" title="امتیاز فوت‌ماب">
          <span className="text-[19px] font-light text-[#dfedff] leading-none tabular-persian">{p.rating ? faDigits(p.rating) : "—"}</span>
          <span className="text-[7.5px] font-bold text-steel/80 mt-0.5">امتیاز</span>
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-[9px] font-black text-steel flex items-center gap-1.5">
            <span aria-hidden className="text-chart-3">★</span> بهترین بازیکن زمین
          </p>
          {p.id ? (
            <Link
              href={`/player/${p.id}`}
              prefetch={false}
              className="font-black text-[15px] leading-6 truncate block text-[#f1f7fd] hover:text-sky-soft transition-colors w-fit max-w-full"
              title="مشاهده پروفایل بازیکن"
            >
              {p.name}
            </Link>
          ) : (
            <p className="font-black text-[15px] leading-6 truncate text-[#f1f7fd]">{p.name}</p>
          )}
          <p className="text-[10.5px] text-steel/85 flex items-center gap-1.5 flex-wrap mt-0.5">
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
        <div className="grid grid-cols-2 sm:grid-cols-4 border-t border-glass-border-soft bg-white/[0.02]">
          {p.stats.map((s, i) => (
            <div key={i} className="px-2 py-2 text-center border-b border-glass-border-soft/70 sm:[&:nth-child(-n+4)]:border-b-0 sm:border-e sm:last:border-e-0 [&:nth-child(odd)]:border-s sm:[&:nth-child(odd)]:border-s-0">
              <p className="font-medium text-[13.5px] text-[#e0efff] tabular-persian leading-5" dir="ltr">{faDigits(s.display)}</p>
              <p className="text-[9px] text-steel/70 truncate">{s.title}</p>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}

// ---------- kickoff countdown (fix cycle-41) ----------
// For upcoming matches only: live «شروع بازی تا …» line under the status chip.
// Hydration-safe: SSR/first frame renders nothing, the label is computed after
// mount (setState inside the deferred timer — never in the effect body) and
// then ticks every second until kickoff.
function KickoffCountdown({ utcTime }: { utcTime: string }) {
  const [label, setLabel] = useState<string | null>(null);
  useEffect(() => {
    const fmt = () => {
      const diff = new Date(utcTime).getTime() - Date.now();
      if (!Number.isFinite(diff) || diff <= 0) return "بازی به‌زودی شروع می‌شود";
      const h = Math.floor(diff / 3_600_000);
      const mnt = Math.floor((diff % 3_600_000) / 60_000);
      const s = Math.floor((diff % 60_000) / 1000);
      if (h > 0) return `شروع بازی تا ${faDigits(h)} ساعت و ${faDigits(mnt)} دقیقه دیگر`;
      if (mnt > 0) return `شروع بازی تا ${faDigits(mnt)} دقیقه و ${faDigits(s)} ثانیه دیگر`;
      return `شروع بازی تا ${faDigits(s)} ثانیه دیگر`;
    };
    const t0 = setTimeout(() => setLabel(fmt()), 0);
    const iv = setInterval(() => setLabel(fmt()), 1000);
    return () => { clearTimeout(t0); clearInterval(iv); };
  }, [utcTime]);
  if (label === null) return null;
  return (
    <p className="text-[10.5px] text-steel/80 tabular-persian whitespace-nowrap" aria-live="off">
      {label}
    </p>
  );
}

// ---------- scoreboard ----------
function Scoreboard({ m, scorers, potm, shootout }: { m: DetailMatch; scorers: DetailScorer[]; potm?: DetailData["playerOfTheMatch"]; shootout?: DetailData["shootout"] }) {
  const status = m.cancelled ? "لغو شده" : m.live ? m.minute || "در جریان" : m.finished ? "پایان بازی" : "پیش از شروع";
  return (
    <section className="glass-card glass-hero overflow-hidden">
      {/* fix cycle-59: match page had no h1/h2 — sr-only h1 for a11y/crawlers,
          league row promoted to the page's visible h2 (identical look) */}
      <h1 className="sr-only">
        {m.home.fa || m.home.name} در برابر {m.away.fa || m.away.name} — {m.leagueFa || m.leagueName}
      </h1>
      <div className="flex items-center justify-between gap-2 px-4 py-2.5 border-b border-glass-border-soft bg-white/[0.02] text-[11px]">
        <h2 className="min-w-0 truncate">
          <Link href="/" className="font-extrabold text-[13px] text-[#ecf3fa]/90 hover:text-sky-soft transition-colors">
            {m.leagueFa || m.leagueName}
          </Link>
        </h2>
        {m.round && <span className="text-steel/70 shrink-0">{m.round}</span>}
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
          <img src={m.home.logo} alt="" width={52} height={52} className="w-11 h-11 sm:w-14 sm:h-14 object-contain drop-shadow-[0_5px_12px_oklch(0.03_0.015_255/65%)]" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
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
            <div className={cn("flex items-center gap-2.5 font-black tabular-persian text-3xl sm:text-4xl", m.live ? "text-red-200 live-glow score-battle" : "")}>
              <span className={m.live ? undefined : "score-forge"}>{m.home.score != null ? faDigits(m.home.score) : "—"}</span>
              <span className="text-muted-foreground/40 text-2xl">:</span>
              <span className={m.live ? undefined : "score-forge"}>{m.away.score != null ? faDigits(m.away.score) : "—"}</span>
            </div>
          ) : (
            <div className="font-black text-2xl sm:text-3xl text-muted-foreground tabular-persian">
              {tehranTime(m.utcTime)}
            </div>
          )}
          <span
            className={cn(
              "text-[11px] font-black rounded-lg px-2.5 py-1 border tabular-persian whitespace-nowrap",
              m.live ? "text-red-300 border-red-500/30 bg-red-500/10" : "text-steel border-glass-border-soft bg-white/[0.03]"
            )}
          >
            {m.live && <span className="live-dot live-dot-glow inline-block w-1.5 h-1.5 rounded-full bg-red-500 me-1.5 align-middle" />}
            {status}
          </span>
          {/* fix cycle-41: live kickoff countdown for upcoming matches (the
              short «رویدادی ثبت نشده» shell gets a useful heartbeat) */}
          {!m.started && !m.cancelled && !m.finished && <KickoffCountdown utcTime={m.utcTime} />}
        </div>
        {/* away */}
        <div className="flex flex-col items-center gap-2.5 text-center min-w-0">
          { }
          <img src={m.away.logo} alt="" width={52} height={52} className="w-11 h-11 sm:w-14 sm:h-14 object-contain drop-shadow-[0_5px_12px_oklch(0.03_0.015_255/65%)]" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <Link
            href={`/team/${m.away.id}`}
            className="font-black text-[13px] sm:text-[15px] leading-5 hover:text-primary transition-colors"
            prefetch={false}
          >
            {m.away.fa || m.away.name}
          </Link>
        </div>
      </div>

      {/* fix cycle-45: shootout score strip (decisive phase made visible) */}
      {shootout && (
        <div className="px-4 py-2 border-t border-glass-border-soft bg-amber-400/[0.05] flex items-center justify-center gap-2 text-[11px] text-amber-200/90 tabular-persian">
          <span>ضربات پنالتی:</span>
          <span className="font-black">{faDigits(shootout.home)}–{faDigits(shootout.away)}</span>
          {shootout.home !== shootout.away && (
            <span className="text-steel/80">
              ({shootout.home > shootout.away ? m.home.fa || m.home.name : m.away.fa || m.away.name} برنده شد)
            </span>
          )}
        </div>
      )}

      {/* scorers + POTM */}
      {m.started && !m.cancelled && (
        <div className="px-4 pb-4 pt-1 grid grid-cols-[1fr_auto_1fr] gap-2 text-[11px]">
          <div className="flex flex-col gap-1 items-start ps-2">
            {m.home.score !== null &&
              scorers.filter((s) => s.side === "home").map((s, i) => (
                <span key={i} className="flex items-center gap-1.5 text-muted-foreground tabular-persian">
                  <GoalIcon className="text-primary/80" />
                  <span className="font-semibold text-foreground/85">{s.player}</span> {faDigits(s.minute)}
                  {s.penalty && " (پ)"}
                  {s.ownGoal && " (گل به خودی)"}
                  {s.assist && <span className="text-muted-foreground/60">(پاس: {s.assist})</span>}
                </span>
              ))}
          </div>
          <div className="w-px bg-glass-border-soft" aria-hidden />
          <div className="flex flex-col gap-1 items-end pe-2">
            {m.away.score !== null &&
              scorers.filter((s) => s.side === "away").map((s, i) => (
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
        <div className="border-t border-glass-border-soft px-4 py-2.5 flex items-center justify-center gap-2 text-[11px] bg-white/[0.02]">
          <span className="text-chart-3">★</span>
          <span className="text-muted-foreground">بهترین بازیکن زمین:</span>
          <span className="font-black">{potm.name}</span>
          {potm.rating && <span className="text-primary font-bold tabular-persian">({faDigits(potm.rating)})</span>}
        </div>
      )}
    </section>
  );
}

// ---------- penalty shootout card (fix cycle-45) ----------
function PenDot({ scored }: { scored: boolean }) {
  return <span className={cn("inline-block w-2 h-2 rounded-full shrink-0", scored ? "bg-emerald-400" : "bg-red-400/70")} aria-hidden />;
}
function ShootoutCard({ shootout, match }: { shootout: NonNullable<DetailData["shootout"]>; match: DetailMatch }) {
  return (
    <div className="glass-card overflow-hidden">
      <div className="px-4 py-2 border-b border-glass-border-soft bg-white/[0.02] text-[11px] font-black text-amber-200/90 tabular-persian">
        ضربات پنالتی — {faDigits(shootout.home)}–{faDigits(shootout.away)}
      </div>
      <div className="glass-list">
        {shootout.attempts.map((a, i) => (
          <div key={i} className="glass-row-hover grid grid-cols-[1fr_auto_1fr] items-center gap-2 px-4 py-2 text-[12px]">
            {/* home side (right in RTL) */}
            <div className={cn("flex items-center gap-2 justify-start", a.side !== "home" && "invisible")}>
              <PenDot scored={a.scored} />
              <span className="font-semibold">{a.player}</span>
              {!a.scored && <span className="text-muted-foreground text-[10.5px]">({a.noteFa})</span>}
            </div>
            <span className="text-[10px] text-muted-foreground tabular-persian">{faDigits(i + 1)}</span>
            {/* away side */}
            <div className={cn("flex items-center gap-2 justify-end", a.side !== "away" && "invisible")}>
              {!a.scored && <span className="text-muted-foreground text-[10.5px]">({a.noteFa})</span>}
              <span className="font-semibold">{a.player}</span>
              <PenDot scored={a.scored} />
            </div>
          </div>
        ))}
      </div>
      <div className="px-4 py-2 text-[10px] text-steel/60 border-t border-glass-border-soft">
        {match.home.fa || match.home.name} — سمت راست | {match.away.fa || match.away.name} — سمت چپ
      </div>
    </div>
  );
}

// ---------- shotmap pitch (update cycle-46) ----------
function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="flex items-center gap-1">
      <span className={cn("inline-block w-2 h-2 rounded-full shrink-0", color)} aria-hidden />
      {label}
    </span>
  );
}
// ---------- team xG strip (update cycle-51) ----------
// «اسکوآپ تیم»: official FotMob xG (fallback = per-shot sum) + shot breakdown
// chips. Sides align with the pitch below (home left / away right): in this RTL
// layout the first flex child renders on the right, so away comes first; the
// split bar itself is dir=ltr with the same bg-primary/bg-chart-4 as StatBars.
function TeamXgStrip({ xg, match }: { xg: NonNullable<DetailData["xg"]>; match: DetailMatch }) {
  const h = xg.home ?? 0;
  const a = xg.away ?? 0;
  const sum = h + a;
  const hp = sum > 0 ? (h / sum) * 100 : 50;
  const team = (s: "home" | "away") => (s === "home" ? match.home : match.away);
  const val = (s: "home" | "away") => (s === "home" ? xg.home : xg.away);
  const bd = (s: "home" | "away") => (s === "home" ? xg.homeBreakdown : xg.awayBreakdown);
  const chip = (label: string, value: string) => (
    <span
      key={label}
      className="inline-flex items-center gap-1 rounded-md bg-white/[0.045] border border-glass-border-soft px-1.5 py-0.5 text-[10px] text-steel tabular-persian leading-4"
    >
      <span className="text-steel/60">{label}</span>
      <span className="font-bold text-[#dcebfa]">{value}</span>
    </span>
  );
  const sideBlock = (s: "home" | "away") => {
    const t = team(s);
    const v = val(s);
    const b = bd(s);
    return (
      <div key={s} className="flex-1 min-w-0 flex flex-col items-center gap-1.5">
        <div className="flex items-center gap-1.5 max-w-full">
          <img
            src={t.logo}
            alt=""
            width={18}
            height={18}
            loading="lazy"
            className="w-[18px] h-[18px] object-contain shrink-0"
            onError={(e) => {
              e.currentTarget.style.visibility = "hidden";
            }}
          />
          <span className="text-[11.5px] font-bold text-[#eef5fc] truncate">{t.fa || t.name}</span>
        </div>
        <span
          className="text-[20px] font-black text-[#ecf3fa] tabular-persian leading-6"
          title="اسکوآپ (گل‌های مورد انتظار)"
        >
          {v != null ? faDigits(v.toFixed(2)) : "—"}
        </span>
        <div className="flex flex-wrap items-center justify-center gap-1">
          {b ? (
            <>
              {chip("شوت", faDigits(b.total))}
              {b.onTarget > 0 && chip("در چارچوب", faDigits(b.onTarget))}
              {b.blocked > 0 && chip("بلوکه", faDigits(b.blocked))}
              {b.post > 0 && chip("تیرک", faDigits(b.post))}
              {b.goals > 0 && chip("گل", faDigits(b.goals))}
            </>
          ) : (
            <span className="text-[10px] text-steel/50">شوتی ثبت نشده</span>
          )}
        </div>
      </div>
    );
  };
  return (
    <div className="glass-card p-3 flex flex-col gap-2.5">
      <div className="flex items-start justify-between gap-2">
        {sideBlock("away")}
        {sideBlock("home")}
      </div>
      <div className="flex h-2 rounded-full overflow-hidden gap-0.5 bg-white/[0.04]" dir="ltr">
        <div className="bg-primary h-full rounded-full transition-all" style={{ width: `${hp}%` }} />
        <div className="flex-1" />
        <div className="bg-chart-4 h-full rounded-full transition-all" style={{ width: `${100 - hp}%` }} />
      </div>
      <p className="text-[10px] text-steel/55 text-center leading-4">
        {xg.source === "stats"
          ? "اسکوآپ رسمی فوت‌ماب · سهم هر تیم در نوار نسبت اسکوآپ‌هاست"
          : "اسکوآپ حاصل مجموع شوت‌های ثبت‌شده است (ردیف رسمی فوت‌ماب موجود نبود)"}
      </p>
    </div>
  );
}

function ShotmapPitch({ shots, match }: { shots: NonNullable<DetailData["shots"]>; match: DetailMatch }) {
  const homeCount = shots.filter((s) => s.side === "home").length;
  const awayCount = shots.filter((s) => s.side === "away").length;
  return (
    <div className="glass-card p-3">
      <div className="flex items-center justify-between text-[10.5px] text-steel/80 mb-2 tabular-persian">
        <span className="font-bold">{match.away.fa || match.away.name} ({faDigits(awayCount)})</span>
        <span className="text-steel/50">جهت حمله →</span>
        <span className="font-bold">({faDigits(homeCount)}) {match.home.fa || match.home.name}</span>
      </div>
      <div dir="ltr" className="relative w-full aspect-[105/68] rounded-lg border border-glass-border-soft bg-[oklch(0.24_0.04_150/30%)] overflow-hidden">
        {/* markings */}
        <div className="absolute inset-y-0 left-1/2 w-px bg-white/15" />
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[14%] aspect-square rounded-full border border-white/15" />
        <div className="absolute inset-y-[24%] left-0 w-[10%] border border-white/15 border-l-0" />
        <div className="absolute inset-y-[24%] right-0 w-[10%] border border-white/15 border-r-0" />
        {/* dots — home attacks right (x→100); away mirrored to attack left */}
        {shots.map((s, i) => {
          const isHome = s.side === "home";
          const left = isHome ? s.x : 100 - s.x;
          const top = isHome ? s.y : 100 - s.y;
          const color = s.isGoal
            ? "bg-emerald-400 border-emerald-100 shadow-[0_0_7px_oklch(0.72_0.17_160)]"
            : s.post
              ? "bg-rose-400 border-rose-100"
              : s.blocked
                ? "bg-amber-400/90 border-amber-100"
                : s.onTarget
                  ? "bg-sky-400 border-sky-100"
                  : "bg-slate-400/80 border-slate-200/70";
          return (
            <span
              key={i}
              title={`${s.player || ""} ${s.minute} — xG ${s.xg ?? "؟"}`}
              className={cn("absolute w-[9px] h-[9px] -translate-x-1/2 -translate-y-1/2 rounded-full border", color)}
              style={{ left: `${left}%`, top: `${top}%` }}
            />
          );
        })}
      </div>
      <div className="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 mt-2 text-[10px] text-steel/80">
        <Legend color="bg-emerald-400" label="گل" />
        <Legend color="bg-sky-400" label="در چارچوب" />
        <Legend color="bg-amber-400/90" label="بلوکه" />
        <Legend color="bg-rose-400" label="تیرک" />
        <Legend color="bg-slate-400/80" label="بیرون" />
      </div>
    </div>
  );
}

// ---------- per-player match stats (update cycle-47) ----------
// «بازیکن‌ها» tab: one card per team, starters first then substitutes, sorted
// by FotMob rating. Rows are chip-based instead of a wide table so 390px never
// overflows; goalkeepers get their own chips (saves / conceded / prevented).
function ratingPillClass(r: number): string {
  if (r >= 7.5) return "bg-emerald-500/20 text-emerald-300 border-emerald-400/30";
  if (r >= 6.5) return "bg-sky-500/20 text-sky-300 border-sky-400/30";
  if (r >= 6) return "bg-white/[0.06] text-steel border-glass-border-soft";
  return "bg-rose-500/15 text-rose-300 border-rose-400/30";
}

function RatingPill({ rating }: { rating?: number }) {
  if (rating == null) return <span className="text-[10px] text-steel/40 tabular-persian">—</span>;
  return (
    <span
      className={cn(
        "inline-flex items-center justify-center min-w-[38px] px-1.5 py-0.5 rounded-md border text-[11px] font-black tabular-persian leading-4",
        ratingPillClass(rating)
      )}
      title="امتیاز فوت‌ماب"
    >
      {faDigits(rating.toFixed(2))}
    </span>
  );
}

function PlayerChip({ label, value }: { label: string; value: string }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-md bg-white/[0.045] border border-glass-border-soft px-1.5 py-0.5 text-[10px] text-steel tabular-persian leading-4">
      <span className="text-steel/60">{label}</span>
      <span className="font-bold text-[#dcebfa]">{value}</span>
    </span>
  );
}

function PlayerRow({ p }: { p: PlayerStatRow }) {
  const chips: { label: string; value: string }[] = [];
  if (p.goals) chips.push({ label: "گل", value: faDigits(p.goals) });
  if (p.assists) chips.push({ label: "پاس‌گل", value: faDigits(p.assists) });
  if (p.isGk) {
    if (p.saves != null) chips.push({ label: "مهار", value: faDigits(p.saves) });
    if (p.conceded != null) chips.push({ label: "گل خورده", value: faDigits(p.conceded) });
    if (p.goalsPrevented != null)
      chips.push({ label: "جلوی گل", value: `${p.goalsPrevented > 0 ? "+" : ""}${faDigits(p.goalsPrevented.toFixed(1))}` });
  } else {
    if (p.passesAcc != null)
      chips.push({
        label: "پاس",
        value: p.passesTotal != null ? `${faDigits(p.passesAcc)}/${faDigits(p.passesTotal)}` : faDigits(p.passesAcc),
      });
    if (p.chances) chips.push({ label: "فرصت", value: faDigits(p.chances) });
    if (p.defActions) chips.push({ label: "دفاع", value: faDigits(p.defActions) });
  }
  if (p.minutes != null) chips.push({ label: "دقیقه", value: faDigits(p.minutes) });
  return (
    <div className="glass-row-hover flex items-start justify-between gap-2.5 px-4 py-2.5 border-b border-glass-border-soft/60 last:border-b-0">
      <div className="min-w-0 flex-1 flex flex-col gap-1.5">
        <p className="flex items-center gap-1.5 min-w-0 text-[12.5px] font-bold text-[#eef5fc]">
          {p.shirt && (
            <span className="shrink-0 text-[10px] font-black text-steel/70 bg-white/[0.05] rounded px-1 py-px tabular-persian" dir="ltr">
              {faDigits(p.shirt)}
            </span>
          )}
          <Link href={`/player/${p.id}`} prefetch={false} className="truncate hover:text-sky-soft transition-colors max-w-full">
            {p.name}
          </Link>
          {p.isGk && <span className="shrink-0 text-[9px] font-bold text-amber-300/80 bg-amber-400/10 rounded px-1 py-px">دروازه‌بان</span>}
        </p>
        {chips.length > 0 && (
          <p className="flex flex-wrap items-center gap-1">
            {chips.map((c) => (
              <PlayerChip key={c.label} label={c.label} value={c.value} />
            ))}
          </p>
        )}
      </div>
      <RatingPill rating={p.rating} />
    </div>
  );
}

function PlayerTeamCard({ rows, match, side }: { rows: PlayerStatRow[]; match: DetailMatch; side: "home" | "away" }) {
  const team = side === "home" ? match.home : match.away;
  const starters = rows.filter((r) => r.starter);
  const subs = rows.filter((r) => !r.starter);
  const groups: { title: string; list: PlayerStatRow[] }[] = [];
  if (starters.length > 0) groups.push({ title: "ترکیب اصلی", list: starters });
  if (subs.length > 0) groups.push({ title: "جایگزین‌ها", list: subs });
  if (groups.length === 0) groups.push({ title: "بازیکنان", list: rows });
  return (
    <section className="glass-card overflow-hidden">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2">
        <img
          src={team.logo}
          alt=""
          width={15}
          height={15}
          className="w-[15px] h-[15px] object-contain"
          onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
        />
        <span className="font-black text-[12.5px] text-[#ecf3fa]">{team.fa || team.name}</span>
        {/* fix cycle-59: team name is the lineup section heading */}
        <h2 className="sr-only">{team.fa || team.name}</h2>
        <span className="text-[10px] text-steel/60 tabular-persian mr-auto">{faDigits(rows.length)} بازیکن</span>
      </header>
      {groups.map((grp) => (
        <div key={grp.title}>
          <p className="px-4 pt-2.5 pb-1 text-[9.5px] font-black text-steel/60">{grp.title}</p>
          {grp.list.map((p) => (
            <PlayerRow key={p.id} p={p} />
          ))}
        </div>
      ))}
    </section>
  );
}

function PlayerStatsTables({ playerStats, match }: { playerStats: NonNullable<DetailData["playerStats"]>; match: DetailMatch }) {
  return (
    <div className="flex flex-col gap-4">
      {playerStats.home.length > 0 && <PlayerTeamCard rows={playerStats.home} match={match} side="home" />}
      {playerStats.away.length > 0 && <PlayerTeamCard rows={playerStats.away} match={match} side="away" />}
      <p className="text-[10px] text-steel/50 text-center">امتیاز و آمار هر بازیکن از فوت‌ماب — بهترین‌ها بالای هر گروه</p>
    </div>
  );
}

// ---------- events timeline ----------
function EventsTimeline({ events, match }: { events: DetailEvent[]; match: DetailMatch }) {
  if (events.length === 0) {
    // cycle 45 — honest empty states: an unstarted match has no events BY DESIGN,
    // «رویدادی ثبت نشده است» was misleading for that case
    return (
      <p className="glass-card text-center text-steel text-sm py-10">
        {match.cancelled
          ? "این بازی لغو شده است."
          : match.started
            ? "رویدادی ثبت نشده است."
            : "بازی هنوز شروع نشده است؛ رویدادها پس از سوت شروع همین‌جا نمایش داده می‌شوند."}
      </p>
    );
  }
  return (
    <div className="glass-card overflow-hidden">
      <div className="glass-list">
        {events.map((e, i) => (
          <div
            key={i}
            className={cn(
              "glass-row-hover grid grid-cols-[1fr_auto_1fr] items-center gap-2 px-4 py-2.5 text-[12.5px]",
              e.side === "home" && "bg-sky-soft/[0.045]"
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
      <div className="px-4 py-2 text-[10px] text-steel/60 border-t border-glass-border-soft">
        {match.home.fa || match.home.name} — رویدادهای سمت راست | {match.away.fa || match.away.name} — رویدادهای سمت چپ
      </div>
    </div>
  );
}

// ---------- stats ----------
function StatBars({ groups, started }: { groups: DetailStatGroup[]; started?: boolean }) {
  if (groups.length === 0) {
    return (
      <p className="glass-card text-center text-steel text-sm py-10">
        {started ? "آماری برای این بازی ثبت نشده است." : "آمار پس از شروع بازی این‌جا نمایش داده می‌شود."}
      </p>
    );
  }
  return (
    <div className="flex flex-col gap-4">
      {groups.map((g, gi) => (
        <div key={gi} className="glass-card overflow-hidden">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center justify-between text-[11px]">
            <span className="font-bold text-steel tabular-persian">{faDigits(g.rows[0]?.home || "0")}</span>
            <span className="font-black text-[12px] text-[#ecf3fa]">{g.title}</span>
            <span className="font-bold text-steel tabular-persian">{faDigits(g.rows[0]?.away || "0")}</span>
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

// update cycle-97: attacking zones («جهت حملات») — stacked three-lane bar per
// team (چپ/مرکز/راست shares of the team's attacking output, TOTAL split).
// Same hue convention as StatBars: home = primary, away = chart-4, with an
// opacity ramp distinguishing the lanes; values restated under each bar so
// the ramp alone never carries the meaning.
function ZoneCard({ zones, match }: { zones: NonNullable<DetailData["zones"]>; match: DetailMatch }) {
  const LANES = [
    { key: "left" as const, fa: "چپ" },
    { key: "center" as const, fa: "مرکز" },
    { key: "right" as const, fa: "راست" },
  ];
  const row = (z: { left: number; center: number; right: number }, name: string, base: string) => (
    <div className="flex flex-col gap-1.5">
      <p className="text-[11.5px] font-black text-[#e6f0fb] truncate">{name}</p>
      <div className="flex h-2 rounded-full overflow-hidden gap-px" dir="ltr">
        {LANES.map((l, i) => (
          <div
            key={l.key}
            className={cn(i === 0 ? base : i === 1 ? `${base} opacity-60` : `${base} opacity-30`, "h-full")}
            style={{ width: `${(z[l.key] / (z.left + z.center + z.right || 1)) * 100}%` }}
            title={`${l.fa}: ${z[l.key]}٪`}
          />
        ))}
      </div>
      <p className="text-[9.5px] text-muted-foreground tabular-persian">
        {LANES.map((l, i) => (
          <span key={l.key}>
            {i > 0 && " · "}
            {faDigits(z[l.key])}٪ {l.fa}
          </span>
        ))}
      </p>
    </div>
  );
  return (
    <div className="glass-card overflow-hidden" data-testid="match-zones">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center justify-between text-[11px]">
        <span className="font-black text-[12px] text-[#ecf3fa]">جهت حملات</span>
        <span className="font-bold text-steel/80">سهم از کل حملات</span>
      </header>
      <div className="p-3 flex flex-col gap-3.5">
        {row(zones.home, match.home.fa || match.home.name, "bg-primary")}
        {row(zones.away, match.away.fa || match.away.name, "bg-chart-4")}
      </div>
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
            <span className="text-[10px] font-bold text-steel border border-glass-border-soft rounded-md px-1.5 py-0.5" dir="ltr">
              {t.formation}
            </span>
          )}
        </div>
        <div className="rounded-2xl border border-glass-border-soft bg-white/[0.02] p-2.5 flex flex-col gap-1.5 min-h-[240px] justify-around">
          {t.rows.map((row, ri) => (
            <div key={ri} className="flex justify-center gap-1.5 flex-wrap">
              {row.players.map((p) => (
                <Link
                  key={p.id}
                  href={`/player/${p.id}`}
                  prefetch={false}
                  className="flex flex-col items-center gap-0.5 min-w-0 hover:opacity-80 transition-opacity"
                  title={`${p.name} — پروفایل بازیکن`}
                >
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
                </Link>
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
                <Link
                  key={s.id}
                  href={`/player/${s.id}`}
                  prefetch={false}
                  className="border border-glass-border-soft bg-white/[0.03] rounded-lg px-2 py-1 text-[10px] flex items-center gap-1.5 hover:border-sky-soft/40 hover:text-sky-soft transition-colors"
                >
                  {s.shirt && <span className="text-muted-foreground tabular-persian">{faDigits(s.shirt)}</span>}
                  {s.name}
                </Link>
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

// update cycle-100: match weather («وضعیت هوا») on the info tab — rows-only
// card (same rhythm as the info list); the badge in the header states the
// data mode honestly: upcoming matches carry the upstream forecast
// («پیش‌بینی»), started/finished ones the observed conditions
// («مشاهده‌شده»). Wind/precipitation rows are deliberately absent — the
// upstream values carry no verified unit (honest omission, cycle-100).
function WeatherIcon({ className }: { className?: string }) {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" className={className} aria-hidden>
      <path d="M17.5 19a4.5 4.5 0 1 0-.9-8.9 6 6 0 1 0-11.3 2.4A3.5 3.5 0 0 0 6.5 19h11z" />
    </svg>
  );
}
function WeatherCard({ weather }: { weather: NonNullable<DetailData["weather"]> }) {
  const rows: { label: string; value?: string }[] = [
    { label: "وضعیت", value: weather.condition || undefined },
    { label: "دما", value: typeof weather.temperature === "number" ? `${faDigits(weather.temperature)}°` : undefined },
    { label: "رطوبت", value: typeof weather.humidity === "number" ? `${faDigits(weather.humidity)}٪` : undefined },
    { label: "پوشش ابر", value: typeof weather.cloudCover === "number" ? `${faDigits(weather.cloudCover)}٪` : undefined },
    { label: "احتمال بارش", value: typeof weather.precipChance === "number" ? `${faDigits(weather.precipChance)}٪` : undefined },
  ].filter((r) => r.value);
  if (rows.length === 0) return null;
  return (
    <div className="glass-card overflow-hidden" data-testid="match-weather">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center justify-between text-[11px]">
        <span className="font-black text-[12px] text-[#ecf3fa] flex items-center gap-1.5">
          <WeatherIcon className="text-chart-3" />
          وضعیت هوا
        </span>
        <span className="font-bold text-steel/80">{weather.forecast ? "پیش‌بینی" : "مشاهده‌شده"}</span>
      </header>
      <ul className="glass-list">
        {rows.map((r) => (
          <li key={r.label} className="flex items-center justify-between px-4 py-2.5 text-[12px]">
            <span className="text-steel font-bold">{r.label}</span>
            <span className="font-semibold text-start">{r.value}</span>
          </li>
        ))}
      </ul>
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
    return <p className="glass-card text-center text-steel text-sm py-10">اطلاعات تکمیلی ثبت نشده است.</p>;
  }
  return (
    <div className="glass-card overflow-hidden">
      <ul className="glass-list">
        {rows.map((r, i) => (
          <li key={i} className="flex items-center justify-between px-4 py-3 text-[12.5px]">
            <span className="text-steel font-bold">{r.label}</span>
            <span className="font-semibold text-start">{r.value}</span>
          </li>
        ))}
      </ul>
      {data.form && (
        <div className="border-t border-glass-border-soft px-4 py-3 flex flex-col gap-2.5">
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
    <section className="glass-card p-4">
      <header className="flex items-center justify-between gap-2 mb-3">
        <span className="flex items-center gap-1.5 min-w-0">
          { }
          <img src={comparison.home.logo} alt="" width={20} height={20} className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
          <span className="font-black text-[12px] truncate">{sideName(comparison.home)}</span>
        </span>
        <h2 className="text-[10px] font-black text-steel whitespace-nowrap">مقایسه فصل</h2>
        <span className="flex items-center gap-1.5 min-w-0 justify-end">
          <span className="font-black text-[12px] truncate">{sideName(comparison.away)}</span>
          { }
          <img src={comparison.away.logo} alt="" width={20} height={20} className="w-5 h-5 object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
        </span>
      </header>
      <div className="glass-list">
        {rows.map((r) => {
          const max = Math.max(r.h ?? 0, r.a ?? 0, 0.0001);
          const hw = r.h != null ? Math.max((r.h / max) * 100, r.h > 0 ? 6 : 0) : 0;
          const aw = r.a != null ? Math.max((r.a / max) * 100, r.a > 0 ? 6 : 0) : 0;
          return (
            <div key={r.label} className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 py-1.5">
              {/* home side (start = right in RTL) */}
              <div className="flex items-center justify-start gap-1.5 min-w-0">
                <div className="w-12 sm:w-20 h-1.5 rounded-full bg-white/[0.06] overflow-hidden flex justify-start shrink-0">
                  <div className="h-full bg-primary/80 rounded-full" style={{ width: `${hw}%` }} />
                </div>
                <span className="text-[11px] font-black tabular-persian">{fmt(r.h, r.digits)}</span>
              </div>
              <span className="text-[9.5px] font-bold text-muted-foreground w-14 sm:w-16 text-center shrink-0">{r.label}</span>
              {/* away side (end = left in RTL) */}
              <div className="flex items-center justify-end gap-1.5 min-w-0">
                <span className="text-[11px] font-black tabular-persian">{fmt(r.a, r.digits)}</span>
                <div className="w-12 sm:w-20 h-1.5 rounded-full bg-white/[0.06] overflow-hidden flex justify-end shrink-0">
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
        m.finished ? "bg-white/[0.04]" : "text-foreground/80"
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
    <div className="glass-row-hover flex items-center gap-3 px-3 sm:px-4 py-2.5">
      <div className="flex flex-col shrink-0 min-w-[84px]">
        <span className="text-[10px] font-bold text-muted-foreground tabular-persian whitespace-nowrap">
          {j.weekday} {faDigits(j.day)} {j.month}
        </span>
        <span className="text-[9px] text-muted-foreground/70 truncate max-w-full">{m.leagueFa}</span>
      </div>
      <div className="flex-1 flex items-center gap-2 min-w-0">{teams}</div>
      {m.finished ? (
        m.reason && m.reason !== "FT" ? (
          <span className="shrink-0 text-[9px] font-bold text-steel border border-glass-border-soft rounded-md px-1.5 py-0.5">{m.reason}</span>
        ) : null
      ) : (
        <span className="shrink-0 text-[9px] font-black text-sky-soft border border-sky-soft/25 bg-sky-soft/10 rounded-md px-1.5 py-0.5">پیش‌رو</span>
      )}
    </div>
  );
}

function H2HPanel({ data, loading }: { data: H2HData | null; loading: boolean }) {
  if (loading && !data) {
    return (
      <div className="glass-card p-4 flex flex-col gap-3" aria-busy="true">
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
      <p className="glass-card text-center text-steel text-sm py-10">
        {data?.error || "سابقه رو در رو در دسترس نیست."}
      </p>
    );
  }
  if (!data.hasData) {
    return <p className="glass-card text-center text-steel text-sm py-10">سابقه‌ای از دیدار این دو تیم ثبت نشده است.</p>;
  }

  const { totals, home, away } = data;
  const { played } = totals;
  const pct = (n: number) => (played > 0 ? (n / played) * 100 : 0);

  return (
    <div className="flex flex-col gap-4">
      {/* summary card */}
      <section className="glass-card p-4">
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
        <div className="flex h-2.5 rounded-full overflow-hidden bg-white/[0.06]" dir="rtl" aria-hidden>
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
        <div className="glass-card overflow-hidden">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft text-[11px] font-black text-steel">
            آخرین دیدارها
          </header>
          <div className="glass-list">
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
        <div className="glass-card overflow-hidden">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft text-[11px] font-black text-steel">
            دیدارهای پیش‌روی این دو تیم
          </header>
          <div className="glass-list">
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
        <div className="glass-card p-8 flex flex-col items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-white/[0.04] border border-glass-border-soft flex items-center justify-center">
            <span className="rune-spin text-lg" aria-hidden>◆</span>
          </div>
          <div className="h-8 w-32 rounded bg-white/[0.05] animate-pulse summon-glyph" />
          <div className="h-4 w-48 rounded bg-white/[0.05] animate-pulse summon-glyph" />
        </div>
        <div className="glass-card h-48 animate-pulse summon-glyph" />
      </div>
    );
  }

  if (error && !data) {
    return (
      <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-5 py-8 text-center">
        <h1 className="sr-only">جزئیات مسابقه</h1>
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

      <Scoreboard m={m} scorers={data.scorers || []} potm={data.playerOfTheMatch} shootout={data.shootout} />

      {/* momentum (live) */}
      {data.momentum && data.momentum.length > 4 && (
        <section className="glass-card p-3.5">
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
                <div className="w-full h-px bg-glass-border-soft" />
                <div className="flex-1">
                  {p.value < 0 && <div className={cn("rounded-b-sm", p.value < -40 ? "bg-chart-4/80" : "bg-chart-4/35")} style={{ height: `${-p.value}%` }} />}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* tabs */}
      <nav className="flex items-center gap-1 border-b border-glass-border-soft -mx-1 px-1 overflow-x-auto" aria-label="بخش‌های مسابقه">
        {TAB_LABELS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            aria-current={tab === t.key ? "page" : undefined}
            className={cn(
              "relative shrink-0 px-3.5 py-2 text-[12.5px] font-bold transition-colors press-fx tab-rune",
              tab === t.key ? "text-primary" : "text-muted-foreground hover:text-foreground"
            )}
          >
            {t.label}
          </button>
        ))}
      </nav>

      <div className={cn(loading && "opacity-50 transition-opacity")}>
        {tab === "events" && (
          <div className="flex flex-col gap-4">
            {data.playerOfTheMatch && <PotmCard p={data.playerOfTheMatch} />}
            {data.shootout && <ShootoutCard shootout={data.shootout} match={m} />}
            <EventsTimeline events={data.events} match={m} />
          </div>
        )}
        {tab === "stats" && (
          <>
            <StatBars groups={data.statGroups} started={m.started && !m.cancelled} />
            {data.zones && <ZoneCard zones={data.zones} match={m} />}
          </>
        )}
        {tab === "shots" && (data.xg || (data.shots && data.shots.length > 0)) && (
          <div className="flex flex-col gap-4">
            {data.xg && <TeamXgStrip xg={data.xg} match={m} />}
            {data.shots && data.shots.length > 0 && <ShotmapPitch shots={data.shots} match={m} />}
          </div>
        )}
        {tab === "shots" && !data.xg && (!data.shots || data.shots.length === 0) && (
          <p className="glass-card text-center text-steel text-sm py-10">شوتی برای این مسابقه ثبت نشده است.</p>
        )}
        {tab === "players" && data.playerStats && <PlayerStatsTables playerStats={data.playerStats} match={m} />}
        {tab === "players" && !data.playerStats && (
          <p className="glass-card text-center text-steel text-sm py-10">آماری برای بازیکنان این مسابقه ثبت نشده است.</p>
        )}
        {tab === "lineups" &&
          (data.lineups ? (
            <LineupsPitch lineups={data.lineups} match={m} />
          ) : (
            <EmptyState
              icon="shirt"
              compact
              title="ترکیب بازیکنان هنوز اعلام نشده است"
              sub="ترکیب معمولاً ۲۰ تا ۴۰ دقیقه پیش از شروع بازی اعلام می‌شود."
            />
          ))}
        {tab === "info" && (
          <div className="flex flex-col gap-4">
            {data.weather && <WeatherCard weather={data.weather} />}
            <InfoPanel data={data} />
          </div>
        )}
        {tab === "h2h" && <H2HPanel data={h2h} loading={h2hLoading} />}
      </div>
    </div>
  );
}
