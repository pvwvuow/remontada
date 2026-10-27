// ------------------------------------------------------------------
// Remontada — JSON-LD structured data (schema.org)
// Universal component: no "use client" — renders where it is imported,
// so server components can emit the script straight into the SSR HTML
// and client components keep using it after their data arrives
// (Google renders JS either way). Improvement of cycle-16 bug #8.
// ------------------------------------------------------------------
export function JsonLd({ data }: { data: Record<string, unknown> | null }) {
  if (!data) return null;
  return (
    <script
      type="application/ld+json"
      // structured data is machine-readable only — safe to inline as-is
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}
