#!/usr/bin/env python3
# cycle-196 update live probe — bytes BEFORE the catalog extension (D5).
# The gap: the cycle-92 season boards («برترین‌های رسمی فصل») curate only
# 6 of the 31 TEAM and 6 of the 46 PLAYER stat leaderboards that ride the
# SAME cached data/leagues payload — 25 team + 40 player categories never
# surface (best defense، shots on target، xG، corners، set-piece goals،
# penalties، yellow cards؛ tackles/90، interceptions/90، chances created،
# xA، GK clean sheets، save percentage). This probe pins (P1) the deficit
# on the served boards، (P2) the exact upstream header bytes for the 14
# new catalog entries on the FINISHED 2024/2025 season (stable pins for
# the gate) and the current season (structure only — values drift)،
# (P3) the player-row link shape. UA Chrome/124. Read-only.
import json, urllib.request, urllib.parse, urllib.error

BASE = "http://localhost:3000"
UP = "https://www.fotmob.com"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"}

def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))

def j(x):
    return json.dumps(x, ensure_ascii=False)[:260]

NEW_TEAM = ["Goals conceded per match", "Shots on target per match", "Expected goals",
            "xG difference", "Corners", "Set piece goals", "Penalties awarded", "Yellow cards"]
NEW_PLAYER = ["Tackles per 90", "Interceptions per 90", "Chances created",
              "Expected assist (xA)", "Clean sheets", "Save percentage"]

print("== P1: the deficit — served pl boards today carry only the 92 catalog ==")
d = get(f"{BASE}/api/standings?league=pl")
boards = d.get("boards") or []
team_h = [b.get("header") for b in boards if b.get("kind") == "team"]
player_h = [b.get("header") for b in boards if b.get("kind") == "player"]
print(f"boards={len(boards)} team={team_h}")
print(f"player={player_h}")
missing_t = [h for h in NEW_TEAM if h not in team_h]
missing_p = [h for h in NEW_PLAYER if h not in player_h]
print(f"new-team absent: {len(missing_t)}/8  new-player absent: {len(missing_p)}/6")

print("== P2: upstream bytes — the 14 new headers, 2024/2025 (stable) + current ==")
for season in ("2024/2025", None):
    q = f"{UP}/api/data/leagues?id=47&ccode3=ENG&lang=en" + (f"&season={urllib.parse.quote(season)}" if season else "")
    raw = get(q)
    stats = raw.get("stats") or {}
    label = season or "current"
    print(f"-- {label} (selectedSeason={(raw.get('overview') or {}).get('selectedSeason')}) --")
    for kind, blocks, idf in (("team", stats.get("teams") or [], "teamId"),
                              ("player", stats.get("players") or [], "id")):
        for b in blocks:
            h = b.get("header")
            if h in (NEW_TEAM if kind == "team" else NEW_PLAYER):
                p = b.get("participant") or {}
                st = p.get("stat") or {}
                print(f"  {kind} | {h} | {p.get('name')} v={st.get('value')} fmt={st.get('format')} fr={st.get('fractions')} {idf}={p.get(idf)} top3={[t.get('name') for t in (b.get('topThree') or [])][:3]}")

print("== P3: player-row link shape (new categories carry team+id) ==")
raw = get(f"{UP}/api/data/leagues?id=47&ccode3=ENG&lang=en")
for b in (raw.get("stats") or {}).get("players") or []:
    if b.get("header") in NEW_PLAYER:
        p = b.get("participant") or {}
        print(f"  {b.get('header')}: name={p.get('name')} id={p.get('id')} teamName={p.get('teamName')} teamId={p.get('teamId')}")
