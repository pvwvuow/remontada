import type { Metadata } from "next";
import Link from "next/link";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { BackToTop } from "@/components/remontada/back-to-top";
import { FavoritesSection } from "@/components/remontada/favorites-section";
import { TeamLogo } from "@/components/remontada/team-logo";
import { LEAGUES } from "@/lib/leagues";

export const metadata: Metadata = {
  title: "لیگ‌ها و جام‌ها",
  description: "فهرست لیگ‌های پوشش‌داده‌شده در رمانتادا: لیگ قهرمانان اروپا، پریمیرلیگ، لالیگا، سری‌آ، بوندسلیگا، لیگ ۱ فرانسه و لیگ خلیج فارس",
};

// FotMob team ids (verified against live standings / match feed)
const POPULAR_TEAMS: { id: number; fa: string; en: string; leagueKey: string }[] = [
  { id: 101610, fa: "پرسپولیس", en: "Persepolis", leagueKey: "persiangulf" },
  { id: 101614, fa: "استقلال", en: "Esteghlal", leagueKey: "persiangulf" },
  { id: 8633, fa: "رئال‌مادرید", en: "Real Madrid", leagueKey: "laliga" },
  { id: 8634, fa: "بارسلونا", en: "Barcelona", leagueKey: "laliga" },
  { id: 10260, fa: "منچستریونایتد", en: "Manchester United", leagueKey: "pl" },
];

export default function LeaguesPage() {
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5">
        <div className="mb-4 px-1">
          <h1 className="text-lg font-black">لیگ‌ها و جام‌ها</h1>
          <p className="text-[11px] text-muted-foreground mt-0.5">
            روی هر لیگ کلیک کنید تا جدول رده‌بندی، برنامه بازی‌ها، نتایج اخیر و آقای گل آن را ببینید.
          </p>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          {LEAGUES.map((l) => (
            <Link
              key={l.key}
              href={`/league/${l.key}`}
              prefetch={false}
              className="group rounded-2xl border border-border/60 bg-card/60 overflow-hidden hover:border-primary/30 hover:bg-card transition-all p-4 flex items-center gap-3.5"
            >
              <div className="w-11 h-11 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="text-primary" aria-hidden>
                  <path d="M12 3l9 4.5v9L12 21l-9-4.5v-9L12 3z" />
                  <path d="M12 8l4.5 3.2-1.7 5.3H9.2L7.5 11.2 12 8z" />
                </svg>
              </div>
              <div className="min-w-0 flex-1">
                <h2 className="font-black text-[14px] truncate group-hover:text-primary transition-colors">{l.faName}</h2>
                <p className="text-[10.5px] text-muted-foreground mt-0.5 truncate">{l.enName}</p>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <span className="text-[10px] font-bold text-muted-foreground border border-border rounded-md px-1.5 py-0.5">
                  {l.ccode3}
                </span>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" className="text-muted-foreground/40 group-hover:text-primary transition-colors" aria-hidden>
                  <path d="M15 18l-6-6 6-6" />
                </svg>
              </div>
            </Link>
          ))}
        </div>

        {/* favorite teams (localStorage) */}
        <FavoritesSection />

        {/* popular teams */}
        <section className="mt-7" aria-label="تیم‌های محبوب">
          <div className="flex items-center gap-2 mb-3 px-1">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className="text-chart-2" aria-hidden>
              <path d="M12 3l2.4 5.6 6.1.5-4.6 4 1.4 6-5.3-3.2L6.7 19l1.4-6-4.6-4 6.1-.5L12 3z" />
            </svg>
            <h2 className="text-sm font-black">تیم‌های محبوب</h2>
            <span className="text-[10px] text-muted-foreground ms-auto">دسترسی سریع به صفحه‌ی تیم</span>
          </div>
          <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-5">
            {POPULAR_TEAMS.map((t) => (
              <Link
                key={t.id}
                href={`/team/${t.id}`}
                prefetch={false}
                className="group rounded-2xl border border-border/60 bg-card/60 p-3.5 flex flex-col items-center gap-2 text-center hover:border-primary/40 hover:bg-card transition-all"
              >
                <TeamLogo id={t.id} alt={t.fa} size={34} className="group-hover:scale-110 transition-transform" />
                <span className="font-bold text-[12px] leading-tight group-hover:text-primary transition-colors">{t.fa}</span>
                <span className="text-[9px] text-muted-foreground truncate w-full">{t.en}</span>
              </Link>
            ))}
          </div>
        </section>
      </main>
      <SiteFooter />
      <BackToTop />
    </div>
  );
}
