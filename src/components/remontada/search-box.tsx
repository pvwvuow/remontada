"use client";

// ------------------------------------------------------------------
// Remontada — live team search (header searchbox with instant results)
// ------------------------------------------------------------------
import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import type { TeamSearchResult, PlayerSearchResult, LeagueSearchResult } from "@/lib/fotmob";
import type { NewsSearchResult } from "@/lib/news";
import { fotmobTeamLogo, teamFa } from "@/lib/leagues";
import type { CoachSearchResult } from "@/lib/fotmob";
import { useFavorites } from "@/lib/favorites";
import { FavoriteStar } from "@/components/remontada/favorite-star";
import { faDigits, timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";

/** fallback suggestions for the empty search state (ids verified from match feed) */
const POPULAR_TEAMS: { id: number; fa: string }[] = [
  { id: 101610, fa: "پرسپولیس" },
  { id: 101614, fa: "استقلال" },
  { id: 176352, fa: "تراکتور" },
  { id: 101611, fa: "سپاهان" },
  { id: 8633, fa: "رئال مادرید" },
  { id: 8634, fa: "بارسلونا" },
  { id: 10260, fa: "منچستریونایتد" },
];

/** renders `text` with the matched [start,end) range highlighted */
function Hl({ text, range }: { text: string; range?: [number, number] | null }) {
  if (!range || range[0] < 0 || range[1] > text.length || range[0] >= range[1]) return <>{text}</>;
  return (
    <>
      {text.slice(0, range[0])}
      <mark className="bg-primary/20 text-primary rounded-sm px-0.5">{text.slice(range[0], range[1])}</mark>
      {text.slice(range[1])}
    </>
  );
}

// cycle-269: honest cap for the live search — the cycle-268 patrol measured a
// cold /api/search (team-index rebuild, 10-min cache) exceeding 30s while the
// server eventually completed and cached; the client previously waited forever
// (spinner, no AbortController). 20s gives the cold rebuild a fair window —
// if it is aborted, the server-side work still finishes and caches, so the
// user's immediate retry hits the warm cache and answers instantly.
const SEARCH_TIMEOUT_MS = 20_000;

export function SearchBox() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  // cycle-269: true only when the 20s cap aborted the request — the dialog
  // then shows the honest retry message instead of a silent stuck spinner
  // (and the «پیدا نشد» empty-state stays quiet: an aborted search never
  // earned the right to claim «not found»)
  const [timedOut, setTimedOut] = useState(false);
  const [results, setResults] = useState<TeamSearchResult[]>([]);
  // cycle-166: the «آقای گل» player pool joins the search — teams stay first
  // (results), players render as their own section below with /player links
  const [players, setPlayers] = useState<PlayerSearchResult[]>([]);
  // cycle-200: competitions join the same additive way — a «رقابت‌ها»
  // section between teams and players, every row a real /league/{key} link
  const [leagues, setLeagues] = useState<LeagueSearchResult[]>([]);
  // cycle-202: news joins the same additive way — a «خبرها» section after
  // players, every row the real external article (warm-only index: an
  // unwarmed feed answers [] and the section honestly hides)
  const [news, setNews] = useState<NewsSearchResult[]>([]);
  // cycle-256: coaches join the same additive way — a «مربی‌ها» section
  // between leagues and players, every row a real /coach/{id} link backed
  // by the cycle-255 profile page
  const [coaches, setCoaches] = useState<CoachSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [active, setActive] = useState(0); // keyboard-highlighted result
  const favorites = useFavorites();
  const inputRef = useRef<HTMLInputElement>(null);
  const boxRef = useRef<HTMLDivElement>(null);

  // cycle-204: set only by keyboard moves (ArrowDown/ArrowUp) — the
  // scroll-into-view effect below must never fight the mouse (a hovered
  // row is visible by definition)
  const kbNav = useRef(false);

  // close on Escape / focus input when opened
  useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 30);
    } else {
      setQ("");
      setResults([]);
      setLeagues([]);
      setNews([]);
      setActive(0);
      setTimedOut(false);
      kbNav.current = false;
    }
  }, [open]);

  // cycle-204: keyboard navigation stays visible — the highlighted row
  // scrolls into view inside the popover's overflow container (the list
  // is max-h-[46vh], so a long needle like «ali» overflows and ArrowDown
  // previously walked the user blind — the active row sat up to ~300px
  // below the visible bottom). block:"nearest" scrolls only as much as
  // needed and never scrolls when the row is already fully visible.
  useEffect(() => {
    if (!open || !kbNav.current) return;
    kbNav.current = false;
    boxRef.current?.querySelector(".cmd-active")?.scrollIntoView({ block: "nearest" });
  }, [active, open]);

  // click-outside closes
  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    return () => document.removeEventListener("mousedown", onDown);
  }, [open]);

  // debounced live search — cycle-269: every in-flight request is bound to an
  // AbortController with a 20s honest cap (SEARCH_TIMEOUT_MS above). The cap
  // abort keeps previous results and shows the retry message; any cleanup
  // (new keystroke, dialog close, unmount) aborts the orphan request instead
  // of letting it run to completion behind the UI.
  useEffect(() => {
    const query = q.trim();
    if (query.length < 2) {
      setResults([]);
      setPlayers([]);
      setLeagues([]);
      setNews([]);
      setCoaches([]);
      setLoading(false);
      setTimedOut(false);
      return;
    }
    setLoading(true);
    setTimedOut(false);
    const ac = new AbortController();
    let abortedByCap = false;
    const cap = setTimeout(() => {
      abortedByCap = true;
      ac.abort();
    }, SEARCH_TIMEOUT_MS);
    const t = setTimeout(async () => {
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`, {
          cache: "no-store",
          signal: ac.signal,
        });
        const json = await res.json();
        if (json.ok) {
          setResults(json.results as TeamSearchResult[]);
          setPlayers((json.players ?? []) as PlayerSearchResult[]);
          setLeagues((json.leagues ?? []) as LeagueSearchResult[]);
          setNews((json.news ?? []) as NewsSearchResult[]);
          setCoaches((json.coaches ?? []) as CoachSearchResult[]);
          setActive(0);
        }
      } catch {
        // cap-abort: keep previous results, flip the honest retry message;
        // every other failure (cleanup abort, network) keeps the old contract
        if (abortedByCap) setTimedOut(true);
      } finally {
        setLoading(false);
      }
    }, 250);
    return () => {
      clearTimeout(t);
      clearTimeout(cap);
      ac.abort();
    };
  }, [q]);

  const go = useCallback(
    (teamId: number) => {
      setOpen(false);
      router.push(`/team/${teamId}`);
    },
    [router]
  );

  // cycle-166: keyboard selection spans teams first, then the players section
  // cycle-200: the span is teams → leagues → players (matches the render order)
  // cycle-202: the span extends to news (teams → leagues → players → خبرها)
  // cycle-256: the span extends to coaches (teams → leagues → مربی‌ها → players → خبرها)
  const totalRows = results.length + leagues.length + coaches.length + players.length + news.length;
  const goPlayer = useCallback(
    (playerId: number) => {
      setOpen(false);
      router.push(`/player/${playerId}`);
    },
    [router]
  );

  // cycle-256: coach rows navigate the cycle-255 profile page
  const goCoach = useCallback(
    (coachId: number) => {
      setOpen(false);
      router.push(`/coach/${coachId}`);
    },
    [router]
  );

  // cycle-200: league rows are real /league/{key} navigation — teams first,
  // then the «رقابت‌ها» section, then players (keyboard order matches)
  const goLeague = useCallback(
    (key: string) => {
      setOpen(false);
      router.push(`/league/${key}`);
    },
    [router]
  );

  // cycle-202: news rows are external articles — same semantics as the news
  // page rows (<a target=_blank rel=noopener>); Enter mirrors the click
  const openNews = useCallback(
    (link?: string) => {
      if (!link) return;
      setOpen(false);
      window.open(link, "_blank", "noopener,noreferrer");
    },
    []
  );

  // empty-state suggestions: user's favorites first, then popular teams (deduped)
  const suggestions: { id: number; fa: string; logo: string }[] = [];
  const seenIds = new Set<number>();
  for (const f of favorites.slice(0, 3)) {
    if (seenIds.has(f.id)) continue;
    seenIds.add(f.id);
    suggestions.push({ id: f.id, fa: f.fa, logo: fotmobTeamLogo(f.id) });
  }
  for (const p of POPULAR_TEAMS) {
    if (suggestions.length >= 6) break;
    if (seenIds.has(p.id)) continue;
    seenIds.add(p.id);
    suggestions.push({ id: p.id, fa: p.fa, logo: fotmobTeamLogo(p.id) });
  }

  const onKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Escape") { setOpen(false); return; }
    if (e.key === "ArrowDown") { e.preventDefault(); kbNav.current = true; setActive((a) => Math.min(a + 1, totalRows - 1)); }
    if (e.key === "ArrowUp") { e.preventDefault(); kbNav.current = true; setActive((a) => Math.max(a - 1, 0)); }
    if (e.key === "Enter") {
      e.preventDefault();
      // cycle-284: the index walk must match the render order (teams → leagues →
      // مربی‌ها → players → خبرها). Coaches were skipped, so Enter on a coach row
      // mis-navigated to a player (or died on coaches-only result sets).
      if (active < results.length) { if (results[active]) go(results[active].teamId); }
      else if (active < results.length + leagues.length) { const l = leagues[active - results.length]; if (l) goLeague(l.key); }
      else if (active < results.length + leagues.length + coaches.length) { const c = coaches[active - results.length - leagues.length]; if (c) goCoach(c.id); }
      else if (active < results.length + leagues.length + coaches.length + players.length) { const p = players[active - results.length - leagues.length - coaches.length]; if (p) goPlayer(p.playerId); }
      else { const n = news[active - results.length - leagues.length - coaches.length - players.length]; if (n) openNews(n.link); }
    }
  };

  return (
    <div ref={boxRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-label="جستجوی تیم"
        aria-expanded={open}
        className={cn(
          "inline-flex items-center justify-center w-8 h-8 rounded-lg border transition-colors",
          open
            ? "text-sky-soft bg-sky-soft/10 border-sky-soft/30"
            : "text-steel hover:text-foreground hover:bg-white/[0.06] border-[color:var(--glass-border-soft)]"
        )}
      >
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" aria-hidden>
          <circle cx="11" cy="11" r="7" />
          <path d="M20 20l-3.8-3.8" />
        </svg>
      </button>

      {open && (
        <>
          {/* overlay panel */}
          <div className="fixed inset-0 z-40 bg-background/40 backdrop-blur-[2px]" onClick={() => setOpen(false)} aria-hidden />
          <div className="cmd-open absolute z-50 top-10 end-0 w-[min(92vw,420px)] rounded-2xl glass-popover overflow-hidden" role="dialog" aria-label="جستجوی تیم">
            <div className="flex items-center gap-2 px-3.5 py-2.5 border-b border-[color:var(--glass-hairline)]">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-muted-foreground shrink-0" aria-hidden>
                <circle cx="11" cy="11" r="7" />
                <path d="M20 20l-3.8-3.8" />
              </svg>
              <input
                ref={inputRef}
                value={q}
                onChange={(e) => setQ(e.target.value)}
                onKeyDown={onKeyDown}
                placeholder="نام تیم… مثلاً پرسپولیس یا Real"
                className="w-full bg-transparent text-[13px] font-medium outline-none placeholder:text-muted-foreground/80"
                maxLength={40}
              />
              {loading && (
                <span className="w-4 h-4 rounded-full border-2 border-sky-soft/30 border-t-sky-soft animate-spin shrink-0" aria-label="در حال جستجو" />
              )}
            </div>

            <div className="max-h-[46vh] overflow-y-auto">
              {timedOut && !loading && (
                <p
                  data-testid="search-timeout"
                  aria-live="polite"
                  className="text-[11px] text-muted-foreground text-center pt-3 pb-1 px-4"
                >
                  جستجو بیش از حد طول کشید — دوباره تلاش کنید.
                </p>
              )}
              {q.trim().length < 2 ? (
                <p className="text-[11.5px] text-muted-foreground text-center py-6 px-4">
                  حداقل {faDigits(2)} حرف بنویسید — جستجو بین تیم‌ها و آقای گل‌های {faDigits(24)} لیگ و جام
                </p>
              ) : !loading && !timedOut && results.length === 0 && leagues.length === 0 && players.length === 0 && news.length === 0 && coaches.length === 0 ? (
                <div className="py-4 px-4 flex flex-col items-center gap-3">
                  <p className="text-[11.5px] text-muted-foreground">تیمی یا بازیکنی با این نام پیدا نشد.</p>
                  <div className="w-full">
                    <p className="text-[10px] font-bold text-muted-foreground/80 text-center mb-2">شاید دنبال این تیم‌ها بودید:</p>
                    <div className="flex flex-wrap justify-center gap-1.5">
                      {/* cycle-285: the item cycle-284 explicitly left out of scope —
                          chips are now real <Link>s too (same look, same click
                          close-then-push via onClick): middle-click/right-click
                          «open in new tab» works on the not-found suggestions */}
                      {suggestions.map((t) => (
                        <Link
                          key={t.id}
                          href={`/team/${t.id}`}
                          prefetch={false}
                          onClick={() => setOpen(false)}
                          className="inline-flex items-center gap-1.5 rounded-full border border-[color:var(--glass-border-soft)] bg-white/[0.04] ps-1.5 pe-2.5 py-1 text-[11px] font-bold hover:bg-sky-soft/10 hover:border-sky-soft/40 hover:text-sky-soft transition-colors"
                        >
                          <img src={t.logo} alt="" width={16} height={16} loading="lazy" className="w-4 h-4 object-contain" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                          {t.fa}
                        </Link>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <ul className="p-1.5 flex flex-col">
                  {results.map((r, i) => (
                    <li key={r.teamId} className="relative">
                      {/* cycle-284: rows are real <Link>s — middle-click/right-click
                          «open in new tab» works and the rows are semantic links;
                          click keeps the same close-then-push behavior via onClick */}
                      <Link
                        href={`/team/${r.teamId}`}
                        prefetch={false}
                        onClick={() => setOpen(false)}
                        onMouseEnter={() => setActive(i)}
                        className={cn(
                          "w-full flex items-center gap-2.5 ps-8 pe-2.5 py-2 rounded-xl text-start transition-colors",
                          i === active ? "cmd-active" : "hover:bg-white/[0.05]"
                        )}
                      >
                        { }
                        <img src={r.logo} alt="" width={22} height={22} loading="lazy" className="w-[22px] h-[22px] object-contain shrink-0" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                        <span className="min-w-0 flex-1">
                          <span className="block font-bold text-[13px] truncate">
                            <Hl text={r.fa || r.name} range={r.fa ? r.hl?.fa ?? null : r.hl?.name ?? null} />
                          </span>
                          <span className="block text-[10px] text-muted-foreground truncate">
                            <Hl text={r.name} range={r.hl?.name ?? null} />
                          </span>
                        </span>
                        <span className="shrink-0 flex flex-col items-end gap-0.5">
                          <span className="text-[9.5px] font-bold text-muted-foreground border border-[color:var(--glass-border-soft)] bg-white/[0.03] rounded-md px-1.5 py-px">
                            {r.leagueFa}
                          </span>
                          {r.rank > 0 && (
                            <span className="text-[9px] text-muted-foreground tabular-persian">
                              رتبه {faDigits(r.rank)}
                            </span>
                          )}
                        </span>
                      </Link>
                      {/* favorite star — sibling of the row link (no nested interactive elements) */}
                      <FavoriteStar
                        team={{ id: r.teamId, fa: r.fa || r.name, en: r.name }}
                        size={14}
                        className="absolute top-1/2 -translate-y-1/2 start-2"
                      />
                    </li>
                  ))}
                </ul>
              )}

              {leagues.length > 0 && (
                <div className="border-t border-[color:var(--glass-hairline)] pt-1 pb-1.5">
                  <p className="text-[9.5px] font-bold text-muted-foreground/80 px-4 pt-1.5 pb-1">رقابت‌ها</p>
                  <ul className="px-1.5 flex flex-col">
                    {leagues.map((l, i) => {
                      const idx = results.length + i;
                      return (
                        <li key={l.key}>
                          <Link
                            href={`/league/${l.key}`}
                            prefetch={false}
                            onClick={() => setOpen(false)}
                            onMouseEnter={() => setActive(idx)}
                            className={cn(
                              "w-full flex items-center gap-2.5 ps-4 pe-2.5 py-2 rounded-xl text-start transition-colors",
                              idx === active ? "cmd-active" : "hover:bg-white/[0.05]"
                            )}
                          >
                            <img
                              src={`https://images.fotmob.com/image_resources/logo/leaguelogo/${l.leagueId}.png`}
                              alt=""
                              width={22}
                              height={22}
                              loading="lazy"
                              className="w-[22px] h-[22px] object-contain shrink-0"
                              onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
                            />
                            <span className="min-w-0 flex-1">
                              <span className="block font-bold text-[13px] truncate">
                                <Hl text={l.fa} range={l.hl?.fa ?? null} />
                              </span>
                              <span className="block text-[10px] text-muted-foreground truncate">
                                <Hl text={l.en} range={l.hl?.en ?? null} />
                              </span>
                            </span>
                            <span className="shrink-0 text-[9.5px] font-bold text-muted-foreground border border-[color:var(--glass-border-soft)] bg-white/[0.03] rounded-md px-1.5 py-px">
                              رقابت
                            </span>
                          </Link>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              )}

              {/* ---------- cycle-256: the coach seed joins the search ---------- */}
              {coaches.length > 0 && (
                <div className="border-t border-[color:var(--glass-hairline)] pt-1 pb-1.5" data-testid="search-coaches">
                  <p className="text-[9.5px] font-bold text-muted-foreground/80 px-4 pt-1.5 pb-1">مربی‌ها</p>
                  <ul className="px-1.5 flex flex-col">
                    {coaches.map((c, i) => {
                      const idx = results.length + leagues.length + i;
                      return (
                        <li key={c.id}>
                          <Link
                            href={`/coach/${c.id}`}
                            prefetch={false}
                            onClick={() => setOpen(false)}
                            onMouseEnter={() => setActive(idx)}
                            className={cn(
                              "w-full flex items-center gap-2.5 ps-4 pe-2.5 py-2 rounded-xl text-start transition-colors",
                              idx === active ? "cmd-active" : "hover:bg-white/[0.05]"
                            )}
                          >
                            {/* no coach headshots exist upstream — the club badge rides in */}
                            <img
                              src={fotmobTeamLogo(c.teamId)}
                              alt=""
                              width={22}
                              height={22}
                              loading="lazy"
                              className="w-[22px] h-[22px] object-contain shrink-0"
                              onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
                            />
                            <span className="min-w-0 flex-1">
                              {/* cycle-259: Persian coach name first (bug-hunt 258
                                  finding) — english falls back dir="auto" */}
                              <span className="block font-bold text-[13px] truncate" dir="auto">
                                {c.fa || c.name}
                              </span>
                              <span className="block text-[10px] text-muted-foreground truncate">
                                {teamFa(c.teamName) || c.teamName}
                              </span>
                            </span>
                            <span className="shrink-0 text-[9.5px] font-bold text-muted-foreground border border-[color:var(--glass-border-soft)] bg-white/[0.03] rounded-md px-1.5 py-px">
                              مربی
                            </span>
                          </Link>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              )}

              {players.length > 0 && (
                <div className="border-t border-[color:var(--glass-hairline)] pt-1 pb-1.5">
                  <p className="text-[9.5px] font-bold text-muted-foreground/80 px-4 pt-1.5 pb-1">بازیکنان</p>
                  <ul className="px-1.5 flex flex-col">
                    {players.map((p, i) => {
                      const idx = results.length + leagues.length + coaches.length + i;
                      return (
                        <li key={p.playerId}>
                          <Link
                            href={`/player/${p.playerId}`}
                            prefetch={false}
                            onClick={() => setOpen(false)}
                            onMouseEnter={() => setActive(idx)}
                            className={cn(
                              "w-full flex items-center gap-2.5 ps-4 pe-2.5 py-2 rounded-xl text-start transition-colors",
                              idx === active ? "cmd-active" : "hover:bg-white/[0.05]"
                            )}
                          >
                            <img
                              src={`https://images.fotmob.com/image_resources/playerimages/${p.playerId}.png`}
                              alt=""
                              width={22}
                              height={22}
                              loading="lazy"
                              className="w-[22px] h-[22px] rounded-full object-cover shrink-0 bg-white/[0.06]"
                              onError={(e) => { e.currentTarget.style.visibility = "hidden"; }}
                            />
                            <span className="min-w-0 flex-1">
                              <span className="block font-bold text-[13px] truncate">
                                <Hl text={p.fa} range={p.hl?.fa ?? null} />
                              </span>
                              <span className="block text-[10px] text-muted-foreground truncate">
                                <Hl text={p.name} range={p.hl?.name ?? null} />
                              </span>
                            </span>
                            <span className="shrink-0 flex flex-col items-end gap-0.5">
                              {p.teamFa ? (
                                <span className="text-[9.5px] font-bold text-muted-foreground border border-[color:var(--glass-border-soft)] bg-white/[0.03] rounded-md px-1.5 py-px">
                                  {p.teamFa}
                                </span>
                              ) : null}
                              <span className="text-[9px] text-muted-foreground truncate max-w-[110px]">
                                {/* cycle-194: a historical fold row tells its finished season
                                    («لیگ برتر کرواسی · ۲۰۲۴/۲۰۲۵») — current rows have no
                                    season field and render exactly as before */}
                                {p.season ? `${p.leagueFa} · ${faDigits(p.season)}` : p.leagueFa}
                              </span>
                            </span>
                          </Link>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              )}

              {/* ---------- cycle-202: the news feed joins the search ---------- */}
              {news.length > 0 && (
                <div className="border-t border-[color:var(--glass-hairline)] pt-1 pb-1.5" data-testid="search-news">
                  <p className="text-[9.5px] font-bold text-muted-foreground/80 px-4 pt-1.5 pb-1">خبرها</p>
                  <ul className="px-1.5 flex flex-col">
                    {news.map((n, i) => {
                      const idx = results.length + leagues.length + coaches.length + players.length + i;
                      return (
                        <li key={`${n.source}-${n.publishedAt}-${i}`}>
                          <a
                            href={n.link || "#"}
                            target="_blank"
                            rel="noopener noreferrer"
                            onClick={() => setOpen(false)}
                            onMouseEnter={() => setActive(idx)}
                            className={cn(
                              "w-full flex items-center gap-2.5 ps-4 pe-2.5 py-2 rounded-xl text-start transition-colors",
                              idx === active ? "cmd-active" : "hover:bg-white/[0.05]"
                            )}
                          >
                            <span className="min-w-0 flex-1">
                              <span className="block font-bold text-[12.5px] leading-snug line-clamp-2">
                                <Hl text={n.titleFa || n.title} range={n.titleFa ? n.hl?.fa ?? null : n.hl?.en ?? null} />
                              </span>
                              <span className="block text-[10px] text-muted-foreground truncate tabular-persian">
                                {n.source} · {timeAgoFa(n.publishedAt)}
                              </span>
                            </span>
                            <span className="shrink-0 text-[9.5px] font-bold text-muted-foreground border border-[color:var(--glass-border-soft)] bg-white/[0.03] rounded-md px-1.5 py-px">
                              خبر
                            </span>
                          </a>
                        </li>
                      );
                    })}
                  </ul>
                </div>
              )}
            </div>
            {/* cycle-66 — palette hint bar: the little game-UI footer */}
            {q.trim().length >= 2 && (
              <div className="flex items-center justify-center gap-2.5 px-3 py-2 border-t border-[color:var(--glass-hairline)] text-[9px] text-muted-foreground/80 bg-white/[0.015]">
                <span className="inline-flex items-center gap-1"><kbd className="inline-flex items-center rounded border border-glass-border-soft bg-white/[0.05] px-1 py-px font-bold">↑</kbd><kbd className="inline-flex items-center rounded border border-glass-border-soft bg-white/[0.05] px-1 py-px font-bold">↓</kbd> حرکت</span>
                <span aria-hidden>·</span>
                <span className="inline-flex items-center gap-1"><kbd className="inline-flex items-center rounded border border-glass-border-soft bg-white/[0.05] px-1 py-px font-bold">Enter</kbd> انتخاب</span>
                <span aria-hidden>·</span>
                <span className="inline-flex items-center gap-1"><kbd className="inline-flex items-center rounded border border-glass-border-soft bg-white/[0.05] px-1 py-px font-bold">Esc</kbd> بستن</span>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
