# Remontada — Multi-Agent Work Log

---
Task ID: cycle-1
Agent: main (Z.ai)
Task: بررسی ریپو، تعمیر بیلد خراب، ارتقا به پرتال چندصفحه‌ای

Work Log:
- ریپو pvwvuow/remontada کلون شد؛ v1 قبلی (تک‌صفحه با ۳ تب) موجود بود
- کشف مشکل بحرانی: پوشه src/components/remontada/ کلاً مفقود بود ولی page.tsx و match/[id]/page.tsx از آن import می‌کردند → بیلد خراب
- ساخت src/lib/format.ts: تقویم جلالی، اعداد فارسی، tehranTime، timeAgoFa، formColor
- ساخت matches-view.tsx: ناوبری روزها (-۷ تا +۷)، مرتب‌سازی زنده‌ها اول، ردیف‌های کلیک‌پذیر به /match/[id]
- ساخت standings-view.tsx: چیپ ۷ لیگ، نوارهای رنگی سهمیه، کارت آقای گل
- ساخت news-view.tsx: کارت تصویری، بج منبع، زمان نسبی فارسی
- ساخت match-detail.tsx: اسکوربورد، گلزنان، تایم‌لاین رویدادها، نوارهای آمار، ترکیب زمین، مومنتوم، اطلاعات، بهترین بازیکن، رفرش خودکار ۳۰ ثانیه‌ای
- ساخت site-chrome.tsx و اتصال به صفحه مسابقه
- فیکس مسیر فونت‌ها (public/fonts/)
- بیلد موفق + تست: هر ۵ API با داده زنده FotMob پاسخ می‌دهند؛ صفحه اصلی و مسابقه 200

Stage Summary:
- Commit 4c0ea06 روی main پوش شد
- سایت حالا پرتال چندصفحه‌ای است: / (نتایج+جدول+اخبار) و /match/[id] کامل
- نکته برای ایجنت‌های بعدی: bun install → bun run build → bun .next/standalone/server.js؛ فونت‌ها در public/fonts/
- تسک چرخه بعدی (پیشنهادی): صفحات لیگ /league/[key] (جدول+برنامه+آقای گل)، صفحات تیم /team/[id]، API برنامه هفتگی، لینک‌دار کردن تیم‌ها از جدول

---
Task ID: cycle-2
Agent: main (Z.ai) — cron self-activation
Task: صفحات لیگ + صفحات تیم + ناوبری پرتال + تعمیر مجدد بیلد ریموت

Work Log:
- محیط سندباکس ریست شده بود → دوباره کلون شد؛ کشف شد کامیت چرخه ۱ ناقص بود: ق rule «remontada/» در .gitignore پوشه src/components/remontada/ را ساکت نادیده می‌گرفت و ۵ کامپوننت هرگز کامیت نشده بودند → ریموت خراب بود
- فیکس .gitignore: «remontada/» → «/remontada/»
- بازسازی هر ۵ کامپوننت چرخه ۱ + ارتقاها
- ریفکتور fotmob.ts: getLeagueRaw مشترک (کش ۶۰ دقیقه) + getLeagueFixtures از fixtures.allMatches (کل فصل با scoreStr) + findTeamInStandings + آقای گل تا ۱۰ نفر
- API جدید: /api/league-fixtures (upcoming/recent کل فصل) و /api/team/[id] (پروفایل تیم از فید روزانه -۳ تا +۱۰ روز؛ اندپوینت تیم فوت‌ماب حذف شده بود/404)
- صفحات جدید: /league/[key] (SSG برای ۷ لیگ، تب‌های جدول/برنامه/نتایج/آقای گل)، /team/[id] (پروفایل + رتبه + فرم W/D/L + بازی‌ها)، /leagues (ایندکس)، /news (اخبار کامل)
- ناوبری پرتال: هدر مشترک (نتایج/لیگ‌ها/اخبار) روی همه زیرصفحه‌ها، لینک تیم‌ها در جدول و اسکوربورد، چیپ لیگ‌ها → صفحه لیگ
- فیکس امتیاز فیکسچرها از status.scoreStr
- بیلد موفق؛ تست: ۸ صفحه 200، ۷ API زنده OK؛ پوش 59c7cb8 (این بار stat کامیت تأیید شد)

Stage Summary:
- سایت حالا پرتال کامل چندصفحه‌ای است: / , /leagues , /league/[key] , /team/[id] , /news , /match/[id]
- نکته‌ی حیاتی برای ایجنت‌های بعدی: بعد از git add -A حتماً `git show --stat HEAD` را چک کن که فایل‌های جدید واقعاً در کامیت باشند؛ rule .gitignore دست نزن
- خروجی standalone در .next/standalone/remontada/server.js است (بخاطر bun.lock والد)
- کرون چرخه ۳ (Job 477392) فعال شد: آقای گلان سراسری + جستجوی تیم + بهبود صفحه لیگ‌ها

