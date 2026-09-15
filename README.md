# Plant Disease AI (appgenai2)

แอป Flutter สำหรับเลือกภาพหรือถ่ายภาพใบพืช แล้วส่งให้ AI วิเคราะห์โรคพืช
ผลลัพธ์จะแสดงชื่อโรคภาษาไทย/ภาษาอังกฤษ คำอธิบายภาษาไทย ระดับความมั่นใจ
และคำแนะนำในการดูแล

## ความต้องการของระบบ

- Flutter 3.22.0 หรือเวอร์ชันที่โปรเจกต์ติดตั้งไว้
- Dart SDK ที่มากับ Flutter
- Android Studio/Android SDK สำหรับรันบน Android หรือ LDPlayer
- Google Chrome สำหรับรันบนเว็บ
- API key จาก UP AI Connect ของมหาวิทยาลัย

ตรวจสอบอุปกรณ์ที่ Flutter มองเห็นได้ด้วยคำสั่ง:

```powershell
flutter devices
```

## เตรียมโปรเจกต์ครั้งแรก

เปิดโฟลเดอร์โปรเจกต์ใน VS Code หรือเปิด PowerShell แล้วรัน:

```powershell
cd "D:\Mobile APP\appgenai2"
flutter pub get
```

ถ้าเจอปัญหา dependency หรือไฟล์ build ค้าง ให้ใช้คำสั่งนี้แล้วโหลด package ใหม่:

```powershell
flutter clean
flutter pub get
```

## ตั้งค่า API key

โปรเจกต์นี้ไม่เก็บ API key ไว้ใน source code โดยรับค่าผ่าน `--dart-define`

1. เข้าเว็บไซต์ UP AI Connect ของมหาวิทยาลัย
2. เปิดเมนู **API Platform**
3. กด **Generate API Key**
4. คัดลอก key ไว้ใช้ในคำสั่งรัน

ค่า API ที่โปรเจกต์ใช้เป็นค่าเริ่มต้น:

```text
Base URL: https://gen.ai.kku.ac.th/upacth/api/v1
Model: gpt-5.6-luna-pro
```

ห้ามใส่ API key จริงลงใน `README.md`, source code หรือ commit ขึ้น GitHub
และไม่ควรส่ง API key ในแชต

## รันบน LDPlayer / Android

### 1. เปิด LDPlayer และเปิด ADB

ใน LDPlayer ให้เปิดการตั้งค่า ADB debugging จากนั้นตรวจสอบอุปกรณ์:

```powershell
adb devices
```

ถ้ายังไม่พบอุปกรณ์ ให้ลองเชื่อมต่อพอร์ตเริ่มต้นของ LDPlayer:

```powershell
adb kill-server
adb start-server
adb connect 127.0.0.1:5555
adb devices
```

ควรเห็นอุปกรณ์ชื่อประมาณ `127.0.0.1:5555` หรือ `emulator-5554`
ในคำสั่งด้านล่างแนะนำให้ใช้ `127.0.0.1:5555`

### 2. รันแอปพร้อม API key

แทนที่ข้อความ `ใส่คีย์มหาวิทยาลัยตรงนี้` ด้วย key ที่ได้จาก UP AI Connect
และอย่าใส่เครื่องหมาย backtick ครอบ key:

```powershell
flutter run -d 127.0.0.1:5555 --dart-define="UPAI_API_KEY=ใส่คีย์มหาวิทยาลัยตรงนี้" --dart-define="UPAI_MODEL=gpt-5.6-luna-pro"
```

ถ้าต้องการใช้โมเดลอื่นที่มหาวิทยาลัยเปิดให้ใช้ ให้เปลี่ยนค่า เช่น:

```powershell
--dart-define="UPAI_MODEL=gpt-5.6-terra-pro"
```

เมื่อเปลี่ยน API key หรือ model ต้องหยุดการรันด้วย `q` แล้วรันคำสั่งใหม่
การ hot reload อย่างเดียวจะไม่เปลี่ยนค่า `--dart-define`

## รันบน Chrome

### เปิดดูหน้าเว็บอย่างเดียว

```powershell
flutter run -d chrome
```

### รันเว็บพร้อมเรียก API

Chrome ปกติอาจบล็อก API request เพราะ CORS ดังนั้นให้ใช้ Chrome profile
สำหรับทดสอบแยกจาก Chrome ที่ใช้งานประจำ

