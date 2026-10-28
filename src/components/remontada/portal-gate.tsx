"use client";

// ------------------------------------------------------------------
// Remontada — Portal Gate (ui-quest 2)
// A minimal fantasy "game boot" moment on the first page view of a
// session: the brand glyph materializes with a breathing arcane glow
// and the title gets a shine sweep, then the veil fades away.
// Rules of engagement:
//   - shows at most once per browser session (sessionStorage)
//   - skipped entirely when the user prefers reduced motion
//   - pointer-events: none — pure ambience, never blocks the page
//   - self-removes from the DOM after the fade
// ------------------------------------------------------------------
import { useEffect, useState } from "react";

type Phase = "hidden" | "in" | "out";

export function PortalGate() {
  const [phase, setPhase] = useState<Phase>("hidden");

  useEffect(() => {
    try {
      if (sessionStorage.getItem("rm-portal-gate") === "1") return;
      sessionStorage.setItem("rm-portal-gate", "1");
      if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    } catch {
      return; // storage disabled → stay invisible, never annoy
    }
    setPhase("in");
    const t1 = setTimeout(() => setPhase("out"), 1450);
    const t2 = setTimeout(() => setPhase("hidden"), 2150);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);

  if (phase === "hidden") return null;
  return (
    <div className={phase === "out" ? "portal-gate portal-gate-out" : "portal-gate"} aria-hidden>
      <div className="portal-gate-core">
        <div className="portal-gate-glyph">
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden>
            <circle cx="12" cy="12" r="10" />
            <path d="M12 7l4.5 3.2-1.7 5.3H9.2L7.5 10.2 12 7z" />
          </svg>
        </div>
        <p className="portal-gate-title">رمانتادا</p>
        <p className="portal-gate-sub">ورود به قلمرو زندهٔ فوتبال</p>
      </div>
    </div>
  );
}
