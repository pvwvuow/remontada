"use client";

// cycle-287: portal-wide Persian runtime error boundary — the exact sibling
// of update cycle-39's Persian 404 (not-found.tsx). Until now any unexpected
// client exception fell back to Next's default unstyled ENGLISH screen
// ("Application error: a client-side exception has occurred") with no
// recovery affordance and none of the site's design language. Same glass
// vocabulary as the 404 shell: dashed card, themed icon, friendly Persian
// copy, action row — plus a REAL recovery control (reset() re-renders the
// failed segment) and the digest code when Next provides one, so a user
// report can be traced server-side. Client component by framework contract
// (error.tsx receives the reset callback) — no metadata export allowed here.

import Link from "next/link";
import { useEffect } from "react";
import { SiteHeader, SiteFooter } from "@/components/remontada/site-chrome";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // same logging contract Next's built-in boundary uses — dev overlay and
    // server logs keep their evidence; production users just see the shell
    console.error(error);
  }, [error]);

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
              {/* red-card motif: the referee shows the card — page errored */}
              <rect x="7" y="4.5" width="10" height="15" rx="1.6" />
              <path d="M5 8.5v7" />
            </svg>
          </div>
          <h1 className="text-5xl font-black tabular-persian text-primary/90 mb-3">خطا!</h1>
          <p className="font-black text-sm mb-1">کارت قرمز به این صفحه!</p>
          <p className="text-xs text-muted-foreground">
            مشکلی غیرمنتظره پیش آمد — نگران نباشید، داوری با شماست: دوباره تلاش کنید.
          </p>
          <p className="text-[11px] text-muted-foreground/80 mt-1">
            اگر تکرار شد، به خانه برگردید یا تیم مورد نظرتان را با جستجوی هدر پیدا کنید.
          </p>
          {error.digest ? (
            <p className="text-[10px] text-muted-foreground/60 mt-2" dir="ltr">
              digest: {error.digest}
            </p>
          ) : null}
          <div className="mt-5 flex flex-wrap items-center justify-center gap-2">
            <button
              type="button"
              data-testid="error-retry"
              onClick={() => reset()}
              className="inline-flex items-center gap-1.5 rounded-xl bg-primary/15 border border-primary/40 text-primary text-xs font-bold px-4 py-2 hover:bg-primary/25 transition-colors cursor-pointer"
            >
              تلاش دوباره
            </button>
            <Link
              href="/"
              data-testid="error-home"
              className="inline-flex items-center gap-1.5 rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.04] text-xs font-bold px-4 py-2 hover:bg-white/[0.08] transition-colors"
            >
              نتایج زنده امروز
            </Link>
          </div>
        </div>
      </main>
      <SiteFooter />
    </div>
  );
}
