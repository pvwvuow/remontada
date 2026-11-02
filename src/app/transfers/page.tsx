import type { Metadata } from "next";
import { TransfersPageClient } from "@/components/remontada/transfers-page-client";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { SITE_URL, RSS_ALTERNATE } from "@/lib/site";

// cycle-415: the portal-level «انتقال‌ها» surface — the third and last
// level of the backlog (league tab + team feed existed; the global wire
// upstream was never consumed). Server shell + client fetch, the /news
// page shape; the shell is prerendered, the wire is live at request time.

const TR_TITLE = "انتقال‌های فوتبال";
const TR_DESC =
  "تازه‌ترین انتقال‌های رسمی فوتبال جهان — جابه‌جایی بازیکنان با مبلغ کارمزد، ارزش بازار، تاریخ جلالی و وضعیت امانی — رمانتادا، مرجع فارسی فوتبال";

export const metadata: Metadata = {
  title: TR_TITLE,
  description: TR_DESC,
  alternates: { canonical: "/transfers", ...RSS_ALTERNATE },
  openGraph: {
    title: `${TR_TITLE} | رمانتادا`,
    description: TR_DESC,
    type: "website",
    siteName: "رمانتادا",
    locale: "fa_IR",
    url: `${SITE_URL}/transfers`,
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "رمانتادا — نتایج زنده فوتبال" }],
  },
  twitter: {
    card: "summary_large_image",
    title: `${TR_TITLE} | رمانتادا`,
    description: TR_DESC,
    images: ["/og.png"],
  },
};

export default function TransfersPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main id="main-content" className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <TransfersPageClient />
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
