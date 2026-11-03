#!/usr/bin/env python3
# cycle-461 probe3: (A) the qualified-title families the disambig pages point
# to (لاپاز (مکزیک) — the OWN spelling the دسامب لاپاز documents, plus the
# مکزیک-qualified families for Guadalajara/Mérida and the missing toponyms
# Tlaxcala/Campeche in spelling variants) + direct club-article candidates
# under باشگاه فوتبال ... forms. (B) the اتلتیکو مورلیا page (41466701) gave
# an EMPTY extract — redirect check + full wikitext head to see the target
# (a redirect is NOT a club-article anchor per the 457 زوریا precedent but
# documents the OWN spelling; the bare page its R-from-move redirect — the
# 460 زنیچ precedent — would still anchor the club). (C) the exact byte form
# of every hit title saved to /tmp/c461-wiki2.json for the verify step.
import json
import subprocess
import time
import urllib.parse

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def api(url: str):
    for attempt in range(3):
        out = subprocess.run(
            ["curl", "-s", "--max-time", "25", "-A", UA, url],
            capture_output=True, text=True, timeout=40,
        ).stdout
        try:
            return json.loads(out)
        except Exception:
            time.sleep(2 + attempt * 2)
    return None


print("== A) qualified-title families + club-article candidates ==")
CAND = ["لاپاز (مکزیک)", "گوادالاخارا (مکزیک)", "مریدا (مکزیک)",
        "مریدا، یوکاتان", "مریدا (یوکاتان)",
        "تلاکسکالا", "تلاسکالا", "تلاکسکالا (مکزیک)",
        "کمپچه", "کمپچه (مکزیک)", "کامپچه",
        "باشگاه فوتبال آتلتیکو مورلیا", "باشگاه فوتبال اتلتیکو مورلیا",
        "آتلتیکو مورلیا",
        "باشگاه فوتبال ونادوس", "ونادوس (باشگاه فوتبال)",
        "باشگاه فوتبال تلاکسکالا", "باشگاه فوتبال کانکون",
        "باشگاه فوتبال لئونس نگروس", "شیرهای سیاه",
        "باشگاه فوتبال الاکرانس", "باشگاه فوتبال دورانگو",
        "دورانگو (مکزیک)", "شهر دورانگو"]
present = {}
for i in range(0, len(CAND), 8):
    chunk = CAND[i:i + 8]
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=info&inprop=url"
           "&titles=" + urllib.parse.quote("|".join(chunk)) + "&format=json")
    d = api(url)
    for pid, p in ((d or {}).get("query", {}).get("pages", {})).items():
        if pid != "-1" and "missing" not in p:
            present[p["title"]] = p.get("lastrevid")
            print(f"  EXISTS pageid={p.get('lastrevid')}: {p['title']}")
    time.sleep(0.3)
print(f"  present={len(present)} / tried={len(CAND)}")

print("== B) اتلتیکو مورلیا (41466701): redirect? wikitext head ==")
url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=revisions"
       "&rvprop=content&rvslots=main&rvchars=300&pageids=41466701&format=json")
d = api(url)
p = (d or {}).get("query", {}).get("pages", {}).get("41466701", {})
revs = p.get("revisions", [])
if revs:
    txt = (revs[0].get("slots", {}).get("main", {}).get("*") or "")[:300]
    print(f"  wikitext head: {txt!r}")
else:
    print("  NO revision content returned")

print("== B2) identity extracts for NEW hits ==")
newhits = [t for t in present if t not in
           ("اتلتیکو مورلیا", "دورانگو", "لا پاز", "لاپاز", "مریدا",
            "مورلیا", "کانکون", "گوادالاخارا", "یوکاتان")]
for i in range(0, len(newhits), 6):
    chunk = newhits[i:i + 6]
    url = ("https://fa.wikipedia.org/w/api.php?action=query&prop=extracts"
           "&exintro&explaintext&exchars=200&titles="
           + urllib.parse.quote("|".join(chunk)) + "&format=json")
    d = api(url)
    for pid, p in ((d or {}).get("query", {}).get("pages", {})).items():
        if pid != "-1" and "missing" not in p:
            txt = (p.get("extract") or "").replace("\n", " ")[:200]
            print(f"  [{p['title']}] {txt}")
    time.sleep(0.3)

json.dump(present, open("/tmp/c461-wiki2.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c461-wiki2.json")
