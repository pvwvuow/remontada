// ------------------------------------------------------------------
// Remontada — /rss.xml
// RSS 2.0 feed of the football news surface — cycle-295 additive.
// The site map had every news consumer (page, /api/news, warm search
// fold, LD ItemList) but NO distribution surface: no rss/atom/feed
// route existed anywhere in the app (probed cycle-295). This closes
// that gap with the standard feed readers expect, reusing the SAME
// 15-min cached producer (getNewsFeed → news:v2, whose cycle-294
// empty-outage guard this feed inherits for free: an upstream cold
// outage surfaces as the honest 502 here too, never an empty channel).
//
// Honest mirroring: the feed renders exactly what /news renders —
// title = titleFa || title (the NewsItem type's own fallback
// contract), items in the producer's own order (the page's
// ItemListOrderDescending, LD=UI=data=feed), capped at the 50 newest.
// Items without a link are skipped (RSS <link> is required per spec;
// live probe: all 16 items carry one).
//
// Entity handling: the upstream sources carry PRE-ESCAPED HTML in
// their strings (live probe: BBC links literally contain "&amp;" in
// the JSON bytes), so raw escaping would double-escape URLs into
// "&amp;amp;". xmlText() therefore DECODES the common named and
// numeric HTML entities first, THEN XML-escapes — "&amp;" in the
// producer string comes out as a correct single "&amp;" in XML.
// Dependency-free on purpose (the site's lib convention).
// ------------------------------------------------------------------
import { getNewsFeed } from "@/lib/news";
import { SITE_URL } from "@/lib/site";

export const dynamic = "force-dynamic";

const MAX_ITEMS = 50;

function xmlText(input: string): string {
  // 1) decode the HTML entities the upstream strings arrive with
  const decoded = input
    .replace(/&(amp|lt|gt|quot|apos|#39);/g, (_m, e: string) => {
      switch (e) {
        case "amp": return "&";
        case "lt": return "<";
        case "gt": return ">";
        case "quot": return '"';
        default: return "'"; // apos and #39
      }
    })
    .replace(/&#(\d+);/g, (_m, n: string) => {
      const code = Number(n);
      return Number.isFinite(code) && code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : _m;
    });
  // 2) XML-escape once — the only escaping the feed ever needs
  return decoded
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function rfc822(iso: string): string | null {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d.toUTCString();
}

export async function GET() {
  let items;
  try {
    items = await getNewsFeed();
  } catch {
    // Same honest failure contract as /api/news (cycle-294): the
    // producer only throws on a true cold start with the upstream
    // down (stale-while-error already served the snapshot otherwise).
    // An empty channel would LIE about "no news today" — a 502 tells
    // the reader to retry instead.
    return new Response("خطا در دریافت فید خبری", {
      status: 502,
      headers: { "content-type": "text/plain; charset=utf-8" },
    });
  }

  const feedItems = items.filter((n) => n.link).slice(0, MAX_ITEMS);
  const lastBuild = feedItems
    .map((n) => rfc822(n.publishedAt))
    .filter((d): d is string => d !== null)
    .sort()
    .at(-1) ?? new Date().toUTCString();

  const parts: string[] = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
    "<channel>",
    `<title>${xmlText("رمانتادا — اخبار فوتبال")}</title>`,
    `<link>${xmlText(`${SITE_URL}/news`)}</link>`,
    `<description>${xmlText("تازه‌ترین اخبار فوتبال با تیترهای فارسی — جمع‌آوری از ESPN، BBC Sport و Sky Sports.")}</description>`,
    "<language>fa-ir</language>",
    `<atom:link href="${xmlText(`${SITE_URL}/rss.xml`)}" rel="self" type="application/rss+xml" />`,
    `<lastBuildDate>${lastBuild}</lastBuildDate>`,
    "<generator>Remontada</generator>",
  ];

  for (const n of feedItems) {
    const pub = rfc822(n.publishedAt);
    parts.push(
      "<item>",
      `<title>${xmlText(n.titleFa || n.title)}</title>`,
      `<link>${xmlText(n.link!)}</link>`,
      `<guid isPermaLink="true">${xmlText(n.link!)}</guid>`,
      ...(pub ? [`<pubDate>${pub}</pubDate>`] : []),
      ...(n.summary ? [`<description>${xmlText(n.summary)}</description>`] : []),
      ...(n.league ? [`<category>${xmlText(n.league)}</category>`] : []),
      "</item>"
    );
  }

  parts.push("</channel>", "</rss>");

  return new Response(parts.join("\n"), {
    status: 200,
    headers: { "content-type": "application/rss+xml; charset=utf-8" },
  });
}
