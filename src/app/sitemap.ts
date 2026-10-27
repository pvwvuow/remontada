import type { MetadataRoute } from "next";
import { LEAGUES } from "@/lib/leagues";
import { SITE_URL } from "@/lib/site";
import { getStandings } from "@/lib/fotmob";

// cycle-20: the sitemap now also lists /player/[id] pages for the top
// scorers of every league (playerId comes with the standings payload).
// The route stays build-time static; league fetch failures (e.g. the
// Persian Gulf league's null body) are swallowed per-league so the
// sitemap always renders.
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const now = new Date();

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${SITE_URL}/`, lastModified: now, changeFrequency: "hourly", priority: 1 },
    { url: `${SITE_URL}/leagues`, lastModified: now, changeFrequency: "daily", priority: 0.9 },
    { url: `${SITE_URL}/topscorers`, lastModified: now, changeFrequency: "daily", priority: 0.8 },
    { url: `${SITE_URL}/news`, lastModified: now, changeFrequency: "hourly", priority: 0.7 },
  ];

  const leagueRoutes: MetadataRoute.Sitemap = LEAGUES.map((l) => ({
    url: `${SITE_URL}/league/${l.key}`,
    lastModified: now,
    changeFrequency: "daily" as const,
    priority: 0.8,
  }));

  const scorersRoutes: MetadataRoute.Sitemap = LEAGUES.map((l) => ({
    url: `${SITE_URL}/topscorers/${l.key}`,
    lastModified: now,
    changeFrequency: "daily" as const,
    priority: 0.7,
  }));

  // fix cycle-33 (finding #3 of the cycle-32 bug hunt): popular team pages
  // belong in the sitemap too. Same verified ids as POPULAR_TEAMS in
  // /leagues + the two other Persian-gulf clubs validated in cycle-3.
  const popularTeamIds = [101610, 101614, 176352, 101611, 8633, 8634, 10260];
  const teamRoutes: MetadataRoute.Sitemap = popularTeamIds.map((id) => ({
    url: `${SITE_URL}/team/${id}`,
    lastModified: now,
    changeFrequency: "daily" as const,
    priority: 0.6,
  }));

  // player profile URLs — top scorers per league, de-duplicated across
  // competitions (a player can appear in league + cup lists)
  const playerRoutes: MetadataRoute.Sitemap = [];
  const seen = new Set<number>();
  const settled = await Promise.allSettled(LEAGUES.map((l) => getStandings(l.key)));
  for (const r of settled) {
    if (r.status !== "fulfilled") continue;
    for (const s of r.value.scorers || []) {
      if (s.playerId == null || seen.has(s.playerId)) continue;
      seen.add(s.playerId);
      playerRoutes.push({
        url: `${SITE_URL}/player/${s.playerId}`,
        lastModified: now,
        changeFrequency: "daily" as const,
        priority: 0.6,
      });
    }
  }

  return [...staticRoutes, ...leagueRoutes, ...scorersRoutes, ...teamRoutes, ...playerRoutes];
}
