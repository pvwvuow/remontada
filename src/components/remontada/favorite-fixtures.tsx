"use client";

// ------------------------------------------------------------------
// Remontada — "upcoming matches of my teams" (client-only, cycle 20)
// Reads the localStorage favorites store (remontada:favorites) and
// scans the next 3 days of the matches feed (offset 0..2) for fixtures
// of those teams that have NOT started yet. Renders a compact card
// grid above the matches list on the home page. Refreshes every 5 min
// (tab-visible only). Renders nothing when: no favorites / no upcoming
// fixture found / fetch failed — fully graceful.
// ------------------------------------------------------------------
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import type { LeagueGroup, NormMatch } from "@/lib/fotmob";
import { faDigits, jalaliShort, tehranDateKey, tehranTime } from "@/lib/format";
import { useFavorites } from "@/lib/favorites";
import { TeamLogo } from "@/components/remontada/team-logo";
import { cn } from "@/lib/utils";

interface UpcomingFavMatch {
  id: string;
  utcTime: string;
  homeId: number; homeName: string; homeLogo: string;
  awayId: number; awayName: string; awayLogo: string;
  leagueFa: string;
  favSide: "home" | "away";
  dayLabel: string;   // «امروز» / «فردا» / «شنبه ۱۲ آبان» style
}

const MAX_SHOW = 6;

function dayLabelFa(utcTime: string): string {
  try {
    const key = tehranDateKey(utcTime);
    const today = tehranDateKey(new Date().toISOString());
    const tomorrow = tehranDateKey(new Date(Date.now() + 86_400_000).toISOString());
    if (key === today) return "امروز";
    if (key === tomorrow) return "فردا";
    const j = jalaliShort(utcTime);
    return `${j.day} ${j.month}`;
  } catch {
    return "";
  }
}

