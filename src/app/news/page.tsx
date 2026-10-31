import type { Metadata } from "next";
import { NewsPageClient } from "@/components/remontada/news-page-client";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { getNewsFeed, type NewsItem } from "@/lib/news";
import { SITE_URL, RSS_ALTERNATE } from "@/lib/site";

export const metadata: Metadata = {
  title: "اخبار فوتبال",
  description: "آخرین اخبار داغ فوتبال جهان از ESPN، BBC Sport و Sky Sports با ترجمه فارسی — رمانتادا",
  // fix cycle-289: self canonical — previously inherited the layout root "/"
  alternates: { canonical: "/news", ...RSS_ALTERNATE },
};

export default async function NewsPage() {
  // update cycle-292: ItemList JSON-LD — the third and last nav-dock index
  // without page-level structured data (/players had ItemList, cycle-291
  // closed /leagues). Same best-effort server-snapshot pattern as /players:
  // a build-time hiccup just omits the LD, the client view always fetches
  // live data from /api/news so the UI is never affected by the snapshot.
  let items: NewsItem[] = [];
  try {
    items = (await getNewsFeed()).slice(0, 12);
  } catch {
    items = []; // cold-producer outage / upstream hiccup → no ItemList, page stays valid
  }
  const itemListLd: Record<string, unknown> | null = items.length
    ? {
        "@context": "https://schema.org",
        "@type": "ItemList",
        "name": "اخبار فوتبال",
        "itemListOrder": "https://schema.org/ItemListOrderDescending",
        "numberOfItems": items.length,
        "itemListElement": items.map((n, i) => ({
          "@type": "ListItem",
          "position": i + 1,
          "name": n.titleFa || n.title,
          ...(n.link ? { "url": n.link } : {}),
        })),
      }
    : null;

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={itemListLd} />
        <div className="mb-4 px-1 flex items-center justify-between">
          <div>
            <h1 className="text-lg font-black">اخبار فوتبال</h1>
            <p className="text-[11px] text-muted-foreground mt-0.5">تیترهای ESPN، BBC Sport و Sky Sports با ترجمه‌ی خودی</p>
          </div>
        </div>
        <NewsPageClient />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
