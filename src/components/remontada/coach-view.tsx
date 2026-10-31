"use client";

// ------------------------------------------------------------------
// Remontada — coach profile view (cycle-255 «صفحهٔ مربی»)
// Presentational client shell for /coach/[id]: bench-record hero + current
// record card + career stints + honours. Same visual language as the team
// and player profiles (glass cards, faDigits, tap-hit rows). All numbers
// honest — sections hide when the payload lacks them.
// ------------------------------------------------------------------
import Link from "next/link";
import { faDigits } from "@/lib/format";
import { TeamLogo } from "@/components/remontada/team-logo";
import { ShareButton } from "@/components/remontada/share-button";
import { JsonLd } from "@/components/remontada/json-ld";
import type { CoachData } from "@/lib/fotmob";

/** tactics-board glyph — the coach avatar (no headshots in the coach id-space) */
function CoachGlyph({ size = 56 }: { size?: number }) {
  return (
    <span
      className="shrink-0 rounded-xl bg-[#a9cdf614] border border-glass-border-soft flex items-center justify-center text-sky-soft"
      style={{ width: size, height: size }}
      aria-hidden="true"
    >
      <svg width={size * 0.55} height={size * 0.55} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
        <rect x="4" y="3.5" width="16" height="17" rx="2.2" />
        <path d="M9 3.5V2h6v1.5" />
        <circle cx="9" cy="9.5" r="1.15" />
        <circle cx="15.5" cy="13.5" r="1.15" />
        <path d="M10 10.3l4 2.6" />
        <path d="M8 16.5h4" />
      </svg>
    </span>
  );
}

function RecordTile({ display, title, tone }: { display: string; title: string; tone?: "win" | "draw" | "loss" }) {
  const cls =
    tone === "win"
      ? "text-emerald-300"
      : tone === "draw"
        ? "text-[#c9d7e6]"
        : tone === "loss"
          ? "text-rose-300"
          : "text-[#e6f0fb]";
  return (
    <div className="flex-1 min-w-0 rounded-xl border border-glass-border-soft bg-white/[0.03] px-2 py-2.5 text-center">
      <p className={`font-black text-base leading-6 tabular-persian ${cls}`}>{display}</p>
      <p className="text-[9.5px] font-bold text-steel/85 mt-0.5">{title}</p>
    </div>
  );
}