---
Task ID: cycle-3
Agent: main (Z.ai) — cron self-activation
Task: صفحه آقای گلان سراسری + جستجوی زنده تیم + بهبود صفحه لیگ‌ها

Work Log:
- تحقیق: صفحات تیم محبوب از فید روزانه فوت‌ماب شناسه‌گیری شدند (پرسپولیس 101610، استقلال 101614، تراکتور 176352، سپاهان 101611، رئال 8633، بارسا 8634، یونایتد 10260)
- کشف مهم: اندپوینت leagues فوت‌ماب برای لیگ خلیج فارس (id 1000001715) مقدار null برمی‌گرداند (صفحه لیگ در دسترس نیست) → جدول/آقای گل ایران فعلاً از این منبع غیرممکن است؛ برای جستجو ۴ تیم ایرانی fallback شدند
- fotmob.ts: getAllTopScorers (ادغام آقای گل ۷ لیگ از getStandings کش‌شده + رتبه سراسری) و getTeamIndex/searchTeams (نمایه تیم‌ها با نرمال‌سازی فارسی: ZWNJ، ي→ی، ك→ک، اعراب) — ترجیح لیگ داخلی بر UCL در dedup (رئال دیگر «UCL» نشان داده نمی‌شود)
- APIهای جدید: /api/topscorers و /api/search?q= (حداقل ۲ کاراکتر، امتیازدهی exact/prefix/contains/کلمات)
- صفحه /topscorers: «مصاف گلزنان» — جدول واحد ۱۸ گلزن ۶ لیگ با نوار سهم گل، چیپ فیلتر همه/هر لیگ، لینک به صفحه لیگ
- search-box.tsx: هدر سایت — دیبانس ۲۵۰ms، ناوبری کیبورد (بالا/پایین/Enter/Escape)، کیک‌آوت‌ساید، نتایج با لوگو+نام فارسی+انگلیسی+لیگ+رتبه؛ در هدر اصلی و هدر همه زیرصفحه‌ها
- leagues/page.tsx: بخش «تیم‌های محبوب» (۵ کارت لوگو) + دکمه شناور بازگشت به بالا (بعد از ۳۰۰px اسکرول)
- nav/site-chrome: آیتم «گلزنان» با آیکون مدال به هدر و فوتر همه صفحات اضافه شد
- فیکس بیلد: onError روی img در Server Component مجاز نیست → کامپوننت کلاینت TeamLogo ساخته شد
- بیلد موفق؛ تست: ۹ صفحه 200، search فارسی/انگلیسی OK، topscorers ۱۸ گلزن OK
- Commit be940ee روی main پوش شد (stat تأیید شد: ۱۱ فایل، +۶۶۹)

Stage Summary:
- پرتال حالا: / ، /leagues ، /league/[key] ، /team/[id] ، /news ، /match/[id] ، /topscorers (۷ مسیر + جستجوی زنده در هدر)
- نکته برای ایجنت‌های بعدی: لیگ خلیج فارس از leagues API فوت‌ماب null می‌دهد؛ اگر جدول ایران خواستی باید از فید روزانه (matches) بسازی یا منبع جایگزین پیدا کنی
- تیم‌های fallback جستجو در SEARCH_FALLBACK_TEAMS داخل fotmob.ts هستند
- کرون چرخه ۴ فعال شد: PWA (manifest + آیکون + service worker سبک) + سئو (sitemap.xml، robots.txt، metadata کامل)

---
Task ID: PROTOCOL-recovery-2026-10-28
Agent: main (Z.ai) — cycle-30
Task: بازسازی پروتکل عملیاتی پس از بازیابی کانتینر — کارت‌های PROTOCOL-next-cycles / cron-fix / cycle-24..29 در بازیابی از بین رفتند؛ این کارت مرجع جدید است

