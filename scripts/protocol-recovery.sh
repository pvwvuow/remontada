#!/usr/bin/env bash
# scripts/protocol-recovery.sh — بازیافت کامل محلی رمانتادا (داخل مخزن، ماندگار روی گیت‌هاب)
# کاربرد وقتی کانتینر/اسنپ‌شاتِ گیرکرده، مخزن محلی را به عقب برگردانده یا سرور مرده است.
# از هر حالت کلونی قابل اجراست؛ حتی از کلون کهنه:
#   git -C /home/z/my-project/remontada fetch origin && \
#   git show origin/main:scripts/protocol-recovery.sh > /tmp/pr.sh && bash /tmp/pr.sh
set -uo pipefail
REPO=/home/z/my-project/remontada
TOKEN_FILE=/home/z/my-project/scripts/remote-token.txt
LOG_TAG="[protocol-recovery $(date '+%Y-%m-%d %H:%M:%S')]"

code() { curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 2>/dev/null; }

# 0) خود را به /tmp کپی کن تا جابه‌جایی دایرکتوری مخزن اجرا را نشکند
if [ "${1:-}" != "--from-tmp" ]; then
  cp "$0" /tmp/protocol-recovery.sh 2>/dev/null || true
  exec bash /tmp/protocol-recovery.sh --from-tmp
fi

TOKEN=$(tr -d '\r\n ' < "$TOKEN_FILE" 2>/dev/null || true)
[ -n "$TOKEN" ] || { echo "$LOG_TAG FATAL: token file missing"; exit 1; }

ORIGIN_HEAD=$(git -C "$REPO" ls-remote "https://${TOKEN}@github.com/pvwvuow/remontada" main 2>/dev/null | cut -f1)
[ -n "$ORIGIN_HEAD" ] || { echo "$LOG_TAG FATAL: cannot read origin/main"; exit 1; }
LOCAL_HEAD=$(git -C "$REPO" rev-parse HEAD 2>/dev/null || echo none)
echo "$LOG_TAG origin=$ORIGIN_HEAD local=$LOCAL_HEAD"

# 1) اگر مخزن محلی عقب/کهنه است: کلون تازه (خود اسکریپت از /tmp اجرا می‌شود)
if [ "$LOCAL_HEAD" != "$ORIGIN_HEAD" ]; then
  cd /home/z/my-project
  [ -d "$REPO" ] && mv "$REPO" "remontada.stale-$(date +%Y%m%d-%H%M%S)"
  git clone -q "https://${TOKEN}@github.com/pvwvuow/remontada" remontada || { echo "$LOG_TAG FATAL: clone failed"; exit 1; }
  echo "$LOG_TAG fresh clone done"
fi
cd "$REPO"
git config user.name "Z User"; git config user.email "z@container"
echo 'DATABASE_URL="file:./dev.db"' > .env

# 2) وابستگی + دیتابیس + بیلد
bun install --frozen-lockfile 2>&1 | tail -1
DATABASE_URL="file:./dev.db" bunx prisma db push 2>&1 | grep -iE "sync" | tail -1
bunx prisma generate 2>&1 | grep -c "Generated" >/dev/null && echo "$LOG_TAG prisma client OK"
bun run build 2>&1 | tail -1

# 3) استارت رسمی: پاک‌سازی شنوندهٔ :3000 و next start با DATABASE_URL صریح
export DATABASE_URL="file:./dev.db"
if command -v fuser >/dev/null 2>&1; then fuser -k 3000/tcp >/dev/null 2>&1; else
  for p in $(ss -ltnp 2>/dev/null | grep ':3000' | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u); do kill "$p" 2>/dev/null; done
fi
sleep 2
nohup bunx next start -p 3000 > /home/z/my-project/remontada-server.log 2>&1 &
echo "$LOG_TAG started pid=$!"
for i in $(seq 1 20); do sleep 3; C=$(code); echo "$LOG_TAG try=$i HTTP=$C"; [ "$C" = "200" ] && break; done
[ "$(code)" = "200" ] || { echo "$LOG_TAG FATAL: server not 200"; tail -20 /home/z/my-project/remontada-server.log; exit 1; }

# 4) رگرسیون رسمی
BASE=http://localhost:3000 bash scripts/cycle17-regression.sh 2>&1 | tail -3
echo "$LOG_TAG RECOVERY COMPLETE"
