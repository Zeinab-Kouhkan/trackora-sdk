# راهنمای فارسی SDK انتساب و اتریبیوشن Trackora

**Trackora** یک SDK متن‌باز و سبک برای دریافت، استانداردسازی و تحلیل داده‌های اتریبیوشن (منبع نصب و کمپین‌های تبلیغاتی) در اپلیکیشن‌های فلاتر (Flutter) است.

این کتابخانه برای استورهای جهانی و ایرانی طراحی شده و از **Google Play**، **کافه‌بازار (CafeBazaar)** و **مایکت (Myket)** به‌همراه **iOS** و **Web** پشتیبانی می‌کند.

---

## ویژگی‌های کلیدی

- **استقلال کامل از سرور اختصاصی:** ترَکورا هیچ سرور اختصاصی، آدرس اجباری یا کلاینت شبکه پنهانی ندارد. داده‌ها کاملاً محلی در گوشی کاربر باقی می‌مانند و توسعه‌دهنده در صورت تمایل می‌تواند آن‌ها را به سرور اختصاصی خود بفرستد.
- **ایزولاسیون کامل وابستگی‌ها در زمان بیلد (Build-Time Store Isolation):** پکیج هسته (`trackora`) هیچ وابستگی به استور خاصی ندارد. شما فقط آداپتور استوری را اضافه می‌کنید که قصد انتشار در آن را دارید (مثلاً در نسخه‌ای که برای مایکت خروجی می‌گیرید نیازی به وابستگی‌های گوگل‌پلی یا بازار نیست).
- **استانداردسازی پارامترهای UTM و شناسه کلیک:** پارامترهای `utm_source`، `utm_medium`، `utm_campaign`، `utm_id`، `utm_term`، `utm_content` و شناسه‌های کلیک نظیر `gclid`، `fbclid`، `ttclid` و غیره را به صورت امن و بدون تداخل دیکود می‌کند.
- **پشتیبانی از دیپ‌لینک و یونیورسال‌لینک:** قابلیت پردازش پیوندهای ورودی در هنگام باز شدن اپلیکیشن.

---

## جدول انتخاب پکیج‌ها

| کانال انتشار | پکیج‌های مورد نیاز در `pubspec.yaml` |
|---|---|
| **فقط گوگل‌پلی** | `trackora`, `trackora_google_play` |
| **فقط کافه‌بازار** | `trackora`, `trackora_cafebazaar` |
| **فقط مایکت** | `trackora`, `trackora_myket` |
| **چند استوره (مولتی‌استور)** | `trackora`, `trackora_google_play`, `trackora_cafebazaar`, `trackora_myket` |
| **وب / iOS** | `trackora` (نیازی به آداپتورهای استور اندروید نیست) |

---

## نحوه راه‌اندازی سریع

### ۱. افزودن به `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  trackora: ^0.1.0
  trackora_cafebazaar: ^0.1.0 # یا trackora_myket / trackora_google_play
```

### ۲. مقداردهی اولیه در `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_cafebazaar/trackora_cafebazaar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Trackora.initialize(
    adapters: [
      CafeBazaarStoreAdapter(),
    ],
  );

  runApp(const MyApp());
}
```

### ۳. دریافت داده‌های اتریبیوشن

```dart
Future<void> fetchAttributionData() async {
  final attribution = await Trackora.instance.getAttribution();

  if (attribution.status == AttributionStatus.available) {
    debugPrint('منبع کمپین: ${attribution.source}');
    debugPrint('نام کمپین: ${attribution.campaign}');
    debugPrint('شناسه کلیک: ${attribution.clickId}');
    debugPrint('مدیوم: ${attribution.medium}');
  } else if (attribution.status == AttributionStatus.notAvailable) {
    debugPrint('نصب ارگانیک (بدون ریفرر کمپین)');
  }
}
```

### ۴. ارسال اختیاری به بک‌اند اختصاصی شما

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendToMyServer(AttributionData data) async {
  if (data.status != AttributionStatus.available) return;

  await http.post(
    Uri.parse('https://api.mycompany.ir/v1/attribution'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data.toJson()),
  );
}
```
