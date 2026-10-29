#!/usr/bin/env python3
# cycle-161 mapping gap check — Croatian HNL facing names vs TEAM_FA +
# PLAYER_NAME_FA (the app is the source of truth: read the TS maps).
import re

def keys(path, pat):
    src = open(path).read()
    m = re.search(pat, src, re.S)
    return set(re.findall(r'"((?:[^"\\]|\\.)*)"\s*:', m.group(1)))

tk = keys("src/lib/leagues.ts", r"const TEAM_FA: Record<string, string> = \{(.*?)\n\};")
pk = keys("src/lib/player-names-fa.ts", r"export const PLAYER_NAME_FA: Record<string, string> = \{(.*?)\n\};")
print(f"TEAM_FA={len(tk)} PLAYER={len(pk)}")

def miss(names, ks, label):
    m = [n for n in names if n.lower().replace("\u0307", "") not in ks]
    print(f"{label} missing ({len(m)}):", m)

table = ["Hajduk Split", "Dinamo Zagreb", "NK Varaždin", "Osijek", "Rijeka",
         "NK Istra 1961", "Slaven", "NK Lokomotiva", "Rudeš", "HNK Gorica"]
scorer = ["Dinamo Zagreb", "Istra 1961", "Slaven Belupo Koprivnica", "NK Osijek",
          "Hajduk Split", "HNK Rijeka", "HNK Gorica", "Lokomotiva Zagreb",
          "Rudeš", "NK Varaždin"]
titles = ["Dinamo Zagreb", "Hajduk Split", "Rijeka", "NK Zagreb"]
transfers = ['APOEL Nicosia', 'Al Ahly SC', 'Al Qadsiah', 'Al Taee', 'Aldosivi', 'Aluminij', 'Anorthosis', 'Arouca', 'Asia Talas', 'Atlético Madrid', 'Augsburg', 'Barcelona', 'Basel', 'Botev Plovdiv', 'Bursaspor', 'Cibalia', 'DAC 1904 Dunajska Streda', 'Deportivo Alavés', 'Dinamo Zagreb', 'Dukagjini', 'Dukla Praha', 'Estoril', 'FAR Rabat', 'FC Arges Pitesti', 'FC København', 'FC Porto', 'FC Rostov', 'FK Sarajevo', 'Feyenoord', 'Free agent', 'Gaziantep FK', 'Go Ahead Eagles', 'Grêmio', 'HNK Gorica', 'Hajduk Split', 'Hapoel Ironi Kiryat Shmona', 'Hellas Verona', 'Independiente Medellín', 'Kilmarnock', 'Kispest Honvéd', 'Koper', 'Le Mans', 'Lincoln Red Imps FC', 'Lugo', 'Marítimo', 'Middlesbrough', 'Milan Futuro', 'Montpellier', 'Mura', 'NFC Volos', 'NK Celje', 'NK Istra 1961', 'NK Lokomotiva', 'NK Radomlje', 'NK Varaždin', 'Osijek', 'Oțelul Galați', 'PFC Sochi', 'PSG', 'Paderborn', 'Pafos FC', 'Paris Saint-Germain', 'Persija Jakarta', 'RFS', 'Real Oviedo', 'Rijeka', 'Rodina', 'Rostov', 'Rudeš', 'SV Lafnitz', 'Samsunspor', 'Sigma Olomouc', 'Slaven', 'Sochi', 'Sporting Gijón', 'Toulouse', 'Vejle Boldklub', 'Venezia', 'Vitória de Guimarães', 'Vukovar 91', 'Wieczysta Kraków', 'Zabbar ST. Patrick FC', 'Zira', 'Újpest', 'Široki Brijeg']
players = ["Dion Drena Beljo", "Emil Frederiksen", "Ilija Nestorovski", "Armando León",
           "Hamza Jaganjac", "Michele Šego", "Nail Omerović", "Daniel Adu-Adjei",
           "Luka Mamić", "Samuel Vignato", "Bruno Bogojević", "Dukan Ahmeti",
           "Dušan Vuković", "Ivan Canjuga", "Marko Livaja", "Niko Galešić",
           "Noa Skoko", "Toni Fruk", "Tiago Dantas", "Abdoulie Sanyang",
           "Mohammad Mohebbi"]

miss(table, tk, "TABLE")
miss(scorer, tk, "SCORER")
miss(titles, tk, "TITLES")
miss(transfers, tk, "TRANSFERS")
miss(players, pk, "PLAYERS")
