"use client";

// ------------------------------------------------------------------
// Remontada — league «تیم هفته» (TOTW, cycle-360). Lazy client section:
// fetches /api/league-totw on mount (and on round change), hides itself
// entirely for leagues/seasons without the surface (honest absence — the
// upstream null body). The 11 nodes sit on a glass pitch at the upstream
// verticalLayout cell geometry (x/y = cell center, w = cell width); every
// node links its /player profile (the 354 link-polish convention). Round
// chips follow the 355 chip-row geometry; «تیم فصل» marks the TOTS round.
// ------------------------------------------------------------------
import { useEffect, useState } from "react";
import Link from "next/link";
import { fotmobTeamLogo } from "@/lib/leagues";
import { faDecimal, faDigits } from "@/lib/format";
import { cn } from "@/lib/utils";

interface TotwPlayer {
  playerId: number;
  fa: string;
  latin: string;
  teamId: number;
  teamFa: string;
  rating: string;
  isTop: boolean;
  matchId: number | null;
  x: number;
  y: number;
  w: number;
}
interface TotwData {
  rounds: { roundId: string; completed: boolean }[];
  last: string | null;
  round: string;
  players: TotwPlayer[];
}

/** «هفتهٔ ۸» / «تیم فصل» — TOTS is the final entry of historical seasons. */
function roundLabel(id: string): string {
  return id === "TOTS" ? "تیم فصل" : `هفتهٔ ${faDigits(id)}`;
}

export function LeagueTotwSection({ leagueKey, season }: { leagueKey: string; season: string | null }) {
  const [data, setData] = useState<TotwData | null>(null);
  const [dead, setDead] = useState(false);
  // null = the upstream default (its own «last» round); a chip click pins one.
  // The round-switch dim is DERIVED (pinned round ≠ loaded round) — no setState
  // in the effect body (the react-hooks/set-state-in-effect rule, the house
  // load()-callback pattern).
  const [round, setRound] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    const sp = season ? `&season=${encodeURIComponent(season)}` : "";
    const rp = round ? `&round=${encodeURIComponent(round)}` : "";
    fetch(`/api/league-totw?league=${leagueKey}${sp}${rp}`, { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (!alive) return;
        if (j?.ok && Array.isArray(j.totw?.players) && j.totw.players.length > 0) {
          setData(j.totw as TotwData);
        } else {
          // leagues without TOTW / seasons without the feed → hidden forever
          setDead(true);
          setData(null);
        }
      })
      .catch(() => {
        if (alive) setDead(true);
      });
    return () => {
      alive = false;
    };
  }, [leagueKey, season, round]);

  // the team-squad convention: a lazy section stays out of the layout until
  // it has real content — no skeleton, no invented rows
  if (dead || !data) return null;
  // derived switch dim: a pinned round still loading shows the previous pitch
  // at half opacity (the tab-content loading convention) instead of jumping
  const switching = round !== null && data.round !== round;

  return (
    <section className="glass-card p-4" data-testid="league-totw" aria-label="تیم هفته">
      <div className="flex items-center justify-between gap-2 mb-2">
        <h3 className="text-[11px] font-black text-[#b6cce3]">تیم هفته</h3>
        <div className="flex items-center gap-1.5 min-w-0">
          {season && (
            <span className="text-[9.5px] font-bold text-muted-foreground tabular-persian shrink-0">
              فصل {faDigits(season)}
            </span>
          )}
          <span className="text-[9.5px] font-black text-steel shrink-0">{roundLabel(data.round)}</span>
        </div>
      </div>

      {/* round chips — the 355 chip-row geometry; the active round is live */}
      {data.rounds.length > 1 && (
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1.5 mb-2" data-testid="league-totw-rounds" aria-label="انتخاب هفتهٔ تیم هفته">
          {data.rounds.map((r) => (
            <button
              key={r.roundId}
              type="button"
              onClick={() => setRound(r.roundId)}
              aria-pressed={data.round === r.roundId}
              className={cn(
                "shrink-0 rounded-md border px-2 py-0.5 text-[10px] font-black transition-colors cursor-pointer",
                data.round === r.roundId
                  ? "border-chart-3/40 bg-chart-3/10 text-chart-3"
                  : "border-border bg-white/[0.03] text-muted-foreground hover:text-foreground"
              )}
            >
              {roundLabel(r.roundId)}
            </button>
          ))}
        </div>
      )}

      {/* glass pitch — same visual language as LineupsPitch; the nodes are
          absolutely positioned by the upstream cell geometry (x/y center,
          w width, height ≈ 0.2 of the pitch for every row) */}
      <div
        className={cn("relative rounded-2xl border border-glass-border-soft bg-white/[0.02] overflow-hidden transition-opacity", switching && "opacity-50")}
        style={{ aspectRatio: "68 / 105" }}
        aria-label={`تیم هفته — ${roundLabel(data.round)}`}
      >
        <div className="absolute inset-y-0 left-1/2 w-px bg-white/[0.05]" aria-hidden />
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22%] aspect-square rounded-full border border-white/[0.05]" aria-hidden />
        {data.players.map((p) => (
          <Link
            key={p.playerId}
            href={`/player/${p.playerId}`}
            prefetch={false}
            data-testid="league-totw-player"
            title={`${p.fa || p.latin}${p.teamFa ? ` — ${p.teamFa}` : ""}${p.rating ? ` — امتیاز ${faDecimal(p.rating)}` : ""}`}
            className="absolute flex flex-col items-center justify-center gap-0.5 group"
            style={{
              left: `${((p.x - p.w / 2) * 100).toFixed(2)}%`,
              top: `${((p.y - 0.1) * 100).toFixed(2)}%`,
              width: `${(p.w * 100).toFixed(2)}%`,
              height: "20%",
            }}
          >
            <img
              src={fotmobTeamLogo(p.teamId)}
              alt=""
              width={18}
              height={18}
              loading="lazy"
              className="w-[18px] h-[18px] object-contain shrink-0"
              onError={(ev) => {
                ev.currentTarget.style.visibility = "hidden";
              }}
            />
            <span className="max-w-full truncate px-0.5 text-center text-[9px] font-bold leading-tight text-[#dfedff] group-hover:text-sky-soft transition-colors">
              {p.fa || p.latin}
            </span>
            {p.rating && (
              <span
                className={cn(
                  "rounded-md border px-1 text-[9px] font-black tabular-persian leading-4",
                  p.isTop ? "border-gold/40 bg-gold/10 text-gold" : "border-border bg-white/[0.06] text-chart-3"
                )}
              >
                {faDecimal(p.rating)}
              </span>
            )}
          </Link>
        ))}
      </div>

      <p className="text-[9px] text-muted-foreground pt-1.5">
        ۱۱ بازیکن برتر هفته طبق دادهٔ FotMob — هر نام به پروفایل بازیکن لینک است.
      </p>
    </section>
  );
}
