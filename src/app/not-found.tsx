import Link from "next/link";
import type { Metadata } from "next";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";
import { faDigits } from "@/lib/format";

// update cycle-39: portal-wide Persian 404 — replaces Next's default English
// error page with the same glass design language as the EmptyState component
// (cycle-34): dashed card, themed icon, friendly Persian copy, action links.
export const metadata: Metadata = {
  title: "صفحه پیدا نشد",
  robots: { index: false, follow: false },
};

export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col">
      <SiteHeader />
      <main className="flex-1 w-full max-w-3xl mx-auto px-3 sm:px-5 py-5 flex items-center justify-center">
        <div className="w-full rounded-2xl border border-dashed border-glass-border-soft bg-white/[0.02] px-6 py-14 text-center">
          <div className="mx-auto w-14 h-14 rounded-2xl bg-white/[0.04] border border-glass-border-soft flex items-center justify-center mb-4">
            <svg
              width="26"
              height="26"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.6"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="text-muted-foreground"
              aria-hidden
            >
              {/* football gone out of bounds: pitch line + ball drifting away */}
              <path d="M2.5 16.5h19" />
              <circle cx="12" cy="10" r="4.2" />
              <path d="M12 7.4l2.1 1.5-.8 2.5h-2.6l-.8-2.5 2.1-1.5z" />
            </svg>
          </div>
          {/* fix cycle-74: the 404 shell had no heading at all (cycle-73
              finding) — the big ۴۰۴ becomes the real h1 (same classes,
              Tailwind preflight renders it identically) */}
          <h1 className="text-5xl font-black tabular-persian text-primary/90 mb-3">{faDigits(404)}</h1>
          <p className="font-black text-sm mb-1">توپ از خط بیرون رفت!</p>
          <p className="text-xs text-muted-foreground">
            صفحه‌ای که دنبالش بودید پیدا نشد — شاید حذف شده یا آدرس اشتباه است.
          </p>
          <p className="text-[11px] text-muted-foreground/70 mt-1">
            می‌توانید از لینک‌های زیر ادامه دهید یا تیم مورد نظرتان را با جستجوی هدر پیدا کنید.
          </p>
          <div className="mt-5 flex flex-wrap items-center justify-center gap-2">
            <Link
              href="/"
              className="inline-flex items-center gap-1.5 rounded-xl bg-primary/15 border border-primary/40 text-primary text-xs font-bold px-4 py-2 hover:bg-primary/25 transition-colors"
            >
              نتایج زنده امروز
            </Link>
            <Link
              href="/leagues"
              className="inline-flex items-center gap-1.5 rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.04] text-xs font-bold px-4 py-2 hover:bg-white/[0.08] transition-colors"
            >
              لیگ‌ها
            </Link>
            <Link
              href="/topscorers"
              className="inline-flex items-center gap-1.5 rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.04] text-xs font-bold px-4 py-2 hover:bg-white/[0.08] transition-colors"
            >
              گلزنان
            </Link>
          </div>
        </div>
      </main>
      <SiteFooter />
    </div>
  );
}
