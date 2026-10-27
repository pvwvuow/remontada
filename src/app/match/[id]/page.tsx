import type { Metadata } from "next";
import { MatchDetail } from "@/components/remontada/match-detail";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { JsonLd } from "@/components/remontada/json-ld";
import { getMatchLdData } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";

// ---- dynamic SEO (cycle 29) ------------------------------------------------
// Title/description from the same cached match payload the JSON-LD uses:
// «رئال مادرید - بارسلونا | رمانتادا» instead of a generic static title.
// Failures degrade to the old static metadata and never break the page.
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  if (!/^\d{4,12}$/.test(id)) {
    // fix cycle-33: empty alternates suppresses the layout's root canonical
    return { title: "جزئیات مسابقه", robots: { index: false, follow: false }, alternates: {} };
  }
  try {
    const m = await getMatchLdData(id);
    // fix cycle-33: feed has no such match → empty page, keep it unindexed
    if (!m) return { title: "جزئیات مسابقه", robots: { index: false, follow: false }, alternates: {} };
    const home = m.homeFa || m.homeName;
    const away = m.awayFa || m.awayName;
    const title = `${home} - ${away}`;
    const kickoff = m.utcTime ? new Date(m.utcTime).getTime() : NaN;
    const state = m.cancelled
      ? "این بازی لغو شده است."
      : m.finished
        ? "نتیجه، خلاصه رویدادها و آمار کامل بازی."
        : Number.isFinite(kickoff) && kickoff <= Date.now()
          ? "پخش زنده، آمار لحظه‌ای و ترکیب تیم‌ها."
          : "زمان شروع، پیش‌بازی و آمار دو تیم.";
    const desc = m.leagueName ? `${title} در ${m.leagueName} — ${state}` : `${title} — ${state}`;
    return {
      title,
      description: desc,
      alternates: { canonical: `/match/${id}` },
      openGraph: { title: `${title} | رمانتادا`, description: desc },
    };
  } catch {
    // fix cycle-33: upstream hiccup → keep the empty shell unindexed
    return { title: "جزئیات مسابقه", robots: { index: false, follow: false }, alternates: {} };
  }
}

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
