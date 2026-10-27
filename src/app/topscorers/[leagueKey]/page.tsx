import type { Metadata } from "next";
import { LeagueScorersView } from "@/components/remontada/league-scorers-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { LEAGUES } from "@/lib/leagues";

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
  };
}

export default async function LeagueScorersPage({ params }: { params: Promise<{ leagueKey: string }> }) {
  const { leagueKey } = await params;
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <LeagueScorersView leagueKey={leagueKey} />
      </main>
      <SiteFooter />
    </div>
  );
}
