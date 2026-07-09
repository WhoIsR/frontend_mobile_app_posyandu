import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/ledger_theme.dart';
import 'package:mobile/app/posyandu_app.dart';
import 'package:mobile/app/providers.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/domain/entities/app_user.dart';
import 'package:mobile/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/admin/domain/entities/admin_account.dart';
import 'package:mobile/features/admin/domain/entities/admin_posyandu.dart';
import 'package:mobile/features/admin/domain/entities/admin_schedule.dart';
import 'package:mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mobile/features/bidan/domain/entities/bidan_dashboard_data.dart';
import 'package:mobile/features/bidan/domain/entities/pmt_stock.dart';
import 'package:mobile/features/bidan/domain/entities/referral.dart';
import 'package:mobile/features/bidan/domain/entities/validation_result.dart';
import 'package:mobile/features/bidan/domain/repositories/bidan_repository.dart';
import 'package:mobile/features/kader/domain/entities/app_notification.dart';
import 'package:mobile/features/kader/domain/entities/balita.dart';
import 'package:mobile/features/kader/domain/entities/create_balita_request.dart';
import 'package:mobile/features/kader/domain/entities/kader_dashboard_data.dart';
import 'package:mobile/features/kader/domain/entities/measurement_result.dart';
import 'package:mobile/features/kader/domain/entities/posyandu_session.dart';
import 'package:mobile/features/kader/domain/entities/screening_item.dart';
import 'package:mobile/features/kader/domain/repositories/kader_repository.dart';

String _expectedAgeText(String tanggalLahir) {
  final birthDate = DateTime.parse(tanggalLahir);
  final now = DateTime.now();
  var months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  if (now.day < birthDate.day) months -= 1;
  if (months < 0) months = 0;
  return 'Usia $months bulan';
}

