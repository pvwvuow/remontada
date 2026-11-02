// ------------------------------------------------------------------
// Remontada — canonical site URL.
// cycle-334 fix (finding F1 from the cycle-333 bug-hunt): the historical
// default https://remontada.vercel.app answers DEPLOYMENT_NOT_FOUND as of
// 2026-11-01 (x-vercel-error from Vercel itself, zero Wayback snapshots),
// so every canonical URL fed by that default — sitemap (522 locs),
// robots.txt Sitemap line, rss.xml, layout OG/canonical, page JSON-LD,
// calendar API — pointed at nothing. Resolution order below:
//   1) NEXT_PUBLIC_SITE_URL — explicit operator override, honored verbatim
//      (minus trailing slashes, the pre-334 behavior kept byte-for-byte).
//   2) VERCEL_PROJECT_PRODUCTION_URL — the STABLE production domain Vercel
//      injects on real deployments; normalized to https://. Trusted only
//      when VERCEL_ENV === "production" so preview builds never leak
//      ephemeral domains into canonical/sitemap output.
//   3) VERCEL_URL — per-deployment fallback, same normalization and guard.
//   4) The production domain itself — cycle-374 fix: the 334 rewrite kept
//      the dead vercel.app string as the final fallback only for
//      byte-compat with cycle-333, but the same 334 evidence proved that
//      domain serves DEPLOYMENT_NOT_FOUND. Every non-Vercel host (the
//      real zxy.site deployment, local sandboxes, any future host) has no
//      Vercel env and therefore advertised a dead domain in its RSS
//      channel/self links, sitemap locs, robots Sitemap line and JSON-LD.
//      The fallback is now the operator-designated production domain;
//      hosts WITH Vercel envs keep the exact 334 behavior.
// ------------------------------------------------------------------
export function resolveSiteUrl(
  env: Record<string, string | undefined>,
): string {
  const explicit = env.NEXT_PUBLIC_SITE_URL?.trim();
  if (explicit) return explicit.replace(/\/+$/, "");
  if (env.VERCEL_ENV === "production") {
    for (const raw of [env.VERCEL_PROJECT_PRODUCTION_URL, env.VERCEL_URL]) {
      const host = raw
        ?.trim()
        .replace(/^https?:\/\//, "")
        .replace(/\/+$/, "");
      if (host) return `https://${host}`;
    }
  }
  return "https://remontada.zxy.site";
}

export const SITE_URL = resolveSiteUrl(process.env);

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
