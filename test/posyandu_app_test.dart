import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/core/token_store.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('login sukses Kader mengarah ke shell Kader', (tester) async {
    final api = FakePosyanduApi.loginAs(UserRole.kader);
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nikField')), '3276010101010001');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(api.lastLoginNik, '3276010101010001');
    expect(find.text('Beranda Kader'), findsOneWidget);
    expect(find.text('Sesi hari ini'), findsOneWidget);
    expect(find.text('Input Pengukuran'), findsOneWidget);
    expect(find.text('Laporan'), findsNothing);
  });

  testWidgets('login sukses Bidan mengarah ke shell Bidan', (tester) async {
    final api = FakePosyanduApi.loginAs(UserRole.bidan);
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nikField')), '1976010101010001');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Beranda Bidan'), findsOneWidget);
    expect(find.text('Rujukan'), findsWidgets);
    expect(find.text('Validasi Medis'), findsOneWidget);
    expect(find.text('PMT'), findsWidgets);
  });

  testWidgets('login gagal menampilkan pesan error', (tester) async {
    final api = FakePosyanduApi.loginAs(UserRole.kader)
      ..loginError = 'NIK/NIP atau password belum sesuai.';
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('nikField')), 'salah');
    await tester.enterText(find.byKey(const Key('passwordField')), 'salah');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('NIK/NIP atau password belum sesuai.'), findsOneWidget);
    expect(find.text('Beranda Kader'), findsNothing);
  });

  testWidgets('Kader input pengukuran sukses menampilkan hasil skrining', (
    tester,
  ) async {
    final api = FakePosyanduApi.loginAs(UserRole.kader);
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.enterText(find.byKey(const Key('weightField')), '10.2');
    await tester.enterText(find.byKey(const Key('heightField')), '84.5');
    await tester.drag(find.byKey(const Key('kaderList')), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(api.savedWeight, 10.2);
    expect(api.savedHeight, 84.5);
    expect(find.text('Perlu perhatian'), findsWidgets);
    expect(
      find.textContaining('Pertumbuhan anak perlu diperhatikan'),
      findsOneWidget,
    );
  });

  testWidgets('duplikasi pengukuran menampilkan pesan backend', (tester) async {
    final api = FakePosyanduApi.loginAs(UserRole.kader)
      ..measurementError = 'Balita ini sudah dicatat pada sesi hari ini.';
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.enterText(find.byKey(const Key('weightField')), '10.2');
    await tester.enterText(find.byKey(const Key('heightField')), '84.5');
    await tester.drag(find.byKey(const Key('kaderList')), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveMeasurementButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Balita ini sudah dicatat pada sesi hari ini.'),
      findsOneWidget,
    );
  });

  testWidgets('prediksi gagal tetap menampilkan pengukuran tersimpan dan retry', (
    tester,
  ) async {
    final api = FakePosyanduApi.loginAs(UserRole.kader)
      ..predictionFails = true;
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();
    await _login(tester);

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
    final api = FakePosyanduApi.loginAs(UserRole.bidan);
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();
    await _login(tester);

    await tester.ensureVisible(find.byKey(const Key('validateButton')));
    await tester.tap(find.byKey(const Key('validateButton')));
    await tester.pumpAndSettle();

    expect(api.validatedDecision, 'observasi');
    expect(find.text('Validasi tersimpan'), findsOneWidget);
  });

  testWidgets('Kader tidak melihat fitur khusus Bidan', (tester) async {
    final api = FakePosyanduApi.loginAs(UserRole.kader);
    await tester.pumpWidget(
      PosyanduApp(api: api, tokenStore: MemoryTokenStore()),
    );
    await tester.pumpAndSettle();
    await _login(tester);

    expect(find.text('Validasi Medis'), findsNothing);
    expect(find.text('Download PDF'), findsNothing);
    expect(find.text('Stok menipis'), findsNothing);
  });

  testWidgets('theme tetap Ledger Posyandu dan bukan default purple', (
    tester,
  ) async {
    await tester.pumpWidget(
      PosyanduApp(
        api: FakePosyanduApi.loginAs(UserRole.kader),
        tokenStore: MemoryTokenStore(),
      ),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.colorScheme.primary, const Color(0xFF4E6F5C));
    expect(materialApp.theme?.scaffoldBackgroundColor, const Color(0xFFF8F4EC));
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('nikField')), '3276010101010001');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
}

class FakePosyanduApi implements PosyanduApi {
  FakePosyanduApi.loginAs(this.role);

