// cycle-334: unit proof of the resolveSiteUrl chain (the F1 fix — dead
// canonical domain). Pure-function assertions over the exact env shapes
// that matter in the field. Run: bun scripts/test-site-url.ts
import { resolveSiteUrl } from "../src/lib/site";

const cases: Array<
  [Record<string, string | undefined>, string, string]
> = [
  [
    {},
    "https://remontada.vercel.app",
    "no env at all — sandbox default unchanged (zero local regression)",
  ],
  [
    { NEXT_PUBLIC_SITE_URL: "" },
    "https://remontada.vercel.app",
    "empty override falls through (pre-334 `||` parity)",
  ],
  [
    { NEXT_PUBLIC_SITE_URL: "https://example.com/" },
    "https://example.com",
    "explicit override wins, trailing slash stripped (pre-334 behavior)",
  ],
  [
    {
      VERCEL_ENV: "preview",
      VERCEL_PROJECT_PRODUCTION_URL: "remontada-git-main-pvwvuow.vercel.app",
    },
    "https://remontada.vercel.app",
    "preview build never leaks an ephemeral domain into canonicals",
  ],
  [
    {
      VERCEL_ENV: "production",
      VERCEL_PROJECT_PRODUCTION_URL: "remontada-pvwvuow.vercel.app",
    },
    "https://remontada-pvwvuow.vercel.app",
    "stable production domain picked up and normalized to https://",
  ],
  [
    { VERCEL_ENV: "production", VERCEL_URL: "remontada-abc123.vercel.app" },
    "https://remontada-abc123.vercel.app",
    "per-deployment VERCEL_URL fallback",
  ],
  [
    {
      VERCEL_ENV: "production",
      VERCEL_PROJECT_PRODUCTION_URL: "https://custom.example/",
      VERCEL_URL: "remontada-abc123.vercel.app",
    },
    "https://custom.example",
    "PROJECT url beats VERCEL_URL; protocol + slash stripped",
  ],
  [
    {
      NEXT_PUBLIC_SITE_URL: "https://x.com",
      VERCEL_ENV: "production",
      VERCEL_PROJECT_PRODUCTION_URL: "y.vercel.app",
    },
    "https://x.com",
    "explicit operator override beats Vercel injection",
  ],
];

let pass = 0;
for (const [env, want, why] of cases) {
  const got = resolveSiteUrl(env);
  const ok = got === want;
  console.log(`${ok ? "PASS" : "FAIL"}  ${why}  →  ${got}`);
  if (ok) pass += 1;
}
console.log(`\n${pass}/${cases.length} resolveSiteUrl cases OK`);
if (pass !== cases.length) process.exit(1);
