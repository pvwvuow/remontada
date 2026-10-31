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
          {/* update cycle-302: the 295 feed was machine-only — head links on
              the 11 canonical pages serve crawlers, but a human had no visible
              entry point anywhere in the UI. This anchor closes the human
              discovery half of the distribution contract, in the empty slot
              of the news header (pure additive; head metadata untouched). */}
          <a
            href="/rss.xml"
            type="application/rss+xml"
            aria-label="فید خبری رمانتادا (RSS)"
            title="فید خبری رمانتادا (RSS)"
            className="shrink-0 inline-flex items-center gap-1.5 rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.04] px-3 py-1.5 text-xs font-bold text-muted-foreground hover:text-foreground hover:bg-white/[0.08] transition-colors"
          >
            <svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
              <path d="M2 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H2zm1.5 2.5c5.523 0 10 4.477 10 10a1 1 0 1 1-2 0 8 8 0 0 0-8-8 1 1 0 0 1 0-2zm0 4a6 6 0 0 1 6 6 1 1 0 1 1-2 0 4 4 0 0 0-4-4 1 1 0 0 1 0-2zm.5 7a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3z" />
            </svg>
            فید RSS
          </a>
        </div>
        <NewsPageClient />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
