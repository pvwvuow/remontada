import type { MetadataRoute } from "next";
import { LEAGUES } from "@/lib/leagues";
import { SITE_URL } from "@/lib/site";

export default function sitemap(): MetadataRoute.Sitemap {
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

  return [...staticRoutes, ...leagueRoutes];
}
