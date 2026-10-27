"use client";

// ------------------------------------------------------------------
// Remontada — live favorite chip (client-only, cycle 19)
// When a favorite team (remontada:favorites) has a match in progress,
// a red strip with a pulsing live-dot appears directly under the site
// header and links straight to the match page. Polls today's matches
// every 60 s (tab-visible only) — same pattern as goal-notifier.
// Renders nothing when: no favorites / nothing live / fetch failed.
// ------------------------------------------------------------------
import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import type { LeagueGroup, NormMatch } from "@/lib/fotmob";
import { faDigits } from "@/lib/format";
import { useFavorites } from "@/lib/favorites";

interface LiveFavMatch {
  id: string;
  minute?: string;
  myTeam: string;       // favorite side name (fa)
  otherTeam: string;
  homeScore: number | null;
  awayScore: number | null;
}

export function LiveFavoriteChip() {
  const favs = useFavorites();
  const [match, setMatch] = useState<LiveFavMatch | null>(null);
  const [extraCount, setExtraCount] = useState(0);
  const stoppedRef = useRef(false);

  useEffect(() => {
    stoppedRef.current = false;
    if (favs.length === 0) {
      // async tick so we never call setState synchronously inside the effect
      // body (react-hooks/set-state-in-effect, cycle-16 bug pattern)
      const t = setTimeout(() => {
        setMatch(null);
        setExtraCount(0);
      }, 0);
      return () => clearTimeout(t);
    }
    const favIds = new Set(favs.map((f) => f.id));

    const tick = async () => {
      if (stoppedRef.current || document.visibilityState !== "visible") return;
      try {
        const res = await fetch("/api/matches?offset=0", { cache: "no-store" });
        const json = await res.json();
        if (stoppedRef.current || !json?.ok) return;
        const all: LiveFavMatch[] = [];
        for (const g of (json.groups || []) as LeagueGroup[]) {
          for (const m of (g.matches || []) as NormMatch[]) {
            if (!m.live || m.cancelled) continue;
            const favIsHome = favIds.has(m.home.id);
            if (!favIsHome && !favIds.has(m.away.id)) continue;
            all.push({
              id: m.id,
              minute: m.minute,
              myTeam: favIsHome ? m.home.fa || m.home.name : m.away.fa || m.away.name,
              otherTeam: favIsHome ? m.away.fa || m.away.name : m.home.fa || m.home.name,
              homeScore: m.home.score,
              awayScore: m.away.score,
            });
          }
        }
        setMatch(all[0] ?? null);
        setExtraCount(Math.max(0, all.length - 1));
      } catch {
        // network hiccup — keep last state, retry on next tick
      }
    };

    void tick();
    const iv = setInterval(() => void tick(), 60_000);
    return () => {
      stoppedRef.current = true;
      clearInterval(iv);
    };
  }, [favs]);

  if (!match) return null;

  return (
    <div className="border-t border-red-500/25 bg-red-500/[0.08] backdrop-blur-md">
      <div className="max-w-5xl mx-auto px-3 sm:px-5 py-1.5 flex items-center justify-center">
        <Link
          href={`/match/${match.id}`}
          prefetch={false}
          className="group inline-flex items-center gap-2 rounded-full border border-red-500/35 bg-red-500/[0.12] hover:bg-red-500/20 transition-colors ps-2.5 pe-3 py-1 text-[11px] font-black max-w-full"
          aria-label={`بازی زنده ${match.myTeam} — مشاهده صفحه بازی`}
        >
          <span className="flex items-center gap-1.5 shrink-0 text-red-400">
            <span className="live-dot live-dot-glow inline-block w-1.5 h-1.5 rounded-full bg-red-500" aria-hidden />
            زنده
          </span>
          <span className="flex items-center gap-1.5 truncate">
            <span className="text-foreground/90 truncate">{match.myTeam}</span>
            <span className="text-red-300 tabular-persian" dir="ltr">
              {match.homeScore !== null && match.awayScore !== null
                ? `${faDigits(match.homeScore)} - ${faDigits(match.awayScore)}`
                : "—"}
            </span>
            <span className="text-foreground/90 truncate">{match.otherTeam}</span>
          </span>
          {match.minute && /^\d+/.test(match.minute) && (
            <span className="text-red-300/90 tabular-persian shrink-0">
              {faDigits(match.minute)}{/[′’']/.test(match.minute) ? "" : "′"}
            </span>
          )}
          {extraCount > 0 && (
            <span className="text-[9.5px] font-bold text-red-300/80 shrink-0 tabular-persian">
              +{faDigits(extraCount)} بازی دیگر
            </span>
          )}
          <span className="text-red-400/80 group-hover:text-red-300 transition-colors shrink-0" aria-hidden>←</span>
        </Link>
      </div>
    </div>
  );
}
