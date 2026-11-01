// ------------------------------------------------------------------
// Remontada — /api/og/person/[id]  (update cycle-342)
// Dynamic share cards for the two PROFILE page families — players and
// coaches (the coach id-space rides the same FotMob person endpoint).
// Until now both surfaces shared the generic static og.png while team/
// match pages carried real crests and league pages their own cycle-341
// cards; this closes the share-card family for the entity pages too.
// Runtime rendering (profile ids are unbounded — no SSG), fonts read
// from the repo's Vazirmatn TTFs once and cached at module level.
// The card is text-only ON PURPOSE: per-person headshots were probed
// and rejected in cycle-306 (playerimages 403s for some ids — a broken
// og:image is worse than the honest brand card).
// Cache: names/teams are stable → long browser/CDN caching; a transfer
// simply refreshes within the week.
// Unknown id / non-person → 404 (the page-level wiring only points here
// on the success branch, so a miss is already an edge case).
// ------------------------------------------------------------------
import { ImageResponse } from "next/og";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { getCoachData, getPlayerData } from "@/lib/fotmob";

const ACCENT = "#2e7d32"; // the remontada green — entity cards stay on-brand

let fontsPromise: Promise<{ regular: ArrayBuffer; bold: ArrayBuffer }> | null = null;
function fonts() {
  fontsPromise ??= Promise.all([
    readFile(path.join(process.cwd(), "public/fonts/Vazirmatn-Regular.ttf")),
    readFile(path.join(process.cwd(), "public/fonts/Vazirmatn-Bold.ttf")),
  ]).then(([regular, bold]) => ({ regular: regular.buffer as ArrayBuffer, bold: bold.buffer as ArrayBuffer }));
  return fontsPromise;
}

// satori shapes Arabic letters but does not run the bidi algorithm (the
// cycle-341 lesson, probed byte-for-byte): split Persian into word spans
// laid out row-reverse so the first word lands rightmost — RTL reading
// order with real wrapping, no bidi needed.
const rtlWords = (text: string) =>
  text.split(" ").map((w, i) => (
    <span key={`w${i}`} style={{ display: "flex" }}>
      {w}
    </span>
  ));
const nameSize = (n: string) => (n.length >= 22 ? 62 : n.length >= 14 ? 80 : 96);

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!/^\d{3,12}$/.test(id)) {
    return new Response("not found", { status: 404 });
  }
  // which page is sharing? coach-people (ex-players on a bench) resolve on
  // BOTH /player/[id] and /coach/[id], so the caller declares its kind and
  // the card always matches the page it decorates. Default (no hint) = the
  // more specific classification: coach when the person isCoach, else player.
  const kind = new URL(req.url).searchParams.get("k") === "player" ? "player" : "coach";

  // satori shapes Arabic letters but does not run the bidi algorithm (the
  // cycle-341 lesson, probed byte-for-byte): split Persian into word spans
  // laid out row-reverse so the first word lands rightmost — RTL reading
  // order with real wrapping, no bidi needed. LATIN names must NOT go
  // through row-reverse (it would render «AlonsoXabi» — probed live on the
  // coach card), so they stay one plain LTR text node.
  const hasRTL = (s: string) => /[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]/.test(s);
  const rtlWords = (text: string) =>
    text.split(" ").map((w, i) => (
      <span key={`w${i}`} style={{ display: "flex" }}>
        {w}
      </span>
    ));
  const nameSize = (n: string) => (n.length >= 22 ? 62 : n.length >= 14 ? 80 : 96);

  let name = "";
  let subFa = "";
  let pillFa = "";
  let resolved = false;
  const tryCoach = async () => {
    const c = await getCoachData(id);
    const team = c.team?.fa || c.team?.name || "";
    name = c.fa || c.name;
    subFa = team ? `سرمربی ${team}` : "مربی";
    pillFa = "کارنامهٔ نیمکت و افتخارات";
    resolved = true;
  };
  const tryPlayer = async () => {
    const p = await getPlayerData(id);
    const team = p.team?.fa || p.team?.name || "";
    name = p.nameFa || p.name;
    subFa = team ? `بازیکن ${team}` : "بازیکن";
    pillFa = "پروفایل، آمار فصل و مسیر حرفه‌ای";
    resolved = true;
  };
  try {
    if (kind === "coach") {
      await tryCoach().catch(() => tryPlayer());
    } else {
      await tryPlayer().catch(() => tryCoach());
    }
  } catch (e) {
    console.error("[/api/og/person] both fetches failed", e);
  }
  if (!resolved || !name) {
    return new Response("not found", { status: 404 });
  }
  const isRTLName = hasRTL(name);

  const { regular, bold } = await fonts();
  const nameNode = isRTLName ? (
    <div
      style={{
        fontSize: nameSize(name),
        fontWeight: 700,
        color: "#ffffff",
        display: "flex",
        flexDirection: "row-reverse",
        flexWrap: "wrap",
        gap: "10px 28px",
        alignItems: "center",
      }}
    >
      {rtlWords(name)}
    </div>
  ) : (
    <div style={{ fontSize: nameSize(name), fontWeight: 700, color: "#ffffff" }}>{name}</div>
  );
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
            <div style={{ width: 18, height: 18, borderRadius: 9, backgroundColor: ACCENT }} />
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

        {/* person identity */}
        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 22 }}>
          {nameNode}
          <div
            style={{
              fontSize: 34,
              color: "#9aa3b5",
              display: "flex",
              flexDirection: "row-reverse",
              flexWrap: "wrap",
              gap: "0px 16px",
              alignItems: "center",
            }}
          >
            {rtlWords(subFa)}
          </div>
          <div
            style={{
              alignItems: "center",
              padding: "12px 28px",
              borderRadius: 999,
              border: `1px solid ${ACCENT}`,
              color: ACCENT,
              fontSize: 26,
              display: "flex",
              flexDirection: "row-reverse",
              flexWrap: "wrap",
              gap: "0px 14px",
            }}
          >
            {rtlWords(pillFa)}
          </div>
        </div>

        {/* bottom accent bar */}
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <div style={{ height: 8, width: 220, borderRadius: 4, backgroundColor: ACCENT }} />
          <div style={{ height: 8, flex: 1, borderRadius: 4, backgroundColor: "#151a26" }} />
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      headers: { "Cache-Control": "public, max-age=604800, stale-while-revalidate=86400" },
      fonts: [
        { name: "Vazirmatn", data: regular, weight: 400, style: "normal" },
        { name: "Vazirmatn", data: bold, weight: 700, style: "normal" },
      ],
    },
  );
}
