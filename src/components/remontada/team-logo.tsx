"use client";

// ------------------------------------------------------------------
// Remontada — team logo with graceful fallback (client-safe onError)
// ------------------------------------------------------------------
export function TeamLogo({ id, alt, size = 34, className = "" }: { id: number | string; alt: string; size?: number; className?: string }) {
  // cycle-145: generic/logoless sides («Free agent» = fotmob id 2) have NO
  // CDN logo — the SSR <img> 403s BEFORE React hydrates, so the onError
  // fallback below never attaches and the house DOM contract counts a
  // visible broken image (5 on the Süper transfers tab). Render an honest
  // neutral placeholder instead — never a <img> for ids without a logo.
  const generic = !id || Number(id) <= 2 || Number.isNaN(Number(id));
  if (generic) {
    return (
      <span
        role="img"
        aria-label={alt}
        className={`inline-flex items-center justify-center rounded-full bg-[#9ec3e514] border border-[color:var(--glass-hairline)] text-steel shrink-0 select-none ${className || ""}`}
        style={{ width: size, height: size, fontSize: Math.max(9, Math.round(size * 0.38)) }}
      >
        ؟
      </span>
    );
  }
  return (
     
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
