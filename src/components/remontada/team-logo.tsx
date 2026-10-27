"use client";

// ------------------------------------------------------------------
// Remontada — team logo with graceful fallback (client-safe onError)
// ------------------------------------------------------------------
export function TeamLogo({ id, alt, size = 34, className = "" }: { id: number | string; alt: string; size?: number; className?: string }) {
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={`https://images.fotmob.com/image_resources/logo/teamlogo/${id}.png`}
      alt={alt}
      width={size}
      height={size}
      loading="lazy"
      className={`object-contain shrink-0 ${className}`}
      style={{ width: size, height: size }}
      onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
    />
  );
}
