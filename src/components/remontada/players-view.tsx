"use client";

// ------------------------------------------------------------------
// Remontada — «بازیکنان» hub. Two modes:
//   «ستاره‌ها» (cycle-104..): photo-centric grid of the star players
//   across the 7 covered leagues, built on the same live /api/topscorers
//   merge the گلزنان page uses (scorers + assists).
//   «همهٔ تیم‌ها» (cycle-134, user request: «بازیکنان کل تیما رو باید
//   داشته باشیم نه فقط گلزن و پاس گلرها»): league → team → FULL squad
//   browser. Standings supply every team of the league, /api/team-squad
//   (the cycle-70 feed the team page already uses) supplies every player
//   grouped by position with shirt/age/rating/goals/assists and the
//   cycle-130 photo pipeline — now fed the probed high-res sources
//   (150/192px, see player-photo.tsx cycle-134 ladder).
// Deep links: ?league=<key>&team=<id> seed the teams mode once on mount
// (strict validation, silent strip — the cycle-132 selector contract);
// every interaction mirrors the state back into the URL.
// Cycle 182: the stars mode joins the season contract — the LAST
// /api/topscorers consumer still stuck on the current season. The merge
// payload already carries selectedSeason + allSeasons (cycle-132 fields,
// live-probed: the 2023/2024 race serves 380 scorers with Kane 36g top +
// 10 assists, and 2013/2014 is an honest 200-with-zero), so the proven
// cycle-55/99/132/180 selector rides the hub byte-style: deep-link
// ?season= seeding (ONE fetch per deep link, strict SEASON_PARAM_RE —
// anything else loads the current race), honesty snap (the payload's
// selectedSeason marker is the truth anchor — on disagreement snap back
// to the current race and strip the stale param), URL replaceState sync,
// options from the payload itself and the season-aware honest empty
// state. Squads («همهٔ تیم‌ها») stay current by nature — no season there.
// ------------------------------------------------------------------
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import type { GlobalScorer, GlobalAssist, GlobalScorersData } from "@/lib/fotmob";
import { SEASON_PARAM_RE } from "@/lib/season";
import { LEAGUES } from "@/lib/leagues";
import { PLAYER_NAME_FA } from "@/lib/player-names-fa";
import { EmptyState } from "@/components/remontada/empty-state";
import { TeamLogo } from "@/components/remontada/team-logo";
import { PlayerPhoto } from "@/components/remontada/player-photo";
import { faDigits, timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";

type Metric = "goals" | "assists";
const METRIC_FA: Record<Metric, string> = { goals: "گل", assists: "پاس گل" };

type Mode = "stars" | "teams";
const MODE_FA: Record<Mode, string> = { stars: "ستاره‌ها", teams: "همهٔ تیم‌ها" };

// cycle-182: "2024/2025" → «۲۰۲۴/۲۵» — the same label the league page and
// the گلزنان selectors use. Local mirror on purpose (the cycle-132 lesson:
// the canonical helper lives in a client component, importing across views
// would couple two client bundles for a 3-line formatter).
function faSeasonShort(s: string): string {
  const m = /^(\d{4})\/(\d{4})$/.exec(s);
  return m ? faDigits(`${m[1]}/${m[2].slice(2)}`) : faDigits(s);
}

// unified card row — scorers and assists flatten into the same shape
interface Row {
  key: string;
  playerId?: number;
  name: string;
  nameFa?: string;
  team: string;
  teamId: number;
  leagueFa: string;
  value: number;        // active metric value (goals or assists)
  extraAssists?: number; // scorers only
  gPlusA?: number;       // scorers only
  rating?: number;       // scorers only
}

function toRows(metric: Metric, scorers: GlobalScorer[], assists: GlobalAssist[]): Row[] {
  if (metric === "goals") {
    return scorers
      .filter((s) => s.goals > 0)
      .map((s) => ({
        key: `${s.leagueKey}-${s.playerId ?? s.name}`,
        playerId: s.playerId,
        name: s.name,
        nameFa: s.nameFa,
        team: s.team,
        teamId: s.teamId,
        leagueFa: s.leagueFa,
        value: s.goals,
        extraAssists: s.assists ?? undefined,
        gPlusA: s.gPlusA ?? undefined,
        rating: s.rating ?? undefined,
      }));
  }
  return assists
    .filter((a) => a.value > 0)
    .map((a) => ({
      key: `${a.leagueKey}-${a.playerId ?? a.name}`,
      playerId: a.playerId,
      name: a.name,
      nameFa: a.nameFa,
      team: a.team,
      teamId: a.teamId,
      leagueFa: a.leagueFa,
      value: a.value,
    }));
}

// ---------- ui-cycle-20: loading states join the site's skeleton language ----------
// The three plain «در حال دریافت…» text boxes predate the shared skeleton
// pattern (glass blocks + animate-pulse + aria-busy, shaped like the real
// content) used by topscorers / league-scorers / standings / matches / news.
// Same visual contract now — truthful shapes, no layout jump on resolve.

function StarsSkeleton() {
  return (
    <div className="flex flex-col gap-2" aria-busy="true" aria-label="در حال بارگذاری بازیکنان">
      <div className="grid grid-cols-3 gap-2">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="glass-popover rounded-2xl p-3 flex flex-col items-center gap-2">
            <div className="w-[88px] h-[88px] rounded-2xl bg-muted animate-pulse" />
            <div className="h-3 rounded bg-muted animate-pulse w-3/4" />
            <div className="h-2.5 rounded bg-muted animate-pulse w-1/2" />
            <div className="flex gap-1">
              <div className="w-9 h-4 rounded-md bg-muted animate-pulse" />
              <div className="w-9 h-4 rounded-md bg-muted animate-pulse" />
            </div>
          </div>
        ))}
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="glass-popover rounded-2xl p-3 flex flex-col items-center gap-2">
            <div className="w-[60px] h-[60px] rounded-2xl bg-muted animate-pulse" />
            <div className="h-3 rounded bg-muted animate-pulse w-3/4" />
            <div className="h-2.5 rounded bg-muted animate-pulse w-1/2" />
            <div className="flex gap-1">
              <div className="w-8 h-4 rounded-md bg-muted animate-pulse" />
              <div className="w-8 h-4 rounded-md bg-muted animate-pulse" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function TeamsSkeleton() {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2" aria-busy="true" aria-label="در حال بارگذاری تیم‌ها">
      {Array.from({ length: 12 }).map((_, i) => (
        <div key={i} className="glass-popover rounded-2xl px-3 py-2.5 flex items-center gap-2">
          <div className="w-[22px] h-[22px] rounded bg-muted animate-pulse shrink-0" />
          <div className="h-3 rounded bg-muted animate-pulse flex-1" style={{ maxWidth: `${55 + ((i * 17) % 35)}%` }} />
        </div>
      ))}
    </div>
  );
}

