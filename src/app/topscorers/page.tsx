import type { Metadata } from "next";
import { TopScorersView } from "@/components/remontada/topscorers-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { getAllTopScorers, type GlobalScorer } from "@/lib/fotmob";
import { SITE_URL, RSS_ALTERNATE } from "@/lib/site";

const TITLE = "آقای گلان لیگ‌های بزرگ";
const DESCRIPTION =
  "جدول یکپارچه‌ی بهترین گلزنان لیگ قهرمانان اروپا، پریمیرلیگ، لالیگا، سری‌آ، بوندسلیگا، لیگ ۱ فرانسه و لیگ خلیج فارس — رمانتادا";

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: "/topscorers", ...RSS_ALTERNATE },
  openGraph: {
    title: `${TITLE} | رمانتادا`,
    description: DESCRIPTION,
    url: `${SITE_URL}/topscorers`,
    type: "website",
    siteName: "رمانتادا",
    locale: "fa_IR",
    // update cycle-306: the page-level openGraph object replaces the
    // layout's (which carries og.png) — restore the site-card parity
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "رمانتادا — نتایج زنده فوتبال" }],
  },
};

export default async function TopScorersPage() {
  // best-effort server-side snapshot for the ItemList JSON-LD (baked into the
  // prerendered HTML); the client view still fetches live data from
  // /api/topscorers at runtime, so the UI is never affected by build-time state
  let scorers: GlobalScorer[] = [];
  try {
    scorers = (await getAllTopScorers()).scorers.slice(0, 18);
  } catch {
    scorers = []; // build-time network hiccup / league feed outage → no ItemList, page stays valid
  }
  const itemListLd: Record<string, unknown> | null = scorers.length
    ? {
        "@context": "https://schema.org",
        "@type": "ItemList",
        "name": TITLE,
        "itemListOrder": "https://schema.org/ItemListOrderDescending",
        "numberOfItems": scorers.length,
        "itemListElement": scorers.map((s) => ({
          "@type": "ListItem",
          "position": s.rank,
          "name": s.name,
          // deep-link to the player page when we know the FotMob id, else the team page
          ...(s.playerId != null
            ? { "url": `${SITE_URL}/player/${s.playerId}` }
            : { "url": `${SITE_URL}/team/${s.teamId}` }),
        })),
      }
    : null;
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main id="main-content" className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={itemListLd} />
        <TopScorersView />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
