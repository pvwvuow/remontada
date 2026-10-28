// ------------------------------------------------------------------
// Remontada — penalty-shootout extraction (fix cycle-45)
// ------------------------------------------------------------------
// FotMob marks shootout attempts with isPenaltyShootoutEvent inside the
// matchFacts events stream. The match route used to drop them entirely
// (`if (e.isPenaltyShootoutEvent) continue;`), which made the decisive
// phase of knockout matches invisible: no score, no attempts, nothing.
// This pure helper turns raw shootout events into a normalized structure.
// It lives in lib (not inside the route module) so a plain bun script can
// unit-test it without the Next.js runtime.
//
// cycle-106: attempts gain playerFa — the honest Persian display name
// (curated map hit, else the raw upstream English name), same contract as
// the cycle-104/105 name map extensions.

import { playerFa } from "./player-names-fa";

export interface ShootoutAttempt {
  side: "home" | "away" | "neutral";
  player?: string;
  playerFa?: string;
  scored: boolean;
  noteFa: string;
}

export interface Shootout {
  home: number;
  away: number;
  attempts: ShootoutAttempt[];
}

// Persian label per unsuccessful FotMob shootout event type
const MISS_FA: Record<string, string> = {
  MissedPenalty: "از دست رفت",
  Miss: "به بیرون",
  AttemptSaved: "مهار شد",
  Save: "مهار شد",
  Post: "تیرک",
};

interface RawShootoutEvent {
  type?: unknown;
  isHome?: unknown;
  player?: { name?: string | null } | null;
}

export function buildShootout(rawEvents: unknown[]): Shootout | null {
  const attempts: ShootoutAttempt[] = [];
  let home = 0;
  let away = 0;
  for (const e of rawEvents) {
    if (!e || typeof e !== "object") continue;
    const ev = e as RawShootoutEvent;
    const type = String(ev.type ?? "");
    const side: ShootoutAttempt["side"] =
      ev.isHome === true ? "home" : ev.isHome === false ? "away" : "neutral";
    const scored = type === "Goal";
    if (scored) {
      if (side === "home") home += 1;
      else if (side === "away") away += 1;
    }
    const playerName = ev.player?.name || undefined;
    attempts.push({
      side,
      player: playerName,
      ...(playerName ? { playerFa: playerFa(playerName) } : {}),
      scored,
      noteFa: scored ? "گل" : MISS_FA[type] || "ناموفق",
    });
  }
  if (attempts.length === 0) return null;
  return { home, away, attempts };
}
