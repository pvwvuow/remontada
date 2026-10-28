// ------------------------------------------------------------------
// Remontada — Fantasy Quest backdrop (ui-quest 1)
// A fixed, pointer-less ambient layer behind the whole portal: three
// slow-drifting aurora fields + two twinkling starfields. Pure CSS
// animation (transform/opacity only) guarded by prefers-reduced-motion
// in globals.css. Presentational server component — zero JS, zero
// layout impact (z-index -1), sits between the canvas background and
// the page content so glass cards keep their backdrop blur depth.
// ------------------------------------------------------------------
export function FantasyBackdrop() {
  return (
    <div className="fx-backdrop" aria-hidden>
      <div className="fx-aurora fx-aurora-a" />
      <div className="fx-aurora fx-aurora-b" />
      <div className="fx-aurora fx-aurora-c" />
      <div className="fx-stars" />
      <div className="fx-stars fx-stars-b" />
    </div>
  );
}
