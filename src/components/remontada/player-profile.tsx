// ------------------------------------------------------------------
// Remontada — player profile (pure server component, no "use client")
// Rendered inside the SSR /player/[id] page; all data arrives as props
// so the markup is present in the initial HTML (SEO + no-JS friendly).
// ------------------------------------------------------------------
import Link from "next/link";
import type { PlayerData, PlayerPitch, PlayerShot, PlayerLinkRow } from "@/lib/fotmob";
import { faDigits, jalaliShort, marketValueFa, tehranTime } from "@/lib/format";
import { countryFa, teamFa } from "@/lib/leagues";
import { cn } from "@/lib/utils";
import { ShareButton } from "./share-button";
import { PlayerPhoto } from "./player-photo";
import { TeamLogo } from "./team-logo";
import { JsonLd } from "./json-ld";
import { RecentMatchesSection } from "./player-recent";

function StatBox({ display, title, accent }: { display: string; title: string; accent?: boolean }) {
  return (
    <div className="rounded-lg bg-[#a9cdf611] border border-glass-border-soft px-2 py-2.5 text-center">
      <p className={cn("font-medium text-[15px] text-[#e0efff] tabular-persian leading-6", accent && "text-chart-3")} dir="ltr">
        {faDigits(display)}
      </p>
      <p className="text-[9px] text-steel/80 truncate">{title}</p>
    </div>
  );
}

function InfoChip({ label, value }: { label: string; value: string }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-lg border border-glass-border-soft bg-white/[0.03] px-2.5 py-1 text-[10.5px]">
      <span className="text-steel/80">{label}</span>
      <span className="font-bold">{value}</span>
    </span>
  );
}

// cycle-87: season shot map + touch heatmap — pure SSR SVG (no client JS),
// probed shapes: shotmap (outfield) / keeperShotmap (GK, shots faced) with
// x/y 0-100 pitch coords, expectedGoals per shot, heatmap touch coordinates.
// Dots: gold = goal, sky = on target, muted = off target/blocked; radius
// scales with xG. Pitch lines at low opacity; heat as soft sky dots.
function PitchSection({ pitch }: { pitch: PlayerPitch }) {
  const px = (x: number) => 1 + (x / 100) * 98; // map 0-100 → 1-99 (viewBox 100×64)
  const py = (y: number) => 1 + (y / 100) * 62;
  const shotR = (xg: number | null) => Math.min(1.4 + Math.sqrt(xg || 0) * 2.6, 5);
  const shotFill = (s: PlayerShot) =>
    s.goal ? "var(--gold)" : s.onTarget ? "var(--sky-soft)" : "var(--steel)";
  const shotTitle = (s: PlayerShot) =>
    [
      `${faDigits(s.min)}′`,
      s.typeFa || "",
      s.xg !== null ? `xG ${faDigits(String(Math.round(s.xg * 100) / 100))}` : "",
      s.by ? `شوت‌زن: ${s.by}` : "",
    ]
      .filter(Boolean)
      .join(" · ");
  const summary = pitch.keeper
    ? `${faDigits(pitch.shots.length)} شوت رو‌به‌رو · ${faDigits(pitch.goals)} گل خورده${pitch.xgTotal !== null ? ` · xG ${faDigits(String(pitch.xgTotal))}` : ""}`
    : `${faDigits(pitch.goals)} گل از ${faDigits(pitch.shots.length)} شوت${pitch.xgTotal !== null ? ` · xG مجموع ${faDigits(String(pitch.xgTotal))}` : ""}`;
  return (
    <section className="glass-card overflow-hidden" aria-label={pitch.keeper ? "شوت‌های رو‌به‌رو" : "نقشهٔ شوت‌ها"} data-testid="player-pitch">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft text-[12px] font-black">
        {pitch.keeper ? "شوت‌های رو‌به‌رو" : "نقشهٔ شوت‌ها"}{" "}
        <span className="text-muted-foreground font-bold text-[10.5px] tabular-persian">({summary})</span>
      </header>
      <div className="px-3 sm:px-4 pt-3" dir="ltr">
        <svg viewBox="0 0 100 64" className="w-full block" role="img" aria-label={pitch.keeper ? "جای شوت‌های رو‌به‌رو روی زمین" : "جای شوت‌ها روی زمین"}>
          {/* pitch lines */}
          <g stroke="currentColor" strokeWidth="0.45" fill="none" opacity="0.22" className="text-muted-foreground">
            <rect x="1" y="1" width="98" height="62" />
            <line x1="50" y1="1" x2="50" y2="63" />
            <circle cx="50" cy="32" r="8.2" />
            <rect x="1" y="13.8" width="15.5" height="36.4" />
            <rect x="83.5" y="13.8" width="15.5" height="36.4" />
            <rect x="1" y="24.4" width="5.8" height="15.2" />
            <rect x="93.2" y="24.4" width="5.8" height="15.2" />
          </g>
          {/* touch heatmap */}
          {pitch.heat.length > 0 && (
            <g>
              {pitch.heat.map((c, i) => (
                <circle key={`h${i}`} cx={px(c.x)} cy={py(c.y)} r="1.05" fill="var(--sky-soft)" opacity="0.14" />
              ))}
            </g>
          )}
          {/* shots */}
          {pitch.shots.map((s, i) => (
            <circle
              key={`s${i}`}
              cx={px(s.x)}
              cy={py(s.y)}
              r={shotR(s.xg)}
              fill={shotFill(s)}
              opacity={s.goal ? 0.95 : 0.6}
              stroke={s.goal ? "var(--background)" : "none"}
              strokeWidth="0.35"
            >
              <title>{shotTitle(s)}</title>
            </circle>
          ))}
        </svg>
      </div>
      <div className="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 sm:px-4 py-2.5 text-[9px] font-bold text-muted-foreground" dir="rtl">
        <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full inline-block" style={{ background: "var(--gold)" }} />{pitch.keeper ? "گل خورده" : "گل"}</span>
        <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full inline-block" style={{ background: "var(--sky-soft)" }} />{pitch.keeper ? "مهارشده" : "در چارچوب"}</span>
        <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full inline-block" style={{ background: "var(--steel)" }} />خارج یا بلاک</span>
        <span>اندازهٔ نقطه = خطر xG</span>
        {pitch.heat.length > 0 && (
          <span className="tabular-persian">· {faDigits(pitch.heat.length)} لمس</span>
        )}
      </div>
    </section>
  );
}

