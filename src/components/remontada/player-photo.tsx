"use client";

// ------------------------------------------------------------------
// Remontada — real player headshot with the honest initials fallback.
// cycle-130: FotMob serves current player photos at
//   https://images.fotmob.com/image_resources/playerimages/{id}.png
// (live-probed with UA Chrome/124: 200 image/png for active players,
// 403 S3 AccessDenied for missing/retired ids — so the <img> hides
// itself onError and the initials tile shows through; zero broken
// images by construction, no server round-trip needed).
// cycle-134 «بازیکنان همهٔ تیم‌ها»: quality ladder. Re-probed 2026-10-29
// with UA Chrome/124 — FotMob serves exactly THREE raster sizes per id:
//   "_xsmall" → 35×35   (~2 KB)
//   "_small"  → 150×150 (~14 KB)
//   ""        → 192×192 (~22 KB)
// "_medium"/"_big" do not exist (403 S3 AccessDenied). The old default
// "_xsmall" was a 35px source — visibly blurry the moment any retina
// screen upscales it past ~17 CSS px, which is exactly the user's
// «آیکون ترکیب تیم» complaint. There is no vector (SVG) variant
// upstream, so the closest to vector-sharp is the smallest source that
// still covers the render box at 2× DPR: renders < 80px get "_small"
// (150px covers up to 75px @2×), heroes >= 80px get the bare 192px
// source. An explicit suffix prop still wins (profile hero passes "").
// ------------------------------------------------------------------
import { ScorerAvatarTile } from "./glass-stats";
import { cn } from "@/lib/utils";

export function PlayerPhoto({
  id,
  name,
  size = 48,
  rounded = "rounded-2xl",
  suffix,
  className = "",
}: {
  id: number | string | null | undefined; // null/0 → initials tile only (honest fallback)
  name: string;
  size?: number;
  rounded?: string;
  suffix?: string; // explicit override; default = probed ladder below
  className?: string;
}) {
  const hasId = id != null && String(id) !== "0" && String(id) !== "";
  const useSuffix = suffix ?? (size >= 80 ? "" : "_small");
  return (
    <span
      className={cn("relative inline-flex shrink-0 select-none", className)}
      style={{ width: size, height: size }}
      aria-hidden
    >
      <ScorerAvatarTile name={name} size={size} rounded={rounded} className="absolute inset-0" />
      {hasId ? (
        <img
          src={`https://images.fotmob.com/image_resources/playerimages/${id}${useSuffix}.png`}
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
