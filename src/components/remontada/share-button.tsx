"use client";

// ------------------------------------------------------------------
// Remontada — share button: Web Share API with clipboard fallback
// - native share sheet when available (mobile / installed PWA)
// - otherwise copies the absolute URL to the clipboard
// - success feedback: icon swaps to a checkmark + «کپی شد» label
// ------------------------------------------------------------------
import { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";

export function ShareButton({
  title,
  path,
  size = 28,
  className,
}: {
  title: string;
  /** relative URL, e.g. /match/123 or /team/8633 */
  path: string;
  size?: number;
  className?: string;
}) {
  const [copied, setCopied] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => () => { if (timer.current) clearTimeout(timer.current); }, []);

  const flash = () => {
    setCopied(true);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setCopied(false), 2200);
  };

  const legacyCopy = (url: string) => {
    const ta = document.createElement("textarea");
    ta.value = url;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    try {
      document.execCommand("copy");
      flash();
    } catch {
      window.prompt("این لینک را کپی کنید:", url);
    } finally {
      document.body.removeChild(ta);
    }
  };

  const onShare = async () => {
    const url = `${window.location.origin}${path}`;
    // native share sheet first
    if (typeof navigator !== "undefined" && navigator.share) {
      try {
        await navigator.share({ title, text: title, url });
        return; // user completed (or cancelled) the native sheet — no toast needed
      } catch (err) {
        if ((err as DOMException)?.name === "AbortError") return;
        // share failed for another reason → fall through to clipboard
      }
    }
    try {
      await navigator.clipboard.writeText(url);
      flash();
    } catch {
      legacyCopy(url);
    }
  };

  return (
    <button
      onClick={onShare}
      title={copied ? "لینک کپی شد" : "اشتراک‌گذاری"}
      aria-label={copied ? "لینک کپی شد" : "اشتراک‌گذاری"}
      className={cn(
        "inline-flex items-center justify-center gap-1 rounded-lg border px-1.5 transition-all shrink-0 cursor-pointer",
        copied
          ? "text-mint border-mint/40 bg-mint/10"
          : "text-steel border-[color:var(--glass-border-soft)] bg-white/[0.04] hover:text-foreground hover:bg-white/[0.08] hover:border-[color:var(--glass-border)]",
        className
      )}
      style={{ height: size, minWidth: size, width: copied ? "auto" : size, maxWidth: "none" }}
    >
      {copied ? (
        <svg width={size * 0.5} height={size * 0.5} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
          <path d="M20 6L9 17l-5-5" />
        </svg>
      ) : (
        <svg width={size * 0.5} height={size * 0.5} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
          <circle cx="18" cy="5" r="3" />
          <circle cx="6" cy="12" r="3" />
          <circle cx="18" cy="19" r="3" />
          <path d="M8.6 10.7l6.8-4M8.6 13.3l6.8 4" />
        </svg>
      )}
      {copied && (
        <span className="text-[10px] font-black whitespace-nowrap me-1">کپی شد</span>
      )}
    </button>
  );
}
