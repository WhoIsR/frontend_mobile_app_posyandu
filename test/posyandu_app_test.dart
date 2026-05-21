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
    final kader = FakeKaderRepository();
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Sesi').last);
    await tester.pumpAndSettle();

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
      find.textContaining('Pertumbuhan anak perlu diperhatikan'),
      findsOneWidget,
    );
  });

  testWidgets('duplikasi pengukuran menampilkan pesan backend', (tester) async {
    final kader = FakeKaderRepository()
      ..measurementError = 'Balita ini sudah dicatat pada sesi hari ini.';
    await tester.pumpWidget(
      _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
    );
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    await tester.tap(find.text('Sesi').last);
    await tester.pumpAndSettle();

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
      final kader = FakeKaderRepository()..predictionFails = true;
      await tester.pumpWidget(
        _app(auth: FakeAuthRepository.loginAs(UserRole.kader), kader: kader),
      );
      await tester.pumpAndSettle();
      await _submitLogin(tester);
      await tester.tap(find.text('Sesi').last);
      await tester.pumpAndSettle();

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

    await tester.scrollUntilVisible(
      find.byKey(const Key('validateButton')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validateButton')));
    await tester.pumpAndSettle();

    expect(bidan.validatedDecision, 'observasi');
    expect(find.text('Validasi tersimpan'), findsOneWidget);
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
    expect(find.text('Preview PDF siap'), findsWidgets);
    expect(find.text('Bagikan / Simpan'), findsOneWidget);
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
    expect(find.text('Posyandu Melati 03'), findsOneWidget);
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

  @override
  Future<List<AdminAccount>> accounts() async {
    return const [
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
    ];
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
  Future<Uint8List> downloadReport(
    String type, {
    String? startDate,
    String? endDate,
  }) async {
    downloadedReports.add(type);
    return Uint8List.fromList([4, 5, 6]);
  }
}
