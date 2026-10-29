#!/bin/bash
# cycle-153 bug-hunt LIVE-TRUTH probe (D5: assertions follow live truth probed
# 2026-10-29, before the hunt gates are written). Targets: the three NEWEST
# league surfaces — championship (150) / portugal (151) / uae (152).
set -u
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
B=http://localhost:3000
j() { curl -s -A "$UA" "$1"; }

echo "== standings (rows / top3 fa+pts) =="
for LK in championship portugal uae; do
  j "$B/api/standings?league=$LK" | python3 -c "
import json,sys
d=json.load(sys.stdin); rows=d.get('rows') or []
print('$LK', 'rows=',len(rows))
for r in rows[:3]: print('   ', r.get('fa'), r.get('pts') if 'pts' in r else r.get('points'), '| keys:', sorted(r.keys())[:8])
"
done

echo "== uae team id for V9 (rows[0] full) =="
j "$B/api/standings?league=uae" | python3 -c "
import json,sys
d=json.load(sys.stdin); rows=d.get('rows') or []
for r in rows[:3]: print(json.dumps(r, ensure_ascii=False)[:220])
"

echo "== global race =="
j "$B/api/topscorers?league=all" | python3 -c "
import json,sys
d=json.load(sys.stdin); ts=d.get('scorers') or []; pl=[p.get('leagueKey') for p in (d.get('perLeague') or [])]
print('scorers=',len(ts),' perLeague=',len(pl), sorted(pl))
t=ts[0] if ts else {}; print('leader:', t.get('nameFa'), t.get('goals'), t.get('team'))
"

echo "== dedicated topscorers =="
for LK in championship portugal uae; do
  j "$B/api/topscorers/$LK" | python3 -c "
import json,sys
d=json.load(sys.stdin); ts=d.get('scorers') or []
t=ts[0] if ts else {}
print('$LK n=',len(ts),' top=',t.get('nameFa'),'(',t.get('goals'),') team=',t.get('team'))
for t in ts[:3]: print('   ', t.get('nameFa'), t.get('goals'), t.get('team'))
"
done

echo "== bracket null (six portal leagues) =="
for LK in superlig scottish saudi championship portugal uae; do
  j "$B/api/league-bracket?league=$LK" | python3 -c "
import json,sys; d=json.load(sys.stdin); print('$LK ok=',d.get('ok'),'bracket=',d.get('bracket'))"
done

echo "== transfers feeds =="
for LK in championship portugal uae; do
  j "$B/api/league-transfers?league=$LK" | python3 -c "
import json,sys
d=json.load(sys.stdin); items=d.get('items') or d.get('transfers') or []
print('$LK ok=',d.get('ok'),' n=',len(items), ' keys=', list(d.keys())[:6])
"
done

echo "== search: FINDING-1 hyphen class + attribution truths =="
python3 - <<'PY'
import json, urllib.request, urllib.parse
def s(q):
    u = f"http://localhost:3000/api/search?q={urllib.parse.quote(q)}"
    with urllib.request.urlopen(u, timeout=30) as r: d = json.load(r)
    rs = d.get('results') or []
    return (rs[0].get('fa'), rs[0].get('leagueKey')) if rs else ('EMPTY', None)
for q in ("Al-Hilal","Real-Madrid","Man-United","Al-Nassr","real_madrid","Al Hilal",
          "Galatasaray","Rangers","Abha","Celtic","FC Porto","Khorfakkan","الهلال"):
    print(f"  [{q}] → {s(q)}")
PY

echo "== race season 2023/2024 perLeague =="
j "$B/api/topscorers?league=all&season=2023/2024" | python3 -c "
import json,sys; d=json.load(sys.stdin); print('perLeague=', len(d.get('perLeague') or []))"
