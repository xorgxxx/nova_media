# البناء السحابي وتنزيل APK عبر GitHub Actions

> **تم بالفعل ✅** — المشروع مرفوع على
> https://github.com/xorgxxx/nova_media والبناء نجح.
> **تحميل الـ APK مباشرة (بدون تسجيل دخول):**
> https://github.com/xorgxxx/nova_media/releases/download/v1.0.0/app-release.apk
>
> | | |
> |---|---|
> | اسم الحزمة | `com.novamedia.nova_media` |
> | الإصدار | `1.0.0` (versionCode 1) |
> | الحجم | 56,460,374 بايت (53.9 ميجا) |
> | SHA-256 | `f73afeb0366310d6da132d1596e13904b475252c16713e23a1c7ddbfa9d1b451` |
> | التوقيع | مفتاح debug (للتجربة فقط، ليس لـ Google Play) |
> | صفحة الـ Release | https://github.com/xorgxxx/nova_media/releases/tag/v1.0.0 |

هذا المستند يشرح المسار الكامل: من رفع المشروع إلى GitHub، إلى تشغيل البناء
على خوادم GitHub، إلى تنزيل ملف `app-release.apk` وتثبيته على الجوال.
**لا تحتاج إلى تنزيل Flutter أو Android SDK، ولا تحتاج إلى كتابة أي كود.**

---

## 0. الفكرة باختصار

```
مشروع nova_media  →  GitHub (كود فقط)  →  GitHub Actions (خادم Ubuntu)
                                             ├─ JDK 17 + Flutter 3.47.9
                                             ├─ Android SDK 36 + NDK
                                             ├─ flutter analyze / test
                                             ├─ flutter build apk --release
                                             └─ app-release.apk  →  Artifact
                                                        ↓
                                              تنزيل (~25–40 ميجا) → تثبيت
```

---

## 1. المتطلبات