void main() {
  testWidgets('login sukses Kader mengarah ke shell Kader', (tester) async {
    final auth = FakeAuthRepository.loginAs(UserRole.kader);
    await tester.pumpWidget(_app(auth: auth));
    await tester.pumpAndSettle();

    await _submitLogin(tester, nik: '3276010101010001');

    expect(auth.lastLoginNik, '3276010101010001');
    expect(find.text('Beranda Kader'), findsWidgets);
    expect(find.text('Mulai kerja hari ini'), findsOneWidget);
    expect(find.text('Sesi hari ini'), findsOneWidget);
    expect(find.text('Laporan'), findsNothing);
  });

  testWidgets('login sukses Bidan mengarah ke shell Bidan', (tester) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.bidan)),
    );
    await tester.pumpAndSettle();

    await _submitLogin(tester, nik: '1976010101010001');

    expect(find.text('Beranda Bidan'), findsOneWidget);
    expect(find.text('Triage hari ini'), findsOneWidget);
    expect(find.text('PMT'), findsWidgets);
  });

  testWidgets('login sukses Admin mengarah ke shell Admin', (tester) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.admin)),
    );
    await tester.pumpAndSettle();

    await _submitLogin(tester, nik: '199001012020011001');

    expect(find.text('Beranda Admin'), findsOneWidget);
    expect(find.text('Akun'), findsWidgets);
    expect(find.text('Posyandu'), findsWidgets);
    expect(find.text('Laporan'), findsWidgets);
    expect(find.text('Input pengukuran'), findsNothing);
    expect(find.text('Validasi Medis'), findsNothing);
  });

  testWidgets('login gagal menampilkan pesan error', (tester) async {
    final auth = FakeAuthRepository.loginAs(UserRole.kader)
      ..loginError = 'NIK/NIP atau password belum sesuai.';
    await tester.pumpWidget(_app(auth: auth));
    await tester.pumpAndSettle();

    await _submitLogin(tester, nik: 'salah', password: 'salah');

    expect(find.text('NIK/NIP atau password belum sesuai.'), findsOneWidget);
    expect(find.text('Beranda Kader'), findsNothing);
  });

  testWidgets('Kader input pengukuran sukses menampilkan hasil skrining', (
    tester,
  ) async {
    final kader = FakeKaderRepository()..startMeasured = false;
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Sesi').last);
    await tester.pumpAndSettle();

    // Select a child from recommendation
    await tester.tap(find.byKey(const Key('nextQueueChildButton')));
    await tester.pumpAndSettle();

    await _scrollToKaderMeasurementFields(tester);
    await tester.enterText(find.byKey(const Key('weightField')), '10.2');
    await tester.enterText(find.byKey(const Key('heightField')), '84.5');
    await _scrollToKaderSaveButton(tester);
    await tester.tap(find.byKey(const Key('saveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(kader.savedWeight, 10.2);
    expect(kader.savedHeight, 84.5);
    await tester.tap(find.text('Skrining').last);
    await tester.pumpAndSettle();
    expect(find.text('Perlu perhatian'), findsWidgets);
    expect(
      find.textContaining('Ada tanda yang perlu dipantau'),
      findsOneWidget,
    );
    await tester.tap(find.text('Raka Pratama'));
    await tester.pumpAndSettle();
    expect(find.text('Tren perlu perhatian'), findsOneWidget);
    expect(find.text('Riwayat BB/TB'), findsOneWidget);
    expect(find.textContaining('10.2 kg'), findsWidgets);
    expect(find.textContaining('+0.2 kg'), findsOneWidget);
    expect(
      find.textContaining('Pertumbuhan terakhir melambat'),
      findsOneWidget,
    );
  });

  testWidgets('duplikasi pengukuran menampilkan pesan backend', (tester) async {
    final kader = FakeKaderRepository()
      ..startMeasured = false
      ..measurementError = 'Balita ini sudah dicatat pada sesi hari ini.';
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Sesi').last);
    await tester.pumpAndSettle();

    // Select a child from recommendation
    await tester.tap(find.byKey(const Key('nextQueueChildButton')));
    await tester.pumpAndSettle();

    await _scrollToKaderMeasurementFields(tester);
    await tester.enterText(find.byKey(const Key('weightField')), '10.2');
    await tester.enterText(find.byKey(const Key('heightField')), '84.5');
    await _scrollToKaderSaveButton(tester);
    await tester.tap(find.byKey(const Key('saveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Balita ini sudah dicatat pada sesi hari ini.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'prediksi gagal tetap menampilkan pengukuran tersimpan dan retry',
    (tester) async {
      final kader = FakeKaderRepository()
        ..startMeasured = false
        ..predictionFails = true;
      await tester.pumpWidget(
        _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
      );
      await tester.pumpAndSettle();
      await _submitLogin(tester);
      await tester.tap(find.text('Sesi').last);
      await tester.pumpAndSettle();

      // Select a child from recommendation
      await tester.tap(find.byKey(const Key('nextQueueChildButton')));
      await tester.pumpAndSettle();

      await _scrollToKaderMeasurementFields(tester);
      await tester.enterText(find.byKey(const Key('weightField')), '10.2');
      await tester.enterText(find.byKey(const Key('heightField')), '84.5');
      await _scrollToKaderSaveButton(tester);
      await tester.tap(find.byKey(const Key('saveMeasurementButton')));
      await tester.pumpAndSettle();

      expect(kader.savedWeight, 10.2);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(find.text('Prediksi gagal'), findsWidgets);
      expect(find.textContaining('Pengukuran tersimpan'), findsWidgets);
      expect(find.text('Coba Lagi'), findsOneWidget);
    },
  );

  testWidgets('Kader bottom nav menampilkan halaman sesuai tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader)),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);

    await tester.tap(find.text('Balita').last);
    await tester.pumpAndSettle();
    expect(find.text('Cari balita'), findsOneWidget);
    expect(find.text('Raka Pratama'), findsWidgets);
    expect(find.text('Tambah Balita'), findsOneWidget);
    expect(find.byKey(const Key('saveMeasurementButton')), findsNothing);
    expect(find.text('Hasil Skrining Hari Ini'), findsNothing);
    expect(find.text('Validasi selesai'), findsNothing);

    await tester.tap(find.text('Skrining').last);
    await tester.pumpAndSettle();
    expect(find.text('Hasil Skrining Hari Ini'), findsOneWidget);
    expect(find.text('Cari balita'), findsNothing);
    expect(find.byKey(const Key('saveMeasurementButton')), findsNothing);
    expect(find.text('Validasi selesai'), findsNothing);
    await tester.tap(find.text('Raka Pratama'));
    await tester.pumpAndSettle();
    expect(find.text('Tren perlu perhatian'), findsOneWidget);

    // Close details bottom sheet
    Navigator.of(tester.element(find.text('Tren perlu perhatian'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notifikasi').last);
    await tester.pumpAndSettle();
    expect(find.text('Validasi selesai'), findsOneWidget);
    expect(find.text('Hasil Skrining Hari Ini'), findsNothing);
    expect(find.text('Cari balita'), findsNothing);
  });

  testWidgets('Kader notifikasi bisa dibuka dan ditandai dibaca', (
    tester,
  ) async {
    final kader = FakeKaderRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Notifikasi').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Validasi selesai'));
    await tester.pumpAndSettle();

    expect(kader.readNotificationId, 91);
    expect(find.text('Detail notifikasi'), findsOneWidget);
    expect(find.text('Rujukan sudah ditinjau bidan.'), findsWidgets);
  });

  testWidgets('Kader bisa mendaftarkan balita baru dari tab Balita', (
    tester,
  ) async {
    final kader = FakeKaderRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Balita').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah Balita'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('childNameField')),
      'Nara Putri',
    );
    await tester.enterText(
      find.byKey(const Key('childNikField')),
      '3276010101010002',
    );
    await tester.enterText(
      find.byKey(const Key('birthDateField')),
      '2024-01-12',
    );
    await tester.tap(find.byKey(const Key('genderDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perempuan').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('motherNameField')), 'Dewi');
    await tester.enterText(
      find.byKey(const Key('motherNikField')),
      '3276010101010003',
    );
    await tester.enterText(
      find.byKey(const Key('addressField')),
      'Jl. Melati 3',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -480));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('incomeField')), '2500000');
    await tester.enterText(find.byKey(const Key('familyCountField')), '4');
    await tester.ensureVisible(find.byKey(const Key('saveBalitaButton')));
    await tester.tap(find.byKey(const Key('saveBalitaButton')));
    await tester.pumpAndSettle();

    expect(kader.createdChildName, 'Nara Putri');
    expect(kader.createdGender, 'P');
    expect(kader.createdPosyanduId, 1);
    expect(find.text('Balita baru tersimpan.'), findsOneWidget);
    expect(find.text('Nara Putri'), findsWidgets);
  });

  testWidgets('Bidan validasi rujukan mengubah status tampilan', (
    tester,
  ) async {
    final bidan = FakeBidanRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.bidan), bidan: bidan),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Rujukan').last);
    await tester.pumpAndSettle();

    // Tap a referral row to open bottom sheet
    await tester.tap(find.text('Raka Pratama').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Rujukan'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('validateReferralDetailButton')),
    );
    await tester.tap(find.byKey(const Key('validateReferralDetailButton')));
    await tester.pumpAndSettle();

    expect(bidan.validatedDecision, 'observasi');
    expect(find.text('Validasi tersimpan'), findsWidgets);
  });

  testWidgets('Bidan distribusi PMT dari validasi PMT', (tester) async {
    final bidan = FakeBidanRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.bidan), bidan: bidan),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '1976010101010001');
    await tester.tap(find.text('Rujukan').last);
    await tester.pumpAndSettle();

    // Tap a referral to open bottom sheet, choose PMT, validate
    await tester.tap(find.text('Raka Pratama').first);
    await tester.pumpAndSettle();
    // Find the dropdown in the bottom sheet
    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdowns.last);
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PMT').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('validateReferralDetailButton')),
    );
    await tester.tap(find.byKey(const Key('validateReferralDetailButton')));
    await tester.pumpAndSettle();

    // Navigate to PMT tab where the pending distribution should appear
    await tester.tap(find.text('PMT').last);
    await tester.pumpAndSettle();
    expect(find.text('Raka Pratama'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('distributePmtButton-0')));
    // Drag up to clear bottom nav overlap
    await tester.drag(find.byType(ListView).last, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('distributePmtButton-0')));
    await tester.pumpAndSettle();

    expect(bidan.validatedDecision, 'pmt');
    expect(bidan.distributedPmtId, 51);
    expect(bidan.distributedQuantity, 1);
    expect(find.text('Distribusi PMT tersimpan'), findsWidgets);
  });

  testWidgets('Bidan bottom nav menampilkan halaman sesuai tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.bidan)),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '1976010101010001');

    await tester.tap(find.text('PMT').last);
    await tester.pumpAndSettle();
    expect(find.text('Biskuit Balita'), findsOneWidget);
    expect(find.text('Validasi Medis'), findsNothing);
    expect(find.text('Laporan PDF'), findsNothing);
    expect(find.text('Rujukan masuk'), findsNothing);

    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();
    expect(find.text('Laporan PDF'), findsOneWidget);
    expect(find.text('Biskuit Balita'), findsNothing);
    expect(find.text('Validasi Medis'), findsNothing);

    await tester.tap(find.text('Notifikasi').last);
    await tester.pumpAndSettle();
    expect(find.text('Rujukan masuk'), findsOneWidget);
    expect(find.text('Laporan PDF'), findsNothing);
    expect(find.text('Biskuit Balita'), findsNothing);
  });

  testWidgets('Bidan bisa memilih tiga jenis laporan PDF', (tester) async {
    final bidan = FakeBidanRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.bidan), bidan: bidan),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '1976010101010001');
    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('downloadReport-prediksi')),
    );
    await tester.tap(find.byKey(const Key('downloadReport-prediksi')));
    await tester.pumpAndSettle();

    expect(bidan.downloadedReports, ['prediksi']);

    // Drag up to reveal bottom preview panel
    await tester.drag(find.byType(ListView).last, const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Laporan siap'), findsOneWidget);
    expect(find.text('Bagikan'), findsOneWidget);
  });

  testWidgets('Admin bisa melihat akun dan Posyandu', (tester) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.admin)),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '199001012020011001');

    await tester.tap(find.text('Akun').last);
    await tester.pumpAndSettle();
    expect(find.text('Bidan Sari'), findsOneWidget);
    expect(find.text('Kader Rini'), findsOneWidget);

    await tester.tap(find.text('Posyandu').last);
    await tester.pumpAndSettle();
    expect(find.text('Posyandu Melati 03'), findsWidgets);
  });

  testWidgets('Admin Posyandu menampilkan relasi dan sesi bisa diatur', (
    tester,
  ) async {
    final admin = FakeAdminRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.admin), admin: admin),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '199001012020011001');

    await tester.tap(find.text('Posyandu').last);
    await tester.pumpAndSettle();
    expect(find.text('1 bidan'), findsOneWidget);
    expect(find.text('1 kader'), findsOneWidget);
    expect(find.text('1 jadwal'), findsOneWidget);
    expect(find.text('Jadwal/Sesi'), findsOneWidget);

    await tester.tap(find.text('Akun terkait'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Filter aktif: Posyandu Melati 03. Data di bawah hanya untuk Posyandu ini.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kader Rini'), findsOneWidget);

    await tester.tap(find.text('Posyandu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwal/Sesi'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Filter aktif: Posyandu Melati 03. Jadwal di bawah hanya untuk Posyandu ini.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sesi').last);
    await tester.pumpAndSettle();
    expect(find.text('Jadwal & sesi'), findsOneWidget);
    expect(find.text('Belum ada sesi aktif'), findsOneWidget);
    expect(find.text('Mulai Sesi'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('startAdminSessionButton')),
    );
    tester
        .widget<FilledButton>(find.byKey(const Key('startAdminSessionButton')))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    expect(admin.startedScheduleId, 1);
    expect(find.text('Sesi sedang berjalan'), findsOneWidget);
  });

  testWidgets('Admin bisa tambah dan nonaktifkan akun dari action sheet', (
    tester,
  ) async {
    final admin = FakeAdminRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.admin), admin: admin),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '199001012020011001');

    await tester.tap(find.text('Akun').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Posyandu Melati 03'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('adminAccountNameField')),
      'Kader Baru',
    );
    await tester.enterText(
      find.byKey(const Key('adminAccountNikField')),
      '3276010101010099',
    );
    await tester.enterText(
      find.byKey(const Key('adminAccountPasswordField')),
      'password',
    );
    await tester.tap(find.byKey(const Key('saveAdminAccountButton')));
    await tester.pumpAndSettle();

    expect(admin.createdAccountName, 'Kader Baru');
    expect(admin.createdAccountPosyanduId, 1);
    expect(find.text('Akun tersimpan.'), findsOneWidget);

    await tester.tap(find.text('Kader Baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nonaktifkan'));
    await tester.pumpAndSettle();
    expect(find.text('Nonaktifkan akun?'), findsOneWidget);
    await tester.tap(find.text('Ya, nonaktifkan'));
    await tester.pumpAndSettle();

    expect(admin.updatedAccountStatus, 'nonaktif');
    expect(find.text('Status akun diperbarui.'), findsOneWidget);
  });

  testWidgets('Admin dashboard dan akun tampil operasional', (tester) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.admin)),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '199001012020011001');

    expect(find.text('Akun nonaktif'), findsOneWidget);
    expect(find.text('1 perlu dicek'), findsOneWidget);
    expect(find.text('Tambah akun kerja'), findsOneWidget);

    await tester.tap(find.text('Akun').last);
    await tester.pumpAndSettle();
    expect(find.text('Bidan Sari'), findsOneWidget);
    expect(find.text('NIP/NIK 1976010101010001'), findsOneWidget);
    expect(find.text('Posyandu Melati 03'), findsWidgets);
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Kader Cuti'), findsOneWidget);
    expect(find.text('nonaktif'), findsWidgets);
  });

  testWidgets('Kader tap balita membuka aksi cepat dan bisa input BB TB', (
    tester,
  ) async {
    final kader = FakeKaderRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Balita').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Raka Pratama'));
    await tester.pumpAndSettle();
    expect(find.text('Aksi balita'), findsOneWidget);

    await tester.tap(find.text('Input BB/TB'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('quickWeightField')), '10.2');
    await tester.enterText(find.byKey(const Key('quickHeightField')), '84.5');
    await tester.tap(find.byKey(const Key('quickSaveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(kader.savedWeight, 10.2);
    expect(kader.savedHeight, 84.5);
    expect(find.textContaining('Hasil skrining diperbarui'), findsWidgets);
  });

  testWidgets('Kader registry rows dan sesi menampilkan konteks operasional', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader)),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);

    await tester.tap(find.text('Balita').last);
    await tester.pumpAndSettle();
    expect(find.text(_expectedAgeText('2023-10-01')), findsOneWidget);
    expect(find.text('Terakhir: 10.2 kg / 84.5 cm'), findsOneWidget);
    expect(find.text('Sudah diukur'), findsWidgets);

    await tester.tap(find.text('Raka Pratama'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat singkat'), findsOneWidget);
    expect(find.text('Edit profil balita'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesi').last);
    await tester.pumpAndSettle();
    expect(find.text('Kerja hari ini'), findsOneWidget);
    expect(find.text('Sudah diukur'), findsOneWidget);
    expect(find.text('Belum diukur'), findsOneWidget);
  });

  testWidgets('Bidan tap rujukan membuka detail dan validasi kontekstual', (
    tester,
  ) async {
    final bidan = FakeBidanRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.bidan), bidan: bidan),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '1976010101010001');
    await tester.tap(find.text('Rujukan').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Raka Pratama').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Rujukan'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('validateReferralDetailButton')),
    );
    await tester.tap(find.byKey(const Key('validateReferralDetailButton')));
    await tester.pumpAndSettle();

    expect(bidan.validatedReferralId, 31);
    expect(find.text('Validasi tersimpan'), findsWidgets);
  });

  testWidgets('Bidan rujukan dan PMT menampilkan konteks operasional', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.bidan)),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '1976010101010001');

    await tester.tap(find.text('Rujukan').last);
    await tester.pumpAndSettle();
    expect(find.text(_expectedAgeText('2023-10-01')), findsOneWidget);
    expect(find.text('BB/TB: 10.2 kg / 84.5 cm'), findsOneWidget);

    await tester.tap(find.text('Raka Pratama').first);
    await tester.pumpAndSettle();
    expect(find.text('Konteks skrining'), findsOneWidget);
    expect(find.text('Keputusan & catatan'), findsOneWidget);
    expect(find.textContaining('bukan diagnosis'), findsWidgets);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PMT').last);
    await tester.pumpAndSettle();
    expect(find.text('Stok 7 dus'), findsOneWidget);
    expect(find.text('Minimum aman 10 dus'), findsOneWidget);
    expect(find.text('Prioritas distribusi'), findsOneWidget);
  });

  testWidgets('Admin bisa preview laporan PDF', (tester) async {
    final admin = FakeAdminRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.admin), admin: admin),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '199001012020011001');

    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview').first);
    await tester.pumpAndSettle();

    expect(admin.downloadedReports, ['prediksi']);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Preview PDF siap'), findsWidgets);
    expect(find.text('Bagikan / Simpan'), findsOneWidget);
  });

  testWidgets('Kader tidak melihat fitur khusus Bidan', (tester) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader)),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);

    expect(find.text('Validasi Medis'), findsNothing);
    expect(find.text('Download PDF'), findsNothing);
    expect(find.text('Stok menipis'), findsNothing);
  });

  testWidgets('theme tetap Ledger Posyandu dan bukan default purple', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.colorScheme.primary, LedgerColors.primary);
    expect(materialApp.theme?.scaffoldBackgroundColor, LedgerColors.paper);
    expect(materialApp.theme?.bottomSheetTheme.showDragHandle, true);
    expect(
      materialApp.theme?.snackBarTheme.behavior,
      SnackBarBehavior.floating,
    );
    expect(
      materialApp.theme?.textTheme.headlineSmall?.fontWeight,
      FontWeight.w900,
    );
  });

  testWidgets('Kader bisa edit profil balita dari bottom sheet aksi balita', (
    tester,
  ) async {
    final fakeKader = FakeKaderRepository();
    await tester.pumpWidget(_app(kader: fakeKader));
    await tester.pumpAndSettle();
    await _submitLogin(tester);

    // Buka tab Balita
    await tester.tap(find.text('Balita').last);
    await tester.pumpAndSettle();

    // Tap child row to open bottom sheet
    await tester.tap(find.text('Raka Pratama'));
    await tester.pumpAndSettle();

    // Verify bottom sheet is shown with the child details
    expect(find.text('Aksi balita'), findsOneWidget);
    expect(find.text('Raka Pratama | Ibu: Wulan'), findsOneWidget);

    // Tap "Edit profil balita"
    await tester.ensureVisible(find.byKey(const Key('editChildProfileButton')));
    await tester.tap(find.byKey(const Key('editChildProfileButton')));
    await tester.pumpAndSettle();

    // Verify _EditBalitaPage is pushed
    expect(find.text('Edit Profil Balita'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Raka Pratama'), findsOneWidget);

    // Change baby name
    await tester.enterText(
      find.byKey(const Key('editChildNameField')),
      'Raka Pratama Baru',
    );
    await tester.enterText(
      find.byKey(const Key('editAddressField')),
      'Alamat Baru',
    );
    await tester.enterText(find.byKey(const Key('editIncomeField')), '5000000');
    await tester.enterText(find.byKey(const Key('editFamilyCountField')), '4');

    // Submit form
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('editSaveBalitaButton')));
    await tester.tap(find.byKey(const Key('editSaveBalitaButton')));
    await tester.pumpAndSettle();

    // Verify popped back and dashboard refreshed
    expect(find.text('Edit Profil Balita'), findsNothing);
    expect(fakeKader.createdChildName, 'Raka Pratama Baru');
  });
}

