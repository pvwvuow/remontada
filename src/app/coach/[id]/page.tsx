// ------------------------------------------------------------------
// Remontada — /coach/[id]  (fully server-rendered)
// Coach profile from FotMob playerData (the coach id-space rides the
// player endpoint — cycle-255 probe: Xabi Alonso 30889). Behavior contract
// (the cycle-74 unknown-entity shell convention, proven live: notFound()
// inside the catch trips Next's NoFallbackError in the standalone build):
//   • unknown id / non-coach → in-page «مربی یافت نشد» shell (page 200;
//     the /api/coach/[id] route still serves the real 404)
//   • upstream/network failure → in-page error state (page stays 200)
//   • success → full SSR markup in the initial HTML
// ------------------------------------------------------------------
import type { Metadata } from "next";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { CoachView } from "@/components/remontada/coach-view";
import { EmptyState } from "@/components/remontada/empty-state";
import { CoachNotFoundError, getCoachData, type CoachData } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  if (!/^\d{3,12}$/.test(id)) {
    return { title: "پروفایل مربی", robots: { index: false, follow: false }, alternates: {} };
  }
  try {
    const c = await getCoachData(id);
    const teamName = c.team?.fa || c.team?.name || "";
    const desc = `کارنامهٔ نیمکت، سوابق هدایت و افتخارات ${c.name}${teamName ? `، سرمربی ${teamName}` : ""} — رمانتادا`;
    return {
      title: `${c.name} — پروفایل مربی`,
      description: desc,
      alternates: { canonical: `/coach/${id}` },
      openGraph: { title: `${c.name} — پروفایل مربی | رمانتادا`, description: desc, type: "profile" },
    };
  } catch {
    // missing coach / upstream hiccup — the page itself handles the UX
    return { title: "پروفایل مربی", robots: { index: false, follow: false }, alternates: {} };
  }
}

export default async function CoachPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const valid = /^\d{3,12}$/.test(id);

  let coach: CoachData | null = null;
  let failed = false;
  let unknown = false;
  if (valid) {
    try {
      coach = await getCoachData(id);
    } catch (err) {
      // FotMob 200 + null / {error:true} / isCoach!==true → genuinely missing coach
      if (err instanceof CoachNotFoundError) {
        unknown = true;
      } else {
        // anything else is an upstream failure — show the in-page error state
        console.error("[/coach]", err);
        failed = true;
      }
    }
  }

  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        {!valid ? (
          <>
            {/* same sr-only Persian h1 pattern as the cycle-84 player shell —
                every page state has exactly one h1 */}
            <h1 className="sr-only">پروفایل مربی</h1>
            <p className="text-center text-muted-foreground text-sm py-16">شناسه مربی نامعتبر است.</p>
          </>
        ) : unknown ? (
          <>
            {/* cycle-74 shell convention: every page state has exactly one h1 */}
            <h1 className="sr-only">پروفایل مربی</h1>
            <EmptyState
              icon="shirt"
              title="مربی یافت نشد."
              sub="این شناسه مربی در منبع داده نیست یا به یک بازیکن تعلق دارد."
              action={{ label: "بازگشت به خانه", href: "/" }}
            />
          </>
        ) : failed ? (
          <div className="rounded-2xl border border-destructive/30 bg-destructive/10 px-4 py-8 text-center flex flex-col items-center gap-3" role="alert">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" className="text-destructive" aria-hidden>
              <circle cx="12" cy="12" r="9.5" />
              <path d="M12 7.5v5.5M12 16.5v.01" />
            </svg>
            <p className="text-sm font-black text-destructive">خطا در دریافت اطلاعات مربی</p>
            <p className="text-[12px] text-muted-foreground leading-6 max-w-sm">
              ارتباط با منبع داده برقرار نشد. ممکن است مشکل موقتی باشد — چند لحظه بعد دوباره تلاش کنید.
            </p>
            <a
              href={`/coach/${id}`}
              className="text-[12px] font-black text-primary bg-primary/10 border border-primary/30 rounded-lg px-4 py-1.5 hover:bg-primary/15 transition-colors"
            >
              تلاش دوباره
            </a>
          </div>
        ) : coach ? (
          <CoachView c={coach} />
        ) : null}
      </main>
      <SiteFooter />
    </div>
  );
}
