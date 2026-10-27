import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const vazir = localFont({
  src: [
    { path: "../../public/fonts/Vazirmatn-Regular.woff2", weight: "400", style: "normal" },
    { path: "../../public/fonts/Vazirmatn-Bold.woff2", weight: "700", style: "normal" },
    { path: "../../public/fonts/Vazirmatn-Black.woff2", weight: "900", style: "normal" },
  ],
  variable: "--font-vazir",
  display: "swap",
});

export const metadata: Metadata = {
  title: "رمانتادا | نتایج زنده فوتبال، جدول لیگ‌ها و اخبار",
  description:
    "رمانتادا — مرجع نتایج زنده فوتبال: امتیاز لحظه‌ای بازی‌ها، جدول رده‌بندی لیگ‌های معتبر جهان و لیگ خلیج فارس، اخبار داغ فوتبال world. Live football scores, standings & news.",
  keywords: ["نتایج زنده فوتبال", "نتیجه زنده", "جدول لیگ", "فوتبال", "رمانتادا", "live score", "football"],
  openGraph: {
    title: "رمانتادا | نتایج زنده فوتبال",
    description: "نتایج زنده، جدول لیگ‌ها و اخبار فوتبال جهان و ایران",
    type: "website",
    locale: "fa_IR",
  },
};

export const viewport: Viewport = {
  themeColor: "#0d1412",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fa" dir="rtl" suppressHydrationWarning>
      <body className={`${vazir.variable} antialiased bg-background text-foreground font-sans`}>
        {children}
        <Toaster />
      </body>
    </html>
  );
}
