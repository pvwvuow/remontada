#!/usr/bin/env python3
# cycle-198 bug-hunt patrol probe — bytes BEFORE the hunt pins (D5).
# PATROL scope: the four surfaces shipped after the 193 hunt:
#   194 (fix)    — five historical card kings in the player search pool
#   195 (update) — the daily feed's teams in the team search index
#   196 (update) — league boards 6+6 → 12+12 (cards/xG/set-piece families)
#   197 (update) — the teammates card (club + national squad navigation)
# The probe pins STRUCTURAL truth + drift-tolerant live anchors only
# (the 193 lesson: nothing live-value is pinned). Read-only, UA Chrome/124.
#
# P1: the 194×197 cross-tie — Fetai (a 194 fold-king) serves his OWN 197
#     teammates block: club group bytes, chip id liveness (sampled ids
#     answer full /playerData profiles — the 167 lesson).
# P2: the 196 boards on ONE served payload — old kinds AND new kinds
#     co-exist; a new TEAM-board row's teamId answers /api/team/{id};
#     a new PLAYER-board row's id answers /api/player/{id}.
# P3: the 195 surface today — non-portal feed teams searchable NOW,
#     true fold rows rank 0 with the group's Persian label.
# P4: the 194 kings today — both alphabets, rank 0, no goals, the season
#     hint fields (season + leagueFa), nameFa via the 189 map.
# P5: the standing anchors — current race drift-tolerant identity;
#     the 197 universality on star/non-star/pool-star (v8 cache serves).
import json, urllib.request, urllib.parse

BASE = "http://localhost:3000"
UP = "https://www.fotmob.com"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"}

def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))

PORTAL = {"LaLiga","Premier League","Serie A","Bundesliga","Ligue 1","UEFA Champions League",
          "UEFA Europa League","UEFA Conference League","Persian Gulf Pro League","Saudi Pro League",
          "Süper Lig","Scottish Premiership","EFL Championship","Liga Portugal","UAE Pro League",
          "Qatar Stars League","Eredivisie","AFC Champions League Elite","AFC Champions League Two",
          "Croatian HNL","Belgian Pro League","Ekstraklasa"}

print("== P1: the 194x197 cross-tie — Fetai's served teammates block ==")
p = get(f"{BASE}/api/player/1516458").get("player") or {}
tm = p.get("teammates") or []
nt = p.get("nationalTeammates") or []
print(f"Fetai 1516458: teammates={len(tm)} national={len(nt)} name={p.get('name')}/{p.get('nameFa')}")
print(f"  club first4: {[(r.get('id'), r.get('name'), r.get('nameFa')) for r in tm[:4]]}")
live = 0
for r in tm[:5]:
    try:
        q = get(f"{BASE}/api/player/{r['id']}").get("player") or {}
        if q.get("name"):
            live += 1
    except Exception:
        pass
print(f"  chip-id liveness: {live}/5 sampled teammates serve full profiles")
seen_ids = [r.get("id") for r in tm]
print(f"  self-in-list: {1516458 in seen_ids}  dup-ids: {len(seen_ids) - len(set(seen_ids))}")

print("== P2: the 196 boards — old+new kinds on ONE payload ==")
st = get(f"{BASE}/api/standings?league=laliga")
boards = st.get("boards") or []
kinds = {}
for b in boards:
    kinds.setdefault(b.get("kind"), 0)
    kinds[b.get("kind")] += 1
print(f"boards={len(boards)} kinds={len(kinds)}")
for k in sorted(kinds):
    print(f"  {k}: {kinds[k]}")
new_team = next((b for b in boards if b.get("kind") == "team" and b.get("headerFa") == "کارت زرد"), None)
if new_team:
    rows = new_team.get("rows") or []
    print(f"new team-board «کارت زرد»: rows={len(rows)} r0={rows[0] if rows else None}")
    if rows:
        tid = rows[0].get("teamId") or rows[0].get("id")
        try:
            t = get(f"{BASE}/api/team/{tid}")
            print(f"  teamId {tid} liveness: /api/team 200 name={(t.get('team') or {}).get('name') or t.get('name')}")
        except Exception as e:
            print(f"  teamId {tid} liveness: DEAD {e!r}")
new_pl = next((b for b in boards if b.get("kind") == "player" and b.get("headerFa") == "تکل در هر ۹۰ دقیقه"), None)
if new_pl:
    rows = new_pl.get("rows") or []
    print(f"new player-board «تکل در هر ۹۰»: rows={len(rows)} r0={rows[0] if rows else None}")
    if rows:
        pid = (rows[0].get("id") or {}).get("id") if isinstance(rows[0].get("id"), dict) else rows[0].get("id")
        print(f"  player id byte: {pid}")

print("== P3: the 195 surface today — feed teams searchable ==")
feed = get(f"{BASE}/api/matches")
feed_teams = {}
for g in feed.get("groups") or []:
    for m in g.get("matches") or []:
        for side in (m.get("home"), m.get("away")):
            if side and side.get("id") and side["id"] not in feed_teams:
                feed_teams[side["id"]] = {"name": side.get("name"), "fa": side.get("fa"),
                                          "leagueFa": g.get("leagueFa"), "leagueName": g.get("leagueName")}
non_portal = [t for t in feed_teams.items() if t[1]["leagueName"] not in PORTAL
              and len((t[1]["fa"] or t[1]["name"] or "")) >= 3]
non_portal.sort(key=lambda kv: kv[0])
found = 0
for tid, t in non_portal[:10]:
    q = t["fa"] or t["name"]
    d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    if any(r.get("teamId") == tid for r in (d.get("results") or [])):
        found += 1
print(f"feed today: {len(feed_teams)} teams / {len(feed.get('groups') or [])} groups; non-portal sample {found}/{min(10, len(non_portal))} searchable")

print("== P4: the 194 kings today — row bytes both alphabets ==")
for q, pid in [("فتای", 1516458), ("داونز", 844943), ("Downes", 844943), ("راداکوویچ", 364855)]:
    d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    rows = [r for r in (d.get("results") or []) if r.get("playerId") == pid]
    r0 = rows[0] if rows else None
    print(f"q={q!r}: rows={len(rows)} row={json.dumps(r0, ensure_ascii=False) if r0 else None}")

print("== P5: standing anchors (drift-tolerant) ==")
ts = get(f"{BASE}/api/topscorers")
s0 = (ts.get("scorers") or [{}])[0]
print(f"race s0: {s0.get('name')}/{s0.get('nameFa')}/{s0.get('goals')}g rank={s0.get('rank')} sel={ts.get('selectedSeason')} n={len(ts.get('scorers') or [])}")
for pid, who in [(696679, "Raphinha/star"), (1800491, "Lulli/non-star"), (664500, "Gyokeres/pool-star")]:
    p = get(f"{BASE}/api/player/{pid}").get("player") or {}
    tm = p.get("teammates") or []
    nt = p.get("nationalTeammates") or []
    print(f"  {who}: teammates={len(tm)} national={len(nt)} (197 universality)")
