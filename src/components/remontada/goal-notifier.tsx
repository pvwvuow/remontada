"use client";

// ------------------------------------------------------------------
// Remontada — live notifications for favorite teams (client-only)
// ------------------------------------------------------------------
// Opt-in: a small floating chip appears only when the user has favorite
// teams AND notification permission is still "default". After opt-in we
// poll today's matches every 60 s (tab visible only) and diff a snapshot
// of favorite teams' games to fire system notifications for:
//   • every new goal        (icon: scoring team's logo)
//   • match kickoff         (icon: home team's logo)
//   • full-time + result    (icon: winner's logo, home on draw)
// Clicking a notification jumps to the match page.
import { useEffect, useRef, useState } from "react";
import type { LeagueGroup, NormMatch } from "@/lib/fotmob";
import { faDigits } from "@/lib/format";
import { useFavorites } from "@/lib/favorites";

interface SnapEntry {
  h: number | null;
  a: number | null;
  started: boolean;
  finished: boolean;
  match: NormMatch;
}

interface NotifOptions {
  title: string;
  body: string;
  icon?: string;
  tag: string;
  matchId: string;
}

function fireNotification({ title, body, icon, tag, matchId }: NotifOptions) {
  try {
    const n = new Notification(title, {
      body,
      icon: icon || "/icon-192.png",
      tag,
      dir: "rtl",
      lang: "fa",
    });
    n.onclick = () => {
      window.focus();
      window.location.href = `/match/${matchId}`;
    };
  } catch {
    // notification subsystem unavailable — silently ignore
  }
}

function scoreText(m: NormMatch): string {
  return `${m.home.fa || m.home.name} ${faDigits(m.home.score ?? 0)} - ${faDigits(m.away.score ?? 0)} ${m.away.fa || m.away.name}`;
}

