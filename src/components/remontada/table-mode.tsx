"use client";

// ------------------------------------------------------------------
// Remontada — cycle-52 (Update #2): shared «کل فصل / خانه / بیرون»
// segmented switch for standings tables. Rendered only by callers that
// actually hold per-side rows, so the "no data → no control" honesty
// rule lives with the data, not the control.
// ------------------------------------------------------------------
import { cn } from "@/lib/utils";

export type TableMode = "all" | "home" | "away";

const MODES: { key: TableMode; label: string; title: string }[] = [
  { key: "all", label: "کل فصل", title: "جدول کامل فصل" },
  { key: "home", label: "خانه", title: "فقط بازی‌های خانگی هر تیم" },
  { key: "away", label: "بیرون", title: "فقط بازی‌های خارج از خانه هر تیم" },
];

export function TableModeSwitch({
  mode,
  onChange,
  className,
}: {
  mode: TableMode;
  onChange: (m: TableMode) => void;
  className?: string;
}) {
  return (
    <div
      role="tablist"
      aria-label="نوع جدول رده‌بندی"
      className={cn(
        "inline-flex items-center gap-0.5 rounded-xl border border-[color:var(--glass-border-soft)] bg-white/[0.035] p-0.5",
        className
      )}
    >
      {MODES.map((m) => (
        <button
          key={m.key}
          type="button"
          role="tab"
          aria-selected={mode === m.key}
          title={m.title}
          onClick={() => onChange(m.key)}
          className={cn(
            "rounded-[10px] px-3 py-1.5 text-[11px] font-black transition-all",
            mode === m.key
              ? "bg-primary/15 text-primary shadow-[inset_0_1px_0_oklch(0.88_0.05_232/22%)]"
              : "text-muted-foreground hover:text-foreground"
          )}
        >
          {m.label}
        </button>
      ))}
    </div>
  );
}
