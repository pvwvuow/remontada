import type { Metadata } from "next";
import { LeagueView } from "@/components/remontada/league-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { LEAGUES } from "@/lib/leagues";
import { SITE_URL } from "@/lib/site";

// unknown league keys → hard 404 (only the 7 known leagues are valid)
export const dynamicParams = false;

export async function generateStaticParams() {
  return LEAGUES.map((l) => ({ key: l.key }));
}

export async function generateMetadata({ params }: { params: Promise<{ key: string }> }): Promise<Metadata> {
  const { key } = await params;
  const lg = LEAGUES.find((l) => l.key === key);
  const name = lg?.faName || "لیگ";
  return {
    title: `${name} | جدول، برنامه و نتایج`,
    description: `جدول رده‌بندی، برنامه بازی‌ها، نتایج اخیر و آقای گل ${name} — رمانتادا، مرجع فارسی فوتبال`,
    alternates: { canonical: `/league/${key}` },
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
        <LeagueView leagueKey={key} />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