// ---------- update cycle-197: squad navigation («هم‌تیمی‌ها») ----------
// Two chip groups off the SAME cached playerData payload (zero extra
// upstream fetch): the current club squad and the national-team squad-mates.
// Every chip = a real /player/[id] link (the 172 family — every id serves a
// full profile, probed 167-style). Honest absence: the card only renders
// when at least one group is non-empty; a group with no rows is omitted
// (the womensNationalTeam rows are empty on every probe — the merged
// national list stays empty for them and only the club group shows).
// nameFa rides the 104 map; unmapped rows render the honest Latin name
// (the 92/107 contract) with the original name in the title attr.
function TeammatesCard({ club, national, teamFa }: { club: PlayerLinkRow[]; national: PlayerLinkRow[]; teamFa?: string }) {
  return (
    <section className="glass-card overflow-hidden" aria-label="هم‌تیمی‌ها" data-testid="player-teammates">
      <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-sky-400" aria-hidden>
          <circle cx="9" cy="8" r="3.2" />
          <path d="M3.5 19c.6-3 2.8-4.8 5.5-4.8s4.9 1.8 5.5 4.8" />
          <circle cx="17" cy="9.5" r="2.6" />
          <path d="M15.5 14.6c2.4.2 4.3 1.7 4.9 4.4" />
        </svg>
        هم‌تیمی‌ها
        <span className="ms-auto text-[9.5px] font-bold text-muted-foreground tabular-persian">
          {faDigits(club.length + national.length)} بازیکن
        </span>
      </header>
      <div className="px-4 py-3.5">
        {club.length > 0 && (
          <div data-testid="player-teammates-club">
            <p className="text-[9.5px] text-muted-foreground mb-1.5">
              باشگاه{teamFa ? ` · ${teamFa}` : ""}
              <span className="tabular-persian"> · {faDigits(club.length)} بازیکن</span>
            </p>
            <div className="flex flex-wrap gap-1.5">
              {club.map((t) => (
                <Link
                  key={`c${t.id}`}
                  href={`/player/${t.id}`}
                  title={t.name}
                  data-testid="player-teammate-chip"
                  className="inline-flex items-center rounded-lg px-2.5 py-1.5 text-[10.5px] font-bold bg-white/[0.03] border border-glass-border-soft text-[#c8dcf2]/85 transition-colors hover:bg-sky-500/10 hover:border-sky-400/25"
                >
                  {t.nameFa}
                </Link>
              ))}
            </div>
          </div>
        )}
        {national.length > 0 && (
          <div className={club.length > 0 ? "mt-3.5" : undefined} data-testid="player-teammates-national">
            <p className="text-[9.5px] text-muted-foreground mb-1.5">
              تیم ملی
              <span className="tabular-persian"> · {faDigits(national.length)} بازیکن</span>
            </p>
            <div className="flex flex-wrap gap-1.5">
              {national.map((t) => (
                <Link
                  key={`n${t.id}`}
                  href={`/player/${t.id}`}
                  title={t.name}
                  data-testid="player-teammate-chip"
                  className="inline-flex items-center rounded-lg px-2.5 py-1.5 text-[10.5px] font-bold bg-white/[0.03] border border-glass-border-soft text-[#c8dcf2]/85 transition-colors hover:bg-sky-500/10 hover:border-sky-400/25"
                >
                  {t.nameFa}
                </Link>
              ))}
            </div>
          </div>
        )}
        <p className="text-[9px] text-muted-foreground leading-4 mt-2.5">
          ترکیب فعلی باشگاه و تیم ملی طبق آرشیو فوت‌ماب؛ هر چیپ لینک مستقیم پروفایل است.
        </p>
      </div>
    </section>
  );
}

