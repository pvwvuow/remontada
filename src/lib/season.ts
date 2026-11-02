// Remontada — season-param contract, dependency-free on purpose.
// -----------------------------------------------------------------
// cycle-99: this lives in its own client-safe module so the UI and the API
// guard the SAME regex ("one regex, one contract"). fotmob.ts re-exports it
// for the API routes; league-view imports it directly because a value import
// from fotmob.ts would drag the whole server graph (cache → db → prisma)
// into the client bundle (caught by the cycle-99 build: module-not-found at
// db.ts under [Client Component SSR]).

// Strict "YYYY/YYYY" shape, both years 19xx/20xx — the only shape the
// standings / league-fixtures / league-bracket APIs accept (cycle-55) and
// the only shape the league page's deep-link seeding accepts (cycle-99).
export const SEASON_PARAM_RE = /^(19|20)\d{2}\/(19|20)\d{2}$/;
