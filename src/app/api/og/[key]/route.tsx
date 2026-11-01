// ------------------------------------------------------------------
// Remontada — /api/og/[key]  (update cycle-341)
// Dynamic per-league share cards (1200×630), rendered at BUILD time via
// next/og (satori + resvg, bundled with Next 16 — zero new deps). It
// replaces the generic static og.png on the two league-keyed share
// surfaces (the league page + the topscorers page) so a shared league
// card now carries the competition's own name and colour instead of the
// site-wide default card. Persian text uses the repo's own Vazirmatn
// TTFs (satori reads TTF/OTF only — the woff2 originals stay untouched;
// the build script copies public/ into the standalone output so the
// runtime fs read works in dev, prod and standalone alike).
// Unknown keys → hard 404 (dynamicParams=false), the same contract as
// the topscorers page.
// ------------------------------------------------------------------
import { ImageResponse } from "next/og";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { LEAGUES } from "@/lib/leagues";

export const dynamicParams = false;

export async function generateStaticParams() {
  return LEAGUES.map((l) => ({ key: l.key }));
}

// one accent per competition — the card's single colour hint
const ACCENT: Record<string, string> = {
  ucl: "#1b3fae",
  pl: "#3d195b",
  laliga: "#ee8707",
  seriea: "#0b1560",
  bundesliga: "#d20515",
  ligue1: "#12325c",
  persiangulf: "#239f40",
  uel: "#ff6900",
  uecl: "#00a0df",
  acl: "#c8102e",
  superlig: "#e30a17",
  scottish: "#1d428a",
};

export async function GET(_req: Request, { params }: { params: Promise<{ key: string }> }) {
  const { key } = await params;
  const lg = LEAGUES.find((l) => l.key === key);
  const faName = lg?.faName || "رمانتادا";
  const enName = lg?.enName || "Football live scores";
  const accent = ACCENT[key] || "#2e7d32";

  // satori shapes Arabic letters correctly but does NOT run the bidi
  // algorithm (direction:"rtl" is a no-op in this bundle — byte-identical
  // output probed), so multi-word Persian renders in LTR word order.
  // Deterministic fix: split into word spans and lay them out in a
  // row-reverse flex — the first word lands on the right, exactly the RTL
  // reading order, with flexWrap giving real RTL paragraph wrapping.
  const rtlWords = (text: string) =>
    text.split(" ").map((w, i) => (
      <span key={`w${i}`} style={{ display: "flex" }}>
        {w}
      </span>
    ));
  const faSize = faName.length >= 17 ? 58 : faName.length >= 13 ? 76 : 96;

  const [regular, bold] = await Promise.all([
    readFile(path.join(process.cwd(), "public/fonts/Vazirmatn-Regular.ttf")),
    readFile(path.join(process.cwd(), "public/fonts/Vazirmatn-Bold.ttf")),
  ]);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "56px 64px",
          backgroundColor: "#05070d",
          backgroundImage:
            "radial-gradient(circle at 85% 15%, rgba(46,125,50,0.16) 0%, rgba(5,7,13,0) 55%), radial-gradient(circle at 10% 90%, rgba(46,125,50,0.10) 0%, rgba(5,7,13,0) 45%)",
        }}
      >
        {/* top brand row */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <div style={{ width: 18, height: 18, borderRadius: 9, backgroundColor: accent }} />
            <div style={{ fontSize: 40, fontWeight: 700, color: "#ffffff" }}>رمانتادا</div>
          </div>
          <div
            style={{
              fontSize: 24,
              color: "#8b93a7",
              display: "flex",
              flexDirection: "row-reverse",
              flexWrap: "wrap",
              gap: "0px 18px",
              alignItems: "center",
            }}
          >
            {rtlWords("نتایج زنده فوتبال")}
          </div>
        </div>

        {/* league identity */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 22 }}>
          <div
            style={{
              fontSize: faSize,
              fontWeight: 700,
              color: "#ffffff",
              display: "flex",
              flexDirection: "row-reverse",
              flexWrap: "wrap",
              gap: "10px 28px",
              alignItems: "center",
            }}
          >
            {rtlWords(faName)}
          </div>
          <div style={{ fontSize: 32, color: "#9aa3b5" }}>{enName}</div>
          <div
            style={{
              alignItems: "center",
              padding: "12px 28px",
              borderRadius: 999,
              border: `1px solid ${accent}`,
              color: accent,
              fontSize: 26,
              display: "flex",
              flexDirection: "row-reverse",
              flexWrap: "wrap",
              gap: "0px 14px",
            }}
          >
            {rtlWords("جدول، نتایج و آقای گلان")}
          </div>
        </div>

        {/* bottom accent bar */}
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <div style={{ height: 8, width: 220, borderRadius: 4, backgroundColor: accent }} />
          <div style={{ height: 8, flex: 1, borderRadius: 4, backgroundColor: "#151a26" }} />
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      fonts: [
        { name: "Vazirmatn", data: regular, weight: 400, style: "normal" },
        { name: "Vazirmatn", data: bold, weight: 700, style: "normal" },
      ],
    },
  );
}
