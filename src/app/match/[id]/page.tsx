import type { Metadata } from "next";
import { MatchDetail } from "@/components/remontada/match-detail";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { getMatchLdData } from "@/lib/fotmob";
import { fotmobTeamLogo } from "@/lib/leagues";
import { SITE_URL, RSS_ALTERNATE } from "@/lib/site";

// ---- dynamic SEO (cycle 29) ------------------------------------------------
// Title/description from the same cached match payload the JSON-LD uses:
// «رئال مادرید - بارسلونا | رمانتادا» instead of a generic static title.
// Failures degrade to the old static metadata and never break the page.
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  if (!/^\d{4,12}$/.test(id)) {
    // fix cycle-33: empty alternates suppresses the layout's root canonical
    return { title: "جزئیات مسابقه", robots: { index: false, follow: false }, alternates: {} };
  }
  try {
    const m = await getMatchLdData(id);
    // fix cycle-33: feed has no such match → empty page, keep it unindexed
    if (!m) return { title: "جزئیات مسابقه", robots: { index: false, follow: false }, alternates: {} };
    const home = m.homeFa || m.homeName;
    const away = m.awayFa || m.awayName;
    const title = `${home} - ${away}`;
    const kickoff = m.utcTime ? new Date(m.utcTime).getTime() : NaN;
    const state = m.cancelled
      ? "این بازی لغو شده است."
      : m.finished
        ? "نتیجه، خلاصه رویدادها و آمار کامل بازی."
        : Number.isFinite(kickoff) && kickoff <= Date.now()
          ? "پخش زنده، آمار لحظه‌ای و ترکیب تیم‌ها."
          : "زمان شروع، پیش‌بازی و آمار دو تیم.";
    const desc = m.leagueName ? `${title} در ${m.leagueName} — ${state}` : `${title} — ${state}`;
    // update cycle-306: the page-level openGraph object replaces the layout's
    // (which carries og.png) — the match card was shared with NO preview.
    // Primary image = the HOME team's real crest via the same teamlogo CDN
    // family the search index renders (live-probed 200); the id is additive
    // on MatchLdData (cycle-306) so a pre-existing 60s cached row without ids
    // — or any hiccup — degrades to the site og.png card, never no image.
    const ogImages = m.homeId
      ? [{ url: fotmobTeamLogo(m.homeId), alt: `نشان ${home}` }]
      : [{ url: "/og.png", width: 1200, height: 630, alt: "رمانتادا — نتایج زنده فوتبال" }];
    return {
      title,
      description: desc,
      alternates: { canonical: `/match/${id}`, ...RSS_ALTERNATE },
      // update cycle-340: complete the share-card family — twitter object was
      // absent (twitter:title fell back to the layout default) and the og
      // object carried no url/siteName/locale. ogImages degrade to og.png (306).
      openGraph: {
        title: `${title} | رمانتادا`,
        description: desc,
        type: "website",
        siteName: "رمانتادا",
        locale: "fa_IR",
        url: `${SITE_URL}/match/${id}`,
        images: ogImages,
      },
      twitter: {
        card: "summary_large_image",
        title: `${title} | رمانتادا`,
        description: desc,
        images: ogImages.map((i) => i.url),
      },
    };
  } catch {
    // fix cycle-33: upstream hiccup → keep the empty shell unindexed
    return { title: "جزئیات مسابقه", robots: { index: false, follow: false }, alternates: {} };
  }
}

