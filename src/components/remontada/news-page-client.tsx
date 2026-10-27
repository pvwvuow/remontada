"use client";

// ------------------------------------------------------------------
// Remontada — dedicated news page client (fetch + refresh)
// ------------------------------------------------------------------
import { useCallback, useEffect, useState } from "react";
import { NewsView, type ClientNewsItem } from "@/components/remontada/news-view";
import { cn } from "@/lib/utils";

export function NewsPageClient() {
  const [items, setItems] = useState<ClientNewsItem[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchNews = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const res = await fetch("/api/news", { cache: "no-store" });
      const json = await res.json();
      if (json.ok) setItems(json.items || []);
    } catch {
      // keep old
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchNews();
  }, [fetchNews]);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex justify-end px-1">
        <button
          onClick={() => fetchNews()}
          className="flex items-center gap-1.5 text-xs font-semibold bg-card/80 border border-border px-3 py-1.5 rounded-lg hover:bg-accent transition-colors"
        >
          <svg
            width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"
            className={cn(loading && "animate-spin")} aria-hidden
          >
            <path d="M21 12a9 9 0 1 1-2.64-6.36" />
            <path d="M21 3v6h-6" />
          </svg>
          بروزرسانی
        </button>
      </div>
      <NewsView items={items} loading={loading} />
    </div>
  );
}
