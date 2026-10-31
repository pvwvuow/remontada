// ------------------------------------------------------------------
// Remontada — ui-cycle-14: viewport-gated card entrances
// ------------------------------------------------------------------
// The studio entrance (.glass-card card-in, cycle-60) fired for EVERY
// card at t=0 — live probe (390×844, home): 186 entrances, 183 below
// the fold on the ~17k px portal page. Those finished before any user
// could scroll to them: pure startup compositor work with zero UX
// value (the effect is never seen). This gate keeps the exact
// above-fold feel and gives below-fold cards their entrance on
// approach instead.
//
// Safety model:
// - Cards WITHOUT .reveal are fully visible (the from-frame opacity:0
//   only exists while the animation class is present) — so SSR, no-JS
//   and any missed node degrade to "no entrance", never to blank.
// - prefers-reduced-motion: reduce → the observer never arms (and the
//   CSS kill-switch in globals.css stays as the second belt).
// - Renders null — zero DOM footprint, no testid, no layout change.
"use client";

import { useEffect } from "react";

const SELECTOR = ".glass-card, .glass-hero, .glass-scorer-hero";

export function CardReveal() {
  useEffect(() => {
    if (typeof window === "undefined") return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    if (!("IntersectionObserver" in window)) return;

    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (!e.isIntersecting) continue;
          const el = e.target as HTMLElement;
          io.unobserve(el);
          // rAF so the class lands on its own frame — the 0.38s ease
          // plays exactly like the old t=0 entrance.
          requestAnimationFrame(() => el.classList.add("reveal"));
        }
      },
      // start slightly before the card actually enters so the entrance
      // is already mid-flight when it crosses the edge (studio feel)
      { rootMargin: "0px 0px -6% 0px", threshold: 0 }
    );

    const arm = (root: ParentNode) => {
      root.querySelectorAll<HTMLElement>(SELECTOR).forEach((el) => {
        if (!el.classList.contains("reveal")) io.observe(el);
      });
    };
    arm(document);

    // client-side navigation / tab switches mount new cards — offer
    // them to the same observer (revealed nodes are already unobserved)
    const mo = new MutationObserver((muts) => {
      for (const m of muts) {
        m.addedNodes.forEach((n) => {
          if (!(n instanceof HTMLElement)) return;
          if (n.matches(SELECTOR)) io.observe(n);
          arm(n);
        });
      }
    });
    mo.observe(document.body, { childList: true, subtree: true });

    return () => {
      io.disconnect();
      mo.disconnect();
    };
  }, []);

  return null;
}