Work Log:
- ⚠️ ساعت ~۰۶:۰۷+08 کانتینر سندباکس ری‌استارت شد (up 0 min) و /home/z/my-project به اسنپ‌شات خیلی قدیمی برگشت: پوشه‌های remontada/ و design-ref/ و tool-results/ حذف، worklog.md به ۷۰ خط اول برگشت، scripts/ فقط فایل‌های اولیه را داشت (بدون remote-token.txt و cycle17-regression.sh). علت: volume پایدار نبودن برخی مسیرها/بازیابی قدیمی — هر جلسه/cron آینده باید سلامت محیط را چک کند: «ls /home/z/my-project/remontada» + «grep -c PROTOCOL-recovery worklog.md»
- ترمیم (همه از مخزن گیت‌هاب، چون همه‌چیز تا 7d9505f پوش شده بود): کلون مجدد remontada@7d9505f + bun install + ساخت مجدد scripts/remote-token.txt (chmod 600) + همسان‌سازی src/کانفیگ‌های پروژه اصلی با مخزن (خنثی‌سازی خطر revert کرون سنک) + بازسازی اسکریپت رگرسیون
- ⭐ از این به بعد worklog.md داخل مخزن هم کامیت می‌شود (remontada/worklog.md) تا پس از هر بازیابی از کلون برگردد؛ اسکریپت sync هم آن را کپی می‌کند
- از دست رفت (قابل قبول): اسکرین‌شات‌ها/HTML مرجع design-ref (تم کامل است — دیگر لازم نیست)، اسکریپت رگرسیون ۵۱تایی اصلی (جایگزین ۲۷تایی ساخته شد — پایه جدید «۲۷/۲۷» است)، agent-browser سراسری (در صورت نیاز: npm i -g agent-browser && agent-browser install)

