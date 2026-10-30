"use client";

// ------------------------------------------------------------------
// Remontada — floating back-to-top button
// ------------------------------------------------------------------
import { useEffect, useState } from "react";
import { cn } from "@/lib/utils";

export function BackToTop() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 300);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // ui-cycle-8 (BL-8 audit): the CSS reduced-motion guard cannot reach
  // JS-driven scrolling — behavior:"smooth" animated the whole viewport
  // trip for motion-sensitive users. Honor the media query at click time
  // (not module load) so a mid-session OS toggle is respected too.
  const scrollToTop = () => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    window.scrollTo({ top: 0, behavior: reduce ? "auto" : "smooth" });
  };

  return (
    <button
      type="button"
      onClick={scrollToTop}
      aria-label="بازگشت به بالای صفحه"
      className={cn(
        "fixed bottom-24 sm:bottom-5 start-5 z-30 w-11 h-11 rounded-full glass-popover text-sky-soft flex items-center justify-center transition-all duration-300 hover:text-foreground hover:border-sky-soft/45",
        visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-3 pointer-events-none"
      )}
    >
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M12 19V5M5 12l7-7 7 7" />
      </svg>
    </button>
  );
}
