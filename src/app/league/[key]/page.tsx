import type { Metadata } from "next";
import { LeagueView } from "@/components/remontada/league-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { LEAGUES } from "@/lib/leagues";

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
  };
}

export default async function LeaguePage({ params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <LeagueView leagueKey={key} />
      </main>
      <SiteFooter />
    </div>
  );
}
