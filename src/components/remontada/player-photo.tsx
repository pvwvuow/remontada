"use client";

// ------------------------------------------------------------------
// Remontada — real player headshot with the honest initials fallback.
// cycle-130: FotMob serves current player photos at
//   https://images.fotmob.com/image_resources/playerimages/{id}.png
// (live-probed with UA Chrome/124: 200 image/png for active players,
// 403 S3 AccessDenied for missing/retired ids — so the <img> hides
// itself onError and the initials tile shows through; zero broken
// images by construction, no server round-trip needed).
// ------------------------------------------------------------------
import { ScorerAvatarTile } from "./glass-stats";
import { cn } from "@/lib/utils";

export function PlayerPhoto({
  id,
  name,
  size = 48,
  rounded = "rounded-2xl",
  suffix = "_xsmall",
  className = "",
}: {
  id: number | string | null | undefined; // null/0 → initials tile only (honest fallback)
  name: string;
  size?: number;
  rounded?: string;
  suffix?: string; // "_xsmall" for list avatars, "" for the big profile hero source
  className?: string;
}) {
  const hasId = id != null && String(id) !== "0" && String(id) !== "";
  return (
    <span
      className={cn("relative inline-flex shrink-0 select-none", className)}
      style={{ width: size, height: size }}
      aria-hidden
    >
      <ScorerAvatarTile name={name} size={size} rounded={rounded} className="absolute inset-0" />
      {hasId ? (
        <img
          src={`https://images.fotmob.com/image_resources/playerimages/${id}${suffix}.png`}
          alt=""
          width={size}
          height={size}
          loading="lazy"
          decoding="async"
          className={cn("absolute inset-0 w-full h-full object-cover object-top", rounded)}
          style={{ width: size, height: size }}
          onError={(e) => {
            e.currentTarget.style.visibility = "hidden";
          }}
        />
      ) : null}
    </span>
  );
}
