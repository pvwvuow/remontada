// ------------------------------------------------------------------
// Remontada — news feed + news search (cycle-202)
//
// The producer is the EXACT code that lived in src/app/api/news/route.ts
// (cycles 57–138), moved here so TWO routes can share ONE cached
// instance: /api/news (the page feed) and /api/search (the cycle-202
// «خبرها» index). Same cache key `news:v1`, same 15-min TTL, same
// translation stage — zero behavior change for the feed route.
//
// cycle-202: the header search never covered the news page — 16
// Persian-translated headlines sat behind /api/news with no path from
// the search dialog. searchNews() folds the SAME cached list (zero
// fresh upstream calls, zero producer trigger: cacheGetDeep is a
// warm-only read — a cold/expired cache yields an empty result, the
// honest-absence pattern, the section simply hides until any
// /api/news visit warms it). Matching mechanics mirror searchLeagues
// (cycle-200): normalizeQuery on both sides (the 169 dual fa-fold + NFD),
// exact 100 > prefix 80 > includes 50 > all-words 40, rangeOf highlight
// spans, ties keep the feed's own newest-first order (stable sort).
// The answer rides a NEW `news` field on /api/search (the cycle-166
// additive-field precedent — existing clients stay untouched).
// ------------------------------------------------------------------
import { cached, cacheGetDeep } from "@/lib/cache";
import { normalizeQuery, rangeOf } from "@/lib/fotmob";

export interface NewsItem {
  title: string;        // original (English)
  titleFa: string;      // Persian translation (falls back to English)
  summary?: string;
  link?: string;
  image?: string;
  publishedAt: string;
  source: string;       // "ESPN" | "BBC Sport" | "Sky Sports"
  league?: string;
}

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

// cycle-138: 12s → 10s. The five feeds run in parallel so the feed phase is
// bounded by the slowest one; together with the 10s translation budget below
// the whole cold producer is hard-bounded at ~20s — inside the regression
// suite's 25s curl budget even on a fully cold process right after a restart.
async function fetchText(url: string, timeoutMs = 10_000): Promise<string> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { headers: { "User-Agent": UA }, signal: ctrl.signal, cache: "no-store" });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.text();
  } finally {
    clearTimeout(t);
  }
}

function pickCdata(block: string): string {
  const c = block.match(/<!\[CDATA\[([\s\S]*?)\]\]>/);
  if (c) return c[1].trim();
  return block.replace(/<[^>]+>/g, "").trim();
}

function parseRss(xml: string, source: string): NewsItem[] {
  const items: NewsItem[] = [];
  const blocks = xml.split(/<item[\s>]/).slice(1);
  for (const b of blocks) {
    const title = pickCdata((b.match(/<title>([\s\S]*?)<\/title>/) || ["", ""])[1]);
    const link = ((b.match(/<link>([\s\S]*?)<\/link>/) || ["", ""])[1]).replace(/<!\[CDATA\[|\]\]>/g, "").trim();
    const descBlock = (b.match(/<description>([\s\S]*?)<\/description>/) || ["", ""])[1];
    const summary = pickCdata(descBlock).slice(0, 220);
    const pub = (b.match(/<pubDate>([\s\S]*?)<\/pubDate>/) || ["", ""])[1].trim();
    const imgMatch = b.match(/<media:thumbnail[^>]+url="([^"]+)"/) || b.match(/<media:content[^>]+url="([^"]+)"/);
    const ts = pub ? new Date(pub).getTime() : Date.now();
    if (!title) continue;
    items.push({
      title, titleFa: title, summary, link,
      image: imgMatch?.[1],
      publishedAt: new Date(ts).toISOString(),
      source,
    });
  }
  return items;
}

async function espnNews(slug: string, league: string): Promise<NewsItem[]> {
  const raw = await fetchText(`https://site.api.espn.com/apis/site/v2/sports/soccer/${slug}/news`);
  const data = JSON.parse(raw) as {
    articles?: {
      headline?: string; description?: string; published?: string;
      images?: { url?: string }[];
      links?: { web?: { href?: string } };
    }[];
  };
  return (data.articles || []).slice(0, 8).map((a) => ({
    title: a.headline || "",
    titleFa: a.headline || "",
    summary: (a.description || "").slice(0, 220),
    link: a.links?.web?.href,
    image: a.images?.[0]?.url,
    publishedAt: a.published || new Date().toISOString(),
    source: "ESPN",
    league,
  })).filter((n) => n.title);
}

// Translate titles to Persian in ONE batched LLM call.
// cycle-138: the LLM round-trip now has a HARD 10s budget. On a cold
// (expired-cache) request the unbounded translation call was the one stage
// that could push /api/news past the regression's 25s curl budget right after
// a restart — the twice-documented first-run 27/28 transient (cycles 134/135:
// the slow first fill only warmed the cache in time for the SECOND run). On
// timeout — as on any SDK failure — the route keeps the honest English titles
// instead of hanging; a still-running background completion is discarded.
const TRANSLATE_BUDGET_MS = 10_000;

