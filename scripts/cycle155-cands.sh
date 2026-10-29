#!/bin/bash
# cycle-155 FINAL candidate probe (v4) — four-block + Iranian-interest,
# exact lib shapes: table[0].data.table.all, stats.players[Top scorer].
# fetchAllUrl goals.json (gzip-decoded).
set -u
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
for C in "38 AUT Austria-Bundesliga" "40 BEL Belgian-Pro" "57 NED Eredivisie" "59 NOR Eliteserien" "69 SUI Swiss-Super-League" "135 GRE Super-League-Greece" "519 EGY Egypt-Premier" "530 MAR Botola-Pro" "535 QAT Qatar-Stars"; do
  set -- $C; PID=$1; CC=$2; NM=$3
  curl -s -A "$UA" --max-time 25 "https://www.fotmob.com/api/data/leagues?id=$PID&ccode3=$CC&lang=en" > /tmp/lg4.json 2>/dev/null
  python3 - "$PID" "$CC" "$NM" <<'PY'
import json, sys, urllib.request, gzip
pid, cc, nm = sys.argv[1], sys.argv[2], sys.argv[3]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
try:
    d = json.load(open('/tmp/lg4.json'))
except Exception:
    print(f"{nm} [{pid}/{cc}] non-json"); raise SystemExit
if not isinstance(d, dict) or d.get('statusCode'):
    kind = type(d).__name__
    print(f"{nm} [{pid}/{cc}] bad-payload({kind})"); raise SystemExit
seasons = d.get('allAvailableSeasons') or []
def sname(s):
    return s if isinstance(s, str) else (s.get('name') or '') if isinstance(s, dict) else ''
s_names = [sname(s) for s in seasons]
rows, top3 = 0, []
try:
    allrows = (((d.get('table') or [{}])[0].get('data') or {}).get('table') or {}).get('all') or []
    rows = len(allrows)
    top3 = [(r.get('name'), r.get('pts')) for r in allrows[:3]]
except Exception:
    pass
url = ''
for cat in ((d.get('stats') or {}).get('players') or []):
    if isinstance(cat, dict) and 'top scorer' in str(cat.get('header', '')).lower():
        url = cat.get('fetchAllUrl') or ''
        break
iranians, scorer_n, lead = [], 0, None
if url:
    if url.startswith('//'): url = 'https:' + url
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA})
        with urllib.request.urlopen(req, timeout=25) as r:
            raw = r.read()
        if raw[:2] == b'\x1f\x8b':
            raw = gzip.decompress(raw)
        g = json.loads(raw.decode('utf-8', 'replace'))
        rl = ((g.get('TopLists') or [{}])[0].get('StatList')) or []
        scorer_n = len(rl)
        if rl:
            p0 = rl[0]
            lead = f"{p0.get('name')}({p0.get('statValue')})"
        PATT = ('Taremi','Azmoun','Ezatolahi','Ghoddos','Jahanbakhsh','Noorallahi','Nourallahi','Ghorbani','Amiri','Mohebi','Dabbagh','Hosseini','Rezaeian','Moharrami','Kanaani','Hajsafi','Azadi','Sarlak','Karimi','Salari','Sharifi','Gholizadeh','Torabi','Sheydaei','Dehnavi','Ansari')
        for p in rl:
            n2 = str(p.get('name') or '')
            if any(k.lower() in n2.lower() for k in PATT):
                iranians.append(f"{n2}({p.get('statValue')})")
    except Exception as e:
        scorer_n = -1
tr = d.get('transfers') or {}
trd = tr.get('data') if isinstance(tr, dict) else None
trn = len(trd.get('transfers') or []) if isinstance(trd, dict) else (len(trd) if isinstance(trd, list) else 0)
po = d.get('playoff', 'absent')
po_s = 'null' if po is None else ('yes' if po == 'absent' else 'obj')
print(f"{nm} [{pid}/{cc}] seasons={len(seasons)}(slash={sum(1 for s in s_names if '/' in s)} first={s_names[0] if s_names else '-'}) rows={rows} top3={top3} scorers={scorer_n} lead={lead} transfers={trn} playoff={po_s} Iranians={','.join(iranians) or 'NONE'}")
PY
done