export function GoalNotifier() {
  const favs = useFavorites();
  const [permission, setPermission] = useState<"default" | "granted" | "denied" | "unsupported">("default");
  const [dismissed, setDismissed] = useState(false);
  const snapRef = useRef<Map<string, SnapEntry>>(new Map());

  // read permission once on mount (client only)
  useEffect(() => {
    setPermission(typeof window === "undefined" || typeof Notification === "undefined" ? "unsupported" : Notification.permission);
  }, []);

  // polling + state diffing
  useEffect(() => {
    if (permission !== "granted" || favs.length === 0) return;
    let stopped = false;

    const tick = async () => {
      if (stopped || document.visibilityState !== "visible") return;
      try {
        const res = await fetch("/api/matches?offset=0", { cache: "no-store" });
        const json = await res.json();
        if (stopped || !json?.ok) return;
        const favIds = new Set(favs.map((f) => f.id));
        const next = new Map<string, SnapEntry>();
        for (const g of (json.groups || []) as LeagueGroup[]) {
          for (const m of g.matches || []) {
            if (!favIds.has(m.home.id) && !favIds.has(m.away.id)) continue;
            if (m.cancelled) continue;
            // track upcoming, live and finished-today games so kickoff / FT
            // transitions are observable across polling ticks
            next.set(m.id, {
              h: m.home.score,
              a: m.away.score,
              started: m.started,
              finished: m.finished,
              match: m,
            });
          }
        }
        const prev = snapRef.current;
        for (const [id, cur] of next) {
          const p = prev.get(id);
          if (!p) continue; // first sighting = baseline, never notifies
          const m = cur.match;

          // ---- kickoff ----
          if (!p.started && cur.started && !cur.finished) {
            fireNotification({
              title: `شروع بازی: ${m.home.fa || m.home.name} - ${m.away.fa || m.away.name}`,
              body: `${m.leagueFa || m.leagueName} • بازی تیم مورد علاقه‌ی شما آغاز شد`,
              icon: m.home.logo,
              tag: `remontada-kickoff-${id}`,
              matchId: id,
            });
          }

          // ---- goals ----
          const homeGoal = cur.h !== null && (p.h === null || cur.h > p.h);
          const awayGoal = cur.a !== null && (p.a === null || cur.a > p.a);
          const minute = m.minute && /^\d+/.test(m.minute) ? ` در دقیقه ${faDigits(m.minute)}` : "";
          if (homeGoal) {
            fireNotification({
              title: `گل! ${m.home.fa || m.home.name}`,
              body: `${scoreText(m)}${minute}`,
              icon: m.home.logo,
              tag: `remontada-goal-${id}-home-${m.home.score}-${m.away.score}`,
              matchId: id,
            });
          }
          if (awayGoal) {
            fireNotification({
              title: `گل! ${m.away.fa || m.away.name}`,
              body: `${scoreText(m)}${minute}`,
              icon: m.away.logo,
              tag: `remontada-goal-${id}-away-${m.home.score}-${m.away.score}`,
              matchId: id,
            });
          }

          // ---- full time ----
          if (!p.finished && cur.finished && cur.started && cur.h !== null && cur.a !== null) {
            const winner =
              cur.h > cur.a
                ? `برد ${m.home.fa || m.home.name}`
                : cur.a > cur.h
                  ? `برد ${m.away.fa || m.away.name}`
                  : "مساوی";
            fireNotification({
              title: `پایان بازی: ${m.home.fa || m.home.name} ${faDigits(cur.h)} - ${faDigits(cur.a)} ${m.away.fa || m.away.name}`,
              body: `${m.leagueFa || m.leagueName} • ${winner}`,
              icon: cur.h > cur.a ? m.home.logo : cur.a > cur.h ? m.away.logo : m.home.logo,
              tag: `remontada-ft-${id}-${cur.h}-${cur.a}`,
              matchId: id,
            });
          }
        }
        snapRef.current = next;
      } catch {
        // network hiccup — retry on next tick
      }
    };

    void tick(); // baseline immediately
    const iv = setInterval(() => void tick(), 60_000);
    return () => {
      stopped = true;
      clearInterval(iv);
    };
  }, [permission, favs]);

  // ---- opt-in chip ----
  if (permission !== "default" || favs.length === 0 || dismissed) return null;

  const sample = favs.slice(0, 3).map((f) => f.fa).join("، ");

  return (
    <div className="fixed bottom-3 start-3 z-40 max-w-[calc(100vw-24px)] sm:max-w-xs rounded-2xl border border-border/70 bg-popover shadow-2xl p-3.5" role="complementary" aria-label="فعال‌سازی اعلان زنده">
      <div className="flex items-start gap-2.5">
        <div className="w-8 h-8 rounded-xl bg-amber-400/10 border border-amber-400/25 flex items-center justify-center shrink-0">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" className="text-amber-400" aria-hidden>
            <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
            <path d="M13.7 21a2 2 0 0 1-3.4 0" />
          </svg>
        </div>
        <div className="min-w-0">
          <p className="text-[12px] font-black leading-snug">گل‌ها را از دست ندهید!</p>
          <p className="text-[10.5px] text-muted-foreground leading-relaxed mt-0.5">
            شروع و پایان بازی‌ها و هر گلی از تیم‌های مورد علاقه‌ی شما ({sample}{favs.length > 3 ? " و …" : ""}) اعلان می‌گیرید — همراه با لوگوی تیم.
          </p>
          <div className="flex items-center gap-2 mt-2.5">
            <button
              type="button"
              onClick={async () => {
                try {
                  if (typeof Notification !== "undefined") {
                    const p = await Notification.requestPermission();
                    setPermission(p);
                  }
                } catch {
                  setPermission("denied");
                }
              }}
              className="text-[11px] font-black text-primary bg-primary/10 border border-primary/30 rounded-lg px-3 py-1.5 hover:bg-primary/15 transition-colors cursor-pointer"
            >
              فعال‌سازی اعلان‌ها
            </button>
            <button
              type="button"
              onClick={() => setDismissed(true)}
              className="text-[11px] font-bold text-muted-foreground hover:text-foreground transition-colors cursor-pointer"
            >
              بعداً
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
