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
import 'package:mobile/features/bidan/domain/entities/bidan_dashboard_data.dart';
import 'package:mobile/features/bidan/domain/entities/pmt_stock.dart';
import 'package:mobile/features/bidan/domain/entities/referral.dart';
import 'package:mobile/features/bidan/domain/entities/validation_result.dart';
import 'package:mobile/features/bidan/domain/repositories/bidan_repository.dart';
import 'package:mobile/features/kader/domain/entities/app_notification.dart';
import 'package:mobile/features/kader/domain/entities/balita.dart';
import 'package:mobile/features/kader/domain/entities/kader_dashboard_data.dart';
import 'package:mobile/features/kader/domain/entities/measurement_result.dart';
import 'package:mobile/features/kader/domain/entities/posyandu_session.dart';
import 'package:mobile/features/kader/domain/entities/screening_item.dart';
import 'package:mobile/features/kader/domain/repositories/kader_repository.dart';

void main() {
  testWidgets('login sukses Kader mengarah ke shell Kader', (tester) async {
    final auth = FakeAuthRepository.loginAs(UserRole.kader);
    await tester.pumpWidget(_app(auth: auth));
    await tester.pumpAndSettle();

    await _submitLogin(tester, nik: '3276010101010001');

    expect(auth.lastLoginNik, '3276010101010001');
    expect(find.text('Beranda Kader'), findsWidgets);
    expect(find.text('Sesi hari ini'), findsOneWidget);
    expect(find.text('Input Pengukuran'), findsOneWidget);
    expect(find.text('Laporan'), findsNothing);
  });

  testWidgets('login sukses Bidan mengarah ke shell Bidan', (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.bidan)));
    await tester.pumpAndSettle();

    await _submitLogin(tester, nik: '1976010101010001');

    expect(find.text('Beranda Bidan'), findsOneWidget);
    expect(find.text('Ringkasan Bidan'), findsOneWidget);
    expect(find.text('PMT'), findsWidgets);
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
    final kader = FakeKaderRepository();
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader));
    await tester.pumpAndSettle();
    await _submitLogin(tester);

    await tester.enterText(find.byKey(const Key('weightField')), '10.2');
    await tester.enterText(find.byKey(const Key('heightField')), '84.5');
    await tester.drag(find.byKey(const Key('kaderList')), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(kader.savedWeight, 10.2);
    expect(kader.savedHeight, 84.5);
    expect(find.text('Perlu perhatian'), findsWidgets);
    expect(find.textContaining('Pertumbuhan anak perlu diperhatikan'), findsOneWidget);
  });

  testWidgets('duplikasi pengukuran menampilkan pesan backend', (tester) async {
    final kader = FakeKaderRepository()
      ..measurementError = 'Balita ini sudah dicatat pada sesi hari ini.';
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader));
    await tester.pumpAndSettle();
    await _submitLogin(tester);

    await tester.enterText(find.byKey(const Key('weightField')), '10.2');
    await tester.enterText(find.byKey(const Key('heightField')), '84.5');
    await tester.drag(find.byKey(const Key('kaderList')), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(find.text('Balita ini sudah dicatat pada sesi hari ini.'), findsOneWidget);
  });

  testWidgets('prediksi gagal tetap menampilkan pengukuran tersimpan dan retry', (
    tester,
  ) async {
    final kader = FakeKaderRepository()..predictionFails = true;
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader));
    await tester.pumpAndSettle();
    await _submitLogin(tester);

    await tester.enterText(find.byKey(const Key('weightField')), '10.2');
    await tester.enterText(find.byKey(const Key('heightField')), '84.5');
    await tester.drag(find.byKey(const Key('kaderList')), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(find.text('Prediksi gagal'), findsWidgets);
    expect(find.textContaining('Pengukuran tersimpan'), findsWidgets);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('Bidan validasi rujukan mengubah status tampilan', (tester) async {
    final bidan = FakeBidanRepository();
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.bidan), bidan: bidan));
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Rujukan').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('validateButton')));
    await tester.tap(find.byKey(const Key('validateButton')));
    await tester.pumpAndSettle();

    expect(bidan.validatedDecision, 'observasi');
    expect(find.text('Validasi tersimpan'), findsOneWidget);
  });

  testWidgets('Bidan distribusi PMT dari validasi PMT', (tester) async {
    final bidan = FakeBidanRepository();
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.bidan), bidan: bidan));
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '1976010101010001');
    await tester.tap(find.text('Rujukan').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('decisionDropdown')));
    await tester.tap(find.byKey(const Key('decisionDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PMT').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validateButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PMT').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('distributePmtButton')));
    await tester.tap(find.byKey(const Key('distributePmtButton')));
    await tester.pumpAndSettle();

    expect(bidan.validatedDecision, 'pmt');
    expect(bidan.distributedPmtId, 51);
    expect(bidan.distributedQuantity, 1);
    expect(find.text('Distribusi PMT tersimpan'), findsOneWidget);
  });

  testWidgets('Bidan bottom nav menampilkan halaman sesuai tab', (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.bidan)));
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
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.bidan), bidan: bidan));
    await tester.pumpAndSettle();
    await _submitLogin(tester, nik: '1976010101010001');
    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();

    for (final type in ['prediksi', 'kehadiran', 'distribusi-pmt']) {
      await tester.ensureVisible(find.byKey(Key('downloadReport-$type')));
      await tester.tap(find.byKey(Key('downloadReport-$type')));
      await tester.pumpAndSettle();
    }

    expect(bidan.downloadedReports, ['prediksi', 'kehadiran', 'distribusi-pmt']);
    expect(find.textContaining('PDF berhasil diminta'), findsOneWidget);
  });

  testWidgets('Kader tidak melihat fitur khusus Bidan', (tester) async {
    await tester.pumpWidget(_app(auth: FakeAuthRepository.loginAs(UserRole.kader)));
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
  });
}