เปิด PowerShell หน้าต่างที่ 1:

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --disable-web-security --user-data-dir="C:\plantcare-chrome"
```

เปิด PowerShell หน้าต่างที่ 2:

```powershell
cd "D:\Mobile APP\appgenai2"
flutter run -d web-server --web-port 5353 --dart-define="UPAI_API_KEY=ใส่คีย์มหาวิทยาลัยตรงนี้" --dart-define="UPAI_MODEL=gpt-5.6-luna-pro"
```

นำ URL ที่ Flutter แสดงใน terminal ไปเปิดใน Chrome profile ที่เปิดด้วย
`--disable-web-security`

> Chrome profile นี้ปิดการตรวจสอบความปลอดภัยบางส่วน ใช้สำหรับทดสอบโปรเจกต์เท่านั้น
> และควรปิดหลังใช้งาน

## รันผ่าน VS Code

1. เปิดโฟลเดอร์ `D:\Mobile APP\appgenai2` ใน VS Code
2. เปิดเมนู **Terminal > New Terminal**
3. รัน `flutter pub get`
4. เลือกอุปกรณ์จากแถบด้านล่างของ VS Code
5. สำหรับการทดสอบที่เรียก API ให้รันคำสั่ง `flutter run` พร้อม `--dart-define`
   จาก terminal ตามตัวอย่างด้านบน

การกดปุ่ม Run/Debug โดยไม่ตั้ง `UPAI_API_KEY` จะทำให้แอปแจ้งว่า
`ยังไม่ได้ตั้งค่า API key` หรือ API ตอบกลับ `Invalid API key`

## คำสั่ง build

คำสั่งต่อไปนี้ใช้สร้างไฟล์สำหรับนำไปติดตั้งเอง โดยโปรเจกต์จะไม่ build ให้อัตโนมัติ:

### Android APK แบบ release

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define="UPAI_API_KEY=ใส่คีย์มหาวิทยาลัยตรงนี้" --dart-define="UPAI_MODEL=gpt-5.6-luna-pro"
```

ไฟล์ APK จะอยู่ที่:

```text
build\app\outputs\flutter-apk\app-release.apk
```

### Web แบบ release

```powershell
flutter clean
flutter pub get
flutter build web --release --dart-define="UPAI_API_KEY=ใส่คีย์มหาวิทยาลัยตรงนี้" --dart-define="UPAI_MODEL=gpt-5.6-luna-pro"
```

ไฟล์เว็บจะอยู่ในโฟลเดอร์:

```text
build\web
```

## แก้ปัญหาที่พบบ่อย

### `Invalid API key`

- ต้องใช้ key ที่สร้างจาก UP AI Connect ของมหาวิทยาลัย
- key จาก OpenRouter หรือ OpenAI ใช้กับ endpoint นี้ไม่ได้
- ตรวจสอบว่าไม่มีช่องว่างหรือขึ้นบรรทัดใหม่ติดไปกับ key
- หยุดแอปด้วย `q` แล้วรันใหม่พร้อม `--dart-define`
- ตรวจสอบว่า model ที่เลือกมีอยู่ในหน้า Models ของมหาวิทยาลัย

### Chrome แสดง CORS error

ให้ใช้วิธี `flutter run -d web-server` และเปิด URL ด้วย Chrome profile
ที่ใช้ `--disable-web-security` ตามขั้นตอนด้านบน หรือทดสอบฟังก์ชันวิเคราะห์บน LDPlayer

### `adb connect` เชื่อมต่อไม่ได้

- ตรวจสอบว่า LDPlayer เปิดอยู่
- เปิด ADB debugging ใน LDPlayer
- ลองใช้ `127.0.0.1:5555` แทน `127.0.0.1:5554`
- รัน `adb kill-server` แล้ว `adb start-server` ใหม่
- ถ้าใช้ WSL2 อยู่ อาจต้องตั้งค่า Hyper-V ให้เข้ากับระบบจำลอง Android ของเครื่อง

### เปลี่ยน API key แล้วแอปยังใช้ค่าเดิม

ค่า `--dart-define` จะถูกกำหนดตอนเริ่มแอป ต้องหยุดด้วย `q` และรันใหม่
ไม่สามารถเปลี่ยนด้วย hot reload ได้

## โครงสร้างไฟล์สำคัญ

```text
lib/
├─ main.dart                         จุดเริ่มต้นแอปและธีม
├─ constants/
│  ├─ constants.dart                  สีและค่ากลางของ UI
│  └─ api_constants.dart              endpoint, model และ API key runtime
├─ screens/
│  ├─ homepage.dart                   หน้าหลัก เลือกภาพ และแสดงผลวิเคราะห์
│  └─ history_page.dart               หน้าประวัติการตรวจ
└─ services/
   └─ api_service.dart                เรียก UP AI Connect และแปลงผลลัพธ์
```

## หมายเหตุด้านความปลอดภัย

การใส่ API key ผ่าน `--dart-define` เหมาะสำหรับงานเรียนและการทดสอบบนเครื่อง
แต่เมื่อ build เป็นเว็บ key อาจถูกมองเห็นจากฝั่ง browser ได้
ถ้านำไปใช้งานจริงควรสร้าง backend ของตนเองเป็นตัวกลางเรียก API
แทนการฝังคีย์ไว้ในแอปโดยตรง
