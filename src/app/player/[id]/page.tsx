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
import { PlayerNotFoundError, getPlayerData, getPlayerFaqLd, type PlayerData } from "@/lib/fotmob";
import { RSS_ALTERNATE, SITE_URL } from "@/lib/site";
import { JsonLd } from "@/components/remontada/json-ld";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  if (!/^\d{3,12}$/.test(id)) {
    return { title: "پروفایل بازیکن", robots: { index: false, follow: false }, alternates: {} };
  }
  try {
    const p = await getPlayerData(id);
    // cycle-107: the metadata follows the honest display name (mapped Persian,
    // else the raw upstream English) — same rule as the profile h1
    const display = p.nameFa || p.name;
    const teamName = p.team?.fa || p.team?.name || "";
    const desc = `آمار فصل، بازی‌های اخیر، پست و مشخصات ${display}${teamName ? `، بازیکن ${teamName}` : ""} — رمانتادا`;
    return {
      title: `${display} — پروفایل بازیکن`,
      description: desc,
      alternates: { canonical: `/player/${id}`, ...RSS_ALTERNATE },
      // update cycle-306: the page-level openGraph object replaces the
      // layout's (which carries og.png) — the player card was shared with
      // NO preview. Per-player headshots were probed and REJECTED (the
      // images.fotmob.com playerimages path 403s for some ids — an og:image
      // that 404/403s is worse than the honest site card), so the player
      // card restores the site og.png parity instead.
      openGraph: {
        title: `${display} — پروفایل بازیکن | رمانتادا`,
        description: desc,
        type: "profile",
        siteName: "رمانتادا",
        locale: "fa_IR",
        url: `${SITE_URL}/player/${id}`,
        // update cycle-342: the person's own dynamic share card (runtime
        // next/og render — name + team + brand, the cycle-341 design) instead
        // of the generic static og.png; headshots stay rejected (306).
        images: [{ url: `/api/og/person/${id}?k=player`, width: 1200, height: 630, alt: `رمانتادا — ${display}` }],
      },
      // update cycle-340: twitter alignment — og was page-specific since 306
      // but twitter:title still fell back to the layout default (the exact
      // asymmetry the 339 card recorded as the family's remaining member).
      twitter: {
        card: "summary_large_image",
        title: `${display} — پروفایل بازیکن | رمانتادا`,
        description: desc,
        images: [`/api/og/person/${id}?k=player`],
      },
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

  // update cycle-311: BreadcrumbList — خانه → بازیکنان → player; completes the
  // trail pattern across the main page families (league/topscorers ship it,
  // cycle-310 added team). The leaf uses the same honest display name rule as
  // the h1/metadata (cycle-107: mapped Persian, else raw English). Only on the
  // success branch — error/invalid shells carry no structured data (same as
  // the metadata's noindex contract).
  const playerCrumbLd: Record<string, unknown> | null = player
    ? {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
          { "@type": "ListItem", "position": 1, "name": "خانه", "item": SITE_URL },
          { "@type": "ListItem", "position": 2, "name": "بازیکنان", "item": `${SITE_URL}/players` },
          { "@type": "ListItem", "position": 3, "name": player.nameFa || player.name, "item": `${SITE_URL}/player/${id}` },
        ],
      }
    : null;

  // cycle-320: FAQPage on the player page — the playerData.meta.faqJSONLD gap
  // (seen-but-unopened until the live probe; the 317 coach probe had hit a
  // payload without the key). Persian rebuild from the SAME processed
  // PlayerData the page already fetched (zero new upstream requests) — the
  // 316/317 convention: no verbatim English LD. Only on the success branch;
  // invalid-id/failed shells carry no structured data (same contract as the
  // breadcrumb above and the metadata noindex).
  const playerFaqLd: Record<string, unknown> | null = player ? getPlayerFaqLd(player) : null;

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main id="main-content" className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={playerCrumbLd} />
        <JsonLd data={playerFaqLd} />
        {!valid ? (
          <>
            {/* fix cycle-84: the invalid-id error shell had no h1 (cycle-83 patrol
                finding) — same sr-only Persian h1 pattern as the cycle-74
                unknown-team shell so every page state has exactly one h1 */}
            <h1 className="sr-only">پروفایل بازیکن</h1>
            <p className="text-center text-muted-foreground text-sm py-16">شناسه بازیکن نامعتبر است.</p>
          </>
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
