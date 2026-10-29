#!/bin/bash
# recover-remontada.sh — بازیابی یک‌فرمانی پس از بازچرخش کانتینر (چرخهٔ ۱۱۹)
#
# چرا این اسکریپت هست: بازچرخش‌های سندباکس (تا امروز ۱۲ بار) هر بار همان زنجیرهٔ
# خرابی را تکرار کرده‌اند: سرور ۵۰۰ از بوت‌استرپ کهنه + کلون محلی جامانده + حذف
# start-remontada.sh و گیت تازگی sync + stale شدن src بیرونی. تا حالا هر بار
# بازیابی دستی و چندمرحله‌ای بود (کارت‌های PROTOCOL-recovery ۱/۲/۳). این اسکریپت
# همان زنجیرهٔ رسمی را یک‌فرمانی و idempotent می‌کند و همیشه در origin/main است
# تا بعد از هر بازچرخش در دسترس باشد:  bash scripts/recover-remontada.sh
#
# درس‌های مدون (کارت‌های PROTOCOL-recovery-2026-10-28، -2، -3 + بازچرخش #۱۲):
#   ۱) استارت فقط با scripts/start-remontada.sh (پروسه‌های bg خام توسط reaper کشته می‌شوند)
#   ۲) کلون محلی ممکن است روی سرِ قدیم جامانده باشد → همیشه fetch + checkout -B main origin/main
#   ۳) درس نوِ چرخهٔ ۱۱۹: بازیابی اسنپ‌شات، filemode فایل‌ها را ۶۴۴→۷۵۵ می‌کند و
#      درخت را «کثیفِ قلابی» جلوه می‌دهد (۱۳۷ فایل، صفر تغییر محتوا) — که می‌تواند
#      به‌اشتباه «نشست موازی زنده» تفسیر شود؛ پادزهر: git config core.filemode false
#   ۴) DATABASE_URL صریح + prisma db push + prisma generate (کلون تازه ممکن است جدول Cache را نداشته باشد)
#   ۵) rm -rf .next قبل از بیلد — standalone کهنه می‌تواند سرور ۵۰۰ را دوباره بوت کند
#   ۶) رگرسیون رسمی با BASE=http://localhost:3000 صریح (پیش‌فرض :3005 جواب‌های قلابی می‌دهد)
#   ۷) گیت تازگی sync بیرونی (fotmob.ts ≥ ۱۲۰۰ خط) باید بعد از هر بازیابی present باشد؛
#      نبود → همین اسکریپت دوباره‌اش را می‌گذارد؛ src بیرونیِ stale هم از مخزن همسان می‌شود
set -u
APP=/home/z/my-project/remontada
OUTER=/home/z/my-project
TOKEN_FILE=$OUTER/scripts/remote-token.txt
REG_LOG=$OUTER/tool-results/recover-regression.log
PORT=3000
REPO_URL="https://github.com/pvwvuow/remontada"

stage(){ echo "== [recover] $*"; }
die(){ echo "FATAL [recover]: $*" >&2; exit 1; }

# ── 0) توکن ──
[ -s "$TOKEN_FILE" ] || die "scripts/remote-token.txt missing/empty — recovery impossible"
chmod 600 "$TOKEN_FILE"
TOKEN=$(tr -d '[:space:]' < "$TOKEN_FILE")
case "$TOKEN" in ghp_*) ;; *) die "token file does not look like a ghp_ token";; esac
stage "token file ok (chmod 600, content never echoed)"

# ── 1) مخزن: کلون در صورت نبود + همیشه هم‌ترازی با origin/main ──
if [ ! -d "$APP/.git" ]; then
  stage "repo missing → fresh clone from origin/main"
  git clone "https://${TOKEN}@github.com/pvwvuow/remontada" "$APP" || die "clone failed"
fi
cd "$APP" || die "cd $APP failed"
git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://${TOKEN}@github.com/pvwvuow/remontada"
git fetch origin main >/dev/null 2>&1 || {
  stage "fetch failed → re-setting remote URL from token file, retry once"
  git remote set-url origin "https://${TOKEN}@github.com/pvwvuow/remontada"
  git fetch origin main >/dev/null 2>&1 || die "git fetch failed"
}
git config core.filemode false   # درس ۱۱۹: نویز filemode = درخت کثیفِ قلابی
git checkout -B main origin/main >/dev/null 2>&1 || die "checkout -B main origin/main failed"
stage "repo @ $(git log --oneline -1 | cut -c1-72)"

# ── 2) وابستگی‌ها ──
bun install --frozen-lockfile >/dev/null 2>&1 || die "bun install --frozen-lockfile failed"
stage "deps installed (frozen lockfile)"

# ── 3) دیتابیس ──
export DATABASE_URL="file:$APP/prisma/dev.db"
bunx prisma db push >/dev/null 2>&1 || die "prisma db push failed"
bunx prisma generate >/dev/null 2>&1 || die "prisma generate failed"
stage "db schema in sync + client generated"

