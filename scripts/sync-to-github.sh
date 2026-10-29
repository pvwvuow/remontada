#!/bin/bash
# sync-to-github.sh — ONE-WAY repo→outer homogenization (canonical copy lives
# in the repo so container recycles cannot resurrect the old direction).
#
# HISTORY: this script originally ran the OPPOSITE direction (outer→repo,
# auto-commit «auto-sync from sandbox:» + push) from the era when the outer
# sandbox workspace was the working surface. The modern rotation engine works
# directly in the repo and pushes with official prefixes, so the outer src is
# now a MIRROR. Two incidents proved the old direction is destructive:
#   - PROTOCOL-sync-direction-1 (9866915, reverted in 056d15b): after cycle-151
#     the stale outer src overwrote the live Portugal work on origin.
#   - PROTOCOL-sync-direction-2 (d6813b8, reverted in c56e9d9): container
#     recycle #14 restored the old outer script; after cycle-154 it pushed a
#     stale-outer revert that un-did the live Persian-numeral fix.
# Contract (mirror of recover-remontada.sh stage 8):
#   - copies repo → outer ONLY (rsync -a --delete), never the reverse
#   - NEVER commits, NEVER pushes — origin/main moves only via the rotation
#     engine's official «Update/Bug-hunt/Fix (cycle N):» commits
#   - keeps the freshness-gate marker text below (recovery greps for it =1)
set -u
PROJECT=/home/z/my-project
REPO=$PROJECT/remontada
LOG_TAG="[sync-github $(date '+%Y-%m-%d %H:%M:%S')]"

# ---- FRESHNESS GATE (text preserved for the recovery grep contract =1) ----
# The REPO is the authority; if its src/lib/fotmob.ts is below the modern
# portal marker (>=1200 lines) something is deeply wrong — refuse to touch
# the outer workspace and point at the official recovery script instead.
FOTMOB_LINES=$(wc -l < "$REPO/src/lib/fotmob.ts" 2>/dev/null || true)
if [ "${FOTMOB_LINES:-0}" -lt 1200 ]; then
  echo "$LOG_TAG SKIP: freshness gate tripped - repo src/lib/fotmob.ts = ${FOTMOB_LINES:-0} lines (<1200): repo is not the modern portal. Refusing to sync; run scripts/recover-remontada.sh."
  exit 0
fi

# ---- SAFETY GUARD (kept from 2026-10-28, recycle #10) ----
if [ ! -e "$REPO/src/components/remontada" ]; then
  echo "$LOG_TAG SKIP: repo src is NOT the current portal. Refusing to sync."
  exit 0
fi
[ -d "$REPO/.git" ] || { echo "$LOG_TAG ERROR: $REPO missing .git — run scripts/recover-remontada.sh"; exit 1; }

cd "$REPO" || exit 1
# only act when the repo moved since the last homogenization
REPO_HEAD=$(git rev-parse --short HEAD 2>/dev/null || echo "")
LAST_SYNCED=$(cat "$PROJECT/.last-synced-head" 2>/dev/null || echo "")
if [ -n "$REPO_HEAD" ] && [ "$REPO_HEAD" = "$LAST_SYNCED" ]; then
  echo "$LOG_TAG no changes to sync (repo @ $REPO_HEAD already homogenized)"
  exit 0
fi

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "$REPO/src/" "$PROJECT/src/"
  for f in package.json bun.lock tsconfig.json next.config.ts postcss.config.mjs tailwind.config.ts components.json eslint.config.mjs; do
    [ -f "$REPO/$f" ] && cp "$REPO/$f" "$PROJECT/$f"
  done
  [ -d "$REPO/prisma" ] && { mkdir -p "$PROJECT/prisma"; rsync -a --delete "$REPO/prisma/" "$PROJECT/prisma/"; }
  [ -d "$REPO/public/fonts" ] && { mkdir -p "$PROJECT/public/fonts"; rsync -a --delete "$REPO/public/fonts/" "$PROJECT/public/fonts/"; }
  [ -n "$REPO_HEAD" ] && echo "$REPO_HEAD" > "$PROJECT/.last-synced-head"
  echo "$LOG_TAG homogenized outer workspace from repo @ $REPO_HEAD — nothing pushed"
else
  echo "$LOG_TAG rsync unavailable — outer workspace NOT homogenized (repo stays authoritative)"
fi
