import Link from "next/link";

/**
 * Shared empty-state (cycle-34): friendly Persian message + themed icon +
 * optional action (href → Link, onClick → button). Used across list views so
 * every "nothing here" moment of the portal looks and reads the same.
 * Presentational only — safe to render from server or client components.
 */
export type EmptyStateIcon =
  | "ball"
  | "star"
  | "live"
  | "calendar"
  | "medal"
  | "shirt"
  | "trophy"
  | "news"
  | "search";

export interface EmptyStateAction {
  label: string;
  href?: string;
  onClick?: () => void;
}

interface EmptyStateProps {
  icon?: EmptyStateIcon;
  title: string;
  sub?: string;
  action?: EmptyStateAction;
  /** smaller paddings/icon for inline tab sections */
  compact?: boolean;
}

const ICON_STROKE: Record<EmptyStateIcon, { path: React.ReactNode; cls: string }> = {
  ball: {
    path: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M12 7l4.5 3.2-1.7 5.3H9.2L7.5 10.2 12 7z" />
      </>
    ),
    cls: "text-muted-foreground",
  },
  star: {
    path: <path d="M12 2.6l2.86 5.8 6.4.93-4.63 4.51 1.09 6.37L12 17.2l-5.72 3.01 1.09-6.37-4.63-4.51 6.4-.93L12 2.6z" />,
    cls: "text-amber-400/70",
  },
  live: {
    path: (
      <>
        <circle cx="12" cy="12" r="3" />
        <path d="M5.6 5.6a9 9 0 0 0 0 12.8M18.4 5.6a9 9 0 0 1 0 12.8" />
      </>
    ),
    cls: "text-red-400/70",
  },
  calendar: {
    path: (
      <>
        <rect x="3.5" y="5" width="17" height="15.5" rx="2.5" />
        <path d="M3.5 9.5h17M8 2.8v4M16 2.8v4" />
      </>
    ),
    cls: "text-sky-400/70",
  },
  medal: {
    path: (
      <>
        <circle cx="12" cy="14.5" r="5" />
        <path d="M12 12.2l.9 1.8 2 .3-1.45 1.4.35 2-1.8-.95-1.8.95.35-2L9.1 14.3l2-.3.9-1.8zM8.5 9.5L5 3h4.2L12 8l2.8-5H19l-3.5 6.5" />
      </>
    ),
    cls: "text-amber-300/70",
  },
  shirt: {
    path: <path d="M8.5 3.5L5 5.5 3 9.5l3 1.8V20.5h12v-9.2l3-1.8-2-4-3.5-2a3.5 3.5 0 0 1-7 0z" />,
    cls: "text-emerald-400/70",
  },
  trophy: {
    path: (
      <>
        <path d="M7 4h10v5a5 5 0 0 1-10 0V4z" />
        <path d="M7 5.5H4.5a0 0 0 0 0 0 0c0 3 1.2 4.6 2.9 5.1M17 5.5h2.5c0 3-1.2 4.6-2.9 5.1M12 14v3.5M8.5 20.5h7M9.5 17.5h5l.8 3h-6.6l.8-3z" />
      </>
    ),
    cls: "text-amber-400/60",
  },
  news: {
    path: (
      <>
        <rect x="3" y="5" width="14" height="15" rx="2" />
        <path d="M17 9h2.5a1.5 1.5 0 0 1 1.5 1.5V18a2 2 0 0 1-2 2H5M6.5 9h7M6.5 12.5h7M6.5 16h4.5" />
      </>
    ),
    cls: "text-sky-400/70",
  },
  search: {
    path: (
      <>
        <circle cx="11" cy="11" r="6.5" />
        <path d="M20 20l-4.4-4.4" />
      </>
    ),
    cls: "text-muted-foreground",
  },
};

export function EmptyState({ icon = "ball", title, sub, action, compact }: EmptyStateProps) {
  const ic = ICON_STROKE[icon];
  const size = compact ? 20 : 26;
  return (
    <div
      className={
        compact
          ? "rounded-2xl border border-dashed border-glass-border-soft bg-white/[0.02] px-5 py-8 text-center"
          : "rounded-2xl border border-dashed border-glass-border-soft bg-white/[0.02] px-6 py-14 text-center"
      }
    >
      <div
        className={
          compact
            ? "mx-auto w-11 h-11 rounded-xl bg-white/[0.04] border border-glass-border-soft flex items-center justify-center mb-3"
            : "mx-auto w-14 h-14 rounded-2xl bg-white/[0.04] border border-glass-border-soft flex items-center justify-center mb-4"
        }
      >
        <svg
          width={size}
          height={size}
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
          strokeLinejoin="round"
          className={ic.cls}
          aria-hidden
        >
          {ic.path}
        </svg>
      </div>
      <p className="font-black text-sm mb-1">{title}</p>
      {sub ? <p className="text-xs text-muted-foreground">{sub}</p> : null}
      {action ? (
        action.href ? (
          <Link
            href={action.href}
            className="mt-4 inline-flex items-center gap-1.5 rounded-xl bg-primary/15 border border-primary/40 text-primary text-xs font-bold px-4 py-2 hover:bg-primary/25 transition-colors"
          >
            {action.label}
          </Link>
        ) : (
          <button
            type="button"
            onClick={action.onClick}
            className="mt-4 inline-flex items-center gap-1.5 rounded-xl bg-primary/15 border border-primary/40 text-primary text-xs font-bold px-4 py-2 hover:bg-primary/25 transition-colors cursor-pointer"
          >
            {action.label}
          </button>
        )
      ) : null}
    </div>
  );
}
