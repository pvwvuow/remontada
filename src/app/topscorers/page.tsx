import type { Metadata } from "next";
import { TopScorersView } from "@/components/remontada/topscorers-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";

export const metadata: Metadata = {
  title: "آقای گلان لیگ‌های بزرگ | رمانتادا",
  description: "جدول یکپارچه‌ی بهترین گلزنان لیگ قهرمانان اروپا، پریمیرلیگ، لالیگا، سری‌آ، بوندسلیگا، لیگ ۱ فرانسه و لیگ خلیج فارس — رمانتادا",
};

export default function TopScorersPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        <TopScorersView />
      </main>
      <SiteFooter />
    </div>
  );
}
