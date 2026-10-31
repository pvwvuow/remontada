// ------------------------------------------------------------------
// Remontada — /search  (shareable search results — cycle-296 additive)
// Search results lived only in the header dropdown; a query could
// never be shared, bookmarked or revisited. This page is the missing
// distribution surface: same /api/search contract, same five sections
// and anchors as the dropdown, and ?q= as the URL state (the client
// debounces typing into the address, so every result view is a link).
// ------------------------------------------------------------------
import type { Metadata } from "next";
import { Suspense } from "react";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { SearchPageClient } from "@/components/remontada/search-page-client";

export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "جستجو",
  // the classic search-page SEO contract: crawlable links inside, but the
  // page itself must never enter the index with unbounded ?q= permutations
  robots: { index: false, follow: true },
  // fix-33 shell convention: a noindex page must not advertise a canonical
  // it does not own — which also keeps it out of the cycle-295 RSS head
  // parity by design (noindex shells carry no alternates, ever)
  alternates: {},
};

export default function SearchPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-2xl mx-auto px-3 sm:px-5 py-5">
        {/* useSearchParams lives in the client — the Suspense boundary is
            the Next contract for reading the URL in a prerendered tree */}
        <Suspense
          fallback={
            <div className="glass-card p-4 text-[12px] font-bold text-muted-foreground" aria-busy="true" aria-label="در حال بارگذاری جستجو">
              در حال بارگذاری جستجو…
            </div>
          }
        >
          <SearchPageClient />
        </Suspense>
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
