# Posyandu ML Mobile

Repo ini berisi aplikasi Flutter Android untuk MVP Posyandu ML sesuai PRD. Backend Laravel dan Flask ML API berada di repo terpisah `posyandu-ml-backend`.

Fokus aplikasi:

- Login role Kader dan Bidan.
- Alur Kader: dashboard, jadwal/sesi, daftar balita, input pengukuran, hasil skrining, status rujukan/PMT, notifikasi.
- Alur Bidan: dashboard, rujukan, validasi medis, stok dan distribusi PMT, laporan PDF, notifikasi.
- Bahasa risiko tetap etis: `Risiko rendah`, `Perlu perhatian`, dan `Perlu ditinjau bidan`.

## Menjalankan Flutter

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

## Konfigurasi API

Mobile hanya boleh memanggil Laravel REST API. Flask ML API tidak dipanggil dari Flutter.

Saat integrasi HTTP dibuat, arahkan base URL ke Laravel:

```text
Android emulator: http://10.0.2.2:8000/api
Device fisik jaringan lokal: http://<IP-LARAVEL>:8000/api
VPS/demo: https://<domain-backend>/api
```

UI saat ini adalah shell Android Flutter berbasis design system Ledger Posyandu. Integrasi HTTP tetap harus mengikuti endpoint Laravel di PRD.

## Test

```powershell
flutter analyze
flutter test
```

## Guardrail PRD

- Repo ini tidak membawa Laravel, Flask, model ML, atau file deployment VPS.
- Tidak menambah fitur di luar PRD seperti offline mode, iOS, chat, OCR, peta statistik, atau integrasi sistem eksternal.
- Light theme menjadi default untuk penggunaan Posyandu siang hari; dark theme tersedia sebagai pertimbangan token desain.
