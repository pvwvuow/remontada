import { NextResponse } from "next/server";
import { getAllTopScorers } from "@/lib/fotmob";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const data = await getAllTopScorers();
    return NextResponse.json({ ok: true, ...data });
  } catch (err) {
    return NextResponse.json(
      { ok: false, error: err instanceof Error ? err.message : "fetch failed" },
      { status: 502 }
    );
  }
}