  final UserRole role;
  String? loginError;
  String? measurementError;
  bool predictionFails = false;
  String? lastLoginNik;
  double? savedWeight;
  double? savedHeight;
  String? validatedDecision;

  @override
  String get reportBaseUrl => 'https://example.test/api';

  @override
  Future<AuthSession> login(String nikNip, String password) async {
    lastLoginNik = nikNip;
    if (loginError != null) {
      throw ApiException(loginError!);
    }
    return AuthSession(
      token: 'token',
      user: AppUser(
        id: role == UserRole.kader ? 1 : 2,
        nama: role == UserRole.kader ? 'Bu Rini' : 'Bidan Sari',
        nikNip: nikNip,
        role: role,
        posyanduId: 1,
      ),
    );
  }

  @override
  Future<AppUser> me() async => AppUser(
    id: role == UserRole.kader ? 1 : 2,
    nama: role == UserRole.kader ? 'Bu Rini' : 'Bidan Sari',
    nikNip: 'demo',
    role: role,
    posyanduId: 1,
  );

  @override
  Future<void> logout() async {}

  @override
  Future<Map<String, dynamic>?> getActiveSession() async => {
    'id': 7,
    'posyandu_id': 1,
    'tanggal': '2026-05-19',
    'status': 'berjalan',
  };

  @override
  Future<PaginatedResult> getChildren({String search = '', int perPage = 10}) async {
    return PaginatedResult(data: [
      {
        'id': 11,
        'nama_balita': 'Raka Pratama',
        'nama_ibu': 'Wulan',
        'tanggal_lahir': '2023-10-01',
        'jenis_kelamin': 'L',
      },
    ]);
  }

  @override
  Future<Map<String, dynamic>> storeMeasurement({
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
    return {
      'id': 22,
      'status_prediksi': predictionFails ? 'gagal' : 'selesai',
      'hasil_prediksi': predictionFails
          ? null
          : {'risk_level': 'sedang'},
    };
  }

  @override
  Future<Map<String, dynamic>> retryPrediction(int measurementId) async => {
    'id': measurementId,
    'status_prediksi': 'selesai',
    'hasil_prediksi': {'risk_level': 'sedang'},
  };

  @override
  Future<PaginatedResult> getScreening(int sessionId) async {
    return PaginatedResult(data: [
      {
        'id': 22,
        'nama_balita': 'Raka Pratama',
        'status_prediksi': predictionFails ? 'gagal' : 'selesai',
        'risk_level': predictionFails ? null : 'sedang',
      },
    ]);
  }

  @override
  Future<PaginatedResult> getNotifications() async {
    return PaginatedResult(data: [
      {'judul': 'Validasi selesai', 'pesan': 'Rujukan sudah ditinjau bidan.'},
    ]);
  }

  @override
  Future<PaginatedResult> getReferrals({String search = '', String? status}) async {
    return PaginatedResult(data: [
      {
        'id': 31,
        'nama_balita': 'Raka Pratama',
        'nama_ibu': 'Wulan',
        'risk_level': 'tinggi',
        'status_rujukan': 'menunggu_validasi',
      },
    ]);
  }

  @override
  Future<Map<String, dynamic>> getReferral(int id) async => {
    'id': id,
    'nama_balita': 'Raka Pratama',
    'nama_ibu': 'Wulan',
    'risk_level': 'tinggi',
    'berat_badan': 10.2,
    'tinggi_badan': 84.5,
  };

  @override
  Future<Map<String, dynamic>> validateReferral({
    required int referralId,
    required String decision,
    required String note,
  }) async {
    validatedDecision = decision;
    return {
      'id': 41,
      'rujukan_id': referralId,
      'keputusan': decision,
      'catatan_bidan': note,
    };
  }

  @override
  Future<PaginatedResult> getPmt() async {
    return PaginatedResult(data: [
      {
        'id': 51,
        'nama_barang': 'Biskuit Balita',
        'stok_saat_ini': 7,
        'stok_minimum': 10,
        'satuan': 'dus',
      },
    ]);
  }

  @override
  Future<Map<String, dynamic>> distributePmt({
    required int validationId,
    required int childId,
    required int pmtId,
    required int amount,
    required DateTime date,
    String? note,
  }) async => {'id': 61};

  @override
  Future<Uint8List> downloadReport({
    required String type,
    String? startDate,
    String? endDate,
  }) async => Uint8List.fromList([1, 2, 3]);
}