async function translateTitles(items: NewsItem[]): Promise<NewsItem[]> {
  const toTranslate = items.slice(0, 16);
  if (toTranslate.length === 0) return items; // nothing to translate — skip the LLM entirely
  const titles = toTranslate.map((n) => n.title.replace(/"/g, "'"));
  const payload = JSON.stringify(titles);
  const work = (async (): Promise<string> => {
    try {
      const { default: ZAI } = await import("z-ai-web-dev-sdk");
      const zai = await ZAI.create();
      const completion = await zai.chat.completions.create({
        messages: [
          {
            role: "assistant",
            content:
              "You are a professional Persian (Farsi) sports translator. You translate football news headlines into natural, fluent Persian used by Iranian football media. Use proper football terminology. Respond with valid JSON only — no explanations, no markdown.",
          },
          {
            role: "user",
            content:
              `Translate this JSON array of football headlines to Persian. Return ONLY a JSON array of translated strings, same order and same length as input (length ${titles.length}). Input: ${payload}`,
          },
        ],
        thinking: { type: "disabled" },
      });
      return completion.choices[0]?.message?.content || "";
    } catch {
      return ""; // any SDK failure → the JSON match below throws → English titles
    }
  })();
  let timer: ReturnType<typeof setTimeout> | null = null;
  try {
    const text = await Promise.race([
      work,
      new Promise<null>((resolve) => {
        timer = setTimeout(() => resolve(null), TRANSLATE_BUDGET_MS);
      }),
    ]);
    if (text === null) throw new Error("translation budget exceeded");
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (!jsonMatch) throw new Error("no json in response");
    const arr = JSON.parse(jsonMatch[0]) as string[];
    if (!Array.isArray(arr) || arr.length !== toTranslate.length) throw new Error("bad translation array");
    toTranslate.forEach((n, i) => {
      if (arr[i] && typeof arr[i] === "string") n.titleFa = arr[i];
    });
  } catch {
    // keep English titles on any failure (translation timeout included)
  } finally {
    if (timer) clearTimeout(timer);
  }
  return items;
}

async function loadNews(): Promise<NewsItem[]> {
  const results = await Promise.allSettled([
    espnNews("eng.1", "پریمیرلیگ"),
    espnNews("uefa.champions", "لیگ قهرمانان"),
    espnNews("esp.1", "لالیگا"),
    fetchText("https://feeds.bbci.co.uk/sport/football/rss.xml").then((x) => parseRss(x, "BBC Sport")),
    fetchText("https://www.skysports.com/rss/12040").then((x) => parseRss(x, "Sky Sports")),
  ]);

  const all: NewsItem[] = [];
  for (const r of results) {
    if (r.status === "fulfilled") all.push(...r.value);
  }

  // dedup by normalized title, keep newest 48h only
  const cutoff = Date.now() - 48 * 3600_000;
  const seen = new Set<string>();
  const deduped = all
    .filter((n) => {
      const k = n.title.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim().slice(0, 60);
      if (seen.has(k)) return false;
      seen.add(k);
      return true;
    })
    .filter((n) => new Date(n.publishedAt).getTime() > cutoff - 24 * 3600_000)
    .sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime())
    .slice(0, 16);

  await translateTitles(deduped);
  return deduped;
}

/** the shared producer — /api/news and searchNews both ride this entry */
export function getNewsFeed(): Promise<NewsItem[]> {
  return cached("news:v1", 15 * 60_000, loadNews);
}

// ---------------- cycle-202: news joins the header search ----------------

export interface NewsSearchResult {
  title: string;       // raw English headline (honest secondary display)
  titleFa: string;     // the Persian title the news page shows (primary display)
  source: string;      // "ESPN" | "BBC Sport" | "Sky Sports"
  publishedAt: string; // ISO — the dialog renders timeAgoFa
  link?: string;       // external article URL (rows open in a new tab)
  matchedOn: string;   // the matched VALUE (titleFa or title) — the 195/200 convention
  hl?: { fa: [number, number] | null; en: [number, number] | null };
}

/** cycle-202: WARM-ONLY fold of the news:v1 feed — search must NEVER
 *  trigger the ~20s cold producer inside a keystroke request, so an
 *  absent/expired cache answers [] (honest absence; the section hides).
 *  Normalized on BOTH titles (the Persian one the portal displays and
 *  the honest English original) so both alphabets find the row. */
export async function searchNews(q: string, limit = 3): Promise<NewsSearchResult[]> {
  const nq = normalizeQuery(q);
  if (nq.length < 2) return [];
  const hit = await cacheGetDeep<NewsItem[]>("news:v1");
  if (!hit || hit.stale) return [];
  const scored: { it: NewsItem; score: number }[] = [];
  for (const it of hit.value) {
    const faHay = normalizeQuery(it.titleFa || "");
    const enHay = normalizeQuery(it.title || "");
    let score = -1;
    let onFa = true;
    if (faHay === nq) score = 100;
    else if (faHay.startsWith(nq)) score = 80;
    else if (faHay.includes(nq)) score = 50;
    if (score < 0) {
      if (enHay === nq) { score = 100; onFa = false; }
      else if (enHay.startsWith(nq)) { score = 80; onFa = false; }
      else if (enHay.includes(nq)) { score = 50; onFa = false; }
      else {
        const words = nq.split(" ");
        if (words.length > 1 && words.every((w) => faHay.includes(w))) score = 40;
        else if (words.length > 1 && words.every((w) => enHay.includes(w))) { score = 40; onFa = false; }
      }
    }
    if (score > 0) scored.push({ it, score });
  }
  // stable sort → equal scores keep the feed's newest-first order
  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, limit).map(({ it }) => {
    const faRange = rangeOf(it.titleFa || "", nq);
    const enRange = rangeOf(it.title || "", nq);
    return {
      title: it.title,
      titleFa: it.titleFa,
      source: it.source,
      publishedAt: it.publishedAt,
      ...(it.link ? { link: it.link } : {}),
      matchedOn: faRange ? it.titleFa : it.title,
      hl: { fa: faRange, en: enRange },
    };
  });
}
