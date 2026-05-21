# Demo Release Mobile Posyandu ML

Dokumen ini dipakai untuk menjalankan demo aplikasi Flutter Android Posyandu ML. Backend Laravel dan Flask ML API harus sudah berjalan dari repo `posyandu-ml-backend`.

## Build APK Demo

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

APK demo berada di:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

Untuk device fisik di jaringan lokal, ganti base URL:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://<IP-LARAVEL>:8000/api
```

Untuk VPS sementara via IP:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://167.172.71.213/api
```

Untuk rilis yang lebih aman, gunakan domain dan HTTPS:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=https://<domain>/api
```

## Install ke Emulator Pixel 6

```powershell
adb devices
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 shell pm clear com.whoisr.posyandu_ml
adb -s emulator-5554 shell am start -n com.whoisr.posyandu_ml/.MainActivity
```

## Akun Demo

- Kader: `3271010101010001` / `password`
- Bidan: `197801012006042001` / `password`

## Flow Demo Wajib

1. Kader login, buka Beranda, lalu cek sesi aktif.
2. Kader buka Balita, tambah balita baru, lalu pilih balita untuk pengukuran.
3. Kader buka Sesi, input berat badan dan tinggi badan, simpan, lalu cek Skrining.
4. Bidan login, buka Rujukan, lihat status risiko sebagai skrining awal, lalu simpan validasi.
5. Bidan buka PMT, cek stok, lalu distribusikan 1 paket jika validasi PMT sudah dibuat.
6. Bidan buka Laporan, tekan tiga tombol PDF: Prediksi Risiko, Kehadiran Posyandu, Distribusi PMT.

## Screenshot QA

Screenshot hasil QA emulator disimpan di folder induk `project-3-development`:

- `demo-kader-home.png`
- `demo-kader-balita.png`
- `demo-kader-after-add.png`
- `demo-kader-after-measure.png`
- `demo-kader-screening.png`
- `demo-bidan-rujukan.png`
- `demo-bidan-pmt.png`
- `demo-bidan-laporan.png`
- `demo-bidan-notifikasi.png`
- `qa-kader-home.png`
- `qa-kader-create-form.png`
- `qa-kader-after-create.png`
- `qa-kader-sesi-selected.png`
- `qa-kader-screening.png`
- `qa-bidan-rujukan.png`
- `qa-bidan-pmt.png`
- `qa-bidan-laporan.png`
- `qa-bidan-notifikasi.png`

## Guardrail PRD

- Flutter hanya memanggil Laravel REST API.
- Flutter tidak memanggil Flask ML API langsung.
- Label risiko tetap etis: `Risiko rendah`, `Perlu perhatian`, dan `Perlu ditinjau bidan`.
- Tidak ada fitur di luar PRD seperti offline mode, OCR, chat, grafik kompleks, iOS, atau integrasi eksternal.