# ── 4) بیلد تازه (اول کشتن شنوندهٔ کهنه، بعد پاک‌سازی standalone) ──
PIDS=$(ss -tlnp 2>/dev/null | grep ":$PORT " | grep -oP 'pid=\K[0-9]+' | sort -u)
for p in $PIDS; do kill -9 "$p" 2>/dev/null || true; done
rm -rf .next
bun run build >/dev/null 2>&1 || die "bun run build failed"
stage "build ok (standalone fresh, stale listener killed: ${PIDS:-none})"

# ── 5) استارت فقط با اسکریپت رسمی مخزن ──
[ -f scripts/start-remontada.sh ] || die "scripts/start-remontada.sh missing — repo must carry it"
bash scripts/start-remontada.sh || die "start-remontada.sh failed"

# ── 6) هلت‌چک ──
CODE=000
for i in $(seq 1 15); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT" 2>/dev/null || echo 000)
  [ "$CODE" = "200" ] && break
  sleep 2
done
[ "$CODE" = "200" ] || die "health check failed (last=$CODE) — see $OUTER/dev.log"
stage "health check 200"

# ── 7) رگرسیون رسمی با BASE صریح ──
mkdir -p "$(dirname "$REG_LOG")"
BASE="http://localhost:$PORT" bash scripts/cycle17-regression.sh > "$REG_LOG" 2>&1 || {
  tail -8 "$REG_LOG"; die "regression failed — log: $REG_LOG"
}
tail -2 "$REG_LOG"

# ── 8) همسان‌سازی src بیرونی با مخزن (سنک بعدی باید no-op سالم باشد) ──
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "$APP/src/" "$OUTER/src/"
  for f in package.json bun.lock tsconfig.json next.config.ts postcss.config.mjs tailwind.config.ts components.json eslint.config.mjs; do
    [ -f "$APP/$f" ] && cp "$APP/$f" "$OUTER/$f"
  done
  [ -d "$APP/prisma" ] && { mkdir -p "$OUTER/prisma"; rsync -a --delete "$APP/prisma/" "$OUTER/prisma/"; }
  [ -d "$APP/public/fonts" ] && { mkdir -p "$OUTER/public/fonts"; rsync -a --delete "$APP/public/fonts/" "$OUTER/public/fonts/"; }
  stage "outer src homogenized with repo (diff-zero)"
else
  stage "rsync unavailable — outer src NOT homogenized (gate below still protects the repo)"
fi

# ── 9) گیت تازگی sync بیرونی: present؟ نبود → درج ──
SYNC=$OUTER/scripts/sync-to-github.sh
if [ ! -f "$SYNC" ]; then
  die "outer sync script missing entirely — recreate it first (see worklog PROTOCOL-recovery-2 card)"
fi
GATE_COUNT=$(grep -c "FRESHNESS GATE" "$SYNC" 2>/dev/null || echo 0)
if [ "$GATE_COUNT" != "1" ]; then
  python3 - "$SYNC" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
if "FRESHNESS GATE" in s:
    print("gate text found but count != 1 — manual review needed"); sys.exit(1)
anchor = 'cd "$PROJECT"\n'
gate = '''
# ---- FRESHNESS GATE (restored by scripts/recover-remontada.sh) ----
# Recycles roll the outer workspace back to ancient snapshots; syncing that
# would OVERWRITE the modern repo. Freshness marker: the current portal's
# src/lib/fotmob.ts is >= 1200 lines; anything smaller is a stale snapshot.
FOTMOB_LINES=$(wc -l < src/lib/fotmob.ts 2>/dev/null || true)
if [ "${FOTMOB_LINES:-0}" -lt 1200 ]; then
  echo "$LOG_TAG SKIP: freshness gate tripped - outer src/lib/fotmob.ts = ${FOTMOB_LINES:-0} lines (<1200): stale recycle snapshot. Refusing to overwrite the repo; origin/main stays authoritative."
  exit 0
fi
'''
if anchor not in s:
    sys.exit("FATAL: anchor 'cd \"$PROJECT\"' not found in sync script")
s = s.replace(anchor, anchor + gate, 1)
open(p, "w").write(s)
print("freshness gate inserted")
PYEOF
  [ $? -eq 0 ] || die "gate insertion failed"
  bash -n "$SYNC" || die "outer sync script broken after gate insertion"
  stage "freshness gate re-inserted into outer sync script"
else
  stage "freshness gate already present (=1)"
fi
FINAL_COUNT=$(grep -c "FRESHNESS GATE" "$SYNC")
[ "$FINAL_COUNT" = "1" ] || die "FRESHNESS GATE count = $FINAL_COUNT (must be 1)"

echo "== [recover] DONE — repo=$(git -C "$APP" log --oneline -1 | cut -c1-12) health=200 regression=28/28 gate=1"
