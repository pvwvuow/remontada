// cycle414-guard-test.ts — fix cycle 414, the UNIT half of the evidence.
// Imports the REAL defectiveFaTitle from src/lib/news (the exact function
// translateBatch consults) and asserts it on the four live defective mixed-
// script titles captured by the cycle-414 probe on the poisoned news:v3 row
// («آستون villa», «فerguson», «مikel آرتا», «فان دیjk»), on clean Persian
// titles from the same live row, on the whitelist cases (VAR/xG stay legal),
// and on the pure-English honest-fallback shape. Run: bun scripts/cycle414-guard-test.ts
import { defectiveFaTitle } from "../src/lib/news";

const cases: [string, boolean, string][] = [
  // the four live defects (byte-copies from the poisoned row)
  ["پائو تورس از آستون villa از بازی با لامین یمال لذت میبرد", true, "live defect 0"],
  ["چرا منچستر یونایتد پس از فerguson در استخدام مربیان ضعیف است", true, "live defect 2"],
  ["دکلن رایس: مikel آرتا به من گفت 'من میتوانم بیشتر برای آرسنال انجام دهم'", true, "live defect 4"],
  ["پیرو هینکاپیه به ویرژیل فان دیjk پس از پیروزی آرسنال بر لیورپول", true, "live defect 10"],
  // clean Persian rows from the same live feed — must stay legal
  ["باشگاه ساندرلند که در انتهای جدول قرار دارد، قصد دارد با بریس به عنوان سرمربی ادامه دهد", false, "clean row 1"],
  ["سررسید برای فیفا برای پاسخ به ۴۲ سوال یوفا درباره اینفانتینو فرا رسیده است", false, "clean row 9 (فیفا/یوفا transliterated)"],
  ["کارل بشبی: هال سیتی ماجراجوی پس از ۲۸ سال پیادهروی از شیلی را خوشامد میگوید", false, "clean row 14"],
  // the whitelist — genuinely Latin football tokens stay acceptable
  ["داوری ویدئویی VAR دوباره در لیگ برتر تغییر میکند", false, "whitelist VAR"],
  ["چرا xG این فصل لیورپول افت کرده است", false, "whitelist xG"],
  ["توپ VAR و آمار xG هر دو در گزارش آمدند", false, "whitelist both"],
  // the honest-fallback shapes — pure Latin is not a defect
  ["Aston Villa's Pau Torres relishing chance to face Lamine Yamal", false, "pure English fallback"],
  ["Why Man United are bad at hiring managers post Ferguson", false, "pure English fallback 2"],
];

let fail = 0;
for (const [s, want, label] of cases) {
  const got = defectiveFaTitle(s);
  if (got !== want) {
    fail++;
    console.log(`FAIL [${label}] want=${want} got=${got} :: ${s}`);
  } else {
    console.log(`ok   [${label}]`);
  }
}
console.log(fail === 0 ? `GUARD-TEST PASS ${cases.length}/${cases.length}` : `GUARD-TEST FAIL ${fail} of ${cases.length}`);
process.exit(fail === 0 ? 0 : 1);