export function CoachView({ c }: { c: CoachData }) {
  const teamName = c.team?.fa || c.team?.name || "";
  const winRate = c.team && c.team.matches > 0 ? Math.round((c.team.wins / c.team.matches) * 100) : null;
  const subParts: string[] = [];
  if (c.countryFa || c.countryEn) subParts.push(c.countryFa || c.countryEn || "");
  if (c.age != null) subParts.push(`${faDigits(c.age)} ساله`);

  const personLd = {
    "@context": "https://schema.org",
    "@type": "Person",
    // cycle-259: Persian rendering first (bug-hunt 258 finding), english as
    // alternateName when it differs — mirrors the team SportsTeam convention
    name: c.fa || c.name,
    ...(c.fa && c.fa !== c.name ? { alternateName: c.name } : {}),
    url: `/coach/${c.id}`,
    jobTitle: "Manager",
    ...(c.team
      ? {
          affiliation: {
            "@type": "SportsTeam",
            name: c.team.name,
            ...(c.team.fa && c.team.fa !== c.team.name ? { alternateName: c.team.fa } : {}),
            url: `/team/${c.team.id}`,
          },
        }
      : {}),
    ...(c.countryEn ? { nationality: { "@type": "Country", name: c.countryEn } } : {}),
  };

  return (
    <div className="flex flex-col gap-4">
      <JsonLd data={personLd} />

      {/* ---------- header ---------- */}
      <section className="glass-scorer-hero overflow-hidden">
        <div className="px-4 py-4 flex items-center gap-3.5">
          <CoachGlyph size={56} />
          <div className="min-w-0 flex-1">
            <p className="text-[9.5px] font-black text-gold tracking-wide mb-0.5">سرمربی</p>
            <h1 className="font-black text-lg leading-7 truncate text-[#f1f7fd]" dir="auto">
              {c.fa || c.name}
            </h1>
            <p className="text-[11px] text-steel flex items-center gap-1.5 flex-wrap mt-0.5">
              {subParts.length > 0 && <span className="font-bold text-[#ecf3fa]/85">{subParts.join(" · ")}</span>}
              {c.team && (
                <>
                  {subParts.length > 0 && <span aria-hidden>·</span>}
                  <Link
                    href={`/team/${c.team.id}`}
                    className="tap-hit-row inline-flex items-center gap-1.5 hover:text-sky-soft transition-colors font-bold"
                    prefetch={false}
                  >
                    <TeamLogo id={c.team.id} alt="" size={14} />
                    <span>{teamName}</span>
                  </Link>
                </>
              )}
            </p>
          </div>
          <ShareButton title={`${c.fa || c.name} — پروفایل مربی | رمانتادا`} path={`/coach/${c.id}`} size={28} />
        </div>
      </section>

      {/* ---------- current bench record ---------- */}
      {c.team && (
        <section className="glass-card overflow-hidden" aria-label="کارنامهٔ نیمکت" data-testid="coach-record">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <span className="font-black text-[12px] text-[#ecf3fa]">
              کارنامه در نیمکت {teamName}
            </span>
            <span className="ms-auto text-[10px] font-bold text-steel/85 tabular-persian">
              فصل جاری
            </span>
          </header>
          <div className="px-4 py-3.5 flex flex-col gap-3">
            <div className="flex gap-2">
              <RecordTile display={faDigits(c.team.matches)} title="بازی" />
              <RecordTile display={faDigits(c.team.wins)} title="برد" tone="win" />
              <RecordTile display={faDigits(c.team.draws)} title="مساوی" tone="draw" />
              <RecordTile display={faDigits(c.team.losses)} title="باخت" tone="loss" />
            </div>
            {winRate != null && (
              <div
                className="flex items-center gap-2"
                role="img"
                aria-label={`درصد برد ${faDigits(winRate)} درصد`}
              >
                <div className="flex-1 h-2 rounded-full bg-white/[0.07] overflow-hidden">
                  <div
                    className="h-full rounded-full bg-emerald-400/70 transition-all"
                    style={{ width: `${winRate}%` }}
                  />
                </div>
                <span className="text-[10.5px] font-black text-emerald-300 tabular-persian shrink-0">
                  {faDigits(winRate)}٪ برد
                </span>
              </div>
            )}
          </div>
        </section>
      )}

      {/* ---------- career stints ---------- */}
      {c.career.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label="سوابق هدایت" data-testid="coach-career">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <span className="font-black text-[12px] text-[#ecf3fa]">سوابق هدایت</span>
            <span className="ms-auto text-[10px] font-bold text-steel/85 tabular-persian">
              {faDigits(c.career.length)} نیمکت
            </span>
          </header>
          <div className="glass-list">
            {c.career.map((s, i) => (
              <Link
                key={`${s.teamId}-${i}`}
                href={`/team/${s.teamId}`}
                className="group flex items-center gap-3 px-4 py-2.5 glass-row-hover transition-colors"
                prefetch={false}
              >
                <TeamLogo id={s.teamId} alt="" size={22} />
                <div className="min-w-0 flex-1">
                  <p className="text-[12px] font-bold text-[#e6f0fb] truncate" dir="auto">
                    {s.fa}
                  </p>
                  <p className="text-[9.5px] text-steel/85 tabular-persian mt-0.5">
                    {s.from ? faDigits(s.from) : "؟"}
                    {" – "}
                    {s.active ? "اکنون" : s.to ? faDigits(s.to) : "؟"}
                  </p>
                </div>
                {s.active && (
                  <span className="shrink-0 text-[9px] font-black rounded-md border border-emerald-400/30 bg-emerald-400/10 text-emerald-300 px-1.5 py-0.5">
                    نیمکت فعلی
                  </span>
                )}
              </Link>
            ))}
          </div>
        </section>
      )}

      {/* ---------- honours ---------- */}
      {c.trophies.length > 0 && (
        <section className="glass-card overflow-hidden" aria-label="افتخارات" data-testid="coach-trophies">
          <header className="glass-thead px-4 py-2.5 border-b border-glass-border-soft flex items-center gap-2 text-[12px] font-black">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-gold" aria-hidden>
              <path d="M8 21h8M12 17v4M7 4h10v4a5 5 0 0 1-10 0V4z" />
              <path d="M7 5H4.5a1 1 0 0 0-1 1.2c.3 1.6 1.2 2.9 2.5 3.5M17 5h2.5a1 1 0 0 1 1 1.2c-.3 1.6-1.2 2.9-2.5 3.5" />
            </svg>
            <span className="font-black text-[12px] text-[#ecf3fa]">افتخارات</span>
            <span className="ms-auto text-[10px] font-bold text-muted-foreground tabular-persian">
              {faDigits(c.trophies.length)} جام
            </span>
          </header>
          <div className="glass-list">
            {c.trophies.map((t, i) => (
              <div key={`${t.leagueName}-${i}`} className="flex items-center gap-3 px-4 py-2.5">
                <span className="w-5 text-[11px] font-black text-muted-foreground tabular-persian shrink-0">
                  {faDigits(i + 1)}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-[12px] font-bold text-[#e6f0fb] truncate" dir="auto">
                    {t.leagueName || t.teamName}
                  </p>
                  {t.teamName && t.leagueName && (
                    <p className="text-[9.5px] text-steel/85 truncate mt-0.5" dir="auto">
                      {t.teamName}
                    </p>
                  )}
                </div>
                <span className="shrink-0 text-[9.5px] font-bold text-steel/85 tabular-persian text-end" dir="ltr">
                  {t.seasonsWon.slice(0, 3).map((s) => faDigits(s)).join(" · ")}
                  {t.seasonsWon.length > 3 ? " …" : ""}
                </span>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
