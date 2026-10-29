#!/usr/bin/env python3
# cycle-162 mapping guard (A7 convention) — totals + zero duplicates + the
# Malaysia-facing names all mapped.
import re

def keys(path, pat):
    src = open(path).read()
    m = re.search(pat, src, re.S)
    body = m.group(1)
    ks = re.findall(r'"((?:[^"\\]|\\.)*)"\s*:', body)
    vals = re.findall(r':\s*"((?:[^"\\]|\\.)*)"', body)
    return ks, vals

tk, tv = keys("src/lib/leagues.ts", r"const TEAM_FA: Record<string, string> = \{(.*?)\n\};")
pk, pv = keys("src/lib/player-names-fa.ts", r"export const PLAYER_NAME_FA: Record<string, string> = \{(.*?)\n\};")
td = [k for k in set(tk) if tk.count(k) > 1]
pd = [k for k in set(pk) if pk.count(k) > 1]
print(f"TEAM_FA={len(tk)} distinct={len(set(tk))} dups={td}")
print(f"PLAYER_NAME_FA={len(pk)} distinct={len(set(pk))} dups={pd}")

# the 26 Malaysia table/scorer/transfer clubs + the 21 player keys must hit
clubs = ["brunei dpmm", "felda united fc", "imigresen fc", "kedah darul aman",
         "kelantan", "kelantan dnfc", "kelantan red warrior",
         "kelantan the real warriors fc", "kelantan united", "maccabi haifa",
         "melaka fc", "melaka united", "negeri sembilan", "pdrm", "penang",
         "perak", "perak ii", "petaling jaya city fc", "sabah",
         "sarawak united", "selangor", "selangor ii", "sri pahang",
         "star city", "terengganu", "uitm"]
players = ["chrigor", "jerome mpacko etame", "shahab zahedi", "bérgson",
           "ajdin mujagić", "gonzalo di renzo", "marcos guilherme",
           "nur fikri azhar", "paulo josué", "christian", "dalberto",
           "dong-hyun do", "dylan wenzel-halls", "faisal abdul halim",
           "gervane kastaneer", "óscar arribas", "philip dandada musa",
           "safawi rasid", "stefano brundo", "stoichkov",
           "mojtaba esmaeilzadeh"]
ks, ps = set(tk), set(pk)
mc = [n for n in clubs if n not in ks]
mp = [n for n in players if n not in ps]
print(f"MAS clubs missing ({len(mc)}): {mc}")
print(f"MAS players missing ({len(mp)}): {mp}")

ok = (len(tk) == 1077 and len(pk) == 533 and not td and not pd
      and not mc and not mp)
print("MAPCHECK OK — 1077 team / 533 player keys, zero duplicates, all MAS-facing names mapped"
      if ok else "MAPCHECK FLAGGED")
exit(0 if ok else 1)
