#!/bin/bash
# cycle-155 update feasibility probe v3 (UA Chrome/124, live 2026-10-29):
# 1) resolve (primaryId, ccode, name) for EVERY league on today's FotMob feed
# 2) four-block-probe each candidate league page
#    (flat table + 17 slash seasons + topScorer fetchAllUrl + titles + transfers + playoff)
# 3) Iranian-interest scan of each candidate's full scorer file
set -u
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
j() { curl -s -A "$UA" --max-time 25 "$1"; }

j "https://www.fotmob.com/api/data/matches?date=20261029" > /tmp/matches.json 2>/dev/null
python3 - <<'PY' > /tmp/cands.txt
import json
d = json.load(open('/tmp/matches.json'))
seen = {}
for lg in d.get('leagues') or []:
    pid, cc, nm = lg.get('primaryId'), lg.get('ccode'), lg.get('name')
    if isinstance(pid, int) and cc and nm and lg.get('matches'):
        seen.setdefault((pid, cc), nm)
for (pid, cc), nm in sorted(seen.items()):
    print(f"{pid}\t{cc}\t{nm}")
PY
echo "candidates: $(wc -l < /tmp/cands.txt)"
while IFS=$'\t' read -r PID CC NM; do
  j "https://www.fotmob.com/api/data/leagues?id=$PID&ccode3=$CC&lang=en" > /tmp/lg.json 2>/dev/null
  python3 - "$PID" "$CC" "$NM" <<'PY'
import json, sys, urllib.request
pid, cc, nm = sys.argv[1], sys.argv[2], sys.argv[3]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
try:
    d = json.load(open('/tmp/lg.json'))
except Exception:
    print(f"{nm} [{pid}/{cc}] non-json"); raise SystemExit
if not isinstance(d, dict) or d.get('statusCode'):
    print(f"{nm} [{pid}/{cc}] null/error"); raise SystemExit
seasons = d.get('allAvailableSeasons') or []
def sname(s):
    if isinstance(s, str): return s
    if isinstance(s, dict): return s.get('name') or s.get('seasonName') or ''
    return ''
s_names = [sname(s) for s in seasons]
tbl = d.get('table') or {}
rows = 0
if isinstance(tbl, dict):
    def count_rows(t):
        if isinstance(t, dict):
            a = t.get('all')
            if isinstance(a, list): return len(a)
            if isinstance(t.get('table'), dict):
                a = t['table'].get('all')
                if isinstance(a, list): return len(a)
            return 0
        if isinstance(t, list): return len(t)
        return 0
    for v in tbl.values():
        if isinstance(v, dict):
            r = count_rows(v)
            if isinstance(v.get('table'), dict): r = count_rows(v.get('table'))
            rows = max(rows, r) if r else rows
tbl = d.get('table') or []
rows = 0
try:
    rows = len((((tbl[0] or {}).get('data') or {}).get('table') or {}).get('all') or [])
except Exception:
    rows = 0
ts_cat = None
for cat in ((d.get('stats') or {}).get('players') or []):
    if isinstance(cat, dict) and 'top scorer' in str(cat.get('header','')).lower():
        ts_cat = cat; break
url = (ts_cat or {}).get('fetchAllUrl') or ''
iranians = []
scorer_n = 0
if url:
    if url.startswith('//'): url = 'https:' + url
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA})
        with urllib.request.urlopen(req, timeout=25) as r:
            raw_bytes = r.read()
        if raw_bytes[:2] == b'\x1f\x8b':  # data.fotmob.com serves gzip (lib fetches decompress automatically)
            import gzip
            raw_bytes = gzip.decompress(raw_bytes)
        g = json.loads(raw_bytes.decode('utf-8', 'replace'))
        rows_list = ((g.get('TopLists') or [{}])[0].get('StatList')) or []
        scorer_n = len(rows_list)
        PATT = ('Taremi','Azmoun','Ezatolahi','Ghoddos','Jahanbakhsh','Noorallahi','Nourallahi','Ghorbani','Amiri','Mohebi','Dabbagh','Hosseini','Rezaeian','Moharrami','Kanaani','Hajsafi','Azadi','Sarlak','Karimi','Sheykhi','Salari','Sharifi','Gholizadeh','Torabi')
        for p in rows_list:
            nmf = str(p.get('name') or (p.get('player') or {}).get('name') or '')
            if any(k.lower() in nmf.lower() for k in PATT):
                iranians.append(f"{nmf}({p.get('statValue') or p.get('value')})")
    except Exception:
        pass
tr = d.get('transfers') or {}
trd = tr.get('data') if isinstance(tr, dict) else None
trn = len(trd.get('transfers') or []) if isinstance(trd, dict) else (len(trd) if isinstance(trd, list) else 0)
tit = d.get('leagueTitles') or {}
tlen = len(tit.get('champions') or tit.get('seasons') or []) if isinstance(tit, dict) else 0
po = d.get('playoff', 'absent')
po_s = 'null' if po is None else ('yes' if po == 'absent' else 'obj')
slash17 = sum(1 for s in s_names if '/' in s)
print(f"{nm} [{pid}/{cc}] seasons={len(seasons)}(slash={slash17} last={s_names[0] if s_names else '-'}) rows={rows} scorers={scorer_n} transfers={trn} titles={tlen} playoff={po_s} Iranians={','.join(iranians[:6]) or 'NONE'}")
PY
done < /tmp/cands.txt
