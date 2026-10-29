"use client";

// ------------------------------------------------------------------
// Remontada — game-menu navigation dock (ui campaign task 3/4, cycle-63)
// Fixed glass pill in the thumb zone, phones only. Lives in the root
// layout (NOT inside the header) so no sticky/blur ancestor can ever
// become its containing block — always anchored to the viewport.
// ------------------------------------------------------------------
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const DOCK_ITEMS = [
  { href: "/", label: "نتایج زنده", icon: "live" },
  { href: "/leagues", label: "لیگ‌ها", icon: "trophy" },
  { href: "/topscorers", label: "گلزنان", icon: "goal" },
  { href: "/players", label: "بازیکنان", icon: "players" },
  { href: "/news", label: "اخبار", icon: "news" },
] as const;

function DockIcon({ name }: { name: "live" | "trophy" | "goal" | "news" | "players" }) {
  if (name === "live") {
    return (
      <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
        <circle cx="12" cy="12" r="3" />
        <path d="M5.6 5.6a9 9 0 0 0 0 12.8M18.4 5.6a9 9 0 0 1 0 12.8" />
      </svg>
    );
  }
  if (name === "trophy") {
    return (
      <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M8 21h8M12 17v4" />
        <path d="M7 4h10v5a5 5 0 0 1-10 0V4z" />
        <path d="M17 5h3a2 2 0 0 1-2 4h-1M7 5H4a2 2 0 0 0 2 4h1" />
      </svg>
    );
  }
  if (name === "goal") {
    return (
      <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <circle cx="12" cy="8" r="4.2" />
        <path d="M9 12l-2.5 9L12 18l5.5 3L15 12" />
      </svg>
    );
  }
  if (name === "players") {
    return (
      <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <circle cx="9" cy="8" r="3.2" />
        <path d="M2.8 19a6.2 6.2 0 0 1 12.4 0" />
        <path d="M16.2 5.1a2.9 2.9 0 1 1 1 5.6" />
        <path d="M15.4 13.7a5.6 5.6 0 0 1 5.8 4.8" />
      </svg>
    );
  }
  return (
    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M4 5h16M4 10h16M4 15h10M4 20h7" />
    </svg>
  );
}

export function NavDock() {
  const pathname = usePathname();
  return (
    <nav
      aria-label="منوی بازی"
      className="sm:hidden fixed z-40 inset-x-3 [bottom:calc(0.75rem+env(safe-area-inset-bottom))]"
    >
      <div className="glass-popover rounded-2xl flex items-stretch justify-between px-1.5 py-1.5">
        {DOCK_ITEMS.map((item) => {
          const active =
            item.href === "/"
              ? pathname === "/" || pathname.startsWith("/match") || pathname.startsWith("/player/")
              : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={active ? "page" : undefined}
              className={cn(
                "flex flex-col items-center justify-center gap-1 rounded-xl px-2 py-1.5 min-w-0 flex-1 transition-all duration-200",
                active
                  ? "text-primary bg-primary/10 border border-primary/30 shadow-[0_0_16px_oklch(0.7_0.1_300/0.28)]"
                  : "text-muted-foreground border border-transparent hover:text-foreground active:scale-95"
              )}
            >
              <DockIcon name={item.icon} />
              <span className="text-[9.5px] font-black whitespace-nowrap">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
