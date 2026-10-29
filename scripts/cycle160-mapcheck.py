#!/usr/bin/env python3
# cycle-160 mapping gap check — which Swiss-facing names are missing from
# TEAM_FA (the app is the source of truth: read the TS map and diff).
import re, json

src = open("src/lib/leagues.ts").read()
m = re.search(r"const TEAM_FA: Record<string, string> = \{(.*?)\n\};", src, re.S)
keys = set(re.findall(r'"((?:[^"\\]|\\.)*)"\s*:', m.group(1)))
print(f"TEAM_FA existing keys: {len(keys)}")

def has(*names):
    miss = []
    for n in names:
        k = n.lower().replace("\u0307", "").strip()
        if k not in keys:
            miss.append(n)
    return miss

table_clubs = ["Lugano", "Young Boys", "Sion", "FC Zürich", "Servette", "St. Gallen",
               "Basel", "Luzern", "Thun", "FC Vaduz", "Grasshopper", "Lausanne"]
ascii_variants = ["FC Zurich", "St Gallen", "Saint Gallen"]
scorer_forms = ["BSC Young Boys", "FC Basel", "FC Vaduz", "FC Zürich"]
titles = ["Thun", "St. Gallen", "Basel", "Servette", "Young Boys", "Lugano", "FC Zürich",
          "Grasshopper", "Luzern", "Sion", "Xamax", "Lausanne"]
transfers = ['1.FC Köln II', 'Amiens', 'Austria Lustenau', 'Auxerre', 'Baník Ostrava', 'Basel', 'Batman Petrolspor', 'Bologna', 'Brighton', 'Brighton & Hove Albion', 'Cagliari', 'Carrarese', 'Castellón', 'Chelsea', 'Club Brugge', 'Derby', 'Derby County', 'Eintracht Frankfurt', 'Enosis Paralimni', 'Etoile Carouge', 'Eupen', 'FC Andorra', 'FC Heidenheim', 'FC Rapperswil-Jona', 'FC Stade Lausanne-Ouchy', 'FC Vaduz', 'FC Zürich', 'Famalicão', 'Fiorentina', 'Frankfurt', 'Free agent', 'Gent', 'Grasshopper', 'Greuther Fürth', 'Hajduk Split', 'Hannover 96', 'Heart of Midlothian', 'Hearts', 'Juventus Next Gen', 'Kalmar FF', 'Kasımpaşa', 'Kocaelispor', 'Konyaspor', 'Kortrijk', 'Kriens', 'Lausanne', 'Le Havre', 'Lecce', 'Lechia Gdańsk', 'Leeds', 'Leeds United', 'Lens', 'Lugano', 'Luzern', 'Lyon', 'MAS Fès', 'Man United', 'Manchester United', 'Middlesbrough', 'Mjällby', 'NYCFC', 'Napoli', 'New York City FC', 'Nordsjælland', 'PSG', 'Paris Saint-Germain', 'Parma', 'Preston', 'Preston North End', 'QPR', 'Queens Park Rangers', 'Red Star', 'Royal Antwerp', 'Sabah FK', 'Servette', 'Sion', 'Sporting CP', 'Sporting Gijón', 'St. Gallen', 'Stade Nyonnais', 'Start', 'Sturm Graz', 'Thun', 'Torino', 'Union Berlin', 'Union Touarga Sport', 'Westerlo', 'Widzew Łódź', 'Wil', 'Winterthur', 'Wisła Kraków', 'Wolfsburg', 'Young Boys', 'Yverdon', 'Örgryte', 'Železničar Pančevo']

print("TABLE missing:", has(*table_clubs))
print("ASCII missing:", has(*ascii_variants))
print("SCORER missing:", has(*scorer_forms))
print("TITLES missing:", has(*titles))
tmiss = has(*transfers)
print(f"TRANSFERS missing ({len(tmiss)}):", tmiss)
