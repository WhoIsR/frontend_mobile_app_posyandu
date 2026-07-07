import '../../domain/entities/app_notification.dart';
import '../../domain/entities/balita.dart';
import '../../domain/entities/create_balita_request.dart';
import '../../domain/entities/kader_dashboard_data.dart';
import '../../domain/entities/measurement_result.dart';
import '../../domain/entities/posyandu_session.dart';
import '../../domain/entities/screening_item.dart';
import '../../domain/repositories/kader_repository.dart';
import '../datasources/kader_remote_data_source.dart';

class KaderRepositoryImpl implements KaderRepository {
  const KaderRepositoryImpl(this._remoteDataSource);

  final KaderRemoteDataSource _remoteDataSource;

  @override
  Future<KaderDashboardData> dashboard() async {
    // Jalankan request independen secara paralel
    final sessionFuture = activeSession();
    final childrenFuture = searchChildren();
    final notificationsFuture = notifications();

    // Tunggu session karena ID-nya dibutuhkan untuk screening
    final session = await sessionFuture;

    // Jalankan request screening secara paralel dengan sisa request lainnya
    final screeningFuture = session == null
        ? Future.value(<ScreeningItem>[])
        : screening(session.id);

    // Kumpulkan semua hasil yang tersisa
    final results = await Future.wait([
      childrenFuture,
      notificationsFuture,
      screeningFuture,
    ]);

    return KaderDashboardData(
      session: session,
      children: results[0] as List<Balita>,
      notifications: results[1] as List<AppNotification>,
      screening: results[2] as List<ScreeningItem>,
    );
  }

  @override
  Future<PosyanduSession?> activeSession() => _remoteDataSource.activeSession();

  @override
  Future<List<Balita>> searchChildren({String search = ''}) {
    return _remoteDataSource.children(search: search);
  }

  @override
  Future<Balita> createBalita(CreateBalitaRequest request) {
    return _remoteDataSource.createBalita(request);
  }

  @override
  Future<Balita> updateBalita(int id, CreateBalitaRequest request) {
    return _remoteDataSource.updateBalita(id, request);
  }

  @override
  Future<MeasurementResult> saveMeasurement({
    required int sessionId,
    required int childId,
    required double weight,
    required double height,
  }) {
    return _remoteDataSource.saveMeasurement(
      sessionId: sessionId,
      childId: childId,
      weight: weight,
      height: height,
    );
  }

  @override
  Future<MeasurementResult> retryPrediction(int measurementId) {
    return _remoteDataSource.retryPrediction(measurementId);
  }

  @override
  Future<List<ScreeningItem>> screening(int sessionId) {
    return _remoteDataSource.screening(sessionId);
  }

  @override
  Future<List<AppNotification>> notifications() {
    return _remoteDataSource.notifications();
  }

  @override
  Future<void> markNotificationRead(int id) {
    return _remoteDataSource.markNotificationRead(id);
  }
}
