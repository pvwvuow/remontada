// ------------------------------------------------------------------
// Remontada — canonical site URL (overridable via NEXT_PUBLIC_SITE_URL)
// ------------------------------------------------------------------
export const SITE_URL = (
  process.env.NEXT_PUBLIC_SITE_URL || "https://remontada.vercel.app"
).replace(/\/+$/, "");

export const SITE_NAME = "رمانتادا";

// cycle-295 additive: the RSS feed's metadata fragment. Next merges
// segment metadata SHALLOWLY — any page that declares its own
// `alternates` (canonical parity since cycle-289) wipes the layout's
// feed link, so every canonical-bearing segment must spread this in
// (the 289 pattern one field deeper). Pages that intentionally clear
// alternates (`alternates: {}` on the noindex branches) stay cleared.
export const RSS_ALTERNATE = {
  types: { "application/rss+xml": "/rss.xml" },
} as const;
