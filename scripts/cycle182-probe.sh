#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-182 probe — observe live bytes BEFORE gates (the D5 rule).
# Patrol target: the three surfaces added since the cycle-178 hunt:
#   cycle-179  «کارت‌ها» card on /topscorers/[leagueKey]
#   cycle-180  season selector on /topscorers/[leagueKey] (?season=)
#   cycle-181  Belgian Pro League (/league/belgium, /topscorers/belgium)
# Read-only; pins drift if the live truth moved.
# ------------------------------------------------------------------
set -u
python3 - <<'PY'
import json, urllib.request, urllib.parse, urllib.error
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
def code(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        return urllib.request.urlopen(req, timeout=30).getcode()
    except urllib.error.HTTPError as e:
        return e.code

print("== P1 page sweep (new + legacy) ==")
pages = ["/", "/leagues", "/players", "/news", "/topscorers",
         "/league/belgium", "/topscorers/belgium", "/league/pl",
         "/topscorers/pl", "/league/persiangulf", "/league/mas",
         "/topscorers/mas", "/player/892709", "/player/688273",
         "/team/2182", "/match/5749723"]
for p in pages:
    print(f"  {p} -> {code(BASE + p)}")

print("== P2 topscorers/pl keys + cards block (179) ==")
d = get(BASE + "/api/topscorers/pl")
old = {"ok", "leagueKey", "leagueFa", "season", "scorers", "updatedAt"}
print("  keys-extra:", sorted(set(d.keys()) - old))
c = d.get("cards") or {}
y, r = c.get("yellow") or [], c.get("red") or []
print(f"  cards y={len(y)} r={len(r)} y0={(y[0] or {}).get('playerId') if y else None}")
print(f"  sel={d.get('selectedSeason')} allSeasons={len(d.get('allSeasons') or [])}")
print(f"  assists={len(d.get('assists') or [])}")

print("== P3 historical seasons on topscorers route (180) ==")
q = urllib.parse.quote("2024/2025", safe="")
h = get(f"{BASE}/api/topscorers/pl?season={q}")
s0 = (h.get("scorers") or [{}])[0]
print(f"  2024/2025 sel={h.get('selectedSeason')} n={len(h.get('scorers') or [])} "
      f"s0={s0.get('name')}/{s0.get('goals')}g/{s0.get('nameFa')} cards={'cards' in h}")
print(f"  assists_hist={len(h.get('assists') or [])} allSeasons={len(h.get('allSeasons') or [])}")
q2 = urllib.parse.quote("2013/2014", safe="")
e = get(f"{BASE}/api/topscorers/pl?season={q2}")
print(f"  2013/2014 ok={e.get('ok')} sel={e.get('selectedSeason')} scorers={len(e.get('scorers') or [])}")
print(f"  2023 (invalid) -> {code(BASE + '/api/topscorers/pl?season=2023')}")

print("== P4 mas historical (180) ==")
mh = get(f"{BASE}/api/topscorers/mas?season={q}")
m0 = (mh.get("scorers") or [{}])[0]
print(f"  mas 2024/2025 sel={mh.get('selectedSeason')} n={len(mh.get('scorers') or [])} "
      f"s0={m0.get('name')}/{m0.get('goals')}g/{m0.get('nameFa')} ass={len(mh.get('assists') or [])} "
      f"allSeasons={len(mh.get('allSeasons') or [])}")

print("== P5 belgium portal (181) ==")
b = get(BASE + "/api/standings?league=belgium")
rows = b.get("rows") or []
sc = b.get("scorers") or []
ek = next((x for x in sc if x.get("playerId") == 892709), None)
bc = b.get("cards") or {}
print(f"  rows={len(rows)} r0={rows[0].get('fa')}/{rows[0].get('pts')} scorers={len(sc)}")
print(f"  eckert: {'in' if ek else 'OUT'} rank={ek.get('rank') if ek else None} fa={ek.get('nameFa') if ek else None} goals={ek.get('goals') if ek else None} ccode={ek.get('ccode') if ek else None}")
print(f"  assists={len(b.get('assists') or [])} a0pid={(b.get('assists') or [{}])[0].get('playerId')}")
print(f"  cards y={len(bc.get('yellow') or [])} r={len(bc.get('red') or [])}")
print(f"  allSeasons={len(b.get('allSeasons') or [])} sel={b.get('selectedSeason')} playoff={'playoff' in b}")

print("== P6 race (181 merge) ==")
t = get(BASE + "/api/topscorers")
ts = t.get("scorers") or []
pl = [p.get("leagueKey") for p in (t.get("perLeague") or [])]
print(f"  race ts={len(ts)} perLeague={len(pl)} belgium={'belgium' in pl} mas={'mas' in pl}")

print("== P7 belgium historical (181/132) ==")
q3 = urllib.parse.quote("2023/2024", safe="")
bh = get(f"{BASE}/api/topscorers/belgium?season={q3}")
bs0 = (bh.get("scorers") or [{}])[0]
print(f"  belgium topscorers 2023/2024 sel={bh.get('selectedSeason')} n={len(bh.get('scorers') or [])} "
      f"s0={bs0.get('name')} cards={'cards' in bh}")
bs = get(f"{BASE}/api/standings?league=belgium&season={q3}")
print(f"  belgium standings 2023/2024 rows={len(bs.get('rows') or [])} sel={bs.get('selectedSeason')}")
hr = get(f"{BASE}/api/topscorers?season={q3}")
hpl = [p.get("leagueKey") for p in (hr.get("perLeague") or [])]
print(f"  hist race ts={len(hr.get('scorers') or [])} perLeague={len(hpl)} belgium={'belgium' in hpl}")

print("== P8 search two-way (181/166) ==")
g1 = get(BASE + "/api/search?q=Eckert")
p1 = [x for x in (g1.get("players") or []) if x.get("playerId") == 892709]
g2 = get(BASE + "/api/search?q=" + urllib.parse.quote("اکرت"))
p2 = [x for x in (g2.get("players") or []) if x.get("playerId") == 892709]
if p1: print(f"  Eckert: fa={p1[0].get('fa')} teamFa={p1[0].get('teamFa')}")
print(f"  Eckert hit={bool(p1)} اکرت hit={bool(p2)}")

print("== P9 titles/transfers (181) ==")
tt = get(BASE + "/api/league-titles?league=belgium")
titles = tt.get("titles") or tt.get("seasons") or tt
try:
    n = len(titles)
except Exception:
    n = "?"
print(f"  titles type={type(titles).__name__} len={n} keys={sorted(tt.keys()) if isinstance(tt, dict) else 'list'}")
tr = get(BASE + "/api/league-transfers?league=belgium")
items = tr.get("items") or tr.get("transfers") or []
print(f"  transfers items={len(items)}")
PY
echo "PROBE DONE"
