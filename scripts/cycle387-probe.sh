#!/usr/bin/env bash
# cycle387-probe.sh — pre-fix live probe for the فیکس 387 (the 386 findings).
# P1 the multi-day day-feed window offset -2..+2: the EXACT recurring raw
#    IRANIAN Azadegan team names (union + per-day presence) — the fix keys.
# P2 the same window's raw league headers (name|ccode, per-day presence) —
#    families (suffix-composable) vs one-offs — the structural decision data.
# P3 otherRaw scale per day (documented, unmapped — never claimed zero).
# P4 which candidate keys ALREADY exist in src/lib/leagues.ts (dedupe guard).
#
# probe lessons applied: heredoc python rides a temp file (the 386 subclass:
# parentheses in an unquoted heredoc nested in $() are parser-counted);
# pipe-separated outputs everywhere (the double-JSON tr trap).
set -u
BASE=http://localhost:3000
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
PY=/tmp/c387_probe.py
cat > "$PY" <<'EOF'
import json, sys, re
off = sys.argv[1]
d = json.load(sys.stdin)
gs = d.get('groups') or []
irn = set(); rawH = []; other = 0; total = 0
for g in gs:
    lgname = g.get('leagueName') or ''
    if (g.get('leagueFa') or '') == lgname and lgname:
        rawH.append((lgname, g.get('ccode') or ''))
    n_irn = set(); n_other = set()
    for m in (g.get('matches') or []):
        for k in ('home', 'away'):
            v = m.get(k) or {}
            n = v.get('name') or ''
            total += 1
            if n and (v.get('fa') or '') == n:
                if (g.get('ccode') or '') == 'IRN': n_irn.add(n)
                else: n_other.add(n)
    irn |= n_irn; other += len(n_other)
print(f"OFF={off} groups={len(gs)} rawHeaders={len(rawH)} irnRaw={len(irn)} otherRawTeams={other}")
for n, c in rawH: print(f"HDR | {n} | {c}")
for n in sorted(irn): print(f"IRN | {n}")
EOF

echo "=== P1/P2/P3: day-feed window offset -2..+2 ==="
for O in -2 -1 0 1 2; do
  api "/api/matches?offset=$O" | python3 "$PY" "$O"
done | tee /tmp/c387_window.txt

echo
echo "=== P1b: IRN raw union across the window ==="
grep '^IRN | ' /tmp/c387_window.txt | sed 's/^IRN | //' | sort -u | tee /tmp/c387_irn.txt

echo
echo "=== P2b: header families vs one-offs (union with day-presence counts) ==="
grep '^HDR | ' /tmp/c387_window.txt | sed 's/^HDR | //' | sort | uniq -c | sort -rn | tee /tmp/c387_hdr.txt

echo
echo "=== P4: candidate keys already present in leagues.ts? ==="
while IFS= read -r N; do
  K=$(printf '%s' "$N" | tr '[:upper:]' '[:lower:]' | sed 's/[.*+?^${}()|[\]\\]/\\&/g')
  if grep -qE "\"$K\"" src/lib/leagues.ts; then echo "EXISTS | $N"; else echo "MISSING | $N"; fi
done < /tmp/c387_irn.txt
echo "--- header keys ---"
cut -d'|' -f2 /tmp/c387_hdr.txt | sed 's/^ //;s/ $//' | while IFS= read -r N; do
  K=$(printf '%s' "$N" | tr '[:upper:]' '[:lower:]' | sed 's/[.*+?^${}()|[\]\\]/\\&/g')
  if grep -qF "\"$K" src/lib/leagues.ts; then echo "EXISTS | $N"; else echo "MISSING | $N"; fi
done
