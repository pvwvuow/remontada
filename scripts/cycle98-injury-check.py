#!/usr/bin/env python3
# cycle-98 bug-hunt cross-check — cycle-96 injury card values vs RAW probes for
# two players NOT verified in cycle-96 (Gabbia 844996, Asencio 1580528), using
# the raw playerData JSONs captured live in the cycle-96 sweep.
# Compares: nameFa (27-entry map logic), returnFa (expectedReturnKey + month
# param), updatedFa (Tehran +3.5h then Gregorian→Jalali).
import json, urllib.request

RAW = "/home/z/my-project/scripts"

INJURY_FA = {
    "injured": "آسیب‌دیدگی", "knock": "ضربه", "illness": "بیماری",
    "physical discomfort": "ناراحتی جسمی", "suspension": "محرومیت",
    "red card suspension": "محرومیت با کارت قرمز",
    "ankle injury": "آسیب‌دیدگی مچ پا", "knee injury": "آسیب‌دیدگی زانو",
    "thigh injury": "آسیب‌دیدگی ران", "calf injury": "آسیب‌دیدگی ساق پا",
    "groin injury": "آسیب‌دیدگی کشالهٔ ران", "hamstring injury": "آسیب‌دیدگی همسترینگ",
    "foot injury": "آسیب‌دیدگی پا", "leg injury": "آسیب‌دیدگی پا",
    "back injury": "آسیب‌دیدگی کمر", "hip injury": "آسیب‌دیدگی لگن",
    "shoulder injury": "آسیب‌دیدگی شانه", "wrist injury": "آسیب‌دیدگی مچ دست",
    "toe injury": "آسیب‌دیدگی انگشت پا", "muscle injury": "آسیب‌دیدگی عضلانی",
    "tendon injury": "آسیب‌دیدگی تاندون", "ligament injury": "آسیب‌دیدگی رباط",
    "cruciate ligament injury": "پارگی رباط صلیبی",
    "achilles tendon injury": "آسیب‌دیدگی تاندون آشیل",
    "meniscus injury": "آسیب‌دیدگی منیسک", "concussion": "آسیب‌دیدگی سر",
    "coronavirus": "کرونا",
}
PREFIX_FA = {"expected_return_date_early": "اوایل", "expected_return_date_mid": "اواسط", "expected_return_date_late": "اواخر"}
KEY_FA = {"expected_return_date_doubtful": "مشارکت مشکوک", "expected_return_date_back_in_training": "بازگشت به تمرین"}
MONTH_FA = {"january": "ژانویه", "february": "فوریه", "march": "مارس", "april": "آوریل", "may": "مه",
            "june": "ژوئن", "july": "ژوئیه", "august": "اوت", "september": "سپتامبر", "october": "اکتبر",
            "november": "نوامبر", "december": "دسامبر"}
FA_DIGITS = str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹")

def g2j(gy, gm, gd):
    # standard jdf.scr.ir (jalaali) algorithm — the compact variant first used
    # here was off by 6 days (false positive on the APP, which was correct)
    g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    jy = 0 if gy <= 1600 else 979
    gy -= 621 if gy <= 1600 else 1600
    gy2 = gy + 1 if gm > 2 else gy
    days = (365 * gy) + ((gy2 + 3) // 4) - ((gy2 + 99) // 100) + ((gy2 + 399) // 400) - 80 + gd + g_d_m[gm - 1]
    jy += 33 * (days // 12053); days %= 12053
    jy += 4 * (days // 1461); days %= 1461
    jy += (days - 1) // 365
    if days > 365:
        days = (days - 1) % 365
    jm = 1 + days // 31 if days < 186 else 7 + (days - 186) // 30
    jd = 1 + (days % 31 if days < 186 else (days - 186) % 30)
    return jy, jm, jd

JMONTH = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"]

def updated_fa(iso):
    import datetime
    t = datetime.datetime.fromisoformat(iso.replace("Z", "+00:00")) + datetime.timedelta(hours=3.5)
    jy, jm, jd = g2j(t.year, t.month, t.day)
    return f"{str(jd).translate(FA_DIGITS)} {JMONTH[jm-1]} {str(jy).translate(FA_DIGITS)}"

def expected_from_raw(inj):
    name = inj["name"]
    fa = INJURY_FA.get(name.lower())
    # app contract: nameEn kept ONLY when a Persian mapping exists (title attr)
    out = {"nameFa": fa or name}
    if fa:
        out["nameEn"] = name
    ret = None
    er = inj.get("expectedReturn") or {}
    key = er.get("expectedReturnKey") or ""
    param = (er.get("expectedReturnDateParam") or "").strip()
    param_fa = " ".join(MONTH_FA.get(w.lower(), w.translate(FA_DIGITS)) for w in param.split()) if param else ""
    if key in KEY_FA: ret = KEY_FA[key]
    elif key in PREFIX_FA and param_fa: ret = f"{PREFIX_FA[key]} {param_fa}"
    elif param_fa: ret = f"بازگشت: {param_fa}"
    lu = (inj.get("lastUpdated") or {}).get("utcTime")
    out["returnFa"] = ret
    out["updatedFa"] = updated_fa(lu) if lu else None
    return out

def fetch(url):
    with urllib.request.urlopen(url, timeout=20) as r:
        return json.load(r)

ok = True
for pid in (844996, 1580528):
    raw = json.load(open(f"{RAW}/cycle96-p{pid}.json", encoding="utf-8"))
    want = expected_from_raw(raw["injuryInformation"])
    app = fetch(f"http://localhost:3000/api/player/{pid}")
    got = app.get("injury") or (app.get("player") or {}).get("injury")
    match = got == want
    ok &= match
    print(f"player={pid} match={match}\n  want={json.dumps(want, ensure_ascii=False)}\n  got ={json.dumps(got, ensure_ascii=False)}")
print("ALL-CHECKS-OK" if ok else "MISMATCH")
