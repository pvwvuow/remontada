import type { Metadata } from "next";
import { LeagueView } from "@/components/remontada/league-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { LEAGUES } from "@/lib/leagues";
import { SITE_URL, RSS_ALTERNATE } from "@/lib/site";

// unknown league keys → hard 404 (only the 10 known competitions are valid)
export const dynamicParams = false;

export async function generateStaticParams() {
  return LEAGUES.map((l) => ({ key: l.key }));
}

export async function generateMetadata({ params }: { params: Promise<{ key: string }> }): Promise<Metadata> {
  const { key } = await params;
  const lg = LEAGUES.find((l) => l.key === key);
  const name = lg?.faName || "لیگ";
  // fix cycle-339: per-page openGraph+twitter — same shape as the topscorers
  // page: the child object replaces the layout's wholesale, so og.png is
  // re-included and siteName/locale/url return page-specific (og:url = this
  // league page, not the site root).
  const title = `${name} | جدول، برنامه و نتایج`;
  const desc = `جدول رده‌بندی، برنامه بازی‌ها، نتایج اخیر و آقای گل ${name} — رمانتادا، مرجع فارسی فوتبال`;
  return {
    title,
    description: desc,
    alternates: { canonical: `/league/${key}`, ...RSS_ALTERNATE },
    openGraph: {
      title: `${title} | رمانتادا`,
      description: desc,
      type: "website",
      siteName: "رمانتادا",
      locale: "fa_IR",
      url: `${SITE_URL}/league/${key}`,
      // update cycle-341: the league's own dynamic share card (build-time
      // next/og render — name + colour of the competition) instead of the
      // generic static og.png; /api/og/[key] is SSG'd per league key.
      images: [{ url: `/api/og/${key}`, width: 1200, height: 630, alt: `رمانتادا — ${name}` }],
    },
    twitter: {
      card: "summary_large_image",
      title: `${title} | رمانتادا`,
      description: desc,
      images: [`/api/og/${key}`],
    },
  };
}

export default async function LeaguePage({ params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  // dynamicParams=false + generateStaticParams → only known keys reach here;
  // still guarded: structured data stays null on any mismatch
  const lg = LEAGUES.find((l) => l.key === key) || null;
  const leagueLd: Record<string, unknown> | null = lg
    ? {
        "@context": "https://schema.org",
        "@type": "SportsLeague",
        "name": lg.faName,
        "alternateName": lg.enName,
        "sport": "Football",
        "url": `${SITE_URL}/league/${lg.key}`,
      }
    : null;
  const crumbLd: Record<string, unknown> | null = lg
    ? {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
          { "@type": "ListItem", "position": 1, "name": "خانه", "item": SITE_URL },
          { "@type": "ListItem", "position": 2, "name": "لیگ‌ها", "item": `${SITE_URL}/leagues` },
          { "@type": "ListItem", "position": 3, "name": lg.faName, "item": `${SITE_URL}/league/${lg.key}` },
        ],
      }
    : null;
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={leagueLd} />
        <JsonLd data={crumbLd} />
        {/* update cycle-101: key={key} remounts LeagueView on a client-side
            league switch (/league/pl → /league/ucl). Before this, ALL local
            state survived the navigation — the registered cycle-99 candidate:
            a season picked on one league silently carried into the next
            (e.g. pl?season=2024/2025 → ucl kept showing 2024/2025 with NO
            ?season in the URL, so the selector/label contradicted the address
            bar and a refresh snapped back). A league switch is a new browsing
            intent: the remount re-runs the cycle-99 seed pass against the NEW
            URL (no ?season → current season), resets the tab and clears
            league-local data — one fetch per navigation, same as a fresh
            deep link. */}
        <LeagueView leagueKey={key} key={key} />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
