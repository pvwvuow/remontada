"use client";

// ------------------------------------------------------------------
// Remontada — favorite-team star toggle button
// ------------------------------------------------------------------
// Usage: <FavoriteStar team={{ id, fa, en }} /> — can live inside a
// <Link> (click is contained). Uses the favorites store hook so all
// stars on the page stay in sync (and SSR/hydration safe).
import { useState } from "react";
import { toggleFavorite, useIsFavorite } from "@/lib/favorites";
import { cn } from "@/lib/utils";

export function FavoriteStar({
  team,
  size = 18,
  withLabel = false,
  className,
}: {
  team: { id: number; fa: string; en?: string };
  size?: number;
  withLabel?: boolean;
  className?: string;
}) {
  const isFav = useIsFavorite(team.id);
  const [pop, setPop] = useState(false);

  function onClick(e: React.MouseEvent) {
    e.preventDefault();
    e.stopPropagation();
    const now = toggleFavorite(team);
    if (now) {
      setPop(true);
      window.setTimeout(() => setPop(false), 350);
    }
  }

  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={isFav}
      title={isFav ? "حذف از علاقه‌مندی‌ها" : "افزودن به علاقه‌مندی‌ها"}
      aria-label={isFav ? `حذف ${team.fa} از علاقه‌مندی‌ها` : `افزودن ${team.fa} به علاقه‌مندی‌ها`}
      className={cn(
        "inline-flex items-center justify-center gap-1.5 shrink-0 transition-colors cursor-pointer",
        isFav ? "text-amber-400" : "text-muted-foreground/50 hover:text-amber-400/80",
        className
      )}
    >
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill={isFav ? "currentColor" : "none"}
        stroke="currentColor"
        strokeWidth="1.9"
        strokeLinecap="round"
        strokeLinejoin="round"
        aria-hidden
        className={cn("transition-transform duration-300", pop && "scale-125")}
      >
        <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
      </svg>
      {withLabel && (
        <span className="text-[11px] font-bold whitespace-nowrap">
          {isFav ? "حذف از علاقه‌مندی‌ها" : "افزودن به علاقه‌مندی‌ها"}
        </span>
      )}
    </button>
  );
}
