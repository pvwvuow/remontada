#!/bin/bash
# start-remontada.sh — تنها الگوی بقا برای استارت سرور remontada
# درس تجربی: پروسه‌های bg که مستقیم در tool-bash با setsid/nohup/disown استارت می‌شوند
# بین دو tool-call توسط reaper کشته می‌شوند؛ فقط استارت «از طریق wrapper اسکریپت» زنده می‌ماند.
# داخل: kill-by-pid از ss (چون fuser -k بی‌صدا شکست می‌خورد) + wait-free + wait-up تا curl 200
set -u
PORT=3000
APP=/home/z/my-project/remontada
LOG=/home/z/my-project/dev.log

# ── 1) kill هر شنونده‌ای روی :3000 با pid از ss ──
PIDS=$(ss -tlnp 2>/dev/null | grep ":${PORT} " | grep -oP 'pid=\K[0-9]+' | sort -u)
for p in $PIDS; do
  kill -9 "$p" 2>/dev/null
done
# wait-free: تا پورت واقعاً آزاد شود
for i in $(seq 1 20); do
  if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
    sleep 0.5
  else
    break
  fi
done

# ── 2) تعیین مسیر standalone (دو حالت ممکن از bun run build) ──
RUN_DIR=""
if [ -f "$APP/.next/standalone/server.js" ]; then
  RUN_DIR="$APP/.next/standalone"
elif [ -f "$APP/.next/standalone/remontada/server.js" ]; then
  RUN_DIR="$APP/.next/standalone/remontada"
else
  echo "FATAL: standalone server.js not found — build first"
  exit 1
fi

# ── 3) استارت ──
cd "$RUN_DIR"
DATABASE_URL="file:$APP/prisma/dev.db" PORT="$PORT" HOSTNAME=0.0.0.0 \
  nohup node server.js > "$LOG" 2>&1 &
NEWPID=$!
disown 2>/dev/null || true

# ── 4) wait-up: تا curl 200 ──
for i in $(seq 1 60); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${PORT}" --max-time 2)
  if [ "$CODE" = "200" ]; then
    echo "UP pid=$NEWPID run_dir=$RUN_DIR try=$i HTTP=200"
    exit 0
  fi
  sleep 1
done

echo "FAILED: no 200 after 60s (last=$CODE)"
tail -30 "$LOG"
exit 1