Widget _app({
  FakeAuthRepository? auth,
  FakeKaderRepository? kader,
  FakeBidanRepository? bidan,
  FakeAdminRepository? admin,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository.loginAs(UserRole.kader),
      ),
      kaderRepositoryProvider.overrideWithValue(kader ?? FakeKaderRepository()),
      bidanRepositoryProvider.overrideWithValue(bidan ?? FakeBidanRepository()),
      adminRepositoryProvider.overrideWithValue(admin ?? FakeAdminRepository()),
    ],
    child: const PosyanduApp(),
  );
}

Future<void> _submitLogin(
  WidgetTester tester, {
  String nik = '3276010101010001',
  String password = 'password',
}) async {
  await tester.enterText(find.byKey(const Key('nikField')), nik);
  await tester.enterText(find.byKey(const Key('passwordField')), password);
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
}

Future<void> _scrollToKaderSaveButton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('saveMeasurementButton')),
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToKaderMeasurementFields(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('weightField')),
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository.loginAs(this.role);

  final UserRole role;
  String? loginError;
  String? lastLoginNik;

  @override
  Future<AuthSession> login(String nikNip, String password) async {
    lastLoginNik = nikNip;
    if (loginError != null) {
      throw ApiException(loginError!);
    }
    return AuthSession(token: 'token', user: _user(nikNip));
  }

  @override
  Future<AppUser> currentUser() async => _user('demo');

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<void> logout() async {}

  AppUser _user(String nikNip) {
    return AppUser(
      id: role == UserRole.kader ? 1 : (role == UserRole.bidan ? 2 : 3),
      nama: role == UserRole.kader
          ? 'Bu Rini'
          : (role == UserRole.bidan ? 'Bidan Sari' : 'Admin Posyandu'),
      nikNip: nikNip,
      role: role,
      posyanduId: role == UserRole.admin ? null : 1,
    );
  }
}

