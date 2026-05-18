import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/app_user.dart';
import 'package:mobile/features/auth/domain/entities/auth_session.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/login.dart';
import 'package:mobile/features/kader/domain/entities/measurement_result.dart';
import 'package:mobile/features/kader/domain/repositories/kader_repository.dart';
import 'package:mobile/features/kader/domain/usecases/save_measurement.dart';
import 'package:mobile/shared/risk/risk_copy.dart';

void main() {
  test('login usecase returns auth session through domain repository', () async {
    final usecase = Login(FakeAuthRepository());

    final session = await usecase('3271010101010001', 'password');

    expect(session.token, 'token');
    expect(session.user.role, UserRole.kader);
  });

  test('save measurement duplicate keeps backend message intact', () async {
    final usecase = SaveMeasurement(FakeKaderRepository(duplicate: true));

    expect(
      () => usecase(
        sessionId: 1,
        childId: 2,
        weight: 10.2,
        height: 84.5,
      ),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('Balita ini sudah dicatat pada sesi hari ini.'),
        ),
      ),
    );
  });

  test('risk copy maps model risk into ethical UI labels', () {
    expect(RiskCopy.label('rendah'), 'Risiko rendah');
    expect(RiskCopy.label('sedang'), 'Perlu perhatian');
    expect(RiskCopy.label('tinggi'), 'Perlu ditinjau bidan');
    expect(RiskCopy.label('gagal'), 'Prediksi gagal');
  });
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login(String nikNip, String password) async {
    return const AuthSession(
      token: 'token',
      user: AppUser(
        id: 1,
        nama: 'Kader Melati',
        nikNip: '3271010101010001',
        role: UserRole.kader,
        posyanduId: 1,
      ),
    );
  }

  @override
  Future<AppUser> currentUser() async => const AppUser(
    id: 1,
    nama: 'Kader Melati',
    nikNip: '3271010101010001',
    role: UserRole.kader,
    posyanduId: 1,
  );

  @override
  Future<void> logout() async {}

  @override
  Future<AppUser?> restoreSession() async => null;
}

class FakeKaderRepository implements KaderRepository {
  FakeKaderRepository({this.duplicate = false});

  final bool duplicate;

  @override
  Future<MeasurementResult> saveMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) async {
    if (duplicate) {
      throw Exception('Balita ini sudah dicatat pada sesi hari ini.');
    }
    return const MeasurementResult(id: 1, predictionStatus: 'selesai', riskLevel: 'sedang');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
