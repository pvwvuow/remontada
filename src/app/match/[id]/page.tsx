import type { Metadata } from "next";
import { MatchDetail } from "@/components/remontada/match-detail";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { JsonLd } from "@/components/remontada/json-ld";
import { getMatchLdData } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";

export const metadata: Metadata = {
  title: "جزئیات مسابقه",
  description: "رویدادهای زنده، آمار، ترکیب تیم‌ها و اطلاعات کامل مسابقه فوتبال",
};

export default async function MatchPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  // ---- SSR JSON-LD (cycle 18) ------------------------------------------------
  // Fetch minimal match data on the server and emit a SportsEvent script into
  // the initial HTML so crawlers without JS see structured data too.
  // Failure must never break the page: any problem → ld stays null.
  let ld: Record<string, unknown> | null = null;
  try {
    const m = await getMatchLdData(id);
    if (m) {
      ld = {
        "@context": "https://schema.org",
        "@type": "SportsEvent",
        "name": `${m.homeFa || m.homeName} در برابر ${m.awayFa || m.awayName}`,
        "alternateName": `${m.homeName} vs ${m.awayName}`,
        "sport": "Football",
        "url": `${SITE_URL}/match/${m.id}`,
        "eventStatus": m.cancelled
          ? "https://schema.org/EventCancelled"
          : "https://schema.org/EventScheduled",
        "competitor": [
          { "@type": "SportsTeam", "name": m.homeName, "alternateName": m.homeFa || m.homeName },
          { "@type": "SportsTeam", "name": m.awayName, "alternateName": m.awayFa || m.awayName },
        ],
        ...(m.stadium
          ? { "location": { "@type": "Place", "name": m.stadium, ...(m.city ? { "address": m.city } : {}) } }
          : {}),
        ...(m.utcTime ? { "startDate": m.utcTime } : {}),
        ...(m.leagueName ? { "superEvent": { "@type": "SportsEvent", "name": m.leagueName } } : {}),
      };
    }
  } catch {
    ld = null; // never break the page for structured data
  }

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={ld} />
        <MatchDetail matchId={id} />
      </main>
      <SiteFooter />
    </div>
  );
}