Widget _app({
  FakeAuthRepository? auth,
  FakeKaderRepository? kader,
  FakeBidanRepository? bidan,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository.loginAs(UserRole.kader)),
      kaderRepositoryProvider.overrideWithValue(kader ?? FakeKaderRepository()),
      bidanRepositoryProvider.overrideWithValue(bidan ?? FakeBidanRepository()),
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
      id: role == UserRole.kader ? 1 : 2,
      nama: role == UserRole.kader ? 'Bu Rini' : 'Bidan Sari',
      nikNip: nikNip,
      role: role,
      posyanduId: 1,
    );
  }
}

class FakeKaderRepository implements KaderRepository {
  String? measurementError;
  bool predictionFails = false;
  double? savedWeight;
  double? savedHeight;

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
    return const [
      Balita(
        id: 11,
        namaBalita: 'Raka Pratama',
        namaIbu: 'Wulan',
        tanggalLahir: '2023-10-01',
        jenisKelamin: 'L',
      ),
    ];
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
    return [
      ScreeningItem(
        id: 22,
        namaBalita: 'Raka Pratama',
        predictionStatus: predictionFails ? 'gagal' : 'selesai',
        riskLevel: predictionFails ? null : 'sedang',
      ),
    ];
  }

  @override
  Future<List<AppNotification>> notifications() async {
    return const [
      AppNotification(
        title: 'Validasi selesai',
        message: 'Rujukan sudah ditinjau bidan.',
      ),
    ];
  }
}

class FakeBidanRepository implements BidanRepository {
  String? validatedDecision;
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
      ),
    ];
  }

  @override
  Future<ValidationResult> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  }) async {
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
  Future<Uint8List> downloadReport(String type) async {
    downloadedReports.add(type);
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<List<AppNotification>> notifications() async {
    return const [
      AppNotification(
        title: 'Rujukan masuk',
        message: 'Ada hasil skrining yang perlu ditinjau.',
      ),
    ];
  }
}