class FakeKaderRepository implements KaderRepository {
  bool startMeasured = true;
  String? measurementError;
  bool predictionFails = false;
  double? savedWeight;
  double? savedHeight;
  String? createdChildName;
  String? createdGender;
  int? createdPosyanduId;

  @override
  Future<KaderDashboardData> dashboard() async {
    final session = await activeSession();
    final children = await searchChildren();
    return KaderDashboardData(
      session: session,
      children: children,
      screening: await screening(session!.id),
      notifications: await notifications(),
    );
  }

  @override
  Future<PosyanduSession?> activeSession() async {
    return const PosyanduSession(
      id: 7,
      posyanduId: 1,
      tanggal: '2026-05-19',
      status: 'berjalan',
    );
  }

  @override
  Future<List<Balita>> searchChildren({String search = ''}) async {
    return [
      if (createdChildName != null)
        Balita(
          id: 12,
          namaBalita: createdChildName!,
          namaIbu: 'Dewi',
          tanggalLahir: '2024-01-12',
          jenisKelamin: createdGender,
        ),
      const Balita(
        id: 11,
        namaBalita: 'Raka Pratama',
        namaIbu: 'Wulan',
        tanggalLahir: '2023-10-01',
        jenisKelamin: 'L',
        latestWeight: 10.2,
        latestHeight: 84.5,
        latestMeasuredAt: '2026-05-19',
      ),
    ];
  }

