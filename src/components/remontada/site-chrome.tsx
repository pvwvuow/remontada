// ------------------------------------------------------------------
// Remontada — shared site chrome (header with portal nav + footer)
// ------------------------------------------------------------------
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { cn } from "@/lib/utils";
import { SearchBox } from "./search-box";
import { LiveFavoriteChip } from "./live-favorite-chip";

export function SiteLogo({ small = false }: { small?: boolean }) {
  return (
    <Link href="/" className="flex items-center gap-2.5 group shrink-0">
      <div className="brand-glyph relative w-9 h-9 flex items-center justify-center overflow-hidden pitch-lines">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="text-primary" aria-hidden>
          <circle cx="12" cy="12" r="10" />
          <path d="M12 7l4.5 3.2-1.7 5.3H9.2L7.5 10.2 12 7z" />
        </svg>
      </div>
      <div className="leading-tight hidden xs:block sm:block">
        <p className={`${small ? "text-base" : "text-lg"} font-black tracking-tight group-hover:text-primary transition-colors`}>
          رمانتادا<span className="text-primary">.</span>
        </p>
        <p className="text-[10px] text-muted-foreground font-medium">فوتبال، بی‌وقفه و زنده</p>
      </div>
    </Link>
  );
}

const NAV_ITEMS = [
  { href: "/", label: "نتایج زنده", icon: "live" },
  { href: "/leagues", label: "لیگ‌ها", icon: "trophy" },
  { href: "/topscorers", label: "گلزنان", icon: "goal" },
  { href: "/news", label: "اخبار", icon: "news" },
] as const;

function NavIcon({ name }: { name: "live" | "trophy" | "goal" | "news" }) {
  if (name === "live") {
    return (
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
        <circle cx="12" cy="12" r="3" />
        <path d="M5.6 5.6a9 9 0 0 0 0 12.8M18.4 5.6a9 9 0 0 1 0 12.8" />
      </svg>
    );
  }
  if (name === "trophy") {
    return (
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M8 21h8M12 17v4" />
        <path d="M7 4h10v5a5 5 0 0 1-10 0V4z" />
        <path d="M17 5h3a2 2 0 0 1-2 4h-1M7 5H4a2 2 0 0 0 2 4h1" />
      </svg>
    );
  }
  if (name === "goal") {
    return (
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <circle cx="12" cy="8" r="4.2" />
        <path d="M9 12l-2.5 9L12 18l5.5 3L15 12" />
      </svg>
    );
  }
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M4 5h16M4 10h16M4 15h10M4 20h7" />
    </svg>
  );
}

export function SiteHeader({ children }: { children?: ReactNode }) {
  const pathname = usePathname();
  return (
    <header className="glass-bar sticky top-0 z-40">
      <div className="max-w-5xl mx-auto px-3 sm:px-5 py-2.5 flex items-center justify-between gap-3">
        <SiteLogo small />
        <div className="flex items-center gap-1.5 min-w-0">
          <SearchBox />
          <nav className="flex items-center gap-1 text-[12px] font-bold min-w-0 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" aria-label="ناوبری اصلی">
          {NAV_ITEMS.map((item) => {
            const active = item.href === "/" ? pathname === "/" || pathname.startsWith("/match") || pathname.startsWith("/player") : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "inline-flex items-center gap-1.5 px-2 sm:px-3 py-1.5 rounded-lg whitespace-nowrap shrink-0 transition-colors",
                  active ? "text-primary bg-primary/10 border border-primary/25" : "text-muted-foreground hover:text-foreground hover:bg-accent/50 border border-transparent"
                )}
              >
                <NavIcon name={item.icon} />
                {item.label}
              </Link>
            );
          })}
          </nav>
        </div>
      </div>
      {/* optional page-specific row (e.g. home tabs + refresh controls) —
          keeps the shared chrome single-source while letting each page
          extend the sticky header with its own controls */}
      {children != null && (
        <div className="max-w-5xl mx-auto px-3 sm:px-5">{children}</div>
      )}
      {/* live favorite strip — only renders when a favorite team is playing now */}
      <LiveFavoriteChip />
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="glass-bar-footer mt-auto">
      <div className="max-w-5xl mx-auto px-4 py-5 flex flex-col items-center gap-1.5 text-center">
        <div className="flex items-center gap-3 text-[11px] font-bold text-muted-foreground">
          <Link href="/" className="hover:text-primary transition-colors">نتایج زنده</Link>
          <span aria-hidden>·</span>
          <Link href="/leagues" className="hover:text-primary transition-colors">لیگ‌ها</Link>
          <span aria-hidden>·</span>
          <Link href="/topscorers" className="hover:text-primary transition-colors">گلزنان</Link>
          <span aria-hidden>·</span>
          <Link href="/news" className="hover:text-primary transition-colors">اخبار</Link>
        </div>
        <p className="text-[10px] text-muted-foreground/70">
          داده‌ها از FotMob و ESPN — رمانتادا، مرجع فارسی نتایج زنده فوتبال
        </p>
      </div>
    </footer>
  );
}
