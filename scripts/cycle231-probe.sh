#!/bin/bash
# cycle231-probe.sh — live feasibility probe for the cycle-231 UPDATE:
# «big chances created» — the 230 card's probed candidate — as the deep-file
# family's FIFTEENTH sibling (the production CREATION surface beside the
# analytics twins xG 226 / xA 230). UA Chrome/124 like every probe since 205.
# Everything verbatim-dumped so the implementation can quote real numbers.
set -u
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

probe_cat () {  # $1=leagueKey $2=fotmobId $3=ccode3 $4=season(optional) $5=regex
  local LK="$1" ID="$2" CC="$3" SEASON="$4" RE="$5"
  local URL="https://www.fotmob.com/api/data/leagues?id=${ID}&ccode3=${CC}&lang=en"
  [ -n "$SEASON" ] && URL="${URL}&season=${SEASON}"
  python3 - "$URL" "$RE" "$LK" "$SEASON" <<'PY'
import sys, json, re, gzip, urllib.request
url, re_pat, lk, season = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
def fetch_json(u):
    req = urllib.request.Request(u, headers={"User-Agent": UA, "Accept-Encoding": "identity"})
    b = urllib.request.urlopen(req, timeout=30).read()
    if b[:2] == b"\x1f\x8b":
        b = gzip.decompress(b)
    return json.loads(b.decode("utf-8"))
try:
    raw = fetch_json(url)
except Exception as e:
    print(f"{lk} season={season or 'cur'} RAW-FAIL {e}"); sys.exit()
cats = (raw.get("stats") or {}).get("players") or []
hit = next((c for c in cats if re.search(re_pat, (c.get("header") or ""), re.I)), None)
if not hit:
    print(f"{lk} season={season or 'cur'} category=ABSENT (players cats: {len(cats)})"); sys.exit()
furl = hit.get("fetchAllUrl") or ""
if not furl.startswith("https://data.fotmob.com/"):
    print(f"{lk} season={season or 'cur'} category={hit.get('header')!r} fetchAllUrl=MISSING"); sys.exit()
try:
    data = fetch_json(furl)
except Exception as e:
    print(f"{lk} season={season or 'cur'} {hit.get('header')!r} FILE-FAIL {e}"); sys.exit()
rows = ((data.get("TopLists") or [{}])[0].get("StatList") or [])
if not rows:
    print(f"{lk} season={season or 'cur'} {hit.get('header')!r} rows=0"); sys.exit()
vals = [r.get("StatValue") for r in rows if r.get("StatValue") is not None]
maxdec = max((len(str(v).split(".")[1]) if isinstance(v, float) and "." in str(v) else 0) for v in vals)
nonint = sum(1 for v in vals if isinstance(v, float) and v != int(v))
top3 = [(r.get("Rank"), r.get("ParticipantName"), r.get("StatValue"), r.get("TeamName")) for r in rows[:3]]
ranks = [r.get("Rank") for r in rows[:12]]
print(f"{lk} season={season or 'cur'} {hit.get('header')!r} rows={len(rows)} maxdec={maxdec} nonint={nonint} ranks={ranks} top3={top3}")
PY
}

echo "== P1: big chances created — 8 served leagues, current season =="
probe_cat ucl          42  UEFA ""  '^big chances created$'
probe_cat pl           47  ENG  ""  '^big chances created$'
probe_cat laliga       87  ESP  ""  '^big chances created$'
probe_cat seriea       55  ITA  ""  '^big chances created$'
probe_cat bundesliga   54  GER  ""  '^big chances created$'
probe_cat ligue1       53  FRA  ""  '^big chances created$'
probe_cat persiangulf 523  IRN  ""  '^big chances created$'
probe_cat mas         8985  MAS  ""  '^big chances created$'

echo "== P2: season-awareness (historical raws serve their OWN files?) =="
probe_cat laliga       87  ESP '2020%2F2021' '^big chances created$'
probe_cat pl           47  ENG '2023%2F2024' '^big chances created$'
probe_cat laliga       87  ESP '2022%2F2023' '^big chances created$'

echo "== P3: the other 16 leagues.ts entries (wide-scan for the comment) =="
probe_cat uel          73  INT "" '^big chances created$'
probe_cat uecl      10216  INT "" '^big chances created$'
probe_cat acl         525  INT "" '^big chances created$'
probe_cat superlig     71  TUR "" '^big chances created$'
probe_cat scottish     64  SCO "" '^big chances created$'
probe_cat saudi       536  KSA "" '^big chances created$'
probe_cat championship 48  ENG "" '^big chances created$'
probe_cat portugal     61  POR "" '^big chances created$'
probe_cat uae         538  UAE "" '^big chances created$'
probe_cat qatar       535  QAT "" '^big chances created$'
probe_cat eredivisie   57  NED "" '^big chances created$'
probe_cat acl2       9469  INT "" '^big chances created$'
probe_cat swiss        69  SUI "" '^big chances created$'
probe_cat hnl         252  CRO "" '^big chances created$'
probe_cat poland      196  POL "" '^big chances created$'
probe_cat belgium      40  BEL "" '^big chances created$'

echo "cycle231-probe done."
