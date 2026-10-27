import type { Metadata } from "next";
import { MatchDetail } from "@/components/remontada/match-detail";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";

export const metadata: Metadata = {
  title: "جزئیات مسابقه",
  description: "رویدادهای زنده، آمار، ترکیب تیم‌ها و اطلاعات کامل مسابقه فوتبال",
};

export default async function MatchPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        <MatchDetail matchId={id} />
      </main>
      <SiteFooter />
    </div>
  );
}
