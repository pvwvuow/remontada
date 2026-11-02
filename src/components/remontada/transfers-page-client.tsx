"use client";

// ------------------------------------------------------------------
// Remontada — transfers page client (cycle-415)
// «تازه‌ترین انتقال‌های فوتبال» — the global wire rendered fa-first.
// Structure mirrors news-page-client: one fetch, the house loading
// skeleton (ui-cycle-20), the honest error + «تلاش دوباره» state
// (empty-state.tsx language), the freshness line (the 305 convention).
// Row = one tap-hit-row anchor to the player profile (the ui-cycle-21
// hit-row language); clubs render as color-dot chips — no nested anchors
// (invalid HTML) — team pages stay reachable from everywhere else.
// ------------------------------------------------------------------
import { useCallback, useEffect, useState } from "react";
import type { GlobalTransferItem } from "@/lib/fotmob";
import { faDigits } from "@/lib/format";
import { timeAgoFa } from "@/lib/format";
import { cn } from "@/lib/utils";

function ClubChip({
  club,
  muted,
}: {
  club: GlobalTransferItem["from"];
  muted?: boolean;
}) {
  const dot = (
    <span
      aria-hidden
      className="inline-block size-2 rounded-full shrink-0"
      style={club.color ? { background: club.color } : { background: "var(--glass-border)" }}
    />
  );
  const label = (
    <span className={cn("truncate text-[11.5px] font-bold", muted ? "text-muted-foreground" : "text-steel")}>
      {club.nameFa || club.name}
    </span>
  );
  if (club.id === 2 || club.id <= 0) {
    // Free agent — not a club, no dead-end link (the honest-absence rule)
    return (
      <span className="inline-flex items-center gap-1.5 min-w-0">
        {dot}
        {label}
      </span>
    );
  }
  return (
    <a
      href={`/team/${club.id}`}
      className="inline-flex items-center gap-1.5 min-w-0 tap-hit-row hover:text-foreground transition-colors"
      title={club.nameFa && club.nameFa !== club.name ? club.name : undefined}
    >
      {dot}
      {label}
    </a>
  );
}

function TransferRow({ t }: { t: GlobalTransferItem }) {
  return (
    <a
      href={`/player/${t.playerId}`}
      className="tap-hit-row block rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.03] px-3 py-2.5 transition-colors hover:border-[color:var(--glass-border)] hover:bg-white/[0.05]"
    >
      <div className="flex items-center gap-2 min-w-0">
        <span className="shrink-0 rounded-md bg-white/[0.06] px-1.5 py-0.5 text-[9.5px] font-black text-steel tabular-persian">
          {t.posFa || t.posLabel || "—"}
        </span>
        <span
          className="truncate text-[13px] font-black text-[#ecf3fa]"
          title={t.nameFa !== t.name ? t.name : undefined}
        >
          {t.nameFa}
        </span>
        <span className="shrink-0 ms-auto text-[10px] font-bold text-muted-foreground tabular-persian">
          {t.agoFa}
        </span>
      </div>
      <div className="mt-1.5 flex items-center gap-1.5 min-w-0 text-[11.5px]">
        <ClubChip club={t.from} />
        <span aria-hidden className="shrink-0 text-muted-foreground">←</span>
        <ClubChip club={t.to} muted={t.to.id === 2} />
        <span className="shrink-0 ms-auto rounded-md bg-sky-soft/10 px-1.5 py-0.5 text-[9.5px] font-black text-sky-soft">
          {t.feeFa}
        </span>
      </div>
      {(t.dateFa || t.marketValueFa) && (
        <div className="mt-1 flex items-center gap-2 text-[9.5px] font-bold text-muted-foreground tabular-persian">
          {t.dateFa && <span>{t.dateFa}</span>}
          {t.marketValueFa && <span>· ارزش بازار {t.marketValueFa}</span>}
        </div>
      )}
    </a>
  );
}

function RowSkeleton() {
  return (
    <div className="rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.03] px-3 py-2.5 animate-pulse" aria-hidden>
      <div className="h-3.5 w-2/3 rounded bg-white/[0.07]" />
      <div className="mt-2 h-3 w-5/6 rounded bg-white/[0.05]" />
    </div>
  );
}

export function TransfersPageClient() {
  const [items, setItems] = useState<GlobalTransferItem[]>([]);
  const [fetchedAt, setFetchedAt] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [failed, setFailed] = useState(false);

  const fetchWire = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const res = await fetch("/api/transfers", { cache: "no-store" });
      const json = await res.json();
      if (json.ok) {
        setItems(json.items || []);
        setFailed(false);
        setFetchedAt(typeof json.fetchedAt === "string" ? json.fetchedAt : "");
      } else {
        setFailed(true);
      }
    } catch {
      setFailed(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchWire();
  }, [fetchWire]);

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-end justify-between gap-3">
        <div>
          <h1 className="text-base font-black text-[#ecf3fa]">تازه‌ترین انتقال‌های فوتبال</h1>
          <p className="mt-0.5 text-[11px] font-bold text-steel">
            آخرین جابه‌جایی‌های رسمی باشگاه‌ها در دنیای فوتبال
          </p>
        </div>
        <span className="shrink-0 rounded-lg bg-white/[0.05] px-2 py-1 text-[10px] font-black text-steel tabular-persian">
          {faDigits(items.length)} انتقال
        </span>
      </div>

      {fetchedAt && !loading && !failed && (
        <p className="text-[10px] font-bold text-muted-foreground tabular-persian">
          به‌روزرسانی فید: {timeAgoFa(fetchedAt)}
        </p>
      )}

      {loading && (
        <div className="flex flex-col gap-2" aria-busy="true">
          {Array.from({ length: 8 }).map((_, i) => (
            <RowSkeleton key={i} />
          ))}
        </div>
      )}

      {!loading && failed && (
        <div className="rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.03] px-4 py-6 text-center">
          <p className="text-[12.5px] font-black text-steel">فید انتقال‌ها در دسترس نیست.</p>
          <p className="mt-1 text-[10.5px] font-bold text-muted-foreground">اتصال دوباره امتحان کنید.</p>
          <button
            onClick={() => fetchWire()}
            className="mt-3 rounded-lg border border-[color:var(--glass-border)] bg-white/[0.05] px-4 py-2 text-[11.5px] font-black text-foreground press-fx tap-hit-row"
          >
            تلاش دوباره
          </button>
        </div>
      )}

      {!loading && !failed && items.length === 0 && (
        <div className="rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.03] px-4 py-6 text-center">
          <p className="text-[12.5px] font-black text-steel">فعلاً انتقالی ثبت نشده است.</p>
        </div>
      )}

      {!loading && !failed && items.length > 0 && (
        <div className="flex flex-col gap-2">
          {items.map((t, i) => (
            <TransferRow key={`${t.playerId}-${t.transferDate}-${i}`} t={t} />
          ))}
        </div>
      )}
    </div>
  );
}
