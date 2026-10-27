// ------------------------------------------------------------------
// Remontada — /player/[id]  (fully server-rendered)
// Player profile from FotMob playerData. Behavior contract (cycle-19):
//   • unknown player → notFound() → real HTTP 404 (Persian not-found page)
//   • upstream/network failure → in-page error state (page stays 200)
//   • success → full SSR markup + Person JSON-LD in the initial HTML
// ------------------------------------------------------------------
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { PlayerProfile } from "@/components/remontada/player-profile";
import { PlayerNotFoundError, getPlayerData, type PlayerData } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  if (!/^\d{3,12}$/.test(id)) {
    return { title: "پروفایل بازیکن", robots: { index: false, follow: false }, alternates: {} };
  }
  try {
    const p = await getPlayerData(id);
    const teamName = p.team?.fa || p.team?.name || "";
    const desc = `آمار فصل، بازی‌های اخیر، پست و مشخصات ${p.name}${teamName ? `، بازیکن ${teamName}` : ""} — رمانتادا`;
    return {
      title: `${p.name} — پروفایل بازیکن`,
      description: desc,
      alternates: { canonical: `/player/${id}` },
      openGraph: { title: `${p.name} — پروفایل بازیکن | رمانتادا`, description: desc, type: "profile" },
    };
  } catch {
    // missing player / upstream hiccup — page itself handles the UX
    return { title: "پروفایل بازیکن", robots: { index: false, follow: false }, alternates: {} };
  }
}

export default async function PlayerPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const valid = /^\d{3,12}$/.test(id);

  let player: PlayerData | null = null;
  let failed = false;
  if (valid) {
    try {
      player = await getPlayerData(id);
    } catch (err) {
      // FotMob 200 + null / {error:true} → genuinely missing player
      if (err instanceof PlayerNotFoundError) notFound();
      // anything else is an upstream failure — show the in-page error state
      console.error("[/player]", err);
      failed = true;
    }
  }

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        {!valid ? (
          <p className="text-center text-muted-foreground text-sm py-16">شناسه بازیکن نامعتبر است.</p>
        ) : failed ? (
          <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-4 py-8 text-center flex flex-col items-center gap-3" role="alert">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" className="text-destructive" aria-hidden>
              <circle cx="12" cy="12" r="9.5" />
              <path d="M12 7.5v5.5M12 16.5v.01" />
            </svg>
            <p className="text-sm font-black text-destructive">خطا در دریافت اطلاعات بازیکن</p>
            <p className="text-[12px] text-muted-foreground leading-6 max-w-sm">
              ارتباط با منبع داده برقرار نشد. ممکن است مشکل موقتی باشد — چند لحظه بعد دوباره تلاش کنید.
            </p>
            <a
              href={`/player/${id}`}
              className="text-[12px] font-black text-primary bg-primary/10 border border-primary/30 rounded-lg px-4 py-1.5 hover:bg-primary/15 transition-colors"
            >
              تلاش دوباره
            </a>
          </div>
        ) : player ? (
          <PlayerProfile p={player} />
        ) : null}
      </main>
      <SiteFooter />
    </div>
  );
}
