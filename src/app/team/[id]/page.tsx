import type { Metadata } from "next";
import { TeamView } from "@/components/remontada/team-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";

export const metadata: Metadata = {
  title: "صفحه تیم",
  description: "نتایج اخیر، بازی‌های پیش‌رو، رتبه و فرم تیم فوتبال — رمانتادا",
};

export default async function TeamPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const teamId = Number(id);
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        {Number.isFinite(teamId) && teamId > 0 ? (
          <TeamView teamId={teamId} />
        ) : (
          <p className="text-center text-muted-foreground text-sm py-16">شناسه تیم نامعتبر است.</p>
        )}
      </main>
      <SiteFooter />
    </div>
  );
}
