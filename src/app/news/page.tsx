import type { Metadata } from "next";
import { NewsPageClient } from "@/components/remontada/news-page-client";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";

export const metadata: Metadata = {
  title: "اخبار فوتبال",
  description: "آخرین اخبار داغ فوتبال جهان از ESPN، BBC Sport و Sky Sports با ترجمه فارسی — رمانتادا",
};

export default function NewsPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-5xl mx-auto px-3 sm:px-5 py-5">
        <div className="mb-4 px-1 flex items-center justify-between">
          <div>
            <h1 className="text-lg font-black">اخبار فوتبال</h1>
            <p className="text-[11px] text-muted-foreground mt-0.5">تیترهای ESPN، BBC Sport و Sky Sports با ترجمه‌ی خودی</p>
          </div>
        </div>
        <NewsPageClient />
      </main>
      <SiteFooter />
    </div>
  );
}