function SquadSkeleton() {
  return (
    <div className="flex flex-col gap-3" aria-busy="true" aria-label="در حال بارگذاری ترکیب تیم">
      <div className="glass-popover rounded-2xl p-3 flex items-center gap-2.5">
        <div className="w-[30px] h-[30px] rounded-lg bg-muted animate-pulse shrink-0" />
        <div className="flex flex-col gap-1.5">
          <div className="h-3.5 rounded bg-muted animate-pulse w-32" />
          <div className="h-2.5 rounded bg-muted animate-pulse w-24" />
        </div>
      </div>
      <section className="flex flex-col gap-2">
        <div className="h-3.5 w-20 rounded bg-muted animate-pulse" />
        <div className="grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-6 gap-2">
          {Array.from({ length: 12 }).map((_, i) => (
            <div key={i} className="glass-popover rounded-2xl p-3 flex flex-col items-center gap-2">
              <div className="w-16 h-16 rounded-2xl bg-muted animate-pulse" />
              <div className="h-3 rounded bg-muted animate-pulse w-3/4" />
              <div className="h-2.5 rounded bg-muted animate-pulse w-1/3" />
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

function PlayerCard({ p, rank, metric, big = false }: { p: Row; rank: number; metric: Metric; big?: boolean }) {
  const name = p.nameFa || p.name;
  const chips: { label: string; value: string; cls: string; title: string }[] = [
    { label: METRIC_FA[metric], value: faDigits(p.value), cls: "bg-primary/10 border-primary/25 text-primary", title: `${METRIC_FA[metric]} فصل` },
  ];
  if (metric === "goals" && p.extraAssists) {
    chips.push({ label: "پاس گل", value: faDigits(p.extraAssists), cls: "bg-chart-2/10 border-chart-2/25 text-chart-2", title: "پاس گل فصل" });
  }
  if (metric === "goals" && p.gPlusA != null && p.gPlusA > 0) {
    chips.push({ label: "گل+پاس", value: faDigits(p.gPlusA), cls: "bg-muted border-border text-muted-foreground", title: "مجموع گل و پاس گل" });
  }
  if (p.rating != null && p.rating > 0) {
    chips.push({ label: "امتیاز", value: faDigits(p.rating.toFixed(1)), cls: "bg-gold/10 border-gold/25 text-gold", title: "میانگین امتیاز فصل" });
  }

  const inner = (
    <>
      <span className="absolute top-2 right-2 w-6 h-6 rounded-lg bg-[#a9cdf611] text-[#dceafd] flex items-center justify-center text-[10px] font-bold tabular-persian z-10">
        {faDigits(rank)}
      </span>
      <div className="flex flex-col items-center gap-2 pt-2 w-full min-w-0">
        <PlayerPhoto id={p.playerId} name={name} size={big ? 88 : 60} rounded="rounded-2xl" />
        <div className="min-w-0 text-center w-full">
          <p className="font-black text-[12.5px] truncate text-[#eef5fd]" dir="auto" title={p.nameFa && p.nameFa !== p.name ? p.name : undefined}>
            {name}
          </p>
          <p className="text-[9.5px] text-steel/80 truncate mt-0.5 flex items-center justify-center gap-1" title={`${p.team} — ${p.leagueFa}`}>
            <TeamLogo id={p.teamId} alt="" size={11} />
            <span className="truncate">{p.team}</span>
          </p>
        </div>
        <div className="flex items-center gap-1 flex-wrap justify-center">
          {chips.map((c) => (
            <span key={c.label} title={c.title} className={cn("shrink-0 rounded-md border px-1.5 py-px text-[9px] font-bold tabular-persian", c.cls)}>
              {c.label} {c.value}
            </span>
          ))}
        </div>
      </div>
    </>
  );
  const cls = cn(
    "glass-popover relative rounded-2xl p-3 flex flex-col items-center gap-2",
    p.playerId ? "glass-row-hover" : "opacity-90"
  );
  return p.playerId ? (
    <Link href={`/player/${p.playerId}`} prefetch={false} className={cls} title={`پروفایل ${name}`}>
      {inner}
    </Link>
  ) : (
    <div className={cls}>{inner}</div>
  );
}

// ------------------------------------------------------------------
// cycle-134 — squads («همهٔ تیم‌ها» mode)
// ------------------------------------------------------------------
// client mirror of /api/team-squad/[id] (getTeamSquad contract)
interface SquadPlayer {
  id: number;
  name: string;
  shirt?: number;
  age?: number;
  nationality?: string;
  rating?: number;
  goals?: number;
  assists?: number;
  injured: boolean;
  height?: number;
}
interface SquadGroup {
  key: "keepers" | "defenders" | "midfielders" | "attackers";
  titleFa: string;
  players: SquadPlayer[];
}
interface SquadData {
  teamName?: string;
  coach: { id: number; name: string; age?: number; nationality?: string } | null;
  groups: SquadGroup[];
}
interface TeamRow {
  teamId: number;
  name: string;
  fa: string;
}

// cycle-132 lesson: the canonical playerFa() lives in the server-only fotmob
// graph — importing it here would drag the fetch/db module into the client
// bundle. This tiny local lookup mirrors the SAME curated map instead; every
// unmapped name falls back to the honest raw upstream English name.
const playerFaLocal = (n: string) => PLAYER_NAME_FA[n.toLowerCase()] ?? n;

function SquadPlayerCard({ p }: { p: SquadPlayer }) {
  const name = playerFaLocal(p.name);
  const chips: { label: string; value: string; cls: string; title: string }[] = [];
  if (p.shirt != null) {
    chips.push({ label: "#", value: faDigits(p.shirt), cls: "bg-muted border-border text-muted-foreground", title: "شماره پیراهن" });
  }
  if (p.age != null) {
    chips.push({ label: "سن", value: faDigits(p.age), cls: "bg-muted border-border text-muted-foreground", title: "سن" });
  }
  if (p.rating != null && p.rating > 0) {
    chips.push({ label: "امتیاز", value: faDigits(p.rating.toFixed(1)), cls: "bg-gold/10 border-gold/25 text-gold", title: "میانگین امتیاز فصل" });
  }
  if (p.goals) {
    chips.push({ label: "گل", value: faDigits(p.goals), cls: "bg-primary/10 border-primary/25 text-primary", title: "گل فصل" });
  }
  if (p.assists) {
    chips.push({ label: "پاس گل", value: faDigits(p.assists), cls: "bg-chart-2/10 border-chart-2/25 text-chart-2", title: "پاس گل فصل" });
  }
  return (
    <Link
      href={`/player/${p.id}`}
      prefetch={false}
      className="glass-popover glass-row-hover relative rounded-2xl p-3 flex flex-col items-center gap-2"
      title={`پروفایل ${name}`}
    >
      <div className="flex flex-col items-center gap-2 pt-1 w-full min-w-0">
        <div className="relative">
          {/* auto ladder: 64px render → 150px source (crisp @2×), see player-photo.tsx */}
          <PlayerPhoto id={p.id} name={name} size={64} rounded="rounded-2xl" />
          {p.injured && (
            /* ui-cycle-18: data floor 9px — status flags carry meaning, never 8px */
            <span className="absolute -bottom-1.5 left-1/2 -translate-x-1/2 rounded-md border border-rose-400/30 bg-rose-500/20 px-1.5 py-px text-[9px] font-black text-rose-300 whitespace-nowrap">
              مصدوم
            </span>
          )}
        </div>
        <div className="min-w-0 text-center w-full">
          <p className="font-black text-[12px] truncate text-[#eef5fd]" dir="auto" title={name !== p.name ? p.name : undefined}>
            {name}
          </p>
          <p className="text-[9px] text-steel/80 truncate mt-0.5" dir="auto">
            {p.nationality || "—"}
          </p>
        </div>
        <div className="flex items-center gap-1 flex-wrap justify-center">
          {chips.map((c) => (
            <span key={c.label} title={c.title} className={cn("shrink-0 rounded-md border px-1.5 py-px text-[9px] font-bold tabular-persian", c.cls)}>
              {c.label} {c.value}
            </span>
          ))}
        </div>
      </div>
    </Link>
  );
}

export function PlayersView() {
  // ---- stars mode state (cycle-104.. contract; season joins cycle-182) ----
  const [data, setData] = useState<GlobalScorersData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [metric, setMetric] = useState<Metric>("goals");
  // cycle-182: selected historical season — null = current race
  const [season, setSeason] = useState<string | null>(null);
  // cycle-182: deep-link seeding gate (the cycle-99/132 pattern) — the URL
  // is read exactly once so a shared /players?season=2023/2024 link performs
  // ONE fetch with the right season
  const [seasonSeeded, setSeasonSeeded] = useState(false);
  const [starsLoading, setStarsLoading] = useState(true);

  // ---- mode + navigation state ----
  // cycle-134: ONE atom carries the hub navigation (seeded + mode + league +
  // team) so the mount seed stays a single converging setState (second run
  // early-returns on the seeded guard) — the proven one-shot URL contract of
  // topscorers cycle-132 / league-view cycle-99
  interface HubState {
    seeded: boolean;
    mode: Mode;
    league: string;
    team: number | null;
  }
  const [hub, setHub] = useState<HubState>({ seeded: false, mode: "stars", league: "pl", team: null });
  const mode = hub.mode;
  const leagueKey = hub.league;
  const teamId = hub.team;
  // keyed-state pattern (no synchronous setState in effect bodies — the
  // react-hooks/set-state-in-effect rule): each fetch result carries the
  // request key it belongs to and the render derives the live one, so a
  // league/team switch shows loading instead of the previous selection
  const [teamsState, setTeamsState] = useState<{ for: string; rows: TeamRow[] } | null>(null);
  const [teamsErrState, setTeamsErrState] = useState<{ for: string; message: string } | null>(null);
  const [squadState, setSquadState] = useState<{ for: number; squad: SquadData } | null>(null);
  const [squadErrState, setSquadErrState] = useState<{ for: number; message: string } | null>(null);

  const teams = teamsState?.for === leagueKey ? teamsState.rows : null;
  const teamsErr = teamsErrState?.for === leagueKey ? teamsErrState.message : null;
  const squad = teamId != null && squadState?.for === teamId ? squadState.squad : null;
  const squadErr = teamId != null && squadErrState?.for === teamId ? squadErrState.message : null;

  // cycle-182: read the deep-linked season once on mount — strict
  // SEASON_PARAM_RE shape; anything else is ignored and the current race loads
  useEffect(() => {
    if (seasonSeeded) return;
    setSeasonSeeded(true);
    try {
      const raw = new URLSearchParams(window.location.search).get("season");
      if (raw && SEASON_PARAM_RE.test(raw)) setSeason(raw);
    } catch { /* no window — ignore */ }
  }, [seasonSeeded]);

  // stars feed — the live topscorers merge (the cycle-104.. contract;
  // mode-independent: the stars tab is always warm when opened).
  // cycle-182: waits for the URL seed pass (one fetch per deep link) and
  // threads the selected season into the merge; the payload's selectedSeason
  // marker is the honesty anchor — upstream serving the CURRENT race for a
  // well-formed season it does not offer snaps the selector back and strips
  // the stale param (the cycle-99/132 snap, byte-style).
  useEffect(() => {
    if (!seasonSeeded) return;
    let alive = true;
    (async () => {
      try {
        const sp = season ? `?season=${encodeURIComponent(season)}` : "";
        const res = await fetch(`/api/topscorers${sp}`, { cache: "no-store" });
        const j = await res.json();
        if (!alive) return;
        if (j?.ok && Array.isArray(j.scorers)) {
          setData(j as GlobalScorersData);
          setError(null);
          const sel = (j as GlobalScorersData).selectedSeason;
          if (season && sel && sel !== season) {
            setSeason(null);
            try {
              const usp = new URLSearchParams(window.location.search);
              usp.delete("season");
              const qs = usp.toString();
              window.history.replaceState(null, "", `${window.location.pathname}${qs ? `?${qs}` : ""}`);
            } catch { /* ignore */ }
          }
        } else setError("داده‌ای برای نمایش نیست.");
      } catch (err) {
        if (alive) {
          const msg = err instanceof Error ? err.message : "";
          setError(msg ? `خطا در دریافت بازیکنان (${msg})` : "خطا در دریافت بازیکنان");
        }
      } finally {
        if (alive) setStarsLoading(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, [season, seasonSeeded]);

  useEffect(() => {
    // one-shot ?league=<key>&team=<id> seeding (cycle-132 contract: the URL
    // is read exactly once) — strict shape, invalid values are ignored and
    // the first interaction rewrites the URL honestly. The setState here is
    // the sanctioned one-shot "sync with an external system on mount" case:
    // it converges immediately (the guard makes the second run a no-op), so
    // the cascading-render heuristic does not apply.
    if (hub.seeded) return;
    // exactly ONE setHub regardless of the URL outcome (the rule reports
    // every synchronous call, not just the first)
    let seededHub: HubState = { seeded: true, mode: hub.mode, league: hub.league, team: hub.team };
    try {
      const sp = new URLSearchParams(window.location.search);
      const l = sp.get("league");
      const t = sp.get("team");
      const lOk = l && LEAGUES.some((x) => x.key === l) ? l : null;
      const tOk = t && /^\d{1,10}$/.test(t) ? Number(t) : null;
      if (lOk || tOk) {
        seededHub = { seeded: true, mode: "teams", league: lOk || hub.league, team: tOk };
      }
    } catch {
      // no window — defaults already in seededHub
    }
    // one-shot converging URL seed (see comment above) — the cycle-182
    // season-seed effect above proved this shape passes the
    // set-state-in-effect rule as-is, so the old disable directive is gone
    setHub(seededHub);
  }, [hub]);

  const syncUrl = (m: Mode, l: string, t: number | null) => {
    if (typeof window === "undefined") return;
    if (m !== "teams") {
      // cycle-182: the stars mode keeps its season in a shareable URL
      const qs = season ? `?season=${encodeURIComponent(season)}` : "";
      history.replaceState(null, "", `/players${qs}`);
      return;
    }
    const p = new URLSearchParams();
    p.set("league", l);
    if (t) p.set("team", String(t));
    history.replaceState(null, "", `/players?${p.toString()}`);
  };

  const applyMode = (m: Mode) => {
    setHub((h) => ({ ...h, mode: m }));
    syncUrl(m, leagueKey, teamId);
  };
  const applyLeague = (k: string) => {
    setHub((h) => ({ ...h, league: k, team: null })); // keyed derivation drops the old squad view automatically
    syncUrl("teams", k, null);
  };
  const applyTeam = (id: number) => {
    setHub((h) => ({ ...h, team: id }));
    syncUrl("teams", leagueKey, id);
  };

  // standings feed = the honest full team list of the league (same endpoint
  // the table page uses; persiangulf keeps its designed empty state)
  useEffect(() => {
    if (!hub.seeded || mode !== "teams") return;
    let alive = true;
    const l = leagueKey;
    fetch(`/api/standings?league=${encodeURIComponent(l)}`, { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`))))
      .then((j) => {
        if (!alive) return;
        const rows = j?.ok && Array.isArray(j.rows) ? j.rows : [];
        setTeamsState({
          for: l,
          rows: rows.map((r: { teamId: number; name: string; fa?: string }) => ({
            teamId: r.teamId,
            name: r.name,
            fa: r.fa || "",
          })),
        });
        setTeamsErrState(rows.length === 0 ? { for: l, message: "جدول این لیگ در دسترس نیست." } : null);
      })
      .catch((e) => {
        if (!alive) return;
        setTeamsErrState({ for: l, message: e?.message ? `خطا در دریافت تیم‌ها (${e.message})` : "خطا در دریافت تیم‌ها" });
      });
    return () => {
      alive = false;
    };
  }, [hub, mode, leagueKey]);

  // full squad of the selected team (lazily fetched, cached upstream)
  useEffect(() => {
    if (!hub.seeded || mode !== "teams" || teamId == null) return;
    let alive = true;
    const t = teamId;
    fetch(`/api/team-squad/${t}`, { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`))))
      .then((j) => {
        if (!alive) return;
        const s = j?.squad as SquadData | null;
        if (j?.ok && s && Array.isArray(s.groups) && s.groups.length > 0) setSquadState({ for: t, squad: s });
        else setSquadErrState({ for: t, message: "اسکوادی برای این تیم ثبت نشده است." });
      })
      .catch((e) => {
        if (!alive) return;
        setSquadErrState({ for: t, message: e?.message ? `خطا در دریافت ترکیب تیم (${e.message})` : "خطا در دریافت ترکیب تیم" });
      });
    return () => {
      alive = false;
    };
  }, [hub, mode, teamId]);

  const list: Row[] = useMemo(() => {
    if (!data) return [];
    return toRows(metric, data.scorers ?? [], data.assists ?? []);
  }, [data, metric]);

  const selectedTeam = teams?.find((t) => t.teamId === teamId) ?? null;
  const totalPlayers = squad ? squad.groups.reduce((a, g) => a + g.players.length, 0) : 0;
  const squadLabel = selectedTeam?.fa || selectedTeam?.name || squad?.teamName || null;

  // cycle-182: season selector contract — options come from the merge's own
  // allSeasons (the cycle-132 fields), so a merge without season metadata
  // simply hides the control. shownSeason follows the payload's selectedSeason
  // marker, exactly like the گلزنان page. A deep-linked season upstream really
  // serves can sit outside the payload's allSeasons window — it is APPENDED so
  // the selector never contradicts the data on screen (the cycle-99 invariant);
  // truly unoffered seasons were already snapped back in the fetch effect.
  const allSeasons = data?.allSeasons || [];
  const shownSeason = data?.selectedSeason || "";
  const seasonOptions =
    season && data?.selectedSeason === season && !allSeasons.includes(season)
      ? [...allSeasons, season]
      : allSeasons;
  const applySeason = (s: string | null) => {
    setSeason(s);
    try {
      const usp = new URLSearchParams(window.location.search);
      if (s) usp.set("season", s);
      else usp.delete("season");
      const qs = usp.toString();
      window.history.replaceState(null, "", `${window.location.pathname}${qs ? `?${qs}` : ""}`);
    } catch { /* ignore */ }
  };

  const tabCls = (active: boolean) =>
    cn(
      "rounded-xl border px-3 py-1.5 text-[11.5px] font-black transition-all duration-200 active:scale-95",
      active
        ? "text-primary bg-primary/10 border-primary/30 shadow-[0_0_16px_oklch(0.7_0.1_300/0.28)]"
        : "text-muted-foreground border-border hover:text-foreground"
    );

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-end justify-between gap-2 flex-wrap">
        <div>
          <h1 className="text-lg font-black">بازیکنان</h1>
          <p className="text-[10.5px] text-steel mt-0.5">
            {mode === "stars"
              ? season && shownSeason
                ? `ستاره‌های فصل ${faSeasonShort(shownSeason)} — بیست لیگ و جام برتر`
                : "ستاره‌های بیست لیگ و جام برتر با عکس و پروفایل کامل"
              : "اسکواد کامل همهٔ تیم‌ها — انتخاب لیگ و تیم"}
          </p>
        </div>
        {mode === "stars" && data?.updatedAt && (
          <span className="text-[9px] text-steel/80 tabular-persian">{timeAgoFa(data.updatedAt)}</span>
        )}
      </div>

      {/* mode tabs */}
      <div className="flex items-center gap-1.5" role="tablist" aria-label="انتخاب حالت بازیکنان">
        {(["stars", "teams"] as Mode[]).map((m) => (
          <button
            key={m}
            type="button"
            role="tab"
            aria-selected={mode === m}
            data-testid={`mode-${m}`}
            onClick={() => applyMode(m)}
            className={tabCls(mode === m)}
          >
            {MODE_FA[m]}
          </button>
        ))}
      </div>

      {/* cycle-182: season selector — same look/contract as the گلزنان page
          (cycle-132) and the league page (cycle-55/99): options from the
          payload itself, deep-link via ?season=, honesty snap back when
          upstream serves the current race */}
      {mode === "stars" && seasonOptions.length > 1 && (
        <div className="flex items-center gap-2 px-1">
          <label htmlFor="season-select" className="text-[11px] font-bold text-muted-foreground flex items-center gap-1.5 shrink-0">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" aria-hidden>
              <rect x="3.5" y="4.5" width="17" height="16" rx="3" />
              <path d="M8 2.5v4M16 2.5v4M3.5 10.5h17" />
            </svg>
            فصل
          </label>
          <select
            id="season-select"
            value={season ?? seasonOptions[0]}
            onChange={(e) => {
              const s = e.target.value === seasonOptions[0] ? null : e.target.value;
              applySeason(s);
            }}
            className="text-[12px] font-bold text-foreground bg-white/[0.04] border border-[color:var(--glass-border-soft)] rounded-lg px-2 py-1.5 outline-none focus:border-sky-soft/50 cursor-pointer"
          >
            {seasonOptions.map((s) => (
              <option key={s} value={s} className="bg-[#10161f] text-foreground">
                {faSeasonShort(s)}{s === seasonOptions[0] ? " (فعلی)" : ""}
              </option>
            ))}
          </select>
          {starsLoading && season != null && (
            <span className="text-[10px] text-muted-foreground animate-pulse">در حال بارگذاری…</span>
          )}
        </div>
      )}

      {mode === "stars" ? (
        <>
          {error ? (
            <EmptyState title="بازیکنان" sub={error} />
          ) : starsLoading && !data ? (
            <StarsSkeleton />
          ) : list.length === 0 ? (
            <EmptyState
              title="بازیکنان"
              sub={
                season
                  ? `ستاره‌ای برای فصل ${faSeasonShort(shownSeason || season)} ثبت نشده است.`
                  : "هنوز آماری برای این سنجه ثبت نشده است."
              }
            />
          ) : (
            <>
              {/* metric tabs */}
              <div className="flex items-center gap-1.5" role="tablist" aria-label="انتخاب سنجه">
                {(["goals", "assists"] as Metric[]).map((m) => (
                  <button
                    key={m}
                    type="button"
                    role="tab"
                    aria-selected={metric === m}
                    onClick={() => setMetric(m)}
                    className={tabCls(metric === m)}
                  >
                    {METRIC_FA[m]}
                  </button>
                ))}
              </div>
              {/* hero trio */}
              <div className="grid grid-cols-3 gap-2">
                {list.slice(0, 3).map((p, i) => (
                  <PlayerCard key={p.key} p={p} rank={i + 1} metric={metric} big />
                ))}
              </div>
              {/* grid */}
              {list.length > 3 && (
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2">
                  {list.slice(3).map((p, i) => (
                    <PlayerCard key={p.key} p={p} rank={i + 4} metric={metric} />
                  ))}
                </div>
              )}
              <p className="text-[9.5px] text-steel/80 text-center pb-1">
                آمار از FotMob — با هر بار بازکردن صفحه خودکار به‌روز می‌شود.
              </p>
            </>
          )}
        </>
      ) : (
        <>
          {/* league chips */}
          <div className="flex items-center gap-1.5 flex-wrap" role="tablist" aria-label="انتخاب لیگ">
            {LEAGUES.map((lg) => (
              <button
                key={lg.key}
                type="button"
                role="tab"
                aria-selected={leagueKey === lg.key}
                data-testid={`league-${lg.key}`}
                onClick={() => applyLeague(lg.key)}
                className={tabCls(leagueKey === lg.key)}
              >
                {lg.faName}
              </button>
            ))}
          </div>

          {teamsErr ? (
            <EmptyState title="تیم‌ها" sub={teamsErr} />
          ) : !teams ? (
            <TeamsSkeleton />
          ) : (
            <div className="flex flex-col gap-3">
              <p className="text-[10px] text-steel px-1">
                تیمی را انتخاب کنید تا اسکواد کاملش با عکس همهٔ بازیکنان باز شود.
              </p>
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2" data-testid="team-grid">
                {teams.map((t) => (
                  <button
                    key={t.teamId}
                    type="button"
                    onClick={() => applyTeam(t.teamId)}
                    aria-pressed={teamId === t.teamId}
                    data-testid={`team-${t.teamId}`}
                    className={cn(
                      "glass-popover rounded-2xl px-3 py-2.5 flex items-center gap-2 text-right",
                      teamId === t.teamId ? "ring-1 ring-primary/40 bg-primary/5" : "glass-row-hover"
                    )}
                  >
                    <TeamLogo id={t.teamId} alt="" size={22} />
                    <span className="min-w-0 flex-1 truncate text-[11.5px] font-bold text-[#e8f1fb]" dir="auto" title={t.fa !== t.name ? t.name : undefined}>
                      {t.fa || t.name}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {teamId != null &&
            (squadErr ? (
              <EmptyState title="ترکیب تیم" sub={squadErr} />
            ) : !squad ? (
              <SquadSkeleton />
            ) : (
              <div className="flex flex-col gap-3" data-testid="squad-panel">
                {/* squad header */}
                <div className="glass-popover rounded-2xl p-3 flex items-center gap-2.5 flex-wrap">
                  <TeamLogo id={teamId} alt="" size={30} />
                  <div className="min-w-0">
                    <p className="font-black text-[13px] text-[#eef5fd] truncate" dir="auto">
                      {squadLabel || "ترکیب تیم"}
                    </p>
                    <p className="text-[9.5px] text-steel/80 mt-0.5 tabular-persian">
                      {faDigits(totalPlayers)} بازیکن
                      {squad.coach ? ` · سرمربی: ${squad.coach.name}` : ""}
                    </p>
                  </div>
                </div>
                {/* position groups */}
                {squad.groups.map((g) => (
                  <section key={g.key} className="flex flex-col gap-2">
                    <h2 className="text-[12px] font-black text-steel px-1 flex items-center gap-1.5">
                      <span className="inline-block w-1 h-3.5 rounded-full bg-primary/70" aria-hidden />
                      {g.titleFa}
                      <span className="text-[9.5px] font-bold text-steel/80 tabular-persian">({faDigits(g.players.length)})</span>
                    </h2>
                    <div className="grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-6 gap-2" data-testid={`group-${g.key}`}>
                      {g.players.map((p) => (
                        <SquadPlayerCard key={p.id} p={p} />
                      ))}
                    </div>
                  </section>
                ))}
                <p className="text-[9.5px] text-steel/80 text-center pb-1">
                  عکس‌ها از FotMob با بالاترین رزولوشن موجود — با هر بار بازکردن صفحه خودکار به‌روز می‌شود.
                </p>
              </div>
            ))}
        </>
      )}
    </div>
  );
}
