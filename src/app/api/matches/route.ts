import { NextRequest, NextResponse } from "next/server";
import { getMatchesByDate, dateKeyToYYYYMMDD } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const offsetRaw = req.nextUrl.searchParams.get("offset") || "0";
  let offset = parseInt(offsetRaw, 10);
  if (!Number.isFinite(offset)) offset = 0;
  if (offset < -7) offset = -7;
  if (offset > 7) offset = 7;

  try {
    const date = dateKeyToYYYYMMDD(offset);
    const data = await getMatchesByDate(date);
    return NextResponse.json({
      ok: true,
      date,
      offset,
      groups: data.groups,
      source: data.source,
      fetchedAt: data.fetchedAt,
    });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "fetch failed" },
      { status: 502 }
    );
  }
}