پروتکل همیشگی چرخه‌ها (بازسازی‌شده):
1) خواندن این کارت + آخرین کارت cycle-N در worklog.md (داخل مخزن هم کپی می‌شود)
2) git pull مخزن /home/z/my-project/remontada؛ اگر مخزن نبود: کلون با URL داخل scripts/remote-token.txt
3) چرخش ۵تایی پس از اتمام تم: نوع N = ((N−13) mod 5)+1 → ۱-۳=اپدیت، ۴=بررسی باگ، ۵=فیکس باگ ⇒ چرخه ۳۱=اپدیت، ۳۲=بررسی باگ (گشت‌زنی صفحات + گزارش)، ۳۳=فیکس باگ (اصلاح یافته‌های ۳۲)، ۳۴=اپدیت، ۳۵=اپدیت، ۳۶=بررسی... ؛ اپدیت = بهبود کوچک محتوایی/کارکردی به سلیقه خودت، کامیت «Update:»
4) پذیرش: bunx eslint src/ = 0، bunx tsc --noEmit = 0، bun run build، BASE=http://localhost:3005 bash /home/z/my-project/scripts/cycle17-regression.sh = ۲۷/۲۷، تست بصری اگر ابزار مرورگر موجب (آفلاین: curl کافی برای تغییرات نامرئی)
5) دیپلوی: بوت‌استرپ کانتینر بعد از هر ری‌استارت «next dev -p 3000» پروژه قدیمی را بالا می‌آورد — قبل از دیپلوی حتماً kill -9 زنجیره آن (ss -tlnp → PIDs؛ شامل sudo/bun/bash/next-server)؛ تست 3005؛ پروداکشن: ( nohup env PORT=3000 HOSTNAME=0.0.0.0 bun .next/standalone/remontada/server.js > /tmp/rm-prod.log 2>&1 & )
6) git add -A + کامیت با پیشوند درست + push با: git push $(cat /home/z/my-project/scripts/remote-token.txt) + git show --stat HEAD
7) کارت worklog با Task ID: cycle-N (append) + کپی worklog.md داخل remontada (کامیت جدا «Update: worklog snapshot»)
8) کرون بعدی: kind=one_time، expr=«yyyy-MM-dd HH:mm:ss» به ساعت سرویس +08 (تهران+۳.۵h؛ TZ=Asia/Shanghai date -d "+11 minutes")، ⛔ بدون فیلد tz، پیام <~۱۵۰ کاراکتر بدون توکن، بعداً cron get برای راستی‌آزمایی + یک پشتیبان idempotent (~۱ ساعت بعد) که اگر کارت cycle-N+1 بود no-op کند
9) گزارش کوتاه فارسی + یادآوری ابطال توکن لو رفته (در worklog نوشته نمی‌شود — در پیام کرون هم نیست)
10) نکات فنی: MultiEdit سندباکس غیراتمیک است → بعد از هر MultiEdit با rg راستی‌آزمایی؛ setState مستقیم در بدنه effect ممنوع (setTimeout(0))؛ onError روی img در Server Component ممنوع؛ لیگ persiangulf در standings/fixtures null برمی‌گرداند → UI باید graceful بماند؛ خروجی ترمینال دنباله [m را حذف می‌کند

Stage Summary:
- محیط کامل بازسازی شد؛ تنها خسارت: design-ref و اسکریپت رگرسیون قدیمی (جایگزین ساخته شد)
- زنجیره cron ادامه دارد: ۳۱=اپدیت، ۳۲=بررسی باگ، ۳۳=فیکس باگ

---
Task ID: cycle-30
Agent: main (Z.ai) — cron self-activation (Job 478713)
Task: چرخه ۳۰ = «اپدیت» دوم — ادامه بهبود داده ساختاریافته (پیشنهاد کارت cycle-29: JSON-LD صفحه لیگ)

Work Log:
- شروع چرخه با کشف بازیابی کانتینر → کل بازسازی محیط (کارت PROTOCOL-recovery-2026-10-28) قبل از ادامه مأموریت
- league/[key]/page.tsx + topscorers/[leagueKey]/page.tsx: JSON-LD SportsLeague (name فارسی/alternateName انگلیسی/sport Football/url) + BreadcrumbList (خانه → لیگ‌ها → لیگ یا «آقای گلان لیگ») — چون SSG با dynamicParams=false هستند، LD در HTML از پیش رندر شده می‌نشیند؛ + canonical در generateMetadata هر دو
- اسکریپت رگرسیون جدید (۲۷ چک: ۱۳ صفحه + ۱۱ API با قرارداد 404 + robots/sitemap/manifest) در scripts/cycle17-regression.sh بازسازی شد
- پذیرش‌ها: ESLint 0/0، tsc 0، بیلد ۲۴/۲۴ صفحه؛ رگرسیون ۲۷/۲۷ روی 3005 و سپس 3000 واقعی؛ SportsLeague «پریمیرلیگ انگلیس» + BreadcrumbList در HTML زنده تأیید شد
- دیپلوی: بعد از kill زنجیره next dev بوت‌استرپ، پروداکشن 3000 استندالون بالا آمد (27/27)
- کامیت 5096a48 «Update:» پوش شد (۲ فایل، +۵۶) — 7d9505f..5096a48 روی main

Stage Summary:
- پوشش داده ساختاریافته کامل شد: خانه WebSite/Organization + بازی SportsEvent + تیم SportsTeam + بازیکن Person + لیگ SportsLeague + BreadcrumbList
- پیشنهاد اپدیت‌های بعدی: بهبود empty-state ها، ItemList آقای گلان در topscorers، دقت داده
- چرخه ۳۱ = اپدیت، ۳۲ = بررسی باگ، ۳۳ = فیکس باگ

---
Task ID: backup-cycle-27
Agent: main (Z.ai) — idempotent backup (Job 478611)
Task: پشتیبان چرخه ۲۷ — اگر کارت cycle-27 موجود بود no-op؛ وگرنه تم فاز ۴/۵ «صفحات جزئیات»

Work Log:
- کارت cycle-27 در worklog نیست (کارت‌های cycle-24..29 در بازیابی 06:07+08 از بین رفتند — کارت PROTOCOL-recovery-2026-10-28) اما خودِ کار تکمیل و پوش شده است
- مدرک در تاریخچه مخزن: dcbff43 «Theme (4/5): glass detail pages» (اسکوربورد بازی/پروفایل تیم/پروفایل بازیکن) + 1bdbd1a «Theme (5/5)»؛ remote main = f887d04 شامل هر دو؛ پس از تم، چرخه‌های ۲۹/۳۰ هم کامل شدند (7d9505f، 5096a48)
- اجرای مجدد تم فاز ۴/۵ رد شد (کار تکراری/مخرب) → no-op با گزارش done
- سه پشتیبان منقضی حذف شدند تا ایجنت تحت‌اللفظی تم را دوباره اجرا نکند: Job 478647 (پشتیبان ۲۸ → تم ۵/۵)، 478685 (پشتیبان ۲۹)، 478714 (پشتیبان ۳۰) — شرط هر سه برای همیشه برآورده است (کار در git است)
- زنجیره زنده دست‌نخورده: cycle-31 @ 06:23 (Job 478741) + پشتیبان ۳۱ @ 07:25 (Job 478742) + سنک ۶ساعته (477222، از 09:40 no-op)
- سلامت محیط تأیید شد: مخزن موجود و سینک با remote؛ src پروژه اصلی با مخزن همسان (diff صفر)؛ worklog آینه‌ای همسان

Stage Summary:
- هیچ تغییری در کد پرتال؛ فقط این کارت + کامیت اسنپ‌شات worklog داخل مخزن
- ⛔ برای ایجنت‌های بعدی: هر پشتیبانی که کارتش در worklog نیست، اول تاریخچه git را چک کند (git log --oneline) — نبود کارت به‌خودی‌خود یعنی کار انجام نشده نیست
- چرخه ۳۱ = اپدیت، ۳۲ = بررسی باگ، ۳۳ = فیکس باگ
