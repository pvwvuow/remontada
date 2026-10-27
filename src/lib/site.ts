// ------------------------------------------------------------------
// Remontada — canonical site URL (overridable via NEXT_PUBLIC_SITE_URL)
// ------------------------------------------------------------------
export const SITE_URL = (
  process.env.NEXT_PUBLIC_SITE_URL || "https://remontada.vercel.app"
).replace(/\/+$/, "");

export const SITE_NAME = "رمانتادا";
