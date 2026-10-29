"use client";

// ------------------------------------------------------------------
// Remontada — live team search (header searchbox with instant results)
// ------------------------------------------------------------------
import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { TeamSearchResult } from "@/lib/fotmob";
import { fotmobTeamLogo } from "@/lib/leagues";
import { useFavorites } from "@/lib/favorites";
import { FavoriteStar } from "@/components/remontada/favorite-star";
import { faDigits } from "@/lib/format";
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

export function SearchBox() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [results, setResults] = useState<TeamSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [active, setActive] = useState(0); // keyboard-highlighted result
  const favorites = useFavorites();
  const inputRef = useRef<HTMLInputElement>(null);
  const boxRef = useRef<HTMLDivElement>(null);

  // close on Escape / focus input when opened
  useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 30);
    } else {
      setQ("");
      setResults([]);
      setActive(0);
    }
  }, [open]);

  // click-outside closes
  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    return () => document.removeEventListener("mousedown", onDown);
  }, [open]);

  // debounced live search
  useEffect(() => {
    const query = q.trim();
    if (query.length < 2) {
      setResults([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    const t = setTimeout(async () => {
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`, { cache: "no-store" });
        const json = await res.json();
        if (json.ok) {
          setResults(json.results as TeamSearchResult[]);
          setActive(0);
        }
      } catch {
        // keep previous results on failure
      } finally {
        setLoading(false);
      }
    }, 250);
    return () => clearTimeout(t);
  }, [q]);

  const go = useCallback(
    (teamId: number) => {
      setOpen(false);
      router.push(`/team/${teamId}`);
    },
    [router]
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
    if (e.key === "ArrowDown") { e.preventDefault(); setActive((a) => Math.min(a + 1, results.length - 1)); }
    if (e.key === "ArrowUp") { e.preventDefault(); setActive((a) => Math.max(a - 1, 0)); }
    if (e.key === "Enter" && results[active]) { e.preventDefault(); go(results[active].teamId); }
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
                className="w-full bg-transparent text-[13px] font-medium outline-none placeholder:text-muted-foreground/60"
                maxLength={40}
              />
              {loading && (
                <span className="w-4 h-4 rounded-full border-2 border-sky-soft/30 border-t-sky-soft animate-spin shrink-0" aria-label="در حال جستجو" />
              )}
            </div>

            <div className="max-h-[46vh] overflow-y-auto">
              {q.trim().length < 2 ? (
                <p className="text-[11.5px] text-muted-foreground text-center py-6 px-4">
                  حداقل {faDigits(2)} حرف بنویسید — جستجو بین تیم‌های {faDigits(8)} لیگ و جام برتر
                </p>
              ) : !loading && results.length === 0 ? (
                <div className="py-4 px-4 flex flex-col items-center gap-3">
                  <p className="text-[11.5px] text-muted-foreground">تیمی با این نام پیدا نشد.</p>
                  <div className="w-full">
                    <p className="text-[10px] font-bold text-muted-foreground/80 text-center mb-2">شاید دنبال این تیم‌ها بودید:</p>
                    <div className="flex flex-wrap justify-center gap-1.5">
                      {suggestions.map((t) => (
                        <button
                          key={t.id}
                          type="button"
                          onClick={() => go(t.id)}
                          className="inline-flex items-center gap-1.5 rounded-full border border-[color:var(--glass-border-soft)] bg-white/[0.04] ps-1.5 pe-2.5 py-1 text-[11px] font-bold hover:bg-sky-soft/10 hover:border-sky-soft/40 hover:text-sky-soft transition-colors"
                        >
                          <img src={t.logo} alt="" width={16} height={16} loading="lazy" className="w-4 h-4 object-contain" onError={(e) => { e.currentTarget.style.visibility = "hidden"; }} />
                          {t.fa}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                <ul className="p-1.5 flex flex-col">
                  {results.map((r, i) => (
                    <li key={r.teamId} className="relative">
                      <button
                        type="button"
                        onClick={() => go(r.teamId)}
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
                      </button>
                      {/* favorite star — sibling of the row button (no nested buttons) */}
                      <FavoriteStar
                        team={{ id: r.teamId, fa: r.fa || r.name, en: r.name }}
                        size={14}
                        className="absolute top-1/2 -translate-y-1/2 start-2"
                      />
                    </li>
                  ))}
                </ul>
              )}
            </div>
            {/* cycle-66 — palette hint bar: the little game-UI footer */}
            {q.trim().length >= 2 && (
              <div className="flex items-center justify-center gap-2.5 px-3 py-2 border-t border-[color:var(--glass-hairline)] text-[9px] text-muted-foreground/75 bg-white/[0.015]">
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
