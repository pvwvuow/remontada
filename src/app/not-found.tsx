import Link from "next/link";

// Persian 404 page — covers unknown /league/[key], /topscorers/[leagueKey]
// and any other unmatched route.
export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-4 text-center">
      <p className="text-6xl font-black text-primary tabular-persian" aria-hidden>
        ۴۰۴
      </p>
      <h1 className="mt-3 text-lg font-black">صفحه‌ای که دنبالش بودی پیدا نشد</h1>
      <p className="mt-2 text-sm text-muted-foreground max-w-sm leading-6">
        ممکن است نشانی را اشتباه وارد کرده باشی یا این بخش جابه‌جا شده باشد. از دکمه‌های زیر به
        مسیرهای اصلی پرتال برگرد.
      </p>
      <div className="mt-5 flex items-center gap-2.5 flex-wrap justify-center">
        <Link
          href="/"
          className="inline-flex items-center gap-1.5 rounded-lg bg-primary text-primary-foreground text-[13px] font-black px-4 py-2.5 hover:opacity-90 transition-opacity"
        >
          صفحه اصلی
        </Link>
        <Link
          href="/leagues"
          className="inline-flex items-center gap-1.5 rounded-lg border border-border text-[13px] font-black px-4 py-2.5 text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
        >
          لیگ‌ها
        </Link>
        <Link
          href="/topscorers"
          className="inline-flex items-center gap-1.5 rounded-lg border border-border text-[13px] font-black px-4 py-2.5 text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
        >
          گلزنان
        </Link>
      </div>
    </div>
  );
}