export default async function MatchPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  // ---- SSR JSON-LD (cycle 18) ------------------------------------------------
  // Fetch minimal match data on the server and emit a SportsEvent script into
  // the initial HTML so crawlers without JS see structured data too.
  // Failure must never break the page: any problem → ld stays null.
  let ld: Record<string, unknown> | null = null;
  // update cycle-311: BreadcrumbList — same trail vocabulary league/[key] and
  // topscorers/[leagueKey] ship (خانه → لیگ‌ها), then the match's league hop
  // (resolved inside getMatchLdData from the upstream league ids) and the
  // SportsEvent name as the leaf. Older cached rows without leagueKey skip
  // the hop; positions stay sequential. Best-effort like SportsEvent: any
  // problem → null, never breaks the page. One upstream call feeds both LDs
  // (same 60s cache key — no extra FotMob request).
  let crumbLd: Record<string, unknown> | null = null;
  try {
    const m = await getMatchLdData(id);
    if (m) {
      ld = {
        "@context": "https://schema.org",
        "@type": "SportsEvent",
        "name": `${m.homeFa || m.homeName} در برابر ${m.awayFa || m.awayName}`,
        "alternateName": `${m.homeName} vs ${m.awayName}`,
        "sport": "Football",
        "url": `${SITE_URL}/match/${m.id}`,
        "eventStatus": m.cancelled
          ? "https://schema.org/EventCancelled"
          : "https://schema.org/EventScheduled",
        "competitor": [
          { "@type": "SportsTeam", "name": m.homeName, "alternateName": m.homeFa || m.homeName },
          { "@type": "SportsTeam", "name": m.awayName, "alternateName": m.awayFa || m.awayName },
        ],
        // update cycle-317: location enriched with the structured facts of the
        // SAME cached payload's seo.eventJSONLD (probed live UA Chrome/124,
        // PL×2 + UCL×1): GeoCoordinates, a full PostalAddress (country +
        // city), plus the event's endDate and attendanceMode. The upstream
        // English LD itself is NOT embedded verbatim (cycle-316 precedent —
        // it would duplicate the Persian SportsEvent above). All optional —
        // old cached rows (60s TTL) or seo-less payloads emit exactly the
        // pre-317 LD. Same getMatchLdData call: zero new upstream requests.
        ...(m.stadium || m.venueGeo
          ? {
              "location": {
                "@type": "Place",
                ...(m.stadium ? { "name": m.stadium } : {}),
                ...(m.venueGeo
                  ? { "geo": { "@type": "GeoCoordinates", "latitude": m.venueGeo.lat, "longitude": m.venueGeo.lng } }
                  : {}),
                ...(m.venueCountry || m.city
                  ? {
                      "address": {
                        "@type": "PostalAddress",
                        ...(m.venueCountry ? { "addressCountry": m.venueCountry } : {}),
                        ...(m.city ? { "addressLocality": m.city } : {}),
                      },
                    }
                  : {}),
              },
            }
          : {}),
        ...(m.utcTime ? { "startDate": m.utcTime } : {}),
        ...(m.endDate ? { "endDate": m.endDate } : {}),
        ...(m.attendanceMode ? { "eventAttendanceMode": m.attendanceMode } : {}),
        ...(m.leagueName ? { "superEvent": { "@type": "SportsEvent", "name": m.leagueName } } : {}),
      };
      const crumbItems: Record<string, unknown>[] = [
        { "@type": "ListItem", "position": 1, "name": "خانه", "item": SITE_URL },
        { "@type": "ListItem", "position": 2, "name": "لیگ‌ها", "item": `${SITE_URL}/leagues` },
      ];
      if (m.leagueKey && m.leagueFa) {
        crumbItems.push({ "@type": "ListItem", "position": 3, "name": m.leagueFa, "item": `${SITE_URL}/league/${m.leagueKey}` });
      }
      crumbItems.push({
        "@type": "ListItem",
        "position": crumbItems.length + 1,
        "name": `${m.homeFa || m.homeName} در برابر ${m.awayFa || m.awayName}`,
        "item": `${SITE_URL}/match/${m.id}`,
      });
      crumbLd = {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": crumbItems,
      };
    }
  } catch {
    ld = null; // never break the page for structured data
    crumbLd = null;
  }

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={ld} />
        <JsonLd data={crumbLd} />
        {/* fix cycle-89: the page body had no id guard at all — a numeric id
            outside the API's \d{3,12} contract (e.g. 20 digits) SSR-rendered
            the bare MatchDetail client skeleton with zero h1, while the
            client-side 400 fallback only arrives after hydration. Render the
            same sr-only Persian h1 pattern as the cycle-59/84 shells so every
            page state has exactly one h1 even without JS */}
        {/^\d{3,12}$/.test(id) ? (
          <MatchDetail matchId={id} />
        ) : (
          <>
            <h1 className="sr-only">جزئیات مسابقه</h1>
            <p className="text-center text-muted-foreground text-sm py-16">شناسه مسابقه نامعتبر است.</p>
          </>
        )}
      </main>
      {/* fix cycle-37: match detail is a long shell (lineups + stats + H2H) — match the
          back-to-top coverage of the other long pages from cycles 34/35 */}
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
