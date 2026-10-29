"use client";

// ------------------------------------------------------------------
// Remontada — league transfers list («انتقال‌ها», cycle-57)
// Current-season transfer feed of the league's clubs: direction chip
// (ورودی/خروجی/داخلی), clubs from→to with tiny logos, Persian fee/type
// label, Jalali date. FotMob serves this feed for the current season
// only (probed: historical season → null data), so the panel says so.
// ------------------------------------------------------------------
import type { LeagueTransfersData, LeagueTransferItem } from "@/lib/fotmob";
import { faDigits, jalaliShort } from "@/lib/format";
import { TeamLogo } from "./team-logo";
import { cn } from "@/lib/utils";

const KIND_CHIP: Record<LeagueTransferItem["kind"], string> = {
  in: "text-mint border-mint/30 bg-mint/10",
  out: "text-rose-soft border-rose-soft/30 bg-rose-soft/10",
  internal: "text-sky-soft border-sky-soft/30 bg-sky-soft/10",
};

function ClubTag({ id, name }: { id: number; name: string }) {
  return (
    <span className="inline-flex items-center gap-1 min-w-0">
      {/* cycle-145: TeamLogo owns the generic-side placeholder — a raw <img>
          here 403s for «Free agent» (id 2) before hydration → visible broken
          image, the only transfers-surface logo without a guard */}
      <TeamLogo id={id} alt="" size={14} className="rounded-[3px] bg-white/10" />
      <span className="truncate">{name}</span>
    </span>
  );
}

function TransferRow({ t }: { t: LeagueTransferItem }) {
  const j = t.date ? jalaliShort(t.date) : null;
  return (
    <li className="glass-card px-3 py-2.5 flex items-start gap-2.5">
      <span
        className="shrink-0 w-8 h-8 rounded-lg bg-white/[0.05] border border-[color:var(--glass-border-soft)] grid place-items-center text-[10px] font-black text-[#c3d4ea]"
        aria-hidden
      >
        {t.position || "—"}
      </span>
      <div className="flex-1 min-w-0">
        <p className="text-[12.5px] font-black truncate">{t.name}</p>
        <p className="text-[11px] text-[#b4c8df]/75 flex items-center gap-1.5 mt-0.5">
          <span className="min-w-0 flex items-center gap-1">
            <ClubTag id={t.from.id} name={t.from.fa} />
          </span>
          <span className="text-muted-foreground shrink-0" aria-hidden>←</span>
          <span className="min-w-0 flex items-center gap-1">
            <ClubTag id={t.to.id} name={t.to.fa} />
          </span>
        </p>
      </div>
      <div className="shrink-0 flex flex-col items-end gap-1">
        <span className={cn("text-[9.5px] font-black rounded-md border px-1.5 py-0.5", KIND_CHIP[t.kind])}>
          {t.kindFa}
        </span>
        <span className="text-[10px] font-bold text-[#c3d4ea]">{t.feeFa}</span>
        {j && (
          <span className="text-[9.5px] text-muted-foreground tabular-persian whitespace-nowrap">
            {j.day} {j.month}
          </span>
        )}
      </div>
    </li>
  );
}

export function LeagueTransfersList({ data }: { data: LeagueTransfersData }) {
  const nIn = data.items.filter((t) => t.kind === "in").length;
  const nOut = data.items.filter((t) => t.kind === "out").length;
  const nInt = data.items.filter((t) => t.kind === "internal").length;
  return (
    <section className="flex flex-col gap-2" aria-label="انتقال‌های لیگ">
      <div className="glass-card px-3.5 py-2.5 flex items-center justify-between gap-2 flex-wrap">
        <p className="text-[12px] font-black">
          {faDigits(data.items.length)} انتقال
          {data.season && (
            <span className="text-muted-foreground font-bold"> · فصل {faDigits(data.season)}</span>
          )}
        </p>
        <p className="text-[10.5px] font-bold text-muted-foreground tabular-persian">
          ورودی {faDigits(nIn)} · خروجی {faDigits(nOut)}
          {nInt > 0 && <> · داخلی {faDigits(nInt)}</>}
        </p>
      </div>
      <p className="text-[10px] text-muted-foreground px-1 leading-5">
        این خوراک از منبع فقط فصل جاری را می‌دهد؛ انتقال‌های فصل‌های تاریخی در دسترس نیست.
      </p>
      <ul className="flex flex-col gap-2">
        {data.items.map((t, i) => (
          <TransferRow key={`${t.playerId}:${t.date}:${i}`} t={t} />
        ))}
      </ul>
    </section>
  );
}
