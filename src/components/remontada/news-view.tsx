"use client";

// ------------------------------------------------------------------
// Remontada — football news view (multi-source, Persian titles)
// ------------------------------------------------------------------
import { timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";

export interface ClientNewsItem {
  title: string;
  titleFa: string;
  summary?: string;
  link?: string;
  image?: string;
  publishedAt: string;
  source: string;
  league?: string;
}

const SOURCE_STYLE: Record<string, string> = {
  ESPN: "bg-red-500/10 text-red-400 border-red-500/30",
  "BBC Sport": "bg-amber-500/10 text-amber-400 border-amber-500/30",
  "Sky Sports": "bg-sky-500/10 text-sky-400 border-sky-500/30",
};

export function sourceStyle(s: string): string {
  if (SOURCE_STYLE[s]) return SOURCE_STYLE[s];
  if (/bbc/i.test(s)) return SOURCE_STYLE["BBC Sport"];
  if (/sky/i.test(s)) return SOURCE_STYLE["Sky Sports"];
  return "bg-muted text-muted-foreground border-border";
}

function NewsCard({ item }: { item: ClientNewsItem }) {
  const display = item.titleFa && item.titleFa !== item.title ? item.titleFa : item.titleFa || item.title;

  const body = (
    <article className="group rounded-2xl border border-border/60 bg-card/60 overflow-hidden hover:border-primary/30 hover:bg-card transition-all cursor-pointer h-full flex flex-col">
      <div className="relative aspect-video bg-muted/40 overflow-hidden">
        {item.image ? (
           
          <img
            src={item.image}
            alt=""
            loading="lazy"
            className="w-full h-full object-cover group-hover:scale-[1.03] transition-transform duration-500"
            onError={(e) => { e.currentTarget.style.display = "none"; }}
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.4" className="text-muted-foreground/40" aria-hidden>
              <circle cx="12" cy="12" r="9" />
              <path d="M12 7l4.5 3.2-1.7 5.3H9.2L7.5 10.2 12 7z" />
            </svg>
          </div>
        )}
        <span className={cn("absolute top-2.5 start-2.5 text-[10px] font-black border rounded-lg px-2 py-0.5 backdrop-blur-md", sourceStyle(item.source))}>
          {item.source}
        </span>
      </div>
      <div className="p-3.5 flex flex-col gap-2 flex-1">
        <h3 className="font-black text-[13.5px] leading-6 line-clamp-3 group-hover:text-primary transition-colors">
          {display}
        </h3>
        {item.summary && (
          <p className="text-[11.5px] text-muted-foreground leading-5 line-clamp-2">{item.summary}</p>
        )}
        <div className="mt-auto pt-1.5 flex items-center justify-between text-[10px] text-muted-foreground/80">
          <span>{timeAgoFa(item.publishedAt)}</span>
          {item.league && <span className="truncate max-w-[45%]">{item.league}</span>}
        </div>
      </div>
    </article>
  );

  return item.link ? (
    <a href={item.link} target="_blank" rel="noopener noreferrer" className="h-full">
      {body}
    </a>
  ) : (
    body
  );
}

function Skeleton() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3" aria-busy="true">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="rounded-2xl border border-border/60 bg-card/40 overflow-hidden">
          <div className="aspect-video bg-muted animate-pulse" />
          <div className="p-3.5 flex flex-col gap-2.5">
            <div className="h-4 rounded bg-muted animate-pulse" />
            <div className="h-4 rounded bg-muted animate-pulse w-4/5" />
            <div className="h-3 rounded bg-muted animate-pulse w-1/3 mt-1" />
          </div>
        </div>
      ))}
    </div>
  );
}

export interface NewsViewProps {
  items: ClientNewsItem[];
  loading: boolean;
  emptyHint?: string;
}

export function NewsView({ items, loading, emptyHint }: NewsViewProps) {
  if (loading && items.length === 0) return <Skeleton />;
  if (items.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-border/70 bg-card/30 px-6 py-14 text-center">
        <p className="font-black text-sm mb-1">خبری یافت نشد</p>
        <p className="text-xs text-muted-foreground">{emptyHint || "چند لحظه بعد دوباره بررسی کنید"}</p>
      </div>
    );
  }
  return (
    <div className={cn("grid gap-4 sm:grid-cols-2 lg:grid-cols-3 transition-opacity", loading && "opacity-50")}>
      {items.map((n, i) => (
        <NewsCard key={`${n.link || n.title}-${i}`} item={n} />
      ))}
    </div>
  );
}
