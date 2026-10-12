# SEMIS Flutter

Aplikasi mobile SEMIS (Sistem Informasi Pencatatan Silsilah dan Pemuliaan Domba Terintegrasi).

## Fitur demo
- Login demo
- Dashboard ringkas
- Ringkasan data domba dan kandang
- Daftar domba dengan pencarian
- Informasi silsilah dan pemuliaan
- Navigasi bawah
- Data contoh masih tersimpan sementara selama aplikasi berjalan

## Menjalankan
1. Ekstrak ZIP.
2. Buka folder `semis_flutter` di VS Code.
3. Jalankan terminal:
   ```bash
   flutter pub get
   flutter run
   ```
4. Untuk membuat APK:
   ```bash
   flutter build apk --release
   ```
5. APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.

Catatan: aplikasi ini merupakan prototipe UI dengan data contoh. Login belum terhubung ke server dan data belum disimpan permanen ke SQLite.
