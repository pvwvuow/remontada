import type { Metadata } from "next";
import { LeagueScorersView } from "@/components/remontada/league-scorers-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { LEAGUES } from "@/lib/leagues";
import { SITE_URL } from "@/lib/site";

// unknown league keys → hard 404 (only the 7 known leagues are valid)
export const dynamicParams = false;

export async function generateStaticParams() {
  return LEAGUES.map((l) => ({ leagueKey: l.key }));
}

export async function generateMetadata({ params }: { params: Promise<{ leagueKey: string }> }): Promise<Metadata> {
  const { leagueKey } = await params;
  const lg = LEAGUES.find((l) => l.key === leagueKey);
  const name = lg?.faName || "لیگ";
  return {
    title: `آقای گلان ${name}`,
    description: `جدول کامل بهترین گلزنان ${name} با پاس گل، گل+پاس، xG، ریتینگ و میانگین دقایق هر گل — رمانتادا، مرجع فارسی فوتبال`,
    alternates: { canonical: `/topscorers/${leagueKey}` },
  };
}

export default async function LeagueScorersPage({ params }: { params: Promise<{ leagueKey: string }> }) {
  const { leagueKey } = await params;
  const lg = LEAGUES.find((l) => l.key === leagueKey) || null;
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
          { "@type": "ListItem", "position": 3, "name": `آقای گلان ${lg.faName}`, "item": `${SITE_URL}/topscorers/${lg.key}` },
        ],
      }
    : null;
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={leagueLd} />
        <JsonLd data={crumbLd} />
        <LeagueScorersView leagueKey={leagueKey} />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