export function PlayerProfile({ p }: { p: PlayerData }) {
  const j = jalaliShort;
  // poster treatment: the season's headline metric (goals, else rating)
  // gets the oversized light number of the studio scoring-chart hero
  const seasonStats = p.season?.stats ?? [];
  const featuredStat =
    seasonStats.find((s) => s.key === "goals") ??
    seasonStats.find((s) => s.key === "rating") ??
    seasonStats[0] ?? null;
  const restStats = featuredStat ? seasonStats.filter((s) => s !== featuredStat) : seasonStats;
  const teamName = p.team?.fa || p.team?.name || "";
  const chips: { label: string; value: string }[] = [];
  if (p.info.age) chips.push({ label: "سن", value: faDigits(p.info.age) });
  if (p.info.height) {
    const h = String(p.info.height).replace(/cm/i, "").trim();
    chips.push({ label: "قد", value: /\d/.test(h) ? `${faDigits(h)} سانتی‌متر` : faDigits(h) });
  }
  if (p.info.shirt) chips.push({ label: "پیراهن", value: faDigits(p.info.shirt) });
  if (p.info.foot) chips.push({ label: "پای ترجیحی", value: p.info.foot });
  if (p.info.country) chips.push({ label: "کشور", value: countryFa(p.info.country) });
  // cycle-86: probed playerData.isCaptain — explicit false when not captain
  if (p.isCaptain) chips.push({ label: "کاپیتان", value: "بله" });
  if (p.info.marketValue) chips.push({ label: "ارزش بازار", value: marketValueFa(p.info.marketValue) });
  if (p.info.contractEnd) chips.push({ label: "پایان قرارداد", value: faDigits(p.info.contractEnd) });

  const personLd = {
    "@context": "https://schema.org",
    "@type": "Person",
    name: p.name,
    url: `/player/${p.id}`,
    ...(p.positionEn ? { jobTitle: p.positionEn } : {}),
    ...(p.team
      ? {
          affiliation: {
            "@type": "SportsTeam",
            name: p.team.name,
            ...(p.team.fa ? { alternateName: p.team.fa } : {}),
            url: `/team/${p.team.id}`,
          },
        }
      : {}),
    ...(p.info.country ? { nationality: { "@type": "Country", name: p.info.country } } : {}),
  };

  // cycle-82: market-value sparkline geometry (x 1..99, y 3..27 in a 101×30 viewBox)
  let marketPts: string | null = null;
  let marketLastY = 0;
  if (p.market && p.market.points.length > 1) {
    const vals = p.market.points;
    const min = Math.min(...vals);
    const max = Math.max(...vals);
    const span = max - min || 1;
    marketPts = vals
      .map((v, i) => `${(1 + (i / (vals.length - 1)) * 98).toFixed(2)},${(27 - ((v - min) / span) * 24).toFixed(2)}`)
      .join(" ");
    marketLastY = 27 - ((vals[vals.length - 1] - min) / span) * 24;
  }

  return (
    <div className="flex flex-col gap-4">
      <JsonLd data={personLd} />

      {/* ---------- header ---------- */}
      <section className="glass-scorer-hero overflow-hidden">
        <div className="px-4 py-4 flex items-center gap-3.5">
          {/* cycle-130: real headshot (image_resources/playerimages) with the initials tile as fallback */}
          <PlayerPhoto id={p.id} name={p.nameFa || p.name || "؟"} size={60} suffix="" />
          <div className="min-w-0 flex-1">
            {/* cycle-106: honest Persian display name (English kept as tooltip when mapped) */}
            <h1 className="font-black text-lg leading-7 truncate text-[#f1f7fd]" dir="auto" title={p.nameFa && p.nameFa !== p.name ? p.name : undefined}>{p.nameFa || p.name}</h1>
            <p className="text-[11px] text-steel flex items-center gap-1.5 flex-wrap mt-0.5">
              {p.positionFa && <span className="font-bold text-[#ecf3fa]/85">{p.positionFa}</span>}
              {p.team && (
                <>
                  {p.positionFa && <span aria-hidden>·</span>}
                  <Link
                    href={`/team/${p.team.id}`}
                    className="inline-flex items-center gap-1.5 hover:text-sky-soft transition-colors font-bold"
                    prefetch={false}
                  >
                    <TeamLogo id={p.team.id} alt="" size={14} />
                    <span>{teamName}</span>
                  </Link>
                </>
              )}
              {p.status && p.status !== "active" && (
                <span className="rounded-md border border-amber-400/30 bg-amber-400/10 text-amber-400 px-1.5 py-0.5 text-[9.5px] font-black">
                  {p.status === "injured" ? "مصدومیت" : p.status}
                </span>
              )}
            </p>
          </div>
          <ShareButton title={`${p.name} — پروفایل بازیکن | رمانتادا`} path={`/player/${p.id}`} size={28} />
        </div>
        {chips.length > 0 && (
          <div className="px-4 pb-3.5 flex items-center flex-wrap gap-1.5">
            {chips.map((c) => (
              <InfoChip key={c.label} label={c.label} value={c.value} />
            ))}
          </div>
        )}
      </section>

      {/* ---------- injury status (cycle-96) ---------- */}
      {p.injury && (
        <section className="glass-card overflow-hidden" aria-label="وضعیت مصدومیت" data-testid="player-injury">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-amber-400" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <path d="M12 8v8" />
              <path d="M8 12h8" />
            </svg>
            وضعیت مصدومیت
            <span className="ms-auto text-[9.5px] font-bold text-muted-foreground">وضعیت اعلامی فوت‌ماب</span>
          </header>
          <div className="px-4 py-3.5 flex flex-col gap-2.5">
            <div className="flex items-center justify-between gap-3">
              <span className="text-[10.5px] font-black text-steel shrink-0">نوع آسیب</span>
              <span
                className="text-[12.5px] font-black text-amber-400 text-end"
                title={p.injury.nameEn || p.injury.nameFa}
              >
                {p.injury.nameFa}
              </span>
            </div>
            {p.injury.returnFa && (
              <div className="flex items-center justify-between gap-3">
                <span className="text-[10.5px] font-black text-steel shrink-0">بازگشت پیش‌بینی‌شده</span>
                <span className="text-[12px] font-bold text-[#e8f2fc] text-end">{p.injury.returnFa}</span>
              </div>
            )}
            {p.injury.updatedFa && (
              <div className="flex items-center justify-between gap-3">
                <span className="text-[10.5px] font-black text-steel shrink-0">آخرین به‌روزرسانی</span>
                <span className="text-[12px] font-bold text-[#e8f2fc] text-end tabular-persian">{p.injury.updatedFa}</span>
              </div>
            )}
            <p className="text-[9px] text-muted-foreground leading-4">
              جزئیات غیبت بر اساس گزارش فوت‌ماب؛ زمان بازگشت تخمینی است و ممکن است تغییر کند.
            </p>
          </div>
        </section>
      )}

      {/* ---------- playing positions (cycle-135) ---------- */}
      {p.positions && p.positions.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label="پست‌های بازی" data-testid="player-positions">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-sky-400" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <circle cx="12" cy="12" r="3.5" />
              <path d="M12 3v5.5M12 15.5V21M3 12h5.5M15.5 12H21" />
            </svg>
            پست‌های بازی
            <span className="ms-auto text-[9.5px] font-bold text-muted-foreground">ترکیب‌های اعلامی فوت‌ماب</span>
          </header>
          <div className="px-4 py-3.5">
            <div className="flex flex-wrap gap-1.5">
              {p.positions.map((s) => (
                <span
                  key={s.en}
                  title={s.en}
                  className={cn(
                    "inline-flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-[10.5px] font-black border",
                    s.isMain
                      ? "bg-sky-500/15 border-sky-400/30 text-[#d9edff]"
                      : "bg-white/[0.03] border-glass-border-soft text-[#c8dcf2]/85"
                  )}
                >
                  {s.isMain && (
                    <svg width="9" height="9" viewBox="0 0 24 24" fill="currentColor" className="text-sky-400" aria-label="پست اصلی">
                      <path d="M12 2l2.6 6.9L22 9.3l-5.4 4.8 1.6 7-6.2-3.7-6.2 3.7 1.6-7L2 9.3l7.4-.4z" />
                    </svg>
                  )}
                  {s.fa}
                  <span className="text-[9px] font-bold text-steel/80 tabular-persian">{faDigits(String(s.occurrences))} بازی</span>
                </span>
              ))}
            </div>
            <p className="text-[9px] text-muted-foreground leading-4 mt-2.5">
              شمارِ بازی‌ها در هر پست بر اساس آرشیو فوت‌ماب است؛ پست اصلی با ستاره نشان شده.
            </p>
          </div>
        </section>
      )}

      {/* ---------- season stats ---------- */}
      {p.season && (
        <section className="glass-card overflow-hidden" aria-label="آمار فصل">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center justify-between text-[11px]">
            <span className="font-black text-[12px] text-[#ecf3fa]">آمار فصل {faDigits(p.season.season)}</span>
            <span className="font-bold text-steel/80">{p.season.leagueFa}</span>
          </header>
          {featuredStat && (
            <div className="px-4 pt-4 pb-1.5 flex items-end justify-between gap-3">
              <div className="flex flex-col min-w-0">
                <span className="text-[38px] font-light text-[#dfedff] leading-none tabular-persian" dir="ltr">
                  {faDigits(featuredStat.display)}
                </span>
                <span className="text-[10.5px] font-black text-steel mt-2">{featuredStat.title}</span>
              </div>
              <p className="text-[9px] font-bold tracking-[0.22em] text-steel/80 uppercase text-end shrink-0 pb-1.5">
                {p.season.leagueFa}
              </p>
            </div>
          )}
          {restStats.length > 0 && (
            <div className="px-4 py-3.5 grid grid-cols-3 sm:grid-cols-4 gap-2">
              {restStats.map((s, i) => (
                <StatBox key={`${s.key}-${i}`} display={s.display} title={s.title} accent={s.key === "rating"} />
              ))}
            </div>
          )}
        </section>
      )}

      {/* ---------- deep season performance (cycle-82) ---------- */}
      {p.deepStats && p.deepStats.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label="عملکرد فصل" data-testid="player-deep-stats">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-sky-soft" aria-hidden>
              <path d="M3 3v18h18" />
              <path d="M7 15l4-5 3 3 5-7" />
            </svg>
            عملکرد فصل
            <span className="ms-auto text-[9.5px] font-bold text-muted-foreground">صدک فوت‌ماب · مقایسه با هم‌پست‌ها</span>
          </header>
          <div className="px-3 sm:px-4 py-3.5 flex flex-col gap-4">
            {p.deepStats.map((g) => (
              <div key={g.fa}>
                <p className="text-[11px] font-black text-sky-soft mb-2">{g.fa}</p>
                <div className="grid sm:grid-cols-2 gap-x-6 gap-y-3">
                  {g.stats.map((s, i) => (
                    <div key={`${s.fa}-${i}`}>
                      <div className="flex items-baseline justify-between gap-2">
                        <span className="text-[11.5px] font-bold text-[#dcebf9] truncate">{s.fa}</span>
                        <span className="text-[12.5px] font-black tabular-persian text-[#e8f2fc] shrink-0">{s.value}</span>
                      </div>
                      {s.pct !== null && (
                        <div className="flex items-center gap-2 mt-1">
                          <div className="h-1 flex-1 rounded-full bg-white/[0.06] overflow-hidden" aria-hidden="true">
                            <div className="h-full rounded-full bg-gold/70" style={{ width: `${s.pct}%` }} />
                          </div>
                          <span className="text-[8.5px] text-muted-foreground tabular-persian shrink-0 whitespace-nowrap">
                            صدک {faDigits(s.pct)}
                            {s.per90 !== null ? ` · هر ۹۰ دقیقه ${s.per90}` : ""}
                          </span>
                        </div>
                      )}
                      {s.pct === null && s.per90 !== null && (
                        <p className="text-[8.5px] text-muted-foreground tabular-persian mt-0.5">هر ۹۰ دقیقه {s.per90}</p>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ---------- traits vs positional peers (cycle-82) ---------- */}
      {p.traits && p.traits.items.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label={p.traits.titleFa} data-testid="player-traits">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-sky-soft" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <path d="M12 7v5l3 2" />
            </svg>
            {p.traits.titleFa}
          </header>
          <ul className="glass-list">
            {p.traits.items.map((t, i) => (
              <li key={`${t.fa}-${i}`} className="px-3 sm:px-4 py-2 flex items-center gap-3">
                <span className="text-[11.5px] font-bold w-28 sm:w-36 shrink-0 truncate">{t.fa}</span>
                <div className="h-1.5 flex-1 rounded-full bg-white/[0.06] overflow-hidden" aria-hidden="true">
                  <div className="h-full rounded-full bg-gold/70" style={{ width: `${t.pct}%` }} />
                </div>
                <span className="text-[10px] font-black text-gold tabular-persian w-12 text-end shrink-0">صدک {faDigits(t.pct)}</span>
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* ---------- market value trend (cycle-82) ---------- */}
      {p.market && marketPts && (
        <section className="glass-card overflow-hidden" aria-label="روند ارزش بازار" data-testid="player-market">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-sky-soft" aria-hidden>
              <path d="M3 17l6-6 4 4 8-8" />
              <path d="M15 7h6v6" />
            </svg>
            روند ارزش بازار
            <span className="ms-auto text-[9.5px] font-bold text-muted-foreground tabular-persian">{faDigits(p.market.points.length)} نقطهٔ ثبت‌شده</span>
          </header>
          <div className="px-4 py-3.5">
            <div className="flex items-end justify-between gap-3">
              <div className="min-w-0">
                <p className="text-[26px] font-light text-[#dfedff] leading-none tabular-persian">{p.market.current}</p>
                {p.market.currentTeamFa && <p className="text-[10px] text-muted-foreground mt-1.5">ارزش فعلی در {p.market.currentTeamFa}</p>}
              </div>
              <p className="text-[9.5px] text-muted-foreground tabular-persian text-end shrink-0 leading-5">
                شروع ثبت: {p.market.sinceValue}
                {p.market.sinceTeamFa ? ` · ${p.market.sinceTeamFa}` : ""}
                {p.market.sinceYear ? ` · ${faDigits(p.market.sinceYear)}` : ""}
              </p>
            </div>
            <div dir="ltr" className="mt-3 text-sky-soft">
              <svg viewBox="0 0 101 30" preserveAspectRatio="none" className="w-full h-12" aria-hidden="true">
                <polyline
                  points={marketPts}
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.6"
                  strokeLinejoin="round"
                  strokeLinecap="round"
                  vectorEffect="non-scaling-stroke"
                />
                <circle cx="99" cy={marketLastY} r="1.5" fill="currentColor" className="text-gold" />
              </svg>
            </div>
          </div>
        </section>
      )}

      {/* ---------- next match ---------- */}
      {p.next && (
        <Link
          href={`/match/${p.next.id}`}
          prefetch={false}
          className="glass-row glass-row-hover group px-4 py-3 flex items-center gap-3"
          aria-label="بازی بعدی بازیکن"
        >
          <span className="text-[10px] font-black text-sky-soft border border-sky-soft/25 bg-sky-soft/10 rounded-lg px-2 py-1 shrink-0">
            بازی بعدی
          </span>
          <span className="flex items-center gap-2 min-w-0 flex-1 text-[12.5px] font-bold">
            <TeamLogo id={p.next.opponentId} alt="" size={18} />
            <span className="truncate">برابر {teamFa(p.next.opponent)}</span>
            <span className="text-[10px] font-bold text-muted-foreground shrink-0">{p.next.isHome ? "(میزبان)" : "(بیرون خانه)"}</span>
          </span>
          <span className="text-[10.5px] text-muted-foreground tabular-persian shrink-0">
            {j(p.next.utcTime).day} {j(p.next.utcTime).month} · {tehranTime(p.next.utcTime)}
          </span>
        </Link>
      )}

      {/* ---------- season pitch: shot map + touch heatmap (cycle-87, SSR SVG) ---------- */}
      {p.pitch && <PitchSection pitch={p.pitch} />}

      {/* ---------- career path (cycle-20) ---------- */}
      {p.career.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label="مسیر حرفه‌ای">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-sky-soft" aria-hidden>
              <path d="M12 12h.01" />
              <path d="M5 3h14v5a7 7 0 0 1-14 0V3z" />
              <path d="M17 5h3a2 2 0 0 1-2 4h-1M7 5H4a2 2 0 0 0 2 4h1" />
              <path d="M8 21h8M12 15v6" />
            </svg>
            مسیر حرفه‌ای
            <span className="ms-auto text-[10px] font-bold text-muted-foreground tabular-persian">{faDigits(p.career.length)} دوره</span>
          </header>
          <ul className="glass-list">
            {p.career.map((c, i) => (
              <li key={`${c.teamId}-${c.from}-${i}`} className="flex items-center gap-3 px-3 sm:px-4 py-2.5">
                {c.kind === "senior" ? (
                  <Link href={`/team/${c.teamId}`} prefetch={false} className="shrink-0" aria-label={c.fa}>
                    <TeamLogo id={c.teamId} alt={c.fa} size={22} />
                  </Link>
                ) : (
                  <TeamLogo id={c.teamId} alt={c.fa} size={22} />
                )}
                <div className="min-w-0 flex-1">
                  <p className="flex items-center gap-1.5 min-w-0">
                    <span className="font-bold text-[12.5px] truncate">{c.fa}</span>
                    {c.kind === "national" && (
                      <span className="text-[8.5px] font-black text-mint border border-mint/25 bg-mint/10 rounded px-1 py-px shrink-0">
                        تیم ملی
                      </span>
                    )}
                    {c.active && (
                      <span className="text-[8.5px] font-black text-green-600 dark:text-green-400 border border-green-500/30 bg-green-500/10 rounded px-1 py-px shrink-0">
                        اکنون
                      </span>
                    )}
                    {c.transfer && (
                      <span className="hidden sm:inline text-[8.5px] font-bold text-steel border border-glass-border-soft rounded px-1 py-px shrink-0">
                        {c.transfer}
                      </span>
                    )}
                  </p>
                  <p className="text-[10px] text-muted-foreground tabular-persian mt-0.5">
                    {c.from ? faDigits(c.from) : "؟"}
                    {c.to ? ` – ${faDigits(c.to)}` : c.from ? " – اکنون" : ""}
                  </p>
                </div>
                <div className="flex items-center gap-2.5 shrink-0 text-[10px] font-bold text-muted-foreground tabular-persian">
                  {c.apps !== null && <span title="بازی">{faDigits(c.apps)}<span className="hidden sm:inline"> بازی</span></span>}
                  {c.goals !== null && <span title="گل" className="text-mint font-black">{faDigits(c.goals)}<span className="hidden sm:inline"> گل</span></span>}
                  {c.assists !== null && <span title="پاس گل">{faDigits(c.assists)}<span className="hidden sm:inline"> پاس</span></span>}
                </div>
              </li>
            ))}
          </ul>
          {p.careerYouth.length > 0 && (
            <div className="border-t border-glass-border-soft px-3 sm:px-4 py-2.5">
              <p className="text-[10px] font-black text-muted-foreground mb-1.5">سطح پایه</p>
              <p className="flex flex-wrap gap-x-3 gap-y-1">
                {p.careerYouth.map((y, i) => (
                  <span key={`${y.teamId}-${i}`} className="text-[10.5px] text-muted-foreground">
                    {y.fa}
                    <span className="tabular-persian text-muted-foreground/80">
                      {" "}({y.from ? faDigits(y.from) : "؟"}{y.to ? `–${faDigits(y.to)}` : ""})
                    </span>
                  </span>
                ))}
              </p>
            </div>
          )}
        </section>
      )}

      {/* ---------- per-season competition registrations (cycle-201) ---------- */}
      {p.statSeasons && p.statSeasons.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label="رقابت‌های هر فصل" data-testid="player-statseasons">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-sky-soft" aria-hidden>
              <rect x="3" y="4" width="18" height="18" rx="2" />
              <path d="M16 2v4M8 2v4M3 10h18" />
            </svg>
            رقابت‌های هر فصل
            <span className="ms-auto text-[10px] font-bold text-muted-foreground tabular-persian">{faDigits(p.statSeasons.length)} فصل</span>
          </header>
          <ul className="glass-list">
            {p.statSeasons.map((s, i) => (
              <li key={`${s.season}-${i}`} className="flex items-start gap-3 px-3 sm:px-4 py-2.5">
                <span className="text-[10px] font-black text-steel/80 tabular-persian w-[52px] shrink-0 pt-0.5">{faDigits(s.season)}</span>
                <p className="flex flex-wrap gap-1.5 min-w-0">
                  {s.tournaments.map((t, j) =>
                    t.leagueKey ? (
                      <Link
                        key={`${t.name}-${j}`}
                        href={`/league/${t.leagueKey}`}
                        prefetch={false}
                        className="text-[10.5px] font-bold text-sky-soft border border-glass-border-soft rounded px-1.5 py-px hover:bg-white/5"
                      >
                        {t.nameFa}
                      </Link>
                    ) : (
                      <span
                        key={`${t.name}-${j}`}
                        className="text-[10.5px] font-bold text-muted-foreground border border-glass-border-soft rounded px-1.5 py-px"
                      >
                        {t.nameFa}
                      </span>
                    )
                  )}
                </p>
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* ---------- trophies (cycle-20) ---------- */}
      {p.trophies.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label="افتخارات">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-chart-3" aria-hidden>
              <path d="M8 21h8M12 17v4" />
              <path d="M7 4h10v5a5 5 0 0 1-10 0V4z" />
              <path d="M17 5h3a2 2 0 0 1-2 4h-1M7 5H4a2 2 0 0 0 2 4h1" />
            </svg>
            افتخارات
            <span className="ms-auto text-[10px] font-bold text-muted-foreground tabular-persian">{faDigits(p.trophies.length)} جام</span>
          </header>
          <ul className="glass-list">
            {p.trophies.map((t, i) => (
              <li key={`${t.leagueName}-${t.teamName}-${i}`} className="flex items-center gap-3 px-3 sm:px-4 py-2.5">
                <span className="w-7 h-7 rounded-lg bg-chart-3/15 border border-chart-3/25 flex items-center justify-center shrink-0 text-chart-3" aria-hidden>
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="1.4" strokeLinejoin="round">
                    <path d="M7 4h10v5a5 5 0 0 1-10 0V4zM5 5H3.5a1.5 1.5 0 1 0 1.9 1.9M19 5h1.5a1.5 1.5 0 1 1-1.9 1.9" />
                  </svg>
                </span>
                <div className="min-w-0 flex-1">
                  <p className="font-bold text-[12.5px] truncate">{t.leagueName}</p>
                  {/* cycle-159: trophy rows carried the RAW upstream team name
                      («Benfica», youth sides) — the career class sibling of the
                      Latin leak fixed this cycle; teamFa keeps the single
                      mapping source (the cycle-145 convention) */}
                  <p className="text-[10px] text-muted-foreground truncate">{teamFa(t.teamName) || t.teamName}</p>
                </div>
                <div className="text-end shrink-0">
                  {t.seasonsWon.length > 0 && (
                    <p className="text-[10.5px] font-black text-chart-3 tabular-persian">
                      {t.seasonsWon.slice(0, 4).map((s) => faDigits(s.slice(0, 4))).join("، ")}
                      {t.seasonsWon.length > 4 ? "…" : ""}
                    </p>
                  )}
                  {t.runnerUp > 0 && (
                    <p className="text-[9.5px] text-muted-foreground tabular-persian">{faDigits(t.runnerUp)} نایب‌قهرمانی</p>
                  )}
                </div>
              </li>
            ))}
          </ul>
        </section>
      )}

      {/* ---------- squad navigation (update cycle-197) ---------- */}
      {(p.teammates.length > 0 || p.nationalTeammates.length > 0) && (
        <TeammatesCard club={p.teammates} national={p.nationalTeammates} teamFa={p.team?.fa} />
      )}

      {/* ---------- recent matches (cycle-86: full archive island —
          side filter club vs national + show-all toggle, SSR-friendly) ---------- */}
      <RecentMatchesSection recent={p.recent} teams={p.recentTeams} />

      <p className="text-[10px] text-muted-foreground/80 text-center">
        آمار از FotMob — امتیازها و ارزش بازار تقریبی است و هر {faDigits(10)} دقیقه به‌روزرسانی می‌شود.
      </p>
    </div>
  );
}
