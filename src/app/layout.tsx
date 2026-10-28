import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
import { PwaRegister } from "@/components/remontada/pwa-register";
import { NavDock } from "@/components/remontada/nav-dock";
import { FantasyBackdrop } from "@/components/remontada/fantasy-backdrop";
import { PortalGate } from "@/components/remontada/portal-gate";
import { JsonLd } from "@/components/remontada/json-ld";
import { SITE_URL, SITE_NAME } from "@/lib/site";

// ---- site-identity structured data (cycle 29) ------------------------------
// Emitted sitewide from the root layout so every page (including the
// client-rendered home) carries WebSite + Organization identity for crawlers.
const SITE_LD: Record<string, unknown> = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebSite",
      "@id": `${SITE_URL}/#website`,
      "name": SITE_NAME,
      "alternateName": "Remontada",
      "url": SITE_URL,
      "inLanguage": "fa-IR",
    },
    {
      "@type": "Organization",
      "@id": `${SITE_URL}/#org`,
      "name": SITE_NAME,
      "url": SITE_URL,
      "logo": `${SITE_URL}/icons/icon-512.png`,
    },
  ],
};

const vazir = localFont({
  src: [
    { path: "../../public/fonts/Vazirmatn-Regular.woff2", weight: "400", style: "normal" },
    { path: "../../public/fonts/Vazirmatn-Bold.woff2", weight: "700", style: "normal" },
    { path: "../../public/fonts/Vazirmatn-Black.woff2", weight: "900", style: "normal" },
  ],
  variable: "--font-vazir",
  display: "swap",
});

const TITLE_DEFAULT = `${SITE_NAME} | نتایج زنده فوتبال، جدول لیگ‌ها و اخبار`;
const DESCRIPTION =
  "رمانتادا — مرجع فارسی نتایج زنده فوتبال: امتیاز لحظه‌ای بازی‌ها، جدول رده‌بندی لیگ‌های معتبر جهان و لیگ خلیج فارس، آقای گلان و اخبار داغ فوتبال. Live football scores, standings & news.";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: TITLE_DEFAULT,
    template: `%s | ${SITE_NAME}`,
  },
  description: DESCRIPTION,
  keywords: [
    "نتایج زنده فوتبال", "نتیجه زنده", "جدول لیگ", "آقای گل", "فوتبال", "رمانتادا",
    "لیگ خلیج فارس", "پریمیرلیگ", "لالیگا", "لیگ قهرمانان", "live score", "football",
  ],
  applicationName: SITE_NAME,
  manifest: "/manifest.webmanifest",
  alternates: { canonical: "/" },
  openGraph: {
    title: TITLE_DEFAULT,
    description: DESCRIPTION,
    type: "website",
    locale: "fa_IR",
    siteName: SITE_NAME,
    url: SITE_URL,
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "رمانتادا — نتایج زنده فوتبال",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE_DEFAULT,
    description: DESCRIPTION,
    images: ["/og.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true, "max-image-preview": "large" },
  },
  icons: {
    icon: [
      { url: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [{ url: "/icons/apple-touch-icon.png", sizes: "180x180" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#0a1119",
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
        <JsonLd data={SITE_LD} />
        <FantasyBackdrop />
        {children}
        <NavDock />
        <PortalGate />
        <Toaster />
        <PwaRegister />
      </body>
    </html>
  );
}