export function FavoriteFixtures() {
  const favs = useFavorites();
  const [items, setItems] = useState<UpcomingFavMatch[]>([]);
  const [expanded, setExpanded] = useState(false);
  const stoppedRef = useRef(false);

  const favKey = favs.map((f) => f.id).join(",");

  useEffect(() => {
    stoppedRef.current = false;
    const favIds = new Set(favKey.split(",").filter(Boolean).map(Number));
    if (favIds.size === 0) {
      const t = setTimeout(() => setItems([]), 0);
      return () => clearTimeout(t);
    }

    const tick = async () => {
      if (stoppedRef.current || document.visibilityState !== "visible") return;
      try {
        const days = await Promise.allSettled(
          [0, 1, 2].map((o) => fetch(`/api/matches?offset=${o}`, { cache: "no-store" }).then((r) => r.json())),
        );
        if (stoppedRef.current) return;
        const found: UpcomingFavMatch[] = [];
        for (const res of days) {
          if (res.status !== "fulfilled" || !res.value?.ok) continue;
          for (const g of (res.value.groups || []) as LeagueGroup[]) {
            for (const m of (g.matches || []) as NormMatch[]) {
              if (m.started || m.cancelled) continue;
              const favIsHome = favIds.has(m.home.id);
              const favIsAway = favIds.has(m.away.id);
              if (!favIsHome && !favIsAway) continue;
              found.push({
                id: m.id,
                utcTime: m.utcTime,
                homeId: m.home.id, homeName: m.home.fa || m.home.name, homeLogo: m.home.logo,
                awayId: m.away.id, awayName: m.away.fa || m.away.name, awayLogo: m.away.logo,
                leagueFa: g.leagueFa || g.leagueName || "",
                favSide: favIsHome ? "home" : "away",
                dayLabel: dayLabelFa(m.utcTime),
              });
            }
          }
        }
        found.sort((a, b) => (a.utcTime || "").localeCompare(b.utcTime || ""));
        setItems(found.slice(0, 40));
      } catch {
        // network hiccup — keep last state, retry on next tick
      }
    };

    void tick();
    const iv = setInterval(() => void tick(), 5 * 60_000);
    return () => {
      stoppedRef.current = true;
      clearInterval(iv);
    };
  }, [favKey]);

  if (favs.length === 0 || items.length === 0) return null;
  const shown = expanded ? items : items.slice(0, MAX_SHOW);
  const hidden = items.length - shown.length;

  return (
    <section className="rounded-2xl border border-amber-400/25 bg-amber-400/[0.04] overflow-hidden" aria-label="بازی‌های بعدی تیم‌های مورد علاقه">
      <header className="flex items-center gap-2 px-3.5 py-2.5 border-b border-amber-400/20 bg-amber-400/[0.05]">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="1.9" strokeLinejoin="round" className="text-amber-400 shrink-0" aria-hidden>
          <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
        </svg>
        <h2 className="font-black text-[12.5px]">بازی‌های بعدی تیم‌های من</h2>
        <span className="text-[10px] font-bold text-amber-400/90 bg-amber-400/10 border border-amber-400/25 rounded-md px-1.5 py-0.5 tabular-persian">
          {faDigits(items.length)} بازی
        </span>
        <span className="ms-auto text-[10px] text-muted-foreground hidden sm:block">۳ روز آینده · هر ۵ دقیقه</span>
      </header>
      <div className="p-1.5 grid gap-1">
        {shown.map((m) => (
          <Link
            key={m.id}
            href={`/match/${m.id}`}
            prefetch={false}
            className="group grid grid-cols-[54px_1fr_auto_1fr] items-center gap-1.5 sm:gap-2.5 px-2.5 py-2 rounded-xl hover:bg-accent/40 transition-colors"
          >
            {/* day + time */}
            <div className="flex flex-col items-center justify-center text-center leading-tight">
              <span className="text-[10px] font-black text-amber-400/90">{m.dayLabel || "—"}</span>
              <span className="text-[10px] text-muted-foreground tabular-persian">{tehranTime(m.utcTime)}</span>
            </div>
            {/* home */}
            <div className={cn("flex items-center justify-end gap-1.5 min-w-0", m.favSide === "home" ? "font-black" : "font-semibold")}>
              {m.favSide === "home" && (
                <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" className="text-amber-400 shrink-0" aria-hidden>
                  <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
                </svg>
              )}
              <span className={cn("truncate text-[12.5px]", m.favSide === "home" ? "text-foreground" : "text-foreground/85")}>{m.homeName}</span>
              <TeamLogo id={m.homeId} alt="" size={18} />
            </div>
            <span className="text-muted-foreground/50 text-[10px] font-bold px-1">vs</span>
            {/* away */}
            <div className={cn("flex items-center gap-1.5 min-w-0", m.favSide === "away" ? "font-black" : "font-semibold")}>
              <TeamLogo id={m.awayId} alt="" size={18} />
              <span className={cn("truncate text-[12.5px]", m.favSide === "away" ? "text-foreground" : "text-foreground/85")}>{m.awayName}</span>
              {m.favSide === "away" && (
                <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor" className="text-amber-400 shrink-0" aria-hidden>
                  <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />
                </svg>
              )}
            </div>
            {/* league — compact chip after away on wide, under on narrow */}
          </Link>
        ))}
      </div>
      <div className="px-3.5 pb-2 -mt-0.5 flex items-center justify-between gap-2">
        <span className="text-[9.5px] text-muted-foreground/70 truncate">{shown[0]?.leagueFa ? `${shown[0].leagueFa} و سایر رقابت‌ها` : ""}</span>
        {(hidden > 0 || expanded) && items.length > MAX_SHOW && (
          <button
            onClick={() => setExpanded((v) => !v)}
            className="text-[10px] font-black text-amber-400/90 hover:text-amber-300 transition-colors shrink-0 cursor-pointer"
          >
            {expanded ? "نمایش کمتر" : `+${faDigits(hidden)} بازی دیگر`}
          </button>
        )}
      </div>
    </section>
  );
}
