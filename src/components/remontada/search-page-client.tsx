"use client";

// ------------------------------------------------------------------
// Remontada — dedicated search page client (/search?q=…)
// cycle-296 additive: search results lived ONLY in the header dropdown
// — a query could never be shared, bookmarked or revisited. This page
// mirrors the dropdown's five sections and anchor scheme (teams
// /team/{id}, competitions /league/{key}, coaches /coach/{id}, players
// /player/{id}, external news) over the SAME /api/search contract, and
// makes the URL the state: typing debounces into ?q= (router.replace,
// no history spam) so every result view is a shareable link. Honest
// mirrors of the dropdown texts (the «حداقل ۲ حرف» hint) keep the two
// surfaces telling the same story. The page itself is noindex (the
// classic search-page SEO contract) — the dropdown and its keyboard
// contracts stay untouched.
// cycle-409 (fix 408 finding): the raw-name subtitle contract went
// one-sided — only the «رقابت» rows showed the honest upstream spelling
// under a Persian title while team/coach/player rows let the raw name
// vanish the moment fa || name rendered. rawSub() now gives every
// entity row the same league-row treatment: raw rides the subtitle iff
// it differs from the rendered title (equal → nothing — no duplicate).
// UI-only, additive; the /api/search byte contract stays untouched.
// ------------------------------------------------------------------
import { useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import type { CoachSearchResult, LeagueSearchResult, PlayerSearchResult, TeamSearchResult } from "@/lib/fotmob";
import type { NewsSearchResult } from "@/lib/news";
import { faDigits, timeAgoFa } from "@/lib/format";

type SearchPayload = {
  ok: boolean;
  results?: TeamSearchResult[];
  players?: PlayerSearchResult[];
  leagues?: LeagueSearchResult[];
  news?: NewsSearchResult[];
  coaches?: CoachSearchResult[];
  message?: string;
};

const MIN_Q = 2;
const HINT_SHORT = "حداقل ۲ حرف بنویسید — جستجو بین تیم‌ها و آقای گل‌های ۲۴ لیگ و جام";

// cycle-409: the raw-name subtitle — the entity's honest upstream spelling
// rides the subtitle IFF it differs from the rendered title (the league-row
// contract from cycle-296, now shared by every entity section).
function rawSub(raw: string, title: string): string | undefined {
  return raw !== title ? raw : undefined;
}

function Section({
  label,
  testid,
  children,
}: {
  label: string;
  testid: string;
  children: React.ReactNode;
}) {
  return (
    <section className="glass-card overflow-hidden" data-testid={testid}>
      <h2 className="text-[11px] font-black text-[#ecf3fa] px-4 pt-3 pb-1.5">{label}</h2>
      <ul className="px-2 pb-2 flex flex-col">
        {children}
      </ul>
    </section>
  );
}

function Row({
  href,
  title,
  subtitle,
  pill,
  external,
}: {
  href: string;
  title: string;
  subtitle?: string;
  pill?: string;
  external?: boolean;
}) {
  return (
    <li>
      <a
        href={href}
        {...(external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
        className="w-full flex items-center gap-2.5 px-2.5 py-2.5 rounded-xl hover:bg-white/[0.05] transition-colors"
      >
        <span className="min-w-0 flex-1">
          <span className="block font-bold text-[13px] leading-snug text-[#e8f1fb] truncate">{title}</span>
          {subtitle && <span className="block text-[10.5px] text-muted-foreground truncate">{subtitle}</span>}
        </span>
        {pill && (
          <span className="shrink-0 text-[9.5px] font-bold text-muted-foreground border border-[color:var(--glass-border-soft)] bg-white/[0.03] rounded-md px-1.5 py-px">
            {pill}
          </span>
        )}
      </a>
    </li>
  );
}

export function SearchPageClient() {
  const params = useSearchParams();
  const urlQ = params.get("q") ?? "";
  const router = useRouter();
  // input state is local; the URL is the source of truth for RESULTS
  const [text, setText] = useState(urlQ);
  const abortRef = useRef<AbortController | null>(null);
  // the payload carries the q it answers — loading/failed/stale are all
  // DERIVED from that q-tag (no setState-in-effect: state changes only
  // inside the async callbacks, the react-hooks rule's honest contract)
  const [payload, setPayload] = useState<{ q: string; d: SearchPayload } | null>(null);
  const [failedQ, setFailedQ] = useState<string | null>(null);

  // typing → URL (debounced, replace — every result view = one shareable link)
  useEffect(() => {
    const t = setTimeout(() => {
      const enc = encodeURIComponent(text.trim());
      const next = enc ? `/search?q=${enc}` : "/search";
      if (next !== `${window.location.pathname}${window.location.search}`) {
        router.replace(next, { scroll: false });
      }
    }, 400);
    return () => clearTimeout(t);
  }, [text, router]);

  // URL → fetch (the only fetch trigger; aborts the stale one)
  useEffect(() => {
    const q = urlQ.trim();
    abortRef.current?.abort();
    if (q.length < MIN_Q) return;
    const ac = new AbortController();
    abortRef.current = ac;
    fetch(`/api/search?q=${encodeURIComponent(q)}`, { cache: "no-store", signal: ac.signal })
      .then((r) => r.json())
      .then((d: SearchPayload) => {
        if (ac.signal.aborted) return;
        setPayload({ q, d });
        setFailedQ(null);
      })
      .catch(() => {
        if (ac.signal.aborted) return;
        setFailedQ(q);
      });
    return () => ac.abort();
  }, [urlQ]);

  const q = urlQ.trim();
  const short = q.length < MIN_Q;
  // data answers THIS url only — a stale payload for another q never shows
  const data = !short && payload?.q === q ? payload.d : null;
  const loading = !short && !data && failedQ !== q;
  const failed = !short && failedQ === q;
  const teams = data?.results ?? [];
  const leagues = data?.leagues ?? [];
  const coaches = data?.coaches ?? [];
  const players = data?.players ?? [];
  const news = data?.news ?? [];
  const total = teams.length + leagues.length + coaches.length + players.length + news.length;

  return (
    <div className="flex flex-col gap-3" data-testid="search-page">
      <div className="glass-card p-3 flex flex-col gap-2">
        <h1 className="font-black text-lg leading-7 text-[#f1f7fd]">جستجو در رمانتادا</h1>
        <input
          data-testid="search-page-input"
          type="search"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="نام تیم، بازیکن، مربی یا رقابت…"
          aria-label="عبارت جستجو"
          className="w-full rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.04] px-3.5 py-2.5 text-[13px] font-bold text-[#e8f1fb] outline-none focus:border-sky-soft/50 placeholder:text-muted-foreground/60"
        />
        {!short && (
          <p className="text-[10.5px] text-muted-foreground tabular-persian" aria-live="polite">
            {loading
              ? "در حال جستجو…"
              : failed
                ? "خطا در جستجو — دوباره تلاش کنید"
                : `${faDigits(total)} نتیجه برای «${q}»`}
          </p>
        )}
      </div>

      {short && (
        <div className="glass-card p-4 text-[12px] font-bold text-muted-foreground" data-testid="search-page-short">
          {HINT_SHORT}
        </div>
      )}

      {!short && !loading && !failed && total === 0 && (
        <div className="glass-card p-4 flex flex-col gap-1" data-testid="search-page-empty">
          <p className="font-black text-[13px] text-[#e8f1fb]">نتیجه‌ای یافت نشد</p>
          <p className="text-[11px] text-muted-foreground">
            عبارت کوتاه‌تر یا املای دیگری را امتحان کنید — جستجو بین تیم‌ها، بازیکن‌ها، مربی‌ها، رقابت‌ها و خبرهاست.
          </p>
        </div>
      )}

      {!short && teams.length > 0 && (
        <Section label="تیم‌ها" testid="search-sec-teams">
          {teams.map((t) => (
            <Row
              key={`t-${t.teamId}`}
              href={`/team/${t.teamId}`}
              title={t.fa || t.name}
              subtitle={[rawSub(t.name, t.fa || t.name), t.leagueFa, t.rank != null ? `رتبه ${faDigits(t.rank)}` : "", t.pts != null ? `${faDigits(t.pts)} امتیاز` : ""].filter(Boolean).join(" · ") || undefined}
              pill="تیم"
            />
          ))}
        </Section>
      )}

      {!short && leagues.length > 0 && (
        <Section label="رقابت‌ها" testid="search-sec-leagues">
          {leagues.map((l) => (
            <Row key={`l-${l.key}`} href={`/league/${l.key}`} title={l.fa || l.en} subtitle={rawSub(l.en, l.fa || l.en)} pill="رقابت" />
          ))}
        </Section>
      )}

      {!short && coaches.length > 0 && (
        <Section label="مربی‌ها" testid="search-sec-coaches">
          {coaches.map((c) => (
            <Row
              key={`c-${c.id}`}
              href={`/coach/${c.id}`}
              title={c.fa || c.name}
              subtitle={[rawSub(c.name, c.fa || c.name), c.teamName ? `سرمربی ${c.teamName}` : ""].filter(Boolean).join(" · ") || undefined}
              pill="مربی"
            />
          ))}
        </Section>
      )}

      {!short && players.length > 0 && (
        <Section label="بازیکن‌ها" testid="search-sec-players">
          {players.map((p) => (
            <Row
              key={`p-${p.playerId}`}
              href={`/player/${p.playerId}`}
              title={p.fa || p.name}
              subtitle={[rawSub(p.name, p.fa || p.name), p.teamFa || ""].filter(Boolean).join(" · ") || undefined}
              pill="بازیکن"
            />
          ))}
        </Section>
      )}

      {!short && news.length > 0 && (
        <Section label="خبرها" testid="search-sec-news">
          {news.map((n, i) => (
            <Row
              key={`n-${n.source}-${n.publishedAt}-${i}`}
              href={n.link || "#"}
              title={n.titleFa || n.title}
              subtitle={`${n.source} · ${timeAgoFa(n.publishedAt)}`}
              pill="خبر"
              external
            />
          ))}
        </Section>
      )}

      {!short && !loading && !failed && total > 0 && (
        <p className="text-[10px] text-muted-foreground/70 text-center pb-2">
          این صفحه آدرس‌پذیر است — همین نتایج با همین لینک برای دیگران هم باز می‌شود.
        </p>
      )}
    </div>
  );
}
