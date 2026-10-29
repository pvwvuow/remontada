import type { Metadata } from "next";
import { PlayersView } from "@/components/remontada/players-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { getAllTopScorers, type GlobalScorer } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";

const TITLE = "بازیکنان برتر لیگ‌های بزرگ";
const DESCRIPTION =
  "چهره‌های ماندگار فوتبال — برترین گلزنان و پاس‌کاران به‌همراه اسکواد کامل همهٔ تیم‌های لیگ قهرمانان اروپا، پریمیرلیگ، لالیگا، سری‌آ، بوندسلیگا، لیگ ۱ فرانسه و لیگ خلیج فارس با عکس و پروفایل کامل — رمانتادا";

export const metadata: Metadata = {
  title: TITLE,
  description: DESCRIPTION,
  alternates: { canonical: "/players" },
  openGraph: {
    title: `${TITLE} | رمانتادا`,
    description: DESCRIPTION,
    url: `${SITE_URL}/players`,
    type: "website",
    siteName: "رمانتادا",
    locale: "fa_IR",
  },
};

export default async function PlayersPage() {
  // best-effort server-side snapshot for the ItemList JSON-LD (same pattern
  // as /topscorers): the client view always fetches live data from
  // /api/topscorers at runtime, so the UI is never affected by build-time state
  let scorers: GlobalScorer[] = [];
  try {
    scorers = (await getAllTopScorers()).scorers.slice(0, 12);
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
          ...(s.playerId != null ? { "url": `${SITE_URL}/player/${s.playerId}` } : {}),
        })),
      }
    : null;

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={itemListLd} />
        <PlayersView />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
