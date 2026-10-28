import type { Metadata } from "next";
import { TeamView } from "@/components/remontada/team-view";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { JsonLd } from "@/components/remontada/json-ld";
import { getTeamIndex } from "@/lib/fotmob";
import { SITE_URL } from "@/lib/site";

// ---- dynamic SEO (cycle 29) ------------------------------------------------
// Team pages used to ship a generic static title and no structured data.
// The lightweight in-memory team index (built from league standings, 10-min
// cache) gives us the Persian + English name and the league for the title,
// description and a SportsTeam JSON-LD — all best-effort: any failure falls
// back to the old static metadata and never breaks the page.
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  if (!/^\d{1,10}$/.test(id)) {
    // fix cycle-33: empty alternates suppresses the layout's root canonical —
    // a noindex page must not advertise a canonical it does not own
    return { title: "صفحه تیم", robots: { index: false, follow: false }, alternates: {} };
  }
  try {
    const teamId = Number(id);
    const entry = (await getTeamIndex()).find((t) => t.teamId === teamId);
    if (!entry) {
      // numeric but unknown → empty page; keep it out of the index too
      return { title: "صفحه تیم", robots: { index: false, follow: false }, alternates: {} };
    }
    const name = entry.fa || entry.name;
    const title = `${name} — صفحه تیم`;
    const desc = `نتایج اخیر، بازی‌های پیش‌رو، رتبه و فرم ${name}${entry.leagueFa ? ` در ${entry.leagueFa}` : ""} — رمانتادا`;
    return {
      title,
      description: desc,
      alternates: { canonical: `/team/${id}` },
      openGraph: { title: `${name} — صفحه تیم | رمانتادا`, description: desc },
    };
  } catch {
    // upstream hiccup → in-page error state; keep the empty shell unindexed
    return { title: "صفحه تیم", robots: { index: false, follow: false }, alternates: {} };
  }
}

export default async function TeamPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const teamId = Number(id);

  // SportsTeam structured data — same cached index, same graceful contract
  let teamLd: Record<string, unknown> | null = null;
  if (Number.isFinite(teamId) && teamId > 0 && /^\d{1,10}$/.test(id)) {
    try {
      const entry = (await getTeamIndex()).find((t) => t.teamId === teamId);
      if (entry) {
        teamLd = {
          "@context": "https://schema.org",
          "@type": "SportsTeam",
          "name": entry.name,
          "alternateName": entry.fa || undefined,
          "sport": "Football",
          "url": `${SITE_URL}/team/${entry.teamId}`,
          ...(entry.logo ? { "image": entry.logo } : {}),
          ...(entry.leagueFa
            ? { "memberOf": { "@type": "SportsLeague", "name": entry.leagueFa } }
            : {}),
        };
      }
    } catch {
      teamLd = null; // never break the page for structured data
    }
  }

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        <JsonLd data={teamLd} />
        {Number.isFinite(teamId) && teamId > 0 ? (
          <TeamView teamId={teamId} />
        ) : (
          <>
            {/* fix cycle-84: the invalid-id error shell had no h1 (cycle-83 patrol
                finding) — same sr-only Persian h1 pattern as the cycle-74
                unknown-team shell so every page state has exactly one h1 */}
            <h1 className="sr-only">صفحه تیم</h1>
            <p className="text-center text-muted-foreground text-sm py-16">شناسه تیم نامعتبر است.</p>
          </>
        )}
      </main>
      <BackToTop />
      <SiteFooter />
    </div>
  );
}
