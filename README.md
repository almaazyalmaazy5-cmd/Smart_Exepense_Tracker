# 💰 Smart Expense & Budget Tracker (تطبيق إدارة المصاريف والميزانية الذكي)

تطبيق متكامل وعالي الأداء لإدارة المصاريف وتتبع الميزانية الشخصية، مبني بأحدث معايير **Flutter** و **Clean Architecture** مع دعم التخزين المحلي والعمل دون اتصال بالإنترنت (Offline-First).

---

## 🌟 مميزات التطبيق الرئيسية (Key Features)

* 📊 **لوحة تحكم مالية شاملة (Financial Dashboard):**
  * عرض إجمالي الرصيد، إجمالي الدخل، وإجمالي المصاريف ببطاقة تفاعلية مميزة.
  * فلترة الحركات بحسب التصنيف (طعام، مواصلات، تسوق، فواتير...).
  * إضافة وحذف المعاملات بسلاسة مع دعم التراجع والتأكيد.

* 💡 **المستشار المالي الذكي (AI Smart Financial Insights):**
  * محرك ذكي يقوم بتحليل النمط الاستهلاكي للمستخدم وتقديم نصائح توفير وتنبيهات عند زيادة الصرف على بند معين.
  * مراقبة معدل الادخار ومقارنته بالمعدل العالمي الموصى به.

* 📈 **تحليلات ورسوم بيانية تفاعلية (Interactive Charts):**
  * مخطط دائري (Donut / Pie Chart) تفاعلي يوضح نسب توزيع المصاريف لكل فئة باستخدام مكتبة `fl_chart`.
  * شريط تقدم يوضح استهلاك كل بند مقارنة بإجمالي النفقات.

* 🎯 **إدارة الميزانية وتنبيهات الاستهلاك (Smart Budgeting):**
  * تحديد سقف الإنفاق الشهري ومتابعة المتبقي بصرياً.
  * نظام تنبيه لوني ثلاثي:
    * 🟢 المنطقة الآمنة (< 80%).
    * 🟠 منطقة التحذير (80% - 100%).
    * 🔴 منطقة الخطر وتجاوز الميزانية (> 100%).
  * نصائح مالية مبنية على قاعدة إدارة الأموال الشهيرة (50/30/20).

* ⚙️ **التخصيص وتعدد العملات (Multi-Currency & Themes):**
  * دعم كامل لتعدد العملات: الدولار ($)، الريال السعودي (ر.س)، الريال اليمني (ر.ي)، الدرهم الإماراتي (د.إ)، الجنيه المصري (ج.م)، واليورو (€).
  * دعم الوضع الليلي (Dark Mode) والوضع النهاري (Light Mode) المتوافق مع Material 3.
  * واجهة عربية كاملة مصممة من اليمين إلى اليسار (RTL).

---

## 🏗 المعمارية النظيفة (Clean Architecture)

تم تقسيم المشروع هندسياً لعزل المنطق عن واجهة المستخدم وتسهيل الاختبار والتطوير:

```text
lib/
├── core/
│   ├── constants/       # ثوابت التطبيق، التصنيفات، والعملات
│   ├── theme/           # ثيمات Material 3 (نهاري / ليلي)
│   └── utils/           # دوال تنسيق التواريخ والعملات
│
├── data/
│   ├── datasources/     # خدمة التخزين المحلي الدائم (LocalStorageService)
│   ├── models/          # نماذج البيانات (Transaction, Category, Budget)
│   └── repositories/    # تطبيق مستودع البيانات الفعلي (ExpenseRepositoryImpl)
│
├── domain/
│   └── repositories/    # عقود الواجهات البرمجية (ExpenseRepository Interface)
│
└── presentation/
    ├── providers/       # إدارة الحالة (ExpenseProvider, BudgetProvider, ThemeProvider)
    ├── screens/         # شاشات التطبيق (الرئيسية، الإضافة، التحليلات، الميزانية، الإعدادات)
    └── widgets/         # العناصر المخصصة (SummaryCard, TransactionTile, SmartBanner)
```

---

## 🛠 التقنيات والمكتبات المستخدمة (Tech Stack)

* **Framework:** [Flutter](https://flutter.dev/) (Channel Stable, Dart 3)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Charts & Visuals:** [fl_chart](https://pub.dev/packages/fl_chart)
* **Local Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences)
* **Formatting & Dates:** [intl](https://pub.dev/packages/intl)
* **Testing:** `flutter_test` (Unit tests for Providers & Business Logic)

---

## 🧪 اختبارات الكود (Unit Testing)

المشروع مغطى باختبارات وحدية للتأكد من سلامة الحسابات المالية:
```bash
flutter test
```
**النتيجة:**
```text
00:01 +4: All tests passed!
```

---

## 🚀 طريقة التشغيل (How to Run)

1. استنساخ المستودع (Clone the repository):
   ```bash
   git clone https://github.com/almaazyalmaazy5-cmd/Smart_Exepense_Tracker.git
   ```
2. تثبيت الحزم (Install dependencies):
   ```bash
   cd Smart_Exepense_Tracker
   flutter pub get
   ```
3. تشغيل التطبيق على المنصة المرغوبة:
   * **Chrome (الويب):**
     ```bash
     flutter run -d chrome
     ```
   * **Windows (سطح المكتب):**
     ```bash
     flutter run -d windows
     ```
   * **Android (الهاتف):**
     ```bash
     flutter run -d android
     ```

---

## 👨‍💻 المطور (Developer)
* **عبد الله المعازي (Abdullah Almaazy)**
* كلية الحاسوب وتكنولوجيا المعلومات
* مطور تطبيقات هواتف ذكية (Flutter Mobile Developer)
