# تحسين سرعة فتح الموقع

## 1) بناء نسخة Release (مهم جدًا)
لو بترفع الموقع بأمر عادي زي:
```
flutter build web
```
ده ممكن يبني نسخة debug/غير محسّنة حسب إعداداتك. الصحيح دايمًا:
```
flutter build web --release
```
ده بيقلل حجم ملف main.dart.js بشكل كبير (tree-shaking + minification)، وده أكبر عامل في سرعة أول فتح لموقع Flutter Web.

اختياري لتقليل الحجم أكتر:
```
flutter build web --release --wasm
```
(لو نسخة الـ Flutter بتاعتك بتدعم WebAssembly renderer، بيكون أسرع من الافتراضي).

## 2) بعد البناء
غير الفولدر اللي بيتولد جوه `build/web` بتاع الاستضافة القديمة بالكامل — ملفاته لازم تكون طازة من أمر `--release` مش من نسخة تجربة (`flutter run -d chrome`).

## 3) اللي عملناه بالفعل في الكود
- الموقع بقى يعرض السبلاش فورًا بدل ما ينتظر Supabase.
- بطّلنا انتظار خطوط Google عبر الإنترنت (GoogleFonts.config.allowRuntimeFetching = false) — التفاصيل والخطوات لو عايز ترجع شكل خط Poppins نفسه، موجودة في تعليق فوق class AppColors في lib/theme/app_theme.dart.
