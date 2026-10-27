"use client";

// ------------------------------------------------------------------
// Remontada — shared presentation primitives for the glass statistics
// posters (phase 3: standings tables + scoring charts). Presentation
// only — no data fetching, no business logic.
// ------------------------------------------------------------------
import { cn } from "@/lib/utils";

/** Two-digit rank label source («۰۱») — convert with faDigits at call site. */
export function pad2(n: number | string): string {
  return String(n).padStart(2, "0");
}

/** Latin initials from a player name («Erling Haaland» -> «EH»). */
export function initialsOf(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "؟";
  const first = parts[0][0] || "";
  const last = parts.length > 1 ? parts[parts.length - 1][0] || "" : "";
  return (first + last).toUpperCase();
}

/** Rounded glass tile with the player's initials — the studio poster's
    photo slot, used by the scorer hero + compact rows. */
export function ScorerAvatarTile({
  name,
  size = 64,
  rounded = "rounded-2xl",
  className = "",
}: {
  name: string;
  size?: number;
  rounded?: string;
  className?: string;
}) {
  return (
    <span
      aria-hidden
      className={cn(
        "glass-avatar flex items-center justify-center shrink-0 font-black text-[#cfe2f8] select-none",
        rounded,
        className
      )}
      style={{ width: size, height: size, fontSize: Math.max(11, Math.round(size * 0.3)) }}
    >
      {initialsOf(name)}
    </span>
  );
}

/** Studio-style stats-card header: league crest on a brand glyph +
    name + tracked country line + season chip on the far side. */
export function GlassLeagueHeader({
  leagueId,
  title,
  sub,
  season,
  titleTag = "div",
  children,
}: {
  leagueId?: number;
  title: string;
  sub?: string;
  season?: string;
  titleTag?: "h2" | "h3" | "div";
  children?: React.ReactNode;
}) {
  const Title = titleTag;
  return (
    <header className="flex items-start justify-between gap-2 px-4 pt-3.5 pb-2.5">
      <div className="flex items-center gap-2.5 min-w-0">
        {leagueId ? (
          <span className="brand-glyph w-9 h-9 flex items-center justify-center shrink-0 overflow-hidden">
            <img
              src={`https://images.fotmob.com/image_resources/logo/leaguelogo/${leagueId}.png`}
              alt=""
              width={24}
              height={24}
              loading="lazy"
              className="w-6 h-6 object-contain"
              onError={(e) => {
                e.currentTarget.style.visibility = "hidden";
              }}
            />
          </span>
        ) : null}
        <div className="min-w-0">
          <Title className="text-[13.5px] font-extrabold text-[#ecf3fa] truncate leading-5">{title}</Title>
          {sub && (
            <p className="text-[8px] font-bold tracking-[0.22em] text-steel/75 uppercase truncate mt-0.5">{sub}</p>
          )}
        </div>
      </div>
      <div className="flex items-center gap-2 shrink-0">
        {children}
        {season && (
          <span className="text-[9.5px] font-bold text-steel/90 border border-glass-border-soft bg-white/[0.03] rounded-md px-2 py-1 tabular-persian whitespace-nowrap">
            {season}
          </span>
        )}
      </div>
    </header>
  );
}

/** Micro caption row under the card header — the studio poster's tiny
    uppercase meta line («LEAGUE STANDINGS — 20 CLUBS» equivalent). */
export function GlassPosterMeta({ right, left, className = "" }: { right: string; left?: string; className?: string }) {
  return (
    <div className={cn("mx-4 mb-1.5 flex items-center justify-between gap-2 text-[9px] font-bold text-steel/70", className)}>
      <span className="truncate">{right}</span>
      {left && <span className="shrink-0 tabular-persian">{left}</span>}
    </div>
  );
}