  @override
  Future<Balita> createBalita(CreateBalitaRequest request) async {
    createdChildName = request.namaBalita;
    createdGender = request.jenisKelamin;
    createdPosyanduId = request.posyanduId;
    return Balita(
      id: 12,
      namaBalita: request.namaBalita,
      namaIbu: request.namaIbu,
      tanggalLahir: request.tanggalLahir,
      jenisKelamin: request.jenisKelamin,
    );
  }

  @override
  Future<MeasurementResult> saveMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) async {
    savedWeight = weight;
    savedHeight = height;
    if (measurementError != null) {
      throw ApiException(measurementError!);
    }
    return MeasurementResult(
      id: 22,
      predictionStatus: predictionFails ? 'gagal' : 'selesai',
      riskLevel: predictionFails ? null : 'sedang',
    );
  }

  @override
  Future<MeasurementResult> retryPrediction(int measurementId) async {
    predictionFails = false;
    return const MeasurementResult(
      id: 22,
      predictionStatus: 'selesai',
      riskLevel: 'sedang',
    );
  }

  @override
  Future<List<ScreeningItem>> screening(int sessionId) async {
    if (!startMeasured && savedWeight == null) {
      return [];
    }
    return [
      ScreeningItem(
        id: 22,
        namaBalita: 'Raka Pratama',
        predictionStatus: predictionFails ? 'gagal' : 'selesai',
        riskLevel: predictionFails ? null : 'sedang',
        continuityLabel: 'Tren perlu perhatian',
        continuityMessage:
            'Pertumbuhan terakhir melambat. Pantau ulang dan beri edukasi sebelum jadwal berikutnya.',
        measurementHistory: [
          MeasurementHistoryPoint(
            visitLabel: 'Kunjungan 1',
            measuredAt: '2026-04-19',
            weightKg: 10.0,
            heightCm: 83.8,
          ),
          MeasurementHistoryPoint(
            visitLabel: 'Kunjungan 2',
            measuredAt: '2026-05-19',
            weightKg: 10.2,
            heightCm: 84.5,
            weightDeltaKg: 0.2,
            heightDeltaCm: 0.7,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<AppNotification>> notifications() async {
    return const [
      AppNotification(
        id: 91,
        title: 'Validasi selesai',
        message: 'Rujukan sudah ditinjau bidan.',
        type: 'validasi_selesai',
        data: {'rujukan_id': 31},
        isRead: false,
      ),
    ];
  }

  int? readNotificationId;

  @override
  Future<void> markNotificationRead(int id) async {
    readNotificationId = id;
  }

  @override
  Future<Balita> updateBalita(int id, CreateBalitaRequest request) async {
    createdChildName = request.namaBalita;
    createdGender = request.jenisKelamin;
    createdPosyanduId = request.posyanduId;
    return Balita(
      id: id,
      namaBalita: request.namaBalita,
      namaIbu: request.namaIbu,
      tanggalLahir: request.tanggalLahir,
      jenisKelamin: request.jenisKelamin,
      nikBalita: request.nikBalita,
      nikIbu: request.nikIbu,
      alamat: request.alamat,
      penghasilan: request.penghasilan,
      jumlahKeluarga: request.jumlahKeluarga,
      posyanduId: request.posyanduId,
    );
  }
}

class FakeBidanRepository implements BidanRepository {
  String? validatedDecision;
  int? validatedReferralId;
  int? distributedPmtId;
  int? distributedQuantity;
  final List<String> downloadedReports = [];

  @override
  Future<BidanDashboardData> dashboard() async {
    return BidanDashboardData(
      referrals: await referrals(),
      pmtStock: await pmtStock(),
      notifications: await notifications(),
    );
  }

  @override
  Future<List<Referral>> referrals({String search = '', String? status}) async {
    return const [
      Referral(
        id: 31,
        childId: 11,
        namaBalita: 'Raka Pratama',
        namaIbu: 'Wulan',
        riskLevel: 'tinggi',
        status: 'menunggu_validasi',
        tanggalLahir: '2023-10-01',
        beratBadan: 10.2,
        tinggiBadan: 84.5,
        tanggalUkur: '2026-05-19',
      ),
    ];
  }

  @override
  Future<ValidationResult> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  }) async {
    validatedReferralId = referralId;
    validatedDecision = decision;
    return ValidationResult(id: 41, referralId: referralId, decision: decision);
  }

  @override
  Future<void> distributePmt({
    required int validationId,
    required int childId,
    required int pmtId,
    required int quantity,
  }) async {
    distributedPmtId = pmtId;
    distributedQuantity = quantity;
  }

  @override
  Future<List<PmtStock>> pmtStock() async {
    return const [
      PmtStock(
        id: 51,
        name: 'Biskuit Balita',
        stock: 7,
        minimumStock: 10,
        unit: 'dus',
      ),
    ];
  }

  @override
  Future<Uint8List> downloadReport(
    String type, {
    String? startDate,
    String? endDate,
  }) async {
    downloadedReports.add(type);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<List<AppNotification>> notifications() async {
    return const [
      AppNotification(
        id: 92,
        title: 'Rujukan masuk',
        message: 'Ada hasil skrining yang perlu ditinjau.',
        type: 'rujukan_masuk',
        data: {'rujukan_id': 31},
        isRead: false,
      ),
    ];
  }

  @override
  Future<void> markNotificationRead(int id) async {}
}

class FakeAdminRepository implements AdminRepository {
  final List<String> downloadedReports = [];
  String? createdAccountName;
  int? createdAccountPosyanduId;
  String? updatedAccountStatus;
  AdminAccount? createdAccount;
  int? startedScheduleId;
  AdminSession? session;

  @override
  Future<List<AdminAccount>> accounts() async {
    final rows = <AdminAccount>[
      AdminAccount(
        id: 1,
        name: 'Bidan Sari',
        nikNip: '1976010101010001',
        role: 'bidan',
        status: 'aktif',
        posyanduId: 1,
      ),
      AdminAccount(
        id: 2,
        name: 'Kader Rini',
        nikNip: '3276010101010001',
        role: 'kader',
        status: 'aktif',
        posyanduId: 1,
      ),
      AdminAccount(
        id: 4,
        name: 'Kader Cuti',
        nikNip: '3276010101010004',
        role: 'kader',
        status: 'nonaktif',
        posyanduId: 1,
      ),
    ];
    if (createdAccount != null) {
      rows.insert(0, createdAccount!);
    }
    return rows;
  }

  @override
  Future<List<AdminPosyandu>> posyandu() async {
    return const [
      AdminPosyandu(
        id: 1,
        name: 'Posyandu Melati 03',
        address: 'Balai Desa Melati',
        village: 'Melati',
        district: 'Sukamaju',
      ),
    ];
  }

  @override
  Future<List<AdminSchedule>> schedules() async {
    return const [
      AdminSchedule(
        id: 1,
        posyanduId: 1,
        date: '2026-03-10',
        startTime: '08:00',
        endTime: '11:00',
        location: 'Balai Desa Melati',
        note: 'Penimbangan rutin',
      ),
    ];
  }

  @override
  Future<AdminSession?> activeSession() async => session;

  @override
  Future<Uint8List> downloadReport(
    String type, {
    String? startDate,
    String? endDate,
  }) async {
    downloadedReports.add(type);
    return Uint8List.fromList([4, 5, 6]);
  }

  @override
  Future<AdminAccount> saveAccount({
    int? id,
    required String name,
    required String nikNip,
    String? password,
    required String role,
    int? posyanduId,
    required String status,
  }) async {
    if (id == null) {
      createdAccountName = name;
      createdAccountPosyanduId = posyanduId;
    } else {
      updatedAccountStatus = status;
    }
    final account = AdminAccount(
      id: id ?? 3,
      name: name,
      nikNip: nikNip,
      role: role,
      status: status,
      posyanduId: posyanduId,
    );
    if (id == null || id == createdAccount?.id) {
      createdAccount = account;
    }
    return account;
  }

  @override
  Future<AdminPosyandu> savePosyandu({
    int? id,
    required String name,
    required String address,
    required String village,
    required String district,
  }) async {
    return AdminPosyandu(
      id: id ?? 2,
      name: name,
      address: address,
      village: village,
      district: district,
    );
  }

  @override
  Future<AdminSchedule> saveSchedule({
    int? id,
    required int posyanduId,
    required String date,
    required String startTime,
    required String endTime,
    required String location,
    required String note,
  }) async {
    return AdminSchedule(
      id: id ?? 2,
      posyanduId: posyanduId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location,
      note: note,
    );
  }

  @override
  Future<AdminSession> startSession({
    int? scheduleId,
    required int posyanduId,
    required String date,
  }) async {
    startedScheduleId = scheduleId;
    session = AdminSession(
      id: 7,
      posyanduId: posyanduId,
      date: date,
      status: 'berjalan',
      scheduleId: scheduleId,
    );
    return session!;
  }

  @override
  Future<AdminSession> closeSession(int id) async {
    final closed = AdminSession(
      id: id,
      posyanduId: session?.posyanduId ?? 1,
      date: session?.date ?? '2026-03-10',
      status: 'selesai',
      scheduleId: session?.scheduleId,
    );
    session = null;
    return closed;
  }
}
