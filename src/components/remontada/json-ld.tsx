"use client";

// ------------------------------------------------------------------
// Remontada — JSON-LD structured data injector (schema.org)
// Renders a <script type="application/ld+json"> tag once the parent
// client component has its data (Google renders JS and reads it).
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
