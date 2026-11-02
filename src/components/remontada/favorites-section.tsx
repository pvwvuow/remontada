"use client";

// ------------------------------------------------------------------
// Remontada — "favorite teams" section for the /leagues page
// ------------------------------------------------------------------
// Reads the localStorage favorites store; shows star-team cards with
// a quick-remove star. Shows a discoverability hint when empty.
import Link from "next/link";
import { FavoriteStar } from "@/components/remontada/favorite-star";
import { TeamLogo } from "@/components/remontada/team-logo";
import { useFavorites } from "@/lib/favorites";

export function FavoritesSection() {
  const favs = useFavorites();

  if (favs.length === 0) {
    return (
      <section className="mt-7" aria-label="تیم‌های مورد علاقه">
        <div className="flex items-center gap-2 mb-3 px-1">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className="text-amber-400" aria-hidden>
            <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
          </svg>
          <h2 className="rune-title text-sm font-black">تیم‌های مورد علاقه</h2>
        </div>
        <div className="glass-card border-dashed border-[color:var(--glass-border-soft)] px-4 py-5 flex items-center gap-3">
          <span className="text-amber-400/80 shrink-0" aria-hidden>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round">
              <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
            </svg>
          </span>
          <p className="text-[11.5px] text-muted-foreground leading-relaxed">
            هنوز تیمی انتخاب نکرده‌اید. در صفحه‌ی هر تیم روی{" "}
            <span className="text-amber-400 font-bold">ستاره</span> بزنید تا این‌جا نمایش داده شود و
            بازی‌هایش در صفحه‌ی نتایج برجسته شوند.
          </p>
        </div>
      </section>
    );
  }

  return (
    <section className="mt-7" aria-label="تیم‌های مورد علاقه">
      <div className="flex items-center gap-2 mb-3 px-1">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="1.9" strokeLinejoin="round" className="text-amber-400" aria-hidden>
          <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
        </svg>
        <h2 className="rune-title text-sm font-black">تیم‌های مورد علاقه</h2>
        <span className="text-[10px] font-bold text-amber-400/90 bg-amber-400/10 border border-amber-400/25 rounded-md px-1.5 py-0.5 tabular-persian">
          {new Intl.NumberFormat("fa-IR").format(favs.length)} تیم
        </span>
        <span className="text-[10px] text-muted-foreground ms-auto hidden sm:block">ستاره را دوباره بزنید تا حذف شود</span>
      </div>
      <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-4 lg:grid-cols-5">
        {favs.map((t) => (
          <div
            key={t.id}
            className="group relative glass-card glass-amber p-3.5 flex flex-col items-center gap-2 text-center hover:border-amber-400/40 transition-all"
          >
            <Link href={`/team/${t.id}`} prefetch={false} className="flex flex-col items-center gap-2 w-full">
              <TeamLogo id={t.id} alt={t.fa} size={34} className="group-hover:scale-110 transition-transform" />
              <span className="font-bold text-[12px] leading-tight group-hover:text-sky-soft transition-colors w-full truncate">
                {t.fa}
              </span>
              {t.en && <span className="text-[9px] text-muted-foreground truncate w-full">{t.en}</span>}
            </Link>
            <FavoriteStar
              team={{ id: t.id, fa: t.fa, en: t.en }}
              size={15}
              className="absolute top-1.5 end-1.5"
            />
          </div>
        ))}
      </div>
      {/* update cycle-425: the PERSONAL rung of the subscription-calendar
          ladder (312 league → 420 team → 421 fixture → 422 matchday →
          425 favorites) — the favorites' whole fixtures merged into ONE
          RFC 5545 file (/api/favorites-calendar?ids=). The honest
          link-visible ⇔ source-data-present contract: this branch only
          renders when favorites exist, so the CTA exists exactly when the
          source list does; the href rides the SAME ids the cards above
          show, in the same order. The visual language is the 422 home
          CTA's (the same calendar glyph + sky-soft label). */}
      <div className="mt-3 px-1" data-testid="fav-ics-row">
        <a
          href={`/api/favorites-calendar?ids=${favs.map((t) => t.id).join(",")}`}
          download
          data-testid="fav-ics-link"
          className="inline-flex items-center gap-1.5 text-[11px] font-bold text-sky-soft hover:text-foreground transition-colors"
        >
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" aria-hidden>
            <rect x="3.5" y="4.5" width="17" height="16" rx="3" />
            <path d="M8 2.5v4M16 2.5v4M3.5 10.5h17" />
            <path d="M9 14.5l2 2 4-4" />
          </svg>
          دانلود تقویم منتخب‌ها (ICS)
        </a>
      </div>
    </section>
  );
}
