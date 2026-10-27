// ------------------------------------------------------------------
// Remontada — shared Persian formatting helpers
// ------------------------------------------------------------------

const FA_DIGITS = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];

export function faDigits(input: string | number): string {
  return String(input).replace(/\d/g, (d) => FA_DIGITS[Number(d)]);
}

export function enDigits(input: string): string {
  return input
    .replace(/[۰-۹]/g, (d) => String("۰۱۲۳۴۵۶۷۸۹".indexOf(d)))
    .replace(/[٠-٩]/g, (d) => String("٠١٢٣٤٥٦٧٨٩".indexOf(d)));
}

// Tehran is UTC+3:30 (no DST since 2022)
export function tehranNow(): Date {
  return new Date(Date.now() + 3.5 * 3600_000);
}

/** "۱۴:۳۰" — clock time of an ISO timestamp in Tehran */
export function tehranTime(iso: string): string {
  if (!iso) return "";
  const d = new Date(new Date(iso).getTime() + 3.5 * 3600_000);
  if (Number.isNaN(d.getTime())) return "";
  const h = String(d.getUTCHours()).padStart(2, "0");
  const m = String(d.getUTCMinutes()).padStart(2, "0");
  return faDigits(`${h}:${m}`);
}

const FA_WEEKDAYS = [
  "یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه", "شنبه",
];
// Gregorian month names used in Iran (Gregorian is fine for intl fixtures)
const FA_GREG_MONTHS = [
  "ژانویه", "فوریه", "مارس", "آوریل", "مه", "ژوئن",
  "ژوئیه", "اوت", "سپتامبر", "اکتبر", "نوامبر", "دسامبر",
];

function gregorianToJalali(gy: number, gm: number, gd: number): [number, number, number] {
  const g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  let jy = gy <= 1600 ? 0 : 979;
  gy -= gy <= 1600 ? 621 : 1600;
  const gy2 = gm > 2 ? gy + 1 : gy;
  let days =
    365 * gy +
    Math.floor((gy2 + 3) / 4) -
    Math.floor((gy2 + 99) / 100) +
    Math.floor((gy2 + 399) / 400) -
    80 +
    gd +
    g_d_m[gm - 1];
  jy += 33 * Math.floor(days / 12053);
  days %= 12053;
  jy += 4 * Math.floor(days / 1461);
  days %= 1461;
  if (days > 365) {
    jy += Math.floor((days - 1) / 365);
    days = (days - 1) % 365;
  }
  const jm = days < 186 ? 1 + Math.floor(days / 31) : 7 + Math.floor((days - 186) / 30);
  const jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
  return [jy, jm, jd];
}

const FA_JALALI_MONTHS = [
  "فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
  "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند",
];

/** "دوشنبه ۵ آبان" — weekday + Jalali date for an ISO timestamp */
export function tehranDateLong(iso: string): string {
  if (!iso) return "";
  const utc = new Date(new Date(iso).getTime() + 3.5 * 3600_000);
  if (Number.isNaN(utc.getTime())) return "";
  const y = utc.getUTCFullYear();
  const m = utc.getUTCMonth() + 1;
  const d = utc.getUTCDate();
  const weekday = FA_WEEKDAYS[utc.getUTCDay()];
  const [jy, jm, jd] = gregorianToJalali(y, m, d);
  return `${weekday} ${faDigits(jd)} ${FA_JALALI_MONTHS[jm - 1]}`;
}

/** "۵ آبان" — short Jalali month/day (for day chips) */
export function jalaliShort(iso: string): { day: string; month: string; weekday: string } {
  const utc = new Date(new Date(iso).getTime() + 3.5 * 3600_000);
  const y = utc.getUTCFullYear();
  const m = utc.getUTCMonth() + 1;
  const d = utc.getUTCDate();
  const [jy, jm, jd] = gregorianToJalali(y, m, d);
  return {
    day: faDigits(jd),
    month: FA_JALALI_MONTHS[jm - 1],
    weekday: FA_WEEKDAYS[utc.getUTCDay()],
  };
}

/** ISO date (YYYYMMDD) of an offset day in Tehran — mirrors lib/fotmob dateKey */
export function offsetDateISO(offset: number): string {
  const t = tehranNow().getTime() + offset * 86400_000;
  return new Date(t).toISOString().slice(0, 10);
}

/** "۳ ساعت پیش" / "۲۰ دقیقه پیش" relative Persian time */
export function timeAgoFa(iso: string): string {
  if (!iso) return "";
  const diff = Date.now() - new Date(iso).getTime();
  if (Number.isNaN(diff) || diff < 0) return "همین حالا";
  const min = Math.floor(diff / 60_000);
  if (min < 1) return "همین حالا";
  if (min < 60) return `${faDigits(min)} دقیقه پیش`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${faDigits(hr)} ساعت پیش`;
  const d = Math.floor(hr / 24);
  if (d < 30) return `${faDigits(d)} روز پیش`;
  return tehranDateLong(iso);
}

/** Persian card color for form chips */
export function formColor(c: "W" | "D" | "L"): string {
  if (c === "W") return "bg-primary/15 text-primary border-primary/30";
  if (c === "D") return "bg-muted text-muted-foreground border-border";
  return "bg-destructive/15 text-destructive border-destructive/30";
}
