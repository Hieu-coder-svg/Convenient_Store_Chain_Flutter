# convenient_store_chain_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Chạy trên điện thoại Android thật với Docker API

Ứng dụng Android dùng `127.0.0.1:8080` thông qua ADB reverse. Khi cắm điện
thoại thật qua USB, chạy lệnh sau tại thư mục dự án để tạo đường hầm tới API
Docker và mở app:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_physical_android.ps1
```

Nếu có nhiều thiết bị, truyền mã thiết bị:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_physical_android.ps1 -DeviceId 36ec0c9a
```