- حساب GitHub مجاني (https://github.com/signup).
- متصفح على الكمبيوتر لتسجيل الدخول مرة واحدة.
- لا حاجة لأي شيء آخر: Git مثبّت على الجهاز، وكل الأوامر ينفّذها الوكيل.

---

## 2. إنشاء المستودع (مرة واحدة)

1. افتح https://github.com/new
2. في خانة **Repository name** اكتب: `nova_media`
3. اختر **Public** (مجاني بلا حدود لدقائق Actions).
4. **لا** تضع علامة على `Add a README file` أو `.gitignore` أو `license`
   (يجب أن يكون المستودع فارغاً حتى لا يحدث تعارض عند الرفع).
5. اضغط **Create repository**.
6. انسخ رابط المستودع الذي يظهر، مثل:
   `https://github.com/USERNAME/nova_media.git`

أخبر الوكيل باسم المستخدم (USERNAME) فقط؛ سيتولى الباقي.

---

## 3. رفع المشروع (مرة واحدة)

ينفّذ الوكيل هذه الخطوات نيابةً عنك:

```bash
git init
git add .
git commit -m "Nova Media: initial commit"
git branch -M main
git remote add origin https://github.com/USERNAME/nova_media.git
git push -u origin main
```

عند تنفيذ `git push` ستظهر **نافذة متصفح** لتسجيل الدخول إلى GitHub
(Git Credential Manager مثبّت مسبقاً مع Git). سجّل الدخول واضغط **Authorize**.
تحدث هذه العملية مرة واحدة فقط.

بعد نجاح الرفع سترى ملفات المشروع في صفحة المستودع.

---

## 4. تشغيل البناء

### تلقائياً
كل عملية `git push` إلى الفرع `main` (أو `master`) تشغّل البناء تلقائياً.

### يدوياً
1. افتح المستودع على GitHub.
2. تبويب **Actions**.
3. من القائمة اليسرى اختر **Android APK Build**.
4. اضغط الزر الأيمن **Run workflow** → **Run workflow**.

مدة البناء المتوقعة: **5–10 دقائق** (البناء الأول أطول قليلاً بسبب تنزيل
الاعتماديات؛ البناءات التالية أسرع بفضل الكاش).

---

## 5. متابعة البناء ومعرفة النتيجة

داخل صفحة التشغيل سترى الخطوات بالترتيب:

| الخطوة | معناها |
|---|---|
| Set up JDK 17 | تثبيت Java 17 |
| Set up Flutter | تثبيت Flutter 3.47.9 |
| Set up Android SDK | تثبيت platform 36 + build-tools + NDK |
| Install Dart/Flutter dependencies | `flutter pub get` |
| Analyze | فحص الكود (أخطاء الترجمة تُفشل البناء) |
| Run tests | اختبارات `test/` |
| Bootstrap Android project | `tool/bootstrap.sh` |
| Build release APK | إنشاء APK |
| Verify APK | التحقق من وجود الملف ومحتواه |
| Upload APK artifact | حفظ الملف للتنزيل |

- ✅ علامة صح خضراء = نجاح.
- ❌ علامة خطأ حمراء = فشل؛ افتح الخطوة الحمراء واقرأ آخر رسالة خطأ.

---

## 6. تنزيل ملف APK

### الطريقة الأولى — الرابط المباشر (الأسهل، بدون تسجيل دخول)

```
https://github.com/xorgxxx/nova_media/releases/download/v1.0.0/app-release.apk
```

هذا رابط عام دائم، يدعم استئناف التنزيل عند انقطاع الشبكة. بجانبه ملف
التحقق: `app-release.apk.sha256` (نفس المجلد على صفحة الـ Release).

### الطريقة الثانية — صفحة الملخص
1. افتح صفحة التشغيل.
2. في الأسفل ستجد قسم **Summary** يحتوي على:
   - اسم الملف وحجمه،
   - بصمة `SHA-256`،
   - رابط التحميل المباشر.
3. اضغط الرابط. (يتطلب تسجيل الدخول بحساب GitHub.)

### الطريقة الثالثة — قسم Artifacts
1. في أسفل صفحة التشغيل → قسم **Artifacts**.
2. اضغط **nova-media-apk** لتنزيل ملف ZIP.
3. فك ضغطه؛ ستجد:
   ```
   app-release.apk
   app-release.apk.sha256
   verify-apk.txt
   flutter-version.txt
   ```

> ملاحظة: ملفات Artifact تُحفظ **30 يوماً** ثم تُحذف تلقائياً. أما ملفات
> الـ Release فتبقى بشكل دائم.

---

## 7. تثبيت APK على الجوال

1. انقل `app-release.apk` إلى الجوال (كيبل USB، Google Drive، Telegram…).
2. افتح الملف من تطبيق **الملفات**.
3. إن ظهر تحذير، اسمح بـ **تثبيت التطبيقات من مصادر غير معروفة** لهذا التطبيق
   فقط (الإعدادات → التطبيقات → التثبيت من مصادر غير معروفة).
4. اضغط **تثبيت**.
5. عند أول فتح، امنح صلاحية الوصول إلى الوسائط (صور/فيديو/صوت).

---

## 8. ملاحظات مهمة

- **التوقيع:** الـ APK موقّع بمفتاح *debug* (كما ينص `AGENTS.md`)؛ يعمل
  للتثبيت المباشر والتجربة، لكن **Google Play لن يقبله**. النشر الرسمي يحتاج
  مفتاح توقيع (keystore) يُخزَّن في GitHub Secrets.
- **الخصوصية:** المستودع عام، أي أن الكود مرئي للجميع (لا توجد مفاتيح أو
  أسرار داخل الكود).
- **التكلفة:** المستودعات العامة لا تستهلك دقائق مدفوعة.
- **تحديث التطبيق:** عدّل الكود ثم `git push`؛ سيُبنى APK جديد. غيّر
  `version: 1.0.0+1` في `pubspec.yaml` إذا أردت ترقية رقم الإصدار.
- **بدون جهاز:** البناء يتحقق من سلامة الملف فقط (`tool/verify_apk.sh`)؛
  التشغيل الفعلي على الجوال هو الاختبار النهائي.

---

## 9. إذا فشل البناء

أرسل إلى الوكيل:
1. رابط صفحة التشغيل، أو
2. اسم الخطوة الحمراء + آخر 30 سطراً من سجلها.

سيقوم الوكيل بتعديل أصغر قدر ممكن من الكود (وفق `AGENTS.md`)، ثم يرفع
الإصلاح ويعيد البناء تلقائياً.
